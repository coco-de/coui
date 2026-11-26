// The checker, checked.
//
// A contrast guard is a machine that turns colours into a verdict, and it
// can be wrong in the direction that produces silence. Two ways it has
// actually been wrong:
//
// * **Reading the wrong background.** In the Figma prototype of this check
//   the background walk started at the node itself instead of its parent,
//   and reported 204 findings that were not there. The code analogue is
//   compositing the label onto the page instead of onto the fill the
//   component paints — the label would then be measured against something
//   it never touches.
// * **Reading a fill that paints nothing as opaque.** A transparent
//   sentinel resolves to zero-alpha black; treated as a background it
//   makes every borderless variant look unreadable. This was hit twice
//   while writing these checks.
//
// Neither shows up as a red build. The first invents failures, the second
// invents them too — and a guard that cries wolf gets muted, which is how
// it ends up silent about the real thing.
//
// * **Measuring a mapping nobody renders.** The schemes were built from
//   the standard mapping for a long time while every CoUI seat rendered
//   CoUI's own mapping. That is the quiet direction again: the audit was
//   green about a blue `primary` no screen shows, and would have said
//   nothing about a change to the ink every screen does. The CoUI schemes
//   are now read from `CouiColorPresets.source`, the same value
//   `CoreThemePresets` renders, and the drift check below holds the two
//   together.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import '../tool/check_contrast.dart';
import 'support/brand_fixture.dart';

/// The four CoUI keys carrying the *standard* mapping's schemes — the
/// regression the drift check exists to catch, built in-test so the test
/// proves the check can fire rather than only that it currently does not.
List<AuditedScheme> _couiKeysOnStandardMapping() {
  final palette = kBrandFixturePalette;
  const standard = CoreSemanticMappingSet.standard;
  return [
    AuditedScheme(
      '$kCouiSchemePrefix light',
      standard.light(palette).resolved(.light),
      brightness: .light,
    ),
    AuditedScheme(
      '$kCouiSchemePrefix dark',
      standard.dark(palette).resolved(.dark),
      brightness: .dark,
    ),
    AuditedScheme(
      '$kCouiSchemePrefix high-contrast light',
      standard.highContrastLight(palette).resolved(.light),
      brightness: .light,
      highContrast: true,
    ),
    AuditedScheme(
      '$kCouiSchemePrefix high-contrast dark',
      standard.highContrastDark(palette).resolved(.dark),
      brightness: .dark,
      highContrast: true,
    ),
  ];
}

void main() {
  group('auditedSchemes — measures the mapping CoUI renders', () {
    final schemes = auditedSchemes();

    test('the CoUI schemes are what CoreThemePresets puts on screen', () {
      expect(auditDriftFromCouiTheme(schemes), isNull);
    });

    test('the drift check fires when the CoUI keys carry the standard '
        'mapping', () {
      // If this ever starts failing, the two mappings have converged and
      // the test above has stopped proving anything — decide then whether
      // the gate still has two mappings to tell apart.
      expect(
        auditDriftFromCouiTheme(_couiKeysOnStandardMapping()),
        contains(kCouiSchemePrefix),
      );
    });

    test('a CoUI scheme that is not audited at all is drift, not silence', () {
      expect(auditDriftFromCouiTheme(const []), isNotNull);
    });

    test('the standard mapping stays audited under its own keys', () {
      // What every brand inherits — kept, but never mistaken for CoUI's.
      final keys = schemes.map((s) => s.key).toSet();

      expect(keys, contains('$kStandardSchemePrefix light'));
      expect(keys, contains('$kStandardSchemePrefix high-contrast dark'));
      expect(keys.where((k) => k.startsWith(kCouiSchemePrefix)), isNotEmpty);
    });

    test('preset deltas are measured against their own mapping, not the '
        'other one', () {
      for (final s in schemes.where((s) => s.isPresetDelta)) {
        final prefix = s.key.split(' ').first;
        final brightness = s.key.endsWith('(dark)') ? 'dark' : 'light';
        final base = schemes.singleWhere((b) => b.key == '$prefix $brightness');

        expect(s.base, same(base.scheme), reason: s.key);
      }
    });
  });

  group('over — the composite the couples are measured on', () {
    const white = CoreColor.fromARGB(255, 255, 255, 255);
    const black = CoreColor.fromARGB(255, 0, 0, 0);

    test('full alpha is the foreground, untouched', () {
      expect(over(black, 1, white), black);
    });

    test('zero alpha is the background, untouched', () {
      expect(over(black, 0, white), white);
    });

    test('half alpha lands between the two', () {
      final blended = over(black, 0.5, white);

      expect(blended.red, closeTo(128, 1));
      expect(blended.red, greaterThan(black.red));
      expect(blended.red, lessThan(white.red));
    });

    test('and it composites onto the given background, not onto white', () {
      // The shape of the "wrong background" mistake: if this ignored `bg`
      // and used a fixed page colour, the two results below would match.
      final onWhite = over(black, 0.5, white);
      final onBlack = over(white, 0.5, black);

      expect(onWhite, onBlack, reason: 'symmetric by construction');

      const grey = CoreColor.fromARGB(255, 64, 64, 64);
      final onGrey = over(black, 0.5, grey);

      expect(onGrey.red, lessThan(onWhite.red));
    });
  });

  group('renderedCouples', () {
    final couples = renderedCouples();

    test('covers more than one component', () {
      final components = couples.map((c) => c.name.split('/').first).toSet();

      expect(components.length, greaterThan(1));
    });

    test('carries states beyond rest', () {
      // Rest-only was the gap that let `card` ship an unreadable hover.
      expect(couples.any((c) => c.name.endsWith('hover')), isTrue);
    });

    test('exempts disabled from the floor but still measures it', () {
      final disabled = couples.where((c) => c.name.endsWith('disabled'));

      expect(disabled, isNotEmpty);
      expect(disabled.every((c) => c.minimum == 0), isTrue);
    });

    test('holds every text couple to the body-text floor', () {
      // Text is held to 1.4.3. The scrollbar thumb, a badge's line and a
      // badge dot, a progress fill and a step's status glyph are not text and
      // owe the component bar instead — see the groups below.
      final text = couples.where(
        (c) => !c.name.endsWith('disabled') && !_isUiMark(c),
      );

      expect(text, isNotEmpty);
      expect(text.every((c) => c.minimum == 4.5), isTrue);
    });

    test('states no raised high-contrast bar on any text couple', () {
      // The raised bar is for UI lines. A text couple that grew one would
      // change what an existing baseline key means.
      final text = couples.where((c) => !_isUiMark(c));

      expect(text.every((c) => c.highContrastMinimum == null), isTrue);
      expect(
        text.every((c) => c.minimumIn(highContrast: true) == c.minimum),
        isTrue,
      );
    });
  });

  group('renderedCouples — tab strip and tree glyphs', () {
    final glyphs = renderedCouples().where(_isGlyphMark).toList();

    test('are audited: the selection bar, the close glyph, and the three '
        'tree glyphs', () {
      final names = glyphs.map((c) => c.name).toSet();

      expect(
        names,
        containsAll([
          'tab-pane/editor-strip indicator on selected tab',
          'tab-pane/editor-strip indicator on strip',
          'tab-pane/editor-strip close glyph on strip',
          'tab-pane/editor-strip close glyph on selected tab',
          for (final glyph in ['chevron', 'file glyph', 'folder glyph'])
            'tree/$glyph on selected row',
        ]),
      );
    });

    test('owe the component bar, not the text bar and not zero', () {
      for (final c in glyphs) {
        expect(c.minimum, 3, reason: c.name);
        expect(c.highContrastMinimum, isNull, reason: c.name);
      }
    });

    test('read their ink from the component defaults, not from a copy', () {
      final byName = {for (final c in glyphs) c.name: c};

      expect(
        byName['tab-pane/editor-strip indicator on strip']!.label,
        CoreTabPaneStyle.editorStrip.indicatorColor,
      );
      expect(
        byName['tab-pane/editor-strip close glyph on strip']!.label,
        CoreTabPaneStyle.editorStripCloseIconStyle.color,
      );
      expect(
        byName['tree/chevron on selected row']!.label,
        CoreTreeStyle.defaultChevronIconStyle.color,
      );
      expect(
        byName['tree/file glyph on selected row']!.label,
        CoreTreeStyle.defaultLeafIconStyle.color,
      );
      expect(
        byName['tree/folder glyph on selected row']!.label,
        CoreTreeStyle.defaultIconColor,
      );
    });
  });

  group('renderedCouples — the scrollbar thumb', () {
    final thumbs = renderedCouples().where(_isThumb).toList();
    final schemes = auditedSchemes().where((s) => !s.isPresetDelta).toList();

    test('is audited at rest and on hover, on every tone it is drawn on', () {
      final names = thumbs.map((c) => c.name).toSet();

      for (final tone in [
        'surface',
        'surface-bright',
        'surface-container-high',
      ]) {
        expect(names, contains('scrollbar/thumb on $tone rest'));
        expect(names, contains('scrollbar/thumb on $tone hover'));
      }
      expect(thumbs, hasLength(6));
    });

    test('reads its ink from the component defaults, not from a copy', () {
      for (final couple in thumbs) {
        final expected = couple.name.endsWith('hover')
            ? CoreScrollbarStyle.defaultHoverThumbColor
            : CoreScrollbarStyle.defaultThumbColor;

        expect(couple.label, expected, reason: couple.name);
      }
    });

    test(
      'is a couple because its ink is translucent, drawn on an opaque tone',
      () {
        // The whole reason the thumb cannot be a slot-versus-slot pair: what
        // the eye receives is the ink laid over the tone.
        for (final couple in thumbs) {
          expect(couple.label.opacity, lessThan(1), reason: couple.name);
          expect(couple.fill.opacity, 1, reason: couple.name);
        }
      },
    );

    test(
      'owes the component bar everywhere, not the text bar and not zero',
      () {
        expect(thumbs.every((c) => c.minimum == 3), isTrue);
      },
    );

    test('owes the raised bar only on the page and the panel, only where '
        'the mode states it', () {
      for (final couple in thumbs) {
        final onPageOrPanel =
            couple.name.contains('on surface ') ||
            couple.name.contains('on surface-bright ');

        expect(couple.minimumIn(highContrast: false), 3, reason: couple.name);
        expect(
          couple.minimumIn(highContrast: true),
          onPageOrPanel ? 4.5 : 3,
          reason: couple.name,
        );
      }
    });

    test('the raised bar is stated by CoUI high-contrast tables alone', () {
      final holders = schemes.where((s) => s.holdsHighContrastLine);

      expect(
        holders.map((s) => s.key),
        unorderedEquals([
          '$kCouiSchemePrefix high-contrast light',
          '$kCouiSchemePrefix high-contrast dark',
        ]),
      );
    });

    test('is measured on the tone it sits on, not on the page', () {
      final dark = schemes.singleWhere(
        (s) => s.key == '$kCouiSchemePrefix dark',
      );
      final onPanel = thumbs.singleWhere(
        (c) => c.name == 'scrollbar/thumb on surface-bright rest',
      );
      final panel = dark.scheme.surfaceBright;
      final ink = dark.scheme.resolve(CoreScrollbarStyle.defaultThumbColor);

      // The same arithmetic by hand: ink at its own alpha over the panel.
      final expected = CoreContrast.ratio(
        over(ink, CoreScrollbarStyle.defaultThumbColor.opacity, panel),
        panel,
      );
      final measured = renderedRatio(dark.scheme, onPanel)!;

      expect(measured, closeTo(expected, 1e-9));
      // And it is not the number the page would give — the dark panel is
      // lighter than the page, so a thumb measured against the page would
      // read stronger than the one the user sees.
      final onPage = renderedRatio(
        dark.scheme,
        thumbs.singleWhere((c) => c.name == 'scrollbar/thumb on surface rest'),
      )!;
      expect(measured, lessThan(onPage));
    });

    test('clears the ordinary 3:1 on every tone in every audited scheme', () {
      // The recorded high-contrast exception is a miss of the RAISED bar.
      // This is what keeps it from hiding a miss of the ordinary one: a
      // thumb under 3:1 anywhere is not an exception, it is a defect.
      for (final scheme in schemes) {
        for (final couple in thumbs) {
          final ratio = renderedRatio(scheme.scheme, couple)!;

          expect(
            ratio,
            greaterThanOrEqualTo(couple.minimum),
            reason: '${scheme.key} ${couple.name}',
          );
        }
      }
    });

    test('the gate can tell 40% ink from 50%', () {
      // The strength was chosen as the weakest that holds 3:1; 40% does not
      // (2.44:1 on the light page). If this stops failing, the threshold
      // moved and the number above is no longer why the default is 50%.
      final light = schemes.singleWhere(
        (s) => s.key == '$kCouiSchemePrefix light',
      );
      const page = CoreColor.token(CoreColors.surface);
      const fortyPercent = RenderedCouple(
        'scrollbar/thumb at 40%',
        page,
        CoreColor.token(CoreColors.onSurface, opacity: CoreOpacity.opacity40),
        3,
      );
      const fiftyPercent = RenderedCouple(
        'scrollbar/thumb at 50%',
        page,
        CoreScrollbarStyle.defaultThumbColor,
        3,
      );

      expect(renderedRatio(light.scheme, fortyPercent), lessThan(3));
      expect(
        renderedRatio(light.scheme, fiftyPercent),
        greaterThanOrEqualTo(3),
      );
    });
  });

  group('categoryPairs — the category colours and their bars by mode', () {
    final schemes = auditedSchemes().where((s) => !s.isPresetDelta).toList();
    final strongLabel = {
      for (final hue in CoreCategoryColor.values)
        (hue.onFill.name, hue.fill.name),
    };
    final outline = {
      for (final hue in CoreCategoryColor.values) hue.outline.name,
    };

    test('every source is audited in all four modes, each knowing which', () {
      for (final prefix in [kCouiSchemePrefix, kStandardSchemePrefix]) {
        final modes = schemes
            .where((s) => s.key.startsWith('$prefix '))
            .map((s) => (s.brightness, s.highContrast))
            .toList();

        expect(
          modes,
          unorderedEquals([
            (CoreBrightness.light, false),
            (CoreBrightness.dark, false),
            (CoreBrightness.light, true),
            (CoreBrightness.dark, true),
          ]),
          reason: prefix,
        );
      }
      for (final s in schemes) {
        expect(
          s.highContrast,
          s.key.contains('high-contrast'),
          reason: s.key,
        );
        expect(
          s.brightness.name,
          s.key.endsWith('dark') ? 'dark' : 'light',
          reason: s.key,
        );
      }
    });

    test('states the strong label, the soft label and the coloured text for '
        'every hue in every audited scheme', () {
      for (final s in schemes) {
        final pairs = categoryPairs(
          s.brightness,
          highContrast: s.highContrast,
        ).map((p) => (p.foreground, p.background)).toSet();

        for (final hue in CoreCategoryColor.values) {
          expect(
            pairs,
            containsAll([
              (hue.onFill.name, hue.fill.name),
              (hue.onContainer.name, hue.container.name),
              (hue.onContainer.name, 'surface'),
            ]),
            reason: '${s.key} ${hue.name}',
          );
        }
      }
    });

    test('3.5 is the light strong label alone — not a 3:1 tier, not '
        'elsewhere', () {
      for (final brightness in CoreBrightness.values) {
        for (final highContrast in [false, true]) {
          for (final p in categoryPairs(
            brightness,
            highContrast: highContrast,
          )) {
            final isLightStrongLabel =
                brightness == .light &&
                !highContrast &&
                strongLabel.contains((p.foreground, p.background));

            expect(
              p.minimum == 3.5,
              isLightStrongLabel,
              reason: '${brightness.name} hc=$highContrast $p',
            );
          }
        }
      }
    });

    test('high-contrast text owes 7 under CoUI, the standard mapping and '
        'a brand registered by colour alike', () {
      final highContrast = schemes.where((s) => s.highContrast).toList();

      // Every audited source, not CoUI's alone — the bar the floating-panel
      // line is held to is CoUI's, this one is not.
      expect(
        highContrast.map((s) => s.key.split(' ').first).toSet(),
        {kCouiSchemePrefix, kStandardSchemePrefix, kBrandSchemePrefix},
      );
      expect(highContrast.where((s) => !s.holdsHighContrastLine), isNotEmpty);
      for (final s in highContrast) {
        final text = categoryPairs(
          s.brightness,
          highContrast: true,
        ).where((p) => !outline.contains(p.foreground));

        expect(text, hasLength(CoreCategoryColor.values.length * 3));
        expect(text.every((p) => p.minimum == 7), isTrue, reason: s.key);
      }
    });

    test('the outline is held only in high contrast, only on the page', () {
      for (final brightness in CoreBrightness.values) {
        for (final highContrast in [false, true]) {
          final outlines = categoryPairs(
            brightness,
            highContrast: highContrast,
          ).where((p) => outline.contains(p.foreground)).toList();

          if (!highContrast) {
            expect(outlines, isEmpty, reason: brightness.name);
            continue;
          }
          expect(outlines, hasLength(CoreCategoryColor.values.length));
          expect(
            outlines.every((p) => p.background == 'surface'),
            isTrue,
            reason: brightness.name,
          );
          expect(outlines.every((p) => p.minimum == 4.5), isTrue);
        }
      }
    });

    test('every pair clears its bar in every audited scheme', () {
      for (final s in schemes) {
        final colours = {
          'surface': s.scheme.surface,
          for (final hue in CoreCategoryColor.values)
            for (final slot in CoreCategorySlot.values)
              hue.token(slot).name: hue.token(slot).read(s.scheme)!,
        };

        for (final p in categoryPairs(
          s.brightness,
          highContrast: s.highContrast,
        )) {
          final ratio = CoreContrast.ratio(
            colours[p.foreground]!,
            colours[p.background]!,
          );

          expect(
            ratio,
            greaterThanOrEqualTo(p.minimum),
            reason: '${s.key} ${p.foreground} on ${p.background}',
          );
        }
      }
    });

    test('the light bar can fail: a fill one step lighter is under it', () {
      // The lowest light fill is orange at 3.55:1. One step lighter measures
      // 3.49:1 — under the exception, and still over the 3:1 large-text
      // tier. If this stops failing, the bar is no longer 3.5.
      final light = CouiColorPresets.source
          .light()
          .copyWith(categoryOrange: const CoreColor(0xFFDA6910))
          .resolved(.light);
      final bar = categoryPairs(.light, highContrast: false).singleWhere(
        (p) =>
            p.foreground == CoreColors.onCategoryOrange.name &&
            p.background == CoreColors.categoryOrange.name,
      );
      final ratio = CoreContrast.ratio(
        light.onCategoryOrange,
        light.categoryOrange,
      );

      expect(ratio, closeTo(3.49, 0.005));
      expect(ratio, lessThan(bar.minimum));
      expect(ratio, greaterThan(CoreContrastLevel.aaLargeText.minimumRatio));
    });
  });

  group('renderedCouples — the badge', () {
    final badge = renderedCouples()
        .where((c) => c.name.startsWith('badge/'))
        .toList();
    final byName = {for (final c in badge) c.name: c};
    final coui = auditedSchemes()
        .where((s) => !s.isPresetDelta && s.key.startsWith(kCouiSchemePrefix))
        .toList();

    test('audits every tone at every strength, and the dot', () {
      for (final tone in CoreBadgeTone.values) {
        final t = tone.name;
        expect(byName, contains('badge/$t filled rest'));
        expect(byName, contains('badge/$t tonal rest'));
        for (final ground in _kContentGrounds) {
          expect(byName, contains('badge/$t outlined on $ground rest'));
          expect(byName, contains('badge/$t outlined line on $ground rest'));
          expect(byName, contains('badge/$t dot on $ground rest'));
        }
      }
      // Two filled strengths, then three couples per ground: the outlined
      // label, its line, and the dot.
      expect(
        badge,
        hasLength(
          CoreBadgeTone.values.length * (2 + 3 * _kContentGrounds.length),
        ),
      );
    });

    test('reads its colours through restingStyleFor, not from a copy', () {
      for (final entry in CoreBadgeStyle.defaultsByTone.entries) {
        final t = entry.key.name;
        final row = entry.value;
        for (final variant in [
          CoreBadgeVariant.filled,
          CoreBadgeVariant.tonal,
        ]) {
          final rest = row.restingStyleFor(variant, CoreBadgeForm.label);
          final couple = byName['badge/$t ${variant.name} rest']!;
          expect(couple.fill, rest.backgroundColor, reason: couple.name);
          expect(couple.label, rest.foregroundColor, reason: couple.name);
        }
        for (final ground in _kContentGrounds) {
          expect(
            byName['badge/$t outlined on $ground rest']!.label,
            row.outlinedForegroundColor,
          );
          expect(
            byName['badge/$t outlined line on $ground rest']!.label,
            row.outlinedBorderColor,
          );
          expect(byName['badge/$t dot on $ground rest']!.label, row.dotColor);
        }
      }
    });

    test('measures the outlined label on the grounds, because its fill '
        'paints nothing', () {
      // On its own fill the label would be skipped — the fill is the
      // transparent outlined one — and never measured at all.
      final light = coui.singleWhere(
        (s) => s.key == '$kCouiSchemePrefix light',
      );
      final onOwnFill = RenderedCouple(
        'badge/info outlined rest',
        CoreBadgeStyle.defaultOutlinedBackgroundColor,
        CoreBadgeStyle
            .defaultsByTone[CoreBadgeTone.info]!
            .outlinedForegroundColor,
        4.5,
      );

      expect(renderedRatio(light.scheme, onOwnFill), isNull);
      expect(byName, isNot(contains('badge/info outlined rest')));
      for (final c in badge.where((c) => c.name.contains(' on '))) {
        expect(c.fill.opacity, 1, reason: c.name);
      }
    });

    test('the line and the dot owe the component bar, the label the text '
        'bar — in every mode', () {
      for (final c in badge) {
        expect(c.minimum, _isUiMark(c) ? 3 : 4.5, reason: c.name);
        expect(c.highContrastMinimum, isNull, reason: c.name);
      }
    });

    test('clears its bar at rest in every CoUI scheme', () {
      for (final scheme in coui) {
        for (final c in badge) {
          final ratio = renderedRatio(scheme.scheme, c)!;

          expect(
            ratio,
            greaterThanOrEqualTo(c.minimum),
            reason: '${scheme.key} ${c.name}',
          );
        }
      }
    });

    test('the gate can tell a line from a label: the line colour set as '
        'text on a card is under the text bar', () {
      // Why the outlined label reads the tone's container text and not the
      // tone's own colour. In light the info line (`600`, 5.06 on the page)
      // measures 4.37 on the high card tone — over the 3:1 a line owes,
      // under the 4.5:1 a word owes. It clears 4.5 on the page and on the
      // card, so the high tone is where the two bars still part. If this
      // stops failing, the bars moved or the palette did, and the reason the
      // two halves of an outlined badge read different slots is no longer
      // this.
      final light = coui.singleWhere(
        (s) => s.key == '$kCouiSchemePrefix light',
      );
      final info = CoreBadgeStyle.defaultsByTone[CoreBadgeTone.info]!;
      const highCard = CoreColor.token(CoreColors.surfaceContainerHigh);
      final lineAsText = RenderedCouple(
        'badge/info line colour as text on surface-container-high',
        highCard,
        info.outlinedBorderColor,
        4.5,
      );
      final ratio = renderedRatio(light.scheme, lineAsText)!;

      expect(ratio, lessThan(4.5));
      expect(ratio, greaterThanOrEqualTo(3));
      expect(
        renderedRatio(
          light.scheme,
          byName['badge/info outlined on surface-container rest']!,
        ),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('renderedCouples — the step list', () {
    final steps = renderedCouples()
        .where(
          (c) => c.name.startsWith('step-item/') || c.name.startsWith('steps/'),
        )
        .toList();
    final byName = {for (final c in steps) c.name: c};
    final coui = auditedSchemes()
        .where((s) => !s.isPresetDelta && s.key.startsWith(kCouiSchemePrefix))
        .toList();

    test('audits every status glyph as a mark and its title and note as '
        'text, read from the status rows', () {
      for (final MapEntry(key: status, value: row)
          in CoreStepItemStyle.defaultsByStatus.entries) {
        for (final ground in ['surface', 'surface-container']) {
          final glyph =
              byName['step-item/${status.name} glyph on $ground rest']!;
          expect(glyph.label, row.iconStyle!.color, reason: glyph.name);
          expect(glyph.minimum, 3, reason: 'a glyph is a mark, not text');

          final title = byName['step-item/${status.name} title on $ground']!;
          expect(title.label, row.titleStyle!.color, reason: title.name);
          expect(title.minimum, 4.5, reason: title.name);

          final note = byName['step-item/${status.name} trailing on $ground']!;
          expect(note.label, row.trailingStyle!.color, reason: note.name);
          expect(note.minimum, 4.5, reason: note.name);
        }
      }
    });

    test('audits the cross a failed numbered step draws against its fill', () {
      final cross = byName['steps/failed indicator mark rest']!;

      expect(cross.fill, CoreStepsStyle.defaultFailedIndicatorColor);
      expect(cross.label, CoreStepsStyle.defaultFailedLabelColor);
      expect(cross.minimum, 3, reason: 'a status mark owes the component bar');
    });

    test('clears its bar at rest in every CoUI scheme, but the trailing note '
        'on a light card for the three statuses that are not failed', () {
      // The recorded exception: the third text tier on a filled card in
      // CoUI light (4.26), held in the contrast baseline's third-tier block.
      // A failed step's note reads in the error family's text ink instead.
      const exceptions = {
        'step-item/current trailing on surface-container',
        'step-item/done trailing on surface-container',
        'step-item/todo trailing on surface-container',
      };
      for (final scheme in coui) {
        for (final c in steps) {
          final ratio = renderedRatio(scheme.scheme, c)!;
          if (scheme.key == '$kCouiSchemePrefix light' &&
              exceptions.contains(c.name)) {
            expect(ratio, lessThan(4.5), reason: c.name);
            continue;
          }
          expect(
            ratio,
            greaterThanOrEqualTo(c.minimum),
            reason: '${scheme.key} ${c.name}',
          );
        }
      }
    });
  });

  group('renderedCouples — the progress bar', () {
    final progress = renderedCouples()
        .where((c) => c.name.startsWith('progress/'))
        .toList();
    final byName = {for (final c in progress) c.name: c};
    final coui = auditedSchemes()
        .where((s) => !s.isPresetDelta && s.key.startsWith(kCouiSchemePrefix))
        .toList();

    test(
      'audits every tone fill on the neutral track, read from the table',
      () {
        for (final MapEntry(key: tone, value: row)
            in CoreProgressStyle.defaultsByTone.entries) {
          final couple = byName['progress/${tone.name} fill on track rest']!;
          expect(couple.fill, CoreProgressStyle.defaultBackgroundColor);
          expect(couple.label, row.color);
          expect(couple.minimum, 3, reason: 'a fill is a mark, not text');
        }
      },
    );

    test('audits the three cells as text on the page and on a card', () {
      for (final ground in ['surface', 'surface-container']) {
        for (final (cell, style) in [
          ('label', CoreProgressStyle.defaultLabelStyle),
          ('value-label', CoreProgressStyle.defaultValueLabelStyle),
          ('caption', CoreProgressStyle.defaultCaptionStyle),
        ]) {
          final couple = byName['progress/$cell on $ground rest']!;
          expect(couple.label, style.color, reason: couple.name);
          expect(couple.minimum, 4.5, reason: couple.name);
        }
      }
    });

    test('clears its bar at rest in every CoUI scheme, but the caption on '
        'a light card', () {
      // The one recorded exception: the third text tier on a filled card
      // in CoUI light (4.26), held in the contrast baseline's third-tier
      // block with the other surfaces that tier misses on.
      const exception = 'progress/caption on surface-container rest';
      for (final scheme in coui) {
        for (final c in progress) {
          final ratio = renderedRatio(scheme.scheme, c)!;
          if (scheme.key == '$kCouiSchemePrefix light' && c.name == exception) {
            expect(ratio, lessThan(4.5));
            continue;
          }
          expect(
            ratio,
            greaterThanOrEqualTo(c.minimum),
            reason: '${scheme.key} ${c.name}',
          );
        }
      }
    });
  });

  group('renderedCouples — radio group text and the chip key', () {
    final couples = renderedCouples()
        .where(
          (c) =>
              c.name.startsWith('radio-group/') || c.name.startsWith('chip/'),
        )
        .toList();
    final byName = {for (final c in couples) c.name: c};
    final schemes = auditedSchemes().where((s) => !s.isPresetDelta).toList();
    const plain = 'radio-group/defaultVariant';
    const card = 'radio-group/card';

    test('audits the plain row description, the tile text on both faces, '
        'and the chip key on every resting face and both disabled faces', () {
      expect(
        byName.keys,
        containsAll([
          for (final ground in _kContentGrounds)
            '$plain description on $ground rest',
          '$plain description disabled',
          for (final face in ['tile', 'selected tile'])
            for (final ink in ['label', 'description'])
              for (final state in ['rest', 'hover', 'pressed'])
                '$card $ink on $face $state',
          for (final face in ['tile', 'selected tile'])
            '$card text on $face disabled',
          for (final color in CoreChipStyle.defaultsByColor.keys) ...[
            for (final ground in _kContentGrounds)
              'chip/${color.name} outlined key on $ground rest',
            'chip/${color.name} filled key rest',
          ],
          for (final color in [
            CoreChipColor.custom,
            ...CoreChipStyle.defaultsByColor.keys,
          ]) ...[
            'chip/${color.name} key disabled',
            'chip/${color.name} selected key disabled',
          ],
        ]),
      );
    });

    test('reads its inks and faces from the component defaults, not from '
        'a copy', () {
      const description = CoreRadioGroupStyle.defaultDescriptionStyle;
      expect(
        byName['$plain description on surface rest']!.label,
        description.color,
      );
      expect(
        byName['$card label on tile rest']!.label,
        CoreRadioGroupStyle.defaultLabelStyle.color,
      );
      expect(
        byName['$card description on selected tile rest']!.fill,
        CoreRadioGroupStyle.defaultTileSelectedBackgroundColor,
      );
      expect(
        byName['$card label on tile rest']!.fill,
        CoreRadioGroupStyle.defaultTileBackgroundColor,
      );
      for (final MapEntry(key: color, value: row)
          in CoreChipStyle.defaultsByColor.entries) {
        final filled = byName['chip/${color.name} filled key rest']!;

        expect(filled.label, row.unselectedPrefixFg);
        expect(
          filled.fill,
          CoreChipStyle.defaultFilledUnselectedBackgroundColor,
        );
        expect(
          byName['chip/${color.name} outlined key on surface rest']!.label,
          row.unselectedPrefixFg,
        );

        final disabled = byName['chip/${color.name} key disabled']!;
        final picked = byName['chip/${color.name} selected key disabled']!;

        expect(disabled.label, row.disabledFg);
        expect(disabled.fill, row.disabledBg);
        expect(picked.label, row.disabledFg);
        expect(picked.fill, row.disabledSelectedBg);
      }
      final customDisabled = byName['chip/custom key disabled']!;
      final customPicked = byName['chip/custom selected key disabled']!;

      expect(
        customDisabled.label,
        CoreChipStyle.defaultCustomDisabledForegroundColor,
      );
      expect(
        customDisabled.fill,
        CoreChipStyle.defaultCustomDisabledUnselectedBackgroundColor,
      );
      expect(
        customPicked.fill,
        CoreChipStyle.defaultCustomDisabledBackgroundColor,
      );
    });

    test("a tile's wash lands on the tile's face, not on the page", () {
      for (final face in ['tile', 'selected tile']) {
        final rest = byName['$card label on $face rest']!;
        final hover = byName['$card label on $face hover']!;

        expect(hover.base, rest.fill, reason: face);
        expect(
          hover.fill.token,
          CoreRadioGroupStyle.defaultStateLayerColor.token,
        );
      }
    });

    test('text owes the text bar, disabled owes nothing — in every mode', () {
      for (final c in couples) {
        expect(
          c.minimum,
          c.name.endsWith('disabled') ? 0 : 4.5,
          reason: c.name,
        );
        expect(c.highContrastMinimum, isNull, reason: c.name);
      }
    });

    // The selected tile's description under the wash is a recorded
    // exception in the baseline in the CoUI, standard and brand light and
    // dark schemes — pinned below.
    bool isWashedDescription(RenderedCouple c) =>
        c.name.startsWith('$card description on ') &&
        (c.name.endsWith(' pressed') || c.name.endsWith(' hover'));

    test('clears its bar in every audited scheme', () {
      for (final s in schemes) {
        for (final c in couples) {
          if (isWashedDescription(c) && !s.highContrast) continue;
          expect(
            renderedRatio(s.scheme, c),
            greaterThanOrEqualTo(c.minimum),
            reason: '${s.key} ${c.name}',
          );
        }
      }
    });

    test("the description under a tile's wash misses exactly where the "
        'baseline records it', () {
      final misses = {
        for (final s in schemes)
          for (final c in couples.where(isWashedDescription))
            if (renderedRatio(s.scheme, c)! < c.minimum) '${s.key} ${c.name}',
      };

      expect(misses, {
        'coui dark $card description on selected tile hover',
        'coui dark $card description on selected tile pressed',
        'coui light $card description on selected tile pressed',
        // The standard mapping's selected face moved one step away from the
        // page under the selected-face gap contract (#6202).
        'standard dark $card description on selected tile hover',
        'standard dark $card description on selected tile pressed',
        'standard light $card description on selected tile pressed',
        // A brand registered by colour reads CoUI's mapping for the wash and
        // its own container for the tile (see the baseline).
        'brand dark $card description on selected tile hover',
        'brand dark $card description on selected tile pressed',
        'brand light $card description on selected tile pressed',
      });
    });

    test("the tile's text clears the text bar at rest on both faces in every "
        'scheme — the selected face is `primaryContainer`', () {
      for (final s in schemes) {
        for (final face in ['tile', 'selected tile']) {
          for (final ink in ['label', 'description']) {
            expect(
              renderedRatio(s.scheme, byName['$card $ink on $face rest']!),
              greaterThanOrEqualTo(4.5),
              reason: '${s.key} $ink on $face',
            );
          }
        }
      }
    });

    test('the gate can tell the description ink from the tier below it: '
        'the third tier on a tile is under the text bar', () {
      // Why the description reads `onSurfaceVariant` and not the quieter
      // `onSurfaceSubtle`. In light the third tier measures 3.72 on the
      // selected tile's `primaryContainer` face. If this stops failing, the
      // palette moved and the reason the description reads the second
      // tier, not the third, is gone.
      final light = schemes.singleWhere(
        (s) => s.key == '$kCouiSchemePrefix light',
      );
      const subtle = RenderedCouple(
        '$card third tier on selected tile',
        CoreRadioGroupStyle.defaultTileSelectedBackgroundColor,
        CoreColor.token(CoreColors.onSurfaceSubtle),
        4.5,
      );

      expect(renderedRatio(light.scheme, subtle), lessThan(4.5));
      expect(
        renderedRatio(
          light.scheme,
          byName['$card description on selected tile rest']!,
        ),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('renderedRatio', () {
    final light = auditedSchemes().firstWhere(
      (s) => s.key == '$kCouiSchemePrefix light',
    );

    test('a fill that paints nothing is not measured', () {
      // The transparent sentinel resolves to zero-alpha black; read as a
      // background it would call every borderless variant unreadable.
      const borderless = RenderedCouple(
        'x/borderless rest',
        CoreColor.transparent,
        CoreColor.token(CoreColors.onSurface),
        4.5,
      );

      expect(renderedRatio(light.scheme, borderless), isNull);
    });

    test('a wash is laid over the face it states, not the page', () {
      // The same pressed wash and the same label, on two faces: measuring
      // both against the page would give one number for two different rows.
      const wash = CoreColor.token(CoreColors.onSurface, opacity: 0.12);
      const label = CoreColor.token(CoreColors.onSurfaceVariant);
      const onPage = RenderedCouple('x/wash page', wash, label, 4.5);
      const onHighlight = RenderedCouple(
        'x/wash highlight',
        wash,
        label,
        4.5,
        base: CoreColor.token(CoreColors.surfaceContainerHigh),
      );

      expect(
        renderedRatio(light.scheme, onHighlight),
        isNot(renderedRatio(light.scheme, onPage)),
      );
    });

    test('the floating-panel and table couples are audited in every mode', () {
      final names = renderedCouples().map((c) => c.name).toSet();

      expect(
        names,
        containsAll([
          'menu-item/label rest',
          'menu-item/label hover',
          'menu-item/label pressed',
          'menu-item/critical label hover',
          'menu-item/critical label pressed',
          'menu/group title',
          'command/label highlighted pressed',
          'command/overline highlighted pressed',
          'command/group heading',
          'table/header rest',
          'table/header hover',
          'table/cell selected',
        ]),
      );
      for (final scheme in auditedSchemes().where((s) => !s.isPresetDelta)) {
        for (final couple in renderedCouples().where(
          (c) =>
              c.name.startsWith('menu') ||
              c.name.startsWith('command') ||
              c.name.startsWith('table'),
        )) {
          expect(
            renderedRatio(scheme.scheme, couple),
            isNotNull,
            reason: '${scheme.key}: ${couple.name} paints a fill',
          );
        }
      }
    });
  });
}

/// The grounds a component with no fill of its own is measured on — an
/// outlined badge, a plain radio row, an outlined chip — by token name: the
/// page, the chrome rung, a card and a floating panel.
const _kContentGrounds = [
  'surface',
  'surface-container-low',
  'surface-container',
  'surface-bright',
];

/// Whether [couple] is the scrollbar thumb.
bool _isThumb(RenderedCouple couple) =>
    couple.name.startsWith('scrollbar/thumb');

/// Whether [couple] is a badge's line or a badge dot — drawn, not text.
bool _isBadgeMark(RenderedCouple couple) =>
    couple.name.startsWith('badge/') &&
    (couple.name.contains(' line on ') || couple.name.contains(' dot on '));

/// Whether [couple] is a progress bar's fill on its track — drawn, not text.
bool _isProgressMark(RenderedCouple couple) =>
    couple.name.startsWith('progress/') &&
    couple.name.contains(' fill on track');

/// Whether [couple] is a step's status glyph, or the cross a failed numbered
/// step draws on its fill — drawn, not text.
bool _isStepMark(RenderedCouple couple) =>
    (couple.name.startsWith('step-item/') &&
        couple.name.contains(' glyph on ')) ||
    couple.name == 'steps/failed indicator mark rest';

/// Whether [couple] is a glyph or bar a component draws without words — the
/// tab strip's selection bar and close glyph, and a tree's chevron, file and
/// folder glyphs.
bool _isGlyphMark(RenderedCouple couple) =>
    couple.name.startsWith('tab-pane/editor-strip ') ||
    couple.name.startsWith('tree/');

/// Whether [couple] is a UI mark rather than text — the scrollbar thumb, a
/// badge's line, a badge dot, a progress fill, a step's status glyph, a tab
/// strip's bar and close glyph, a tree's glyphs. Each owes the component bar
/// (WCAG 1.4.11), not the text bar.
bool _isUiMark(RenderedCouple couple) =>
    _isThumb(couple) ||
    _isBadgeMark(couple) ||
    _isProgressMark(couple) ||
    _isStepMark(couple) ||
    _isGlyphMark(couple);
