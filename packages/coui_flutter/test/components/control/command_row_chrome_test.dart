import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// The palette's row, search row, list and heading chrome — each value read
/// back from the resolver or from the painted tree, not from the Style.
void main() {
  Color tokenColor(BuildContext context, CoreColorToken token) => Theme.of(
    context,
  ).colorScheme.resolve(CoreColor.token(token)).toValue();

  group('Command search row', () {
    for (final size in CoreCommandSize.values) {
      testWidgets('${size.name}: 12 across, a 10 gap, an on-surface-variant '
          'glyph', (tester) async {
        late ResolvedCommand r;
        late Color variant;
        await pumpTestApp(
          tester,
          Builder(
            builder: (context) {
              r = resolveCommand(context, size: size);
              variant = tokenColor(context, CoreColors.onSurfaceVariant);
              return Command(groups: const [], size: size);
            },
          ),
        );
        expect(r.searchPadding, const EdgeInsets.symmetric(horizontal: 12));
        expect(r.searchGapStyle.size, 10);
        final glyph = tester.widget<Icon>(
          find.byWidgetPredicate(
            (w) => w is Icon && w.icon == LucideIcons.search,
          ),
        );
        final ctx = tester.element(find.byWidget(glyph));
        expect(
          Theme.of(ctx).colorScheme.resolve(glyph.iconStyle!.color!).toValue(),
          variant,
        );
      });
    }
  });

  group('Command row', () {
    const insets = {
      CoreCommandSize.sm: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      CoreCommandSize.md: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      CoreCommandSize.lg: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    };
    for (final MapEntry(key: size, value: inset) in insets.entries) {
      testWidgets('${size.name}: insets $inset, a 10 gap', (tester) async {
        late ResolvedCommand r;
        await pumpTestApp(
          tester,
          Builder(
            builder: (context) {
              r = resolveCommand(context, size: size);
              return const SizedBox.shrink();
            },
          ),
        );
        expect(r.itemPadding, inset);
        expect(r.itemGapStyle.size, 10);
      });
    }

    testWidgets('the active fill is surface-container', (tester) async {
      late ResolvedCommand r;
      late Color container;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            r = resolveCommand(context);
            container = tokenColor(context, CoreColors.surfaceContainer);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(r.itemHighlightColor, container);
    });

    testWidgets('the glyph is on-surface-variant at rest, on-surface on the '
        'active row and the disabled token on a disabled row', (tester) async {
      late Color variant;
      late Color onSurface;
      late Color disabled;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            variant = tokenColor(context, CoreColors.onSurfaceVariant);
            onSurface = tokenColor(context, CoreColors.onSurface);
            disabled = tokenColor(context, CoreColors.disabledContent);
            return const Command(
              groups: [
                CoreCommandGroup(
                  items: [
                    CoreCommandItem(
                      value: 'a',
                      label: 'Calendar',
                      icon: Icon(LucideIcons.calendar),
                    ),
                    CoreCommandItem(
                      value: 'b',
                      label: 'Smile',
                      icon: Icon(LucideIcons.smile),
                    ),
                    CoreCommandItem(
                      value: 'c',
                      label: 'Off',
                      enabled: false,
                      icon: Icon(LucideIcons.user),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
      Color tintOf(IconName icon) {
        final glyph = find.byWidgetPredicate(
          (w) => w is Icon && w.icon == icon,
        );
        return IconTheme.of(tester.element(glyph)).color!;
      }

      // The first enabled row is the keyboard cursor.
      expect(tintOf(LucideIcons.calendar), onSurface);
      expect(tintOf(LucideIcons.smile), variant);
      expect(tintOf(LucideIcons.user), disabled);
    });
  });

  group('Command list', () {
    for (final presentation in CoreCommandPresentation.values) {
      testWidgets('${presentation.name}: an 8 inset and a 2 gap between the '
          'children', (tester) async {
        await pumpTestApp(
          tester,
          Command(
            presentation: presentation,
            groups: const [
              CoreCommandGroup(
                heading: 'Suggestions',
                items: [
                  CoreCommandItem(value: 'a', label: 'Alpha'),
                  CoreCommandItem(value: 'b', label: 'Beta'),
                ],
              ),
            ],
          ),
        );
        final scroll = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        expect(scroll.padding, const EdgeInsets.all(8));
        final alpha = find
            .ancestor(
              of: find.text('Alpha'),
              matching: find.byType(AnimatedContainer),
            )
            .first;
        final beta = find
            .ancestor(
              of: find.text('Beta'),
              matching: find.byType(AnimatedContainer),
            )
            .first;
        expect(
          tester.getTopLeft(beta).dy - tester.getBottomLeft(alpha).dy,
          2,
        );
      });
    }
  });

  group('Command heading', () {
    const ends = {
      CoreCommandSize.sm: 8.0,
      CoreCommandSize.md: 12.0,
      CoreCommandSize.lg: 16.0,
    };
    for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
      for (final MapEntry(key: size, value: end) in ends.entries) {
        testWidgets('${size.name} ${dir.name}: 10 where the text starts, '
            '$end where it ends, 6 above and below', (tester) async {
          await pumpTestApp(
            tester,
            Command(
              size: size,
              groups: const [
                CoreCommandGroup(
                  heading: 'Suggestions',
                  items: [CoreCommandItem(value: 'a', label: 'Alpha')],
                ),
              ],
            ),
            textDirection: dir,
          );
          final pad = tester.widget<Padding>(
            find
                .ancestor(
                  of: find.text('Suggestions'),
                  matching: find.byType(Padding),
                )
                .first,
          );
          final resolved = pad.padding.resolve(dir);
          final start = dir == .ltr ? resolved.left : resolved.right;
          final endSide = dir == .ltr ? resolved.right : resolved.left;
          expect(start, 10);
          expect(endSide, end);
          expect(resolved.top, 6);
          expect(resolved.bottom, 6);
        });
      }
    }
  });

  group('Command scope chips', () {
    testWidgets('carry no border and an 8 corner', (tester) async {
      late ResolvedCommand r;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            r = resolveCommand(context, size: .sm);
            return const SizedBox.shrink();
          },
        ),
      );
      expect(r.scopeChipStyle.borderWidth, 0);
      expect(
        r.scopeChipStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius8),
      );
    });
  });

  group('Command dialog search row', () {
    testWidgets('names Escape on the search row when it can be dismissed', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Command(groups: const [], presentation: .dialog, onDismiss: () {}),
      );
      final field = find.byType(TextField);
      final row = find.ancestor(of: field, matching: find.byType(Row)).first;
      expect(
        find.descendant(of: row, matching: find.byType(Kbd)),
        findsOneWidget,
      );
    });

    testWidgets('names nothing when it cannot be dismissed, or inline', (
      tester,
    ) async {
      for (final (presentation, dismiss) in [
        (CoreCommandPresentation.dialog, false),
        (CoreCommandPresentation.inline, true),
      ]) {
        await pumpTestApp(
          tester,
          Command(
            groups: const [],
            presentation: presentation,
            onDismiss: dismiss ? () {} : null,
          ),
        );
        final row = find
            .ancestor(of: find.byType(TextField), matching: find.byType(Row))
            .first;
        expect(
          find.descendant(of: row, matching: find.byType(Kbd)),
          findsNothing,
        );
      }
    });
  });

  group('Command footer', () {
    testWidgets('a dialog names Escape on its search row, not in its footer', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Command(groups: const [], presentation: .dialog, onDismiss: () {}),
      );
      expect(find.text('Close'), findsNothing);
      // The one `esc` cap is the search row's.
      expect(
        find.byWidgetPredicate((w) => w is Kbd && w.keys.contains('esc')),
        findsOneWidget,
      );
    });

    testWidgets('an inline palette with a footer still names Escape there', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Command(groups: const [], showFooter: true, onDismiss: () {}),
      );
      expect(find.text('Close'), findsOneWidget);
    });
  });
}
