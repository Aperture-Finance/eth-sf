// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IHomoraPDN {
    // Contract address info
    struct ContractInfo {
        address bank; // HomoraBank's address
        address oracle; // Homora's Oracle address
        address router; // DEX's router address
        address spell; // Homora's Spell address
        address optimalSwap;
        address wrapper; // WUniswapV3Position
    }

    // Addresses in the pair
    struct PairInfo {
        address stableToken; // token 0
        address assetToken; // token 1
        address lpToken; // ERC-721 LP token address
    }

    struct VaultConfig {
        uint16 leverageLevel; // target leverage * 10000
        uint16 targetDebtRatio; // target debt ratio * 10000, 92% -> 9200
        uint16 minDebtRatio; // minimum debt ratio * 10000
        uint16 maxDebtRatio; // maximum debt ratio * 10000
        uint16 deltaThreshold; // delta deviation threshold in percentage * 10000
        uint16 collateralFactor; // LP collateral factor on Homora
        uint16 stableBorrowFactor; // stable token borrow factor on Homora
        uint16 assetBorrowFactor; // asset token borrow factor on Homora
    }

    struct Position {
        uint256 shareAmount;
    }
}
