// The Web half of Chip's `emphasis` axis — same two obligations as the
// Flutter twin: the new quiet register works, and adding it repainted
// nothing that already existed.
//
// Web emits token names rather than resolved colours, so these read the
// class the resolver put on the root. That is the consumption point here:
// the browser turns `bg-primary-container` into a colour at runtime, and
// what this layer owes is the right token name.
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/base/debug_warn.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));

  return context;
}

ResolvedChip _resolve(
  BuildContext context, {
  required CoreChipColor chipColor,
  required CoreChipEmphasis emphasis,
  required bool selected,
  CoreChipVariant variant = CoreChipVariant.outlined,
  bool enabled = true,
  CoreColor? seedColor,
}) => resolveChip(
  context,
  variant: variant,
  chipColor: chipColor,
  size: CoreChipSize.md,
  selected: selected,
  emphasis: emphasis,
  enabled: enabled,
  seedColor: seedColor,
);

void main() {
  group('Chip emphasis', () {
    testComponents('defaults to high — the render every chip already had', (
      tester,
    ) async {
      final context = _themedContext(tester);

      for (final color in CoreChipColor.values) {
        for (final selected in [true, false]) {
          final explicit = _resolve(
            context,
            chipColor: color,
            emphasis: CoreChipEmphasis.high,
            selected: selected,
          );
          final byDefault = _resolve(
            context,
            chipColor: color,
            emphasis: CoreChipEmphasis.defaultEmphasis,
            selected: selected,
          );

          expect(
            byDefault.root.className,
            explicit.root.className,
            reason: '$color selected=$selected',
          );
          expect(
            byDefault.label.className,
            explicit.label.className,
            reason: '$color selected=$selected',
          );
        }
      }
    });

    testComponents('low + selected tints from the colour container', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        chipColor: CoreChipColor.primary,
        emphasis: CoreChipEmphasis.low,
        selected: true,
      );

      expect(
        resolved.root.className,
        contains(CoreColors.primaryContainer.name),
      );
    });

    testComponents(
      'low + unselected states no colour — the same chip for all',
      (
        tester,
      ) async {
        final context = _themedContext(tester);

        // A resting low chip is neutral whatever its colour: the quiet
        // hairline and `on-surface-variant` on the label. The colour first
        // appears when the chip is selected.
        for (final color in CoreChipColor.values) {
          if (color == CoreChipColor.custom) continue;
          final resolved = _resolve(
            context,
            chipColor: color,
            emphasis: CoreChipEmphasis.low,
            selected: false,
          );

          expect(
            resolved.root.className,
            contains('border-${CoreColors.outlineVariant.name}'),
            reason: '$color',
          );
          expect(
            resolved.root.className,
            contains('text-${CoreColors.onSurfaceVariant.name}'),
            reason: '$color',
          );
          expect(
            resolved.root.className,
            isNot(contains('text-${CoreColors.primary.name}')),
            reason: '$color keeps no primary on a resting low chip',
          );
        }
      },
    );

    testComponents(
      'neutral at high — quiet outline resting, inverse pill selected',
      (tester) async {
        final context = _themedContext(tester);

        final unselected = _resolve(
          context,
          chipColor: CoreChipColor.neutral,
          emphasis: CoreChipEmphasis.high,
          selected: false,
        );
        expect(
          unselected.root.className,
          contains('border-${CoreColors.outlineVariant.name}'),
        );
        expect(
          unselected.root.className,
          contains('text-${CoreColors.onSurface.name}'),
        );

        // Fill, border and label follow the one inverse pair.
        final selected = _resolve(
          context,
          chipColor: CoreChipColor.neutral,
          emphasis: CoreChipEmphasis.high,
          selected: true,
        );
        expect(
          selected.root.className,
          contains('bg-${CoreColors.inverseSurface.name}'),
        );
        expect(
          selected.root.className,
          contains('border-${CoreColors.inverseSurface.name}'),
        );
        expect(
          selected.root.className,
          contains('text-${CoreColors.inverseOnSurface.name}'),
        );
      },
    );

    testComponents(
      'primary at high — colourless resting, its own fill selected',
      (tester) async {
        final context = _themedContext(tester);

        // A resting chip states no colour at either volume: the quiet
        // hairline and `on-surface`, the same picture neutral draws. The
        // colour is the fill the chip takes on when it is selected.
        final unselected = _resolve(
          context,
          chipColor: CoreChipColor.primary,
          emphasis: CoreChipEmphasis.high,
          selected: false,
        );
        expect(
          unselected.root.className,
          contains('border-${CoreColors.outlineVariant.name}'),
        );
        expect(
          unselected.root.className,
          contains('text-${CoreColors.onSurface.name}'),
        );
        expect(
          unselected.root.className,
          isNot(contains('border-${CoreColors.primary.name}')),
        );
        final selected = _resolve(
          context,
          chipColor: CoreChipColor.primary,
          emphasis: CoreChipEmphasis.high,
          selected: true,
        );
        expect(
          selected.root.className,
          contains('bg-${CoreColors.primary.name}'),
        );
      },
    );

    testComponents('a resting chip is the same picture for every colour', (
      tester,
    ) async {
      final context = _themedContext(tester);

      for (final emphasis in CoreChipEmphasis.values) {
        final neutral = _resolve(
          context,
          chipColor: CoreChipColor.neutral,
          emphasis: emphasis,
          selected: false,
        );
        final primary = _resolve(
          context,
          chipColor: CoreChipColor.primary,
          emphasis: emphasis,
          selected: false,
        );
        expect(
          primary.root.className,
          neutral.root.className,
          reason: '${emphasis.name} classes',
        );
      }
    });

    testComponents(
      'disabled is two rows — the selection survives the greying',
      (
        tester,
      ) async {
        final context = _themedContext(tester);

        // Selected keeps a filled container whose border is its own fill;
        // unselected sits on the surface behind a hairline. The ink is the
        // disabled one on both — not a step down from the resting label.
        final selected = _resolve(
          context,
          chipColor: CoreChipColor.primary,
          emphasis: CoreChipEmphasis.high,
          selected: true,
          enabled: false,
        );
        expect(
          selected.root.className,
          contains('bg-${CoreColors.disabledContainer.name}'),
        );
        expect(
          selected.root.className,
          contains('text-${CoreColors.disabledContent.name}'),
        );
        expect(
          selected.root.className,
          isNot(contains('border-${CoreColors.disabledOutline.name}')),
        );
        // No border at all — not a stroke in the fill colour, which is
        // what this row used to state and what the designer's copy does
        // not draw. The width collapses with it (the outlined-container
        // rule both platforms apply to a transparent border), so this
        // pill keeps the same box as its Flutter twin.
        expect(
          selected.root.className,
          isNot(contains('border-${CoreColors.disabledContainer.name}')),
        );
        expect(
          selected.root.inlineStyles?.properties['border-color'],
          CoreColor.transparent.toValue(),
        );
        expect(
          selected.root.inlineStyles?.properties['border-width'],
          strokeWidthCss(CoreStrokeWidth.stroke0),
        );

        final unselected = _resolve(
          context,
          chipColor: CoreChipColor.primary,
          emphasis: CoreChipEmphasis.high,
          selected: false,
          enabled: false,
        );
        expect(
          unselected.root.className,
          contains('bg-${CoreColors.surface.name}'),
        );
        expect(
          unselected.root.className,
          contains('border-${CoreColors.disabledOutline.name}'),
        );
        expect(
          unselected.root.className,
          contains('text-${CoreColors.disabledContent.name}'),
        );
        // The hairline row keeps its width — the collapse is the
        // transparent row's alone.
        expect(
          unselected.root.inlineStyles?.properties['border-width'],
          isNull,
        );
      },
    );

    // Without this the two above would still pass if the resolver ignored
    // `emphasis` and the low values simply happened to match.
    testComponents('low actually emits different classes from high', (
      tester,
    ) async {
      final context = _themedContext(tester);

      for (final selected in [true, false]) {
        final low = _resolve(
          context,
          chipColor: CoreChipColor.primary,
          emphasis: CoreChipEmphasis.low,
          selected: selected,
        );
        final high = _resolve(
          context,
          chipColor: CoreChipColor.primary,
          emphasis: CoreChipEmphasis.high,
          selected: selected,
        );

        expect(
          low.root.className,
          isNot(high.root.className),
          reason: 'selected=$selected',
        );
      }
    });

    testComponents('disabled ignores emphasis — it has no volume', (
      tester,
    ) async {
      final context = _themedContext(tester);

      for (final selected in [true, false]) {
        final low = _resolve(
          context,
          chipColor: CoreChipColor.primary,
          emphasis: CoreChipEmphasis.low,
          selected: selected,
          enabled: false,
        );
        final high = _resolve(
          context,
          chipColor: CoreChipColor.primary,
          emphasis: CoreChipEmphasis.high,
          selected: selected,
          enabled: false,
        );

        expect(
          low.root.className,
          high.root.className,
          reason: 'selected=$selected',
        );
      }
    });
  });

  group('Chip variant', () {
    const fill = CoreColors.surfaceContainerHigh;

    testComponents('filled paints a grey fill and mirrors it as the border', (
      tester,
    ) async {
      final context = _themedContext(tester);

      for (final color in CoreChipColor.values) {
        for (final emphasis in CoreChipEmphasis.values) {
          final resolved = _resolve(
            context,
            chipColor: color,
            variant: CoreChipVariant.filled,
            emphasis: emphasis,
            selected: false,
            seedColor: const CoreColor(0xFF3366FF),
          );
          final reason = '${color.name} ${emphasis.name}';
          expect(
            resolved.root.className,
            contains('bg-${fill.name}'),
            reason: reason,
          );
          expect(
            resolved.root.className,
            contains('border-${fill.name}'),
            reason: reason,
          );
          expect(
            resolved.root.className,
            isNot(contains('border-${CoreColors.outlineVariant.name}')),
            reason: reason,
          );
        }
      }
    });

    testComponents('filled keeps the label of each volume', (tester) async {
      final context = _themedContext(tester);

      for (final color in [CoreChipColor.neutral, CoreChipColor.primary]) {
        final low = _resolve(
          context,
          chipColor: color,
          variant: CoreChipVariant.filled,
          emphasis: CoreChipEmphasis.low,
          selected: false,
        );
        final high = _resolve(
          context,
          chipColor: color,
          variant: CoreChipVariant.filled,
          emphasis: CoreChipEmphasis.high,
          selected: false,
        );
        expect(
          low.root.className,
          contains('text-${CoreColors.onSurfaceVariant.name}'),
          reason: '${color.name} low',
        );
        expect(
          high.root.className,
          contains('text-${CoreColors.onSurface.name}'),
          reason: '${color.name} high',
        );
      }
    });

    testComponents('outlined is the default and keeps the transparent fill', (
      tester,
    ) async {
      final context = _themedContext(tester);

      expect(Chip().variant, CoreChipVariant.outlined);
      final resolved = _resolve(
        context,
        chipColor: CoreChipColor.neutral,
        emphasis: CoreChipEmphasis.high,
        selected: false,
      );
      expect(
        resolved.root.className,
        isNot(contains('bg-${fill.name}')),
      );
      expect(
        resolved.root.className,
        contains('border-${CoreColors.outlineVariant.name}'),
      );
    });

    testComponents('variant never touches a selected or a disabled chip', (
      tester,
    ) async {
      final context = _themedContext(tester);

      for (final color in [CoreChipColor.neutral, CoreChipColor.primary]) {
        for (final emphasis in CoreChipEmphasis.values) {
          for (final (selected, enabled) in [
            (true, true),
            (true, false),
            (false, false),
          ]) {
            final outlined = _resolve(
              context,
              chipColor: color,
              emphasis: emphasis,
              selected: selected,
              enabled: enabled,
            );
            final filled = _resolve(
              context,
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
              filled.root.className,
              outlined.root.className,
              reason: reason,
            );
          }
        }
      }
    });

    testComponents('a filled pill is a surface; an outlined one is not', (
      tester,
    ) async {
      final context = _themedContext(tester);

      // The grey fill is a real fill, so the pill publishes it the way any
      // filled surface does — the outlined pill states none and stays
      // see-through.
      final filled = _resolve(
        context,
        chipColor: CoreChipColor.neutral,
        variant: CoreChipVariant.filled,
        emphasis: CoreChipEmphasis.high,
        selected: false,
      );
      final outlined = _resolve(
        context,
        chipColor: CoreChipColor.neutral,
        emphasis: CoreChipEmphasis.high,
        selected: false,
      );
      expect(
        filled.root.inlineStyles?.properties.containsKey(kWebSurfaceFillVar),
        isTrue,
      );
      expect(
        outlined.root.inlineStyles?.properties.containsKey(kWebSurfaceFillVar),
        isFalse,
      );
    });
  });

  group('Chip filled + low report', () {
    List<String> collect(void Function() body) {
      final reports = <String>[];
      final previous = debugWarn;
      debugWarn = reports.add;
      try {
        body();
      } finally {
        debugWarn = previous;
      }
      return reports;
    }

    testComponents('a static filled + low badge is silent', (tester) async {
      final reports = collect(() {
        pumpWithTheme(
          tester,
          Chip(
            label: 'x',
            variant: CoreChipVariant.filled,
            emphasis: CoreChipEmphasis.low,
          ),
        );
      });
      expect(reports, isEmpty);
    });

    testComponents('a selectable filled + low chip is reported, in debug', (
      tester,
    ) async {
      final reports = collect(() {
        pumpWithTheme(
          tester,
          Chip(
            label: 'x',
            variant: CoreChipVariant.filled,
            emphasis: CoreChipEmphasis.low,
            selected: true,
          ),
        );
      });
      expect(reports, [CoreChipContract.filledLowEmphasisReport]);
    });

    testComponents('every other pairing is silent', (tester) async {
      for (final (variant, emphasis) in [
        (CoreChipVariant.filled, CoreChipEmphasis.high),
        (CoreChipVariant.outlined, CoreChipEmphasis.low),
        (CoreChipVariant.outlined, CoreChipEmphasis.high),
      ]) {
        final reports = collect(() {
          pumpWithTheme(
            tester,
            Chip(label: 'x', variant: variant, emphasis: emphasis),
          );
        });
        expect(reports, isEmpty, reason: '${variant.name} ${emphasis.name}');
      }
    });
  });
}
