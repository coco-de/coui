import 'package:coui_flutter/src/page/page_transition_style.dart';
import 'package:coui_flutter/src/theme/theme.dart';
import 'package:coui_flutter/src/util/motion.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:material_ui/material_ui.dart' as m;
import 'package:flutter/widgets.dart';

/// CoUI 의 라우트 페이지 primitive — Navigator 2.0 `Page` 구현체.
///
/// 선언형 라우팅(go_router 등)에서 화면 하나를 표현한다. 소비처가 material 의
/// `MaterialPage` 를 이름으로 참조하지 않고 CoUI API 만으로 페이지를 선언할 수
/// 있게 하는 것이 목적이다.
///
/// 이름이 `Page` 가 아닌 이유: 배럴이 `widgets.dart` 를 broad re-export 하므로
/// bare `Page` 는 Flutter `Page<T>` 와 `ambiguous_export` 로 충돌한다. 시맨틱
/// 대안명 규칙(`Container`→`Box`, `Stack`→`Stacks`)을 따라 `RoutePage` 로 둔다.
///
/// 새 화면은 플랫폼에 따라 다르게 들어온다:
///
/// - **iOS** — 옆에서 밀려 들어오고, 화면 가장자리를 쓸어 뒤로 간다.
/// - **Android** — 예측 뒤로 가기 제스처를 따른다.
/// - **그 밖(데스크톱 · 웹)** — CoUI 의 화면 전환: 살짝 올라오며 나타나고,
///   닫히면 내려가며 사라진다. 시간 · 곡선 · 거리는 `CorePageTransitionStyle`
///   이고 앱 전체는 `CoreComponentTheme.pageTransition` 으로 바꾼다.
///
/// iOS · Android 가 플랫폼 전환을 쓰는 이유는 뒤로 가기 제스처가 그 전환에 묶여
/// 있기 때문이다. `CorePageTransitionStyle.usePlatformDurations`로 전환 시간을
/// 조정해도 제스처를 쓸 수 있다. 동작 줄이기를 켜면 화면이 바로 바뀐다.
///
/// go_router 는 앱이 Material · Cupertino 앱이 아니면 `GoRoute(builder:)` 로 만든
/// 화면에 전환을 붙이지 않는다. `CoUIApp` 에서 새 화면에 모션을 붙이려면
/// `pageBuilder` 에서 이 페이지를 돌려준다:
///
/// ```dart
/// GoRoute(
///   path: 'detail',
///   pageBuilder: (context, state) =>
///       RoutePage(key: state.pageKey, child: const DetailScreen()),
/// )
/// ```
final class RoutePage<T> extends Page<T> {
  /// 라우트 페이지를 만든다.
  const RoutePage({
    required this.child,
    this.maintainState = true,
    this.fullscreenDialog = false,
    this.allowSnapshotting = true,
    super.key,
    super.canPop,
    super.onPopInvoked,
    super.name,
    super.arguments,
    super.restorationId,
  });

  /// 이 페이지가 만드는 [Route] 에 표시할 콘텐츠.
  final Widget child;

  /// {@macro flutter.widgets.ModalRoute.maintainState}
  final bool maintainState;

  /// {@macro flutter.widgets.PageRoute.fullscreenDialog}
  final bool fullscreenDialog;

  /// {@macro flutter.widgets.TransitionRoute.allowSnapshotting}
  final bool allowSnapshotting;

  @override
  Route<T> createRoute(BuildContext context) {
    return _RoutePageRoute(page: this, allowSnapshotting: allowSnapshotting);
  }
}

/// 명령형 라우팅용 CoUI 라우트 — `Navigator.push` 에 직접 넣는다.
///
/// 선언형 라우팅(go_router 등)에는 [RoutePage] 를 쓴다. 이 클래스는 라우트를
/// 직접 만들어 밀어 넣는 명령형 경로를 위한 것으로, material 의
/// `MaterialPageRoute` 와 파라미터 표면이 동일해 1:1 로 치환된다. `CoUIApp` 의
/// 이름 붙은 라우트(`routes` · `home`)도 이 라우트로 열린다.
///
/// ```dart
/// Navigator.of(context).push(
///   RoutePageRoute<void>(builder: (context) => const DetailPage()),
/// );
/// ```
///
/// 전환은 [RoutePage] 와 같다 — iOS · Android 는 플랫폼 전환과 뒤로 가기
/// 제스처, 그 밖은 CoUI 의 화면 전환.
class RoutePageRoute<T> extends PageRoute<T> with _RouteTransitionMixin<T> {
  /// 명령형 라우트를 만든다. 콘텐츠는 [builder] 가 정의한다.
  RoutePageRoute({
    required this.builder,
    super.settings,
    super.requestFocus,
    this.maintainState = true,
    super.fullscreenDialog,
    super.allowSnapshotting = true,
    super.barrierDismissible = false,
    super.traversalEdgeBehavior,
    super.directionalTraversalEdgeBehavior,
  }) {
    assert(opaque, 'RoutePageRoute 는 불투명(opaque) 라우트를 전제한다.');
  }

  /// 라우트의 주 콘텐츠를 만든다.
  final WidgetBuilder builder;

  @override
  final bool maintainState;

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}

/// [RoutePage] 가 만드는 라우트.
class _RoutePageRoute<T> extends PageRoute<T> with _RouteTransitionMixin<T> {
  _RoutePageRoute({required RoutePage<T> page, super.allowSnapshotting})
    : super(settings: page) {
    assert(opaque, 'RoutePage 는 불투명(opaque) 라우트를 전제한다.');
  }

  RoutePage<T> get _page => settings as RoutePage<T>;

  @override
  Widget buildContent(BuildContext context) => _page.child;

  @override
  bool get maintainState => _page.maintainState;

  @override
  bool get fullscreenDialog => _page.fullscreenDialog;

  @override
  String get debugLabel => '${super.debugLabel}(${_page.name})';
}

/// The page transition of [RoutePage] and [RoutePageRoute].
///
/// Picks the transition from the platform of the CoUI [Theme] above the
/// navigator (`defaultTargetPlatform` without one): Flutter's own on iOS
/// and Android, where it carries the back gesture, and CoUI's
/// fade-and-rise everywhere else. Every one is a widget-layer
/// [PageTransitionsBuilder], so the choice is CoUI's, not a Material
/// theme's — an app's `materialTheme` does not reach it.
///
/// A reduced-motion request makes every page transition instant.
mixin _RouteTransitionMixin<T> on PageRoute<T> {
  /// Builds the primary contents of the route.
  @protected
  Widget buildContent(BuildContext context);

  @override
  Duration get transitionDuration => _timing(navigator!.context).enter;

  @override
  Duration get reverseTransitionDuration => _timing(navigator!.context).exit;

  ({Duration enter, Duration exit}) _timing(BuildContext context) {
    final builder = _builderFor(context);
    final style = Theme.maybeOf(
      context,
    )?.coreComponentTheme?.pageTransition?.style;
    if (builder is _FadeRisePageTransitionsBuilder ||
        style?.usePlatformDurations == false) {
      final resolved = resolvePageTransition(context);

      return (enter: resolved.enterDuration, exit: resolved.exitDuration);
    }
    if (resolveReducedMotion(context)) {
      return (enter: Duration.zero, exit: Duration.zero);
    }

    return (
      enter: builder.transitionDuration,
      exit: builder.reverseTransitionDuration,
    );
  }

  // The durations make the controller once, when the route is installed.
  // A theme or a reduced-motion request that changes afterwards reaches the
  // next push or pop through these, the way Material's routes refresh them.
  @override
  TickerFuture didPush() {
    controller?.duration = transitionDuration;

    return super.didPush();
  }

  @override
  bool didPop(T? result) {
    controller?.reverseDuration = reverseTransitionDuration;

    return super.didPop(result);
  }

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _delegatedTransition;

  static Widget? _delegatedTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    bool allowSnapshotting,
    Widget? child,
  ) {
    return _builderFor(context).delegatedTransition?.call(
      context,
      animation,
      secondaryAnimation,
      allowSnapshotting,
      child,
    );
  }

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    // No outgoing motion under a fullscreen dialog. Otherwise this route
    // moves with the next one when that one is a CoUI page, or when it
    // hands down a transition of its own to sync with.
    final nextRouteIsNotFullscreen =
        (nextRoute is! PageRoute<T>) || !nextRoute.fullscreenDialog;
    final nextRouteHasDelegatedTransition =
        nextRoute is ModalRoute<T> && nextRoute.delegatedTransition != null;

    return nextRouteIsNotFullscreen &&
        ((nextRoute is _RouteTransitionMixin) ||
            nextRouteHasDelegatedTransition);
  }

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> previousRoute) {
    return previousRoute is PageRoute && !fullscreenDialog;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: buildContent(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _builderFor(
      context,
    ).buildTransitions<T>(this, context, animation, secondaryAnimation, child);
  }
}

/// The page transition for the platform of the CoUI [Theme] at [context].
///
/// On iOS and Android it is Flutter's own default for that platform — the
/// transition the back gesture is part of. Everywhere else it is CoUI's.
PageTransitionsBuilder _builderFor(BuildContext context) {
  final platform = Theme.maybeOf(context)?.platform ?? defaultTargetPlatform;

  return switch (platform) {
    .iOS || .android => _kPlatformTransitions.builders[platform]!,
    _ => const _FadeRisePageTransitionsBuilder(),
  };
}

/// Flutter's per-platform page transitions, read for the two platforms
/// whose transition carries a back gesture.
const _kPlatformTransitions = m.PageTransitionsTheme();

/// CoUI's page transition: the arriving screen fades in while it rises by
/// the style's distance, and a closed screen sinks while it fades out. The
/// screen underneath stays where it is.
class _FadeRisePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeRisePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _FadeRiseTransition(
      animation: animation,
      resolved: resolvePageTransition(context),
      child: child,
    );
  }
}

class _FadeRiseTransition extends StatefulWidget {
  const _FadeRiseTransition({
    required this.animation,
    required this.resolved,
    required this.child,
  });

  final Animation<double> animation;
  final ResolvedPageTransition resolved;
  final Widget child;

  @override
  State<_FadeRiseTransition> createState() => _FadeRiseTransitionState();
}

class _FadeRiseTransitionState extends State<_FadeRiseTransition> {
  late CurvedAnimation _progress;

  Curve get _enterCurve => widget.resolved.enterCurve;

  // A route plays its departure as its animation running backwards. The
  // exit curve states the departure in real time (start at rest, speed
  // up), so the reverse curve is its flip.
  Curve get _exitCurve => widget.resolved.exitCurve.flipped;

  @override
  void initState() {
    super.initState();
    _progress = CurvedAnimation(
      parent: widget.animation,
      curve: _enterCurve,
      reverseCurve: _exitCurve,
    );
  }

  @override
  void didUpdateWidget(covariant _FadeRiseTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _progress.dispose();
      _progress = CurvedAnimation(
        parent: widget.animation,
        curve: _enterCurve,
        reverseCurve: _exitCurve,
      );
    } else {
      _progress
        ..curve = _enterCurve
        ..reverseCurve = _exitCurve;
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final distance = widget.resolved.slideDistance;

    return FadeTransition(
      opacity: _progress,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - _progress.value) * distance),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
