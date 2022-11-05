// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.16 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "../interfaces/IHomoraPDN.sol";
import "../interfaces/uniswapv3/IUniswapV3Pool.sol";

library VaultLib {
    using SafeERC20 for IERC20;
    using Math for uint256;

    uint256 public constant X96 = 2**96;


    function uniSqrtPriceX96(IUniswapV3Pool pool) internal view returns (uint160 sqrtPriceX96) {
        (sqrtPriceX96, , , , , , ) = pool.slot0();
    }

    function mulSquareX96(uint256 amount, uint160 sqrtPriceBx96) internal pure returns (uint256) {
        return amount.mulDiv(sqrtPriceBx96.mulDiv(sqrtPriceBx96, ));
    }

    function deltaNeutralMath(
        IHomoraPDN.PairInfo memory pairInfo,
        uint256 amtAUser,
        uint256 amtBUser,
        uint256 L
    ) internal view returns (uint256) {
        IUniswapV3Pool pool = IUniswapV3Pool(pairInfo.lpToken);
        uint160 sqrtPriceBx96 = uniSqrtPriceX96(pool);
        uint256 equity = amtAUser;
        if (pairInfo.stableToken == pool.token0()) {
            equity += priceB * amtBUser;
        }
        uint256 amtABorrow;
        uint256 amtBBorrow;

    }
}
