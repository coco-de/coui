@Timeout(Duration(minutes: 2))
library;

import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:puppeteer/puppeteer.dart' show MediaFeature;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/ssr_render.dart';

const _kKinds = ['tabs', 'tree', 'pagination', 'sortable', 'multi-answer'];
const _kDurations = <String, Duration?>{
  'default': null,
  'zero': Duration.zero,
  'arbitrary': Duration(milliseconds: 123),
  'token': Duration(milliseconds: 150),
  'display': Duration(milliseconds: 2000),
};

Duration _defaultDuration(String kind) => switch (kind) {
  'tabs' => CoreTabsStyle.defaultIndicatorTransitionDuration,
  'tree' => CoreTreeStyle.defaultTransitionDuration,
  'pagination' => CorePaginationStyle.defaultHoverDuration,
  'sortable' => CoreSortableStyle.defaultAnimationDuration,
  'multi-answer' => CoreMultiAnswerCardStyle.defaultTransitionDuration,
  _ => throw ArgumentError.value(kind),
};

List<Component> _cases(String kind, Duration? duration) {
  Component sample(String name, Component child) => div(
    [child],
    attributes: {'data-duration-case': name, 'data-duration-kind': kind},
  );

  switch (kind) {
    case 'tabs':
      return [
        for (final variant in [CoreTabVariant.pill, CoreTabVariant.underline])
          sample(
            'tabs-${variant.name}',
            Tabs(
              tabs: const [
                CoreTabItem<Component>(label: 'Current'),
                CoreTabItem<Component>(label: 'Next'),
                CoreTabItem<Component>(label: 'Disabled', enabled: false),
              ],
              selectedIndex: 0,
              onChanged: (_) {},
              variant: variant,
              tabsStyle: CoreTabsStyle(indicatorTransitionDuration: duration),
            ),
          ),
        sample(
          'tabs-closable',
          Tabs(
            tabs: [
              CoreTabItem<Component>(label: 'Closable', onClose: () {}),
              const CoreTabItem<Component>(label: 'Next'),
            ],
            selectedIndex: 0,
            onChanged: (_) {},
            variant: .underline,
            tabsStyle: CoreTabsStyle(indicatorTransitionDuration: duration),
          ),
        ),
      ];
    case 'tree':
      return [
        sample(
          'tree',
          Tree(
            nodes: const [
              CoreTreeNode(
                id: 'expanded',
                label: 'Expanded',
                expanded: true,
                children: [CoreTreeNode(id: 'leaf', label: 'Leaf')],
              ),
              CoreTreeNode(
                id: 'closed',
                label: 'Closed',
                children: [CoreTreeNode(id: 'hidden', label: 'Hidden')],
              ),
            ],
            treeStyle: CoreTreeStyle(transitionDuration: duration),
          ),
        ),
      ];
    case 'pagination':
      return [
        for (final page in [1, 10])
          sample(
            'pagination-$page',
            Pagination(
              page: page,
              totalPages: 20,
              maxPages: 5,
              onPageChanged: (_) {},
              paginationStyle: CorePaginationStyle(hoverDuration: duration),
            ),
          ),
        sample(
          'pagination-disabled',
          Pagination(
            page: 10,
            totalPages: 20,
            enabled: false,
            paginationStyle: CorePaginationStyle(hoverDuration: duration),
          ),
        ),
      ];
    case 'sortable':
      return [
        for (final enabled in [true, false])
          sample(
            'sortable-$enabled',
            Sortable(
              itemCount: 2,
              enabled: enabled,
              onReorder: (_, _) {},
              itemBuilder: (index, handle, remove) => div([
                handle,
                Text('Item $index'),
              ]),
              sortableStyle: CoreSortableStyle(animationDuration: duration),
            ),
          ),
      ];
    case 'multi-answer':
      return [
        for (final state in ['idle', 'selected', 'disabled'])
          sample(
            'multi-answer-$state',
            MultiAnswerCard<String>(
              value: state,
              selected: state == 'selected',
              enabled: state != 'disabled',
              onChanged: (_) {},
              multiAnswerCardStyle: CoreMultiAnswerCardStyle(
                transitionDuration: duration,
              ),
              child: Text(state),
            ),
          ),
      ];
    default:
      throw ArgumentError.value(kind);
  }
}

Future<String> _body(Iterable<String> kinds, Duration? duration) =>
    renderComponentBodyHtml(
      Component.fragment([
        Style(styles: docsContentTheme().styles),
        CoUIWeb(
          theme: .coui,
          child: div([
            for (final kind in kinds) ..._cases(kind, duration),
          ]),
        ),
      ]),
    );

// Read the browser's actual clock and state on every affected face. Close
// buttons and nested checkboxes own independent clocks and are excluded by
// their different transition-property classes, not by duration values.
const _kRead = '''
() => [...document.querySelectorAll('[data-duration-case]')].flatMap(host => {
  const kind = host.dataset.durationKind;
  const selector = {
    tabs: '.transition-all', tree: '.transition-transform',
    pagination: '.transition-colors', sortable: '[role="listitem"]',
    'multi-answer': ':scope > [role="button"] > .transition-all',
  }[kind];
  return [...host.querySelectorAll(selector)].map((node, index) => {
    const s = getComputedStyle(node), r = node.getBoundingClientRect();
    const owner = node.closest('[role="tab"], [role="treeitem"], ' +
      '[role="button"], [role="listitem"]');
    return {kind, sample: host.dataset.durationCase, index,
      duration: parseFloat(s.transitionDuration) * 1000,
      property: s.transitionProperty, geometry: [r.x, r.y, r.width, r.height],
      selected: owner?.getAttribute('aria-selected'),
      pressed: owner?.getAttribute('aria-pressed'),
      expanded: owner?.getAttribute('aria-expanded'),
      current: owner?.getAttribute('aria-current'),
      disabled: owner?.getAttribute('aria-disabled'),
      tabIndex: owner?.getAttribute('tabindex'),
      draggable: owner?.getAttribute('draggable')};
  });
})
''';

void main() {
  for (final kind in _kKinds) {
    test('$kind renders a 123ms public override through SSR', () async {
      final body = await _body([kind], _kDurations['arbitrary']);
      expect(body, contains('data-duration-kind="$kind"'));
      expect(body, isNot(contains('Error on building component')));
    });
  }

  test(
    'navigation and answer surfaces preserve duration policy and state',
    () async {
      final dir = Directory.systemTemp.createTempSync(
        'coui-navigation-duration-',
      );
      final browser = await launchCaptureBrowser(width: 800, height: 1600);
      try {
        final page = await browser.newPage();
        await page.setOfflineMode(true);
        final errors = <String>[];
        page.onError.listen((error) => errors.add('$error'));

        Future<List<Map<String, dynamic>>> read() async =>
            (await page.evaluate<List<dynamic>>(
              _kRead,
            )).cast<Map<String, dynamic>>();

        for (final entry in _kDurations.entries) {
          final body = await _body(_kKinds, entry.value);
          for (final theme in ['light', 'dark']) {
            await page.emulateMediaFeatures([
              MediaFeature.prefersReducedMotion('no-preference'),
            ]);
            final file = File('${dir.path}/${entry.key}-$theme.html')
              ..writeAsStringSync(
                buildOfflineTailwindHarnessHtml(
                  bodyHtml: body,
                  themeConfig: ThemeConfig.defaults(),
                  theme: theme,
                  vendoredTailwindScript: loadVendoredTailwindScript(),
                  additionalHeadHtml:
                      '<style>${buildLocalFontFaceCss()}</style>',
                  animationFreezeCss: '',
                ),
              );
            await page.goto(file.uri.toString(), wait: .load);
            await page.evaluate<void>('() => document.fonts.ready');
            final normal = await read();
            for (final kind in _kKinds) {
              expect(normal.where((row) => row['kind'] == kind), isNotEmpty);
            }
            for (final row in normal) {
              final duration =
                  entry.value ?? _defaultDuration(row['kind'] as String);
              expect(
                row['duration'],
                duration.inMilliseconds,
                reason: '$theme ${entry.key} $row',
              );
            }

            final tabs = normal.where((row) => row['kind'] == 'tabs');
            expect(
              tabs.map((row) => row['selected']),
              containsAll(['true', 'false']),
            );
            expect(tabs.map((row) => row['disabled']), contains('true'));
            expect(
              normal
                  .where((row) => row['kind'] == 'tree')
                  .map((row) => row['expanded']),
              containsAll(['true', 'false']),
            );
            expect(
              normal
                  .where((row) => row['kind'] == 'pagination')
                  .map((row) => row['current']),
              contains('page'),
            );
            expect(
              normal
                  .where((row) => row['sample'] == 'multi-answer-selected')
                  .map((row) => row['pressed']),
              everyElement('true'),
            );
            expect(
              normal
                  .where((row) => row['sample'] == 'multi-answer-disabled')
                  .map((row) => row['disabled']),
              everyElement('true'),
            );

            await page.emulateMediaFeatures([
              MediaFeature.prefersReducedMotion('reduce'),
            ]);
            final reduced = await read();
            expect(reduced, hasLength(normal.length));
            for (var i = 0; i < reduced.length; i++) {
              final row = reduced[i];
              final duration =
                  entry.value ?? _defaultDuration(row['kind'] as String);
              expect(
                row['duration'],
                CoreReducedMotion.isTransitionMotion(duration)
                    ? 0
                    : duration.inMilliseconds,
                reason: '$theme ${entry.key} reduced $row',
              );
              for (final key in normal[i].keys.where(
                (key) => key != 'duration',
              )) {
                expect(row[key], normal[i][key], reason: '$theme $key');
              }
            }

            await page.emulateMediaFeatures([
              MediaFeature.prefersReducedMotion('no-preference'),
            ]);
            for (final remap in [73, 0]) {
              await page.evaluate<void>(
                '(ms) => document.documentElement.style.setProperty( '
                '"--coui-duration-150", ms + "ms")',
                args: [remap],
              );
              for (final row in await read()) {
                final duration =
                    entry.value ?? _defaultDuration(row['kind'] as String);
                expect(
                  row['duration'],
                  duration.inMilliseconds == 150
                      ? remap
                      : duration.inMilliseconds,
                );
              }
            }
            await page.evaluate<void>('''
() => document.documentElement.style.removeProperty('--coui-duration-150')
''');
            // Trigger one property each component really animates, then ask
            // CSS Transitions for its effect duration. This checks the clock
            // used by Chrome, beyond reading a serialized style string.
            final clocks = await page.evaluate<List<dynamic>>('''
() => [...document.querySelectorAll('[data-duration-case]')].map(host => {
  const kind = host.dataset.durationKind;
  const selector = {tabs: '.transition-all', tree: '.transition-transform',
    pagination: '.transition-colors', sortable: '[role="listitem"]',
    'multi-answer': ':scope > [role="button"] > .transition-all'}[kind];
  const node = host.querySelector(selector);
  getComputedStyle(node).transitionDuration;
  if (kind === 'tree' || kind === 'sortable') {
    node.style.transform = 'translateX(12px)';
  } else if (kind === 'pagination') {
    node.style.color = 'rgb(123, 45, 67)';
  } else {
    node.style.opacity = '0.25';
  }
  return {kind, effects: node.getAnimations().map(animation => ({
    property: animation.transitionProperty,
    duration: animation.effect.getTiming().duration,
  }))};
})
''');
            for (final raw in clocks) {
              final row = raw as Map<String, dynamic>;
              final duration =
                  entry.value ?? _defaultDuration(row['kind'] as String);
              final effects = row['effects'] as List;
              if (duration == Duration.zero) {
                expect(effects, isEmpty);
              } else {
                expect(effects, isNotEmpty, reason: '$theme ${entry.key} $row');
                for (final effect in effects.cast<Map<String, dynamic>>()) {
                  expect(effect['duration'], duration.inMilliseconds);
                }
              }
            }
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
