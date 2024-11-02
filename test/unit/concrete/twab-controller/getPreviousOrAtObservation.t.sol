// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {TwabController_Unit_Shared_Test} from "../../shared/TwabController.t.sol";
import {TwabControllerHarness} from "../../../harness/TwabControllerHarness.sol";
import {AccountDetails, Observation} from "@lucky-me/utils/Structs.sol";
import {MAX_CARDINALITY, PERIOD_LENGTH} from "@lucky-me/utils/Constants.sol";
import {TWAB_TWAB_BETWEEN__INSUFFICIENT_HISTORY} from "@lucky-me/utils/Errors.sol";
import {RingBufferLib} from "@lucky-me/libraries/RingBufferLib.sol";

contract GetPreviousOrAtObservation_Unit_Concrete_Test is TwabController_Unit_Shared_Test {
    TwabControllerHarness twabControllerHarness;
    Observation expectedObservation;
    uint256 targetTime;

    function setUp() public virtual override {
        TwabController_Unit_Shared_Test.setUp();
        twabControllerHarness = new TwabControllerHarness(block.timestamp);
    }

    // ================================== SETUP MODIFIERS ==================================

    modifier whenCardinalityIsZero() {
        expectedObservation = Observation({cumulativeBalance: 0, balance: 0, timestamp: 0});
        _;
    }

    modifier whenCardinalityIsOne() {
        twabControllerHarness.increaseBalance(bob, 10e6);
        _;
    }

    modifier whenCardinalityIsTwo() {
        for (uint256 i; i < 2; ++i) {
            skip(PERIOD_LENGTH);
            twabControllerHarness.increaseBalance(bob, 10e6);
        }
        _;
    }

    modifier whenCardinalityGreaterThanTwo() {
        for (uint256 i; i < 4; ++i) {
            skip(PERIOD_LENGTH);
            twabControllerHarness.increaseBalance(bob, 10e6);
        }
        _;
    }

    modifier whenCardinalityBelowMax() {
        _;
    }

    modifier whenCardinalityReachedMax() {
        for (uint256 i; i < MAX_CARDINALITY; ++i) {
            skip(PERIOD_LENGTH);
            twabControllerHarness.increaseBalance(bob, 10e6);
        }
        _;
    }

    modifier whenOldestObservationTimestampGreaterThanTargetTime() {
        AccountDetails memory account = twabControllerHarness.getAccount(bob);
        uint256 oldestIndex =
            RingBufferLib.oldestIndex(account.nextObservationIndex, account.cardinality, MAX_CARDINALITY);
        targetTime = account.observations[oldestIndex].timestamp - 1;
        expectedObservation = Observation({cumulativeBalance: 0, balance: 0, timestamp: 0});
        _;
    }

    modifier whenOldestObservationTimestampNotGreaterThanTargetTime() {
        AccountDetails memory account = twabControllerHarness.getAccount(bob);
        uint256 oldestIndex =
            RingBufferLib.oldestIndex(account.nextObservationIndex, account.cardinality, MAX_CARDINALITY);
        targetTime = account.observations[oldestIndex].timestamp;
        expectedObservation = account.observations[oldestIndex];
        _;
    }

    modifier whenNewestObservationTimestampLowerOrEqualToTargetTime() {
        AccountDetails memory account = twabControllerHarness.getAccount(bob);
        uint256 newestIndex = RingBufferLib.newestIndex(account.nextObservationIndex, account.cardinality);
        targetTime = account.observations[newestIndex].timestamp + 1;
        expectedObservation = account.observations[newestIndex];
        _;
    }

    modifier whenNewestObservationTimestampGreaterThanTargetTime() {
        AccountDetails memory account = twabControllerHarness.getAccount(bob);
        uint256 newestIndex = RingBufferLib.newestIndex(account.nextObservationIndex, account.cardinality);
        targetTime = account.observations[newestIndex].timestamp - 1;
        expectedObservation = account.observations[newestIndex - 1];
        _;
    }

    modifier whenAfterOrAtObservationTimestampEqualToTargetTime() {
        AccountDetails memory account = twabControllerHarness.getAccount(bob);
        uint256 newestIndex = RingBufferLib.newestIndex(account.nextObservationIndex, account.cardinality);
        uint256 prevIndex = RingBufferLib.prevIndex(newestIndex, MAX_CARDINALITY);
        targetTime = account.observations[prevIndex].timestamp;
        expectedObservation = account.observations[prevIndex];
        _;
    }

    modifier whenAfterOrAtObservationTimestampGreaterThanTargetTime() {
        AccountDetails memory account = twabControllerHarness.getAccount(bob);
        uint256 newestIndex = RingBufferLib.newestIndex(account.nextObservationIndex, account.cardinality);
        targetTime = account.observations[newestIndex].timestamp - 1;
        expectedObservation = account.observations[newestIndex - 1];
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_MaxCardinalityAfterTargetTime()
        public
        whenCardinalityReachedMax
        whenOldestObservationTimestampGreaterThanTargetTime
    {
        // Expect revert with `TWAB_TWAB_BETWEEN__INSUFFICIENT_HISTORY` error
        vm.expectRevert(TWAB_TWAB_BETWEEN__INSUFFICIENT_HISTORY.selector);
        twabControllerHarness.getPreviousOrAtObservation(bob, targetTime);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_GetPreviousOrAtObservation_ZeroCardinality() public whenCardinalityIsZero {
        _assertExpectedObservation();
    }

    function test_GetPreviousOrAtObservation_OneCardinalityAfterTargetTime()
        public
        whenCardinalityIsOne
        whenOldestObservationTimestampGreaterThanTargetTime
    {
        _assertExpectedObservation();
    }

    function test_GetPreviousOrAtObservation_OneCardinalityBeforeTargetTime()
        public
        whenCardinalityIsOne
        whenOldestObservationTimestampNotGreaterThanTargetTime
    {
        _assertExpectedObservation();
    }

    function test_GetPreviousOrAtObservation_TwoCardinalityAfterTargetTime()
        public
        whenCardinalityIsTwo
        whenOldestObservationTimestampGreaterThanTargetTime
    {
        _assertExpectedObservation();
    }

    function test_GetPreviousOrAtObservation_TwoCardinalityWithNewestBeforeTargetTime()
        public
        whenCardinalityIsTwo
        whenNewestObservationTimestampLowerOrEqualToTargetTime
    {
        _assertExpectedObservation();
    }

    function test_GetPreviousOrAtObservation_TwoCardinalityWithNewestAfterTargetTime()
        public
        whenCardinalityIsTwo
        whenNewestObservationTimestampGreaterThanTargetTime
    {
        _assertExpectedObservation();
    }

    function test_GetPreviousOrAtObservation_CardinalityAboveTwoAndBelowMaxAfterTargetTime()
        public
        whenCardinalityGreaterThanTwo
        whenCardinalityBelowMax
        whenOldestObservationTimestampGreaterThanTargetTime
    {
        _assertExpectedObservation();
    }

    function test_GetPreviousOrAtObservation_CardinalityAboveTwoAndBelowMaxWithAfterOrAtObsTimestampEqualTargetTime()
        public
        whenCardinalityGreaterThanTwo
        whenCardinalityBelowMax
        whenAfterOrAtObservationTimestampEqualToTargetTime
    {
        _assertExpectedObservation();
    }

    function test_GetPreviousOrAtObservation_CardinalityAboveTwoAndBelowMaxWithAfterOrAtObsTimestampAboveTargetTime()
        public
        whenCardinalityGreaterThanTwo
        whenCardinalityBelowMax
        whenAfterOrAtObservationTimestampGreaterThanTargetTime
    {
        _assertExpectedObservation();
    }

    function test_GetPreviousOrAtObservation_MaxCardinalityWithAfterOrAtObsTimestampEqualTargetTime()
        public
        whenCardinalityReachedMax
        whenAfterOrAtObservationTimestampEqualToTargetTime
    {
        _assertExpectedObservation();
    }

    function test_GetPreviousOrAtObservation_MaxCardinalityWithAfterOrAtObsTimestampGreaterTargetTime()
        public
        whenCardinalityReachedMax
        whenAfterOrAtObservationTimestampGreaterThanTargetTime
    {
        _assertExpectedObservation();
    }

    function _assertExpectedObservation() internal view {
        // Get observation previous or at target time
        Observation memory observation = twabControllerHarness.getPreviousOrAtObservation(bob, targetTime);

        // Asserting that the expected observation was returned
        assertEq(observation.balance, expectedObservation.balance);
        assertEq(observation.cumulativeBalance, expectedObservation.cumulativeBalance);
        assertEq(observation.timestamp, expectedObservation.timestamp);
    }
}
