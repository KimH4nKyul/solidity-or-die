// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

error ZeroDeposit();
error ZeroAmount();
error ExceededAmount();
error EthSendFail();
error AlreadyLock();

contract MiniVaultV0 { 

    mapping(address => uint256) public balances;
    uint256 public totalDeposits;
    bool private reentrancyLock;
    
    event Withdraw(address indexed from, uint256 value);
    event Deposit(address indexed from, uint256 value);     

    modifier nonReentrant() { 
        if (reentrancyLock) revert AlreadyLock();
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    function withdraw(uint256 value) external nonReentrant { 
         if (value == 0) revert ZeroAmount();
        uint256 bal = balances[msg.sender];
        if (value > bal) revert ExceededAmount();

        balances[msg.sender] = bal - value;
        totalDeposits -= value;

        (bool ok, ) = msg.sender.call{value: value}("");
        if (!ok) revert EthSendFail();

        emit Withdraw(msg.sender, value);
    }

    // why use `external`? 
    function deposit() external payable nonReentrant(){ 
        if (msg.value == 0) revert ZeroDeposit();
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }

    /**
    누가 실수로 deposit() 안 거치고 그냥 ETH를 보낼 때 막아 두는 게 안전하다(총합 불변 유지).
    주의: selfdestruct로 강제 송금은 막을 수 없음 — 그래서 아래 “불변식”에서 <=로 보정.
     */
    receive() external payable { revert(); }
    fallback() external payable { revert(); }
}