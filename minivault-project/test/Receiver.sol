//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

contract Receiver { 
    receive() external payable {
        revert("I don't accept ETH");
    }
}