/// Hidden 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="hidden/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`hidden_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'hidden_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _hidden;

/// 장면 이름(`hidden/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'hidden/states': () => _captionedStack([
    ('hidden: false', _column(hidden: false)),
    ('hidden: true', _column(hidden: true)),
  ]),
  'hidden/keep-space': () => _captionedStack([
    ('keepSpace: false', _column(hidden: true)),
    ('keepSpace: true', _column(hidden: true, keepSpace: true)),
  ]),
  'hidden/direction': () => _captionedStack([
    ('vertical — 높이를 접습니다', _column(hidden: true)),
    ('horizontal — 폭을 접습니다', _row(CoreHiddenDirection.horizontal, hidden: true, child: _icon())),
  ]),
  'hidden/related-collapsible': () => const SizedBox(
    width: CoreSpace.space192,
    child: Collapsible(
      trigger: Text('고급 설정'),
      content: Text('접었다 펴는 내용'),
      expanded: true,
    ),
  ),
  'hidden/related-swap': () => const Swap(checked: true, onContent: Text('일시정지'), offContent: Text('재생')),
};

Widget _hidden(Map<String, String> props, String? label) {
  final direction = page.hiddenPreviewDirection(props);
  final hidden = previewFlag(props, 'hidden');
  final keepSpace = previewFlag(props, 'keepSpace');
  return direction == CoreHiddenDirection.vertical
      ? _column(hidden: hidden, keepSpace: keepSpace)
      : _row(direction, hidden: hidden, keepSpace: keepSpace);
}

Widget _target(CoreHiddenDirection direction, {required bool hidden, bool keepSpace = false, Widget? child}) => Hidden(
  hidden: hidden,
  direction: direction,
  keepSpace: keepSpace,
  child: child ?? const Badge(child: Text(page.hiddenDemoContent)),
);

/// 줄 바꿈이 없는 자식 — Web 의 가로 접기는 글자를 줄 바꿈한다.
Widget _icon() => const Icon(LucideIcons.bell);

/// 세로로 쌓은 앞 · 대상 · 뒤.
Widget _column({required bool hidden, bool keepSpace = false}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space8,
  children: [
    const Text(page.hiddenDemoBefore).bodySmall.onSurfaceVariant,
    _target(CoreHiddenDirection.vertical, hidden: hidden, keepSpace: keepSpace),
    const Text(page.hiddenDemoAfter).bodySmall.onSurfaceVariant,
  ],
);

/// 가로로 늘어놓은 앞 · 대상 · 뒤.
Widget _row(CoreHiddenDirection direction, {required bool hidden, bool keepSpace = false, Widget? child}) => Row(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space8,
  children: [
    const Text(page.hiddenDemoBefore).bodySmall.onSurfaceVariant,
    _target(direction, hidden: hidden, keepSpace: keepSpace, child: child),
    const Text(page.hiddenDemoAfter).bodySmall.onSurfaceVariant,
  ],
);

/// 위에 이름을 단 조각을 세로로 쌓는다.
Widget _captionedStack(List<(String, Widget)> entries) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space24,
  children: [
    for (final (caption, child) in entries)
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CoreSpace.space8,
        children: [Text(caption).labelSmall.onSurfaceVariant, child],
      ),
  ],
);
