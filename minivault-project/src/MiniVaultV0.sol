// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

error ZeroDeposit();
error ZeroAmount();
error ExceededAmount();
error EthSendFail();

contract MiniVaultV0 { 

    mapping(address => uint256) balances;
    uint256 public totalDeposits;
    
    event Withdraw(address indexed from, uint256 value);
    event Deposit(address indexed from, uint256 value);     

    function withdraw(uint256 value) public { 
        if (value == 0) revert ZeroAmount();
        if (value > balances[msg.sender]) revert ExceededAmount();
        
        balances[msg.sender] -= value;
        totalDeposits -= value;

        (bool ok, ) = msg.sender.call{value: value}("");
        if (!ok) revert EthSendFail();

        emit Withdraw(msg.sender, value);
    }

    function deposit() public payable { 
        if (msg.value == 0) revert ZeroDeposit();
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }
}