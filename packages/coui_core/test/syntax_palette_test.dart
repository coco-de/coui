// The syntax slots and the two surface-text slots beside them, as each
// mapping authors them — every source, every mode, and both doors into high
// contrast.
//
// Reads the AUTHORED scheme, before `resolved()`. Resolving fills an unset
// slot from CoUI's normal values, so a builder that forgot a slot would
// still resolve to a colour and pass any check made after it.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import 'support/brand_fixture.dart';

/// CoUI's own source, then the mappings a generated palette ships through.
final _kSources = <String, CoreSchemeSource>{
  'CoUI': CouiColorPresets.source,
  'standard': kBrandFixtureSource,
  // The retired monochrome reading stands in for any brand with a set of
  // its own built on the standard one.
  'monochrome': CoreSemanticMappingSet.monochrome.bind(kBrandFixturePalette),
};

const List<(CoreBrightness, bool)> _kModes = [
  (CoreBrightness.light, false),
  (CoreBrightness.dark, false),
  (CoreBrightness.light, true),
  (CoreBrightness.dark, true),
];

String _label((CoreBrightness, bool) mode) =>
    '${mode.$1.name}${mode.$2 ? ' high contrast' : ''}';

/// Every door into one mode: the builder, and for high contrast also the
/// raise applied to the normal builder — the one the theme seat takes.
Map<String, CoreColorScheme> _doors(
  CoreSchemeSource source,
  (CoreBrightness, bool) mode,
) => switch (mode) {
  (.light, false) => {'builder': source.light()},
  (.dark, false) => {'builder': source.dark()},
  (.light, true) => {
    'builder': source.highContrastLight(),
    'raise': source.raiseContrast(source.light(), .light),
  },
  (.dark, true) => {
    'builder': source.highContrastDark(),
    'raise': source.raiseContrast(source.dark(), .dark),
  },
};

CoreColorScheme _normal(CoreSchemeSource source, CoreBrightness b) =>
    b == .light ? source.light() : source.dark();

String _hex(CoreColor? c) => c!.toHex().toUpperCase();

void main() {
  group('CoreSyntaxPalette', () {
    test('six primitives under syntax/<hue>/<shade>, as authored', () {
      expect(
        CoreSyntaxPalette.primitives.map((k, v) => MapEntry(k, _hex(v))),
        {
          'syntax/purple/light': '#8956A9',
          'syntax/purple/dark': '#C792EA',
          'syntax/yellow/light': '#8C650A',
          'syntax/yellow/dark': '#FFCB6B',
          'syntax/lime/light': '#567516',
          'syntax/lime/dark': '#C3E88D',
        },
      );
    });

    test('primitiveLinks names the three brand-less slots, never '
        'syntax-function', () {
      expect(CoreSyntaxPalette.primitiveLinks(.light), {
        'syntax-keyword': 'syntax/purple/light',
        'syntax-type': 'syntax/yellow/light',
        'syntax-string': 'syntax/lime/light',
      });
      expect(CoreSyntaxPalette.primitiveLinks(.dark), {
        'syntax-keyword': 'syntax/purple/dark',
        'syntax-type': 'syntax/yellow/dark',
        'syntax-string': 'syntax/lime/dark',
      });
    });

    test('every link points at a primitive that exists', () {
      for (final b in CoreBrightness.values) {
        for (final name in CoreSyntaxPalette.primitiveLinks(b).values) {
          expect(CoreSyntaxPalette.primitives, contains(name));
        }
      }
    });

    test('syntaxPrimitiveTriplets carries the same six', () {
      expect(
        PrimitiveCssGenerator.syntaxPrimitiveTriplets().keys,
        CoreSyntaxPalette.primitives.keys,
      );
    });
  });

  group('the syntax primitives are no brand vocabulary', () {
    for (final MapEntry(key: name, value: source) in _kSources.entries) {
      test('$name keeps them out of its primitives', () {
        const namespace = '${CoreSyntaxPalette.namespace}/';
        expect(
          source.primitives.keys.where((k) => k.startsWith(namespace)),
          isEmpty,
        );
        expect(
          PrimitiveCssGenerator.primitiveVars(
            source,
          ).keys.where((k) => k.startsWith('--coui-syntax-')),
          isEmpty,
          reason: 'the Web emits only the semantic syntax slots',
        );
      });
    }
  });

  group('every mapping writes the syntax slots in every mode', () {
    for (final MapEntry(key: name, value: source) in _kSources.entries) {
      for (final mode in _kModes) {
        for (final MapEntry(key: door, value: scheme) in _doors(
          source,
          mode,
        ).entries) {
          test('$name ${_label(mode)} ($door)', () {
            // Function names read the brand's link step — the info step
            // already measured as text in the normal mode of this
            // brightness. High contrast keeps every normal value.
            final function = _normal(source, mode.$1).link!;
            for (final slot in CoreSyntaxSlot.values) {
              expect(
                _hex(slot.token.read(scheme)),
                _hex(
                  CoreSyntaxPalette.valueOf(slot, mode.$1, function: function),
                ),
                reason: slot.token.name,
              );
            }
          });
        }
      }
    }
  });

  group('high contrast leaves the syntax slots and surfaceRaised to the '
      'base', () {
    const sentinel = CoreColor(0xFF123456);
    for (final MapEntry(key: name, value: source) in _kSources.entries) {
      for (final b in CoreBrightness.values) {
        test('$name ${b.name}', () {
          final bent = _normal(source, b).copyWith(
            syntaxKeyword: sentinel,
            syntaxType: sentinel,
            syntaxFunction: sentinel,
            syntaxString: sentinel,
            surfaceRaised: sentinel,
          );
          final raised = source.raiseContrast(bent, b);
          for (final slot in [
            raised.syntaxKeyword,
            raised.syntaxType,
            raised.syntaxFunction,
            raised.syntaxString,
            raised.surfaceRaised,
          ]) {
            expect(_hex(slot), _hex(sentinel));
          }
        });
      }
    }
  });

  group('CoUI states the six new slots on its palette', () {
    const source = CouiColorPresets.source;
    final expected = <String, Map<String, String>>{
      'light': {
        'onSurfaceSubtle': '#737476',
        'surfaceRaised': '#FFFFFF',
        'syntaxKeyword': '#8956A9',
        'syntaxType': '#8C650A',
        'syntaxFunction': '#005EB2',
        'syntaxString': '#567516',
      },
      'dark': {
        'onSurfaceSubtle': '#939596',
        'surfaceRaised': '#404143',
        'syntaxKeyword': '#C792EA',
        'syntaxType': '#FFCB6B',
        'syntaxFunction': '#77B8FF',
        'syntaxString': '#C3E88D',
      },
      'highContrastLight': {
        'onSurfaceSubtle': '#58595A',
        'surfaceRaised': '#FFFFFF',
        'syntaxKeyword': '#8956A9',
        'syntaxType': '#8C650A',
        'syntaxFunction': '#005EB2',
        'syntaxString': '#567516',
      },
      'highContrastDark': {
        'onSurfaceSubtle': '#B4B5B6',
        'surfaceRaised': '#404143',
        'syntaxKeyword': '#C792EA',
        'syntaxType': '#FFCB6B',
        'syntaxFunction': '#77B8FF',
        'syntaxString': '#C3E88D',
      },
    };
    final schemes = {
      'light': source.light(),
      'dark': source.dark(),
      'highContrastLight': source.highContrastLight(),
      'highContrastDark': source.highContrastDark(),
    };

    for (final MapEntry(key: mode, value: slots) in expected.entries) {
      test(mode, () {
        final s = schemes[mode]!;
        expect({
          'onSurfaceSubtle': _hex(s.onSurfaceSubtle),
          'surfaceRaised': _hex(s.surfaceRaised),
          'syntaxKeyword': _hex(s.syntaxKeyword),
          'syntaxType': _hex(s.syntaxType),
          'syntaxFunction': _hex(s.syntaxFunction),
          'syntaxString': _hex(s.syntaxString),
        }, slots);
      });
    }
  });

  group('the standard mapping reads the new surface-text slots off its '
      'own steps', () {
    final source = kBrandFixtureSource;
    final schemes = {
      'light': source.light(),
      'dark': source.dark(),
      'high contrast light': source.highContrastLight(),
      'high contrast dark': source.highContrastDark(),
    };

    for (final MapEntry(key: mode, value: s) in schemes.entries) {
      test('$mode: onSurfaceSubtle is the placeholder step', () {
        expect(_hex(s.onSurfaceSubtle), _hex(s.placeholder));
      });
    }

    test('light: surfaceRaised is the page', () {
      expect(
        _hex(source.light().surfaceRaised),
        _hex(source.light().surface),
      );
    });

    test('dark: surfaceRaised is the topmost surface tone', () {
      expect(
        _hex(source.dark().surfaceRaised),
        _hex(source.dark().surfaceContainerHighest),
      );
    });
  });

  group('the Web emits the six slots in every mode', () {
    const keys = [
      'on-surface-subtle',
      'surface-raised',
      'syntax-keyword',
      'syntax-type',
      'syntax-function',
      'syntax-string',
    ];
    for (final MapEntry(key: name, value: source) in _kSources.entries) {
      for (final mode in _kModes) {
        test('$name ${_label(mode)}', () {
          final vars = PrimitiveCssGenerator.semanticVarsFor(
            source,
            mode.$1,
            highContrast: mode.$2,
          );
          for (final key in keys) {
            expect(vars, contains('--coui-$key'));
          }
        });
      }
    }
  });
}
