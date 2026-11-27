/// Icon 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="icon/...">` 가 읽는다. 같은 이름의 Web 파일(`icon_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 장면은 패키지에 번들된 Lucide 아이콘만 쓴다 — 네트워크 없이 그려진다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'icon_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _icon;

/// 장면 이름(`icon/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'icon/sizes': () => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.end,
    spacing: CoreSpace.space20,
    runSpacing: CoreSpace.space20,
    children: [
      for (final size in iconSizeSteps)
        _captioned('${size.toInt()}', Icon(LucideIcons.settings, iconStyle: CoreIconStyle(size: size))),
    ],
  ),
  'icon/colors': () => docsFlutterDemoRow([
    _captioned(
      iconPreviewInheritColor,
      const Icon(LucideIcons.heart, iconStyle: CoreIconStyle(size: CoreIconSize.size32)),
    ),
    for (final MapEntry(key: name, value: token) in iconPreviewColors.entries)
      _captioned(
        name,
        Icon(
          LucideIcons.heart,
          iconStyle: CoreIconStyle(size: CoreIconSize.size32, color: CoreColor.token(token)),
        ),
      ),
  ]),
  'icon/slots': () => docsFlutterDemoRow([
    Button(onPressed: () {}, leading: const Icon(LucideIcons.download), child: const Text('내려받기')),
    Button(
      variant: CoreButtonVariant.outline,
      onPressed: () {},
      trailing: const Icon(LucideIcons.arrowRight),
      child: const Text('다음'),
    ),
    Button(
      variant: CoreButtonVariant.outline,
      shape: CoreButtonShape.square,
      onPressed: () {},
      child: Semantics(label: '검색', child: const Icon(LucideIcons.search)),
    ),
    const Badge(tone: CoreBadgeTone.primary, leading: Icon(LucideIcons.star), child: Text('추천')),
  ]),
  'icon/do-inherit': () => docsFlutterDemoRow([
    Button(onPressed: () {}, leading: const Icon(LucideIcons.star), child: const Text('즐겨찾기')),
    Button(
      variant: CoreButtonVariant.destructive,
      onPressed: () {},
      leading: const Icon(LucideIcons.x),
      child: const Text('삭제'),
    ),
  ]),
  'icon/dont-color': () => Button(
    onPressed: () {},
    leading: const Icon(
      LucideIcons.star,
      iconStyle: CoreIconStyle(color: CoreColor.token(CoreColors.onSurface)),
    ),
    child: const Text('즐겨찾기'),
  ),
  'icon/do-size': () => Button(
    variant: CoreButtonVariant.outline,
    size: CoreComponentSize.sm,
    onPressed: () {},
    leading: const Icon(LucideIcons.plus),
    child: const Text('추가'),
  ),
  'icon/dont-size': () => Button(
    variant: CoreButtonVariant.outline,
    size: CoreComponentSize.sm,
    onPressed: () {},
    leading: const Icon(LucideIcons.plus, iconStyle: CoreIconStyle(size: CoreIconSize.size28)),
    child: const Text('추가'),
  ),
  'icon/theme-order': () => Text(iconThemeOrder.join(' → ')),
  'icon/a11y-name': () => Semantics(
    label: '주의',
    child: const Icon(LucideIcons.triangleAlert, iconStyle: CoreIconStyle(size: CoreIconSize.size32)),
  ),
  'icon/related-button': () => Button(
    onPressed: () {},
    leading: const Icon(LucideIcons.download),
    child: const Text('내려받기'),
  ),
  'icon/related-badge': () => const Badge(
    tone: CoreBadgeTone.info,
    leading: Icon(LucideIcons.info),
    child: Text('안내'),
  ),
  'icon/related-fab': () => Fab(trigger: const Icon(LucideIcons.plus), onPressed: () {}),
};

Widget _icon(Map<String, String> props, String? label) => Icon(
  iconPreviewGlyph(props),
  iconStyle: CoreIconStyle(size: iconPreviewSize(props), color: iconPreviewColor(props)),
);

/// 아래에 이름을 단 장면 조각.
Widget _captioned(String caption, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space8,
  children: [child, Text(caption).labelSmall.onSurfaceVariant],
);
