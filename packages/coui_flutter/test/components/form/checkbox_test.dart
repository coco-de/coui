import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

// Theme constants
const _kCheckboxSize = 20.0;
const _kCheckboxGap = 12.0;
const _kCheckboxBorderRadius = 4.0;

// Color constants
const _kActiveColor = material.Color(0xFF2196F3);
const _kBorderColor = material.Color(0xFF9E9E9E);

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('CheckboxState', () {
    test('compareTo returns 0 for same state', () {
      const stateA = CheckboxState.checked;
      const stateB = CheckboxState.checked;
      expect(
        stateA.compareTo(stateB),
        equals(0),
      );
    });

    test('compareTo distinguishes states by index order', () {
      expect(
        CheckboxState.checked.compareTo(.unchecked),
        lessThan(0),
      );
      expect(
        CheckboxState.unchecked.compareTo(.checked),
        greaterThan(0),
      );
    });

    test('all three states are distinct', () {
      expect(CheckboxState.checked, isNot(equals(CheckboxState.unchecked)));
      expect(
        CheckboxState.checked,
        isNot(equals(CheckboxState.indeterminate)),
      );
      expect(
        CheckboxState.unchecked,
        isNot(equals(CheckboxState.indeterminate)),
      );
    });
  });

  group('CheckboxController', () {
    test('initializes with provided state', () {
      final controller = CheckboxController(.unchecked);
      expect(controller.value, equals(CheckboxState.unchecked));
      controller.dispose();
    });

    test('check() sets state to checked', () {
      final controller = CheckboxController(.unchecked);
      controller.check();
      expect(controller.value, equals(CheckboxState.checked));
      controller.dispose();
    });

    test('uncheck() sets state to unchecked', () {
      final controller = CheckboxController(.checked);
      controller.uncheck();
      expect(controller.value, equals(CheckboxState.unchecked));
      controller.dispose();
    });

    test('indeterminate() sets state to indeterminate', () {
      final controller = CheckboxController(.checked);
      controller.indeterminate();
      expect(controller.value, equals(CheckboxState.indeterminate));
      controller.dispose();
    });

    test('toggle() switches checked to unchecked', () {
      final controller = CheckboxController(.checked);
      controller.toggle();
      expect(controller.value, equals(CheckboxState.unchecked));
      controller.dispose();
    });

    test('toggle() switches unchecked to checked', () {
      final controller = CheckboxController(.unchecked);
      controller.toggle();
      expect(controller.value, equals(CheckboxState.checked));
      controller.dispose();
    });

    test('toggle() switches indeterminate to checked', () {
      final controller = CheckboxController(.indeterminate);
      controller.toggle();
      expect(controller.value, equals(CheckboxState.checked));
      controller.dispose();
    });

    test(
      'toggleTristate() cycles checked -> unchecked -> indeterminate -> checked',
      () {
        final controller = CheckboxController(.checked);

        controller.toggleTristate();
        expect(controller.value, equals(CheckboxState.unchecked));

        controller.toggleTristate();
        expect(controller.value, equals(CheckboxState.indeterminate));

        controller.toggleTristate();
        expect(controller.value, equals(CheckboxState.checked));

        controller.dispose();
      },
    );

    test('isChecked returns true only when checked', () {
      final controller = CheckboxController(.checked);
      expect(controller.isChecked, isTrue);
      expect(controller.isUnchecked, isFalse);
      expect(controller.isIndeterminate, isFalse);
      controller.dispose();
    });

    test('isUnchecked returns true only when unchecked', () {
      final controller = CheckboxController(.unchecked);
      expect(controller.isChecked, isFalse);
      expect(controller.isUnchecked, isTrue);
      expect(controller.isIndeterminate, isFalse);
      controller.dispose();
    });

    test('isIndeterminate returns true only when indeterminate', () {
      final controller = CheckboxController(.indeterminate);
      expect(controller.isChecked, isFalse);
      expect(controller.isUnchecked, isFalse);
      expect(controller.isIndeterminate, isTrue);
      controller.dispose();
    });
  });

  group('Checkbox widget', () {
    testWidgets('renders without error in unchecked state', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (_) {},
            checked: false,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('renders without error in checked state', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (_) {},
            checked: true,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('renders without error in indeterminate state', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (_) {},
            checked: null,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('respects key parameter', (tester) async {
      const testKey = Key('checkbox-key');

      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            key: testKey,
            onChanged: (_) {},
            checked: false,
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('calls onChanged with the next value when tapped', (
      tester,
    ) async {
      bool? received;
      var called = false;

      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (value) {
              called = true;
              received = value;
            },
            checked: false,
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox));
      final _ = await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(received, isTrue);
    });

    testWidgets('tristate cycles true → false → null → true', (tester) async {
      final values = <bool?>[];
      bool? current = true;

      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(),
            child: material.StatefulBuilder(
              builder: (context, setState) {
                return Checkbox(
                  onChanged: (value) {
                    setState(() {
                      current = value;
                      values.add(value);
                    });
                  },
                  checked: current,
                  tristate: true,
                );
              },
            ),
          ),
        ),
      );

      // true -> false
      await tester.tap(find.byType(Checkbox));
      final _ = await tester.pumpAndSettle();
      // false -> null (indeterminate)
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      // null -> true
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(values, [false, null, true]);
    });

    testWidgets('a disabled checked box still paints its mark', (
      tester,
    ) async {
      // The mark takes the disabled ramp's own ink — `onPrimary` over the
      // disabled container was white on grey, an invisible mark.
      await tester.pumpWidget(
        _buildApp(
          const Checkbox(
            onChanged: null,
            checked: true,
            enabled: false,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final context = tester.element(find.byType(Checkbox));
      final resolved = resolveCheckbox(context, size: CoreComponentSize.md);
      // The check glyph — the `Icon` inside the ring — is handed the disabled
      // icon style and paints in the disabled ink at the enabled glyph's size.
      final checkIcon = find.descendant(
        of: find.byType(FocusOutline),
        matching: find.byType(Icon),
      );
      final picture = tester.widget<SvgPicture>(
        find.descendant(of: checkIcon, matching: find.byType(SvgPicture)),
      );

      expect(
        tester.widget<Icon>(checkIcon).iconStyle,
        resolved.disabledCheckmarkIconStyle,
      );
      expect(
        picture.colorFilter,
        ColorFilter.mode(resolved.disabledCheckmarkColor, BlendMode.srcIn),
      );
      expect(
        resolved.disabledCheckmarkIconStyle.size,
        resolved.checkmarkIconStyle.size,
      );
      expect(
        resolved.disabledCheckmarkColor,
        isNot(resolved.checkmarkColor),
        reason: 'the disabled mark must not keep the enabled ink',
      );
    });

    testWidgets('the ring hugs the box, not the row', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (_) {},
            checked: false,
            label: 'Accept terms',
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // The `Clickable` draws no ring of its own; the one `FocusOutline`
      // in the tree wraps the square and sits inside the row.
      final clickable = tester.widget<Clickable>(find.byType(Clickable));
      expect(clickable.focusOutline, isFalse);
      expect(
        find.descendant(
          of: find.byType(Row),
          matching: find.byType(FocusOutline),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(FocusOutline),
          matching: find.text('Accept terms'),
        ),
        findsNothing,
        reason: 'the label is outside the ring',
      );
    });

    testWidgets('the box stroke is the 1 px line at every size', (
      tester,
    ) async {
      Future<double> paintedStrokeAt(CoreComponentSize size) async {
        await tester.pumpWidget(
          _buildApp(
            Checkbox(onChanged: (_) {}, checked: false, size: size),
          ),
        );
        final _ = await tester.pumpAndSettle();

        // The box is the `AnimatedContainer` that carries a border.
        final box = tester.widget<AnimatedContainer>(
          find.byWidgetPredicate(
            (w) =>
                w is AnimatedContainer &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).border != null,
          ),
        );

        return ((box.decoration! as BoxDecoration).border! as Border).top.width;
      }

      for (final size in CoreComponentSize.values) {
        expect(
          await paintedStrokeAt(size),
          CoreStrokeWidth.stroke1,
          reason: '${size.name} resting box stroke',
        );
      }

      // And the three composed bundles carry the one width — the stroke is
      // size-invariant and state-invariant (a checked box's stroke takes the
      // fill's colour, not a different width).
      final context = tester.element(find.byType(Checkbox));
      for (final size in CoreComponentSize.values) {
        final resolved = resolveCheckbox(context, size: size);
        expect(resolved.uncheckedContainerStyle.borderWidth, 1);
        expect(resolved.activeContainerStyle.borderWidth, 1);
        expect(resolved.disabledContainerStyle.borderWidth, 1);
      }
    });

    testWidgets('does not call onChanged when null (disabled)', (tester) async {
      var called = false;

      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: null,
            checked: false,
          ),
        ),
      );

      await tester.tap(find.byType(Checkbox), warnIfMissed: false);
      final _ = await tester.pumpAndSettle();

      expect(called, isFalse);
    });

    testWidgets('renders leading widget when provided', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (_) {},
            prefix: const Text('leading'),
            checked: false,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('leading'), findsOneWidget);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            onChanged: (_) {},
            checked: false,
            suffix: const Text('trailing'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('trailing'), findsOneWidget);
    });
  });
}
