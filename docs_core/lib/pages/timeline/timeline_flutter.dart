/// Timeline 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="timeline/...">` ·
/// `<Card demo>` · `<Anatomy demo>` 가 읽는다. 같은 이름의 Web 파일
/// (`timeline_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'timeline_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _timeline;

/// 장면 이름(`timeline/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'timeline/anatomy': () => _box(
    const Timeline(items: page.timelineAnatomyItems),
    width: page.timelineAnatomyWidth,
  ),
  'timeline/connector': () => _box(const Timeline(items: page.timelineConnectorItems)),
  'timeline/do-dot-align': () => _box(
    const Timeline(items: page.timelineShortItems, timelineStyle: page.timelineAlignedDotStyle),
  ),
  'timeline/dont-dot-align': () => _box(
    const Timeline(items: page.timelineShortItems, timelineStyle: page.timelineLargeDotStyle),
  ),
  'timeline/states': () => _box(const Timeline(items: page.timelineStateItems)),
  'timeline/do-optional': () => _box(
    const Timeline(items: page.timelineOptionalItems, timelineStyle: page.timelineCompactStyle),
  ),
  'timeline/do-count': () => _box(
    _stack([
      const Text(page.timelineCountHeading).labelLarge.onSurface,
      const Timeline(items: page.timelineShortItems, timelineStyle: page.timelineCompactStyle),
    ]),
  ),
  'timeline/dont-count': () => _box(
    const Timeline(items: page.timelineShortItems, timelineStyle: page.timelineCompactStyle),
  ),
  'timeline/do-state-text': () => _box(
    const Timeline(items: page.timelineStateTextItems, timelineStyle: page.timelineCompactStyle),
  ),
  'timeline/dont-state-color': () => _box(
    const Timeline(items: page.timelineStateColorItems, timelineStyle: page.timelineErrorDotStyle),
  ),
  'timeline/long-text': () => _box(const Timeline(items: page.timelineLongItems)),
  'timeline/narrow': () => _box(
    const Timeline(items: page.timelineOrderItems, timelineStyle: page.timelineCompactStyle),
    width: page.timelineNarrowSceneWidth,
  ),
  'timeline/styled': () => _box(
    const Timeline(items: page.timelineOrderItems, timelineStyle: page.timelineStyledStyle),
  ),
  'timeline/related-steps': () => const Steps(
    currentStep: 1,
    items: [
      CoreStepData(title: '접수'),
      CoreStepData(title: '결제'),
      CoreStepData(title: '발송'),
    ],
  ),
  'timeline/related-stepper': () => _box(
    Stepper(
      currentStep: 1,
      onStepChanged: (_) {},
      steps: const [
        CoreStepItem(label: '정보'),
        CoreStepItem(label: '결제'),
        CoreStepItem(label: '확인'),
      ],
    ),
    width: page.timelineNarrowSceneWidth,
  ),
  'timeline/related-tracker': () => const SizedBox(
    width: CoreSpace.space160,
    child: Tracker(
      segments: [
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.warning),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
        CoreTrackerSegment(status: CoreTrackerStatus.critical),
        CoreTrackerSegment(status: CoreTrackerStatus.fine),
      ],
    ),
  ),
};

Widget _timeline(Map<String, String> props, String? label) {
  final width = page.timelinePreviewTimeColumnWidth(props);
  return _box(
    Timeline(
      items: page.timelinePreviewItems(props),
      timelineStyle: width == null ? null : CoreTimelineStyle(timeColumnWidth: width),
    ),
  );
}

/// 폭을 정한 상자. Timeline 은 부모가 높이를 제한하면 그 높이를 다 차지하므로,
/// `Column(mainAxisSize: min)` 에 담아 내용 높이로 두어 무대 가운데에 놓는다.
Widget _box(Widget child, {double width = page.timelineSceneWidth}) => ConstrainedBox(
  constraints: BoxConstraints(maxWidth: width),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [child],
  ),
);

/// 제목과 Timeline 을 위아래로 놓는다.
Widget _stack(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: CoreSpace.space12,
  children: children,
);
