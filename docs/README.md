# CoUI Flutter Documentation

> **AI/LLM을 위한 coui_flutter 컴포넌트 문서**

이 디렉토리에는 AI 모델이 coui_flutter를 효과적으로 사용할 수 있도록 작성된 문서들이 포함되어 있습니다.

## 📚 문서 목록

### 1. [CoUI Flutter LLM 가이드](./coui_flutter_llm_guide.md)
**메인 가이드 - 가장 중요한 문서**

80개 이상의 coui_flutter 컴포넌트에 대한 완전한 참조 가이드입니다.

**포함 내용**:
- ✅ 컴포넌트 명명 규칙 (Co 접두사 없음!)
- ✅ 모든 카테고리별 컴포넌트 설명
- ✅ 실전 사용 예제
- ✅ 일반적인 사용 패턴
- ✅ 자주 하는 실수
- ✅ 빠른 참조 인덱스

**크기**: ~1,400줄, 매우 상세한 설명

**사용 시기**: 
- 처음 coui_flutter를 사용할 때
- 특정 컴포넌트의 상세한 사용법이 필요할 때
- 실전 예제가 필요할 때

---

### 2. [빠른 참조 가이드](./coui_flutter_quick_reference.md)
**치트시트 - 빠른 검색용**

자주 사용하는 컴포넌트와 패턴을 빠르게 찾을 수 있는 참조 문서입니다.

**포함 내용**:
- ✅ 컴포넌트별 기본 사용법 (한 줄)
- ✅ 간단한 예제 코드
- ✅ 알파벳순 컴포넌트 목록
- ✅ 용도별 빠른 찾기

**크기**: ~400줄, 간결한 참조

**사용 시기**:
- 컴포넌트 이름만 빠르게 찾고 싶을 때
- 기본 사용법만 확인하고 싶을 때
- 어떤 컴포넌트가 있는지 전체 목록을 보고 싶을 때

---

### 3. [일반적인 UI 패턴](./coui_flutter_common_patterns.md)
**전체 화면 예제 - 실전 패턴 모음**

실제 앱 개발에서 자주 사용하는 전체 화면 패턴들입니다.

**포함 내용**:
- ✅ 로그인/회원가입 화면
- ✅ 대시보드
- ✅ 프로필 화면
- ✅ 리스트/그리드 화면
- ✅ 설정 화면
- ✅ 검색 화면
- ✅ 폼 화면

**크기**: ~700줄, 실행 가능한 전체 예제

**사용 시기**:
- 특정 화면 전체를 구현해야 할 때
- 화면 레이아웃 패턴이 필요할 때
- 여러 컴포넌트를 조합하는 방법을 알고 싶을 때

---

### 4. [컴포넌트 메타데이터](./component_metadata.json)
**기계 판독용 - JSON 형식**

모든 컴포넌트의 메타데이터를 JSON 형식으로 제공합니다.

**포함 내용**:
- 컴포넌트 이름
- 설명
- 예제 개수
- 예제 파일 경로

**사용 시기**:
- 프로그래밍 방식으로 컴포넌트 정보가 필요할 때
- 자동화된 도구를 만들 때

---

## 🚀 빠른 시작

### AI 모델이 처음 coui_flutter를 사용할 때

1. **먼저 읽어야 할 것**: [coui_flutter_llm_guide.md](./coui_flutter_llm_guide.md)의 "개요"와 "중요: 명명 규칙" 섹션
2. **컴포넌트 찾기**: [coui_flutter_quick_reference.md](./coui_flutter_quick_reference.md)에서 필요한 컴포넌트 검색
3. **전체 화면 구현**: [coui_flutter_common_patterns.md](./coui_flutter_common_patterns.md)에서 유사한 패턴 참조

---

## 🎯 가장 중요한 규칙

### ❌ Co 접두사 사용 금지!

```dart
// ❌ 절대 이렇게 하지 마세요!
CoButton(...)
CoAvatar(...)
CoCard(...)
```

### ✅ 올바른 사용법

```dart
// ✅ 이렇게 사용하세요
PrimaryButton(...)
Avatar(...)
Card(...)
```

**모든 coui_flutter 컴포넌트는 Co 접두사 없이 사용합니다!**

---

## 📊 컴포넌트 통계

- **총 컴포넌트 수**: 83개
- **카테고리**: 8개 (Control, Display, Form, Layout, Menu, Navigation, Overlay, Text)
- **검증된 예제**: 모든 컴포넌트에 실행 가능한 예제 포함
- **실전 패턴**: 8가지 일반적인 화면 패턴

---

## 🔍 컴포넌트 찾기 가이드

### 용도별 검색

**버튼이 필요하다면?**
→ `PrimaryButton`, `SecondaryButton`, `GhostButton`, `IconButton`

**입력 필드가 필요하다면?**
→ `TextField`, `TextArea`, `Select`, `Checkbox`, `Toggle`

**레이아웃이 필요하다면?**
→ `Card`, `Divider`, `Gap`, `Accordion`

**표시 요소가 필요하다면?**
→ `Avatar`, `Badge`, `Progress`, `Loading`

**피드백이 필요하다면?**
→ `Dialog`, `Toast`, `Tooltip`, `Alert`

---

## 📖 추가 리소스

### 실제 예제 코드
- 경로: `packages/coui_flutter/docs/lib/pages/docs/components/`
- 모든 컴포넌트의 실행 가능한 예제가 있습니다

### 컴포넌트 소스 코드
- 경로: `packages/coui_flutter/lib/src/components/`
- 컴포넌트 구현 세부 사항을 확인할 수 있습니다

### Export 목록
- 파일: `packages/coui_flutter/lib/coui_flutter.dart`
- 모든 export된 컴포넌트 목록을 확인할 수 있습니다

---

## ✅ 문서 사용 체크리스트

AI 모델이 coui_flutter를 사용하기 전에 확인하세요:

- [ ] Co 접두사를 사용하지 않는다는 것을 알고 있나요?
- [ ] `PrimaryButton`, `GhostButton` 같은 variant 시스템을 이해했나요?
- [ ] `Gap.v()`, `Gap.h()`로 간격을 설정하는 방법을 알고 있나요?
- [ ] Text extensions (`.bold`, `.muted`, `.large`)를 사용할 수 있나요?
- [ ] `setState()`를 사용하여 상태를 업데이트한다는 것을 알고 있나요?

---

## 📝 문서 업데이트

**최종 업데이트**: 2024년
**coui_flutter 버전**: 0.1.0+
**문서 버전**: 1.0

### 변경 이력

- **v1.0** (2024): 초기 LLM 문서 생성
  - 메인 가이드 작성 (1,400줄)
  - 빠른 참조 가이드 작성
  - 일반적인 패턴 모음 작성
  - 컴포넌트 메타데이터 자동 추출

---

## 🤝 기여

문서 개선 제안이나 오류 발견 시:
1. 예제 코드 확인: `packages/coui_flutter/docs/`
2. 이슈 제출 또는 PR 생성

---

## 📄 라이선스

이 문서는 coui_flutter 프로젝트의 일부이며 동일한 라이선스를 따릅니다.

---

**Happy Coding with CoUI Flutter! 🚀**

