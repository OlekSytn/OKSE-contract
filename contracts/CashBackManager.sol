//SPDX-License-Identifier: LICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;
pragma abicoder v2;
import "./interfaces/ERC20Interface.sol";
import "./interfaces/ICard.sol";
import "./MultiSigOwner.sol";
import "./Manager.sol";

contract CashBackManager is MultiSigOwner, Manager {
    uint256 public constant MAX_LEVEL = 5;
    // Setting for cashback enable or disable
    bool public cashBackEnable;
    // cashback percent for each level
    uint256[] public CashBackPercents;

    event CashBackEnableChanged(bool cashBackEnable);
    event CashBackPercentChanged(uint256 index, uint256 _amount);

    constructor(address _cardContract) Manager(_cardContract) {
        CashBackPercents = [10, 200, 300, 400, 500, 600];
        cashBackEnable = true;
    }

    ////////////////////////// Read functions /////////////////////////////////////////////////////////////
    //verified
    function getCashBackPercent(uint256 level) public view returns (uint256) {
        require(level <= 5, "level > 5");
        return CashBackPercents[level];
    }

    //////////////////// Owner functions ////////////////////////////////////////////////////////////////
    // verified
    function setCashBackPercent(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "setCashBackPercent")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        (uint256 index, uint256 _amount) = abi.decode(
            params,
            (uint256, uint256)
        );
        require(index <= MAX_LEVEL, "level<=5");
        CashBackPercents[index] = _amount;
        emit CashBackPercentChanged(index, _amount);
    }

    function setCashBackEnable(bytes calldata signData, bytes calldata keys)
        public
        validSignOfOwner(signData, keys, "setCashBackEnable")
    {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        bool newEnabled = abi.decode(params, (bool));
        cashBackEnable = newEnabled;
        emit CashBackEnableChanged(cashBackEnable);
    }
}
