import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression: an inline `Link` inside a `Table` cell used to crash (#3163).
///
/// docs_app rendering 153 doc pages natively surfaced it — two pages with a
/// link in a table cell died with `RenderLimitedBox does not implement
/// computeDryBaseline`. The root cause was `FocusOutline`'s decorative ring
/// layer (a childless box) being caught by the stack's baseline query.
void main() {
  testWidgets('Table 셀 안 WidgetSpan(Link) 가 크래시 없이 렌더된다', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      CoUIApp(
        home: Center(
          child: Table(
            rows: [
              CoreTableRowData.header(
                cells: const [CoreTableCellData(child: Text('Docs'))],
              ),
              CoreTableRowData(
                cells: [
                  CoreTableCellData(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'see '),
                          WidgetSpan(
                            alignment: .baseline,
                            baseline: .alphabetic,
                            child: Link(
                              href: 'https://example.com',
                              onPressed: () {},
                              child: const Text('guide'),
                            ),
                          ),
                          const TextSpan(text: ' for details'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        theme: ThemeData.fromCore(CoreThemePresets.previewLight),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('guide'), findsOneWidget);
  });
}
