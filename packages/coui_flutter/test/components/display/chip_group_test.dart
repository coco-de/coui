import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(data: const ThemeData(), child: child),
  );
}

Widget _buildChipGroup({
  List<String> items = const ['A', 'B', 'C'],
  CoreChipGroupSelectionMode? selectionMode,
  CoreChipGroupLayout? layout,
  Set<String>? initialValue,
  int? maxSelection,
  ValueChanged<Set<String>>? onChanged,
  Widget? title,
  Widget? selectionHint,
}) {
  return _buildApp(
    ChipGroup<String>(
      onChanged: onChanged,
      initialValue: initialValue,
      items: items,
      chipBuilder:
          (item, {required selected, required enabled, required onTap}) => Chip(
            onTap: onTap,
            label: item,
            enabled: enabled,
            selected: selected,
          ),
      layout: layout,
      maxSelection: maxSelection,
      selectionHint: selectionHint,
      selectionMode: selectionMode,
      title: title,
    ),
  );
}

void main() {
  group('ChipGroup', () {
    testWidgets('renders all items', (tester) async {
      await tester.pumpWidget(
        _buildChipGroup(items: ['A', 'B', 'C']),
      );
      await tester.pump();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('renders with initial selection', (tester) async {
      await tester.pumpWidget(
        _buildChipGroup(initialValue: {'B'}),
      );
      await tester.pump();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('multi selection mode allows multiple selections', (
      tester,
    ) async {
      Set<String>? lastChanged;

      await tester.pumpWidget(
        _buildChipGroup(
          onChanged: (selected) {
            lastChanged = selected;
          },
          selectionMode: .multi,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('A'));
      await tester.pump();
      expect(lastChanged, equals({'A'}));

      await tester.tap(find.text('B'));
      await tester.pump();
      expect(lastChanged, equals({'A', 'B'}));
    });

    testWidgets('single selection mode allows only one selection', (
      tester,
    ) async {
      Set<String>? lastChanged;

      await tester.pumpWidget(
        _buildChipGroup(
          onChanged: (selected) {
            lastChanged = selected;
          },
          selectionMode: .single,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('A'));
      await tester.pump();
      expect(lastChanged, equals({'A'}));

      await tester.tap(find.text('B'));
      await tester.pump();
      expect(lastChanged, equals({'B'}));
    });

    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        _buildChipGroup(title: const Text('Select tags')),
      );
      await tester.pump();

      expect(find.text('Select tags'), findsOneWidget);
    });

    testWidgets('renders with selection hint', (tester) async {
      await tester.pumpWidget(
        _buildChipGroup(
          title: const Text('Tags'),
          selectionHint: const Text('0/3 selected'),
        ),
      );
      await tester.pump();

      expect(find.text('0/3 selected'), findsOneWidget);
    });

    testWidgets('wrap layout renders Wrap widget', (tester) async {
      await tester.pumpWidget(
        _buildChipGroup(layout: .wrap),
      );
      await tester.pump();

      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('scroll layout renders SingleChildScrollView', (tester) async {
      await tester.pumpWidget(
        _buildChipGroup(
          items: ['A', 'B', 'C', 'D', 'E'],
          layout: .scroll,
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('respects maxSelection', (tester) async {
      Set<String>? lastChanged;

      await tester.pumpWidget(
        _buildChipGroup(
          onChanged: (selected) {
            lastChanged = selected;
          },
          selectionMode: .multi,
          maxSelection: 2,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.tap(find.text('B'));
      await tester.pump();
      expect(lastChanged, equals({'A', 'B'}));

      // Third tap should be ignored (max reached)
      await tester.tap(find.text('C'));
      await tester.pump();
      expect(lastChanged, equals({'A', 'B'}));
    });

    testWidgets('component theme integration', (tester) async {
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(
              coreComponentTheme: CoreComponentTheme(
                chipGroup: CoreChipGroupTheme(
                  layout: .wrap,
                  selectionMode: .single,
                ),
              ),
            ),
            child: ChipGroup<String>(
              items: const ['X', 'Y'],
              chipBuilder:
                  (
                    item, {
                    required selected,
                    required enabled,
                    required onTap,
                  }) => Chip(
                    onTap: onTap,
                    label: item,
                    enabled: enabled,
                    selected: selected,
                  ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('X'), findsOneWidget);
      expect(find.text('Y'), findsOneWidget);
    });
  });
}
