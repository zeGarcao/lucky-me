// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ITwabController} from "./interfaces/ITwabController.sol";
import {RingBufferLib} from "./libraries/RingBufferLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {BalanceIncreased, BalanceDecreased, ObservationRecorded} from "./utils/Events.sol";
import {MAX_CARDINALITY, PERIOD_LENGTH} from "./utils/Constants.sol";
import {Observation, AccountDetails} from "./utils/Structs.sol";
import {DECREASE_BALANCE__INSUFFICIENT_BALANCE} from "./utils/Errors.sol";

contract TwabController is ITwabController, Ownable {
    uint256 public immutable PERIOD_OFFSET;

    mapping(address => AccountDetails) public accounts;
    AccountDetails public totalSupplyAccount;

    constructor(uint256 _periodOffset) Ownable(msg.sender) {
        // @todo do checks on _periodOffset arg
        PERIOD_OFFSET = _periodOffset;
    }

    function increaseBalance(address _account, uint256 _amount) external onlyOwner returns (uint256) {
        (uint256 newBalance, Observation memory observation, bool isNewObservation) =
            _increaseBalance(accounts[_account], _amount);

        _increaseBalance(totalSupplyAccount, _amount);

        emit BalanceIncreased(_account, _amount, newBalance, block.timestamp);
        emit ObservationRecorded(_account, observation, isNewObservation);

        return newBalance;
    }

    function decreaseBalance(address _account, uint256 _amount) external onlyOwner returns (uint256) {
        (uint256 newBalance, Observation memory observation, bool isNewObservation) =
            _decreaseBalance(accounts[_account], _amount);

        _decreaseBalance(totalSupplyAccount, _amount);

        emit BalanceDecreased(_account, _amount, newBalance, block.timestamp);
        emit ObservationRecorded(_account, observation, isNewObservation);

        return newBalance;
    }

    function _increaseBalance(AccountDetails storage _account, uint256 _amount)
        internal
        returns (uint256 newBalance, Observation memory observation, bool isNewObservation)
    {
        newBalance = _account.balance + _amount;
        _account.balance = newBalance;

        (observation, isNewObservation) = _recordObservation(_account);
    }

    function _decreaseBalance(AccountDetails storage _account, uint256 _amount)
        internal
        returns (uint256 newBalance, Observation memory observation, bool isNewObservation)
    {
        uint256 currentBalance = _account.balance;
        require(_amount <= currentBalance, DECREASE_BALANCE__INSUFFICIENT_BALANCE());

        newBalance = currentBalance - _amount;
        _account.balance = newBalance;

        (observation, isNewObservation) = _recordObservation(_account);
    }

    function _recordObservation(AccountDetails storage _account)
        internal
        returns (Observation memory observation, bool isNew)
    {
        uint256 currentPeriod = _getPeriod(block.timestamp);

        uint256 lastObservationIndex = RingBufferLib.newestIndex(_account.nextObservationIndex, MAX_CARDINALITY);
        uint256 nextIndex = lastObservationIndex;
        Observation memory lastObservation = _account.observations[lastObservationIndex];
        uint256 lastPeriod = _getPeriod(lastObservation.timestamp);

        uint256 cardinality = _account.cardinality;
        isNew = cardinality == 0 || currentPeriod > lastPeriod;

        if (isNew) {
            nextIndex = _account.nextObservationIndex;
            _account.nextObservationIndex = RingBufferLib.nextIndex(lastObservationIndex, MAX_CARDINALITY);
            _account.cardinality = cardinality < MAX_CARDINALITY ? cardinality + 1 : MAX_CARDINALITY;
        }

        observation = Observation({
            balance: _account.balance,
            cumulativeBalance: lastObservation.cumulativeBalance
                + lastObservation.balance * (block.timestamp - lastObservation.timestamp),
            timestamp: block.timestamp
        });

        _account.observations[nextIndex] = observation;
    }

    function _getPeriod(uint256 timestamp) internal view returns (uint256) {
        if (timestamp < PERIOD_OFFSET) return 0;
        return (timestamp - PERIOD_OFFSET) / PERIOD_LENGTH;
    }
}
