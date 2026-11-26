import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('Breadcrumb', () {
    testWidgets('renders with items', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Breadcrumb(
            items: [
              CoreBreadcrumbItem(label: 'Home'),
              CoreBreadcrumbItem(label: 'Products'),
              CoreBreadcrumbItem(label: 'Electronics'),
            ],
          ),
        ),
      );

      expect(find.byType(Breadcrumb), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Electronics'), findsOneWidget);
    });

    testWidgets('renders with single item', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const Breadcrumb(
            items: [CoreBreadcrumbItem(label: 'Home')],
          ),
        ),
      );

      expect(find.byType(Breadcrumb), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('invokes onItemTap when a link item is tapped', (
      tester,
    ) async {
      int? tappedIndex;

      final _ = await tester.pumpWidget(
        _buildApp(
          Breadcrumb(
            onItemTap: (index) {
              tappedIndex = index;
            },
            items: const [
              CoreBreadcrumbItem(label: 'Home'),
              CoreBreadcrumbItem(label: 'Details'),
            ],
          ),
        ),
      );

      // The non-last items are interactive links.
      await tester.tap(find.text('Home'));
      await tester.pump();

      expect(tappedIndex, equals(0));
    });
  });

  group('Breadcrumb redesign (#5965)', () {
    const items = [
      CoreBreadcrumbItem(label: 'Home'),
      CoreBreadcrumbItem(label: 'Library'),
      CoreBreadcrumbItem(label: 'Data'),
    ];

    ColorScheme schemeOf(WidgetTester tester) =>
        Theme.of(tester.element(find.byType(Breadcrumb))).colorScheme;

    testWidgets('link items are 14 Regular on-surface-variant, the current '
        'item 14 Medium on-surface', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(Breadcrumb(items: items, onItemTap: (_) {})),
      );
      final scheme = schemeOf(tester);

      final link = tester
          .widget<material.AnimatedDefaultTextStyle>(
            find.ancestor(
              of: find.text('Home'),
              matching: find.byType(material.AnimatedDefaultTextStyle),
            ),
          )
          .style;
      expect(link.fontSize, 14);
      expect(link.fontWeight, material.FontWeight.w400);
      expect(link.height, closeTo(1.5, 1e-6));
      expect(
        link.color,
        scheme
            .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
            .toValue(),
      );

      final current = tester
          .widget<material.AnimatedDefaultTextStyle>(
            find.ancestor(
              of: find.text('Data'),
              matching: find.byType(material.AnimatedDefaultTextStyle),
            ),
          )
          .style;
      expect(current.fontSize, 14);
      expect(current.fontWeight, material.FontWeight.w500);
      expect(current.height, closeTo(1.4, 1e-6));
      expect(
        current.color,
        scheme.resolve(const CoreColor.token(CoreColors.onSurface)).toValue(),
      );
    });

    testWidgets('the focus ring wraps a 25-high item: 21 line + 2/2 inset, '
        '4 between item and chevron', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(Breadcrumb(items: items, onItemTap: (_) {})),
      );

      final home = tester.getRect(
        find.ancestor(of: find.text('Home'), matching: find.byType(Clickable)),
      );
      final text = tester.getRect(find.text('Home'));
      // 2 above / below, 4 to either side of the label.
      expect(home.height, closeTo(text.height + 4, 0.01));
      expect(home.width, closeTo(text.width + 8, 0.01));
      expect(home.height, closeTo(25, 0.5));

      final chevron = tester.getRect(find.byType(Icon).first);
      expect(chevron.left - home.right, closeTo(4, 0.01));
    });

    testWidgets('the item corner the ring is drawn around is 6', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(Breadcrumb(items: items, onItemTap: (_) {})),
      );
      final resolved = resolveBreadcrumb(
        tester.element(find.byType(Breadcrumb)),
        variant: CoreBreadcrumbVariant.defaultVariant,
        enabled: true,
      );
      expect(
        resolved.clickableStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius6),
      );
    });

    testWidgets('the separator is on-surface-subtle', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(Breadcrumb(items: items, onItemTap: (_) {})),
      );
      final resolved = resolveBreadcrumb(
        tester.element(find.byType(Breadcrumb)),
        variant: CoreBreadcrumbVariant.defaultVariant,
        enabled: true,
      );
      expect(
        resolved.separatorIconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
    });

    testWidgets('disabled: every label and the separator take '
        'disabled-content, and nothing is interactive', (tester) async {
      int? tapped;
      final _ = await tester.pumpWidget(
        _buildApp(
          Breadcrumb(
            items: items,
            enabled: false,
            onItemTap: (i) => tapped = i,
          ),
        ),
      );
      final scheme = schemeOf(tester);
      final disabled = scheme
          .resolve(const CoreColor.token(CoreColors.disabledContent))
          .toValue();

      for (final label in ['Home', 'Library', 'Data']) {
        final style = tester
            .widget<material.AnimatedDefaultTextStyle>(
              find.ancestor(
                of: find.text(label),
                matching: find.byType(material.AnimatedDefaultTextStyle),
              ),
            )
            .style;
        expect(style.color, disabled, reason: label);
      }
      final resolved = resolveBreadcrumb(
        tester.element(find.byType(Breadcrumb)),
        variant: CoreBreadcrumbVariant.defaultVariant,
        enabled: false,
      );
      expect(
        resolved.separatorIconStyle.color,
        const CoreColor.token(CoreColors.disabledContent),
      );
      expect(find.byType(Clickable), findsNothing);

      await tester.tap(find.text('Home'));
      await tester.pump();
      expect(tapped, isNull);
    });

    testWidgets('enabled follows the handler when unstated', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(const Breadcrumb(items: items)),
      );
      expect(find.byType(Clickable), findsNothing);
      final scheme = schemeOf(tester);
      final style = tester
          .widget<material.AnimatedDefaultTextStyle>(
            find.ancestor(
              of: find.text('Home'),
              matching: find.byType(material.AnimatedDefaultTextStyle),
            ),
          )
          .style;
      expect(
        style.color,
        scheme
            .resolve(const CoreColor.token(CoreColors.disabledContent))
            .toValue(),
      );

      // An explicit `enabled: true` keeps a display-only trail coloured.
      await tester.pumpWidget(
        _buildApp(const Breadcrumb(items: items, enabled: true)),
      );
      final live = tester
          .widget<material.AnimatedDefaultTextStyle>(
            find.ancestor(
              of: find.text('Home'),
              matching: find.byType(material.AnimatedDefaultTextStyle),
            ),
          )
          .style;
      expect(
        live.color,
        scheme
            .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
            .toValue(),
      );
    });
  });
}
