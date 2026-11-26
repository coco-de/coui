/// Kbd 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="kbd/...">` · `<Card demo>` · `<Anatomy demo>` 가 읽는다.
/// 같은 이름의 Flutter 파일(`kbd_flutter.dart`)과 컴포넌트 · 속성 · 장면
/// 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'kbd_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _kbd;

/// 장면 이름(`kbd/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'kbd/anatomy': () => const Kbd(keys: ['Ctrl', 'Shift', 'P']),
  'kbd/constructor-keys': () => const Kbd(keys: ['Ctrl', 'C']),
  'kbd/constructor-single': () => Kbd.single(keyText: 'Esc'),
  'kbd/constructor-icon': () => _iconKey(LucideIcons.cornerDownLeft, label: '확인'),
  'kbd/counts': () => _spread([
    for (final (caption, keys) in page.kbdCountSamples) _captioned(caption, Kbd(keys: keys)),
  ]),
  'kbd/shortcut-list': _shortcutList,
  // Web 에는 `ShortcutActivator` 가 없어 키 목록을 그대로 넘긴다.
  'kbd/activator': () => const Kbd(keys: page.kbdActivatorSampleKeys),
  'kbd/do-platform': () => _spread([
    _captioned('macOS', const Kbd(keys: ['⌘', 'K'])),
    _captioned('Windows · Linux', const Kbd(keys: ['Ctrl', 'K'])),
  ]),
  'kbd/dont-plus': () => const Kbd(keys: ['Ctrl', '+', 'C']),
  'kbd/do-text': () => const Text('저장은 Ctrl+S 입니다.').bodyMedium.onSurface,
  'kbd/dont-in-sentence': () => docsWebDemoRow([
    const Text('저장은').bodyMedium.onSurface,
    const Kbd(keys: ['Ctrl', 'S']),
    const Text('입니다.').bodyMedium.onSurface,
  ]),
  'kbd/do-three': () => const Kbd(keys: ['Ctrl', 'Shift', 'P']),
  'kbd/dont-four': () => const Kbd(keys: ['Ctrl', 'Alt', 'Shift', 'F5']),
  'kbd/related-command': () => docsWebDemoRow([
    _iconKey(LucideIcons.arrowUp),
    _iconKey(LucideIcons.arrowDown),
    const Text('이동').labelSmall.onSurfaceVariant,
    const Kbd(keys: ['esc']),
    const Text('닫기').labelSmall.onSurfaceVariant,
  ]),
  'kbd/related-tooltip': () => Tooltip(
    message: '복사',
    tooltipChild: docsWebDemoRow([
      const Text('복사'),
      const Kbd(keys: ['Ctrl', 'C']),
    ]),
    // 글자 없는 아이콘 버튼 — 이름을 `aria-label` 로 준다.
    child: Button(
      variant: CoreButtonVariant.outline,
      shape: CoreButtonShape.square,
      attributes: const {'aria-label': '복사'},
      onPressed: () {},
      child: const Icon(LucideIcons.copy),
    ),
  ),
};

Component _kbd(Map<String, String> props, String? label) => Kbd(
  keys: page.kbdPreviewKeys(props),
  kbdStyle: CoreKbdStyle(
    keySeparatorSpacing: page.kbdPreviewSpacing(props),
    keyShadow: page.kbdPreviewShadow(props) ? CoreShadow.xs : null,
  ),
);

/// 아이콘 키 하나. [label] 을 주지 않으면 이름이 없는 키다.
Component _iconKey(IconName icon, {String? label}) => Kbd.icon(
  keyContent: Icon(icon, iconStyle: page.kbdIconKeyStyle),
  label: label,
);

/// 이름을 단 조각들을 넓게 띄워 나란히 놓는다 — 폭이 모자라면 줄을 바꾼다.
Component _spread(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'align-items': 'center',
      'justify-content': 'center',
      'gap': 'var(--coui-space-16)',
    },
  ),
  children,
);

/// 아래에 이름을 단 장면 조각.
Component _captioned(String caption, Component child) => div(
  styles: Styles(
    raw: {'display': 'flex', 'flex-direction': 'column', 'align-items': 'center', 'gap': 'var(--coui-space-8)'},
  ),
  [child, Text(caption).labelSmall.onSurfaceVariant],
);

/// 동작 이름과 단축키를 한 줄씩 늘어놓는다.
Component _shortcutList() => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': 'var(--coui-space-12)',
      'width': pinnedLengthCss(CoreSpace.space256),
      'max-width': '100%',
    },
  ),
  [
    for (final (action, keys) in page.kbdShortcutSamples)
      div(
        styles: Styles(raw: {'display': 'flex', 'align-items': 'center', 'gap': 'var(--coui-space-12)'}),
        [
          div(styles: Styles(raw: {'flex': '1', 'min-width': '0'}), [Text(action).bodySmall.onSurface]),
          Kbd(keys: keys),
        ],
      ),
  ],
);
