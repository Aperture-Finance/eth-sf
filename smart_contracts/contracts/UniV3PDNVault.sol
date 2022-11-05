// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.16 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IHomoraPDN.sol";

contract UniV3PDNVault {
    using SafeERC20 for IERC20;

    IHomoraPDN.PairInfo public pairInfo;
    // bank, oracle, router, spell
    IHomoraPDN.ContractInfo public contractInfo;

    IHomoraPDN.VaultConfig public vaultConfig;

    // Homora position id.
    uint256 public pid;

    constructor(
        address stableToken,
        address assetToken,
        address _bank
    ) payable {
        pairInfo.stableToken = stableToken;
        pairInfo.assetToken = assetToken;
        bank = _bank;
    }

    function setConfig(uint256 _leverageLevel, uint256 _debtRatioWidth)
        external
    {
        leverageLevel = _leverageLevel;
        debtRatioWidth = _debtRatioWidth;
    }

    function deposit(uint256 stableDepositAmount) public {
        if (stableDepositAmount > 0) {
            IERC20(pairInfo.stableToken).safeTransferFrom(
                msg.sender,
                address(this),
                stableDepositAmount
            );
        }

        // Call library to finish core deposit function.
        uint256 pidAfter = 20; // Function should return actual pid from Homora.
        pid = pid == pidAfter ? pid : pidAfter;
    }

    function withfraw(uint256 amount) public {
        // Call library to finish core withdraw function.
    }

    function rebalance() public {}

    function reinvest() public {}
}
