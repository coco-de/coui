// #3376 — proves the FlutterCaptureBackend contract end to end: pump a
// real CoUI widget, extract its render values with Epic A's
// `widget_tree_probe.dart` primitives, convert them to the
// `PropertySnapshot` JSON shape (`flutter_property_snapshot.dart`), and
// write both a `<key>.flutter.json` and a `<key>.flutter.png` —
// `tool/parity/compare.dart` (#3607) can load either unmodified, the same
// pair `web_capture_backend.dart` writes for Web (#3595's own completion
// definition: "매트릭스 한 칸에 대해 양 플랫폼 PNG + 속성 JSON 산출"). This
// is a *parity capture*, not a golden (pixel-regression) test — it belongs
// beside the property capture under `test/parity/`
// (`.bmad/architecture-*.md`'s Code Organization table:
// "packages/coui_flutter/test/parity/ # ② + ⑧ Flutter"), not under
// `test/src/golden/` where Alchemist's own baseline images live.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../src/parity_probe/widget_tree_probe.dart';
import 'flutter_property_snapshot.dart';
import 'integer_capture.dart';
import 'parity_capture_binding.dart';
import 'parity_fonts.dart';
import 'parity_page_background.dart';

/// Repo-root-relative `test/parity/captured/`, resolved from this
/// package's own directory (`flutter test`'s working directory is the
/// package root, `packages/coui_flutter/`, not the repo root the
/// architecture doc's paths are all written relative to).
Directory _capturedDir() =>
    Directory('../../test/parity/captured')..createSync(recursive: true);

/// Writes [snapshotByRole] to `<capturedDir>/<key>.flutter.json`, matching
/// `web_capture_backend.dart`'s `writeWebCaptureArtifacts` sibling shape
/// exactly: `{key, byRole: {role: <PropertySnapshot JSON>}}`. Web's
/// wrapper additionally carries `chromeVersion` (a Web-only fact) — this
/// wrapper has no Flutter-side equivalent to put there, so the field is
/// simply absent rather than a fabricated placeholder.
void _writeFlutterCapture({
  required String key,
  required Map<String, Map<String, Object?>> snapshotByRole,
}) {
  final file = File('${_capturedDir().path}/$key.flutter.json');
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'key': key,
      'byRole': snapshotByRole,
    }),
  );
}

/// A [GlobalKey] identifying the [RepaintBoundary] [buildTestApp] wraps its
/// child in — the same "screenshot just the component, not the whole page"
/// intent `capture_web.dart`'s `data-parity-key` wrapper serves for Web.
final GlobalKey _repaintBoundaryKey = GlobalKey();

void main() {
  ParityCaptureBinding();
  group('FlutterCaptureBackend — Button', () {
    // #3665 — loads real Pretendard/Geist Mono bytes once for this
    // file (see `parity_fonts.dart`'s top comment for why every other
    // test file in this package must not inherit this).
    setUpAll(loadParityFonts);

    testWidgets(
      'writes a <key>.flutter.json and <key>.flutter.png with the root '
      'role populated from the pumped widget tree',
      (tester) async {
        const key = 'button-primary-light-defaultStyle';

        // #3657 — the widget-under-test comes from the same
        // `kFlutterPreviewRegistry` entry `capture_web.dart`'s Web
        // pipeline renders for this exact key (`ButtonPrimaryExample`,
        // label `'Primary'`), not a hand-typed `Button(child: Text(...))`.
        // Root-caused: this test previously hard-coded `Text('Submit')`
        // while the Web side (via the registry) rendered `Text('Primary')`
        // — two different strings of different intrinsic width, captured
        // and then compared to each other as if they were the same
        // component. That was the entire 116×40-vs-80×40 mismatch #3657
        // reported: with matching content, both platforms' *unrounded*
        // intrinsic widths agree to within ~0.01px (measured directly —
        // at the then label weight 600, Flutter `Size(81.387, 40.0)` vs Chrome
        // `boundingBox 81.390625×40`), so there is no font-shaping
        // divergence between the two rasterizers loading the same static
        // Pretendard OTF file. Sourcing both platforms' widget-under-test
        // from the one registry (`docs_core/lib/previews/{flutter,web}_
        // registry.dart`) is what "같은 기준" means here — it's the same
        // fix `flutter_capture_matrix_test.dart` (#3652) already applies
        // to every other component; this file just predates it.
        final buttonWidget = kFlutterPreviewRegistry['button']!('primary');
        final rootFinder = find.byType(Button);

        // #3657 — integer-width two-pass capture (`integer_capture.dart`,
        // #3665). Even with identical content, `RenderRepaintBoundary.
        // toImage()` always CEILs a fractional intrinsic width while
        // Chrome's `element.screenshot()` rounds to NEAREST — a
        // rounding-*function* mismatch, not a rendering difference, and
        // the residual dimension delta once the content-mismatch above is
        // fixed. `captureAtIntegerWidth` already solves this for
        // `flutter_capture_matrix_test.dart`; this file's own
        // `buildTestApp` tree needs no `Overlay` ancestor (unlike that
        // generic entrypoint), so the same helper drops in unmodified.
        final image = await captureAtIntegerWidth(
          tester,
          buildApp: (pin) => buildTestApp(buttonWidget, pin: pin),
          content: rootFinder,
          boundaryKey: _repaintBoundaryKey,
        );

        final textFinder = find.descendant(
          of: rootFinder,
          matching: find.byType(Text),
        );
        final textStyle = probeEffectiveTextStyle(tester, textFinder);

        // #3665 — test-font exclusion. flutter_test's own deterministic
        // test font renders every unrecognized family as one square glyph
        // per character, exactly fontSize wide — so a real font's
        // TextPainter width is (almost) never exactly
        // `text.length * fontSize`. Only checks *that* this capture isn't
        // measuring the synthetic test font, not any exact Pretendard
        // metric — a fixed value (`closeTo(48.111…)`) belongs to the
        // advisory parity-gate baseline, not this blocking test:flutter
        // target, where a Pretendard version bump must not repo-wide
        // block every PR.
        //
        // #3657 — `capturedText` is read off the actually-pumped `Text`
        // widget rather than hard-coded, so this assertion (and every
        // sanity check below it) stays correct if the shared registry's
        // label ever changes, instead of silently drifting the way the
        // old hard-coded `'Submit'` literal did.
        final capturedText = tester.widget<Text>(textFinder).data!;
        final testFontWidth = capturedText.length * (textStyle.fontSize ?? 0);
        final textPainter = TextPainter(
          text: TextSpan(text: capturedText, style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        expect(
          textPainter.width,
          isNot(testFontWidth),
          reason:
              'textPainter.width (${textPainter.width}) == '
              'text.length * fontSize ($testFontWidth) — this is '
              "flutter_test's deterministic test-font signature (1 glyph "
              '== 1 fontSize square), not real Pretendard metrics. '
              'loadParityFonts() did not load, or was never called.',
        );
        // `skip: 1`, confirmed by hand against the actual pumped tree
        // (three DecoratedBoxes under `Button`, in this order): [0] is
        // the focus ring's gap band (present even unfocused, at opacity
        // 0 — a shape stroke, so its decoration is not a `BoxDecoration`
        // and `probeBoxDecoration` reads `null` there); [1] is the
        // button's own chrome (fill color 0x4273D7 confirmed against the
        // real Web capture of the same variant, padding 16/8/16/8
        // likewise confirmed); [2] is the focus ring's border stroke.
        // The band layer exists because Button's focus slot states a
        // (transparent) band colour; a slot with no band colour drops the
        // layer and shifts these indices down by one.
        const chromeSkipIndex = 1;
        final decoration = probeBoxDecoration(
          tester,
          rootFinder,
          skip: chromeSkipIndex,
        );
        final padding = probeEffectivePadding(
          tester,
          rootFinder,
          skip: chromeSkipIndex,
        );

        final rootJson = buildFlutterPropertySnapshotJson(
          key: key,
          probeRole: 'root',
          textStyle: textStyle,
          decoration: decoration,
          padding: padding,
          size: tester.getSize(rootFinder),
        );

        // The properties a real Button paints must actually have reached
        // this snapshot — a JSON file with every field null would satisfy
        // the schema but prove nothing about the capture pipeline.
        expect(rootJson['fontFamily'], isNotNull);
        expect(rootJson['fontWeight'], isNotNull);
        expect(rootJson['fontSizePx'], isNotNull);
        expect(rootJson['backgroundColor'], isNotNull);
        expect(rootJson['paddingPx'], isNotNull);
        // Geometry is the one field layout produces rather than the tree
        // declaring it, so "the pipeline carried it" is the only thing
        // that can be checked here — and it is exactly what was missing
        // when the gate compared fifteen painted fields and no size.
        expect(rootJson['widthPx'], isNotNull);
        expect(rootJson['heightPx'], isNotNull);

        _writeFlutterCapture(key: key, snapshotByRole: {'root': rootJson});

        final written = jsonDecode(
          File('${_capturedDir().path}/$key.flutter.json').readAsStringSync(),
        );
        expect(written['key'], key);
        expect(written['byRole']['root']['fontWeight'], rootJson['fontWeight']);

        // `captureAtIntegerWidth` already returned the rasterized `ui.Image`
        // (pinned to the rounded-to-nearest integer width) above — only the
        // PNG encode is left, and that (like the boundary rasterization
        // itself) is real async I/O that needs `runAsync`.
        final rawPngBytes = await tester.runAsync(() async {
          final byteData = await image.toByteData(
            format: ui.ImageByteFormat.png,
          );
          return byteData!.buffer.asUint8List();
        });
        final pngBytes = rawPngBytes!;
        // A blank/near-blank capture (a boundary that rendered nothing)
        // would still produce *some* PNG bytes — a minimum size floor
        // catches a boundary sized to nothing more reliably than
        // `isNotEmpty` would.
        const minPlausiblePngBytes = 100;
        expect(pngBytes.length, greaterThan(minPlausiblePngBytes));

        // #3657 — regression pin. The pinned width tracks Button's real
        // Web capture width for this exact key
        // (`button-primary-light-defaultStyle`, via `capture_web.dart`'s
        // puppeteer pipeline against the same `docs_core` registry entry)
        // — not a value derived from this file. Either root cause #3657
        // fixed regressing moves this number on its own: reverting only
        // the registry-sourced [buttonWidget] above (back to a
        // hand-typed `Text('Submit')`) reproduces a different capture width —
        // `'Submit'` is not `'기본'`, the label Web's shared preview
        // registry actually renders for this key.
        // Reverting only the `captureAtIntegerWidth` pinning (back to a
        // bare `boundary.toImage()`) reproduces +1px —
        // `RenderRepaintBoundary.toImage()` CEILs a fractional width
        // rather than rounding to nearest the way Chrome's own
        // `element.screenshot()` does (`integer_capture.dart`).
        //
        // 56: the registry entry's label is '기본' at weight 500, and
        // `captureAtIntegerWidth` rounds its natural width to 56. The
        // number follows the docs example's label — when that label changes
        // this pin moves with it; what it guards is the boundary, which
        // regressing would produce 800x600 or the CEIL'd +1px, not a
        // different label width. (With the English 'Primary' label it was
        // 80, from 80.252px. At the earlier weight 600 Chrome 150 laid the
        // same registry entry out within 0.004px of Flutter; the parity
        // capture job is what compares the two at 500.)
        const expectedCaptureWidthPx = 56;
        final decodedPng = img.decodePng(pngBytes);
        expect(decodedPng, isNotNull, reason: '캡처된 PNG 디코딩 실패');
        expect(
          decodedPng!.width,
          expectedCaptureWidthPx,
          reason:
              'Flutter capture width is ${decodedPng.width}px, not '
              '${expectedCaptureWidthPx}px — no longer matches the real '
              'Web capture of this key (#3657 regressed).',
        );

        File(
          '${_capturedDir().path}/$key.flutter.png',
        ).writeAsBytesSync(pngBytes);

        // #3665 — opaque background guard. `toImage()` captures *with* an
        // alpha channel: the corner of a rounded component's own bounding
        // box (outside its border-radius) is transparent (alpha 0) unless
        // the capture target is composited over an opaque page background
        // first — the same background Web's own corner shows through to
        // (`parity_page_background.dart`). Checks the top-left pixel of
        // the artifact this test just wrote, not an intermediate value.
        final decodedCorner = await tester.runAsync(() async {
          final codec = await ui.instantiateImageCodec(pngBytes);
          final frame = await codec.getNextFrame();
          final byteData = await frame.image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          return byteData!.buffer.asUint8List();
        });
        final cornerAlpha = decodedCorner![3];
        expect(
          cornerAlpha,
          255,
          reason:
              'top-left corner pixel alpha is $cornerAlpha, not opaque '
              '(255) — the capture target is not composited over '
              'parityPageBackground(), so this corner is transparent '
              'while the equivalent Web corner shows an opaque page '
              'background through it. Every rounded component would '
              'carry a fixed pixel-diff floor unrelated to any real '
              'rendering difference.',
        );
      },
    );
  });
}

/// A minimal ambient tree matching `buildGoldenTestApp`'s theme/direction
/// setup, but wrapping [child] in a keyed [RepaintBoundary] so
/// `captureAtIntegerWidth` can screenshot just the component — the same
/// "screenshot the component, not the whole page" intent
/// `capture_web.dart`'s `data-parity-key` wrapper serves for Web.
///
/// The [RepaintBoundary]'s child is [ColoredBox]-wrapped in
/// [parityPageBackground] (`dark: false` — this file only captures the
/// light theme today) rather than [child] directly — see
/// `parity_page_background.dart`'s top comment for why an unwrapped
/// (alpha-transparent) capture would carry a fixed pixel-diff floor
/// against Web's opaque one on every rounded component.
///
/// [pin] is `captureAtIntegerWidth`'s contract (`integer_capture
/// .dart`): `null` for pass 1 ([child] renders at its own natural width),
/// or a rounded-to-nearest integer for pass 2, in which case [child] is
/// centered — never force-stretched — inside a [pin]-wide box.
/// This tree has no `Overlay` ancestor (unlike
/// `flutter_capture_matrix_test.dart`'s generic entrypoint), so
/// `captureAtIntegerWidth`'s own two-pass measurement isn't defeated by
/// `Overlay`'s theater sizing to `constraints.biggest` instead of its
/// non-positioned child's natural size.
Widget buildTestApp(Widget child, {PinnedWidth? pin}) {
  // `pinnedWidthBox` (integer_capture.dart) is the one place the
  // pinned-width tree shape is written — its doc comment carries the
  // reasoning for every knob (`+1` slack only when the content overhangs,
  // `.deferToChild`, the two `Center` factors).
  final content = pin == null ? child : pinnedWidthBox(pin, child: child);
  return Theme(
    data: const ThemeData(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: material.Material(
        child: Center(
          child: RepaintBoundary(
            key: _repaintBoundaryKey,
            child: ColoredBox(
              color: parityPageBackground(dark: false),
              child: content,
            ),
          ),
        ),
      ),
    ),
  );
}
