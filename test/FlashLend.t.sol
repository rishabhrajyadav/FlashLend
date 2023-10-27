// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {FlashLend} from "../src/FlashLend.sol";
import {FlashBorrower} from "../src/FlashBorrower.sol";
import {ERC20} from "../src/ERC20.sol";
import "../src/interfaces/IERC3156FlashBorrower.sol";

/**
 * @title FlashLendTest
 * @dev A testing contract to verify the functionality of the FlashLend and FlashBorrower contracts.
 */
contract FlashLendTest is Test {
    FlashLend public lender;
    FlashBorrower public borrower;
    ERC20 public weth;
   
    //Initial Setup
    function setUp() public {
       address[] memory adminAddresses = new address[](3);

       adminAddresses[0] = address(7);
       adminAddresses[1] = address(8);
       adminAddresses[2] = address(9);

        lender = new FlashLend(10 , 1 days , adminAddresses , 2);
        borrower = new FlashBorrower(lender);
        weth = new ERC20("Weth" , "WETH");

        weth._mint(address(lender), 1000);
    }
    
    // To test The MultiSigTimeLock In addSupportedToken Function
    function testAddSupportedToken() public {
        vm.warp(2 days);

        vm.prank(address(7));
        lender.confirm();

        vm.startPrank(address(8));
        lender.confirm();
        lender.addSupportedToken(address(weth));
        vm.stopPrank();
    }
    
    //To test the Flash Loan
     function testFlashLoan() public {
        vm.warp(2 days);

        vm.prank(address(7));
        lender.confirm();

        vm.startPrank(address(8));
        lender.confirm();
        lender.addSupportedToken(address(weth));
        vm.stopPrank();

       uint256 flashBalanceBefore = borrower.flashBalance();
       assertEq(flashBalanceBefore, 0); 

       vm.prank(address(4));
       borrower.flashBorrow(address(weth), 1);
       
       uint256 flashBalanceAfter = borrower.flashBalance();
       assertEq(flashBalanceAfter, 1);

       address flashToken = borrower.flashToken();
       assertEq(flashToken, address(weth));

       uint256 flashAmount = borrower.flashAmount();
       assertEq(flashAmount, 1);

       address initiator = borrower.flashInitiator();
       assertEq(initiator, address(borrower));
    }
    
    //To test the Flash Loan that pays Fee
    function testFlashLoanThatPaysFee() public {
        vm.warp(2 days);

        vm.prank(address(7));
        lender.confirm();

        vm.startPrank(address(8));
        lender.confirm();
        lender.addSupportedToken(address(weth));
        vm.stopPrank();

       uint256 loan = 1000;
       uint256 fees = lender.flashFee(address(weth), loan);

       vm.startPrank(address(4));
       weth._mint(address(borrower), 1);
       borrower.flashBorrow(address(weth), loan);
       vm.stopPrank();
       
       uint256 flashBalance = borrower.flashBalance();
       assertEq(flashBalance, loan + fees);

       address flashToken = borrower.flashToken();
       assertEq(flashToken, address(weth));

       uint256 flashAmount = borrower.flashAmount();
       assertEq(flashAmount, loan);

       address initiator = borrower.flashInitiator();
       assertEq(initiator, address(borrower));
    }
    
    //To test the ReentrancyAttack 
    function testFlashBorrowAndReenter() public {
         vm.warp(2 days);

        vm.prank(address(7));
        lender.confirm();

        vm.startPrank(address(8));
        lender.confirm();
        lender.addSupportedToken(address(weth));
        vm.stopPrank();

        vm.prank(address(4));
        vm.expectRevert();
        borrower.flashBorrowAndReenter(address(weth), 100);
    }
    
    //To test Borrow And Steal
    function testFlashBorrowAndSteal() public {
        vm.warp(2 days);

        vm.prank(address(7));
        lender.confirm();

        vm.startPrank(address(8));
        lender.confirm();
        lender.addSupportedToken(address(weth));
        vm.stopPrank();

        vm.prank(address(4));
        vm.expectRevert();
        borrower.flashBorrowAndSteal(address(weth), 100);
    }   

}