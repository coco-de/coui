import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// What the icon ladders and the label weight put on the page, read back
/// from the resolver's output and the rendered DOM rather than from the rows
/// they were written in.
///
/// The Flutter twin has the same file; the claims are the same ones.
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

ResolvedButton _resolve(
  BuildContext context,
  CoreButtonVariant variant, {
  CoreComponentSize size = CoreComponentSize.md,
  CoreButtonShape shape = CoreButtonShape.rectangle,
  CoreButtonStyle? style,
}) => resolveButton(
  context,
  variant: variant,
  size: size,
  shape: shape,
  expanded: false,
  buttonStyle: style,
);

Map<String, String> _inline(ResolvedButton resolved) =>
    resolved.root.inlineStyles?.properties ?? const {};

void main() {
  group('the glyph beside a label', () {
    testComponents('is 12 · 14 · 16 · 18 · 20 · 24 from xs to xl2', (
      tester,
    ) async {
      final context = _themedContext(tester);

      expect(
        [
          for (final size in CoreComponentSize.values)
            _resolve(
              context,
              CoreButtonVariant.primary,
              size: size,
            ).leadingIconStyle.size,
        ],
        [12, 14, 16, 18, 20, 24],
      );
    });

    testComponents('both slots read the size row', (tester) async {
      final context = _themedContext(tester);

      for (final size in CoreComponentSize.values) {
        final resolved = _resolve(
          context,
          CoreButtonVariant.primary,
          size: size,
        );
        final row = CoreButtonStyle.defaultsBySize[size]!;

        expect(resolved.leadingIconStyle.size, row.leadingIconStyle!.size);
        expect(resolved.trailingIconStyle.size, row.trailingIconStyle!.size);
      }
    });
  });

  group('the glyph of a square or circle button', () {
    testComponents('is 14 · 16 · 18 · 20 · 24 · 28 from xs to xl2', (
      tester,
    ) async {
      final context = _themedContext(tester);

      for (final shape in [CoreButtonShape.square, CoreButtonShape.circle]) {
        expect(
          [
            for (final size in CoreComponentSize.values)
              _resolve(
                context,
                CoreButtonVariant.ghost,
                size: size,
                shape: shape,
              ).leadingIconStyle.size,
          ],
          [14, 16, 18, 20, 24, 28],
          reason: shape.name,
        );
      }
    });

    testComponents('both slots read the shape row, a step above the label '
        'glyph', (tester) async {
      final context = _themedContext(tester);

      for (final size in CoreComponentSize.values) {
        final resolved = _resolve(
          context,
          CoreButtonVariant.ghost,
          size: size,
          shape: CoreButtonShape.square,
        );
        final row = CoreButtonStyle.defaultsBySize[size]!;

        expect(resolved.leadingIconStyle.size, row.iconShapeIconStyle!.size);
        expect(resolved.trailingIconStyle.size, row.iconShapeIconStyle!.size);
        expect(
          resolved.leadingIconStyle.size,
          isNot(row.leadingIconStyle!.size),
          reason: size.name,
        );
      }
    });

    testComponents('a glyph sized through the slot style keeps winning over '
        'the row', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        CoreButtonVariant.ghost,
        size: CoreComponentSize.sm,
        shape: CoreButtonShape.square,
        style: const CoreButtonStyle(
          leadingIconStyle: CoreIconStyle(size: 22),
        ),
      );

      expect(resolved.leadingIconStyle.size, 22);
      // The other slot follows the one the caller sized, the way it always
      // seeded both from one size.
      expect(resolved.trailingIconStyle.size, 22);
    });

    testComponents('a shape statement on the instance outranks the slot '
        'statement and the row', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        CoreButtonVariant.ghost,
        size: CoreComponentSize.sm,
        shape: CoreButtonShape.circle,
        style: const CoreButtonStyle(
          leadingIconStyle: CoreIconStyle(size: 22),
          iconShapeIconStyle: CoreIconStyle(size: 26),
        ),
      );

      expect(resolved.leadingIconStyle.size, 26);
      expect(resolved.trailingIconStyle.size, 26);
    });

    testComponents('a shape statement colours the glyph of both slots of a '
        'shaped button', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        CoreButtonVariant.ghost,
        size: CoreComponentSize.sm,
        shape: CoreButtonShape.square,
        style: const CoreButtonStyle(
          iconShapeIconStyle: CoreIconStyle(
            color: CoreColor.token(CoreColors.error),
          ),
        ),
      );

      const error = CoreColor.token(CoreColors.error);
      expect(resolved.leadingIconStyle.color, error);
      expect(resolved.trailingIconStyle.color, error);
      // Colour only — the size stays the shape row's.
      expect(
        resolved.leadingIconStyle.size,
        CoreButtonStyle
            .defaultsBySize[CoreComponentSize.sm]!
            .iconShapeIconStyle!
            .size,
      );
    });

    testComponents('a shape statement is not read by a button with a label', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        CoreButtonVariant.primary,
        size: CoreComponentSize.sm,
        style: const CoreButtonStyle(
          iconShapeIconStyle: CoreIconStyle(size: 26),
        ),
      );

      expect(
        resolved.leadingIconStyle.size,
        CoreButtonStyle
            .defaultsBySize[CoreComponentSize.sm]!
            .leadingIconStyle!
            .size,
      );
    });
  });

  group('a Carousel nav button', () {
    testComponents("draws its chevron at the circle button's glyph size, as "
        'the Flutter twin takes it from the ambient icon theme', (
      tester,
    ) async {
      // The Carousel's two arrows are `Button(shape: circle, size: sm)`. The
      // chevron's size is read off the same row the button's own glyph is,
      // so the platform that reads the row directly and the one that reads
      // the button's ambient theme cannot draw different chevrons.
      final resolved = _resolve(
        _themedContext(tester),
        CoreButtonVariant.ghost,
        size: CoreComponentSize.sm,
        shape: CoreButtonShape.circle,
      );
      final row = CoreButtonStyle.defaultsBySize[CoreComponentSize.sm]!;

      expect(resolved.leadingIconStyle.size, row.iconShapeIconStyle!.size);

      pumpWithTheme(
        tester,
        const Carousel(items: [Text('a'), Text('b')], showIndicators: false),
      );
      await tester.pump();

      // Both arrows are drawn, and both at the shape row's size — not the
      // size of the row's glyph beside a label.
      final chevrons = find
          .byType(Icon)
          .evaluate()
          .map((e) => e.component)
          .whereType<Icon>()
          .toList();

      expect(chevrons, hasLength(2));
      for (final chevron in chevrons) {
        expect(chevron.iconStyle?.size, row.iconShapeIconStyle!.size);
        expect(chevron.iconStyle?.size, isNot(row.leadingIconStyle!.size));
      }
    });
  });

  group('the label weight', () {
    // Every label is its size row's role, whose class already carries the
    // role's medium — so no variant writes a weight inline.
    for (final variant in CoreButtonVariant.values) {
      testComponents('${variant.name} states no weight', (tester) async {
        final context = _themedContext(tester);

        for (final size in CoreComponentSize.values) {
          expect(
            _inline(_resolve(context, variant, size: size)),
            isNot(contains('font-weight')),
            reason: size.name,
          );
        }
      });
    }

    testComponents('the role stays on its class and nothing typographic is '
        'inline', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        CoreButtonVariant.primary,
        size: CoreComponentSize.sm,
      );
      final role = CoreButtonStyle
          .defaultsBySize[CoreComponentSize.sm]!
          .labelStyle!
          .token!;

      expect(resolved.root.className.split(' '), contains('text-${role.name}'));
      expect(_inline(resolved), isNot(contains('font-weight')));
      expect(_inline(resolved), isNot(contains('font-size')));
    });

    testComponents("a composer that states a role takes that role's weight, "
        "not the variant's", (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        CoreButtonVariant.ghost,
        size: CoreComponentSize.sm,
        style: const CoreButtonStyle(
          labelStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
        ),
      );

      expect(
        resolved.root.className.split(' '),
        contains('text-${CoreTextStyles.bodySmall.name}'),
      );
      expect(_inline(resolved), isNot(contains('font-weight')));
    });

    testComponents('a composer that states only a colour leaves the weight '
        'to the role', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        CoreButtonVariant.primary,
        style: const CoreButtonStyle(
          labelStyle: CoreTextStyle(color: CoreColor.token(CoreColors.error)),
        ),
      );

      expect(_inline(resolved), isNot(contains('font-weight')));
    });

    testComponents('a composer that states a weight keeps it', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        CoreButtonVariant.primary,
        style: const CoreButtonStyle(
          labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.regular),
        ),
      );

      expect(_inline(resolved)['font-weight'], '400');
    });

    testComponents('a Button on the page writes no weight on its root', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Button(onPressed: () {}, child: const Text('Go')),
      );

      final root =
          find.tag('button').evaluate().first.component as DomComponent;
      expect(
        root.styles?.properties ?? const <String, String>{},
        isNot(contains('font-weight')),
      );
    });

    // `Calendar` draws every day cell and the header as a `Button` whose
    // label is a `body` role. Flutter re-wraps the label in its own text
    // style; on the page the label inherits from the button root, so no
    // weight may sit on that root or the day numbers come out heavier on
    // Web alone.
    testComponents('a Calendar day cell does not wear the variant weight', (
      tester,
    ) async {
      pumpWithTheme(tester, const Calendar());

      // Every month has a 15th, and the only element holding that text is
      // the day cell's label.
      final cell = find
          .ancestor(of: find.text('15'), matching: find.tag('button'))
          .evaluate()
          .map((e) => e.component)
          .whereType<DomComponent>()
          .toList();

      expect(cell, isNotEmpty);
      for (final button in cell) {
        expect(
          button.styles?.properties ?? const <String, String>{},
          isNot(contains('font-weight')),
        );
      }
    });
  });
}
