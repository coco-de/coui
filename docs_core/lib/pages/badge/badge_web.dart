/// Badge 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="badge/...">` 가 읽는다. 같은 이름의 Flutter 파일(`badge_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'badge_page.dart' show badgeSampleText, badgeStatusSamples, badgeThemeOrder, badgeToneWords;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _badge;

/// 장면 이름(`badge/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 표시 전용 배지로 그린다. 누를 수 있는 배지는 루트 안에 범위 지정
  // `<style>` 을 두는데, 구조 표시가 그 글을 라벨로 잘못 고른다.
  'badge/anatomy': () => Badge(
    tone: CoreBadgeTone.primary,
    size: CoreComponentSize.xl,
    showDot: true,
    leading: Icon(LucideIcons.star),
    trailing: Icon(LucideIcons.arrowRight),
    child: const Text('추천'),
  ),
  'badge/tone-strength': _toneStrength,
  'badge/status-dot': () => docsWebDemoRow([
    for (final (tone, text) in badgeStatusSamples) Badge(tone: tone, showDot: true, child: Text(text)),
  ]),
  'badge/states': _badgeStates,
  'badge/long-label': () => docsWebDemoRow([
    div(styles: Styles(raw: {'width': '9rem'}), [
      Badge(tone: CoreBadgeTone.info, showDot: true, child: const Text('검토를 기다리는 문서 세 건')),
    ]),
    div(styles: Styles(raw: {'width': '3rem'}), [
      Badge(
        tone: CoreBadgeTone.primary,
        variant: CoreBadgeVariant.filled,
        form: CoreBadgeForm.count,
        child: const Text('128000'),
      ),
    ]),
  ]),
  'badge/do-tone': () => docsWebDemoRow([
    Badge(tone: CoreBadgeTone.success, showDot: true, child: const Text('완료')),
    Badge(tone: CoreBadgeTone.destructive, showDot: true, child: const Text('오류')),
    Badge(tone: CoreBadgeTone.warning, showDot: true, child: const Text('대기')),
  ]),
  'badge/dont-style-color': () => Badge(
    showDot: true,
    badgeStyle: const CoreBadgeStyle(backgroundColor: CoreColor.token(CoreColors.errorContainer)),
    child: const Text('오류'),
  ),
  'badge/do-short': () => docsWebDemoRow([
    Badge(child: const Text('신규')),
    Badge(
      tone: CoreBadgeTone.info,
      variant: CoreBadgeVariant.filled,
      form: CoreBadgeForm.count,
      child: const Text('12'),
    ),
  ]),
  'badge/dont-long': () => div(styles: Styles(raw: {'width': '7rem'}), [
    Badge(child: const Text('새로 추가된 기능입니다')),
  ]),
  // 선이 있는 기본 `outlined` 옆에 선이 없는 `tonal` 을 면 · 모서리만 바꿔
  // 놓는다. `outlined` 에 `borderWidth: 0` 을 주는 길은 Flutter 가 헤어라인을
  // 남겨 두 플랫폼이 갈린다.
  'badge/borderless': () => docsWebDemoRow([
    Badge(variant: CoreBadgeVariant.outlined, child: const Text('베타')),
    Badge(
      badgeStyle: const CoreBadgeStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      ),
      child: const Text('베타'),
    ),
  ]),
  'badge/theme-order': () => div(classes: 'docs-demo-order', [
    const Text('적용 순서 · 뒤로 갈수록 우선합니다').labelMedium.onSurfaceVariant,
    ol([
      for (final (index, step) in badgeThemeOrder.indexed)
        li(classes: index == badgeThemeOrder.length - 1 ? 'is-strong' : null, [
          span([Component.text('${index + 1}')]),
          Component.text(step),
        ]),
    ]),
  ]),
  'badge/a11y-name': () => div(classes: 'docs-demo-caption', [
    Badge(
      tone: CoreBadgeTone.destructive,
      form: CoreBadgeForm.dot,
      size: CoreComponentSize.lg,
      attributes: const {'role': 'img', 'aria-label': '새 알림'},
    ),
    div([
      code([Component.text('role="img" aria-label="새 알림"')]),
      const Text('점만 있는 배지에는 이름이 없습니다. 웹에서는 attributes 로 이름을 붙입니다.').bodySmall.onSurfaceVariant,
    ]),
  ]),
  'badge/related-chip': () => Chip(label: '디자인', onRemove: () {}),
  'badge/related-avatar': () => Avatar(
    initials: 'KS',
    badge: Badge(tone: CoreBadgeTone.success, form: CoreBadgeForm.dot),
  ),
  'badge/related-indicator': () => Indicator(
    item: Badge(
      tone: CoreBadgeTone.destructive,
      variant: CoreBadgeVariant.filled,
      form: CoreBadgeForm.count,
      size: CoreComponentSize.xs,
      child: const Text('3'),
    ),
    child: Icon(LucideIcons.bell),
  ),
  'badge/related-icon': () => docsWebDemoRow([
    Icon(LucideIcons.star),
    Badge(tone: CoreBadgeTone.primary, leading: Icon(LucideIcons.star), child: const Text('추천')),
  ]),
};

Component _badge(Map<String, String> props, String? label) {
  final form = previewEnum(CoreBadgeForm.values, props['form'], CoreBadgeForm.defaultForm);
  return Badge(
    tone: previewEnum(CoreBadgeTone.values, props['tone'], CoreBadgeTone.defaultTone),
    variant: previewEnum(CoreBadgeVariant.values, props['variant'], CoreBadgeVariant.defaultVariant),
    form: form,
    size: previewEnum(CoreComponentSize.values, props['size'], CoreBadgeContract.defaultSize),
    showDot: previewFlag(props, 'showDot'),
    leading: docsWebIcon(props['leading']),
    trailing: docsWebIcon(props['trailing']),
    onPressed: previewFlag(props, 'pressable') ? () {} : null,
    child: form == CoreBadgeForm.dot ? null : Text(badgeSampleText(form, label)),
  );
}

/// 톤 × 세기 표 — 세기마다 한 줄, 마지막 줄은 점(dot). 점은 세기와 무관하게
/// 톤의 점 색 하나로 칠하므로 한 줄이면 된다.
Component _toneStrength() => div(
  styles: Styles(
    raw: {
      'display': 'grid',
      'grid-template-columns': 'auto repeat(${CoreBadgeTone.values.length}, max-content)',
      'align-items': 'center',
      'justify-items': 'center',
      'gap': 'var(--coui-space-12)',
    },
  ),
  [
    for (final variant in CoreBadgeVariant.values) ...[
      code([Component.text(variant.name)]),
      for (final tone in CoreBadgeTone.values) Badge(tone: tone, variant: variant, child: Text(badgeToneWords[tone]!)),
    ],
    code([Component.text('dot')]),
    for (final tone in CoreBadgeTone.values) Badge(tone: tone, form: CoreBadgeForm.dot),
  ],
);

/// 상태 격자의 열 이름.
const List<String> _stateColumns = ['기본', 'Hover', 'Pressed', 'Focus', '표시 전용'];

/// 상태 격자 — 기본 · Focus 는 실제로 누를 수 있는 배지(기본 칸은 마우스를
/// 올리면 실제 hover · pressed 를 그린다), hover · pressed 는 배지가 그 상태에
/// 칠하는 채움을 같은 계산(`stateLayerWashCss` · `defaultStateLayer` · 톤의 쉬는
/// 색)으로 고정한 배지, focus 는 문서 시트가 링을 그린다(브라우저는 포인터
/// 없이 hover 를 켤 수 없다). 표시 전용 배지는 어떤 상태도 칠하지 않는다.
Component _badgeStates() {
  const tone = CoreBadgeTone.primary;
  final layer = CoreBadgeStyle.defaultStateLayer;
  Component cell(CoreBadgeVariant variant, String state) {
    final rest = CoreBadgeStyle.defaultsByTone[tone]!.restingStyleFor(variant, CoreBadgeForm.label);
    String wash(double weight) =>
        stateLayerWashCss(ink: rest.foregroundColor!, base: rest.backgroundColor!, weight: weight);
    final washed = switch (state) {
      'Hover' => wash(layer.hover),
      'Pressed' => wash(layer.pressed),
      _ => null,
    };
    final badge = Badge(
      tone: tone,
      variant: variant,
      onPressed: state == '기본' || state == 'Focus' ? () {} : null,
      css: washed == null ? null : Styles(raw: {'background-color': washed}),
      child: const Text('필터'),
    );
    return state == 'Focus' ? span(classes: 'docs-demo-focus', [badge]) : badge;
  }

  return div(classes: 'docs-demo-states', [
    span([const Text('variant').labelSmall.onSurfaceVariant]),
    for (final column in _stateColumns) span([Text(column).labelSmall.onSurfaceVariant]),
    for (final variant in CoreBadgeVariant.values) ...[
      code([Component.text(variant.name)]),
      for (final column in _stateColumns) cell(variant, column),
    ],
  ]);
}
