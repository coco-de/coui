import 'dart:ui' show Tristate;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// The row `Menu`, `DropdownMenu`, `ContextMenu`, `Menubar` and `Select`
/// all place. What is pinned here is the part a reader cannot see from
/// the resolver alone: which of the three per-state bundles the widget
/// actually selects, and what the selection does to the painted box.
///
/// The size ladder is asserted in rendered pixels rather than against
/// `CoreMenuItemStyle.defaultsBySize` — restating the table would pass
/// whatever the table said, including a value the row never draws.
void main() {
  /// A menu row needs a bounded width: its label seat is an `Expanded`,
  /// and the centred harness hands loose constraints.
  Future<void> pumpRow(WidgetTester tester, Widget child) => pumpTestApp(
    tester,
    SizedBox(width: 240, child: child),
    theme: ThemeData.fromCore(CoreThemePresets.light),
  );

  /// The row's own box — the one `AnimatedContainer` that states a
  /// height floor. `Clickable` may wrap another for its press chrome, so
  /// the constraint is what tells the two apart.
  AnimatedContainer rowBox(WidgetTester tester, {Finder? of}) => tester
      .widgetList<AnimatedContainer>(
        find.descendant(
          of: of ?? find.byType(MenuItem),
          matching: find.byType(AnimatedContainer),
        ),
      )
      .firstWhere((container) => container.constraints != null);

  BoxDecoration rowFill(WidgetTester tester, {Finder? of}) =>
      rowBox(tester, of: of).decoration! as BoxDecoration;

  /// What the label text actually reads in — the row hands its per-state
  /// colour down through `DefaultTextStyle.merge`, so the ambient style
  /// at the `Text` is the resolved one.
  Color labelColor(WidgetTester tester, String label) =>
      DefaultTextStyle.of(tester.element(find.text(label))).style.color!;

  Color tokenColor(WidgetTester tester, CoreColorToken token) => Theme.of(
    tester.element(find.byType(MenuItem).first),
  ).colorScheme.resolve(CoreColor.token(token)).toValue();

  group('MenuItem renders its seats', () {
    testWidgets('draws the label', (tester) async {
      await pumpRow(
        tester,
        MenuItem(label: const Text('Rename'), onPressed: () {}),
      );

      expect(find.byType(MenuItem), findsOneWidget);
      expect(find.text('Rename'), findsOneWidget);
    });

    testWidgets('draws the shortcut hint next to the label', (tester) async {
      await pumpRow(
        tester,
        MenuItem(
          label: const Text('Save'),
          shortcut: const Text('Ctrl+S'),
          onPressed: () {},
        ),
      );

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Ctrl+S'), findsOneWidget);
    });

    testWidgets('a description grows the row past its height floor', (
      tester,
    ) async {
      await pumpRow(
        tester,
        MenuItem(
          label: const Text('Export'),
          description: const Text('Write the current view to a file'),
          onPressed: () {},
        ),
      );

      expect(find.text('Write the current view to a file'), findsOneWidget);
      expect(
        tester.getSize(find.byType(MenuItem)).height,
        greaterThan(CoreSize.size36),
        reason:
            'a described row that stops at the md floor clipped its second '
            'line — the row must grow past the minimum, not clamp to it',
      );
    });
  });

  group('MenuItem density ladder', () {
    // Measured, not restated: at scaling 1 the three rungs are 32 / 36 /
    // 48. Reading `defaultsBySize` back would pass whatever that table
    // happens to hold.
    const expected = {
      CoreMenuItemSize.sm: CoreControlSize.heightSm,
      CoreMenuItemSize.md: CoreSize.size36,
      CoreMenuItemSize.lg: CoreControlSize.heightLg,
    };

    for (final entry in expected.entries) {
      testWidgets('${entry.key.name} rows are ${entry.value} high', (
        tester,
      ) async {
        await pumpRow(
          tester,
          MenuItem(
            label: const Text('Row'),
            size: entry.key,
            onPressed: () {},
          ),
        );

        expect(tester.getSize(find.byType(MenuItem)).height, entry.value);
      });
    }

    testWidgets('the default size is sm', (tester) async {
      await pumpRow(
        tester,
        MenuItem(label: const Text('Row'), onPressed: () {}),
      );

      expect(
        tester.getSize(find.byType(MenuItem)).height,
        CoreControlSize.heightSm,
      );
    });
  });

  group('MenuItem content sits at the row centre', () {
    /// The label's gap to the row's top edge and to its bottom edge. The
    /// row's height is a floor, so when padding + content is shorter than
    /// the floor the leftover must split above and below — measured on the
    /// painted `Text`, not read back from the resolver.
    Future<({double top, double bottom, double height})> labelGaps(
      WidgetTester tester, {
      CoreMenuItemSize size = CoreMenuItemSize.md,
      CoreDensity density = CoreDensity.standard,
      CoreMenuItemStyle? menuItemStyle,
      Widget? description,
    }) async {
      await pumpTestApp(
        tester,
        SizedBox(
          width: 240,
          child: MenuItem(
            label: const Text('Row'),
            size: size,
            description: description,
            menuItemStyle: menuItemStyle,
            onPressed: () {},
          ),
        ),
        theme: ThemeData.fromCore(CoreThemePresets.light),
        density: density,
      );
      final row = tester.getRect(find.byType(MenuItem));
      final label = tester.getRect(find.text('Row'));
      return (
        top: label.top - row.top,
        bottom: row.bottom - label.bottom,
        height: row.height,
      );
    }

    // Every rung of both ladders: the standard sm / md rows only land on the
    // centre by coincidence (padding + a 20 line = the floor), so the cases
    // that matter are the ones where the floor outgrows the content —
    // compact (padding shrinks, the 36 md floor does not) and the lg row.
    for (final density in CoreDensity.values) {
      for (final size in CoreMenuItemSize.values) {
        testWidgets('${size.name} row at ${density.name} density', (
          tester,
        ) async {
          final gaps = await labelGaps(tester, size: size, density: density);

          expect(
            gaps.top,
            closeTo(gaps.bottom, 0.01),
            reason:
                'the label sat ${gaps.top} below the top and ${gaps.bottom} '
                "above the bottom of a ${gaps.height} row — the Stack's "
                'default top seat leaves the leftover height underneath',
          );
        });
      }
    }

    testWidgets("a caller's own height floor is split above and below", (
      tester,
    ) async {
      final gaps = await labelGaps(
        tester,
        menuItemStyle: const CoreMenuItemStyle(minHeight: 56),
      );

      expect(gaps.height, 56);
      expect(gaps.top, closeTo(gaps.bottom, 0.01));
      expect(gaps.top, greaterThan(8));
    });

    testWidgets('a described row still starts at the top inset', (
      tester,
    ) async {
      final gaps = await labelGaps(
        tester,
        description: const Text('Write the current view to a file'),
      );

      // The described row grows past its floor, so there is no leftover to
      // centre: the two lines stay top-aligned at the 8 inset.
      expect(gaps.top, 8);
    });
  });

  group('MenuItem md row values', () {
    testWidgets('reads 10 / 8 insets, an 18 leading icon, a 10 gap and an 8 '
        'corner', (tester) async {
      await pumpRow(
        tester,
        MenuItem(
          size: CoreMenuItemSize.md,
          label: const Text('Row'),
          leading: const SizedBox.square(key: ValueKey('leading')),
          onPressed: () {},
        ),
      );

      final row = tester.getTopLeft(find.byType(MenuItem));
      final leading = tester.getTopLeft(find.byKey(const ValueKey('leading')));
      // The leading seat starts one inset in, and the label one gap past it.
      expect(leading.dx - row.dx, 10);
      expect(
        tester.getTopLeft(find.text('Row')).dx -
            tester
                .getTopRight(
                  find.byKey(const ValueKey('leading')),
                )
                .dx,
        10,
      );
      expect(
        IconTheme.of(
          tester.element(find.byKey(const ValueKey('leading'))),
        ).size,
        18,
      );
      expect(
        rowBox(tester).constraints!.minHeight,
        36,
      );
      expect(
        (rowFill(tester).borderRadius! as BorderRadius).topLeft.x,
        8,
      );
    });

    testWidgets('description reads body-small (13) and the shortcut body-xs '
        '(12)', (tester) async {
      await pumpRow(
        tester,
        MenuItem(
          size: CoreMenuItemSize.md,
          label: const Text('Export'),
          description: const Text('Write a file'),
          shortcut: const Text('Ctrl+E'),
          onPressed: () {},
        ),
      );

      double sizeOf(String text) => DefaultTextStyle.of(
        tester.element(find.text(text)),
      ).style.fontSize!;
      expect(sizeOf('Export'), 14);
      expect(sizeOf('Write a file'), 13);
      expect(sizeOf('Ctrl+E'), 12);
    });
  });

  group('MenuItem disabled is inert, not invisible', () {
    testWidgets('a row without onPressed does not act, and says so', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpRow(tester, const MenuItem(label: Text('Paste')));

      final data = tester
          .getSemantics(find.byType(MenuItem))
          .getSemanticsData();

      expect(data.flagsCollection.isEnabled, isNot(Tristate.none));
      expect(
        data.flagsCollection.isEnabled,
        Tristate.isFalse,
        reason:
            'a row with no handler must announce as disabled — silence '
            'here is a row a screen-reader user cannot tell apart from a '
            'working one',
      );
      handle.dispose();
    });

    testWidgets('enabled: false withholds the handler it was given', (
      tester,
    ) async {
      var pressed = false;
      await pumpRow(
        tester,
        MenuItem(
          label: const Text('Paste'),
          enabled: false,
          onPressed: () => pressed = true,
        ),
      );

      await tester.tap(find.text('Paste'), warnIfMissed: false);
      final _ = await tester.pumpAndSettle();

      expect(
        pressed,
        isFalse,
        reason:
            'an explicit `enabled: false` must outrank the presence of a '
            'handler — otherwise the flag is decorative',
      );
    });

    testWidgets('a disabled row stays a focus stop', (tester) async {
      await pumpRow(
        tester,
        MenuItem(
          label: const Text('Paste'),
          enabled: false,
          onPressed: () {},
        ),
      );

      // WAI-ARIA keeps a disabled menu row in the keyboard order so the
      // user can land on it and hear why it does nothing. Dropping it out
      // of the order is the failure this pins.
      final node =
          tester
                .widgetList<Focus>(
                  find.descendant(
                    of: find.byType(MenuItem),
                    matching: find.byType(Focus),
                  ),
                )
                .firstWhere((focus) => focus.focusNode != null)
                .focusNode!
            ..requestFocus();
      await tester.pump();

      expect(node.hasFocus, isTrue);
    });

    testWidgets('a disabled row reads in the disabled foreground', (
      tester,
    ) async {
      await pumpRow(tester, const MenuItem(label: Text('Paste')));

      expect(
        labelColor(tester, 'Paste'),
        tokenColor(tester, CoreColors.disabledContent),
      );
    });

    testWidgets('description, shortcut and glyphs share the disabled ink', (
      tester,
    ) async {
      await pumpRow(
        tester,
        const MenuItem(
          label: Text('Export'),
          description: Text('Write a file'),
          shortcut: Text('Ctrl+E'),
          leading: Icon(LucideIcons.download),
        ),
      );

      final disabled = tokenColor(tester, CoreColors.disabledContent);
      expect(labelColor(tester, 'Export'), disabled);
      expect(labelColor(tester, 'Write a file'), disabled);
      expect(labelColor(tester, 'Ctrl+E'), disabled);
      expect(
        IconTheme.of(tester.element(find.byType(Icon))).color,
        disabled,
      );
      // Not the enabled secondary ink the row rests in.
      expect(
        disabled,
        isNot(tokenColor(tester, CoreColors.onSurfaceVariant)),
      );
    });

    testWidgets('the pressed wash is 12% and hover and focus 8%', (
      tester,
    ) async {
      late ResolvedMenuItem resolved;
      late Color foreground;
      await pumpRow(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveMenuItem(
              context,
              size: CoreMenuItemSize.md,
              tone: CoreMenuItemTone.neutral,
            );
            foreground = Theme.of(context).colorScheme
                .resolve(const CoreColor.token(CoreColors.onSurface))
                .toValue();
            return const SizedBox();
          },
        ),
      );

      expect(resolved.hoverColor.a, closeTo(0.08, 1e-6));
      expect(resolved.focusColor.a, closeTo(0.08, 1e-6));
      expect(resolved.pressedColor.a, closeTo(0.12, 1e-6));
      expect(resolved.pressedColor.withValues(alpha: 1), foreground);
    });

    testWidgets('disabled outranks selected', (tester) async {
      await pumpRow(
        tester,
        const MenuItem(label: Text('Paste'), selected: true),
      );

      // A disabled row never draws the selected fill: selection is a
      // statement about a choice the user can still make.
      expect(
        rowFill(tester).color,
        isNot(tokenColor(tester, CoreColors.primary)),
      );
    });
  });

  group('MenuItem selection and tone', () {
    testWidgets('a selected row fills with primary', (tester) async {
      await pumpRow(
        tester,
        MenuItem(
          label: const Text('Grid'),
          selected: true,
          onPressed: () {},
        ),
      );

      expect(rowFill(tester).color, tokenColor(tester, CoreColors.primary));
      expect(
        labelColor(tester, 'Grid'),
        tokenColor(tester, CoreColors.onPrimary),
      );
    });

    testWidgets('an unselected row paints no fill of its own', (tester) async {
      await pumpRow(
        tester,
        MenuItem(label: const Text('Grid'), onPressed: () {}),
      );

      expect(
        rowFill(tester).color?.a,
        0,
        reason: 'the panel behind the row is the surface, not the row',
      );
    });

    testWidgets('a critical row reads in the error colour', (tester) async {
      await pumpRow(
        tester,
        MenuItem(
          label: const Text('Delete'),
          tone: CoreMenuItemTone.critical,
          onPressed: () {},
        ),
      );

      expect(
        labelColor(tester, 'Delete'),
        tokenColor(tester, CoreColors.error),
      );
    });

    testWidgets('a neutral row reads in onSurface', (tester) async {
      await pumpRow(
        tester,
        MenuItem(label: const Text('Delete'), onPressed: () {}),
      );

      expect(
        labelColor(tester, 'Delete'),
        tokenColor(tester, CoreColors.onSurface),
      );
    });

    testWidgets('onPressed fires on tap', (tester) async {
      var pressed = false;
      await pumpRow(
        tester,
        MenuItem(
          label: const Text('Run'),
          onPressed: () => pressed = true,
        ),
      );

      await tester.tap(find.text('Run'));
      final _ = await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });
  });

  group('MenuItem critical active state', () {
    Widget critical({
      bool selected = false,
      VoidCallback? onPressed,
      bool enabled = true,
    }) => MenuItem(
      label: const Text('Delete'),
      description: const Text('Cannot be undone'),
      shortcut: const Text('Del'),
      leading: const Icon(LucideIcons.trash2),
      tone: CoreMenuItemTone.critical,
      selected: selected,
      enabled: enabled,
      onPressed: onPressed ?? () {},
    );

    /// Connects a mouse *before* the row mounts: `FocusableActionDetector`
    /// snapshots the highlight mode in its first post-frame callback, and a
    /// mouse that connects afterwards never shows a hover highlight.
    Future<TestGesture> connectMouse(WidgetTester tester) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      return gesture;
    }

    Future<void> hoverRow(WidgetTester tester, TestGesture gesture) async {
      await gesture.moveTo(tester.getCenter(find.text('Delete')));
      await tester.pumpAndSettle();
    }

    /// Pump [row] with a mouse already connected, then rest on it.
    Future<TestGesture> pumpHovered(WidgetTester tester, Widget row) async {
      final gesture = await connectMouse(tester);
      await pumpRow(tester, row);
      await hoverRow(tester, gesture);
      return gesture;
    }

    /// Every ink the row paints, by seat.
    Map<String, Color> inks(WidgetTester tester) => {
      'label': labelColor(tester, 'Delete'),
      'description': labelColor(tester, 'Cannot be undone'),
      'shortcut': labelColor(tester, 'Del'),
      'glyph': IconTheme.of(tester.element(find.byType(Icon))).color!,
    };

    /// How many `Position` layers the row draws — the wash is one of them.
    int layers(WidgetTester tester) => find
        .descendant(of: find.byType(MenuItem), matching: find.byType(Position))
        .evaluate()
        .length;

    testWidgets('rests transparent in the error ink', (tester) async {
      await pumpRow(tester, critical());

      expect(rowFill(tester).color?.a, 0);
      expect(
        labelColor(tester, 'Delete'),
        tokenColor(tester, CoreColors.error),
      );
    });

    testWidgets('hover fills with errorContainer and keeps every ink at '
        'rest', (tester) async {
      final gesture = await connectMouse(tester);
      await pumpRow(tester, critical());
      final resting = layers(tester);
      final restingInks = inks(tester);
      await hoverRow(tester, gesture);

      expect(
        rowFill(tester).color,
        tokenColor(tester, CoreColors.errorContainer),
      );
      // Only the fill changes (designer decision 2026-11-05, #6012): the
      // label stays `error`, the description and the shortcut keep their
      // muted colour.
      expect(inks(tester), restingInks);
      expect(restingInks['label'], tokenColor(tester, CoreColors.error));
      expect(
        restingInks['description'],
        isNot(restingInks['label']),
        reason: 'the description keeps its own muted colour',
      );
      // The fill replaces the wash — a wash of the error ink over a
      // transparent row would be the error colour itself.
      expect(layers(tester), resting);
    });

    testWidgets('pressed fills with errorContainer too', (tester) async {
      final gesture = await connectMouse(tester);
      await pumpRow(tester, critical());
      await gesture.moveTo(tester.getCenter(find.text('Delete')));
      await tester.pump();
      await gesture.down(tester.getCenter(find.text('Delete')));
      await tester.pumpAndSettle();

      expect(
        rowFill(tester).color,
        tokenColor(tester, CoreColors.errorContainer),
      );
      expect(
        labelColor(tester, 'Delete'),
        tokenColor(tester, CoreColors.error),
      );
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('keyboard focus reads the same as hover', (tester) async {
      await pumpRow(tester, critical());
      final node = tester
          .widgetList<Focus>(
            find.descendant(
              of: find.byType(MenuItem),
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

      expect(
        rowFill(tester).color,
        tokenColor(tester, CoreColors.errorContainer),
      );
      expect(
        labelColor(tester, 'Delete'),
        tokenColor(tester, CoreColors.error),
      );
    });

    testWidgets('leaving the row restores the resting ink', (tester) async {
      final gesture = await pumpHovered(tester, critical());
      await gesture.moveTo(const Offset(2, 2));
      await tester.pumpAndSettle();

      expect(rowFill(tester).color?.a, 0);
      expect(
        labelColor(tester, 'Delete'),
        tokenColor(tester, CoreColors.error),
      );
    });

    testWidgets('a neutral row is still washed, not filled', (tester) async {
      final gesture = await connectMouse(tester);
      await pumpRow(
        tester,
        MenuItem(
          label: const Text('Delete'),
          onPressed: () {},
        ),
      );
      final resting = layers(tester);
      await hoverRow(tester, gesture);

      expect(rowFill(tester).color?.a, 0);
      expect(layers(tester), resting + 1, reason: 'the wash appears');
      expect(
        labelColor(tester, 'Delete'),
        tokenColor(tester, CoreColors.onSurface),
      );
    });

    testWidgets('a selected critical row keeps the selected pair', (
      tester,
    ) async {
      await pumpHovered(tester, critical(selected: true));

      expect(rowFill(tester).color, tokenColor(tester, CoreColors.primary));
      expect(
        labelColor(tester, 'Delete'),
        tokenColor(tester, CoreColors.onPrimary),
      );
    });

    testWidgets('a disabled critical row takes no active state', (
      tester,
    ) async {
      await pumpHovered(tester, critical(enabled: false));

      expect(rowFill(tester).color?.a, 0);
      expect(
        labelColor(tester, 'Delete'),
        tokenColor(tester, CoreColors.disabledContent),
      );
    });

    testWidgets('the error ink on errorContainer clears 4.5 : 1 in the '
        'modes this suite renders', (tester) async {
      late Color fill;
      late Color ink;
      await pumpRow(
        tester,
        Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            fill = scheme
                .resolve(const CoreColor.token(CoreColors.errorContainer))
                .toValue();
            ink = scheme
                .resolve(const CoreColor.token(CoreColors.error))
                .toValue();
            return const SizedBox();
          },
        ),
      );

      final hi = fill.computeLuminance() > ink.computeLuminance() ? fill : ink;
      final lo = identical(hi, fill) ? ink : fill;
      final ratio =
          (hi.computeLuminance() + 0.05) / (lo.computeLuminance() + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });
  });

  group('MenuItem end seat', () {
    bool hasChevron(WidgetTester tester) => tester
        .widgetList<Icon>(find.byType(Icon))
        .any((icon) => icon.icon == LucideIcons.chevronRight);

    testWidgets('a submenu row draws the chevron instead of the shortcut', (
      tester,
    ) async {
      await pumpRow(
        tester,
        MenuItem(
          label: const Text('More'),
          shortcut: const Text('Ctrl+M'),
          hasSubmenu: true,
          onPressed: () {},
        ),
      );

      expect(hasChevron(tester), isTrue);
      expect(
        find.text('Ctrl+M'),
        findsNothing,
        reason:
            'the chevron takes the shortcut seat — drawing both puts two '
            'end affordances on one row',
      );
    });

    testWidgets('a plain row draws no chevron', (tester) async {
      await pumpRow(
        tester,
        MenuItem(
          label: const Text('More'),
          shortcut: const Text('Ctrl+M'),
          onPressed: () {},
        ),
      );

      expect(hasChevron(tester), isFalse);
      expect(find.text('Ctrl+M'), findsOneWidget);
    });
  });

  group('MenuItem mark column', () {
    /// Two rows in one column: one draws its mark, the other only
    /// reserves the seat. Their labels must start on the same x — that
    /// alignment is the whole reason `reserveMark` exists.
    testWidgets("reserveMark keeps the marked row's label x", (tester) async {
      await pumpRow(
        tester,
        Column(
          mainAxisSize: .min,
          children: [
            MenuItem(
              label: const Text('On'),
              mark: const Icon(LucideIcons.check),
              reserveMark: true,
              onPressed: () {},
            ),
            MenuItem(
              label: const Text('Off'),
              reserveMark: true,
              onPressed: () {},
            ),
          ],
        ),
      );

      expect(
        tester.getTopLeft(find.text('Off')).dx,
        tester.getTopLeft(find.text('On')).dx,
      );
    });

    testWidgets('without reserveMark an unmarked label sits further left', (
      tester,
    ) async {
      await pumpRow(
        tester,
        Column(
          mainAxisSize: .min,
          children: [
            MenuItem(
              label: const Text('On'),
              mark: const Icon(LucideIcons.check),
              reserveMark: true,
              onPressed: () {},
            ),
            MenuItem(label: const Text('Off'), onPressed: () {}),
          ],
        ),
      );

      // The negative control: without the reserved column the two labels
      // disagree, which is what makes the assertion above meaningful.
      expect(
        tester.getTopLeft(find.text('Off')).dx,
        lessThan(tester.getTopLeft(find.text('On')).dx),
      );
    });
  });

  group('MenuItem style slot', () {
    testWidgets('menuItemStyle overrides the ladder height', (tester) async {
      await pumpRow(
        tester,
        MenuItem(
          label: const Text('Tall'),
          onPressed: () {},
          menuItemStyle: const CoreMenuItemStyle(minHeight: 64),
        ),
      );

      expect(tester.getSize(find.byType(MenuItem)).height, 64);
    });

    testWidgets('withStyle merges a patch into the slot', (tester) async {
      await pumpRow(
        tester,
        MenuItem(
          label: const Text('Tall'),
          onPressed: () {},
        ).withStyle(const CoreMenuItemStyle(minHeight: 64)),
      );

      expect(tester.getSize(find.byType(MenuItem)).height, 64);
    });

    testWidgets('withStyle keeps the fields it was not given', (tester) async {
      await pumpRow(
        tester,
        MenuItem(
          label: const Text('Tall'),
          onPressed: () {},
          menuItemStyle: const CoreMenuItemStyle(minHeight: 64),
        ).withStyle(
          const CoreMenuItemStyle(
            backgroundColor: CoreColor.token(CoreColors.secondary),
          ),
        ),
      );

      // A patch that replaced the slot rather than merging into it would
      // drop the height back to the ladder.
      expect(tester.getSize(find.byType(MenuItem)).height, 64);
      expect(rowFill(tester).color, tokenColor(tester, CoreColors.secondary));
    });

    testWidgets('a component theme reaches the row', (tester) async {
      await pumpTestApp(
        tester,
        SizedBox(
          width: 240,
          child: MenuItem(label: const Text('Themed'), onPressed: () {}),
        ),
        theme: ThemeData.fromCore(CoreThemePresets.light),
        componentTheme: const CoreComponentTheme(
          menuItem: CoreMenuItemTheme(
            style: CoreMenuItemStyle(minHeight: 56),
          ),
        ),
      );

      expect(tester.getSize(find.byType(MenuItem)).height, 56);
    });
  });
}
