import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

/// #5740: the docked bar's top hairline lies over its top padding, so the
/// bar is `padding + item` tall — 80 with labels, 56 icon-only — with or
/// without the line. Read off the rendered box, not the resolver.
void main() {
  const items = [
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.house),
      label: 'Home',
    ),
    CoreNavigationBarItem.destination(
      icon: Icon(LucideIcons.search),
      label: 'Search',
    ),
  ];

  Future<Size> barSize(
    WidgetTester tester, {
    CoreNavigationLabelMode? labelMode,
    CoreNavigationBarStyle? style,
  }) async {
    await pumpTestApp(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 360,
          child: NavigationBar(
            labelMode: labelMode,
            selectedIndex: 0,
            onSelected: (_) {},
            navigationBarStyle: style,
            items: items,
          ),
        ),
      ),
    );
    await tester.pump();
    return tester.getSize(find.byType(NavigationBar));
  }

  testWidgets('a labelled bar is 80 tall, the line included', (tester) async {
    expect((await barSize(tester)).height, 80);
  });

  testWidgets('an icon-only bar is 56 tall', (tester) async {
    expect(
      (await barSize(tester, labelMode: CoreNavigationLabelMode.none)).height,
      56,
    );
  });

  testWidgets('a thicker line does not grow the bar', (tester) async {
    expect(
      (await barSize(
        tester,
        style: const CoreNavigationBarStyle(barBorderWidth: 4),
      )).height,
      80,
    );
  });

  testWidgets('the line is painted over the bar, top edge only', (
    tester,
  ) async {
    await barSize(tester);
    final hairline = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(NavigationBar),
            matching: find.byWidgetPredicate(
              (w) => w is DecoratedBox && w.position == .foreground,
            ),
          )
          .first,
    );
    final border =
        (hairline.decoration as BoxDecoration).border! as BorderDirectional;
    expect(border.top.width, 1);
    expect(border.bottom, BorderSide.none);
  });
}
