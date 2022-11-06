// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.16 <0.9.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/homorav2/IOracle.sol";
import "./interfaces/homorav2/banks/IBank.sol";
import "./interfaces/homorav2/spells/IUniswapV3Spell.sol";
import "./interfaces/homorav2/IUniswapV3OptimalSwap.sol";
import "./interfaces/homorav2/wrappers/IWUniswapV3Position.sol";
import "./interfaces/uniswapv3/IUniswapV3Pool.sol";

import "./libraries/UniswapV3TickMath.sol";

contract UniV3PDNVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    struct VaultConfig {
        uint16 leverage; // target leverage * 10000
        uint16 targetDebtRatio; // target debt ratio * 10000, 92% -> 9200
        uint16 minDebtRatio; // minimum debt ratio * 10000
        uint16 maxDebtRatio; // maximum debt ratio * 10000
        uint16 collateralFactor; // LP collateral factor on Homora
        uint16 stableBorrowFactor; // stable token borrow factor on Homora
        uint16 assetBorrowFactor; // asset token borrow factor on Homora
    }

    // --- constants ---
    uint256 public constant X96 = 2 ** 96;
    uint16 public constant MAX_BPS = 10000;
    uint16 public constant SQRT_MAX_BPS = 100;
    uint16 public constant TWO_MAX_BPS = 20000;

    // --- config ---
    IBank public bank; // HomoraBank's address
    IOracle public oracle; // Homora's Oracle address
    IUniswapV3Spell public spell; // Homora's Spell address
    IUniswapV3OptimalSwap public optimalSwap;
    IWUniswapV3Position public wrapper; // WUniswapV3Position

    address stableToken; // token 0
    address assetToken; // token 1
    IUniswapV3Pool public pool; // ERC-721 LP token address

    VaultConfig public vaultConfig;

    // --- state ---
    uint256 public totalShare;
    // Mapping from user address to Homora position id.
    mapping(address => uint256) public positions;

    event LogDeposit(
        address user,
        uint256 position_id,
        uint256 stableDepositAmount
    );
    event LogWithdraw(
        address user,
        uint256 position_id,
        uint256 stableWithdrawAmount,
        uint256 assetWithdrawAmount
    );
    event LogRebalance();
    event LogReinvest(address user, uint256 position_id);

    error Invalid_Debt_Ratio();

    constructor(
        address _spell,
        address _stableToken,
        address _assetToken,
        address _pool,
        address _optimalSwap
    ) payable {
        stableToken = _stableToken;
        assetToken = _assetToken;
        require(_spell != address(0));
        IUniswapV3Spell iSpell = IUniswapV3Spell(_spell);
        spell = iSpell;
        optimalSwap = IUniswapV3OptimalSwap(_optimalSwap);
        wrapper = IWUniswapV3Position(iSpell.wrapper());
        IBank iBank = IBank(iSpell.bank());
        bank = iBank;
        oracle = IOracle(iBank.oracle());
        pool = IUniswapV3Pool(_pool);
        require(iBank.support(_stableToken));
        stableToken = _stableToken;
        require(iBank.support(_assetToken));
        assetToken = _assetToken;
    }

    function setConfig(
        uint16 _leverage,
        uint16 _debtRatioWidth
    ) external onlyOwner {
        IBaseOracle source = oracle.source();
        (, uint16 collateralFactor, ) = oracle.tokenFactors(address(pool));
        (uint16 stableBorrowFactor, , ) = oracle.tokenFactors(stableToken);
        (uint16 assetBorrowFactor, , ) = oracle.tokenFactors(assetToken);
        uint16 targetDebtRatio = uint16(
            (MAX_BPS *
                (Math.mulDiv(
                    stableBorrowFactor,
                    _leverage - TWO_MAX_BPS,
                    _leverage
                ) + assetBorrowFactor)) / (2 * collateralFactor)
        );
        uint16 minDebtRatio = targetDebtRatio - _debtRatioWidth;
        uint16 maxDebtRatio = targetDebtRatio + _debtRatioWidth;
        console.log("collateralFactor", collateralFactor);
        console.log("stableBorrowFactor", stableBorrowFactor);
        console.log("assetBorrowFactor", assetBorrowFactor);
        console.log("targetDebtRatio", targetDebtRatio);
        //        console.log("stableETHPx", source.getETHPx(stableToken));
        //        console.log("assetETHPx", source.getETHPx(assetToken));
        //        console.log("lpETHPx", source.getETHPx(address(pool)));
        if (
            !(0 < minDebtRatio &&
                minDebtRatio < maxDebtRatio &&
                maxDebtRatio < MAX_BPS)
        ) {
            revert Invalid_Debt_Ratio();
        }
        vaultConfig = VaultConfig(
            _leverage,
            targetDebtRatio,
            minDebtRatio,
            maxDebtRatio,
            collateralFactor,
            stableBorrowFactor,
            assetBorrowFactor
        );
    }

    function sqrtToken0PriceX96() internal view returns (uint160 sqrtPriceX96) {
        (sqrtPriceX96, , , , , , ) = pool.slot0();
    }

    function matchTickSpacing(int24 tick) internal view returns (int24) {
        uint tickSpacing = uint(int(pool.tickSpacing()));
        uint absTick = tick < 0 ? uint(-int(tick)) : uint(int(tick));
        absTick -= absTick % tickSpacing;
        return tick < 0 ? -int24(int(absTick)) : int24(int(absTick));
    }

    function mulSquareX96(
        uint256 amount,
        uint160 sqrtPriceBx96
    ) internal pure returns (uint256) {
        return amount.mulDiv(sqrtPriceBx96, X96).mulDiv(sqrtPriceBx96, X96);
    }

    function divSquareX96(
        uint256 amount,
        uint160 sqrtPriceBx96
    ) internal pure returns (uint256) {
        return amount.mulDiv(X96, sqrtPriceBx96).mulDiv(X96, sqrtPriceBx96);
    }

    function deltaNeutralMath(
        uint16 priceRatioBps,
        uint256 amtAUser,
        uint256 amtBUser
    ) internal view returns (IUniswapV3Spell.OpenPositionParams memory params) {
        params.fee = 500;
        uint160 sqrtPriceX96 = sqrtToken0PriceX96();
        params.tickUpper = matchTickSpacing(
            UniswapV3TickMath.getTickAtSqrtRatio(
                (sqrtPriceX96 * uint160(Math.sqrt(priceRatioBps))) /
                    SQRT_MAX_BPS
            )
        );
        params.tickLower = matchTickSpacing(
            UniswapV3TickMath.getTickAtSqrtRatio(
                (sqrtPriceX96 * SQRT_MAX_BPS) /
                    uint160(Math.sqrt(priceRatioBps))
            )
        );

        uint16 leverage = vaultConfig.leverage;
        uint256 equity;
        if (stableToken == pool.token0()) {
            // sqrtPriceX96 == sqrt(token1/token0) * 2**96
            params.token0 = stableToken;
            params.token1 = assetToken;
            params.amt0User = amtAUser;
            params.amt1User = amtBUser;
            equity =
                params.amt0User +
                divSquareX96(params.amt1User, sqrtPriceX96);
            params.amt0Borrow =
                ((leverage - TWO_MAX_BPS) * equity) /
                TWO_MAX_BPS;
            params.amt1Borrow = mulSquareX96(
                (leverage * equity) / TWO_MAX_BPS,
                sqrtPriceX96
            );
        } else {
            require(stableToken == pool.token1(), "Wrong pool");
            params.token0 = assetToken;
            params.token1 = stableToken;
            params.amt0User = amtBUser;
            params.amt1User = amtAUser;
            equity =
                params.amt0User +
                divSquareX96(params.amt1User, sqrtPriceX96);
            params.amt0Borrow = (leverage * equity) / TWO_MAX_BPS;
            params.amt1Borrow = mulSquareX96(
                ((leverage - TWO_MAX_BPS) * equity) / TWO_MAX_BPS,
                sqrtPriceX96
            );
        }

        (
            params.amtInOptimalSwap,
            params.amtOutMinOptimalSwap,
            params.isZeroForOneSwap
        ) = optimalSwap.getOptimalSwapAmt(
            pool,
            params.amt0User + params.amt0Borrow,
            params.amt1User + params.amt1Borrow,
            params.tickLower,
            params.tickUpper
        );
        params.deadline = block.timestamp;
    }

    function deposit(
        uint16 priceRatioBps,
        uint256 stableDepositAmount
    ) external nonReentrant {
        if (stableDepositAmount > 0) {
            IERC20(stableToken).safeTransferFrom(
                msg.sender,
                address(this),
                stableDepositAmount
            );
            IERC20(stableToken).approve(address(bank), stableDepositAmount);
        }

        IUniswapV3Spell.OpenPositionParams memory params = deltaNeutralMath(
            priceRatioBps,
            stableDepositAmount,
            0
        );
        console.log("amt0User", params.amt0User);
        console.log("amt1User", params.amt1User);
        console.log("amt0Borrow", params.amt0Borrow);
        console.log("amt1Borrow", params.amt1Borrow);

        uint256 position_id = bank.execute(
            positions[msg.sender],
            address(spell),
            abi.encodeWithSelector(
                IUniswapV3Spell.openPosition.selector,
                params
            )
        );
        positions[msg.sender] = position_id;

        emit LogDeposit(msg.sender, position_id, stableDepositAmount);
    }

    function withdraw() external nonReentrant {
        IUniswapV3Spell.ClosePositionParams memory params = IUniswapV3Spell
            .ClosePositionParams(0, 0, block.timestamp, true);
        uint256 position_id = positions[msg.sender];
        bank.execute(
            position_id,
            address(spell),
            abi.encodeWithSelector(
                IUniswapV3Spell.closePosition.selector,
                params
            )
        );
        uint256 stableBalance = IERC20(stableToken).balanceOf(address(this));
        if (stableBalance > 0) {
            IERC20(stableToken).safeTransfer(msg.sender, stableBalance);
        }
        uint256 assetBalance = IERC20(assetToken).balanceOf(address(this));
        if (assetBalance > 0) {
            IERC20(assetToken).safeTransfer(msg.sender, assetBalance);
        }

        emit LogWithdraw(msg.sender, position_id, stableBalance, assetBalance);
    }

    function rebalance() external nonReentrant {}

    function reinvest() external nonReentrant {
        IUniswapV3Spell.ReinvestParams memory params = IUniswapV3Spell
            .ReinvestParams(0, 0, false, 0, 0, block.timestamp);
        uint256 position_id = positions[msg.sender];
        bank.execute(
            position_id,
            address(spell),
            abi.encodeWithSelector(IUniswapV3Spell.reinvest.selector, params)
        );
        emit LogReinvest(msg.sender, position_id);
    }

    function getHomoraPositionInfo(
        address user
    )
        public
        view
        returns (address collToken, uint256 collId, uint256 collateralSize)
    {
        (, collToken, collId, collateralSize) = bank.getPositionInfo(
            positions[user]
        );
    }

    function getUniV3PositionInfo(
        address user
    ) public view returns (IWUniswapV3Position.PositionInfo memory) {
        (, uint256 collId, uint256 collateralSize) = getHomoraPositionInfo(
            user
        );
        console.log("collId", collId);
        console.log("collateralSize", collateralSize);
        return wrapper.getPositionInfoFromTokenId(collId);
    }

    function getCollateralETHValue(address user) public view returns (uint256) {
        return bank.getCollateralETHValue(positions[user]);
    }

    function getBorrowETHValue(address user) public view returns (uint256) {
        return bank.getBorrowETHValue(positions[user]);
    }

    /// @notice Calculate the debt ratio as seen by Homora Bank, multiplied by 1e4
    function getDebtRatio(address user) public view returns (uint16) {
        return
            uint16(
                (getBorrowETHValue(user) * MAX_BPS) /
                    getCollateralETHValue(user)
            );
    }

    receive() external payable {}
}
