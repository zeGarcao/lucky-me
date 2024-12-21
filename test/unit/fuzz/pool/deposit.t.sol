// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {MIN_DEPOSIT} from "@lucky-me/utils/Constants.sol";
import {POOL_DEPOSIT__INVALID_AMOUNT} from "@lucky-me/utils/Errors.sol";
import {Deposited} from "@lucky-me/utils/Events.sol";
import {Pool_Unit_Shared_Test} from "../../shared/Pool.t.sol";

contract Deposit_Unit_Fuzz_Test is Pool_Unit_Shared_Test {
    // ================================== SETUP MODIFIERS ==================================

    modifier whenDepositAmountBelowMin(uint256 _depositAmount) {
        depositAmount = _clampBetween(_depositAmount, 0, MIN_DEPOSIT);
        _;
    }

    modifier whenDepositAmountAboveMin(uint256 _depositAmount) {
        vm.startPrank(bob);
        depositAmount = _clampBetween(_depositAmount, MIN_DEPOSIT, usdc.balanceOf(bob));
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_InvalidDepositAmount(uint256 _depositAmount)
        public
        whenDepositAmountBelowMin(_depositAmount)
    {
        // Expect revert with `POOL_DEPOSIT__INVALID_AMOUNT` error
        vm.expectRevert(POOL_DEPOSIT__INVALID_AMOUNT.selector);
        pool.deposit(depositAmount);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_Deposit_ValidDepositAmount(uint256 _depositAmount) public whenDepositAmountAboveMin(_depositAmount) {
        // Expect call to `twabController` to increase balance
        vm.expectCall(address(twabController), abi.encodeCall(twabController.increaseBalance, (bob, depositAmount)));
        // Expect call to `usdc` to transfer the assets from the caller to the pool contract
        vm.expectCall(address(usdc), abi.encodeCall(usdc.transferFrom, (bob, address(pool), depositAmount)));
        // Expect call to `usdc` to approve Aave
        vm.expectCall(address(usdc), abi.encodeCall(usdc.approve, (address(aavePool), depositAmount)));
        // Expect call to `aavePool` to supply the assets
        vm.expectCall(
            address(aavePool), abi.encodeCall(aavePool.supply, (address(usdc), depositAmount, address(pool), 0))
        );
        // Expect the `Deposited` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit Deposited(bob, depositAmount, depositAmount, block.timestamp);

        // Deposit assets into `pool`
        pool.deposit(depositAmount);
    }
}
