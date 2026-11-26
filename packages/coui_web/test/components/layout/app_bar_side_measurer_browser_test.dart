@TestOn('browser')
library;

import 'package:coui_web/src/components/layout/app_bar/app_bar_side_measurer_web.dart';
import 'package:coui_web/src/components/layout/app_bar/app_bar_style.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  test(
    'CSSOM side width survives root text scaling and follows resizing',
    () async {
      final documentRoot = web.document.documentElement! as web.HTMLElement;
      final oldFontSize = documentRoot.style.fontSize;
      final root = web.document.createElement('div') as web.HTMLDivElement;
      root.style
        ..display = 'grid'
        ..width = '480px'
        ..gridTemplateColumns =
            'var($kAppBarSideVar, max-content) '
            'minmax(0,1fr) var($kAppBarSideVar, max-content)';
      final anchor = web.document.createElement('span')
        ..id = 'measured-bar-anchor';
      final leading = (web.document.createElement('div') as web.HTMLDivElement)
        ..setAttribute('data-coui-app-bar-leading', '')
        ..style.width = '40px'
        ..style.height = '20px';
      final trailing = (web.document.createElement('div') as web.HTMLDivElement)
        ..setAttribute('data-coui-app-bar-trailing', '')
        ..style.width = '120px'
        ..style.height = '20px';
      root
        ..appendChild(anchor)
        ..appendChild(leading)
        ..appendChild(trailing);
      web.document.body!.appendChild(root);
      final measurer = AppBarSideMeasurer(anchorId: anchor.id);
      addTearDown(() {
        measurer.dispose();
        root.remove();
        documentRoot.style.fontSize = oldFontSize;
      });
      double side() => double.parse(
        root.style.getPropertyValue(kAppBarSideVar).replaceFirst('px', ''),
      );
      documentRoot.style.fontSize = '16px';
      measurer.attach();
      expect(side(), 120);
      documentRoot.style.fontSize = '24px';
      expect(side(), 120);
      expect(
        web.window.getComputedStyle(root).gridTemplateColumns,
        startsWith('120px '),
      );
      trailing.style.width = '180px';
      final deadline = DateTime.now().add(const Duration(seconds: 3));
      while (side() != 180 && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(side(), 180);
      measurer.dispose();
      expect(root.style.getPropertyValue(kAppBarSideVar), isEmpty);
    },
  );
}
