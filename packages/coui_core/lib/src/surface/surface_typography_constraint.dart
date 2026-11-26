import 'dart:math' as math;

import 'package:coui_core/src/typography/typography_scale.dart';
import 'package:meta/meta.dart';

/// The CSS weight range. Spec values, not tuning knobs.
const int _kMinWeight = 100;
const int _kMaxWeight = 900;

/// How a surface preset bends type without replacing the scale.
///
/// The third sibling of the colour and geometry constraints, and the same
/// shape: a preset states a requirement and the values come from whatever
/// the app authored. A style that shipped its own role table would be
/// re-authoring the type scale, which is the thing the axis avoids.
///
/// Only weight is expressible. Size and line height are the scale's own
/// composition — a style that changed those would be changing the type
/// scale rather than the surface, and the reader has no way to tell which
/// of the two decided a heading's size. Weight is the one property a
/// surface treatment legitimately has an opinion about, because it reads as
/// part of how heavy the surface itself feels.
@immutable
class CoreSurfaceTypographyConstraint {
  /// Creates a constraint. The default is identity.
  const CoreSurfaceTypographyConstraint({this.weightFloor})
    : assert(
        weightFloor == null ||
            (weightFloor >= _kMinWeight && weightFloor <= _kMaxWeight),
        'A CSS weight is 100..900.',
      );

  /// Lower bound on every role's weight.
  ///
  /// Null leaves the scale alone. A role already at or above the floor is
  /// untouched, so a style that wants "nothing thinner than semibold" does
  /// not flatten the difference between a heading and body text — the
  /// hierarchy the scale encodes survives, compressed at the light end.
  final int? weightFloor;

  /// Whether this constraint leaves type untouched.
  bool get isIdentity => weightFloor == null;

  /// Applies the floor to one weight.
  ///
  /// A null weight means the role states none and inherits, so there is
  /// nothing to raise — writing a weight here would be the style inventing
  /// a value the scale deliberately left open.
  int? weight(int? value) {
    if (weightFloor == null || value == null) return value;

    return math.max(value, weightFloor!);
  }

  /// Applies the floor across the whole scale.
  ///
  /// Returns [value] itself when identity, so the default surface costs
  /// nothing and nothing downstream sees a new instance to diff.
  CoreTypography apply(CoreTypography value) {
    if (isIdentity) return value;

    return value.map((s) => s.copyWith(fontWeight: weight(s.fontWeight)));
  }

  /// Creates a copy with modified values.
  CoreSurfaceTypographyConstraint copyWith({int? weightFloor}) =>
      .new(weightFloor: weightFloor ?? this.weightFloor);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreSurfaceTypographyConstraint &&
          weightFloor == other.weightFloor;

  @override
  int get hashCode => weightFloor.hashCode;
}
