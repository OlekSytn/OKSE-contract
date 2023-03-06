//SPDX-License-Identifier: LICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;
import "./quickswap/interfaces/IUniswapV2Pair.sol";
import "./quickswap/interfaces/IUniswapV2Factory.sol";
import "./quickswap/libraries/UniswapV2Library.sol";

contract QuickSwapper {
  // factory address for AMM dex, normally we use spookyswap on fantom chain.
  address public factory;

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
    
      path = new address[](2);
      path[0] = token0;
      path[1] = token1;
  }
}
