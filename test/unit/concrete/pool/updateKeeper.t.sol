// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {POOL_UPDATE_KEEPER__INVALID_KEEPER_ADDRESS} from "@lucky-me/utils/Errors.sol";
import {KeeperUpdated} from "@lucky-me/utils/Events.sol";
import {KEEPER_ROLE} from "@lucky-me/utils/Constants.sol";
import {Pool_Unit_Shared_Test} from "../../shared/Pool.t.sol";

contract UpdateKeeper_Unit_Concrete_Test is Pool_Unit_Shared_Test {
    address newKeeper;

    // ================================== SETUP MODIFIERS ==================================

    modifier whenCallerHasNotOwnerRole() {
        vm.startPrank(bob);
        _;
    }

    modifier whenCallerHasOwnerRole() {
        vm.startPrank(owner);
        _;
    }

    modifier whenNewKeeperIsZeroAddress() {
        _;
    }

    modifier whenNewKeeperIsNotZeroAddress() {
        _;
    }

    modifier whenNewKeeperIsCurrentKeeper() {
        newKeeper = keeper;
        _;
    }

    modifier whenNewKeeperIsNotCurrentKeeper() {
        newKeeper = rando;
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_CallerIsNotOwner() public whenCallerHasNotOwnerRole {
        // Expect revert since caller has not `OWNER_ROLE` role.
        vm.expectRevert();
        pool.updateKeeper(newKeeper);
    }

    function test_RevertWhen_ZeroAddress() public whenCallerHasOwnerRole whenNewKeeperIsZeroAddress {
        // Expect revert with `POOL_UPDATE_KEEPER__INVALID_KEEPER_ADDRESS` error.
        vm.expectRevert(POOL_UPDATE_KEEPER__INVALID_KEEPER_ADDRESS.selector);
        pool.updateKeeper(newKeeper);
    }

    function test_RevertWhen_SameKeeper()
        public
        whenCallerHasOwnerRole
        whenNewKeeperIsNotZeroAddress
        whenNewKeeperIsCurrentKeeper
    {
        // Expect revert with `POOL_UPDATE_KEEPER__INVALID_KEEPER_ADDRESS` error.
        vm.expectRevert(POOL_UPDATE_KEEPER__INVALID_KEEPER_ADDRESS.selector);
        pool.updateKeeper(newKeeper);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_UpdateKeeper_ValidNewKeeper()
        public
        whenCallerHasOwnerRole
        whenNewKeeperIsNotZeroAddress
        whenNewKeeperIsNotCurrentKeeper
    {
        // Expect the `KeeperUpdated` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit KeeperUpdated(newKeeper, keeper, block.timestamp);

        // Update keeper.
        pool.updateKeeper(newKeeper);

        // Asserting that `KEEPER_ROLE` role was revoked for current keeper.
        assertFalse(pool.hasRole(KEEPER_ROLE, keeper));
        // Asserting that `KEEPER_ROLE` role was granted for new keeper.
        assertTrue(pool.hasRole(KEEPER_ROLE, newKeeper));
    }
}
