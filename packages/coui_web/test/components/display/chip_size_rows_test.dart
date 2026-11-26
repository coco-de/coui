// The Web half of the chip size rows: the corner (6 · 8 · 10), the inline
// padding (10 · 12 · 14) and the leading / trailing icons (12 · 14 · 16) reach
// the resolved chrome from `CoreChipStyle.defaultsBySize`, and the composed
// `Clickable` is handed the corner the face is drawn with so the focus ring
// follows it. The rendered tree is read back too: the corner reaches the
// stylesheet as a `--coui-radius-*` variable (so a density change moves it),
// and a caller's `Icon` in the leading / trailing slot is drawn at the size
// of the row.
import 'package:coui_web/coui_web.dart';
// chip_style.dart is not re-exported by the barrel past the resolver — the
// face marker the rendered tree is read by comes from it directly.
import 'package:coui_web/src/components/display/chip/chip_style.dart'
    show kChipBodyMarker;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext) onBuild;

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
  BuildContext context,
  CoreChipSize size, {
  CoreChipStyle? chipStyle,
}) => resolveChip(
  context,
  variant: CoreChipVariant.outlined,
  chipColor: CoreChipColor.neutral,
  size: size,
  selected: false,
  emphasis: CoreChipEmphasis.high,
  enabled: true,
  chipStyle: chipStyle,
);

/// The rendered `<svg>` glyphs, in document order.
List<DomComponent> _glyphs() => [
  for (final element in find.tag('svg').evaluate())
    element.component as DomComponent,
];

/// The four-corner `border-radius` a face states when every corner is the
/// `CoreRadius` rung [step] — each corner a variable the density rules write.
String _corners(int step) =>
    List.filled(4, 'var(--coui-radius-$step)').join(' ');

/// The CSS `font-size` a rendered glyph is drawn at — `size / 16` rem.
String _remOf(double size) => '${size / kRemDivisor}rem';

/// The chip face: the element wearing the border, radius and padding.
DomComponent _face() => [
  for (final element in find.tag('div').evaluate())
    if ((element.component as DomComponent).classes?.contains(
          kChipBodyMarker,
        ) ??
        false)
      element.component as DomComponent,
].single;

void main() {
  const pill = CoreBorderRadius.all(CoreRadius.radius9999);

  group('Chip size rows reach the resolved chrome (Web)', () {
    testComponents('the face states the row corner inline, never the pill', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final size in CoreChipSize.values) {
        final row = CoreChipStyle.defaultsBySize[size]!;
        final root = _resolve(context, size).root;
        expect(
          root.inlineStyles?.properties['border-radius'],
          row.borderRadius!.toValue(),
          reason: '${size.name} corner',
        );
        expect(
          root.inlineStyles?.properties['border-radius'],
          isNot(pill.toValue()),
          reason: '${size.name} is not the pill',
        );
      }
    });

    testComponents('the three corners are three different values', (
      tester,
    ) async {
      // The 6 · 8 · 10 ladder reaches the CSS: a resolver that read one row
      // for every size would emit one string three times.
      final context = _themedContext(tester);
      final corners = {
        for (final size in CoreChipSize.values)
          _resolve(
            context,
            size,
          ).root.inlineStyles?.properties['border-radius'],
      };
      expect(corners, hasLength(CoreChipSize.values.length));
    });

    testComponents('the focus ring follows the corner the face is drawn with', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final size in CoreChipSize.values) {
        final row = CoreChipStyle.defaultsBySize[size]!;
        expect(
          _resolve(context, size).clickableStyle.borderRadius,
          row.borderRadius,
          reason: '${size.name} ring',
        );
      }
    });

    testComponents('a corner the caller states moves the ring with the face', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final size in CoreChipSize.values) {
        final resolved = _resolve(
          context,
          size,
          chipStyle: const CoreChipStyle(borderRadius: pill),
        );
        expect(
          resolved.root.inlineStyles?.properties['border-radius'],
          pill.toValue(),
          reason: '${size.name} face',
        );
        expect(
          resolved.clickableStyle.borderRadius,
          pill,
          reason: '${size.name} ring',
        );
      }
    });

    testComponents('a clickableStyle corner still wins over the face corner', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const ring = CoreBorderRadius.all(CoreRadius.radius4);
      final resolved = _resolve(
        context,
        CoreChipSize.md,
        chipStyle: const CoreChipStyle(
          clickableStyle: CoreClickableStyle(borderRadius: ring),
        ),
      );
      expect(resolved.clickableStyle.borderRadius, ring);
      expect(
        resolved.root.inlineStyles?.properties['border-radius'],
        CoreChipStyle.defaultsBySize[CoreChipSize.md]!.borderRadius!.toValue(),
      );
    });

    testComponents('the small chip keeps its close button no rounder than it', (
      tester,
    ) async {
      final context = _themedContext(tester);
      expect(
        _resolve(context, CoreChipSize.sm).closeButtonStyle?.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius6),
      );
      for (final size in [CoreChipSize.md, CoreChipSize.lg]) {
        expect(
          _resolve(context, size).closeButtonStyle?.borderRadius,
          isNull,
          reason: size.name,
        );
      }
    });

    testComponents('padding and the leading / trailing icons are the row', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final size in CoreChipSize.values) {
        final row = CoreChipStyle.defaultsBySize[size]!;
        final resolved = _resolve(context, size);
        expect(
          resolved.root.inlineStyles?.properties['padding'],
          row.padding!.toValue(),
          reason: '${size.name} padding',
        );
        expect(
          resolved.leadingIconStyle.size,
          row.leadingIconStyle!.size,
          reason: '${size.name} leading',
        );
        expect(
          resolved.trailingIconStyle.size,
          row.trailingIconStyle!.size,
          reason: '${size.name} trailing',
        );
      }
    });
  });

  group('Chip corner reaches the stylesheet as a variable (Web)', () {
    const steps = {
      CoreChipSize.sm: 6,
      CoreChipSize.md: 8,
      CoreChipSize.lg: 10,
    };

    testComponents(
      'each size row draws its corner as var(--coui-radius-6|8|10)',
      (tester) async {
        final context = _themedContext(tester);
        for (final MapEntry(key: size, value: step) in steps.entries) {
          expect(
            _resolve(
              context,
              size,
            ).root.inlineStyles?.properties['border-radius'],
            _corners(step),
            reason: '${size.name} resolved',
          );
        }
      },
    );

    for (final MapEntry(key: size, value: step) in steps.entries) {
      testComponents('the rendered ${size.name} face carries '
          'var(--coui-radius-$step), not a literal', (tester) async {
        pumpWithTheme(tester, Chip(label: 'Tag', size: size));

        expect(
          _face().styles?.properties['border-radius'],
          _corners(step),
        );
      });
    }

    testComponents('a density rule re-points each of the three variables', (
      tester,
    ) async {
      // The corner moves with the density only because it goes out as the
      // variable the density rules write — a literal would sit still. Each
      // of the three rungs is written by at least one non-default density,
      // with the value the shared seat draws.
      final blocks = ThemeConfig.defaults().densityVariableBlocks;
      for (final step in steps.values) {
        final moved = [
          for (final density in CoreDensity.values)
            if (density != CoreDensity.defaultDensity &&
                density.radius(step.toDouble()) != step)
              density,
        ];
        expect(moved, isNotEmpty, reason: 'radius $step never moves');
        for (final density in moved) {
          final rule = RegExp(
            '\\[data-coui-density="${density.name}"\\]\\{([^}]*)\\}',
          ).firstMatch(blocks)!.group(1)!;
          expect(
            rule,
            contains(
              '--coui-radius-$step:${density.radius(step.toDouble())}px;',
            ),
            reason: '${density.name} radius $step',
          );
        }
      }
    });
  });

  group('Chip leading / trailing glyphs take the size row (Web render)', () {
    // The rendered `<svg>` is read, not the resolver output: the resolver
    // has always made the slot style, and only an `IconTheme` around the
    // caller's slot carries it to a bare `Icon`.
    const rowSizes = {
      CoreChipSize.sm: CoreIconSize.size12,
      CoreChipSize.md: CoreIconSize.size14,
      CoreChipSize.lg: CoreIconSize.size16,
    };

    testComponents('the rows state 12 · 14 · 16', (tester) async {
      for (final MapEntry(key: size, value: glyph) in rowSizes.entries) {
        final row = CoreChipStyle.defaultsBySize[size]!;
        expect(row.leadingIconStyle!.size, glyph, reason: '${size.name} lead');
        expect(
          row.trailingIconStyle!.size,
          glyph,
          reason: '${size.name} trail',
        );
      }
    });

    for (final MapEntry(key: size, value: glyph) in rowSizes.entries) {
      testComponents('a bare leading Icon is drawn at ${glyph.toInt()} on '
          '${size.name}', (tester) async {
        pumpWithTheme(
          tester,
          Chip(
            label: 'Tag',
            size: size,
            leading: const Icon(LucideIcons.check),
          ),
        );

        final glyphs = _glyphs();
        expect(glyphs, hasLength(1));
        expect(glyphs.single.styles?.properties['font-size'], _remOf(glyph));
      });

      testComponents('a bare trailing Icon is drawn at ${glyph.toInt()} on '
          '${size.name}', (tester) async {
        pumpWithTheme(
          tester,
          Chip(
            label: 'Tag',
            size: size,
            trailing: const Icon(LucideIcons.chevronRight),
          ),
        );

        final glyphs = _glyphs();
        expect(glyphs, hasLength(1));
        expect(glyphs.single.styles?.properties['font-size'], _remOf(glyph));
      });
    }

    testComponents('leading and trailing are both sized, in document order', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Chip(
          label: 'Tag',
          size: CoreChipSize.sm,
          leading: const Icon(LucideIcons.check),
          trailing: const Icon(LucideIcons.chevronRight),
        ),
      );

      final glyphs = _glyphs();
      expect(glyphs, hasLength(2));
      for (final glyph in glyphs) {
        expect(
          glyph.styles?.properties['font-size'],
          _remOf(CoreIconSize.size12),
        );
      }
    });

    testComponents('the row outranks the app-root ambient icon size', (
      tester,
    ) async {
      // `CoUIWeb` mounts an ambient `IconTheme` at the app root; the chip's
      // own is the nearest one and wins over it.
      pumpWithTheme(
        tester,
        IconTheme(
          data: const IconThemeData(size: CoreIconStyle.defaultAmbientSize),
          child: Chip(
            label: 'Tag',
            size: CoreChipSize.sm,
            leading: const Icon(LucideIcons.check),
            trailing: const Icon(LucideIcons.chevronRight),
          ),
        ),
      );

      for (final glyph in _glyphs()) {
        expect(
          glyph.styles?.properties['font-size'],
          _remOf(CoreIconSize.size12),
        );
        expect(
          glyph.styles?.properties['font-size'],
          isNot(_remOf(CoreIconStyle.defaultAmbientSize)),
        );
      }
    });

    testComponents('an Icon that states its own size keeps it', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Chip(
          label: 'Tag',
          leading: const Icon(
            LucideIcons.check,
            iconStyle: CoreIconStyle(size: CoreIconSize.size24),
          ),
        ),
      );

      expect(
        _glyphs().single.styles?.properties['font-size'],
        _remOf(CoreIconSize.size24),
      );
    });

    testComponents('a slot size the caller states on the chip style wins', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Chip(
          label: 'Tag',
          leading: const Icon(LucideIcons.check),
          trailing: const Icon(LucideIcons.chevronRight),
          chipStyle: const CoreChipStyle(
            leadingIconStyle: CoreIconStyle(size: CoreIconSize.size20),
            trailingIconStyle: CoreIconStyle(size: CoreIconSize.size18),
          ),
        ),
      );

      final glyphs = _glyphs();
      expect(glyphs, hasLength(2));
      expect(
        glyphs[0].styles?.properties['font-size'],
        _remOf(CoreIconSize.size20),
      );
      expect(
        glyphs[1].styles?.properties['font-size'],
        _remOf(CoreIconSize.size18),
      );
    });

    testComponents('a slot colour the caller states reaches a bare glyph', (
      tester,
    ) async {
      const red = CoreColor(0xFFFF0000);
      pumpWithTheme(
        tester,
        Chip(
          label: 'Tag',
          leading: const Icon(LucideIcons.check),
          trailing: const Icon(LucideIcons.chevronRight),
          chipStyle: const CoreChipStyle(
            leadingIconStyle: CoreIconStyle(color: red),
            trailingIconStyle: CoreIconStyle(color: red),
          ),
        ),
      );

      final glyphs = _glyphs();
      expect(glyphs, hasLength(2));
      for (final glyph in glyphs) {
        expect(glyph.styles?.properties['color'], red.toValue());
      }
      // The row's own size still rides along with the stated colour.
      expect(
        glyphs.first.styles?.properties['font-size'],
        _remOf(CoreIconSize.size14),
      );
    });

    testComponents('no slot colour leaves the glyph on currentColor', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Chip(label: 'Tag', leading: const Icon(LucideIcons.check)),
      );

      final glyph = _glyphs().single;
      expect(glyph.styles?.properties['color'], isNull);
      expect(glyph.classes ?? '', isNot(contains('text-')));
    });

    testComponents('the glyphs add no wrapper element of their own', (
      tester,
    ) async {
      // `IconTheme` is ambient metadata: the leading slot is still exactly
      // the wrapper `span` holding the caller's glyph.
      pumpWithTheme(
        tester,
        Chip(label: 'Tag', leading: const Icon(LucideIcons.check)),
      );

      final svg = find.tag('svg').evaluate().single;
      DomComponent? wrapper;
      svg.visitAncestorElements((ancestor) {
        final component = ancestor.component;
        if (component is DomComponent) {
          wrapper = component;

          return false;
        }

        return true;
      });
      expect(wrapper?.tag, 'span');
    });

    testComponents('the close icon is its own row, untouched by the slots', (
      tester,
    ) async {
      const closeRows = {
        CoreChipSize.sm: CoreIconSize.size12,
        CoreChipSize.md: CoreIconSize.size14,
        CoreChipSize.lg: CoreIconSize.size16,
      };
      for (final MapEntry(key: size, value: close) in closeRows.entries) {
        pumpWithTheme(
          tester,
          Chip(
            label: 'Tag',
            size: size,
            leading: const Icon(LucideIcons.check),
            onRemove: () {},
          ),
        );

        final glyphs = _glyphs();
        expect(glyphs, hasLength(2), reason: size.name);
        expect(
          glyphs[0].styles?.properties['font-size'],
          _remOf(rowSizes[size]!),
          reason: '${size.name} leading',
        );
        expect(
          glyphs[1].styles?.properties['font-size'],
          _remOf(close),
          reason: '${size.name} close',
        );
      }
    });
  });

  group('A ChipInput badge keeps the glyph size it states (Web render)', () {
    testComponents('the badge close icon is drawn at the ChipInput 12', (
      tester,
    ) async {
      // The badge is a composed `Chip` with no leading / trailing slot: the
      // slot icon themes have nothing to wrap, and the close icon states its
      // own size, so the compact badge draws the size it states.
      pumpWithTheme(
        tester,
        ChipInput(chips: const ['a', 'b'], onChanged: (_) {}),
      );

      final glyphs = _glyphs();
      expect(glyphs, hasLength(2));
      for (final glyph in glyphs) {
        expect(
          glyph.styles?.properties['font-size'],
          _remOf(
            CoreChipInputStyle.defaultChipStyle.closeIconStyle!.size!,
          ),
        );
      }
      expect(
        CoreChipInputStyle.defaultChipStyle.closeIconStyle!.size,
        CoreIconSize.size12,
      );
    });

    testComponents('the badge takes the sm row corner and 28 floor', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        ChipInput(chips: const ['a'], onChanged: (_) {}),
      );

      final face = _face();
      // No corner or floor of its own: the badge is the Chip's `sm` row.
      expect(face.styles?.properties['border-radius'], _corners(6));
      expect(
        face.styles?.properties['min-height'],
        '${CoreSize.size28 / kRemDivisor}rem',
      );
    });
  });

  group('Chip content alignment (Web resolve, #6068)', () {
    testComponents('the content row is centred when the chip is wider', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final size in CoreChipSize.values) {
        final classes = _resolve(context, size).root.className.split(' ');
        expect(classes, contains('justify-center'), reason: size.name);
      }
      final start = _resolve(
        context,
        CoreChipSize.md,
        chipStyle: const CoreChipStyle(contentAlignment: .start),
      ).root.className.split(' ');
      expect(start, contains('justify-start'));
      expect(start, isNot(contains('justify-center')));
    });
  });
}
