@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/previews/web_registry.dart';
import 'package:image/image.dart' as img;
import 'package:puppeteer/puppeteer.dart' show Browser;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/model/parity_theme.dart';
import '../../src/model/parity_tier.dart';
import '../../src/model/probe_spec.dart';
import '../../src/web/local_fonts.dart';
import '../../src/web/local_icons.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/web_capture_backend.dart';

/// A fixed-time parent containing independent time, scroll and view clocks.
/// References use the same boxes and a static opacity; no measured offsets are
/// applied to either the captured fixture or its reference.
Component _mixedClockFixture({required bool horizontal, required bool fits}) {
  final extent = fits ? 100 : 200;
  final spacer = fits ? 0 : 50;
  final direction = horizontal ? 'row' : 'column';
  final width = horizontal ? extent : 100;
  final height = horizontal ? 100 : extent;
  final halfOpacity = fits ? '1' : '.5';
  Component solid({String? id, String opacity = '1'}) => div(
    const [],
    id: id,
    styles: Styles(
      raw: {
        'flex': 'none',
        'width': '100px',
        'height': '100px',
        'background': 'rgb(255,0,0)',
        'opacity': opacity,
      },
    ),
  );
  Component viewport({required String id, required Component child}) => div(
    [child],
    id: id,
    styles: const Styles(
      raw: {
        'width': '100px',
        'height': '100px',
        'overflow': 'auto',
        'scrollbar-width': 'none',
      },
    ),
  );
  final root = div(
    [
      div(
        [
          for (final id in ['css-clock', 'document-clock', 'null-clock'])
            div(
              const [],
              id: id,
              styles: const Styles(
                raw: {
                  'width': '50px',
                  'height': '20px',
                  'background': 'rgb(255,0,0)',
                },
              ),
            ),
          const span([], id: 'clock-callbacks'),
        ],
        styles: const Styles(raw: {'display': 'flex', 'grid-column': 'span 2'}),
      ),
      viewport(
        id: 'scroll-viewport',
        child: div(
          const [],
          styles: Styles(
            raw: {
              'width': '${width}px',
              'height': '${height}px',
              'background': 'rgb(255,0,0)',
            },
          ),
        ),
      ),
      solid(opacity: halfOpacity),
      viewport(
        id: 'view-viewport',
        child: div(
          [
            div(
              const [],
              styles: Styles(
                raw: {
                  'flex': 'none',
                  'width': horizontal ? '${spacer}px' : '100px',
                  'height': horizontal ? '100px' : '${spacer}px',
                },
              ),
            ),
            solid(id: 'view-subject'),
            div(
              const [],
              styles: Styles(
                raw: {
                  'flex': 'none',
                  'width': horizontal ? '${spacer}px' : '100px',
                  'height': horizontal ? '100px' : '${spacer}px',
                },
              ),
            ),
          ],
          styles: Styles(
            raw: {
              'display': 'flex',
              'flex-direction': direction,
              'width': '${width}px',
              'height': '${height}px',
            },
          ),
        ),
      ),
      // An aligned ViewTimeline subject is halfway through its entry/exit
      // range even when its viewport fits; ScrollTimeline is inactive there.
      solid(opacity: '.5'),
    ],
    id: 'clock-fixture',
    styles: const Styles(
      raw: {
        'display': 'grid',
        'grid-template-columns': '100px 100px',
        'grid-template-rows': '20px 100px 100px',
        'width': '200px',
        'height': '220px',
        'background': '#123456',
      },
    ),
  );
  return Component.fragment([
    div([LoadingRegion(semanticLabel: 'clock region', child: root)]),
    const Component.element(
      tag: 'style',
      children: [
        RawText('''
@keyframes capture-clock { from { background-color:rgb(255,0,0); }
                          to { background-color:rgb(0,0,255); } }
#css-clock { animation:capture-clock 100s linear infinite; }
'''),
      ],
    ),
    Component.element(
      tag: 'script',
      children: [
        RawText('''
const frames = {backgroundColor:['rgb(255,0,0)','rgb(0,0,255)']};
const documentClock = document.getElementById('document-clock').animate(
  frames, {duration:100000,fill:'both',timeline:new DocumentTimeline()});
documentClock.currentTime = 50000;
const nullClock = new Animation(new KeyframeEffect(
  document.getElementById('null-clock'),frames,{duration:100000,fill:'both'}),null);
nullClock.currentTime = 50000;
const scrollViewport = document.getElementById('scroll-viewport');
scrollViewport.animate({opacity:[0,1]}, {
  duration:'auto',fill:'both',
  timeline:new ScrollTimeline({source:scrollViewport,axis:'${horizontal ? 'x' : 'y'}'})
});
const viewViewport = document.getElementById('view-viewport');
const subject = document.getElementById('view-subject');
subject.animate({opacity:[0,1]}, {
  duration:'auto',fill:'both',
  timeline:new ViewTimeline({subject,axis:'${horizontal ? 'x' : 'y'}'})
});
scrollViewport.${horizontal ? 'scrollLeft' : 'scrollTop'} = ${fits ? 0 : 50};
viewViewport.${horizontal ? 'scrollLeft' : 'scrollTop'} = ${fits ? 0 : 50};
for (const animation of document.getAnimations()) {
  for (const type of ['finish','cancel']) animation.addEventListener(type, () => {
    document.getElementById('clock-callbacks').textContent += type;
  });
}
'''),
      ],
    ),
  ]);
}

void main() {
  late Browser browser;
  late Directory directory;

  setUpAll(() async {
    directory = Directory.systemTemp.createTempSync('capture-clock-');
    browser = await launchCaptureBrowser(width: 800, height: 1200);
  });
  tearDownAll(() async {
    await browser.close();
    directory.deleteSync(recursive: true);
  });

  for (final horizontal in [true, false]) {
    for (final fits in [true, false]) {
      test('fixed-time preserves ${horizontal ? 'x' : 'y'} '
          '${fits ? 'inactive' : 'active'} progress clocks', () async {
        final original = kWebPreviewRegistry['loading-region']!;
        addTearDown(() => kWebPreviewRegistry['loading-region'] = original);
        kWebPreviewRegistry['loading-region'] = (context, variant) =>
            _mixedClockFixture(horizontal: horizontal, fits: fits);
        const key = 'loading-region-default-light-defaultStyle';
        final pagesBefore = (await browser.pages).length;
        final result = await captureWebEntry(
          browser: browser,
          entry: MatrixEntry(
            component: 'loading-region',
            variant: 'default',
            theme: ParityTheme.light,
            surfaceStyle: CoreSurfaceStyleId.defaultStyle,
            tier: ParityTier.t1,
            probes: [
              rootProbeSpec(key: key, flutterClassName: 'LoadingRegion'),
            ],
          ),
          themeConfig: ThemeConfig.defaults(),
          vendoredTailwindScript: loadVendoredTailwindScript(),
          fontFaceCss: buildLocalFontFaceCss(),
          iconifyHeadHtml: buildLocalIconifyHeadHtml(),
          harnessDir: directory,
        );
        expect((await browser.pages).length, pagesBefore);
        final times = result.captureContext['animationTimes']! as List;
        final states = result.captureContext['animationStates']! as List;
        expect(times, hasLength(5));
        expect(times.where((time) => time == 0), hasLength(3));
        expect(states.where((state) => state == 'paused'), hasLength(3));
        expect(states.where((state) => state == 'running'), hasLength(2));
        expect(
          times.whereType<Map<Object?, Object?>>(),
          hasLength(fits ? 1 : 2),
        );
        expect(times.where((time) => time == null), hasLength(fits ? 1 : 0));
        expect(result.captureContext['text'], 'clock region');
        final image = img.decodePng(result.pngBytes)!;
        expect((image.width, image.height), (200, 220));
        for (final x in [25, 75, 125]) {
          final pixel = image.getPixel(x, 10);
          expect([pixel.r, pixel.g, pixel.b, pixel.a], [255, 0, 0, 255]);
        }
        for (var y = 20; y < 220; y++) {
          for (var x = 0; x < 100; x++) {
            final actual = image.getPixel(x, y);
            final reference = image.getPixel(x + 100, y);
            expect(
              [actual.r, actual.g, actual.b, actual.a],
              [reference.r, reference.g, reference.b, reference.a],
              reason: 'progress pixel ($x,$y), fits=$fits',
            );
          }
        }
      });
    }
  }
}
