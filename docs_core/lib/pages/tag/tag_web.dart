/// Tag 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="tag/...">` 가 읽는다. 같은 이름의 Flutter 파일(`tag_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'tag_page.dart'
    show
        tagColorWords,
        tagConsistentSamples,
        tagMixedSamples,
        tagPillStyle,
        tagRowSamples,
        tagRowTitle,
        tagSampleText,
        tagStatusBadgeSamples,
        tagStatusMisuseSamples,
        tagWrapSamples;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _tag;

/// 장면 이름(`tag/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'tag/anatomy': () => const Tag(color: CoreCategoryColor.blue, child: Text(tagSampleText)),
  'tag/palette': _palette,
  // 줄 정렬을 Flutter `Wrap` 과 같게(앞쪽 정렬) 두려고 가운데 맞추는
  // `docsWebDemoRow` 를 쓰지 않는다.
  'tag/wrap': () => div(
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-wrap': 'wrap',
        'gap': spaceCss(CoreSpace.space8),
        'max-width': pinnedLengthCss(CoreSpace.space240),
      },
    ),
    [for (final (color, text) in tagWrapSamples) Tag(color: color, child: Text(text))],
  ),
  'tag/in-row': () => docsWebDemoRow([
    Text(tagRowTitle).titleSmall.onSurface,
    for (final (color, text) in tagRowSamples) Tag(color: color, size: CoreTagSize.sm, child: Text(text)),
  ]),
  'tag/do-same-color': () => docsWebDemoRow([
    for (final (color, text) in tagConsistentSamples) Tag(color: color, child: Text(text)),
  ]),
  'tag/dont-mixed-color': () => docsWebDemoRow([
    for (final (color, text) in tagMixedSamples) Tag(color: color, child: Text(text)),
  ]),
  'tag/do-status-badge': () => docsWebDemoRow([
    for (final (tone, text) in tagStatusBadgeSamples) Badge(tone: tone, showDot: true, child: Text(text)),
  ]),
  'tag/dont-status-tag': () => docsWebDemoRow([
    for (final (color, text) in tagStatusMisuseSamples) Tag(color: color, child: Text(text)),
  ]),
  'tag/related-badge': () => docsWebDemoRow([
    Badge(tone: CoreBadgeTone.info, showDot: true, child: const Text('검토 중')),
    Badge(
      tone: CoreBadgeTone.info,
      variant: CoreBadgeVariant.filled,
      form: CoreBadgeForm.count,
      child: const Text('12'),
    ),
  ]),
  'tag/related-chip': () => docsWebDemoRow([
    Chip(label: '디자인', selected: true, onTap: () {}),
    Chip(label: '개발', onRemove: () {}),
  ]),
};

Component _tag(Map<String, String> props, String? label) => Tag(
  color: previewEnum(CoreCategoryColor.values, props['color'], CoreTagContract.defaultColor),
  emphasis: previewEnum(CoreTagEmphasis.values, props['emphasis'], CoreTagEmphasis.defaultEmphasis),
  size: previewEnum(CoreTagSize.values, props['size'], CoreTagSize.defaultSize),
  tagStyle: previewFlag(props, 'pill') ? tagPillStyle : null,
  child: Text(label ?? tagSampleText),
);

/// 분류색 × 세기 — 세기마다 한 줄.
Component _palette() => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'center',
      'gap': spaceCss(CoreSpace.space12),
    },
  ),
  [
    for (final emphasis in CoreTagEmphasis.values)
      docsWebDemoRow([
        for (final color in CoreCategoryColor.values)
          Tag(color: color, emphasis: emphasis, child: Text(tagColorWords[color]!)),
      ]),
  ],
);
