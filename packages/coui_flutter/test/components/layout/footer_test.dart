import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: Align(alignment: Alignment.topCenter, child: child),
  ),
);

const _sections = [
  CoreFooterNavData<Widget>(
    title: 'Services',
    children: [Text('Branding'), Text('Design')],
  ),
];

void main() {
  testWidgets('nav-only footer still renders', (tester) async {
    await tester.pumpWidget(_app(const Footer(sections: _sections)));
    expect(tester.takeException(), isNull);
    expect(find.text('Branding'), findsOneWidget);
  });

  testWidgets('legal block renders with a long paragraph', (tester) async {
    await tester.pumpWidget(
      _app(
        const Footer(
          sections: _sections,
          company: Text('Cocode Inc.'),
          businessInfoLabel: Text('Business info'),
          businessInfo: Text(
            'CEO Jane Doe · Business registration no. 000-00-00000 · '
            'Mail-order sales registration no. 0000-Seoul-0000 · '
            'Address 000 Some Street, Seoul, Republic of Korea',
          ),
          businessInfoExpanded: true,
          links: [Text('Refund policy'), Text('Terms'), Text('Privacy')],
          copyright: Text('© 2026 Cocode Inc. All rights reserved.'),
          showDivider: true,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Cocode Inc.'), findsOneWidget);
    expect(find.text('Business info'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(
      find.text('© 2026 Cocode Inc. All rights reserved.'),
      findsOneWidget,
    );
  });

  testWidgets('an empty legal block eats no vertical space', (tester) async {
    await tester.pumpWidget(_app(const Footer(sections: _sections)));
    final withoutLegal = tester.getSize(find.byType(Footer)).height;

    await tester.pumpWidget(
      _app(
        const Footer(
          key: ValueKey('two'),
          sections: _sections,
          copyright: Text('c'),
        ),
      ),
    );
    final withCopyright = tester.getSize(find.byType(Footer)).height;

    expect(withCopyright, greaterThan(withoutLegal));
  });

  testWidgets('the tick is inlineDividerLength tall, not zero', (tester) async {
    await tester.pumpWidget(
      _app(
        const Footer(
          sections: _sections,
          links: [Text('a'), Text('b')],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final tick = tester.getSize(
      find
          .ancestor(
            of: find.byType(Divider),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(tick.height, 12.0);
  });

  testWidgets('no divider drawn by default', (tester) async {
    await tester.pumpWidget(_app(const Footer(sections: _sections)));
    expect(find.byType(Divider), findsNothing);
  });

  testWidgets('the top rule is full-bleed, not inset by the padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const Footer(sections: _sections, showDivider: true)),
    );
    final band = tester.getRect(find.byType(Footer));
    final rule = tester.getRect(find.byType(Divider));
    final title = tester.getRect(find.text('Services'));

    expect(rule.width, band.width);
    expect(rule.left, band.left);
    // …and the content it sits above is still inset.
    expect(title.left, greaterThan(band.left));
  });

  testWidgets('the disclosure toggles the footer height', (tester) async {
    await tester.pumpWidget(
      _app(
        const Footer(
          sections: _sections,
          company: Text('Cocode Inc.'),
          businessInfoLabel: Text('Business info'),
          businessInfo: Text('secret registration details'),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final collapsed = tester.getSize(find.byType(Footer)).height;

    await tester.tap(find.text('Business info'));
    await tester.pumpAndSettle();
    final expanded = tester.getSize(find.byType(Footer)).height;

    expect(expanded, greaterThan(collapsed));
  });

  testWidgets('narrow viewport does not overflow', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        const Footer(
          sections: _sections,
          company: Text('Cocode Inc.'),
          businessInfoLabel: Text('Business info'),
          businessInfo: Text(
            'CEO Jane Doe · Business registration no. 000-00-00000 · '
            'Mail-order sales registration no. 0000-Seoul-0000',
          ),
          businessInfoExpanded: true,
          links: [Text('Refund policy'), Text('Terms'), Text('Privacy')],
          copyright: Text('© 2026 Cocode Inc.'),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('centre layout actually centres', (tester) async {
    await tester.pumpWidget(
      _app(
        const Footer(
          sections: _sections,
          layout: CoreFooterLayout.center,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final footer = tester.getRect(find.byType(Footer));
    final title = tester.getRect(find.text('Services'));
    expect(title.center.dx, closeTo(footer.center.dx, 1.0));
  });
}
