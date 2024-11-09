// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Draw, Request, RequestConfig} from "@lucky-me/utils/Structs.sol";

// TODO documentation
interface IDrawManager {
    /**
     * @notice Awards a draw with a prize and random number.
     * @dev Must only be called by the owner.
     * @param _drawId Id of the draw to be awarded.
     * @param _prize Prize amount to award the draw.
     */
    function awardDraw(uint256 _drawId, uint256 _prize) external;

    /**
     * @notice Updates Chainlink's request configuration.
     * @dev Must only be called by the owner.
     * @param _callbackGasLimit Limit of gas amount that can be consumed by the callback.
     * @param _requestConfirmations Number of confirmations for the randomness request.
     */
    function updateRequestConfig(uint32 _callbackGasLimit, uint16 _requestConfirmations) external;

    /**
     * @notice Fetches the cost of the randomness request.
     * @return Randomness request cost.
     */
    function getRandomnessRequestCost() external view returns (uint256);

    /**
     * @notice Retrieves the randomness request configuration.
     * @return RequestConfig data structure.
     */
    function getRequestConfig() external view returns (RequestConfig memory);

    /**
     * @notice Retrieves the id of the current open draw.
     * @return Id of current open draw.
     */
    function getCurrentOpenDrawId() external view returns (uint256);

    /**
     * @notice Retrieves the draw with id `_drawId`.
     * @dev Id starts at 1.
     * @param _drawId Id of the draw.
     * @return Draw data structure.
     */
    function getDraw(uint256 _drawId) external view returns (Draw memory);

    /**
     * @notice Retrieves the request with id `_requestId`.
     * @param _requestId Id of the request.
     * @return Request data structure.
     */
    function getRequest(uint256 _requestId) external view returns (Request memory);

    /**
     * @notice Retrieves whether the draw with id `_drawId` is open or not.
     * @param _drawId Id of the draw.
     * @return Flag indicating if draw is open.
     */
    function isDrawOpen(uint256 _drawId) external view returns (bool);

    /**
     * @notice Retrieves whether the draw with id `_drawId` is closed or not.
     * @param _drawId Id of the draw.
     * @return Flag indicating if draw is closed.
     */
    function isDrawClosed(uint256 _drawId) external view returns (bool);

    /**
     * @notice Retrieves whether the draw with id `_drawId` is awarded or not.
     * @param _drawId Id of the draw.
     * @return Flag indicating if draw is awarded.
     */
    function isDrawAwarded(uint256 _drawId) external view returns (bool);

    /**
     * @notice Retrieves whether the draw with id `_drawId` is finalized or not.
     * @param _drawId Id of the draw.
     * @return Flag indicating if draw is finalized.
     */
    function isDrawFinalized(uint256 _drawId) external view returns (bool);

    /**
     * @notice Retrieves Link token address used as the payment token for Chainlink's VRF service.
     * @return Link token address.
     */
    function getLinkTokenAddress() external view returns (address);

    /**
     * @notice Retrieves the timestamp where the first draw began.
     * @return Genesis draw start time.
     */
    function GENESIS_START_TIME() external view returns (uint256);
}
