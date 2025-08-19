# Tasks 

- [ ] References의 주어진 과제 항목을 보고 현재 구현된 MiniVaultV0와 그 테스트 점검
- [ ] 소스코드 주석을 참고해 사용자가 원하는 개념 설명을 작성
- [ ] 과제 피드백 (DAY2_FEEDBACK.md) 작성



# References

## 주어진 과제 


Day 2 목표 (4h 플랜)
 MiniVault(v0): ETH deposit/withdraw + 이벤트 + CEI 순서 + 재진입 방지

 테스트 10개+: 정상/경계/리버트/퍼징/이벤트/에러 셀렉터

 불변식 2개: (1) address(this).balance == totalDeposits (2) userBalances 합 == totalDeposits
→ 합산이 느릴 수 있으니 totalDeposits 상태값을 유지하며 증감 검증

 Slither: Critical 0, 재진입/권한/tx.origin 미사용 확인

 가스 스냅샷: withdraw 경로 최소 2종(부분/전액) 비교

성공 기준

forge test --gas-report 전부 PASS

Slither에서 High/Critical 0

불변식 테스트 PASS

---

Day 2 과제 (구체)
설계

상태: mapping(address => uint256) balances; uint256 totalDeposits;

이벤트: Deposit(address indexed user, uint256 amount), Withdraw(address indexed user, uint256 amount)

재진입: 간단히 checks-effects-interactions + nonReentrant(bool 락)로 시작

구현 가이드

deposit()는 msg.value > 0 체크 → 상태 갱신(Effects) → 이벤트

withdraw(uint256 amt)는 CEI: 잔액 확인(Checks) → 상태 차감(Effects) → call 송금(Interactions) → 실패 시 revert

전체 합 보존: totalDeposits 증감 동기화

테스트 목록(예시)

입금/출금 정상 경로

withdraw 잔액 초과 리버트(커스텀 에러 + selector)

재진입 공격 컨트랙트로 실패 확인

퍼징: 랜덤 입금/부분 출금 후 불변식 유지

이벤트 expectEmit 확인

Slither 체크포인트

Reentrancy / tx.origin / low-level call 반환값 점검

public 표면적 최소화(내부 헬퍼는 internal)

---

Day 2 제출 포맷
diff
복사
편집
[설정]
- solc/pragma 버전(고정 여부)
- 주요 플래그(foundry.toml): gas_reports, optimizer_runs 등

[구현 요약]
- CEI/재진입 방지 방식
- 커스텀 에러/이벤트 목록

[테스트]
- 시나리오 리스트(정상/경계/리버트/퍼징/불변식)
- forge test 로그 요약(실패 0)

[가스 스냅샷]
- deposit/withdraw 경로별: before → after 비교(필요 시 이벤트 on/off 실험)

[보안 점검]
- Slither 결과(High/Critical 0) + 무시 항목/사유
- 체크리스트: 재진입/권한/overflow/프론트런

[회고]
- 배운 점 / 막혔던 점 / 개선 아이디어


## 과제 제출

- 아직 안한 상태 