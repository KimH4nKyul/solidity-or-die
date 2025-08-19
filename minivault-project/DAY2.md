[설정]
- solc/pragma 버전: 0.8.23 (고정)
- 주요 플래그(foundry.toml): gas_reports = ["MiniVaultV0"], optimizer = true, optimizer_runs = 200

[구현 요약]
- CEI/재진입 방지 방식: 커스텀 nonReentrant 모디파이어 (bool reentrancyLock)
- 커스텀 에러: ZeroDeposit, ZeroAmount, ExceededAmount, EthSendFail, AlreadyLock
- 커스텀 이벤트: Deposit(address indexed from, uint256 value), Withdraw(address indexed from, uint256 value)
- receive/fallback: revert로 막아서 직접 ETH 송금 차단

[테스트]
- 시나리오 리스트:
  * 정상: deposit, withdraw, 이벤트 발생
  * 경계: 0값 deposit/withdraw, 잔액 초과 withdraw
  * 리버트: receive reject하는 컨트랙트로 withdraw
  * 재진입: Reenteror 컨트랙트로 재진입 공격 테스트
  * 강제송금: selfdestruct로 강제 ETH 송금 후 정상 동작 확인
  * 퍼징: testFuzz_Withdraw_EmitsEvent (256 runs)
  * 불변식: invariant_SumEqualsTotal, invariant_BalanceGTEBook (256 runs, 128000 calls each)
- forge test 로그 요약: 14 tests passed, 0 failed, 0 skipped

[가스 스냅샷]
- deposit: 67,378 gas (이벤트 포함: 68,352 gas)
- withdraw: 110,133 gas (평균: 113,927 gas)
- 재진입 방지: 추가 비용 약 300 gas
- 복잡한 시나리오: 최대 288,915 gas (재진입 테스트)

[보안 점검]
- Slither 결과: High/Critical 0개
  * Informational 1개: low-level call 사용 (msg.sender.call{value: value}()) - 의도된 설계로 무시
- 체크리스트:
  * ✅ 재진입: nonReentrant 모디파이어로 방지
  * ✅ 권한: msg.sender 기반 개인 잔액 관리
  * ✅ overflow: Solidity 0.8.23 내장 overflow protection
  * ✅ 프론트런: 개인 잔액 기반으로 프론트런 영향 최소

[회고]
- 배운 점: CEI 패턴과 재진입 방지의 중요성, 불변식 테스트의 효과
- 막혔던 점: selfdestruct 강제송금은 막을 수 없어 불변식을 >= 대신 <= 로 설계
- 개선 아이디어: 가스 최적화를 위한 packed struct 사용, 더 정교한 권한 관리
