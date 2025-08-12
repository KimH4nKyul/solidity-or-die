// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

contract MiniVaultV0 { 

    mapping(address => uint256) balances;
    uint256 public totalDeposits;
    
    event Withdraw(address indexed from, uint256 value);
    event Deposit(address indexed from, uint256 value);     

    function withdraw(uint256 value) public { 
        emit Withdraw(msg.sender, value);
    }

    // why use `payable` keyword?
    function deposit() public payable { 
        emit Deposit(msg.sender, msg.value);
    }
}