/// Chip 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<VariantRow>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="chip/...">` · `<Anatomy>` · `<Card demo>` 가 읽는다. 같은
/// 이름의 Web 파일(`chip_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야
/// 한다.
///
/// `filled` + `low` 인 칩을 선택할 수 있게(`selected` 또는 `onTap`) 그리는
/// 장면은 두지 않는다 — 디버그 빌드가 그 조합을 오류로 보고한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'chip_page.dart'
    show
        chipCastSamples,
        chipFilterSamples,
        chipLongLabel,
        chipSampleLabel,
        chipSampleSeed,
        chipSampleTags,
        chipThemeOrder;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _chip;

/// 장면 이름(`chip/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'chip/anatomy': () => Chip(
    size: CoreChipSize.lg,
    leading: const Icon(LucideIcons.star),
    prefixLabel: '상태',
    label: chipSampleLabel,
    trailing: const Icon(LucideIcons.chevronDown),
    onRemove: () {},
  ),
  'chip/truncation': () => docsFlutterDemoRow([
    const Chip(label: chipLongLabel, maxLength: 7),
    ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: const Chip(label: chipLongLabel),
    ),
    ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: const Chip(label: chipLongLabel, labelMaxLines: 2),
    ),
  ]),
  'chip/variants': () => docsFlutterDemoRow(const [
    Chip(label: 'outlined 꺼짐'),
    Chip(label: 'outlined 켜짐', selected: true),
    Chip(label: 'filled 꺼짐', variant: CoreChipVariant.filled),
    Chip(label: 'filled 켜짐', variant: CoreChipVariant.filled, selected: true),
  ]),
  'chip/grey-surface': () => Card(
    variant: CoreCardVariant.filled,
    body: docsFlutterDemoRow(const [
      Chip(label: 'outlined'),
      Chip(label: 'filled', variant: CoreChipVariant.filled),
    ]),
  ),
  'chip/colors': () => docsFlutterDemoRow(const [
    Chip(label: 'neutral', selected: true),
    Chip(label: 'primary', chipColor: CoreChipColor.primary, selected: true),
    Chip(label: 'custom', chipColor: CoreChipColor.custom, seedColor: chipSampleSeed, selected: true),
    Chip(label: 'custom 꺼짐', chipColor: CoreChipColor.custom, seedColor: chipSampleSeed),
  ]),
  'chip/emphasis': () => docsFlutterDemoRow(const [
    Chip(label: '꺼짐 · low', emphasis: CoreChipEmphasis.low),
    Chip(label: '꺼짐 · high'),
    Chip(label: '켜짐 · low', emphasis: CoreChipEmphasis.low, selected: true),
    Chip(label: '켜짐 · high', selected: true),
  ]),
  'chip/sizes': () => docsFlutterDemoRow([
    for (final size in CoreChipSize.values)
      Chip(size: size, label: size.name, leading: const Icon(LucideIcons.star), onRemove: () {}),
  ]),
  'chip/prefix': () => docsFlutterDemoRow([
    for (final (key, value, applied) in chipFilterSamples)
      Chip(
        variant: CoreChipVariant.filled,
        prefixLabel: key,
        label: value,
        trailing: const Icon(LucideIcons.chevronDown),
        selected: applied,
        onTap: () {},
      ),
  ]),
  'chip/states': () => docsFlutterDemoRow([
    Chip(label: '기본', onTap: () {}),
    Chip(label: '선택', selected: true, onTap: () {}),
    Chip(label: '비활성', enabled: false, onTap: () {}),
    Chip(label: '비활성 · 선택', selected: true, enabled: false, onTap: () {}),
    Chip(label: '비활성 · onRemove', enabled: false, onRemove: () {}),
  ]),
  'chip/cast-motion': () => docsFlutterDemoRow([
    for (final (motion, name) in chipCastSamples)
      Chip(
        label: name,
        chipStyle: CoreChipStyle(castMotion: motion),
        onTap: () {},
      ),
  ]),
  'chip/do-short': () => docsFlutterDemoRow([
    for (final (index, tag) in chipSampleTags.indexed) Chip(label: tag, selected: index == 0, onTap: () {}),
  ]),
  'chip/dont-long': () => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 144),
    child: Chip(label: '내가 최근에 방문한 카테고리만 보기', onTap: () {}),
  ),
  'chip/do-chip-color': () => docsFlutterDemoRow([
    Chip(label: '꺼짐', chipColor: CoreChipColor.primary, onTap: () {}),
    Chip(label: '켜짐', chipColor: CoreChipColor.primary, selected: true, onTap: () {}),
  ]),
  'chip/dont-background': () => docsFlutterDemoRow([
    for (final (name, selected) in const [('꺼짐', false), ('켜짐', true)])
      Chip(
        label: name,
        selected: selected,
        chipStyle: const CoreChipStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
        onTap: () {},
      ),
  ]),
  'chip/group': () => docsFlutterDemoRow([
    for (final tag in chipSampleTags) Chip(label: tag, onRemove: () {}),
  ]),
  'chip/borderless': () => docsFlutterDemoRow(const [
    Chip(label: '베타'),
    Chip(
      label: '베타',
      chipStyle: CoreChipStyle(
        borderWidth: CoreStrokeWidth.stroke0,
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      ),
    ),
    Chip(label: '추천', variant: CoreChipVariant.filled),
  ]),
  'chip/theme-order': () => Text(chipThemeOrder.join(' → ')),
  'chip/related-chip-input': () => SizedBox(
    width: 240,
    child: ChipInput(chips: const ['디자인', '개발'], placeholder: '태그 추가', onChanged: (_) {}),
  ),
  'chip/related-chip-group': () => ChipGroup<String>(
    items: chipSampleTags,
    initialValue: const {'디자인'},
    chipBuilder: (item, {required selected, required enabled, required onTap}) =>
        Chip(label: item, selected: selected, enabled: enabled, onTap: onTap),
  ),
  'chip/related-badge': () => docsFlutterDemoRow(const [
    Badge(tone: CoreBadgeTone.info, showDot: true, child: Text('검토 중')),
    Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('승인됨')),
  ]),
  'chip/related-button': () => Button(onPressed: () {}, child: const Text('필터 적용')),
};

/// `pair` 면 같은 속성의 꺼진 칩과 켜진 칩을 나란히 그린다.
///
/// 임베드 팬의 높이는 칩 한 줄 몫이라 둘을 두 줄로 넘기지 않고, 팬이 좁으면
/// 한 줄을 통째로 줄인다.
Widget _chip(Map<String, String> props, String? label) {
  if (previewFlag(props, 'pair')) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpace.space8,
        children: [
          _oneChip(props, label, selected: false),
          _oneChip(props, label, selected: true),
        ],
      ),
    );
  }
  return _oneChip(props, label, selected: previewFlag(props, 'selected'));
}

Widget _oneChip(Map<String, String> props, String? label, {required bool selected}) {
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
    leading: docsFlutterIcon(props['leading']),
    trailing: docsFlutterIcon(props['trailing']),
    selected: selected,
    enabled: previewFlag(props, 'enabled', fallback: true),
    onTap: () {},
    onRemove: previewFlag(props, 'removable') ? () {} : null,
  );
}
