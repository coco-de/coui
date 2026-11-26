// The three container-bordered inputs — ChipInput, ObjectInput, ItemPicker —
// draw their own box, so hover has to ride that box's border: the inline
// `TextField`s inside are chromeless, and none of the three states a wash.
// Each declares `hoverBorderColor` (the override) and
// `defaultHoverBorderColor` (the named default both platforms read), and the
// hover step goes to `outline`, one step past the resting `outline-variant`.
//
// Two failures are pinned, neither of which is "wrong colour":
//  * the field exists on the style but is left out of `merge` / `copyWith` /
//    `==` / `hashCode`, so a theme or per-instance override is silently
//    dropped or compares equal to the style it should replace;
//  * the hover border lands on (or within rounding of) the resting one,
//    which is the literal absence of a state.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const CoreColor _outline = CoreColor.token(CoreColors.outline);
const CoreColor _outlineVariant = CoreColor.token(CoreColors.outlineVariant);

/// A colour that is neither the default hover nor the default rest, so an
/// override can be told apart from either.
const CoreColor _custom = CoreColor.token(CoreColors.primary);
const CoreColor _otherCustom = CoreColor.token(CoreColors.error);

/// Below this a state is invisible up to rounding, which is the same bug as
/// being exactly invisible. Matches the floor `text_area_style_test.dart` and
/// `text_field_state_change_perceptibility_test.dart` use.
const double _perceptibleFloor = 1.02;

Map<String, CoreColorScheme> _schemes() {
  const source = CouiColorPresets.source;
  return {
    'light': source.light(),
    'dark': source.dark(),
    'high-contrast light': source.highContrastLight(),
    'high-contrast dark': source.highContrastDark(),
  };
}

int _argb(CoreColorScheme scheme, CoreColor color) =>
    scheme.resolve(color).argb | 0xFF000000;

/// One component's slice of the hover-border contract, so the same
/// assertions run against all three styles.
class _Subject {
  const _Subject({
    required this.name,
    required this.defaultHover,
    required this.defaultRest,
    required this.empty,
    required this.withHover,
    required this.hoverOf,
    required this.withRest,
  });

  final String name;
  final CoreColor defaultHover;
  final CoreColor defaultRest;
  final Object empty;

  /// A style whose only set field is `hoverBorderColor`.
  final Object Function(CoreColor hover) withHover;

  /// Reads `hoverBorderColor` back off a style.
  final CoreColor? Function(Object style) hoverOf;

  /// A style whose only set field is `borderColor` (the resting border) — a
  /// field the hover step must not be confused with.
  final Object Function(CoreColor rest) withRest;
}

final List<_Subject> _subjects = [
  _Subject(
    name: 'ChipInput',
    defaultHover: CoreChipInputStyle.defaultHoverBorderColor,
    defaultRest: CoreChipInputStyle.defaultBorderColor,
    empty: const CoreChipInputStyle(),
    withHover: (c) => CoreChipInputStyle(hoverBorderColor: c),
    hoverOf: (s) => (s as CoreChipInputStyle).hoverBorderColor,
    withRest: (c) => CoreChipInputStyle(borderColor: c),
  ),
  _Subject(
    name: 'ObjectInput',
    defaultHover: CoreObjectInputStyle.defaultHoverBorderColor,
    defaultRest: CoreObjectInputStyle.defaultBorderColor,
    empty: const CoreObjectInputStyle(),
    withHover: (c) => CoreObjectInputStyle(hoverBorderColor: c),
    hoverOf: (s) => (s as CoreObjectInputStyle).hoverBorderColor,
    withRest: (c) => CoreObjectInputStyle(borderColor: c),
  ),
  _Subject(
    name: 'ItemPicker',
    defaultHover: CoreItemPickerStyle.defaultHoverBorderColor,
    defaultRest: CoreItemPickerStyle.defaultBorderColor,
    empty: const CoreItemPickerStyle(),
    withHover: (c) => CoreItemPickerStyle(hoverBorderColor: c),
    hoverOf: (s) => (s as CoreItemPickerStyle).hoverBorderColor,
    withRest: (c) => CoreItemPickerStyle(borderColor: c),
  ),
];

/// `merge` through the style's own typed method — each `CoreXxxStyle.merge`
/// takes its own type, so the dispatch has to be per-subject.
Object _merge(Object base, Object other) => switch (base) {
  CoreChipInputStyle() => base.merge(other as CoreChipInputStyle),
  CoreObjectInputStyle() => base.merge(other as CoreObjectInputStyle),
  CoreItemPickerStyle() => base.merge(other as CoreItemPickerStyle),
  _ => throw ArgumentError('unsupported style ${base.runtimeType}'),
};

Object _copyWithHover(Object base, CoreColor hover) => switch (base) {
  CoreChipInputStyle() => base.copyWith(hoverBorderColor: hover),
  CoreObjectInputStyle() => base.copyWith(hoverBorderColor: hover),
  CoreItemPickerStyle() => base.copyWith(hoverBorderColor: hover),
  _ => throw ArgumentError('unsupported style ${base.runtimeType}'),
};

void main() {
  for (final subject in _subjects) {
    group('${subject.name} hover border', () {
      test('the named default is outline — one step past the resting '
          'outline-variant', () {
        expect(subject.defaultHover, _outline);
        expect(subject.defaultRest, _outlineVariant);
        expect(subject.defaultHover, isNot(subject.defaultRest));
      });

      test('both defaults are design-system tokens, so Web can ride a '
          'class', () {
        expect(subject.defaultHover.token, isNotNull);
        expect(subject.defaultRest.token, isNotNull);
      });

      test('the default hover border is perceptibly different from the '
          'resting one, in every mode', () {
        _schemes().forEach((mode, scheme) {
          final rest = _argb(scheme, subject.defaultRest);
          final hovered = _argb(scheme, subject.defaultHover);
          final delta = CoreContrast.ratio(CoreColor(rest), CoreColor(hovered));

          expect(
            delta,
            greaterThanOrEqualTo(_perceptibleFloor),
            reason:
                '$mode / ${subject.name} — the hover border lands on '
                '${delta.toStringAsFixed(4)} against the resting one, '
                'which is a state that draws nothing',
          );
        });
      });

      test('an unset style states no hover border of its own — the default '
          'is left to the resolvers to apply', () {
        expect(subject.hoverOf(subject.empty), isNull);
      });

      test('merge: the later layer wins', () {
        final merged = _merge(
          subject.withHover(_custom),
          subject.withHover(_otherCustom),
        );
        expect(subject.hoverOf(merged), _otherCustom);
      });

      test('merge: an unset later layer keeps the earlier hover border', () {
        final merged = _merge(subject.withHover(_custom), subject.empty);
        expect(subject.hoverOf(merged), _custom);
      });

      test('merge: a later layer that sets only another field keeps the '
          'earlier hover border', () {
        final merged = _merge(
          subject.withHover(_custom),
          subject.withRest(_otherCustom),
        );
        expect(subject.hoverOf(merged), _custom);
      });

      test('merge: the hover border does not leak into the resting one', () {
        final merged = _merge(
          subject.withRest(_otherCustom),
          subject.withHover(_custom),
        );
        expect(subject.hoverOf(merged), _custom);
        expect(merged, isNot(subject.withHover(_custom)));
      });

      test('copyWith replaces the hover border', () {
        final copy = _copyWithHover(subject.withHover(_custom), _otherCustom);
        expect(subject.hoverOf(copy), _otherCustom);
      });

      test('copyWith without it keeps the hover border', () {
        final copy = switch (subject.withHover(_custom)) {
          final CoreChipInputStyle s => s.copyWith(),
          final CoreObjectInputStyle s => s.copyWith(),
          final CoreItemPickerStyle s => s.copyWith(),
          _ => throw StateError('unreachable'),
        };
        expect(subject.hoverOf(copy), _custom);
      });

      test('equality and hashCode include the hover border', () {
        final a = subject.withHover(_custom);
        final same = subject.withHover(_custom);
        final different = subject.withHover(_otherCustom);

        expect(a, same);
        expect(a.hashCode, same.hashCode);
        // The only field that differs is the hover border — if `==` skipped
        // it these would compare equal and a rebuild would never fire.
        expect(a, isNot(different));
        expect(a.hashCode, isNot(different.hashCode));
        expect(subject.empty, isNot(a));
      });
    });
  }
}
