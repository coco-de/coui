/// Loading 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · `<SizeSpec>` · 플레이그라운드가,
/// 장면은 `<Preview demo="loading/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`loading_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import '../page_kit_web.dart';
import 'loading_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _loading;

/// 장면 이름(`loading/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
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
  'loading/do-caption': () => _captioned(loadingDemoCaption, const Loading(componentSize: CoreComponentSize.lg)),
  'loading/dont-many': () => _flex(vertical: true, start: true, [
    for (final (index, name) in loadingDemoRows.indexed) ...[
      if (index > 0) const Gap.space12(),
      _flex([const Loading(), const Gap.space8(), Text(name).bodySmall.onSurface]),
    ],
  ]),
  'loading/do-button': () => Button(
    leading: const Loading(tone: CoreLoadingTone.neutral),
    child: Text(loadingDemoBusyLabel),
  ),
  'loading/dont-button-inverse': () => Button(
    leading: const Loading(tone: CoreLoadingTone.inverse),
    child: Text(loadingDemoBusyLabel),
  ),
  'loading/wide-bar': () => const Loading(
    variant: CoreLoadingVariant.bar,
    loadingStyle: CoreLoadingStyle(size: CoreSize.size128, barHeight: CoreStrokeWidth.stroke4),
  ),
  'loading/related-loading-region': () => LoadingRegion(
    semanticLabel: loadingDemoRegionLabel,
    child: _box(CoreSpace.space160, Skeleton.text()),
  ),
  'loading/related-skeleton': () => _flex([
    Skeleton.circle(size: pinnedLengthCss(CoreSize.size40)),
    const Gap.space12(),
    _box(CoreSpace.space120, Skeleton.text()),
  ]),
  'loading/related-progress': () => _box(CoreSpace.space160, const Progress(value: 0.6)),
  'loading/related-empty-state': () => EmptyState.compact(
    icon: Icon(LucideIcons.inbox),
    title: Text(loadingDemoEmptyTitle),
  ),
};

Component _loading(Map<String, String> props, String? label) {
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
Component _onPrimary(Component child) => div(
  styles: Styles(
    raw: {
      'display': 'inline-flex',
      'padding': pinnedLengthCss(CoreSpace.space8),
      'border-radius': const CoreBorderRadius.all(CoreRadius.radius8).toValue(),
      'background-color': const CoreColor.token(CoreColors.primary).toValue(),
    },
  ),
  [child],
);

/// 크기 장면이 그리는 변형 — `spinner` 는 크기 블록이 그린다.
final List<CoreLoadingVariant> _sizeSceneVariants = [
  for (final variant in CoreLoadingVariant.values)
    if (variant != CoreLoadingVariant.spinner) variant,
];

/// `spinner` 를 뺀 변형을 모든 크기 단계로 — 변형마다 한 줄.
Component _sizeVariants() => _flex(vertical: true, [
  for (final (index, variant) in _sizeSceneVariants.indexed) ...[
    if (index > 0) const Gap.space24(),
    docsWebDemoRow([
      _box(CoreSpace.space48, Text(variant.name).labelSmall.onSurfaceVariant),
      for (final size in CoreLoadingStyle.defaultsBySize.keys) Loading(variant: variant, componentSize: size),
    ]),
  ],
]);

/// 표시 아래에 설명을 단 장면 조각.
Component _captioned(String caption, Component child) =>
    _flex(vertical: true, [child, const Gap.space8(), Text(caption).bodySmall.onSurfaceVariant]);

/// 문서 시트의 간격 없이 [Gap] 만으로 띄우는 flex 상자.
Component _flex(List<Component> children, {bool vertical = false, bool start = false}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': vertical ? 'column' : 'row',
      'align-items': start ? 'flex-start' : 'center',
    },
  ),
  children,
);

/// 폭을 [width](logical px)로 정한 상자.
Component _box(double width, Component child) => div(styles: Styles(raw: {'width': pinnedLengthCss(width)}), [child]);
