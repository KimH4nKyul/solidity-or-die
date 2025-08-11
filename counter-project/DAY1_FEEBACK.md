## 피드백 반영 내용:

- `foundry.toml`:
  - `solc_version` 명시 


```text
Version constraint 0.8.19 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
        - VerbatimInvalidDeduplication
        - FullInlinerNonExpressionSplitArgumentEvaluationOrder
        - MissingSideEffectsOnSelectorAccess.
It is used by:
        - 0.8.19 (src/Counter.sol#2)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity
```  
- slither 내용:  
  - 위 3개 이슈는 솔리디티 버전을 최소 0.8.23으로 업데이트 해야 함 
  - 각각 0.8.21과 0.8.23에서 패치됨 
  - 위와 같은 내용 안보려면 `slither . --exclude-informational` 실행으로 노이즈 줄일 수 있음 (`--solc-dsiabe-warnings`는 solc 경고 옵션 끔)
  - solc 버전을 0.8.23으로 업그레이드해 대응

- `get()` 메서드 제거:  
  - `number`가 이미 `public`이기 때문에 자동 getter 제공 
  - 중복 제거로 가스/표면적 축소 (gas: 9285 -> 9277)

- `require(..., "string")` 대신 custom errors → 가스 절감 & 명확성


- `event` 추가:  
  - 이벤트는 체인의 상태에 직접 영향 주지 않는 기록을 남김 -> 가스비 절감
  - 오프체인 애플리이케이션이나 인덱서가 읽는 용도로 쓰임 -> EVM 안에서는 못읽음
  - 프론트/백엔드 브릿지: `web3.js` 같은 라이브러리로 이벤트를 통한 실시간 반응 감지
  - 디비깅 & 테스트 목적: `expectEmit` 쓰면 함수 호출 시점 상태 변화를 간접 검증 가능 
  - 인덱싱: 이벤트 파라미터에 `indexed` 붙이면 EVM이 토픽으로 따로 저장해서 빠르게 필터 가능 
    - 예를 들어, `event Transfer(address indexed from, address indexed to, uint256 amonut)` 


---

## 그외 알게 된 것 

```text
urllib.error.URLError: <urlopen error [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:1035)>
```
- `solc-select` 사용 중에 발생하는 CA 인증서 에러:  
  - MAC 실행 환경이므로 `open "/Applications/Python 3.13/Install Certificates.command"` 명령어 실행 후 
  - `solc-select upgrade` -> `solc-select install 0.8.23` -> `solc-select use 0.8.23` 수행해 글로벌 버전을 업데이트



```text
╭----------------------------------+-----------------+-------+--------+-------+---------╮
| src/Counter.sol:Counter Contract |                 |       |        |       |         |
+=======================================================================================+
| Deployment Cost                  | Deployment Size |       |        |       |         |
|----------------------------------+-----------------+-------+--------+-------+---------|
| 206988                           | 743             |       |        |       |         |
|----------------------------------+-----------------+-------+--------+-------+---------|
|                                  |                 |       |        |       |         |
|----------------------------------+-----------------+-------+--------+-------+---------|
| Function Name                    | Min             | Avg   | Median | Max   | # Calls |
|----------------------------------+-----------------+-------+--------+-------+---------|
| decrement                        | 22833           | 23087 | 23087  | 23342 | 2       |
|----------------------------------+-----------------+-------+--------+-------+---------|
| increment                        | 44796           | 44796 | 44796  | 44796 | 1       |
|----------------------------------+-----------------+-------+--------+-------+---------|
| number                           | 2446            | 2446  | 2446   | 2446  | 259     |
|----------------------------------+-----------------+-------+--------+-------+---------|
| setNumber                        | 24994           | 44341 | 44954  | 45278 | 263     |
╰----------------------------------+-----------------+-------+--------+-------+---------╯
```
- 가스 리포트 기능 ON:  
  - `foundry.toml`에 `gas_reports = ["Counter"]`와 같이 명시하고, `forge test --gas-report` 수행 
  - 같은 함수라도: 
    - 0↔︎nonzero 전환 여부
    - 첫 접근(cold) vs 재접근(warm)
    - 이벤트 토픽/데이터 길이
  - 때문에 Min/Avg/Max가 갈림 
  - 비교할 때는 초기 상태를 고정해서(예: 항상 setNumber(1) 후 decrement()) 측정해야 공정함
