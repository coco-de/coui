import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('Alert', () {
    testWidgets('renders with title and description', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Alert(
            description: 'Alert content',
            title: 'Alert title',
          ),
        ),
      );

      expect(find.byType(Alert), findsOneWidget);
      expect(find.text('Alert title'), findsOneWidget);
      expect(find.text('Alert content'), findsOneWidget);
    });

    testWidgets('renders with title and description text', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Alert(title: 'Only title', description: 'Body'),
        ),
      );

      expect(find.byType(Alert), findsOneWidget);
      expect(find.text('Only title'), findsOneWidget);
    });

    testWidgets('renders with only description', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Alert(title: 'Only content'),
        ),
      );

      expect(find.byType(Alert), findsOneWidget);
      expect(find.text('Only content'), findsOneWidget);
    });

    testWidgets('renders Alert.destructive', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Alert.destructive(
            description: 'Destructive content',
            title: 'Destructive title',
          ),
        ),
      );

      expect(find.byType(Alert), findsOneWidget);
      expect(find.text('Destructive title'), findsOneWidget);
      expect(find.text('Destructive content'), findsOneWidget);
    });

    test('default variant is not destructive', () {
      const alert = Alert(title: 'Title', description: 'Body');

      expect(alert.variant, isNot(equals(CoreAlertVariant.destructive)));
    });

    test('destructive constructor sets the destructive variant', () {
      const alert = Alert.destructive(title: 'Title', description: 'Body');

      expect(alert.variant, equals(CoreAlertVariant.destructive));
    });
  });

  group('layout and leading', () {
    // A real CoUI app — the resolver reads the scheme, the scaling and the
    // geometry, and the bare `ThemeData()` above carries none of the
    // brightness a colour assertion needs.
    Future<void> pump(
      WidgetTester tester,
      material.Widget alert, {
      double width = 420,
    }) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: material.Center(
            child: material.SizedBox(width: width, child: alert),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    test('the default layout is stacked', () {
      expect(const Alert(title: 'Title').layout, CoreAlertLayout.stacked);
    });

    testWidgets('the inline strip does not draw the description', (
      tester,
    ) async {
      await pump(
        tester,
        const Alert(
          layout: CoreAlertLayout.inline,
          title: 'Strip title',
          description: 'Never drawn inline',
        ),
      );

      expect(find.text('Strip title'), findsOneWidget);
      expect(find.text('Never drawn inline'), findsNothing);
    });

    testWidgets('the stacked panel still draws it', (tester) async {
      await pump(
        tester,
        const Alert(title: 'Panel title', description: 'Drawn stacked'),
      );

      expect(find.text('Drawn stacked'), findsOneWidget);
    });

    testWidgets('the inline title stays on one line and ellipsizes', (
      tester,
    ) async {
      const long =
          'A status line long enough that it cannot fit the strip at this '
          'width and has to end in an ellipsis instead of wrapping';
      await pump(
        tester,
        const Alert(layout: CoreAlertLayout.inline, title: long),
        width: 240,
      );

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(long),
      );
      expect(paragraph.maxLines, 1);
      expect(paragraph.overflow, material.TextOverflow.ellipsis);
      // Rendered, not just configured: the text really was cut short.
      expect(paragraph.didExceedMaxLines, isTrue);
    });

    testWidgets('a stacked title wraps freely', (tester) async {
      const long =
          'A title long enough that it cannot fit one line at this width '
          'and so wraps onto a second line inside the panel';
      await pump(tester, const Alert(title: long), width: 240);

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text(long),
      );
      expect(paragraph.maxLines, isNull);
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    testWidgets('leading replaces the tone glyph', (tester) async {
      await pump(
        tester,
        const Alert(
          variant: CoreAlertVariant.info,
          title: 'Title',
          leading: material.SizedBox(
            key: material.ValueKey('lead'),
            width: 24,
            height: 24,
          ),
        ),
      );

      expect(find.byKey(const material.ValueKey('lead')), findsOneWidget);
      // The alert draws the leading widget instead of its glyph, not as
      // well as it — no icon is left in the row.
      expect(find.byType(Icon), findsNothing);
    });

    for (final (layout, size) in [
      (CoreAlertLayout.stacked, CoreAlertStyle.defaultIconStyle.size!),
      (
        CoreAlertLayout.inline,
        CoreAlertStyle
            .defaultsByLayout[CoreAlertLayout.inline]!
            .iconStyle!
            .size!,
      ),
    ]) {
      testWidgets(
        'a bare icon as leading takes the glyph colour and the '
        '${layout.name} glyph size',
        (tester) async {
          await pump(
            tester,
            Alert(
              variant: CoreAlertVariant.info,
              layout: layout,
              title: 'Title',
              leading: const Icon(LucideIcons.star),
            ),
          );

          final context = tester.element(find.byType(Alert));
          final theme = Theme.of(context);
          final expected = theme.colorScheme
              .resolve(
                CoreAlertStyle
                    .defaultsByVariant[CoreAlertVariant.info]!
                    .iconColor,
              )
              .toValue();
          final ambient = material.IconTheme.of(
            tester.element(find.byType(Icon)),
          );
          expect(ambient.color, expected);
          expect(ambient.size, size * theme.scaling);
        },
      );
    }

    // What each layout's row says has to be what is drawn. The core tests
    // read the table and `banner_alert_height_test` measures the box; neither
    // would notice a resolver that read the stacked constants (or the other
    // layout's row) for a field, so the drawn title and the drawn spacing
    // are read back here.
    for (final (layout, role, colour, weight) in [
      (
        CoreAlertLayout.stacked,
        CoreTextStyles.labelLarge,
        CoreColors.onSurface,
        material.FontWeight.w600,
      ),
      (
        CoreAlertLayout.inline,
        CoreTextStyles.bodySmall,
        CoreColors.onSurfaceVariant,
        null,
      ),
    ]) {
      testWidgets('the ${layout.name} title is drawn in its own role and '
          'colour', (tester) async {
        await pump(tester, Alert(layout: layout, title: 'Role and colour'));

        final theme = Theme.of(tester.element(find.byType(Alert)));
        final roleStyle = switch (role) {
          CoreTextStyles.labelLarge => theme.typography.labelLarge,
          CoreTextStyles.bodySmall => theme.typography.bodySmall,
          _ => fail('the table pins no other role here'),
        };
        final drawn = material.DefaultTextStyle.of(
          tester.element(find.text('Role and colour')),
        ).style;

        expect(drawn.fontSize, roleStyle.fontSize);
        expect(
          drawn.color,
          theme.colorScheme.resolve(CoreColor.token(colour)).toValue(),
        );
        expect(
          drawn.fontWeight,
          weight ?? fontWeightFromInt(roleStyle.fontWeight),
        );
        // The two roles differ in size, so a swap between the layout rows
        // cannot hide behind equal numbers.
        expect(
          theme.typography.labelLarge.fontSize,
          isNot(theme.typography.bodySmall.fontSize),
        );
      });
    }

    for (final (layout, start, vertical, gap) in [
      (CoreAlertLayout.stacked, 16.0, null, 12.0),
      (CoreAlertLayout.inline, 14.0, 10.0, 10.0),
    ]) {
      testWidgets('the ${layout.name} row pads and spaces as its row says', (
        tester,
      ) async {
        await pump(
          tester,
          Alert(
            layout: layout,
            title: 'Measured',
            leading: const material.SizedBox(
              key: material.ValueKey('lead'),
              width: 24,
              height: 24,
            ),
          ),
        );

        final scaling = Theme.of(tester.element(find.byType(Alert))).scaling;
        final alert = tester.getRect(find.byType(Alert));
        final lead = tester.getRect(
          find.byKey(const material.ValueKey('lead')),
        );
        final title = tester.getRect(find.text('Measured'));

        // Leading edge, then the space between the slot and the title.
        expect(lead.left - alert.left, moreOrLessEquals(start * scaling));
        expect(title.left - lead.right, moreOrLessEquals(gap * scaling));
        // The inline strip holds nothing open, so the slot sits exactly the
        // row's vertical padding below the top. The stacked panel's floor
        // centres its row instead, so only the strip is read here.
        if (vertical != null) {
          expect(lead.top - alert.top, moreOrLessEquals(vertical * scaling));
        }
      });
    }

    test('the glyph slot is on by default, from the contract', () {
      expect(const Alert(title: 'Title').showIcon, isTrue);
      expect(CoreAlertContract.defaultShowIcon, isTrue);
      expect(const Alert.success(title: 'Title').showIcon, isTrue);
    });

    for (final layout in CoreAlertLayout.values) {
      testWidgets('showIcon: false drops the ${layout.name} glyph and the gap '
          'after it — the title starts at the panel inset', (tester) async {
        await pump(
          tester,
          Alert(
            variant: CoreAlertVariant.success,
            layout: layout,
            title: 'Text only',
            showIcon: false,
          ),
        );

        expect(find.byType(Icon), findsNothing);
        final scaling = Theme.of(tester.element(find.byType(Alert))).scaling;
        final start = CoreAlertStyle.defaultsByLayout[layout]!.padding!.left!;
        final alert = tester.getRect(find.byType(Alert));
        final title = tester.getRect(find.text('Text only'));
        expect(title.left - alert.left, moreOrLessEquals(start * scaling));
      });
    }

    testWidgets('showIcon: false hides a caller\'s leading too — it is the '
        'same slot', (tester) async {
      await pump(
        tester,
        const Alert(
          title: 'Title',
          showIcon: false,
          leading: material.SizedBox(
            key: material.ValueKey('lead'),
            width: 24,
            height: 24,
          ),
        ),
      );

      expect(find.byKey(const material.ValueKey('lead')), findsNothing);
    });

    testWidgets('showIcon: false keeps the action and the dismiss mark', (
      tester,
    ) async {
      await pump(
        tester,
        Alert(
          title: 'Title',
          showIcon: false,
          action: const material.SizedBox(
            key: material.ValueKey('action'),
            width: 40,
            height: 24,
          ),
          onDismiss: () {},
        ),
      );

      expect(find.byKey(const material.ValueKey('action')), findsOneWidget);
      expect(find.byType(Button), findsOneWidget);
      expect(find.byType(Icon), findsOneWidget); // the dismiss mark's ✕
    });

    testWidgets('a theme variantStyles titleColor carries the tone into the '
        'title of a glyph-less alert', (tester) async {
      const tone = CoreColor.token(CoreColors.onSuccessContainer);
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light).copyWith(
            coreComponentTheme: () => const CoreComponentTheme(
              alert: CoreAlertTheme(
                variantStyles: {
                  CoreAlertVariant.success: CoreAlertStyle(titleColor: tone),
                },
              ),
            ),
          ),
          home: const material.Center(
            child: material.SizedBox(
              width: 420,
              child: material.Column(
                mainAxisSize: material.MainAxisSize.min,
                children: [
                  Alert.success(title: 'Toned', showIcon: false),
                  Alert(title: 'Untoned', showIcon: false),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byType(Alert).first));
      Color? drawn(String text) => material.DefaultTextStyle.of(
        tester.element(find.text(text)),
      ).style.color;
      expect(drawn('Toned'), theme.colorScheme.resolve(tone).toValue());
      // `neutral` states no title colour of its own and keeps the layout's.
      expect(
        drawn('Untoned'),
        theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.onSurface))
            .toValue(),
      );
    });

    test('copyWith carries layout, leading and showIcon', () {
      const leading = material.SizedBox();
      final copy = const Alert(
        title: 'Title',
        layout: CoreAlertLayout.inline,
        leading: leading,
        showIcon: false,
      ).copyWith(title: 'New');

      expect(copy.layout, CoreAlertLayout.inline);
      expect(copy.leading, same(leading));
      expect(copy.showIcon, isFalse);
      expect(copy.copyWith(showIcon: true).showIcon, isTrue);
    });
  });

  group('title colour precedence', () {
    testWidgets('titleColor outranks foregroundColor', (tester) async {
      // Web and Flutter used to answer this the opposite way round — one
      // platform painted the title in `foregroundColor`, the other in
      // `titleColor`. Both now let the title-specific field win.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: const material.Center(
            child: material.SizedBox(
              width: 420,
              child: Alert(
                title: 'Title',
                alertStyle: CoreAlertStyle(
                  titleColor: CoreColor.token(CoreColors.primary),
                  foregroundColor: CoreColor.token(CoreColors.error),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byType(Alert)));
      final style = material.DefaultTextStyle.of(
        tester.element(find.text('Title')),
      ).style;
      expect(
        style.color,
        theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.primary))
            .toValue(),
      );
    });
  });

  group('AlertStyleChain', () {
    test(
      'withStyle merges patch into alertStyle and preserves other fields',
      () {
        var dismissed = false;
        final alert = Alert(
          description: 'Body',
          title: 'Title',
          variant: CoreAlertVariant.success,
          onDismiss: () => dismissed = true,
        );

        final patched = alert.withStyle(
          const CoreAlertStyle(borderWidth: 3),
        );

        expect(patched.description, 'Body');
        expect(patched.title, 'Title');
        expect(patched.variant, CoreAlertVariant.success);
        expect(patched.alertStyle?.borderWidth, 3);
        patched.onDismiss?.call();
        expect(dismissed, isTrue);
      },
    );

    test('copyWith replaces only the given fields', () {
      var dismissed = false;
      final alert = Alert(
        description: 'Body',
        title: 'Title',
        variant: CoreAlertVariant.success,
        onDismiss: () => dismissed = true,
      );

      final copy = alert.copyWith(title: 'New title');

      expect(copy.title, 'New title');
      expect(copy.description, 'Body');
      expect(copy.variant, CoreAlertVariant.success);
      copy.onDismiss?.call();
      expect(dismissed, isTrue);
    });
  });
}
