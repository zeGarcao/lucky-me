// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {DrawManager_Unit_Shared_Test} from "../../shared/DrawManager.t.sol";
import {DRAW_UPDATE_ADMIN__INVALID_ADMIN} from "@lucky-me/utils/Errors.sol";
import {AdminUpdated} from "@lucky-me/utils/Events.sol";

contract UpdateAdmin_Unit_Concrete_Test is DrawManager_Unit_Shared_Test {
    address newAdmin;

    // ================================== SETUP MODIFIERS ==================================

    modifier whenCallerDoesNotHaveAdminRole() {
        vm.startPrank(rando);
        _;
    }

    modifier whenCallerHasAdminRole() {
        vm.startPrank(owner);
        _;
    }

    modifier whenNewAdminIsZeroAddress() {
        newAdmin = address(0);
        _;
    }

    modifier whenNewAdminIsNotZeroAddress() {
        _;
    }

    modifier whenNewAdminIsEqualToCurrentAdmin() {
        newAdmin = drawManager.admin();
        _;
    }

    modifier whenNewAdminIsDifferentFromCurrentAdmin() {
        newAdmin = rando;
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_NotAdmin() public whenCallerDoesNotHaveAdminRole {
        // Expect to revert since caller does not have `ADMIN_ROLE` role.
        vm.expectRevert();
        drawManager.updateAdmin(newAdmin);
    }

    function test_RevertWhen_ZeroAddress() public whenCallerHasAdminRole whenNewAdminIsZeroAddress {
        // Expect revert with `DRAW_UPDATE_ADMIN__INVALID_ADMIN` error.
        vm.expectRevert(DRAW_UPDATE_ADMIN__INVALID_ADMIN.selector);
        drawManager.updateAdmin(newAdmin);
    }

    function test_RevertWhen_SameAdmin()
        public
        whenCallerHasAdminRole
        whenNewAdminIsNotZeroAddress
        whenNewAdminIsEqualToCurrentAdmin
    {
        // Expect revert with `DRAW_UPDATE_ADMIN__INVALID_ADMIN` error.
        vm.expectRevert(DRAW_UPDATE_ADMIN__INVALID_ADMIN.selector);
        drawManager.updateAdmin(newAdmin);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_UpdateAdmin_ValidAdmin()
        public
        whenCallerHasAdminRole
        whenNewAdminIsNotZeroAddress
        whenNewAdminIsDifferentFromCurrentAdmin
    {
        // Expect the `AdminUpdated` event to be emitted.
        vm.expectEmit(true, true, true, true);
        emit AdminUpdated(drawManager.admin(), newAdmin, block.timestamp);

        // Update the admin.
        drawManager.updateAdmin(newAdmin);

        // Asserting that admin was updated.
        assertEq(drawManager.admin(), newAdmin);
    }
}
