# CoUI Web 누락 컴포넌트 목록

## 현황
- **coui_flutter**: 110개 파일 (80+ 컴포넌트)
- **coui_web**: 15개 컴포넌트만 구현됨
- **누락**: 약 95개 컴포넌트

## 이미 구현된 컴포넌트 (coui_web)
1. Alert
2. Badge ✅
3. Button ✅ (lint 개선 완료)
4. Card
5. Checkbox ✅
6. Divider
7. Icon
8. Input ✅
9. Link
10. Loading
11. Progress
12. Radio
13. Select
14. TextArea
15. Toggle

## 누락된 컴포넌트 (우선순위별)

### 🔴 High Priority - Display 카테고리
1. **Avatar** - 사용자 프로필, 아이콘 표시
2. **Carousel** - 이미지/콘텐츠 슬라이더
3. **Chip** - 태그, 필터 표시
4. **Skeleton** - 로딩 상태 표시
5. **Spinner** / CircularProgressIndicator - 로딩 인디케이터
6. **LinearProgressIndicator** - 진행률 바
7. **CodeSnippet** - 코드 표시
8. **Calendar** - 날짜 선택기
9. **DotIndicator** - 페이지 인디케이터
10. **KeyboardShortcut** - 키보드 단축키 표시
11. **NumberTicker** - 숫자 애니메이션
12. **FadeScroll** - 스크롤 페이드 효과

### 🟡 Medium Priority - Form 카테고리
1. **Slider** - 범위 선택
2. **Switch** - 토글 스위치
3. **RadioGroup** - 라디오 버튼 그룹
4. **Autocomplete** - 자동완성 입력
5. **DatePicker** - 날짜 선택
6. **TimePicker** - 시간 선택
7. **ColorPicker** - 색상 선택
8. **StarRating** - 별점 입력
9. **ChipInput** - 태그 입력
10. **PhoneInput** - 전화번호 입력
11. **InputOTP** - OTP 입력
12. **FormattedInput** - 포맷된 입력
13. **FileInput** / FilePicker - 파일 업로드
14. **ItemPicker** - 아이템 선택
15. **MultipleChoice** - 다중 선택
16. **Sortable** - 드래그 앤 드롭 정렬
17. **Form** / FormField / Validated - 폼 관리

### 🟢 Lower Priority - Layout 카테고리
1. **Dialog** / AlertDialog - 모달 대화상자
2. **Drawer** - 사이드 패널
3. **Accordion** - 접을 수 있는 섹션
4. **Collapsible** - 접기/펼치기
5. **Breadcrumb** - 경로 표시
6. **FocusOutline** - 포커스 아웃라인
7. **OutlinedContainer** - 테두리 컨테이너
8. **OverflowMarquee** - 오버플로우 마키
9. **Resizable** - 크기 조절
10. **Scaffold** - 레이아웃 스캐폴드
11. **ScrollableClient** - 스크롤 클라이언트
12. **StageContainer** - 스테이지 컨테이너
13. **Stepper** / Steps - 단계 표시
14. **Table** - 테이블
15. **Timeline** - 타임라인
16. **Tree** - 트리 뷰
17. **Window** - 윈도우

### 🔵 Navigation 카테고리
1. **NavigationBar** - 내비게이션 바
2. **Pagination** - 페이지네이션
3. **Tabs** / TabList / TabPane / TabContainer - 탭
4. **Subfocus** - 서브 포커스
5. **Switcher** - 스위처

### 🟣 Menu 카테고리
1. **Menu** - 메뉴
2. **Menubar** - 메뉴바
3. **NavigationMenu** - 내비게이션 메뉴
4. **ContextMenu** - 컨텍스트 메뉴
5. **DropdownMenu** - 드롭다운 메뉴
6. **Popup** - 팝업

### 🟠 Overlay 카테고리
1. **HoverCard** - 호버 카드
2. **Popover** - 팝오버
3. **Tooltip** - 툴팁
4. **Toast** - 토스트 알림
5. **RefreshTrigger** - 새로고침 트리거
6. **Swiper** - 스와이프

### ⚫ Control 카테고리
1. **Clickable** - 클릭 가능한 요소
2. **Command** - 커맨드
3. **Hover** - 호버
4. **Scrollbar** - 스크롤바
5. **Scrollview** - 스크롤 뷰

## 구현 전략

### Phase 1: 핵심 Display 컴포넌트 (1-2주)
- Avatar, Skeleton, Spinner, Chip, Carousel
- 목표: 기본적인 UI 표시 컴포넌트 완성

### Phase 2: 필수 Form 컴포넌트 (2-3주)
- Slider, Switch, DatePicker, TimePicker, RadioGroup
- 목표: 주요 입력 컴포넌트 완성

### Phase 3: Layout & Navigation (2주)
- Dialog, Tabs, Pagination, NavigationBar, Accordion
- 목표: 페이지 구조 및 네비게이션 완성

### Phase 4: Advanced 컴포넌트 (3-4주)
- Menu, Overlay, 나머지 Form 컴포넌트들
- 목표: 고급 기능 완성

## 구현 시 주의사항

1. **API 호환성**: coui_flutter의 API와 최대한 동일하게 유지
2. **DaisyUI 매핑**: DaisyUI 클래스를 활용하여 구현
3. **Named Constructors**: .primary(), .secondary() 등 제공
4. **이벤트 매핑**: Flutter events → Web events 변환
5. **Lint 준수**: DCM 린트 통과하도록 구현

## 다음 구현 컴포넌트
1. **Avatar** (Display - High Priority)
2. **Skeleton** (Display - High Priority)
3. **Slider** (Form - Medium Priority)