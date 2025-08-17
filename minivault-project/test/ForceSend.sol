// SPDX-Lincense-Identifier: UNLICENSED
pragma solidity 0.8.23;


contract ForceSend { function boom(address payable to) external payable { selfdestruct(to); } }
