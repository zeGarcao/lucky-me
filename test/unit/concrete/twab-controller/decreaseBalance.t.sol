// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {TwabController_Unit_Shared_Test} from "../../shared/TwabController.t.sol";

import {
    TWAB_DECREASE_BALANCE__INVALID_AMOUNT,
    TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE
} from "@lucky-me/utils/Errors.sol";
import {MIN_DEPOSIT, PERIOD_LENGTH, MAX_CARDINALITY} from "@lucky-me/utils/Constants.sol";
import {BalanceDecreased, ObservationRecorded} from "@lucky-me/utils/Events.sol";
import {Observation, AccountDetails} from "@lucky-me/utils/Structs.sol";
import {RingBufferLib} from "@lucky-me/libraries/RingBufferLib.sol";

contract DecreaseBalance_Unit_Concrete_Test is TwabController_Unit_Shared_Test {
    // ================================== SETUP MODIFIERS ==================================

    modifier whenNotOwner() {
        vm.startPrank(bob);
        _;
    }

    modifier whenOwner() {
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
        twabController.increaseBalance(bob, decreaseAmount - 1);
        _;
    }

    modifier whenBalanceIsSufficient() {
        increaseAmount = decreaseAmount * 2;
        _;
    }

    modifier whenCardinalityBelowMax() {
        twabController.increaseBalance(bob, increaseAmount);
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
            twabController.increaseBalance(bob, increaseAmount);
            if (i != MAX_CARDINALITY - 1) skip(PERIOD_LENGTH);
        }
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_CallerIsNotOwner() public whenNotOwner {
        // Expect revert when caller is not the owner
        vm.expectRevert();
        twabController.decreaseBalance(bob, decreaseAmount);
    }

    function test_RevertWhen_AmountIsZero() public whenOwner whenAmountIsZero {
        // Expect revert with `TWAB_DECREASE_BALANCE__INVALID_AMOUNT` error
        vm.expectRevert(TWAB_DECREASE_BALANCE__INVALID_AMOUNT.selector);
        twabController.decreaseBalance(bob, decreaseAmount);
    }

    function test_RevertWhen_InsufficientBalance() public whenOwner whenAmountIsNotZero whenBalanceIsInsufficient {
        // Expect revert with `TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE` error
        vm.expectRevert(TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE.selector);
        twabController.decreaseBalance(bob, decreaseAmount);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_DecreaseBalance_NewPeriodWithCardinalityBelowMax()
        public
        whenOwner
        whenAmountIsNotZero
        whenBalanceIsSufficient
        whenCardinalityBelowMax
        whenNewPeriod
    {
        // Get user account before decrease balance
        AccountDetails memory accountBefore = twabController.getAccount(bob);
        // Compute expected new balance
        uint256 expectedNewBalance = accountBefore.balance - decreaseAmount;
        // Get newest observation index
        uint256 accountNewestIndexBefore =
            RingBufferLib.newestIndex(accountBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = accountBefore.observations[accountNewestIndexBefore].cumulativeBalance
            + accountBefore.observations[accountNewestIndexBefore].balance * skipLength;

        // Expect the `BalanceDecreased` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit BalanceDecreased(bob, decreaseAmount, expectedNewBalance, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewBalance,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(bob, observation, true);

        // Decrease balance
        uint256 newBalance = twabController.decreaseBalance(bob, decreaseAmount);
        assertEq(newBalance, expectedNewBalance);

        // **** ACCOUNT UPDATE ****
        AccountDetails memory accountAfter = twabController.getAccount(bob);

        // Asserting that the account balance was updated
        assertEq(accountAfter.balance, expectedNewBalance);
        // Asserting that the account next observation index was updated
        assertEq(accountAfter.nextObservationIndex, accountBefore.nextObservationIndex + 1);
        // Asserting that the account cardinality was updated
        assertEq(accountAfter.cardinality, accountBefore.cardinality + 1);
        // Asserting that a new observation was recorded
        uint256 accountNewestIndexAfter = RingBufferLib.newestIndex(accountAfter.nextObservationIndex, MAX_CARDINALITY);
        assertEq(accountNewestIndexAfter, accountNewestIndexBefore + 1);
        // Asserting that the new observation balance was updated
        assertEq(accountAfter.observations[accountNewestIndexAfter].balance, accountAfter.balance);
        // Asserting that the new observation cumulative balance was updated
        assertEq(accountAfter.observations[accountNewestIndexAfter].cumulativeBalance, expectedCumulativeBalance);
        // Asserting that the new observation timestamp was updated
        assertEq(accountAfter.observations[accountNewestIndexAfter].timestamp, block.timestamp);
    }

    function test_DecreaseBalance_NotNewPeriodWithCardinalityBelowMax()
        public
        whenOwner
        whenAmountIsNotZero
        whenBalanceIsSufficient
        whenCardinalityBelowMax
        whenNotNewPeriod
    {
        // Get user account before decrease balance
        AccountDetails memory accountBefore = twabController.getAccount(bob);
        // Compute expected new balance
        uint256 expectedNewBalance = accountBefore.balance - decreaseAmount;
        // Get newest observation index
        uint256 accountNewestIndexBefore =
            RingBufferLib.newestIndex(accountBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = accountBefore.observations[accountNewestIndexBefore].cumulativeBalance
            + accountBefore.observations[accountNewestIndexBefore].balance * skipLength;

        // Expect the `BalanceDecreased` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit BalanceDecreased(bob, decreaseAmount, expectedNewBalance, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewBalance,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(bob, observation, false);

        // Decrease balance
        uint256 newBalance = twabController.decreaseBalance(bob, decreaseAmount);
        assertEq(newBalance, expectedNewBalance);

        // **** ACCOUNT UPDATE ****
        AccountDetails memory accountAfter = twabController.getAccount(bob);

        // Asserting that the account balance was updated
        assertEq(accountAfter.balance, expectedNewBalance);
        // Asserting that the account next observation remained the same
        assertEq(accountAfter.nextObservationIndex, accountBefore.nextObservationIndex);
        // Asserting that the account cardinality remained the same
        assertEq(accountAfter.cardinality, accountBefore.cardinality);
        // Asserting that the last observation was overridden
        uint256 accountNewestIndexAfter = RingBufferLib.newestIndex(accountAfter.nextObservationIndex, MAX_CARDINALITY);
        assertEq(accountNewestIndexAfter, accountNewestIndexBefore);
        // Asserting that the new observation balance was updated
        assertEq(accountAfter.observations[accountNewestIndexAfter].balance, accountAfter.balance);
        // Asserting that the new observation cumulative balance was updated
        assertEq(accountAfter.observations[accountNewestIndexAfter].cumulativeBalance, expectedCumulativeBalance);
        // Asserting that the new observation timestamp was updated
        assertEq(accountAfter.observations[accountNewestIndexAfter].timestamp, block.timestamp);
    }

    function test_DecreaseBalance_NewPeriodWithMaxCardinality()
        public
        whenOwner
        whenAmountIsNotZero
        whenBalanceIsSufficient
        whenMaxCardinality
        whenNewPeriod
    {
        // Get user account before decrease balance
        AccountDetails memory accountBefore = twabController.getAccount(bob);
        // Compute expected new balance
        uint256 expectedNewBalance = accountBefore.balance - decreaseAmount;
        // Get newest observation index
        uint256 accountNewestIndexBefore =
            RingBufferLib.newestIndex(accountBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = accountBefore.observations[accountNewestIndexBefore].cumulativeBalance
            + accountBefore.observations[accountNewestIndexBefore].balance * skipLength;

        // Expect the `BalanceDecreased` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit BalanceDecreased(bob, decreaseAmount, expectedNewBalance, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewBalance,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(bob, observation, true);

        // Decrease balance
        uint256 newBalance = twabController.decreaseBalance(bob, decreaseAmount);
        assertEq(newBalance, expectedNewBalance);

        // **** ACCOUNT UPDATE ****
        AccountDetails memory accountAfter = twabController.getAccount(bob);

        // Asserting that the account balance was updated
        assertEq(accountAfter.balance, expectedNewBalance);
        // Asserting that the account next observation index was updated
        assertEq(accountAfter.nextObservationIndex, 1);
        // Asserting that the account cardinality remained `MAX_CARDINALITY`
        assertEq(accountAfter.cardinality, MAX_CARDINALITY);
        // Asserting that a new observation was recorded at the first index
        uint256 accountNewestIndexAfter = RingBufferLib.newestIndex(accountAfter.nextObservationIndex, MAX_CARDINALITY);
        assertEq(accountNewestIndexAfter, 0);
        // Asserting that the new observation balance was updated
        assertEq(accountAfter.observations[accountNewestIndexAfter].balance, accountAfter.balance);
        // Asserting that the new observation cumulative balance was updated
        assertEq(accountAfter.observations[accountNewestIndexAfter].cumulativeBalance, expectedCumulativeBalance);
        // Asserting that the new observation timestamp was updated
        assertEq(accountAfter.observations[accountNewestIndexAfter].timestamp, block.timestamp);
    }
}
