/// RefreshTrigger 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="refresh-trigger/...">` · `<Card demo>` · `<Anatomy>` 가 읽는다.
/// 같은 이름의 Web 파일(`refresh_trigger_web.dart`)과 컴포넌트 · 속성 · 장면
/// 이름이 같아야 한다.
///
/// 장면의 상자는 실제 `RefreshTrigger` 다. `stage` 를 직접 지정해
/// `refreshing` · `completed` 를 보인다. `stage-pulling` · `stage-release` 만
/// 그림이다 — 직접 지정한 `pulling` 은 당긴 거리가 0 이라 표시가 영역 밖에
/// 남는다. 그림은 표시 상자인 실제 `OutlinedContainer` 에 `RefreshTrigger` 의
/// 기본값을 넘겨 그린다.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import 'refresh_trigger_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _refreshTrigger;

/// 장면 이름(`refresh-trigger/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'refresh-trigger/anatomy': () => _frame(
    _box(stage: CoreRefreshStage.refreshing, height: page.demoAnatomyHeight),
    width: page.demoAnatomyWidth,
  ),
  'refresh-trigger/stage-pulling': () => _pullingPicture(label: page.demoPullLabel, degrees: 0),
  'refresh-trigger/stage-release': () => _pullingPicture(label: page.demoReleaseLabel, degrees: -180),
  'refresh-trigger/stage-refreshing': () => _still(_frame(_box(stage: CoreRefreshStage.refreshing))),
  'refresh-trigger/stage-completed': () => _frame(_box(stage: CoreRefreshStage.completed)),
  'refresh-trigger/custom-style': () => _frame(
    _box(stage: CoreRefreshStage.refreshing, style: page.demoCustomStyle),
    width: page.demoBoxWidth,
  ),
  'refresh-trigger/do-report-failure': () => _frame(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Alert(
          variant: CoreAlertVariant.destructive,
          title: page.demoFailureTitle,
          description: page.demoFailureHint,
        ),
        const Gap.space8(),
        _box(),
      ],
    ),
  ),
  'refresh-trigger/do-button': () => _frame(
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _refreshButton(() {}),
        const Gap.space8(),
        _box(),
      ],
    ),
  ),
  'refresh-trigger/dont-gesture-only': () => _frame(_box()),
  'refresh-trigger/related-loading': () => _still(const Loading()),
  'refresh-trigger/related-progress': () => _frame(const Progress(value: 0.6), width: CoreSpace.space160),
  'refresh-trigger/related-alert': () => _frame(
    const Alert(
      layout: CoreAlertLayout.inline,
      variant: CoreAlertVariant.destructive,
      title: page.demoFailureTitle,
    ),
  ),
};

Widget _refreshTrigger(Map<String, String> props, String? label) => _RefreshPreview(props: props);

/// 속성 미리보기 · 플레이그라운드 — 실제 `RefreshTrigger` 하나와, `button` 이면
/// 그 위의 `refresh()` 버튼.
class _RefreshPreview extends StatefulWidget {
  const _RefreshPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_RefreshPreview> createState() => _RefreshPreviewState();
}

class _RefreshPreviewState extends State<_RefreshPreview> {
  var _refreshKey = GlobalKey<RefreshTriggerState>();

  @override
  void didUpdateWidget(_RefreshPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 같은 단계 동안에는 표시가 옛 글을 남긴다. 라벨이 바뀌면 새로 만든다.
    if (page.demoCustomTexts.keys.any((name) => oldWidget.props[name] != widget.props[name])) {
      _refreshKey = GlobalKey<RefreshTriggerState>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    return _frame(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 버튼 자리는 늘 두어, 버튼을 켜고 꺼도 아래 상자가 같은 자리에 남는다.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (page.demoShowsButton(props)) ...[
                _refreshButton(() => unawaited(_refreshKey.currentState?.refresh())),
                const Gap.space12(),
              ],
            ],
          ),
          _box(key: _refreshKey, stage: page.demoStageOf(props), height: page.demoBoxHeight, texts: props),
        ],
      ),
      width: page.demoBoxWidth,
    );
  }
}

/// 미리보기의 `onRefresh`.
Future<void> _wait() => Future<void>.delayed(page.demoRefreshWait);

/// 테두리를 두른 상자 속의 실제 `RefreshTrigger`. [texts] 는 네 라벨의 속성 —
/// 없는 라벨은 기본 문구.
Widget _box({
  CoreRefreshStage stage = CoreRefreshStage.defaultStage,
  double height = page.demoCardHeight,
  Key? key,
  Map<String, String> texts = const {},
  CoreRefreshTriggerStyle? style,
}) => OutlinedContainer(
  child: SizedBox(
    height: height,
    child: RefreshTrigger(
      key: key,
      stage: stage,
      pullText: texts['pullText'],
      releaseText: texts['releaseText'],
      refreshingText: texts['refreshingText'],
      completedText: texts['completedText'],
      refreshTriggerStyle: style,
      onRefresh: _wait,
      child: _rows(),
    ),
  ),
);

/// 감싼 목록. 문서 페이지의 스크롤과 위치를 나눠 쓰지 않도록 `primary` 를 끈다.
/// 끄면 짧은 목록은 당겨지지 않아, 코드의 `ListView` 처럼 늘 스크롤되게 한다.
Widget _rows() => ListView(
  primary: false,
  physics: const AlwaysScrollableScrollPhysics(),
  padding: EdgeInsets.zero,
  children: [
    for (final row in page.demoRows)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: CoreSpace.space16, vertical: CoreSpace.space12),
        child: Text(row),
      ),
  ],
);

Widget _refreshButton(VoidCallback onPressed) => Button(
  variant: CoreButtonVariant.outline,
  size: CoreComponentSize.sm,
  onPressed: onPressed,
  child: const Text(page.demoRefreshButton),
);

/// 당기는 동안의 표시 그림 — 화살표 둘 사이의 라벨. [degrees] 는 화살표 회전.
Widget _pullingPicture({required String label, required double degrees}) {
  Widget arrow() => Transform.rotate(
    angle: degrees * math.pi / 180,
    child: Icon(
      LucideIcons.arrowDown,
      iconStyle: CoreIconStyle(color: CoreRefreshTriggerStyle.defaultIdleTextStyle.color),
    ),
  );

  return OutlinedContainer(
    role: CoreSurfaceRole.functional,
    containerStyle: page.demoPullingBoxStyle,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        arrow(),
        const Gap(gapStyle: CoreRefreshTriggerStyle.defaultIndicatorGapStyle),
        Flexible(child: Text(label).labelLarge.onSurfaceVariant),
        const Gap(gapStyle: CoreRefreshTriggerStyle.defaultIndicatorGapStyle),
        arrow(),
      ],
    ),
  );
}

/// 카드의 스피너를 멈춘 그림. 계속 도는 애니메이션이 있으면 네이티브 앱의 카드
/// 검사(`pumpAndSettle`)가 끝나지 않는다.
Widget _still(Widget child) => TickerMode(enabled: false, child: child);

/// 상자의 폭 — 좁은 카드에서는 칸 폭으로 줄어든다.
Widget _frame(Widget child, {double width = page.demoCardWidth}) => SizedBox(width: width, child: child);
