// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IVRFV2PlusWrapper} from "@chainlink/vrf/dev/interfaces/IVRFV2PlusWrapper.sol";
import {VRFV2PlusWrapperConsumerBase} from "@chainlink/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";

contract VRFWrapperMock is IVRFV2PlusWrapper {
    uint256 public constant DEFAULT_PRICE = 0.25e18;
    address immutable LINK;
    uint256 _lastRequestId;
    uint256 _price;

    constructor(address _linkAddress) {
        LINK = _linkAddress;
        _price = DEFAULT_PRICE;
    }

    function lastRequestId() external view returns (uint256) {
        return _lastRequestId;
    }

    function calculateRequestPrice(uint32, uint32) external view returns (uint256) {
        return _price;
    }

    // Mock function to update request price
    function updateRequestPirce(uint256 _newPrice) external {
        _price = _newPrice;
    }

    function calculateRequestPriceNative(uint32, uint32) external view returns (uint256) {
        /* Not necessary */
        return 0;
    }

    function estimateRequestPrice(uint32, uint32, uint256) external view returns (uint256) {
        /* Not necessary */
        return 0;
    }

    function estimateRequestPriceNative(uint32, uint32, uint256) external view returns (uint256) {
        /* Not necessary */
        return 0;
    }

    function requestRandomWordsInNative(uint32, uint16, uint32, bytes calldata)
        external
        payable
        returns (uint256 requestId)
    {
        /* Not necessary */
        return 0;
    }

    function link() external view returns (address) {
        return LINK;
    }

    function linkNativeFeed() external view returns (address) {
        /* Not necessary */
        return address(0);
    }

    // Mock function to fulfill random request
    function fulfillRandomWords(address _consumer, uint256 _requestId, uint256[] memory _randomWords) external {
        _lastRequestId += 1;
        VRFV2PlusWrapperConsumerBase(_consumer).rawFulfillRandomWords(_requestId, _randomWords);
    }
}
