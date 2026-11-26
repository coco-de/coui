@TestOn('vm')
library;

import 'package:coui_web/coui_web.dart' show CoUIWeb, CoreSurfaceStyleId, ThemeData;
import 'package:docs_core/shared/docs_navigation.dart';
import 'package:docs_site/components/preview_gallery.dart';
import 'package:docs_site/components/site_drawer.dart';
import 'package:docs_site/components/site_theme_tools.dart';
import 'package:docs_site/components/style_setup_code.dart';
import 'package:docs_site/components/surface_style_switcher.dart';
import 'package:docs_site/main.server.options.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_test/server_test.dart';

void main() {
  setUpAll(() => Jaspr.initializeApp(options: defaultServerOptions));
  testServer('only the selected variant mounts paired previews and code starts collapsed', (tester) async {
    tester.pumpComponent(
      CoUIWeb(
        theme: ThemeData.coui,
        child: const PreviewGallery(
          componentName: 'button',
          variants: ['primary', 'secondary', 'chain'],
          panelId: 'preview-button-test',
        ),
      ),
    );
    final response = await tester.request('/');
    final document = response.document!;
    expect(response.body, contains('<!--@preview_gallery'));
    expect(response.body, isNot(contains('<!--@docs_core:web_preview')));
    expect(response.body, isNot(contains('<!--@flutter_preview')));
    expect(document.querySelectorAll('.live-preview'), hasLength(1));
    expect(document.querySelectorAll('.preview-web'), hasLength(1));
    expect(document.querySelectorAll('.preview-flutter'), hasLength(1));
    expect(document.querySelector('.preview-code')!.localName, 'details');
    expect(document.querySelector('.preview-code')!.attributes.containsKey('open'), isFalse);
    expect(document.querySelectorAll('[role="tab"]'), hasLength(3));
  });
  testServer('every offered style and mode has both export configurations', (tester) async {
    tester.pumpComponent(CoUIWeb(theme: ThemeData.coui, child: const SiteThemeTools()));
    final document = (await tester.request('/')).document!;
    final templates = document.querySelectorAll('template[data-theme-snippet]');
    expect(templates, hasLength(SurfaceStyleSwitcher.offered.length * 4));
    final code = templates.map((e) => e.text).join('\n');
    expect(code, contains('CoreThemeMode.dark'));
    expect(code, contains('SurfaceStyleScope.setSurfaceStyle'));
    expect(code, contains('CoUIThemeController.setTheme'));
  });
  testServer('the drawer reaches every tab and its sidebar documents without hydration', (
    tester,
  ) async {
    // The drawer is a `popover`: its button opens it natively, so the links
    // below are reachable before (or without) the client bundle.
    for (final tab in kDocsNavTabs) {
      tester.pumpComponent(
        CoUIWeb(
          theme: ThemeData.coui,
          child: SiteDrawer(currentPath: tab.path),
        ),
      );
      final document = (await tester.request('/')).document!;
      final links = document.querySelectorAll('nav a[href]').map((e) => e.attributes['href']).toSet();

      expect(document.querySelector('aside[popover]'), isNotNull);
      expect(links, containsAll([for (final each in kDocsNavTabs) each.path]));
      expect(
        links,
        containsAll([
          for (final page in tab.pages)
            if (page.path != '/components/icon') page.path,
        ]),
        reason: tab.id,
      );
      if (tab.id == 'components') {
        // The Icon card stays in the catalog. The icon guide is in Foundations.
        expect(links, isNot(contains('/components/icon')));
      }
    }
  });
  test('exported configuration retains the selected surface and mode', () {
    final flutter = surfaceSetupCode(style: CoreSurfaceStyleId.liquidGlass, dark: true, forFlutter: true);
    expect(flutter, contains('surfaceStyle: CoreSurfaceStyleId.liquidGlass'));
    expect(flutter, contains('themeMode: CoreThemeMode.dark'));
    final web = surfaceSetupCode(style: CoreSurfaceStyleId.neoBrutalism, dark: false, forFlutter: false);
    expect(web, contains('SurfaceStyleScope.setSurfaceStyle(CoreSurfaceStyleId.neoBrutalism)'));
    expect(web, contains('CoUIThemeController.light'));
  });
}
