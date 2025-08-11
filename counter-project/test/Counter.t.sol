// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {Counter, AlreadyZero, Overflow} from "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    event Set(uint256 newNumber);
    event Increment(uint256 newNumber);
    event Decrement(uint256 newNumber);

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function test_Decrement() public { 
        counter.setNumber(1);
        counter.decrement();
        assertEq(counter.number(), 0);
    }

    function test_Decrement_RevertWhenZero() public { 
        // counter.setNumber(0);
        // 왜 bytes를 써야할까?
        /**
            EVM 리버트 리턴 데이터는 모두 bytes 형태 
            문자열 리버트는 실제로 
            - 함수 셀렉터: Error(string) + 0x08c379a0
            - 이어서 ABI 인코딩된 string 
         */
        // vm.expectRevert(bytes("Already zero"));
        vm.expectRevert(AlreadyZero.selector);
        counter.decrement();
    }

    function test_Increment_RevertWhenMax() public { 
        counter.setNumber(type(uint256).max);
        
        vm.expectRevert(Overflow.selector);
        counter.increment();
    }

    function test_Increment_EmitsEvent() public { 
        vm.expectEmit();
        emit Increment(1);
        counter.increment();
    }

    function test_Decrement_EmitsEvent() public { 
        counter.setNumber(1);
        
        vm.expectEmit();
        emit Decrement(0);

        counter.decrement();
    }

    function test_SetNumber_EmitsEvent() public { 
        vm.expectEmit();
        emit Set(1);

        counter.setNumber(1);
    }

    function test_Get() public { 
        counter.setNumber(0);
        assertEq(counter.number(), 0);
    }

    // testFuzz_ 하면 Foundry가 값을 반복해서 자동으로 넣어줌
    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
