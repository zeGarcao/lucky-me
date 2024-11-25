// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Request, RequestConfig} from "@lucky-me/utils/Structs.sol";

// TODO documentation
interface IDrawManager {
    /**
     * @notice Awards a draw with a random number.
     * @dev Must be called only by address with OWNER_ROLE role.
     * @param _drawId Id of the draw to be awarded.
     */
    function awardDraw(uint256 _drawId) external;

    /**
     * @notice Updates Chainlink's request configuration.
     * @dev Must be called only by address with ADMIN_ROLE role.
     * @param _callbackGasLimit Limit of gas amount that can be consumed by the callback.
     * @param _requestConfirmations Number of confirmations for the randomness request.
     */
    function updateRequestConfig(uint32 _callbackGasLimit, uint16 _requestConfirmations) external;

    /**
     * @notice Updates the admin address.
     * @dev Must be called only by address with ADMIN_ROLE role.
     * @param _admin Address of new admin.
     */
    function updateAdmin(address _admin) external;

    /**
     * @notice Retrieves the draw random number.
     * @param _drawId Id of the draw.
     * @return Random number of the draw.
     */
    function getDrawRandomNumber(uint256 _drawId) external view returns (uint256);

    /**
     * @notice Retrieves request id of a specific draw id.
     * @param _drawId Id of the draw.
     * @return Id of randomness request.
     */
    function drawToRequestId(uint256 _drawId) external view returns (uint256);

    /**
     * @notice Retrieves the address of the admin.
     * @return Address of the admin.
     */
    function admin() external view returns (address);

    /**
     * @notice Retrieves the start and end period for a specific draw.
     * @param _drawId Id of the draw.
     * @return startTime Start time of the draw.
     * @return endTime End time of the draw.
     */
    function getDrawPeriod(uint256 _drawId) external view returns (uint256 startTime, uint256 endTime);

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
