// Two slots that had nowhere to land, and one that already did.
//
// `suffix` *replaces* the label — `widget.suffix ?? Text(label)` — so a
// caller who wanted a chevron at the end of a disclosure row had to give
// up the label to get it, and a caller who wanted a supporting line under
// the label had no field at all. `description` and `trailing` are the two
// slots that fix each half; this file pins that they render, that they
// render *alongside* the label rather than instead of it, and that the
// row re-aligns when the content becomes two lines tall.
//
// The alignment assertion is the one worth stating plainly: a box centred
// against a label-plus-description block sits against neither line, and
// the canvas states `counterAxisAlignItems: MIN` for exactly that reason.
// A single-line row keeps centre, which is what every checkbox already
// rendered — so this also pins that nothing moved for callers who never
// pass a description.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// The checkbox draws its own checkmark with an `Icon`, so a
/// `find.byType(Icon)` would match two widgets and silently pick the
/// wrong one. Every trailing slot in this file carries this key.
const _trailingKey = ValueKey<String>('trailing-affordance');

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

/// The `Row` the checkbox lays its slots out in — the widget builds
/// exactly one, so `first` is unambiguous.
Row _row(WidgetTester tester) => tester.widgetList<Row>(find.byType(Row)).first;

void main() {
  group('the description steps one under the label', () {
    testWidgets('11 / 12 / 13 / 14 / 14 / 14 across the size ladder', (
      tester,
    ) async {
      Future<double?> descriptionSizeAt(CoreComponentSize size) async {
        await tester.pumpWidget(
          _buildApp(
            Checkbox(
              onChanged: (_) {},
              checked: false,
              size: size,
              label: 'Accept terms',
              description: 'You can withdraw consent later',
            ),
          ),
        );
        await tester.pumpAndSettle();

        return tester
            .widget<Text>(find.text('You can withdraw consent later'))
            .style
            ?.fontSize;
      }

      expect(await descriptionSizeAt(.xs), CoreFontSize.s11);
      expect(await descriptionSizeAt(.sm), CoreFontSize.s12);
      expect(await descriptionSizeAt(.md), CoreFontSize.s13);
      expect(await descriptionSizeAt(.lg), CoreFontSize.s14);
      expect(await descriptionSizeAt(.xl), CoreFontSize.s14);
      expect(await descriptionSizeAt(.xl2), CoreFontSize.s14);
    });
  });

  group('description renders as its own line under the label', () {
    testWidgets('label and description are both present', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (_) {},
            checked: false,
            label: 'Accept terms',
            description: 'You can withdraw consent later',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Accept terms'),
        findsOneWidget,
        reason:
            'the description replaced the label — that is the `suffix` '
            'behaviour these slots exist to stop repeating',
      );
      expect(find.text('You can withdraw consent later'), findsOneWidget);
    });

    testWidgets('a description with no label still renders', (tester) async {
      // The slot must not be silently conditional on a sibling.
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (_) {},
            checked: false,
            description: 'Standalone note',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Standalone note'), findsOneWidget);
    });

    testWidgets('the description is drawn quieter than the label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (_) {},
            checked: false,
            label: 'Accept terms',
            description: 'Supporting text',
          ),
        ),
      );
      await tester.pumpAndSettle();

      final label = tester.widget<Text>(find.text('Accept terms'));
      final description = tester.widget<Text>(find.text('Supporting text'));

      expect(
        description.style?.color,
        isNot(label.style?.color),
        reason:
            'the two lines resolve to the same foreground, so the '
            'hierarchy the description exists to state is not drawn',
      );
    });
  });

  group('the row re-aligns only when the content is two lines', () {
    testWidgets('a labelled checkbox keeps centre alignment', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (_) {},
            checked: false,
            label: 'Accept terms',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _row(tester).crossAxisAlignment,
        CrossAxisAlignment.center,
        reason:
            'this is the alignment every checkbox rendered with before '
            'the description slot existed — adding a slot must not move '
            'rows that never use it',
      );
    });

    testWidgets('a described checkbox top-aligns the box', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (_) {},
            checked: false,
            label: 'Accept terms',
            description: 'Supporting text',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        _row(tester).crossAxisAlignment,
        CrossAxisAlignment.start,
        reason:
            'centred against a two-line block the box sits against '
            'neither line; the canvas states MIN for this pose',
      );
    });
  });

  group('trailing sits after the label, not instead of it', () {
    testWidgets('label and trailing both render', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (_) {},
            checked: false,
            label: 'Terms of service',
            trailing: const Icon(LucideIcons.chevronRight, key: _trailingKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terms of service'), findsOneWidget);
      expect(find.byKey(_trailingKey), findsOneWidget);
    });

    testWidgets('trailing is the last child of the row', (tester) async {
      // Position matters: a chevron that renders before the label is not
      // the affordance the caller asked for, and `findsOneWidget` alone
      // would pass either way.
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (_) {},
            checked: false,
            label: 'Terms of service',
            trailing: const Icon(LucideIcons.chevronRight, key: _trailingKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final labelX = tester.getCenter(find.text('Terms of service')).dx;
      final trailingX = tester.getCenter(find.byKey(_trailingKey)).dx;

      expect(
        trailingX,
        greaterThan(labelX),
        reason: 'trailing rendered before the label it should follow',
      );
    });

    testWidgets('all three slots coexist', (tester) async {
      // The shape the reference row actually needs: box, label with a
      // supporting line, and a chevron at the end.
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (_) {},
            checked: true,
            label: 'Terms of service',
            description: 'Required',
            trailing: const Icon(LucideIcons.chevronRight, key: _trailingKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terms of service'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);
      expect(find.byKey(_trailingKey), findsOneWidget);
      expect(_row(tester).crossAxisAlignment, CrossAxisAlignment.start);
    });
  });

  group('copyWith carries the new slots', () {
    testWidgets('description and trailing survive a copyWith', (tester) async {
      final original = Checkbox(
        onChanged: (_) {},
        checked: false,
        label: 'Accept terms',
        description: 'Supporting text',
        trailing: const Icon(LucideIcons.chevronRight, key: _trailingKey),
      );
      final copy = original.copyWith(checked: true, checkedProvided: true);

      expect(copy.description, 'Supporting text');
      expect(copy.trailing, isNotNull);
      expect(copy.checked, isTrue);
    });
  });
}
