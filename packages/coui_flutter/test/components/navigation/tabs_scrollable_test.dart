import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as m;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _labels = [
  'Account and privacy settings',
  '계정 및 개인정보 보호 설정',
  'アカウントとプライバシーの設定',
  '账户和隐私设置',
  'Kontoeinstellungen und Datenschutz',
  'Paramètres du compte et confidentialité',
  'Configuración de cuenta y privacidad',
  'Configurações de conta e privacidade',
  'Impostazioni account e riservatezza',
  'Настройки аккаунта и конфиденциальности',
  'إعدادات الحساب والخصوصية',
];

Widget _app(Widget child, double width, double scale) => m.MaterialApp(
  home: m.Scaffold(
    body: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Theme(
        data: const ThemeData(),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: child),
        ),
      ),
    ),
  ),
);

void main() {
  for (final variant in CoreTabVariant.values) {
    for (final scale in [1.0, 2.0]) {
      for (final width in [160.0, 320.0]) {
        testWidgets('$variant $scale× at $width retains 11 long labels', (
          tester,
        ) async {
          int? selected;
          await tester.pumpWidget(
            _app(
              Tabs.labels(
                labels: _labels,
                selectedIndex: 0,
                onChanged: (index) => selected = index,
                variant: variant,
                expand: true,
                scrollable: true,
              ),
              width,
              scale,
            ),
          );
          expect(tester.takeException(), isNull);
          for (final label in _labels) {
            expect(find.text(label), findsOneWidget);
          }
          final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
          expect(scroll.position.maxScrollExtent, greaterThan(0));
          expect(
            tester.getSize(find.byType(Tabs)).width,
            lessThanOrEqualTo(width),
          );
          await tester.drag(find.byType(Tabs), const Offset(-100, 0));
          await tester.pumpAndSettle();
          expect(scroll.position.pixels, greaterThan(0));
          expect(selected, isNull, reason: 'drag scroll must not select a tab');
          scroll.position.jumpTo(scroll.position.maxScrollExtent);
          await tester.pumpAndSettle();
          final visibleLabel = tester
              .getRect(find.text(_labels.last))
              .intersect(
                tester.getRect(find.byType(SingleChildScrollView)),
              );
          expect(visibleLabel.width, greaterThan(0));
          await tester.tapAt(visibleLabel.center);
          await tester.pumpAndSettle();
          expect(selected, _labels.length - 1);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('keyboard focus reveals an offscreen tab and Enter selects it', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      _app(
        Tabs.labels(
          labels: _labels,
          selectedIndex: 0,
          onChanged: (index) => selected = index,
          scrollable: true,
        ),
        320,
        2,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    for (var i = 1; i < _labels.length; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, _labels.length - 1);
    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('RTL scrolling preserves badges and independent close actions', (
    tester,
  ) async {
    var closed = false;
    int? selected;
    await tester.pumpWidget(
      _app(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Tabs(
            tabs: [
              for (final label in _labels)
                CoreTabItem<Widget>(
                  label: label,
                  badge: const Text('99'),
                  onClose: () => closed = true,
                ),
            ],
            selectedIndex: 0,
            onChanged: (index) => selected = index,
            scrollable: true,
          ),
        ),
        320,
        2,
      ),
    );
    expect(tester.takeException(), isNull);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scroll.position.axisDirection, AxisDirection.left);
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Button).last);
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(selected, isNull);
    expect(find.text('99'), findsNWidgets(_labels.length));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty scrollable tabs and unbounded width remain legal', (
    tester,
  ) async {
    for (final labels in [
      <String>[],
      ['Account', 'Settings'],
    ]) {
      await tester.pumpWidget(
        _app(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tabs.labels(
                labels: labels,
                selectedIndex: 0,
                expand: true,
                scrollable: true,
              ),
            ],
          ),
          320,
          1,
        ),
      );
      expect(tester.takeException(), isNull);
    }
  });

  test('scrolling defaults off and survives copyWith and style chains', () {
    final tabs = Tabs.labels(labels: _labels, selectedIndex: 0);
    expect(tabs.scrollable, isFalse);
    expect(tabs.copyWith(scrollable: true).primary.scrollable, isTrue);
  });
}
