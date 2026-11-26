// Fieldset — the size-keyed legend typography ladder (md=titleSmall/16px,
// lg=titleMedium/18px), the disabled legend colour (disabled-content), the
// `variant` axis (filled / outlined / plain), the `description` slot and the
// spacing that sets the header apart from the fields.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

TextStyle _legendStyleOf(WidgetTester tester, String text) => tester
    .widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text(text),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    )
    .style;

void main() {
  group('Fieldset widget', () {
    testWidgets('renders legend and children', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Fieldset(
            legend: Text('Personal Information'),
            children: [Text('field')],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('field'), findsOneWidget);
    });

    testWidgets('respects key parameter', (tester) async {
      const testKey = Key('fieldset-key');
      await tester.pumpWidget(
        _buildApp(const Fieldset(key: testKey, children: [Text('field')])),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('md legend reads at 16px (titleSmall) — the default size', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Fieldset(
            legend: Text('Legend'),
            children: [Text('field')],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(_legendStyleOf(tester, 'Legend').fontSize, CoreFontSize.s16);
    });

    testWidgets('lg legend reads at 18px (titleMedium) — a different rung', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Fieldset(
            legend: Text('Legend'),
            size: CoreComponentSize.lg,
            children: [Text('field')],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(_legendStyleOf(tester, 'Legend').fontSize, CoreFontSize.s18);
    });

    testWidgets(
      'a disabled fieldset tones the legend with disabledLegendColor '
      '(disabled-content, not the onSurfaceVariant convention other '
      'form components use)',
      (tester) async {
        await tester.pumpWidget(
          _buildApp(
            const Fieldset(
              legend: Text('Legend'),
              enabled: false,
              children: [Text('field')],
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final expectedColor = Theme.of(tester.element(find.text('Legend')))
            .colorScheme
            .resolve(CoreFieldsetStyle.defaultDisabledLegendColor)
            .toValue();
        expect(_legendStyleOf(tester, 'Legend').color, expectedColor);
      },
    );

    testWidgets(
      'disabledLegendColor override reaches the disabled legend',
      (tester) async {
        const overrideColor = Color(0xFF654321);
        await tester.pumpWidget(
          _buildApp(
            const Fieldset(
              legend: Text('Legend'),
              enabled: false,
              fieldsetStyle: CoreFieldsetStyle(
                disabledLegendColor: CoreColor(0xFF654321),
              ),
              children: [Text('field')],
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        expect(_legendStyleOf(tester, 'Legend').color, overrideColor);
      },
    );

    testWidgets('an enabled fieldset legend is not toned disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Fieldset(
            legend: Text('Legend'),
            children: [Text('field')],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final disabledColor = Theme.of(tester.element(find.text('Legend')))
          .colorScheme
          .resolve(CoreFieldsetStyle.defaultDisabledLegendColor)
          .toValue();
      expect(_legendStyleOf(tester, 'Legend').color, isNot(disabledColor));
    });
  });

  group('Fieldset variants', () {
    CoreOutlinedContainerStyle containerOf(WidgetTester tester) => tester
        .widget<OutlinedContainer>(find.byType(OutlinedContainer))
        .containerStyle!;

    testWidgets('defaults to filled: panel fill, subtle edge, 16 corner', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Fieldset(legend: Text('L'), children: [Text('f')]),
      );

      final box = containerOf(tester);
      expect(
        box.backgroundColor,
        CoreFieldsetStyle.defaultFilledBackgroundColor,
      );
      expect(box.borderColor, CoreFieldsetStyle.defaultBorderColor);
      expect(box.borderWidth, CoreStrokeWidth.stroke1);
      expect(box.borderRadius, CoreFieldsetStyle.defaultBorderRadius);
      expect(box.padding, CoreFieldsetStyle.defaultPadding);
    });

    testWidgets('outlined keeps the edge, corner and padding but no fill', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Fieldset(
          variant: .outlined,
          legend: Text('L'),
          children: [Text('f')],
        ),
      );

      final box = containerOf(tester);
      expect(box.backgroundColor, CoreFieldsetStyle.defaultBackgroundColor);
      expect(box.borderColor, CoreFieldsetStyle.defaultBorderColor);
      expect(box.borderWidth, CoreStrokeWidth.stroke1);
      expect(box.borderRadius, CoreFieldsetStyle.defaultBorderRadius);
      expect(box.padding, CoreFieldsetStyle.defaultPadding);
    });

    testWidgets('plain draws no box: no fill, edge, corner or padding', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Fieldset(
          variant: .plain,
          legend: Text('L'),
          children: [Text('f')],
        ),
      );

      final box = containerOf(tester);
      expect(box.backgroundColor, CoreFieldsetStyle.defaultBackgroundColor);
      expect(box.borderWidth, CoreStrokeWidth.stroke0);
      expect(box.borderRadius, CoreBorderRadius.zero);
      expect(box.padding, CoreEdgeInsets.zero);
    });

    // A style that injects a cast needs a resolved theme — the same app
    // shell the cast tests elsewhere use.
    Future<List<BoxShadow>> injectedCastUnderNeoBrutalism(
      WidgetTester tester,
      Fieldset fieldset,
    ) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          home: Center(child: fieldset),
        ),
      );
      await tester.pumpAndSettle();

      return tester
          .widgetList<InjectedCast>(find.byType(InjectedCast))
          .expand((c) => c.shadows)
          .toList();
    }

    testWidgets('plain paints no cast under a style that injects one', (
      tester,
    ) async {
      // A cast around a box that is not there would float as a stray shadow.
      final shadows = await injectedCastUnderNeoBrutalism(
        tester,
        const Fieldset(variant: .plain, children: [Text('f')]),
      );
      expect(shadows, isEmpty);
    });

    testWidgets('outlined still takes the style cast through InjectedCast', (
      tester,
    ) async {
      final shadows = await injectedCastUnderNeoBrutalism(
        tester,
        const Fieldset(variant: .outlined, children: [Text('f')]),
      );
      expect(shadows, isNotEmpty);
    });

    const themeRow = CoreComponentTheme(
      fieldset: CoreFieldsetTheme(
        variantStyles: {
          CoreFieldsetVariant.outlined: CoreFieldsetStyle(
            borderColor: CoreColor(0xFF123456),
          ),
        },
      ),
    );

    testWidgets('a theme variantStyles row reaches its own variant', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Fieldset(variant: .outlined, children: [Text('f')]),
        componentTheme: themeRow,
      );
      expect(containerOf(tester).borderColor, const CoreColor(0xFF123456));
    });

    testWidgets('a theme variantStyles row leaves the other variants alone', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Fieldset(children: [Text('f')]),
        componentTheme: themeRow,
      );
      expect(
        containerOf(tester).borderColor,
        CoreFieldsetStyle.defaultBorderColor,
      );
    });

    testWidgets('the widget fieldsetStyle wins over the variant row', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Fieldset(
          variant: .plain,
          fieldsetStyle: CoreFieldsetStyle(padding: CoreEdgeInsets.all(8)),
          children: [Text('f')],
        ),
      );
      expect(containerOf(tester).padding, const CoreEdgeInsets.all(8));
    });
  });

  group('Fieldset description and spacing', () {
    // Fixed-height fields make the gaps between the rectangles exact.
    const field = SizedBox(width: 80, height: 32);

    testWidgets('description renders in bodySmall / on-surface-variant', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Fieldset(
          legend: Text('Legend'),
          description: Text('Description'),
          children: [field],
        ),
      );

      final style = _legendStyleOf(tester, 'Description');
      final theme = Theme.of(tester.element(find.text('Description')));
      expect(
        style.fontSize,
        CoreFieldsetStyle.defaultDescriptionTextStyle
            .toValue(theme: theme)
            .fontSize,
      );
      expect(
        style.color,
        theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
            .toValue(),
      );
    });

    testWidgets('legend → description 4, header → first field 12', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Fieldset(
          legend: Text('Legend'),
          description: Text('Description'),
          children: [field],
        ),
      );

      final legend = tester.getRect(find.text('Legend'));
      final description = tester.getRect(find.text('Description'));
      final first = tester.getRect(find.byWidget(field));
      expect(description.top - legend.bottom, CoreSpace.space4);
      expect(first.top - description.bottom, CoreSpace.space12);
    });

    testWidgets('legend alone → first field 12', (tester) async {
      await pumpTestApp(
        tester,
        const Fieldset(legend: Text('Legend'), children: [field]),
      );

      final legend = tester.getRect(find.text('Legend'));
      final first = tester.getRect(find.byWidget(field));
      expect(first.top - legend.bottom, CoreSpace.space12);
    });

    testWidgets('fields sit 16 apart', (tester) async {
      await pumpTestApp(
        tester,
        const Fieldset(
          legend: Text('Legend'),
          children: [
            SizedBox(key: Key('a'), width: 80, height: 32),
            SizedBox(key: Key('b'), width: 80, height: 32),
          ],
        ),
      );

      final a = tester.getRect(find.byKey(const Key('a')));
      final b = tester.getRect(find.byKey(const Key('b')));
      expect(b.top - a.bottom, CoreSpace.space16);
    });

    testWidgets('the legend starts on the same line as the fields', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Fieldset(legend: Text('Legend'), children: [field]),
      );

      final legend = tester.getRect(find.text('Legend'));
      final first = tester.getRect(find.byWidget(field));
      expect(legend.left, first.left);
    });

    testWidgets('no header: the first field sits at the box padding', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Fieldset(children: [field]),
      );

      final box = tester.getRect(find.byType(OutlinedContainer));
      final first = tester.getRect(find.byWidget(field));
      // 1px edge + 16px padding.
      expect(first.top - box.top, CoreStrokeWidth.stroke1 + CoreSpace.space16);
    });

    testWidgets('a disabled fieldset does not recolour the description', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        const Fieldset(
          enabled: false,
          legend: Text('Legend'),
          description: Text('Description'),
          children: [field],
        ),
      );

      final theme = Theme.of(tester.element(find.text('Description')));
      expect(
        _legendStyleOf(tester, 'Description').color,
        theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
            .toValue(),
      );
    });
  });
}
