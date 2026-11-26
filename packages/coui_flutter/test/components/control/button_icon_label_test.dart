import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the icon ladders and the label weight put on screen, read back from
/// the resolver's output rather than from the rows they were written in.
///
/// A row can state a value and still never reach a glyph or a label — the
/// resolver has to read it through `iconSizeFor` / `labelStyleFor` and the
/// widget has to hand it on — so every claim here is a resolved number.
class _Capture extends StatelessWidget {
  const _Capture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild(context);

    return const SizedBox.shrink();
  }
}

const Set<WidgetState> _kRest = {};

void main() {
  late BuildContext context;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(CoreThemePresets.light),
        home: _Capture((c) => context = c),
      ),
    );
  }

  ResolvedButton resolved(
    CoreButtonVariant variant, {
    CoreComponentSize size = .md,
    CoreButtonShape shape = .rectangle,
    CoreButtonStyle? buttonStyle,
  }) => resolveButton(
    context,
    variant: variant,
    size: size,
    shape: shape,
    buttonStyle: buttonStyle,
  );

  double leadingSize(ResolvedButton r) =>
      r.leadingIconTheme.resolve(_kRest).size!;

  double trailingSize(ResolvedButton r) =>
      r.trailingIconTheme.resolve(_kRest).size!;

  group('the glyph beside a label', () {
    for (final size in CoreComponentSize.values) {
      testWidgets('${size.name} reads the size row', (tester) async {
        await pump(tester);
        final r = resolved(.primary, size: size);
        final row = CoreButtonStyle.defaultsBySize[size]!;

        expect(leadingSize(r), row.leadingIconStyle!.size);
        expect(trailingSize(r), row.trailingIconStyle!.size);
      });
    }

    testWidgets('is 12 · 14 · 16 · 18 · 20 · 24 from xs to xl2', (
      tester,
    ) async {
      await pump(tester);

      expect(
        [
          for (final size in CoreComponentSize.values)
            leadingSize(resolved(.primary, size: size)),
        ],
        [12, 14, 16, 18, 20, 24],
      );
    });
  });

  group('the glyph of a square or circle button', () {
    for (final shape in [CoreButtonShape.square, CoreButtonShape.circle]) {
      for (final size in CoreComponentSize.values) {
        testWidgets('${shape.name} ${size.name} reads the shape row', (
          tester,
        ) async {
          await pump(tester);
          final r = resolved(.ghost, size: size, shape: shape);
          final row = CoreButtonStyle.defaultsBySize[size]!;

          expect(leadingSize(r), row.iconShapeIconStyle!.size);
          expect(trailingSize(r), row.iconShapeIconStyle!.size);
          expect(leadingSize(r), isNot(row.leadingIconStyle!.size));
        });
      }
    }

    testWidgets('is 14 · 16 · 18 · 20 · 24 · 28 from xs to xl2', (
      tester,
    ) async {
      await pump(tester);

      expect(
        [
          for (final size in CoreComponentSize.values)
            leadingSize(resolved(.ghost, size: size, shape: .square)),
        ],
        [14, 16, 18, 20, 24, 28],
      );
    });

    testWidgets('a glyph sized through the slot style keeps winning over '
        'the row', (tester) async {
      await pump(tester);
      final r = resolved(
        .ghost,
        size: .sm,
        shape: .square,
        buttonStyle: const CoreButtonStyle(
          leadingIconStyle: CoreIconStyle(size: 22),
        ),
      );

      expect(leadingSize(r), 22);
      // The other slot follows the one the caller sized, the way it always
      // seeded both from one size.
      expect(trailingSize(r), 22);
    });

    testWidgets('a shape statement on the instance outranks the slot '
        'statement and the row', (tester) async {
      await pump(tester);
      final r = resolved(
        .ghost,
        size: .sm,
        shape: .circle,
        buttonStyle: const CoreButtonStyle(
          leadingIconStyle: CoreIconStyle(size: 22),
          iconShapeIconStyle: CoreIconStyle(size: 26),
        ),
      );

      expect(leadingSize(r), 26);
      expect(trailingSize(r), 26);
    });

    testWidgets('a shape statement pins the glyph colour of a shaped '
        'button on both slots, across states', (tester) async {
      await pump(tester);
      final pinned = Theme.of(
        context,
      ).colorScheme.resolve(const CoreColor.token(CoreColors.error)).toValue();
      final r = resolved(
        .ghost,
        size: .sm,
        shape: .square,
        buttonStyle: const CoreButtonStyle(
          iconShapeIconStyle: CoreIconStyle(
            color: CoreColor.token(CoreColors.error),
          ),
        ),
      );

      for (final states in [
        _kRest,
        {WidgetState.hovered},
        {WidgetState.pressed},
      ]) {
        expect(r.leadingIconTheme.resolve(states).color, pinned);
        expect(r.trailingIconTheme.resolve(states).color, pinned);
      }
    });

    testWidgets('a shape statement is not read by a button with a label', (
      tester,
    ) async {
      await pump(tester);
      final r = resolved(
        .primary,
        size: .sm,
        buttonStyle: const CoreButtonStyle(
          iconShapeIconStyle: CoreIconStyle(size: 26),
        ),
      );

      expect(
        leadingSize(r),
        CoreButtonStyle
            .defaultsBySize[CoreComponentSize.sm]!
            .leadingIconStyle!
            .size,
      );
    });
  });

  group('a Carousel arrow', () {
    testWidgets('draws its chevron at the circle button glyph size, the size '
        'the Web twin reads off the same row', (tester) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: SizedBox(
            width: 400,
            height: 300,
            child: Carousel(
              transition: const CarouselTransition.sliding(),
              itemCount: 3,
              itemBuilder: (context, index) =>
                  SizedBox(width: 200, child: Text('Item $index')),
            ),
          ),
        ),
      );
      await tester.pump();

      final row = CoreButtonStyle.defaultsBySize[CoreComponentSize.sm]!;
      final chevrons = find.byType(Icon);

      expect(chevrons, findsNWidgets(2));
      for (final chevron in chevrons.evaluate()) {
        final size = IconTheme.of(chevron).size;
        expect(size, row.iconShapeIconStyle!.size);
        expect(size, isNot(row.leadingIconStyle!.size));
      }
    });
  });

  group('the gap between the glyph and the label', () {
    testWidgets('is 4 · 6 · 6 · 6 · 8 · 8 from xs to xl2', (tester) async {
      await pump(tester);

      expect(
        [
          for (final size in CoreComponentSize.values)
            resolved(.primary, size: size).iconLabelGapStyle.size,
        ],
        [4, 6, 6, 6, 8, 8],
      );
    });
  });

  group('the label weight', () {
    for (final variant in CoreButtonVariant.values) {
      testWidgets("${variant.name} draws the role's medium", (tester) async {
        await pump(tester);

        for (final size in CoreComponentSize.values) {
          expect(
            resolved(
              variant,
              size: size,
            ).textStyle.resolve(_kRest).fontWeight,
            FontWeight.w500,
            reason: size.name,
          );
        }
      });
    }

    testWidgets("a composer that states a role gets that role's weight, not "
        "the variant's", (tester) async {
      await pump(tester);
      final r = resolved(
        .ghost,
        size: .sm,
        buttonStyle: const CoreButtonStyle(
          labelStyle: CoreTextStyle.token(CoreTextStyles.bodySmall),
        ),
      );

      expect(r.textStyle.resolve(_kRest).fontWeight, FontWeight.w400);
    });

    testWidgets('a composer that states only a colour leaves the weight to '
        'the role', (tester) async {
      await pump(tester);
      final r = resolved(
        .primary,
        buttonStyle: const CoreButtonStyle(
          labelStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.error),
          ),
        ),
      );

      expect(r.textStyle.resolve(_kRest).fontWeight, FontWeight.w500);
    });

    testWidgets('a composer that states a weight keeps it', (tester) async {
      await pump(tester);
      final r = resolved(
        .primary,
        buttonStyle: const CoreButtonStyle(
          labelStyle: CoreTextStyle(fontWeight: CoreFontWeight.regular),
        ),
      );

      expect(r.textStyle.resolve(_kRest).fontWeight, FontWeight.w400);
    });

    testWidgets('reaches the label a Button actually draws', (tester) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: Button(
            onPressed: () {},
            child: const Text('Go'),
          ),
        ),
      );

      final style = DefaultTextStyle.of(tester.element(find.text('Go')));
      expect(style.style.fontWeight, FontWeight.w500);
    });
  });
}
