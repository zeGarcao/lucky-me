// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {TwabController_Unit_Shared_Test} from "../../shared/TwabController.t.sol";
import {MIN_DEPOSIT, MAX_CARDINALITY, PERIOD_LENGTH} from "@lucky-me/utils/Constants.sol";
import {TWAB_INCREASE_TOTAL_SUPPLY__INVALID_AMOUNT} from "@lucky-me/utils/Errors.sol";
import {TotalSupplyIncreased, ObservationRecorded} from "@lucky-me/utils/Events.sol";
import {RingBufferLib} from "@lucky-me/libraries/RingBufferLib.sol";
import {AccountDetails, Observation} from "@lucky-me/utils/Structs.sol";

contract IncreaseTotalSupply_Unit_Fuzz_Test is TwabController_Unit_Shared_Test {
    // ================================== SETUP MODIFIERS ==================================

    modifier setUpState(uint256 _increaseAmount) {
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
            twabController.increaseTotalSupply(increaseAmount);
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
            twabController.increaseTotalSupply(increaseAmount);
            if (i != MAX_CARDINALITY - 1) skip(PERIOD_LENGTH);
        }
        _;
    }

    // ==================================== HAPPY TESTS ====================================

    function testFuzz_IncreaseTotalSupply_ZeroCardinality(uint256 _increaseAmount)
        public
        setUpState(_increaseAmount)
        whenCardinalityIsZero
    {
        // Get total supply account before increase balance
        AccountDetails memory accountBefore = twabController.getTotalSupplyAccount();
        // Compute expected new total supply
        uint256 expectedNewTotalSupply = accountBefore.balance + increaseAmount;
        // Get newest observation index
        uint256 accountNewestIndexBefore =
            RingBufferLib.newestIndex(accountBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = accountBefore.observations[accountNewestIndexBefore].cumulativeBalance
            + accountBefore.observations[accountNewestIndexBefore].balance * skipLength;

        // Expect the `TotalSupplyIncreased` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit TotalSupplyIncreased(increaseAmount, expectedNewTotalSupply, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewTotalSupply,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(address(0), observation, true);

        // Increase total supply
        uint256 newTotalSupply = twabController.increaseTotalSupply(increaseAmount);
        assertEq(newTotalSupply, expectedNewTotalSupply);

        // **** TOTAL SUPPLY UPDATE ****
        AccountDetails memory totalSupply = twabController.getTotalSupplyAccount();

        // Asserting that the total supply balance was updated
        assertEq(totalSupply.balance, expectedNewTotalSupply);
        // Asserting that the total supply next observation index was updated
        assertEq(totalSupply.nextObservationIndex, 1);
        // Asserting that the total supply cardinality was updated
        assertEq(totalSupply.cardinality, 1);
        // Asserting that a new observation was recorded
        uint256 totalSupplyNewestIndex = RingBufferLib.newestIndex(totalSupply.nextObservationIndex, MAX_CARDINALITY);
        assertEq(totalSupplyNewestIndex, 0);
        // Asserting that the new observation balance was updated
        assertEq(totalSupply.observations[0].balance, totalSupply.balance);
        // Asserting that the new observation cumulative balance was updated
        assertEq(totalSupply.observations[0].cumulativeBalance, 0);
        // Asserting that the new observation timestamp was updated
        assertEq(totalSupply.observations[0].timestamp, block.timestamp);
    }

    function testFuzz_IncreaseTotalSupply_NewPeriodWithCardinalityBelowMax(
        uint256 _increaseAmount,
        uint256 _cardinality,
        uint256 _skip
    ) public setUpState(_increaseAmount) whenCardinalityBelowMax(_cardinality) whenNewPeriod(_skip) {
        // Get total supply account before increase balance
        AccountDetails memory totalSupplyBefore = twabController.getTotalSupplyAccount();
        // Compute expected new total supply
        uint256 expectedNewTotalSupply = totalSupplyBefore.balance + increaseAmount;
        // Get newest observation index
        uint256 totalSupplyNewestIndexBefore =
            RingBufferLib.newestIndex(totalSupplyBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = totalSupplyBefore.observations[totalSupplyNewestIndexBefore]
            .cumulativeBalance + totalSupplyBefore.observations[totalSupplyNewestIndexBefore].balance * skipLength;

        // Expect the `TotalSupplyIncreased` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit TotalSupplyIncreased(increaseAmount, expectedNewTotalSupply, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewTotalSupply,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(address(0), observation, true);

        // Increase total supply
        uint256 newTotalSupply = twabController.increaseTotalSupply(increaseAmount);
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

    function testFuzz_IncreaseTotalSupply_NotNewPeriodWithCardinalityBelowMax(
        uint256 _increaseAmount,
        uint256 _cardinality,
        uint256 _skip
    ) public setUpState(_increaseAmount) whenCardinalityBelowMax(_cardinality) whenNotNewPeriod(_skip) {
        // Get total supply account before increase balance
        AccountDetails memory totalSupplyBefore = twabController.getTotalSupplyAccount();
        // Compute expected new total supply
        uint256 expectedNewTotalSupply = totalSupplyBefore.balance + increaseAmount;
        // Get newest observation index
        uint256 totalSupplyNewestIndexBefore =
            RingBufferLib.newestIndex(totalSupplyBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = totalSupplyBefore.observations[totalSupplyNewestIndexBefore]
            .cumulativeBalance + totalSupplyBefore.observations[totalSupplyNewestIndexBefore].balance * skipLength;

        // Expect the `TotalSupplyIncreased` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit TotalSupplyIncreased(increaseAmount, expectedNewTotalSupply, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewTotalSupply,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(address(0), observation, false);

        // Increase total supply
        uint256 newTotalSupply = twabController.increaseTotalSupply(increaseAmount);
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

    function testFuzz_IncreaseTotalSupply_NewPeriodWithMaxCardinality(uint256 _increaseAmount, uint256 _skip)
        public
        setUpState(_increaseAmount)
        whenMaxCardinality
        whenNewPeriod(_skip)
    {
        // Get total supply account before increase balance
        AccountDetails memory totalSupplyBefore = twabController.getTotalSupplyAccount();
        // Compute expected new total supply
        uint256 expectedNewTotalSupply = totalSupplyBefore.balance + increaseAmount;
        // Get newest observation index
        uint256 totalSupplyNewestIndexBefore =
            RingBufferLib.newestIndex(totalSupplyBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = totalSupplyBefore.observations[totalSupplyNewestIndexBefore]
            .cumulativeBalance + totalSupplyBefore.observations[totalSupplyNewestIndexBefore].balance * skipLength;

        // Expect the `TotalSupplyIncreased` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit TotalSupplyIncreased(increaseAmount, expectedNewTotalSupply, block.timestamp);

        // Expect the `ObservationRecorded` event to be emitted
        Observation memory observation = Observation({
            balance: expectedNewTotalSupply,
            cumulativeBalance: expectedCumulativeBalance,
            timestamp: block.timestamp
        });
        vm.expectEmit(true, true, true, true);
        emit ObservationRecorded(address(0), observation, true);

        // Increase total supply
        uint256 newTotalSupply = twabController.increaseTotalSupply(increaseAmount);
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
