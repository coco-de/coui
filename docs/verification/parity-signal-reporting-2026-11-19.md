# 미실행 속성 신호의 보고 문구 복구 — 2026-11-19 (#6434)

픽셀 전용 실행에서 `propertyDiff == null`인데도 “속성 완전 일치”와 폰트 래스터라이저 추정이 붙던 보고 오류를 수정했다. 미실행은 미실행으로, 실행 후 통과는 측정한 속성 비교의 통과로 적는다. 속성 결과만으로 픽셀 원인을 단정하지 않는다. 실패 분류·판정·JSON 형식은 유지했다.

제품 checkpoint `e112d2f680e63f30e06ca451ccc64595face87d9`, 포함 main `e8f89cd1a1696039feef7a53088d468b8713a5e5`다. 원본 구현에서 새 회귀 조건3개 실패를 보존했고, 관련 보고서/비교기99개 테스트와 최종 classifier11개 재검증을 통과했다. touched3 fatal 진단0, format3 변경0이다. 처음 노출된 기존 테스트 import/order/default-argument lint와 정리 후 검증을 구분해 보존했다.

실제 source555의 Web816/Native309 원본3288개를 그대로 읽어 두 공식 보고서를 다시 생성했다. raw SHA 전부 동일, matrix·propertyDiffs·passedCount·infra·structural 분류 변화0, 두 exit1 유지다. 픽셀 전용235개 실패 role의 잘못된 일치/래스터라이저 안내만 사라지고 미실행 안내235개로 바뀌었다. 235는 role 수이며 실패 key234개와 다르다.

| default816 matrix keys | pass | fail | infra | structural skip |
|---|---:|---:|---:|---:|
| pixel |582|234|0|0|
| property |402|368|0|46|

공개 CoUI API·컴포넌트·디자인값·Core/Native/Web renderer·캡처·manifest·normalizer·comparator·임계값·fields·skip·baseline·JSON schema·의존성은 변경하지 않았다. UI 경로 변경이 없어 새 이미지·docs 빌드나 앱 reload를 통과로 세지 않는다. 실제 CLI 보고서 실행이 이번 경로의 검증이며 새 전수 촬영으로 재라벨하지 않는다.

원본 잘못된 안내, 음성3개, 모든 실행/exit/paired JSON·원본 hash는 `/var/folders/_4/xbybljsj3s3c93fmpc7djtrh0000gn/T/weever-root-6434-report-20261119.h72m8xrm`와 같은 이름JSON에 보존했다. stage의 declared2/실행17 문제와 남은234/368 차이는 이번 범위에서 변경하지 않았다.
