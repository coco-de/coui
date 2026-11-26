import 'dart:ui'
    show DisplayFeature, DisplayFeatureState, DisplayFeatureType, Rect, Size;

import 'package:flutter/foundation.dart';

/// How far the hinge of a folding iPhone is open, as UIKit reports it
/// (`UIHinge.Status`).
enum FoldHingeStatus {
  /// No hinge was reported: the device has none, the OS or the SDK the app
  /// was built with is older than the hinge, or nothing has measured yet.
  unavailable,

  /// The device has a hinge and does not say how far it is open.
  unknown,

  /// Folded shut. The app is on the outer screen, which has no fold.
  closed,

  /// Open at an angle — held like a book, or stood on a table.
  partiallyOpen,

  /// Open as far as it goes: the inner screen lies flat.
  fullyOpen,
}

/// A strip of the Flutter view the system reserves across a fold
/// (`UIView.ReservedRegion` of kind `division`).
@immutable
class FoldDivision {
  /// A division at [bounds].
  const FoldDivision({required this.bounds, required this.active});

  /// Where it is, in the view's logical pixels. The system's frame, margins
  /// included: the strip content keeps out of.
  final Rect bounds;

  /// Whether it divides the view now. The system turns it on once the hinge
  /// has come to rest partly open, and off again when the device is laid
  /// flat; it keeps its frame either way.
  final bool active;

  @override
  bool operator ==(Object other) =>
      other is FoldDivision && other.bounds == bounds && other.active == active;

  @override
  int get hashCode => Object.hash(bounds, active);

  @override
  String toString() => 'FoldDivision($bounds, active: $active)';
}

/// What a platform that reports no fold to Flutter measured of one: the hinge
/// and the divisions across the view. What `FoldScopeHost` turns into display
/// features.
///
/// Today that platform is iOS. Flutter's embedder there hands Dart the safe
/// area and nothing about a fold, so the package's own plugin measures it
/// (`CoUIFoldPlugin`). Android needs none of this: its engine fills
/// `MediaQuery.displayFeatures` itself.
@immutable
class FoldReading {
  /// A reading of [status] and [divisions].
  const FoldReading({
    this.status = FoldHingeStatus.unavailable,
    this.divisions = const [],
  });

  /// Reads what the plugin sent. Anything it did not send in the expected
  /// shape reads as [none] — a reading that cannot be trusted is no fold,
  /// not a guess at one.
  factory FoldReading.fromMessage(Object? message) {
    if (message is! Map<Object?, Object?>) return none;
    final rawStatus = message['status'];
    final rawDivisions = message['divisions'];
    if (rawStatus is! String || rawDivisions is! List<Object?>) return none;
    final status = FoldHingeStatus.values
        .where((value) => value.name == rawStatus)
        .firstOrNull;
    if (status == null) return none;

    final divisions = <FoldDivision>[];
    for (final raw in rawDivisions) {
      if (raw is! Map<Object?, Object?>) return none;
      final left = raw['left'];
      final top = raw['top'];
      final width = raw['width'];
      final height = raw['height'];
      final active = raw['active'];
      if (left is! num ||
          top is! num ||
          width is! num ||
          height is! num ||
          active is! bool ||
          width < 0 ||
          height < 0) {
        return none;
      }
      divisions.add(
        FoldDivision(
          bounds: Rect.fromLTWH(
            left.toDouble(),
            top.toDouble(),
            width.toDouble(),
            height.toDouble(),
          ),
          active: active,
        ),
      );
    }

    return FoldReading(status: status, divisions: List.unmodifiable(divisions));
  }

  /// Nothing measured: no hinge, no division.
  static const FoldReading none = FoldReading();

  /// How far apart a division's ends may be from the viewport's edges and
  /// still count as reaching them. The system's frames are fractions of a
  /// point on the screens measured so far (951 × 669 with a fold from 455.5
  /// to 495.5); this absorbs the rounding, not a gap.
  static const double _edgeTolerance = 0.5;

  /// How far the hinge is open.
  final FoldHingeStatus status;

  /// The divisions across the view, active or not.
  final List<FoldDivision> divisions;

  /// The display features this reading puts on a viewport of [viewport]
  /// logical pixels — what Android's engine would have reported for the same
  /// device, so everything that reads `MediaQuery.displayFeatures` reads an
  /// iPhone the way it reads the rest:
  ///
  /// * partly open with the division active — a fold as wide as the strip the
  ///   system reserves, half opened. It splits the viewport;
  /// * lying flat — a fold with no width where the strip is centred, flat.
  ///   The screen reads as one surface, and the kind of device and its
  ///   posture can still be told;
  /// * partly open before the system has turned the division on, or a hinge
  ///   that does not say — the same line with no posture, so nothing splits
  ///   while the hinge is still moving. The system waits for the hinge to
  ///   rest for the same reason;
  /// * folded shut, or no hinge — nothing. Shut, the view is on the outer
  ///   screen.
  ///
  /// A division that does not run across the whole viewport is left out: one
  /// the window only reaches the edge of (two apps side by side meet at the
  /// fold) divides nothing in it.
  List<DisplayFeature> displayFeaturesFor(Size viewport) {
    if (status == FoldHingeStatus.unavailable ||
        status == FoldHingeStatus.closed) {
      return const [];
    }

    final features = <DisplayFeature>[];
    for (final division in divisions) {
      final across = _acrossViewport(division.bounds, viewport);
      if (across == null) continue;
      final halfOpened =
          status == FoldHingeStatus.partiallyOpen && division.active;
      features.add(
        DisplayFeature(
          bounds: halfOpened ? across : _centreLine(across),
          // A fold, not a hinge: the inner screen is one panel that bends.
          type: DisplayFeatureType.fold,
          state: halfOpened
              ? DisplayFeatureState.postureHalfOpened
              : status == FoldHingeStatus.fullyOpen
              ? DisplayFeatureState.postureFlat
              : DisplayFeatureState.unknown,
        ),
      );
    }

    return features;
  }

  /// [bounds] cut to [viewport] when it runs across the whole of it one way
  /// and lies inside it the other; null otherwise.
  static Rect? _acrossViewport(Rect bounds, Size viewport) {
    if (bounds.longestSide <= 0) return null;
    final downTheHeight =
        bounds.top <= _edgeTolerance &&
        bounds.bottom >= viewport.height - _edgeTolerance &&
        bounds.left >= 0 &&
        bounds.right <= viewport.width;
    if (downTheHeight) {
      return Rect.fromLTRB(bounds.left, 0, bounds.right, viewport.height);
    }
    final acrossTheWidth =
        bounds.left <= _edgeTolerance &&
        bounds.right >= viewport.width - _edgeTolerance &&
        bounds.top >= 0 &&
        bounds.bottom <= viewport.height;
    if (acrossTheWidth) {
      return Rect.fromLTRB(0, bounds.top, viewport.width, bounds.bottom);
    }

    return null;
  }

  /// The line down the middle of [strip], the way it runs.
  static Rect _centreLine(Rect strip) => strip.height >= strip.width
      ? Rect.fromLTWH(strip.center.dx, strip.top, 0, strip.height)
      : Rect.fromLTWH(strip.left, strip.center.dy, strip.width, 0);

  @override
  bool operator ==(Object other) =>
      other is FoldReading &&
      other.status == status &&
      listEquals(other.divisions, divisions);

  @override
  int get hashCode => Object.hash(status, Object.hashAll(divisions));

  @override
  String toString() => 'FoldReading(${status.name}, $divisions)';
}
