// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";

abstract contract BaseTest is Test {
    uint256 constant FORK_BLOCK_NUMBER = 21573952;

    function setUp() public virtual {
        vm.createSelectFork(vm.rpcUrl("mainnet"), FORK_BLOCK_NUMBER);
    }
}
