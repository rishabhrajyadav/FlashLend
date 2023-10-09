# FlashLend and FlashBorrower Contracts

## Overview

This repository contains two Solidity contracts: `FlashLend` and `FlashBorrower`. These contracts implement the ERC-3156 Flash Loan interface and allow for flash loans with a fee. Additionally, the `FlashLend` contract includes a multi-sig time lock mechanism for admin functions.

## FlashLend Contract

### Purpose

The `FlashLend` contract facilitates flash loans with a fee. It supports multiple tokens and includes advanced features such as a multi-sig time lock mechanism for admin functions.

### Functions

### Functions

1. **flashLoan**
   - Allows users to borrow tokens using a flash loan.
   - Parameters:
     - `receiver`: The contract receiving the tokens.
     - `token`: The loan currency.
     - `amount`: The amount of tokens lent.
     - `data`: Custom data passed to the receiver.
   - Emits `FlashLoanRequested` and `FlashLoanExecuted` events.

2. **addSupportedToken**
   - Allows authorized admins to add a supported token for flash loans.
   - Parameters:
     - `token`: The address of the token to be added.
   - Emits `SupportedTokenAdded` event.

3. **flashFee**
   - Returns the fee to be charged for a given loan.
   - Parameters:
     - `token`: The loan currency.
     - `amount`: The amount of tokens lent.

4. **maxFlashLoan**
   - Returns the maximum amount of currency available for flash loans.
   - Parameter:
     - `token`: The loan currency.

### Events

- `FlashLoanRequested`: Emitted when a flash loan is requested.
- `FlashLoanExecuted`: Emitted when a flash loan is executed successfully.
- `SupportedTokenAdded`: Emitted when a new token is added to the supported tokens list.

### Errors

- `UnsupportedCurrency`: Indicates that the requested currency is not supported.
- `TransferFailed`: Indicates that the token transfer failed.
- `CallbackFailed`: Indicates that the flash loan callback failed.
- `RepayFailed`: Indicates that the repayment transfer failed.
- `NotTheOwner`: Indicates that the caller is not the owner.

### Multi-Sig Time Lock

This contract includes a multi-sig time lock mechanism for admin functions. Admins can execute privileged functions only after a certain time lock duration.

## FlashBorrower Contract

### Purpose

The `FlashBorrower` contract implements the ERC-3156 Flash Borrower interface and interacts with a flash lender.

### Functions

1. **onFlashLoan**
   - ERC-3156 Flash loan callback.
   - Parameters:
     - `initiator`: The initiator of the flash loan.
     - `token`: The loan currency.
     - `amount`: The amount of tokens lent.
     - `fee`: The fee associated with the flash loan.
     - `data`: Arbitrary data passed by the flash lender.
   - Returns a bytes32 value representing the keccak256 hash of "ERC3156FlashBorrower.onFlashLoan".

2. **flashBorrow**
   - Initiates a flash loan with a normal action.
   - Parameters:
     - `token`: The loan currency.
     - `amount`: The amount of tokens to borrow.

3. **flashBorrowAndSteal**
   - Initiates a flash loan with a steal action.
   - Parameters:
     - `token`: The loan currency.
     - `amount`: The amount of tokens to borrow.

4. **flashBorrowAndReenter**
   - Initiates a flash loan with a reenter action.
   - Parameters:
     - `token`: The loan currency.
     - `amount`: The amount of tokens to borrow.

5. **approveRepayment**
   - Approves repayment for the flash loan.
   - Parameters:
     - `token`: The loan currency.
     - `amount`: The amount of tokens to approve for repayment.

### Events

- `FlashLoanInitiated`: Emitted when a flash loan is initiated.
- `FlashLoanCompleted`: Emitted when a flash loan is completed successfully.

### Errors

- `UntrustedLender`: Indicates that the flash lender is not trusted.
- `ExternalLoanInitiator`: Indicates that the loan initiator is not the expected contract.

## How to Interact with the Contracts

### FlashLend Contract

- Use the `flashLoan` function to borrow tokens.
- Add supported tokens using `addSupportedToken`.
- Check the fee for a loan with `flashFee`.
- Query the maximum flash loan amount with `maxFlashLoan`.

### FlashBorrower Contract

- Implement the `onFlashLoan` function to handle flash loans.
- Use `flashBorrow`, `flashBorrowAndSteal`, and `flashBorrowAndReenter` to initiate flash loans.
- Call `approveRepayment` to approve repayment for the flash loan.

## Events and Error Handling

- Events are emitted to provide information about flash loan activities.
- Errors are thrown to indicate issues during flash loans.

## Flash Loan Manager (LandAndFieldManager)

- A manager contract is available to interact with NFT collections and handle flash loans.

## Deployment Instructions

1. Deploy the `FlashLend` contract by providing the initial fee, time lock duration, admin addresses, and required confirmations as constructor parameters.

2. Deploy the `FlashBorrower` contract by providing the address of the deployed `FlashLend` contract as a constructor parameter.


