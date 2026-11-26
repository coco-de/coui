// #5149 — component icons render on their first frame with no network
// request. Before, every component chrome icon (Select chevron, Alert
// glyph, Pagination arrows, Checkbox check …) was fetched from the Iconify
// API at runtime and stayed an empty box offline, behind a strict CSP and
// in every widget test.
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fails the test if anything opens an HTTP client.
class _NoNetwork extends HttpOverrides {
  final opened = <String>[];

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    opened.add(StackTrace.current.toString().split('\n').take(6).join('\n'));

    return super.createHttpClient(context);
  }
}

Future<_NoNetwork> _pumpOffline(WidgetTester tester, Widget home) async {
  final network = _NoNetwork();
  final previous = HttpOverrides.current;
  HttpOverrides.global = network;
  addTearDown(() => HttpOverrides.global = previous);
  IconResolver.instance.clearMemoryCache();

  await tester.pumpWidget(CoUIApp(theme: const ThemeData(), home: home));
  return network;
}

void main() {
  test('every bundled component icon resolves without a preload', () {
    IconResolver.instance.clearMemoryCache();
    for (final id in CoreBundledIcons.icons.keys) {
      expect(IconResolver.instance.has(id), isTrue, reason: id);
    }
  });

  testWidgets(
    'component chrome icons paint on the first frame and request nothing',
    (tester) async {
      final network = await _pumpOffline(
        tester,
        Column(
          children: [
            Select<String>(
              placeholder: 'x',
              items: const [CoreSelectItem(value: 'a', label: 'A')],
              onChanged: (_) {},
            ),
            const Alert.info(title: 'Saved'),
            Checkbox(checked: true, onChanged: (_) {}),
            Pagination(page: 2, totalPages: 5, onPageChanged: (_) {}),
          ],
        ),
      );

      // First frame — no pump for an async fetch to land.
      final icons = find.byType(Icon);
      expect(icons, findsWidgets);
      for (final element in icons.evaluate()) {
        expect(
          find.descendant(
            of: find.byWidget(element.widget),
            matching: find.byType(SvgPicture),
          ),
          findsOneWidget,
          reason: '${(element.widget as Icon).icon.id} drew an empty box',
        );
      }

      await tester.pump(const Duration(seconds: 1));
      expect(network.opened, isEmpty, reason: network.opened.join('\n---\n'));
    },
  );

  testWidgets('a registered icon still wins over the bundled one', (
    tester,
  ) async {
    final id = LucideIcons.check.id;
    const custom = IconSvgData(body: '<circle cx="12" cy="12" r="4"/>');
    IconResolver.instance.register(id, custom);
    addTearDown(IconResolver.instance.clearMemoryCache);

    expect(IconResolver.instance.get(id), same(custom));
  });
}
