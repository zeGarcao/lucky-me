// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {TwabController_Unit_Shared_Test} from "../../shared/TwabController.t.sol";
import {MIN_DEPOSIT, MAX_CARDINALITY, PERIOD_LENGTH} from "@lucky-me/utils/Constants.sol";
import {RingBufferLib} from "@lucky-me/libraries/RingBufferLib.sol";
import {AccountDetails} from "@lucky-me/utils/Structs.sol";

contract DecreaseTotalSupply_Unit_Concrete_Test is TwabController_Unit_Shared_Test {
    // ================================== SETUP MODIFIERS ==================================
    modifier whenCardinalityBelowMax() {
        vm.startPrank(address(pool));
        decreaseAmount = MIN_DEPOSIT;
        increaseAmount = decreaseAmount * 2;
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
        vm.startPrank(address(pool));
        decreaseAmount = MIN_DEPOSIT;
        increaseAmount = MIN_DEPOSIT;
        for (uint256 i; i < MAX_CARDINALITY; ++i) {
            twabController.increaseBalance(bob, increaseAmount);
            if (i != MAX_CARDINALITY - 1) skip(PERIOD_LENGTH);
        }
        _;
    }

    // ==================================== HAPPY TESTS ====================================

    function test_DecreaseTotalSupply_NewPeriodWithCardinalityBelowMax() public whenCardinalityBelowMax whenNewPeriod {
        // Get total supply account before decrease balance
        AccountDetails memory totalSupplyBefore = twabController.getTotalSupplyAccount();
        // Compute expected new total supply
        uint256 expectedNewBalance = totalSupplyBefore.balance - decreaseAmount;
        // Get newest observation index
        uint256 totalSupplyNewestIndexBefore =
            RingBufferLib.newestIndex(totalSupplyBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = totalSupplyBefore.observations[totalSupplyNewestIndexBefore]
            .cumulativeBalance + totalSupplyBefore.observations[totalSupplyNewestIndexBefore].balance * skipLength;

        // Decrease total supply
        twabController.decreaseBalance(bob, decreaseAmount);

        // **** TOTAL SUPPLY UPDATE ****
        AccountDetails memory totalSupplyAfter = twabController.getTotalSupplyAccount();

        // Asserting that the total supply balance was updated
        assertEq(totalSupplyAfter.balance, expectedNewBalance);
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
        whenCardinalityBelowMax
        whenNotNewPeriod
    {
        // Get total supply account before decrease balance
        AccountDetails memory totalSupplyBefore = twabController.getTotalSupplyAccount();
        // Compute expected new total supply
        uint256 expectedNewBalance = totalSupplyBefore.balance - decreaseAmount;
        // Get newest observation index
        uint256 totalSupplyNewestIndexBefore =
            RingBufferLib.newestIndex(totalSupplyBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = totalSupplyBefore.observations[totalSupplyNewestIndexBefore]
            .cumulativeBalance + totalSupplyBefore.observations[totalSupplyNewestIndexBefore].balance * skipLength;

        // Decrease total supply
        twabController.decreaseBalance(bob, decreaseAmount);

        // **** TOTAL SUPPLY UPDATE ****
        AccountDetails memory totalSupplyAfter = twabController.getTotalSupplyAccount();

        // Asserting that the total supply balance was updated
        assertEq(totalSupplyAfter.balance, expectedNewBalance);
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

    function test_DecreaseTotalSupply_NewPeriodWithMaxCardinality() public whenMaxCardinality whenNewPeriod {
        // Get total supply account before decrease balance
        AccountDetails memory totalSupplyBefore = twabController.getTotalSupplyAccount();
        // Compute expected new total supply
        uint256 expectedNewBalance = totalSupplyBefore.balance - decreaseAmount;
        // Get newest observation index
        uint256 totalSupplyNewestIndexBefore =
            RingBufferLib.newestIndex(totalSupplyBefore.nextObservationIndex, MAX_CARDINALITY);
        // Compute expected cumulative balance
        uint256 expectedCumulativeBalance = totalSupplyBefore.observations[totalSupplyNewestIndexBefore]
            .cumulativeBalance + totalSupplyBefore.observations[totalSupplyNewestIndexBefore].balance * skipLength;

        // Decrease total supply
        twabController.decreaseBalance(bob, decreaseAmount);

        // **** TOTAL SUPPLY UPDATE ****
        AccountDetails memory totalSupplyAfter = twabController.getTotalSupplyAccount();

        // Asserting that the total supply balance was updated
        assertEq(totalSupplyAfter.balance, expectedNewBalance);
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
