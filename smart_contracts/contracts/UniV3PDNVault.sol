// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.16 <0.9.0;

contract UniV3PDNVault {
    address stableToken;
    address assetToken;
    address bank;
    uint256 totalShareAmount;

    constructor(
        address _stableToken,
        address _assetToken,
        address _bank
    ) payable {
        stableToken = _stableToken;
        assetToken = _assetToken;
        bank = _bank;
    }

    function deposit(uint256 amount) public {}

    function withfraw(uint256 amount) public {}

    function rebalance() public {}

    function reinvest() public {}
}
