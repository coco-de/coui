part of 'navigation_bar.dart';

/// Flutter clock adapter; motion and deformation are shared with Web.
class _GlassNavigationMotion extends ChangeNotifier {
  _GlassNavigationMotion(TickerProvider vsync, double initialPosition)
    : _motion = CoreGlassNavigationMotion(initialPosition) {
    _ticker = vsync.createTicker(_handleTick);
  }

  final CoreGlassNavigationMotion _motion;
  late final Ticker _ticker;
  Duration? _lastTick;
  CoreGlassSpring get position => _motion.position;
  double get activation => _motion.activation;
  double get energy => _motion.energy;
  double get direction => _motion.direction;

  /// The scale the whole bar is drawn at — see
  /// `CoreGlassNavigationMotion.barScale`.
  double get barScale => _motion.barScale;

  /// The distance between two adjacent destinations' centres, in logical
  /// pixels — what turns the lens's speed in destinations into a speed on
  /// screen.
  ///
  /// [configure] states it from the track's build. A column's track cannot:
  /// its cells are sized by layout, so whoever lays out against the column
  /// first sets it here. Setting it wakes nothing — the value is read on the
  /// next tick.
  double get itemExtent => _motion.pixelsPerItem;
  set itemExtent(double value) => _motion.pixelsPerItem = value;

  void configure({required bool reduced, required double itemExtent}) {
    _motion.configure(reduced: reduced, itemExtent: itemExtent);
    if (reduced) {
      _ticker.stop();
      _lastTick = null;
    } else if (!_motion.isSettled) {
      _wake();
    }
  }

  void _wake() {
    if (!_motion.reducedMotion && !_ticker.isActive) {
      _lastTick = null;
      _ticker.start();
    }
  }

  void moveTo(double value, {required bool held}) {
    _motion.moveTo(value, held: held);
    _wake();
  }

  void release(double value) => moveTo(value, held: false);

  void _handleTick(Duration elapsed) {
    final previous = _lastTick ?? Duration.zero;
    _lastTick = elapsed;
    _motion.advance((elapsed - previous).inMicroseconds / 1000000);
    if (_motion.isSettled) {
      _ticker.stop();
      _lastTick = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

/// The whole bar's swell while its glass lens is up, handed from the track —
/// which owns the motion — to the capsule above it, which draws it.
///
/// The track writes it from the motion's clock or after a frame, never while
/// the tree is being built, so the capsule hears of it the way it would hear
/// of an animation.
class _GlassBarSwell extends ChangeNotifier {
  double _scale = 1;
  double _origin = .5;
  bool _disposed = false;

  /// The capsule as it is laid out, inside the transform: the box the track
  /// measures the lens against.
  final GlobalKey capsuleKey = GlobalKey(debugLabel: 'glass bar capsule');

  /// The scale the capsule is drawn at.
  double get scale => _scale;

  /// Where along the capsule it grows from, `0` to `1` from its left edge
  /// (a row) or its top edge (a column).
  double get origin => _origin;

  void update(double scale, double origin) {
    if (_disposed || (scale == _scale && origin == _origin)) return;
    _scale = scale;
    _origin = origin;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Draws the bar's capsule at the swell's scale, about the swell's point on
/// the capsule's middle line.
///
/// A transform, so the bar keeps its box: the swell paints past the room the
/// bar is laid out in, and nothing around it moves. At rest it is the
/// identity, which paints without a layer of its own.
class _GlassBarSwellTransform extends StatelessWidget {
  const _GlassBarSwellTransform({
    required this.swell,
    required this.axis,
    required this.child,
  });

  final _GlassBarSwell swell;

  /// The axis the destinations run along.
  final Axis axis;

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: swell,
    builder: (context, child) {
      final along = swell.origin * 2 - 1;

      return Transform.scale(
        scale: swell.scale,
        alignment: axis == .horizontal
            ? Alignment(along, 0)
            : Alignment(0, along),
        child: child,
      );
    },
    child: KeyedSubtree(key: swell.capsuleKey, child: child),
  );
}
