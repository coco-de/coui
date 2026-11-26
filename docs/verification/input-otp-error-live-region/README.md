# InputOtp 오류 알림 영역

전화 인증 실패 화면에서 InputOtp.errorText가 일반 Text/div로만 나타나는 결함을
발견했다. Flutter의 LTR/RTL 의미 트리 및 Web 컴포넌트 테스트에서 live region이
0개라는 실패를 재현했다. 오류 문구만 Flutter Semantics(liveRegion:true), Web
aria-live=polite/aria-atomic=true로 감싼다. 입력값·그룹 이름·다른 텍스트를 알림
영역에 합치지 않는다. 오류가 없으면 알림 영역도 없다.

공개 생성자/계약/스타일/리졸버/번역/렌더 문구는 그대로다. copyWith, 한 개의 실제
입력과 접근성 이름, 값 유지, 오류 변경·제거, RTL을 검증했다. 스크린리더 실제
발화 시점은 플랫폼에 달려 있으며 자동 테스트가 음성 출력까지 확인하지는 않는다.
Web 입력의 aria-invalid/aria-describedby 연결은 아직 없고 문서의 해당 제약은
유지했다. 입력값 가림과 separator 의미 트리도 별도 기존 제약이다.

## 실행 근거

- Flutter: `flutter test --no-pub test/components/form/input_otp_error_semantics_test.dart test/components/form/input_otp_test.dart`
  - Expected: 오류만 live; 기존 입력/붙여넣기/완료/비활성 동작 보존.
  - Evidence: `+58: All tests passed!` (신규 LTR/RTL 2개 포함).
  - Pass: 통과.
- Web/Core: `dart test packages/coui_web/test/components/form/input_otp_test.dart packages/coui_core/test/input_otp_style_test.dart`
  - Expected: polite/atomic helper 하나, 입력·그룹은 live 아님; 기존 스타일 동일.
  - Evidence: `+92: All tests passed!`.
  - Pass: 통과.
- 변경 Dart 4개 `dart analyze --fatal-infos`: `No issues found!`.
  기존 파일의 불필요한 타입·raw string·기본 인자·const·문서 lint를 정리했다.
  인접 resolver/계약은 이 변경을 위한 lint 정리 대상에 넣지 않았다.
- 같은 4개 `dart format --set-exit-if-changed --output=none`: `Formatted 4 files (0 changed)`.
- 실제 docs_site Pretendard를 기존 `loadParityFonts()`로 로드한 RepaintBoundary
  전후 캡처: light/dark × LTR/RTL × 오류 있음/없음 **8/8 RGBA 동일**.
  `pixel-parity.json`에 크기·PNG 해시와 비교 결과를 기록한다. 첨부 이미지는
  light RTL/error와 dark LTR/error다. Ahem 테스트 글꼴로도 8/8 동일했지만
  실제 글리프 근거는 Pretendard 재캡처로 한정한다.
- 기존 공식 골든 `flutter test --no-pub test/src/golden/size_axis_golden_test.dart --name InputOtp`:
  이전/이후 모두 **11 px / 0.02% 실패**. 기존 기준 파일을 갱신하지 않았다.
  캡처 동일 결과를 공식 baseline 통과로 표현하지 않는다.
- `bash scripts/guards/resolver/verify_contracts.sh`: `=== All checks passed ===`
  (Core/Flutter/Web 분석 및 구조·리졸버 계약 검사 포함).
- 실제 SSR `renderComponentToDocumentHtml(Theme.defaults(child: InputOtp(...)))`:
  `SSR bytes: 7074; polite: 1; atomic: 1`. 이전 HTML과 새 aria 속성 두 개를
  제외한 전체 HTML이 동일하다. 서버 렌더만 실행했으므로 client
  script 없음 경고가 나며 이 결과를 hydrated 브라우저 동작 검증으로 표현하지 않는다.

앱의 Figma/정책/공유 데이터/의존성 핀은 바꾸지 않았다. 앱 반영은 CoUI 필수
검사와 정상 머지 후 공식 sync 및 앱 관련 검증이 필요하다. Figma 2% 차이율
개선이 아니라 접근성 동작 개선이다. 생성기·API·토큰·theme·variant·애니메이션
변경이 없으며 디자인 재발행 대상 스타일도 없다.
