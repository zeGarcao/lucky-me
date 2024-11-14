// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ERC20Mock} from "./ERC20Mock.sol";

contract LinkMock is ERC20Mock {
    constructor(string memory _tokenName, string memory _tokenSymbol) ERC20Mock(_tokenName, _tokenSymbol, 18) {}

    function transferAndCall(address to, uint256 value, bytes calldata) external returns (bool success) {
        _transfer(msg.sender, to, value);
        success = true;
    }
}
