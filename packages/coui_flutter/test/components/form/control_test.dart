import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kInitialValue = 'initial';
const _kNewValue = 'new value';
const _kAnotherValue = 'another value';
const _kIntValue = 42;
const _kNewIntValue = 99;
const _kBoolValue = false;
const _kNewBoolValue = true;

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

void main() {
  group('ComponentValueController', () {
    test('initializes with given value', () {
      final controller = ComponentValueController(_kInitialValue);

      expect(controller.value, equals(_kInitialValue));
      controller.dispose();
    });

    test('notifies listeners on value change', () {
      final controller = ComponentValueController(_kInitialValue);
      var notifyCount = 0;
      void handleNotify() {
        notifyCount += 1;
      }

      controller.addListener(handleNotify);

      controller.value = _kNewValue;

      expect(notifyCount, equals(1));
      expect(controller.value, equals(_kNewValue));
      controller.dispose();
    });

    test('works with integer type', () {
      final controller = ComponentValueController(_kIntValue);

      expect(controller.value, equals(_kIntValue));

      controller.value = _kNewIntValue;
      expect(controller.value, equals(_kNewIntValue));
      controller.dispose();
    });

    test('works with bool type', () {
      final controller = ComponentValueController(_kBoolValue);

      expect(controller.value, equals(_kBoolValue));

      controller.value = _kNewBoolValue;
      expect(controller.value, equals(_kNewBoolValue));
      controller.dispose();
    });

    test('multiple listeners are notified', () {
      final controller = ComponentValueController(_kInitialValue);
      var count1 = 0;
      var count2 = 0;

      void handleListener1() {
        count1 += 1;
      }

      void handleListener2() {
        count2 += 1;
      }

      controller.addListener(handleListener1);
      controller.addListener(handleListener2);

      controller.value = _kNewValue;

      expect(count1, equals(1));
      expect(count2, equals(1));
      controller.dispose();
    });

    test('removeListener stops notifications', () {
      final controller = ComponentValueController(_kInitialValue);
      var count = 0;

      void listener() {
        count += 1;
      }

      controller.addListener(listener);
      controller.value = _kNewValue;
      expect(count, equals(1));

      controller.removeListener(listener);
      controller.value = _kAnotherValue;
      expect(count, lessThan(2));
      controller.dispose();
    });
  });

  group('ControlledComponentData', () {
    test('stores value, onChanged, and enabled', () {
      var callbackReceived = '';
      void handleChange(String v) {
        callbackReceived = v;
      }

      final data = ControlledComponentData(
        onChanged: handleChange,
        enabled: true,
        value: _kInitialValue,
      );

      expect(data.value, equals(_kInitialValue));
      expect(data.enabled, isTrue);
      data.onChanged(_kNewValue);
      expect(callbackReceived, equals(_kNewValue));
    });

    test('disabled data has enabled false', () {
      void handleChange(String v) {}

      final data = ControlledComponentData(
        onChanged: handleChange,
        enabled: false,
        value: _kInitialValue,
      );

      expect(data.enabled, isFalse);
    });
  });

  group('ControlledComponentAdapter widget', () {
    testWidgets('renders with initialValue', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          ControlledComponentAdapter<String>(
            initialValue: _kInitialValue,
            builder: (context, data) => material.Text(data.value),
          ),
        ),
      );

      expect(find.text(_kInitialValue), findsOneWidget);
    });

    testWidgets('accepts key parameter', (tester) async {
      const testKey = material.Key('test-adapter');

      await tester.pumpWidget(
        _buildApp(
          ControlledComponentAdapter<String>(
            key: testKey,
            initialValue: _kInitialValue,
            builder: (context, data) => material.Text(data.value),
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('builder receives correct initial value', (tester) async {
      String? receivedValue;

      await tester.pumpWidget(
        _buildApp(
          ControlledComponentAdapter<String>(
            initialValue: _kInitialValue,
            builder: (context, data) {
              receivedValue = data.value;
              return material.Text(data.value);
            },
          ),
        ),
      );

      expect(receivedValue, equals(_kInitialValue));
    });

    testWidgets('updates internal state when onChanged called', (tester) async {
      String? lastValue;

      await tester.pumpWidget(
        _buildApp(
          ControlledComponentAdapter<String>(
            initialValue: _kInitialValue,
            builder: (context, data) {
              return material.GestureDetector(
                onTap: () => data.onChanged(_kNewValue),
                child: material.Text(data.value),
              );
            },
          ),
        ),
      );

      expect(find.text(_kInitialValue), findsOneWidget);

      await tester.tap(find.byType(material.GestureDetector));
      final _ = await tester.pumpAndSettle();

      expect(find.text(_kNewValue), findsOneWidget);
      expect(lastValue, isNull); // No external onChanged provided
    });

    testWidgets('fires onChanged callback when value changes', (tester) async {
      String? lastValue;

      await tester.pumpWidget(
        _buildApp(
          ControlledComponentAdapter<String>(
            onChanged: (v) {
              lastValue = v;
            },
            initialValue: _kInitialValue,
            builder: (context, data) {
              return material.GestureDetector(
                onTap: () => data.onChanged(_kNewValue),
                child: material.Text(data.value),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(material.GestureDetector));
      final _ = await tester.pumpAndSettle();

      expect(lastValue, equals(_kNewValue));
    });

    testWidgets('works with controller', (tester) async {
      final controller = ComponentValueController(_kInitialValue);

      await tester.pumpWidget(
        _buildApp(
          ControlledComponentAdapter<String>(
            controller: controller,
            builder: (context, data) => material.Text(data.value),
          ),
        ),
      );

      expect(find.text(_kInitialValue), findsOneWidget);
      controller.dispose();
    });

    testWidgets('updates when controller value changes', (tester) async {
      final controller = ComponentValueController(_kInitialValue);

      await tester.pumpWidget(
        _buildApp(
          ControlledComponentAdapter<String>(
            controller: controller,
            builder: (context, data) => material.Text(data.value),
          ),
        ),
      );

      controller.value = _kNewValue;
      final _ = await tester.pumpAndSettle();

      expect(find.text(_kNewValue), findsOneWidget);
      controller.dispose();
    });

    testWidgets('builder receives correct enabled state', (tester) async {
      bool? receivedEnabled;

      await tester.pumpWidget(
        _buildApp(
          ControlledComponentAdapter<String>(
            initialValue: _kInitialValue,
            enabled: false,
            builder: (context, data) {
              receivedEnabled = data.enabled;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(receivedEnabled, isFalse);
    });

    testWidgets('enabled defaults to true', (tester) async {
      bool? receivedEnabled;

      await tester.pumpWidget(
        _buildApp(
          ControlledComponentAdapter<String>(
            initialValue: _kInitialValue,
            builder: (context, data) {
              receivedEnabled = data.enabled;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(receivedEnabled, isTrue);
    });
  });
}
