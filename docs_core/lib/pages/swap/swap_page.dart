/// Swap 페이지 — 플레이그라운드와 장면이 함께 읽는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `swap_web.dart` · `swap_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성은 넷이다: `animation`(`CoreSwapAnimation` 의 이름), `face`(`icon` ·
/// `text`, 두 면에 넣는 내용), `checked`, `interactive`(`false` 면 `onToggle`
/// 없이 그린다).
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/swap.md`.
const String slug = 'swap';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => DocsPlaygroundSpec(
  initial: const {'animation': 'rotate', 'face': 'icon'},
  controls: [
    DocsPlaygroundChoice(
      label: 'animation',
      prop: 'animation',
      options: [for (final value in CoreSwapAnimation.values) value.name],
      segmented: true,
    ),
    const DocsPlaygroundChoice(label: '면 내용', prop: 'face', options: ['icon', 'text'], segmented: true),
    const DocsPlaygroundFlag(label: '켜짐', on: {'checked': 'true'}),
    const DocsPlaygroundFlag(label: '표시 전용', on: {'interactive': 'false'}),
  ],
  code: _swapCode,
  webCode: _swapWebCode,
);

/// 크기 표. Swap 은 크기 축이 없고 두 면의 크기를 따른다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 누를 수 있는 아이콘 면의 접근 가능한 이름.
const String swapPreviewName = '메뉴';

/// `face=text` 의 `offContent` 글자.
const String swapPreviewOffText = '꺼짐';

/// `face=text` 의 `onContent` 글자.
const String swapPreviewOnText = '켜짐';

/// `swap/sizing` 장면의 전환 효과 — 크기 규칙이 갈리는 두 갈래.
const List<CoreSwapAnimation> swapSizingAnimations = [CoreSwapAnimation.none, CoreSwapAnimation.flip];

/// `swap/sizing` 장면의 좁은 면 글자.
const String swapSizingOffText = '끔';

/// `swap/sizing` 장면의 넓은 면 글자.
const String swapSizingOnText = '알림 켜짐';

/// 속성의 `animation`. 없거나 모르는 값은 `none`.
CoreSwapAnimation swapPreviewAnimation(Map<String, String> props) =>
    previewEnum(CoreSwapAnimation.values, props['animation'], CoreSwapAnimation.none);

/// 속성의 `checked`.
bool swapPreviewChecked(Map<String, String> props) => previewFlag(props, 'checked');

/// `onToggle` 을 주는가.
bool swapPreviewInteractive(Map<String, String> props) => previewFlag(props, 'interactive', fallback: true);

/// 두 면이 글자인가. 아니면 아이콘이다.
bool swapPreviewTextFace(Map<String, String> props) => props['face'] == 'text';

/// 누를 수 있고 면에 글자가 없어 이름을 따로 주어야 하는가.
bool swapPreviewNeedsName(Map<String, String> props) => swapPreviewInteractive(props) && !swapPreviewTextFace(props);

String _swapCode(Map<String, String> props, String? label) {
  final call = _swapCall(_swapArguments(props));
  if (!swapPreviewNeedsName(props)) return _withState(props, call);
  // 누를 수 있는 Swap 은 시맨틱 노드가 둘이라, 이름과 동작을 `MergeSemantics` 로 합친다.
  final child = call.split('\n').join('\n    ');
  return _withState(
    props,
    "MergeSemantics(\n  child: Semantics(\n    label: '$swapPreviewName',\n    child: $child,\n  ),\n)",
  );
}

String _swapWebCode(Map<String, String> props, String? label) => _withState(
  props,
  _swapCall([
    ..._swapArguments(props),
    if (swapPreviewNeedsName(props)) "attributes: {'aria-label': '$swapPreviewName'},",
  ]),
);

/// 두 플랫폼이 같이 쓰는 인자 줄.
List<String> _swapArguments(Map<String, String> props) {
  final animation = swapPreviewAnimation(props);
  final interactive = swapPreviewInteractive(props);
  final text = swapPreviewTextFace(props);
  return [
    if (interactive) 'checked: checked,' else if (swapPreviewChecked(props)) 'checked: true,',
    if (animation != CoreSwapAnimation.none) 'animation: CoreSwapAnimation.${animation.name},',
    if (text) "offContent: Text('$swapPreviewOffText')," else 'offContent: Icon(LucideIcons.menu),',
    if (text) "onContent: Text('$swapPreviewOnText')," else 'onContent: Icon(LucideIcons.x),',
    if (interactive) 'onToggle: (value) => setState(() => checked = value),',
  ];
}

String _swapCall(List<String> arguments) => 'Swap(\n${arguments.map((line) => '  $line').join('\n')}\n)';

/// 누를 수 있으면 `checked` 는 앱의 상태다 — 그 처음 값을 코드 위에 적는다.
String _withState(Map<String, String> props, String code) =>
    swapPreviewInteractive(props) ? '// bool checked = ${swapPreviewChecked(props)};\n$code' : code;
