// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC3156FlashBorrower.sol";
import "./interfaces/IERC3156FlashLender.sol";

/**
 * @title FlashBorrower
 * @dev A contract that implements the ERC-3156 Flash Borrower interface and interacts with a flash lender.
 */
contract FlashBorrower is IERC3156FlashBorrower {
    enum Action {NORMAL, STEAL, REENTER}

    IERC3156FlashLender lender;

    uint256 public flashBalance;
    address public flashInitiator;
    address public flashToken;
    uint256 public flashAmount;
    uint256 public flashFee;
    
    //Events
    event FlashLoanInitiated(Action action, address initiator, address token, uint256 amount, uint256 fee);
    event FlashLoanCompleted(Action action, address initiator, address token, uint256 amount, uint256 fee);
    
    //Custom Errors
    error UntrustedLender();
    error ExternalLoanInitiator();
   
   /**
     * @dev Constructor to set the flash lender.
     * @param lender_ The address of the flash lender.
     */
   constructor (IERC3156FlashLender lender_) {
        lender = lender_;
    }

     /**
     * @dev ERC-3156 Flash loan callback
     * @param initiator The initiator of the flash loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The fee associated with the flash loan.
     * @param data Arbitrary data passed by the flash lender.
     * @return A bytes32 value representing the keccak256 hash of "ERC3156FlashBorrower.onFlashLoan".
     */
    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data) external override returns(bytes32) {
        if(msg.sender != address(lender)) revert UntrustedLender();
        if(initiator != address(this)) revert ExternalLoanInitiator();
        
        (Action action) = abi.decode(data, (Action)); // Use this to unpack arbitrary data

        flashInitiator = initiator;
        flashToken = token;
        flashAmount = amount;
        flashFee = fee;
        
        if (action == Action.NORMAL) {
            flashBalance = IERC20(token).balanceOf(address(this));
        } else if (action == Action.STEAL) {
            // do nothing
        } else if (action == Action.REENTER) {
            flashBorrow(token, amount * 2);
        }

        emit FlashLoanCompleted(action, initiator, token, amount, fee);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
    
    /**
     * @dev Initiates a flash loan with normal action.
     * @param token The loan currency.
     * @param amount The amount of tokens to borrow.
     */
    function flashBorrow(address token, uint256 amount) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.NORMAL);
        approveRepayment(token, amount);
        lender.flashLoan(this, token, amount, data);
        emit FlashLoanInitiated(Action.NORMAL, address(this), token, amount, lender.flashFee(token, amount));
    }
    
    /**
     * @dev Initiates a flash loan with steal action.
     * @param token The loan currency.
     * @param amount The amount of tokens to borrow.
     */
    function flashBorrowAndSteal(address token, uint256 amount) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.STEAL);
        lender.flashLoan(this, token, amount, data);
        emit FlashLoanInitiated(Action.STEAL, address(this), token, amount, lender.flashFee(token, amount));
    }
    
    /**
     * @dev Initiates a flash loan with reenter action.
     * @param token The loan currency.
     * @param amount The amount of tokens to borrow.
     */
    function flashBorrowAndReenter(address token, uint256 amount) public {
        // Use this to pack arbitrary data to `onFlashLoan`
        bytes memory data = abi.encode(Action.REENTER);
        approveRepayment(token, amount);
        lender.flashLoan(this, token, amount, data);
        emit FlashLoanInitiated(Action.REENTER, address(this), token, amount, lender.flashFee(token, amount));
    }
    
     /**
     * @dev Approves repayment for the flash loan.
     * @param token The loan currency.
     * @param amount The amount of tokens to approve for repayment.
     */
    function approveRepayment(address token, uint256 amount) public {
        uint256 _allowance = IERC20(token).allowance(address(this), address(lender));
        uint256 _fee = lender.flashFee(token, amount);
        uint256 _repayment = amount + _fee;
        IERC20(token).approve(address(lender), _allowance + _repayment);
    }
}