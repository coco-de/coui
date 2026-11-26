// A content surface that names its own material, rendered — what a real Chrome
// with the shipped stylesheet makes of the markers `Card` and
// `OutlinedContainer` write.
//
// The Web unit tests read the class list the resolver emits and check that no
// rule of the stylesheet could select it. That proves the markup and the
// selectors; the claim lives in the pixels. An "opaque card in a glass theme"
// is only opaque if no declaration that survives the cascade still blurs it,
// frosts its edge, or lets the page through its fill — and the cascade is the
// one thing a class string cannot show.
//
// ## What is asserted, and why each half
//
//   computed style  — the declarations the browser kept: no backdrop filter,
//                     an opaque fill, the resting stroke, no edge band. These
//                     say *why* the pixels are what they are.
//   pixels          — the centre of the card read back over two different
//                     backdrops. An opaque card is the same pixels over both;
//                     a glass one is not. This is the claim itself, and it
//                     needs no knowledge of which declaration did the work.
//
// Every case pairs the surface under test with the sibling that states
// nothing: without that control "the pixel did not change" could be a page
// that draws no glass at all.
//
// The markup is the real components' server output.
import 'dart:convert';
import 'dart:io';
import 'dart:math' show Rectangle;

import 'package:coui_web/coui_web.dart';
import 'package:image/image.dart' as img;
import 'package:jaspr_test/server_test.dart';
import 'package:path/path.dart' as p;
import 'package:puppeteer/puppeteer.dart' as pptr;

import '../../../browser_launch.dart';
import '../../src/web/offline_tailwind_harness.dart';
import '../../src/web/panel_pixels.dart';

String? _systemChromePath() {
  const candidates = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
    '/usr/bin/google-chrome-stable',
    '/usr/bin/chromium-browser',
    '/usr/bin/chromium',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }

  return null;
}

const int _kViewportWidth = 560;
const int _kViewportHeight = 360;

/// The probe region: a square at the centre of a surface, small enough to sit
/// inside the fill whatever the radius and the edge band do.
const int _kProbeSide = 8;

/// A body of fixed size, so the surface around it has a known centre.
Component _body() => const div(
  [],
  styles: Styles(
    raw: {'width': '96px', 'height': '56px', 'display': 'block'},
  ),
);

Component _cards() => div(
  [
    Card(
      id: 'card-opaque',
      variant: .outlined,
      cardStyle: const CoreCardStyle(surfaceStyle: .defaultStyle),
      child: _body(),
    ),
    Card(id: 'card-plain', variant: .outlined, child: _body()),
    Card(
      id: 'card-glass',
      variant: .outlined,
      cardStyle: const CoreCardStyle(surfaceStyle: .liquidGlass),
      child: _body(),
    ),
    OutlinedContainer(
      id: 'box-opaque',
      containerStyle: const CoreOutlinedContainerStyle(
        surfaceStyle: .defaultStyle,
      ),
      child: _body(),
    ),
    OutlinedContainer(id: 'box-plain', child: _body()),
    OutlinedContainer(
      id: 'box-glass',
      containerStyle: const CoreOutlinedContainerStyle(
        surfaceStyle: .liquidGlass,
      ),
      child: _body(),
    ),
  ],
  styles: const Styles(
    raw: {
      'display': 'grid',
      'grid-template-columns': 'repeat(3, max-content)',
      'gap': '24px',
      'padding': '24px',
    },
  ),
);

/// The page: a hard-edged backdrop behind the surfaces, switchable between two
/// states so a surface's dependence on what is behind it can be read.
///
/// `z-index: -1` on a fixed layer, because the surfaces are in-flow and some
/// of them (the glass ones) are positioned by the stylesheet: a positioned
/// backdrop would paint above the unpositioned ones and hide them.
///
/// `.border` gets its `solid` style here because the shipped Tailwind config
/// turns preflight off, which is where a bare `border` utility would
/// otherwise get one from. The surfaces then carry a real 1px box, which is
/// what "the resting stroke is kept" and "the box stays" are statements about.
String _page(String cards) =>
    '''
<style>
  html, body { margin: 0; background: transparent; }
  .border { border-style: solid; }
  #bg { position: fixed; inset: 0; z-index: -1; }
  body[data-backdrop="stripes"] #bg {
    background: repeating-linear-gradient(90deg, #000 0 12px, #fff 12px 24px);
  }
  body[data-backdrop="solid"] #bg { background: #d0149a; }
</style>
<div id="bg"></div>
$cards
''';

/// What the browser kept for [id]: the declarations, not the classes.
String _measure(String id) =>
    '''
() => {
  const el = document.getElementById('$id');
  const cs = getComputedStyle(el);
  const after = getComputedStyle(el, '::after');
  const alpha = (c) => {
    const slash = c.match(/\\/\\s*([0-9.]+%?)\\s*\\)/);
    if (slash) {
      return slash[1].endsWith('%') ? parseFloat(slash[1]) / 100
                                     : parseFloat(slash[1]);
    }
    const comma = c.match(/^rgba\\(([^)]*)\\)\$/);
    if (comma) return parseFloat(comma[1].split(',')[3]);
    return 1;
  };
  const r = el.getBoundingClientRect();
  return JSON.stringify({
    classes: el.className,
    backdrop: cs.backdropFilter,
    fill: cs.backgroundColor,
    fillAlpha: alpha(cs.backgroundColor),
    stroke: cs.borderTopColor,
    strokeAlpha: alpha(cs.borderTopColor),
    strokeWidth: cs.borderTopWidth,
    band: after.content,
    box: {x: r.left, y: r.top, width: r.width, height: r.height},
  });
}
''';

class _Surface {
  _Surface(this.json);

  final Map<String, dynamic> json;

  String get backdrop => json['backdrop'] as String;
  double get fillAlpha => (json['fillAlpha'] as num).toDouble();
  double get strokeAlpha => (json['strokeAlpha'] as num).toDouble();
  String get strokeWidth => json['strokeWidth'] as String;
  String get band => json['band'] as String;
  String get classes => json['classes'] as String;

  /// The border box's size — what a neighbour in the layout sees.
  ({double width, double height}) get size {
    final box = json['box'] as Map<String, dynamic>;

    return (
      width: (box['width'] as num).toDouble(),
      height: (box['height'] as num).toDouble(),
    );
  }

  Rectangle<int> get centre {
    final box = json['box'] as Map<String, dynamic>;
    final x = (box['x'] as num).toDouble() + (box['width'] as num) / 2;
    final y = (box['y'] as num).toDouble() + (box['height'] as num) / 2;

    return Rectangle<int>(
      (x - _kProbeSide / 2).round(),
      (y - _kProbeSide / 2).round(),
      _kProbeSide,
      _kProbeSide,
    );
  }

  /// Whether the browser kept a backdrop pass on this surface.
  bool get blurs => backdrop.contains('blur(');

  /// Whether the surface draws an edge band (the glass material's `::after`).
  bool get hasBand => band != 'none' && band != 'normal';
}

void main() {
  final repoRoot = Directory.current.path;
  final vendoredScript = loadVendoredTailwindScript(repoRoot: repoRoot);
  final themeConfig = ThemeConfig.defaults();
  final chromePath = _systemChromePath();

  late String bodyHtml;

  testServer('server output of the surfaces under test', (tester) async {
    tester.pumpComponent(Theme.defaults(child: _cards()));
    final response = await tester.request('/');
    final match = RegExp(
      '<body[^>]*>(.*)</body>',
      dotAll: true,
    ).firstMatch(response.body);
    bodyHtml = match == null ? response.body : match.group(1)!;
    expect(bodyHtml, contains('id="card-opaque"'));
    expect(bodyHtml, contains('id="box-opaque"'));
  });

  final skip = chromePath == null
      ? 'no local Chrome — the rendered claims cannot be verified here'
      : null;

  group('a content surface that names its material, in Chrome', () {
    late pptr.Browser browser;
    late pptr.Page page;
    late Directory tempDir;

    setUpAll(() async {
      if (chromePath == null) return;
      browser = await launchCaptureBrowser(
        width: _kViewportWidth,
        height: _kViewportHeight,
        executablePath: chromePath,
      );
    });
    tearDownAll(() async {
      if (chromePath == null) return;
      await browser.close();
    });

    setUp(() async {
      if (chromePath == null) return;
      page = await browser.newPage();
      tempDir = Directory.systemTemp.createTempSync('coui-content-surface-');
    });
    tearDown(() async {
      if (chromePath == null) return;
      await page.close();
      tempDir.deleteSync(recursive: true);
    });

    /// Loads the surfaces under the document preset [style] (null = none).
    Future<void> load(String? style) async {
      final html = buildOfflineTailwindHarnessHtml(
        bodyHtml: _page(bodyHtml),
        themeConfig: themeConfig,
        vendoredTailwindScript: vendoredScript,
        surfaceStyleId: style,
      );
      final file = File(p.join(tempDir.path, 'surfaces.html'))
        ..writeAsStringSync(html);
      await page.goto(Uri.file(file.path).toString(), wait: pptr.Until.load);
      await _settle(page);
    }

    Future<_Surface> measure(String id) async => _Surface(
      jsonDecode(await page.evaluate<String>(_measure(id)))
          as Map<String, dynamic>,
    );

    /// The centre of [surface], read back with the backdrop in [state].
    Future<img.Image> shoot(_Surface surface, String state) async {
      await page.evaluate<void>(
        "() => document.body.setAttribute('data-backdrop', '$state')",
      );
      await _settle(page);
      final bytes = await page.screenshot(clip: surface.centre);

      return img.decodePng(bytes)!;
    }

    /// How much of the centre of [id] depends on what is behind it.
    Future<double> dependence(String id) async {
      final surface = await measure(id);
      final over = await shoot(surface, 'stripes');
      final other = await shoot(surface, 'solid');

      return diffRatio(over, other);
    }

    for (final kind in ['card', 'box']) {
      test(
        'a $kind that names the baseline material is opaque inside a glass '
        'document',
        () async {
          await load('liquidGlass');

          // The control: the same document does make an unmarked surface
          // glass. Without this, an opaque result below would be a page that
          // draws no glass at all.
          final plain = await measure('$kind-plain');
          expect(plain.blurs, isTrue, reason: 'the document draws glass');
          expect(plain.fillAlpha, lessThan(1), reason: 'glass lets it through');
          expect(plain.strokeAlpha, 0, reason: 'the material is the edge');
          expect(plain.hasBand, isTrue);
          expect(
            await dependence('$kind-plain'),
            greaterThan(kMovedRatioFloor),
            reason: 'a glass surface shows what is behind it',
          );

          final opaque = await measure('$kind-opaque');
          stdout.writeln('W-content-surface  $kind-opaque  ${opaque.json}');
          expect(opaque.classes, contains('coui-material-defaultStyle'));
          expect(opaque.classes.split(' '), isNot(contains('coui-surface')));
          expect(opaque.blurs, isFalse, reason: 'a rule is still blurring');
          expect(opaque.fillAlpha, 1, reason: 'the fill lets the page through');
          expect(opaque.strokeAlpha, greaterThan(0), reason: 'resting stroke');
          expect(opaque.strokeWidth, '1px', reason: 'the resting stroke box');
          // The same box, not the same border width: a glass surface folds its
          // transparent edge into the padding (its computed border is 0), so
          // the two boxes differ in where the 1px sits but not in their size.
          expect(opaque.size, plain.size, reason: 'same box');
          expect(opaque.hasBand, isFalse, reason: 'no glass edge band');
          expect(
            await dependence('$kind-opaque'),
            lessThan(kUnchangedRatioCeiling),
            reason: 'an opaque surface does not show what is behind it',
          );
        },
        skip: skip,
      );

      test(
        'a $kind that names glass is glass inside an opaque document',
        () async {
          await load(null);

          // The control: the same document leaves an unmarked surface alone.
          final plain = await measure('$kind-plain');
          expect(plain.blurs, isFalse);
          expect(plain.fillAlpha, 1);
          expect(
            await dependence('$kind-plain'),
            lessThan(kUnchangedRatioCeiling),
          );

          final glass = await measure('$kind-glass');
          stdout.writeln('W-content-surface  $kind-glass  ${glass.json}');
          expect(glass.classes, contains('coui-material-liquidGlass'));
          expect(glass.blurs, isTrue, reason: 'the local rule did not match');
          expect(glass.fillAlpha, lessThan(1));
          expect(glass.strokeAlpha, 0);
          expect(glass.hasBand, isTrue);
          expect(
            await dependence('$kind-glass'),
            greaterThan(kMovedRatioFloor),
          );
        },
        skip: skip,
      );
    }
  });
}

Future<void> _settle(pptr.Page page) async {
  // Two frames, not one: the first lets style changes land, the second lets
  // the compositor draw them.
  await page.evaluate<void>(
    '() => new Promise(function (done) { requestAnimationFrame(function () '
    '{ requestAnimationFrame(done); }); })',
  );
}
