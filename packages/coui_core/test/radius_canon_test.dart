import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The control corner is the control height × this (디자이너 결정
/// 2026-10-08) — one ratio on every rung, not one value.
const double _kRatio = 0.25;

/// The default derived corner a row takes when a `Select` panel hosts it — 6 on
/// every size: the panel corner (12) minus the panel padding (6), so the row
/// is concentric with the panel.
const CoreBorderRadius _kHostedRow = CoreBorderRadius.all(CoreRadius.radius6);

/// The corner a `Command` row takes — 8 on every size and presentation, the
/// designer's list-row decision. Not the hosted 6: the row is a little rounder
/// than the concentric corner its 6 list inset leaves inside the 12 panel.
const CoreBorderRadius _kCommandRow = CoreBorderRadius.all(CoreRadius.radius8);

/// The rung each [CoreComponentSize] aligns to. Stated here rather than
/// read off a style row so the test checks the rows against the contract,
/// not against themselves.
const Map<CoreComponentSize, double> _kControlHeight = {
  CoreComponentSize.xs: CoreControlSize.heightXs,
  CoreComponentSize.sm: CoreControlSize.heightSm,
  CoreComponentSize.md: CoreControlSize.heightMd,
  CoreComponentSize.lg: CoreControlSize.heightLg,
  CoreComponentSize.xl: CoreControlSize.heightXl,
  CoreComponentSize.xl2: CoreControlSize.heightXl2,
};

/// A chip's heights are its own three-tier ladder (not the shared six), so
/// they are stated here too — against the contract, not against the rows.
const Map<CoreChipSize, double> _kChipHeight = {
  CoreChipSize.sm: CoreSize.size28,
  CoreChipSize.md: CoreSize.size32,
  CoreChipSize.lg: CoreSize.size40,
};

/// The `FocusOutline` band's standoff from the host: `align − borderWidth`.
const double _kBandOffset =
    CoreFocusOutlineStyle.defaultAlign -
    CoreFocusOutlineStyle.defaultBorderWidth;

/// A corner stated on all four sides with one value — the only shape a
/// control row states — and that value.
double _uniform(CoreBorderRadius? radius, String where) {
  expect(radius, isNotNull, reason: '$where states no corner');
  final r = radius!;
  expect(
    {r.topLeft, r.topRight, r.bottomLeft, r.bottomRight},
    hasLength(1),
    reason: '$where is not one value on all four corners',
  );
  return r.topLeft;
}

void main() {
  group('control corner = control height × 0.25, on the size rows', () {
    test('every Button size row states height × 0.25 on a ladder rung', () {
      for (final size in CoreComponentSize.values) {
        final row = CoreButtonStyle.defaultsBySize[size]!;
        final corner = _uniform(row.borderRadius, 'Button $size');
        expect(row.height, _kControlHeight[size], reason: 'Button $size');
        expect(corner, _kControlHeight[size]! * _kRatio, reason: '$size');
        expect(CoreRadius.steps, contains(corner), reason: '$size');
      }
    });

    test('every TextField size row states height × 0.25 on a ladder rung', () {
      for (final size in CoreComponentSize.values) {
        final row = CoreTextFieldStyle.defaultsBySize[size]!;
        final corner = _uniform(row.borderRadius, 'TextField $size');
        expect(row.minHeight, _kControlHeight[size], reason: 'TextField $size');
        expect(corner, _kControlHeight[size]! * _kRatio, reason: '$size');
        expect(CoreRadius.steps, contains(corner), reason: '$size');
      }
    });

    test('the six corners are 6 · 8 · 10 · 12 · 14 · 16', () {
      expect(
        [
          for (final size in CoreComponentSize.values)
            CoreButtonStyle.defaultsBySize[size]!.borderRadius!.topLeft,
        ],
        [6, 8, 10, 12, 14, 16],
      );
    });

    test('TextArea takes the TextField corner of the same size', () {
      for (final size in CoreComponentSize.values) {
        expect(
          CoreTextAreaStyle.defaultsBySize[size]!.borderRadius,
          CoreTextFieldStyle.defaultsBySize[size]!.borderRadius,
          reason: 'TextArea $size',
        );
      }
    });

    test(
      'every Chip size row states its height × 0.25, snapped onto a rung',
      () {
        // A chip is on its own ladder (28 · 32 · 40), so the exact ratio is 7 ·
        // 8 · 10. 8 and 10 are rungs of `CoreRadius.steps`; 7 is not, and a
        // corner off the ladder would miss the preset and the Web
        // `--coui-radius-*` variable path — so it takes the rung below it,
        // 6. The exception is stated by the shape ("the ratio is not a
        // rung"), not by naming the size.
        for (final size in CoreChipSize.values) {
          final row = CoreChipStyle.defaultsBySize[size]!;
          final corner = _uniform(row.borderRadius, 'Chip $size');
          expect(row.minHeight, _kChipHeight[size], reason: 'Chip $size');
          expect(CoreRadius.steps, contains(corner), reason: 'Chip $size');
          final exact = _kChipHeight[size]! * _kRatio;
          if (CoreRadius.steps.contains(exact)) {
            expect(corner, exact, reason: 'Chip $size');
          } else {
            final below = CoreRadius.steps.where((rung) => rung < exact).last;
            expect(corner, below, reason: 'Chip $size is off the ladder');
          }
        }
        expect(
          [
            for (final size in CoreChipSize.values)
              CoreChipStyle.defaultsBySize[size]!.borderRadius!.topLeft,
          ],
          [6, 8, 10],
        );
      },
    );

    test('a standalone MenuItem row on a ladder height is its height × 0.25 '
        '(sm 8 · lg 12)', () {
      for (final size in [CoreMenuItemSize.sm, CoreMenuItemSize.lg]) {
        final row = CoreMenuItemStyle.defaultsBySize[size]!;
        final corner = _uniform(row.borderRadius, 'MenuItem $size');
        expect(corner, row.minHeight! * _kRatio, reason: 'MenuItem $size');
        expect(CoreRadius.steps, contains(corner), reason: '$size');
        // The same height on the shared ladder takes the same corner.
        expect(
          row.borderRadius,
          CoreButtonStyle.defaultsBySize[size.toComponentSize()]!.borderRadius,
          reason: 'MenuItem $size',
        );
      }
    });

    test(
      'the 36 MenuItem md row takes 8 — 36 × 0.25 = 9 is no corner rung',
      () {
        final row = CoreMenuItemStyle.defaultsBySize[CoreMenuItemSize.md]!;
        expect(row.minHeight, CoreSize.size36);
        expect(CoreControlSize.steps, isNot(contains(row.minHeight)));
        expect(row.minHeight! * _kRatio, 9);
        expect(CoreRadius.steps, isNot(contains(9)));
        expect(_uniform(row.borderRadius, 'MenuItem md'), 8);
      },
    );

    test('a variant that states its own radius wins over the size row', () {
      for (final size in CoreComponentSize.values) {
        expect(
          CoreButtonStyle.borderRadiusForSize(size: size, variantRadius: 4),
          const CoreBorderRadius.all(4),
          reason: '$size',
        );
        expect(
          CoreButtonStyle.borderRadiusForSize(size: size, variantRadius: null),
          CoreButtonStyle.defaultsBySize[size]!.borderRadius,
          reason: '$size',
        );
      }
      // No variant states one, so every variant reads the size row.
      for (final variant in CoreButtonVariant.values) {
        expect(
          CoreButtonStyle.defaultsByVariant[variant]!.radius,
          isNull,
          reason: '$variant',
        );
      }
    });

    test('shape exceptions — circle is a pill, plain field has no box', () {
      expect(
        CoreButtonStyle.defaultCircleBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
      // `plain` states no border colour and no box of its own; the corner it
      // does not draw is not a second radius value.
      expect(
        CoreTextFieldStyle.defaultPlainVariant.borderColor,
        CoreColor.transparent,
      );
    });
  });

  group('a nested surface is never rounder than its container', () {
    test('TextField affordances take the field corner at every size', () {
      // The clear / password affordance is a size-less (`md`) Button; its
      // own row would draw 10 inside an `xs` (6) or `sm` (8) field.
      expect(CoreTextFieldStyle.defaultFeatureButtonStyle.borderRadius, isNull);
      for (final size in CoreComponentSize.values) {
        final row = CoreTextFieldStyle.defaultsBySize[size]!;
        expect(
          row.featureButtonStyle?.borderRadius,
          row.borderRadius,
          reason: 'TextField $size',
        );
      }
    });

    test('a Chip close button is no rounder than its chip at every size', () {
      // The close button is `Button(variant: ghost, size: sm)` inside the
      // chip. The row states the chip's corner on it where the button's own
      // (8) would be rounder — only the small chip — and leaves it to the
      // button elsewhere.
      final ghost = CoreButtonStyle.defaultsByVariant[CoreButtonVariant.ghost]!;
      for (final size in CoreChipSize.values) {
        final row = CoreChipStyle.defaultsBySize[size]!;
        final close =
            row.closeButtonStyle!.borderRadius ??
            CoreButtonStyle.borderRadiusForSize(
              size: CoreComponentSize.sm,
              variantRadius: ghost.radius,
            );
        expect(
          close.topLeft,
          lessThanOrEqualTo(row.borderRadius!.topLeft),
          reason: 'Chip $size',
        );
      }
      expect(
        CoreChipStyle
            .defaultsBySize[CoreChipSize.sm]!
            .closeButtonStyle!
            .borderRadius,
        CoreChipStyle.defaultsBySize[CoreChipSize.sm]!.borderRadius,
      );
    });

    test('Menu rows take the copy’s 8 within the 12 panel; Select keeps 6', () {
      final menuRow = const CoreMenuStyle().effectiveItemStyle.borderRadius!;
      expect(menuRow, const CoreBorderRadius.all(CoreRadius.radius8));
      expect(
        menuRow.topLeft,
        lessThanOrEqualTo(CorePopupStyle.defaultBorderRadius.topLeft),
      );
      expect(CoreMenuStyle.defaultItemStyle.padding, isNull);
      expect(CoreSelectStyle.defaultOptionStyle.borderRadius, _kHostedRow);
      expect(
        const CoreSelectStyle().effectiveOptionStyle.borderRadius,
        _kHostedRow,
      );
    });

    test(
      'Command rows are 8 on every size and presentation, not the hosted 6',
      () {
        expect(CoreCommandStyle.defaultItemBorderRadius, _kCommandRow);
        expect(CoreCommandStyle.defaultItemBorderRadius, isNot(_kHostedRow));
        // No Command size or presentation row moves the row corner.
        for (final row in CoreCommandStyle.defaultsBySize.values) {
          expect(row.itemBorderRadius, isNull);
        }
        for (final row in CoreCommandStyle.defaultsByPresentation.values) {
          expect(row.itemBorderRadius, isNull);
          // A row is never rounder than the panel that holds it. A fullscreen
          // panel has no corner of its own (it is the screen's edge), so only
          // the rounded presentations state one.
          final panel = row.borderRadius!.topLeft;
          if (panel > 0) {
            expect(
              CoreCommandStyle.defaultItemBorderRadius.topLeft,
              lessThanOrEqualTo(panel),
            );
          }
        }
      },
    );

    test('a caller row override still wins over each hosted default', () {
      const override = CoreBorderRadius.all(CoreRadius.radius4);
      expect(
        const CoreMenuStyle(
          itemStyle: CoreMenuItemStyle(borderRadius: override),
        ).effectiveItemStyle.borderRadius,
        override,
      );
      expect(
        const CoreSelectStyle(
          optionStyle: CoreMenuItemStyle(borderRadius: override),
        ).effectiveOptionStyle.borderRadius,
        override,
      );
    });

    test('size-less composed controls restate their container corner', () {
      // Tree's rename field sits in the node row.
      expect(
        CoreTreeRenameRules.fieldStyle(
          const CoreTextStyle.token(CoreTextStyles.bodyMedium),
        ).borderRadius,
        CoreTreeStyle.defaultBorderRadius,
      );
      // ItemPicker's search field is the bare variant: it draws no corner
      // of its own, the picker's frame is the only box.
      expect(CoreItemPickerStyle.defaultSearchFieldStyle.borderRadius, isNull);
    });
  });

  group('a close button inside the toast panel', () {
    test("is a full circle — the same affordance as Banner's dismiss", () {
      // A designer decision: one role, one shape. The close is the square
      // `md` button made a circle by the full corner, like Banner's dismiss.
      expect(
        CoreToastStyle.defaultCloseButtonStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
      expect(
        CoreToastStyle.defaultCloseButtonStyle.borderRadius,
        CoreBannerStyle.defaultCloseButtonStyle.borderRadius,
      );
    });
  });

  group('containers keep their own corners', () {
    test('Fieldset is the surface role whatever the fields inside', () {
      // The fields it holds are elements that sit in it (their corner is per
      // size, 6 to 16), so the container is not derived from them — it is the
      // role of a container that sits on the page.
      expect(
        CoreFieldsetStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.surface),
      );
      expect(
        CoreFieldsetStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius16),
      );
    });

    test('Select panel stays 12, concentric with its 6 rows', () {
      final panel = CoreSelectStyle.defaultPopoverStyle.panelStyle!;
      final padding = panel.padding!;
      expect(padding.left, padding.top);
      expect(
        panel.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius12),
      );
      expect(
        panel.borderRadius!.topLeft,
        _kHostedRow.topLeft + padding.left,
      );
    });
  });

  group(
    'a hosted row is concentric with its panel (panel 12 = row 6 + pad 6)',
    () {
      test('the Popup panel holds a 6 row inside its 6 list padding', () {
        // A popup does not know it holds a list, so its own padding is the
        // content preset (16); a component that holds rows states the list
        // preset, and that is the inset the rows are concentric with.
        expect(
          CorePopupStyle.defaultListPadding,
          const CoreEdgeInsets.all(6),
        );
        expect(
          CorePopupStyle.defaultPadding,
          CorePopupStyle.defaultContentPadding,
        );
        expect(
          CorePopupStyle.defaultBorderRadius,
          const CoreBorderRadius.all(CoreRadiusRole.panel),
        );
        expect(
          CorePopupStyle.defaultBorderRadius.topLeft,
          _kHostedRow.topLeft + CorePopupStyle.defaultListPadding.left,
        );
      });

      test(
        'the Menu panel states the list padding and inherits the corner',
        () {
          const popup = CoreMenuStyle.defaultPopupStyle;
          expect(popup.padding, CorePopupStyle.defaultListPadding);
          expect(popup.borderRadius, isNull);
        },
      );

      test(
        'the Command list inset is 8, and its 8 row is rounder than the '
        'concentric corner (12 − 8) on purpose',
        () {
          final inline = CoreCommandStyle
              .defaultsByPresentation[CoreCommandPresentation.inline]!;
          expect(inline.listPadding, const CoreEdgeInsets.all(8));
          expect(
            CoreCommandStyle.defaultListPadding,
            const CoreEdgeInsets.all(8),
          );
          final panel = inline.borderRadius!.topLeft;
          final concentric = panel - inline.listPadding!.left;
          // The designer's copy states panel 12, list inset 8, row 8: the row
          // is not concentric with the panel (that would be 4), it is 4 rounder
          // — and still inside the panel.
          expect(panel, 12);
          expect(concentric, 4);
          expect(CoreCommandStyle.defaultItemBorderRadius.topLeft, 8);
          expect(
            CoreCommandStyle.defaultItemBorderRadius.topLeft,
            greaterThan(concentric),
          );
          expect(
            CoreCommandStyle.defaultItemBorderRadius.topLeft,
            lessThan(panel),
          );
        },
      );

      test('the Command dialog panel is the modal corner with an 8 inset', () {
        final dialog = CoreCommandStyle
            .defaultsByPresentation[CoreCommandPresentation.dialog]!;
        expect(
          dialog.borderRadius,
          const CoreBorderRadius.all(CoreRadiusRole.modal),
        );
        expect(dialog.listPadding, const CoreEdgeInsets.all(8));
      });

      test('the Fab speed-dial rows are 6 inside the Popup padding', () {
        expect(CoreFabStyle.defaultActionButtonStyle.borderRadius, _kHostedRow);
        expect(
          CorePopupStyle.defaultBorderRadius.topLeft,
          CoreFabStyle.defaultActionButtonStyle.borderRadius!.topLeft +
              CoreFabStyle.defaultPopupStyle.padding!.left,
        );
      });
    },
  );

  group('derived corners, not tokens', () {
    test('focus band = R + 2, ring = R + 4 (concentric) on every size', () {
      // The widget adds `offsetExtent` to the band and `align` to the ring;
      // these two are what those sums come out to on the control radius.
      // xl and xl2 reach 18 and 20 — computed, so off the ladder is fine.
      expect(_kBandOffset, 2);
      expect(CoreFocusOutlineStyle.defaultAlign, 4);
      final bands = <double>[];
      final rings = <double>[];
      for (final size in CoreComponentSize.values) {
        final r = CoreButtonStyle.defaultsBySize[size]!.borderRadius!.topLeft;
        bands.add(r + _kBandOffset);
        rings.add(r + CoreFocusOutlineStyle.defaultAlign);
      }
      expect(bands, [8, 10, 12, 14, 16, 18]);
      expect(rings, [10, 12, 14, 16, 18, 20]);
      // Button seeds its focus slot from the same align / width.
      expect(
        CoreButtonStyle.defaultFocusOutlineStyle.align,
        CoreFocusOutlineStyle.defaultAlign,
      );
      expect(
        CoreButtonStyle.defaultFocusOutlineStyle.borderWidth,
        CoreFocusOutlineStyle.defaultBorderWidth,
      );
      // The text area ring takes the host corner; the slot states none.
      expect(CoreTextAreaStyle.defaultFocusOutlineStyle.borderRadius, isNull);
    });
  });

  group('retired size-independent corners', () {
    // The four flat corners and the size-less helper stay compiling through
    // their deprecation window (process/deprecation.md) and keep answering
    // what they always answered — 8 — for callers outside the kit.
    test('still 8, still compiling', () {
      const retired = CoreBorderRadius.all(CoreRadius.radius8);
      expect(CoreButtonStyle.defaultBorderRadius, retired);
      expect(CoreTextFieldStyle.defaultBorderRadius, retired);
      expect(CoreTextAreaStyle.defaultBorderRadius, retired);
      expect(CoreMenuItemStyle.defaultBorderRadius, retired);
      expect(CoreButtonStyle.borderRadiusFor(variantRadius: null), retired);
      expect(
        CoreButtonStyle.borderRadiusFor(variantRadius: 4),
        const CoreBorderRadius.all(4),
      );
    });

    test('the retired chip corner still answers a pill', () {
      // Chip's flat corner is not a rung of the ladder either: it answers a
      // pill, and a caller outside the kit keeps that answer through the
      // window.
      expect(
        CoreChipStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
    });

    test('nothing in coui_core reads them', () {
      // A retired corner read anywhere would paint 8 where the size rows
      // say otherwise. Production source only — this test is the one
      // reader meant to exist — and with the retired pair's own
      // declarations cut out first: `borderRadiusFor` answering with
      // `defaultBorderRadius` is the retired unit, not a reader of it.
      final retiredTwin = RegExp(
        r'static CoreBorderRadius borderRadiusFor\([^)]*\)\s*\{.*?\n  \}',
        dotAll: true,
      );
      final declaration = RegExp(
        'static const CoreBorderRadius defaultBorderRadius =',
      );
      final declaring = {
        'contracts/button/button_style.dart',
        'contracts/text_field/text_field_style.dart',
        'contracts/text_area/text_area_style.dart',
        'contracts/menu_item/menu_item_style.dart',
        'contracts/chip/chip_style.dart',
      };
      final qualified = RegExp(
        r'\b(CoreButtonStyle|CoreTextFieldStyle|CoreTextAreaStyle|'
        r'CoreMenuItemStyle|CoreChipStyle)\s*\.\s*'
        r'(defaultBorderRadius|borderRadiusFor)\b',
      );
      final bare = RegExp(r'\b(defaultBorderRadius|borderRadiusFor)\b');
      final hits = <String>[];
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is! File || !file.path.endsWith('.dart')) continue;
        final path = file.uri.path;
        final isDeclaring = declaring.any(path.endsWith);
        final text = file.readAsStringSync().replaceAll(retiredTwin, '');
        for (final line in text.split('\n')) {
          final trimmed = line.trimLeft();
          if (trimmed.startsWith('//')) continue;
          if (declaration.hasMatch(line)) continue;
          if (qualified.hasMatch(line) ||
              (isDeclaring && bare.hasMatch(line))) {
            hits.add('${file.path}: ${line.trim()}');
          }
        }
      }
      expect(hits, isEmpty, reason: hits.join('\n'));
    });
  });

  group('the primitive ladder', () {
    test('has no 18 rung — the derived 18 above stays a number', () {
      expect(CoreRadius.steps, isNot(contains(18)));
      expect(CoreRadius.radius16, 16);
      expect(CoreRadius.radius20, 20);
    });
  });
}
