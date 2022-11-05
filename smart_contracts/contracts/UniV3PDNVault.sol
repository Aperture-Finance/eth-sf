// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.16 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/IHomoraPDN.sol";
import "./interfaces/homorav2/banks/IBank.sol";
import "./interfaces/homorav2/spells/IUniswapV3Spell.sol";
import "./interfaces/uniswapv3/IUniswapV3Pool.sol";

contract UniV3PDNVault {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // --- constants ---
    uint256 public constant X96 = 2**96;

    // --- config ---
    IHomoraPDN.PairInfo public pairInfo;
    // bank, oracle, router, spell
    IHomoraPDN.ContractInfo public contractInfo;

    IHomoraPDN.VaultConfig public vaultConfig;

    // --- state ---
    uint256 public totalShare;
    mapping(uint16 => mapping(uint128 => IHomoraPDN.Position)) public positions;
    // Homora position id.
    uint256 public pid;

    event LogDeposit();
    event LogWithdraw();
    event LogRebalance();
    event LogReinvest();

    constructor(
        address stableToken,
        address assetToken,
        address bank,
        address spell,
        address stableToken,
        address assetToken
    ) payable {
        pairInfo.stableToken = stableToken;
        pairInfo.assetToken = assetToken;
        require(bank != address(0));
        contractInfo.bank = bank;
        contractInfo.oracle = IBank(bank).oracle();
        require(spell != address(0));
        contractInfo.spell = spell;
        contractInfo.router = IUniswapV3Spell(spell).router();
//        pairInfo.lpToken = IUniswapV3Spell(spell).pairs(
//            stableToken,
//            assetToken
//        );
//        require(IBank(bank).support(pairInfo.lpToken));
        require(IBank(bank).support(stableToken));
        pairInfo.stableToken = stableToken;
        require(IBank(bank).support(assetToken));
        pairInfo.assetToken = assetToken;
    }

    function setConfig(uint256 _leverageLevel, uint256 _debtRatioWidth)
        external
    {
        leverageLevel = _leverageLevel;
        debtRatioWidth = _debtRatioWidth;
    }

    function uniSqrtPriceX96(IUniswapV3Pool pool)
        internal
        view
        returns (uint160 sqrtPriceX96)
    {
        (sqrtPriceX96, , , , , , ) = pool.slot0();
    }

    function mulSquareX96(uint256 amount, uint160 sqrtPriceBx96)
        internal
        pure
        returns (uint256)
    {
        return amount.mulDiv(sqrtPriceBx96, X96).mulDiv(sqrtPriceBx96, X96);
    }

    function divSquareX96(uint256 amount, uint160 sqrtPriceBx96)
        internal
        pure
        returns (uint256)
    {
        return amount.mulDiv(X96, sqrtPriceBx96).mulDiv(X96, sqrtPriceBx96);
    }

    function deltaNeutralMath(
        IHomoraPDN.PairInfo memory pairInfo,
        uint256 amtAUser,
        uint256 amtBUser,
        uint256 leverage
    ) internal view returns (uint256) {
        IUniswapV3Pool pool = IUniswapV3Pool(pairInfo.lpToken);
        uint160 sqrtPriceBx96 = uniSqrtPriceX96(pool);
        uint256 equity = amtAUser;
        if (pairInfo.stableToken == pool.token0()) {
             equity += mulSquareX96(amtBUser, sqrtPriceBx96);
        } else {
            equity += divSquareX96(amtBUser, sqrtPriceBx96);
        }
        uint256 amtABorrow;
        uint256 amtBBorrow;
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
        uint256 pidAfter = 20;
        // Function should return actual pid from Homora.
        pid = pid == pidAfter ? pid : pidAfter;
    }

    function withfraw(uint256 amount) public {
        // Call library to finish core withdraw function.
    }

    function rebalance() public {}

    function reinvest() public {}
}
