// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {DrawManager_Unit_Shared_Test} from "../../shared/DrawManager.t.sol";
import {DEFAULT_CALLBACK_GAS_LIMIT, DEFAULT_REQUEST_CONFIRMATIONS} from "@lucky-me/utils/Constants.sol";
import {
    DRAW_REQUEST_CONFIG__INVALID_CALLBACK_GAS_LIMIT,
    DRAW_REQUEST_CONFIG__INVALID_REQUEST_CONFIRMATIONS
} from "@lucky-me/utils/Errors.sol";
import {RequestConfig} from "@lucky-me/utils/Structs.sol";
import {RequestConfigUpdated} from "@lucky-me/utils/Events.sol";

contract UpdateRequestConfig_Unit_Concrete_Test is DrawManager_Unit_Shared_Test {
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    // ================================== SETUP MODIFIERS ==================================

    modifier whenCallerDoesNotHaveAdminRole() {
        vm.startPrank(rando);
        _;
    }

    modifier whenCallerHasAdminRole() {
        vm.startPrank(address(owner));
        _;
    }

    modifier whenCallbackGasLimitIsZero() {
        callbackGasLimit = 0;
        _;
    }

    modifier whenCallbackGasLimitIsNotZero() {
        callbackGasLimit = DEFAULT_CALLBACK_GAS_LIMIT + 1;
        _;
    }

    modifier whenRequestConfirmationsIsZero() {
        requestConfirmations = 0;
        _;
    }

    modifier whenRequestConfirmationsIsNotZero() {
        requestConfirmations = DEFAULT_REQUEST_CONFIRMATIONS + 1;
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_NotAdmin() public whenCallerDoesNotHaveAdminRole {
        // Expect revert since caller does not have `ADMIN_ROLE` role.
        vm.expectRevert();
        drawManager.updateRequestConfig(callbackGasLimit, requestConfirmations);
    }

    function test_RevertWhen_CallbackGasLimitIsZero() public whenCallerHasAdminRole whenCallbackGasLimitIsZero {
        // Expect revert with `DRAW_REQUEST_CONFIG__INVALID_CALLBACK_GAS_LIMIT` error.
        vm.expectRevert(DRAW_REQUEST_CONFIG__INVALID_CALLBACK_GAS_LIMIT.selector);
        drawManager.updateRequestConfig(callbackGasLimit, requestConfirmations);
    }

    function test_RevertWhen_RequestConfirmationsIsZero()
        public
        whenCallerHasAdminRole
        whenCallbackGasLimitIsNotZero
        whenRequestConfirmationsIsZero
    {
        // Expect revert with `DRAW_REQUEST_CONFIG__INVALID_REQUEST_CONFIRMATIONS` error.
        vm.expectRevert(DRAW_REQUEST_CONFIG__INVALID_REQUEST_CONFIRMATIONS.selector);
        drawManager.updateRequestConfig(callbackGasLimit, requestConfirmations);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_UpdateRequestConfig_StoreNewConfig()
        public
        whenCallerHasAdminRole
        whenCallbackGasLimitIsNotZero
        whenRequestConfirmationsIsNotZero
    {
        // Expect `RequestConfigUpdated` to be emitted.
        vm.expectEmit(true, true, true, true);
        emit RequestConfigUpdated(callbackGasLimit, requestConfirmations, block.timestamp);

        // Update request config.
        drawManager.updateRequestConfig(callbackGasLimit, requestConfirmations);

        // Asserting that callback gas limit and request confirmations were updated.
        RequestConfig memory reqConfig = drawManager.getRequestConfig();
        assertEq(reqConfig.callbackGasLimit, callbackGasLimit);
        assertEq(reqConfig.requestConfirmations, requestConfirmations);
    }
}
