# Welcome to CoUI — 처음 기여하는 날

**목표: 컴포넌트 하나를 열어 보고, 어디를 고쳐야 하는지 설명할 수 있게 되기.**
처음부터 전체 라이브러리를 읽을 필요는 없습니다.

전체 기여 흐름은 [CONTRIBUTING.md](CONTRIBUTING.md), 한국어 상세 안내는
[기여자 가이드](docs/contributing/README.md)에서 시작합니다.

## 첫 학습 순서

1. **[첫 실행](docs/contributing/getting-started.md)** — 접근 권한과 도구를
   확인하고 의존성을 설치한 뒤 Web 또는 Flutter 프리뷰를 엽니다.
2. **[구조와 용어](docs/contributing/architecture.md)** — 토큰, Contract,
   Style, Theme, Resolver, Widget이 무엇인지 Badge의 파일로 연결합니다.
3. **[첫 변경 실습](docs/contributing/first-change.md)** — outline Badge의
   선 두께 하나가 Core에서 양 플랫폼과 Figma까지 어떻게 전달되는지 따라갑니다.
4. **[검증](docs/contributing/verification.md)** — 변경에 맞는 검사와
   결과 증거를 남깁니다.
5. **[Figma](docs/contributing/figma.md)**와 **[업그레이드](docs/contributing/upgrading.md)**
   — 로컬 확인 이후 팀과 소비 프로젝트에 전달하는 순서를 읽습니다.

## 준비 체크리스트

- [ ] `coco-de/coui` 저장소에 접근할 수 있다.
- [ ] Flutter/Dart 버전을 루트 `pubspec.yaml` 및 CI와 대조했다.
- [ ] `flutter pub get`과 `melos bootstrap`이 완료됐다.
- [ ] 프리뷰에서 Badge를 찾았다. Web과 Flutter는 서로 다른 구현임을 안다.
- [ ] 기본값을 바꿀 Core 파일과 양쪽 resolver 파일을 찾았다.
- [ ] Figma를 다룬다면 폰트·플랜·편집 권한을 확인하고 내 checkout의
  `manifest.json`으로 플러그인을 불러왔다.
- [ ] 연습 변경과 제출할 변경을 `git diff`로 구별할 수 있다.

## AI 도구를 함께 쓴다면

AI 도구 없이도 위 명령과 문서로 기여할 수 있습니다. 사용하는 경우에는
도구가 어떤 작업을 했는지 결과를 확인하세요.

| 도구 | 도움받는 작업 |
|---|---|
| [CoUI 팀 스킬 설치 안내](https://github.com/coco-de/skills/tree/main/internal/coui) (팀 접근 권한 필요) | 공유 계약 → Flutter → Web → 문서 → 검증의 통일화 절차 |
| Dart / Marionette MCP | 실행 중인 Flutter 앱의 위젯 확인, 조작, hot reload |
| Playwright / Chrome DevTools | Web의 실제 DOM, 키보드 동작, computed style 확인 |
| Figma 도구와 CoUI Token Sync | 디자인 확인 및 코드에서 Figma Variables/컴포넌트 생성 |
| GitHub / ZenHub | 이슈와 PR의 진행 상태 기록 |

도구에 표시된 저장소·앱·Figma 파일이 이번 작업 대상인지 확인합니다.
공개 기여 절차와 검증 방법은 [기여자 가이드](docs/contributing/README.md)에서 확인합니다.

## 첫 PR을 설명하는 연습

다음 세 문장을 채울 수 있으면 좋은 출발입니다.

> **무엇을:** ___에서 ___가 달라집니다.
>
> **왜 여기서:** 원본은 ___이고, Flutter/Web/Figma는 ___로 따라옵니다.
>
> **어떻게 확인:** ___ 명령과 ___ 화면에서 확인했습니다.

막히면 [증상별 해결 안내](docs/contributing/verification.md)를 보고,
실패한 명령·실행 디렉터리·오류 메시지를 이슈에 남기세요.
