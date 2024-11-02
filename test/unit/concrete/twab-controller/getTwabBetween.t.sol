// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {TwabController_Unit_Shared_Test} from "../../shared/TwabController.t.sol";
import {TWAB_TWAB_BETWEEN__INVALID_TIME_RANGE} from "@lucky-me/utils/Errors.sol";
import {PERIOD_LENGTH} from "@lucky-me/utils/Constants.sol";
import {AccountDetails, Observation} from "@lucky-me/utils/Structs.sol";
import {RingBufferLib} from "@lucky-me/libraries/RingBufferLib.sol";

contract GetTwabBetween_Unit_Concrete_Test is TwabController_Unit_Shared_Test {
    Observation startObservation;
    Observation endObservation;
    uint256 startTime;
    uint256 endTime;

    function setUp() public virtual override {
        TwabController_Unit_Shared_Test.setUp();

        vm.startPrank(address(pool));

        for (uint256 i; i < 3; ++i) {
            twabController.increaseBalance(bob, 10e6);
            skip(PERIOD_LENGTH);
        }

        twabController.decreaseBalance(bob, 10e6);

        vm.stopPrank();
    }

    // ================================== SETUP MODIFIERS ==================================

    modifier whenStartTimeGreaterThanEndTime() {
        endTime = block.timestamp;
        startTime = endTime + 1;
        _;
    }

    modifier whenStartTimeEqualsEndTime() {
        startTime = block.timestamp;
        endTime = block.timestamp;
        _;
    }

    modifier whenStartTimeLowerThanEndTime() {
        AccountDetails memory account = twabController.getAccount(bob);
        startObservation = account.observations[1];
        endObservation = account.observations[3];
        _;
    }

    modifier whenStartObservationTimestampEqualsStartTime() {
        startTime = startObservation.timestamp;
        _;
    }

    modifier whenStartObservationTimestampDiffersStartTime() {
        startTime = startObservation.timestamp + (PERIOD_LENGTH / 2);
        _;
    }

    modifier whenEndObservationTimestampEqualsEndTime() {
        endTime = endObservation.timestamp;
        _;
    }

    modifier whenEndObservationTimestampDiffersEndTime() {
        endTime = endObservation.timestamp + (PERIOD_LENGTH / 2);
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_StartTimeGreaterThanEndTime() public whenStartTimeGreaterThanEndTime {
        // Expect revert with `TWAB_TWAB_BETWEEN__INVALID_TIME_RANGE` error
        vm.expectRevert(TWAB_TWAB_BETWEEN__INVALID_TIME_RANGE.selector);
        twabController.getTwabBetween(bob, startTime, endTime);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_GetTwabBetween_StartTimeEqualsEndTime() public whenStartTimeEqualsEndTime {
        uint256 bobTwab = twabController.getTwabBetween(bob, startTime, endTime);

        AccountDetails memory bobAccount = twabController.getAccount(bob);
        uint256 newestIndex = RingBufferLib.newestIndex(bobAccount.nextObservationIndex, bobAccount.cardinality);
        uint256 expectedTwab = bobAccount.observations[newestIndex].balance;

        assertEq(bobTwab, expectedTwab);
    }

    function test_GetTwabBetween_StartTimeLowerThanEndTimeWithSameTimestamps()
        public
        whenStartTimeLowerThanEndTime
        whenStartObservationTimestampEqualsStartTime
        whenEndObservationTimestampEqualsEndTime
    {
        uint256 bobTwab = twabController.getTwabBetween(bob, startTime, endTime);

        uint256 expectedTwab = (endObservation.cumulativeBalance - startObservation.cumulativeBalance)
            / (endObservation.timestamp - startObservation.timestamp);

        assertEq(bobTwab, expectedTwab);
    }

    function test_GetTwabBetween_StartTimeLowerThanEndTimeWithDifferentEndTimes()
        public
        whenStartTimeLowerThanEndTime
        whenStartObservationTimestampEqualsStartTime
        whenEndObservationTimestampDiffersEndTime
    {
        uint256 bobTwab = twabController.getTwabBetween(bob, startTime, endTime);

        Observation memory temporaryEndObservation = Observation({
            cumulativeBalance: endObservation.cumulativeBalance
                + endObservation.balance * (endTime - endObservation.timestamp),
            balance: endObservation.balance,
            timestamp: endTime
        });

        uint256 expectedTwab = (temporaryEndObservation.cumulativeBalance - startObservation.cumulativeBalance)
            / (endTime - startObservation.timestamp);

        assertEq(bobTwab, expectedTwab);
    }

    function test_GetTwabBetween_StartTimeLowerThanEndTimeWithDifferentStartTimes()
        public
        whenStartTimeLowerThanEndTime
        whenStartObservationTimestampDiffersStartTime
        whenEndObservationTimestampEqualsEndTime
    {
        uint256 bobTwab = twabController.getTwabBetween(bob, startTime, endTime);

        Observation memory temporaryStartObservation = Observation({
            cumulativeBalance: startObservation.cumulativeBalance
                + startObservation.balance * (startTime - startObservation.timestamp),
            balance: startObservation.balance,
            timestamp: startTime
        });

        uint256 expectedTwab = (endObservation.cumulativeBalance - temporaryStartObservation.cumulativeBalance)
            / (endObservation.timestamp - startTime);

        assertEq(bobTwab, expectedTwab);
    }

    function test_GetTwabBetween_StartTimeLowerThanEndTimeWithDifferentStartAndEndTimes()
        public
        whenStartTimeLowerThanEndTime
        whenStartObservationTimestampDiffersStartTime
        whenEndObservationTimestampDiffersEndTime
    {
        uint256 bobTwab = twabController.getTwabBetween(bob, startTime, endTime);

        Observation memory temporaryStartObservation = Observation({
            cumulativeBalance: startObservation.cumulativeBalance
                + startObservation.balance * (startTime - startObservation.timestamp),
            balance: startObservation.balance,
            timestamp: startTime
        });
        Observation memory temporaryEndObservation = Observation({
            cumulativeBalance: endObservation.cumulativeBalance
                + endObservation.balance * (endTime - endObservation.timestamp),
            balance: endObservation.balance,
            timestamp: endTime
        });

        uint256 expectedTwab = (temporaryEndObservation.cumulativeBalance - temporaryStartObservation.cumulativeBalance)
            / (endTime - startTime);

        assertEq(bobTwab, expectedTwab);
    }
}
