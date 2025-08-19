// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {MiniVaultV0} from "../src/MiniVaultV0.sol";

contract Handler is Test {
    MiniVaultV0 public vault;
    address[] public users;

    constructor(MiniVaultV0 v) {
        vault = v;
        users.push(address(0xA11CE));
        users.push(address(0xB0B));
        users.push(address(0xC0DE));
        for (uint256 i = 0; i < users.length; i++) {
            vm.deal(users[i], 100 ether); // OK
        }
    }

    function usersLength() external view returns (uint256) { return users.length; }
    function userAt(uint256 i) external view returns (address) { return users[i]; }

    function h_deposit(uint8 i, uint64 amt) external {
        address u = users[i % users.length];
        uint256 v = bound(uint256(amt), 1, 1 ether); // OK
        vm.prank(u);                                  // OK
        vault.deposit{value: v}();
    }

    function h_withdraw(uint8 i, uint64 amt) external {
        address u = users[i % users.length];
        uint256 bal = vault.balances(u);
        if (bal == 0) return;
        uint256 v = bound(uint256(amt), 1, bal);     // OK
        vm.prank(u);                                  // OK
        vault.withdraw(v);
    }
}

contract VaultInvariants is StdInvariant, Test {
    MiniVaultV0 public vault;
    Handler public h;

    function setUp() public {
        vault = new MiniVaultV0();
        h = new Handler(vault);
        targetContract(address(h));
    }

    function invariant_SumEqualsTotal() public {
        uint256 sum;
        uint256 n = h.usersLength();
        for (uint256 i = 0; i < n; i++) {
            sum += vault.balances(h.userAt(i));
        }
        assertEq(sum, vault.totalDeposits());
    }

    function invariant_BalanceGTEBook() public {
        assertGe(address(vault).balance, vault.totalDeposits());
    }
}
