/// Chip 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<VariantRow>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="chip/...">` · `<Anatomy>` · `<Card demo>` 가 읽는다. 같은
/// 이름의 Flutter 파일(`chip_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이
/// 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'chip_page.dart'
    show
        chipCastSamples,
        chipFilterSamples,
        chipLongLabel,
        chipSampleLabel,
        chipSampleSeed,
        chipSampleTags,
        chipThemeOrder;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _chip;

/// 장면 이름(`chip/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 표시 전용 칩으로 그린다. 누를 수 있는 칩은 안에 범위 지정
  // `<style>` 을 두고 바깥에 누름을 받는 상자가 하나 더 생긴다.
  'chip/anatomy': () => Chip(
    size: CoreChipSize.lg,
    leading: Icon(LucideIcons.star),
    prefixLabel: '상태',
    label: chipSampleLabel,
    trailing: Icon(LucideIcons.chevronDown),
    onRemove: () {},
  ),
  'chip/truncation': () => docsWebDemoRow([
    Chip(label: chipLongLabel, maxLength: 7),
    div(styles: Styles(raw: {'max-width': '10rem'}), [Chip(label: chipLongLabel)]),
    div(styles: Styles(raw: {'max-width': '10rem'}), [Chip(label: chipLongLabel, labelMaxLines: 2)]),
  ]),
  'chip/variants': () => docsWebDemoRow([
    Chip(label: 'outlined 꺼짐'),
    Chip(label: 'outlined 켜짐', selected: true),
    Chip(label: 'filled 꺼짐', variant: CoreChipVariant.filled),
    Chip(label: 'filled 켜짐', variant: CoreChipVariant.filled, selected: true),
  ]),
  'chip/grey-surface': () => Card(
    variant: CoreCardVariant.filled,
    body: docsWebDemoRow([
      Chip(label: 'outlined'),
      Chip(label: 'filled', variant: CoreChipVariant.filled),
    ]),
  ),
  'chip/colors': () => docsWebDemoRow([
    Chip(label: 'neutral', selected: true),
    Chip(label: 'primary', chipColor: CoreChipColor.primary, selected: true),
    Chip(label: 'custom', chipColor: CoreChipColor.custom, seedColor: chipSampleSeed, selected: true),
    Chip(label: 'custom 꺼짐', chipColor: CoreChipColor.custom, seedColor: chipSampleSeed),
  ]),
  'chip/emphasis': () => docsWebDemoRow([
    Chip(label: '꺼짐 · low', emphasis: CoreChipEmphasis.low),
    Chip(label: '꺼짐 · high'),
    Chip(label: '켜짐 · low', emphasis: CoreChipEmphasis.low, selected: true),
    Chip(label: '켜짐 · high', selected: true),
  ]),
  'chip/sizes': () => docsWebDemoRow([
    for (final size in CoreChipSize.values)
      Chip(size: size, label: size.name, leading: Icon(LucideIcons.star), onRemove: () {}),
  ]),
  'chip/prefix': () => docsWebDemoRow([
    for (final (key, value, applied) in chipFilterSamples)
      Chip(
        variant: CoreChipVariant.filled,
        prefixLabel: key,
        label: value,
        trailing: Icon(LucideIcons.chevronDown),
        selected: applied,
        onTap: () {},
      ),
  ]),
  'chip/states': () => docsWebDemoRow([
    Chip(label: '기본', onTap: () {}),
    Chip(label: '선택', selected: true, onTap: () {}),
    Chip(label: '비활성', enabled: false, onTap: () {}),
    Chip(label: '비활성 · 선택', selected: true, enabled: false, onTap: () {}),
    Chip(label: '비활성 · onRemove', enabled: false, onRemove: () {}),
  ]),
  'chip/cast-motion': () => docsWebDemoRow([
    for (final (motion, name) in chipCastSamples)
      Chip(
        label: name,
        chipStyle: CoreChipStyle(castMotion: motion),
        onTap: () {},
      ),
  ]),
  'chip/do-short': () => docsWebDemoRow([
    for (final (index, tag) in chipSampleTags.indexed) Chip(label: tag, selected: index == 0, onTap: () {}),
  ]),
  'chip/dont-long': () => div(styles: Styles(raw: {'max-width': '9rem'}), [
    Chip(label: '내가 최근에 방문한 카테고리만 보기', onTap: () {}),
  ]),
  'chip/do-chip-color': () => docsWebDemoRow([
    Chip(label: '꺼짐', chipColor: CoreChipColor.primary, onTap: () {}),
    Chip(label: '켜짐', chipColor: CoreChipColor.primary, selected: true, onTap: () {}),
  ]),
  'chip/dont-background': () => docsWebDemoRow([
    for (final (name, selected) in const [('꺼짐', false), ('켜짐', true)])
      Chip(
        label: name,
        selected: selected,
        chipStyle: const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
        onTap: () {},
      ),
  ]),
  'chip/group': () => docsWebDemoRow([
    for (final tag in chipSampleTags) Chip(label: tag, onRemove: () {}),
  ]),
  'chip/borderless': () => docsWebDemoRow([
    Chip(label: '베타'),
    Chip(
      label: '베타',
      chipStyle: const CoreChipStyle(
        borderWidth: CoreStrokeWidth.stroke0,
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      ),
    ),
    Chip(label: '추천', variant: CoreChipVariant.filled),
  ]),
  'chip/theme-order': () => div(classes: 'docs-demo-order', [
    const Text('적용 순서 · 뒤로 갈수록 우선합니다').labelMedium.onSurfaceVariant,
    ol([
      for (final (index, step) in chipThemeOrder.indexed)
        li(classes: index == chipThemeOrder.length - 1 ? 'is-strong' : null, [
          span([Component.text('${index + 1}')]),
          Component.text(step),
        ]),
    ]),
  ]),
  'chip/related-chip-input': () => div(styles: Styles(raw: {'width': '15rem'}), [
    ChipInput(chips: const ['디자인', '개발'], placeholder: '태그 추가', onChanged: (_) {}),
  ]),
  'chip/related-chip-group': () => ChipGroup<String>(
    items: chipSampleTags,
    initialValue: const {'디자인'},
    chipBuilder: (item, {required selected, required enabled, required onTap}) =>
        Chip(label: item, selected: selected, enabled: enabled, onTap: onTap),
  ),
  'chip/related-badge': () => docsWebDemoRow([
    Badge(tone: CoreBadgeTone.info, showDot: true, child: const Text('검토 중')),
    Badge(tone: CoreBadgeTone.success, showDot: true, child: const Text('승인됨')),
  ]),
  'chip/related-button': () => Button(onPressed: () {}, child: const Text('필터 적용')),
};

/// `pair` 면 같은 속성의 꺼진 칩과 켜진 칩을 나란히 그린다.
Component _chip(Map<String, String> props, String? label) {
  if (previewFlag(props, 'pair')) {
    return docsWebDemoRow([
      _oneChip(props, label, selected: false),
      _oneChip(props, label, selected: true),
    ]);
  }
  return _oneChip(props, label, selected: previewFlag(props, 'selected'));
}

Component _oneChip(Map<String, String> props, String? label, {required bool selected}) {
  final chipColor = previewEnum(CoreChipColor.values, props['chipColor'], CoreChipColor.defaultColor);
  return Chip(
    prefixLabel: props['prefixLabel'],
    label: label ?? chipSampleLabel,
    variant: previewEnum(CoreChipVariant.values, props['variant'], CoreChipVariant.defaultVariant),
    emphasis: previewEnum(CoreChipEmphasis.values, props['emphasis'], CoreChipEmphasis.defaultEmphasis),
    shape: previewEnum(CoreChipShape.values, props['shape'], CoreChipShape.defaultShape),
    size: previewEnum(CoreChipSize.values, props['size'], CoreChipSize.defaultSize),
    chipColor: chipColor,
    seedColor: chipColor == CoreChipColor.custom ? chipSampleSeed : null,
    leading: docsWebIcon(props['leading']),
    trailing: docsWebIcon(props['trailing']),
    selected: selected,
    enabled: previewFlag(props, 'enabled', fallback: true),
    onTap: () {},
    onRemove: previewFlag(props, 'removable') ? () {} : null,
  );
}
