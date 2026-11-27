/// Tracker 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="tracker/...">` ·
/// `<Card demo>` · `<Anatomy demo>` 가 읽는다. 같은 이름의 Web 파일
/// (`tracker_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'tracker_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _tracker;

/// 장면 이름(`tracker/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'tracker/anatomy': () => _box(
    Tracker(
      segments: page.trackerSegments(page.trackerAnatomyHistory),
      trackerStyle: page.trackerAnatomyStyle,
    ),
  ),
  'tracker/statuses': () => _box(
    _column([
      Tracker(
        segments: [
          for (final status in CoreTrackerStatus.values)
            CoreTrackerSegment(status: status, tooltip: page.trackerStatusWords[status]),
        ],
      ),
      _statusNames(),
    ]),
  ),
  'tracker/heights': () => _box(
    _column([
      for (final (caption, height) in page.trackerHeightSamples)
        _captioned(
          caption,
          Tracker(
            segments: page.trackerSample(),
            trackerStyle: CoreTrackerStyle(itemHeight: height),
          ),
        ),
    ], gap: CoreSpace.space16),
  ),
  'tracker/shape': () => _box(
    _column([
      for (final (caption, rounded, endRadius) in page.trackerShapeSamples)
        _captioned(
          caption,
          Tracker(
            segments: page.trackerSample(),
            rounded: rounded,
            trackerStyle: CoreTrackerStyle(endRadius: endRadius),
          ),
        ),
    ], gap: CoreSpace.space16),
  ),
  'tracker/dense': () => _box(
    _captioned(
      '60칸, itemSpacing: 2',
      Tracker(segments: page.trackerSegments(page.trackerDenseHistory), trackerStyle: page.trackerDenseStyle),
    ),
  ),
  'tracker/do-summary': () => _box(
    _column([
      const Text('API 서버').labelMedium.onSurface,
      Tracker(segments: page.trackerSample()),
      Text(page.trackerSummary()).bodySmall.onSurfaceVariant,
    ]),
    width: page.trackerCardWidth,
  ),
  'tracker/dont-bare': () => _box(Tracker(segments: page.trackerSample()), width: page.trackerCardWidth),
  'tracker/do-status-color': () => _box(Tracker(segments: page.trackerSample(7)), width: page.trackerCardWidth),
  'tracker/dont-one-color': () => _box(
    Tracker(
      segments: page.trackerSample(7),
      trackerStyle: const CoreTrackerStyle(segmentColor: CoreColor.token(CoreColors.primary)),
    ),
    width: page.trackerCardWidth,
  ),
  'tracker/related-status': () => const Status(color: CoreStatusColor.success, label: Text('정상 운영')),
  'tracker/related-progress': () => _box(const Progress(value: 0.6), width: page.trackerCardWidth),
  'tracker/related-timeline': () => _box(_column(const [Timeline(items: page.trackerRelatedEvents)])),
  'tracker/related-stat': () => _box(
    _column(const [Stat(label: '가동률', value: '99.9', unit: '%')]),
    width: page.trackerCardWidth,
  ),
};

Widget _tracker(Map<String, String> props, String? label) => _box(
  Tracker(
    segments: page.trackerSample(page.trackerPreviewCount(props)),
    rounded: previewFlag(props, 'rounded', fallback: true),
    trackerStyle: page.trackerPreviewStyle(props),
  ),
);

/// 폭을 정한 상자 — 좁은 부모에서는 부모의 폭까지만 쓴다.
Widget _box(Widget child, {double width = page.trackerSceneWidth}) => ConstrainedBox(
  constraints: BoxConstraints(maxWidth: width),
  child: child,
);

/// 위에서 아래로 쌓고 폭을 채운다.
Widget _column(List<Widget> children, {double gap = CoreSpace.space8}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: gap,
  children: children,
);

/// 위에 설명을 단 장면 조각.
Widget _captioned(String caption, Widget child) => _column([
  Text(caption).labelSmall.onSurfaceVariant,
  child,
]);

/// 구간 아래에 같은 폭으로 놓는 상태 이름.
Widget _statusNames() => Row(
  spacing: CoreTrackerStyle.defaultItemSpacing,
  children: [
    for (final status in CoreTrackerStatus.values)
      Expanded(child: Center(child: Text(status.name).labelSmall.onSurfaceVariant)),
  ],
);
