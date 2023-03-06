//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
import "./libraries/SafeMath.sol";
import "./interfaces/ERC20Interface.sol";
import "./interfaces/PriceOracle.sol";

contract Converter {
    using SafeMath for uint256;

    function convertUsdAmountToAssetAmount(
        uint256 usdAmount,
        address assetAddress
    ) public view returns (uint256) {
        ERC20Interface token = ERC20Interface(assetAddress);
        uint256 tokenDecimal = uint256(token.decimals());
        uint256 defaultDecimal = 18;
        if (defaultDecimal == tokenDecimal) {
            return usdAmount;
        } else if (defaultDecimal > tokenDecimal) {
            return usdAmount.div(10**(defaultDecimal.sub(tokenDecimal)));
        } else {
            return usdAmount.mul(10**(tokenDecimal.sub(defaultDecimal)));
        }
    }

    function convertAssetAmountToUsdAmount(
        uint256 assetAmount,
        address assetAddress
    ) public view returns (uint256) {
        ERC20Interface token = ERC20Interface(assetAddress);
        uint256 tokenDecimal = uint256(token.decimals());
        uint256 defaultDecimal = 18;
        if (defaultDecimal == tokenDecimal) {
            return assetAmount;
        } else if (defaultDecimal > tokenDecimal) {
            return assetAmount.mul(10**(defaultDecimal.sub(tokenDecimal)));
        } else {
            return assetAmount.div(10**(tokenDecimal.sub(defaultDecimal)));
        }
    }

    function getUsdAmount(
        address market,
        uint256 assetAmount,
        address priceOracle
    ) public view returns (uint256 usdAmount) {
        uint256 usdPrice = PriceOracle(priceOracle).getUnderlyingPrice(market);
        require(usdPrice > 0, "upe");
        usdAmount = (assetAmount.mul(usdPrice)).div(10**8);
    }

    // verified not
    function getAssetAmount(
        address market,
        uint256 usdAmount,
        address priceOracle
    ) public view returns (uint256 assetAmount) {
        uint256 usdPrice = PriceOracle(priceOracle).getUnderlyingPrice(market);
        require(usdPrice > 0, "usd price error");
        assetAmount = (usdAmount.mul(10**8)).div(usdPrice);
    }
}
