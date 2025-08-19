# [오늘의 목표 — Day 3]

- [ ] Pull-Payment v1: requestWithdraw(amount) + claim() 분리
- [ ] Ownable + Pausable 도입(운영/긴급차단)
- [ ] Surplus sweep: 강제 ETH(혹은 기부금)만 분리 인출
- [ ] 테스트 12개 이상 + 인변 3개 유지/확장
- [ ] 가스 목표: withdraw → claim 분리 후 핵심 경로 -5%(상황 고정 비교)

## 성공 기준

- forge test --gas-report 전부 PASS, withdraw/request/claim 경로 수치 기록
- Slither High/Critical 0, new surface(onlyOwner/paused) 검증
- 인변 통과(합계 보존, 잔고≥장부, pending 불변)

# [오늘의 과제]

## 1) 설계 변경 (Push → Pull-Payment)

- 상태 추가:  
    - mapping(address => uint256) public pending;

- 흐름:  
    - requestWithdraw(amount): Checks(잔액/0) → Effects(balances[msg.sender]-=, totalDeposits-=, pending[msg.sender]+=) → 이벤트
    - claim(): Checks(pending>0) → Effects(pending=0) → Interactions(송금) → 이벤트

- 이점:
    - 사용자 잔액 차감이 전송과 분리 → 재진입에 의한 이중 차감/전송 창 줄어듦
    - 운영 관점에서 claim()만 차단(혹은 rate limit) 같은 전략도 가능

## 스니펫 (핵심만):
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

error Paused();
error NotOwner();
error NoPending();

contract MiniVaultV1 {
    mapping(address=>uint256) public balances;
    mapping(address=>uint256) public pending;
    uint256 public totalDeposits;
    bool private reentrancyLock;
    address public owner;
    bool public paused;

    // --- ownable/pausable ---
    modifier onlyOwner(){ if(msg.sender!=owner) revert NotOwner(); _; }
    modifier whenNotPaused(){ if(paused) revert Paused(); _; }

    // nonReentrant 동일 (생략)

    constructor(){ owner = msg.sender; }

    function pause() external onlyOwner { paused = true; }
    function unpause() external onlyOwner { paused = false; }

    // --- deposit/request/claim ---
    function deposit() external payable nonReentrant whenNotPaused {
        if (msg.value==0) revert ZeroDeposit();
        balances[msg.sender] += msg.value;
        totalDeposits      += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function requestWithdraw(uint256 amt) external nonReentrant whenNotPaused {
        if (amt==0) revert ZeroAmount();
        uint256 bal = balances[msg.sender];
        if (amt>bal) revert ExceededAmount();
        balances[msg.sender] = bal - amt;
        totalDeposits       -= amt;
        pending[msg.sender] += amt;
        emit WithdrawRequested(msg.sender, amt);
    }

    function claim() external nonReentrant {
        uint256 p = pending[msg.sender];
        if (p==0) revert NoPending();
        pending[msg.sender] = 0;                   // Effects 먼저
        (bool ok,) = msg.sender.call{value:p}(""); // Interaction
        if(!ok) revert EthSendFail();
        emit Withdraw(msg.sender, p);
    }

    // --- surplus sweep (강제 ETH 처리) ---
    function sweepSurplus(address payable to) external onlyOwner {
        uint256 surplus = address(this).balance - totalDeposits - _sumPendingUnsafe();
        if (surplus==0) return;
        (bool ok,) = to.call{value: surplus}("");
        if(!ok) revert EthSendFail();
        emit SurplusSwept(to, surplus);
    }

    // 경량 모델: pending까지 뺀 서플러스만 스윕(유저 수 적으면 직접 합산)
    function _sumPendingUnsafe() internal view returns(uint256 sum){
        // v1에선 추적 유저가 적다고 가정. v2에선 이벤트/오프체인 집계 or 별도 집계변수 유지.
        // (실무는 totalPending 상태값을 함께 유지 권장)
    }

    // receive/fallback는 v0와 동일하게 revert, 주석으로 강제송금 허용 명시
}
```

> 프로덕션이면 _sumPendingUnsafe() 대신 uint256 public totalPending; 상태값을 유지/증감하는 편이 가스/안전 모두 좋다.

---

## 2) 테스트 (필수 시나리오)

- 정상:
    - deposit → requestWithdraw(part) → claim()
    - deposit → requestWithdraw(all) → claim()(잔액 0)
  
- 경계/리버트:  
    - requestWithdraw(0), requestWithdraw(>balance), claim() when pending=0
    - paused 중 deposit/requestWithdraw 리버트, claim은 정책에 따라 허용/차단 결정

- 재진입: 
    - claim() 중 receive()에서 requestWithdraw/claim 재호출 시도 → nonReentrant로 차단되고 원 트랜잭션은 성공(try/catch로 삼킴)

- 강제송금 + sweep:  
    - selfdestruct로 잔고 > 장부 상태 만들기 → sweepSurplus() 후 잔고 재확인(장부 불변 유지)

- 인변 추가/수정:  
    - sum(balances) + sum(pending) == totalDeposits + totalPending (또는 상태값으로 totalPending)
    - address(this).balance >= totalDeposits + totalPending
    - 모든 balances[addr] 및 pending[addr]은 음수 불가(자명하지만 퍼저가 분기 타게 하면 유용)

## 예시 스니펫(핵심 2~3개): 
```solidity
function test_RequestThenClaim_Full() public {
    vm.deal(user, 5 ether);
    vm.startPrank(user);
    v1.deposit{value: 5 ether}();
    v1.requestWithdraw(5 ether);
    assertEq(v1.balances(user), 0);
    assertEq(v1.pending(user),  5 ether);
    v1.claim();
    vm.stopPrank();
    assertEq(user.balance, 5 ether);
}

function test_Claim_ReentrancyBlocked() public {
    ReenterorClaim evil = new ReenterorClaim(v1); // receive에서 claim/request 재호출 시도
    vm.deal(address(evil), 2 ether);
    vm.prank(address(evil));
    evil.primeDeposit{value: 2 ether}();
    vm.prank(address(evil));
    evil.requestAndClaim(1 ether, /*tryClaimAgain=*/true, /*tryRequestAgain=*/true);
    // 원 호출 성공 + pending/balances/totalDeposits 정합성 확인
}
```

## 3) 가스 측정 계획

- 고정 시나리오 비교:
    - v0 withdraw(1 ether) vs v1 requestWithdraw(1 ether) + claim()
    - 각각 1→0, 2→1 케이스 분리
- foundry.toml:  
```toml
[profile.default]
gas_reports = ["MiniVaultV0","MiniVaultV1"]
optimizer = true
optimizer_runs = 200
```

- 목표: 성공 경로 평균 -5%(함수 분리로 핫패스 짧아질 가능성)
    - 단, claim()에 전송 로그 비용이 붙으므로 총합 비교도 함께 남겨라.


## 4) Slither 체크포인트 (v1 추가분): 

- Reentrancy: claim()/requestWithdraw() 모두 nonReentrant 부착 확인
- Dangerous external call: 여전히 low-level call → 의도 문서화
- Locked Ether: sweepSurplus 존재로 운영 회수 가능
- Missing Events: WithdrawRequested, SurplusSwept 등 새 이벤트 누락 X
- Pausable: deposit/requestWithdraw만 막고 claim은 유지(운영 정책 선택)