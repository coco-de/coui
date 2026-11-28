/// Hidden 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `hidden_web.dart` · `hidden_flutter.dart` 가 그린다.
///
/// 플레이그라운드는 미리보기를 새로 만들지 않는다 — `hidden` 을 바꾸면 같은
/// Hidden 이 전환하며 숨고 나타난다. 숨긴 동안에도 자식은 남으므로, 자식에는
/// 누르거나 포커스를 받는 것을 두지 않는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/hidden.md`.
const String slug = 'hidden';

/// 숨기는 자식의 글자.
const String hiddenDemoContent = '숨길 수 있는 내용';

/// 숨기는 자식 앞과 뒤에 두는 글자 — 자리가 접히는지 보여 준다.
const String hiddenDemoBefore = '앞의 내용';
const String hiddenDemoAfter = '뒤의 내용';

/// 플레이그라운드.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'direction': 'vertical'},
  controls: [
    DocsPlaygroundFlag(label: 'hidden', on: {'hidden': 'true'}),
    DocsPlaygroundChoice(label: 'direction', prop: 'direction', options: ['vertical', 'horizontal'], segmented: true),
    DocsPlaygroundFlag(label: 'keepSpace', on: {'keepSpace': 'true'}),
  ],
  code: _hiddenCode,
);

/// 크기 표. Hidden 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 속성 `direction` → 접는 축. 없거나 모르는 값은 `vertical`.
CoreHiddenDirection hiddenPreviewDirection(Map<String, String> props) =>
    previewEnum(CoreHiddenDirection.values, props['direction'], CoreHiddenDirection.vertical);

String _hiddenCode(Map<String, String> props, String? label) => [
  'Hidden(',
  '  hidden: ${previewFlag(props, 'hidden')},',
  if (hiddenPreviewDirection(props) == CoreHiddenDirection.horizontal) '  direction: CoreHiddenDirection.horizontal,',
  if (previewFlag(props, 'keepSpace')) '  keepSpace: true,',
  "  child: Badge(child: Text('$hiddenDemoContent')),",
  ')',
].join('\n');
