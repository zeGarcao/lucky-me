// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Integration_Shared_Test} from "../../shared/Pool.t.sol";
import {TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE} from "@lucky-me/utils/Errors.sol";
import {MIN_DEPOSIT} from "@lucky-me/utils/Constants.sol";

contract Withdraw_Integration_Fuzz_Test is Pool_Integration_Shared_Test {
    // ================================== SETUP MODIFIERS ==================================

    modifier deposit(uint256 _depositAmount) {
        depositAmount = _clampBetween(_depositAmount, MIN_DEPOSIT, usdc.balanceOf(bob));

        vm.startPrank(bob);
        pool.deposit(depositAmount);
        _;
    }

    modifier whenWithdrawAmountAboveBalance(uint256 _withdrawAmount) {
        withdrawAmount = _clampBetween(_withdrawAmount, depositAmount + 1, type(uint256).max);
        _;
    }

    modifier whenWithdrawAmountNotAboveBalance(uint256 _withdrawAmount) {
        withdrawAmount = _withdrawAmount == depositAmount
            ? depositAmount
            : _clampBetween(_withdrawAmount, 1, depositAmount - (MIN_DEPOSIT - 1));
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function testFuzz_RevertWhen_InvalidAmount(uint256 _depositAmount, uint256 _withdrawAmount)
        public
        deposit(_depositAmount)
        whenWithdrawAmountAboveBalance(_withdrawAmount)
    {
        // Expect to revert with `TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE` error
        vm.expectRevert(TWAB_DECREASE_BALANCE__INSUFFICIENT_BALANCE.selector);
        pool.withdraw(withdrawAmount);
    }

    // ==================================== HAPPY TESTS ====================================

    function testFuzz_Withdraw_ValidAmount(uint256 _depositAmount, uint256 _withdrawAmount)
        public
        deposit(_depositAmount)
        whenWithdrawAmountNotAboveBalance(_withdrawAmount)
    {
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
