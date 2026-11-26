// A disabled button has to LOOK disabled — on every variant.
//
// Four of them did not. `ghost`, `link`, `text` and `fixed` named the
// same `onSurface` for enabled and disabled and the same fill for both,
// so the two states were pixel-identical; `outline` kept its foreground
// AND its border and only dropped a 30%-alpha fill; `card` was inverted,
// going from the muted `onSurfaceVariant` to the full-strength
// `onSurface` — disabling made the label MORE prominent.
//
// Even once every variant dropped its label, the quiet ones (`plain`, and
// `ghost` / `menu` on a page-coloured fill) dropped it to the SAME colour a
// quiet enabled button already uses — `onSurfaceVariant` is the enabled
// secondary-text ink — so an enabled `plain` and a disabled one differed by
// nothing. Every disabled label is therefore the one dedicated ink.
//
// Nothing caught it. The contrast guard reads the scheme, not a
// variant's own pairing. Flutter had opted out of `Clickable`'s generic
// disabled dim (`disabledOpacity: 1.0`) on the stated premise that
// "Button expresses disabled via its own disabled colour tokens" — true
// of the working variants, false of these, and the opt-out removed the
// last signal they had. On Web the only survivor was
// `disabled:cursor-not-allowed`, which a static render never shows and
// a keyboard user never gets.
//
// So the invariant is stated once, over every variant, in the terms the
// repo already settled on for Chip / TextField / Label: the dedicated
// `disabled*` tokens, not an opacity multiplier over the enabled colour
// (whose result depends on whatever is behind it, and which
// forced-colours mode does not touch at all).
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// A colour's identity for comparison — token name plus alpha, which is
/// what decides whether two states can be told apart. Comparing
/// `CoreColor` directly would also pass for two different tokens that
/// happen to resolve alike, and fail for the same token written twice.
String _identity(CoreColor? color) {
  if (color == null) return 'unset';
  final name = color.token?.name ?? 'literal:0x${color.argb.toRadixString(16)}';
  return color.opacity >= 1 ? name : '$name@${color.opacity}';
}

void main() {
  group('every button variant looks disabled when it is', () {
    for (final variant in CoreButtonVariant.values) {
      final style = CoreButtonStyle.defaultsByVariant[variant]!;

      test(
        '${variant.name} states its disabled label with disabledContent',
        () {
          // Not merely "different from enabled" — that would pass for
          // `card`'s inversion, which differed by getting darker. And not
          // `onSurfaceVariant`: that is what an enabled quiet button
          // already paints, so a disabled one in it is the enabled one.
          // `disabledContent` is the dedicated token — the one `Label`,
          // `FormLabel`, `Checkbox` and `Chip` state "off" with — and a
          // disabled control is WCAG-exempt from the text floor
          // (`disabled_label_readability_test.dart` pins the numbers).
          expect(
            _identity(style.disabledForegroundColor),
            _identity(const CoreColor.token(CoreColors.disabledContent)),
            reason:
                '${variant.name} disabled label is '
                '${_identity(style.disabledForegroundColor)}; enabled is '
                '${_identity(style.foregroundColor)}. Every disabled button '
                'label is CoreColors.disabledContent.',
          );
        },
      );

      test('${variant.name} is not pixel-identical when disabled', () {
        // `plain` stays fill-less when disabled (#4553): disabled is the
        // missing hover, not a grey pill. Its label still changes, so it is
        // held to the general test below as well.
        if (variant == CoreButtonVariant.plain) {
          expect(
            _identity(style.disabledBackgroundColor),
            _identity(style.backgroundColor),
            reason:
                '${variant.name} is a text-only control — disabled must '
                'not grow a fill.',
          );
          return;
        }
        final same =
            _identity(style.foregroundColor) ==
                _identity(style.disabledForegroundColor) &&
            _identity(style.backgroundColor) ==
                _identity(style.disabledBackgroundColor) &&
            _identity(style.borderColor) ==
                _identity(style.disabledBorderColor);
        expect(
          same,
          isFalse,
          reason:
              '${variant.name} paints identical foreground, fill and '
              'border in both states.',
        );
      });

      test('${variant.name} does not dim by opacity instead', () {
        // `design-tokens.md`: a dedicated disabled token wins over an
        // opacity multiplier, because a multiplier's contrast depends on
        // the surface behind it and forced-colours mode leaves alpha
        // alone while swapping the colour.
        for (final entry in <String, CoreColor?>{
          'disabledForegroundColor': style.disabledForegroundColor,
          'disabledBackgroundColor': style.disabledBackgroundColor,
          'disabledBorderColor': style.disabledBorderColor,
        }.entries) {
          final color = entry.value;
          if (color == null) continue;
          // Alpha 0 is "draw nothing", not a dim — a variant that is
          // transparent when enabled stays transparent when disabled.
          if (color.opacity == 0) continue;
          expect(
            color.opacity,
            1,
            reason:
                '${variant.name}.${entry.key} carries alpha '
                '${color.opacity} — use a dedicated disabled token.',
          );
        }
      });
    }

    test('a bordered variant states a dedicated disabled border', () {
      // Scoped to the variants that actually draw one: requiring it of
      // a borderless variant would be requiring a colour for a line
      // that is never painted.
      for (final variant in CoreButtonVariant.values) {
        final style = CoreButtonStyle.defaultsByVariant[variant]!;
        if (style.borderWidth <= 0) continue;
        expect(
          _identity(style.disabledBorderColor),
          _identity(const CoreColor.token(CoreColors.disabledOutline)),
          reason:
              '${variant.name} draws a ${style.borderWidth}px border but '
              'its disabled colour is '
              '${_identity(style.disabledBorderColor)}.',
        );
      }
    });
  });
}
