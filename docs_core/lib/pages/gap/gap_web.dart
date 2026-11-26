/// Gap 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="gap/...">` 가 읽는다. 같은 이름의 Flutter 파일(`gap_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Web 의 Gap 은 부모가 flex 일 때만 자리를 차지한다(`flex-basis`). 그래서
/// 모든 장면은 Gap 을 인라인 `display: flex` 부모 안에 둔다 — 문서 시트의
/// `docs-demo-row` 는 자기 `gap` 이 있어 Gap 의 간격에 더해지므로 쓰지 않는다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'gap_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _gap;

/// 장면 이름(`gap/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'gap/direction': () => _flex(start: true, [
    _captioned('Row', _flex([_item('A'), const Gap.space16(), _item('B')])),
    const Gap.space48(),
    _captioned('Column', _flex(vertical: true, [_item('A'), const Gap.space16(), _item('B')])),
  ]),
  'gap/sizes': () => _flex(vertical: true, start: true, [
    for (final (index, size) in gapSceneSizeSteps.indexed) ...[
      if (index > 0) const Gap.space12(),
      _flex([
        span(styles: Styles(raw: {'width': pinnedLengthCss(72)}), [
          Text('space${size.toInt()}').labelSmall.onSurfaceVariant,
        ]),
        _item('A'),
        Gap(gapStyle: CoreGapStyle(size: size)),
        _item('B'),
      ]),
    ],
  ]),
  'gap/max-gap': () => _flex(vertical: true, start: true, [
    for (final (index, (caption, width)) in gapSceneMaxGapParents.indexed) ...[
      if (index > 0) const Gap.space16(),
      Text(caption).labelSmall.onSurfaceVariant,
      const Gap.space8(),
      _flex(width: width, [_item('A'), const MaxGap.space64(), _item('B')]),
    ],
  ]),
  'gap/related-join': () => Join(
    children: [
      for (final label in ['1', '2', '3'])
        Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text(label)),
    ],
  ),
  'gap/related-divider': () => div(styles: Styles(raw: {'width': pinnedLengthCss(160)}), [const Divider()]),
};

Component _gap(Map<String, String> props, String? label) {
  final size = gapPreviewSize(props);
  return _flex(vertical: gapPreviewVertical(props), [
    _item('A'),
    Gap(gapStyle: size == null ? null : CoreGapStyle(size: size)),
    _item('B'),
  ]);
}

/// Gap 의 양옆에 두는 요소.
Component _item(String label) => Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text(label));

/// Gap 이 방향을 읽는 부모 — `flex`, 자식 사이 간격 없음. [width] 는 logical px.
Component _flex(List<Component> children, {bool vertical = false, bool start = false, double? width}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': vertical ? 'column' : 'row',
      'align-items': start ? 'flex-start' : 'center',
      if (width != null) 'width': pinnedLengthCss(width),
    },
  ),
  children,
);

/// 위에 이름을 단 장면 조각.
Component _captioned(String caption, Component child) =>
    _flex(vertical: true, start: true, [Text(caption).labelSmall.onSurfaceVariant, const Gap.space8(), child]);
