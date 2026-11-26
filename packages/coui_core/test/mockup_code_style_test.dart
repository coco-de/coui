// Tests for CoreMockupCodeStyle.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kColorPrimary = CoreColor.token(CoreColors.primary);
const _kColorOnSurface = CoreColor.token(CoreColors.onSurface);
const _kColorSurface = CoreColor.token(CoreColors.surface);

const _kRadius8 = CoreBorderRadius.all(8);
const _kRadius12 = CoreBorderRadius.all(12);
const _kRadius16 = CoreBorderRadius.all(16);

const _kPaddingS = CoreEdgeInsets.all(8);
const _kPaddingM = CoreEdgeInsets.all(12);

const _kColorOnSurfaceVariant = CoreColor.token(CoreColors.onSurfaceVariant);
const _kLineSpacing = 6.0;
const _kLineNumberWidth = 48.0;

void main() {
  group('CoreMockupCodeStyle', () {
    test('chain — design system → theme.style → widget', () {
      const designSystem = CoreMockupCodeStyle(
        backgroundColor: _kColorSurface,
        textStyle: CoreTextStyle(color: _kColorOnSurface),
        borderRadius: _kRadius8,
        padding: _kPaddingS,
      );
      const themeStyle = CoreMockupCodeStyle(borderRadius: _kRadius12);
      const widgetStyle = CoreMockupCodeStyle(
        backgroundColor: _kColorPrimary,
        padding: _kPaddingM,
      );

      final effective = designSystem.merge(themeStyle).merge(widgetStyle);

      expect(effective.backgroundColor, _kColorPrimary);
      expect(effective.textStyle?.color, _kColorOnSurface);
      expect(effective.borderRadius, _kRadius12);
      expect(effective.padding, _kPaddingM);
    });

    test(
      'chain — prefixTextStyle / lineSpacing / lineNumberWidth overrides',
      () {
        const designSystem = CoreMockupCodeStyle(
          prefixTextStyle: CoreTextStyle(color: _kColorOnSurfaceVariant),
          lineSpacing: _kLineSpacing,
        );
        const widgetStyle = CoreMockupCodeStyle(
          prefixTextStyle: CoreTextStyle(color: _kColorPrimary),
          lineNumberWidth: _kLineNumberWidth,
        );

        final effective = designSystem.merge(widgetStyle);

        expect(effective.prefixTextStyle?.color, _kColorPrimary);
        expect(effective.lineSpacing, _kLineSpacing);
        expect(effective.lineNumberWidth, _kLineNumberWidth);
      },
    );

    test('equality + copyWith', () {
      const a = CoreMockupCodeStyle(
        backgroundColor: _kColorSurface,
        textStyle: CoreTextStyle(color: _kColorOnSurface),
      );
      const b = CoreMockupCodeStyle(
        backgroundColor: _kColorSurface,
        textStyle: CoreTextStyle(color: _kColorOnSurface),
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final copy = a.copyWith(
        prefixTextStyle: const CoreTextStyle(color: _kColorPrimary),
        borderRadius: _kRadius16,
        lineSpacing: _kLineSpacing,
        lineNumberWidth: _kLineNumberWidth,
      );
      expect(copy.borderRadius, _kRadius16);
      expect(copy.backgroundColor, _kColorSurface);
      expect(copy.textStyle?.color, _kColorOnSurface);
      expect(copy.prefixTextStyle?.color, _kColorPrimary);
      expect(copy.lineSpacing, _kLineSpacing);
      expect(copy.lineNumberWidth, _kLineNumberWidth);
    });

    test('defaults are wired to the expected design tokens', () {
      expect(
        CoreMockupCodeStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
      expect(
        CoreMockupCodeStyle.defaultTextStyle.color,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(
        CoreMockupCodeStyle.defaultPrefixTextStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CoreMockupCodeStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius8),
      );
      expect(
        CoreMockupCodeStyle.defaultPadding,
        const CoreEdgeInsets.symmetric(
          vertical: CoreSpace.space10,
          horizontal: CoreSpace.space16,
        ),
      );
      expect(CoreMockupCodeStyle.defaultLineSpacing, CoreSpace.space4);
      expect(CoreMockupCodeStyle.defaultLineNumberWidth, CoreSize.size28);
    });

    // The inset is vertical 10 / horizontal 16 — read the four sides, not
    // just the constructor that was used to state them.
    test('padding default is 10 above and below, 16 left and right', () {
      const padding = CoreMockupCodeStyle.defaultPadding;
      expect(padding.top, 10);
      expect(padding.bottom, 10);
      expect(padding.left, 16);
      expect(padding.right, 16);
      expect(padding.isDirectional, isFalse);
    });

    // Text and gutter both sit on the `codeSm` role so they share one
    // 21px line grid; the role is carried by the token, the colour slots
    // are untouched by it.
    test('text and prefix are token-backed on the codeSm role', () {
      expect(CoreMockupCodeStyle.defaultTextStyle.token, CoreTextStyles.codeSm);
      expect(
        CoreMockupCodeStyle.defaultPrefixTextStyle.token,
        CoreTextStyles.codeSm,
      );
      // Role only: no fontSize / line-box overlay on top of it (an overlay
      // would keep another role's tracking on the new size).
      expect(CoreMockupCodeStyle.defaultTextStyle.fontSize, isNull);
      expect(CoreMockupCodeStyle.defaultTextStyle.lineHeightPx, isNull);
      expect(CoreMockupCodeStyle.defaultPrefixTextStyle.fontSize, isNull);
      expect(CoreMockupCodeStyle.defaultPrefixTextStyle.lineHeightPx, isNull);
    });

    test('the codeSm role the defaults select is monospace on a 21px box', () {
      final codeSm = CoreTypography.coui.codeSm;
      expect(codeSm.fontSize, CoreFontSize.s12);
      expect(codeSm.lineHeightPx, CoreLineBox.px21);
      expect(codeSm.fontFamily, CoreFontFamily.mono);
    });

    // The face is the lighter container step, and it is the one the Browser
    // window body already uses — the two mockup bodies share one tone. The
    // gutter ink is NOT part of that move: it stays `onSurfaceVariant`.
    test('the face is surfaceContainerLow, shared with the Browser body', () {
      expect(
        CoreMockupCodeStyle.defaultBackgroundColor,
        isNot(const CoreColor.token(CoreColors.surfaceContainer)),
      );
      expect(
        CoreMockupCodeStyle.defaultBackgroundColor,
        CoreMockupBrowserStyle.defaultBackgroundColor,
      );
      expect(
        CoreMockupCodeStyle.defaultTextStyle.color,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(
        CoreMockupCodeStyle.defaultPrefixTextStyle.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
    });

    // The pair a reader sees: each default ink over the default face,
    // resolved through CoUI's own colour source in all four modes. The
    // declaration test above would stay green if the face tokens resolved
    // to something the ink cannot be read on; this reads the colours.
    group('the default inks stay readable on the default face', () {
      const source = CouiColorPresets.source;
      final schemes = <String, CoreColorScheme>{
        'light': resolveThemeSchemeFrom(
          source,
          brightness: CoreBrightness.light,
        ),
        'dark': resolveThemeSchemeFrom(
          source,
          brightness: CoreBrightness.dark,
        ),
        'high-contrast light': resolveThemeSchemeFrom(
          source,
          brightness: CoreBrightness.light,
          highContrast: true,
        ),
        'high-contrast dark': resolveThemeSchemeFrom(
          source,
          brightness: CoreBrightness.dark,
          highContrast: true,
        ),
      };
      final inks = <String, CoreColor>{
        'code text': CoreMockupCodeStyle.defaultTextStyle.color!,
        'line-number gutter': CoreMockupCodeStyle.defaultPrefixTextStyle.color!,
      };

      for (final entry in inks.entries) {
        schemes.forEach((mode, scheme) {
          test('${entry.key}, $mode', () {
            final face = scheme
                .resolve(CoreMockupCodeStyle.defaultBackgroundColor)
                .argb;
            final ink = scheme.resolve(entry.value).argb;
            final ratio = CoreContrast.ratio(CoreColor(ink), CoreColor(face));
            // WCAG 1.4.3 for body-size text. Compared unrounded.
            expect(ratio, greaterThanOrEqualTo(4.5));
          });
        });
      }
    });

    // Merging a caller's colour onto the default keeps the role.
    test('a colour-only override keeps the codeSm role', () {
      final merged = CoreMockupCodeStyle.defaultTextStyle.merge(
        const CoreTextStyle(color: _kColorPrimary),
      );
      expect(merged.token, CoreTextStyles.codeSm);
      expect(merged.color, _kColorPrimary);
    });
  });

  group('CoreCodeLine tone', () {
    test('a line states no tone by default — neutral', () {
      const line = CoreCodeLine(text: 'plain');
      expect(line.tone, CoreCodeLineTone.neutral);
      expect(CoreCodeLineTone.defaultTone, CoreCodeLineTone.neutral);
    });

    test('the six tones, in the order the spec lists them', () {
      expect(CoreCodeLineTone.values, [
        CoreCodeLineTone.neutral,
        CoreCodeLineTone.muted,
        CoreCodeLineTone.link,
        CoreCodeLineTone.success,
        CoreCodeLineTone.warning,
        CoreCodeLineTone.error,
      ]);
    });

    test('a stated tone is kept, and the prefix is independent of it', () {
      const line = CoreCodeLine(
        text: 'done',
        prefix: r'$',
        tone: CoreCodeLineTone.success,
      );
      expect(line.tone, CoreCodeLineTone.success);
      expect(line.prefix, r'$');
    });
  });

  group('CoreMockupCodeStyle tone colours', () {
    test('each tone maps to its colour role by default', () {
      expect(
        CoreMockupCodeStyle.defaultMutedToneColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(
        CoreMockupCodeStyle.defaultLinkToneColor,
        const CoreColor.token(CoreColors.link),
      );
      expect(
        CoreMockupCodeStyle.defaultSuccessToneColor,
        const CoreColor.token(CoreColors.onSuccessContainer),
      );
      expect(
        CoreMockupCodeStyle.defaultWarningToneColor,
        const CoreColor.token(CoreColors.onWarningContainer),
      );
      expect(
        CoreMockupCodeStyle.defaultErrorToneColor,
        const CoreColor.token(CoreColors.onErrorContainer),
      );
    });

    test('neutral has no slot — it is the code text colour (onSurface)', () {
      expect(
        CoreMockupCodeStyle.defaultTextStyle.color,
        const CoreColor.token(CoreColors.onSurface),
      );
    });

    test('a style states no tone colour until a caller does', () {
      const style = CoreMockupCodeStyle();
      expect(style.mutedToneColor, isNull);
      expect(style.linkToneColor, isNull);
      expect(style.successToneColor, isNull);
      expect(style.warningToneColor, isNull);
      expect(style.errorToneColor, isNull);
    });

    test('merge — later slots win per tone, others survive', () {
      const base = CoreMockupCodeStyle(
        mutedToneColor: _kColorOnSurface,
        linkToneColor: _kColorSurface,
      );
      const patch = CoreMockupCodeStyle(
        linkToneColor: _kColorPrimary,
        warningToneColor: _kColorPrimary,
      );
      final merged = base.merge(patch);
      expect(merged.mutedToneColor, _kColorOnSurface);
      expect(merged.linkToneColor, _kColorPrimary);
      expect(merged.warningToneColor, _kColorPrimary);
      expect(merged.successToneColor, isNull);
      expect(merged.errorToneColor, isNull);
    });

    test('equality, hashCode and copyWith cover every tone slot', () {
      const a = CoreMockupCodeStyle(
        mutedToneColor: _kColorPrimary,
        linkToneColor: _kColorPrimary,
        successToneColor: _kColorPrimary,
        warningToneColor: _kColorPrimary,
        errorToneColor: _kColorPrimary,
      );
      final b = a.copyWith();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      final changed = <String, CoreMockupCodeStyle>{
        'muted': a.copyWith(mutedToneColor: _kColorSurface),
        'link': a.copyWith(linkToneColor: _kColorSurface),
        'success': a.copyWith(successToneColor: _kColorSurface),
        'warning': a.copyWith(warningToneColor: _kColorSurface),
        'error': a.copyWith(errorToneColor: _kColorSurface),
      };
      for (final MapEntry(:key, :value) in changed.entries) {
        expect(value, isNot(equals(a)), reason: '$key slot is in ==');
      }
    });
  });

  group('CoreMockupCodeTheme passes through style', () {
    test('CoreMockupCodeTheme', () {
      const style = CoreMockupCodeStyle(borderRadius: _kRadius12);
      const theme = CoreMockupCodeTheme(style: style);
      expect(theme.style, style);
    });
  });
}
