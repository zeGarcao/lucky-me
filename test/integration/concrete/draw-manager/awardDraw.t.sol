// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {DrawManager_Integration_Shared_Test} from "../../shared/DrawManager.t.sol";
import {DRAW_DURATION} from "@lucky-me/utils/Constants.sol";

contract AwardDraw_Integration_Concrete_Test is DrawManager_Integration_Shared_Test {
    uint256 drawId;

    function setUp() public override {
        DrawManager_Integration_Shared_Test.setUp();
        link.mint(address(drawManager), 10e18);
    }

    // ================================== SETUP MODIFIERS ==================================

    modifier whenCallerHasOwnerRole() {
        vm.startPrank(address(pool));
        _;
    }

    modifier whenDrawIsClosed() {
        skip(DRAW_DURATION);
        drawId = drawManager.getCurrentOpenDrawId() - 1;
        _;
    }

    // ==================================== HAPPY TESTS ====================================

    function test_AwardDraw_TransferLink() public whenCallerHasOwnerRole whenDrawIsClosed {
        // Get balances before awarding draw.
        uint256 reqPrice = drawManager.getRandomnessRequestCost();
        uint256 drawManagerBalanceBefore = link.balanceOf(address(drawManager));
        uint256 vrfWrapperBalanceBefore = link.balanceOf(address(vrfWrapper));

        // Awards draw.
        drawManager.awardDraw(drawId);

        // Asserting that the balance of draw manager was updated.
        assertEq(link.balanceOf(address(drawManager)), drawManagerBalanceBefore - reqPrice);
        // Asserting that the balance of vrf wrapper was updated.
        assertEq(link.balanceOf(address(vrfWrapper)), vrfWrapperBalanceBefore + reqPrice);
    }
}
