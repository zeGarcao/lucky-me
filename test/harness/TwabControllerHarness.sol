// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {TwabController} from "@lucky-me/TwabController.sol";
import {Observation} from "@lucky-me/utils/Structs.sol";

contract TwabControllerHarness is TwabController {
    constructor(uint256 _periodOffset) TwabController(_periodOffset) {}

    function getPreviousOrAtObservation(address _account, uint256 _targetTime)
        external
        view
        returns (Observation memory)
    {
        return _getPreviousOrAtObservation(getAccount(_account), _targetTime);
    }
}
