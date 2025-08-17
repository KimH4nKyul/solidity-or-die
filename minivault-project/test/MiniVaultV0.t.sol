// SPDX-License-Identifier: UNLICENSED 
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {ForceSend} from "./ForceSend.sol";
import {Reenteror} from "./Reenteror.sol";
import {Receiver} from "./Receiver.sol";
import {MiniVaultV0, ZeroDeposit, ZeroAmount, ExceededAmount, EthSendFail, AlreadyLock} from "../src/MiniVaultV0.sol";


contract MiniVaultV0Test is Test { 
    MiniVaultV0 public miniVaultV0; 

    event Withdraw(address indexed from, uint256 value);
    event Deposit(address indexed from, uint256 value);     

    address user;

    function setUp() public { 
        miniVaultV0 = new MiniVaultV0();
        user = makeAddr("user");
    }    

    function test_ForcedETH_doesNotAffectAccounting() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        miniVaultV0.deposit{value: 1 ether}();
        uint256 td = miniVaultV0.totalDeposits();

        ForceSend f = new ForceSend();
        vm.deal(address(f), 0.5 ether);
        f.boom{value: 0.5 ether}(payable(address(miniVaultV0)));

        assertEq(miniVaultV0.totalDeposits(), td);            // 내부 장부는 그대로
        assertGe(address(miniVaultV0).balance, td);           // 강제 ETH로 커질 수 있음

        vm.prank(user);
        miniVaultV0.withdraw(1 ether);                        // 출금 정상 동작
    }

    /** Reentrancy Lock Test */
    function test_LockResets_AfterRevert() public {
        address receiver = address(new Receiver()); // receive()에서 revert
        vm.deal(receiver, 2 ether);

        vm.startPrank(receiver);
        miniVaultV0.deposit{value: 1 ether}();
        vm.expectRevert(EthSendFail.selector);
        miniVaultV0.withdraw(1 ether); // 실패 → 전체 revert → 락도 원복

        // 같은 트랜잭션 다음이 아니라, 새 호출에서 정상 동작 확인
        vm.deal(receiver, 1 ether);
        miniVaultV0.deposit{value: 1 ether}(); // 여기 성공해야 함(락이 남아있지 않음)
        vm.stopPrank();
    }

    function test_ReentrancyLock_WithdrawInReceive_succeedsOuter() public {
        Reenteror evil = new Reenteror(miniVaultV0);
        vm.deal(address(evil), 3 ether);
        vm.prank(address(evil));
        evil.primeDeposit{value: 2 ether}();

        uint256 vaultBefore = address(miniVaultV0).balance;
        vm.prank(address(evil));
        evil.attackWithdraw(1 ether, /*tryDepositAgain=*/false, /*tryWithdrawAgain=*/true);

        assertEq(address(miniVaultV0).balance, vaultBefore - 1 ether);
        assertEq(miniVaultV0.balances(address(evil)), 1 ether);
    }

    function test_Withdraw_OtherUserCannot() public {
        address alice = makeAddr("alice");
        address bob   = makeAddr("bob");
        vm.deal(alice, 5 ether);
        vm.prank(alice);
        miniVaultV0.deposit{value: 5 ether}();

        vm.prank(bob);
        vm.expectRevert(ExceededAmount.selector);
        miniVaultV0.withdraw(1 ether);
    }

    /** Business Logic Test */

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