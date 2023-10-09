// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC3156FlashBorrower.sol";
import "./interfaces/IERC3156FlashLender.sol";
import "./ReentrancyGuard.sol";
import "./MultiSigTimeLock.sol";

/**
 * @title FlashLend
 * @dev A contract that implements the ERC-3156 Flash Loan interface and allows for flash loans with a fee.
 */
contract FlashLend is IERC3156FlashLender , ReentrancyGuard , MultiSigTimeLock {

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint256 public fee; //  1 == 0.01 %.
    //address public immutable owner;
    mapping(address => bool) public supportedTokens;
    
    //Events
    event FlashLoanRequested(address indexed borrower, address indexed token, uint256 amount, uint256 fee, bytes data);
    event FlashLoanExecuted(address indexed borrower, address indexed token, uint256 amount, uint256 fee, bytes data);
    event SupportedTokenAdded(address indexed token);
    
    //Custom Errors
    error UnsupportedCurrency();
    error TransferFailed();
    error CallbackFailed();
    error RepayFailed();
    error NotTheOwner();
    
    /**
     * @dev Constructor to set the owner, initial fee, and time lock parameters.
     * @param _fee The fee percentage for flash loans.
     * @param _timeLockDuration The duration of the time lock period.
     * @param _adminAddresses The addresses of the administrators.
     * @param _requiredConfirmations The number of required confirmations.
     */
    constructor(uint256 _fee, uint256 _timeLockDuration, address[] memory _adminAddresses, uint256 _requiredConfirmations) MultiSigTimeLock(_timeLockDuration, _adminAddresses, _requiredConfirmations) {
        fee = _fee;
    }

    /**
     * @dev Loan `amount` tokens to `receiver`, and takes it back plus a `flashFee` after the callback.
     * @param receiver The contract receiving the tokens, needs to implement the `onFlashLoan(address user, uint256 amount, uint256 fee, bytes calldata)` interface.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data A data parameter to be passed on to the `receiver` for any custom use.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant override returns(bool) {
        if(!supportedTokens[token]) revert UnsupportedCurrency();
        
        uint256 _fee = _flashFee(token, amount);

        emit FlashLoanRequested(msg.sender, token, amount, _fee, data);

        if(!IERC20(token).transfer(address(receiver), amount)) revert TransferFailed();
        if(receiver.onFlashLoan(msg.sender, token, amount, _fee, data) != CALLBACK_SUCCESS) revert CallbackFailed();
        if(!IERC20(token).transferFrom(address(receiver), address(this), amount + _fee)) revert RepayFailed();
        
        emit FlashLoanExecuted(msg.sender, token, amount, _fee, data);

        return true;
    }

     /**
      * @notice Adds a supported token to the list of allowed flash loan currencies.
      * @dev This function can only be called by admins in the time lock and after being confirmed by enough admins.
      * @param token The address of the token to be added as a supported token.
      * @notice Emits a `SupportedTokenAdded` event upon successful addition.
      */
    function addSupportedToken(address token) external onlyAdminsInTimeLockAndConfirmed {
       supportedTokens[token] = true;
       emit SupportedTokenAdded(token);
    }

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view override returns (uint256) {
        if(!supportedTokens[token]) revert UnsupportedCurrency();
        return _flashFee(token, amount);
    }

    /**
     * @dev The fee to be charged for a given loan. Internal function with no checks.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function _flashFee(
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        return amount * fee / 10000;
    }

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token
    ) external view override returns (uint256) {
        return supportedTokens[token] ? IERC20(token).balanceOf(address(this)) : 0;
    }
}