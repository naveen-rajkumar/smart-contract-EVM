/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: Apache-2.0
*/

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./JOJOStorage.sol";
import "../intf/IDealer.sol";
import "../lib/Liquidation.sol";
import "../lib/Trading.sol";
import "../utils/Errors.sol";

abstract contract JOJOView is JOJOStorage, IDealer {
    // ========== simple read state ==========

    function getPrimaryAsset() external view returns (address) {
        return state.primaryAsset;
    }

    function getSecondaryAsset() external view returns (address) {
        return state.secondaryAsset;
    }

    /// @param perp the address of perpetual contract market
    function getRiskParams(address perp)
        external
        view
        returns (Types.RiskParams memory params)
    {
        params = state.perpRiskParams[perp];
    }

    /// @inheritdoc IDealer
    function getFundingRate(address perp)
        external
        view
        returns (int256)
    {
        return state.perpRiskParams[perp].fundingRate;
    }

    /// @notice Return all registered perpetual contract market
    function getRegisteredPerp() external view returns (address[] memory) {
        return state.registeredPerp;
    }

    /// @notice Get all open positions of a certain trader
    function getPositions(address trader)
        external
        view
        returns (address[] memory)
    {
        return state.openPositions[trader];
    }

    /// @notice Return a detailed credit info of a certain trader.
    /// You can not use credit as net value or net margin of a trader.
    /// The net value of positions should also be counted in.
    function getCreditOf(address trader)
        external
        view
        returns (
            int256 primaryCredit,
            uint256 secondaryCredit,
            uint256 pendingPrimaryWithdraw,
            uint256 pendingSecondaryWithdraw,
            uint256 executionTimestamp
        )
    {
        primaryCredit = state.primaryCredit[trader];
        secondaryCredit = state.secondaryCredit[trader];
        pendingPrimaryWithdraw = state.pendingPrimaryWithdraw[trader];
        pendingSecondaryWithdraw = state.pendingSecondaryWithdraw[trader];
        executionTimestamp = state.withdrawExecutionTimestamp[trader];
    }

    // ========== risk related ==========

    /// @inheritdoc IDealer
    function isSafe(address trader) external view returns (bool safe) {
        return Liquidation._isSafe(state, trader);
    }

    /// @inheritdoc IDealer
    function isPositionSafe(address trader, address perp)
        external
        view
        returns (bool safe)
    {
        (int256 paper, ) = IPerpetual(perp).balanceOf(trader);
        if (paper == 0) {
            return true;
        }
        return Liquidation._isPositionSafe(state, trader, perp);
    }

    /// @notice get risk related data of trader
    /// @return netValue net value of trader, count in credit
    /// @return exposure open position value of trader among all markets
    function getTraderRisk(address trader)
        external
        view
        returns (int256 netValue, uint256 exposure)
    {
        int256 positionNetValue;
        (positionNetValue, exposure, ) = Liquidation._getTotalExposure(
            state,
            trader
        );
        netValue =
            positionNetValue +
            state.primaryCredit[trader] +
            int256(state.secondaryCredit[trader]);
    }

    // ========== liquidation related ==========

    /// @notice get liquidation price of a position
    /// @dev this function should only be used as a reference. It has accuracy
    /// problems, usually less than 10 wei. 
    /// @return liquidationPrice equals 0 if there is no liquidation price.
    function getLiquidationPrice(address trader, address perp)
        external
        view
        returns (uint256 liquidationPrice)
    {
        // return 0 if the trader can not be liquidated
        return Liquidation._getLiquidationPrice(state, trader, perp);
    }

    /// @notice a view version of requestLiquidate, liquidators can use 
    /// this function to check how much you have to pay in advance.
    function getLiquidationCost(
        address perp,
        address liquidatedTrader,
        int256 requestPaperAmount
    )
        external
        view
        returns (int256 liqtorPaperChange, int256 liqtorCreditChange)
    {
        (liqtorPaperChange, liqtorCreditChange, ) = Liquidation
            ._getLiquidateCreditAmount(
                state,
                perp,
                liquidatedTrader,
                requestPaperAmount
            );
    }

    // ========== order related ==========

    /// @notice calculate order hash
    /// @dev use this function to check if your script 
    /// returns correct order hash
    function getOrderHash(Types.Order memory order)
        external
        view
        returns (bytes32 orderHash)
    {
        orderHash = Trading._getOrderHash(state.domainSeparator, order);
    }

    /// @notice get filled paper amount of an order. Avoid duplicate matching.
    /// @return filledAmount count in paper amount
    function getOrderFilledAmount(bytes32 orderHash)
        external
        view
        returns (uint256 filledAmount)
    {
        filledAmount = state.orderFilledPaperAmount[orderHash];
    }
}
