// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title MultiSigTimeLock
 * @dev Multi-signature time lock mechanism for admin functions.
 */
contract MultiSigTimeLock {
    address[] public adminAddresses;
    uint256 public requiredConfirmations;
    uint256 public timeLockDuration;
    uint256 public lastExecutionTime;
    mapping(address => bool) public isConfirmed;

    error NotAnAdmin();
    error TimeLockNotExpired();
    error AdminNotConfirmed();
    error NotEnoughAdminsConfirmed();
    error RequiredConfirmationsExceedNumberOfAdmins();

    /**
     * @dev Modifier to restrict access to only designated admins.
     */
    modifier onlyAdmin() {
        bool isAdmin = false;
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            if (adminAddresses[i] == msg.sender) {
                isAdmin = true;
                break;
            }
        }
        if(!isAdmin) revert NotAnAdmin();
        _;
    }

    /**
     * @dev Modifier to restrict access to only admins within the time lock and confirmed.
     */
    modifier onlyAdminsInTimeLockAndConfirmed() {
        if(block.timestamp < lastExecutionTime + timeLockDuration) revert TimeLockNotExpired();
        if(!isConfirmed[msg.sender]) revert AdminNotConfirmed();
        if(!areEnoughAdminsConfirmed()) revert NotEnoughAdminsConfirmed();
        _;
    }

    event Confirmation(address indexed admin);
    event Execution();

    /**
     * @dev Constructor to initialize the time lock parameters.
     * @param _timeLockDuration The duration of the time lock in seconds.
     * @param _adminAddresses The addresses of the designated admins.
     * @param _requiredConfirmations The number of confirmations required for execution.
     */
    constructor(uint256 _timeLockDuration, address[] memory _adminAddresses, uint256 _requiredConfirmations) {
        if(_requiredConfirmations > _adminAddresses.length) revert RequiredConfirmationsExceedNumberOfAdmins();
        timeLockDuration = _timeLockDuration;
        adminAddresses = _adminAddresses;
        requiredConfirmations = _requiredConfirmations;
        lastExecutionTime = block.timestamp;
    }

    /**
     * @dev Allows an admin to confirm their participation.
     */
    function confirm() external onlyAdmin {
        isConfirmed[msg.sender] = true;
        emit Confirmation(msg.sender);
    }

    /**
     * @dev Executes the admin function if conditions are met, resets confirmations, and updates the execution timestamp.
     */
    function execute() external onlyAdminsInTimeLockAndConfirmed {
        lastExecutionTime = block.timestamp;
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            isConfirmed[adminAddresses[i]] = false;
        }
        emit Execution();
    }

    /**
     * @dev Checks if the required number of admins have confirmed.
     */
    function areEnoughAdminsConfirmed() internal view returns (bool) {
        uint256 confirmations = 0;
        for (uint256 i = 0; i < adminAddresses.length; i++) {
            if (isConfirmed[adminAddresses[i]]) {
                confirmations++;
                if (confirmations >= requiredConfirmations) {
                    return true;
                }
            }
        }
        return false;
    }
}
