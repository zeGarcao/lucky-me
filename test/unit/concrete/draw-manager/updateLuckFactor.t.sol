// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {DrawManager_Unit_Shared_Test} from "../../shared/DrawManager.t.sol";
import {DRAW_UPDATE_LUCK_FACTOR__INVALID_LUCK_FACTOR_LIST} from "@lucky-me/utils/Errors.sol";
import {LuckFactorUpdated} from "@lucky-me/utils/Events.sol";

contract UpdateLuckFactor_Unit_Concrete_Test is DrawManager_Unit_Shared_Test {
    uint256[] newLuckFactor;

    // ================================== SETUP MODIFIERS ==================================

    modifier whenCallerIsNotOwner() {
        vm.startPrank(rando);
        _;
    }

    modifier whenCallerIsOwner() {
        vm.startPrank(address(pool));
        _;
    }

    modifier whenNewLuckFactorIsEmpty() {
        _;
    }

    modifier whenNewLuckFactorIsNotEmpty() {
        newLuckFactor.push(1000);
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_CallerNotOwner() public whenCallerIsNotOwner {
        // Expect revert since caller is not the owner.
        vm.expectRevert();
        drawManager.updateLuckFactor(newLuckFactor);
    }

    function test_RevertWhen_EmptyLuckFactor() public whenCallerIsOwner whenNewLuckFactorIsEmpty {
        // Expect revert with `DRAW_UPDATE_LUCK_FACTOR__INVALID_LUCK_FACTOR_LIST` error.
        vm.expectRevert(DRAW_UPDATE_LUCK_FACTOR__INVALID_LUCK_FACTOR_LIST.selector);
        drawManager.updateLuckFactor(newLuckFactor);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_UpdateLuckFactor_ValidLuckFactor() public whenCallerIsOwner whenNewLuckFactorIsNotEmpty {
        // Gets the current luck factor list.
        uint256[] memory oldLuckFactor = drawManager.getLuckFactor();

        // Expect the `LuckFactorUpdated` event to be emitted.
        vm.expectEmit(true, true, true, true);
        emit LuckFactorUpdated(oldLuckFactor, newLuckFactor, block.timestamp);

        // Updates the luck factor list.
        drawManager.updateLuckFactor(newLuckFactor);

        // Gets the new luck factor list.
        uint256[] memory updatedLuckFactor = drawManager.getLuckFactor();

        // Asserting that the luck factor list was updated.
        assertEq(updatedLuckFactor, newLuckFactor);
    }
}
