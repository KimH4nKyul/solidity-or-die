// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {MiniVaultV0} from "../src/MiniVaultV0.sol";

contract Reenteror { 
    MiniVaultV0 public vault;

    
    constructor(MiniVaultV0 _vault) payable {
        vault = _vault;
    }

    // 테스트에서 이걸로 예치해 둠
    function primeDeposit() external payable {
        vault.deposit{value: msg.value}();
    }

    // 테스트에서 이걸로 출금 유도
    function attackWithdraw(uint256 amount, bool tryDepositAgain, bool tryWithdrawAgain) external {
        _tryDepositAgain = tryDepositAgain;
        _tryWithdrawAgain = tryWithdrawAgain;
        vault.withdraw(amount);
    }

    bool private _tryDepositAgain;
    bool private _tryWithdrawAgain;

    receive() external payable {
        // 재진입 시도. 락 때문에 revert가 날 수 있으므로 try/catch로
        // **원 호출을 성공시키려면 catch로 삼켜야** withdraw 전체가 안 뒤집힘.
        if (_tryDepositAgain) {
            try vault.deposit{value: 1 wei}() { } catch { }
        }
        if (_tryWithdrawAgain) {
            try vault.withdraw(1 wei) { } catch { }
        }
    }
}