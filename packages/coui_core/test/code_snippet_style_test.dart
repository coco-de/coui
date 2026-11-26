// The default values are the fixture data — naming each one would hide the
// number the assertion is about.

/// The product-side defaults of `CoreCodeSnippetStyle`: the corner, the inner
/// padding, the code role, the gutter gap and the copy button's seat, and the
/// colours — the face, the borderless pair, the code ink, the gutter ink, the
/// copy glyph (which states none, so it follows the copy button) and the copy
/// button's plain focus ring.
///
/// Every line states one decision with the value it resolves to, so a default
/// moved back (a 16 corner, a 16 padding, a body role on a multiplier line
/// box, an inverse-surface face) fails here rather than only in a parity
/// screenshot. The syntax role table has its own file
/// (`code_syntax_roles_test.dart`).
library;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const CoreTypography _scale = CoreTypography.coui;

void main() {
  group('CoreCodeSnippetStyle defaults — geometry', () {
    test('corner is radius8 on all four corners', () {
      const radius = CoreCodeSnippetStyle.defaultBorderRadius;
      expect(radius.topLeft, CoreRadius.radius8);
      expect(radius.topRight, CoreRadius.radius8);
      expect(radius.bottomLeft, CoreRadius.radius8);
      expect(radius.bottomRight, CoreRadius.radius8);
      expect(radius, const CoreBorderRadius.all(8));
    });

    test('the corner equals the copy button corner (no concentric step)', () {
      expect(
        CoreCodeSnippetStyle.defaultCopyButtonStyle.borderRadius,
        CoreCodeSnippetStyle.defaultBorderRadius,
      );
    });

    test('padding is 10 vertical and 12 horizontal', () {
      const padding = CoreCodeSnippetStyle.defaultPadding;
      expect(padding.top, CoreSpace.space10);
      expect(padding.bottom, CoreSpace.space10);
      expect(padding.left, CoreSpace.space12);
      expect(padding.right, CoreSpace.space12);
      expect(
        padding,
        const CoreEdgeInsets.symmetric(vertical: 10, horizontal: 12),
      );
    });

    test('the gutter gap is space12', () {
      expect(CoreCodeSnippetStyle.defaultLineNumberMargin, CoreSpace.space12);
      expect(CoreCodeSnippetStyle.defaultLineNumberMargin, 12);
    });

    test('the copy button offset (top and right) is space6', () {
      expect(CoreCodeSnippetStyle.defaultCopyButtonOffset, CoreSpace.space6);
      expect(CoreCodeSnippetStyle.defaultCopyButtonOffset, 6);
    });
  });

  group('CoreCodeSnippetStyle defaults — code role', () {
    test('the code role is the token-backed codeSm', () {
      expect(
        CoreCodeSnippetStyle.defaultCodeTypography.token,
        CoreTextStyles.codeSm,
      );
    });

    test('the default states the role only — no raw overlay field', () {
      // A token-backed default with no overlay emits as a pure role class on
      // Web; a stated field here would leak into every snippet as inline CSS.
      const role = CoreCodeSnippetStyle.defaultCodeTypography;
      expect(role.fontSize, isNull);
      expect(role.fontWeight, isNull);
      expect(role.lineHeight, isNull);
      expect(role.lineHeightPx, isNull);
      expect(role.letterSpacing, isNull);
      expect(role.fontFamily, isNull);
      expect(role.color, isNull);
    });

    test('codeSm resolves to 12 / 400 / a 21px box / no tracking / mono', () {
      final resolved = _scale.resolve(
        CoreCodeSnippetStyle.defaultCodeTypography,
      );
      expect(resolved.fontSize, 12);
      expect(resolved.fontWeight, CoreFontWeight.regular);
      expect(resolved.lineHeightPx, CoreLineBox.px21);
      expect(resolved.lineHeight, isNull);
      expect(resolved.letterSpacing, CoreLetterSpacing.normal);
      expect(resolved.fontFamily, CoreFontFamily.mono);
    });

    test('a one-line snippet is 10 + 21 + 10 = 41 tall inside its border', () {
      const padding = CoreCodeSnippetStyle.defaultPadding;
      final box = _scale
          .resolve(CoreCodeSnippetStyle.defaultCodeTypography)
          .lineHeightPx!;
      expect(padding.top + box + padding.bottom, 41);
    });

    test('the copy button sits inside that one-line box', () {
      // 6 above + the 28px button leaves 7 below a 41px line — the button
      // never overhangs the block.
      const offset = CoreCodeSnippetStyle.defaultCopyButtonOffset;
      final button = CoreCodeSnippetStyle.defaultCopyButtonStyle.height!;
      expect(offset + button, lessThan(41));
    });
  });

  group('CoreCodeSnippetStyle defaults — colour', () {
    test('the face is surfaceContainerLow, not an inverse slab', () {
      expect(
        CoreCodeSnippetStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
    });

    test('borderless is a pair: width 0 and a transparent colour', () {
      // Width 0 alone still strokes a hairline on Flutter; the authored
      // transparent colour is what collapses the width there.
      expect(CoreCodeSnippetStyle.defaultBorderWidth, CoreStrokeWidth.stroke0);
      expect(CoreCodeSnippetStyle.defaultBorderWidth, 0);
      expect(CoreCodeSnippetStyle.defaultBorderColor, CoreColor.transparent);
      expect(CoreCodeSnippetStyle.defaultBorderColor.token, isNull);
    });

    test('the code ink is onSurface', () {
      expect(
        CoreCodeSnippetStyle.defaultCodeTextStyle.color,
        const CoreColor.token(CoreColors.onSurface),
      );
    });

    test('the gutter has a stated ink: onSurfaceVariant, opaque', () {
      final color = CoreCodeSnippetStyle.defaultLineNumberTextStyle.color!;
      expect(color.token, CoreColors.onSurfaceVariant);
      expect(color.opacity, 1);
      expect(
        color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
        reason: 'no alpha is laid over it',
      );
    });

    test('the copy glyph states a size and no colour', () {
      // A colour stated on the icon outranks the one the button hands down and
      // pins the glyph through hover; none stated lets it follow the button.
      expect(CoreCodeSnippetStyle.defaultCopyIconStyle.color, isNull);
      expect(
        CoreCodeSnippetStyle.defaultCopyIconStyle.size,
        CoreIconSize.size16,
      );
    });

    test(
      'the glyph follows the button: onSurfaceVariant, then onSurface',
      () {
        // The plain variant's own foreground at rest and on hover — what the
        // glyph reads, since it states none. The copy button states no
        // foreground of its own, so the variant's is the one in force.
        expect(
          CoreCodeSnippetStyle.defaultCopyButtonStyle.foregroundColor,
          isNull,
        );
        expect(
          CoreCodeSnippetStyle.defaultCopyButtonStyle.hoverForegroundColor,
          isNull,
        );
        final plain =
            CoreButtonStyle.defaultsByVariant[CoreButtonVariant.plain]!;
        expect(
          plain.foregroundColor,
          const CoreColor.token(CoreColors.onSurfaceVariant),
        );
        expect(
          plain.hoverForegroundColor,
          const CoreColor.token(CoreColors.onSurface),
        );
      },
    );

    test('a glyph colour stated on the instance wins and pins the glyph', () {
      const stated = CoreCodeSnippetStyle(
        copyIconStyle: CoreIconStyle(
          color: CoreColor.token(CoreColors.onPrimary),
        ),
      );
      final merged = CoreCodeSnippetStyle.defaultCopyIconStyle.merge(
        stated.copyIconStyle,
      );
      expect(merged.color, const CoreColor.token(CoreColors.onPrimary));
      expect(merged.size, CoreIconSize.size16);
    });

    test('the copy button states no focus ring of its own', () {
      // The standard ring (2 / 2 / focusRing, no gap band) applies; a stated
      // `focusOutlineStyle` here would be a ring the Button default is not.
      expect(
        CoreCodeSnippetStyle.defaultCopyButtonStyle.focusOutlineStyle,
        isNull,
      );
    });

    test('a stated gutter colour wins over the default', () {
      const stated = CoreCodeSnippetStyle(
        lineNumberTextStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.primary),
        ),
      );
      final merged = CoreCodeSnippetStyle.defaultLineNumberTextStyle.merge(
        stated.lineNumberTextStyle,
      );
      expect(merged.color, const CoreColor.token(CoreColors.primary));
      expect(
        CoreCodeSnippetStyle.defaultLineNumberTextStyle.merge(null).color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
    });

    test('the gutter does not read the code colour', () {
      // A restated code colour leaves the gutter's default where it was.
      const stated = CoreCodeSnippetStyle(
        codeTextStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.onPrimary),
        ),
      );
      final merged = CoreCodeSnippetStyle.defaultLineNumberTextStyle.merge(
        stated.lineNumberTextStyle,
      );
      expect(merged.color, const CoreColor.token(CoreColors.onSurfaceVariant));
    });

    test('the retired alpha is still a value-type field', () {
      // Read by no platform, but `==`, `hashCode`, `merge` and `copyWith`
      // keep carrying it until it is removed.
      const a = CoreCodeSnippetStyle(lineNumberAlpha: 0.2);
      const b = CoreCodeSnippetStyle(lineNumberAlpha: 0.3);
      expect(a == b, isFalse);
      expect(a.merge(b).lineNumberAlpha, 0.3);
      expect(a.copyWith(lineNumberAlpha: 0.5).lineNumberAlpha, 0.5);
      expect(a.hashCode == b.hashCode, isFalse);
    });
  });

  group('CoreCodeSnippetStyle defaults — contrast on the face', () {
    // The decision's own bar: text owes 4.5:1 on the face it sits on, in all
    // four modes. These are the rendered pairs, not slot-vs-slot guesses.
    final modes = <String, CoreColorScheme>{
      'Light': CouiColorPresets.source.light().resolved(.light),
      'Dark': CouiColorPresets.source.dark().resolved(.dark),
      'HCLight': CouiColorPresets.source.highContrastLight().resolved(.light),
      'HCDark': CouiColorPresets.source.highContrastDark().resolved(.dark),
    };
    final plain = CoreButtonStyle.defaultsByVariant[CoreButtonVariant.plain]!;
    final ink = <String, CoreColor>{
      'code ink': CoreCodeSnippetStyle.defaultCodeTextStyle.color!,
      'gutter ink': CoreCodeSnippetStyle.defaultLineNumberTextStyle.color!,
      // The glyph states none: it reads the plain button's foreground.
      'copy glyph at rest': plain.foregroundColor,
      'copy glyph on hover': plain.hoverForegroundColor!,
    };

    for (final MapEntry(key: mode, value: scheme) in modes.entries) {
      final face = CoreCodeSnippetStyle.defaultBackgroundColor.token!.read(
        scheme,
      )!;
      for (final MapEntry(key: name, value: color) in ink.entries) {
        test('$name on the face, $mode', () {
          final foreground = color.token!.read(scheme)!;
          expect(
            CoreContrast.ratio(foreground, face),
            greaterThanOrEqualTo(4.5),
          );
        });
      }
    }
  });

  group('CoreCodeSnippetStyle — the ink on a solid role face', () {
    final modes = <String, CoreColorScheme>{
      'Light': CouiColorPresets.source.light().resolved(.light),
      'Dark': CouiColorPresets.source.dark().resolved(.dark),
      'HCLight': CouiColorPresets.source.highContrastLight().resolved(.light),
      'HCDark': CouiColorPresets.source.highContrastDark().resolved(.dark),
    };
    const faces = <String, CoreColorToken>{
      'primary': CoreColors.primary,
      'secondary': CoreColors.secondary,
      'tertiary': CoreColors.tertiary,
      'error': CoreColors.error,
      'success': CoreColors.success,
      'warning': CoreColors.warning,
      'info': CoreColors.info,
      'outline': CoreColors.outline,
    };

    test('the table names the eight solid role fills, once each', () {
      expect(
        [for (final entry in CoreCodeSnippetStyle.solidFaceInks) entry.face],
        unorderedEquals(faces.values),
      );
    });

    test(
      "every ink is the face's on-partner; outline has none, so surface",
      () {
        for (final entry in CoreCodeSnippetStyle.solidFaceInks) {
          final expected = entry.face == CoreColors.outline
              ? CoreColors.surface
              : CoreColors.onColorOf(entry.face);
          expect(entry.ink, expected, reason: entry.face.name);
        }
      },
    );

    test('a solid face states its ink on the gutter, the glyph and the copy '
        "button's focus ring", () {
      for (final entry in CoreCodeSnippetStyle.solidFaceInks) {
        final ink = CoreColor.token(entry.ink);
        expect(
          CoreCodeSnippetStyle.inkOnFace(CoreColor.token(entry.face)),
          CoreCodeSnippetStyle(
            lineNumberTextStyle: CoreTextStyle(color: ink),
            copyButtonStyle: CoreButtonStyle(
              focusOutlineStyle: CoreFocusOutlineStyle(borderColor: ink),
            ),
            copyIconStyle: CoreIconStyle(color: ink),
          ),
          reason: entry.face.name,
        );
      }
    });

    test('it states nothing else: the face, the code colour and the rest of '
        "the copy button are the caller's", () {
      final style = CoreCodeSnippetStyle.inkOnFace(
        const CoreColor.token(CoreColors.primary),
      )!;
      expect(style.backgroundColor, isNull);
      expect(style.codeTextStyle, isNull);
      // Only the ring's colour: its width, gap and the transparent band stay
      // the copy button's, so the ring sits where it does on any other face.
      expect(
        style.copyButtonStyle,
        const CoreButtonStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(
            borderColor: CoreColor.token(CoreColors.onPrimary),
          ),
        ),
      );
    });

    test('any other face keeps the defaults', () {
      for (final face in [
        for (final tone in CoreSyntaxFaces.tones) CoreColor.token(tone),
        const CoreColor.token(CoreColors.surfaceContainerHighest),
        const CoreColor.token(CoreColors.inverseSurface),
        const CoreColor.token(CoreColors.primaryContainer),
        const CoreColor(0xFF1E2430),
        CoreColor.transparent,
        const CoreColor.token(CoreColors.primary, opacity: 0.99),
        const CoreColor.token(CoreColors.outline, opacity: 0.5),
      ]) {
        expect(CoreCodeSnippetStyle.inkOnFace(face), isNull);
      }
    });

    test('the ink sits under what the caller states', () {
      final derived = CoreCodeSnippetStyle.inkOnFace(
        const CoreColor.token(CoreColors.primary),
      );
      const stated = CoreCodeSnippetStyle(
        lineNumberTextStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.onError),
        ),
      );
      final merged = resolveStyleChain(const CoreCodeSnippetStyle(), [
        derived,
        stated,
      ]);
      expect(
        merged.lineNumberTextStyle?.color,
        const CoreColor.token(CoreColors.onError),
      );
      expect(
        merged.copyIconStyle?.color,
        const CoreColor.token(CoreColors.onPrimary),
        reason: 'the glyph colour was not stated, so the face ink stays',
      );
    });

    test('a ring the caller states keeps the ink unless it states a '
        'colour', () {
      final derived = CoreCodeSnippetStyle.inkOnFace(
        const CoreColor.token(CoreColors.primary),
      );
      CoreFocusOutlineStyle? ringUnder(CoreFocusOutlineStyle stated) =>
          resolveStyleChain(const CoreCodeSnippetStyle(), [
            derived,
            CoreCodeSnippetStyle(
              copyButtonStyle: CoreButtonStyle(focusOutlineStyle: stated),
            ),
          ]).copyButtonStyle?.focusOutlineStyle;

      final widthOnly = ringUnder(
        const CoreFocusOutlineStyle(borderWidth: CoreStrokeWidth.stroke3),
      );
      expect(widthOnly?.borderWidth, CoreStrokeWidth.stroke3);
      expect(
        widthOnly?.borderColor,
        const CoreColor.token(CoreColors.onPrimary),
        reason: 'a width alone does not drop the face ink',
      );

      final coloured = ringUnder(
        const CoreFocusOutlineStyle(
          borderColor: CoreColor.token(CoreColors.onError),
        ),
      );
      expect(coloured?.borderColor, const CoreColor.token(CoreColors.onError));
    });

    test('a copy button the caller states without a ring keeps the ink', () {
      final merged = resolveStyleChain(const CoreCodeSnippetStyle(), [
        CoreCodeSnippetStyle.inkOnFace(
          const CoreColor.token(CoreColors.primary),
        ),
        const CoreCodeSnippetStyle(
          copyButtonStyle: CoreButtonStyle(height: CoreSize.size32),
        ),
      ]);
      expect(merged.copyButtonStyle?.height, CoreSize.size32);
      expect(
        merged.copyButtonStyle?.focusOutlineStyle?.borderColor,
        const CoreColor.token(CoreColors.onPrimary),
      );
    });

    for (final MapEntry(key: mode, value: scheme) in modes.entries) {
      test('the ink reads 4.5:1 on its face — gutter and glyph, $mode', () {
        for (final entry in CoreCodeSnippetStyle.solidFaceInks) {
          expect(
            CoreContrast.ratio(
              entry.ink.read(scheme)!,
              entry.face.read(scheme)!,
            ),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.ink.name} on ${entry.face.name}',
          );
        }
      });

      test('the ring would not: focusRing reads under 3:1 on every solid '
          'face, $mode', () {
        // What the ink on the ring prevents, measured: the system ring meets
        // the face through a transparent gap, so the face is its neighbour on
        // both sides. 1.00 on primary and tertiary (the same colour), at most
        // 2.76 elsewhere.
        final ring = CoreFocusRing.ringColor.token!.read(scheme)!;
        for (final entry in CoreCodeSnippetStyle.solidFaceInks) {
          expect(
            CoreContrast.ratio(ring, entry.face.read(scheme)!),
            lessThan(3),
            reason: 'focusRing on ${entry.face.name}',
          );
        }
      });

      test('the defaults would not: the gutter and the glyph at rest read '
          'under 3.5:1 on a solid face, $mode', () {
        // What the ink on the face prevents, measured: the defaults of a
        // surface tone laid on a solid fill. Under 3.5 on all eight, in every
        // mode; the lowest is 1.00 (`onSurfaceVariant` on `primary`).
        final plain =
            CoreButtonStyle.defaultsByVariant[CoreButtonVariant.plain]!;
        for (final entry in CoreCodeSnippetStyle.solidFaceInks) {
          final face = entry.face.read(scheme)!;
          for (final colour in [
            CoreCodeSnippetStyle.defaultLineNumberTextStyle.color!,
            plain.foregroundColor,
          ]) {
            expect(
              CoreContrast.ratio(colour.token!.read(scheme)!, face),
              lessThan(3.5),
              reason: '${colour.token!.name} on ${entry.face.name}',
            );
          }
        }
      });
    }
  });

  group('CoreCodeSnippetStyle defaults — reach the merge chain', () {
    test('an instance value wins over each of the defaults', () {
      const instance = CoreCodeSnippetStyle(
        borderRadius: CoreBorderRadius.all(24),
        padding: CoreEdgeInsets.all(CoreSpace.space24),
        codeTypography: CoreTextStyle.token(CoreTextStyles.codeMd),
        lineNumberMargin: CoreSpace.space20,
        copyButtonOffset: CoreSpace.space20,
      );
      const base = CoreCodeSnippetStyle(
        borderRadius: CoreCodeSnippetStyle.defaultBorderRadius,
        padding: CoreCodeSnippetStyle.defaultPadding,
        codeTypography: CoreCodeSnippetStyle.defaultCodeTypography,
        lineNumberMargin: CoreCodeSnippetStyle.defaultLineNumberMargin,
        copyButtonOffset: CoreCodeSnippetStyle.defaultCopyButtonOffset,
      );
      final merged = base.merge(instance);
      expect(merged.borderRadius, const CoreBorderRadius.all(24));
      expect(merged.padding, const CoreEdgeInsets.all(24));
      expect(merged.codeTypography?.token, CoreTextStyles.codeMd);
      expect(merged.lineNumberMargin, CoreSpace.space20);
      expect(merged.copyButtonOffset, CoreSpace.space20);
    });

    test(
      'a role stated on top of codeSm keeps the role and wins the field',
      () {
        final merged = CoreCodeSnippetStyle.defaultCodeTypography.merge(
          const CoreTextStyle(fontSize: 14),
        );
        expect(merged.token, CoreTextStyles.codeSm);
        expect(merged.fontSize, 14);
        // Stating only a size leaves the role's box alone — the box is read off
        // the role, not off the overlay.
        expect(merged.lineHeightPx, isNull);
      },
    );
  });
}
