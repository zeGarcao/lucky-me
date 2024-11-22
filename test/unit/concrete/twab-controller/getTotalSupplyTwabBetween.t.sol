// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {TwabController_Unit_Shared_Test} from "../../shared/TwabController.t.sol";
import {TWAB_TWAB_BETWEEN__INVALID_TIME_RANGE} from "@lucky-me/utils/Errors.sol";
import {PERIOD_LENGTH, MIN_DEPOSIT} from "@lucky-me/utils/Constants.sol";
import {AccountDetails, Observation} from "@lucky-me/utils/Structs.sol";
import {RingBufferLib} from "@lucky-me/libraries/RingBufferLib.sol";

contract GetTotalSupplyTwabBetween_Unit_Concrete_Test is TwabController_Unit_Shared_Test {
    function setUp() public virtual override {
        TwabController_Unit_Shared_Test.setUp();

        vm.startPrank(address(pool));

        for (uint256 i; i < 3; ++i) {
            twabController.increaseBalance(bob, MIN_DEPOSIT);
            skip(PERIOD_LENGTH);
        }

        twabController.decreaseBalance(bob, MIN_DEPOSIT);

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
        AccountDetails memory account = twabController.getTotalSupplyAccount();
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
        twabController.getTotalSupplyTwabBetween(startTime, endTime);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_GetTotalSupplyTwabBetween_StartTimeEqualsEndTime() public whenStartTimeEqualsEndTime {
        // Get total supply twab between `startTime` and `endTime`
        uint256 totalSupplyTwab = twabController.getTotalSupplyTwabBetween(startTime, endTime);

        // Compute expected twab
        AccountDetails memory totalSupplyAccount = twabController.getAccount(bob);
        uint256 newestIndex =
            RingBufferLib.newestIndex(totalSupplyAccount.nextObservationIndex, totalSupplyAccount.cardinality);
        uint256 expectedTwab = totalSupplyAccount.observations[newestIndex].balance;

        // Asserting that total supply has the expected twab
        assertEq(totalSupplyTwab, expectedTwab);
    }

    function test_GetTotalSupplyTwabBetween_StartTimeLowerThanEndTimeWithSameTimestamps()
        public
        whenStartTimeLowerThanEndTime
        whenStartObservationTimestampEqualsStartTime
        whenEndObservationTimestampEqualsEndTime
    {
        // Get total supply twab between `startTime` and `endTime`
        uint256 totalSupplyTwab = twabController.getTotalSupplyTwabBetween(startTime, endTime);

        // Compute expected twab
        uint256 expectedTwab = (endObservation.cumulativeBalance - startObservation.cumulativeBalance)
            / (endObservation.timestamp - startObservation.timestamp);

        // Asserting that total supply has the expected twab
        assertEq(totalSupplyTwab, expectedTwab);
    }

    function test_GetTotalSupplyTwabBetween_StartTimeLowerThanEndTimeWithDifferentEndTimes()
        public
        whenStartTimeLowerThanEndTime
        whenStartObservationTimestampEqualsStartTime
        whenEndObservationTimestampDiffersEndTime
    {
        // Get total supply twab between `startTime` and `endTime`
        uint256 totalSupplyTwab = twabController.getTotalSupplyTwabBetween(startTime, endTime);

        // Compute expected twab
        Observation memory temporaryEndObservation = Observation({
            cumulativeBalance: endObservation.cumulativeBalance
                + endObservation.balance * (endTime - endObservation.timestamp),
            balance: endObservation.balance,
            timestamp: endTime
        });
        uint256 expectedTwab = (temporaryEndObservation.cumulativeBalance - startObservation.cumulativeBalance)
            / (endTime - startObservation.timestamp);

        // Asserting that total supply has the expected twab
        assertEq(totalSupplyTwab, expectedTwab);
    }

    function test_GetTotalSupplyTwabBetween_StartTimeLowerThanEndTimeWithDifferentStartTimes()
        public
        whenStartTimeLowerThanEndTime
        whenStartObservationTimestampDiffersStartTime
        whenEndObservationTimestampEqualsEndTime
    {
        // Get total supply twab between `startTime` and `endTime`
        uint256 totalSupplyTwab = twabController.getTotalSupplyTwabBetween(startTime, endTime);

        // Compute expected twab
        Observation memory temporaryStartObservation = Observation({
            cumulativeBalance: startObservation.cumulativeBalance
                + startObservation.balance * (startTime - startObservation.timestamp),
            balance: startObservation.balance,
            timestamp: startTime
        });
        uint256 expectedTwab = (endObservation.cumulativeBalance - temporaryStartObservation.cumulativeBalance)
            / (endObservation.timestamp - startTime);

        // Asserting that total supply has the expected twab
        assertEq(totalSupplyTwab, expectedTwab);
    }

    function test_GetTotalSupplyTwabBetween_StartTimeLowerThanEndTimeWithDifferentStartAndEndTimes()
        public
        whenStartTimeLowerThanEndTime
        whenStartObservationTimestampDiffersStartTime
        whenEndObservationTimestampDiffersEndTime
    {
        // Get total supply twab between `startTime` and `endTime`
        uint256 totalSupplyTwab = twabController.getTotalSupplyTwabBetween(startTime, endTime);

        // Compute expected twab
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

        // Asserting that total supply has the expected twab
        assertEq(totalSupplyTwab, expectedTwab);
    }
}
