// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Unit_Shared_Test} from "../../shared/Pool.t.sol";
import {POOL_WITHDRAW__INVALID_AMOUNT, POOL_WITHDRAW__INVALID_BALANCE} from "@lucky-me/utils/Errors.sol";
import {MIN_DEPOSIT} from "@lucky-me/utils/Constants.sol";
import {Withdrawn} from "@lucky-me/utils/Events.sol";

contract Withdraw_Unit_Fuzz_Test is Pool_Unit_Shared_Test {
    // ================================== SETUP MODIFIERS ==================================

    modifier deposit(uint256 _depositAmount) {
        vm.startPrank(bob);
        depositAmount = _clampBetween(_depositAmount, MIN_DEPOSIT, usdc.balanceOf(bob));
        pool.deposit(depositAmount);
        _;
    }

    modifier whenNewBalanceIsZero() {
        withdrawAmount = depositAmount;
        _;
    }

    modifier whenNewBalanceIsNotZero() {
        _;
    }

    modifier whenNewBalanceBelowMin(uint256 _withdrawAmount) {
        withdrawAmount = _clampBetween(_withdrawAmount, depositAmount - (MIN_DEPOSIT - 1), depositAmount);
        _;
    }

    modifier whenNewBalanceAboveMin(uint256 _withdrawAmount) {
        withdrawAmount = _clampBetween(_withdrawAmount, 1, depositAmount - (MIN_DEPOSIT - 1));
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function testFuzz_RevertWhen_InvalidNewBalance(uint256 _depositAmount, uint256 _withdrawAmount)
        public
        deposit(_depositAmount)
        whenNewBalanceIsNotZero
        whenNewBalanceBelowMin(_withdrawAmount)
    {
        // Expect revert with `POOL_WITHDRAW__INVALID_BALANCE` error
        vm.expectRevert(POOL_WITHDRAW__INVALID_BALANCE.selector);
        pool.withdraw(withdrawAmount);
    }

    // ==================================== HAPPY TESTS ====================================

    function testFuzz_Withdraw_ZeroedNewBalance(uint256 _depositAmount)
        public
        deposit(_depositAmount)
        whenNewBalanceIsZero
    {
        // Expect call to `twabController` to decrease balance
        vm.expectCall(address(twabController), abi.encodeCall(twabController.decreaseBalance, (bob, withdrawAmount)));
        // Expect call to `aavePool` to withdraw the assets
        vm.expectCall(address(aavePool), abi.encodeCall(aavePool.withdraw, (address(usdc), withdrawAmount, bob)));
        // Expect the `Withdrawn` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit Withdrawn(bob, withdrawAmount, 0, block.timestamp);

        // Withdraw the assets from the `pool`
        pool.withdraw(withdrawAmount);
    }

    function testFuzz_Withdraw_ValidNewBalance(uint256 _depositAmount, uint256 _withdrawAmount)
        public
        deposit(_depositAmount)
        whenNewBalanceIsNotZero
        whenNewBalanceAboveMin(_withdrawAmount)
    {
        // Expect call to `twabController` to decrease the balance
        vm.expectCall(address(twabController), abi.encodeCall(twabController.decreaseBalance, (bob, withdrawAmount)));
        // Expect call to `aavePool` to withdraw the assets
        vm.expectCall(address(aavePool), abi.encodeCall(aavePool.withdraw, (address(usdc), withdrawAmount, bob)));
        // Expect the `Withdrawn` event to be emitted
        vm.expectEmit(true, true, true, true);
        emit Withdrawn(bob, withdrawAmount, depositAmount - withdrawAmount, block.timestamp);

        // Withdraw the assets
        pool.withdraw(withdrawAmount);
    }
}
