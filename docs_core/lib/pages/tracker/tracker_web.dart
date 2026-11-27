/// Tracker 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="tracker/...">` ·
/// `<Card demo>` · `<Anatomy demo>` 가 읽는다. 같은 이름의 Flutter 파일
/// (`tracker_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import 'tracker_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _tracker;

/// 장면 이름(`tracker/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
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
  'tracker/related-status': () => Status(color: CoreStatusColor.success, label: const Text('정상 운영')),
  'tracker/related-progress': () => _box(const Progress(value: 0.6), width: page.trackerCardWidth),
  'tracker/related-timeline': () => _box(_column([const Timeline(items: page.trackerRelatedEvents)])),
  'tracker/related-stat': () => _box(
    _column([const Stat(label: '가동률', value: '99.9', unit: '%')]),
    width: page.trackerCardWidth,
  ),
};

Component _tracker(Map<String, String> props, String? label) => _box(
  Tracker(
    segments: page.trackerSample(page.trackerPreviewCount(props)),
    rounded: previewFlag(props, 'rounded', fallback: true),
    trackerStyle: page.trackerPreviewStyle(props),
  ),
);

/// 폭을 정한 상자 — 좁은 화면과 좁은 부모에서는 그 안에 들어오게 줄인다.
/// 폭을 `%` 로만 적으면 내용에 맞춰 폭이 정해지는 부모(구조 그림의 무대)에서
/// Tracker 가 나눠 가질 폭이 없어진다.
Component _box(Component child, {double width = page.trackerSceneWidth}) => div(
  styles: Styles(
    raw: {
      'width': 'min(${pinnedLengthCss(width)}, calc(100vw - ${pinnedLengthCss(CoreSpace.space128)}))',
      'max-width': '100%',
    },
  ),
  [child],
);

/// 위에서 아래로 쌓는다.
Component _column(List<Component> children, {double gap = CoreSpace.space8}) => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(gap)}),
  children,
);

/// 위에 설명을 단 장면 조각.
Component _captioned(String caption, Component child) => _column([
  Text(caption).labelSmall.onSurfaceVariant,
  child,
]);

/// 구간 아래에 같은 폭으로 놓는 상태 이름.
Component _statusNames() => div(
  styles: Styles(raw: {'display': 'flex', 'gap': spaceCss(CoreTrackerStyle.defaultItemSpacing)}),
  [
    for (final status in CoreTrackerStatus.values)
      div(
        styles: Styles(raw: {'flex': '1', 'min-width': '0', 'text-align': 'center'}),
        [Text(status.name).labelSmall.onSurfaceVariant],
      ),
  ],
);
