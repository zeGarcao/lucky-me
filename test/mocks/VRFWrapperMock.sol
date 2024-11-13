// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IVRFV2PlusWrapper} from "@chainlink/vrf/dev/interfaces/IVRFV2PlusWrapper.sol";

contract VRFWrapperMock is IVRFV2PlusWrapper {
    // TODO last request id code
    function lastRequestId() external view returns (uint256) {}

    // TODO request price code
    function calculateRequestPrice(uint32 _callbackGasLimit, uint32 _numWords) external view returns (uint256) {}

    // TODO request price native code
    function calculateRequestPriceNative(uint32 _callbackGasLimit, uint32 _numWords) external view returns (uint256) {}

    // TODO estimate request price code
    function estimateRequestPrice(uint32 _callbackGasLimit, uint32 _numWords, uint256 _requestGasPriceWei)
        external
        view
        returns (uint256)
    {}

    // TODO estimate request price native code
    function estimateRequestPriceNative(uint32 _callbackGasLimit, uint32 _numWords, uint256 _requestGasPriceWei)
        external
        view
        returns (uint256)
    {}

    // TODO request random words native
    function requestRandomWordsInNative(
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint32 _numWords,
        bytes calldata extraArgs
    ) external payable returns (uint256 requestId) {}

    // TODO link address code
    function link() external view returns (address) {}

    // TODO link native feed code
    function linkNativeFeed() external view returns (address) {}
}
