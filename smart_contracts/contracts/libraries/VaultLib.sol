// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.16 <0.9.0;

import "@openzeppelin/contracts/utils/math/Math.sol";

import "../interfaces/IHomoraPDN.sol";

library VaultLib {
    using SafeERC20 for IERC20;
    using Math for uint256;

    function deltaNeutralMath(
        IHomoraPDN.PairInfo memory pairInfo,
        uint256 Ua,
        uint256 Ub,
        uint256 L
    ) internal view returns (uint) {

    }
}
