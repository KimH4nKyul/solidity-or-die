// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;


error AlreadyZero();
error Overflow();



contract Counter {
    uint256 public number; // auto-getter: number 

    event Set(uint256 newNumber);
    event Increment(uint256 newNumber);
    event Decrement(uint256 newNumber);

    function setNumber(uint256 newNumber) public {
        number = newNumber;
        emit Set(newNumber);
    }

    function increment() public {
        // 오버플로 방지: 0.8.x는 기본 체크하지만 unchecked를 쓰려면 가드가 필요
        if(number == type(uint256).max) revert Overflow();
        unchecked {
            number++;
        }
        emit Increment(number);
    }

    function decrement() public { 
        // How to detect negative in solidity?
        /**
        uint256은 부호 없는 정수라고 음수 개념 없음
        따라서, number가 0인데, number-- 하면 트랜잭션 리버트 발생
        이는 언더플로 문제라고 함 
        require로 방어문을 걸 수 있음
         */
        // require(number > 0, "Already zero");
        // 현재 컨트랙트는 SSTORE가 지배적이기 때문에, 사실 가드 + unchecked는 가스비가 더 소비됨
        // 이런 상황에선 안쓰는게 가스비에 최적임
        if (number == 0) revert AlreadyZero();
        unchecked {
            number--;
        }
        emit Decrement(number);
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
    // function get() public view returns (uint256) { 
    //     return number;
    // }
}
