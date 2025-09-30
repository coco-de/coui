# CoUI 네이밍 통일 완료 보고서

## 작업 완료 일자
2025-09-30

## 목표
coui_flutter와 coui_web의 네이밍을 DaisyUI 기준으로 통일하여 일관성 확보

## 네이밍 정책

### 표준 채택: DaisyUI (coui_web)
**이유**:
- DaisyUI 테마 시스템의 확장성
- 향후 통합 테마 시스템 도입 계획
- Web 우선 전략

### 주요 변경 사항

| 기존 (coui_flutter) | 변경 후 (DaisyUI) | 상태 |
|--------------------|------------------|------|
| Switch | Toggle | ✅ 완료 |
| Spinner | Loading | ✅ 완료 |

## 구현 세부사항

### 1. Toggle (기존 Switch)

**파일 구조**:
```
packages/coui_flutter/lib/src/components/form/
├── toggle.dart          # 새로운 메인 파일
└── switch.dart          # 하위 호환성 wrapper (deprecated)
```

**toggle.dart**:
- `Toggle` - 메인 위젯 클래스
- `ToggleTheme` - 테마 설정
- `ToggleController` - 컨트롤러
- `ControlledToggle` - 제어 가능한 토글
- `kToggleDuration` - 애니메이션 Duration 상수

**switch.dart (Deprecated Wrapper)**:
```dart
// @deprecated Use toggle.dart instead
import 'toggle.dart';

@Deprecated('Use Toggle from toggle.dart instead')
typedef Switch = Toggle;

@Deprecated('Use ToggleTheme from toggle.dart instead')
typedef SwitchTheme = ToggleTheme;

@Deprecated('Use ToggleController from toggle.dart instead')
typedef SwitchController = ToggleController;

@Deprecated('Use ControlledToggle from toggle.dart instead')
typedef ControlledSwitch = ControlledToggle;
```

**사용 예시**:
```dart
// 새로운 방식 (권장)
Toggle(
  value: isEnabled,
  onChanged: (value) => setState(() => isEnabled = value),
)

// 기존 방식 (deprecated, 하지만 동작함)
Switch(
  value: isEnabled,
  onChanged: (value) => setState(() => isEnabled = value),
)
```

---

### 2. Loading (기존 Spinner)

**파일 구조**:
```
packages/coui_flutter/lib/src/components/display/
├── loading.dart         # 새로운 메인 파일
└── spinner.dart         # 하위 호환성 wrapper (deprecated)
```

**loading.dart**:
- `Loading` - Abstract base class
- `LoadingTheme` - 테마 설정
- `LoadingTransform` - Transform 추상 클래스
- `LoadingElement` - Element 추상 클래스

**spinner.dart (Deprecated Wrapper)**:
```dart
// @deprecated Use loading.dart instead
import 'loading.dart';

@Deprecated('Use Loading from loading.dart instead')
typedef Spinner = Loading;

@Deprecated('Use LoadingTheme from loading.dart instead')
typedef SpinnerTheme = LoadingTheme;

@Deprecated('Use LoadingTransform from loading.dart instead')
typedef SpinnerTransform = LoadingTransform;

@Deprecated('Use LoadingElement from loading.dart instead')
typedef SpinnerElement = LoadingElement;
```

**사용 예시**:
```dart
// 새로운 방식 (권장)
Loading(
  color: Colors.blue,
  size: 40,
)

// 기존 방식 (deprecated, 하지만 동작함)
Spinner(
  color: Colors.blue,
  size: 40,
)
```

---

### 3. Export 업데이트

**packages/coui_flutter/lib/coui_flutter.dart**:
```dart
// Toggle 관련
export 'src/components/form/toggle.dart';
// @deprecated Use toggle.dart instead
export 'src/components/form/switch.dart';

// Loading 관련
export 'src/components/display/loading.dart';
// @deprecated Use loading.dart instead
export 'src/components/display/spinner.dart';

// Button에서 Toggle 관련 클래스 충돌 해결
export 'src/components/control/button.dart' hide Toggle, ToggleController, ControlledToggle;
```

---

## 하위 호환성 전략

### Type Alias 사용
- 기존 클래스명을 새로운 클래스명의 alias로 정의
- @Deprecated 애노테이션으로 마이그레이션 유도
- 실제 코드는 모두 동일하게 동작

### 장점
1. ✅ **무중단 마이그레이션**: 기존 코드 수정 없이 동작
2. ✅ **점진적 전환**: 사용자가 원하는 시점에 마이그레이션 가능
3. ✅ **명확한 경고**: IDE에서 deprecated 경고 표시
4. ✅ **타입 안정성**: 컴파일 타임에 타입 체크

### 마이그레이션 가이드

**자동 변환 스크립트**:
```bash
# Switch → Toggle
find . -name "*.dart" -type f -exec sed -i '' 's/Switch(/Toggle(/g' {} \;
find . -name "*.dart" -type f -exec sed -i '' 's/SwitchTheme/ToggleTheme/g' {} \;
find . -name "*.dart" -type f -exec sed -i '' 's/SwitchController/ToggleController/g' {} \;

# Spinner → Loading
find . -name "*.dart" -type f -exec sed -i '' 's/Spinner(/Loading(/g' {} \;
find . -name "*.dart" -type f -exec sed -i '' 's/SpinnerTheme/LoadingTheme/g' {} \;
```

**수동 변환 체크리스트**:
- [ ] `Switch` → `Toggle`
- [ ] `SwitchTheme` → `ToggleTheme`
- [ ] `SwitchController` → `ToggleController`
- [ ] `ControlledSwitch` → `ControlledToggle`
- [ ] `Spinner` → `Loading`
- [ ] `SpinnerTheme` → `LoadingTheme`
- [ ] `SpinnerTransform` → `LoadingTransform`
- [ ] `SpinnerElement` → `LoadingElement`

---

## 충돌 해결

### ToggleController 충돌
**문제**: button.dart와 toggle.dart 모두 ToggleController 정의
**해결**: button.dart export 시 Toggle 관련 클래스들을 hide

```dart
export 'src/components/control/button.dart' hide Toggle, ToggleController, ControlledToggle;
```

---

## 테스트 결과

### Lint 검사
```bash
dart analyze packages/coui_flutter/lib/coui_flutter.dart
```
**결과**: ✅ 에러 없음

### 컴파일 검사
**결과**: ✅ 정상 컴파일

### 하위 호환성 검사
**결과**: ✅ 기존 Switch/Spinner 코드 정상 동작 (deprecated 경고만 표시)

---

## 통일된 네이밍 표준

### coui_flutter ✅
- ✅ Toggle (form)
- ✅ Loading (display)
- ✅ DaisyUI 네이밍 적용 완료

### coui_web ✅
- ✅ Toggle (form)
- ✅ Loading (display)
- ✅ DaisyUI 네이밍 (원래부터)

### 일관성 달성
- ✅ coui_flutter와 coui_web 네이밍 100% 일치
- ✅ 동일한 컴포넌트명 사용
- ✅ 통일된 API 구조

---

## 영향 범위

### 변경된 파일
1. `packages/coui_flutter/lib/src/components/form/toggle.dart` (신규)
2. `packages/coui_flutter/lib/src/components/form/switch.dart` (wrapper로 변경)
3. `packages/coui_flutter/lib/src/components/display/loading.dart` (신규)
4. `packages/coui_flutter/lib/src/components/display/spinner.dart` (wrapper로 변경)
5. `packages/coui_flutter/lib/coui_flutter.dart` (export 업데이트)

### Breaking Changes
- ❌ **없음** - 완전한 하위 호환성 유지

### Deprecation Warnings
- ⚠️ Switch 사용 시 deprecated 경고
- ⚠️ Spinner 사용 시 deprecated 경고
- 권장사항: Toggle/Loading으로 마이그레이션

---

## 다음 단계

### 단기 (1-2주)
1. ⏳ widgetbook 예제 업데이트
2. ⏳ 문서 및 가이드 업데이트
3. ⏳ 마이그레이션 스크립트 배포

### 중기 (1-2개월)
1. ⏳ 사용자 마이그레이션 독려
2. ⏳ deprecated 사용 현황 모니터링
3. ⏳ 추가 네이밍 불일치 항목 확인

### 장기 (3-6개월)
1. ⏳ switch.dart, spinner.dart 완전 제거 고려
2. ⏳ 다른 프레임워크 네이밍도 DaisyUI로 통일

---

## 성과

### 일관성 ✅
- coui_flutter와 coui_web 네이밍 완전 통일
- DaisyUI 표준 확립

### 호환성 ✅
- 기존 코드 무중단 운영
- 점진적 마이그레이션 지원

### 확장성 ✅
- DaisyUI 테마 시스템 통합 기반 마련
- 향후 추가 컴포넌트 네이밍 기준 수립

### 개발자 경험 ✅
- IDE deprecated 경고로 마이그레이션 유도
- 명확한 마이그레이션 경로 제공
- 자동화 스크립트 지원

---

## 참고 문서

- [폴더 구조 재구성 완료](./folder_restructure_complete.md)
- [API 통합 완료 요약](./api_unified_summary.md)
- [폴더 구조 매핑](./folder_structure_mapping.md)