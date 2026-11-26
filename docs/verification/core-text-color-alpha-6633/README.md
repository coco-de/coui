# CoreTextStyle 색상 알파 정밀도 보존 (#6633)

`CoreTextStyle.toValue(theme: null)`은 정식 `CoreColor.toValue()` 결과를
8비트 ARGB로 저장했다가 다시 `Color`로 만들어 소수 알파를 반올림했다.
공개 scheme.resolve로 얻은 opacity .3은 .3019607843, 저장 알파 128/255와
.3의 곱은 .1505882353에서 .1490196078로 바뀌었다.

테마 없는 변환 한 곳에서 `ownColor?.toValue()`를 직접 재사용한다.
명시적 Flutter color 우선순위, 테마 있는 변환, typography-token의 theme 요구,
이미 packed된 ARGB, 투명색, 글꼴·줄높이·자간·기본값은 유지한다.
Core/public API/의존성/측정기/비교 기준/기준 이미지는 변경하지 않는다.

## 실행 근거

- 유효한 원본 12개: b75 원본에서 7PASS, 4 assertion FAIL, 1 widget matcher error.
  렌더러 실행 오류가 아닌 기대 알파 불일치이며, 같은 12개는 후보에서 모두 PASS.
- 원본과 후보의 테스트 bytes는 SHA434ebd99…로 같다.
  초기 raw.withOpacity 입력에 대한 잘못된 가정은 제품 수정 전에 정정했고,
  해당 첫 기록은 보존하되 유효한 원본 증거로 사용하지 않는다.
- 기존 converter/typography 3파일의 66개도 PASS. 새 12개와 합쳐 78PASS.
  fatal-infos 0, format 0. 이 실행은 b75 + 동결 후보 2파일 시점이다.
- 코드 5200d69fa2 후 Alpha #6627의 main f19를 정상 통합한 9fc57828에서
  생산 Native/Core/Web와 의존성의 upstream 차이는 0이고, 후보 2파일도 동일하다.
  통합 전 78개를 통합 후 재실행으로 표기하지 않는다.
- 9fc의 소유 Native flutter-tester debug 앱에서 Git f19 변환기 원본 → 후보를
  실제 `app.restart(fullRestart: false)`로 hot reload했다(1/3754 libraries).
  RenderParagraph.a는 77/255 → .3, 참조는 .3 유지. State/input/RenderParagraph
  identity, RGB/ARGB32, 글꼴·줄높이·자간·크기 등 19개 관측 필드는 동일하다.
- 해당 공개 변환 fixture의 RepaintBoundary 전후 PNG 2장은 encoded bytes/RGBA가 같다.
  이 한 표본의 결과이며 전체 화면의 픽셀 차이나 파리티 개선을 주장하지 않는다.
- 두 소유 job 정상 종료·회수, Native 앱 종료·포트 2개 닫힘. 소스/232 metadata/
  graph/lock 불변, pubget/설치/다운로드/브라우저 호출 0.

## 범위와 미실행

증빙 이미지는 custom public conversion fixture이며 canonical 라이트/다크 캡처나
committed 이미지 baseline 비교가 아니다. 전체 default FAIL 감소도 측정하지 않았다.
Web/Jaspr/Figma는 변경 축이 없어 N/A. 다른 앱·IDE·DTD는 조작하지 않았다.
원본·실행 명령·로그·소스 SHA·PNG·정리 근거는 verification.json의 외부 원본을 참조한다.
