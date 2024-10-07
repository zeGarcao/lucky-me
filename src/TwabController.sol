// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {ITwabController} from "./interfaces/ITwabController.sol";
import {RingBufferLib} from "./libraries/RingBufferLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract TwabController is ITwabController, Ownable {
    event BalanceIncreased(address indexed user, uint256 amount, uint256 balance);
    event BalanceDecreased(address indexed user, uint256 amount, uint256 balance);
    event ObservationRecorded(address indexed user, Observation observation, bool isNew);

    uint256 public constant MAX_CARDINALITY = 17520;
    uint256 public constant PERIOD_LENGTH = 1 hours;

    uint256 public immutable PERIOD_OFFSET;

    struct Observation {
        uint256 balance;
        uint256 cumulativeBalance;
        uint256 timestamp;
    }

    struct Account {
        uint256 balance;
        uint256 nextObservationIndex;
        uint256 cardinality;
        Observation[MAX_CARDINALITY] observations;
    }

    mapping(address => Account) public accounts;
    Account public totalSupplyAccount;

    constructor(uint256 _periodOffset) Ownable(msg.sender) {
        // @todo do checks on _periodOffset arg
        PERIOD_OFFSET = _periodOffset;
    }

    function increaseBalance(address _account, uint256 _amount) external returns (uint256) {
        Account storage account = accounts[_account];
        uint256 newBalance = account.balance + _amount;
        account.balance = newBalance;
        (Observation memory observation, bool isNew) = _recordObservation(account);

        _increaseTotalSupply(_amount);

        emit BalanceIncreased(_account, _amount, newBalance);
        emit ObservationRecorded(_account, observation, isNew);

        return newBalance;
    }

    function decreaseBalance(address _account, uint256 _amount) external returns (uint256) {
        Account storage account = accounts[_account];
        uint256 newBalance = account.balance - _amount;
        account.balance = newBalance;
        (Observation memory observation, bool isNew) = _recordObservation(account);

        _decreaseTotalSupply(_amount);

        emit BalanceDecreased(_account, _amount, newBalance);
        emit ObservationRecorded(_account, observation, isNew);

        return newBalance;
    }

    function _increaseTotalSupply(uint256 _amount) internal {
        totalSupplyAccount.balance += _amount;
        _recordObservation(totalSupplyAccount);
    }

    function _decreaseTotalSupply(uint256 _amount) internal {
        totalSupplyAccount.balance -= _amount;
        _recordObservation(totalSupplyAccount);
    }

    function _recordObservation(Account storage _account)
        internal
        returns (Observation memory observation, bool isNew)
    {
        uint256 currentPeriod = _getPeriod(block.timestamp);
        uint256 lastObservationIndex = RingBufferLib.newestIndex(_account.nextObservationIndex, MAX_CARDINALITY);
        uint256 nextIndex = lastObservationIndex;
        Observation memory lastObservation = _account.observations[lastObservationIndex];
        uint256 lastPeriod = _getPeriod(lastObservation.timestamp);
        isNew = _account.cardinality == 0 || currentPeriod > lastPeriod;

        if (_account.cardinality == 0 || currentPeriod > lastPeriod) {
            nextIndex = _account.nextObservationIndex;
            _account.nextObservationIndex = RingBufferLib.nextIndex(lastObservationIndex, MAX_CARDINALITY);
            _account.cardinality = _account.cardinality < MAX_CARDINALITY ? _account.cardinality + 1 : MAX_CARDINALITY;
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
        return (timestamp - PERIOD_OFFSET) / PERIOD_LENGTH;
    }
}
