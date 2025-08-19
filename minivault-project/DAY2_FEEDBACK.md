# DAY2 과제 피드백

## 설정
- **solc 버전**: 0.8.23 (고정)
- **주요 플래그 (foundry.toml)**: 
  - gas_reports = ["MiniVaultV0"] 활성화
  - optimizer_runs: 기본값 200 사용

## 구현 요약
- **CEI/재진입 방지 방식**: Checks-Effects-Interactions 패턴 부분 적용, 하지만 재진입 방지 미흡
- **커스텀 에러 목록**: ZeroDeposit, ZeroAmount, ExceededAmount, EthSendFail
- **이벤트 목록**: Deposit(address indexed from, uint256 value), Withdraw(address indexed from, uint256 value)

## 테스트 현황
### 시나리오 리스트 (8개 테스트 구현됨)
✅ **정상 경로**:
- test_Deposit: 입금 기능 정상 동작
- test_Withdraw: 출금 기능 정상 동작

✅ **경계 테스트**:
- test_Deposit_RevertWhenZero: 0 입금 시 revert
- test_Withdraw_RevertWhenZero: 0 출금 시 revert
- test_Withdraw_RevertWhenExceeded: 잔액 초과 출금 시 revert

✅ **리버트 테스트**:
- test_Withdraw_RevertWhenFailSendEth: ETH 전송 실패 시 revert

✅ **이벤트 테스트**:
- test_Deposit_EmitsEvent: 입금 이벤트 검증
- testFuzz_Withdraw_EmitsEvent: 퍼징을 통한 출금 이벤트 검증

### forge test 결과
```
Ran 8 tests for test/MiniVaultV0.t.sol:MiniVaultV0Test
[PASS] 모든 테스트 통과 (실패 0)
```

## 가스 스냅샷
| Function | Min | Avg | Median | Max | # Calls |
|----------|-----|-----|--------|-----|---------|
| deposit | 21,261 | 67,401 | 67,578 | 67,578 | 263 |
| withdraw | 21,626 | 40,809 | 41,025 | 41,097 | 260 |

**withdraw 경로별 분석**:
- 부분 출금: ~41,000 가스
- 전액 출금: ~41,000 가스 (유사한 패턴)

## 보안 점검

### Slither 결과
❌ **발견된 문제들**:
1. **Reentrancy (INFO 레벨)**: withdraw 함수에서 외부 호출 후 이벤트 발생
2. **Low level call (INFO 레벨)**: call() 사용에 대한 경고

### 보안 체크리스트
❌ **재진입**: CEI 패턴을 따르지만 이벤트가 외부 호출 후 발생  
✅ **권한**: 적절한 권한 관리  
✅ **overflow**: Solidity 0.8.x 기본 보호  
✅ **프론트런**: 특별한 프론트런 취약점 없음  
❌ **tx.origin**: 사용하지 않음 (양호)

## 과제 요구사항 대비 분석

### 완료된 항목 ✅
1. ✅ ETH deposit/withdraw 기본 기능
2. ✅ 이벤트 발생 (Deposit, Withdraw)
3. ✅ 커스텀 에러 구현
4. ✅ totalDeposits 상태값 유지
5. ✅ 8개 테스트 구현 (정상/경계/리버트/이벤트 포함)
6. ✅ forge test 전부 PASS

### 미완료/개선 필요 항목 ❌
1. ❌ **재진입 방지 미흡**: 
   - CEI 패턴은 따르지만 이벤트가 외부 호출 후 발생
   - nonReentrant modifier 미구현
   
2. ❌ **불변식 테스트 누락**: 
   - (1) address(this).balance == totalDeposits 검증 테스트 없음
   - (2) userBalances 합 == totalDeposits 검증 테스트 없음
   
3. ❌ **부족한 테스트 커버리지**:
   - 재진입 공격 테스트 없음 (Receiver 계약은 있으나 재진입 시뮬레이션 안함)
   - 퍼징 테스트가 단순함 (복잡한 시나리오 부족)
   
4. ❌ **Slither 보안 이슈**: 
   - High/Critical은 없으나 reentrancy 정보성 경고 

## 개념 설명 (코드 주석 기반)

### 1. `payable` 키워드 (MiniVaultV0.sol:30)
```solidity
function deposit() public payable {
```
**설명**: `payable` 키워드는 함수가 ETH를 받을 수 있도록 해줍니다. 이 키워드가 없으면 ETH를 전송하는 호출은 실패합니다.

### 2. 오버플로우 방지 (MiniVaultV0.sol:34-36)
```solidity
// if u need no overflow? use this. => `+=`
balances[msg.sender] = balances[msg.sender] + msg.value;
```
**설명**: Solidity 0.8.x부터는 기본적으로 오버플로우 검사가 활성화됩니다. `+=` 연산자와 수동 덧셈 모두 동일하게 보호됩니다.

### 3. `address` 타입 변수 (MiniVaultV0.t.sol:15-16)
```solidity
// why use address type variable `user` here?
address user;
```
**설명**: 테스트에서 실제 계정을 시뮬레이션하기 위해 address 타입을 사용합니다. 이를 통해 서로 다른 사용자의 상호작용을 테스트할 수 있습니다.

### 4. `makeAddr()` 함수 (MiniVaultV0.t.sol:21)
```solidity
user = makeAddr("user");
```
**설명**: Forge의 테스트 유틸리티로, 주어진 문자열로부터 결정론적 주소를 생성합니다. 테스트에서 일관된 주소를 사용할 수 있게 해줍니다.

### 5. `startPrank()`/`stopPrank()` (MiniVaultV0.t.sol:103-104)
```solidity
vm.startPrank(user);
// ... 여러 호출
vm.stopPrank();
```
**설명**: 여러 트랜잭션을 특정 주소에서 보낸 것처럼 시뮬레이션합니다. `startPrank()`부터 `stopPrank()`까지의 모든 호출이 지정된 주소에서 실행됩니다.

### 6. `expectEmit()` 매개변수 (MiniVaultV0.t.sol:107-108)
```solidity
vm.expectEmit(true, false, false, true, address(miniVaultV0));
```
**설명**: 
- 첫 번째 `true`: 첫 번째 indexed 매개변수 검증
- 두 번째 `false`: 두 번째 indexed 매개변수 무시
- 세 번째 `false`: 세 번째 indexed 매개변수 무시  
- 네 번째 `true`: 데이터(non-indexed) 매개변수 검증
- 마지막: 이벤트가 발생할 컨트랙트 주소

### 7. `bound()`, `deal()`, `prank()` (MiniVaultV0.t.sol:114-115)
- **`bound(x, min, max)`**: 값 x를 min~max 범위로 제한
- **`deal(address, amount)`**: 특정 주소에 ETH 잔액 설정
- **`prank(address)`**: 다음 호출을 특정 주소에서 실행한 것처럼 시뮬레이션

## 회고

### 배운 점
1. ✅ Solidity 기본 패턴 (CEI) 이해
2. ✅ Forge 테스트 프레임워크 활용
3. ✅ 커스텀 에러와 이벤트 구현
4. ✅ 가스 최적화 의식

### 막혔던 점
1. ❌ 재진입 방지가 완전하지 않음
2. ❌ 불변식 테스트 구현 누락
3. ❌ 보안 도구(Slither) 경고 해결 필요

### 개선 아이디어
1. **재진입 방지**: ReentrancyGuard 또는 mutex 패턴 도입
2. **불변식 테스트**: invariant 테스트 추가로 시스템 무결성 검증
3. **이벤트 순서**: 외부 호출 전에 이벤트 발생 고려
4. **포괄적 퍼징**: 더 복잡한 시나리오의 fuzz 테스트 추가

## 최종 평가

**성공한 부분**: 기본적인 vault 기능과 테스트 구현 완료  
**개선 필요**: 재진입 방지와 불변식 테스트가 핵심 누락 사항

전체적으로 견고한 기초 구현이지만, Day 2 요구사항의 보안 측면에서 추가 개선이 필요합니다.