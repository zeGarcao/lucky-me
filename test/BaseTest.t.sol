// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";

import {Pool} from "@lucky-me/Pool.sol";
import {TwabController} from "@lucky-me/TwabController.sol";

import {AavePoolMock} from "./mocks/AavePoolMock.sol";
import {USDCMock} from "./mocks/USDCMock.sol";

abstract contract BaseTest is Test {
    USDCMock usdc;
    AavePoolMock aavePool;
    Pool pool;
    TwabController twabController;

    address owner = makeAddr("owner");
    address bob = makeAddr("bob");

    function setUp() public virtual {
        usdc = new USDCMock();
        aavePool = new AavePoolMock();

        vm.prank(owner);
        pool = new Pool(address(usdc), address(aavePool), block.timestamp);

        twabController = TwabController(pool.twabController());

        usdc.mint(bob, 1_000_000e6);
        vm.prank(bob);
        usdc.approve(address(pool), 1_000_000e6);
    }
}
