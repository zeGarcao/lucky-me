// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {DrawManager_Unit_Shared_Test} from "../../shared/DrawManager.t.sol";
import {DRAW_DURATION} from "@lucky-me/utils/Constants.sol";

contract GetDrawPeriod_Unit_Concrete_Test is DrawManager_Unit_Shared_Test {
    // ================================== SETUP MODIFIERS ==================================

    modifier whenDrawIdIsZero() {
        drawId = 0;
        _;
    }

    modifier whenDrawIdIsNotZero() {
        drawId = 1;
        _;
    }

    // ==================================== HAPPY TESTS ====================================

    function test_GetDrawPeriod_ZeroedDrawId() public whenDrawIdIsZero {
        // Gets the draw start and end times.
        (uint256 startTime, uint256 endTime) = drawManager.getDrawPeriod(drawId);

        // Asserting that the correct start and end times were retrieved.
        assertEq(startTime, 0);
        assertEq(endTime, 0);
    }

    function test_GetDrawPeriod_ValidDrawId() public whenDrawIdIsNotZero {
        // Gets the draw start and end times.
        (uint256 startTime, uint256 endTime) = drawManager.getDrawPeriod(drawId);

        // Computes the expected start and end times.
        uint256 expectedStartTime = block.timestamp;
        uint256 expectedEndTime = expectedStartTime + DRAW_DURATION;

        // Asserting that the correct start and end times were retrieved.
        assertEq(startTime, expectedStartTime);
        assertEq(endTime, expectedEndTime);
    }
}
