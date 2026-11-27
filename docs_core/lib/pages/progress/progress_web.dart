/// Progress 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="progress/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`progress_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 직선형 막대는 부모 폭을 채우므로 미리보기는 늘 폭을 정한 상자에 담는다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../../shared/preview_props.dart';
import '../page_kit_web.dart';
import 'progress_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _progress;

/// 장면 이름(`progress/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'progress/anatomy': () => _box(
    const Progress(
      value: progressPlanValue,
      size: CoreProgressSize.lg,
      label: Text(progressPlanLabel),
      valueLabel: Text(progressPlanValueText),
      caption: Text(progressPlanCaption),
    ),
  ),
  'progress/segments': () => _box(
    const Progress(
      value: 1,
      max: 2,
      segments: 2,
      size: CoreProgressSize.xs,
      label: Text(progressStepLabel),
      progressStyle: CoreProgressStyle(
        labelStyle: CoreTextStyle(color: CoreColor.token(CoreColors.primary)),
      ),
    ),
  ),
  'progress/segment-count': () => _box(
    _column([
      for (final (index, value) in progressCountSamples.indexed) ...[
        if (index > 0) const Gap.space12(),
        Text(progressCountCaption(value)).labelSmall.onSurfaceVariant,
        const Gap.space4(),
        Progress(value: value, segments: progressCountCells, size: CoreProgressSize.md),
      ],
    ]),
  ),
  'progress/shape-continuous': () => _box(
    const Progress(value: 0.6, size: CoreProgressSize.lg),
    width: CoreSpace.space160,
  ),
  'progress/shape-segments': () => _box(
    const Progress(value: 0.6, segments: 5, size: CoreProgressSize.lg),
    width: CoreSpace.space160,
  ),
  'progress/shape-square': () => _box(
    const Progress(
      value: 0.6,
      size: CoreProgressSize.lg,
      progressStyle: CoreProgressStyle(borderRadius: CoreBorderRadius.zero),
    ),
    width: CoreSpace.space160,
  ),
  'progress/sizes': () => _box(
    _column([
      for (final (index, size) in CoreProgressStyle.defaultsBySize.keys.indexed) ...[
        if (index > 0) const Gap.space12(),
        Text(progressSizeCaption(size)).labelSmall.onSurfaceVariant,
        const Gap.space4(),
        Progress(value: progressDemoValue, size: size),
      ],
    ]),
  ),
  'progress/states': () => _box(
    _column([
      for (final (index, (caption, value, tone)) in progressStateSamples.indexed) ...[
        if (index > 0) const Gap.space12(),
        Text(caption).labelSmall.onSurfaceVariant,
        const Gap.space4(),
        Progress(value: value, tone: tone),
      ],
    ]),
  ),
  'progress/radial-sizes': () => docsWebDemoRow([
    for (final size in CoreRadialProgressStyle.defaultsBySize.keys)
      _captioned(
        progressRadialSizeCaption(size),
        RadialProgress(value: 75, size: size, showValueText: true),
      ),
  ]),
  'progress/radial-tones': () => docsWebDemoRow([
    for (final tone in CoreProgressTone.values)
      _captioned(
        tone.name,
        RadialProgress(value: 70, size: CoreProgressSize.md, tone: tone, showValueText: true),
      ),
  ]),
  // Web 의 `RadialProgress` 는 `child` 를 가운데로 옮기지 않으므로 가운데 놓는
  // 상자로 감싼다.
  'progress/radial-child': () => docsWebDemoRow([
    RadialProgress(
      value: 75,
      tone: CoreProgressTone.success,
      child: _ringCenter(Icon(LucideIcons.check)),
    ),
    RadialProgress(
      value: 60,
      child: _ringCenter(const Text(progressRadialChildText).labelLarge.onSurface),
    ),
  ]),
  'progress/do-labelled': () => _box(
    const Progress(
      value: progressDemoValue,
      label: Text(progressDemoLabel),
      valueLabel: Text('65%'),
    ),
    width: CoreSpace.space160,
  ),
  'progress/do-radial-stat': () => _captioned(
    progressRadialStatCaption,
    const RadialProgress(value: 75, showValueText: true),
  ),
  'progress/do-caption': () => _box(
    const Progress(value: 0.9, caption: Text(progressSlowCaption)),
    width: CoreSpace.space160,
  ),
  'progress/dont-silent': () => _box(
    const Progress(value: 0.9),
    width: CoreSpace.space160,
  ),
  'progress/dont-tone-only': () => _box(
    const Progress(value: 0.4, tone: CoreProgressTone.destructive),
    width: CoreSpace.space160,
  ),
  'progress/in-row': () => _box(
    div(
      styles: Styles(raw: {'display': 'flex', 'align-items': 'center'}),
      [
        const Text(progressRowLabel).labelMedium.onSurface,
        const Gap.space12(),
        div(
          styles: Styles(raw: {'flex': '1', 'min-width': '0'}),
          [const Progress(value: 0.42)],
        ),
        const Gap.space12(),
        const Text(progressRowValueText).labelMedium.onSurfaceVariant,
      ],
    ),
  ),
  'progress/a11y-name': () => docsWebDemoRow([
    _box(
      const Progress(value: 0.4, attributes: {'aria-label': progressA11yName}),
      width: CoreSpace.space160,
    ),
    const RadialProgress(
      value: 75,
      showValueText: true,
      attributes: {'aria-label': progressRadialA11yName},
    ),
  ]),
  'progress/related-loading': () => const Loading(componentSize: CoreComponentSize.lg),
  'progress/related-skeleton': () => div(
    styles: Styles(raw: {'display': 'flex', 'align-items': 'center'}),
    [
      Skeleton.circle(size: pinnedLengthCss(CoreSize.size40)),
      const Gap.space12(),
      _box(Skeleton.text(), width: CoreSpace.space96),
    ],
  ),
  'progress/related-slider': () => _box(
    Slider(value: 60, onChanged: (_) {}),
    width: CoreSpace.space160,
  ),
  'progress/related-tracker': () => _box(
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
    width: CoreSpace.space160,
  ),
};

Component _progress(Map<String, String> props, String? label) {
  final value = progressPreviewValue(props);
  final segments = progressPreviewSegments(props);
  final labelled = previewFlag(props, 'labelled');
  final valueText = progressPreviewValueText(value, segments);
  return _box(
    Progress(
      value: value,
      segments: segments,
      tone: previewEnum(CoreProgressTone.values, props['tone'], CoreProgressTone.defaultTone),
      size: previewEnum(CoreProgressSize.values, props['size'], CoreProgressSize.defaultSize),
      disableAnimation: previewFlag(props, 'disableAnimation'),
      label: labelled ? Text(label ?? progressDemoLabel) : null,
      valueLabel: labelled && valueText != null ? Text(valueText) : null,
      caption: labelled ? const Text(progressDemoCaption) : null,
    ),
  );
}

/// 폭을 정한 상자 — 좁은 화면에서는 부모 폭까지만 쓴다.
Component _box(Component child, {double width = CoreSpace.space256}) => div(
  styles: Styles(raw: {'width': pinnedLengthCss(width), 'max-width': '100%'}),
  [child],
);

/// 문서 시트의 간격 없이 [Gap] 만으로 띄우는 세로 상자.
Component _column(List<Component> children) => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column'}),
  children,
);

/// 그림 아래에 설명을 단 장면 조각.
Component _captioned(String caption, Component child) => div(
  styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'align-items': 'center'}),
  [child, const Gap.space8(), Text(caption).labelSmall.onSurfaceVariant],
);

/// `RadialProgress` 의 `child` 를 링 가운데에 놓는 상자.
Component _ringCenter(Component child) => div(
  styles: Styles(
    raw: {
      'position': 'absolute',
      'inset': '0',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
    },
  ),
  [child],
);
