/// Loading 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · `<SizeSpec>` · 플레이그라운드가,
/// 장면은 `<Preview demo="loading/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`loading_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'loading_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _loading;

/// 장면 이름(`loading/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'loading/size-variants': _sizeVariants,
  'loading/pixel-size': () => _flex([
    _captioned(
      loadingDemoDefaultStrokeCaption,
      const Loading(loadingStyle: CoreLoadingStyle(size: CoreSize.size64)),
    ),
    const Gap.space32(),
    _captioned(
      loadingDemoThickStrokeCaption,
      const Loading(
        loadingStyle: CoreLoadingStyle(size: CoreSize.size64, strokeWidth: CoreStrokeWidth.stroke6),
      ),
    ),
  ]),
  'loading/do-caption': () =>
      _still(_captioned(loadingDemoCaption, const Loading(componentSize: CoreComponentSize.lg))),
  'loading/dont-many': () => _still(
    _flex(vertical: true, start: true, [
      for (final (index, name) in loadingDemoRows.indexed) ...[
        if (index > 0) const Gap.space12(),
        _flex([const Loading(), const Gap.space8(), Text(name).bodySmall.onSurface]),
      ],
    ]),
  ),
  'loading/do-button': () => _still(
    const Button(
      leading: Loading(tone: CoreLoadingTone.neutral),
      child: Text(loadingDemoBusyLabel),
    ),
  ),
  'loading/dont-button-inverse': () => _still(
    const Button(
      leading: Loading(tone: CoreLoadingTone.inverse),
      child: Text(loadingDemoBusyLabel),
    ),
  ),
  'loading/wide-bar': () => const Loading(
    variant: CoreLoadingVariant.bar,
    loadingStyle: CoreLoadingStyle(size: CoreSize.size128, barHeight: CoreStrokeWidth.stroke4),
  ),
  'loading/related-loading-region': () => _still(
    const LoadingRegion(
      semanticLabel: loadingDemoRegionLabel,
      child: SizedBox(width: CoreSpace.space160, child: Skeleton.text()),
    ),
  ),
  'loading/related-skeleton': () => _still(
    _flex(const [
      Skeleton.circle(size: CoreSize.size40),
      Gap.space12(),
      SizedBox(width: CoreSpace.space120, child: Skeleton.text()),
    ]),
  ),
  'loading/related-progress': () => const SizedBox(width: CoreSpace.space160, child: Progress(value: 0.6)),
  'loading/related-empty-state': () => const EmptyState.compact(
    icon: Icon(LucideIcons.inbox),
    title: Text(loadingDemoEmptyTitle),
  ),
};

Widget _loading(Map<String, String> props, String? label) {
  final tone = previewEnum(CoreLoadingTone.values, props['tone'], CoreLoadingTone.defaultTone);
  final indicator = Loading(
    variant: previewEnum(CoreLoadingVariant.values, props['variant'], CoreLoadingVariant.spinner),
    tone: tone,
    componentSize: loadingPreviewSize(props),
    loadingStyle: loadingPreviewStyle(props),
  );
  return tone == CoreLoadingTone.inverse ? _onPrimary(indicator) : indicator;
}

/// `inverse` 톤은 흰 무대에서 보이지 않는다 — primary 로 채운 면 위에 올린다.
Widget _onPrimary(Widget child) => Builder(
  builder: (context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.resolve(const CoreColor.token(CoreColors.primary)).toValue(),
      borderRadius: const BorderRadius.all(Radius.circular(CoreRadius.radius8)),
    ),
    child: Padding(padding: const EdgeInsets.all(CoreSpace.space8), child: child),
  ),
);

/// 크기 장면이 그리는 변형 — `spinner` 는 크기 블록이 그린다.
final List<CoreLoadingVariant> _sizeSceneVariants = [
  for (final variant in CoreLoadingVariant.values)
    if (variant != CoreLoadingVariant.spinner) variant,
];

/// `spinner` 를 뺀 변형을 모든 크기 단계로 — 변형마다 한 줄.
Widget _sizeVariants() => _flex(vertical: true, [
  for (final (index, variant) in _sizeSceneVariants.indexed) ...[
    if (index > 0) const Gap.space24(),
    Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: CoreSpace.space8,
      runSpacing: CoreSpace.space8,
      children: [
        SizedBox(width: CoreSpace.space48, child: Text(variant.name).labelSmall.onSurfaceVariant),
        for (final size in CoreLoadingStyle.defaultsBySize.keys) Loading(variant: variant, componentSize: size),
      ],
    ),
  ],
]);

/// 표시 아래에 설명을 단 장면 조각.
Widget _captioned(String caption, Widget child) =>
    _flex(vertical: true, [child, const Gap.space8(), Text(caption).bodySmall.onSurfaceVariant]);

/// 내용만큼만 차지하는 `Flex` — [Gap] 이 방향을 읽는다.
Widget _flex(List<Widget> children, {bool vertical = false, bool start = false}) => Flex(
  direction: vertical ? Axis.vertical : Axis.horizontal,
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: start ? CrossAxisAlignment.start : CrossAxisAlignment.center,
  children: children,
);

/// 카드의 스피너 · 스켈레톤을 멈춘 그림. 계속 도는 애니메이션이 있으면 네이티브
/// 앱의 카드 검사(`pumpAndSettle`)가 끝나지 않는다.
Widget _still(Widget child) => TickerMode(enabled: false, child: child);
