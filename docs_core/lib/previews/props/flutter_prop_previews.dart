/// 속성 문자열(`variant=outline;size=md`)로 컴포넌트를 그리는 빌더 — Flutter.
///
/// 컴포넌트 페이지(v2 템플릿)의 `<Preview>` · `<VariantRow>` · `<SizeSpec>` ·
/// 미리보기를 단 `<Card>` 가 쓴다. 빌더는 컴포넌트마다 `pages/<slug>/<slug>_flutter.dart` 에 있다. 같은 속성을 Jaspr Web(`web_prop_previews.dart`) 빌더가 같은 이름으로
/// 읽으므로, 두 파일은 컴포넌트 · 속성 · 아이콘 이름이 늘 같아야 한다
/// (`prop_previews_parity_test.dart` 가 대조한다).
///
/// 속성은 위젯 생성자의 이름을 그대로 쓴다. 문자열 슬롯(`label`)은 값을
/// 그대로, 위젯 슬롯(`placeholder`)은 `Text` 로 감싸 넘긴다. 모르는 값은
/// 기본값으로 떨어진다 — 문서 한 줄의 오타가 페이지를 깨뜨리지 않는다.
library;

import 'package:coui_flutter/coui_flutter.dart';

export '../../pages/page_registry_flutter.g.dart' show kFlutterPropPreviews;

/// 속성 → 위젯. [label] 은 태그의 `label` 속성(버튼 라벨 같은 본문 글자).
typedef FlutterPropPreviewBuilder = Widget Function(Map<String, String> props, String? label);
