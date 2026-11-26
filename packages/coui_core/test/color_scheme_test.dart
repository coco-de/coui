import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

const _kRed = CoreColor(0xFFFF0000);
const _kBlue = CoreColor(0xFF0000FF);

/// Names of every `CoreColor` field declared on `CoreColorScheme`.
///
/// Read from source so the tests below cannot quietly fall behind the class.
Set<String> _declaredColorFields() {
  final source = File('lib/src/color/color_scheme.dart').readAsStringSync();
  return RegExp(
    r'^\s+final CoreColor\??\s+(\w+);',
    multiLine: true,
  ).allMatches(source).map((m) => m.group(1)!).toSet();
}

CoreColorScheme _createTestScheme() => kBrandFixtureSource.light();

/// One setter per colour slot, keyed by field name.
///
/// Shared by every test that must touch each slot on its own, so a slot
/// added to the class is covered by all of them the moment it is listed
/// here — and `exercises every declared slot` fails until it is.
final _slotSetters =
    <String, CoreColorScheme Function(CoreColorScheme, CoreColor)>{
      'surface': (s, c) => s.copyWith(surface: c),
      'surfaceDim': (s, c) => s.copyWith(surfaceDim: c),
      'surfaceBright': (s, c) => s.copyWith(surfaceBright: c),
      'surfaceContainerLowest': (s, c) => s.copyWith(surfaceContainerLowest: c),
      'surfaceContainerLow': (s, c) => s.copyWith(surfaceContainerLow: c),
      'surfaceContainer': (s, c) => s.copyWith(surfaceContainer: c),
      'surfaceContainerHigh': (s, c) => s.copyWith(surfaceContainerHigh: c),
      'surfaceContainerHighest': (s, c) =>
          s.copyWith(surfaceContainerHighest: c),
      'onSurface': (s, c) => s.copyWith(onSurface: c),
      'onSurfaceVariant': (s, c) => s.copyWith(onSurfaceVariant: c),
      'placeholder': (s, c) => s.copyWith(placeholder: c),
      'surfaceTint': (s, c) => s.copyWith(surfaceTint: c),
      'primary': (s, c) => s.copyWith(primary: c),
      'onPrimary': (s, c) => s.copyWith(onPrimary: c),
      'primaryContainer': (s, c) => s.copyWith(primaryContainer: c),
      'onPrimaryContainer': (s, c) => s.copyWith(onPrimaryContainer: c),
      'primaryFixed': (s, c) => s.copyWith(primaryFixed: c),
      'primaryFixedDim': (s, c) => s.copyWith(primaryFixedDim: c),
      'onPrimaryFixed': (s, c) => s.copyWith(onPrimaryFixed: c),
      'onPrimaryFixedVariant': (s, c) => s.copyWith(onPrimaryFixedVariant: c),
      'primaryText': (s, c) => s.copyWith(primaryText: c),
      'primaryTextLarge': (s, c) => s.copyWith(primaryTextLarge: c),
      'secondary': (s, c) => s.copyWith(secondary: c),
      'onSecondary': (s, c) => s.copyWith(onSecondary: c),
      'secondaryContainer': (s, c) => s.copyWith(secondaryContainer: c),
      'onSecondaryContainer': (s, c) => s.copyWith(onSecondaryContainer: c),
      'secondaryFixed': (s, c) => s.copyWith(secondaryFixed: c),
      'secondaryFixedDim': (s, c) => s.copyWith(secondaryFixedDim: c),
      'onSecondaryFixed': (s, c) => s.copyWith(onSecondaryFixed: c),
      'onSecondaryFixedVariant': (s, c) =>
          s.copyWith(onSecondaryFixedVariant: c),
      'tertiary': (s, c) => s.copyWith(tertiary: c),
      'onTertiary': (s, c) => s.copyWith(onTertiary: c),
      'tertiaryContainer': (s, c) => s.copyWith(tertiaryContainer: c),
      'onTertiaryContainer': (s, c) => s.copyWith(onTertiaryContainer: c),
      'tertiaryFixed': (s, c) => s.copyWith(tertiaryFixed: c),
      'tertiaryFixedDim': (s, c) => s.copyWith(tertiaryFixedDim: c),
      'onTertiaryFixed': (s, c) => s.copyWith(onTertiaryFixed: c),
      'onTertiaryFixedVariant': (s, c) => s.copyWith(onTertiaryFixedVariant: c),
      'error': (s, c) => s.copyWith(error: c),
      'errorStrong': (s, c) => s.copyWith(errorStrong: c),
      'focusRing': (s, c) => s.copyWith(focusRing: c),
      'primaryHover': (s, c) => s.copyWith(primaryHover: c),
      'primaryPressed': (s, c) => s.copyWith(primaryPressed: c),
      'secondaryHover': (s, c) => s.copyWith(secondaryHover: c),
      'secondaryPressed': (s, c) => s.copyWith(secondaryPressed: c),
      'errorPressed': (s, c) => s.copyWith(errorPressed: c),
      'onError': (s, c) => s.copyWith(onError: c),
      'errorContainer': (s, c) => s.copyWith(errorContainer: c),
      'onErrorContainer': (s, c) => s.copyWith(onErrorContainer: c),
      'success': (s, c) => s.copyWith(success: c),
      'onSuccess': (s, c) => s.copyWith(onSuccess: c),
      'successContainer': (s, c) => s.copyWith(successContainer: c),
      'onSuccessContainer': (s, c) => s.copyWith(onSuccessContainer: c),
      'warning': (s, c) => s.copyWith(warning: c),
      'onWarning': (s, c) => s.copyWith(onWarning: c),
      'warningContainer': (s, c) => s.copyWith(warningContainer: c),
      'onWarningContainer': (s, c) => s.copyWith(onWarningContainer: c),
      'info': (s, c) => s.copyWith(info: c),
      'onInfo': (s, c) => s.copyWith(onInfo: c),
      'infoContainer': (s, c) => s.copyWith(infoContainer: c),
      'onInfoContainer': (s, c) => s.copyWith(onInfoContainer: c),
      'errorIcon': (s, c) => s.copyWith(errorIcon: c),
      'successIcon': (s, c) => s.copyWith(successIcon: c),
      'warningIcon': (s, c) => s.copyWith(warningIcon: c),
      'infoIcon': (s, c) => s.copyWith(infoIcon: c),
      'outline': (s, c) => s.copyWith(outline: c),
      'outlineVariant': (s, c) => s.copyWith(outlineVariant: c),
      'outlineSubtle': (s, c) => s.copyWith(outlineSubtle: c),
      'link': (s, c) => s.copyWith(link: c),
      'onSurfaceSubtle': (s, c) => s.copyWith(onSurfaceSubtle: c),
      'surfaceRaised': (s, c) => s.copyWith(surfaceRaised: c),
      'syntaxKeyword': (s, c) => s.copyWith(syntaxKeyword: c),
      'syntaxType': (s, c) => s.copyWith(syntaxType: c),
      'syntaxFunction': (s, c) => s.copyWith(syntaxFunction: c),
      'syntaxString': (s, c) => s.copyWith(syntaxString: c),
      'inverseSurface': (s, c) => s.copyWith(inverseSurface: c),
      'inverseOnSurface': (s, c) => s.copyWith(inverseOnSurface: c),
      'inversePrimary': (s, c) => s.copyWith(inversePrimary: c),
      'shadow': (s, c) => s.copyWith(shadow: c),
      'surfaceHighlight': (s, c) => s.copyWith(surfaceHighlight: c),
      'scrim': (s, c) => s.copyWith(scrim: c),
      'disabledContent': (s, c) => s.copyWith(disabledContent: c),
      'disabledContainer': (s, c) => s.copyWith(disabledContainer: c),
      'disabledOutline': (s, c) => s.copyWith(disabledOutline: c),
      'categoryRed': (s, c) => s.copyWith(categoryRed: c),
      'onCategoryRed': (s, c) => s.copyWith(onCategoryRed: c),
      'categoryRedContainer': (s, c) => s.copyWith(categoryRedContainer: c),
      'onCategoryRedContainer': (s, c) => s.copyWith(onCategoryRedContainer: c),
      'categoryRedOutline': (s, c) => s.copyWith(categoryRedOutline: c),
      'categoryOrange': (s, c) => s.copyWith(categoryOrange: c),
      'onCategoryOrange': (s, c) => s.copyWith(onCategoryOrange: c),
      'categoryOrangeContainer': (s, c) =>
          s.copyWith(categoryOrangeContainer: c),
      'onCategoryOrangeContainer': (s, c) =>
          s.copyWith(onCategoryOrangeContainer: c),
      'categoryOrangeOutline': (s, c) => s.copyWith(categoryOrangeOutline: c),
      'categoryYellow': (s, c) => s.copyWith(categoryYellow: c),
      'onCategoryYellow': (s, c) => s.copyWith(onCategoryYellow: c),
      'categoryYellowContainer': (s, c) =>
          s.copyWith(categoryYellowContainer: c),
      'onCategoryYellowContainer': (s, c) =>
          s.copyWith(onCategoryYellowContainer: c),
      'categoryYellowOutline': (s, c) => s.copyWith(categoryYellowOutline: c),
      'categoryGreen': (s, c) => s.copyWith(categoryGreen: c),
      'onCategoryGreen': (s, c) => s.copyWith(onCategoryGreen: c),
      'categoryGreenContainer': (s, c) => s.copyWith(categoryGreenContainer: c),
      'onCategoryGreenContainer': (s, c) =>
          s.copyWith(onCategoryGreenContainer: c),
      'categoryGreenOutline': (s, c) => s.copyWith(categoryGreenOutline: c),
      'categoryBlue': (s, c) => s.copyWith(categoryBlue: c),
      'onCategoryBlue': (s, c) => s.copyWith(onCategoryBlue: c),
      'categoryBlueContainer': (s, c) => s.copyWith(categoryBlueContainer: c),
      'onCategoryBlueContainer': (s, c) =>
          s.copyWith(onCategoryBlueContainer: c),
      'categoryBlueOutline': (s, c) => s.copyWith(categoryBlueOutline: c),
      'categoryPurple': (s, c) => s.copyWith(categoryPurple: c),
      'onCategoryPurple': (s, c) => s.copyWith(onCategoryPurple: c),
      'categoryPurpleContainer': (s, c) =>
          s.copyWith(categoryPurpleContainer: c),
      'onCategoryPurpleContainer': (s, c) =>
          s.copyWith(onCategoryPurpleContainer: c),
      'categoryPurpleOutline': (s, c) => s.copyWith(categoryPurpleOutline: c),
      'categoryPink': (s, c) => s.copyWith(categoryPink: c),
      'onCategoryPink': (s, c) => s.copyWith(onCategoryPink: c),
      'categoryPinkContainer': (s, c) => s.copyWith(categoryPinkContainer: c),
      'onCategoryPinkContainer': (s, c) =>
          s.copyWith(onCategoryPinkContainer: c),
      'categoryPinkOutline': (s, c) => s.copyWith(categoryPinkOutline: c),
      'categoryBrown': (s, c) => s.copyWith(categoryBrown: c),
      'onCategoryBrown': (s, c) => s.copyWith(onCategoryBrown: c),
      'categoryBrownContainer': (s, c) => s.copyWith(categoryBrownContainer: c),
      'onCategoryBrownContainer': (s, c) =>
          s.copyWith(onCategoryBrownContainer: c),
      'categoryBrownOutline': (s, c) => s.copyWith(categoryBrownOutline: c),
      'categoryGray': (s, c) => s.copyWith(categoryGray: c),
      'onCategoryGray': (s, c) => s.copyWith(onCategoryGray: c),
      'categoryGrayContainer': (s, c) => s.copyWith(categoryGrayContainer: c),
      'onCategoryGrayContainer': (s, c) =>
          s.copyWith(onCategoryGrayContainer: c),
      'categoryGrayOutline': (s, c) => s.copyWith(categoryGrayOutline: c),
    };

void main() {
  group('CoreColorScheme', () {
    test('creates with M3 semantic tokens', () {
      final scheme = _createTestScheme();
      expect(scheme.primary.value, isNonZero);
      expect(scheme.secondary.value, isNonZero);
      expect(scheme.surface, isNotNull);
      expect(scheme.onSurface, isNotNull);
      expect(scheme.onPrimary, isNotNull);
      expect(scheme.primaryContainer, isNotNull);
    });

    test('tertiary is set from Primitive', () {
      final scheme = _createTestScheme();
      expect(scheme.tertiary, isNotNull);
      expect(scheme.onTertiary, isNotNull);
    });

    test('toMap exports color tokens', () {
      final scheme = _createTestScheme();
      final map = scheme.toMap();
      expect(map.containsKey('primary'), isTrue);
      expect(map.containsKey('error'), isTrue);
      expect(map.containsKey('surface'), isTrue);
      expect(map.containsKey('on-primary'), isTrue);
    });

    test('copyWith modifies specified fields', () {
      final scheme = _createTestScheme();
      final modified = scheme.copyWith(primary: _kRed);
      // Scheme tags raw colours with their slot's token; compare the
      // ARGB rather than the whole CoreColor (which now carries token
      // metadata for Web rendering).
      expect(modified.primary.argb, equals(_kRed.argb));
      // Other fields unchanged
      expect(modified.secondary, equals(scheme.secondary));
    });

    test('lerp interpolates between schemes', () {
      final a = _createTestScheme();
      final b = a.copyWith(
        primary: _kRed,
        secondary: _kBlue,
      );

      final mid = CoreColorScheme.lerp(a, b, 0.5);
      expect(mid.primary.red, greaterThan(0));
      expect(mid.primary.blue, greaterThan(0));
    });

    test('equality works', () {
      final a = _createTestScheme();
      // A no-arg `copyWith` produces a distinct instance with identical
      // field values, exercising `==` across separate objects.
      final b = a.copyWith();
      expect(identical(a, b), isFalse);
      expect(a, equals(b));
    });

    test('fromMap parses hex values', () {
      final scheme = CoreColorScheme.fromMap(const {
        'primary': '#0000FF',
        'secondary': '#00FF00',
        'error': '#FF0000',
        'success': '#00FF00',
        'warning': '#FFAA00',
        'info': '#0000FF',
        'surface': '#FFFFFF',
        'on-surface': '#000000',
        'on-primary': '#FFFFFF',
      });

      expect(scheme.primary.blue, equals(255));
      expect(scheme.primary.red, equals(0));
      expect(scheme.surface, isNotNull);
    });
  });

  // A theme axis (high-contrast set, surface preset, brightness) works by
  // building a new scheme and letting the framework compare it against the
  // old one to decide whether to rebuild. A slot left out of that comparison
  // is a slot no axis can move — the axis computes correct colours, the
  // schemes compare equal, no rebuild happens, and the screen stays as it
  // was. Nothing on screen hints at the cause, so it has to be caught here.
  group('CoreColorScheme equality covers every slot', () {
    // Two probes rather than one: asserting against a single sentinel would
    // silently pass for any slot whose base value already equalled it.
    // Comparing probe-A against probe-B isolates the slot regardless of base.
    const probeA = CoreColor(0xFF010203);
    const probeB = CoreColor(0xFF040506);

    test('exercises every declared slot', () {
      // Asserting a hard-coded count would let a newly added field pass
      // unexercised — the count would still match the map, just not the
      // class. Comparing against the source keeps the two tied.
      final declared = _declaredColorFields();
      expect(declared, isNotEmpty);
      expect(
        declared.difference(_slotSetters.keys.toSet()),
        isEmpty,
        reason:
            'These slots have no case below, so nothing checks that a theme '
            'axis writing one of them triggers a rebuild.',
      );
      expect(_slotSetters.keys.toSet().difference(declared), isEmpty);
    });

    for (final entry in _slotSetters.entries) {
      test('${entry.key} alone makes two schemes unequal', () {
        final base = _createTestScheme();
        final a = entry.value(base, probeA);
        final b = entry.value(base, probeB);

        expect(
          a,
          isNot(equals(b)),
          reason:
              '${entry.key} is not compared in operator== — a theme axis '
              'writing only this slot would not trigger a rebuild.',
        );
        expect(
          a.hashCode,
          isNot(equals(b.hashCode)),
          reason: '${entry.key} is not part of hashCode.',
        );
      });
    }

    test('identical schemes stay equal and share a hashCode', () {
      // The inverse guard: if the comparison were accidentally made
      // slot-sensitive in a way that never matches, every rebuild would fire
      // and the above tests would still pass.
      final a = _createTestScheme();
      final b = _createTestScheme();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('ResolvedColorScheme inherits full-slot equality', () {
      // Axes usually hand around resolved schemes, so the subclass — which
      // overrides the getters to non-null but adds no fields — must compare
      // the same way.
      final base = _createTestScheme();
      final a = base.copyWith(inversePrimary: probeA).resolved(.light);
      final b = base.copyWith(inversePrimary: probeB).resolved(.light);
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('CoreColorScheme equality slot list is complete', () {
    test('every declared CoreColor field appears in the compared slots', () {
      // The parameterised tests above can only check slots someone remembered
      // to list. This reads the source so a newly added field that never
      // reaches the comparison fails here instead of shipping as a dead axis.
      final source = File('lib/src/color/color_scheme.dart').readAsStringSync();

      final declared = RegExp(
        r'^\s+final CoreColor\??\s+(\w+);',
        multiLine: true,
      ).allMatches(source).map((m) => m.group(1)!).toSet();

      final slotBlock = RegExp(
        r'List<CoreColor\?> get _equalitySlots => \[(.*?)\n  \];',
        dotAll: true,
      ).firstMatch(source);
      expect(slotBlock, isNotNull, reason: '_equalitySlots not found.');

      final compared = RegExp(
        r'^\s+(\w+),$',
        multiLine: true,
      ).allMatches(slotBlock!.group(1)!).map((m) => m.group(1)!).toSet();

      expect(declared, isNotEmpty);
      expect(
        declared.difference(compared),
        isEmpty,
        reason:
            'These colour slots are declared but never compared, so a theme '
            'axis writing one of them cannot trigger a rebuild.',
      );
      expect(
        compared.difference(declared),
        isEmpty,
        reason: '_equalitySlots names something that is not a field.',
      );
    });
  });

  // A slot the interpolation leaves out comes back null, and whoever resolves
  // the crossfade frame fills it from a default palette — neither endpoint.
  // It jumps on the first frame while every other slot glides. Nothing throws
  // and a unit test on one slot never notices, so the full set is pinned here.
  group('CoreColorScheme.lerp interpolates every slot', () {
    // Channel differences are all multiples of 4 (0x40, 0x60, 0x80), so the
    // quarter points below land on whole numbers — no rounding tie can make
    // the symmetry check fail for reasons that have nothing to do with slots.
    const from = CoreColor(0xFF204060);
    const to = CoreColor(0xFF60A0E0);
    const midway = CoreColor(0xFF4070A0);

    test('interpolates the same slot set it compares', () {
      final source = File('lib/src/color/color_scheme.dart').readAsStringSync();

      // `lerp` walks the slots through `_zipSlots`, so that constructor's
      // initializer list is the set it interpolates.
      final lerpBody = RegExp(
        r'CoreColorScheme\._zipSlots\(.*?\) : this\((.*?)\n      \);',
        dotAll: true,
      ).firstMatch(source);
      expect(
        lerpBody,
        isNotNull,
        reason: 'CoreColorScheme._zipSlots not found.',
      );
      expect(
        RegExp(
          r'static CoreColorScheme lerp\([^;]*CoreColorScheme\._zipSlots\(',
        ).hasMatch(source),
        isTrue,
        reason: 'lerp no longer goes through _zipSlots.',
      );

      final interpolated = RegExp(
        r'^\s+(\w+):',
        multiLine: true,
      ).allMatches(lerpBody!.group(1)!).map((m) => m.group(1)!).toSet();

      final slotBlock = RegExp(
        r'List<CoreColor\?> get _equalitySlots => \[(.*?)\n  \];',
        dotAll: true,
      ).firstMatch(source)!;
      final compared = RegExp(
        r'^\s+(\w+),$',
        multiLine: true,
      ).allMatches(slotBlock.group(1)!).map((m) => m.group(1)!).toSet();

      expect(compared, isNotEmpty);
      expect(
        compared.difference(interpolated),
        isEmpty,
        reason:
            'These slots are compared but never interpolated, so a theme '
            'crossfade snaps them instead of blending.',
      );
      expect(interpolated.difference(compared), isEmpty);
    });

    for (final entry in _slotSetters.entries) {
      test('${entry.key} lands midway at t = 0.5', () {
        // Lerping the base with itself first normalises every other slot the
        // way lerp does, so the comparison isolates the one slot under test.
        final base = CoreColorScheme.lerp(
          _createTestScheme(),
          _createTestScheme(),
          0.5,
        );
        final a = entry.value(base, from);
        final b = entry.value(base, to);

        expect(
          CoreColorScheme.lerp(a, b, 0.5),
          equals(entry.value(base, midway)),
          reason:
              '${entry.key} did not reach the midpoint — it is missing from '
              'lerp and snaps during a theme crossfade.',
        );
      });
    }

    CoreColorScheme fill(CoreColor c) => _slotSetters.values.fold(
      _createTestScheme(),
      (scheme, set) => set(scheme, c),
    );

    test('endpoints return the endpoint schemes', () {
      final a = fill(from);
      final b = fill(to);
      expect(CoreColorScheme.lerp(a, b, 0), equals(a));
      expect(CoreColorScheme.lerp(a, b, 1), equals(b));
    });

    test('lerp(a, b, t) == lerp(b, a, 1 - t)', () {
      final a = fill(from);
      final b = fill(to);
      for (final t in const [0.25, 0.5, 0.75]) {
        expect(
          CoreColorScheme.lerp(a, b, t),
          equals(CoreColorScheme.lerp(b, a, 1 - t)),
          reason: 't=$t',
        );
      }
    });
  });

  // A token-only scheme carries slot names, not colours, so interpolating it
  // throws. Resolving it first against the palette widgets paint from is how
  // an animated theme change over such a scheme stays on the colours that
  // were on screen.
  group('CoreColorScheme.resolveTokensAgainst', () {
    final palette = CoreThemePresets.lightColorScheme;

    test('a token-only scheme becomes the palette it resolves against', () {
      const tokens = CoreColorScheme.tokenized();
      expect(
        () => CoreColorScheme.lerp(tokens, tokens, 0.5),
        throwsStateError,
        reason: 'precondition: the unresolved scheme cannot be interpolated',
      );

      final resolved = tokens.resolveTokensAgainst(palette);
      expect(resolved, equals(palette));
      expect(
        () => CoreColorScheme.lerp(resolved, resolved, 0.5),
        returnsNormally,
      );
    });

    test('raw slots are kept as they are', () {
      final authored = _createTestScheme().copyWith(primary: _kRed);
      expect(authored.resolveTokensAgainst(palette), equals(authored));
    });
  });

  // The high-contrast door of a mapping stated as two complete tables:
  // where the tables disagree the raised value wins, where they agree the
  // base keeps whatever it had — including what an earlier axis did to it.
  group('CoreColorScheme.raiseByDelta', () {
    final normal = _createTestScheme();
    final raised = normal.copyWith(primary: _kRed, outline: _kBlue);

    test('with base == normal the result is the raised table', () {
      expect(
        CoreColorScheme.raiseByDelta(normal, normal: normal, raised: raised),
        equals(raised),
      );
    });

    test('lays the disagreeing slots over the base', () {
      final base = normal.copyWith(surface: const CoreColor(0xFF00FF00));
      final result = CoreColorScheme.raiseByDelta(
        base,
        normal: normal,
        raised: raised,
      );

      expect(result.primary.argb, _kRed.argb);
      expect(result.outline!.argb, _kBlue.argb);
    });

    test('keeps the base value on every slot the tables agree on', () {
      // Every slot of the base carries a sentinel no table states, so any
      // slot that comes back as something else was not kept.
      const sentinel = CoreColor(0xFF123456);
      final base = _slotSetters.values.fold(
        normal,
        (scheme, set) => set(scheme, sentinel),
      );
      final result = CoreColorScheme.raiseByDelta(
        base,
        normal: normal,
        raised: raised,
      );

      expect(result, equals(base.copyWith(primary: _kRed, outline: _kBlue)));
    });

    test('a slot both tables leave unset keeps the base value', () {
      final unset = CoreColorScheme(
        primary: _kRed,
        secondary: _kRed,
        error: _kRed,
        success: _kRed,
        warning: _kRed,
        info: _kRed,
      );
      final base = normal.copyWith(surfaceHighlight: _kBlue);
      final result = CoreColorScheme.raiseByDelta(
        base,
        normal: unset,
        raised: unset,
      );

      expect(result.surfaceHighlight!.argb, _kBlue.argb);
    });

    test('a transparent raised value is laid over, not taken as agreement', () {
      final clear = normal.copyWith(scrim: CoreColor.transparent);
      final result = CoreColorScheme.raiseByDelta(
        normal,
        normal: normal,
        raised: clear,
      );

      expect(result.scrim!.argb, 0);
      expect(result.scrim, equals(clear.scrim));
    });
  });
}
