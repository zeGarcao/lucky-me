// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IAavePool} from "@lucky-me/interfaces/IAavePool.sol";
import {ERC20Mock} from "./ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IER20.sol";

contract AavePoolMock is IAavePool {
    ERC20Mock immutable _receiptToken;

    constructor(address _receiptTokenAddress) {
        _receiptToken = ERC20Mock(_receiptTokenAddress);
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16) external {
        // transfer the assets from `onBehalfOf` to this contract
        IERC20(asset).transferFrom(onBehalfOf, address(this), amount);
        // mint receipt tokens to `onBehalfOf`
        _receiptToken.mint(onBehalfOf, amount);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        // check if caller has enough receipt tokens
        require(_receiptToken.balanceOf(msg.sender) >= amount, "AAVE: not enough funds");
        // burn receipt tokens
        _receiptToken.burn(msg.sender, amount);
        // transfer underlying asset to `to`
        IERC20(asset).transfer(to, amount);
        // return final amount withdrawn
        return amount;
    }

    // Mock function to generate yield
    function updateYield(address asset, address account, uint256 amount) external {
        _receiptToken.mint(account, amount);
        ERC20Mock(asset).mint(address(this), amount);
    }
}
