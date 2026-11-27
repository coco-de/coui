/// Indicator 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="indicator/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`indicator_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'indicator_page.dart'
    show
        indicatorCorners,
        indicatorOffsetSamples,
        indicatorOffsetSteps,
        indicatorRingSteps,
        indicatorSampleButtonText,
        indicatorSampleInitials,
        indicatorSampleText;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _indicator;

/// 장면 이름(`indicator/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'indicator/anatomy': () => const Indicator(
    item: Badge(
      tone: CoreBadgeTone.destructive,
      variant: CoreBadgeVariant.filled,
      form: CoreBadgeForm.count,
      size: CoreComponentSize.lg,
      child: Text('3'),
    ),
    child: Avatar(initials: indicatorSampleInitials, size: CoreComponentSize.xl2),
  ),
  'indicator/ring': () => docsFlutterDemoRow([
    for (final MapEntry(key: name, value: width) in indicatorRingSteps.entries)
      Indicator(
        indicatorStyle: CoreIndicatorStyle(ringWidth: width),
        item: _countBadge('3'),
        child: Button(onPressed: () {}, child: Text('ringWidth $name')),
      ),
  ]),
  'indicator/positions': () => docsFlutterDemoRow([
    for (final (horizontal, vertical) in indicatorCorners)
      Indicator(
        horizontalPosition: horizontal,
        verticalPosition: vertical,
        item: const Status(color: CoreStatusColor.success, size: CoreStatusSize.lg),
        child: Button(
          variant: CoreButtonVariant.secondary,
          onPressed: () {},
          child: Text('${horizontal.name} · ${vertical.name}'),
        ),
      ),
  ]),
  // 값은 버튼 아래에 적는다 — 버튼 안에 적으면 안쪽으로 들어온 배지가 가린다.
  'indicator/offset': () => docsFlutterDemoRow([
    for (final name in indicatorOffsetSamples)
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpace.space12,
        children: [
          Indicator(
            indicatorStyle: CoreIndicatorStyle(offset: indicatorOffsetSteps[name]),
            item: _countBadge('3'),
            child: Button(variant: CoreButtonVariant.secondary, onPressed: () {}, child: const Text('알림함')),
          ),
          Text('offset $name').labelSmall.onSurfaceVariant,
        ],
      ),
  ]),
  'indicator/do-count': () => Indicator(
    item: _countBadge('3'),
    child: Button(
      variant: CoreButtonVariant.outline,
      leading: const Icon(LucideIcons.bell),
      onPressed: () {},
      child: const Text('알림'),
    ),
  ),
  'indicator/dont-long': () => const Indicator(
    item: Badge(
      tone: CoreBadgeTone.info,
      variant: CoreBadgeVariant.filled,
      size: CoreComponentSize.xs,
      child: Text('새로운 알림이 도착했어요'),
    ),
    child: Avatar(initials: indicatorSampleInitials, size: CoreComponentSize.xl),
  ),
  'indicator/do-dots': () => const DotIndicator(index: 1, length: 5),
  // 빈 child 마다 점 하나를 얹어 점 목록처럼 늘어놓은 잘못된 쓰임. 빈 child 에
  // 크기를 주어야 점끼리 겹치지 않는다.
  'indicator/dont-list': () => docsFlutterDemoRow([
    for (var i = 0; i < 5; i++)
      const Indicator(
        item: Status(),
        child: SizedBox.square(dimension: CoreSpace.space8),
      ),
  ]),
  'indicator/related-badge': () => const Badge(
    tone: CoreBadgeTone.destructive,
    variant: CoreBadgeVariant.filled,
    form: CoreBadgeForm.count,
    child: Text('12'),
  ),
  'indicator/related-avatar': () => const Avatar(initials: indicatorSampleInitials, badge: AvatarBadge()),
  'indicator/related-status': () => const Status(color: CoreStatusColor.success, label: Text('온라인')),
  'indicator/related-dot-indicator': () => const DotIndicator(index: 0, length: 4),
};

Widget _indicator(Map<String, String> props, String? label) {
  final item = props['item'] ?? 'count';
  return Indicator(
    horizontalPosition: previewEnum(
      CoreIndicatorHorizontalPosition.values,
      props['horizontalPosition'],
      CoreIndicatorHorizontalPosition.end,
    ),
    verticalPosition: previewEnum(
      CoreIndicatorVerticalPosition.values,
      props['verticalPosition'],
      CoreIndicatorVerticalPosition.top,
    ),
    indicatorStyle: CoreIndicatorStyle(
      offset: indicatorOffsetSteps[props['offset']],
      ringWidth: indicatorRingSteps[props['ringWidth']],
    ),
    item: _item(item, indicatorSampleText(item, label)),
    child: _child(props['child']),
  );
}

Widget _item(String item, String text) => switch (item) {
  'dot' => const Status(color: CoreStatusColor.success, size: CoreStatusSize.lg),
  'label' => Badge(
    tone: CoreBadgeTone.info,
    variant: CoreBadgeVariant.filled,
    size: CoreComponentSize.xs,
    child: Text(text),
  ),
  _ => _countBadge(text),
};

Widget _countBadge(String text) => Badge(
  tone: CoreBadgeTone.destructive,
  variant: CoreBadgeVariant.filled,
  form: CoreBadgeForm.count,
  size: CoreComponentSize.xs,
  child: Text(text),
);

Widget _child(String? child) => switch (child) {
  'avatar' => const Avatar(initials: indicatorSampleInitials, size: CoreComponentSize.xl),
  _ => Button(onPressed: () {}, child: const Text(indicatorSampleButtonText)),
};
