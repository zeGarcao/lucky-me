// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Unit_Shared_Test} from "../../shared/Pool.t.sol";

import {WITHDRAW__INVALID_AMOUNT, WITHDRAW__INVALID_BALANCE} from "@lucky-me/utils/Errors.sol";
import {Withdrawn} from "@lucky-me/utils/Events.sol";

contract Withdraw_Unit_Concrete_Test is Pool_Unit_Shared_Test {
    modifier whenWithdrawAmountIsZero() {
        withdrawAmount = 0;
        _;
    }

    modifier whenWithdrawAmountIsNotZero() {
        withdrawAmount = 5000e6;
        _;
    }

    modifier whenNewBalanceNotZeroAndBelowMin() {
        depositAmount = 5001e6;
        vm.prank(bob);
        pool.deposit(depositAmount);
        _;
    }

    modifier whenNewBalanceIsZero() {
        depositAmount = 5000e6;
        vm.prank(bob);
        pool.deposit(depositAmount);
        _;
    }

    modifier whenNewBalanceAboveMin() {
        depositAmount = 7500e6;
        vm.prank(bob);
        pool.deposit(depositAmount);
        _;
    }

    function test_RevertWhen_WithdrawAmountIsZero() public whenWithdrawAmountIsZero {
        vm.expectRevert(WITHDRAW__INVALID_AMOUNT.selector);
        pool.withdraw(withdrawAmount);
    }

    function test_RevertWhen_NewBalanceIsInvalid()
        public
        whenWithdrawAmountIsNotZero
        whenNewBalanceNotZeroAndBelowMin
    {
        vm.expectRevert(WITHDRAW__INVALID_BALANCE.selector);

        vm.prank(bob);
        pool.withdraw(withdrawAmount);
    }

    function test_Withdraw_NewBalanceIsZero() public whenWithdrawAmountIsNotZero whenNewBalanceIsZero {
        vm.expectCall(address(twabController), abi.encodeCall(twabController.decreaseBalance, (bob, withdrawAmount)));
        vm.expectCall(address(aavePool), abi.encodeCall(aavePool.withdraw, (address(usdc), withdrawAmount, bob)));
        vm.expectEmit(true, true, true, true);
        emit Withdrawn(bob, withdrawAmount, 0, block.timestamp);

        vm.prank(bob);
        pool.withdraw(withdrawAmount);
    }

    function test_Withdraw_NewBalance() public whenWithdrawAmountIsNotZero whenNewBalanceAboveMin {
        vm.expectCall(address(twabController), abi.encodeCall(twabController.decreaseBalance, (bob, withdrawAmount)));
        vm.expectCall(address(aavePool), abi.encodeCall(aavePool.withdraw, (address(usdc), withdrawAmount, bob)));
        vm.expectEmit(true, true, true, true);
        emit Withdrawn(bob, withdrawAmount, depositAmount - withdrawAmount, block.timestamp);

        vm.prank(bob);
        pool.withdraw(withdrawAmount);
    }
}
