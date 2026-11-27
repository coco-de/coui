/// Skeleton 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="skeleton/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`skeleton_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'skeleton_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _skeleton;

/// 장면 이름(`skeleton/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'skeleton/sizing': () => _sized(
    _column([
      _caption('width와 height를 모두 정한 막대'),
      Skeleton(width: pinnedLengthCss(CoreSize.size128), height: pinnedLengthCss(CoreSize.size16)),
      _caption('부모 폭을 채운 블록'),
      Skeleton(width: '100%', height: pinnedLengthCss(CoreSize.size96)),
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
  'skeleton/do-match-layout': () => _sized(
    LoadingRegion(
      child: _column(gap: CoreSpace.space12, [
        Skeleton(width: '100%', height: pinnedLengthCss(CoreSize.size96)),
        _avatarRow(),
        Skeleton(width: pinnedLengthCss(CoreSize.size96), height: pinnedLengthCss(CoreSize.size16)),
      ]),
    ),
  ),
  'skeleton/dont-single-block': () => _sized(Skeleton(width: '100%', height: pinnedLengthCss(CoreSize.size128))),
  'skeleton/do-list': () => _sized(
    LoadingRegion(
      child: _column(gap: CoreSpace.space16, [for (var i = 0; i < skeletonListRows; i++) _avatarRow()]),
    ),
  ),
  'skeleton/dont-spinner': () => _sized(
    div(
      styles: Styles(
        raw: {
          'display': 'flex',
          'flex-direction': 'column',
          'align-items': 'center',
          'gap': spaceCss(CoreSpace.space12),
        },
      ),
      [const Loading(), Skeleton.text()],
    ),
  ),
  'skeleton/styles': () => _sized(
    _column([
      _caption('borderRadius: radius16'),
      _block(const CoreSkeletonStyle(borderRadius: CoreBorderRadius.all(CoreRadius.radius16))),
      _caption('backgroundColor: info'),
      _block(const CoreSkeletonStyle(backgroundColor: CoreColor.token(CoreColors.info))),
      _caption('lines: 4, lastLineWidth: $skeletonShortLastLine'),
      Skeleton.text(skeletonStyle: const CoreSkeletonStyle(lines: 4, lastLineWidth: skeletonShortLastLine)),
    ]),
  ),
  'skeleton/related-loading-region': () => _sized(
    LoadingRegion(
      semanticLabel: '주문 목록 불러오는 중',
      child: _column([_bar(null), _bar(null), _bar(null)]),
    ),
  ),
  'skeleton/related-loading': () => const Loading(),
  'skeleton/related-empty-state': () => _sized(EmptyState.compact(title: Text('주문이 없습니다'))),
  'skeleton/related-avatar': () => div(
    styles: Styles(raw: {'display': 'flex', 'align-items': 'center', 'gap': spaceCss(CoreSpace.space16)}),
    [
      Skeleton.circle(size: pinnedLengthCss(CoreSize.size40)),
      Avatar(initials: 'AB', size: CoreComponentSize.md),
    ],
  ),
};

Component _skeleton(Map<String, String> props, String? label) {
  final style = skeletonPreviewStyle(props);
  return switch (skeletonPreviewVariant(props)) {
    CoreSkeletonVariant.rectangular => Skeleton(
      width: pinnedLengthCss(skeletonPreviewWidth),
      height: pinnedLengthCss(CoreSize.size40),
      skeletonStyle: style,
    ),
    CoreSkeletonVariant.circular => Skeleton.circle(size: pinnedLengthCss(CoreSize.size48), skeletonStyle: style),
    CoreSkeletonVariant.text => _sized(Skeleton.text(skeletonStyle: style)),
  };
}

/// 미리보기의 폭. 좁은 무대에서는 무대에 맞춰 줄어든다.
Component _sized(Component child) => div(
  styles: Styles(raw: {'width': pinnedLengthCss(skeletonPreviewWidth), 'max-width': '100%'}),
  [child],
);

/// 세로 묶음. 폭을 정한 Skeleton 은 늘어나지 않는다.
Component _column(List<Component> children, {double gap = CoreSpace.space8}) => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(gap)}),
  children,
);

Component _caption(String text) => Text(text).labelSmall.onSurfaceVariant;

/// 부모 폭을 채우는 한 줄 막대.
Component _bar(CoreSkeletonStyle? style) =>
    Skeleton(width: '100%', height: pinnedLengthCss(CoreSize.size16), skeletonStyle: style);

/// 부모 폭을 채우는 블록.
Component _block(CoreSkeletonStyle style) =>
    Skeleton(width: '100%', height: pinnedLengthCss(CoreSize.size48), skeletonStyle: style);

/// 원 하나와 그 옆의 글줄 두 줄. 글줄은 남은 폭을 받는 래퍼 안에 둔다 — 폭이
/// 100% 인 글줄을 원 옆에 바로 두면 원이 좁아진다.
Component _avatarRow() => div(
  styles: Styles(raw: {'display': 'flex', 'align-items': 'center'}),
  [
    Skeleton.circle(size: pinnedLengthCss(CoreSize.size40)),
    const Gap.space12(),
    div(styles: Styles(raw: {'flex': '1'}), [Skeleton.text(skeletonStyle: const CoreSkeletonStyle(lines: 2))]),
  ],
);
