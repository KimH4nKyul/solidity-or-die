[환경 세팅]
- OS: MacOS
- 설치 버전:
  - foundryup: 1.2.3-stable
  - slither: 0.11.3

[구현 내용]
- Counter.sol 주요 코드:
```solidity
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
        require(number > 0, "Already zero");
        number--;
    }

    function get() public view returns (uint256) { 
        return number;
    }
}
```

[테스트 결과]
- forge test 결과 캡처/로그
```text
[⠊] Compiling...
[⠰] Compiling 1 files with Solc 0.8.30
[⠔] Solc 0.8.30 finished in 352.31ms
Compiler run successful!

Ran 5 tests for test/Counter.t.sol:CounterTest
[PASS] testFuzz_SetNumber(uint256) (runs: 256, μ: 28677, ~: 29377)
[PASS] test_Decrment() (gas: 20037)
[PASS] test_Decrment_RevertWhenZero() (gas: 12426)
[PASS] test_Get() (gas: 9306)
[PASS] test_Increment() (gas: 28893)
Suite result: ok. 5 passed; 0 failed; 0 skipped; finished in 3.42ms (3.38ms CPU time)

Ran 1 test suite in 98.22ms (3.42ms CPU time): 5 tests passed, 0 failed, 0 skipped (5 total tests)
```
- 모든 테스트 케이스 설명:
  - `testFuzz_SetNumber(uint256)`: Foundry가 x에 랜덤 값(0~uint256 최대값까지) 계속 넣어 테스트 
  - `test_Increment()`: 숫자 증가 테스트
  - `test_Decrement()`: 숫자 감소 테스트
  - `test_Decrement_RevertWhenZero()`: number 상태 변수가 0일 때, 감소하면 트랜잭션 리버트 발생 및 리버트 메시지 확인 테스트
  - `test_Get()`: 현재 number 상태 변수의 상태 확인 

[보안 점검]
- Slither 경고 목록
```text
Version constraint ^0.8.13 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
        - VerbatimInvalidDeduplication
        - FullInlinerNonExpressionSplitArgumentEvaluationOrder
        - MissingSideEffectsOnSelectorAccess
        - StorageWriteRemovalBeforeConditionalTermination
        - AbiReencodingHeadOverflowWithStaticArrayCleanup
        - DirtyBytesArrayToStorage
        - InlineAssemblyMemorySideEffects
        - DataLocationChangeInInternalOverride
        - NestedCalldataArrayAbiReencodingSizeValidation.
It is used by:
        - ^0.8.13 (src/Counter.sol#2)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity
INFO:Slither:. analyzed (1 contracts with 100 detectors), 1 result(s) found
```
- 조치 여부 및 방법:
  - 무시

[오늘 회고]
- 배운 점: 
  - 솔리디티 Counter 컨트랙트를 간단히 작성하고, Foundry를 활용한 테스트 코드 작성방법을 배움 
  - forge, slither 사용 방법을 배움 
- 어려웠던 점:
  - 간단한 컨트랙트지만 solidity의 문법에 익숙치 않아 적재적소에 활용하는 방법을 더 배워야함 
- 내일 개선할 부분:
  - slither 해석 방법을 배워야함 
