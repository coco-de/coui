/// Hidden 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="hidden/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`hidden_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'hidden_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _hidden;

/// 장면 이름(`hidden/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
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
  'hidden/related-collapsible': () => div(
    styles: Styles(raw: {'width': pinnedLengthCss(CoreSpace.space192)}),
    [
      Collapsible(
        trigger: Text('고급 설정'),
        content: Text('접었다 펴는 내용'),
        expanded: true,
        classes: 'w-full',
      ),
    ],
  ),
  'hidden/related-swap': () => Swap(checked: true, onContent: Text('일시정지'), offContent: Text('재생')),
};

Component _hidden(Map<String, String> props, String? label) {
  final direction = page.hiddenPreviewDirection(props);
  final hidden = previewFlag(props, 'hidden');
  final keepSpace = previewFlag(props, 'keepSpace');
  return direction == CoreHiddenDirection.vertical
      ? _column(hidden: hidden, keepSpace: keepSpace)
      : _row(direction, hidden: hidden, keepSpace: keepSpace);
}

Component _target(CoreHiddenDirection direction, {required bool hidden, bool keepSpace = false, Component? child}) =>
    Hidden(
      hidden: hidden,
      direction: direction,
      keepSpace: keepSpace,
      child: child ?? Badge(child: Text(page.hiddenDemoContent)),
    );

/// 줄 바꿈이 없는 자식 — Web 의 가로 접기는 글자를 줄 바꿈한다.
Component _icon() => Icon(LucideIcons.bell);

/// 세로로 쌓은 앞 · 대상 · 뒤.
Component _column({required bool hidden, bool keepSpace = false}) => _stack(
  vertical: true,
  [
    const Text(page.hiddenDemoBefore).bodySmall.onSurfaceVariant,
    _target(CoreHiddenDirection.vertical, hidden: hidden, keepSpace: keepSpace),
    const Text(page.hiddenDemoAfter).bodySmall.onSurfaceVariant,
  ],
);

/// 가로로 늘어놓은 앞 · 대상 · 뒤.
Component _row(CoreHiddenDirection direction, {required bool hidden, bool keepSpace = false, Component? child}) =>
    _stack([
      const Text(page.hiddenDemoBefore).bodySmall.onSurfaceVariant,
      _target(direction, hidden: hidden, keepSpace: keepSpace, child: child),
      const Text(page.hiddenDemoAfter).bodySmall.onSurfaceVariant,
    ]);

Component _stack(List<Component> children, {bool vertical = false}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': vertical ? 'column' : 'row',
      'align-items': vertical ? 'flex-start' : 'center',
      'gap': spaceCss(CoreSpace.space8),
    },
  ),
  children,
);

/// 위에 이름을 단 조각을 세로로 쌓는다.
Component _captionedStack(List<(String, Component)> entries) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'flex-start',
      'gap': spaceCss(CoreSpace.space24),
    },
  ),
  [
    for (final (caption, child) in entries)
      div(
        styles: Styles(
          raw: {
            'display': 'flex',
            'flex-direction': 'column',
            'align-items': 'flex-start',
            'gap': spaceCss(CoreSpace.space8),
          },
        ),
        [Text(caption).labelSmall.onSurfaceVariant, child],
      ),
  ],
);
