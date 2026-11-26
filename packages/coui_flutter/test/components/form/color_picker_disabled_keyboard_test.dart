import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Tristate;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

import '../../parity/parity_fonts.dart';

const _initial = Color(0xFF6750A4);
const _red = CoreColor(0xFFFF0000);
const _blue = CoreColor(0xFF0000FF);
const _frame = Duration(milliseconds: 300);
final _observations = <Map<String, Object?>>[];

Finder _group() => find.byType(ToggleGroup<CoreColorPickerMode>);

Finder _recent(CoreColor color) => find.byWidgetPredicate(
  (widget) =>
      widget is Clickable &&
      widget.child is Container &&
      (widget.child as Container).decoration is BoxDecoration &&
      ((widget.child as Container).decoration! as BoxDecoration).color ==
          Color(color.value),
);

Future<bool> _activate(WidgetTester tester, Finder owner) async {
  final detector = find.descendant(
    of: owner,
    matching: find.byType(FocusableActionDetector),
  );
  expect(detector, findsOneWidget);
  final node = tester.widget<FocusableActionDetector>(detector).focusNode!
    ..requestFocus();
  await tester.pump();
  final accepted = node.hasFocus;
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pump(_frame);
  return accepted;
}

Future<void> _pump(
  WidgetTester tester, {
  required bool enabled,
  required ValueChanged<Color> onChanged,
  Color color = _initial,
  void Function(CoreColorHistoryStorage)? readStorage,
}) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      initialRecentColors: const [_red],
      home: Builder(
        builder: (context) {
          final storage = RecentColorsScope.maybeOf(context)!;
          readStorage?.call(storage);
          return Center(
            child: ColorPicker(
              key: const ValueKey('picker'),
              color: color,
              enabled: enabled,
              promptMode: .inline,
              onChanged: onChanged,
            ),
          );
        },
      ),
    ),
  );
  await tester.pump(_frame);
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(loadParityFonts);
  tearDownAll(() {
    final output = Platform.environment['COUI_DISABLED_NATIVE_PROOF'];
    if (output != null) {
      File(output).writeAsStringSync(
        '${const JsonEncoder.withIndent('  ').convert(_observations)}\n',
      );
    }
  });

  for (final enabled in [true, false]) {
    testWidgets('inline keyboard obeys enabled=$enabled', (tester) async {
      final changes = <Color>[];
      await _pump(tester, enabled: enabled, onChanged: changes.add);
      final before = tester.widget<ToggleGroup<CoreColorPickerMode>>(_group());
      final radios = find.descendant(
        of: _group(),
        matching: find.byType(Clickable),
      );
      expect(radios, findsNWidgets(3));
      final modeFocused = await _activate(tester, radios.last);
      final after = tester.widget<ToggleGroup<CoreColorPickerMode>>(_group());
      final recent = _recent(_red);
      expect(recent, findsOneWidget);
      final recentFocused = await _activate(tester, recent);
      _observations.add({
        'test': 'keyboard',
        'enabled': enabled,
        'modeFocused': modeFocused,
        'modeBefore': before.value?.name,
        'modeAfter': after.value?.name,
        'recentFocused': recentFocused,
        'changes': changes.map((c) => c.toARGB32()).toList(),
      });
      expect(
        after.value,
        enabled ? CoreColorPickerMode.hsv : before.value,
      );
      expect(changes, enabled ? [const Color(0xFFFF0000)] : isEmpty);
      expect(modeFocused, enabled);
      expect(recentFocused, enabled);
    });
  }

  testWidgets('disabled labels and current value remain accessible', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pump(tester, enabled: false, onChanged: (_) {});
      final input = find.descendant(
        of: find.byType(TextField).first,
        matching: find.byType(EditableText),
      );
      expect(input, findsOneWidget);
      expect(tester.getSemantics(input).getSemanticsData().value, '#6750A4');
      expect(find.bySemanticsLabel(RegExp('^RGB')), findsWidgets);
      final radio = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^RGB')).first,
      );
      expect(
        radio.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      expect(tester.widget<Clickable>(_recent(_red)).enabled, isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('disabled picker receives external color and history updates', (
    tester,
  ) async {
    final changes = <Color>[];
    late CoreColorHistoryStorage storage;
    await _pump(
      tester,
      enabled: false,
      onChanged: changes.add,
      readStorage: (value) => storage = value,
    );
    final state = tester.state(find.byType(ColorPicker));
    await _pump(
      tester,
      enabled: false,
      color: const Color(0xFF0000FF),
      onChanged: changes.add,
    );
    expect(tester.state(find.byType(ColorPicker)), same(state));
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.first.initialValue, '#0000FF');
    storage.addHistory(_blue);
    await tester.pump(_frame);
    expect(_recent(_blue), findsOneWidget);
    expect(tester.widget<Clickable>(_recent(_blue)).enabled, isFalse);
    expect(changes, isEmpty);
    _observations.add({
      'test': 'programmatic-model-updates',
      'hex': fields.first.initialValue,
      'history': storage.recentColors.map((color) => color.toHex()).toList(),
      'changes': changes.length,
    });
  });

  testWidgets('old UI callbacks cannot edit after disable or disposal', (
    tester,
  ) async {
    final changes = <Color>[];
    await _pump(tester, enabled: true, onChanged: changes.add);
    final input = tester.widget<TextField>(find.byType(TextField).first);
    final mode = tester.widget<ToggleGroup<CoreColorPickerMode>>(_group());
    final groupElement = tester.element(_group());
    final recent = tester.widget<Clickable>(_recent(_red));
    await _pump(tester, enabled: false, onChanged: changes.add);
    expect(tester.element(_group()), same(groupElement));
    input.onChanged?.call('#00FF00');
    mode.onChanged?.call(CoreColorPickerMode.hsv);
    recent.onPressed?.call();
    await tester.pump(_frame);
    expect(tester.takeException(), isNull);
    expect(changes, isEmpty);
    expect(
      tester.widget<ToggleGroup<CoreColorPickerMode>>(_group()).value,
      CoreColorPickerMode.rgb,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    input.onChanged?.call('#00FF00');
    mode.onChanged?.call(CoreColorPickerMode.hsv);
    recent.onPressed?.call();
    await tester.pump(_frame);
    expect(tester.takeException(), isNull);
    expect(changes, isEmpty);
  });
}
