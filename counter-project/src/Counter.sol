// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    function decrement() public { 
        // How to detect negative in solidity?
        /**
        uint256은 부호 없는 정수라고 음수 개념 없음
        따라서, number가 0인데, number-- 하면 트랜잭션 리버트 발생
        이는 언더플로 문제라고 함 
        require로 방어문을 걸 수 있음
         */
        require(number > 0, "Already zero");
        number--;
    }

    // What is 'view'?
    /**
    view 함수는 상태를 변경하지 않겠다는 뜻
    즉, 블록체인에 저장된 값만 읽고 쓰지 않겠음 
    트랜잭션 안 보내고 로컬 호출 가능함
    따라서, 가스비가 발생하지 않음 
    pure도 있는데 이건 읽기/쓰기 둘 다 안하는 순수 계산 함수
    pure는 상태 변수를 참조하면 안됨 -> 함수 내에서 입력값이나 상수로만 계산
     */
    function get() public view returns (uint256) { 
        return number;
    }
}
