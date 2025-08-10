// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function test_Decrment() public { 
        counter.setNumber(1);
        counter.decrement();
        assertEq(counter.number(), 0);
    }

    function test_Decrment_RevertWhenZero() public { 
        counter.setNumber(0);

        // 왜 bytes를 써야할까?
        vm.expectRevert(bytes("Already zero"));
        counter.decrement();
    }

    function test_Get() public { 
        counter.setNumber(0);

        assertEq(counter.get(), 0);
    }

    // testFuzz_ 하면 Foundry가 값을 반복해서 자동으로 넣어줌
    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
