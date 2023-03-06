//SPDX-License-Identifier: LICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;
pragma abicoder v2;
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ERC20Interface.sol";
import "../interfaces/PriceOracle.sol";
import "../libraries/SafeMath.sol";

contract UniswapV3Swapper is Ownable {
    using SafeMath for uint256;
    address public immutable WETH;
    address public immutable USDC;
    uint24 public poolFee; // pool fees for weth-usdc pool
    ISwapRouter public immutable swapRouter;
    uint256 slippage;
    uint256 public constant SLIPPAGE_MAX = 1000000;
    address public priceOracle;
    mapping(address => bool) public tokenList;
    mapping(address => uint24) public poolFees;
    event TokenEnableUpdaated(address tokenAddr, bool _enabled);
    event PoolFeeUpdated(address tokenAddr, uint24 _poolFee);
    event PriceOracleUpdated(address priceOracle);
    event SlippageUpdated(uint256 slippage);

    constructor(
        address _swapRouter,
        address _priceOracle,
        address _weth,
        address _usdc
    ) {
        swapRouter = ISwapRouter(_swapRouter);
        priceOracle = _priceOracle;
        poolFee = 500;
        slippage = 30000; // 3%
        WETH = _weth;
        USDC = _usdc;
    }

    function _swapSingle(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal returns (uint256 amountOut) {
        uint256 amountInMaximum = ERC20Interface(path[0]).balanceOf(
            address(this)
        );
        // Approve the router to spend token
        TransferHelper.safeApprove(
            path[0],
            address(swapRouter),
            amountInMaximum
        );
        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        uint24 poolFee0 = poolFees[path[0]];
        require(poolFee0 > 0, "invalid poolfee");
        amountOut = amounts[1];
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: path[0],
                tokenOut: path[1],
                fee: poolFee0,
                recipient: _to,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactOutputSingle` executes the swap.
        uint256 amountIn = swapRouter.exactOutputSingle(params);
        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(path[0], address(swapRouter), 0);
            TransferHelper.safeTransfer(
                path[0],
                msg.sender,
                amountInMaximum - amountIn
            );
        }
    }

    function _swapMultiple(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal returns (uint256 amountOut) {
        uint256 amountInMaximum = ERC20Interface(path[0]).balanceOf(
            address(this)
        );
        TransferHelper.safeApprove(
            path[0],
            address(swapRouter),
            amountInMaximum
        );
        // Multiple pool swaps are encoded through bytes called a `path`. A path is a sequence of token addresses and poolFees that define the pools used in the swaps.
        // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut) where tokenIn/tokenOut parameter is the shared token across the pools.
        // Since we are swapping DAI to USDC and then USDC to WETH9 the path encoding is (DAI, 0.3%, USDC, 0.3%, WETH9).
        uint24 poolFee0 = poolFees[path[0]];
        require(poolFee0 > 0 && tokenList[path[0]], "not supported token");
        amountOut = amounts[amounts.length - 1];
        ISwapRouter.ExactOutputParams memory params = ISwapRouter
            .ExactOutputParams({
                path: abi.encodePacked(
                    path[0],
                    poolFee0,
                    path[1],
                    poolFee,
                    path[2]
                ),
                recipient: _to,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum
            });

        // Executes the swap.
        uint256 amountIn = swapRouter.exactOutput(params);
        // If the swap did not require the full amountInMaximum to achieve the exact amountOut then we refund msg.sender and approve the router to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(path[0], address(swapRouter), 0);
            TransferHelper.safeTransferFrom(
                path[0],
                address(this),
                msg.sender,
                amountInMaximum - amountIn
            );
        }
    }

    // **** SWAP ****
    // verified
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) external returns (uint256 amountOut) {
        require(path.length == 2 || path.length == 3, "invalid length");
        if (path.length == 2) {
            amountOut = _swapSingle(amounts, path, _to);
        } else {
            amountOut = _swapMultiple(amounts, path, _to);
        }
    }

    function getUsdAmount(
        address market,
        uint256 assetAmount,
        address _priceOracle
    ) public view returns (uint256 usdAmount) {
        uint256 usdPrice = PriceOracle(_priceOracle).getUnderlyingPrice(market);
        require(usdPrice > 0, "upe");
        usdAmount = (assetAmount.mul(usdPrice)).div(10**8);
    }

    // verified not
    function getAssetAmount(
        address market,
        uint256 usdAmount,
        address _priceOracle
    ) public view returns (uint256 assetAmount) {
        uint256 usdPrice = PriceOracle(_priceOracle).getUnderlyingPrice(market);
        require(usdPrice > 0, "usd price error");
        assetAmount = (usdAmount.mul(10**8)).div(usdPrice);
    }

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts)
    {
        require(path.length == 2 || path.length == 3, "invalid length");
        uint256 usdAmount = getUsdAmount(
            path[path.length - 1],
            amountOut,
            priceOracle
        );
        uint256 amountIn = getAssetAmount(path[0], usdAmount, priceOracle);
        amounts = new uint256[](path.length);
        amounts[0] = amountIn.add(amountIn.mul(slippage).div(SLIPPAGE_MAX));
        amounts[path.length - 1] = amountOut;
    }

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts)
    {
        require(path.length == 2 || path.length == 3, "invalid length");
        uint256 usdAmount = getUsdAmount(path[0], amountIn, priceOracle);
        uint256 amountOut = getAssetAmount(
            path[path.length - 1],
            usdAmount,
            priceOracle
        );
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        amounts[path.length - 1] = amountOut;
    }

    function GetReceiverAddress(
        address[] memory /*path*/
    ) external view returns (address) {
        return address(this);
    }

    function getOptimumPath(address token0, address token1)
        external
        view
        returns (address[] memory path)
    {
        if (tokenList[token0] && token1 == USDC) {
            path = new address[](3);
            path[0] = token0;
            path[1] = WETH;
            path[2] = USDC;
        } else {
            path = new address[](2);
            path[0] = token0;
            path[1] = token1;
        }
    }

    function setTokenEnable(address tokenAddr, bool _enable)
        external
        onlyOwner
    {
        tokenList[tokenAddr] = _enable;
        emit TokenEnableUpdaated(tokenAddr, _enable);
    }

    function setPoolFee(address tokenAddr, uint24 _poolFee) external onlyOwner {
        poolFees[tokenAddr] = _poolFee;
        emit PoolFeeUpdated(tokenAddr, _poolFee);
    }

    function setPriceOracle(address _priceoracle) external onlyOwner {
        priceOracle = _priceoracle;
        emit PriceOracleUpdated(priceOracle);
    }

    function setSlippage(uint256 _slippage) external onlyOwner {
        require(_slippage <= SLIPPAGE_MAX, "overflow slippage");
        slippage = _slippage;
        emit SlippageUpdated(slippage);
    }
}
