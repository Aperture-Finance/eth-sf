// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.16 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/IHomoraPDN.sol";
import "./interfaces/homorav2/banks/IBank.sol";
import "./interfaces/homorav2/spells/IUniswapV3Spell.sol";
import "./interfaces/homorav2/IUniswapV3OptimalSwap.sol";
import "./interfaces/uniswapv3/IUniswapV3Pool.sol";

import "./libraries/UniswapV3TickMath.sol";

contract UniV3PDNVault {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // --- constants ---
    uint256 public constant X96 = 2**96;
    uint16 public constant MAX_BPS = 10000;
    uint16 public constant SQRT_MAX_BPS = 100;
    uint16 public constant TWO_MAX_BPS = 20000;

    // --- config ---
    IHomoraPDN.PairInfo public pairInfo;
    // bank, oracle, router, spell
    IHomoraPDN.ContractInfo public contractInfo;

    IHomoraPDN.VaultConfig public vaultConfig;

    // --- state ---
    uint256 public totalShare;
    mapping(uint16 => mapping(uint128 => IHomoraPDN.Position)) public positions;
    // Homora position id.
    uint256 public position_id;

    event LogDeposit();
    event LogWithdraw();
    event LogRebalance();
    event LogReinvest();

    constructor(
        address spell,
        address stableToken,
        address assetToken,
        address lpToken,
        address optimalSwap
    ) payable {
        pairInfo.stableToken = stableToken;
        pairInfo.assetToken = assetToken;
        require(spell != address(0));
        contractInfo.spell = spell;
        contractInfo.optimalSwap = optimalSwap;
        address bank = IUniswapV3Spell(spell).bank();
        contractInfo.bank = bank;
        contractInfo.oracle = IBank(bank).oracle();
        contractInfo.router = IUniswapV3Spell(spell).router();
        pairInfo.lpToken = lpToken;
        //        require(IBank(bank).support(pairInfo.lpToken));
        require(IBank(bank).support(stableToken));
        pairInfo.stableToken = stableToken;
        require(IBank(bank).support(assetToken));
        pairInfo.assetToken = assetToken;
    }

    function setConfig(uint16 _leverageLevel, uint256 _debtRatioWidth)
        external
    {
        vaultConfig.leverageLevel = _leverageLevel;
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
        uint16 priceRatioBps,
        uint256 amtAUser,
        uint256 amtBUser
    ) internal view returns (IUniswapV3Spell.OpenPositionParams memory params) {
        IUniswapV3Pool pool = IUniswapV3Pool(pairInfo.lpToken);
        uint160 sqrtPriceX96 = uniSqrtPriceX96(pool);
        int24 tickUpper = UniswapV3TickMath.getTickAtSqrtRatio(
            (sqrtPriceX96 * uint160(Math.sqrt(priceRatioBps))) / SQRT_MAX_BPS
        );
        int24 tickLower = UniswapV3TickMath.getTickAtSqrtRatio(
            (sqrtPriceX96 * SQRT_MAX_BPS) / uint160(Math.sqrt(priceRatioBps))
        );
        uint256 equity = amtAUser;
        if (pairInfo.stableToken == pool.token0()) {
            params.token0 = pairInfo.stableToken;
            params.token1 = pairInfo.assetToken;
            params.amt0User = amtAUser;
            params.amt1User = amtBUser;
            equity += mulSquareX96(amtBUser, sqrtPriceX96);
            params.amt0Borrow =
                ((vaultConfig.leverageLevel - TWO_MAX_BPS) * equity) /
                vaultConfig.leverageLevel;
            params.amt1Borrow = divSquareX96(
                (vaultConfig.leverageLevel * equity) / 2,
                sqrtPriceX96
            );
        } else {
            params.token0 = pairInfo.assetToken;
            params.token1 = pairInfo.stableToken;
            params.amt0User = amtBUser;
            params.amt1User = amtAUser;
            equity += divSquareX96(amtBUser, sqrtPriceX96);
            params.amt0Borrow = mulSquareX96(
                (vaultConfig.leverageLevel * equity) / 2,
                sqrtPriceX96
            );
            params.amt1Borrow =
                ((vaultConfig.leverageLevel - TWO_MAX_BPS) * equity) /
                vaultConfig.leverageLevel;
        }

        IUniswapV3OptimalSwap optimalSwap = IUniswapV3OptimalSwap(
            contractInfo.optimalSwap
        );
        (
            params.amtInOptimalSwap,
            params.amtOutMinOptimalSwap,
            params.isZeroForOneSwap
        ) = optimalSwap.getOptimalSwapAmt(
            pool,
            params.amt0User + params.amt0Borrow,
            params.amt1User + params.amt1Borrow,
            tickLower,
            tickUpper
        );
        params.deadline = block.timestamp;
    }

    function deposit(uint16 priceRatioBps, uint256 stableDepositAmount)
        external
    {
        if (stableDepositAmount > 0) {
            IERC20(pairInfo.stableToken).safeTransferFrom(
                msg.sender,
                address(this),
                stableDepositAmount
            );
        }

        IUniswapV3Spell.OpenPositionParams memory params = deltaNeutralMath(
            priceRatioBps,
            stableDepositAmount,
            0
        );
        position_id = IBank(contractInfo.bank).execute(
            position_id,
            contractInfo.spell,
            abi.encodeWithSelector(
                IUniswapV3Spell.openPosition.selector,
                params
            )
        );

        emit LogDeposit();
    }

    function withdraw(uint256 amount) external {
        // Call library to finish core withdraw function.
    }

    function rebalance() external {}

    function reinvest() external {}

    /// @notice Vault position on Homora
    function getPositionInfo()
        public
        view
        returns (
            address collToken,
            uint256 collId,
            uint256 collateralSize
        )
    {
        (collToken, collId, collateralSize) = IBank(contractInfo.bank)
            .getPositionInfo(position_id);
    }

    function getCollateralETHValue() public view returns (uint256) {
        return IBank(contractInfo.bank).getCollateralETHValue(position_id);
    }

    function getBorrowETHValue() public view returns (uint256) {
        return IBank(contractInfo.bank).getBorrowETHValue(position_id);
    }

    /// @notice Calculate the debt ratio as seen by Homora Bank, multiplied by 1e4
    function getDebtRatio() external view returns (uint16) {
        return
            uint16((getBorrowETHValue() * MAX_BPS) / getCollateralETHValue());
    }
}
