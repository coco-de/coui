// A disabled control still has to say which control it is.
//
// `disabledContent` and `disabledContainer` sit on the same neutral ramp —
// 1.89:1 in light, 3.02:1 in dark. That is the right amount of
// contrast for a *graphic*: a check mark or a chevron carries the off state
// better by being faint, and nobody needs to read it. It is the wrong
// amount for *text*, because the label is what tells someone which control
// is off and often how to turn it on. WCAG exempts disabled controls from
// the contrast floor; exempt and legible are different claims.
//
// So text drops one step to `onSurfaceVariant` instead, and this pins both
// halves: that the text moved, and that the two tokens are not
// interchangeable — otherwise a later simplification collapses them back.
//
// Two kinds of text are classified here, and they do not drop to the same
// token. The text a disabled control paints *on itself* — a field's value,
// the dial code — drops to `onSurfaceVariant`, the enabled secondary-text
// ink. The label a field *captions itself with* is
// already `onSurfaceVariant` while enabled (it names the control, the value
// is the louder line), so a disabled label held at the same token would be
// an enabled label; it drops one tier further to `onSurfaceSubtle` — still
// the text ladder, still above the 4.5:1 floor over the page it sits on
// (it hangs above the field, not on the disabled fill), and not the
// graphics ink. The census below keeps the two kinds apart so that a new
// disabled-text default has to choose which kind it is.
//
// `Chip` is classified out of that rule rather than exempted by name, and
// the classification is the designer's, with the measurement beside it. A
// chip states "off" with a faint label because the rest of its chrome
// cannot: the disabled unselected chip sits on `surface` — the page's own
// colour — so its fill says nothing, and against the enabled低 row the only
// other difference is the hairline. Holding the label at `onSurfaceVariant`
// there measures 7.00:1 light / 8.65:1 dark, which is not a disabled chip;
// it is a quiet one. Measured with `disabledContent`: 2.06:1 / 3.83:1 on
// `surface`, and 1.89:1 / 3.02:1 on the `disabledContainer` the SELECTED
// disabled chip fills with.
//
// These pairs are below the 4.5:1 text floor this file defends everywhere
// else, and the light ones are below the 3:1 graphics floor too: CoUI light
// draws `disabledContent` at neutral 400 (#5748) so an unusable control
// reads apart from a usable one. That is the trade the designer made
// knowingly (disabled controls are WCAG-exempt). It is recorded here rather than
// silenced so the next reader sees the number, not just the exception.
//
// `Label` and `FormLabel` are classified with the controls they caption, not
// with the labels a control paints on itself. A form sets `FormLabel` beside
// `Checkbox`, `RadioGroup` and `Toggle`, and those state "off" with
// `disabledContent`; a `Label` on `onSurfaceVariant` would leave one screen
// with two different disabled greys. Both captions therefore take
// `disabledContent` too, over the same `surface` the chip's unselected
// label sits on, so the numbers above are theirs as well.
//
// `Button` is classified with them, for the same reason `Label` is: a button
// is set beside the controls and captions that state "off" with
// `disabledContent`, and one that kept `onSurfaceVariant` read as an enabled
// quiet button next to them — that colour is the enabled secondary-text
// colour, so a disabled `outline`, `ghost` or `plain` button (no fill of its
// own to say "off") differed from an enabled one by nothing at all. Over the
// `disabledContainer` a filled button rests on the label lands at 1.89 : 1
// light / 3.02 : 1 dark, and over `surface` at 2.06 : 1 / 3.83 : 1; both are
// the rows the chip test below pins, and disabled controls are WCAG-exempt.
// That settles the question for these three. It stays open for every other
// label in the kit — except the text field's, which is decided above: it is
// a field's own caption, one tier below the enabled caption.
//
// A `NavigationBar` destination is classified with the controls by the same
// argument as a button: its resting label is already `onSurfaceVariant`, so a
// disabled destination that kept that colour would differ from an enabled
// unselected one by nothing at all. Its label and icon take `disabledContent`
// together, over the bar's own `surfaceContainerLow` face — 1.97 : 1 light /
// 3.51 : 1 dark, pinned below.
//
// The text inputs (`TextField` · `TextArea`, and `Select` through the field)
// are classified with the controls too, by the designer's decision in the
// input redesign (#5747): a disabled field's value and placeholder take
// `disabledContent`, the ink every other disabled control in the same form
// already states "off" with. Held at `onSurfaceVariant` a disabled field with
// text in it read like an enabled one on a grey fill. Over the
// `disabledContainer` the boxed field rests on that is the 4.28 : 1 light /
// 3.02 : 1 dark pair the chip pins, below the text floor and WCAG-exempt —
// pinned below so the next palette move re-decides with the number in view.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

double _contrast(int a, int b) =>
    CoreContrast.ratio(CoreColor(a), CoreColor(b));

/// The everyday modes.
Map<String, CoreColorScheme> _normalSchemes() {
  const source = CouiColorPresets.source;
  return {'light': source.light(), 'dark': source.dark()};
}

/// The modes someone turned on because they needed to read the screen.
Map<String, CoreColorScheme> _highContrastSchemes() {
  const source = CouiColorPresets.source;
  return {
    'high-contrast light': source.highContrastLight(),
    'high-contrast dark': source.highContrastDark(),
  };
}

Map<String, CoreColorScheme> _schemes() => {
  ..._normalSchemes(),
  ..._highContrastSchemes(),
};

int _argb(CoreColorScheme scheme, CoreColorToken token) =>
    scheme.resolve(CoreColor.token(token)).argb | 0xFF000000;

/// The disabled **captions** a field composes — the label above the box,
/// stated by the field itself. Enabled, the caption is `onSurfaceVariant`,
/// so disabled it is one tier below that, named by where it lives.
Map<String, CoreColor> _disabledFieldLabelDefaults() => {
  'text_field label': CoreTextFieldStyle.defaultLabelDisabledColor,
  'text_area label': CoreTextAreaStyle.defaultLabelDisabledColor,
};

/// Every default that paints a disabled component's own **text** as a
/// caption rather than as a control's value, named by where it lives so a
/// failure says which component regressed. (The phone input's dial code is
/// the value of a control — classified with the controls below.)
Map<String, CoreColor> _disabledLabelDefaults() => const {};

/// A text input's disabled value and placeholder — classified with the
/// controls (header, #5747), every variant.
Map<String, CoreColor> _textInputDisabledDefaults() => {
  for (final entry in CoreTextFieldStyle.defaultsByVariant.entries)
    'text_field ${entry.key.name}': entry.value.disabledForegroundColor,
  for (final entry in CoreTextAreaStyle.defaultsByVariant.entries)
    'text_area ${entry.key.name}': entry.value.disabledForegroundColor,
};

/// Guards the census itself: if a component grows a disabled-label default
/// and nobody adds it above, the map silently stops describing the system.
/// This is the count the sweep actually found, so a new one has to be
/// classified — text or graphic — rather than slipping in unclassified. The
/// two maps above together are the census: the captions a field composes
/// and the text a control paints on itself.
const _censusSize = 2;

/// The labels that caption a control — classified with the control they sit
/// beside (header), so they state "off" with the same ink it does. Named by
/// where they live, like the census, so a failure says which one regressed.
Map<String, CoreColor> _captionLabelDefaults() => {
  'label disabled text': CoreLabelStyle.defaultDisabledTextStyle.color!,
  'form_label disabled': CoreFormLabelStyle.defaultDisabledColor,
};

/// A navigation destination's disabled label and icon — classified with the
/// controls (header): its resting label is the enabled secondary-text colour
/// already, so "off" has to be a different ink. The label carries its colour
/// inside a text style rather than as a bare slot — same claim, different
/// shape.
Map<String, CoreColor> _navigationDisabledDefaults() => {
  'navigation_bar disabled label':
      CoreNavigationBarStyle.defaultDisabledLabelTextStyle.color!,
  'navigation_bar disabled icon':
      CoreNavigationBarStyle.defaultDisabledIconStyle.color!,
};

/// Every button variant's disabled label — classified with the controls it
/// is set beside (header), so it states "off" with their ink.
Map<String, CoreColor> _buttonDisabledLabelDefaults() => {
  for (final entry in CoreButtonStyle.defaultsByVariant.entries)
    'button ${entry.key.name}': entry.value.disabledForegroundColor,
};

/// Chip's disabled labels — classified as "faint on purpose" (header), and
/// held to the two fills they actually sit on so the classification cannot
/// quietly become "any contrast is fine".
Map<String, ({CoreColor label, CoreColorToken fill})> _chipDisabledLabels() => {
  'chip custom-seed label': (
    label: CoreChipStyle.defaultCustomDisabledForegroundColor,
    fill: CoreColors.disabledContainer,
  ),
  for (final entry in CoreChipStyle.defaultsByColor.entries) ...{
    'chip ${entry.key.name} selected': (
      label: entry.value.disabledFg,
      fill: CoreColors.disabledContainer,
    ),
    'chip ${entry.key.name} unselected': (
      label: entry.value.disabledFg,
      fill: CoreColors.surface,
    ),
  },
};

void main() {
  group('a disabled label stays readable', () {
    test('every disabled label default is one step down, not graphics ink', () {
      const wanted = CoreColor.token(CoreColors.onSurfaceVariant);
      expect(
        _disabledLabelDefaults().length + _disabledFieldLabelDefaults().length,
        _censusSize,
        reason:
            'a disabled-label default appeared or vanished — classify it as '
            'text or graphic and update the census',
      );

      _disabledLabelDefaults().forEach((where, color) {
        expect(
          color,
          wanted,
          reason:
              '$where paints text, so it drops one step to onSurfaceVariant '
              'rather than the graphics-only disabledContent',
        );
      });
    });

    // A field's caption is already onSurfaceVariant while enabled; the
    // disabled one is the next text tier down. Held at the enabled token it
    // would be an enabled label, and held at `disabledContent` it would be
    // graphics ink on text.
    test('a field caption steps one tier below its enabled caption', () {
      const wanted = CoreColor.token(CoreColors.onSurfaceSubtle);
      final enabled = CoreFormLabelStyle.defaultLabelStyle.color;
      expect(
        _disabledFieldLabelDefaults(),
        hasLength(2),
        reason: 'a field caption appeared or vanished — classify it',
      );

      _disabledFieldLabelDefaults().forEach((where, color) {
        expect(color, wanted, reason: where);
        expect(color, isNot(enabled), reason: '$where reads as enabled');
        expect(
          color,
          isNot(const CoreColor.token(CoreColors.disabledContent)),
          reason: '$where is text, not graphics ink',
        );
      });
    });

    // The caption hangs above the box on the page, not on the disabled fill,
    // so the page is the ground it is measured on — and it clears the text
    // floor in every mode, the everyday and the asked-for-contrast ones.
    test('and a field caption clears 4.5:1 over the page in every mode', () {
      _schemes().forEach((mode, scheme) {
        final ratio = _contrast(
          _argb(scheme, CoreColors.onSurfaceSubtle),
          _argb(scheme, CoreColors.surface),
        );

        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$mode — got ${ratio.toStringAsFixed(2)}:1',
        );
      });
    });

    // Every variant, `fixed` and the two menu rows included: the rule is that
    // a disabled button label is one colour, so a variant that kept a private
    // grey would be the one case where two disabled buttons side by side
    // stop matching.
    test('a button states off with the ink of the controls it sits beside', () {
      const wanted = CoreColor.token(CoreColors.disabledContent);
      expect(
        _buttonDisabledLabelDefaults(),
        hasLength(CoreButtonVariant.values.length),
        reason:
            'a button variant appeared or vanished — it owes a disabled label',
      );

      _buttonDisabledLabelDefaults().forEach((where, color) {
        expect(color, wanted, reason: where);
      });
    });

    test("a text input states off with the controls' ink, measured on its "
        'disabled fill', () {
      const wanted = CoreColor.token(CoreColors.disabledContent);
      expect(
        _textInputDisabledDefaults(),
        hasLength(
          CoreTextFieldVariant.values.length +
              CoreTextAreaVariant.values.length,
        ),
        reason: 'a text input variant appeared or vanished — classify it',
      );
      _textInputDisabledDefaults().forEach((where, color) {
        expect(color, wanted, reason: where);
      });
    });

    test("a phone input dial code states off with the controls' ink", () {
      expect(
        CorePhoneInputStyle.defaultDisabledDialCodeColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    test("a navigation destination states off with the controls' ink, "
        'measured on its bar', () {
      const wanted = CoreColor.token(CoreColors.disabledContent);
      _navigationDisabledDefaults().forEach((where, color) {
        expect(color, wanted, reason: where);
      });

      const bounds = {'light': 1.97, 'dark': 3.51};
      final face = CoreNavigationBarStyle
          .defaultsByVariant[CoreNavigationBarVariant.standard]!
          .backgroundColor;
      _normalSchemes().forEach((mode, scheme) {
        final ratio = _contrast(
          _argb(scheme, CoreColors.disabledContent),
          scheme.resolve(face).argb | 0xFF000000,
        );
        expect(
          ratio,
          closeTo(bounds[mode]!, 0.05),
          reason: '$mode — got ${ratio.toStringAsFixed(2)}:1',
        );
      });
    });

    test('chip states off with the graphics ink, and it is measured', () {
      // Not "chip is exempt" — chip is classified, and the classification
      // carries the numbers. If the palette moves these, this fails and
      // someone re-decides with the new values in front of them.
      const wanted = CoreColor.token(CoreColors.disabledContent);
      for (final entry in _chipDisabledLabels().entries) {
        expect(entry.value.label, wanted, reason: entry.key);
      }

      const bounds = {
        // (fill, mode) → the ratio the label lands at, ±0.05.
        'light disabledContainer': 1.89,
        'dark disabledContainer': 3.02,
        'light surface': 2.06,
        'dark surface': 3.83,
      };
      _normalSchemes().forEach((mode, scheme) {
        for (final fill in [CoreColors.disabledContainer, CoreColors.surface]) {
          final ratio = _contrast(
            _argb(scheme, CoreColors.disabledContent),
            _argb(scheme, fill),
          );
          final ground = fill.name.contains('container')
              ? 'disabledContainer'
              : 'surface';
          final key = '$mode $ground';
          expect(
            ratio,
            closeTo(bounds[key]!, 0.05),
            reason: '$key — got ${ratio.toStringAsFixed(2)}:1',
          );
        }
      });
    });

    test('and that step clears 4.5:1 over the disabled fill', () {
      _schemes().forEach((mode, scheme) {
        final ratio = _contrast(
          _argb(scheme, CoreColors.onSurfaceVariant),
          _argb(scheme, CoreColors.disabledContainer),
        );

        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$mode — got ${ratio.toStringAsFixed(2)}:1',
        );
      });
    });

    // Without this the assertion above would also pass if someone pointed
    // `disabledContent` at `onSurfaceVariant` and called the job done —
    // which would take the off-state signal away from the graphics that
    // legitimately want to be faint.
    test('the graphics token stays faint in the everyday modes', () {
      _normalSchemes().forEach((mode, scheme) {
        final ratio = _contrast(
          _argb(scheme, CoreColors.disabledContent),
          _argb(scheme, CoreColors.disabledContainer),
        );

        expect(
          ratio,
          lessThan(4.5),
          reason:
              '$mode — disabledContent is deliberately below the text floor; '
              'if it now clears it, the two tokens have collapsed into one',
        );
      });
    });

    // …but not when someone asked for contrast. The high-contrast mapping
    // reinterprets both tokens, so the graphic that is faint by design in
    // the everyday modes comes up with everything else — a faint glyph is a
    // deliberate signal, not an exemption from the setting. This is also the
    // evidence that the accessibility axis reaches these two slots at all.
    test('and comes up when someone asks for contrast', () {
      _highContrastSchemes().forEach((mode, scheme) {
        final ratio = _contrast(
          _argb(scheme, CoreColors.disabledContent),
          _argb(scheme, CoreColors.disabledContainer),
        );

        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: '$mode — got ${ratio.toStringAsFixed(2)}:1',
        );
      });
    });

    // A token nothing reads is dead whatever its documentation says. The
    // label sweep took `disabledContent` down to a single consumer, so name
    // it here: if that one goes, the token goes with it rather than
    // lingering as a slot the next person authors against.
    test('the graphics token still has a consumer', () {
      expect(
        CorePhoneInputStyle.defaultDisabledChevronColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    // The two captions are one disabled grey on a form, not two. If either
    // drifts back to `onSurfaceVariant`, a disabled `Label` and a disabled
    // `FormLabel` set side by side stop matching.
    test(
      'a caption label states off with the ink of the controls it captions',
      () {
        const wanted = CoreColor.token(CoreColors.disabledContent);
        expect(
          _captionLabelDefaults(),
          hasLength(2),
          reason: 'a caption label appeared or vanished — classify it',
        );

        _captionLabelDefaults().forEach((where, color) {
          expect(color, wanted, reason: where);
        });
      },
    );

    // The everyday numbers for these captions are the `surface` rows the
    // chip test above already pins. Someone who asked for contrast gets a
    // legible caption too — the accessibility axis reaches this slot.
    test(
      'and a caption stays legible over surface when contrast is asked for',
      () {
        _highContrastSchemes().forEach((mode, scheme) {
          final ratio = _contrast(
            _argb(scheme, CoreColors.disabledContent),
            _argb(scheme, CoreColors.surface),
          );

          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$mode — got ${ratio.toStringAsFixed(2)}:1',
          );
        });
      },
    );
  });
}
