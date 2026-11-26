import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

// `<html lang>` / `<html dir>` used to be set only via a client-side DOM
// mutation (`setHtmlLangAttribute` / `setHtmlDirAttribute`), a no-op under
// `coui_web_dom_stub.dart` during SSR — so every server-rendered page shipped
// with neither attribute, regardless of locale. These tests exercise the real
// `ServerAppBinding` path (`testServer`, not `testComponents`) so the
// attributes actually have to reach the markup, not just a mocked DOM.
void main() {
  group('CoUIWeb SSR <html lang> / <html dir>', () {
    testServer(
      'falls back to supportedLocales.first when no locale is configured '
      '(SSR has no navigator.languages to negotiate against)',
      (tester) async {
        tester.pumpComponent(
          CoUIWeb(theme: .coui, child: div([])),
        );
        final response = await tester.request('/');
        final html = response.document?.documentElement;
        expect(html?.attributes['lang'], 'en-US');
        expect(html?.attributes['dir'], 'ltr');
      },
    );

    testServer('emits an explicit locale and its resolved direction', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          locale: const Locale('ko', 'KR'),
          child: div([]),
        ),
      );
      final response = await tester.request('/');
      final html = response.document?.documentElement;
      expect(html?.attributes['lang'], 'ko-KR');
      expect(html?.attributes['dir'], 'ltr');
    });

    testServer('emits rtl for a right-to-left locale', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          locale: const Locale('ar', 'EG'),
          child: div([]),
        ),
      );
      final response = await tester.request('/');
      final html = response.document?.documentElement;
      expect(html?.attributes['lang'], 'ar-EG');
      expect(html?.attributes['dir'], 'rtl');
    });
  });
}
