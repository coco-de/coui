import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

/// `glass-*` is `@Deprecated('Unreachable (since 0.128)')` — no palette
/// fills it, so the CSS generator has nothing to emit for it. This is the
/// one intentional gap between the token catalog and the stylesheet; any
/// other gap is drift (#3734/#3735 — F2).
///
/// A baseline is an item list, not a count: `BASELINE=4` would pass just as
/// happily if a real semantic token silently swapped places with one of
/// these, which is exactly the kind of drift this guard exists to catch.
/// Catalog names the stylesheet does not carry.
///
/// Empty, and the assertion below is what keeps it that way: a token in
/// `CoreColors` that the generator never emits is a `var(--coui-*)` the
/// Web can reference and the stylesheet cannot answer.
const _kColorSlotParityBaseline = <String>{};

/// The `CoreColors` catalog's token names, read straight from source.
///
/// `abstract final class CoreColors` has no runtime enumeration (no
/// `values`, no reflection in a Dart-VM test) — the token name is a literal
/// single-axis string, which is the one thing a source grep is allowed to
/// count without an AST reader (a structural count — brace depth, member
/// count — would drift with `dart format`; a quoted literal does not).
Set<String> _coreColorsCatalogNames() {
  final source = File(
    'lib/src/color/core_color_token.dart',
  ).readAsStringSync();

  return RegExp(
    r"CoreColorToken\._\(\s*'([a-z0-9-]+)'",
  ).allMatches(source).map((m) => m.group(1)!).toSet();
}

/// The stylesheet the Web emits for [source], parsed back into slots.
///
/// The CSS generator once restated the mapping slot by slot, which made it
/// a second source for the same decisions. That is fine only while
/// something holds the two together: change the mapping alone and Flutter
/// moves while the web stays put, and nothing about either file looks
/// wrong. This is that something — it reads the emitted stylesheet, not the
/// generator's inputs, so it holds whatever the generator does inside.
///
/// It was written after exactly that happened. Turning the dark shadow over
/// so a raised surface reads on a dark page changed the mapping; the web
/// kept emitting black, because the generator had its own copy.
Map<String, String> _emitted(CoreSchemeSource source, String brightness) {
  final css = PrimitiveCssGenerator.toCssBlockFrom(
    source,
    brightness: brightness,
  );

  return {
    for (final m in RegExp(r'--coui-([a-z0-9-]+):\s*([^;]+);').allMatches(css))
      m[1]!: m[2]!.trim(),
  };
}

String _rgb(CoreColor c) => '${c.red} ${c.green} ${c.blue}';

/// Both mappings that ship — a brand palette read through the standard
/// mapping, and CoUI's own source.
final _kSources = <String, CoreSchemeSource>{
  'standard mapping on a brand palette': kBrandFixtureSource,
  'CoUI': CouiColorPresets.source,
};

void main() {
  for (final MapEntry(key: name, value: source) in _kSources.entries) {
    _mirrorSuite(name, source);
    _shadowSuite(name, source);
  }

  _noComponentPicksItsOwnShadowTint();
  _catalogParity();
}

void _mirrorSuite(String name, CoreSchemeSource source) {
  for (final (brightness, mode) in [
    ('light', CoreBrightness.light),
    ('dark', CoreBrightness.dark),
  ]) {
    group(
      '$name: the $brightness stylesheet says what the $brightness mapping '
      'says',
      () {
        final scheme =
            (mode == CoreBrightness.light ? source.light() : source.dark())
                .resolved(mode);
        final css = _emitted(source, brightness);

        // Named rather than reflected: the pairing is the point, and a
        // reflective walk would silently cover fewer slots the day a name
        // changes on one side only.
        final slots = <String, CoreColor>{
          'surface': scheme.surface,
          'surface-dim': scheme.surfaceDim,
          'surface-bright': scheme.surfaceBright,
          'surface-container-lowest': scheme.surfaceContainerLowest,
          'surface-container-low': scheme.surfaceContainerLow,
          'surface-container': scheme.surfaceContainer,
          'surface-container-high': scheme.surfaceContainerHigh,
          'surface-container-highest': scheme.surfaceContainerHighest,
          'on-surface': scheme.onSurface,
          'on-surface-variant': scheme.onSurfaceVariant,
          'primary': scheme.primary,
          'on-primary': scheme.onPrimary,
          'primary-container': scheme.primaryContainer,
          'on-primary-container': scheme.onPrimaryContainer,
          'primary-fixed': scheme.primaryFixed,
          'primary-fixed-dim': scheme.primaryFixedDim,
          'on-primary-fixed': scheme.onPrimaryFixed,
          'on-primary-fixed-variant': scheme.onPrimaryFixedVariant,
          'secondary': scheme.secondary,
          'on-secondary': scheme.onSecondary,
          'secondary-fixed': scheme.secondaryFixed,
          'secondary-fixed-dim': scheme.secondaryFixedDim,
          'on-secondary-fixed': scheme.onSecondaryFixed,
          'on-secondary-fixed-variant': scheme.onSecondaryFixedVariant,
          'tertiary': scheme.tertiary,
          'on-tertiary': scheme.onTertiary,
          'tertiary-fixed': scheme.tertiaryFixed,
          'tertiary-fixed-dim': scheme.tertiaryFixedDim,
          'on-tertiary-fixed': scheme.onTertiaryFixed,
          'on-tertiary-fixed-variant': scheme.onTertiaryFixedVariant,
          'error': scheme.error,
          'on-error': scheme.onError,
          'success': scheme.success,
          'on-success': scheme.onSuccess,
          'warning': scheme.warning,
          'on-warning': scheme.onWarning,
          'info': scheme.info,
          'on-info': scheme.onInfo,
          'outline': scheme.outline,
          'outline-variant': scheme.outlineVariant,
          'outline-subtle': scheme.outlineSubtle,
          'link': scheme.link,
          'inverse-surface': scheme.inverseSurface,
          'inverse-on-surface': scheme.inverseOnSurface,
          'inverse-primary': scheme.inversePrimary,
          'shadow': scheme.shadow,
          'surface-highlight': scheme.surfaceHighlight,
          'scrim': scheme.scrim,
          'disabled-content': scheme.disabledContent,
          'disabled-container': scheme.disabledContainer,
          'disabled-outline': scheme.disabledOutline,
        };

        test('every slot matches', () {
          final drift = <String>[];
          slots.forEach((name, colour) {
            final got = css[name];
            if (got == null) {
              drift.add('$name is not emitted at all');

              return;
            }
            if (got != _rgb(colour)) {
              drift.add('$name: mapping ${_rgb(colour)}, stylesheet $got');
            }
          });

          expect(drift, isEmpty, reason: drift.join('\n'));
        });
      },
    );
  }
}

void _shadowSuite(String name, CoreSchemeSource source) {
  group('$name: a shadow is drawn in both modes', () {
    final light = source.light().resolved(CoreBrightness.light);
    final dark = source.dark().resolved(CoreBrightness.dark);

    test('it is black in both modes and never the page colour', () {
      // The colour does not turn over; the dark theme strengthens the
      // alpha instead (`CoreShadow.darkStrength`). It must still differ
      // from the page, or no strength could make it read.
      expect(_rgb(light.shadow), isNot(_rgb(light.surface)));
      expect(_rgb(dark.shadow), isNot(_rgb(dark.surface)));
      expect(_rgb(light.shadow), _rgb(dark.shadow));
    });

    test('the scrim does not turn over with it', () {
      // It darkens what is behind a modal, which is the same job either way.
      expect(_rgb(light.scrim), _rgb(dark.scrim));
    });
  });
}

void _noComponentPicksItsOwnShadowTint() {
  group('the shadow token', () {
    test('no component picks its own shadow tint', () {
      // Six of them used to, and four picked a different token from the
      // other two — which is how the dark page ended up with some surfaces
      // glowing and some casting nothing at all.
      for (final base in <CoreColor>[
        CoreCardStyle.defaultShadowBaseColor,
        CorePopupStyle.defaultShadowBaseColor,
        CoreDrawerStyle.defaultShadowBaseColor,
        CoreFrameStyle.defaultShadowBaseColor,
        CoreDescriptionCardStyle.defaultShadowBaseColor,
        CoreHoverStyle.defaultShadowBaseColor,
      ]) {
        expect(base, const CoreColor.token(CoreColors.shadow));
      }
    });
  });
}

void _catalogParity() {
  group('G8 — CoreColors 카탈로그 ↔ CSS 생성기 3-way 일치', () {
    // Catalog tokens / semantic CSS keys / Figma export variables.
    // `export_figma_tokens.dart` reads the *same*
    // `PrimitiveCssGenerator.semanticVarsFor` maps this test checks — so a
    // passing 3-way count here is a structural guarantee for the export
    // count too, not a separate thing that could drift from it. The
    // vocabulary is one walk whatever the source, so CoUI's — the first
    // brand the export publishes — stands for every brand.
    test('catalog names not in the stylesheet are exactly the baseline', () {
      final catalog = _coreColorsCatalogNames();

      // C1 — a population floor independent of the diff below. If source
      // parsing collapsed (renamed pattern, moved file), `catalog` could
      // shrink toward empty and the diff would shrink right along with it —
      // "fewer catalog names than the stylesheet has" reads as "nothing
      // missing" exactly when the guard is blind, not when it is green.
      expect(
        catalog.length,
        greaterThanOrEqualTo(60),
        reason:
            'CoreColors 카탈로그 추출이 하한 아래인 ${catalog.length}개 — '
            'core_color_token.dart 파싱이 붕괴했을 가능성(정규식이 더 이상 '
            '토큰 선언과 매칭하지 않음). 조용히 통과하면 안 되는 상태.',
      );

      final light = PrimitiveCssGenerator.semanticVarsFor(
        CouiColorPresets.source,
        CoreBrightness.light,
      );
      final emittedNames = light.keys
          .map((k) => k.replaceFirst('--coui-', ''))
          .toSet();

      final missing = catalog.difference(emittedNames);

      expect(
        missing,
        _kColorSlotParityBaseline,
        reason:
            'CoreColors 에는 있는데 PrimitiveCssGenerator 에는 없는 토큰이 '
            '생겼다 — 새 토큰이 CSS/Figma emit 없이 추가되면 Web 이 정의되지 '
            '않은 var() 를 참조하게 된다. 실제 diff: $missing',
      );
    });

    test('the dark stylesheet has the same key set as the light one', () {
      // Fixed slots do not turn over with brightness, but every other
      // decision does — the *names* must still match even though the
      // *values* differ, or the two modes disagree on what exists at all.
      final light = PrimitiveCssGenerator.semanticVarsFor(
        CouiColorPresets.source,
        CoreBrightness.light,
      );
      final dark = PrimitiveCssGenerator.semanticVarsFor(
        CouiColorPresets.source,
        CoreBrightness.dark,
      );
      expect(dark.keys.toSet(), light.keys.toSet());
    });
  });
}
