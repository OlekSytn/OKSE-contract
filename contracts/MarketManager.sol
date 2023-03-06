//SPDX-License-Identifier: LICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;
pragma abicoder v2;
import "./interfaces/ERC20Interface.sol";
import "./interfaces/ICard.sol";
import "./interfaces/IConverter.sol";
import "./MultiSigOwner.sol";
import "./Manager.sol";

contract MarketManager is MultiSigOwner, Manager {
    // default market , which is used when user didn't select any market for his main market
    address public defaultMarket;
    /// @notice A list of all assets
    address[] public allMarkets;
    // enable or disable for each market
    mapping(address => bool) public marketEnable;
    // store user's main asset used when user make payment.
    mapping(address => address) public userMainMarket;

    address public WETH;
    // // this is main currency for master wallet, master wallet will get always this token. normally we use USDC for this token.
    address public USDC;
    // // this is okse token address, which is used for setting of user's daily level and cashback.
    address public OKSE;
    // Set whether user can use okse as payment asset. normally it is false.
    bool public oksePaymentEnable;
    bool public emergencyStop;
    uint256 public slippage;
    address public immutable converter;
    modifier marketSupported(address market) {
        require(isMarketExist(market), "mns");
        _;
    }
    // verified
    modifier marketEnabled(address market) {
        require(marketEnable[market], "mdnd");
        _;
    }

    event MarketAdded(address market);
    event DefaultMarketChanged(address newMarket);
    event TokenAddressChanged(address okse, address usdc);
    event EmergencyStopChanged(bool emergencyStop);
    event OkseAsPaymentChanged(bool oksePaymentEnable);
    event MarketEnableChanged(address market, bool bEnable);
    event SlippageChanged(uint256 slippage);

    constructor(
        address _cardContract,
        address _WETH,
        address _usdcAddress,
        address _okseAddress,
        address _converter
    ) Manager(_cardContract) {
        WETH = _WETH;
        USDC = _usdcAddress;
        OKSE = _okseAddress;
        _addMarketInternal(WETH);
        _addMarketInternal(USDC);
        _addMarketInternal(OKSE);
        defaultMarket = WETH;
        converter = _converter;
        slippage = 1000; // 10%
    }

    //verified
    function _addMarketInternal(address assetAddr) internal {
        for (uint256 i = 0; i < allMarkets.length; i++) {
            require(allMarkets[i] != assetAddr, "maa");
        }
        allMarkets.push(assetAddr);
        marketEnable[assetAddr] = true;
        emit MarketAdded(assetAddr);
    }

    ////////////////////////// Read functions /////////////////////////////////////////////////////////////
    function isMarketExist(address market) public view returns (bool) {
        bool marketExist = false;
        for (uint256 i = 0; i < allMarkets.length; i++) {
            if (allMarkets[i] == market) {
                marketExist = true;
            }
        }
        return marketExist;
    }

    function getBlockTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getAllMarkets() public view returns (address[] memory) {
        return allMarkets;
    }

    function getUserMainMarket(address userAddr) public view returns (address) {
        if (userMainMarket[userAddr] == address(0)) {
            return defaultMarket; // return default market
        }
        address market = userMainMarket[userAddr];
        if (marketEnable[market] == false) {
            return defaultMarket; // return default market
        }
        return market;
    }

    function getBatchUserAssetAmount(address userAddr)
        public
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256[] memory assets = new uint256[](allMarkets.length);
        uint256[] memory decimals = new uint256[](allMarkets.length);

        for (uint256 i = 0; i < allMarkets.length; i++) {
            assets[i] = ICard(cardContract).usersBalances(
                userAddr,
                allMarkets[i]
            );
            ERC20Interface token = ERC20Interface(allMarkets[i]);
            uint256 tokenDecimal = uint256(token.decimals());
            decimals[i] = tokenDecimal;
        }
        return (allMarkets, assets, decimals);
    }

    function getBatchUserBalanceInUsd(address userAddr)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256[] memory assets = new uint256[](allMarkets.length);

        for (uint256 i = 0; i < allMarkets.length; i++) {
            assets[i] = IConverter(converter).getUsdAmount(
                allMarkets[i],
                ICard(cardContract).usersBalances(userAddr, allMarkets[i]),
                ICard(cardContract).priceOracle()
            );
        }
        return (allMarkets, assets);
    }

    function getUserBalanceInUsd(address userAddr)
        public
        view
        returns (uint256)
    {
        address market = getUserMainMarket(userAddr);
        uint256 assetAmount = ICard(cardContract).usersBalances(
            userAddr,
            market
        );
        uint256 usdAmount = IConverter(converter).getUsdAmount(
            market,
            assetAmount,
            ICard(cardContract).priceOracle()
        );
        return usdAmount;
    }

    ///////////////// CallBack functions from card contract //////////////////////////////////////////////
    function setUserMainMakret(address userAddr, address market)
        public
        onlyFromCardContract
    {
        if (getUserMainMarket(userAddr) == market) return;
        userMainMarket[userAddr] = market;
    }

    //////////////////// Owner functions ////////////////////////////////////////////////////////////////
    // verified
    function addMarket(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "addMarket")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        address market = abi.decode(params, (address));
        _addMarketInternal(market);
    }

    function setDefaultMarket(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "setDefaultMarket")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        address market = abi.decode(params, (address));
        require(isMarketExist(market), "me");
        require(marketEnable[market], "mn");
        defaultMarket = market;
        emit DefaultMarketChanged(market);
    }

    // verified
    function enableMarket(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "enableMarket")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        (address market, bool bEnable) = abi.decode(params, (address, bool));
        marketEnable[market] = bEnable;
        emit MarketEnableChanged(market, bEnable);
    }

    function setParams(bytes calldata signData, bytes calldata keys)
        external
        validSignOfOwner(signData, keys, "setParams")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        (address _newOkse, address _newUSDC) = abi.decode(
            params,
            (address, address)
        );
        OKSE = _newOkse;
        USDC = _newUSDC;
        emit TokenAddressChanged(OKSE, USDC);
    }

    // verified
    function setOkseAsPayment(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "setOkseAsPayment")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        bool bEnable = abi.decode(params, (bool));
        oksePaymentEnable = bEnable;
        emit OkseAsPaymentChanged(oksePaymentEnable);
    }

    function setSlippage(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "setSlippage")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        uint256 _value = abi.decode(params, (uint256));
        slippage = _value;
        emit SlippageChanged(slippage);
    }

    function setEmergencyStop(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "setEmergencyStop")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        bool _value = abi.decode(params, (bool));
        emergencyStop = _value;
        emit EmergencyStopChanged(emergencyStop);
    }
}
