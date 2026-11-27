/// Timeline 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="timeline/...">` ·
/// `<Card demo>` · `<Anatomy demo>` 가 읽는다. 같은 이름의 Flutter 파일
/// (`timeline_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'timeline_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _timeline;

/// 장면 이름(`timeline/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
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
  'timeline/related-tracker': () => div(
    styles: Styles(raw: {'width': pinnedLengthCss(CoreSpace.space160)}),
    [
      const Tracker(
        segments: [
          CoreTrackerSegment(status: CoreTrackerStatus.fine),
          CoreTrackerSegment(status: CoreTrackerStatus.fine),
          CoreTrackerSegment(status: CoreTrackerStatus.warning),
          CoreTrackerSegment(status: CoreTrackerStatus.fine),
          CoreTrackerSegment(status: CoreTrackerStatus.critical),
          CoreTrackerSegment(status: CoreTrackerStatus.fine),
        ],
      ),
    ],
  ),
};

Component _timeline(Map<String, String> props, String? label) {
  final width = page.timelinePreviewTimeColumnWidth(props);
  return _box(
    Timeline(
      items: page.timelinePreviewItems(props),
      timelineStyle: width == null ? null : CoreTimelineStyle(timeColumnWidth: width),
    ),
  );
}

/// 폭을 정한 상자. 무대는 가운데로 모으는 flex 상자라, 폭을 정하지 않으면
/// Timeline 이 내용 폭으로 줄어든다.
Component _box(Component child, {double width = page.timelineSceneWidth}) => div(
  styles: Styles(raw: {'width': pinnedLengthCss(width), 'max-width': '100%'}),
  [child],
);

/// 제목과 Timeline 을 위아래로 놓는다.
Component _stack(List<Component> children) => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space12)}),
  children,
);
