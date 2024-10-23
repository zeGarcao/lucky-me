// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {MIN_DEPOSIT} from "@lucky-me/utils/Constants.sol";
import {DEPOSIT__INVALID_AMOUNT} from "@lucky-me/utils/Errors.sol";
import {Deposited} from "@lucky-me/utils/Events.sol";
import {Pool_Unit_Shared_Test} from "../../shared/Pool.t.sol";

contract Deposit_Unit_Concrete_Test is Pool_Unit_Shared_Test {
    modifier whenDepositAmountBelowMin() {
        depositAmount = MIN_DEPOSIT - 1;
        _;
    }

    modifier whenDepositAmountAboveMin() {
        depositAmount = MIN_DEPOSIT;
        _;
    }

    function test_RevertWhen_DepositAmountIsInvalid() public whenDepositAmountBelowMin {
        vm.expectRevert(DEPOSIT__INVALID_AMOUNT.selector);
        pool.deposit(depositAmount);
    }

    function test_Deposit_DepositAmountIsValid() public whenDepositAmountAboveMin {
        vm.expectCall(address(twabController), abi.encodeCall(twabController.increaseBalance, (bob, depositAmount)));
        vm.expectCall(address(usdc), abi.encodeCall(usdc.transferFrom, (bob, address(pool), depositAmount)));
        vm.expectCall(address(usdc), abi.encodeCall(usdc.approve, (address(aavePool), depositAmount)));
        vm.expectCall(
            address(aavePool), abi.encodeCall(aavePool.supply, (address(usdc), depositAmount, address(pool), 0))
        );
        vm.expectEmit(true, true, true, true);
        emit Deposited(bob, depositAmount, depositAmount, block.timestamp);

        vm.prank(bob);
        pool.deposit(depositAmount);
    }
}
