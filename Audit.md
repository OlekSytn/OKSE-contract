1. following files is already audited from other projects, so we don't need audit for these files and folders.

   | Files                                 |                                 description                                 |
   | ------------------------------------- | :-------------------------------------------------------------------------: |
   | /interfaces/AggregatorV3Interface.sol |  fetched from chainlink github and audited already with chainlink contract  |
   | /interfaces/PriceOracle.sol           |  fetched from chainlink github and audited already with chainlink contract  |
   | /interfaces/ERC20Interface.sol        |   fettched from openzepplin and audited already with openzepplin contract   |
   | /interfaces/IWETH.sol                 |   fettched from openzepplin and audited already with openzepplin contract   |
   | /libraries/SafeMath.sol               | fetched from uniswap v2 github and audited already with uniswap v2 contract |
   | /libraries/TransferHelper.sol         | fetched from uniswap v2 github and audited already with uniswap v2 contract |
   | /Swapper/pancakeswap/                 |                 https://www.certik.com/projects/pancakeswap                 |
   | /Swapper/quickswap/                   |              https://omniscia.io/quickswap-converter-contract/              |
   | /Swapper/spookyswap/                  |                 https://www.certik.com/projects/spookyswap                  |
   | /Swapper/sushiswap/                   |                     https://www.defisafety.com/pqrs/113                     |
   | /Swapper/uniswapv2/                   |                       https://rskswap.com/audit.html                        |

2. following files are not audited before

   | Files                                |
   | ------------------------------------ |
   | CustomPriceFeed/CustomPriceFeed.sol  |
   | CustomPriceFeed/CustomPriceFeed2.sol |
   | interface/ISwapper.sol               |
   | Swapper/PancakeSwapper.sol           |
   | Swapper/QuickSwapper.sol             |
   | Swapper/SpookySwapper.sol            |
   | Swapper/SushiSwapper.sol             |
   | OkseCard.sol                         |
   | OkseToken.sol                        |
   | OkseCardPriceOracle.sol              |
   | OwnerConstants.sol                   |
   | Signer.sol                           |
