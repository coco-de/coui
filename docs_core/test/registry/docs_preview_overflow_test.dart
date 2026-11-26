/// Every preview a docs page draws fits the stage it is drawn on — at the
/// width the page gives its pane, under every density.
///
/// **What is drawn.** Every `<LivePreview>` tag under `content/`, resolved
/// to variants the way the page resolves them (`resolveDocsPreviewVariants`).
/// A chain panel mounts the component's shuffle renderer at its first step
/// when it has one — the permutations change only radius and colour, so
/// every step stands as tall as the first — and the static chain example
/// otherwise.
///
/// **At what width.** The page decides it from two registrations and the
/// docs stylesheets (`site_head.dart`, `docs_site/web/docs-shell.css`),
/// measured on a release build at a 1280px and a 1440px viewport:
///
/// * the content row the previews lay out in — 668 and 828px. 1280px is
///   where a desktop layout gives the narrowest row: the contents column
///   appears there and the article's padding grows. Narrower desktop
///   viewports give more (680px at 1024px, up to 876px just under 1280px),
///   and the gallery keeps its two tracks across all of them;
/// * `.variant-gallery` — `repeat(auto-fit, minmax(300px, 1fr))` with a
///   1rem gap — unless the component takes the full row
///   (`kDocsFullRowGalleryComponents`, `kDocsWideComponents`). The chain
///   panel sits outside the grid, at the row's width;
/// * `.live-preview`'s 1px border, the 1px gap between side-by-side panes
///   (stacked for `kDocsWideComponents`) and `.preview-pane`'s 1.5rem
///   padding.
///
/// **What fails.** Two signals, because each misses what the other sees:
///
/// 1. an overflow reported while drawing on the stage — the
///    `docsPreviewConstraintsFor` `maxHeight` both panes sit on;
/// 2. content taller than the stage that reports nothing — a scroll view
///    hiding its tail, a fixed-size box squeezed by its constraint, a flex
///    squeezed to zero size (which skips painting its overflow indicator).
///    When the preview takes the whole stage it is drawn again on a tall
///    view, and content that does not fill that one must fit the stage. A
///    preview that fills whatever height it gets (a column left at
///    `MainAxisSize.max`) has no height of its own, so only signal 1
///    covers it.
///
/// The floor (`minHeight`) is not drawn: a named tier's floor is shared by
/// many components rather than set from one, and the bands sized from this
/// sweep are one height, floor and stage alike.
///
/// **Fonts.** The embed draws Pretendard and Geist Mono. flutter_test
/// draws its own font — every glyph a 1em square — unless real faces are
/// loaded, and with it text wraps far earlier than on the page: measured
/// that way, the NavigationMenu bar overflowed a stacked pane, which it
/// does not with the real faces. The faces load from `docs_site/fonts`.
///
/// **Images.** flutter_test answers every request with HTTP 400, and the
/// failure surfaces asynchronously in whichever test runs next. A stub
/// client serves a small PNG instead — the hook the parity capture uses
/// (`packages/coui_flutter/test/parity/parity_network_image_stub.dart`).
/// The examples size their images from their own boxes, so the decode — which
/// a widget test does not complete — moves no layout.
///
/// **Densities.** The embed passes none today; the bands hold all three so
/// that a density switch on the site does not reopen them.
///
/// **Known defects** ([_kKnownDefects]) are previews that do not fit
/// because of the component or the embed rather than a registration. They
/// are left out of the per-preview cases, and one test per entry asserts
/// the defect still shows — so the entry goes when its issue is fixed.
///
/// **Reachable states** ([_kReachableStates]) are previews that grow in
/// use — every disclosure of a group open, an accordion's longest answer.
/// They are drawn a second time after the taps that reach that state.
///
/// Shares the traps `menubar_preview_overflow_test.dart` documents: each
/// draw mounts a fresh tree (an overflow is reported once per render
/// object), and the view is sized rather than a box, because the embed
/// constrains the view.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/markdown/repo_root.dart';
import 'package:docs_core/previews/flutter_chain_registry.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:docs_core/shared/chain_permutations.dart';
import 'package:docs_core/shared/preview_constraints.dart';
import 'package:docs_core/shared/preview_layout.dart';
import 'package:docs_core/shared/preview_variants.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

/// Previews that do not fit for a reason no registration can fix —
/// `component/variant` → the issue that tracks it.
const Map<String, String> _kKnownDefects = {
  // Flutter sizes the carousel to the current slide, Web to the tallest —
  // a taller neighbour overflows on Flutter.
  'carousel/banner': 'https://github.com/coco-de/coui/issues/5462',
};

/// Previews whose tallest state is reached by use — `component/variant` →
/// the texts tapped, in order, to reach it (every match of each text).
const Map<String, List<String>> _kReachableStates = {
  // One answer open at a time; the longest one.
  'accordion/default': ['이메일을 바꿀 수 있나요?'],
  'accordion/chain': ['이메일을 바꿀 수 있나요?'],
  // Opening one does not close the others — every one open.
  'disclosure/group': [
    '하나를 열면 나머지가 닫히나요?',
    '머리글에 글자 말고 다른 것도 넣을 수 있나요?',
  ],
  // The sidebar opened in a drawer: a title row over three rows, inside
  // the pane on Flutter.
  'navigation-bar-item/drawer': ['사이드바 열기'],
};

/// The content row the previews lay out in, by viewport width — measured
/// on a release build of the docs page. The first is the narrowest row a
/// desktop layout gives, the second the row at the design width.
const Map<int, double> _kContentRows = {1280: 668, 1440: 828};

/// `.variant-gallery`'s `minmax(300px, 1fr)` track and 1rem gap.
const double _kGalleryMinColumn = 300;
const double _kGalleryGap = 16;

/// `.live-preview`'s border, the gap between side-by-side panes and
/// `.preview-pane`'s padding — per side where there are two.
const double _kPreviewBorder = 1;
const double _kPaneGap = 1;
const double _kPanePadding = 24;

/// Taller than any preview. Content that does not fill it has a height of
/// its own.
const double _kTallView = 4000;

/// Layout lands on fractional pixels; a difference under this is not one.
const double _kEpsilon = 0.5;

const ValueKey<String> _kProbe = ValueKey('docs-preview-probe');

/// Every scaling axis at 1, as `PreviewApp` pins them.
final ThemeData _kPreviewTheme = ThemeData.fromCore(
  CoreThemePresets.previewLight.copyWith(
    sizeScaling: 1,
    textScaling: 1,
    radiusScaling: 1,
  ),
);

/// One preview a docs page draws, and the pane width it is drawn at.
class _Case {
  const _Case(this.component, this.variant, this.viewport, this.width);

  final String component;
  final String? variant;
  final int viewport;
  final double width;

  String get key => variant == null ? component : '$component/$variant';

  DocsPreviewConstraints get stage => docsPreviewConstraintsFor(component, variant);
}

/// Every preview the docs pages draw, at both viewports.
final List<_Case> _kCases = _casesFromContent();

List<_Case> _casesFromContent() {
  final tag = RegExp(r'<LivePreview\s+([^>]*?)/?>');
  final componentAttr = RegExp(r'component="([a-z0-9-]+)"');
  final variantsAttr = RegExp(r'variants="([^"]*)"');
  final variantAttr = RegExp(r'\svariant="([^"]*)"');

  final seen = <String>{};
  final cases = <_Case>[];
  final pages = [
    for (final entry in Directory('content').listSync(recursive: true))
      if (entry is File && entry.path.endsWith('.md')) entry,
  ]..sort((a, b) => a.path.compareTo(b.path));
  // v2 pages draw a registered example with `<Preview example>` or a
  // `<Card example>` instead of `<LivePreview>`; the stage is the same one.
  final exampleTag = RegExp(r'<(?:Preview|Card)\s+([^>]*?)/?>');
  final exampleAttr = RegExp(r'example="([^"]*)"');
  for (final page in pages) {
    final source = page.readAsStringSync();
    for (final match in exampleTag.allMatches(source)) {
      final attributes = match.group(1)!;
      final component = componentAttr.firstMatch(attributes)?.group(1);
      final example = exampleAttr.firstMatch(attributes)?.group(1);
      if (component == null || example == null) continue;
      for (final MapEntry(key: viewport, value: row) in _kContentRows.entries) {
        final width = _paneWidth(row, component: component, chain: example == 'chain', gridItems: 1);
        final key = '$component/$example';
        if (seen.add('$key@$width')) cases.add(_Case(component, example, viewport, width));
      }
    }
    for (final match in tag.allMatches(source)) {
      final attributes = match.group(1)!;
      final component = componentAttr.firstMatch(attributes)?.group(1);
      if (component == null) continue;

      // Mirrors docs_site's `LivePreview` component.
      final variants = variantsAttr.firstMatch(attributes)?.group(1);
      final variant = variantAttr.firstMatch(attributes)?.group(1);
      final declared = variants != null
          ? [
              for (final part in variants.split(','))
                if (part.trim().isNotEmpty) part.trim(),
            ]
          : [if (variant != null && variant.trim().isNotEmpty) variant.trim()];
      final effective = resolveDocsPreviewVariants(
        component,
        declared,
        chainOptOut: attributes.contains('chain="off"'),
      );
      final inGallery = variants != null || effective.length > 1;
      final gridItems = effective.where((v) => v != 'chain').length;

      for (final MapEntry(key: viewport, value: row) in _kContentRows.entries) {
        for (final drawn in effective.isEmpty ? [null] : effective) {
          final width = _paneWidth(
            row,
            component: component,
            chain: drawn == 'chain',
            gridItems: inGallery ? gridItems : 1,
          );
          final key = drawn == null ? component : '$component/$drawn';
          if (seen.add('$key@$width')) {
            cases.add(_Case(component, drawn, viewport, width));
          }
        }
      }
    }
  }
  return cases;
}

/// The width of one pane's content for [component] on a content row
/// [row] px wide, in a gallery of [gridItems] grid items.
/// A negative control's case, built from the registry rather than found on a
/// page — a page may stop drawing that example when it moves to v2.
_Case _directCase(String component, String variant) {
  final MapEntry(key: viewport, value: row) = _kContentRows.entries.first;
  return _Case(
    component,
    variant,
    viewport,
    _paneWidth(row, component: component, chain: variant == 'chain', gridItems: 1),
  );
}

double _paneWidth(
  double row, {
  required String component,
  required bool chain,
  required int gridItems,
}) {
  final stacked = kDocsWideComponents.contains(component);
  final fullRow = stacked || kDocsFullRowGalleryComponents.contains(component);

  var item = row;
  if (!chain && !fullRow && gridItems > 1) {
    // auto-fit collapses the tracks no item uses.
    final tracks = ((row + _kGalleryGap) / (_kGalleryMinColumn + _kGalleryGap)).floor().clamp(1, gridItems);
    item = (row - (tracks - 1) * _kGalleryGap) / tracks;
  }

  final inside = item - 2 * _kPreviewBorder;
  final pane = stacked ? inside : (inside - _kPaneGap) / 2;
  return pane - 2 * _kPanePadding;
}

/// What a docs page mounts for [component]/[variant] — see the library doc.
Widget _previewOf(String component, String? variant) {
  if (variant == 'chain') {
    final renderer = kFlutterChainRegistry[component];
    if (renderer != null) return renderer(chainPermutationAt(0));
  }
  return kFlutterPreviewRegistry[component]!(variant);
}

/// docs_site's `PreviewApp` around [preview] — the same app, scaling and
/// insets — with [density], which the embed itself leaves at the default.
Widget _embed(Widget preview, CoreDensity density) => CoUIApp(
  theme: _kPreviewTheme,
  density: density,
  scaling: const AdaptiveScaling(),
  debugShowCheckedModeBanner: false,
  disableBrowserContextMenu: false,
  enableThemeAnimation: false,
  home: Align(
    alignment: Alignment.topCenter,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: kDocsPreviewContentInset,
      ),
      child: KeyedSubtree(key: _kProbe, child: preview),
    ),
  ),
);

/// Settles [tester], or gives up on what never settles — a spinner, a
/// skeleton's pulse, a marquee — whose motion moves nothing's height.
Future<void> _settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
  } on FlutterError catch (error) {
    if (!error.message.contains('pumpAndSettle timed out')) rethrow;
  }
}

/// Draws [component]/[variant] on a fresh tree in a [width] × [height] view
/// under [density], tapping every match of each of [taps] in order, and
/// returns the overflows it reported and how tall the preview stood.
Future<({List<String> overflows, double height})> _draw(
  WidgetTester tester, {
  required String component,
  required String? variant,
  required double width,
  required double height,
  required CoreDensity density,
  List<String> taps = const [],
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(width, height);

  final overflows = <String>[];
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.exception.toString();
    if (text.contains('overflowed')) {
      overflows.add(text.split('\n').first);
    } else {
      previousOnError?.call(details);
    }
  };
  try {
    await tester.pumpWidget(_embed(_previewOf(component, variant), density));
    await _settle(tester);
    for (final text in taps) {
      final count = find.text(text).evaluate().length;
      expect(count, greaterThan(0), reason: 'no "$text" to tap');
      for (var i = 0; i < count; i++) {
        await tester.tap(find.text(text).at(i));
        await _settle(tester);
      }
    }
  } finally {
    FlutterError.onError = previousOnError;
  }
  return (
    overflows: overflows,
    height: tester.getSize(find.byKey(_kProbe)).height,
  );
}

/// Every way [c] fails to fit [stage] (its own by default), under each
/// density, after [taps].
Future<List<String>> _failuresOf(
  WidgetTester tester,
  _Case c, {
  double? stage,
  List<String> taps = const [],
}) async {
  final stageHeight = stage ?? c.stage.maxHeight;
  final room = stageHeight - 2 * kDocsPreviewContentInset;
  final failures = <String>[];
  for (final density in CoreDensity.values) {
    final onStage = await _draw(
      tester,
      component: c.component,
      variant: c.variant,
      width: c.width,
      height: stageHeight,
      density: density,
      taps: taps,
    );
    failures.addAll([
      for (final overflow in onStage.overflows) '${density.name}: $overflow',
    ]);

    if (onStage.height < room - _kEpsilon) continue;
    final onTall = await _draw(
      tester,
      component: c.component,
      variant: c.variant,
      width: c.width,
      height: _kTallView,
      density: density,
      taps: taps,
    );
    final fills = onTall.height >= _kTallView - 2 * kDocsPreviewContentInset - _kEpsilon;
    if (!fills && onTall.height > room + _kEpsilon) {
      final needs = onTall.height + 2 * kDocsPreviewContentInset;
      failures.add(
        '${density.name}: stands $needs tall with the insets, on a '
        '$stageHeight stage',
      );
    }
  }
  return failures;
}

/// Runs [body] with network images served [png] — set and unset inside
/// the test body, because flutter_test checks the painting globals the
/// moment a body returns.
Future<T> _withStubbedImages<T>(
  Uint8List png,
  Future<T> Function() body,
) async {
  debugNetworkImageHttpClientProvider = () => _StubHttpClient(png);
  try {
    return await body();
  } finally {
    debugNetworkImageHttpClientProvider = null;
  }
}

void main() {
  late Uint8List png;

  setUpAll(() async {
    await _loadDocsFaces();
    png = await _stubPng();
  });

  test('the content pages draw previews at both viewports', () {
    // A content move would otherwise leave the sweep below green and empty.
    for (final viewport in _kContentRows.keys) {
      expect(
        _kCases.where((c) => c.viewport == viewport).length,
        // A floor, not a census: pages move from `<LivePreview>` to the v2
        // blocks, and only the registered examples those blocks draw stay in
        // the sweep. Zero would mean the collector went blind.
        greaterThan(50),
      );
    }
  });

  for (final viewport in _kContentRows.keys) {
    group('${viewport}px viewport', () {
      for (final c in _kCases.where((c) => c.viewport == viewport)) {
        if (_kKnownDefects.containsKey(c.key)) continue;
        final taps = _kReachableStates[c.key];
        testWidgets('${c.key} on a ${c.width}px pane', (tester) async {
          addTearDown(tester.view.reset);
          final failures = await _withStubbedImages(png, () async {
            return [
              ...await _failuresOf(tester, c),
              if (taps != null)
                for (final failure in await _failuresOf(tester, c, taps: taps)) 'after tapping $taps — $failure',
            ];
          });

          expect(
            failures,
            isEmpty,
            reason: '${c.key} on its ${c.stage.maxHeight}px stage',
          );
        });
      }
    });
  }

  group('known defects', () {
    for (final MapEntry(key: key, value: issue) in _kKnownDefects.entries) {
      testWidgets('$key still does not fit — $issue', (tester) async {
        addTearDown(tester.view.reset);
        final cases = _kCases.where((c) => c.key == key).toList();
        expect(cases, isNotEmpty, reason: 'no docs page draws $key');

        final failures = await _withStubbedImages(png, () async {
          return [for (final c in cases) ...await _failuresOf(tester, c)];
        });

        expect(
          failures,
          isNotEmpty,
          reason:
              '$key fits every pane now — close $issue and remove it '
              'from _kKnownDefects',
        );
      });
    }
  });

  group('the sweep sees', () {
    // Negative controls: if either detector goes blind, every case above
    // passes for the wrong reason.
    testWidgets('an overflow the preview reports', (tester) async {
      addTearDown(tester.view.reset);
      // Two stacked pickers need more than the tall stage — why their
      // chain has a band of its own.
      final failures = await _withStubbedImages(
        png,
        () => _failuresOf(
          tester,
          _directCase('item-picker', 'chain'),
          stage: kDocsTallConstraints.maxHeight,
        ),
      );

      expect(failures, contains(contains('overflowed')));
    });

    testWidgets('content a stage hides without an overflow', (tester) async {
      addTearDown(tester.view.reset);
      // The sidebar scrolls instead of overflowing when its stage is short.
      final failures = await _withStubbedImages(
        png,
        () => _failuresOf(
          tester,
          _directCase('navigation-bar', 'sidebar'),
          stage: kDocsMediumConstraints.maxHeight,
        ),
      );

      expect(failures, isNotEmpty);
      expect(failures, everyElement(contains('tall with the insets')));
    });
  });
}

/// Loads the faces the docs embed draws, from `docs_site/fonts`.
Future<void> _loadDocsFaces() async {
  final faces = <String, List<File>>{};
  final directory = Directory('${findRepoRoot().path}/docs_site/fonts');
  for (final file in directory.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    // Static weights only — a variable face needs a weight range.
    if (name.contains('Variable')) continue;
    final family = name.startsWith('Pretendard-')
        ? CoreFontFamily.sans
        : name.startsWith('GeistMono-')
        ? CoreFontFamily.mono
        : null;
    if (family != null) faces.putIfAbsent(family, () => []).add(file);
  }
  expect(faces.keys, containsAll([CoreFontFamily.sans, CoreFontFamily.mono]));

  for (final MapEntry(key: family, value: files) in faces.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(file.readAsBytes().then(ByteData.sublistView));
    }
    await loader.load();
  }
}

/// A small PNG from the engine's own encoder — no hand-typed bytes to get
/// wrong.
Future<Uint8List> _stubPng() async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    const ui.Rect.fromLTWH(0, 0, 4, 3),
    ui.Paint()..color = const ui.Color(0xFF9E9E9E),
  );
  final image = await recorder.endRecording().toImage(4, 3);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// The members `NetworkImage` calls, as the parity stub covers them.
class _StubHttpClient extends Fake implements HttpClient {
  _StubHttpClient(this._png);

  final Uint8List _png;

  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _StubHttpClientRequest(_png);
}

class _StubHttpClientRequest extends Fake implements HttpClientRequest {
  _StubHttpClientRequest(this._png);

  final Uint8List _png;

  @override
  final HttpHeaders headers = _StubHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _StubHttpClientResponse(_png);
}

class _StubHttpClientResponse extends Fake implements HttpClientResponse {
  _StubHttpClientResponse(this._png);

  final Uint8List _png;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _png.length;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_png).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );
}

class _StubHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
}
