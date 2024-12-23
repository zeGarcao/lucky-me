// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {TwabController_Unit_Shared_Test} from "../../shared/TwabController.t.sol";
import {TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE} from "@lucky-me/utils/Errors.sol";
import {MIN_DEPOSIT, PERIOD_LENGTH, MAX_CARDINALITY} from "@lucky-me/utils/Constants.sol";
import {BalanceDecreased, ObservationRecorded} from "@lucky-me/utils/Events.sol";
import {Observation, AccountDetails} from "@lucky-me/utils/Structs.sol";
import {RingBufferLib} from "@lucky-me/libraries/RingBufferLib.sol";

contract DecreaseBalance_Unit_Fuzz_Test is TwabController_Unit_Shared_Test {
    address user;
    uint256 cardinality;

    // ================================== SETUP MODIFIERS ==================================

    modifier setUpState(uint256 _user, uint256 _decreaseAmount) {
        decreaseAmount = _clampBetween(_decreaseAmount, 1, 100_000_000e6);
        user = users[_clampBetween(_user, 0, users.length)];
        vm.startPrank(address(pool));
        _;
    }

    modifier whenBalanceIsInsufficient(uint256 _increaseAmount) {
        twabController.increaseBalance(user, _clampBetween(_increaseAmount, 1, decreaseAmount));
        _;
    }

    modifier whenBalanceIsSufficient(uint256 _cardinality, uint256 _increaseAmount) {
        cardinality = _cardinality;
        increaseAmount = _clampBetween(_increaseAmount, 1, 100_000_000e6);
        vm.assume(decreaseAmount <= (increaseAmount * cardinality));
        _;
    }

    modifier whenCardinalityBelowMax() {
        for (uint256 i; i < cardinality; ++i) {
            twabController.increaseBalance(user, increaseAmount);
            if (i != cardinality - 1) skip(PERIOD_LENGTH);
        }
        _;
    }

    modifier whenNewPeriod(uint256 _skip) {
        skipLength = _clampBetween(_skip, PERIOD_LENGTH, PERIOD_LENGTH * 100);
        skip(skipLength);
        _;
    }

    modifier whenNotNewPeriod(uint256 _skip) {
        skipLength = _clampBetween(_skip, 0, PERIOD_LENGTH);
        skip(skipLength);
        _;
    }

    modifier whenMaxCardinality() {
        for (uint256 i; i < cardinality; ++i) {
            twabController.increaseBalance(user, increaseAmount);
            if (i != cardinality - 1) skip(PERIOD_LENGTH);
        }
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function testFuzz_RevertWhen_InsufficientBalance(uint256 _user, uint256 _decreaseAmount, uint256 _increaseAmount)
        public
        setUpState(_user, _decreaseAmount)
        whenBalanceIsInsufficient(_increaseAmount)
    {
        // Expect revert with `TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE` error
        vm.expectRevert(TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE.selector);
        twabController.decreaseBalance(user, decreaseAmount);
    }

    // ==================================== HAPPY TESTS ====================================

    function testFuzz_DecreaseBalance_NewPeriodWithCardinalityBelowMax(
        uint256 _user,
        uint256 _decreaseAmount,
        uint256 _cardinality,
        uint256 _increaseAmount,
        uint256 _skip
    )
        public
        setUpState(_user, _decreaseAmount)
        whenBalanceIsSufficient(_clampBetween(_cardinality, 1, MAX_CARDINALITY), _increaseAmount)
        whenCardinalityBelowMax
        whenNewPeriod(_skip)
    {
        // Get user account before decrease balance
        AccountDetails memory accountBefore = twabController.getAccount(user);
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
        emit BalanceDecreased(user, decreaseAmount, expectedNewBalance, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewBalance,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(user, observation, true);

        // Decrease balance
        uint256 newBalance = twabController.decreaseBalance(user, decreaseAmount);
        assertEq(newBalance, expectedNewBalance);

        // **** ACCOUNT UPDATE ****
        AccountDetails memory accountAfter = twabController.getAccount(user);

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

    function testFuzz_DecreaseBalance_NotNewPeriodWithCardinalityBelowMax(
        uint256 _user,
        uint256 _decreaseAmount,
        uint256 _cardinality,
        uint256 _increaseAmount,
        uint256 _skip
    )
        public
        setUpState(_user, _decreaseAmount)
        whenBalanceIsSufficient(_clampBetween(_cardinality, 1, MAX_CARDINALITY), _increaseAmount)
        whenCardinalityBelowMax
        whenNotNewPeriod(_skip)
    {
        // Get user account before decrease balance
        AccountDetails memory accountBefore = twabController.getAccount(user);
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
        emit BalanceDecreased(user, decreaseAmount, expectedNewBalance, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewBalance,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(user, observation, false);

        // Decrease balance
        uint256 newBalance = twabController.decreaseBalance(user, decreaseAmount);
        assertEq(newBalance, expectedNewBalance);

        // **** ACCOUNT UPDATE ****
        AccountDetails memory accountAfter = twabController.getAccount(user);

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

    function testFuzz_DecreaseBalance_NewPeriodWithMaxCardinality(
        uint256 _user,
        uint256 _decreaseAmount,
        uint256 _increaseAmount,
        uint256 _skip
    )
        public
        setUpState(_user, _decreaseAmount)
        whenBalanceIsSufficient(MAX_CARDINALITY, _increaseAmount)
        whenMaxCardinality
        whenNewPeriod(_skip)
    {
        // Get user account before decrease balance
        AccountDetails memory accountBefore = twabController.getAccount(user);
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
        emit BalanceDecreased(user, decreaseAmount, expectedNewBalance, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewBalance,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(user, observation, true);

        // Decrease balance
        uint256 newBalance = twabController.decreaseBalance(user, decreaseAmount);
        assertEq(newBalance, expectedNewBalance);

        // **** ACCOUNT UPDATE ****
        AccountDetails memory accountAfter = twabController.getAccount(user);

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
