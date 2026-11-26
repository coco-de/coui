// SwitchField's defaults — the toggle size it composes and the description
// it sets under the label. Read off the laid-out boxes and the painted text,
// so a resolver that stops reading the Core default fails here.
import 'dart:ui' show Tristate;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: Align(alignment: Alignment.topLeft, child: child),
  ),
);

/// The one `OutlinedContainer` a switch field composes — the toggle's track.
Rect _track(WidgetTester tester) =>
    tester.getRect(find.byType(OutlinedContainer));

/// The colour token the composed toggle's track is filled with.
CoreColor? _trackFill(WidgetTester tester) => tester
    .widget<OutlinedContainer>(find.byType(OutlinedContainer))
    .containerStyle!
    .backgroundColor;

void main() {
  group('SwitchField toggle size', () {
    testWidgets('composes the lg toggle by default — a 40 × 24 track', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(SwitchField(label: 'Alerts', value: true, onChanged: (_) {})),
      );
      final _ = await tester.pumpAndSettle();

      final lg = CoreToggleStyle.sizeDefaults(CoreSwitchFieldStyle.defaultSize);
      expect(CoreSwitchFieldStyle.defaultSize, CoreComponentSize.lg);
      expect(_track(tester).size, const Size(40, 24));
      expect(_track(tester).width, lg.trackWidth);
      expect(_track(tester).height, lg.trackHeight);
    });

    testWidgets('a one-line field is as tall as the lg track', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          SwitchField(label: 'Alerts', value: false, onChanged: (_) {}),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final row = tester.getRect(find.byType(Clickable).first);
      expect(row.height, 24);
    });

    testWidgets('a size the app states wins over the default', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          SwitchField(
            label: 'Alerts',
            value: false,
            onChanged: (_) {},
            switchFieldStyle: const CoreSwitchFieldStyle(
              size: CoreComponentSize.md,
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(_track(tester).size, const Size(36, 20));
    });
  });

  group('SwitchField track colour', () {
    // The field hands its own off colour to the composed Toggle, so the
    // composed track is what proves the field's default moved with the
    // Toggle's.
    testWidgets('the composed off track is the highest container step', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          SwitchField(label: 'Alerts', value: false, onChanged: (_) {}),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(
        _trackFill(tester),
        const CoreColor.token(CoreColors.surfaceContainerHighest),
      );
      expect(
        _trackFill(tester),
        isNot(const CoreColor.token(CoreColors.surfaceContainer)),
      );
    });

    testWidgets('the composed on track is primary', (tester) async {
      await tester.pumpWidget(
        _buildApp(SwitchField(label: 'Alerts', value: true, onChanged: (_) {})),
      );
      final _ = await tester.pumpAndSettle();

      expect(_trackFill(tester), const CoreColor.token(CoreColors.primary));
    });
  });

  group('SwitchField description', () {
    testWidgets('reads as labelSmall — 12 / 500 / 140%', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          SwitchField(
            label: 'Alerts',
            description: 'Arrival notices',
            value: false,
            onChanged: (_) {},
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final style = tester.widget<Text>(find.text('Arrival notices')).style!;
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.height, 1.4);
    });

    testWidgets('is the subtle ink, a step under the label', (tester) async {
      late ResolvedColorScheme scheme;
      await tester.pumpWidget(
        _buildApp(
          material.Builder(
            builder: (context) {
              scheme = Theme.of(context).colorScheme;
              return SwitchField(
                label: 'Alerts',
                description: 'Arrival notices',
                value: false,
                onChanged: (_) {},
              );
            },
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      material.Color token(CoreColorToken t) =>
          scheme.resolve(CoreColor.token(t)).toValue();
      final style = tester.widget<Text>(find.text('Arrival notices')).style!;
      expect(style.color, token(CoreColors.onSurfaceSubtle));
      // The negative control: the description is not the label's
      // `onSurfaceVariant`.
      expect(style.color, isNot(token(CoreColors.onSurfaceVariant)));
    });

    testWidgets('a disabled field sets the same description', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const SwitchField(
            label: 'Alerts',
            description: 'Arrival notices',
            value: false,
            onChanged: null,
            enabled: false,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final style = tester.widget<Text>(find.text('Arrival notices')).style!;
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w500);
      expect(style.height, 1.4);
    });

    testWidgets('a disabled field keeps the subtle ink', (tester) async {
      late ResolvedColorScheme scheme;
      await tester.pumpWidget(
        _buildApp(
          material.Builder(
            builder: (context) {
              scheme = Theme.of(context).colorScheme;
              return const SwitchField(
                label: 'Alerts',
                description: 'Arrival notices',
                value: false,
                onChanged: null,
                enabled: false,
              );
            },
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final style = tester.widget<Text>(find.text('Arrival notices')).style!;
      expect(
        style.color,
        scheme
            .resolve(const CoreColor.token(CoreColors.onSurfaceSubtle))
            .toValue(),
      );
    });
  });

  group('SwitchField enabled follows the callback', () {
    // Read off the rendered semantics node, not off the declared flag: a row
    // that looks live and does nothing is exactly what this group is about.
    SemanticsData row(WidgetTester tester) =>
        tester.getSemantics(find.text('Alerts')).getSemanticsData();

    testWidgets('a field nobody listens to reads as disabled', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const SwitchField(label: 'Alerts', value: true, onChanged: null),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final data = row(tester);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
    });

    testWidgets('a field with a callback reads as enabled', (tester) async {
      await tester.pumpWidget(
        _buildApp(SwitchField(label: 'Alerts', value: true, onChanged: (_) {})),
      );
      final _ = await tester.pumpAndSettle();

      expect(row(tester).flagsCollection.isEnabled, Tristate.isTrue);
    });

    testWidgets('and is drawn like a field that was told to be disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const SwitchField(label: 'Alerts', value: true, onChanged: null),
        ),
      );
      final _ = await tester.pumpAndSettle();
      final derived = _trackFill(tester);

      await tester.pumpWidget(
        _buildApp(
          SwitchField(
            label: 'Alerts',
            value: true,
            onChanged: (_) {},
            enabled: false,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      final told = _trackFill(tester);

      await tester.pumpWidget(
        _buildApp(SwitchField(label: 'Alerts', value: true, onChanged: (_) {})),
      );
      final _ = await tester.pumpAndSettle();
      final live = _trackFill(tester);

      // The negative control is the third reading: if the derived field were
      // drawn as a live one, `derived` would equal `live`, not `told`.
      expect(derived, told);
      expect(derived, isNot(live));
    });

    testWidgets('what the app states still wins over the callback', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const SwitchField(
            label: 'Alerts',
            value: true,
            onChanged: null,
            enabled: true,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(row(tester).flagsCollection.isEnabled, Tristate.isTrue);
    });
  });
}
