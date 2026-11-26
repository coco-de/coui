/// Kbd 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="kbd/...">` · `<Card demo>` · `<Anatomy demo>` 가 읽는다.
/// 같은 이름의 Web 파일(`kbd_web.dart`)과 컴포넌트 · 속성 · 장면 이름이
/// 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;

import '../../previews/props/flutter_prop_previews.dart';
import 'kbd_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _kbd;

/// 장면 이름(`kbd/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'kbd/anatomy': () => const Kbd(keys: ['Ctrl', 'Shift', 'P']),
  'kbd/constructor-keys': () => const Kbd(keys: ['Ctrl', 'C']),
  'kbd/constructor-single': () => Kbd.single(keyText: 'Esc'),
  'kbd/constructor-icon': () => _iconKey(LucideIcons.cornerDownLeft, label: '확인'),
  'kbd/counts': () => _spread([
    for (final (caption, keys) in page.kbdCountSamples) _captioned(caption, Kbd(keys: keys)),
  ]),
  'kbd/shortcut-list': _shortcutList,
  // `page.kbdActivatorSampleKeys` 와 같은 키가 나온다.
  'kbd/activator': () => Kbd(
    keys: kbdKeysFromActivator(
      const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true),
    ),
  ),
  'kbd/do-platform': () => _spread([
    _captioned('macOS', const Kbd(keys: ['⌘', 'K'])),
    _captioned('Windows · Linux', const Kbd(keys: ['Ctrl', 'K'])),
  ]),
  'kbd/dont-plus': () => const Kbd(keys: ['Ctrl', '+', 'C']),
  'kbd/do-text': () => const Text('저장은 Ctrl+S 입니다.').bodyMedium.onSurface,
  'kbd/dont-in-sentence': () => _inline([
    const Text('저장은').bodyMedium.onSurface,
    const Kbd(keys: ['Ctrl', 'S']),
    const Text('입니다.').bodyMedium.onSurface,
  ]),
  'kbd/do-three': () => const Kbd(keys: ['Ctrl', 'Shift', 'P']),
  'kbd/dont-four': () => const Kbd(keys: ['Ctrl', 'Alt', 'Shift', 'F5']),
  'kbd/related-command': () => _inline([
    _iconKey(LucideIcons.arrowUp),
    _iconKey(LucideIcons.arrowDown),
    const Text('이동').labelSmall.onSurfaceVariant,
    const Kbd(keys: ['esc']),
    const Text('닫기').labelSmall.onSurfaceVariant,
  ]),
  'kbd/related-tooltip': () => Tooltip(
    message: '복사',
    tooltipChild: _inline([
      const Text('복사'),
      const Kbd(keys: ['Ctrl', 'C']),
    ]),
    // 글자 없는 아이콘 버튼 — 이름을 `Semantics` 로 준다.
    child: Semantics(
      label: '복사',
      child: Button(
        variant: CoreButtonVariant.outline,
        shape: CoreButtonShape.square,
        onPressed: () {},
        child: const Icon(LucideIcons.copy),
      ),
    ),
  ),
};

Widget _kbd(Map<String, String> props, String? label) => Kbd(
  keys: page.kbdPreviewKeys(props),
  kbdStyle: CoreKbdStyle(
    keySeparatorSpacing: page.kbdPreviewSpacing(props),
    keyShadow: page.kbdPreviewShadow(props) ? CoreShadow.xs : null,
  ),
);

/// 아이콘 키 하나. [label] 을 주지 않으면 이름이 없는 키다.
Widget _iconKey(IconName icon, {String? label}) => Kbd.icon(
  keyContent: Icon(icon, iconStyle: page.kbdIconKeyStyle),
  label: label,
);

/// 키캡과 글을 세로 가운데에 맞춰 한 줄에 놓는다 — 폭이 모자라면 줄을 바꾼다.
Widget _inline(List<Widget> children) => Wrap(
  spacing: CoreSpace.space8,
  runSpacing: CoreSpace.space8,
  alignment: WrapAlignment.center,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: children,
);

/// 이름을 단 조각들을 넓게 띄워 나란히 놓는다 — 폭이 모자라면 줄을 바꾼다.
Widget _spread(List<Widget> children) => Wrap(
  spacing: CoreSpace.space16,
  runSpacing: CoreSpace.space16,
  alignment: WrapAlignment.center,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: children,
);

/// 아래에 이름을 단 장면 조각.
Widget _captioned(String caption, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space8,
  children: [child, Text(caption).labelSmall.onSurfaceVariant],
);

/// 동작 이름과 단축키를 한 줄씩 늘어놓는다.
Widget _shortcutList() => SizedBox(
  width: CoreSpace.space256,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    spacing: CoreSpace.space12,
    children: [
      for (final (action, keys) in page.kbdShortcutSamples)
        Row(
          spacing: CoreSpace.space12,
          children: [
            Expanded(child: Text(action).bodySmall.onSurface),
            Kbd(keys: keys),
          ],
        ),
    ],
  ),
);
