// SPDX-License-Identifier: UNLICENSED 
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {MiniVaultV0} from "../src/MiniVaultV0.sol";


contract MiniVaultV0Test is Test { 
    MiniVaultV0 public miniVaultV0; 

    event Withdraw(address indexed from, uint256 value);
    event Deposit(address indexed from, uint256 value);     

    // why use address type variable `user` here? 
    address user;

    function setUp() public { 
        miniVaultV0 = new MiniVaultV0();
        // what is makeAddr?
        user = makeAddr("user");
    }    

    function test_Deposit_EmitsEvent() public { 
        vm.deal(user, 100 ether);

        vm.expectEmit(true, false, false, true, address(miniVaultV0));
        emit Deposit(user, 100 ether);

        vm.prank(user);
        miniVaultV0.deposit{value: 100 ether}();
    }

    function testFuzz_Withdraw_EmitsEvent(uint256 x) public { 
        x = bound(x, 1, 100 ether);
        vm.deal(user, 100 ether);

        // what is startPrank and stopPrank?
        vm.startPrank(user); 
        miniVaultV0.deposit{value: 100 ether}();

        // how to explain this code? what is expectEmit and it's optinal params?
        vm.expectEmit(true, false, false, true, address(miniVaultV0));
        emit Withdraw(user, x);

        miniVaultV0.withdraw(x);
        vm.stopPrank();

        // whiat is bound, deal, prank?
    }
}