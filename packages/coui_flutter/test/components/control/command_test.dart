import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('Command', () {
    testWidgets('renders item labels', (tester) async {
      await pumpTestApp(
        tester,
        Command(
          onSelect: (_) {},
          groups: const [
            CoreCommandGroup(
              items: [CoreCommandItem(value: 'cmd', label: 'Command')],
            ),
          ],
        ),
      );

      expect(find.text('Command'), findsOneWidget);
    });

    testWidgets('renders an item with an icon', (tester) async {
      await pumpTestApp(
        tester,
        Command(
          onSelect: (_) {},
          groups: const [
            CoreCommandGroup(
              items: [
                CoreCommandItem(
                  value: 'search',
                  label: 'Search',
                  icon: Icon(LucideIcons.search),
                ),
              ],
            ),
          ],
        ),
      );

      expect(find.text('Search'), findsOneWidget);
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('renders a group heading', (tester) async {
      await pumpTestApp(
        tester,
        Command(
          onSelect: (_) {},
          groups: const [
            CoreCommandGroup(
              heading: 'Category',
              items: [CoreCommandItem(value: 'sub', label: 'Sub Item')],
            ),
          ],
        ),
      );

      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Sub Item'), findsOneWidget);
    });

    testWidgets('a keyword-only query shows the row', (tester) async {
      await pumpTestApp(
        tester,
        const Command(
          query: 'date',
          groups: [
            CoreCommandGroup(
              items: [
                CoreCommandItem(
                  value: 'calendar',
                  label: 'Calendar',
                  keywords: ['date', 'schedule'],
                ),
                CoreCommandItem(value: 'search', label: 'Search Emoji'),
              ],
            ),
          ],
        ),
      );

      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Search Emoji'), findsNothing);
    });

    testWidgets('shows the empty label when the query matches nothing', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Command(
          query: 'zzz-no-match',
          emptyLabel: 'No results',
          groups: [
            CoreCommandGroup(
              items: [CoreCommandItem(value: 'x', label: 'Xyz')],
            ),
          ],
        ),
      );

      expect(find.text('No results'), findsOneWidget);
    });
  });

  group('Command redesign', () {
    const groups = [
      CoreCommandGroup<Widget>(
        heading: 'Actions',
        scope: 'actions',
        items: [
          CoreCommandItem(value: 'new', label: 'New file'),
          CoreCommandItem(value: 'open', label: 'Open', enabled: false),
        ],
      ),
      CoreCommandGroup<Widget>(
        heading: 'Pages',
        scope: 'pages',
        items: [
          CoreCommandItem(
            value: 'settings',
            label: 'Settings',
            overline: 'Account',
          ),
        ],
      ),
    ];
    const scopes = [
      CoreCommandScope(value: 'actions', label: 'Actions'),
      CoreCommandScope(value: 'pages', label: 'Pages'),
    ];

    testWidgets('scope chips render with an automatic All chip and a '
        'selected scope hides the other groups', (tester) async {
      await pumpTestApp(
        tester,
        Command(
          onSelect: (_) {},
          groups: groups,
          scopes: scopes,
          scope: 'pages',
        ),
      );
      expect(find.byType(Chip), findsNWidgets(3));
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('New file'), findsNothing);
    });

    testWidgets('every scope chip asks for the quiet register — a selected '
        'one is the tint, never the solid fill', (tester) async {
      await pumpTestApp(
        tester,
        Command(
          onSelect: (_) {},
          groups: groups,
          scopes: scopes,
          scope: 'pages',
        ),
      );
      final chips = tester.widgetList<Chip>(find.byType(Chip)).toList();
      expect(chips, hasLength(3));
      for (final chip in chips) {
        expect(chip.emphasis, CoreChipEmphasis.low);
      }
      expect(chips.where((c) => c.selected), hasLength(1));
      expect(chips.singleWhere((c) => c.selected).label, 'Pages');
    });

    testWidgets('an overline renders above the label', (tester) async {
      await pumpTestApp(
        tester,
        Command(onSelect: (_) {}, groups: groups),
      );
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('ArrowRight moves the scope ring, Escape dismisses', (
      tester,
    ) async {
      String? scope;
      var dismissed = false;
      await pumpTestApp(
        tester,
        Command(
          onSelect: (_) {},
          groups: groups,
          scopes: scopes,
          onScopeChanged: (s) => scope = s,
          onDismiss: () => dismissed = true,
        ),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(scope, 'actions');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(dismissed, isTrue);
    });

    testWidgets('the empty state composes EmptyState with the locale hint', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Command(onSelect: (_) {}, groups: groups, query: 'zzz'),
      );
      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No results found.'), findsOneWidget);
    });

    // The list's ceiling is where its rows start to scroll; an empty state does
    // not scroll. Its centring took the whole 240–320 range — 320 tall where
    // the Web's `min-height` draws 240.
    testWidgets('the empty state is as tall as the floor, not the ceiling', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Command(onSelect: (_) {}, groups: groups, query: 'zzz'),
      );

      expect(
        tester.getSize(find.byType(EmptyState)).height,
        CoreCommandStyle.defaultListMinHeight,
      );
    });

    testWidgets('an empty state taller than the ceiling is not cut to it', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Command(
          onSelect: (_) {},
          groups: groups,
          query: 'zzz',
          emptyAction: const SizedBox(height: 400, width: 40),
        ),
      );

      expect(
        tester.getSize(find.byType(EmptyState)).height,
        greaterThan(CoreCommandStyle.defaultListMaxHeight),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a fullscreen palette still centres its empty state', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Command(
          onSelect: (_) {},
          groups: groups,
          query: 'zzz',
          presentation: .fullscreen,
        ),
      );

      final command = tester.getRect(find.byType(Command));
      final divider = tester.getRect(find.byType(Divider).first);
      final region = Rect.fromLTRB(
        command.left,
        divider.bottom,
        command.right,
        command.bottom,
      );
      expect(
        tester.getSize(find.byType(EmptyState)).height,
        CoreCommandStyle.defaultListMinHeight,
      );
      expect(
        tester.getCenter(find.byType(EmptyState)).dy,
        closeTo(region.center.dy, 1),
      );
    });

    testWidgets('showFooter defaults off for the inline shape', (
      tester,
    ) async {
      await pumpTestApp(tester, Command(onSelect: (_) {}, groups: groups));
      expect(find.byType(Kbd), findsNothing);
    });

    testWidgets('showFooter defaults on for the dialog shape', (tester) async {
      await pumpTestApp(
        tester,
        Command(onSelect: (_) {}, groups: groups, presentation: .dialog),
      );
      expect(find.byType(Kbd), findsWidgets);
    });

    testWidgets('the arrow pair is labelled once, for moving either way', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Command(onSelect: (_) {}, groups: groups, presentation: .dialog),
      );
      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('Move Up'), findsNothing);
      expect(find.text('Move Down'), findsNothing);
    });
  });

  group('Command row (redesign)', () {
    late ResolvedCommand sm;
    late ResolvedCommand md;
    late ResolvedCommand lg;
    late CoreTypography typography;
    late ColorScheme scheme;

    Future<void> resolveAll(WidgetTester tester) async {
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            sm = resolveCommand(context, size: .sm);
            md = resolveCommand(context);
            lg = resolveCommand(context, size: .lg);
            typography = Theme.of(context).typography;
            scheme = Theme.of(context).colorScheme;
            return const SizedBox.shrink();
          },
        ),
      );
    }

    testWidgets('the title is Regular at the body size of the rung', (
      tester,
    ) async {
      await resolveAll(tester);
      expect(sm.itemTitleTextStyle.fontSize, typography.bodySmall.fontSize);
      expect(md.itemTitleTextStyle.fontSize, typography.bodyMedium.fontSize);
      expect(lg.itemTitleTextStyle.fontSize, typography.bodyMedium.fontSize);
      for (final r in [sm, md, lg]) {
        expect(r.itemTitleTextStyle.fontWeight, FontWeight.w400);
        expect(r.itemTitleTextStyle.color, r.itemForegroundColor);
        expect(r.itemTitleDisabledTextStyle.fontWeight, FontWeight.w400);
        expect(
          r.itemTitleDisabledTextStyle.color,
          r.itemDisabledForegroundColor,
        );
      }
    });

    testWidgets('the description is Regular, in on-surface-variant, and one '
        'step smaller than the title', (tester) async {
      await resolveAll(tester);
      expect(sm.overlineTextStyle.fontSize, typography.bodyXs.fontSize);
      expect(md.overlineTextStyle.fontSize, typography.bodyXs.fontSize);
      expect(lg.overlineTextStyle.fontSize, typography.bodyXs.fontSize);
      // The confirmed description tone is shared across row states.
      const variant = CoreColor.token(CoreColors.onSurfaceVariant);
      for (final r in [sm, md, lg]) {
        expect(r.overlineTextStyle.fontWeight, FontWeight.w400);
        expect(r.overlineTextStyle.color, scheme.resolve(variant).toValue());
        // Disabled keeps the disabled token on every text.
        expect(
          r.overlineDisabledTextStyle.color,
          r.itemDisabledForegroundColor,
        );
        expect(r.overlineDisabledTextStyle.fontWeight, FontWeight.w400);
      }
    });

    testWidgets('the shortcut keeps on-surface-variant, disabled keeps the '
        'disabled token', (tester) async {
      await resolveAll(tester);
      const variant = CoreColor.token(CoreColors.onSurfaceVariant);
      expect(md.shortcutTextStyle.color, scheme.resolve(variant).toValue());
      expect(
        md.shortcutDisabledTextStyle.color,
        md.itemDisabledForegroundColor,
      );
    });

    testWidgets('a two-line row grows from its text: sm 46 · md 55 · lg 59', (
      tester,
    ) async {
      final heights = <CoreCommandSize, double>{};
      for (final size in CoreCommandSize.values) {
        // A fresh tree per rung — the rows would otherwise animate from the
        // previous rung's floor.
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpTestApp(
          tester,
          Command(
            onSelect: (_) {},
            size: size,
            groups: const [
              CoreCommandGroup(
                items: [
                  CoreCommandItem(
                    value: 'profile',
                    label: 'Profile',
                    overline: 'Account',
                  ),
                ],
              ),
            ],
          ),
        );
        // The row animates its floor when the rung changes — let it land.
        await tester.pumpAndSettle();
        // The row is the nearest animated box around the title.
        final row = find
            .ancestor(
              of: find.text('Profile'),
              matching: find.byType(AnimatedContainer),
            )
            .first;
        heights[size] = tester.getSize(row).height;
      }
      // Insets + the description line + the title line, on the 1.5 body
      // leading. Figma rounds each line up, so the canvas is up to a pixel
      // taller than the layout box.
      expect(heights[CoreCommandSize.sm], closeTo(46, 1));
      expect(heights[CoreCommandSize.md], closeTo(55, 1));
      expect(heights[CoreCommandSize.lg], closeTo(59, 1));
    });

    testWidgets('the active row is the fill alone — no accent bar is '
        'painted', (tester) async {
      await pumpTestApp(
        tester,
        Command(
          onSelect: (_) {},
          groups: const [
            CoreCommandGroup(
              items: [CoreCommandItem(value: 'a', label: 'Alpha')],
            ),
          ],
        ),
      );
      await tester.pump();
      final row = find
          .ancestor(
            of: find.text('Alpha'),
            matching: find.byType(AnimatedContainer),
          )
          .first;
      // The stack inside the row holds the padded content and, on hover,
      // the wash — never a left-pinned bar.
      final stack = find.descendant(of: row, matching: find.byType(Stacks));
      final pinned = tester
          .widgetList<Position>(
            find.descendant(of: stack, matching: find.byType(Position)),
          )
          .where((p) => p.left == 0 && p.top != null);
      expect(pinned, isEmpty);
    });
  });

  group('Command panel (redesign)', () {
    // The canvas draws the inline palette with a heading, three one-line rows
    // and one two-line row under the three scope chips: 315 · 331 · 369 tall.
    // On `sm` and `md` the list sits on its 240 floor, so its 8 inset and the
    // 2 gap between its children do not show; on `lg` the rows outgrow the
    // floor. The layout box is up to a pixel shorter than the canvas, which
    // rounds every text line up.
    testWidgets('the inline panel is as tall as the canvas draws it', (
      tester,
    ) async {
      const expected = {
        CoreCommandSize.sm: 315.0,
        CoreCommandSize.md: 331.0,
        CoreCommandSize.lg: 369.0,
      };
      for (final MapEntry(key: size, value: height) in expected.entries) {
        await tester.pumpWidget(const SizedBox.shrink());
        await pumpTestApp(
          tester,
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 360,
              child: Command(
                onSelect: (_) {},
                size: size,
                scopes: const [
                  CoreCommandScope(value: 'actions', label: 'Actions'),
                  CoreCommandScope(value: 'pages', label: 'Pages'),
                ],
                groups: const [
                  CoreCommandGroup(
                    heading: 'Suggestions',
                    items: [
                      CoreCommandItem(value: 'a', label: 'Calendar'),
                      CoreCommandItem(value: 'b', label: 'Search Emoji'),
                      CoreCommandItem(value: 'c', label: 'Calculator'),
                      CoreCommandItem(
                        value: 'p',
                        label: 'Profile',
                        overline: 'Account',
                        shortcut: 'Ctrl+P',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byType(Command)).height,
          closeTo(height, 1.5),
          reason: '$size',
        );
      }
    });
  });
}
