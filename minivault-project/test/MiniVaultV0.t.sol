// SPDX-License-Identifier: UNLICENSED 
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Receiver} from "./Receiver.sol";
import {MiniVaultV0, ZeroDeposit, ZeroAmount, ExceededAmount, EthSendFail} from "../src/MiniVaultV0.sol";


contract MiniVaultV0Test is Test { 
    MiniVaultV0 public miniVaultV0; 

    event Withdraw(address indexed from, uint256 value);
    event Deposit(address indexed from, uint256 value);     

    address user;

    function setUp() public { 
        miniVaultV0 = new MiniVaultV0();
        user = makeAddr("user");
    }    

    function test_Deposit() public { 
        vm.deal(user, 100 ether);
        vm.prank(user);
        miniVaultV0.deposit{value: 100 ether}();
        
        assertEq(user.balance, 0 ether);
        assertEq(miniVaultV0.totalDeposits(), 100 ether);
    }

    function test_Deposit_RevertWhenZero() public { 
        vm.expectRevert(ZeroDeposit.selector);
        miniVaultV0.deposit{value: 0 ether}();
    }

    function test_Deposit_EmitsEvent() public { 
        vm.deal(user, 100 ether);

        vm.expectEmit(true, false, false, true, address(miniVaultV0));
        emit Deposit(user, 100 ether);

        vm.prank(user);
        miniVaultV0.deposit{value: 100 ether}();
    }

    function test_Withdraw() public { 
        vm.deal(user, 100 ether);

        vm.startPrank(user);

        miniVaultV0.deposit{value: 100 ether}();
        miniVaultV0.withdraw(10 ether);

        vm.stopPrank();

        assertEq(user.balance, 10 ether);
        assertEq(miniVaultV0.totalDeposits(), 90 ether);
    }

    function test_Withdraw_RevertWhenZero() public { 
        vm.deal(user, 100 ether);

        vm.startPrank(user);

        miniVaultV0.deposit{value: 100 ether}();
        vm.expectRevert(ZeroAmount.selector);
        miniVaultV0.withdraw(0 ether);

        vm.stopPrank();
    }

    function test_Withdraw_RevertWhenExceeded() public { 
        vm.deal(user, 100 ether);

        vm.startPrank(user);

        miniVaultV0.deposit{value: 100 ether}();
        vm.expectRevert(ExceededAmount.selector);
        miniVaultV0.withdraw(101 ether);

        vm.stopPrank();
    }

    function test_Withdraw_RevertWhenFailSendEth() public { 
        address receiver = address(new Receiver());
        vm.deal(receiver, 1 ether);
        
        vm.startPrank(receiver);

        miniVaultV0.deposit{value: 1 ether}();
        vm.expectRevert(EthSendFail.selector);
        miniVaultV0.withdraw(1 ether);

        vm.stopPrank();
    }

    function testFuzz_Withdraw_EmitsEvent(uint256 x) public { 
        x = bound(x, 1, 100 ether);
        vm.deal(user, 100 ether);

        vm.startPrank(user); 
        miniVaultV0.deposit{value: 100 ether}();

        vm.expectEmit(true, false, false, true, address(miniVaultV0));
        emit Withdraw(user, x);

        miniVaultV0.withdraw(x);
        vm.stopPrank();
    }
}