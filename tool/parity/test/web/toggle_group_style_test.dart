import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' show MediaFeature;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

void main() {
  test(
    'ToggleGroup preserves arbitrary and reduced-motion durations',
    () async {
      final durations = <String, Duration?>{
        'default': null,
        'zero': Duration.zero,
        'token': const Duration(milliseconds: 150),
        'arbitrary': const Duration(milliseconds: 123),
        'display': const Duration(milliseconds: 2000),
      };
      // SSR is itself part of this contract: an arbitrary Duration must render.
      final body = await renderComponentBodyHtml(
        Component.fragment([
          Style(styles: docsContentTheme().styles),
          CoUIWeb(
            theme: .coui,
            child: div([
              for (final entry in durations.entries)
                ToggleGroup<String>(
                  id: 'group-${entry.key}',
                  value: 'am',
                  onChanged: (_) {},
                  items: const [
                    CoreToggleGroupItem(value: 'am', label: 'Morning'),
                    CoreToggleGroupItem(value: 'pm', label: 'Afternoon'),
                  ],
                  toggleGroupStyle: CoreToggleGroupStyle(
                    transitionDuration: entry.value,
                  ),
                ),
            ]),
          ),
        ]),
      );
      final dir = Directory.systemTemp.createTempSync('coui-toggle-duration-');
      final browser = await launchCaptureBrowser(width: 800, height: 1200);
      try {
        final page = await browser.newPage();
        await page.setOfflineMode(true);
        final errors = <String>[];
        page.onError.listen((error) => errors.add('$error'));

        Future<List<Map<String, dynamic>>> measure() async {
          final rows = await page.evaluate<List<dynamic>>('''
() => [...document.querySelectorAll('[id^="group-"]')].flatMap(group =>
  [...group.querySelectorAll('[role="radio"]')].map((radio, index) => {
    const face = radio.querySelector(':scope > div[style*="height:"]');
    const rect = face.getBoundingClientRect();
    const hit = document.elementFromPoint(rect.x + rect.width / 2,
      rect.y + rect.height / 2);
    return {id: group.id, index,
      duration: parseFloat(getComputedStyle(face).transitionDuration) * 1000,
      geometry: [rect.x, rect.y, rect.width, rect.height],
      checked: radio.getAttribute('aria-checked'),
      tabIndex: radio.getAttribute('tabindex'),
      hit: hit.closest('[role="radio"]') === radio};
  }))
''');
          return rows.cast<Map<String, dynamic>>();
        }

        for (final theme in ['light', 'dark']) {
          await page.emulateMediaFeatures([
            MediaFeature.prefersReducedMotion('no-preference'),
          ]);
          final file = File('${dir.path}/$theme.html')
            ..writeAsStringSync(
              buildOfflineTailwindHarnessHtml(
                bodyHtml: body,
                themeConfig: ThemeConfig.defaults(),
                theme: theme,
                vendoredTailwindScript: loadVendoredTailwindScript(),
                additionalHeadHtml: '<style>${buildLocalFontFaceCss()}</style>',
                // Read the real transition, not the screenshot-only freeze.
                animationFreezeCss: '',
              ),
            );
          await page.goto(file.uri.toString(), wait: .load);
          await page.evaluate<void>('() => document.fonts.ready');
          final normal = await measure();
          expect(normal, hasLength(durations.length * 2));
          for (final row in normal) {
            final name = (row['id'] as String).substring('group-'.length);
            final duration =
                durations[name] ??
                CoreToggleGroupStyle.defaultTransitionDuration;
            expect(
              row['duration'],
              duration.inMilliseconds,
              reason: '$theme $row',
            );
            expect(row['checked'], row['index'] == 0 ? 'true' : 'false');
            expect(row['tabIndex'], row['index'] == 0 ? '0' : '-1');
            expect(row['hit'], isTrue);
          }

          await page.emulateMediaFeatures([
            MediaFeature.prefersReducedMotion('reduce'),
          ]);
          final reduced = await measure();
          for (var i = 0; i < reduced.length; i++) {
            final row = reduced[i];
            final name = (row['id'] as String).substring('group-'.length);
            final duration =
                durations[name] ??
                CoreToggleGroupStyle.defaultTransitionDuration;
            final expected = CoreReducedMotion.isTransitionMotion(duration)
                ? 0
                : duration.inMilliseconds;
            expect(row['duration'], expected, reason: '$theme reduced $row');
            for (final field in ['geometry', 'checked', 'tabIndex', 'hit']) {
              expect(row[field], normal[i][field], reason: '$theme $field');
            }
          }

          await page.emulateMediaFeatures([
            MediaFeature.prefersReducedMotion('no-preference'),
          ]);
          // A token duration still follows its existing public variable.
          await page.evaluate<void>('''
() => document.documentElement.style.setProperty('--coui-duration-150', '73ms')
''');
          var remapped = await measure();
          for (final row in remapped) {
            if (row['id'] == 'group-token') expect(row['duration'], 73);
            if (row['id'] == 'group-arbitrary') expect(row['duration'], 123);
            if (row['id'] == 'group-zero') expect(row['duration'], 0);
          }
          await page.evaluate<void>('''
() => document.documentElement.style.setProperty('--coui-duration-150', '0ms')
''');
          remapped = await measure();
          for (final row in remapped) {
            if (row['id'] == 'group-token') expect(row['duration'], 0);
            if (row['id'] == 'group-arbitrary') expect(row['duration'], 123);
          }
        }
        expect(errors, isEmpty);
      } finally {
        await browser.close();
        dir.deleteSync(recursive: true);
      }
    },
  );
}
