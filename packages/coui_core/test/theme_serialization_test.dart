import 'dart:convert';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

CoreThemeData _createTheme() {
  return CoreThemeData(
    colorScheme: CouiColorPresets.source.light(),
    brightness: .light,
    designSystem: .coui,
  );
}

void main() {
  group('TokenSerialization', () {
    test('roundtrip JSON serialization', () {
      final theme = _createTheme();
      final json = TokenSerialization.toJson(theme);
      final restored = TokenSerialization.fromJson(json);

      expect(restored.brightness, equals(theme.brightness));
      expect(restored.designSystem, equals(theme.designSystem));
      expect(
        restored.colorScheme.primary.value,
        equals(theme.colorScheme.primary.value),
      );
    });

    test('toJson produces valid JSON', () {
      final theme = _createTheme();
      final json = TokenSerialization.toJson(theme);
      expect(() => jsonDecode(json), returnsNormally);
    });

    test('toFigmaVariables exports flat hex map', () {
      final theme = _createTheme();
      final vars = TokenSerialization.toFigmaVariables(theme);

      expect(vars.containsKey('primary'), isTrue);
      expect(vars['primary'], startsWith('#'));
      expect(vars.length, greaterThan(20));
    });

    test('toCouiTheme exports hex values', () {
      final theme = _createTheme();
      final daisyTheme = TokenSerialization.toCouiTheme(theme);

      expect(daisyTheme.containsKey('primary'), isTrue);
      expect(daisyTheme.length, greaterThan(20));
    });
  });

  group('CoreThemeData', () {
    test('copyWith modifies specified fields', () {
      final theme = _createTheme();
      final dark = theme.copyWith(brightness: .dark);

      expect(dark.brightness, equals(CoreBrightness.dark));
      expect(dark.designSystem, equals(theme.designSystem));
    });

    test('toJson contains all expected keys', () {
      final theme = _createTheme();
      final json = theme.toJson();

      expect(json.containsKey('brightness'), isTrue);
      expect(json.containsKey('designSystem'), isTrue);
      expect(json.containsKey('colors'), isTrue);
      expect(json.containsKey('textScaling'), isTrue);
    });

    test('equality works', () {
      final a = _createTheme();
      // A no-arg `copyWith` produces a distinct instance with identical
      // field values, exercising `==` across separate objects.
      final b = a.copyWith();
      expect(identical(a, b), isFalse);
      expect(a, equals(b));
    });

    test('equality distinguishes defaultSurface', () {
      final base = _createTheme();
      final withSurface = base.copyWith(
        defaultSurface: const CoreSurfaceToken.tonalElevation(elevation: 2),
      );

      expect(base, isNot(equals(withSurface)));
      expect(base.hashCode, isNot(equals(withSurface.hashCode)));
    });

    test('toJson serializes defaultSurface', () {
      final theme = _createTheme().copyWith(
        defaultSurface: const CoreSurfaceToken.tonalElevation(elevation: 2),
      );
      final json = theme.toJson();

      expect(json['defaultSurface'], isA<Map<String, dynamic>>());
      expect(
        (json['defaultSurface'] as Map)['type'],
        equals('tonalElevation'),
      );
    });

    test('toJson leaves null defaultSurface as null', () {
      final json = _createTheme().toJson();
      expect(json.containsKey('defaultSurface'), isTrue);
      expect(json['defaultSurface'], isNull);
    });
  });

  group('Motion / surface token toJson', () {
    test('CssTransitionMotion', () {
      expect(
        const CssTransitionMotion(durationMs: 150, easing: 'ease-out').toJson(),
        equals({
          'type': 'cssTransition',
          'durationMs': 150,
          'easing': 'ease-out',
        }),
      );
    });

    test('GlassPhysicsMotion nests its spring', () {
      const motion = GlassPhysicsMotion(
        spring: SpringMotion(dampingRatio: 0.7, stiffness: 300),
        specularResponse: 0.6,
      );
      final json = motion.toJson();
      expect(json['type'], equals('glassPhysics'));
      expect((json['spring'] as Map)['type'], equals('spring'));
    });

    test('CoreSurfaceToken.glass carries its blur and opacity', () {
      const surface = CoreSurfaceToken.glass(
        opacity: CoreSurfaceOpacity.same(0.6),
        blur: 12,
      );
      final json = surface.toJson();
      expect(json['type'], equals('glass'));
      expect(json['opacity'], equals({'light': 0.6, 'dark': 0.6}));
      expect(json['blurRadius'], equals(12));
    });
  });

  group('CssVariableGenerator', () {
    test('generates color variables', () {
      final theme = _createTheme();
      final vars = CssVariableGenerator.generate(theme);

      expect(vars.containsKey('--coui-primary'), isTrue);
      expect(vars.containsKey('--coui-primary-hex'), isTrue);
      expect(vars.containsKey('--coui-error'), isTrue);
    });

    test('generates radius variables', () {
      final theme = _createTheme();
      final vars = CssVariableGenerator.generate(theme);

      expect(vars.containsKey('--coui-radius-0'), isTrue);
      expect(vars.containsKey('--coui-radius-8'), isTrue);
      expect(vars.containsKey('--coui-radius-16'), isTrue);
    });

    group('radius variables under radiusScaling', () {
      // Not 1 — the only scale at which a step the generator skips (and so
      // leaves at its unscaled `:root` value) comes apart from its
      // neighbours.
      const scale = 1.5;
      final vars = CssVariableGenerator.generate(
        _createTheme().copyWith(radiusScaling: scale),
      );
      String name(double step) => '--coui-radius-${step.toInt()}';
      double px(double step) {
        final value = vars[name(step)];
        expect(value, isNotNull, reason: '${name(step)} is not generated');
        expect(value, endsWith('px'), reason: '${name(step)}: $value');
        return double.parse(value!.substring(0, value.length - 2));
      }

      test('every CoreRadius step has a variable', () {
        for (final step in [
          CoreRadius.radius0,
          ...CoreRadius.steps,
          CoreRadius.radius9999,
        ]) {
          expect(vars.containsKey(name(step)), isTrue, reason: name(step));
        }
      });

      test('every ladder step is rescaled, the control corners included', () {
        for (final step in CoreRadius.steps) {
          expect(px(step), step * scale, reason: name(step));
        }
        // The control-size corners that are not on a 4-px rung —
        // xs 6 · md 10 · xl 14.
        expect(px(CoreRadius.radius6), 9);
        expect(px(CoreRadius.radius10), 15);
        expect(px(CoreRadius.radius14), 21);
      });

      test('the ladder stays in order — sm is never rounder than md', () {
        final values = [for (final step in CoreRadius.steps) px(step)];
        for (var i = 1; i < values.length; i++) {
          expect(
            values[i],
            greaterThan(values[i - 1]),
            reason:
                '${name(CoreRadius.steps[i])} is not rounder than '
                '${name(CoreRadius.steps[i - 1])}',
          );
        }
        expect(px(CoreRadius.radius8), lessThan(px(CoreRadius.radius10)));
      });

      test('the sentinels keep their meaning', () {
        expect(px(CoreRadius.radius0), 0);
        expect(px(CoreRadius.radius9999), CoreRadius.radius9999);
      });
    });

    test('toCssBlock produces valid CSS', () {
      final theme = _createTheme();
      final css = CssVariableGenerator.toCssBlock(theme);

      expect(css, startsWith(':root {'));
      expect(css, endsWith('}\n'));
      expect(css, contains('--coui-primary:'));
    });

    test('CoUI scheme variables are unchanged by the adapter pass-through', () {
      // The Web resolution path now routes the scheme through
      // `designSystem.adapter.resolveColorScheme`; the CoUI baseline is a
      // pass-through, so the emitted variables match the raw scheme's map.
      final theme = _createTheme();
      final vars = CssVariableGenerator.generate(theme);
      final rawColors = theme.colorScheme.toMap();

      for (final key in rawColors.keys) {
        expect(vars.containsKey('--coui-$key'), isTrue, reason: key);
      }
    });
  });

  group('ThemeParser', () {
    test('fromMap parses theme correctly', () {
      final map = {
        'primary': '#0000FF',
        'primary-content': '#FFFFFF',
        'secondary': '#00FF00',
        'secondary-content': '#000000',
        'accent': '#FF0000',
        'accent-content': '#FFFFFF',
        'neutral': '#808080',
        'neutral-content': '#FFFFFF',
        'base-100': '#FFFFFF',
        'base-200': '#F0F0F0',
        'base-300': '#E0E0E0',
        'base-content': '#000000',
        'info': '#0000FF',
        'info-content': '#FFFFFF',
        'success': '#00FF00',
        'success-content': '#000000',
        'warning': '#FFAA00',
        'warning-content': '#000000',
        'error': '#FF0000',
        'error-content': '#FFFFFF',
        'brightness': 'light',
      };

      final theme = ThemeParser.fromMap(map);
      expect(theme.brightness, equals(CoreBrightness.light));
      expect(theme.designSystem, equals(DesignSystem.coui));
      expect(theme.colorScheme.primary.blue, equals(255));
    });
  });

  group('tapSoundEnabled (#4201)', () {
    // The axis lives in `coui_core`, so its serialization has to be
    // covered by the `coui_core` job. CI runs `test:dart` and
    // `test:flutter` as separate jobs — a round-trip assertion parked in
    // the Flutter package leaves this API with zero coverage in the job
    // that owns it.

    test('round-trips a disabled axis through JSON', () {
      final json = TokenSerialization.toJson(
        CoreThemePresets.light.copyWith(tapSoundEnabled: false),
      );

      expect(TokenSerialization.fromJson(json).tapSoundEnabled, isFalse);
    });

    test('a payload written before the key existed still means sound', () {
      final json = TokenSerialization.toJson(CoreThemePresets.light);
      // Rebuilt without the key rather than deleting a literal
      // `"tapSoundEnabled":false` from the text: the preset serialises
      // `true`, so matching the `false` spelling removes nothing and the
      // absent-key path never runs.
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final stripped = jsonEncode({
        for (final entry in decoded.entries)
          if (entry.key != 'tapSoundEnabled') entry.key: entry.value,
      });

      // The premise has to hold, or the assertion below proves nothing.
      expect(stripped, isNot(contains('tapSoundEnabled')));
      expect(TokenSerialization.fromJson(stripped).tapSoundEnabled, isTrue);
    });
  });
}
