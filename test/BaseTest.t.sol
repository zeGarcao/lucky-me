// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {Pool} from "@lucky-me/Pool.sol";
import {TwabController} from "@lucky-me/TwabController.sol";
import {AavePoolMock} from "./mocks/AavePoolMock.sol";
import {ERC20Mock} from "./mocks/ERC20Mock.sol";
import {LinkMock} from "./mocks/LinkMock.sol";
import {SwapRouterMock} from "./mocks/SwapRouterMock.sol";
import {QuoterMock} from "./mocks/QuoterMock.sol";
import {VRFWrapperMock} from "./mocks/VRFWrapperMock.sol";

abstract contract BaseTest is Test {
    ERC20Mock usdc;
    ERC20Mock aUsdc;
    LinkMock link;
    AavePoolMock aavePool;
    Pool pool;
    TwabController twabController;
    SwapRouterMock swapRouter;
    QuoterMock quoter;
    VRFWrapperMock vrfWrapper;

    address owner = makeAddr("owner");
    address bob = makeAddr("bob");
    address rando = makeAddr("rando");
    address keeper = makeAddr("keeper");

    function setUp() public virtual {
        // Skip 1 week in time
        skip(1 weeks);

        // Deploy mocks
        usdc = new ERC20Mock("USDC Mock", "USDC", 6);
        aUsdc = new ERC20Mock("aUSDC Mock", "aUSDC", 6);
        link = new LinkMock("LINK Mock", "LINK");
        aavePool = new AavePoolMock(address(aUsdc));
        quoter = new QuoterMock();
        swapRouter = new SwapRouterMock(address(quoter));
        vrfWrapper = new VRFWrapperMock(address(link));

        // Deploy Lucky Me pool
        vm.prank(owner);
        pool = new Pool(
            address(usdc),
            address(aavePool),
            address(aUsdc),
            keeper,
            address(vrfWrapper),
            address(swapRouter),
            address(quoter),
            block.timestamp
        );

        // Get twab controller
        twabController = TwabController(pool.TWAB_CONTROLLER());

        // Setup user account with USDC
        usdc.mint(bob, 1_000_000e6);
        vm.prank(bob);
        usdc.approve(address(pool), 1_000_000e6);
    }
}
