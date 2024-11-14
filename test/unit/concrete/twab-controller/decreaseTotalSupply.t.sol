// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {TwabController_Unit_Shared_Test} from "../../shared/TwabController.t.sol";
import {MIN_DEPOSIT, MAX_CARDINALITY, PERIOD_LENGTH} from "@lucky-me/utils/Constants.sol";
import {
    TWAB_DECREASE_TOTAL_SUPPLY__INVALID_AMOUNT,
    TWAB_DECREASE_TOTAL_SUPPLY__INSUFFICIENT_BALANCE
} from "@lucky-me/utils/Errors.sol";
import {TotalSupplyDecreased, ObservationRecorded} from "@lucky-me/utils/Events.sol";
import {RingBufferLib} from "@lucky-me/libraries/RingBufferLib.sol";
import {AccountDetails, Observation} from "@lucky-me/utils/Structs.sol";

contract DecreaseTotalSupply_Unit_Concrete_Test is TwabController_Unit_Shared_Test {
    // ================================== SETUP MODIFIERS ==================================

    modifier whenCallerIsNotOwner() {
        vm.startPrank(rando);
        _;
    }

    modifier whenCallerIsOwner() {
        vm.startPrank(address(pool));
        _;
    }

    modifier whenAmountIsZero() {
        decreaseAmount = 0;
        _;
    }

    modifier whenAmountIsNotZero() {
        decreaseAmount = MIN_DEPOSIT;
        _;
    }

    modifier whenBalanceIsInsufficient() {
        twabController.increaseTotalSupply(decreaseAmount - 1);
        _;
    }

    modifier whenBalanceIsSufficient() {
        increaseAmount = decreaseAmount * 2;
        _;
    }

    modifier whenCardinalityBelowMax() {
        twabController.increaseTotalSupply(increaseAmount);
        _;
    }

    modifier whenNewPeriod() {
        skipLength = PERIOD_LENGTH;
        skip(skipLength);
        _;
    }

    modifier whenNotNewPeriod() {
        skipLength = PERIOD_LENGTH / 2;
        skip(skipLength);
        _;
    }

    modifier whenMaxCardinality() {
        for (uint256 i; i < MAX_CARDINALITY; ++i) {
            skip(PERIOD_LENGTH);
            twabController.increaseTotalSupply(increaseAmount);
        }
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_CallerIsNotOwner() public whenCallerIsNotOwner {
        vm.expectRevert();
        twabController.decreaseTotalSupply(decreaseAmount);
    }

    function test_RevertWhen_ZeroAmount() public whenCallerIsOwner whenAmountIsZero {
        vm.expectRevert(TWAB_DECREASE_TOTAL_SUPPLY__INVALID_AMOUNT.selector);
        twabController.decreaseTotalSupply(decreaseAmount);
    }

    function test_RevertWhen_InsufficientBalance()
        public
        whenCallerIsOwner
        whenAmountIsNotZero
        whenBalanceIsInsufficient
    {
        vm.expectRevert(TWAB_DECREASE_TOTAL_SUPPLY__INSUFFICIENT_BALANCE.selector);
        twabController.decreaseTotalSupply(decreaseAmount);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_DecreaseTotalSupply_NewPeriodWithCardinalityBelowMax()
        public
        whenCallerIsOwner
        whenAmountIsNotZero
        whenBalanceIsSufficient
        whenCardinalityBelowMax
        whenNewPeriod
    {
        // Get total supply account before decrease balance
        AccountDetails memory totalSupplyBefore = twabController.getTotalSupplyAccount();
        // Compute expected new total supply
        uint256 expectedNewTotalSupply = totalSupplyBefore.balance - decreaseAmount;
        // Get newest observation index
        uint256 totalSupplyNewestIndexBefore =
            RingBufferLib.newestIndex(totalSupplyBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = totalSupplyBefore.observations[totalSupplyNewestIndexBefore]
            .cumulativeBalance + totalSupplyBefore.observations[totalSupplyNewestIndexBefore].balance * skipLength;

        // Expect the `TotalSupplyDecreased` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit TotalSupplyDecreased(decreaseAmount, expectedNewTotalSupply, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewTotalSupply,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(address(0), observation, true);

        // Decrease total supply
        uint256 newTotalSupply = twabController.decreaseTotalSupply(decreaseAmount);
        assertEq(newTotalSupply, expectedNewTotalSupply);

        // **** TOTAL SUPPLY UPDATE ****
        AccountDetails memory totalSupplyAfter = twabController.getTotalSupplyAccount();

        // Asserting that the total supply balance was updated
        assertEq(totalSupplyAfter.balance, expectedNewTotalSupply);
        // Asserting that the total supply next observation index was updated
        assertEq(totalSupplyAfter.nextObservationIndex, totalSupplyBefore.nextObservationIndex + 1);
        // Asserting that the total supply cardinality was updated
        assertEq(totalSupplyAfter.cardinality, totalSupplyBefore.cardinality + 1);
        // Asserting that a new observation was recorded
        uint256 totalSupplyNewestIndexAfter =
            RingBufferLib.newestIndex(totalSupplyAfter.nextObservationIndex, MAX_CARDINALITY);
        assertEq(totalSupplyNewestIndexAfter, totalSupplyNewestIndexBefore + 1);
        // Asserting that the new observation balance was updated
        assertEq(totalSupplyAfter.observations[totalSupplyNewestIndexAfter].balance, totalSupplyAfter.balance);
        // Asserting that the new observation cumulative balance was updated
        assertEq(
            totalSupplyAfter.observations[totalSupplyNewestIndexAfter].cumulativeBalance, expectedCumulativeBalance
        );
        // Asserting that the new observation timestamp was updated
        assertEq(totalSupplyAfter.observations[totalSupplyNewestIndexAfter].timestamp, block.timestamp);
    }

    function test_DecreaseTotalSupply_NotNewPeriodWithCardinalityBelowMax()
        public
        whenCallerIsOwner
        whenAmountIsNotZero
        whenBalanceIsSufficient
        whenCardinalityBelowMax
        whenNotNewPeriod
    {
        // Get total supply account before decrease balance
        AccountDetails memory totalSupplyBefore = twabController.getTotalSupplyAccount();
        // Compute expected new total supply
        uint256 expectedNewTotalSupply = totalSupplyBefore.balance - decreaseAmount;
        // Get newest observation index
        uint256 totalSupplyNewestIndexBefore =
            RingBufferLib.newestIndex(totalSupplyBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = totalSupplyBefore.observations[totalSupplyNewestIndexBefore]
            .cumulativeBalance + totalSupplyBefore.observations[totalSupplyNewestIndexBefore].balance * skipLength;

        // Expect the `TotalSupplyDecreased` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit TotalSupplyDecreased(decreaseAmount, expectedNewTotalSupply, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewTotalSupply,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(address(0), observation, false);

        // Decrease total supply
        uint256 newTotalSupply = twabController.decreaseTotalSupply(decreaseAmount);
        assertEq(newTotalSupply, expectedNewTotalSupply);

        // **** TOTAL SUPPLY UPDATE ****
        AccountDetails memory totalSupplyAfter = twabController.getTotalSupplyAccount();

        // Asserting that the total supply balance was updated
        assertEq(totalSupplyAfter.balance, expectedNewTotalSupply);
        // Asserting that the total supply next observation index remained the same
        assertEq(totalSupplyAfter.nextObservationIndex, totalSupplyBefore.nextObservationIndex);
        // Asserting that the total supply cardinality remained the same
        assertEq(totalSupplyAfter.cardinality, totalSupplyBefore.cardinality);
        // Asserting that the last observation was overridden
        uint256 totalSupplyNewestIndexAfter =
            RingBufferLib.newestIndex(totalSupplyAfter.nextObservationIndex, MAX_CARDINALITY);
        assertEq(totalSupplyNewestIndexAfter, totalSupplyNewestIndexBefore);
        // Asserting that the new observation balance was updated
        assertEq(totalSupplyAfter.observations[totalSupplyNewestIndexAfter].balance, totalSupplyAfter.balance);
        // Asserting that the new observation cumulative balance was updated
        assertEq(
            totalSupplyAfter.observations[totalSupplyNewestIndexAfter].cumulativeBalance, expectedCumulativeBalance
        );
        // Asserting that the new observation timestamp was updated
        assertEq(totalSupplyAfter.observations[totalSupplyNewestIndexAfter].timestamp, block.timestamp);
    }

    function test_DecreaseTotalSupply_NewPeriodWithMaxCardinality()
        public
        whenCallerIsOwner
        whenAmountIsNotZero
        whenBalanceIsSufficient
        whenMaxCardinality
        whenNewPeriod
    {
        // Get total supply account before decrease balance
        AccountDetails memory totalSupplyBefore = twabController.getTotalSupplyAccount();
        // Compute expected new total supply
        uint256 expectedNewTotalSupply = totalSupplyBefore.balance - decreaseAmount;
        // Get newest observation index
        uint256 totalSupplyNewestIndexBefore =
            RingBufferLib.newestIndex(totalSupplyBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = totalSupplyBefore.observations[totalSupplyNewestIndexBefore]
            .cumulativeBalance + totalSupplyBefore.observations[totalSupplyNewestIndexBefore].balance * skipLength;

        // Expect the `TotalSupplyDecreased` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit TotalSupplyDecreased(decreaseAmount, expectedNewTotalSupply, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewTotalSupply,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(address(0), observation, true);

        // Decrease total supply
        uint256 newTotalSupply = twabController.decreaseTotalSupply(decreaseAmount);
        assertEq(newTotalSupply, expectedNewTotalSupply);

        // **** TOTAL SUPPLY UPDATE ****
        AccountDetails memory totalSupplyAfter = twabController.getTotalSupplyAccount();

        // Asserting that the total supply balance was updated
        assertEq(totalSupplyAfter.balance, expectedNewTotalSupply);
        // Asserting that the total supply next observation index was updated
        assertEq(totalSupplyAfter.nextObservationIndex, 1);
        // Asserting that the total supply cardinality remained the `MAX_CARDINALITY`
        assertEq(totalSupplyAfter.cardinality, MAX_CARDINALITY);
        // Asserting that a new observation was recorded at index 0
        uint256 totalSupplyNewestIndexAfter =
            RingBufferLib.newestIndex(totalSupplyAfter.nextObservationIndex, MAX_CARDINALITY);
        assertEq(totalSupplyNewestIndexAfter, 0);
        // Asserting that the new observation balance was updated
        assertEq(totalSupplyAfter.observations[totalSupplyNewestIndexAfter].balance, totalSupplyAfter.balance);
        // Asserting that the new observation cumulative balance was updated
        assertEq(
            totalSupplyAfter.observations[totalSupplyNewestIndexAfter].cumulativeBalance, expectedCumulativeBalance
        );
        // Asserting that the new observation timestamp was updated
        assertEq(totalSupplyAfter.observations[totalSupplyNewestIndexAfter].timestamp, block.timestamp);
    }
}
