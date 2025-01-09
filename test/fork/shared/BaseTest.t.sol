// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAavePool} from "@lucky-me/interfaces/IAavePool.sol";
import {ISwapRouter} from "@lucky-me/interfaces/ISwapRouter.sol";
import {IQuoter} from "@lucky-me/interfaces/IQuoter.sol";
import {Pool} from "@lucky-me/Pool.sol";
import {TwabController} from "@lucky-me/TwabController.sol";
import {DrawManager} from "@lucky-me/DrawManager.sol";

abstract contract BaseTest is Test {
    uint256 constant FORK_BLOCK_NUMBER = 21573952;

    // external tokens
    IERC20 constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 constant A_USDC = IERC20(0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c);
    IERC20 constant LINK = IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA);

    // external protocols
    IAavePool constant AAVE_POOL = IAavePool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
    ISwapRouter constant SWAP_ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IQuoter constant QUOTER = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);
    address constant VRF_WRAPPER = 0x02aae1A04f9828517b3007f83f6181900CaD910c;

    // internal contracts
    TwabController twabController;
    DrawManager drawManager;
    Pool pool;

    // actors
    address owner = makeAddr("owner");
    address keeper = makeAddr("keeper");
    address bob = makeAddr("bob");

    function setUp() public virtual {
        // fork ethereum mainnet
        vm.createSelectFork(vm.rpcUrl("mainnet"), FORK_BLOCK_NUMBER);

        // Set luck factor list
        uint256[] memory luckFactor = new uint256[](13);
        luckFactor[0] = 1000;
        luckFactor[1] = 1000;
        luckFactor[2] = 1000;
        luckFactor[3] = 5000;
        luckFactor[4] = 5000;
        luckFactor[5] = 5000;
        luckFactor[6] = 5000;
        luckFactor[7] = 10000;
        luckFactor[8] = 10000;
        luckFactor[9] = 10000;
        luckFactor[10] = 10000;
        luckFactor[11] = 10000;
        luckFactor[12] = 15000;

        // deploy pool
        vm.prank(owner);
        pool = new Pool(
            address(USDC),
            address(AAVE_POOL),
            address(A_USDC),
            keeper,
            address(VRF_WRAPPER),
            address(SWAP_ROUTER),
            address(QUOTER),
            block.timestamp,
            luckFactor
        );

        // Get twab controller & draw manager
        twabController = TwabController(pool.TWAB_CONTROLLER());
        drawManager = DrawManager(pool.DRAW_MANAGER());

        // Set up actors' funds
        deal(address(USDC), bob, 1_000_000e6, true);
        vm.prank(bob);
        USDC.approve(address(pool), 1_000_000e6);
    }
}
