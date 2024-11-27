// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Unit_Shared_Test} from "../../shared/Pool.t.sol";
import {POOL_UPDATE_LUCK_FACTOR__INVALID_LUCK_FACTOR} from "@lucky-me/utils/Errors.sol";
import {LuckFactorUpdated} from "@lucky-me/utils/Events.sol";

contract UpdateLuckFactor_Unit_Concrete_Test is Pool_Unit_Shared_Test {
    uint256[] newLuckFactor;
    // ================================== SETUP MODIFIERS ==================================

    modifier whenCallerDoesNotHaveOwnerRole() {
        vm.startPrank(rando);
        _;
    }

    modifier whenCallerHasOwnerRole() {
        vm.startPrank(owner);
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

    function test_RevertWhen_NotOwner() public whenCallerDoesNotHaveOwnerRole {
        // Expect to revert since caller does not have `OWNER_ROLE` role.
        vm.expectRevert();
        pool.updateLuckFactor(newLuckFactor);
    }

    function test_RevertWhen_EmptyLuckFactor() public whenCallerHasOwnerRole whenNewLuckFactorIsEmpty {
        // Expect to revert with `POOL_UPDATE_LUCK_FACTOR__INVALID_LUCK_FACTOR` error.
        vm.expectRevert(POOL_UPDATE_LUCK_FACTOR__INVALID_LUCK_FACTOR.selector);
        pool.updateLuckFactor(newLuckFactor);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_UpdateLuckFactor_ValidLuckFactor() public whenCallerHasOwnerRole whenNewLuckFactorIsNotEmpty {
        // Expect the `LuckFactorUpdated` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit LuckFactorUpdated(pool.getLuckFactor(), newLuckFactor, block.timestamp);

        // Updates the luck factor list.
        pool.updateLuckFactor(newLuckFactor);

        // Asserting that luck factor was updated.
        assertEq(pool.getLuckFactor(), newLuckFactor);
    }
}
