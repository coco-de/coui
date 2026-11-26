// How a page arrives and leaves, read from real Chrome.
//
// The VM test reads the rules the server puts in the head. Whether the
// browser runs them — a transition between two documents, the new page
// rising over the old one, a step back playing the departure instead — is
// the browser's reading of rules it drops whole when one name in them is
// wrong (a variable it cannot find, a pseudo-class it does not know). So
// this serves two server-rendered pages from one origin, walks between
// them the way a reader does (a link, then back), and records the view
// transition each page is revealed with.
@Timeout(Duration(minutes: 2))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:puppeteer/puppeteer.dart' as pptr;
import 'package:test/test.dart';

import '../../../browser_launch.dart';
import '../../src/web/ssr_render.dart';

/// Milliseconds into a transition where it is read: under way for both the
/// arrival (300 ms) and the departure (200 ms), and past both ends.
const _kUnderWay = 100;
const _kSettled = 1000;

/// Records the view transition the page is revealed with. It runs first in
/// the head, so it hears the reveal, and reads the transition once it is
/// ready — after every other reveal listener, the direction script among
/// them, has run.
const _kRecorder =
    '''
addEventListener('pagereveal', function (e) {
  var t = e.viewTransition;
  window.__probe = {transition: !!t};
  if (!t) return;
  t.ready.then(function () {
    var animations = document.getAnimations().filter(function (a) {
      return String(a.effect && a.effect.pseudoElement || '')
          .indexOf('::view-transition') === 0;
    });
    animations.forEach(function (a) { a.pause(); });
    function hitLink() {
      var link = document.getElementById('go').getBoundingClientRect();
      var hit = document.elementFromPoint(
          link.left + link.width / 2, link.top + link.height / 2);
      if (!hit) return null;
      return hit.closest('#go') ? 'go' : hit.tagName;
    }
    function read(pseudo) {
      var s = getComputedStyle(document.documentElement, pseudo);
      return {opacity: Number(s.opacity), transform: s.transform,
          zIndex: s.zIndex, animationName: s.animationName};
    }
    var at = {};
    [$_kUnderWay, $_kSettled].forEach(function (ms) {
      animations.forEach(function (a) { a.currentTime = ms; });
      at[ms] = {old: read('::view-transition-old(root)'),
          new: read('::view-transition-new(root)'),
          hit: hitLink()};
    });
    window.__probe = {
      transition: true,
      types: Array.from(t.types),
      animations: animations.map(function (a) {
        return {pseudo: a.effect.pseudoElement, name: a.animationName,
            duration: a.effect.getComputedTiming().duration,
            easing: a.effect.getKeyframes()[0].easing};
      }),
      at: at,
    };
    t.finished.then(function () { window.__probe.after = hitLink(); });
    animations.forEach(function (a) { a.finish(); });
  });
});
''';

/// A server-rendered page with the theme's variables and the recorder in
/// its head, and a link to [next].
Future<String> _page(String label, {required String next}) async {
  final document = await renderComponentToDocumentHtml(
    CoUIWeb(
      theme: .coui,
      child: div([
        a([Text(label)], href: next, id: 'go'),
      ]),
    ),
  );
  const head = '<head>';
  final at = document.indexOf(head);
  if (at < 0) throw StateError('SSR 문서에 <head> 가 없음');

  return document.replaceRange(
    at + head.length,
    at + head.length,
    '<style>${ThemeConfig.defaults().cssVariables}</style>'
    '<script>$_kRecorder</script>',
  );
}

/// How far below its place a pseudo-element is drawn, in CSS px.
double _drop(Map<String, dynamic> style) {
  final transform = style['transform'] as String;
  if (transform == 'none') return 0;
  final values = transform
      .substring(transform.indexOf('(') + 1, transform.indexOf(')'))
      .split(',')
      .map((v) => double.parse(v.trim()))
      .toList();

  return values.last;
}

/// The four control points of a `cubic-bezier(...)` — the browser spells
/// `1.0` as `1`, so the curve is compared as numbers.
List<double> _points(String css) => css
    .substring(css.indexOf('(') + 1, css.indexOf(')'))
    .split(',')
    .map((v) => double.parse(v.trim()))
    .toList();

void main() {
  late pptr.Browser browser;
  late HttpServer server;
  late String origin;

  setUpAll(() async {
    final pages = {
      '/': await _page('first', next: '/second'),
      '/second': await _page('second', next: '/'),
    };
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0)
      ..listen((request) {
        final body = pages[request.uri.path];
        final response = request.response;
        if (body == null) {
          response.statusCode = HttpStatus.notFound;
        } else {
          // A fresh load on every visit, so a step back reveals the page the
          // way a first visit does rather than from the back/forward cache.
          response.headers
            ..contentType = ContentType.html
            ..set(HttpHeaders.cacheControlHeader, 'no-store');
          response.write(body);
        }
        unawaited(response.close());
      });
    origin = 'http://${server.address.address}:${server.port}';
    browser = await launchCaptureBrowser(width: 800, height: 600);
  });

  tearDownAll(() async {
    await browser.close();
    await server.close(force: true);
  });

  Future<Map<String, dynamic>> probe(pptr.Page page) async {
    await page.waitForFunction(
      '() => window.__probe && (window.__probe.transition === false || '
      "typeof window.__probe.after === 'string')",
    );

    return jsonDecode(
          await page.evaluate<String>('() => JSON.stringify(window.__probe)'),
        )
        as Map<String, dynamic>;
  }

  /// Opens the first page, follows its link, steps back, and returns what
  /// the second page and then the first one were revealed with.
  Future<({Map<String, dynamic> forward, Map<String, dynamic> back})> walk({
    required bool reduceMotion,
  }) async {
    final page = await browser.newPage();
    addTearDown(page.close);
    if (reduceMotion) {
      await page.emulateMediaFeatures([
        pptr.MediaFeature.prefersReducedMotion('reduce'),
      ]);
    }
    await page.goto('$origin/', wait: .load);

    await Future.wait([page.waitForNavigation(), page.click('#go')]);
    final forward = await probe(page);
    await page.goBack();
    final back = await probe(page);

    return (forward: forward, back: back);
  }

  Map<String, dynamic> animationOn(Map<String, dynamic> run, String pseudo) =>
      (run['animations'] as List).cast<Map<String, dynamic>>().singleWhere(
        (animation) =>
            animation['pseudo'] == pseudo &&
            '${animation['name']}'.startsWith('coui-'),
      );

  Map<String, dynamic> at(Map<String, dynamic> run, int ms, String part) =>
      ((run['at'] as Map)['$ms'] as Map)[part] as Map<String, dynamic>;

  /// What a click on the link's centre reaches at [ms] into the transition.
  String hitAt(Map<String, dynamic> run, int ms) =>
      ((run['at'] as Map)['$ms'] as Map)['hit'] as String;

  group('Page transition in Chrome', () {
    late ({Map<String, dynamic> forward, Map<String, dynamic> back}) run;

    setUpAll(() async => run = await walk(reduceMotion: false));

    test('following a link reveals the next page with a view transition', () {
      expect(run.forward['transition'], isTrue);
      expect(run.forward['types'], isEmpty);
    });

    test("the new page arrives on the style's timing and curve", () {
      final arrival = animationOn(run.forward, '::view-transition-new(root)');
      expect(arrival['name'], 'coui-page-enter');
      expect(
        arrival['duration'],
        CorePageTransitionStyle.defaultEnterDuration.inMilliseconds,
      );
      expect(
        _points(arrival['easing'] as String),
        _points(CorePageTransitionStyle.defaultEnterCurve.toCss()),
      );
    });

    test('under way, the new page fades in as it rises over the old one, '
        'which stays put', () {
      final arriving = at(run.forward, _kUnderWay, 'new');
      final underneath = at(run.forward, _kUnderWay, 'old');
      expect(arriving['opacity'], inExclusiveRange(0, 1));
      expect(
        _drop(arriving),
        inExclusiveRange(0, CorePageTransitionStyle.defaultSlideDistance),
      );
      expect(underneath['animationName'], 'none');
      expect(underneath['opacity'], 1);
      expect(_drop(underneath), 0);
    });

    test('while it plays, Chrome gives a click to the document; once it '
        'ends, the page takes clicks', () {
      // The Web reach the resolver documents: a Flutter page takes taps
      // while it arrives, a page under a view transition does not.
      expect(hitAt(run.forward, _kUnderWay), 'HTML');
      expect(run.forward['after'], 'go');
    });

    test('settled, the new page is in place', () {
      final arrived = at(run.forward, _kSettled, 'new');
      expect(arrived['opacity'], 1);
      expect(_drop(arrived), 0);
    });

    test('a step back is marked as one', () {
      expect(run.back['transition'], isTrue);
      expect(run.back['types'], ['back']);
    });

    test('stepping back, the page left sinks and fades over the page '
        'returned to, on the exit timing and curve', () {
      final departure = animationOn(run.back, '::view-transition-old(root)');
      expect(departure['name'], 'coui-page-exit');
      expect(
        departure['duration'],
        CorePageTransitionStyle.defaultExitDuration.inMilliseconds,
      );
      expect(
        _points(departure['easing'] as String),
        _points(CorePageTransitionStyle.defaultExitCurve.toCss()),
      );

      final leaving = at(run.back, _kUnderWay, 'old');
      final returnedTo = at(run.back, _kUnderWay, 'new');
      expect(leaving['zIndex'], '1');
      expect(leaving['opacity'], inExclusiveRange(0, 1));
      expect(
        _drop(leaving),
        inExclusiveRange(0, CorePageTransitionStyle.defaultSlideDistance),
      );
      expect(returnedTo['animationName'], 'none');
      expect(returnedTo['opacity'], 1);
    });

    test('once a step back ends, the page returned to takes clicks', () {
      expect(hitAt(run.back, _kUnderWay), 'HTML');
      expect(run.back['after'], 'go');
    });

    test('settled, the page left is gone', () {
      expect(at(run.back, _kSettled, 'old')['opacity'], 0);
    });
  });

  test('a reduced-motion request swaps pages at once, both ways', () async {
    final run = await walk(reduceMotion: true);
    expect(run.forward['transition'], isFalse);
    expect(run.back['transition'], isFalse);
  });
}
