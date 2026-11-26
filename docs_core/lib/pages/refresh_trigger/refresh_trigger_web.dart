/// RefreshTrigger 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="refresh-trigger/...">` · `<Card demo>` · `<Anatomy>` 가 읽는다.
/// 같은 이름의 Flutter 파일(`refresh_trigger_flutter.dart`)과 컴포넌트 · 속성 ·
/// 장면 이름이 같아야 한다.
///
/// 장면의 상자는 실제 `RefreshTrigger` 다. 서버가 그린 무대에서는 당길 수
/// 없으므로 `stage` 를 직접 지정해 `refreshing` · `completed` 를 보인다.
/// `stage-pulling` · `stage-release` 만 그림이다 — 직접 지정한 `pulling` 은
/// 당긴 거리가 0 이라 표시가 영역 밖에 남는다. 그림은 표시 상자인 실제
/// `OutlinedContainer` 에 `RefreshTrigger` 의 기본값을 넘겨 그린다.
library;

import 'dart:async';

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import 'refresh_trigger_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _refreshTrigger;

/// 장면 이름(`refresh-trigger/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'refresh-trigger/anatomy': () => _anatomyFrame(
    _box(stage: CoreRefreshStage.refreshing, height: page.demoAnatomyHeight, markContent: true),
  ),
  'refresh-trigger/stage-pulling': () => _pullingPicture(label: page.demoPullLabel, degrees: 0),
  'refresh-trigger/stage-release': () => _pullingPicture(label: page.demoReleaseLabel, degrees: -180),
  'refresh-trigger/stage-refreshing': () => _frame(_box(stage: CoreRefreshStage.refreshing)),
  'refresh-trigger/stage-completed': () => _frame(_box(stage: CoreRefreshStage.completed)),
  'refresh-trigger/custom-style': () => _frame(
    _box(stage: CoreRefreshStage.refreshing, style: page.demoCustomStyle),
    width: page.demoBoxWidth,
  ),
  'refresh-trigger/do-report-failure': () => _frame(
    div(classes: 'flex w-full flex-col', [
      const Alert(
        variant: CoreAlertVariant.destructive,
        title: page.demoFailureTitle,
        description: page.demoFailureHint,
      ),
      const Gap.space8(),
      _box(),
    ]),
  ),
  'refresh-trigger/do-button': () => _frame(
    div(classes: 'flex w-full flex-col items-center', [
      _refreshButton(() {}),
      const Gap.space8(),
      _box(),
    ]),
  ),
  'refresh-trigger/dont-gesture-only': () => _frame(_box()),
  'refresh-trigger/related-loading': () => const Loading(),
  'refresh-trigger/related-progress': () => _frame(const Progress(value: 0.6), width: CoreSpace.space160),
  'refresh-trigger/related-alert': () => _frame(
    const Alert(
      layout: CoreAlertLayout.inline,
      variant: CoreAlertVariant.destructive,
      title: page.demoFailureTitle,
    ),
  ),
};

Component _refreshTrigger(Map<String, String> props, String? label) => _RefreshPreview(props: props);

/// 속성 미리보기 · 플레이그라운드 — 실제 `RefreshTrigger` 하나와, `button` 이면
/// 그 위의 `refresh()` 버튼.
class _RefreshPreview extends StatefulComponent {
  const _RefreshPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_RefreshPreview> createState() => _RefreshPreviewState();
}

class _RefreshPreviewState extends State<_RefreshPreview> {
  final _refreshKey = GlobalStateKey<RefreshTriggerState>();

  @override
  Component build(BuildContext context) {
    final props = component.props;
    return _frame(
      div(classes: 'flex w-full flex-col items-center', [
        // 버튼 자리는 늘 두어, 버튼을 켜고 꺼도 아래 상자가 같은 자리에 남는다.
        div(classes: 'flex flex-col items-center', [
          if (page.demoShowsButton(props)) ...[
            _refreshButton(() => unawaited(_refreshKey.currentState?.refresh())),
            const Gap.space12(),
          ],
        ]),
        _box(key: _refreshKey, stage: page.demoStageOf(props), height: page.demoBoxHeight, texts: props),
      ]),
      width: page.demoBoxWidth,
    );
  }
}

/// 미리보기의 `onRefresh`.
Future<void> _wait() => Future<void>.delayed(page.demoRefreshWait);

/// 테두리를 두른 상자 속의 실제 `RefreshTrigger`. 높이를 줘야 안쪽 상자가
/// 스크롤 영역이 된다. [texts] 는 네 라벨의 속성 — 없는 라벨은 기본 문구.
Component _box({
  CoreRefreshStage stage = CoreRefreshStage.defaultStage,
  double height = page.demoCardHeight,
  Key? key,
  Map<String, String> texts = const {},
  CoreRefreshTriggerStyle? style,
  bool markContent = false,
}) => OutlinedContainer(
  classes: 'w-full',
  child: RefreshTrigger(
    key: key,
    css: Styles(raw: {'height': pinnedLengthCss(height)}),
    stage: stage,
    pullText: texts['pullText'],
    releaseText: texts['releaseText'],
    refreshingText: texts['refreshingText'],
    completedText: texts['completedText'],
    refreshTriggerStyle: style,
    onRefresh: _wait,
    child: _rows(markContent: markContent),
  ),
);

/// 감싼 목록.
Component _rows({bool markContent = false}) => div(
  attributes: markContent ? const {'data-docs-part': 'content'} : null,
  [
    for (final row in page.demoRows)
      div([Text(row)], classes: 'px-${CoreSpace.scale.space16} py-${CoreSpace.scale.space12}'),
  ],
);

Component _refreshButton(void Function() onPressed) => Button(
  variant: CoreButtonVariant.outline,
  size: CoreComponentSize.sm,
  onPressed: onPressed,
  child: const Text(page.demoRefreshButton),
);

/// 당기는 동안의 표시 그림 — 화살표 둘 사이의 라벨. [degrees] 는 화살표 회전.
Component _pullingPicture({required String label, required double degrees}) {
  Component arrow() => div(
    styles: Styles(raw: {'display': 'inline-flex', 'transform': 'rotate(${degrees}deg)'}),
    [
      Icon(
        LucideIcons.arrowDown,
        iconStyle: CoreIconStyle(color: CoreRefreshTriggerStyle.defaultIdleTextStyle.color),
      ),
    ],
  );

  return OutlinedContainer(
    role: CoreSurfaceRole.functional,
    containerStyle: page.demoPullingBoxStyle,
    child: div(
      styles: const Styles(raw: {'display': 'flex', 'align-items': 'center', 'white-space': 'nowrap'}),
      [
        arrow(),
        const Gap(gapStyle: CoreRefreshTriggerStyle.defaultIndicatorGapStyle),
        Text(label).labelLarge.onSurfaceVariant,
        const Gap(gapStyle: CoreRefreshTriggerStyle.defaultIndicatorGapStyle),
        arrow(),
      ],
    ),
  );
}

/// 상자의 폭 — 좁은 카드에서는 칸 폭으로 줄어든다.
Component _frame(Component child, {double width = page.demoCardWidth}) => div(
  styles: Styles(raw: {'width': 'min(100%, ${pinnedLengthCss(width)})'}),
  [child],
);

/// 구조 그림의 폭. 구조 블록은 장면을 담은 상자의 폭을 내용이 정해 `100%` 를 쓸 수
/// 없다. 좁은 화면에서는 양옆의 번호 자리를 남기고 줄어든다.
Component _anatomyFrame(Component child) => div(
  styles: Styles(
    raw: {
      'width': 'min(${pinnedLengthCss(page.demoAnatomyWidth)}, calc(100vw - ${pinnedLengthCss(CoreSpace.space128)}))',
    },
  ),
  [child],
);
