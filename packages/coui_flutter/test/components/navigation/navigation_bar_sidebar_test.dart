import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show SemanticsFlag;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// The layout modes are one component at two densities, and each cell of
/// the per-mode table is read back where it lands — the resolver output
/// and the rendered box — so a mode cell nobody reads fails here rather
/// than reading as a design value that silently does nothing.
Future<ResolvedNavigationBar> _resolve(
  WidgetTester tester,
  CoreNavigationBarMode mode, {
  CoreNavigationBarStyle? style,
}) async {
  late ResolvedNavigationBar resolved;
  await tester.pumpWidget(
    buildTestApp(
      Builder(
        builder: (context) {
          resolved = resolveNavigationBar(
            context,
            mode: mode,
            variant: CoreNavigationBarVariant.defaultVariant,
            navigationBarStyle: style,
          );
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return resolved;
}

Color _token(WidgetTester tester, CoreColorToken token) =>
    _color(tester, CoreColor.token(token));

Color _color(WidgetTester tester, CoreColor color) {
  final context = tester.element(find.byType(SizedBox).first);
  return Theme.of(context).colorScheme.resolve(color).toValue();
}

// The count the docs and the canvas show — the `xs` step is the 18-tall
// count that fits a 36 sidebar row.
const _badge = Badge(
  form: CoreBadgeForm.count,
  tone: CoreBadgeTone.info,
  variant: CoreBadgeVariant.filled,
  size: CoreComponentSize.xs,
  child: Text('3'),
);

Widget _bar(
  CoreNavigationBarMode mode, {
  CoreNavigationLabelMode? labelMode,
  Widget? badge = _badge,
  Widget? footer,
}) {
  return NavigationBar(
    mode: mode,
    labelMode: labelMode,
    selectedIndex: 0,
    onSelected: (_) {},
    footer: footer,
    items: [
      CoreNavigationBarItem.destination(
        icon: const Icon(LucideIcons.inbox, key: ValueKey('icon-0')),
        label: 'Inbox',
        badge: badge == null
            ? null
            : KeyedSubtree(key: const ValueKey('badge'), child: badge),
      ),
      const CoreNavigationBarItem.label('Workspace'),
      const CoreNavigationBarItem.destination(
        icon: Icon(LucideIcons.search),
        label: 'Search',
        enabled: false,
      ),
    ],
  );
}

void main() {
  group('the per-mode density table reaches the resolver', () {
    testWidgets('sidebar draws its own density', (tester) async {
      final resolved = await _resolve(tester, CoreNavigationBarMode.sidebar);
      final typography = Theme.of(
        tester.element(find.byType(SizedBox).first),
      ).typography;

      expect(
        resolved.padding,
        const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      );
      expect(resolved.itemSpacing, 2);
      expect(resolved.itemMinHeight, 40);
      expect(
        resolved.itemPadding,
        const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      );
      expect(resolved.iconSize, 20);
      expect(resolved.labelSpacing, 10);
      for (final style in [
        resolved.labelTextStyle,
        resolved.selectedLabelTextStyle,
        resolved.disabledLabelTextStyle,
      ]) {
        expect(style.fontSize, typography.labelLarge.fontSize);
      }
      // The role moved; the per-state weights stayed where they were —
      // bold selected, medium resting (#6358).
      expect(
        resolved.selectedLabelTextStyle.fontWeight,
        fontWeightFromInt(CoreFontWeight.bold),
      );
      expect(
        resolved.labelTextStyle.fontWeight,
        fontWeightFromInt(CoreFontWeight.medium),
      );
      // A row's face is the selected tile face every placement paints
      // (#6358).
      expect(
        resolved.selectedBackgroundColor,
        _color(tester, CoreNavigationBarStyle.defaultSelectedFaceColor),
      );
    });

    for (final (mode, padding) in [
      // The bar states its own padding — 8 above and below, 12 at the
      // sides; every other density value is the flat one.
      (
        CoreNavigationBarMode.bar,
        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      (CoreNavigationBarMode.rail, const EdgeInsets.all(8)),
    ]) {
      testWidgets('${mode.name} keeps the flat defaults', (tester) async {
        final resolved = await _resolve(tester, mode);
        final typography = Theme.of(
          tester.element(find.byType(SizedBox).first),
        ).typography;

        expect(resolved.padding, padding);
        expect(resolved.itemMinHeight, 64);
        expect(
          resolved.itemPadding,
          const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        );
        expect(resolved.iconSize, 24);
        expect(resolved.labelSpacing, 4);
        expect(
          resolved.labelTextStyle.fontSize,
          typography.labelSmall.fontSize,
        );
        // The rail (`fill`) paints the selected tile face (#6358); the bar
        // (`color`) paints none (#6393).
        if (mode == CoreNavigationBarMode.rail) {
          expect(
            resolved.selectedBackgroundColor,
            _color(tester, CoreNavigationBarStyle.defaultSelectedFaceColor),
          );
        } else {
          expect(resolved.selectedBackgroundColor.a, 0);
        }
      });
    }

    testWidgets('an instance value outranks the mode cell', (tester) async {
      final resolved = await _resolve(
        tester,
        CoreNavigationBarMode.sidebar,
        style: const CoreNavigationBarStyle(
          padding: CoreEdgeInsets.all(CoreSpace.space4),
          itemMinHeight: CoreSize.size40,
          itemPadding: CoreEdgeInsets.all(CoreSpace.space6),
          iconStyle: CoreIconStyle(size: CoreIconSize.size20),
          labelSpacing: CoreSpace.space8,
          labelTextStyle: CoreTextStyle.token(CoreTextStyles.labelMedium),
          selectedBackgroundColor: CoreColor.token(CoreColors.surface),
        ),
      );
      final typography = Theme.of(
        tester.element(find.byType(SizedBox).first),
      ).typography;

      expect(resolved.padding, const EdgeInsets.all(4));
      expect(resolved.itemMinHeight, 40);
      expect(resolved.itemPadding, const EdgeInsets.all(6));
      expect(resolved.iconSize, 20);
      expect(resolved.labelSpacing, 8);
      expect(
        resolved.selectedBackgroundColor,
        _token(tester, CoreColors.surface),
      );
      // The instance's role reaches the slot it states; the other states keep
      // the mode cell's role.
      expect(
        resolved.labelTextStyle.fontSize,
        typography.labelMedium.fontSize,
      );
      expect(
        resolved.selectedLabelTextStyle.fontSize,
        typography.labelLarge.fontSize,
      );
    });
  });

  group('the bar reads its own tones', () {
    for (final mode in CoreNavigationBarMode.values) {
      // The bottom bar sits on the page's own tone (its mode cell); the rail
      // and the sidebar on the chrome tier (the variant face).
      final face = mode == CoreNavigationBarMode.bar
          ? CoreColors.surface
          : CoreColors.surfaceContainerLow;
      testWidgets('${mode.name} sits on ${face.name}', (tester) async {
        final resolved = await _resolve(tester, mode);

        expect(resolved.backgroundColor, _token(tester, face));
        expect(
          resolved.disabledForegroundColor,
          _token(tester, CoreColors.disabledContent),
        );
        expect(
          resolved.disabledIconColor,
          _token(tester, CoreColors.disabledContent),
        );
        expect(
          resolved.sectionLabelTextStyle.color,
          _token(tester, CoreColors.onSurfaceSubtle),
        );
        expect(
          resolved.sectionLabelPadding,
          const EdgeInsets.fromLTRB(10, 18, 10, 6),
        );
      });
    }

    testWidgets('a disabled destination paints its icon in the disabled tone', (
      tester,
    ) async {
      Color? enabledIcon;
      Color? disabledIcon;
      await pumpTestApp(
        tester,
        SizedBox(
          width: 240,
          child: NavigationBar(
            mode: CoreNavigationBarMode.sidebar,
            onSelected: (_) {},
            items: [
              CoreNavigationBarItem.destination(
                icon: Builder(
                  builder: (context) {
                    enabledIcon = IconTheme.of(context).color;
                    return const SizedBox.square(dimension: 18);
                  },
                ),
                label: 'Inbox',
              ),
              CoreNavigationBarItem.destination(
                icon: Builder(
                  builder: (context) {
                    disabledIcon = IconTheme.of(context).color;
                    return const SizedBox.square(dimension: 18);
                  },
                ),
                label: 'Search',
                enabled: false,
              ),
            ],
          ),
        ),
      );

      expect(enabledIcon, _token(tester, CoreColors.onSurfaceSubtle));
      expect(disabledIcon, _token(tester, CoreColors.disabledContent));
    });

    testWidgets('a section header is inset by its own padding', (tester) async {
      await pumpTestApp(
        tester,
        SizedBox(width: 240, child: _bar(CoreNavigationBarMode.sidebar)),
      );
      final padding = tester.widget<Padding>(
        find
            .ancestor(
              of: find.text('Workspace'),
              matching: find.byType(Padding),
            )
            .first,
      );

      expect(padding.padding, const EdgeInsets.fromLTRB(10, 18, 10, 6));
    });
  });

  group('a destination badge', () {
    testWidgets('sits at the trailing end of a sidebar row', (tester) async {
      await pumpTestApp(
        tester,
        SizedBox(width: 240, child: _bar(CoreNavigationBarMode.sidebar)),
      );
      final row = tester.getRect(
        find
            .ancestor(
              of: find.byKey(const ValueKey('badge')),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final badge = tester.getRect(find.byKey(const ValueKey('badge')));
      final label = tester.getRect(find.text('Inbox'));

      expect(row.height, 40);
      // The row's own end inset, not just "somewhere right of the label".
      expect(badge.right, closeTo(row.right - 12, 0.01));
      expect(badge.left, greaterThan(label.right));
    });

    for (final mode in [
      CoreNavigationBarMode.bar,
      CoreNavigationBarMode.rail,
    ]) {
      testWidgets("lies over the icon's top-end corner in the ${mode.name}", (
        tester,
      ) async {
        await pumpTestApp(
          tester,
          SizedBox(width: 320, height: 400, child: _bar(mode)),
        );
        final icon = tester.getRect(find.byKey(const ValueKey('icon-0')));
        final badge = tester.getRect(find.byKey(const ValueKey('badge')));

        // Pulled out of the glyph by the indicator offset on both edges.
        expect(badge.right, closeTo(icon.right + 6, 0.01));
        expect(badge.top, closeTo(icon.top - 6, 0.01));
      });
    }
  });

  group('the footer', () {
    testWidgets('lands on the far edge inside the sidebar chrome', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        SizedBox(
          width: 240,
          height: 480,
          child: _bar(
            CoreNavigationBarMode.sidebar,
            footer: const SizedBox(key: ValueKey('footer'), height: 40),
          ),
        ),
      );
      final bar = tester.getRect(find.byType(NavigationBar));
      final footer = tester.getRect(find.byKey(const ValueKey('footer')));

      expect(footer.bottom, closeTo(bar.bottom - 16, 0.01));
      expect(footer.left, closeTo(bar.left + 12, 0.01));
      // Inside the end-side hairline, which the chrome draws on the bar.
      expect(footer.right, lessThanOrEqualTo(bar.right - 12));
    });

    testWidgets('is as tall as items and footer together when the height is '
        'not pinned', (tester) async {
      await pumpTestApp(
        tester,
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240, maxHeight: 800),
          child: _bar(
            CoreNavigationBarMode.sidebar,
            footer: const SizedBox(key: ValueKey('footer'), height: 40),
          ),
        ),
      );
      final bar = tester.getRect(find.byType(NavigationBar));
      final footer = tester.getRect(find.byKey(const ValueKey('footer')));
      final lastItem = tester.getRect(find.text('Search'));

      // A loose bound is room the bar may use, not room it must fill.
      expect(bar.height, lessThan(400));
      expect(footer.bottom, closeTo(bar.bottom - 16, 0.01));
      expect(footer.top, greaterThan(lastItem.bottom));
    });

    testWidgets('scrolls its items and keeps the footer in place once the '
        'bounds run out', (tester) async {
      await pumpTestApp(
        tester,
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240, maxHeight: 120),
          child: _bar(
            CoreNavigationBarMode.sidebar,
            footer: const SizedBox(key: ValueKey('footer'), height: 40),
          ),
        ),
      );
      final bar = tester.getRect(find.byType(NavigationBar));
      final footer = tester.getRect(find.byKey(const ValueKey('footer')));

      expect(bar.height, 120);
      expect(footer.bottom, closeTo(bar.bottom - 16, 0.01));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('takes the trailing end of a horizontal bar', (tester) async {
      await pumpTestApp(
        tester,
        SizedBox(
          width: 360,
          child: _bar(
            CoreNavigationBarMode.bar,
            footer: const SizedBox(key: ValueKey('footer'), width: 48),
          ),
        ),
      );
      final bar = tester.getRect(find.byType(NavigationBar));
      final footer = tester.getRect(find.byKey(const ValueKey('footer')));

      expect(footer.right, closeTo(bar.right - 12, 0.01));
      expect(tester.takeException(), isNull);
    });
  });

  group('the docked bar consumes the bottom safe area', () {
    const inset = EdgeInsets.only(bottom: 34);

    Future<ResolvedNavigationBar> resolveUnder(
      WidgetTester tester,
      CoreNavigationBarMode mode, {
      EdgeInsets padding = inset,
      EdgeInsets viewPadding = inset,
      bool wrapInSafeArea = false,
      CoreNavigationBarStyle? style,
    }) async {
      late ResolvedNavigationBar resolved;
      final probe = Builder(
        builder: (context) {
          resolved = resolveNavigationBar(
            context,
            mode: mode,
            variant: CoreNavigationBarVariant.defaultVariant,
            navigationBarStyle: style,
          );
          return const SizedBox.shrink();
        },
      );
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(padding: padding, viewPadding: viewPadding),
              child: wrapInSafeArea ? SafeArea(child: probe) : probe,
            ),
          ),
        ),
      );
      return resolved;
    }

    testWidgets('the inset joins the bar bottom padding', (tester) async {
      final resolved = await resolveUnder(tester, CoreNavigationBarMode.bar);

      expect(resolved.padding, const EdgeInsets.fromLTRB(12, 8, 12, 8 + 34));
    });

    testWidgets('an ancestor SafeArea has consumed it — not added twice', (
      tester,
    ) async {
      final resolved = await resolveUnder(
        tester,
        CoreNavigationBarMode.bar,
        wrapInSafeArea: true,
      );

      expect(
        resolved.padding,
        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      );
    });

    testWidgets('a keyboard over the indicator leaves nothing to add', (
      tester,
    ) async {
      // `padding` drops the part the keyboard covers; `viewPadding` keeps it.
      final resolved = await resolveUnder(
        tester,
        CoreNavigationBarMode.bar,
        padding: EdgeInsets.zero,
      );

      expect(resolved.padding.bottom, 8);
    });

    for (final (mode, stated) in [
      (CoreNavigationBarMode.rail, const EdgeInsets.all(8)),
      (
        CoreNavigationBarMode.sidebar,
        const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      ),
    ]) {
      testWidgets('${mode.name} takes none', (tester) async {
        final resolved = await resolveUnder(tester, mode);

        expect(resolved.padding, stated);
      });
    }

    testWidgets('a bar detached by barMargin takes none', (tester) async {
      final resolved = await resolveUnder(
        tester,
        CoreNavigationBarMode.bar,
        style: const CoreNavigationBarStyle(
          barMargin: CoreEdgeInsets.all(CoreSpace.space8),
        ),
      );

      expect(resolved.padding.bottom, 8);
    });

    testWidgets('the face paints under the indicator', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(padding: inset, viewPadding: inset),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: 360,
                  child: _bar(CoreNavigationBarMode.bar),
                ),
              ),
            ),
          ),
        ),
      );
      final bar = tester.getRect(find.byType(NavigationBar));
      final destination = tester.getRect(
        find.byKey(const ValueKey('icon-0')),
      );

      // 8 + 64 + 8 + the 34 inset, and the destinations above the inset.
      // The top hairline lies over the top padding rather than adding to
      // it, and the bar names its destinations by default, so each is the
      // 64-tall labelled one (#5740).
      expect(bar.height, 8 + 64 + 8 + 34);
      expect(destination.bottom, lessThanOrEqualTo(bar.bottom - 34 - 8));
      expect(tester.takeException(), isNull);
    });
  });

  group('a destination is announced once', () {
    // One destination is one button node with its name said once — the
    // nested button and the label read twice were the same defect.
    for (final mode in CoreNavigationBarMode.values) {
      for (final labelMode in [
        CoreNavigationLabelMode.all,
        CoreNavigationLabelMode.none,
      ]) {
        testWidgets('${mode.name} / labels ${labelMode.name}', (tester) async {
          final handle = tester.ensureSemantics();
          await pumpTestApp(
            tester,
            SizedBox(
              width: 320,
              height: 400,
              child: _bar(mode, labelMode: labelMode),
            ),
          );

          final buttons = find.semantics.byFlag(SemanticsFlag.isButton);
          final labels = [
            for (final node in buttons.evaluate()) node.label,
          ];
          expect(labels, ['Inbox\n3', 'Search']);
          handle.dispose();
        });
      }
    }

    testWidgets('without a badge the name is the label alone', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTestApp(
        tester,
        SizedBox(
          width: 240,
          child: _bar(
            CoreNavigationBarMode.sidebar,
            labelMode: CoreNavigationLabelMode.all,
            badge: null,
          ),
        ),
      );

      expect(
        find.semantics.byFlag(SemanticsFlag.isButton).evaluate().first.label,
        'Inbox',
      );
      expect(
        tester.getSemantics(find.text('Inbox')),
        matchesSemantics(
          label: 'Inbox',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          isSelected: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          isImage: true,
        ),
      );
      handle.dispose();
    });
  });
}
