import 'dart:ui' show Tristate;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// The command palette trigger. What is pinned here is what a reader cannot
/// see from the resolver alone: the rendered height and inset per rung,
/// which face and ink the widget selects, the wash it lays over the face,
/// the role it announces and what activation does.
///
/// The size ladder is asserted in rendered pixels rather than against
/// `CoreCommandSearchStyle.defaultsBySize` — restating the table would pass
/// whatever the table said, including a value the trigger never draws.
void main() {
  /// The trigger fills the width it is given (its hint seat is an
  /// `Expanded`), and the centred harness hands loose constraints.
  Future<void> pumpTrigger(
    WidgetTester tester,
    Widget child, {
    CoreDensity density = .defaultDensity,
    TextDirection textDirection = .ltr,
  }) => pumpTestApp(
    tester,
    SizedBox(width: CoreLayout.layout320, child: child),
    theme: ThemeData.fromCore(CoreThemePresets.light),
    density: density,
    textDirection: textDirection,
  );

  /// The trigger's own box — the `AnimatedContainer` that states a height.
  /// `Clickable` may wrap another for its press chrome, so the constraint is
  /// what tells the two apart.
  AnimatedContainer faceBox(WidgetTester tester) => tester
      .widgetList<AnimatedContainer>(
        find.descendant(
          of: find.byType(CommandSearch),
          matching: find.byType(AnimatedContainer),
        ),
      )
      .firstWhere((container) => container.constraints != null);

  BoxDecoration face(WidgetTester tester) =>
      faceBox(tester).decoration! as BoxDecoration;

  Color tokenColor(WidgetTester tester, CoreColorToken token) => Theme.of(
    tester.element(find.byType(CommandSearch)),
  ).colorScheme.resolve(CoreColor.token(token)).toValue();

  TextStyle hintStyle(WidgetTester tester, String hint) =>
      tester.widget<Text>(find.text(hint)).style!;

  Color glyphColor(WidgetTester tester) => IconTheme.of(
    tester.element(
      find.descendant(
        of: find.byType(CommandSearch),
        matching: find.byType(Icon),
      ),
    ),
  ).color!;

  /// How many `Position` layers the trigger draws — the wash is one of them.
  int layers(WidgetTester tester) => find
      .descendant(
        of: find.byType(CommandSearch),
        matching: find.byType(Position),
      )
      .evaluate()
      .length;

  group('CommandSearch renders its seats', () {
    testWidgets('the locale placeholder is the hint by default', (
      tester,
    ) async {
      await pumpTrigger(tester, CommandSearch(onPressed: () {}));

      expect(
        find.text(DefaultCoUILocalizations.instance.commandSearch),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(CommandSearch),
          matching: find.byType(Icon),
        ),
        findsOneWidget,
        reason: 'the search glyph stands in for an absent leading',
      );
    });

    testWidgets('a stated hint, leading and shortcut take their seats', (
      tester,
    ) async {
      await pumpTrigger(
        tester,
        CommandSearch(
          hint: 'Search docs',
          leading: const Icon(LucideIcons.bookOpen),
          shortcut: const Kbd(keys: ['⌘K']),
          onPressed: () {},
        ),
      );

      expect(find.text('Search docs'), findsOneWidget);
      expect(find.byType(Kbd), findsOneWidget);
      // The shortcut sits at the end: after the hint, against the end inset.
      expect(
        tester.getTopLeft(find.byType(Kbd)).dx,
        greaterThan(tester.getTopRight(find.text('Search docs')).dx),
      );
    });

    testWidgets('fills the width its parent gives — no width of its own', (
      tester,
    ) async {
      await pumpTrigger(tester, CommandSearch(onPressed: () {}));

      expect(
        tester.getSize(find.byType(CommandSearch)).width,
        CoreLayout.layout320,
      );
    });
  });

  group('CommandSearch size ladder', () {
    const heights = {
      CoreCommandSize.sm: 32.0,
      CoreCommandSize.md: 40.0,
      CoreCommandSize.lg: 48.0,
    };
    for (final MapEntry(key: size, value: height) in heights.entries) {
      testWidgets('${size.name} is $height tall, corner ${height / 4}', (
        tester,
      ) async {
        await pumpTrigger(
          tester,
          CommandSearch(size: size, onPressed: () {}),
        );

        expect(tester.getSize(find.byType(CommandSearch)).height, height);
        expect(face(tester).borderRadius, BorderRadius.circular(height / 4));
      });
    }

    testWidgets('the default rung is md', (tester) async {
      await pumpTrigger(tester, CommandSearch(onPressed: () {}));

      expect(tester.getSize(find.byType(CommandSearch)).height, 40);
    });

    testWidgets('a density moves the height one ladder rung', (tester) async {
      await pumpTrigger(
        tester,
        CommandSearch(onPressed: () {}),
        density: .compact,
      );

      expect(tester.getSize(find.byType(CommandSearch)).height, 32);
    });

    testWidgets('the start inset follows the reading direction', (
      tester,
    ) async {
      Future<double> glyphInset(TextDirection direction) async {
        await pumpTrigger(
          tester,
          CommandSearch(onPressed: () {}),
          textDirection: direction,
        );
        final box = tester.getRect(find.byType(CommandSearch));
        final glyph = tester.getRect(
          find.descendant(
            of: find.byType(CommandSearch),
            matching: find.byType(Icon),
          ),
        );
        return direction == .ltr
            ? glyph.left - box.left
            : box.right - glyph.right;
      }

      // md: start 12 — the glyph keeps the larger inset in both directions.
      expect(await glyphInset(.ltr), 12);
      expect(await glyphInset(.rtl), 12);
    });
  });

  group('CommandSearch content sits at the trigger centre', () {
    /// A seat's gap to the trigger's top edge and to its bottom edge,
    /// measured on the painted widget. The trigger's height is a ladder rung,
    /// not its content's height, so the leftover has to split above and
    /// below — reading the resolver back would pass whatever the seat did
    /// with it.
    ({double top, double bottom}) gaps(WidgetTester tester, Finder seat) {
      final box = tester.getRect(find.byType(CommandSearch));
      final rect = tester.getRect(seat);
      return (top: rect.top - box.top, bottom: box.bottom - rect.bottom);
    }

    Finder glyph() => find.descendant(
      of: find.byType(CommandSearch),
      matching: find.byType(Icon),
    );

    Finder hint() => find.text(DefaultCoUILocalizations.instance.commandSearch);

    void expectCentred(WidgetTester tester, Finder seat, String what) {
      final gap = gaps(tester, seat);
      final height = tester.getSize(find.byType(CommandSearch)).height;
      expect(
        gap.top,
        closeTo(gap.bottom, 0.01),
        reason:
            'the $what sat ${gap.top} below the top and ${gap.bottom} above '
            'the bottom of a $height trigger — the Stack default top seat '
            'leaves the leftover height underneath',
      );
    }

    // Every rung of both ladders. The row is only as tall as its text line,
    // and the inset is horizontal only, so nothing but the seat's own
    // alignment puts the content mid-box at any rung or density.
    for (final density in CoreDensity.values) {
      for (final size in CoreCommandSize.values) {
        testWidgets('${size.name} trigger at ${density.name} density', (
          tester,
        ) async {
          await pumpTrigger(
            tester,
            CommandSearch(size: size, onPressed: () {}),
            density: density,
          );

          expectCentred(tester, hint(), 'hint');
          expectCentred(tester, glyph(), 'glyph');
        });
      }
    }

    testWidgets('the shortcut key is centred with them', (tester) async {
      await pumpTrigger(
        tester,
        CommandSearch(
          shortcut: const Kbd(keys: ['⌘K']),
          onPressed: () {},
        ),
      );

      expectCentred(tester, find.byType(Kbd), 'shortcut key');
      expectCentred(tester, hint(), 'hint');
    });

    testWidgets("a caller's own height is split above and below", (
      tester,
    ) async {
      await pumpTrigger(
        tester,
        CommandSearch(
          commandSearchStyle: const CoreCommandSearchStyle(height: 64),
          onPressed: () {},
        ),
      );

      expect(tester.getSize(find.byType(CommandSearch)).height, 64);
      expectCentred(tester, hint(), 'hint');
      expect(
        gaps(tester, hint()).top,
        greaterThan(20),
        reason: 'a 64 trigger around a ~21 line leaves more than 20 per side',
      );
    });

    testWidgets('a right-to-left reading direction keeps the same centre', (
      tester,
    ) async {
      await pumpTrigger(
        tester,
        CommandSearch(onPressed: () {}),
        textDirection: .rtl,
      );

      expectCentred(tester, hint(), 'hint');
      expectCentred(tester, glyph(), 'glyph');
    });
  });

  group('CommandSearch face and ink', () {
    testWidgets('rests on surfaceContainer in onSurfaceVariant', (
      tester,
    ) async {
      await pumpTrigger(tester, CommandSearch(onPressed: () {}));
      final hint = DefaultCoUILocalizations.instance.commandSearch;

      expect(
        face(tester).color,
        tokenColor(tester, CoreColors.surfaceContainer),
      );
      expect(face(tester).border, isNull, reason: 'a button, not an input');
      final ink = tokenColor(tester, CoreColors.onSurfaceVariant);
      expect(hintStyle(tester, hint).color, ink);
      expect(glyphColor(tester), ink);
    });

    testWidgets('the hint reads the size row role', (tester) async {
      await pumpTrigger(
        tester,
        CommandSearch(size: .lg, hint: 'Search', onPressed: () {}),
      );
      final theme = Theme.of(tester.element(find.byType(CommandSearch)));
      final bodyLarge = theme.typography.resolve(
        const CoreTextStyle.token(CoreTextStyles.bodyLarge),
      );

      expect(hintStyle(tester, 'Search').fontSize, bodyLarge.fontSize);
    });

    testWidgets('disabled drops face and ink to the disabled pair', (
      tester,
    ) async {
      await pumpTrigger(tester, const CommandSearch(hint: 'Search'));

      expect(
        face(tester).color,
        tokenColor(tester, CoreColors.disabledContainer),
      );
      final ink = tokenColor(tester, CoreColors.disabledContent);
      expect(hintStyle(tester, 'Search').color, ink);
      expect(glyphColor(tester), ink);
    });

    testWidgets('an instance style overrides the face', (tester) async {
      await pumpTrigger(
        tester,
        CommandSearch(
          onPressed: () {},
        ).withStyle(
          const CoreCommandSearchStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
          ),
        ),
      );

      expect(
        face(tester).color,
        tokenColor(tester, CoreColors.surfaceContainerHigh),
      );
    });

    testWidgets('a project theme reaches every trigger', (tester) async {
      await pumpTestApp(
        tester,
        SizedBox(
          width: CoreLayout.layout320,
          child: CommandSearch(onPressed: () {}),
        ),
        theme: ThemeData.fromCore(CoreThemePresets.light),
        componentTheme: const CoreComponentTheme(
          commandSearch: CoreCommandSearchTheme(
            style: CoreCommandSearchStyle(height: CoreControlSize.heightLg),
          ),
        ),
      );

      expect(tester.getSize(find.byType(CommandSearch)).height, 48);
    });
  });

  group('CommandSearch focus ring corner', () {
    /// The outline the composed `Clickable` draws around the trigger.
    CoreBorderRadius? ringCorner(WidgetTester tester) => tester
        .widget<FocusOutline>(
          find.descendant(
            of: find.byType(CommandSearch),
            matching: find.byType(FocusOutline),
          ),
        )
        .focusOutlineStyle
        ?.borderRadius;

    const rungs = {
      CoreCommandSize.sm: 32.0,
      CoreCommandSize.md: 40.0,
      CoreCommandSize.lg: 48.0,
    };
    for (final MapEntry(key: size, value: height) in rungs.entries) {
      testWidgets('${size.name}: the ring takes the trigger corner '
          '${height / 4}', (tester) async {
        await pumpTrigger(tester, CommandSearch(size: size, onPressed: () {}));

        expect(ringCorner(tester), CoreBorderRadius.all(height / 4));
        expect(face(tester).borderRadius, BorderRadius.circular(height / 4));
      });
    }

    testWidgets('a corner stated for the trigger carries the ring with it', (
      tester,
    ) async {
      await pumpTrigger(
        tester,
        CommandSearch(onPressed: () {}).withStyle(
          const CoreCommandSearchStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
          ),
        ),
      );

      expect(ringCorner(tester), const CoreBorderRadius.all(20));
      expect(face(tester).borderRadius, BorderRadius.circular(20));
    });

    testWidgets('a corner stated for the ring wins and the box keeps its own', (
      tester,
    ) async {
      await pumpTrigger(
        tester,
        CommandSearch(onPressed: () {}).withStyle(
          const CoreCommandSearchStyle(
            clickableStyle: CoreClickableStyle(
              borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
            ),
          ),
        ),
      );

      expect(ringCorner(tester), const CoreBorderRadius.all(20));
      expect(face(tester).borderRadius, BorderRadius.circular(10));
    });
  });

  group('CommandSearch state layer', () {
    Future<TestGesture> connectMouse(WidgetTester tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      return gesture;
    }

    /// Every fill drawn on a `Position` layer inside the trigger — the wash
    /// is one of them (`Clickable` may draw its focus ring on another).
    List<Color?> layerFills(WidgetTester tester) => [
      for (final box in tester.widgetList<DecoratedBox>(
        find.descendant(
          of: find.descendant(
            of: find.byType(CommandSearch),
            matching: find.byType(Position),
          ),
          matching: find.byType(DecoratedBox),
        ),
      ))
        if (box.decoration case final BoxDecoration decoration)
          decoration.color,
    ];

    testWidgets('hover lays onSurface at 8% over the face', (tester) async {
      final gesture = await connectMouse(tester);
      await pumpTrigger(
        tester,
        CommandSearch(hint: 'Search', onPressed: () {}),
      );
      final resting = layers(tester);
      await gesture.moveTo(tester.getCenter(find.text('Search')));
      await tester.pumpAndSettle();

      expect(layers(tester), resting + 1, reason: 'the wash appears');
      final onSurface = tokenColor(tester, CoreColors.onSurface);
      expect(layerFills(tester), contains(onSurface.withValues(alpha: 0.08)));
      expect(
        face(tester).color,
        tokenColor(tester, CoreColors.surfaceContainer),
        reason: 'the face stays under the wash',
      );
    });

    testWidgets('pressed lays it at 12%', (tester) async {
      final gesture = await connectMouse(tester);
      await pumpTrigger(
        tester,
        CommandSearch(hint: 'Search', onPressed: () {}),
      );
      await gesture.moveTo(tester.getCenter(find.text('Search')));
      await tester.pump();
      await gesture.down(tester.getCenter(find.text('Search')));
      await tester.pumpAndSettle();

      final onSurface = tokenColor(tester, CoreColors.onSurface);
      expect(layerFills(tester), contains(onSurface.withValues(alpha: 0.12)));
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('keyboard focus lays it at 8%', (tester) async {
      await pumpTrigger(
        tester,
        CommandSearch(hint: 'Search', onPressed: () {}),
      );
      final node = tester
          .widgetList<Focus>(
            find.descendant(
              of: find.byType(CommandSearch),
              matching: find.byType(Focus),
            ),
          )
          .firstWhere((focus) => focus.focusNode != null)
          .focusNode!;
      // `requestFocus` alone does not flip the highlight mode; a key event
      // does.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
      node.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);

      final onSurface = tokenColor(tester, CoreColors.onSurface);
      expect(layerFills(tester), contains(onSurface.withValues(alpha: 0.08)));
    });

    testWidgets('a disabled trigger takes no wash', (tester) async {
      final gesture = await connectMouse(tester);
      await pumpTrigger(tester, const CommandSearch(hint: 'Search'));
      final resting = layers(tester);
      await gesture.moveTo(tester.getCenter(find.text('Search')));
      await tester.pumpAndSettle();

      expect(layers(tester), resting);
    });
  });

  group('CommandSearch behaviour', () {
    testWidgets('a tap calls onPressed', (tester) async {
      var presses = 0;
      await pumpTrigger(
        tester,
        CommandSearch(hint: 'Search', onPressed: () => presses++),
      );
      await tester.tap(find.byType(CommandSearch));
      await tester.pump();

      expect(presses, 1);
    });

    testWidgets('enabled: false withholds activation', (tester) async {
      var presses = 0;
      await pumpTrigger(
        tester,
        CommandSearch(
          hint: 'Search',
          enabled: false,
          onPressed: () => presses++,
        ),
      );
      await tester.tap(find.byType(CommandSearch), warnIfMissed: false);
      await tester.pump();

      expect(presses, 0);
    });

    testWidgets('announced as an enabled button named by its hint', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpTrigger(
        tester,
        CommandSearch(hint: 'Search', onPressed: () {}),
      );
      // The hint's label merges into the node that carries the role.
      final data = tester.getSemantics(find.text('Search')).getSemanticsData();

      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      expect(data.label, contains('Search'));
      handle.dispose();
    });

    testWidgets('a disabled trigger is announced disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTrigger(tester, const CommandSearch(hint: 'Search'));
      // The hint's label merges into the node that carries the role.
      final data = tester.getSemantics(find.text('Search')).getSemanticsData();

      expect(data.flagsCollection.isButton, isTrue);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });
  });
}
