// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Pool_Unit_Shared_Test} from "../../shared/Pool.t.sol";
import {DRAW_DURATION, MAX_CLAIMS} from "@lucky-me/utils/Constants.sol";
import {POOL_SET_PRIZE__NOT_ENOUGH_FUNDS, POOL_SET_PRIZE__PRIZE_TOO_SMALL} from "@lucky-me/utils/Errors.sol";
import {ISwapRouter} from "@lucky-me/interfaces/ISwapRouter.sol";
import {PrizeSet} from "@lucky-me/utils/Events.sol";

contract SetPrize_Unit_Concrete_Test is Pool_Unit_Shared_Test {
    uint24 constant POOL_FEE = 3000;
    uint256 constant SLIPPAGE = 100;
    uint256 drawId;

    function setUp() public override {
        Pool_Unit_Shared_Test.setUp();

        vm.prank(bob);
        pool.deposit(10_000e6);

        skip(DRAW_DURATION);
        drawId = drawManager.getCurrentOpenDrawId() - 1;
    }

    // ================================== SETUP MODIFIERS ==================================

    modifier whenCallerDoesNotHaveKeeperRole() {
        vm.startPrank(rando);
        _;
    }

    modifier whenCallerHasKeeperRole() {
        vm.startPrank(keeper);
        _;
    }

    modifier whenGeneratedYieldIsNotEnoughToCoverCosts() {
        _;
    }

    modifier whenGeneratedYieldIsEnoughToCoverCosts() {
        aUsdc.mint(address(pool), 500e6);
        _;
    }

    modifier whenPrizeBelowMinPrize() {
        vrfWrapper.updateRequestPirce(15e18);
        _;
    }

    modifier whenPrizeEqualOrAboveMinPrize() {
        _;
    }

    modifier whenThereIsRemainingBalanceAfterSwap() {
        _;
    }

    modifier whenThereIsNoRemainingBalanceAfterSwap() {
        _;
    }

    // =================================== UNHAPPY TESTS ===================================

    function test_RevertWhen_NotKeeper() public whenCallerDoesNotHaveKeeperRole {
        // Expect to revert since caller does not have `KEEPER_ROLE` role.
        vm.expectRevert();
        pool.setPrize(drawId, POOL_FEE, SLIPPAGE);
    }

    function test_RevertWhen_InsufficientYield()
        public
        whenCallerHasKeeperRole
        whenGeneratedYieldIsNotEnoughToCoverCosts
    {
        // Expect to revert with `POOL_SET_PRIZE__NOT_ENOUGH_FUNDS` error.
        vm.expectRevert(POOL_SET_PRIZE__NOT_ENOUGH_FUNDS.selector);
        pool.setPrize(drawId, POOL_FEE, SLIPPAGE);
    }

    function test_RevertWhen_InsufficientPrize()
        public
        whenCallerHasKeeperRole
        whenGeneratedYieldIsEnoughToCoverCosts
        whenPrizeBelowMinPrize
    {
        // Expect to revert with `POOL_SET_PRIZE__PRIZE_TOO_SMALL` error.
        vm.expectRevert(POOL_SET_PRIZE__PRIZE_TOO_SMALL.selector);
        pool.setPrize(drawId, POOL_FEE, SLIPPAGE);
    }

    // ==================================== HAPPY TESTS ====================================

    function test_SetPrize_RemainingBalanceAfterSwap()
        public
        whenCallerHasKeeperRole
        whenGeneratedYieldIsEnoughToCoverCosts
        whenPrizeEqualOrAboveMinPrize
        whenThereIsRemainingBalanceAfterSwap
    {
        uint256 usdcAmountIn = _getUsdcAmountIn(drawManager.getRandomnessRequestCost(), POOL_FEE, SLIPPAGE);
        // Expect call to aave pool to withdraw funds.
        vm.expectCall(
            address(aavePool), abi.encodeCall(aavePool.withdraw, (address(usdc), usdcAmountIn, address(pool)))
        );
        // Expect call to swap router to swap USDC for LINK.
        ISwapRouter.ExactOutputSingleParams memory swapParams = ISwapRouter.ExactOutputSingleParams({
            tokenIn: address(usdc),
            tokenOut: drawManager.getLinkTokenAddress(),
            fee: POOL_FEE,
            recipient: address(drawManager),
            deadline: block.timestamp,
            amountOut: drawManager.getRandomnessRequestCost(),
            amountInMaximum: usdcAmountIn,
            sqrtPriceLimitX96: 0
        });
        vm.expectCall(address(swapRouter), abi.encodeCall(swapRouter.exactOutputSingle, (swapParams)));
        // Expect call to `drawManager` to award the draw.
        vm.expectCall(address(drawManager), abi.encodeCall(drawManager.awardDraw, (drawId)));
        // Expect call to aave pool to supply the remaining balance after swap.
        uint256 remainingAmount = usdcAmountIn - _getUsdcAmountIn(drawManager.getRandomnessRequestCost(), POOL_FEE, 0);
        vm.expectCall(
            address(aavePool), abi.encodeCall(aavePool.supply, (address(usdc), remainingAmount, address(pool), 0))
        );

        // Expect the `PrizeSet` event to be emitted
        vm.expectEmit(true, true, true, true);
        uint256 yield = aUsdc.balanceOf(address(pool)) - twabController.getTotalSupply();
        uint256 prize = (yield - usdcAmountIn) / MAX_CLAIMS;
        emit PrizeSet(drawId, prize, block.timestamp);

        // Set prize.
        pool.setPrize(drawId, POOL_FEE, SLIPPAGE);

        // Asserting that the prize for the draw was updated.
        assertEq(pool.getDrawPrize(drawId).amount, prize);
    }

    function test_SetPrize_NoRemainingBalanceAfterSwap()
        public
        whenCallerHasKeeperRole
        whenGeneratedYieldIsEnoughToCoverCosts
        whenPrizeEqualOrAboveMinPrize
        whenThereIsNoRemainingBalanceAfterSwap
    {
        uint256 usdcAmountIn = _getUsdcAmountIn(drawManager.getRandomnessRequestCost(), POOL_FEE, 0);
        // Expect call to aave pool to withdraw funds.
        vm.expectCall(
            address(aavePool), abi.encodeCall(aavePool.withdraw, (address(usdc), usdcAmountIn, address(pool)))
        );
        // Expect call to swap router to swap USDC for LINK.
        ISwapRouter.ExactOutputSingleParams memory swapParams = ISwapRouter.ExactOutputSingleParams({
            tokenIn: address(usdc),
            tokenOut: drawManager.getLinkTokenAddress(),
            fee: POOL_FEE,
            recipient: address(drawManager),
            deadline: block.timestamp,
            amountOut: drawManager.getRandomnessRequestCost(),
            amountInMaximum: usdcAmountIn,
            sqrtPriceLimitX96: 0
        });
        vm.expectCall(address(swapRouter), abi.encodeCall(swapRouter.exactOutputSingle, (swapParams)));
        // Expect call to `drawManager` to award the draw.
        vm.expectCall(address(drawManager), abi.encodeCall(drawManager.awardDraw, (drawId)));

        // Expect the `PrizeSet` event to be emitted
        vm.expectEmit(true, true, true, true);
        uint256 yield = aUsdc.balanceOf(address(pool)) - twabController.getTotalSupply();
        uint256 prize = (yield - usdcAmountIn) / MAX_CLAIMS;
        emit PrizeSet(drawId, prize, block.timestamp);

        // Set prize.
        pool.setPrize(drawId, POOL_FEE, 0);

        // Asserting that the prize for the draw was updated.
        assertEq(pool.getDrawPrize(drawId).amount, prize);
    }
}
