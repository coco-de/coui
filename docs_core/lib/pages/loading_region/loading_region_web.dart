/// LoadingRegion 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="loading-region/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`loading_region_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// LoadingRegion 은 아무것도 그리지 않으므로, 알리는 문구는 문서의 글로 적고
/// 영역의 범위를 말해야 하는 장면은 문서의 선으로 두른다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'loading_region_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _loadingRegion;

/// 장면 이름(`loading-region/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'loading-region/announcements': () => _sized(
    _column(gap: CoreSpace.space24, [
      _column([Text('Skeleton만 두기').labelMedium.onSurface, _skeletons(), _caption(wrapped: false)]),
      _column([
        Text('LoadingRegion으로 감싸기').labelMedium.onSurface,
        LoadingRegion(child: _skeletons()),
        _caption(wrapped: true),
      ]),
    ]),
  ),
  'loading-region/do-name': () => _sized(
    _column(gap: CoreSpace.space24, [
      for (final name in [loadingRegionOrdersLabel, loadingRegionProductsLabel])
        _column([
          LoadingRegion(semanticLabel: name, child: _skeletons()),
          _caption(wrapped: true, semanticLabel: name),
        ]),
    ]),
  ),
  'loading-region/dont-default-label': () => _sized(
    _column(gap: CoreSpace.space24, [
      for (var i = 0; i < 2; i++) _column([LoadingRegion(child: _skeletons()), _caption(wrapped: true)]),
    ]),
  ),
  'loading-region/do-skeletons-only': () => _sized(
    _column(gap: CoreSpace.space12, [
      _filterButton(),
      _frame([_frameName(), LoadingRegion(semanticLabel: loadingRegionOrdersLabel, child: _skeletons())]),
    ]),
  ),
  // 그림만 그린다 — 실제 영역 안에 버튼을 두면 이 문서에서도 보조 기술이 그
  // 버튼을 찾지 못한다.
  'loading-region/dont-controls-inside': () => _sized(_frame([_frameName(), _filterButton(), _skeletons()])),
  'loading-region/layout-gap': () => _sized(
    _column(gap: CoreSpace.space12, [
      Text('주문 내역').titleSmall.onSurface,
      LoadingRegion(semanticLabel: loadingRegionOrdersLabel, child: _skeletons()),
      Text('최근 30일 기준').labelSmall.onSurfaceVariant,
    ]),
  ),
  'loading-region/related-skeleton': () => _sized(
    div(
      styles: Styles(raw: {'display': 'flex', 'align-items': 'center'}),
      [
        Skeleton.circle(size: pinnedLengthCss(CoreSize.size40)),
        const Gap.space12(),
        div(styles: Styles(raw: {'flex': '1'}), [_skeletons(2)]),
      ],
    ),
  ),
  'loading-region/related-loading': () => const Loading(),
};

Component _loadingRegion(Map<String, String> props, String? label) {
  final wrapped = loadingRegionPreviewWrapped(props);
  final semanticLabel = loadingRegionPreviewLabel(props);
  return _sized(
    _column(gap: CoreSpace.space12, [
      if (wrapped) LoadingRegion(semanticLabel: semanticLabel, child: _skeletons()) else _skeletons(),
      _caption(wrapped: wrapped, semanticLabel: semanticLabel),
    ]),
  );
}

/// 미리보기의 폭. 좁은 무대에서는 무대에 맞춰 줄어든다.
Component _sized(Component child) => div(
  styles: Styles(raw: {'width': pinnedLengthCss(loadingRegionPreviewWidth), 'max-width': '100%'}),
  [child],
);

/// 부모의 폭을 채우는 세로 묶음. [gap] 은 logical px.
Component _column(List<Component> children, {double gap = CoreSpace.space8}) => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(gap)}),
  children,
);

/// 내용 자리를 채우는 Skeleton 들.
Component _skeletons([int count = loadingRegionSkeletonCount]) =>
    _column([for (var i = 0; i < count; i++) Skeleton(height: pinnedLengthCss(CoreSize.size16))]);

/// 알리는 문구를 적는 설명 글. 문구가 없거나 영역이 없으면 지금 로케일의
/// 로딩 문구를 적는다.
Component _caption({required bool wrapped, String? semanticLabel}) => Builder(
  builder: (context) => Text(
    loadingRegionCaption(
      wrapped: wrapped,
      label: (wrapped ? semanticLabel : null) ?? CouiLocalizations.of(context).loadingLabel,
    ),
  ).labelSmall.onSurfaceVariant,
);

/// 로딩과 상관없이 쓸 수 있는 컨트롤.
Component _filterButton() => div(
  styles: Styles(raw: {'display': 'flex'}),
  [Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text('필터'))],
);

/// 선 안쪽이 무엇인지 적는 이름.
Component _frameName() => Text('LoadingRegion 범위').labelSmall.onSurfaceVariant;

/// 영역의 범위를 보이는 문서의 선 — LoadingRegion 이 그리는 것이 아니다.
Component _frame(List<Component> children) => div(
  styles: Styles(
    raw: {
      'padding': spaceCss(CoreSpace.space12),
      'border':
          '${strokeWidthCss(CoreStrokeWidth.stroke1)} solid ${const CoreColor.token(CoreColors.outline).toValue()}',
      'border-radius': radiusCss(CoreRadius.radius8),
    },
  ),
  [_column(gap: CoreSpace.space12, children)],
);
