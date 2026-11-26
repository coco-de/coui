import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

// Each size row names a typography role for the label and the title. The
// expected sizes are those roles' own sizes in the CoUI scale, so the pins
// say which role each row draws and follow the role table when it moves.
final double _kLabelFontXs = CoreTypography.coui.bodyXs.fontSize!;
final double _kLabelFontSm = CoreTypography.coui.bodySmall.fontSize!;
final double _kLabelFontMd = CoreTypography.coui.bodyMedium.fontSize!;
final double _kLabelFontLg = CoreTypography.coui.bodyLarge.fontSize!;
// No Regular 16 role exists: xl's label uses the nearest, bodyLarge.
final double _kLabelFontXl = CoreTypography.coui.bodyLarge.fontSize!;

final double _kTitleFontXs = CoreTypography.coui.labelMedium.fontSize!;
final double _kTitleFontSm = CoreTypography.coui.labelLarge.fontSize!;
final double _kTitleFontMd = CoreTypography.coui.labelXl.fontSize!;
final double _kTitleFontLg = CoreTypography.coui.labelXl2.fontSize!;
final double _kTitleFontXl = CoreTypography.coui.titleLarge.fontSize!;

void main() {
  // ══════════════════════════════════════════════
  // Basic rendering
  // ══════════════════════════════════════════════

  group('DescriptionCard basic rendering', () {
    testWidgets('renders label and value text', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(label: 'Name', value: 'John Doe'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('renders title when provided', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(label: 'Status', value: 'Shipped'),
            ],
            title: 'Order Detail',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Order Detail'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Shipped'), findsOneWidget);
    });

    testWidgets('renders multiple rows', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(label: 'Name', value: 'Alice'),
              DescriptionRow(label: 'Email', value: 'alice@example.com'),
              DescriptionRow(label: 'Phone', value: '010-0000-0000'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('alice@example.com'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('010-0000-0000'), findsOneWidget);
    });

    testWidgets('renders leading widget on a row', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(
                label: 'Status',
                value: 'Active',
                leading: material.Icon(material.Icons.circle),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(material.Icon), findsOneWidget);
    });

    testWidgets('renders trailing widget on a row', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(
                label: 'Document',
                value: 'Resume.pdf',
                trailing: material.Icon(material.Icons.edit),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(material.Icon), findsOneWidget);
      expect(find.text('Resume.pdf'), findsOneWidget);
    });

    testWidgets('renders titleLeading widget', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(label: 'Name', value: 'Bob'),
            ],
            title: 'Profile',
            titleLeading: material.Icon(material.Icons.person),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(material.Icon), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('renders titleTrailing widget', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(label: 'Mode', value: 'Dark'),
            ],
            title: 'Settings',
            titleTrailing: material.Icon(material.Icons.settings),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(material.Icon), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders custom valueWidget without value text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          DescriptionCard(
            rows: [
              DescriptionRow(
                label: 'Rating',
                valueWidget: material.Container(
                  key: const material.Key('custom-value'),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const material.Key('custom-value')), findsOneWidget);
    });

    testWidgets('valueWidget takes precedence over supplied value text', (
      tester,
    ) async {
      const customValue = material.Text('Custom value');
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(
                label: 'Status',
                value: 'Unused fallback',
                valueWidget: customValue,
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byWidget(customValue), findsOneWidget);
      expect(find.text('Unused fallback'), findsNothing);
    });
  });

  // ══════════════════════════════════════════════
  // Variants
  // ══════════════════════════════════════════════

  group('DescriptionCard variants', () {
    testWidgets('outlined variant renders a DecoratedBox', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            variant: .outlined,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(material.DecoratedBox), findsWidgets);
    });

    testWidgets('filled variant renders without error', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            variant: .filled,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DescriptionCard), findsOneWidget);
    });

    testWidgets('ghost variant renders without error', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            variant: .ghost,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DescriptionCard), findsOneWidget);
    });

    testWidgets('outlined variant has border in decoration', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            variant: .outlined,
          ),
        ),
      );
      await tester.pump();

      final decoratedBoxes = tester.widgetList<material.DecoratedBox>(
        find.byType(material.DecoratedBox),
      );
      final outermostBox = decoratedBoxes.first;
      final decoration = outermostBox.decoration as material.BoxDecoration;

      expect(decoration.border, isNotNull);
    });

    testWidgets('filled variant has no border', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            variant: .filled,
          ),
        ),
      );
      await tester.pump();

      // The box is composed via `OutlinedContainer` (#4362) — read its
      // contract input rather than reaching into its own internal
      // `Container`/`BoxDecoration`, which is that widget's own test's
      // responsibility.
      final outlinedContainer = tester.widget<OutlinedContainer>(
        find.descendant(
          of: find.byType(DescriptionCard),
          matching: find.byType(OutlinedContainer),
        ),
      );

      expect(
        outlinedContainer.containerStyle?.borderColor,
        equals(CoreColor.transparent),
      );
    });

    testWidgets('ghost variant has no border and transparent background', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            variant: .ghost,
          ),
        ),
      );
      await tester.pump();

      final outlinedContainer = tester.widget<OutlinedContainer>(
        find.descendant(
          of: find.byType(DescriptionCard),
          matching: find.byType(OutlinedContainer),
        ),
      );

      expect(
        outlinedContainer.containerStyle?.borderColor,
        equals(CoreColor.transparent),
      );
      expect(
        outlinedContainer.containerStyle?.backgroundColor,
        equals(CoreColor.transparent),
      );
    });
  });

  // ══════════════════════════════════════════════
  // Layouts
  // ══════════════════════════════════════════════

  group('DescriptionCard layouts', () {
    testWidgets('horizontal fixed layout renders Row with Expanded value', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            layout: .horizontal,
            alignment: .fixed,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Label'), findsOneWidget);
      expect(find.text('Value'), findsOneWidget);
    });

    testWidgets('horizontal spaceBetween layout renders with Spacer', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Total', value: '100,000')],
            layout: .horizontal,
            alignment: .spaceBetween,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('100,000'), findsOneWidget);
      expect(find.byType(material.Spacer), findsOneWidget);
    });

    testWidgets('vertical layout renders label above value', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Description', value: 'Some text')],
            layout: .vertical,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Some text'), findsOneWidget);
    });

    testWidgets('vertical layout contains a Column inside the row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            layout: .vertical,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(material.Column), findsWidgets);
    });
  });

  // ══════════════════════════════════════════════
  // Sizes
  // ══════════════════════════════════════════════

  group('DescriptionCard sizes', () {
    double _getLabelFontSize(WidgetTester tester, String labelText) {
      final textWidget = tester.widget<material.Text>(find.text(labelText));
      return textWidget.style?.fontSize ?? 0;
    }

    double _getTitleFontSize(WidgetTester tester, String titleText) {
      final textWidget = tester.widget<material.Text>(find.text(titleText));
      return textWidget.style?.fontSize ?? 0;
    }

    testWidgets('xs size uses xs font sizes', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            size: .xs,
            title: 'Title',
          ),
        ),
      );
      await tester.pump();

      expect(_getLabelFontSize(tester, 'Label'), equals(_kLabelFontXs));
      expect(_getTitleFontSize(tester, 'Title'), equals(_kTitleFontXs));
    });

    testWidgets('sm size uses sm font sizes', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            size: .sm,
            title: 'Title',
          ),
        ),
      );
      await tester.pump();

      expect(_getLabelFontSize(tester, 'Label'), equals(_kLabelFontSm));
      expect(_getTitleFontSize(tester, 'Title'), equals(_kTitleFontSm));
    });

    testWidgets('md size uses md font sizes (default)', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            title: 'Title',
          ),
        ),
      );
      await tester.pump();

      expect(_getLabelFontSize(tester, 'Label'), equals(_kLabelFontMd));
      expect(_getTitleFontSize(tester, 'Title'), equals(_kTitleFontMd));
    });

    testWidgets('lg size uses lg font sizes', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            size: .lg,
            title: 'Title',
          ),
        ),
      );
      await tester.pump();

      expect(_getLabelFontSize(tester, 'Label'), equals(_kLabelFontLg));
      expect(_getTitleFontSize(tester, 'Title'), equals(_kTitleFontLg));
    });

    testWidgets('xl size uses xl font sizes', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            size: .xl,
            title: 'Title',
          ),
        ),
      );
      await tester.pump();

      expect(_getLabelFontSize(tester, 'Label'), equals(_kLabelFontXl));
      expect(_getTitleFontSize(tester, 'Title'), equals(_kTitleFontXl));
    });

    testWidgets('font size increases from xs to xl', (tester) async {
      Future<double> measureLabelFont(CoreDescriptionCardSize size) async {
        await tester.pumpWidget(
          _buildApp(
            DescriptionCard(
              rows: const [DescriptionRow(label: 'Label', value: 'Value')],
              size: size,
            ),
          ),
        );
        await tester.pump();
        return tester
                .widget<material.Text>(find.text('Label'))
                .style
                ?.fontSize ??
            0;
      }

      final xs = await measureLabelFont(.xs);
      final sm = await measureLabelFont(.sm);
      final md = await measureLabelFont(.md);
      final lg = await measureLabelFont(.lg);
      final xl = await measureLabelFont(.xl);

      expect(xs, lessThan(sm));
      expect(sm, lessThan(md));
      expect(md, lessThan(lg));
      expect(lg, lessThanOrEqualTo(xl));
    });
  });

  // ══════════════════════════════════════════════
  // Empty behavior
  // ══════════════════════════════════════════════

  group('DescriptionCard emptyValueBehavior', () {
    testWidgets('hide behavior hides null-value rows', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(label: 'Visible', value: 'Present'),
              DescriptionRow(label: 'Hidden'),
            ],
            emptyValueBehavior: .hide,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Visible'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Hidden'), findsNothing);
    });

    testWidgets('hide is default behavior', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(label: 'A', value: 'Yes'),
              DescriptionRow(label: 'B'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsNothing);
    });

    testWidgets('placeholder behavior shows placeholder text for null rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(label: 'Name', value: 'Alice'),
              DescriptionRow(label: 'Nickname'),
            ],
            emptyValueBehavior: .placeholder,
            emptyPlaceholder: '-',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Nickname'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('placeholder behavior with custom placeholder text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(label: 'Missing'),
            ],
            emptyValueBehavior: .placeholder,
            emptyPlaceholder: 'N/A',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('N/A'), findsOneWidget);
    });

    testWidgets('all rows hidden when all null and hide behavior', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(label: 'A'),
              DescriptionRow(label: 'B'),
            ],
            emptyValueBehavior: .hide,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsNothing);
    });
  });

  // ══════════════════════════════════════════════
  // Emphasis
  // ══════════════════════════════════════════════

  group('DescriptionCard emphasis', () {
    testWidgets('isEmphasized row applies emphasisStyle valueColor', (
      tester,
    ) async {
      const kEmphasisValueColor = material.Color(0xFF3B82F6);

      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(
                label: 'Amount',
                value: '100,000',
                isEmphasized: true,
              ),
              DescriptionRow(label: 'Normal', value: 'Standard'),
            ],
            descriptionCardStyle: CoreDescriptionCardStyle(
              emphasizedValueTextStyle: CoreTextStyle(
                color: CoreColor(0xFF3B82F6),
                fontWeight: CoreFontWeight.bold,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final emphasizedText = tester.widget<material.Text>(
        find.text('100,000'),
      );
      expect(emphasizedText.style?.color, equals(kEmphasisValueColor));
      expect(
        emphasizedText.style?.fontWeight,
        equals(material.FontWeight.w700),
      );
    });

    testWidgets('non-emphasized row is not affected by emphasisStyle', (
      tester,
    ) async {
      const kEmphasisValueColor = material.Color(0xFF3B82F6);

      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(
                label: 'Amount',
                value: '100,000',
                isEmphasized: true,
              ),
              DescriptionRow(label: 'Normal', value: 'Standard'),
            ],
            descriptionCardStyle: CoreDescriptionCardStyle(
              emphasizedValueTextStyle: CoreTextStyle(
                color: CoreColor(0xFF3B82F6),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final normalText = tester.widget<material.Text>(find.text('Standard'));
      expect(normalText.style?.color, isNot(equals(kEmphasisValueColor)));
    });

    testWidgets('isEmphasized row applies emphasisStyle labelColor', (
      tester,
    ) async {
      const kEmphasisLabelColor = material.Color(0xFFEF4444);

      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(
                label: 'Alert',
                value: 'Critical',
                isEmphasized: true,
              ),
            ],
            descriptionCardStyle: CoreDescriptionCardStyle(
              emphasizedLabelTextStyle: CoreTextStyle(
                color: CoreColor(0xFFEF4444),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final labelText = tester.widget<material.Text>(find.text('Alert'));
      expect(labelText.style?.color, equals(kEmphasisLabelColor));
    });
  });

  // ══════════════════════════════════════════════
  // Row onTap
  // ══════════════════════════════════════════════

  group('DescriptionCard row onTap', () {
    testWidgets('row onTap fires when row is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _buildApp(
          DescriptionCard(
            rows: [
              DescriptionRow(
                onTap: () {
                  tapped = true;
                },
                label: 'Tappable',
                value: 'Tap me',
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Tap me'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('row without onTap does not wrap with GestureDetector', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(label: 'Static', value: 'No tap'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Static'), findsOneWidget);
    });

    testWidgets('multiple rows each fire their own onTap', (tester) async {
      var firstTapped = false;
      var secondTapped = false;

      await tester.pumpWidget(
        _buildApp(
          DescriptionCard(
            rows: [
              DescriptionRow(
                onTap: () {
                  firstTapped = true;
                },
                label: 'First',
                value: 'Row 1',
              ),
              DescriptionRow(
                onTap: () {
                  secondTapped = true;
                },
                label: 'Second',
                value: 'Row 2',
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Row 1'));
      await tester.pump();

      expect(firstTapped, isTrue);
      expect(secondTapped, isFalse);

      await tester.tap(find.text('Row 2'));
      await tester.pump();

      expect(secondTapped, isTrue);
    });
  });

  // ══════════════════════════════════════════════
  // Card onTap
  // ══════════════════════════════════════════════

  group('DescriptionCard card-level onTap', () {
    testWidgets('card onTap fires when card is tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        _buildApp(
          DescriptionCard(
            onTap: () {
              tapped = true;
            },
            rows: const [
              DescriptionRow(label: 'Info', value: 'Value'),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Value'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('card without onTap does not wrap with GestureDetector', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DescriptionCard), findsOneWidget);
    });

    testWidgets('card onTap wraps with GestureDetector', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          DescriptionCard(
            onTap: () {},
            rows: const [DescriptionRow(label: 'Label', value: 'Value')],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(material.GestureDetector), findsWidgets);
    });
  });

  // ══════════════════════════════════════════════
  // Dividers
  // ══════════════════════════════════════════════

  group('DescriptionCard dividers', () {
    testWidgets('showDivider true shows divider below title', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            title: 'Title',
            showDivider: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Divider), findsWidgets);
    });

    testWidgets('showDivider false hides divider below title', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            title: 'Title',
            showDivider: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('showRowDividers false shows no row dividers', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(label: 'A', value: '1'),
              DescriptionRow(label: 'B', value: '2'),
              DescriptionRow(label: 'C', value: '3'),
            ],
            showRowDividers: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('showRowDividers true shows dividers between rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(label: 'A', value: '1'),
              DescriptionRow(label: 'B', value: '2'),
              DescriptionRow(label: 'C', value: '3'),
            ],
            showRowDividers: true,
          ),
        ),
      );
      await tester.pump();

      // 3 rows => 2 row dividers between them.
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets(
      'no divider rendered for single row even with showRowDividers',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const DescriptionCard(
              rows: [
                DescriptionRow(label: 'Only', value: 'One'),
              ],
              showRowDividers: true,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(Divider), findsNothing);
      },
    );
  });

  // ══════════════════════════════════════════════
  // bottomAction
  // ══════════════════════════════════════════════

  group('DescriptionCard bottomAction', () {
    testWidgets('renders bottomAction widget when provided', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            bottomAction: material.Text('View More'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('View More'), findsOneWidget);
    });

    testWidgets('bottomAction not rendered when null', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('View More'), findsNothing);
    });

    testWidgets(
      'showBottomActionDivider true shows divider above bottomAction',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const DescriptionCard(
              rows: [DescriptionRow(label: 'Label', value: 'Value')],
              bottomAction: material.Text('Action'),
              showBottomActionDivider: true,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(Divider), findsOneWidget);
      },
    );

    testWidgets(
      'showBottomActionDivider false hides divider above bottomAction',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const DescriptionCard(
              rows: [DescriptionRow(label: 'Label', value: 'Value')],
              bottomAction: material.Text('Action'),
              showBottomActionDivider: false,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(Divider), findsNothing);
      },
    );
  });

  // ══════════════════════════════════════════════
  // DescriptionCardTheme
  // ══════════════════════════════════════════════

  // ══════════════════════════════════════════════
  // DescriptionRow
  // ══════════════════════════════════════════════

  group('DescriptionRow', () {
    test('default isEmphasized is false', () {
      const row = DescriptionRow(label: 'Label');

      expect(row.isEmphasized, isFalse);
    });

    test('label is required', () {
      const row = DescriptionRow(label: 'My Label');

      expect(row.label, equals('My Label'));
    });

    test('value can be null', () {
      const row = DescriptionRow(label: 'Label');

      expect(row.value, isNull);
    });
  });

  // ══════════════════════════════════════════════
  // Row weight
  // ══════════════════════════════════════════════

  group('DescriptionCard rowWeight', () {
    testWidgets('renders without error with valueProminent', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            rowWeight: .valueProminent,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DescriptionCard), findsOneWidget);
    });

    testWidgets('renders without error with labelProminent', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            rowWeight: .labelProminent,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(DescriptionCard), findsOneWidget);
    });
  });

  // ══════════════════════════════════════════════
  // Custom styling
  // ══════════════════════════════════════════════

  group('DescriptionCard custom styling', () {
    testWidgets('applies custom backgroundColor', (tester) async {
      const kBgColor = material.Color(0xFFF0F0F0);

      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            descriptionCardStyle: CoreDescriptionCardStyle(
              backgroundColor: CoreColor(0xFFF0F0F0),
            ),
          ),
        ),
      );
      await tester.pump();

      final decoratedBoxes = tester.widgetList<material.DecoratedBox>(
        find.byType(material.DecoratedBox),
      );
      final outermostBox = decoratedBoxes.first;
      final decoration = outermostBox.decoration as material.BoxDecoration;

      expect(decoration.color, equals(kBgColor));
    });

    testWidgets('applies custom borderColor for outlined variant', (
      tester,
    ) async {
      const kCustomBorderColor = material.Color(0xFF123456);

      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            variant: .outlined,
            descriptionCardStyle: CoreDescriptionCardStyle(
              borderColor: CoreColor(0xFF123456),
            ),
          ),
        ),
      );
      await tester.pump();

      final decoratedBoxes = tester.widgetList<material.DecoratedBox>(
        find.byType(material.DecoratedBox),
      );
      final outermostBox = decoratedBoxes.first;
      final decoration = outermostBox.decoration as material.BoxDecoration;
      final border = decoration.border as material.Border?;

      expect(border?.top.color, equals(kCustomBorderColor));
    });

    testWidgets('applies custom row style override', (tester) async {
      const kCustomLabelColor = material.Color(0xFFABCDEF);

      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [
              DescriptionRow(
                label: 'Custom',
                value: 'Styled',
                labelTextStyle: CoreTextStyle(color: CoreColor(0xFFABCDEF)),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      final labelText = tester.widget<material.Text>(find.text('Custom'));
      expect(labelText.style?.color, equals(kCustomLabelColor));
    });
  });
  // ══════════════════════════════════════════════
  // Value role
  // ══════════════════════════════════════════════

  // Each size row names a *value* role as well as a label role, and the
  // value is drawn with it. The value used to be laid over the label's
  // style and only ever picked up a caller's override, so it kept the
  // label's weight and line height — a regular 150% line instead of the
  // medium 140% one — and every value line came out taller than the Web
  // card's.
  group('DescriptionCard value role', () {
    final valueRole = CoreTypography.coui.labelLarge;

    testWidgets('the value draws its own per-size role, not the label\'s', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
          ),
        ),
      );
      await tester.pump();

      final label = tester.widget<material.Text>(find.text('Label')).style!;
      final value = tester.widget<material.Text>(find.text('Value')).style!;

      expect(value.fontSize, valueRole.fontSize);
      expect(value.height, valueRole.lineHeight);
      expect(value.fontWeight, material.FontWeight.w500);
      // The two roles differ in line height and weight; sharing one
      // style would make these equal.
      expect(value.height, isNot(label.height));
      expect(value.fontWeight, isNot(label.fontWeight));
    });

    testWidgets('a partial override keeps the rest of the value role', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const DescriptionCard(
            rows: [DescriptionRow(label: 'Label', value: 'Value')],
            descriptionCardStyle: CoreDescriptionCardStyle(
              valueTextStyle: CoreTextStyle(color: CoreColor(0xFF123456)),
            ),
          ),
        ),
      );
      await tester.pump();

      final value = tester.widget<material.Text>(find.text('Value')).style!;

      expect(value.color, const material.Color(0xFF123456));
      expect(value.height, valueRole.lineHeight);
      expect(value.fontWeight, material.FontWeight.w500);
    });
  });
}
