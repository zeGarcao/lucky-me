// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDrawManager} from "@lucky-me/interfaces/IDrawManager.sol";
import {
    DRAW_INIT__INVALID_GENESIS_START_TIME,
    DRAW_AWARD_DRAW__REQUEST_ALREADY_SENT,
    DRAW_REQUEST_CONFIG__INVALID_CALLBACK_GAS_LIMIT,
    DRAW_REQUEST_CONFIG__INVALID_REQUEST_CONFIRMATIONS
} from "@lucky-me/utils/Errors.sol";
import {DRAW_DURATION, DEFAULT_CALLBACK_GAS_LIMIT, DEFAULT_REQUEST_CONFIRMATIONS} from "@lucky-me/utils/Constants.sol";
import {RequestStatus} from "@lucky-me/utils/Enums.sol";
import {Draw, Request, RequestConfig} from "@lucky-me/utils/Structs.sol";
import {RandomnessRequestSent, RandomnessRequestFulFilled, RequestConfigUpdated} from "@lucky-me/utils/Events.sol";
import {VRFV2PlusWrapperConsumerBase} from "@chainlink/vrf/dev/VRFV2PlusWrapperConsumerBase.sol";
import {VRFV2PlusClient} from "@chainlink/vrf/dev/libraries/VRFV2PlusClient.sol";

// TODO documentation
contract DrawManager is IDrawManager, Ownable, VRFV2PlusWrapperConsumerBase {
    /// @notice Genesis draw start time.
    uint256 public immutable GENESIS_START_TIME;

    /// @notice Mapping that tracks randomness requests by their ids.
    mapping(uint256 => Request) private _requests;
    /// @notice Mapping that tracks draws by their ids.
    mapping(uint256 => Draw) private _draws;

    /// @notice Configuration for randomness requests.
    RequestConfig private _requestConfig;

    /* ===================== Constructor ===================== */

    // TODO documentation
    constructor(uint256 _genesisStartTime, address _wrapperAddress)
        Ownable(msg.sender)
        VRFV2PlusWrapperConsumerBase(_wrapperAddress)
    {
        require(_genesisStartTime >= block.timestamp, DRAW_INIT__INVALID_GENESIS_START_TIME());

        GENESIS_START_TIME = _genesisStartTime;
        _requestConfig = RequestConfig({
            callbackGasLimit: DEFAULT_CALLBACK_GAS_LIMIT,
            requestConfirmations: DEFAULT_REQUEST_CONFIRMATIONS
        });
    }

    /* ===================== Public & External Functions ===================== */

    /// @inheritdoc IDrawManager
    function awardDraw(uint256 _drawId, uint256 _prize) external onlyOwner {
        Draw storage draw = _draws[_drawId];
        // Reverts if randomness request was already sent for the draw.
        require(_requests[draw.requestId].status == RequestStatus.NOT_SENT, DRAW_AWARD_DRAW__REQUEST_ALREADY_SENT());

        // Requests a random number from Chainlink.
        (uint256 requestId,) = requestRandomness(
            _requestConfig.callbackGasLimit,
            _requestConfig.requestConfirmations,
            1,
            VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        );

        // Marks the request as pending.
        _requests[requestId].status = RequestStatus.PENDING;

        // Sets the prize and assigns the request id to the draw.
        draw.prize = _prize;
        draw.requestId = requestId;

        emit RandomnessRequestSent(requestId, _drawId, block.timestamp);
    }

    /// @inheritdoc IDrawManager
    function updateRequestConfig(uint32 _callbackGasLimit, uint16 _requestConfirmations) external onlyOwner {
        // Reverts if the callback gas limit is zero.
        require(_callbackGasLimit != 0, DRAW_REQUEST_CONFIG__INVALID_CALLBACK_GAS_LIMIT());
        // Reverts if the number of request confirmations is zero.
        require(_requestConfirmations != 0, DRAW_REQUEST_CONFIG__INVALID_REQUEST_CONFIRMATIONS());

        // Updates the randomness request configuration.
        _requestConfig =
            RequestConfig({callbackGasLimit: _callbackGasLimit, requestConfirmations: _requestConfirmations});

        emit RequestConfigUpdated(_callbackGasLimit, _requestConfirmations, block.timestamp);
    }

    /// @inheritdoc IDrawManager
    function getRandomnessRequestCost() public view returns (uint256) {
        return i_vrfV2PlusWrapper.calculateRequestPrice(_requestConfig.callbackGasLimit, 1);
    }

    /// @inheritdoc IDrawManager
    function getRequestConfig() public view returns (RequestConfig memory) {
        return _requestConfig;
    }

    /// @inheritdoc IDrawManager
    function getCurrentOpenDrawId() public view returns (uint256) {
        if (block.timestamp < GENESIS_START_TIME) return 1;
        return ((block.timestamp - GENESIS_START_TIME) / DRAW_DURATION) + 1;
    }

    /// @inheritdoc IDrawManager
    function getDraw(uint256 _drawId) public view returns (Draw memory) {
        return _draws[_drawId];
    }

    /// @inheritdoc IDrawManager
    function getRequest(uint256 _requestId) public view returns (Request memory) {
        return _requests[_requestId];
    }

    /// @inheritdoc IDrawManager
    function isDrawOpen(uint256 _drawId) public view returns (bool) {
        return _drawId == getCurrentOpenDrawId();
    }

    /// @inheritdoc IDrawManager
    function isDrawClosed(uint256 _drawId) public view returns (bool) {
        uint256 currentOpenDrawId = getCurrentOpenDrawId();
        // No closed draws if we are in the genesis draw.
        if (currentOpenDrawId < 2) return false;

        // Retrieves the randomness request status for the draw.
        uint256 requestId = getDraw(_drawId).requestId;
        RequestStatus requestStatus = getRequest(requestId).status;

        // Draw is closed if it is the previous draw and hasn't been awarded yet.
        return _drawId == currentOpenDrawId - 1 && requestStatus != RequestStatus.FULFILLED;
    }

    /// @inheritdoc IDrawManager
    function isDrawAwarded(uint256 _drawId) public view returns (bool) {
        uint256 currentOpenDrawId = getCurrentOpenDrawId();
        // No awarded draws if we are in the genesis draw.
        if (currentOpenDrawId < 2) return false;

        // Retrieves the randomness request status for the draw.
        uint256 requestId = getDraw(_drawId).requestId;
        RequestStatus requestStatus = getRequest(requestId).status;

        // Draw is awarded if it is the previous draw and has been awarded.
        return _drawId == currentOpenDrawId - 1 && requestStatus == RequestStatus.FULFILLED;
    }

    /// @inheritdoc IDrawManager
    function isDrawFinalized(uint256 _drawId) public view returns (bool) {
        uint256 currentOpenDrawId = getCurrentOpenDrawId();
        // No finalized draws if we are in the genesis draw or the next one.
        if (currentOpenDrawId < 3) return false;

        // Draw is finalized when it is older than the previous draw of the current draw.
        return _drawId < currentOpenDrawId - 1;
    }

    /// @inheritdoc IDrawManager
    function getLinkTokenAddress() public view returns (address) {
        return i_vrfV2PlusWrapper.link();
    }

    /* ===================== Internal & Private Functions ===================== */

    /**
     * @notice Receives the random number from Chainlink and stores it.
     * @param _requestId Id of the randomness request.
     * @param _randomWords Random number.
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        // Marks randomness request as fulfilled and stores the random number retrieved from Chainlink.
        Request storage request = _requests[_requestId];
        request.status = RequestStatus.FULFILLED;
        request.randomNumber = _randomWords[0];

        emit RandomnessRequestFulFilled(_requestId, block.timestamp);
    }
}
