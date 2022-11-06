// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IHomoraPDN {
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
