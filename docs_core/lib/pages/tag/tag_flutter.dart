/// Tag 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="tag/...">` 가 읽는다. 같은 이름의 Web 파일(`tag_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
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

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _tag;

/// 장면 이름(`tag/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'tag/anatomy': () => const Tag(color: CoreCategoryColor.blue, child: Text(tagSampleText)),
  'tag/palette': _palette,
  'tag/wrap': () => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: CoreSpace.space240),
    child: docsFlutterDemoRow([for (final (color, text) in tagWrapSamples) Tag(color: color, child: Text(text))]),
  ),
  'tag/in-row': () => Wrap(
    spacing: CoreSpace.space8,
    runSpacing: CoreSpace.space8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text(tagRowTitle).titleSmall.onSurface,
      for (final (color, text) in tagRowSamples) Tag(color: color, size: CoreTagSize.sm, child: Text(text)),
    ],
  ),
  'tag/do-same-color': () => docsFlutterDemoRow([
    for (final (color, text) in tagConsistentSamples) Tag(color: color, child: Text(text)),
  ]),
  'tag/dont-mixed-color': () => docsFlutterDemoRow([
    for (final (color, text) in tagMixedSamples) Tag(color: color, child: Text(text)),
  ]),
  'tag/do-status-badge': () => docsFlutterDemoRow([
    for (final (tone, text) in tagStatusBadgeSamples) Badge(tone: tone, showDot: true, child: Text(text)),
  ]),
  'tag/dont-status-tag': () => docsFlutterDemoRow([
    for (final (color, text) in tagStatusMisuseSamples) Tag(color: color, child: Text(text)),
  ]),
  'tag/related-badge': () => docsFlutterDemoRow(const [
    Badge(tone: CoreBadgeTone.info, showDot: true, child: Text('검토 중')),
    Badge(
      tone: CoreBadgeTone.info,
      variant: CoreBadgeVariant.filled,
      form: CoreBadgeForm.count,
      child: Text('12'),
    ),
  ]),
  'tag/related-chip': () => docsFlutterDemoRow([
    Chip(label: '디자인', selected: true, onTap: () {}),
    Chip(label: '개발', onRemove: () {}),
  ]),
};

Widget _tag(Map<String, String> props, String? label) => Tag(
  color: previewEnum(CoreCategoryColor.values, props['color'], CoreTagContract.defaultColor),
  emphasis: previewEnum(CoreTagEmphasis.values, props['emphasis'], CoreTagEmphasis.defaultEmphasis),
  size: previewEnum(CoreTagSize.values, props['size'], CoreTagSize.defaultSize),
  tagStyle: previewFlag(props, 'pill') ? tagPillStyle : null,
  child: Text(label ?? tagSampleText),
);

/// 분류색 × 세기 — 세기마다 한 줄.
Widget _palette() => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space12,
  children: [
    for (final emphasis in CoreTagEmphasis.values)
      docsFlutterDemoRow([
        for (final color in CoreCategoryColor.values)
          Tag(color: color, emphasis: emphasis, child: Text(tagColorWords[color]!)),
      ]),
  ],
);
