import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Test constants.
const _kCustomPadding = 16.0;
const _kCustomBorderRadius = 8.0;
const _kBannerVariantCount = 5;

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(
      data: const ThemeData(),
      child: material.Material(child: child),
    ),
  );
}

void main() {
  group('Banner', () {
    testWidgets('zero-width rounded border is omitted without hiding content', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Banner(
            message: Text('Visible safety notice'),
            description: Text('Read before continuing'),
            showIcon: false,
            bannerStyle: CoreBannerStyle(
              borderWidth: 0,
              borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Visible safety notice'), findsOneWidget);
      expect(find.text('Read before continuing'), findsOneWidget);
      final surface = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(Banner),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Container && widget.decoration is BoxDecoration,
              ),
            )
            .first,
      );
      expect((surface.decoration! as BoxDecoration).border, isNull);
    });

    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Banner(message: Text('Hello World'))),
      );
      await tester.pump();

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('renders the widget in the tree', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Banner(message: Text('Info message'))),
      );
      await tester.pump();

      expect(find.byType(Banner), findsOneWidget);
    });

    testWidgets('renders with info variant', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Banner(message: Text('Info message'), variant: .info),
        ),
      );
      await tester.pump();

      expect(find.text('Info message'), findsOneWidget);
    });

    testWidgets('renders with warning variant', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Banner(message: Text('Warning message'), variant: .warning),
        ),
      );
      await tester.pump();

      expect(find.text('Warning message'), findsOneWidget);
    });

    testWidgets('renders with destructive variant', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Banner(
            message: Text('Error message'),
            variant: .destructive,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Error message'), findsOneWidget);
    });

    testWidgets('renders with success variant', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Banner(message: Text('Success message'), variant: .success),
        ),
      );
      await tester.pump();

      expect(find.text('Success message'), findsOneWidget);
    });

    testWidgets('renders with default variant', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Banner(message: Text('Neutral message')),
        ),
      );
      await tester.pump();

      expect(find.text('Neutral message'), findsOneWidget);
    });

    testWidgets('renders with description', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Banner(
            message: Text('Custom title'),
            description: Text('Custom description'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Custom title'), findsOneWidget);
      expect(find.text('Custom description'), findsOneWidget);
    });

    testWidgets('renders with action widget', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Banner(
            message: const Text('Message with action'),
            action: material.TextButton(
              onPressed: () {},
              child: const Text('Action'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Message with action'), findsOneWidget);
    });

    testWidgets('a Button action wears the variant foreground', (
      tester,
    ) async {
      // The message, description, icon and dismiss glyph all track the
      // variant. The action used to be the one thing that did not — it
      // kept `plain`'s own label colour, picked for a light neutral
      // surface, which on a solid banner is a dark word on a saturated
      // fill.
      await tester.pumpWidget(
        _buildApp(
          const Banner(
            message: Text('Solid'),
            variant: CoreBannerVariant.destructive,
            emphasis: CoreBannerEmphasis.solid,
            action: Button(child: Text('Retry')),
          ),
        ),
      );
      await tester.pump();

      final button = tester.widget<Button>(find.byType(Button).first);
      expect(
        button.buttonStyle?.foregroundColor,
        const CoreColor.token(CoreColors.onError),
      );
      expect(
        button.buttonStyle?.hoverForegroundColor,
        const CoreColor.token(CoreColors.onError),
      );
    });

    testWidgets('a caller colour on the action still wins', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Banner(
            message: Text('Solid'),
            variant: CoreBannerVariant.success,
            emphasis: CoreBannerEmphasis.solid,
            action: Button(
              buttonStyle: CoreButtonStyle(
                foregroundColor: CoreColor.token(CoreColors.surface),
              ),
              child: Text('Undo'),
            ),
          ),
        ),
      );
      await tester.pump();

      final button = tester.widget<Button>(find.byType(Button).first);
      expect(
        button.buttonStyle?.foregroundColor,
        const CoreColor.token(CoreColors.surface),
      );
    });

    testWidgets('renders dismiss button when onDismiss provided', (
      tester,
    ) async {
      var dismissed = false;

      await tester.pumpWidget(
        _buildApp(
          Banner(
            message: const Text('Dismissible'),
            onDismiss: () {
              dismissed = true;
            },
          ),
        ),
      );
      await tester.pump();

      final dismissFinder = find.byType(Button);
      expect(dismissFinder, findsOneWidget);

      await tester.tap(dismissFinder);
      await tester.pump();

      expect(dismissed, isTrue);
    });

    // #6214: Banner states no close-glyph size, so the ✕ takes the `md`
    // square button's own (`iconShapeIconStyle`, 18) — the glyph Toast's
    // close draws too. Read off the rendered icon, not the style.
    testWidgets('the dismiss glyph is the md square button glyph (18)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(Banner(message: const Text('Dismissible'), onDismiss: () {})),
      );
      await tester.pump();
      final glyph = find.descendant(
        of: find.byType(Button),
        matching: find.byWidgetPredicate(
          (w) => w is Icon && w.icon == LucideIcons.x,
        ),
      );
      expect(glyph, findsOneWidget);
      expect(tester.getSize(glyph), const Size(18, 18));
    });

    testWidgets('the dismiss button is a 40 × 40 circle, not a tall pill', (
      tester,
    ) async {
      // An icon-only affordance is square: on the rectangle shape the
      // 4 px inset around the 20 px glyph drew the hover and pressed wash
      // as a 28 × 40 pill (#6214).
      await tester.pumpWidget(
        _buildApp(Banner(message: const Text('Dismissible'), onDismiss: () {})),
      );
      await tester.pump();

      final button = tester.widget<Button>(find.byType(Button));
      expect(button.shape, CoreButtonShape.square);
      expect(tester.getSize(find.byType(Button)), const Size(40, 40));
    });

    testWidgets('a plain action is 8 wider than its label on each side', (
      tester,
    ) async {
      // `plain` sits flush with its label, so on a banner the wash was the
      // word wide — a highlighter stroke rather than a button (#6214).
      await tester.pumpWidget(
        _buildApp(
          const Banner(
            message: Text('With action'),
            action: Button(
              size: CoreComponentSize.sm,
              variant: CoreButtonVariant.plain,
              child: Text('Retry'),
            ),
          ),
        ),
      );
      await tester.pump();

      final button = tester.getSize(find.byType(Button));
      final label = tester.getSize(find.text('Retry'));
      expect(button.width - label.width, CoreSpace.space8 * 2);
      expect(button.height, CoreControlSize.heightSm);
    });

    testWidgets('an outline action keeps its own inset inside a banner', (
      tester,
    ) async {
      // The inline inset is `plain`'s alone: an `sm` outline is as wide in a
      // banner as outside one, so Button's size row stays the one place its
      // inset is decided (#6214).
      const outline = Button(
        size: CoreComponentSize.sm,
        variant: CoreButtonVariant.outline,
        child: Text('Retry'),
      );
      await tester.pumpWidget(_buildApp(const material.Center(child: outline)));
      await tester.pump();
      final alone = tester.getSize(find.byType(Button)).width;

      await tester.pumpWidget(
        _buildApp(const Banner(message: Text('With action'), action: outline)),
      );
      await tester.pump();
      expect(tester.getSize(find.byType(Button)).width, alone);
    });

    testWidgets('does not render dismiss button when onDismiss is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Banner(message: Text('No dismiss')),
        ),
      );
      await tester.pump();

      expect(find.byType(Button), findsNothing);
    });

    testWidgets('showIcon false hides default icon', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Banner(
            message: Text('No icon'),
            showIcon: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('No icon'), findsOneWidget);
    });

    testWidgets('renders with custom padding via bannerStyle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Banner(
            message: Text('Custom padding'),
            bannerStyle: CoreBannerStyle(
              padding: CoreEdgeInsets.all(_kCustomPadding),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Custom padding'), findsOneWidget);
    });

    testWidgets('renders with custom border radius via bannerStyle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Banner(
            message: Text('Custom radius'),
            bannerStyle: CoreBannerStyle(
              borderRadius: CoreBorderRadius.circular(_kCustomBorderRadius),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Custom radius'), findsOneWidget);
    });
  });

  group('CoreBannerVariant', () {
    test('has all expected variants', () {
      expect(CoreBannerVariant.values, hasLength(_kBannerVariantCount));
      expect(
        CoreBannerVariant.values,
        containsAll([
          CoreBannerVariant.neutral,
          CoreBannerVariant.info,
          CoreBannerVariant.warning,
          CoreBannerVariant.destructive,
          CoreBannerVariant.success,
        ]),
      );
    });
  });
}
