// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Integration_Shared_Test} from "../../shared/Pool.t.sol";
import {TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE} from "@lucky-me/utils/Errors.sol";

contract Withdraw_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    function setUp() public override {
        Pool_Integration_Shared_Test.setUp();

        depositAmount = 100e6;

        vm.startPrank(bob);
        pool.deposit(depositAmount);
    }

    // ================================== SETUP MODIFIERS ==================================

    modifier whenWithdrawAmountAboveBalance() {
        withdrawAmount = depositAmount + 1;
        _;
    }

    modifier whenWithdrawAmountNotAboveBalance() {
        withdrawAmount = depositAmount;
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_InvalidAmount() public whenWithdrawAmountAboveBalance {
        // Expect to revert with `TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE` error
        vm.expectRevert(TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE.selector);
        pool.withdraw(withdrawAmount);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_Withdraw_ValidAmount() public whenWithdrawAmountNotAboveBalance {
        // Get balances before withdrawal
        uint256 bobInternalBalanceBefore = twabController.getAccount(bob).balance;
        uint256 poolTotalSupplyBefore = twabController.getTotalSupply();
        uint256 aUsdcTotalSupplyBefore = aUsdc.totalSupply();
        uint256 bobUsdcBalanceBefore = usdc.balanceOf(bob);

        // Withdraw from the pool
        pool.withdraw(withdrawAmount);

        // Asserting that user's internal balance was updated
        assertEq(twabController.getAccount(bob).balance, bobInternalBalanceBefore - withdrawAmount);
        // Asserting that pool's total supply was updated
        assertEq(twabController.getTotalSupply(), poolTotalSupplyBefore - withdrawAmount);
        // Asserting that receipt tokens were burned
        assertEq(aUsdc.totalSupply(), aUsdcTotalSupplyBefore - withdrawAmount);
        // Asserting that USDC was transferred back to the user
        assertEq(usdc.balanceOf(bob), bobUsdcBalanceBefore + withdrawAmount);
    }
}
