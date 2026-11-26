import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

const _kTestBorderWidth = 2.0;
const _kSurfaceBlur = 10.0;
const _kTestFillColor = CoreColor(0xFFFFFFFF);
const _kTestBorderColor = CoreColor(0xFF000000);
const _kTestBorderRadius = CoreBorderRadius.circular(8);

void main() {
  group('CoreCardStyle', () {
    test('constructor with defaults', () {
      const style = CoreCardStyle();

      expect(style.borderRadius, isNull);
      expect(style.padding, isNull);
      expect(style.backgroundColor, isNull);
      expect(style.borderColor, isNull);
      expect(style.borderWidth, isNull);
    });

    test('constructor with values', () {
      const style = CoreCardStyle(
        backgroundColor: _kTestFillColor,
        borderColor: _kTestBorderColor,
        borderWidth: 1,
        borderRadius: _kTestBorderRadius,
        padding: CoreEdgeInsets.all(8),
      );

      expect(style.borderRadius, _kTestBorderRadius);
      expect(style.padding, const CoreEdgeInsets.all(8));
      expect(style.backgroundColor, _kTestFillColor);
      expect(style.borderColor, _kTestBorderColor);
      expect(style.borderWidth, 1);
    });

    test('copyWith preserves values when no overrides', () {
      const original = CoreCardStyle(
        borderWidth: 1,
        borderRadius: _kTestBorderRadius,
      );
      final copy = original.copyWith();

      expect(copy.borderRadius, _kTestBorderRadius);
      expect(copy.borderWidth, 1);
    });

    test('copyWith overrides specified values', () {
      const original = CoreCardStyle(borderRadius: _kTestBorderRadius);
      final copy = original.copyWith(
        borderRadius: const CoreBorderRadius.circular(16),
      );

      expect(copy.borderRadius, const CoreBorderRadius.circular(16));
    });

    test('merge overrides only non-null fields', () {
      const base = CoreCardStyle(borderWidth: 1);
      const override = CoreCardStyle(borderColor: _kTestBorderColor);
      final merged = base.merge(override);

      expect(merged.borderWidth, 1);
      expect(merged.borderColor, _kTestBorderColor);
    });
  });

  group('Card', () {
    testWidgets('renders with child', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(child: material.Text('Card content')),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Card content'), findsOneWidget);
    });

    testWidgets('renders with backgroundColor via cardStyle', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(
            cardStyle: CoreCardStyle(backgroundColor: _kTestFillColor),
            child: material.Text('Filled card'),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Filled card'), findsOneWidget);
    });

    testWidgets('renders with borderRadius via cardStyle', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(
            cardStyle: CoreCardStyle(borderRadius: _kTestBorderRadius),
            child: material.Text('Rounded card'),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders with borderColor via cardStyle', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(
            cardStyle: CoreCardStyle(borderColor: _kTestBorderColor),
            child: material.Text('Bordered card'),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('renders with borderWidth via cardStyle', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(
            cardStyle: CoreCardStyle(borderWidth: _kTestBorderWidth),
            child: material.Text('Thick border card'),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('Card variant', () {
    testWidgets('filled is the default', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(child: material.Text('Default')),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(
        tester.widget<Card>(find.byType(Card)).variant,
        CoreCardVariant.filled,
      );
      final container = tester
          .widget<OutlinedContainer>(find.byType(OutlinedContainer))
          .containerStyle!;
      // The filled row: a flat surfaceContainer face and no edge.
      expect(container.borderWidth, 0);
      expect(container.borderColor, CoreColor.transparent);
      expect(
        container.backgroundColor,
        CoreCardStyle
            .defaultsByVariant[CoreCardVariant.filled]!
            .backgroundColor,
      );
    });

    testWidgets('outlined draws the outlineVariant hairline', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(variant: .outlined, child: material.Text('Outlined')),
        ),
      );

      final container = tester
          .widget<OutlinedContainer>(find.byType(OutlinedContainer))
          .containerStyle!;
      expect(container.borderWidth, CoreCardStyle.defaultOutlinedBorderWidth);
      expect(container.borderColor!.token, CoreColors.outlineVariant);
    });

    testWidgets('outlined variant renders', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(
            variant: .outlined,
            child: material.Text('Outlined'),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('Card elevation', () {
    testWidgets('none renders without shadow', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(
            cardStyle: CoreCardStyle(elevation: CoreCardElevation.none),
            child: material.Text('No shadow'),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('soft renders with shadow', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(
            cardStyle: CoreCardStyle(elevation: CoreCardElevation.soft),
            child: material.Text('Soft shadow'),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('medium renders with shadow', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(
            cardStyle: CoreCardStyle(elevation: CoreCardElevation.medium),
            child: material.Text('Medium shadow'),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('Card sizing', () {
    testWidgets('intrinsic sizes to content', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const material.Center(
            child: Card(
              cardStyle: CoreCardStyle(sizing: CoreCardSizing.intrinsic),
              child: material.Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('expand fills available width', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(
            cardStyle: CoreCardStyle(sizing: CoreCardSizing.expand),
            child: material.Text('Expanded'),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('fixed uses width/height', (tester) async {
      const fixedWidth = 200.0;
      const fixedHeight = 300.0;
      final _ = await tester.pumpWidget(
        _buildApp(
          const material.Center(
            child: Card(
              cardStyle: CoreCardStyle(
                sizing: CoreCardSizing.fixed,
                width: fixedWidth,
                height: fixedHeight,
              ),
              child: material.Text('Fixed'),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('Card slots', () {
    testWidgets('renders media slot', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          Card(
            media: material.Container(
              color: material.Colors.blue,
              height: 100,
            ),
            header: const material.Text('Title'),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('renders header/body/footer slots', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(
            header: material.Text('Header'),
            body: material.Text('Body'),
            footer: material.Text('Footer'),
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
      expect(find.text('Footer'), findsOneWidget);
    });

    testWidgets('overlay renders over media', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          Card(
            media: material.Container(
              color: material.Colors.blue,
              height: 100,
            ),
            overlay: const material.Positioned(
              left: 8,
              top: 8,
              child: material.Text('Badge'),
            ),
          ),
        ),
      );

      expect(find.text('Badge'), findsOneWidget);
    });

    testWidgets('child takes precedence over slots', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(
            header: material.Text('Header'),
            child: material.Text('Child'),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
      expect(find.text('Header'), findsNothing);
    });
  });

  group('Card onTap', () {
    testWidgets('fires callback on tap', (tester) async {
      var tapped = false;
      final _ = await tester.pumpWidget(
        _buildApp(
          Card(
            onTap: () => tapped = true,
            child: const material.Text('Tappable'),
          ),
        ),
      );

      await tester.tap(find.text('Tappable'));
      expect(tapped, isTrue);
    });
  });

  group('Card style', () {
    testWidgets('cardStyle overrides padding', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(
            header: material.Text('Padded'),
            cardStyle: CoreCardStyle(padding: CoreEdgeInsets.all(24)),
          ),
        ),
      );

      expect(find.text('Padded'), findsOneWidget);
    });
  });

  group('Card glassmorphism', () {
    testWidgets('cardStyle.surfaceBlur renders a backdrop blur', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Card(
            cardStyle: CoreCardStyle(surfaceBlur: _kSurfaceBlur),
            child: material.Text('Glass content'),
          ),
        ),
      );

      // The `OutlinedContainer` surface renders glassmorphism via a
      // `BackdropFilter` when `surfaceBlur > 0`.
      expect(find.byType(material.BackdropFilter), findsOneWidget);
      expect(find.text('Glass content'), findsOneWidget);
    });

    testWidgets('no surfaceBlur renders no backdrop blur', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(const Card(child: material.Text('Opaque content'))),
      );

      expect(find.byType(material.BackdropFilter), findsNothing);
    });
  });

  group('CardStyleChain', () {
    test('withStyle merges a patch into cardStyle', () {
      const card = Card(header: material.Text('Title'));

      final patched = card.withStyle(
        const CoreCardStyle(borderRadius: CoreBorderRadius.all(4)),
      );

      expect(patched.cardStyle?.borderRadius, const CoreBorderRadius.all(4));
    });

    test('.radius4 getter sets borderRadius via withStyle', () {
      const card = Card(header: material.Text('Title'));

      final patched = card.radius4;

      expect(
        patched.cardStyle?.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
    });

    test('.surface getter sets backgroundColor via withStyle', () {
      const card = Card(header: material.Text('Title'));

      final patched = card.surface;

      expect(
        patched.cardStyle?.backgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
    });

    test('chained primitive getters compose like withStyle chains', () {
      const card = Card(header: material.Text('Title'));

      final patched = card.radius4.surface;

      expect(
        patched.cardStyle?.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
      expect(
        patched.cardStyle?.backgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
    });
  });
}
