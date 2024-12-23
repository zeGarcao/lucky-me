// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {TwabController_Unit_Shared_Test} from "../../shared/TwabController.t.sol";
import {TWAB_CREDIT_BALANCE__INVALID_AMOUNT} from "@lucky-me/utils/Errors.sol";
import {BalanceCredited, ObservationRecorded} from "@lucky-me/utils/Events.sol";
import {Observation, AccountDetails} from "@lucky-me/utils/Structs.sol";
import {MAX_CARDINALITY, PERIOD_LENGTH, MIN_DEPOSIT} from "@lucky-me/utils/Constants.sol";
import {RingBufferLib} from "@lucky-me/libraries/RingBufferLib.sol";

contract CreditBalance_Unit_Fuzz_Test is TwabController_Unit_Shared_Test {
    address user;

    // ================================== SETUP MODIFIERS ==================================

    modifier setUpState(uint256 _user, uint256 _increaseAmount) {
        user = users[_clampBetween(_user, 0, users.length)];
        increaseAmount = _clampBetween(_increaseAmount, 1, 100_000_000e6);
        vm.startPrank(address(pool));
        _;
    }

    modifier whenCardinalityIsZero() {
        _;
    }

    modifier whenCardinalityBelowMax(uint256 _cardinality) {
        uint256 cardinality = _clampBetween(_cardinality, 1, MAX_CARDINALITY);
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
        for (uint256 i; i < MAX_CARDINALITY; ++i) {
            twabController.increaseBalance(user, increaseAmount);
            if (i != MAX_CARDINALITY - 1) skip(PERIOD_LENGTH);
        }
        _;
    }

    // ==================================== HAPPY TESTS ====================================

    function testFuzz_CreditBalance_ZeroCardinality(uint256 _user, uint256 _increaseAmount)
        public
        setUpState(_user, _increaseAmount)
    {
        // Expect the `BalanceCredited` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit BalanceCredited(user, increaseAmount, increaseAmount, block.timestamp);
        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation =
            Observation({balance: increaseAmount, cumulativeBalance: 0, timestamp: block.timestamp});
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(user, observation, true);

        // Increase balance
        uint256 newBalance = twabController.creditBalance(user, increaseAmount);
        // Asserting that the returning new balance is correct
        assertEq(newBalance, increaseAmount);

        // **** ACCOUNT UPDATE ****
        AccountDetails memory account = twabController.getAccount(user);

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

    function testFuzz_CreditBalance_NewPeriodWithCardinalityBelowMax(
        uint256 _user,
        uint256 _increaseAmount,
        uint256 _cardinality,
        uint256 _skip
    ) public setUpState(_user, _increaseAmount) whenCardinalityBelowMax(_cardinality) whenNewPeriod(_skip) {
        // Get user account before increase balance
        AccountDetails memory accountBefore = twabController.getAccount(user);
        // Compute expected new balance
        uint256 expectedNewBalance = accountBefore.balance + increaseAmount;
        // Get newest observation index
        uint256 accountNewestIndexBefore =
            RingBufferLib.newestIndex(accountBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = accountBefore.observations[accountNewestIndexBefore].cumulativeBalance
            + accountBefore.observations[accountNewestIndexBefore].balance * skipLength;

        // Expect the `BalanceCredited` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit BalanceCredited(user, increaseAmount, expectedNewBalance, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewBalance,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(user, observation, true);

        // Increase balance
        uint256 newBalance = twabController.creditBalance(user, increaseAmount);
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

    function test_CreditBalance_NotNewPeriodWithCardinalityBelowMax(
        uint256 _user,
        uint256 _increaseAmount,
        uint256 _cardinality,
        uint256 _skip
    ) public setUpState(_user, _increaseAmount) whenCardinalityBelowMax(_cardinality) whenNotNewPeriod(_skip) {
        // Get user account before increase balance
        AccountDetails memory accountBefore = twabController.getAccount(user);
        // Compute expected new balance
        uint256 expectedNewBalance = accountBefore.balance + increaseAmount;
        // Get newest observation index
        uint256 accountNewestIndexBefore =
            RingBufferLib.newestIndex(accountBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = accountBefore.observations[accountNewestIndexBefore].cumulativeBalance
            + accountBefore.observations[accountNewestIndexBefore].balance * skipLength;

        // Expect the `BalanceCredited` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit BalanceCredited(user, increaseAmount, expectedNewBalance, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewBalance,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(user, observation, false);

        // Increase balance
        uint256 newBalance = twabController.creditBalance(user, increaseAmount);
        assertEq(newBalance, expectedNewBalance);

        // **** ACCOUNT UPDATE ****
        AccountDetails memory accountAfter = twabController.getAccount(user);

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

    function test_CreditBalance_NewPeriodWithMaxCardinality(uint256 _user, uint256 _increaseAmount, uint256 _skip)
        public
        setUpState(_user, _increaseAmount)
        whenMaxCardinality
        whenNewPeriod(_skip)
    {
        // Get user account before increase balance
        AccountDetails memory accountBefore = twabController.getAccount(user);
        // Compute expected new balance
        uint256 expectedNewBalance = accountBefore.balance + increaseAmount;
        // Get newest observation index
        uint256 accountNewestIndexBefore =
            RingBufferLib.newestIndex(accountBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = accountBefore.observations[accountNewestIndexBefore].cumulativeBalance
            + accountBefore.observations[accountNewestIndexBefore].balance * skipLength;

        // Expect the `BalanceCredited` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit BalanceCredited(user, increaseAmount, expectedNewBalance, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewBalance,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(user, observation, true);

        // Increase balance
        uint256 newBalance = twabController.creditBalance(user, increaseAmount);
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
