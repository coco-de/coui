/// Badge 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="badge/...">` 가 읽는다. 같은 이름의 Web 파일(`badge_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'badge_page.dart' show badgeSampleText, badgeStatusSamples, badgeThemeOrder, badgeToneWords;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _badge;

/// 장면 이름(`badge/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'badge/anatomy': () => const Badge(
    tone: CoreBadgeTone.primary,
    size: CoreComponentSize.xl,
    showDot: true,
    leading: Icon(LucideIcons.star),
    trailing: Icon(LucideIcons.arrowRight),
    child: Text('추천'),
  ),
  'badge/tone-strength': _toneStrength,
  'badge/status-dot': () => docsFlutterDemoRow([
    for (final (tone, text) in badgeStatusSamples) Badge(tone: tone, showDot: true, child: Text(text)),
  ]),
  'badge/states': _badgeStates,
  'badge/long-label': () => docsFlutterDemoRow([
    ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 144),
      child: const Badge(tone: CoreBadgeTone.info, showDot: true, child: Text('검토를 기다리는 문서 세 건')),
    ),
    const SizedBox(
      width: 48,
      child: Badge(
        tone: CoreBadgeTone.primary,
        variant: CoreBadgeVariant.filled,
        form: CoreBadgeForm.count,
        child: Text('128000'),
      ),
    ),
  ]),
  'badge/do-tone': () => docsFlutterDemoRow(const [
    Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('완료')),
    Badge(tone: CoreBadgeTone.destructive, showDot: true, child: Text('오류')),
    Badge(tone: CoreBadgeTone.warning, showDot: true, child: Text('대기')),
  ]),
  'badge/dont-style-color': () => const Badge(
    showDot: true,
    badgeStyle: CoreBadgeStyle(backgroundColor: CoreColor.token(CoreColors.errorContainer)),
    child: Text('오류'),
  ),
  'badge/do-short': () => docsFlutterDemoRow(const [
    Badge(child: Text('신규')),
    Badge(
      tone: CoreBadgeTone.info,
      variant: CoreBadgeVariant.filled,
      form: CoreBadgeForm.count,
      child: Text('12'),
    ),
  ]),
  'badge/dont-long': () => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 112),
    child: const Badge(child: Text('새로 추가된 기능입니다')),
  ),
  'badge/borderless': () => docsFlutterDemoRow(const [
    Badge(variant: CoreBadgeVariant.outlined, child: Text('베타')),
    Badge(
      badgeStyle: CoreBadgeStyle(
        borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
      ),
      child: Text('베타'),
    ),
  ]),
  'badge/theme-order': () => Text(badgeThemeOrder.join(' → ')),
  'badge/a11y-name': () => Semantics(
    label: '새 알림',
    child: const Badge(tone: CoreBadgeTone.destructive, form: CoreBadgeForm.dot, size: CoreComponentSize.lg),
  ),
  'badge/related-chip': () => Chip(label: '디자인', onRemove: () {}),
  'badge/related-avatar': () => const Avatar(
    initials: 'KS',
    badge: Badge(tone: CoreBadgeTone.success, form: CoreBadgeForm.dot),
  ),
  'badge/related-indicator': () => const Indicator(
    item: Badge(
      tone: CoreBadgeTone.destructive,
      variant: CoreBadgeVariant.filled,
      form: CoreBadgeForm.count,
      size: CoreComponentSize.xs,
      child: Text('3'),
    ),
    child: Icon(LucideIcons.bell),
  ),
  'badge/related-icon': () => docsFlutterDemoRow(const [
    Icon(LucideIcons.star),
    Badge(tone: CoreBadgeTone.primary, leading: Icon(LucideIcons.star), child: Text('추천')),
  ]),
};

Widget _badge(Map<String, String> props, String? label) {
  final form = previewEnum(CoreBadgeForm.values, props['form'], CoreBadgeForm.defaultForm);
  return Badge(
    tone: previewEnum(CoreBadgeTone.values, props['tone'], CoreBadgeTone.defaultTone),
    variant: previewEnum(CoreBadgeVariant.values, props['variant'], CoreBadgeVariant.defaultVariant),
    form: form,
    size: previewEnum(CoreComponentSize.values, props['size'], CoreBadgeContract.defaultSize),
    showDot: previewFlag(props, 'showDot'),
    leading: docsFlutterIcon(props['leading']),
    trailing: docsFlutterIcon(props['trailing']),
    onPressed: previewFlag(props, 'pressable') ? () {} : null,
    child: form == CoreBadgeForm.dot ? null : Text(badgeSampleText(form, label)),
  );
}

/// 톤 × 세기 표 — 세기마다 한 줄, 마지막 줄은 점(dot).
Widget _toneStrength() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space12,
  children: [
    for (final variant in CoreBadgeVariant.values)
      docsFlutterDemoRow([
        for (final tone in CoreBadgeTone.values)
          Badge(tone: tone, variant: variant, child: Text(badgeToneWords[tone]!)),
      ]),
    docsFlutterDemoRow([for (final tone in CoreBadgeTone.values) Badge(tone: tone, form: CoreBadgeForm.dot)]),
  ],
);

/// 상태 — 세기마다 누를 수 있는 배지와 표시 전용 배지. 누를 수 있는 배지는
/// 마우스를 올리거나 누르면 실제 상태를 그린다.
Widget _badgeStates() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space12,
  children: [
    for (final variant in CoreBadgeVariant.values)
      docsFlutterDemoRow([
        Badge(tone: CoreBadgeTone.primary, variant: variant, onPressed: () {}, child: const Text('필터')),
        Badge(tone: CoreBadgeTone.primary, variant: variant, child: const Text('필터')),
      ]),
  ],
);
