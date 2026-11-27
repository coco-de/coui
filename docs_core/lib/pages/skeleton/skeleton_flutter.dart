/// Skeleton 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="skeleton/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`skeleton_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'skeleton_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _skeleton;

/// 장면 이름(`skeleton/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'skeleton/sizing': () => _sized(
    _column([
      _caption('width와 height를 모두 정한 막대'),
      const Skeleton(width: CoreSize.size128, height: CoreSize.size16),
      _caption('부모 폭을 채운 블록'),
      const Skeleton(width: double.infinity, height: CoreSize.size96),
    ]),
  ),
  // 앞의 두 막대는 두 불투명도를 같게 두어 맥동의 한쪽 끝에 세운다.
  'skeleton/pulse-ends': () => _sized(
    _column([
      _caption('쉼 끝 (fromOpacity)'),
      _bar(const CoreSkeletonStyle(toOpacity: CoreSkeletonStyle.defaultFromOpacity)),
      _caption('정점 (toOpacity)'),
      _bar(const CoreSkeletonStyle(fromOpacity: CoreSkeletonStyle.defaultToOpacity)),
      _caption('기본 설정'),
      _bar(null),
    ]),
  ),
  'skeleton/avatar-row': () => _sized(_avatarRow()),
  'skeleton/do-match-layout': () => _still(
    _sized(
      LoadingRegion(
        child: _column(gap: CoreSpace.space12, [
          const Skeleton(width: double.infinity, height: CoreSize.size96),
          _avatarRow(),
          const Skeleton(width: CoreSize.size96, height: CoreSize.size16),
        ]),
      ),
    ),
  ),
  'skeleton/dont-single-block': () => _still(_sized(const Skeleton(width: double.infinity, height: CoreSize.size128))),
  'skeleton/do-list': () => _still(
    _sized(
      LoadingRegion(
        child: _column(gap: CoreSpace.space16, [for (var i = 0; i < skeletonListRows; i++) _avatarRow()]),
      ),
    ),
  ),
  'skeleton/dont-spinner': () => _still(
    _sized(
      const Column(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpace.space12,
        children: [Loading(), Skeleton.text()],
      ),
    ),
  ),
  'skeleton/styles': () => _sized(
    _column([
      _caption('borderRadius: radius16'),
      _block(const CoreSkeletonStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius16))),
      _caption('backgroundColor: info'),
      _block(const CoreSkeletonStyle(backgroundColor: CoreColor.token(CoreColors.info))),
      _caption('lines: 4, lastLineWidth: $skeletonShortLastLine'),
      const Skeleton.text(skeletonStyle: CoreSkeletonStyle(lines: 4, lastLineWidth: skeletonShortLastLine)),
    ]),
  ),
  'skeleton/related-loading-region': () => _still(
    _sized(
      LoadingRegion(
        semanticLabel: '주문 목록 불러오는 중',
        child: _column([_bar(null), _bar(null), _bar(null)]),
      ),
    ),
  ),
  'skeleton/related-loading': () => _still(const Loading()),
  'skeleton/related-empty-state': () => _sized(const EmptyState.compact(title: Text('주문이 없습니다'))),
  'skeleton/related-avatar': () => _still(
    const Row(
      mainAxisSize: MainAxisSize.min,
      spacing: CoreSpace.space16,
      children: [
        Skeleton.circle(size: CoreSize.size40),
        Avatar(initials: 'AB', size: CoreComponentSize.md),
      ],
    ),
  ),
};

Widget _skeleton(Map<String, String> props, String? label) {
  final style = skeletonPreviewStyle(props);
  return switch (skeletonPreviewVariant(props)) {
    CoreSkeletonVariant.rectangular => Skeleton(
      width: skeletonPreviewWidth,
      height: CoreSize.size40,
      skeletonStyle: style,
    ),
    CoreSkeletonVariant.circular => Skeleton.circle(size: CoreSize.size48, skeletonStyle: style),
    CoreSkeletonVariant.text => _sized(Skeleton.text(skeletonStyle: style)),
  };
}

/// 미리보기의 폭. `Skeleton.text` 는 폭이 한정된 부모가 있어야 한다.
Widget _sized(Widget child) => SizedBox(width: skeletonPreviewWidth, child: child);

/// 왼쪽에 맞춘 세로 묶음 — 폭을 정한 Skeleton 이 늘어나지 않는다.
Widget _column(List<Widget> children, {double gap = CoreSpace.space8}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: gap,
  children: children,
);

Widget _caption(String text) => Text(text).labelSmall.onSurfaceVariant;

/// 부모 폭을 채우는 한 줄 막대.
Widget _bar(CoreSkeletonStyle? style) =>
    Skeleton(width: double.infinity, height: CoreSize.size16, skeletonStyle: style);

/// 부모 폭을 채우는 블록.
Widget _block(CoreSkeletonStyle style) =>
    Skeleton(width: double.infinity, height: CoreSize.size48, skeletonStyle: style);

/// 원 하나와 그 옆의 글줄 두 줄.
Widget _avatarRow() => const Row(
  children: [
    Skeleton.circle(size: CoreSize.size40),
    Gap.space12(),
    Expanded(child: Skeleton.text(skeletonStyle: CoreSkeletonStyle(lines: 2))),
  ],
);

/// 카드의 스피너 · 스켈레톤을 멈춘 그림. 계속 도는 애니메이션이 있으면 네이티브
/// 앱의 카드 검사(`pumpAndSettle`)가 끝나지 않는다.
Widget _still(Widget child) => TickerMode(enabled: false, child: child);
