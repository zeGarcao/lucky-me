// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {MIN_DEPOSIT} from "@lucky-me/utils/Constants.sol";
import {Pool_Integration_Shared_Test} from "../../shared/Pool.t.sol";

contract Deposit_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    // ================================== SETUP MODIFIERS ==================================

    modifier whenDepositAmountAboveMin() {
        depositAmount = MIN_DEPOSIT;
        _;
    }

    // ==================================== HAPPY TESTS ====================================

    function test_Deposit_ValidDepositAmount() public whenDepositAmountAboveMin {
        // Get balances before pool deposit
        uint256 bobInternalBalanceBefore = twabController.getAccount(bob).balance;
        uint256 poolTotalSupplyBefore = twabController.getTotalSupply();
        uint256 aavePoolTotalSupplyBefore = usdc.balanceOf(address(aavePool));
        uint256 poolReceiptBalanceBefore = aUsdc.balanceOf(address(pool));

        // Deposit into the pool
        vm.prank(bob);
        pool.deposit(depositAmount);

        // Asserting that bob's internal balance was updated
        assertEq(twabController.getAccount(bob).balance, bobInternalBalanceBefore + depositAmount);
        // Asserting that pool's total supply was updated
        assertEq(twabController.getTotalSupply(), poolTotalSupplyBefore + depositAmount);
        // Asserting that aave USDC pool's total supply was updated
        assertEq(usdc.balanceOf(address(aavePool)), aavePoolTotalSupplyBefore + depositAmount);
        // Asserting that receipt tokens were minted to the pool
        assertEq(aUsdc.balanceOf(address(pool)), poolReceiptBalanceBefore + depositAmount);
    }
}
