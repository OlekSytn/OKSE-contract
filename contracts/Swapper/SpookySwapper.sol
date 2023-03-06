//SPDX-License-Identifier: LICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;
import "./spookyswap/interfaces/IUniswapV2Pair.sol";
import "./spookyswap/interfaces/IUniswapV2Factory.sol";
import "./spookyswap/libraries/UniswapV2Library.sol";

contract SpookySwapper {
  // factory address for AMM dex, normally we use spookyswap on fantom chain.
  address public factory;
  address public constant TOMB = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7;
  address public constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
  address public constant USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;
  address public constant OKSE = 0xEFF6FcfBc2383857Dd66ddf57effFC00d58b7d9D;
  address public constant BOO = 0x841FAD6EAe12c286d1Fd18d1d525DFfA75C7EFFE;
  address public constant TOR = 0x74E23dF9110Aa9eA0b6ff2fAEE01e740CA1c642e;

  constructor(address _factory) {
    factory = _factory;
  }

  // **** SWAP ****
  // verified
  // requires the initial amount to have already been sent to the first pair
  function _swap(
    uint256[] memory amounts,
    address[] memory path,
    address _to
  ) external {
    for (uint256 i; i < path.length - 1; i++) {
      (address input, address output) = (path[i], path[i + 1]);
      (address token0, ) = UniswapV2Library.sortTokens(input, output);
      uint256 amountOut = amounts[i + 1];
      (uint256 amount0Out, uint256 amount1Out) = input == token0
        ? (uint256(0), amountOut)
        : (amountOut, uint256(0));
      address to = i < path.length - 2
        ? UniswapV2Library.pairFor(factory, output, path[i + 2])
        : _to;
      IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
        amount0Out,
        amount1Out,
        to,
        new bytes(0)
      );
    }
  }

  function getAmountsIn(
    uint256 amountOut,
    address[] memory path
  ) external view returns (uint256[] memory amounts) {
    return UniswapV2Library.getAmountsIn(factory, amountOut, path);
  }

  function GetReceiverAddress(
    address[] memory path
  ) external view returns (address) {
    return UniswapV2Library.pairFor(factory, path[0], path[1]);
  }

  function getOptimumPath(
    address token0,
    address token1
  ) external view returns (address[] memory path) {
    if(token0 == TOMB && token1 == USDC) { //TOMB-USDC pair
      path = new address[](3);
      path[0] = TOMB;
      path[1] = WFTM;
      path[2] = USDC;
    }
    else if(token0 == OKSE && token1 == USDC) // OKSE-USDC pair
    {
      path = new address[](3);
      path[0] = OKSE;
      path[1] = WFTM;
      path[2] = USDC;
    }
    else if(token0 == BOO && token1 == USDC) // OKSE-USDC pair
    {
      path = new address[](3);
      path[0] = BOO;
      path[1] = WFTM;
      path[2] = USDC;
    }
    else if(token0 == TOR && token1 == USDC) // TOR-USDC pair
    {
      path = new address[](3);
      path[0] = TOR;
      path[1] = WFTM;
      path[2] = USDC;
    }
    else
    {
      path = new address[](2);
      path[0] = token0;
      path[1] = token1;
    }
  }
}
