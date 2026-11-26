// Tests for CoreCodeDiffStyle geometry, typography and colour defaults — the
// 21px grid (code roles, no vertical padding, a 40px gutter cell whose 12px
// gap leaves a 28px digit column) and the opaque added / removed bands with
// their own ink.

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreCodeDiffStyle defaults — outer corner', () {
    test('the corner is the panel role (12)', () {
      expect(
        CoreCodeDiffStyle.defaultCornerRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
      expect(
        CoreCodeDiffStyle.defaultCornerRadius.topLeft,
        CoreRadius.radius12,
      );
    });
  });

  group('CoreCodeDiffStyle defaults — typography', () {
    test('body is the codeMd role, gutter is the codeSm role', () {
      expect(
        identical(
          CoreCodeDiffStyle.defaultBodyTypography,
          CoreTypography.coui.codeMd,
        ),
        isTrue,
      );
      expect(
        identical(
          CoreCodeDiffStyle.defaultGutterTypography,
          CoreTypography.coui.codeSm,
        ),
        isTrue,
      );
    });

    test('body and gutter are monospace on the same fixed 21px line box', () {
      final body = CoreCodeDiffStyle.defaultBodyTypography;
      final gutter = CoreCodeDiffStyle.defaultGutterTypography;

      expect(body.fontSize, CoreFontSize.s13);
      expect(gutter.fontSize, CoreFontSize.s12);
      expect(body.fontFamily, CoreFontFamily.mono);
      expect(gutter.fontFamily, CoreFontFamily.mono);
      expect(body.lineHeightPx, CoreLineBox.px21);
      expect(gutter.lineHeightPx, CoreLineBox.px21);
    });
  });

  group('CoreCodeDiffStyle defaults — the 21px row', () {
    test('the row has 12 horizontal padding and no vertical padding', () {
      const row = CoreCodeDiffStyle.defaultLinePadding;

      expect(row.left, CoreSpace.space12);
      expect(row.right, CoreSpace.space12);
      expect(row.top, 0);
      expect(row.bottom, 0);
    });

    test('the gutter text has no vertical padding', () {
      const gutter = CoreCodeDiffStyle.defaultLineNumberPadding;

      expect(gutter.top, 0);
      expect(gutter.bottom, 0);
    });

    test('row height is the line box alone: no vertical term anywhere', () {
      // 21 = the code roles' line box + padding above + padding below, for
      // the row and for the gutter cell inside it.
      const row = CoreCodeDiffStyle.defaultLinePadding;
      const gutter = CoreCodeDiffStyle.defaultLineNumberPadding;

      expect(
        CoreLineBox.px21 + row.top + row.bottom + gutter.top + gutter.bottom,
        CoreLineBox.px21,
      );
    });
  });

  group('CoreCodeDiffStyle defaults — the x = 52 gutter', () {
    test('the gap is a directional end-side inset of 12', () {
      const gutter = CoreCodeDiffStyle.defaultLineNumberPadding;

      expect(gutter.isDirectional, isTrue);
      expect(gutter.start, 0);
      expect(gutter.end, CoreSpace.space12);
    });

    test('40 total width leaves a 28 digit column beside the 12 gap', () {
      const width = CoreCodeDiffStyle.defaultLineNumberWidth;
      const gutter = CoreCodeDiffStyle.defaultLineNumberPadding;

      expect(width, CoreSpace.space40);
      expect(width - gutter.start - gutter.end, CoreSize.size28);
    });

    test('the prefix starts at x = 52 (12 row + 28 digits + 12 gap)', () {
      const row = CoreCodeDiffStyle.defaultLinePadding;
      const width = CoreCodeDiffStyle.defaultLineNumberWidth;

      // The width is the gutter cell's total width — the padding lives
      // inside it — so the prefix sits one row inset plus one width in.
      expect(row.left + width, 52);
    });
  });

  group('CoreCodeDiffStyle — new defaults ride merge / copyWith / ==', () {
    test('a directional gutter padding survives merge and copyWith', () {
      const directional = CoreEdgeInsets.directional(end: CoreSpace.space12);
      const base = CoreCodeDiffStyle(lineNumberPadding: directional);

      expect(
        base.merge(const CoreCodeDiffStyle()).lineNumberPadding,
        directional,
      );
      expect(base.copyWith(borderWidth: 2).lineNumberPadding, directional);
    });

    test('directional and physical gutter padding are different values', () {
      const directional = CoreCodeDiffStyle(
        lineNumberPadding: CoreEdgeInsets.directional(end: CoreSpace.space12),
      );
      const physical = CoreCodeDiffStyle(
        lineNumberPadding: CoreEdgeInsets.only(right: CoreSpace.space12),
      );

      expect(directional, isNot(physical));
    });

    test('the typography roles merge like any other field', () {
      final style = const CoreCodeDiffStyle().merge(
        CoreCodeDiffStyle(bodyTypography: CoreTypography.coui.codeXs),
      );

      expect(
        identical(style.bodyTypography, CoreTypography.coui.codeXs),
        isTrue,
      );
      expect(style.gutterTypography, isNull);
    });
  });

  group('CoreCodeDiffStyle defaults — the block face', () {
    test('the face is surfaceContainerLow', () {
      expect(
        CoreCodeDiffStyle.defaultSurfaceColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
    });

    test('the block states no border: stroke0 paired with a transparent '
        'colour', () {
      // A width of 0 alone is a hairline on Flutter and nothing on Web; the
      // transparent colour is what makes both platforms draw nothing.
      expect(CoreCodeDiffStyle.defaultBorderWidth, CoreStrokeWidth.stroke0);
      expect(CoreCodeDiffStyle.defaultOutlineColor, CoreColor.transparent);
      expect(CoreCodeDiffStyle.defaultOutlineColor.token, isNull);
    });
  });

  group('CoreCodeDiffStyle defaults — opaque bands and their ink', () {
    test('the bands are the container tokens, at full opacity', () {
      expect(
        CoreCodeDiffStyle.defaultAddedBackgroundColor,
        const CoreColor.token(CoreColors.successContainer),
      );
      expect(
        CoreCodeDiffStyle.defaultRemovedBackgroundColor,
        const CoreColor.token(CoreColors.errorContainer),
      );
      // Opaque: no opacity multiplier rides the band.
      expect(CoreCodeDiffStyle.defaultAddedBackgroundColor.opacity, 1);
      expect(CoreCodeDiffStyle.defaultRemovedBackgroundColor.opacity, 1);
    });

    test('the band ink is the matching on-container token, at full '
        'opacity', () {
      expect(
        CoreCodeDiffStyle.defaultAddedForegroundColor,
        const CoreColor.token(CoreColors.onSuccessContainer),
      );
      expect(
        CoreCodeDiffStyle.defaultRemovedForegroundColor,
        const CoreColor.token(CoreColors.onErrorContainer),
      );
      expect(CoreCodeDiffStyle.defaultAddedForegroundColor.opacity, 1);
      expect(CoreCodeDiffStyle.defaultRemovedForegroundColor.opacity, 1);
    });

    test('the gutter number on a plain row is onSurfaceVariant, opaque', () {
      expect(
        CoreCodeDiffStyle.defaultLineNumberColor,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      expect(CoreCodeDiffStyle.defaultLineNumberColor.opacity, 1);
    });

    test('the body ink is onSurface — one colour for every row', () {
      expect(
        CoreCodeDiffStyle.defaultUnchangedTextStyle.color,
        const CoreColor.token(CoreColors.onSurface),
      );
    });
  });

  group('CoreCodeDiffStyle — the band fields ride merge / copyWith / ==', () {
    const info = CoreColor.token(CoreColors.infoContainer);
    const onInfo = CoreColor.token(CoreColors.onInfoContainer);
    const warning = CoreColor.token(CoreColors.warningContainer);
    const onWarning = CoreColor.token(CoreColors.onWarningContainer);

    CoreCodeDiffStyle stated() => const CoreCodeDiffStyle(
      addedBackgroundColor: info,
      addedForegroundColor: onInfo,
      removedBackgroundColor: warning,
      removedForegroundColor: onWarning,
    );

    test('merge: the patch wins field by field, the base fills the rest', () {
      final merged = stated().merge(
        const CoreCodeDiffStyle(addedForegroundColor: onWarning),
      );

      expect(merged.addedBackgroundColor, info);
      expect(merged.addedForegroundColor, onWarning);
      expect(merged.removedBackgroundColor, warning);
      expect(merged.removedForegroundColor, onWarning);
      expect(const CoreCodeDiffStyle().merge(stated()), stated());
    });

    test('copyWith replaces one field and keeps the others', () {
      final copy = stated().copyWith(removedBackgroundColor: info);

      expect(copy.removedBackgroundColor, info);
      expect(copy.addedBackgroundColor, info);
      expect(copy.addedForegroundColor, onInfo);
      expect(copy.removedForegroundColor, onWarning);
    });

    test('each band field takes part in == and hashCode', () {
      expect(stated(), stated());
      expect(stated().hashCode, stated().hashCode);

      // Changing any one of the four makes a different value — a field that
      // fell out of `==` would let a theme change skip its rebuild.
      expect(
        stated(),
        isNot(stated().copyWith(addedBackgroundColor: warning)),
      );
      expect(
        stated(),
        isNot(stated().copyWith(addedForegroundColor: warning)),
      );
      expect(
        stated(),
        isNot(stated().copyWith(removedBackgroundColor: info)),
      );
      expect(
        stated(),
        isNot(stated().copyWith(removedForegroundColor: info)),
      );
    });
  });

  group('CoreCodeDiffStyle — the retired alpha model stays declared', () {
    // The fields are kept so apps that state them still compile; nothing
    // reads them (the platform tests pin that). Their defaults keep the old
    // values so a caller reading one still gets the number it expects.
    test('the retired defaults keep their old values', () {
      expect(CoreCodeDiffStyle.defaultRowTintAlpha, 0.15);
      expect(CoreCodeDiffStyle.defaultLineNumberAlpha, 0.5);
      expect(
        CoreCodeDiffStyle.defaultAddedColor,
        const CoreColor.token(CoreColors.success),
      );
      expect(
        CoreCodeDiffStyle.defaultRemovedColor,
        const CoreColor.token(CoreColors.error),
      );
    });

    test('the retired fields still ride merge / copyWith / == / hashCode', () {
      const retired = CoreCodeDiffStyle(
        addedColor: CoreColor.token(CoreColors.info),
        removedColor: CoreColor.token(CoreColors.warning),
        rowTintAlpha: 0.3,
        lineNumberAlpha: 0.2,
      );

      expect(const CoreCodeDiffStyle().merge(retired), retired);
      expect(retired.copyWith(borderWidth: 2).rowTintAlpha, 0.3);
      expect(retired.copyWith(borderWidth: 2).lineNumberAlpha, 0.2);
      expect(retired, isNot(retired.copyWith(rowTintAlpha: 0.4)));
      expect(retired, isNot(retired.copyWith(lineNumberAlpha: 0.3)));
      expect(
        retired,
        isNot(retired.copyWith(addedColor: CoreColor.transparent)),
      );
      expect(
        retired,
        isNot(retired.copyWith(removedColor: CoreColor.transparent)),
      );
      expect(retired.hashCode, isNot(const CoreCodeDiffStyle().hashCode));
    });
  });

  group('CoreCodeDiffStyle — colour pairs hold contrast in all four modes', () {
    // check_contrast.dart does not list these pairs; this pins them here. Text
    // owes 4.5:1 (WCAG 1.4.3) and the small gutter number is text.
    const minimum = 4.5;
    const source = CouiColorPresets.source;
    final modes = <String, ResolvedColorScheme>{
      'light': source.light().resolved(.light),
      'dark': source.dark().resolved(.dark),
      'high-contrast light': source.highContrastLight().resolved(.light),
      'high-contrast dark': source.highContrastDark().resolved(.dark),
    };

    double ratio(ResolvedColorScheme scheme, CoreColor fg, CoreColor bg) =>
        CoreContrast.ratio(scheme.resolve(fg), scheme.resolve(bg));

    for (final mode in modes.entries) {
      final scheme = mode.value;
      const plainFace = CoreCodeDiffStyle.defaultSurfaceColor;
      const addedBand = CoreCodeDiffStyle.defaultAddedBackgroundColor;
      const removedBand = CoreCodeDiffStyle.defaultRemovedBackgroundColor;
      final bodyInk = CoreCodeDiffStyle.defaultUnchangedTextStyle.color!;

      test('${mode.key}: the body ink reads on the block face and on both '
          'bands', () {
        expect(
          ratio(scheme, bodyInk, plainFace),
          greaterThanOrEqualTo(minimum),
        );
        expect(
          ratio(scheme, bodyInk, addedBand),
          greaterThanOrEqualTo(minimum),
        );
        expect(
          ratio(scheme, bodyInk, removedBand),
          greaterThanOrEqualTo(minimum),
        );
      });

      test('${mode.key}: the band ink reads on its own band', () {
        expect(
          ratio(
            scheme,
            CoreCodeDiffStyle.defaultAddedForegroundColor,
            addedBand,
          ),
          greaterThanOrEqualTo(minimum),
        );
        expect(
          ratio(
            scheme,
            CoreCodeDiffStyle.defaultRemovedForegroundColor,
            removedBand,
          ),
          greaterThanOrEqualTo(minimum),
        );
      });

      test('${mode.key}: the plain gutter number reads on the block face', () {
        expect(
          ratio(scheme, CoreCodeDiffStyle.defaultLineNumberColor, plainFace),
          greaterThanOrEqualTo(minimum),
        );
      });
    }
  });
}
