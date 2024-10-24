// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {TwabController_Unit_Shared_Test} from "../../shared/TwabController.t.sol";

import {INCREASE_BALANCE__INVALID_AMOUNT} from "@lucky-me/utils/Errors.sol";
import {BalanceIncreased, ObservationRecorded} from "@lucky-me/utils/Events.sol";
import {Observation, AccountDetails} from "@lucky-me/utils/Structs.sol";
import {MAX_CARDINALITY, PERIOD_LENGTH, MIN_DEPOSIT} from "@lucky-me/utils/Constants.sol";
import {RingBufferLib} from "@lucky-me/libraries/RingBufferLib.sol";

contract IncreaseBalance_Unit_Concrete_Test is TwabController_Unit_Shared_Test {
    uint256 increaseAmount;
    uint256 skipLength;

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
        increaseAmount = 0;
        _;
    }

    modifier whenAmountIsNotZero() {
        increaseAmount = MIN_DEPOSIT;
        _;
    }

    modifier whenCardinalityIsZero() {
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
        twabController.increaseBalance(bob, increaseAmount);
    }

    function test_RevertWhen_AmountIsZero() public whenOwner whenAmountIsZero {
        // Expect revert with `INCREASE_BALANCE__INVALID_AMOUNT` error
        vm.expectRevert(INCREASE_BALANCE__INVALID_AMOUNT.selector);
        twabController.increaseBalance(bob, increaseAmount);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_IncreaseBalance_ZeroCardinality() public whenOwner whenAmountIsNotZero whenCardinalityIsZero {
        // Expect the `BalanceIncreased` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit BalanceIncreased(bob, increaseAmount, increaseAmount, block.timestamp);
        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation =
            Observation({balance: increaseAmount, cumulativeBalance: 0, timestamp: block.timestamp});
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(bob, observation, true);

        // Increase balance
        uint256 newBalance = twabController.increaseBalance(bob, increaseAmount);
        // Asserting that the returning new balance is correct
        assertEq(newBalance, increaseAmount);

        // **** ACCOUNT UPDATE ****
        AccountDetails memory account = twabController.getAccount(bob);

        // Asserting that the account balance was updated
        assertEq(account.balance, increaseAmount);
        // Asserting that the account next observation index was updated
        assertEq(account.nextObservationIndex, 1);
        // Asserting that the account cardinality was updated
        assertEq(account.cardinality, 1);
        // Asserting that a new observation was recorded
        uint256 accountNewestIndex = RingBufferLib.newestIndex(account.nextObservationIndex, MAX_CARDINALITY);
        assertEq(accountNewestIndex, 0);
        // Asserting that the new observation balance was updated
        assertEq(account.observations[0].balance, account.balance);
        // Asserting that the new observation cumulative balance was updated
        assertEq(account.observations[0].cumulativeBalance, 0);
        // Asserting that the new observation timestamp was updated
        assertEq(account.observations[0].timestamp, block.timestamp);
    }

    function test_IncreaseBalance_NewPeriodWithCardinalityBelowMax()
        public
        whenOwner
        whenAmountIsNotZero
        whenCardinalityBelowMax
        whenNewPeriod
    {
        // Get user account before increase balance
        AccountDetails memory accountBefore = twabController.getAccount(bob);
        // Compute expected new balance
        uint256 expectedNewBalance = accountBefore.balance + increaseAmount;
        // Get newest observation index
        uint256 accountNewestIndexBefore =
            RingBufferLib.newestIndex(accountBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = accountBefore.observations[accountNewestIndexBefore].cumulativeBalance
            + accountBefore.observations[accountNewestIndexBefore].balance * skipLength;

        // Expect the `BalanceIncreased` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit BalanceIncreased(bob, increaseAmount, expectedNewBalance, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewBalance,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(bob, observation, true);

        // Increase balance
        uint256 newBalance = twabController.increaseBalance(bob, increaseAmount);
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

    function test_IncreaseBalance_NotNewPeriodWithCardinalityBelowMax()
        public
        whenOwner
        whenAmountIsNotZero
        whenCardinalityBelowMax
        whenNotNewPeriod
    {
        // Get user account before increase balance
        AccountDetails memory accountBefore = twabController.getAccount(bob);
        // Compute expected new balance
        uint256 expectedNewBalance = accountBefore.balance + increaseAmount;
        // Get newest observation index
        uint256 accountNewestIndexBefore =
            RingBufferLib.newestIndex(accountBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = accountBefore.observations[accountNewestIndexBefore].cumulativeBalance
            + accountBefore.observations[accountNewestIndexBefore].balance * skipLength;

        // Expect the `BalanceIncreased` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit BalanceIncreased(bob, increaseAmount, expectedNewBalance, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewBalance,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(bob, observation, false);

        // Increase balance
        uint256 newBalance = twabController.increaseBalance(bob, increaseAmount);
        assertEq(newBalance, expectedNewBalance);

        // **** ACCOUNT UPDATE ****
        AccountDetails memory accountAfter = twabController.getAccount(bob);

        // Asserting that the account balance was updated
        assertEq(accountAfter.balance, expectedNewBalance);
        // Asserting that the account next observation index remained the same
        assertEq(accountAfter.nextObservationIndex, accountBefore.nextObservationIndex);
        // Asserting that the account cardinality remained the same
        assertEq(accountAfter.cardinality, accountBefore.cardinality);
        // Asserting that the last observation was overridden
        uint256 accountNewestIndexAfter = RingBufferLib.newestIndex(accountAfter.nextObservationIndex, MAX_CARDINALITY);
        assertEq(accountNewestIndexAfter, accountNewestIndexBefore);
        // Asserting that the overridden observation balance was updated
        assertEq(accountAfter.observations[accountNewestIndexAfter].balance, accountAfter.balance);
        // Asserting that the overridden observation cumulative balance was updated
        assertEq(accountAfter.observations[accountNewestIndexAfter].cumulativeBalance, expectedCumulativeBalance);
        // Asserting that the overridden observation timestamp was updated
        assertEq(accountAfter.observations[accountNewestIndexAfter].timestamp, block.timestamp);
    }

    function test_IncreaseBalance_NewPeriodWithMaxCardinality()
        public
        whenOwner
        whenAmountIsNotZero
        whenMaxCardinality
        whenNewPeriod
    {
        // Get user account before increase balance
        AccountDetails memory accountBefore = twabController.getAccount(bob);
        // Compute expected new balance
        uint256 expectedNewBalance = accountBefore.balance + increaseAmount;
        // Get newest observation index
        uint256 accountNewestIndexBefore =
            RingBufferLib.newestIndex(accountBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = accountBefore.observations[accountNewestIndexBefore].cumulativeBalance
            + accountBefore.observations[accountNewestIndexBefore].balance * skipLength;

        // Expect the `BalanceIncreased` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit BalanceIncreased(bob, increaseAmount, expectedNewBalance, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewBalance,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(bob, observation, true);

        // Increase balance
        uint256 newBalance = twabController.increaseBalance(bob, increaseAmount);
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
