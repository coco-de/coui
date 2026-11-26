import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _title = 'Description title';

material.TextStyle _titleStyle(WidgetTester tester) => tester
    .widget<material.RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is material.RichText && widget.text.toPlainText() == _title,
      ),
    )
    .text
    .style!;

Future<void> _pumpCard(
  WidgetTester tester, {
  CoreDescriptionCardSize size = .md,
  CoreDescriptionCardStyle? style,
  CoreDescriptionCardStyle? themeStyle,
  bool dark = false,
}) async {
  // Overlay.initialEntries belongs to its first mount, so replace the
  // test shell before changing its child in a later assertion.
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpTestApp(
    tester,
    DescriptionCard(
      title: _title,
      size: size,
      rows: const [DescriptionRow(label: 'Label', value: 'Value')],
      descriptionCardStyle: style,
    ),
    theme: ThemeData.fromCore(
      dark ? CoreThemePresets.dark : CoreThemePresets.light,
    ),
    componentTheme: CoreComponentTheme(
      descriptionCard: CoreDescriptionCardTheme(style: themeStyle),
    ),
  );
}

void main() {
  final tokens = <String, (CoreTextStyle?, CoreTextStyle)>{
    'code': (null, const CoreTextStyle.token(CoreTextStyles.codeMd)),
    'raw': (
      null,
      const CoreTextStyle.token(CoreTextStyles.codeMd).copyWith(
        fontSize: 17,
        lineHeight: 1.3,
        lineHeightPx: 20.3,
        fontWeight: CoreFontWeight.bold,
        letterSpacing: 0.03,
        color: const CoreColor(0xFF123456),
      ),
    ),
    'replace': (
      const CoreTextStyle.token(CoreTextStyles.codeMd).copyWith(
        fontSize: 17,
        lineHeightPx: 20.3,
        fontWeight: CoreFontWeight.semiBold,
        letterSpacing: 0.02,
      ),
      const CoreTextStyle.token(CoreTextStyles.bodyLarge),
    ),
    'same': (
      const CoreTextStyle.token(CoreTextStyles.codeMd).copyWith(
        fontSize: 17,
        lineHeightPx: 20.3,
        fontWeight: CoreFontWeight.semiBold,
      ),
      const CoreTextStyle.token(CoreTextStyles.codeMd),
    ),
  };
  for (final dark in [false, true]) {
    for (final entry in tokens.entries) {
      testWidgets(
        'title token ${entry.key} keeps Core merge semantics, dark=$dark',
        (
          tester,
        ) async {
          await _pumpCard(
            tester,
            dark: dark,
            themeStyle: CoreDescriptionCardStyle(
              titleTextStyle: entry.value.$1,
            ),
            style: CoreDescriptionCardStyle(titleTextStyle: entry.value.$2),
          );
          final title = _titleStyle(tester);
          final fixed = entry.key == 'raw' || entry.key == 'same';
          // The size fallback is an existing raw role, so it still supplies
          // its measures after a newer token discards the earlier overlay.
          expect(title.fontSize, fixed ? 17 : 15);
          expect(title.height, fixed ? 20.3 / 17 : 1.4);
          // The card lays SemiBold over every size role
          // (`defaultTitleTextStyle`); a later role keeps that weight
          // overlay (Core merge), only an explicit weight replaces it.
          expect(title.fontWeight?.value, switch (entry.key) {
            'raw' => 700,
            _ => CoreFontWeight.semiBold,
          });
          expect(
            title.fontFamily,
            entry.key == 'replace' ? CoreFontFamily.sans : CoreFontFamily.mono,
          );
          expect(title.letterSpacing, switch (entry.key) {
            'code' => -0.15,
            'raw' => 0.51,
            'replace' => 0.3,
            _ => -0.17,
          });
          if (entry.key == 'raw') {
            expect(title.color, const material.Color(0xFF123456));
          }
        },
      );
    }
  }

  for (final dark in [false, true]) {
    testWidgets('titleColor retains priority over a token color, dark=$dark', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        dark: dark,
        style: const CoreDescriptionCardStyle(
          titleColor: CoreColor(0xFF654321),
          titleTextStyle: CoreTextStyle.token(
            CoreTextStyles.codeMd,
            color: CoreColor.token(CoreColors.primary),
          ),
        ),
      );
      expect(_titleStyle(tester).fontFamily, CoreFontFamily.mono);
      expect(_titleStyle(tester).color, const material.Color(0xFF654321));
    });

    for (final size in CoreDescriptionCardSize.values) {
      testWidgets('default title retains $size role, dark=$dark', (
        tester,
      ) async {
        await _pumpCard(tester, size: size, dark: dark);

        final style = _titleStyle(tester);
        final role =
            CoreDescriptionCardStyle.defaultsBySize[size]!.titleTextStyle!;
        final scheme =
            (dark ? CoreThemePresets.dark : CoreThemePresets.light).colorScheme;
        expect(style.fontSize, role.fontSize);
        // SemiBold on every rung (#6470) — the size role keeps its
        // size / line height / tracking.
        expect(style.fontWeight?.value, CoreFontWeight.semiBold);
        expect(style.height, role.lineHeight);
        expect(style.fontFamily, CoreFontFamily.sans);
        expect(
          style.color,
          scheme.resolve(CoreDescriptionCardStyle.defaultTitleColor).toValue(),
        );
      });
    }
  }

  testWidgets('a partial title override retains its size role', (tester) async {
    await _pumpCard(
      tester,
      size: .lg,
      style: const CoreDescriptionCardStyle(
        titleTextStyle: CoreTextStyle(letterSpacing: 0.04),
      ),
    );

    final style = _titleStyle(tester);
    final role = CoreDescriptionCardStyle
        .defaultsBySize[CoreDescriptionCardSize.lg]!
        .titleTextStyle!;
    expect(style.fontSize, role.fontSize);
    expect(style.fontWeight?.value, CoreFontWeight.semiBold);
    expect(style.height, role.lineHeight);
    expect(style.letterSpacing, 0.04 * role.fontSize!);
  });

  testWidgets('title draws theme typography and widget partial overrides', (
    tester,
  ) async {
    const themeStyle = CoreDescriptionCardStyle(
      titleTextStyle: CoreTextStyle(
        fontSize: 17,
        fontWeight: CoreFontWeight.bold,
        letterSpacing: 0.03,
        lineHeight: 1.3,
        fontFamily: CoreFontFamily.mono,
        color: CoreColor(0xFF123456),
      ),
    );
    await _pumpCard(tester, themeStyle: themeStyle);
    var style = _titleStyle(tester);
    expect(style.fontSize, 17);
    expect(style.fontWeight, material.FontWeight.w700);
    expect(style.letterSpacing, 0.51);
    expect(style.height, 1.3);
    expect(style.fontFamily, CoreFontFamily.mono);
    expect(
      style.fontFamilyFallback,
      contains('packages/coui_flutter/GeistMono'),
    );
    expect(style.color, const material.Color(0xFF123456));

    await _pumpCard(
      tester,
      themeStyle: themeStyle,
      style: const CoreDescriptionCardStyle(
        titleTextStyle: CoreTextStyle(
          fontSize: 19,
          fontWeight: CoreFontWeight.semiBold,
        ),
      ),
    );
    style = _titleStyle(tester);
    expect(style.fontSize, 19);
    expect(style.fontWeight, material.FontWeight.w600);
    expect(style.letterSpacing, 0.03 * 19);
    expect(style.height, 1.3);
    expect(style.fontFamily, CoreFontFamily.mono);
    expect(style.color, const material.Color(0xFF123456));
    final label = tester.widget<material.Text>(find.text('Label')).style!;
    expect(label.fontSize, 14);
    expect(label.fontFamily, CoreFontFamily.sans);
    expect(label.fontWeight, material.FontWeight.w400);
  });

  testWidgets('a fixed title line box wins over a simultaneous ratio', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      style: const CoreDescriptionCardStyle(
        titleTextStyle: CoreTextStyle(
          fontSize: 17,
          lineHeight: 1.3,
          lineHeightPx: 20.3,
        ),
      ),
    );

    expect(_titleStyle(tester).height, 20.3 / 17);
  });

  testWidgets('a later title ratio replaces a theme fixed line box', (
    tester,
  ) async {
    await _pumpCard(
      tester,
      themeStyle: const CoreDescriptionCardStyle(
        titleTextStyle: CoreTextStyle(fontSize: 17, lineHeightPx: 20.3),
      ),
      style: const CoreDescriptionCardStyle(
        titleTextStyle: CoreTextStyle(lineHeight: 1.3),
      ),
    );

    expect(_titleStyle(tester).height, 1.3);
    expect(_titleStyle(tester).fontSize, 17);
  });

  for (final dark in [false, true]) {
    testWidgets('titleColor retains priority over slot color, dark=$dark', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        dark: dark,
        themeStyle: const CoreDescriptionCardStyle(
          titleColor: CoreColor(0xFF654321),
        ),
        style: const CoreDescriptionCardStyle(
          titleTextStyle: CoreTextStyle(color: CoreColor(0xFF123456)),
        ),
      );
      expect(_titleStyle(tester).color, const material.Color(0xFF654321));

      await _pumpCard(
        tester,
        dark: dark,
        style: const CoreDescriptionCardStyle(
          titleColor: CoreColor.transparent,
          titleTextStyle: CoreTextStyle(color: CoreColor(0xFF123456)),
        ),
      );
      expect(_titleStyle(tester).color, const material.Color(0x00000000));
    });
  }
}
