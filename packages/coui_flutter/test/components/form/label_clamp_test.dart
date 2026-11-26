import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

const _kLabel = 'A label long enough to be worth clamping';
const _kTwoLines = 2;

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

/// The `Text` the component drew for [_kLabel] — the clamp is read off
/// the widget the label actually renders through, not off the field.
Text _labelText(WidgetTester tester) =>
    tester.widget<Text>(find.text(_kLabel).first);

void main() {
  // `labelMaxLines` / `labelOverflow` are behaviour, not chrome: they
  // live on the widget, and each assertion below reads them back off the
  // rendered label so a parameter that is declared but never forwarded
  // fails here rather than passing silently.
  group('wrap-by-default controls keep wrapping until asked', () {
    testWidgets('Checkbox leaves its label unclamped by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(Checkbox(checked: false, onChanged: (_) {}, label: _kLabel)),
      );

      expect(_labelText(tester).maxLines, isNull);
      expect(_labelText(tester).overflow, isNull);
    });

    testWidgets('Checkbox forwards a stated clamp to its label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          Checkbox(
            checked: false,
            onChanged: (_) {},
            label: _kLabel,
            labelMaxLines: _kTwoLines,
            labelOverflow: CoreTextOverflow.ellipsis,
          ),
        ),
      );

      expect(_labelText(tester).maxLines, _kTwoLines);
      expect(_labelText(tester).overflow, material.TextOverflow.ellipsis);
    });

    testWidgets('SwitchField forwards a stated clamp to its label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          SwitchField(
            label: _kLabel,
            value: false,
            onChanged: (_) {},
            labelMaxLines: 1,
            labelOverflow: CoreTextOverflow.clip,
          ),
        ),
      );

      expect(_labelText(tester).maxLines, 1);
      expect(_labelText(tester).overflow, material.TextOverflow.clip);
    });

    testWidgets('TextField forwards a stated clamp through FormLabel', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          TextField(
            label: _kLabel,
            labelMaxLines: 1,
            labelOverflow: CoreTextOverflow.ellipsis,
          ),
        ),
      );

      expect(_labelText(tester).maxLines, 1);
      expect(_labelText(tester).overflow, material.TextOverflow.ellipsis);
    });
  });

  group('single-line controls keep their clamp as the default', () {
    testWidgets('ValidationBadge draws one ellipsised line by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidationBadge(label: _kLabel, state: .valid),
        ),
      );

      expect(
        _labelText(tester).maxLines,
        CoreValidationBadgeContract.defaultLabelMaxLines,
      );
      expect(_labelText(tester).overflow, material.TextOverflow.ellipsis);
    });

    testWidgets('ValidationBadge lets the caller lift the clamp', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const ValidationBadge(
            label: _kLabel,
            state: .valid,
            labelMaxLines: _kTwoLines,
          ),
        ),
      );

      expect(_labelText(tester).maxLines, _kTwoLines);
      // The unstated half falls back to the contract default.
      expect(_labelText(tester).overflow, material.TextOverflow.ellipsis);
    });

    testWidgets('Chip draws one ellipsised line by default', (tester) async {
      await tester.pumpWidget(_buildApp(const Chip(label: _kLabel)));

      expect(
        _labelText(tester).maxLines,
        CoreChipContract.defaultLabelMaxLines,
      );
      expect(_labelText(tester).overflow, material.TextOverflow.ellipsis);
    });

    testWidgets('Chip forwards a stated overflow over its default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Chip(label: _kLabel, labelOverflow: CoreTextOverflow.fade),
        ),
      );

      expect(
        _labelText(tester).maxLines,
        CoreChipContract.defaultLabelMaxLines,
      );
      expect(_labelText(tester).overflow, material.TextOverflow.fade);
    });
  });
}
