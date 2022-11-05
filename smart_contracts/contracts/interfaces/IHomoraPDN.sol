// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IHomoraPDN {
    // Contract address info
    struct ContractInfo {
        address adapter; // Aperture's adapter to interact with Homora
        address bank; // HomoraBank's address
        address oracle; // Homora's Oracle address
        address router; // DEX's router address
        address spell; // Homora's Spell address
    }

    // Addresses in the pair
    struct PairInfo {
        address stableToken; // token 0
        address assetToken; // token 1
        address lpToken; // ERC-721 LP token address
    }


}
