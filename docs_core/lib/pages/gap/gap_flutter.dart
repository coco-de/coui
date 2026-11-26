/// Gap 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="gap/...">` 가 읽는다. 같은 이름의 Web 파일(`gap_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Flutter 의 Gap 은 바로 위 `Flex`(Row · Column)에서 방향을 읽는다. 그래서
/// 모든 장면은 Gap 을 `Flex` 의 직계 자식으로 둔다 — `docsFlutterDemoRow` 는
/// `Wrap` 이라 Gap 이 방향을 찾지 못하므로 쓰지 않는다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'gap_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _gap;

/// 장면 이름(`gap/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'gap/direction': () => _flex(start: true, [
    _captioned('Row', _flex([_item('A'), const Gap.space16(), _item('B')])),
    const Gap.space48(),
    _captioned('Column', _flex(vertical: true, [_item('A'), const Gap.space16(), _item('B')])),
  ]),
  'gap/sizes': () => _flex(vertical: true, start: true, [
    for (final (index, size) in gapSceneSizeSteps.indexed) ...[
      if (index > 0) const Gap.space12(),
      _flex([
        SizedBox(width: 72, child: Text('space${size.toInt()}').labelSmall.onSurfaceVariant),
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
      SizedBox(
        width: width,
        child: Row(children: [_item('A'), const MaxGap.space64(), _item('B')]),
      ),
    ],
  ]),
  'gap/related-join': () => Join(
    children: [
      for (final label in ['1', '2', '3'])
        Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text(label)),
    ],
  ),
  'gap/related-divider': () => const SizedBox(width: 160, child: Divider()),
};

Widget _gap(Map<String, String> props, String? label) {
  final size = gapPreviewSize(props);
  return _flex(vertical: gapPreviewVertical(props), [
    _item('A'),
    Gap(gapStyle: size == null ? null : CoreGapStyle(size: size)),
    _item('B'),
  ]);
}

/// Gap 의 양옆에 두는 요소.
Widget _item(String label) => Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text(label));

/// Gap 이 방향을 읽는 부모 — 내용만큼만 차지하는 `Flex`.
Widget _flex(List<Widget> children, {bool vertical = false, bool start = false}) => Flex(
  direction: vertical ? Axis.vertical : Axis.horizontal,
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: start ? CrossAxisAlignment.start : CrossAxisAlignment.center,
  children: children,
);

/// 위에 이름을 단 장면 조각.
Widget _captioned(String caption, Widget child) =>
    _flex(vertical: true, start: true, [Text(caption).labelSmall.onSurfaceVariant, const Gap.space8(), child]);
