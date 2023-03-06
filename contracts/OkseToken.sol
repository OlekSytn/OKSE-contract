//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OkseToken is ERC20{
    constructor() ERC20("Okse", "OKSE"){
        _mint(msg.sender,1000000000*10**18);
    }
}