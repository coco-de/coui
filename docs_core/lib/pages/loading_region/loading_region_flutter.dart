/// LoadingRegion 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="loading-region/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`loading_region_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// LoadingRegion 은 아무것도 그리지 않으므로, 알리는 문구는 문서의 글로 적고
/// 영역의 범위를 말해야 하는 장면은 문서의 선으로 두른다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'loading_region_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _loadingRegion;

/// 장면 이름(`loading-region/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
  'loading-region/do-name': () => _still(
    _sized(
      _column(gap: CoreSpace.space24, [
        for (final name in [loadingRegionOrdersLabel, loadingRegionProductsLabel])
          _column([
            LoadingRegion(semanticLabel: name, child: _skeletons()),
            _caption(wrapped: true, semanticLabel: name),
          ]),
      ]),
    ),
  ),
  'loading-region/dont-default-label': () => _still(
    _sized(
      _column(gap: CoreSpace.space24, [
        for (var i = 0; i < 2; i++) _column([LoadingRegion(child: _skeletons()), _caption(wrapped: true)]),
      ]),
    ),
  ),
  'loading-region/do-skeletons-only': () => _still(
    _sized(
      _column(gap: CoreSpace.space12, [
        _filterButton(),
        _frame([_frameName(), LoadingRegion(semanticLabel: loadingRegionOrdersLabel, child: _skeletons())]),
      ]),
    ),
  ),
  // 그림만 그린다 — 실제 영역 안에 버튼을 두면 이 문서에서도 보조 기술이 그
  // 버튼을 찾지 못한다.
  'loading-region/dont-controls-inside': () => _still(_sized(_frame([_frameName(), _filterButton(), _skeletons()]))),
  'loading-region/layout-gap': () => _sized(
    _column(gap: CoreSpace.space12, [
      Text('주문 내역').titleSmall.onSurface,
      LoadingRegion(semanticLabel: loadingRegionOrdersLabel, child: _skeletons()),
      Text('최근 30일 기준').labelSmall.onSurfaceVariant,
    ]),
  ),
  'loading-region/related-skeleton': () => _still(
    _sized(
      Row(
        children: [
          const Skeleton.circle(size: CoreSize.size40),
          const Gap.space12(),
          Expanded(child: _skeletons(2)),
        ],
      ),
    ),
  ),
  'loading-region/related-loading': () => _still(const Loading()),
};

Widget _loadingRegion(Map<String, String> props, String? label) {
  final wrapped = loadingRegionPreviewWrapped(props);
  final semanticLabel = loadingRegionPreviewLabel(props);
  return _sized(
    _column(gap: CoreSpace.space12, [
      if (wrapped) LoadingRegion(semanticLabel: semanticLabel, child: _skeletons()) else _skeletons(),
      _caption(wrapped: wrapped, semanticLabel: semanticLabel),
    ]),
  );
}

/// 미리보기의 폭.
Widget _sized(Widget child) => SizedBox(width: loadingRegionPreviewWidth, child: child);

/// 부모의 폭을 채우는 세로 묶음.
Widget _column(List<Widget> children, {double gap = CoreSpace.space8}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: gap,
  children: children,
);

/// 내용 자리를 채우는 Skeleton 들.
Widget _skeletons([int count = loadingRegionSkeletonCount]) =>
    _column([for (var i = 0; i < count; i++) const Skeleton(height: CoreSize.size16)]);

/// 알리는 문구를 적는 설명 글. 문구가 없거나 영역이 없으면 지금 로케일의
/// 로딩 문구를 적는다.
Widget _caption({required bool wrapped, String? semanticLabel}) => Builder(
  builder: (context) => Text(
    loadingRegionCaption(
      wrapped: wrapped,
      label: (wrapped ? semanticLabel : null) ?? CoUILocalizations.of(context).loadingLabel,
    ),
  ).labelSmall.onSurfaceVariant,
);

/// 로딩과 상관없이 쓸 수 있는 컨트롤.
Widget _filterButton() => Align(
  alignment: Alignment.centerLeft,
  child: Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text('필터')),
);

/// 선 안쪽이 무엇인지 적는 이름.
Widget _frameName() => Text('LoadingRegion 범위').labelSmall.onSurfaceVariant;

/// 영역의 범위를 보이는 문서의 선 — LoadingRegion 이 그리는 것이 아니다.
Widget _frame(List<Widget> children) => Builder(
  builder: (context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border.all(
        color: Theme.of(context).colorScheme.resolve(const CoreColor.token(CoreColors.outline)).toValue(),
        width: CoreStrokeWidth.stroke1,
      ),
      borderRadius: const BorderRadius.all(Radius.circular(CoreRadius.radius8)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(CoreSpace.space12),
      child: _column(gap: CoreSpace.space12, children),
    ),
  ),
);

/// 카드의 스피너 · 스켈레톤을 멈춘 그림. 계속 도는 애니메이션이 있으면 네이티브
/// 앱의 카드 검사(`pumpAndSettle`)가 끝나지 않는다.
Widget _still(Widget child) => TickerMode(enabled: false, child: child);
