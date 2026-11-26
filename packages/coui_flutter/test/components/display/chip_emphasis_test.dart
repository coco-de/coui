// `emphasis` is a second axis on Chip, orthogonal to `selected`: a chip is
// selected or not, and separately it speaks loudly or quietly.
//
// Two things have to hold, and only one of them is about the new capability.
// The other is that adding it changed nothing — the axis defaults to `high`
// precisely because that is what every chip already rendered, and a default
// that repaints the catalogue as a side effect of gaining a knob is a
// regression however good the knob is.
//
// These read the value back at the point it is consumed rather than
// asserting the field exists. A field can be declared, carried through
// `copyWith`, compared in `==` and serialised, and still be read by nobody —
// which looks complete from the authoring side and changes no pixel.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// Resolves a chip under a default theme and hands back both the resolved
/// chrome and the scheme needed to name the colours it produced.
Future<({ResolvedChip resolved, CoreColorScheme scheme})> _resolve(
  WidgetTester tester, {
  required CoreChipColor chipColor,
  required CoreChipEmphasis emphasis,
  required bool selected,
  CoreChipVariant variant = CoreChipVariant.outlined,
  bool enabled = true,
  CoreColor? seedColor,
  CoreChipStyle? chipStyle,
  CoreChipTheme? chipTheme,
}) async {
  late ResolvedChip resolved;
  late CoreColorScheme scheme;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: ThemeData(
          coreComponentTheme: CoreComponentTheme(chip: chipTheme),
        ),
        child: Builder(
          builder: (context) {
            scheme = Theme.of(context).colorScheme;
            resolved = resolveChip(
              context,
              chipColor: chipColor,
              variant: variant,
              emphasis: emphasis,
              size: CoreChipSize.md,
              selected: selected,
              enabled: enabled,
              seedColor: seedColor,
              chipStyle: chipStyle,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return (resolved: resolved, scheme: scheme);
}

Color _token(CoreColorScheme scheme, CoreColorToken token) =>
    scheme.resolve(CoreColor.token(token)).toValue();

void main() {
  group('Chip emphasis', () {
    testWidgets('defaults to high — the render every chip already had', (
      tester,
    ) async {
      for (final color in CoreChipColor.values) {
        for (final selected in [true, false]) {
          final explicit = await _resolve(
            tester,
            chipColor: color,
            emphasis: CoreChipEmphasis.high,
            selected: selected,
          );
          final byDefault = await _resolve(
            tester,
            chipColor: color,
            emphasis: CoreChipEmphasis.defaultEmphasis,
            selected: selected,
          );

          final reason = '$color selected=$selected';
          expect(
            byDefault.resolved.containerStyle.backgroundColor,
            explicit.resolved.containerStyle.backgroundColor,
            reason: reason,
          );
          expect(
            byDefault.resolved.containerStyle.borderColor,
            explicit.resolved.containerStyle.borderColor,
            reason: reason,
          );
          expect(
            byDefault.resolved.foregroundColor,
            explicit.resolved.foregroundColor,
            reason: reason,
          );
        }
      }
    });

    testWidgets('low + selected tints from the colour container', (
      tester,
    ) async {
      final low = await _resolve(
        tester,
        chipColor: CoreChipColor.primary,
        emphasis: CoreChipEmphasis.low,
        selected: true,
      );

      expect(
        low.resolved.containerStyle.backgroundColor,
        const CoreColor.token(CoreColors.primaryContainer),
      );
      expect(
        low.resolved.foregroundColor,
        _token(low.scheme, CoreColors.onPrimaryContainer),
      );
    });

    testWidgets('low + unselected states no colour — the same chip for all', (
      tester,
    ) async {
      // A resting low chip is neutral whatever its colour: the quiet
      // hairline and `onSurfaceVariant` on the label. The colour first
      // appears when the chip is selected.
      for (final color in CoreChipColor.values) {
        if (color == CoreChipColor.custom) continue;
        final low = await _resolve(
          tester,
          chipColor: color,
          emphasis: CoreChipEmphasis.low,
          selected: false,
        );

        expect(
          low.resolved.containerStyle.borderColor,
          const CoreColor.token(CoreColors.outlineVariant),
          reason: '$color',
        );
        expect(
          low.resolved.foregroundColor,
          _token(low.scheme, CoreColors.onSurfaceVariant),
          reason: '$color',
        );
      }
    });

    testWidgets(
      'neutral at high — quiet outline resting, inverse pill selected',
      (
        tester,
      ) async {
        final unselected = await _resolve(
          tester,
          chipColor: CoreChipColor.neutral,
          emphasis: CoreChipEmphasis.high,
          selected: false,
        );
        expect(
          unselected.resolved.containerStyle.borderColor,
          const CoreColor.token(CoreColors.outlineVariant),
        );
        expect(
          unselected.resolved.foregroundColor,
          _token(unselected.scheme, CoreColors.onSurface),
        );

        // Fill, border, label, the wash the state layers paint and the icons
        // all follow the one inverse pair.
        final selected = await _resolve(
          tester,
          chipColor: CoreChipColor.neutral,
          emphasis: CoreChipEmphasis.high,
          selected: true,
        );
        const fill = CoreColor.token(CoreColors.inverseSurface);
        expect(selected.resolved.containerStyle.backgroundColor, fill);
        expect(selected.resolved.containerStyle.borderColor, fill);
        final onFill = _token(selected.scheme, CoreColors.inverseOnSurface);
        expect(selected.resolved.foregroundColor, onFill);
        expect(selected.resolved.labelTextStyle.color, onFill);
      },
    );

    testWidgets('primary at high — colourless resting, its own fill selected', (
      tester,
    ) async {
      // A resting chip states no colour at either volume: the quiet
      // hairline and `onSurface`, the same picture neutral draws. The colour
      // is the fill the chip takes on when it is selected.
      final unselected = await _resolve(
        tester,
        chipColor: CoreChipColor.primary,
        emphasis: CoreChipEmphasis.high,
        selected: false,
      );
      expect(
        unselected.resolved.containerStyle.borderColor,
        const CoreColor.token(CoreColors.outlineVariant),
        reason: 'resting border',
      );
      expect(
        unselected.resolved.foregroundColor,
        _token(unselected.scheme, CoreColors.onSurface),
        reason: 'resting label',
      );
      final selected = await _resolve(
        tester,
        chipColor: CoreChipColor.primary,
        emphasis: CoreChipEmphasis.high,
        selected: true,
      );
      expect(
        selected.resolved.containerStyle.backgroundColor,
        const CoreColor.token(CoreColors.primary),
        reason: 'selected fill',
      );
    });

    testWidgets('a resting chip is the same picture for every colour', (
      tester,
    ) async {
      for (final emphasis in CoreChipEmphasis.values) {
        final neutral = await _resolve(
          tester,
          chipColor: CoreChipColor.neutral,
          emphasis: emphasis,
          selected: false,
        );
        final primary = await _resolve(
          tester,
          chipColor: CoreChipColor.primary,
          emphasis: emphasis,
          selected: false,
        );
        expect(
          primary.resolved.containerStyle,
          neutral.resolved.containerStyle,
          reason: '${emphasis.name} box',
        );
        expect(
          primary.resolved.foregroundColor,
          neutral.resolved.foregroundColor,
          reason: '${emphasis.name} label',
        );
      }
    });

    // Without this the tests above would still pass if the resolver ignored
    // `emphasis` entirely and the low values simply happened to match.
    testWidgets('low actually renders differently from high', (tester) async {
      // Selected: the fill and the label both change register. Unselected:
      // both volumes sit on the same quiet hairline, so the label — darker
      // at high — is the only part that differs.
      final lowSel = await _resolve(
        tester,
        chipColor: CoreChipColor.primary,
        emphasis: CoreChipEmphasis.low,
        selected: true,
      );
      final highSel = await _resolve(
        tester,
        chipColor: CoreChipColor.primary,
        emphasis: CoreChipEmphasis.high,
        selected: true,
      );
      expect(
        lowSel.resolved.foregroundColor,
        isNot(highSel.resolved.foregroundColor),
      );

      final lowUn = await _resolve(
        tester,
        chipColor: CoreChipColor.primary,
        emphasis: CoreChipEmphasis.low,
        selected: false,
      );
      final highUn = await _resolve(
        tester,
        chipColor: CoreChipColor.primary,
        emphasis: CoreChipEmphasis.high,
        selected: false,
      );
      expect(
        lowUn.resolved.containerStyle.borderColor,
        highUn.resolved.containerStyle.borderColor,
      );
      expect(
        lowUn.resolved.foregroundColor,
        isNot(highUn.resolved.foregroundColor),
      );
    });

    testWidgets('disabled is two rows — the selection survives the greying', (
      tester,
    ) async {
      // A palette of disabled chips with one of them selected is where a
      // single disabled fill failed: the picked chip fell back to the
      // unselected look. Selected keeps a filled container with no border
      // at all — the transparent sentinel, which the composed
      // `OutlinedContainer` collapses out of layout, so the pill is NOT
      // 1px wider per side than the designer's stroke-less copy; unselected
      // sits on the surface behind a hairline.
      final selected = await _resolve(
        tester,
        chipColor: CoreChipColor.primary,
        emphasis: CoreChipEmphasis.high,
        selected: true,
        enabled: false,
      );
      expect(
        selected.resolved.containerStyle.backgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
      expect(
        selected.resolved.containerStyle.borderColor,
        CoreColor.transparent,
      );
      // A stroke in the fill colour is what this used to be — pixel-identical
      // in Flutter, but a stroke on the canvas. Guard the distinction.
      expect(
        selected.resolved.containerStyle.borderColor,
        isNot(const CoreColor.token(CoreColors.disabledContainer)),
      );

      final unselected = await _resolve(
        tester,
        chipColor: CoreChipColor.primary,
        emphasis: CoreChipEmphasis.high,
        selected: false,
        enabled: false,
      );
      expect(
        unselected.resolved.containerStyle.backgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
      expect(
        unselected.resolved.containerStyle.borderColor,
        const CoreColor.token(CoreColors.disabledOutline),
      );

      // The colour is gone from both — including the label, which is the
      // disabled ink and not one step down from the resting one.
      for (final r in [selected, unselected]) {
        expect(
          r.resolved.foregroundColor,
          _token(r.scheme, CoreColors.disabledContent),
        );
      }
    });

    testWidgets('disabled ignores emphasis — it has no volume', (
      tester,
    ) async {
      for (final selected in [true, false]) {
        final low = await _resolve(
          tester,
          chipColor: CoreChipColor.primary,
          emphasis: CoreChipEmphasis.low,
          selected: selected,
          enabled: false,
        );
        final high = await _resolve(
          tester,
          chipColor: CoreChipColor.primary,
          emphasis: CoreChipEmphasis.high,
          selected: selected,
          enabled: false,
        );

        expect(
          low.resolved.foregroundColor,
          high.resolved.foregroundColor,
          reason: 'selected=$selected',
        );
        expect(
          low.resolved.containerStyle.backgroundColor,
          high.resolved.containerStyle.backgroundColor,
          reason: 'selected=$selected',
        );
      }
    });

    testWidgets('a custom seed drops out at low, and says so', (tester) async {
      const seed = CoreColor(0xFF3366FF);

      final highSelected = await _resolve(
        tester,
        chipColor: CoreChipColor.custom,
        emphasis: CoreChipEmphasis.high,
        selected: true,
        seedColor: seed,
      );
      expect(highSelected.resolved.containerStyle.backgroundColor, seed);

      // There is no container token to derive from a raw seed, so low
      // reads as a quiet neutral chip until the caller supplies a tint.
      final lowSelected = await _resolve(
        tester,
        chipColor: CoreChipColor.custom,
        emphasis: CoreChipEmphasis.low,
        selected: true,
        seedColor: seed,
      );
      expect(
        lowSelected.resolved.containerStyle.backgroundColor,
        CoreChipStyle.defaultCustomLowSelectedBackgroundColor,
      );

      final lowUnselected = await _resolve(
        tester,
        chipColor: CoreChipColor.custom,
        emphasis: CoreChipEmphasis.low,
        selected: false,
        seedColor: seed,
      );
      expect(
        lowUnselected.resolved.containerStyle.borderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
    });

    // The four low-emphasis values the axis introduced are `CoreChipStyle`
    // fields, not constants the resolver reaches past the merge chain — so a
    // caller can retune the quiet register the same way it retunes anything
    // else. A default with no field behind it is unreachable by definition.
    testWidgets('a caller can retune the quiet register', (tester) async {
      const tint = CoreColor(0xFFAABBCC);

      final unselected = await _resolve(
        tester,
        chipColor: CoreChipColor.primary,
        emphasis: CoreChipEmphasis.low,
        selected: false,
        chipStyle: const CoreChipStyle(lowUnselectedBorderColor: tint),
      );
      expect(unselected.resolved.containerStyle.borderColor, tint);

      final customSelected = await _resolve(
        tester,
        chipColor: CoreChipColor.custom,
        emphasis: CoreChipEmphasis.low,
        selected: true,
        seedColor: const CoreColor(0xFF3366FF),
        chipStyle: const CoreChipStyle(customLowSelectedBackgroundColor: tint),
      );
      expect(customSelected.resolved.containerStyle.backgroundColor, tint);
    });
  });

  group('Chip variant', () {
    const fill = CoreColor.token(CoreColors.surfaceContainerHigh);

    testWidgets('filled paints a grey fill and mirrors it as the border', (
      tester,
    ) async {
      for (final color in CoreChipColor.values) {
        for (final emphasis in CoreChipEmphasis.values) {
          final r = await _resolve(
            tester,
            chipColor: color,
            variant: CoreChipVariant.filled,
            emphasis: emphasis,
            selected: false,
            seedColor: const CoreColor(0xFF3366FF),
          );
          final reason = '${color.name} ${emphasis.name}';
          expect(
            r.resolved.containerStyle.backgroundColor,
            fill,
            reason: reason,
          );
          expect(r.resolved.containerStyle.borderColor, fill, reason: reason);
        }
      }
    });

    testWidgets('filled keeps the label of each volume, whatever the colour', (
      tester,
    ) async {
      for (final color in [CoreChipColor.neutral, CoreChipColor.primary]) {
        final low = await _resolve(
          tester,
          chipColor: color,
          variant: CoreChipVariant.filled,
          emphasis: CoreChipEmphasis.low,
          selected: false,
        );
        final high = await _resolve(
          tester,
          chipColor: color,
          variant: CoreChipVariant.filled,
          emphasis: CoreChipEmphasis.high,
          selected: false,
        );
        expect(
          low.resolved.foregroundColor,
          _token(low.scheme, CoreColors.onSurfaceVariant),
          reason: '${color.name} low',
        );
        expect(
          high.resolved.foregroundColor,
          _token(high.scheme, CoreColors.onSurface),
          reason: '${color.name} high',
        );
      }
    });

    testWidgets('outlined is the default and keeps the transparent fill', (
      tester,
    ) async {
      expect(const Chip().variant, CoreChipVariant.outlined);
      final r = await _resolve(
        tester,
        chipColor: CoreChipColor.neutral,
        emphasis: CoreChipEmphasis.high,
        selected: false,
      );
      expect(r.resolved.containerStyle.backgroundColor, CoreColor.transparent);
      expect(
        r.resolved.containerStyle.borderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
    });

    testWidgets('variant never touches a selected or a disabled chip', (
      tester,
    ) async {
      for (final color in [CoreChipColor.neutral, CoreChipColor.primary]) {
        for (final emphasis in CoreChipEmphasis.values) {
          for (final (selected, enabled) in [
            (true, true),
            (true, false),
            (false, false),
          ]) {
            final outlined = await _resolve(
              tester,
              chipColor: color,
              emphasis: emphasis,
              selected: selected,
              enabled: enabled,
            );
            final filled = await _resolve(
              tester,
              chipColor: color,
              variant: CoreChipVariant.filled,
              emphasis: emphasis,
              selected: selected,
              enabled: enabled,
            );
            final reason =
                '${color.name} ${emphasis.name} selected=$selected '
                'enabled=$enabled';
            expect(
              filled.resolved.containerStyle,
              outlined.resolved.containerStyle,
              reason: reason,
            );
            expect(
              filled.resolved.foregroundColor,
              outlined.resolved.foregroundColor,
              reason: reason,
            );
          }
        }
      }
    });

    testWidgets('the state layer washes the filled fill, not the page', (
      tester,
    ) async {
      final r = await _resolve(
        tester,
        chipColor: CoreChipColor.neutral,
        variant: CoreChipVariant.filled,
        emphasis: CoreChipEmphasis.high,
        selected: false,
      );
      final rest = r.resolved.containerStyle.backgroundColor;
      expect(r.resolved.hoverContainerStyle.backgroundColor, isNot(rest));
      expect(r.resolved.pressedContainerStyle.backgroundColor, isNot(rest));
      // The border is the fill's mirror and does not wash with it.
      expect(r.resolved.hoverContainerStyle.borderColor, fill);
    });

    testWidgets('a caller retunes the filled fill through chipStyle', (
      tester,
    ) async {
      const tint = CoreColor(0xFFAABBCC);
      final r = await _resolve(
        tester,
        chipColor: CoreChipColor.neutral,
        variant: CoreChipVariant.filled,
        emphasis: CoreChipEmphasis.high,
        selected: false,
        chipStyle: const CoreChipStyle(filledUnselectedBackgroundColor: tint),
      );
      expect(r.resolved.containerStyle.backgroundColor, tint);
      expect(r.resolved.containerStyle.borderColor, tint);
    });

    testWidgets('the theme reaches the resolver by variant and by colour', (
      tester,
    ) async {
      const byVariant = CoreColor(0xFF112233);
      const byColor = CoreColor(0xFF445566);
      const theme = CoreChipTheme(
        variantStyles: {
          CoreChipVariant.filled: CoreChipStyle(
            filledUnselectedBackgroundColor: byVariant,
          ),
        },
        colorStyles: {
          CoreChipColor.primary: CoreChipStyle(
            foregroundColor: byColor,
          ),
        },
      );

      final filledPrimary = await _resolve(
        tester,
        chipColor: CoreChipColor.primary,
        variant: CoreChipVariant.filled,
        emphasis: CoreChipEmphasis.high,
        selected: false,
        chipTheme: theme,
      );
      expect(filledPrimary.resolved.containerStyle.backgroundColor, byVariant);
      expect(
        filledPrimary.resolved.foregroundColor,
        filledPrimary.scheme.resolve(byColor).toValue(),
      );

      // Another variant and another colour read neither entry.
      final outlinedNeutral = await _resolve(
        tester,
        chipColor: CoreChipColor.neutral,
        emphasis: CoreChipEmphasis.high,
        selected: false,
        chipTheme: theme,
      );
      expect(
        outlinedNeutral.resolved.containerStyle.backgroundColor,
        CoreColor.transparent,
      );
      expect(
        outlinedNeutral.resolved.foregroundColor,
        _token(outlinedNeutral.scheme, CoreColors.onSurface),
      );
    });
  });

  group('Chip filled + low report', () {
    Future<List<FlutterErrorDetails>> pumpAndCollect(
      WidgetTester tester,
      Chip chip,
    ) async {
      final reports = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = reports.add;
      try {
        await tester.pumpWidget(
          material.MaterialApp(
            home: Theme(data: const ThemeData(), child: chip),
          ),
        );
      } finally {
        FlutterError.onError = previous;
      }
      return reports;
    }

    testWidgets('a static filled + low badge is silent', (tester) async {
      final reports = await pumpAndCollect(
        tester,
        const Chip(
          label: 'x',
          variant: CoreChipVariant.filled,
          emphasis: CoreChipEmphasis.low,
        ),
      );
      expect(reports, isEmpty);
    });

    testWidgets('a selectable filled + low chip is reported once, in debug', (
      tester,
    ) async {
      final reports = await pumpAndCollect(
        tester,
        const Chip(
          label: 'x',
          variant: CoreChipVariant.filled,
          emphasis: CoreChipEmphasis.low,
          selected: true,
        ),
      );
      expect(reports, hasLength(1));
      expect(
        reports.single.exceptionAsString(),
        contains(CoreChipContract.filledLowEmphasisReport),
      );
    });

    testWidgets('every other pairing is silent', (tester) async {
      for (final (variant, emphasis) in [
        (CoreChipVariant.filled, CoreChipEmphasis.high),
        (CoreChipVariant.outlined, CoreChipEmphasis.low),
        (CoreChipVariant.outlined, CoreChipEmphasis.high),
      ]) {
        final reports = await pumpAndCollect(
          tester,
          Chip(label: 'x', variant: variant, emphasis: emphasis),
        );
        expect(reports, isEmpty, reason: '${variant.name} ${emphasis.name}');
      }
    });
  });
}
