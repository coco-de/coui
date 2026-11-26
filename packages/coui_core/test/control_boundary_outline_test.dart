// A control's resting edge is its only boundary, so it has to read as one:
// WCAG 1.4.11 asks 3:1 for the part of a control that identifies it. The
// hairline `outline-variant` lands near 1.25 against a white surface, which is
// the failure this file pins away from — the controls in the first two groups
// rest on `outline` instead.
//
// The text inputs (TextField · TextArea · InputOTP · the ChipInput frame, and
// Select through TextField) are the exception the input redesign (#5747)
// chose: a form of several fields reads as a page of lines when every resting
// edge is `outline`, so they rest on `outline-variant` and step to `outline`
// under the pointer, with focus and error keeping their own full-contrast
// boundary. The last group pins that choice so it cannot drift back
// unannounced — or spread to the controls in the first two groups.
//
// What is pinned here is the *declared* token on each control's Core default
// (the resolvers read nothing else, so the token is the single source) and the
// contrast that token actually delivers in every mode the scheme ships.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const CoreColor _outline = CoreColor.token(CoreColors.outline);

/// WCAG 2.2 SC 1.4.11 non-text contrast floor.
const double _nonTextFloor = 3;

/// The resting edge of every control the redesign moved onto `outline`, keyed
/// by the name the issue uses.
Map<String, CoreColor> _restingEdges() => {
  // TimePicker is not listed: its hour / minute segment is a filled tile
  // (`surface-container-high`, no edge of its own), so the segment border is
  // transparent and the boundary is the face.
  'Checkbox': CoreCheckboxStyle.defaultBoxBorderColor,
  'RadioGroup': CoreRadioGroupStyle
      .defaultsByVariant[CoreRadioGroupVariant.defaultVariant]!
      .borderColor,
  // FileInput is not listed either: its dashed drop zone rests on the pale
  // `outline-variant` (designer decision, the zone is a drop target rather
  // than a control edge), and a drag over it takes `primary`.
  // MultipleChoice is not listed: its option is a composed Chip, so the
  // resting edge is the Chip's own (a quiet `outline-variant`, the
  // hairline the Chip family rests on), not a control boundary declared
  // here.
};

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

double _contrast(int a, int b) =>
    CoreContrast.ratio(CoreColor(a), CoreColor(b));

void main() {
  group('control boundary — the resting edge is `outline`', () {
    for (final entry in _restingEdges().entries) {
      test('${entry.key} rests on outline', () {
        expect(entry.value, _outline);
      });
    }

    test('all controls are covered', () {
      expect(_restingEdges(), hasLength(2));
    });
  });

  group('control boundary — the glyph-entry controls step to `on-surface` '
      'under the pointer', () {
    const onSurface = CoreColor.token(CoreColors.onSurface);

    // The glyph-entry controls that take the full-contrast step; the text
    // inputs step to `outline` in the last group. The three selection controls
    // (Checkbox · RadioGroup · MultipleChoice) keep the state layer for hover
    // and state no hover border.
    final hoverSteps = <String, CoreColor>{
      'FileInput': CoreFileInputStyle.defaultHoverBorderColor,
    };

    for (final entry in hoverSteps.entries) {
      test('${entry.key} hovers on on-surface', () {
        expect(entry.value, onSurface);
      });
    }

    test('all controls are covered', () {
      expect(hoverSteps, hasLength(1));
    });

    _schemes().forEach((mode, scheme) {
      test('$mode: the step is perceptible against the resting edge', () {
        final ratio = _contrast(
          _argb(scheme, _outline),
          _argb(scheme, onSurface),
        );
        expect(
          ratio,
          greaterThan(1.02),
          reason:
              '$mode — `outline` → `on-surface` lands on '
              '${ratio.toStringAsFixed(3)}:1, a hover that draws nothing',
        );
      });
    });

    test('an error control restates its error edge — the pointer does not '
        'soften it', () {
      const error = CoreColor.token(CoreColors.error);
      expect(
        CoreTextFieldStyle
            .defaultsByVariant[CoreTextFieldVariant.error]!
            .hoverBorderColor,
        error,
      );
      expect(
        CoreTextAreaStyle
            .defaultsByVariant[CoreTextAreaVariant.error]!
            .hoverBorderColor,
        error,
      );
      expect(
        CoreInputOtpStyle
            .defaultsByVariant[CoreInputOtpVariant.error]!
            .hoverBorderColor,
        error,
      );
    });
  });

  group('control boundary — the edge clears 3:1 against the surface it sits '
      'on, in every mode', () {
    const surface = CoreColor.token(CoreColors.surface);

    _schemes().forEach((mode, scheme) {
      test('$mode: outline vs surface >= 3:1', () {
        final ratio = _contrast(
          _argb(scheme, _outline),
          _argb(scheme, surface),
        );
        expect(
          ratio,
          greaterThanOrEqualTo(_nonTextFloor),
          reason:
              '$mode — `outline` reads ${ratio.toStringAsFixed(2)}:1 on the '
              'surface; a control edge below $_nonTextFloor:1 is not a '
              'boundary',
        );
      });
    });
  });

  group('the text inputs rest one tone quieter (#5747)', () {
    const outlineVariant = CoreColor.token(CoreColors.outlineVariant);
    // The default field's merge-chain head: InputOTP states its edge as a
    // static default, so the head is where an override of it would show.
    final otpHead = CoreInputOtpStyle.chainHeadFor(
      CoreInputOtpSize.md,
      CoreInputOtpVariant.defaultVariant,
    );
    final rows = <String, Object>{
      'TextField': CoreTextFieldStyle
          .defaultsByVariant[CoreTextFieldVariant.defaultVariant]!,
      'TextArea': CoreTextAreaStyle
          .defaultsByVariant[CoreTextAreaVariant.defaultVariant]!,
      'InputOTP': otpHead,
    };
    test('TextField rests on outline-variant and hovers on outline', () {
      final row = CoreTextFieldStyle
          .defaultsByVariant[CoreTextFieldVariant.defaultVariant]!;
      expect(row.borderColor, outlineVariant);
      expect(row.hoverBorderColor, _outline);
    });
    test('TextArea rests on outline-variant and hovers on outline', () {
      final row = CoreTextAreaStyle
          .defaultsByVariant[CoreTextAreaVariant.defaultVariant]!;
      expect(row.borderColor, outlineVariant);
      expect(row.hoverBorderColor, _outline);
    });
    test('ChipInput frame rests on outline-variant and hovers on outline', () {
      expect(CoreChipInputStyle.defaultBorderColor, outlineVariant);
      expect(CoreChipInputStyle.defaultHoverBorderColor, _outline);
    });
    test('InputOTP rests on outline-variant and hovers on outline', () {
      // The resolvers read `merged.X ?? head.X ?? CoreInputOtpStyle.defaultX`,
      // so the default field's edge is the head's value or the static default.
      expect(
        otpHead.borderColor ?? CoreInputOtpStyle.defaultBorderColor,
        outlineVariant,
      );
      expect(
        otpHead.hoverBorderColor ?? CoreInputOtpStyle.defaultHoverBorderColor,
        _outline,
      );
    });
    test('all three inputs are covered', () => expect(rows, hasLength(3)));
  });
}
