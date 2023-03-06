//SPDX-License-Identifier: LICENSED
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "./interfaces/ERC20Interface.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/PriceOracle.sol";
import "./interfaces/AggregatorV3Interface.sol";
import "./MultiSigOwner.sol";

contract OkseCardPriceOracle is PriceOracle, MultiSigOwner {
    using SafeMath for uint256;

    mapping(address => uint256) prices;
    event PricePosted(
        address asset,
        uint256 previousPriceMantissa,
        uint256 requestedPriceMantissa,
        uint256 newPriceMantissa
    );

    mapping(address => address) priceFeeds;
    event PriceFeedChanged(
        address asset,
        address previousPriceFeed,
        address newPriceFeed
    );

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        //////bsc///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        if (chainId == 56) {
            priceFeeds[
                0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
            ] = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE; // BNB/USD
            priceFeeds[
                0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d
            ] = 0x51597f405303C4377E36123cBc172b13269EA163; // USDC/USD
            priceFeeds[
                0x55d398326f99059fF775485246999027B3197955
            ] = 0xB97Ad0E74fa7d920791E90258A6E2085088b4320; // USDT/USD
            priceFeeds[
                0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
            ] = 0xcBb98864Ef56E9042e7d2efef76141f15731B82f; // BUSD/USD
            priceFeeds[
                0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c
            ] = 0x264990fbd0A4796A3E3d8E37C4d5F87a3aCa5Ebf; // WBTC/USD
            priceFeeds[
                0x2170Ed0880ac9A755fd29B2688956BD959F933F8
            ] = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e; // ETH/USD
        }
        //// matic //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        if (chainId == 137) {
            priceFeeds[
                0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270
            ] = 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0; // MATIC/USD
            priceFeeds[
                0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
            ] = 0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7; // USDC/USD
            priceFeeds[
                0xc2132D05D31c914a87C6611C10748AEb04B58e8F
            ] = 0x0A6513e40db6EB1b165753AD52E80663aeA50545; // USDT/USD
            priceFeeds[
                0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6
            ] = 0xDE31F8bFBD8c84b5360CFACCa3539B938dd78ae6; // WBTC/USD
            priceFeeds[
                0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619
            ] = 0xF9680D99D6C9589e2a93a78A04A279e509205945; // ETH/USD
            priceFeeds[
                0x0b3F868E0BE5597D5DB7fEB59E1CADBb0fdDa50a
            ] = 0x49B0c695039243BBfEb8EcD054EB70061fd54aa0; // SUSHI/USD
            priceFeeds[
                0xa3Fa99A148fA48D14Ed51d610c367C61876997F1
            ] = 0xd8d483d813547CfB624b8Dc33a00F2fcbCd2D428; // MIMATIC/USD
        }
        //// fantom //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        if (chainId == 250) {
            priceFeeds[
                0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83
            ] = 0xf4766552D15AE4d256Ad41B6cf2933482B0680dc; // FTM/USD
            priceFeeds[
                0x04068DA6C83AFCFA0e13ba15A6696662335D5B75
            ] = 0x2553f4eeb82d5A26427b8d1106C51499CBa5D99c; // USDC/USD
            priceFeeds[
                0x049d68029688eAbF473097a2fC38ef61633A3C7A
            ] = 0xF64b636c5dFe1d3555A847341cDC449f612307d0; // fUSDT/USD
            priceFeeds[
                0x321162Cd933E2Be498Cd2267a90534A804051b11
            ] = 0x8e94C22142F4A64b99022ccDd994f4e9EC86E4B4; // WBTC/USD
            priceFeeds[
                0x74b23882a30290451A17c44f4F05243b6b58C76d
            ] = 0x11DdD3d147E5b83D01cee7070027092397d63658; // WETH/USD
            priceFeeds[
                0xae75A438b2E0cB8Bb01Ec1E1e376De11D44477CC
            ] = 0xCcc059a1a17577676c8673952Dc02070D29e5a66; // SUSHI/USD
        }
        //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    }

    //return usd price of asset , decimal is 8
    function getUnderlyingPrice(address market)
        public
        view
        override
        returns (uint256)
    {
        uint80 roundID;
        int256 price;
        uint256 startedAt;
        uint256 timeStamp;
        uint80 answeredInRound;

        uint256 resultPrice;

        if (prices[market] != 0) {
            resultPrice = prices[market];
        } else {
            if (priceFeeds[market] != address(0)) {
                (
                    roundID,
                    price,
                    startedAt,
                    timeStamp,
                    answeredInRound
                ) = AggregatorV3Interface(priceFeeds[market]).latestRoundData();
            } else {
                price = 0;
            }
            resultPrice = uint256(price);
        }
        uint256 defaultDecimal = 18;
        ERC20Interface token = ERC20Interface(market);
        uint256 tokenDecimal = uint256(token.decimals());
        if (defaultDecimal == tokenDecimal) {
            return resultPrice;
        } else if (defaultDecimal > tokenDecimal) {
            return resultPrice.mul(10**(defaultDecimal.sub(tokenDecimal)));
        } else {
            return resultPrice.div(10**(tokenDecimal.sub(defaultDecimal)));
        }
    }

    function assetPrices(address asset) external view returns (uint256) {
        return prices[asset];
    }

    function setDirectPrice(bytes calldata signData, bytes calldata keys)
        external
        validSignOfOwner(signData, keys, "setDirectPrice")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        (address asset, uint256 price) = abi.decode(params, (address, uint256));
        setDirectPriceInternal(asset, price);
    }

    function setBatchDirectPrice(bytes calldata signData, bytes calldata keys)
        external
        validSignOfOwner(signData, keys, "setBatchDirectPrice")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        (address[] memory _assets, uint256[] memory _prices) = abi.decode(
            params,
            (address[], uint256[])
        );
        require(_assets.length == _prices.length, "le");
        for (uint256 i = 0; i < _assets.length; i++) {
            setDirectPriceInternal(_assets[i], _prices[i]);
        }
    }

    function setDirectPriceInternal(address asset, uint256 price) internal {
        emit PricePosted(asset, prices[asset], price, price);
        prices[asset] = price;
    }

    function setPriceFeed(bytes calldata signData, bytes calldata keys)
        external
        validSignOfOwner(signData, keys, "setPriceFeed")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        (address asset, address priceFeed) = abi.decode(
            params,
            (address, address)
        );
        emit PriceFeedChanged(asset, priceFeeds[asset], priceFeed);
        priceFeeds[asset] = priceFeed;
    }
}
