// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface IBaseOracle {
    /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
    /// @param token The ERC-20 token to check the value.
    function getETHPx(address token) external view returns (uint256);
}

interface IOracle {
    function source() external view returns (IBaseOracle);

    function tokenFactors(
        address token
    )
        external
        view
        returns (
            uint16 borrowFactor,
            uint16 collateralFactor,
            uint16 liqIncentive
        );

    /// @dev Return whether the ERC-20 token is supported
    /// @param token The ERC-20 token to check for support
    function support(address token) external view returns (bool);

    /// @dev Return whether the oracle supports evaluating collateral value of the given address.
    /// @param token The ERC-1155 token to check the acceptence.
    /// @param id The token id to check the acceptance.
    function supportWrappedToken(
        address token,
        uint256 id
    ) external view returns (bool);

    /// @dev Return the amount of token out as liquidation reward for liquidating token in.
    /// @param tokenIn The ERC-20 token that gets liquidated.
    /// @param tokenOut The ERC-1155 token to pay as reward.
    /// @param tokenOutId The id of the token to pay as reward.
    /// @param amountIn The amount of liquidating tokens.
    function convertForLiquidation(
        address tokenIn,
        address tokenOut,
        uint256 tokenOutId,
        uint256 amountIn
    ) external view returns (uint256);

    /// @dev Return the value of the given input as ETH for collateral purpose.
    /// @param token The ERC-1155 token to check the value.
    /// @param id The id of the token to check the value.
    /// @param amount The amount of tokens to check the value.
    /// @param owner The owner of the token to check for collateral credit.
    function asETHCollateral(
        address token,
        uint256 id,
        uint256 amount,
        address owner
    ) external view returns (uint256);

    /// @dev Return the value of the given input as ETH for borrow purpose.
    /// @param token The ERC-20 token to check the value.
    /// @param amount The amount of tokens to check the value.
    /// @param owner The owner of the token to check for borrow credit.
    function asETHBorrow(
        address token,
        uint256 amount,
        address owner
    ) external view returns (uint256);
}
