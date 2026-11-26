// The selected-face gap contract (`CorePrimaryContainerGap`) over real and
// generated brands, in all four modes.
//
// Which values the contract fails on is decided by shape, not by a list of
// brand names: a brand's `primaryContainer` that equals what the standard
// mapping would draw from the same palette is the GENERATOR's choice, and the
// contract holds it — gap, and the text drawn on the face. A brand that states
// its own face (it differs from the standard reading) made a decision the
// generator did not, so its shortfall is reported, not failed. CoUI reads its
// fixed palette through its own mapping, so every CoUI face is stated — and
// the contract's thresholds were chosen to pass it, which the CoUI group
// holds separately.
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import '../bin/figma_brands/brands.dart';

typedef _Mode = ({String name, CoreBrightness brightness, bool highContrast});

const List<_Mode> _kModes = [
  (name: 'Light', brightness: .light, highContrast: false),
  (name: 'Dark', brightness: .dark, highContrast: false),
  (name: 'HCLight', brightness: .light, highContrast: true),
  (name: 'HCDark', brightness: .dark, highContrast: true),
];

CoreColorScheme _schemeOf(CoreSchemeSource source, _Mode mode) =>
    switch ((mode.brightness, mode.highContrast)) {
      (.light, false) => source.light(),
      (.dark, false) => source.dark(),
      (.light, true) => source.highContrastLight(),
      (.dark, true) => source.highContrastDark(),
    };

/// One brand in one mode, measured.
final class _Reading {
  _Reading(this.brand, this.mode, CoreColorScheme scheme, {this.stated = true})
    : container = scheme.primaryContainer!,
      gap = CoreContrast.ratio(scheme.primaryContainer!, scheme.surface!),
      onContainer = CoreContrast.ratio(
        scheme.onPrimaryContainer!,
        scheme.primaryContainer!,
      ),
      primaryText = CoreContrast.ratio(
        scheme.primaryText!,
        scheme.primaryContainer!,
      );

  final String brand;
  final _Mode mode;
  final CoreColor container;
  final double gap;
  final double onContainer;
  final double primaryText;

  /// Whether the brand states this face itself (it differs from the standard
  /// reading of its palette) rather than taking the generator's.
  final bool stated;

  bool get keepsGap =>
      gap >= CorePrimaryContainerGap.minimumFor(mode.brightness);

  bool get keepsText =>
      CorePrimaryContainerGap.onContainerLevel.isMetBy(onContainer) &&
      CorePrimaryContainerGap.primaryTextLevel.isMetBy(primaryText);

  bool get holds => keepsGap && keepsText;

  @override
  String toString() =>
      '$brand ${mode.name}: gap ${gap.toStringAsFixed(2)} '
      'on-primary-container ${onContainer.toStringAsFixed(2)} '
      'primary-text ${primaryText.toStringAsFixed(2)}'
      '${stated ? ' (stated)' : ''}';
}

List<_Reading> _readingsOf(String brand, CoreSchemeSource source) {
  // The standard reading of the same palette — what the generator draws.
  final standard = source is CorePrimitiveSchemeSource
      ? CorePrimitiveSchemeSource(source.palette)
      : null;

  return [
    for (final mode in _kModes)
      _Reading(
        brand,
        mode,
        _schemeOf(source, mode),
        stated:
            standard == null ||
            _schemeOf(source, mode).primaryContainer!.argb !=
                _schemeOf(standard, mode).primaryContainer!.argb,
      ),
  ];
}

/// The generated sample: one brand per hue family, the rest of the seeds
/// shared, so the hue is the only thing that moves the face.
PrimitiveColors _generated(double hue) => PrimitiveColors.generate(
  primaryHSL: (h: hue, s: 0.75, l: 0.5),
  secondaryHSL: (h: (hue + 30) % 360, s: 0.6, l: 0.45),
  tertiaryHSL: (h: (hue + 60) % 360, s: 0.6, l: 0.45),
  successHSL: (h: 140, s: 0.70, l: 0.30),
  infoHSL: (h: 200, s: 0.75, l: 0.38),
  warningHSL: (h: 45, s: 0.85, l: 0.50),
  errorHSL: (h: 0, s: 0.75, l: 0.50),
  neutralHue: 220,
);

const Map<String, double> _kSampleHues = {
  'blue': 220,
  'red': 0,
  'orange': 25,
  'yellow': 50,
  'green': 140,
  'teal': 180,
  'purple': 270,
  'pink': 330,
};

/// The step the standard mapping is expected to draw `primaryContainer` at,
/// counted from the default (`lightest` on light, `darker` on dark) away from
/// the page. Measured when the contract went in; a change here means the
/// palette generator or the contract moved, and the table in the issue that
/// decided the contract no longer describes the shipped brands.
const Map<String, ({int light, int dark})> _kExpectedSteps = {
  'unibook': (light: 0, dark: 1),
  'gen-blue': (light: 0, dark: 1),
  'gen-red': (light: 0, dark: 1),
  'gen-orange': (light: 1, dark: 0),
  'gen-yellow': (light: 2, dark: 0),
  'gen-green': (light: 2, dark: 0),
  'gen-teal': (light: 2, dark: 0),
  'gen-purple': (light: 0, dark: 1),
  'gen-pink': (light: 0, dark: 1),
};

int _stepOf(PrimitiveColors c, CoreBrightness brightness, CoreColor face) {
  final ladder = brightness == .dark
      ? [c.primary.darker, c.primary.dark, c.primary.base]
      : [c.primary.lightest, c.primary.lighter, c.primary.light];
  // A scheme stamps its slot's token on the colour, so match by value.
  return ladder.indexWhere((step) => step.argb == face.argb);
}

void main() {
  final brands = <String, CoreSchemeSource>{
    for (final brand in kFigmaBrands.all) brand.id: brand.source,
    for (final MapEntry(:key, :value) in _kSampleHues.entries)
      'gen-$key': CorePrimitiveSchemeSource(_generated(value)),
  };
  final readings = [
    for (final MapEntry(:key, :value) in brands.entries)
      ..._readingsOf(key, value),
  ];

  setUpAll(() {
    // The full table on every run — the stated faces' shortfalls are only
    // reported, so this is where a person reads them.
    stdout.writeln('primaryContainer ↔ surface gap contract:');
    for (final r in readings) {
      stdout.writeln('  ${r.holds ? 'ok  ' : 'SHORT'} $r');
    }
  });

  group('faces the generator chose', () {
    for (final r in readings.where((r) => !r.stated)) {
      test('${r.brand} ${r.mode.name} keeps the gap and the text on it', () {
        expect(
          r.gap,
          greaterThanOrEqualTo(
            CorePrimaryContainerGap.minimumFor(r.mode.brightness),
          ),
          reason: '$r — more than two steps would be needed; a person looks',
        );
        expect(
          r.onContainer,
          greaterThanOrEqualTo(
            CorePrimaryContainerGap.onContainerLevel.minimumRatio,
          ),
          reason: '$r',
        );
        expect(
          r.primaryText,
          greaterThanOrEqualTo(
            CorePrimaryContainerGap.primaryTextLevel.minimumRatio,
          ),
          reason: '$r',
        );
      });
    }
  });

  test('a stated face is reported, not held — Medibooks states its own', () {
    final medibooks = readings.where((r) => r.brand == 'medibooks');
    expect(medibooks.every((r) => r.stated), isTrue);
    // Today's values, kept by the statement: the shortfall is what the
    // report lists.
    expect(medibooks.where((r) => !r.keepsGap), isNotEmpty);
  });

  test('Medibooks keeps its selected face in every mode', () {
    final source = kFigmaBrands['medibooks'].source;
    for (final mode in _kModes) {
      final face = _schemeOf(source, mode).primaryContainer!;
      expect(
        face.argb,
        mode.brightness == .dark ? 0xFF003520 : 0xFFDAF3E4,
        reason: mode.name,
      );
    }
  });

  test('CoUI keeps the contract in every mode', () {
    for (final r in readings.where((r) => r.brand == 'coui')) {
      expect(r.holds, isTrue, reason: '$r');
    }
  });

  test(
    'the standard mapping moves each brand the measured number of steps',
    () {
      for (final MapEntry(key: id, value: steps) in _kExpectedSteps.entries) {
        final source = brands[id]! as CorePrimitiveSchemeSource;
        for (final mode in _kModes) {
          final face = _schemeOf(source, mode).primaryContainer!;
          expect(
            _stepOf(source.palette, mode.brightness, face),
            mode.brightness == .dark ? steps.dark : steps.light,
            reason: '$id ${mode.name}',
          );
        }
      }
    },
  );

  group('CorePrimaryContainerGap.pick', () {
    const white = CoreColor(0xFFFFFFFF);
    const black = CoreColor(0xFF000000);
    const near = CoreColor(0xFFF5F5F5); // 1.09 on white
    const mid = CoreColor(0xFFDDDDDD); // 1.36 on white
    const far = CoreColor(0xFFBBBBBB); // 1.92 on white

    CoreColor pick(List<CoreColor> ladder, {CoreColor text = black}) =>
        CorePrimaryContainerGap.pick(
          ladder,
          surface: white,
          onContainer: text,
          primaryText: text,
          brightness: .light,
        );

    test('keeps the default step when it already keeps the gap', () {
      expect(pick([mid, far, far]), mid);
    });

    test('takes the first step away from the page that keeps the gap', () {
      expect(pick([near, mid, far]), mid);
      expect(pick([near, near, mid]), mid);
    });

    test('does not move at all when two steps are not enough', () {
      expect(pick([near, near, near, mid]), near);
    });

    test('does not move when the step that keeps the gap costs the text', () {
      // White text on the moved face: far under 4.5:1.
      expect(pick([near, mid, far], text: white), near);
    });

    test('holds the text on a moved face to 7:1 in a high-contrast mode', () {
      // #555555 on the moved face is about 5.5:1 — the normal bar, not the
      // high-contrast one.
      const grey = CoreColor(0xFF555555);
      CoreColor pickHc({required bool highContrast}) =>
          CorePrimaryContainerGap.pick(
            [near, mid, far],
            surface: white,
            onContainer: grey,
            primaryText: black,
            brightness: .light,
            highContrast: highContrast,
          );

      expect(
        CoreContrast.ratio(grey, mid),
        inInclusiveRange(4.5, 7),
        reason: 'the probe must sit between the two bars',
      );
      expect(pickHc(highContrast: false), mid);
      expect(pickHc(highContrast: true), near);
    });
  });
}
