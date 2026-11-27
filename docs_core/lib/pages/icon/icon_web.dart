/// Icon 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="icon/...">` 가 읽는다. 같은 이름의 Flutter 파일(`icon_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 장면은 패키지에 번들된 Lucide 아이콘만 쓴다 — 네트워크 없이 그려진다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'icon_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _icon;

/// 장면 이름(`icon/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'icon/sizes': () => div(
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-wrap': 'wrap',
        'align-items': 'flex-end',
        'justify-content': 'center',
        'gap': 'var(--coui-space-20)',
      },
    ),
    [
      for (final size in iconSizeSteps)
        _captioned('${size.toInt()}', Icon(LucideIcons.settings, iconStyle: CoreIconStyle(size: size))),
    ],
  ),
  'icon/colors': () => docsWebDemoRow([
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
  'icon/slots': () => docsWebDemoRow([
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
      attributes: const {'aria-label': '검색'},
      child: const Icon(LucideIcons.search),
    ),
    Badge(tone: CoreBadgeTone.primary, leading: const Icon(LucideIcons.star), child: const Text('추천')),
  ]),
  'icon/do-inherit': () => docsWebDemoRow([
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
  'icon/theme-order': () => div(classes: 'docs-demo-order', [
    const Text('적용 순서 · 뒤로 갈수록 우선합니다').labelMedium.onSurfaceVariant,
    ol([
      for (final (index, step) in iconThemeOrder.indexed)
        li(classes: index == iconThemeOrder.length - 1 ? 'is-strong' : null, [
          span([Component.text('${index + 1}')]),
          Component.text(step),
        ]),
    ]),
  ]),
  'icon/a11y-name': () => div(classes: 'docs-demo-caption', [
    const Icon(
      LucideIcons.triangleAlert,
      iconStyle: CoreIconStyle(size: CoreIconSize.size32),
      attributes: {'role': 'img', 'aria-label': '주의'},
    ),
    div([
      code([Component.text('role="img" aria-label="주의"')]),
      const Text('글 없이 홀로 선 아이콘이 뜻을 담으면 이름을 붙입니다.').bodySmall.onSurfaceVariant,
    ]),
  ]),
  'icon/related-button': () => Button(
    onPressed: () {},
    leading: const Icon(LucideIcons.download),
    child: const Text('내려받기'),
  ),
  'icon/related-badge': () => Badge(
    tone: CoreBadgeTone.info,
    leading: const Icon(LucideIcons.info),
    child: const Text('안내'),
  ),
  'icon/related-fab': () => Fab(trigger: const Icon(LucideIcons.plus), onPressed: () {}),
};

Component _icon(Map<String, String> props, String? label) => Icon(
  iconPreviewGlyph(props),
  iconStyle: CoreIconStyle(size: iconPreviewSize(props), color: iconPreviewColor(props)),
);

/// 아래에 이름을 단 장면 조각.
Component _captioned(String caption, Component child) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': 'var(--coui-space-8)',
    },
  ),
  [child, Text(caption).labelSmall.onSurfaceVariant],
);
