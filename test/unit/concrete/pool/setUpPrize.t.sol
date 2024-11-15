// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Unit_Shared_Test} from "../../shared/Pool.t.sol";
import {
    POOL_PRIZE_SETUP__DRAW_NOT_CLOSED,
    POOL_PRIZE_SETUP__NOT_ENOUGH_FUNDS,
    POOL_PRIZE_SETUP__PRIZE_TOO_SMALL
} from "@lucky-me/utils/Errors.sol";
import {DRAW_DURATION, ONE_HUNDRED_PERCENT_BPS, MIN_DEPOSIT} from "@lucky-me/utils/Constants.sol";
import {ISwapRouter} from "@lucky-me/interfaces/ISwapRouter.sol";
import {PrizeSetUp} from "@lucky-me/utils/Events.sol";

contract SetUpPrize_Unit_Concrete_Test is Pool_Unit_Shared_Test {
    uint24 constant POOL_FEE = 3000;
    uint256 constant SLIPPAGE = 100;

    function setUp() public override {
        Pool_Unit_Shared_Test.setUp();

        vm.prank(bob);
        pool.deposit(MIN_DEPOSIT);
    }

    // ================================== SETUP MODIFIERS ==================================

    modifier whenCallerHasNotKeeperRole() {
        vm.startPrank(rando);
        _;
    }

    modifier whenCallerHasKeeperRole() {
        vm.startPrank(keeper);
        _;
    }

    modifier whenDrawIsNotClosed() {
        _;
    }

    modifier whenDrawIsClosed() {
        skip(DRAW_DURATION);
        _;
    }

    modifier whenGeneratedYieldIsNotEnoughToCoverCosts() {
        _;
    }

    modifier whenGeneratedYieldIsEnoughToCoverCosts() {
        aavePool.updateYield(address(usdc), address(pool), 120e6);
        _;
    }

    modifier whenPrizeIsBelowMin() {
        vrfWrapper.updateRequestPirce(2e18);
        _;
    }

    modifier whenPirzeIsAboveMin() {
        _;
    }

    // =================================== UNHAPPY TESTS ===================================
    function test_RevertWhen_CallerIsNotKeeper() public whenCallerHasNotKeeperRole {
        // Expect revert since caller has not `KEEPER_ROLE` role.
        vm.expectRevert();
        pool.setUpPrize(POOL_FEE, SLIPPAGE);
    }

    function test_RevertWhen_DrawIsNotClosed() public whenCallerHasKeeperRole whenDrawIsNotClosed {
        // Expect revert with `POOL_PRIZE_SETUP__DRAW_NOT_CLOSED` error
        vm.expectRevert(POOL_PRIZE_SETUP__DRAW_NOT_CLOSED.selector);
        pool.setUpPrize(POOL_FEE, SLIPPAGE);
    }

    function test_RevertWhen_NotEnoughYield()
        public
        whenCallerHasKeeperRole
        whenDrawIsClosed
        whenGeneratedYieldIsNotEnoughToCoverCosts
    {
        // Expect revert with `POOL_PRIZE_SETUP__NOT_ENOUGH_FUNDS` error
        vm.expectRevert(POOL_PRIZE_SETUP__NOT_ENOUGH_FUNDS.selector);
        pool.setUpPrize(POOL_FEE, SLIPPAGE);
    }

    function test_RevertWhen_InsufficientPrize()
        public
        whenCallerHasKeeperRole
        whenDrawIsClosed
        whenGeneratedYieldIsEnoughToCoverCosts
        whenPrizeIsBelowMin
    {
        // Expect revert with `POOL_PRIZE_SETUP__PRIZE_TOO_SMALL` error
        vm.expectRevert(POOL_PRIZE_SETUP__PRIZE_TOO_SMALL.selector);
        pool.setUpPrize(POOL_FEE, SLIPPAGE);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_SetUpPrize_SufficientPrize()
        public
        whenCallerHasKeeperRole
        whenDrawIsClosed
        whenGeneratedYieldIsEnoughToCoverCosts
        whenPirzeIsAboveMin
    {
        // Expect call to `swapRouter` to swap USDC for LINK.
        ISwapRouter.ExactOutputSingleParams memory swapParams = _generateSwapParams();
        vm.expectCall(address(swapRouter), abi.encodeCall(swapRouter.exactOutputSingle, (swapParams)));

        // Expect call to `drawManager` to award the previous closed draw.
        uint256 yield = aUsdc.balanceOf(address(pool)) - twabController.getTotalSupply();
        uint256 prize = yield - swapParams.amountInMaximum;
        vm.expectCall(address(drawManager), abi.encodeCall(drawManager.awardDraw, (1, prize)));

        // Expect the `PrizeSetUp` event to be emitted.
        vm.expectEmit(true, true, true, true);
        emit PrizeSetUp(1, prize, block.timestamp);

        // Set up prize for previous closed draw.
        pool.setUpPrize(POOL_FEE, SLIPPAGE);
    }

    function _generateSwapParams() internal returns (ISwapRouter.ExactOutputSingleParams memory) {
        uint256 usdcAmountIn =
            quoter.quoteExactOutputSingle(address(usdc), address(link), POOL_FEE, vrfWrapper.DEFAULT_PRICE(), 0);
        uint256 usdcAmountInWithSlippage =
            (usdcAmountIn * (ONE_HUNDRED_PERCENT_BPS + SLIPPAGE)) / ONE_HUNDRED_PERCENT_BPS;

        return ISwapRouter.ExactOutputSingleParams({
            tokenIn: address(usdc),
            tokenOut: address(link),
            fee: POOL_FEE,
            recipient: address(drawManager),
            deadline: block.timestamp,
            amountOut: vrfWrapper.DEFAULT_PRICE(),
            amountInMaximum: usdcAmountInWithSlippage,
            sqrtPriceLimitX96: 0
        });
    }
}
