import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/components/layout/overflow_marquee/overflow_marquee_style.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Unified marquee-style scrolling wrapper for CoUI Flutter.
///
/// Content that fits the bounding box renders statically; content that
/// overflows scrolls along [direction] with optional edge fades. Mirrors Web
/// `OverflowMarquee` — same parameter names and visual outcome.
///
/// Per Epic #1302 dimensional / timing chrome overrides flow through
/// the single [overflowMarqueeStyle] slot. Semantic enums
/// ([direction], [curve]) and behavioural boolean ([pauseOnHover])
/// stay flat on the widget.
class OverflowMarquee extends StatefulWidget
    implements CoreOverflowMarqueeContract<Widget> {
  /// Creates a [OverflowMarquee].
  const OverflowMarquee({
    required this.child,
    super.key,
    this.direction = .horizontal,
    this.curve,
    this.pauseOnHover = false,
    this.overflowMarqueeStyle,
  });

  @override
  final Widget child;

  @override
  final CoreAxis direction;

  @override
  final CoreMarqueeCurve? curve;

  @override
  final bool pauseOnHover;

  @override
  final CoreOverflowMarqueeStyle? overflowMarqueeStyle;

  /// Returns a copy of this [OverflowMarquee] with the given fields
  /// replaced. All fields default to this instance's current value when
  /// omitted.
  OverflowMarquee copyWith({
    Key? key,
    CoreAxis? direction,
    CoreMarqueeCurve? curve,
    bool? pauseOnHover,
    CoreOverflowMarqueeStyle? overflowMarqueeStyle,
    Widget? child,
  }) {
    return OverflowMarquee(
      key: key ?? this.key,
      direction: direction ?? this.direction,
      curve: curve ?? this.curve,
      pauseOnHover: pauseOnHover ?? this.pauseOnHover,
      overflowMarqueeStyle: overflowMarqueeStyle ?? this.overflowMarqueeStyle,
      child: child ?? this.child,
    );
  }

  @override
  State<OverflowMarquee> createState() => _OverflowMarqueeState();
}

/// Chain sugar for merging a [CoreOverflowMarqueeStyle] patch into
/// [OverflowMarquee.overflowMarqueeStyle] without hand-reconstructing
/// every field. Mirrors the Web `OverflowMarquee.withStyle` extension so
/// both platforms read identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreOverflowMarqueeStyle.merge` right-side-wins semantics).
extension OverflowMarqueeStyleChain on OverflowMarquee {
  /// Returns a copy of this [OverflowMarquee] with [patch] merged into
  /// [overflowMarqueeStyle] (patch fields win on conflict).
  OverflowMarquee withStyle(CoreOverflowMarqueeStyle patch) => copyWith(
    overflowMarqueeStyle:
        (overflowMarqueeStyle ?? const CoreOverflowMarqueeStyle()).merge(patch),
  );
}

class _OverflowMarqueeState extends State<OverflowMarquee>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  /// Elapsed time consumed by the animation so far, ignoring paused
  /// periods. Accumulates deltas from the ticker each frame so that
  /// hover-pause resumes from where it left off — which is what users
  /// expect from `pauseOnHover` ("stop so I can read it, then keep
  /// going"). `Ticker.muted` would keep the clock running in the
  /// background and jump ahead on resume, so we skip it.
  Duration _accumulated = .zero;
  Duration _lastTickElapsed = .zero;
  bool _paused = false;

  /// Anchors the layout render object so ticks can push [_accumulated]
  /// straight into it — a per-frame `setState` rebuilt the whole child
  /// subtree every tick, which (under the docs preview's size-notifier
  /// wrapper) left a just-swapped child painted after `dropChild` and
  /// tripped the debug-web render assert ('not visited by
  /// visitChildren') every frame, blanking the marquee.
  final GlobalKey _layoutKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_handleTick);
    unawaited(_ticker.start());
  }

  void _handleTick(Duration elapsed) {
    if (!mounted) return;
    final delta = elapsed - _lastTickElapsed;
    _lastTickElapsed = elapsed;
    if (_paused) return;
    _accumulated += delta;
    final renderObject = _layoutKey.currentContext?.findRenderObject();
    if (renderObject is _RenderOverflowMarqueeLayout) {
      renderObject.elapsed = _accumulated;
      renderObject.markNeedsPaint();
    }
  }

  void _handlePause() {
    _paused = true;
  }

  void _handleResume() {
    _paused = false;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final resolved = resolveOverflowMarquee(
      context,
      direction: widget.direction,
      curve: widget.curve,
      pauseOnHover: widget.pauseOnHover,
      overflowMarqueeStyle: widget.overflowMarqueeStyle,
    );

    Widget content = ClipRect(
      child: _OverflowMarqueeLayout(
        key: _layoutKey,
        direction: resolved.direction,
        duration: resolved.duration,
        delayDuration: resolved.delayDuration,
        step: resolved.step,
        fadePortion: resolved.fadePortion,
        curve: resolved.curve,
        elapsed: _accumulated,
        textDirection: textDirection,
        ticker: _ticker,
        child: widget.child,
      ),
    );

    if (resolved.pauseOnHover) {
      content = MouseRegion(
        onEnter: (_) => _handlePause(),
        onExit: (_) => _handleResume(),
        child: content,
      );
    }
    return content;
  }
}

class _OverflowMarqueeLayout extends SingleChildRenderObjectWidget {
  const _OverflowMarqueeLayout({
    super.key,
    required super.child,
    required this.direction,
    required this.duration,
    required this.delayDuration,
    required this.step,
    required this.fadePortion,
    required this.curve,
    required this.elapsed,
    required this.textDirection,
    required this.ticker,
  });

  final CoreAxis direction;
  final Duration duration;
  final Duration delayDuration;
  final double step;
  final double fadePortion;
  final Curve curve;
  final Duration elapsed;
  final TextDirection textDirection;
  final Ticker ticker;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderOverflowMarqueeLayout(
      direction: direction,
      duration: duration,
      delayDuration: delayDuration,
      step: step,
      fadePortion: fadePortion,
      curve: curve,
      elapsed: elapsed,
      textDirection: textDirection,
      ticker: ticker,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderOverflowMarqueeLayout renderObject,
  ) {
    var changed = false;
    if (renderObject.direction != direction) {
      renderObject.direction = direction;
      changed = true;
    }
    if (renderObject.duration != duration) {
      renderObject.duration = duration;
      changed = true;
    }
    if (renderObject.delayDuration != delayDuration) {
      renderObject.delayDuration = delayDuration;
      changed = true;
    }
    if (renderObject.step != step) {
      renderObject.step = step;
      changed = true;
    }
    if (renderObject.fadePortion != fadePortion) {
      renderObject.fadePortion = fadePortion;
      changed = true;
    }
    if (renderObject.curve != curve) {
      renderObject.curve = curve;
      changed = true;
    }
    if (renderObject.elapsed != elapsed) {
      // 스크롤 진행은 paint 에서 계산한다 — elapsed 만 바뀐 프레임은
      // 레이아웃 불변이므로 paint 만 무효화. (매 프레임 markNeedsLayout
      // 은 프리뷰의 크기 알림 래퍼와 프레임 순서가 꼬여 디버그 웹
      // 빌드에서 'not visited by visitChildren' 렌더 assert 를 매
      // 프레임 유발 — 마퀴가 통째로 빈 화면이 됐다. 성능상으로도
      // 불변 레이아웃의 재계산 낭비 제거.)
      renderObject.elapsed = elapsed;
      renderObject.markNeedsPaint();
    }
    if (renderObject.textDirection != textDirection) {
      renderObject.textDirection = textDirection;
      changed = true;
    }
    if (renderObject.ticker != ticker) {
      renderObject.ticker = ticker;
      changed = true;
    }
    if (changed) {
      renderObject.markNeedsLayout();
    }
  }
}

class _OverflowMarqueeParentData extends BoxParentData {
  double? sizeDiff;
}

// 단일-자식 렌더(RenderShiftedBox)다 — ContainerRenderObjectMixin
// (다중-자식)을 섞으면 그 mixin 의 visitChildren 이 (비어 있는)
// 자식 연결 리스트만 순회해 실제 `child` 가 영원히 방문되지 않는다.
// 그러면 flushCompositingBits 가 자식으로 하강하지 못해, 합성이
// 필요한 자식(RepaintBoundary 류)이나 프리뷰 래퍼 아래에서
// 'not visited by visitChildren' 렌더 assert 가 매 프레임 터져
// 마퀴가 통째로 빈 화면이 됐다.
class _RenderOverflowMarqueeLayout extends RenderShiftedBox {
  _RenderOverflowMarqueeLayout({
    required this.direction,
    required this.duration,
    required this.delayDuration,
    required this.step,
    required this.fadePortion,
    required this.curve,
    required this.elapsed,
    required this.textDirection,
    required this.ticker,
  }) : super(null);

  CoreAxis direction;
  Duration duration;
  Duration delayDuration;
  double step;
  double fadePortion;
  Curve curve;
  Duration elapsed;
  TextDirection textDirection;
  Ticker ticker;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _OverflowMarqueeParentData) {
      child.parentData = _OverflowMarqueeParentData();
    }
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return direction == .horizontal
        ? super.computeMaxIntrinsicHeight(.infinity)
        : super.computeMaxIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return direction == .vertical
        ? super.computeMaxIntrinsicWidth(.infinity)
        : super.computeMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return direction == .horizontal
        ? super.computeMinIntrinsicHeight(.infinity)
        : super.computeMinIntrinsicHeight(width);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return direction == .vertical
        ? super.computeMinIntrinsicWidth(.infinity)
        : super.computeMinIntrinsicWidth(height);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final loosened = direction == .horizontal
        ? constraints.copyWith(maxWidth: .infinity)
        : constraints.copyWith(maxHeight: .infinity);
    final target = child;
    return target != null ? target.getDryLayout(loosened) : loosened.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final target = child;
    if (target == null) {
      layer = null;
      return;
    }
    final parentData = target.parentData! as _OverflowMarqueeParentData;
    final sizeDiff = parentData.sizeDiff ?? 0;
    final progress = offsetProgress;
    // 가장자리 페이드는 합성 레이어(ShaderMaskLayer)로 그린다 —
    // 캔버스 saveLayer + dstIn 은 자체 레이어를 가진 자식
    // (RepaintBoundary 류)과 혼합될 수 없다. 이 레이어 방식이
    // 동작하는 전제(visitChildren 이 자식을 방문해 합성 비트가
    // 정리되는 것)는 위 클래스 주석의 mixin 제거가 보장한다.
    final maskLayer = ShaderMaskLayer()
      ..shader = _createAlphaShader(
        fadeStart: progress > 0 && sizeDiff != 0,
        fadeEnd: progress < 1 && sizeDiff != 0,
        bounds: Offset.zero & size,
      )
      ..maskRect = (offset & size).inflate(1)
      ..blendMode = .modulate;
    layer = maskLayer;
    context.pushLayer(maskLayer, _paintChild, offset);
  }

  @override
  void performLayout() {
    final target = child;
    if (target == null) {
      size = constraints.biggest;
      if (ticker.isActive) ticker.stop();
      return;
    }
    final looseConstraints = direction == .horizontal
        ? constraints.copyWith(maxWidth: .infinity)
        : constraints.copyWith(maxHeight: .infinity);
    target.layout(looseConstraints, parentUsesSize: true);
    size = constraints.constrain(target.size);
    final axisDiff = direction == .horizontal
        ? target.size.width - size.width
        : target.size.height - size.height;
    final sizeDiff = axisDiff > 0 ? axisDiff : 0.0;
    if (sizeDiff > 0 && size.width > 0 && size.height > 0) {
      if (!ticker.isActive) unawaited(ticker.start());
    } else if (ticker.isActive) {
      ticker.stop();
    }
    final parentData = target.parentData! as _OverflowMarqueeParentData;
    parentData.sizeDiff = sizeDiff;
    // 스크롤 오프셋은 layout 산물이 아니라 paint/히트테스트에서
    // `_scrollOffset` 으로 계산한다 — layout 은 크기 관계(sizeDiff)만
    // 소유해 tick 마다 다시 돌 필요가 없다.
    parentData.offset = .zero;
  }

  /// Paint-time scroll offset of the child — derived from the current
  /// [elapsed] progress over the layout-owned [sizeDiff].
  Offset get _scrollOffset {
    final diff = sizeDiff ?? 0;
    if (diff <= 0) return .zero;
    final progress = offsetProgress;
    return direction == .horizontal
        ? Offset(-diff * progress, 0)
        : Offset(0, -diff * progress);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    // 스크롤 오프셋이 paint 소유라 지오메트리 변환에도 반영한다 —
    // localToGlobal / semantics / 히트가 화면과 일치.
    final parentData = child.parentData! as _OverflowMarqueeParentData;
    final off = parentData.offset + _scrollOffset;
    transform.translateByDouble(off.dx, off.dy, 0, 1);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final target = child;
    if (target == null) return false;
    final parentData = target.parentData! as _OverflowMarqueeParentData;
    return result.addWithPaintOffset(
      offset: parentData.offset + _scrollOffset,
      position: position,
      hitTest: (result, transformed) =>
          target.hitTest(result, position: transformed),
    );
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  double get offsetProgress {
    final diff = sizeDiff ?? 0;
    if (diff <= 0) return 0;
    final durationMicros = duration.inMicroseconds * (diff / step);
    final delayMicros = delayDuration.inMicroseconds;
    final cycleMicros = delayMicros + durationMicros;
    final overallMicros = cycleMicros * 2;
    var elapsedMicros = elapsed.inMicroseconds.toDouble();
    elapsedMicros %= overallMicros;
    final reverse = elapsedMicros > cycleMicros;
    final cycleElapsed = elapsedMicros % cycleMicros;
    if (cycleElapsed < delayMicros) {
      return reverse ? 1 : 0;
    }
    if (cycleElapsed < cycleMicros) {
      final t = (cycleElapsed - delayMicros) / durationMicros;
      final eased = curve.transform(t);
      return reverse ? 1 - eased : eased;
    }
    return reverse ? 0 : 1;
  }

  double? get sizeDiff {
    final parentData = child?.parentData as _OverflowMarqueeParentData?;
    return parentData?.sizeDiff;
  }

  double get fadeStartProgress {
    if (child == null) return 0;
    final diff = sizeDiff ?? 0;
    if (diff <= 0 || fadePortion <= 0) return 0;
    final progressed = diff * offsetProgress;
    return (progressed / fadePortion).clamp(0, 1).toDouble();
  }

  double get fadeEndProgress {
    if (child == null) return 0;
    final diff = sizeDiff ?? 0;
    if (diff <= 0 || fadePortion <= 0) return 0;
    final progressed = diff * (1 - offsetProgress);
    return (progressed / fadePortion).clamp(0, 1).toDouble();
  }

  Shader _createAlphaShader({
    required bool fadeStart,
    required bool fadeEnd,
    required Rect bounds,
  }) {
    if (fadePortion <= 0) {
      return LinearGradient(
        colors: const [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
      ).createShader(bounds);
    }
    final portion = direction == .horizontal
        ? fadePortion / bounds.width
        : fadePortion / bounds.height;
    // `0xFFFFFFFF` here is *not* a design color — it's an alpha-control
    // sentinel. `ShaderMask` with `blendMode.modulate` multiplies the
    // shader's alpha against the child's pixels; the RGB channels are
    // ignored. Using a theme token would imply the colour has visual
    // meaning (it doesn't) and would change behaviour across themes
    // (it shouldn't). Same rationale as coui_web's
    // `rgb(0 0 0 / var(--co-om-fade-*-alpha))` stops.
    final colors = <Color>[];
    final stops = <double>[];
    if (fadeStart) {
      final start = fadeStartProgress;
      colors.addAll([
        const Color(0xFFFFFFFF).withValues(alpha: 1 - start),
        const Color(0xFFFFFFFF),
      ]);
      stops.addAll([0.0, portion]);
    } else {
      colors.add(const Color(0xFFFFFFFF));
      stops.add(0.0);
    }
    if (fadeEnd) {
      final end = fadeEndProgress;
      colors.addAll([
        const Color(0xFFFFFFFF),
        const Color(0xFFFFFFFF).withValues(alpha: 1 - end),
      ]);
      stops.addAll([1.0 - portion, 1.0]);
    } else {
      colors.add(const Color(0xFFFFFFFF));
      stops.add(1.0);
    }
    AlignmentGeometry begin;
    AlignmentGeometry end;
    if (direction == .horizontal) {
      begin = AlignmentDirectional.centerStart.resolve(textDirection);
      end = AlignmentDirectional.centerEnd.resolve(textDirection);
    } else {
      begin = Alignment.topCenter;
      end = Alignment.bottomCenter;
    }
    return LinearGradient(
      begin: begin,
      end: end,
      colors: colors,
      stops: stops,
    ).createShader(bounds);
  }

  void _paintChild(PaintingContext context, Offset offset) {
    final target = child;
    if (target == null) return;
    final parentData = target.parentData! as _OverflowMarqueeParentData;
    context.paintChild(target, offset + parentData.offset + _scrollOffset);
  }
}
