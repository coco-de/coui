// A hovered destination has to look hovered — and not look like a hole.
//
// Two claims live here, and the second is why this file exists at all.
//
// The first is the one every `CoreStateLayer` adopter owes: the ramp sits
// outside the alpha-parity guard's net, so a component taking the type has
// to show that its own composited states actually differ. That is the same
// deal `button_state_change_perceptibility_test` struck for Button.
//
// The second is specific to this component. Hover is a state layer, not a
// token SWAP to a neighbouring surface tone: where that tone is exactly the
// page colour, hovering a destination paints the page into the bar and the
// item reads as a hole punched through it. Nothing would catch that: read
// either state alone and both are legitimate colours, and the contrast
// guard reads the scheme, not this pairing. So the pairing is what gets
// read here.

// The schemes are CoUI's own source (`CouiColorPresets.source`) — the
// look this product ships. A generated palette read through a mapping is
// the brand path and would measure a palette nobody sees here.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

double _contrast(int a, int b) =>
    CoreContrast.ratio(CoreColor(a), CoreColor(b));

/// The same arithmetic `Color.alphaBlend` performs on Flutter and
/// `color-mix(in srgb, …)` performs on Web, so one measurement answers for
/// both platforms.
int _blend(int over, int base, double alpha) {
  int channel(int shift) {
    final o = (over >> shift) & 0xFF;
    final b = (base >> shift) & 0xFF;
    return (o * alpha + b * (1 - alpha)).round();
  }

  return 0xFF000000 | (channel(16) << 16) | (channel(8) << 8) | channel(0);
}

const double _perceptibleFloor = 1.02;

Map<String, CoreColorScheme> _normalSchemes() {
  const source = CouiColorPresets.source;
  return {'light': source.light(), 'dark': source.dark()};
}

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

void main() {
  const layer = CoreNavigationBarStyle.defaultStateLayer;
  const ink = CoreNavigationBarStyle.defaultStateLayerColor;

  group('NavigationBar states a ramp of its own', () {
    // The pressed wash is the one weight that is not the subtle tier's.
    // Both a 12 % and an 8 % pressed fill leave the unselected label over
    // the 4.5 floor, so the floor does not choose; 8 % is the weight this
    // component keeps (the per-mode figures are read back below). Hover
    // and focus are the subtle tier's unchanged. The accepted cost is that
    // focus and pressed are the same strength, so pressing a
    // keyboard-focused destination does not visibly change it.
    test('the default is 3 / 8 / 8', () {
      expect([layer.hover, layer.focus, layer.pressed], [0.03, 0.08, 0.08]);
      expect(layer.pressed, CoreOpacity.opacity8);
    });

    test("hover and focus are the subtle tier's, pressed is not", () {
      expect(layer.hover, CoreStateLayer.subtle.hover);
      expect(layer.focus, CoreStateLayer.subtle.focus);
      expect(layer.pressed, lessThan(CoreStateLayer.subtle.pressed));
    });

    test('focus equals pressed, and the ramp is still non-decreasing', () {
      // Stated rather than hidden: the designer accepted this. The
      // invariant `CoreStateLayer.isAscending` names is "never weaker than
      // the step before", not "strictly stronger".
      expect(layer.focus, layer.pressed);
      expect(layer.isAscending, isTrue);
    });

    test('the shared subtle ramp is untouched, and its readers keep it', () {
      expect(
        [
          CoreStateLayer.subtle.hover,
          CoreStateLayer.subtle.focus,
          CoreStateLayer.subtle.pressed,
        ],
        [0.03, 0.08, 0.12],
      );
      expect(CoreChipStyle.defaultStateLayer, CoreStateLayer.subtle);
      expect(
        CoreTextFieldStyle.defaultPlainVariant.stateLayer,
        CoreStateLayer.subtle,
      );
    });

    test('the unselected label over the pressed wash, measured per mode', () {
      // Read back off the real schemes over the bar's chrome-tier face
      // (`surfaceContainerLow`). The unselected label is `onSurfaceSubtle`,
      // a step quieter than the selected one, and under the pressed wash it
      // sits below 4.5 in light and dark — the designer accepted that so the
      // selected destination reads at a glance (the unselected Tabs take
      // the same tone). A drift past the tolerance means the wash, the face
      // or the label colour moved and the exception deserves a fresh look.
      const expected = {
        'light': 3.848,
        'dark': 4.333,
        'high-contrast light': 5.617,
        'high-contrast dark': 6.256,
      };
      final chrome = CoreNavigationBarStyle
          .defaultsByVariant[CoreNavigationBarVariant.standard]!;
      _schemes().forEach((mode, scheme) {
        final bar = _argb(scheme, chrome.backgroundColor);
        final pressed = _blend(_argb(scheme, ink), bar, layer.pressed);
        final label = _argb(
          scheme,
          CoreNavigationBarStyle.defaultLabelTextStyle.color!,
        );
        expect(
          _contrast(label, pressed),
          closeTo(expected[mode]!, 0.005),
          reason: '$mode — unselected label over the pressed wash',
        );
      });
    });
  });

  group('a NavigationBar destination says when it is interacted with', () {
    test('the ramp is stated and ascends', () {
      expect(layer, isNotNull);
      expect(layer.isAscending, isTrue);
    });

    test('hover paints no fill of its own by default', () {
      // The swap and the ramp are alternatives, never a stack. If the
      // default ever grows a token again, the two mechanisms are both live
      // and which one wins becomes an accident of resolver order.
      expect(
        CoreNavigationBarStyle.defaultHoverBackgroundColor.token,
        isNull,
        reason:
            'a token here means the swap is back on the default path and '
            'the state layer is painting underneath something opaque',
      );
    });

    for (final variant in CoreNavigationBarVariant.values) {
      final chrome = CoreNavigationBarStyle.defaultsByVariant[variant]!;

      test('${variant.name} — every state differs from rest, in every '
          'mode', () {
        _schemes().forEach((mode, scheme) {
          final bar = _argb(scheme, chrome.backgroundColor);
          final over = _argb(scheme, ink);

          for (final entry in <String, double>{
            'hover': layer.hover,
            'focus': layer.focus,
            'pressed': layer.pressed,
          }.entries) {
            final washed = _blend(over, bar, entry.value);
            final delta = _contrast(washed, bar);
            expect(
              delta,
              greaterThanOrEqualTo(_perceptibleFloor),
              reason:
                  '$mode / ${variant.name} / ${entry.key} — '
                  '${delta.toStringAsFixed(4)} against the bar is a state '
                  'that draws nothing',
            );
          }
        });
      });

      test('${variant.name} — the wash never lands on the page colour', () {
        // The defect this component actually shipped, stated directly. A
        // hovered destination that equals the page reads as a hole in the
        // bar rather than as a lift, and it is a legitimate colour in
        // isolation — only the pairing shows it.
        _schemes().forEach((mode, scheme) {
          final bar = _argb(scheme, chrome.backgroundColor);
          final page = _argb(scheme, const CoreColor.token(CoreColors.surface));
          final over = _argb(scheme, ink);

          for (final weight in [layer.hover, layer.focus, layer.pressed]) {
            expect(
              _blend(over, bar, weight),
              isNot(page),
              reason:
                  '$mode / ${variant.name} — the wash lands on the page '
                  'colour, which punches a hole in the bar',
            );
          }
        });
      });

      test('${variant.name} — and the wash moves AWAY from the page', () {
        // Stronger than "not equal": the old swap went toward the page in
        // dark (page-coloured) and away from it in light, so the same
        // gesture moved in opposite directions per mode. One ink over the
        // bar's own ground always moves the same way — toward the ink.
        _schemes().forEach((mode, scheme) {
          final bar = _argb(scheme, chrome.backgroundColor);
          final page = _argb(scheme, const CoreColor.token(CoreColors.surface));
          if (bar == page) return; // a bar on the page colour has no axis
          final over = _argb(scheme, ink);
          final washed = _blend(over, bar, layer.pressed);

          expect(
            _contrast(washed, page),
            greaterThan(_contrast(bar, page)),
            reason:
                '$mode / ${variant.name} — the pressed wash moves the item '
                'TOWARD the page colour, which is the hole again in slow '
                'motion',
          );
        });
      });

      test('${variant.name} — labels survive the heaviest wash', () {
        _schemes().forEach((mode, scheme) {
          final bar = _argb(scheme, chrome.backgroundColor);
          final over = _argb(scheme, ink);
          final pressed = _blend(over, bar, layer.pressed);

          expect(
            _contrast(
              _argb(
                scheme,
                CoreNavigationBarStyle.defaultSelectedLabelTextStyle.color!,
              ),
              pressed,
            ),
            greaterThanOrEqualTo(4.5),
            reason:
                '$mode / ${variant.name} / selected label over the '
                'pressed wash',
          );
          // The unselected label is the accepted exception (measured above):
          // it stays readable as a secondary caption, never under 3 : 1.
          expect(
            _contrast(
              _argb(
                scheme,
                CoreNavigationBarStyle.defaultLabelTextStyle.color!,
              ),
              pressed,
            ),
            greaterThanOrEqualTo(3),
            reason:
                '$mode / ${variant.name} / unselected label over the '
                'pressed wash',
          );
        });
      });
    }
  });

  group('a selected row says which destination is current', () {
    final chrome = CoreNavigationBarStyle
        .defaultsByVariant[CoreNavigationBarVariant.standard]!;
    final fill = CoreNavigationBarStyle
        .defaultsByIndicator[CoreNavigationSelectionIndicator.fill]!;
    final rowFace = fill.selectedBackgroundColor!;
    final rowLabel = fill.selectedLabelTextStyle!.color!;

    test('no mode states a face; the fill indicator does', () {
      for (final cell in CoreNavigationBarStyle.defaultsByMode.values) {
        expect(cell.selectedBackgroundColor, isNull);
      }
      expect(rowFace, const CoreColor.token(CoreColors.surfaceContainerHigh));
      expect(
        CoreNavigationBarStyle.defaultSelectedBackgroundColor,
        CoreColor.transparent,
      );
    });

    test('the selected face is a step off the bar, in every mode', () {
      _schemes().forEach((mode, scheme) {
        final bar = _argb(scheme, chrome.backgroundColor);
        final face = _argb(scheme, rowFace);
        expect(
          _contrast(face, bar),
          greaterThanOrEqualTo(_perceptibleFloor),
          reason: '$mode — the selected row face draws nothing on the bar',
        );
      });
    });

    test('the selected label reads on its face, also under the focus '
        'wash', () {
      _schemes().forEach((mode, scheme) {
        final face = _argb(scheme, rowFace);
        final label = _argb(scheme, rowLabel);
        final washed = _blend(_argb(scheme, ink), face, layer.focus);
        for (final ground in [face, washed]) {
          expect(
            _contrast(label, ground),
            greaterThanOrEqualTo(4.5),
            reason: '$mode — selected label on the selected row face',
          );
        }
      });
    });

    test('a group title sits a step below the items, measured', () {
      // `onSurfaceSubtle` on the chrome face. Light lands just under 4.5 —
      // accepted: a group title is metadata no state layer covers, and the
      // quieter tone is what sets it a step below the items it names.
      const expected = {'light': 4.477, 'dark': 5.424};
      _normalSchemes().forEach((mode, scheme) {
        final bar = _argb(scheme, chrome.backgroundColor);
        final title = _argb(
          scheme,
          CoreNavigationBarStyle.defaultSectionLabelTextStyle.color!,
        );
        expect(
          _contrast(title, bar),
          closeTo(expected[mode]!, 0.005),
          reason: '$mode — group title on the bar',
        );
      });
    });
  });
}
