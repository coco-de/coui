# 제품별 폼 디자인과 반응형 전시

CoUI의 기본 모양은 출발점이다. 제품의 서체·정보 위계·밀도·모서리를 모두 기본값으로
고정할 필요는 없다. 전역 테마 → 컴포넌트 테마 → 인스턴스 스타일 순서로 필요한 차이만
지정한다. 기존 컴포넌트가 제공하는 동작과 접근성은 유지한다.

## 넓이와 터치 크기는 별개로 조정한다

날짜·시간 입력의 `triggerStyle`은 공개된 `CoreTextFieldStyle` 슬롯이다. 부모는 가용 폭을
정하고, 트리거 슬롯은 높이를 정한다. `48`을 모든 제품의 기본값으로 바꾸지 않고 터치
화면에서 선택할 수 있다. Flutter와 Web에서 같은 스타일 계약을 쓴다.

```dart
const touchField = CoreTextFieldStyle(minHeight: CoreA11ySize.touchTarget);

DatePicker(datePickerStyle: const CoreDatePickerStyle(triggerStyle: touchField));
TimePicker(timePickerStyle: const CoreTimePickerStyle(triggerStyle: touchField));
```

Figma에서는 바깥 인스턴스만 Fill로 바꿔서는 충분하지 않다. root → field → trigger가
연속해서 폭을 받아야 한다. 생성기 수정은 이 연결을 유지한다. 40px은 기본 md 높이이며,
필요한 제품 높이는 노출된 TextField 인스턴스와 코드의 트리거 스타일을 함께 맞춘다.

## 일반 설명과 검증 메시지를 구분한다

`NumberInput(description: ...)`은 일반 설명이다. 오류를 보여 줄 때는 양 플랫폼에서
`errorText`를 전달한다. 오류가 사라지면 `null`로 돌려 도움말을 다시 보여 준다.

```dart
NumberInput(
  description: '최대 8명까지 선택할 수 있어요',
  errorText: invalid ? '인원을 다시 확인해 주세요' : null,
  min: 1,
  max: 8,
)
```

Figma의 기존 `Description` 속성 키는 보존한다. `Variant=error`에서는 같은 슬롯이
오류 메시지 역할로 오류 색을 쓴다. 기존 문구 덮어쓰기를 새 속성으로 이동할 필요가 없다.

## TextArea 내용과 부가 영역

값을 표시할 때 `Value=true`, `Show placeholder=false`로 설정한다. Figma Boolean은
다른 Boolean의 반대 값을 표현하지 못하므로 두 속성을 명시한다. 자리 표시 글자 노드를
직접 찾아 숨기는 깊은 덮어쓰기는 필요 없다. 오류 변형도 같은 설명·자리 표시 슬롯을 가진다.

설명과 카운터가 모두 꺼지면 부가 영역이 접힌다. 생성기는 빈 Hug 프레임이 마지막 높이를
유지하는 Figma 동작을 피하도록 보이지 않는 0 크기 레이아웃 앵커를 둔다. 앵커는 그림을
그리지 않고, 카운터 간격은 카운터 자신에게 붙인다.

## Widgetbook과 앱의 글자 크기를 맞춘다

Widgetbook은 자체 앱 루트를 사용한다. CoUI 테마만 넣으면 `CoUIApp`의 반응형 제목 크기
선택이 실행되지 않을 수 있다. 공식 `ViewportAddon`이 선택한 `MediaQuery` 아래에서
공개 범위 위젯을 적용한다. 바깥 브라우저 폭으로 계산하지 않는다.

```dart
TypographyTierScope(
  tier: CoreBreakpoint.forWidth(MediaQuery.sizeOf(context).width).toTier(),
  child: child,
)
```

제품이 자체 타이포그래피를 정했다면 그 테마를 먼저 공급한다. 이 범위는 기존 역할을
선택한 화면 폭에 맞춰 접으며, 제품의 글꼴·굵기 선택을 대신 결정하지 않는다.

## 합성과 발행의 경계

Drawer의 내용은 제품 컴포넌트로 만든 뒤 `Content` 인스턴스 교체 슬롯에 넣을 수 있다.
임의의 일반 프레임을 인스턴스 내부에 추가하는 것은 Figma 모델의 제약이다. 인스턴스를
분리하거나 라이브러리 외곽선을 복제하기 전에 제품 컴포넌트 슬롯으로 합성한다.

생성기 코드 수정, 플러그인 빌드, 실제 Generate, 라이브러리 게시, 제품 업데이트 수락은
각각 별도 단계다. 코드 테스트나 임시 복제본의 리사이즈 검증만으로 게시 완료라고 하지 않는다.
