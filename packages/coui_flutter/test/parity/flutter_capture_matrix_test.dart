// #3652 — manifest-driven generic Flutter parity capture entrypoint.
//
// `flutter_capture_test.dart` (#3376) proved the `FlutterCaptureBackend`
// contract for exactly one component (`Button`), hand-writing its widget
// instance and its chrome/padding lookup index. This file generalizes that
// proof to every entry a `tool/parity/manifest.dart`-shaped manifest names,
// reusing the same pumped-widget-tree-is-the-source-of-truth approach
// `widget_tree_probe.dart` established and the capture contract #3665
// landed (`loadParityFonts`/`parityPageBackground`/`captureAtIntegerWidth`/
// `kCaptureAvailableWidthPx`) — none of that is reimplemented here.
//
// Widget instantiation does **not** need a string-class-name → Dart-Type
// resolver (the difficulty the originating issue flagged as needing a
// spike): `docs_core/lib/previews/flutter_registry.dart`'s
// `kFlutterPreviewRegistry` already maps every catalog slug to a builder
// function taking an optional variant name and returning a `Widget` — the
// same map `docs_core`/`docs_site`'s own live-preview pages already call,
// and (per this issue's own investigation) exactly key-for-key identical
// to `web_registry.dart`'s `kWebPreviewRegistry`, which
// `web_capture_backend.dart` already calls the same way. "Root" is simply
// whatever that builder function returns — matching Web's `[data-parity-
// key] > *` selector, which is likewise "the wrapper's one rendered
// child", not a name-resolved specific component type.
//
// Run with `PARITY_MANIFEST=<path> flutter test --tags parity` from
// `packages/coui_flutter/` (fonts/relative-path resolution assumes that
// working directory — see `parity_fonts.dart`'s top comment), or
// `flutter test --tags parity --dart-define=PARITY_MANIFEST=<path>` when
// an env var isn't convenient (a CI step that can't easily set one).
// `PARITY_OUT` (env or `--dart-define`) overrides the output directory;
// absent, artifacts land at the same repo-root-relative
// `test/parity/captured` `flutter_capture_test.dart` already writes to.
@Tags(['parity'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:clock/clock.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/internal/preview/scenes.dart' show docsScenePrefix;
import 'package:docs_core/markdown/repo_root.dart' show findRepoRoot;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:syntax_highlight_lite/syntax_highlight_lite.dart' as hl;

import '../../../../tool/parity/src/manifest/capture_probes.dart';
import '../../../../tool/parity/src/model/capture_body.dart';
import '../../../../tool/parity/src/model/capture_clock.dart';
import '../../../../tool/parity/src/model/capture_motion.dart';
import '../../../../tool/parity/src/source/playground_value_authority.dart';
import 'box_padding_additive.dart';
import 'box_padding_observation.dart';
import 'box_padding_paired.dart';
import 'box_padding_preview_receipts.dart';
import 'capture_body_probe.dart';
import 'capture_host.dart';
import 'capture_localizations.dart';
import 'capture_motion_host.dart';
import 'chrome_node_probe.dart';
import 'flutter_property_snapshot.dart';
import 'integer_capture.dart';
import 'parity_capture_binding.dart';
import 'parity_fonts.dart';
import 'parity_matrix_entry.dart';
import 'parity_network_image_stub.dart';
import 'parity_page_background.dart';
import 'root_opacity_probe.dart';
import 'root_text_probe.dart';

/// `PARITY_MANIFEST` — env var first, `--dart-define` fallback (both
/// reachable, per #3665's follow-up investigation: a CI step can set
/// either, and an env var needs no recompilation between manifest paths
/// while a `--dart-define` bakes in at compile time, which is fine since
/// `flutter test` compiles fresh per invocation regardless).
///
/// `String.fromEnvironment` requires a literal name at its own call site (a
/// compile-time const) — inlined at each of the two call sites below rather
/// than factored into a shared helper that would need a dynamic name.
String? _manifestPath() {
  final fromEnv = Platform.environment['PARITY_MANIFEST'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  const fromDefine = String.fromEnvironment('PARITY_MANIFEST');
  return fromDefine.isEmpty ? null : fromDefine;
}

/// Repo-root-relative `test/parity/captured/` by default — matches
/// `flutter_capture_test.dart`'s own `_capturedDir()` exactly, so a manual
/// local run without `PARITY_OUT` lands captures in the same place. A CI
/// step instead passes an absolute path (`$RUNNER_TEMP/parity-gate/captured`),
/// which is used as-is regardless of `flutter test`'s actual working
/// directory.
String _outDirPath() {
  final fromEnv = Platform.environment['PARITY_OUT'];
  if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
  const fromDefine = String.fromEnvironment('PARITY_OUT');
  return fromDefine.isEmpty ? '../../test/parity/captured' : fromDefine;
}

Directory _capturedDir() =>
    Directory(_outDirPath())..createSync(recursive: true);

void main() {
  ParityCaptureBinding();
  setUpAll(loadParityFonts);

  // #3908 — some manifest entries (diff/hover-gallery/card-image) render
  // docs examples that load real photos via `Image.network`. This capture
  // suite's own contract only ever compares chrome (padding/border/
  // color/…), never image content — see `parity_network_image_stub.dart`'s
  // top comment for why depending on real CDN reachability here was
  // actively wrong, not merely fragile. Rendered once here; applied
  // per-entry below via `runParityEntryWithStubbedNetwork`.
  late Uint8List stubImageBytes;
  setUpAll(() async {
    stubImageBytes = await renderParityStubImageBytes();
  });

  // The Lucide set the Web harness reads offline (`tool/parity/vendor/
  // iconify`) is seeded into the icon resolver. Only the icons CoUI's own
  // components draw are bundled; an `Icon` a docs example picks for itself
  // (a `Basic` leading `LucideIcons.user`) is fetched from the Iconify API,
  // and `flutter test` has no network — the glyph never arrived and the cell
  // was captured with an empty box where the Web twin draws the icon. Which
  // icons came out blank also depended on what an earlier cell in the same
  // process had already pulled into the cache, so the capture of one entry
  // changed with the manifest it ran in.
  late Directory iconCache;
  setUpAll(() async {
    iconCache = Directory.systemTemp.createTempSync('parity-icons-');
    File(
      '../../tool/parity/vendor/iconify/lucide-1.2.121.json',
    ).copySync('${iconCache.path}/lucide.json');
    IconResolver.instance.cacheDir = iconCache.path;
    await IconResolver.instance.loadFromDisk();
  });
  tearDownAll(() {
    IconResolver.instance.clearMemoryCache();
    iconCache.deleteSync(recursive: true);
  });

  final manifestPath = _manifestPath();
  if (manifestPath == null) {
    // No manifest configured — leave exactly one `parity`-tagged test so
    // `flutter test --tags parity` (run without a manifest, e.g. by
    // accident, or while exploring locally) reports a clean skip instead
    // of failing with "no tests matched" (`flutter test`'s own exit 79 for
    // an empty selection) — see this repo's `pubspec.yaml` `test:flutter`
    // script, which excludes this tag from the blocking suite precisely so
    // that suite never needs a manifest at all.
    testWidgets(
      'skipped — no PARITY_MANIFEST provided (env var or --dart-define)',
      (tester) async {},
      skip: true,
    );
    return;
  }

  final manifestFile = File(manifestPath);
  if (!manifestFile.existsSync()) {
    testWidgets(
      'skipped — manifest file not found: $manifestPath',
      (tester) async {},
      skip: true,
    );
    return;
  }

  final entries = parseParityManifest(manifestFile);
  if (entries.isEmpty) {
    // A well-formed, empty manifest (`manifest.dart --changed-from` when no
    // Tier1 component changed) is a legitimate "nothing to capture" run,
    // not a failure — same reasoning as the skip case above.
    testWidgets(
      'skipped — manifest has 0 entries: $manifestPath',
      (tester) async {},
      skip: true,
    );
    return;
  }

  for (final entry in entries) {
    testWidgets(entry.key, (tester) async {
      await runParityEntryWithStubbedNetwork(
        stubImageBytes,
        // The calendar reads today from the clock — capture at the fixed
        // moment the Web harness also renders at, not at the test's clock.
        () => withClock(
          Clock.fixed(kCaptureNow),
          () => _captureEntry(tester, entry),
        ),
      );
    });
  }
}

/// 캡처 뷰의 **논리** 높이(px) — Web 캡처 뷰포트 높이
/// (`tool/parity/capture_web.dart` 의 `_kViewportHeight` = 1200) 와 같은
/// 수. flutter_test 기본 뷰(logical 800×600)는 자연 높이가 600 을 넘는
/// 컴포넌트(예: window 예제 648px — 600px 데스크톱 + Gap + 버튼)를
/// 클램프해 `RenderFlex overflowed` 로 캡처를 죽인다. 캡처는 child 의
/// 자연 크기로 shrink-wrap 되므로(아래 `Center(heightFactor: 1)`) 이
/// 헤드룸 확대는 600 미만 컴포넌트의 캡처 픽셀을 바꾸지 않는다.
const double _kCaptureViewportHeightLogicalPx = 1200;

/// The pixel ratio every capture is rasterized at — `toImage()`'s default,
/// one image pixel per logical pixel, the 1x screen the Web side captures.
const double _kCapturePixelRatio = 1;

/// Captures one manifest entry end to end: build → settle → rasterize →
/// probe → write `<key>.flutter.png` + `<key>.flutter.json`.
Future<void> _captureEntry(WidgetTester tester, ParityMatrixEntry entry) async {
  requireCaptureProbes(
    component: entry.component,
    variant: entry.variant,
    roles: entry.probes.map((probe) => probe.role),
  );
  // 높이만 키운다 — **폭은 그대로**: pass 1 의 natural-width 측정이
  // ambient 뷰 폭에 노출되므로 폭을 바꾸면 정수 핀 폭이 흔들려 기존
  // baseline 전체가 움직인다. dpr 도 그대로 — 래스터라이즈가 dpr 에
  // 민감하다. 물리 크기 = 논리 × dpr.
  tester.view.physicalSize = Size(
    tester.view.physicalSize.width,
    _kCaptureViewportHeightLogicalPx * tester.view.devicePixelRatio,
  );
  addTearDown(tester.view.reset);

  final builder = kFlutterPreviewRegistry[entry.component];
  if (builder == null) {
    fail(
      "'${entry.component}' 이 kFlutterPreviewRegistry 에 없음 — 카탈로그와 "
      '프리뷰 레지스트리가 갈렸다 (docs_core/lib/previews/flutter_registry.dart).',
    );
  }

  final rootProbe = entry.rootProbe;
  if (rootProbe == null) {
    fail(
      '${entry.key}: 매니페스트 항목에 role=="root" probe 가 없음 — '
      'manifest.dart 의 산출물이 아니거나 손상됨.',
    );
  }

  // #3652 — GlobalKey pitfall (the biggest trap in this file). A shared
  // module-level key reused across entries lets the framework's element
  // reconciliation treat entry N+1's `pumpWidget` as an *update* of entry
  // N's still-mounted subtree rather than a fresh mount — measured
  // empirically: `Size(130, 40)` (entry 1's Button) leaking into every
  // later entry (Card, Badge, …) with no error raised, so 622 cells full
  // of the first component's data would still look like a clean run (PNGs
  // and JSON both "succeed"). Every key here is a fresh, entry-local
  // instance, and the tree is explicitly cleared before this entry's first
  // `pumpWidget` — belt-and-suspenders on top of `flutter_test`'s own
  // per-`testWidgets` binding reset, which should already guarantee this,
  // but this file exists specifically because "should already" isn't
  // something 622 silently-wrong cells get to rely on.
  await tester.pumpWidget(const SizedBox.shrink());
  final repaintBoundaryKey = GlobalKey();
  final rootKey = GlobalKey();
  final captureNotes = <String>[];
  final needsPlaygroundReceipt =
      (Platform.environment['PARITY_PAIRED_BOX_OBSERVATIONS_OUT']?.isNotEmpty ??
          false) &&
      rootProbe.boxObservationSource?['nativeAdapterId'] ==
          'docs-playground-stage-frame-v1';
  SceneValueAuthority? sceneAuthority;
  BoxObservationError? receiptError;
  final receipts = needsPlaygroundReceipt
      ? OfficialPreviewReceipts.capture(
          registry: kFlutterPreviewRegistry,
          epoch: '${entry.key}/${identityHashCode(rootKey)}',
        )
      : null;
  if (receipts != null) {
    try {
      sceneAuthority = SceneValueAuthority.fromJson(
        readPlaygroundValueAuthority(
          sourceRoot: findRepoRoot(),
          manifestFile: File(_manifestPath()!),
          entryKey: entry.key,
          component: entry.component,
          reference: entry.variant,
        ),
      );
    } on Object catch (error) {
      receiptError = BoxObservationError(
        'INVALID_PLAYGROUND_SOURCE_AUTHORITY',
        '$error',
      );
    }
  }

  final surfaceStyle = CoreSurfaceStyleId.values.firstWhere(
    (id) => id.name == entry.surfaceStyleName,
    orElse: () => throw StateError(
      '${entry.key}: 알 수 없는 surfaceStyle "${entry.surfaceStyleName}" — '
      'CoreSurfaceStyleId 에 없음.',
    ),
  );
  // #3652 — `const ThemeData()`'s default `ResolvedColorScheme.tokenized()`
  // throws (`Bad state: CoreColor.red called on unresolved token
  // "primary"`) the moment `applySurfaceStyle` folds a style with a
  // `colorConstraint` (`neoBrutalism` et al.) into it — `applySurfaceStyle`'s
  // own doc comment names this precondition ("colorConstraint 는 ... 실제
  // ARGB 를 읽는다. base 의 colorScheme 이 토큰 참조 상태면 그 자리에서
  // 던진다"). `CoreThemePresets.light`/`.dark` are already-resolved
  // schemes, not the tokenized default. `.previewLight`/`.previewDark` are
  // deliberately NOT used either — their `previewScaleFactor = 1.15` folds
  // a 3-axis (text/size/radius) scale meant to visually match a *scaled*
  // Web docs-site embed, which would put a systematic ~15% error on every
  // dimensional field this capture reads, unrelated to any real
  // cross-platform difference.
  final baseCore = entry.dark ? CoreThemePresets.dark : CoreThemePresets.light;
  // `applySurfaceStyle` is the single source of truth for folding a surface
  // preset into a theme (its own doc comment: a verification harness that
  // re-derives this fold independently becomes "a second source of preset
  // resolution" and can silently diverge from what `CoUIApp` itself does).
  ThemeData styledFor(CoreThemeData core) => applySurfaceStyle(
    ThemeData.fromCore(core),
    surfaceStyle: surfaceStyle,
    highContrast: false,
    // The screen the capture stands for: the image is rasterized at 1
    // (`toImage`'s ratio), the 1x screen the Web capture is taken on —
    // not flutter_test's view, which keeps its own 3. `CoUIApp` folds the
    // real screen's ratio the same way.
    devicePixelRatio: _kCapturePixelRatio,
  );
  final styledTheme = styledFor(baseCore);
  // `CoUIApp` publishes the app's theme in both brightnesses for a
  // `BrightnessScope` (a light screen in a dark editor), folded like the
  // active one. This tree stands in for `CoUIApp`, so it publishes the same
  // pair; without it the scope falls back to an unfolded preset, which no
  // app inside `CoUIApp` ever renders.
  final lightTheme = entry.dark
      ? styledFor(CoreThemePresets.light)
      : styledTheme;
  final darkTheme = entry.dark ? styledTheme : styledFor(CoreThemePresets.dark);

  Widget buildApp(PinnedWidth? pin) {
    final variant = entry.variant == 'default' ? null : entry.variant;
    final authority = sceneAuthority;
    OfficialPreviewToken? token;
    if (receipts != null && authority != null) {
      try {
        token = receipts.authorize(
          entryKey: entry.key,
          component: entry.component,
          variant: variant,
          builder: builder,
          sceneValueAuthority: authority,
        );
      } on BoxObservationError catch (error) {
        receiptError ??= error;
      }
    }
    final previewWidget = builder(variant);
    final keyedPreview = KeyedSubtree(key: rootKey, child: previewWidget);
    if (token != null) {
      try {
        receipts!.record(
          token: token,
          keyedHandle: keyedPreview,
          result: previewWidget,
        );
      } on BoxObservationError catch (error) {
        receiptError ??= error;
      }
    }
    // `KeyedSubtree` introduces no `RenderObject` of its own — walking
    // `rootKey.currentContext!.findRenderObject()` resolves straight to
    // whatever [previewWidget] itself renders as its own topmost
    // `RenderBox`, the Flutter-side equivalent of Web's "the wrapper's one
    // rendered child" (`[data-parity-key] > *`).
    // Outside the keyed root, so the root still resolves to what the
    // preview renders: the publication has no render object of its own.
    Widget content = AppBrightnessThemes(
      light: lightTheme,
      dark: darkTheme,
      child: keyedPreview,
    );
    // `CoUIApp` mounts the ambient `IconTheme` (`theme.iconTheme.medium`, 20,
    // in `onSurface`) around the whole app. An `Icon` with no size in its
    // resolve chain reads that ambient size, so without it every such icon
    // in this tree drew at Flutter's own 24 fallback while the same icon in
    // an app — and on Web, whose root mounts the same 20 — drew at 20: the
    // cell came out 4px wider per icon than anything an app renders. Like
    // `IconTheme`'s own widget, this has no render object, so the keyed root
    // above still resolves to whatever the preview itself renders.
    content = IconTheme.merge(
      data: styledTheme.iconTheme.medium.copyWith(
        color: styledTheme.colorScheme.onSurface.toValue(),
      ),
      child: content,
    );
    if (pin != null) {
      // `pinnedWidthBox` (integer_capture.dart) is the one place the
      // pinned-width tree shape is written; its doc comment carries the
      // reasoning for every knob — why the slack is `+1` and only when the
      // content overhangs the box (the 801px fill-width defect), why
      // `.deferToChild`, why both `Center` factors. Sharing it with
      // `flutter_capture_test.dart` and the overlay-pinning regression test
      // is what keeps the three trees from drifting apart again.
      content = pinnedWidthBox(pin, child: content);
    }
    final app = Theme(
      data: styledTheme,
      child: Directionality(
        textDirection: .ltr,
        // #3852 — `textStyle` pins `Material`'s own re-installed
        // `DefaultTextStyle` to CoUI's baseline (bodyMedium + onSurface),
        // mirroring `CoUIApp`'s `WidgetsApp.home` wrapping
        // (`coui_app.dart`'s own doc comment: "Material 재-install
        // DefaultTextStyle from the ambient Material textTheme (14px /
        // Roboto by default) ... without the pin every inheritance-reliant
        // bare Text ... silently renders 14px Roboto"). Unpinned, a root
        // whose own chrome relies on this ambient default (rather than a
        // local `DefaultTextStyle.merge` override) reads Flutter's
        // fallback Material theme instead of CoUI's — measured (#3852):
        // `scaffold`'s root text color came back `r:29 g:27 b:32`
        // (Material's fallback) instead of CoUI's own `onSurface`.
        child: material.Material(
          color: material.Colors.transparent,
          textStyle: styledTheme.typography.bodyMedium
              .toValue(theme: styledTheme)
              .copyWith(color: styledTheme.colorScheme.onSurface.toValue()),
          // #3909 — `Overlay` stays (`EditableText`'s `SelectionOverlay`
          // needs one ancestor the moment a manifest entry autofocuses a
          // text field, #3813 — `Command`/`Filter`/`Menubar`), but
          // `RepaintBoundary` moved *inside* it, wrapping `content`
          // directly, instead of wrapping `Overlay` from the outside.
          //
          // Why this was the bug (#3909): `Overlay`'s own render object
          // (`_RenderTheatre.performLayout`) always sets `size =
          // constraints.biggest` when the incoming constraint is
          // bounded/finite — true for *this* ambient tree regardless of
          // whether that incoming constraint was itself tight or loose,
          // since `.biggest` only reads the constraint's *max*. It then
          // lays out every non-positioned child (`content` here, never
          // `Positioned`) with `BoxConstraints.tight(size)` — forced
          // exactly to that filled size, not loosely sized to its own
          // natural extent the way a plain `Stack` would. With the old
          // `RepaintBoundary` sitting *outside* `Overlay`, the boundary
          // simply painted whatever `Overlay` reported as its own size —
          // the ambient `flutter_test` view (800×600) — on every single
          // entry, independent of what that entry's actual component
          // measured as. Measured directly (#3909's own issue): 48/48
          // sampled PNGs were exactly 800×600.
          //
          // The fix is a `Center` between `Overlay` and `RepaintBoundary`
          // — `Align`'s render object (what `Center` compiles to) always
          // lays out its own single child with `constraints.loosen()`,
          // regardless of `widthFactor`/`heightFactor` (those only affect
          // how `Center` sizes *itself* relative to the child's resulting
          // size, not what constraint the child receives). So `Overlay`'s
          // forced-tight (800, 600) becomes a *loose* (0..800, 0..600)
          // bound for `RepaintBoundary`'s subtree — exactly the same
          // "bounded but not force-filled" shape `flutter_capture_test
          // .dart`'s `buildTestApp` already gives its own (`Overlay`-free)
          // `RepaintBoundary` via an unfactored `Center`, for the same
          // reason: a content-driven component (`Button`, `Card`) then
          // shrink-wraps to its own natural size within that bound, while
          // a container-driven one (`Divider`, `Progress`, `Slider`) still
          // expands to fill it — matching Web's own `[data-parity-key] >
          // *` bounding-box capture in both cases, since Web's wrapper is
          // *also* a bounded-but-not-forced 800px-wide box
          // (`kCaptureAvailableWidthPx`, `capture_surface_test.dart`).
          //
          // `captureHost` (`capture_host.dart`) is that `Center` plus an
          // `UnconstrainedBox(constrainedAxis: Axis.horizontal)`: the loose
          // *width* above is kept and the *height* is released. Web's
          // wrapper is `auto` tall, so a widget that fills a bounded height
          // (`Column(max)`, `Align`, `Center`) must not be handed 1200 to
          // fill. That file says why only the vertical axis is released.
          //
          // `Overlay`'s own `key: ValueKey(pinnedWidth)` — distinct
          // between pass 1 (`null`) and pass 2 (a rounded width) —
          // forces a genuinely fresh `OverlayState` on the second
          // `pumpWidget` call. Without it, `OverlayState.initState()`
          // (the *only* place `Overlay.initialEntries` is ever read,
          // Flutter's own `overlay.dart`) keeps pass 1's `OverlayEntry` —
          // and the *closure* it captured — mounted forever: pass 2's
          // differently-wrapped `content` (`captureAtIntegerWidth`'s own
          // pinned-width rebuild) would silently never reach the render
          // tree, reintroducing the exact "`RenderRepaintBoundary
          // .toImage()` always CEILs a fractional width, Web always
          // ROUNDS" 1px mismatch `captureAtIntegerWidth` exists to close
          // (`integer_capture.dart`'s own top comment) — the very defect
          // #3657/#3907 already fixed for the single-`Button` capture.
          // `Overlay` re-mounting between passes is ordinary Flutter
          // widget-tree churn, not a hack: `rootKey`'s `GlobalKey` still
          // lets the framework re-associate `previewWidget`'s element
          // across that remount where it can, and nothing this harness
          // measures depends on cross-pass interaction state surviving
          // (`flutter_capture_matrix_overlay_pinning_test.dart` pins the
          // resulting geometry directly).
          child: Overlay(
            key: ValueKey(pin?.width),
            initialEntries: [
              OverlayEntry(
                builder: (_) => captureHost(
                  child: RepaintBoundary(
                    key: repaintBoundaryKey,
                    child: ColoredBox(
                      color: parityPageBackground(dark: entry.dark),
                      child: captureMotionHost(
                        component: entry.component,
                        child: content,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return captureLocalizations(child: app);
  }

  final rootFinder = find.byKey(rootKey);

  // ── settle, with a bounded fallback for indeterminate/looping animation ──
  //
  // `captureAtIntegerWidth` (#3665) calls `tester.pumpAndSettle()` — no
  // custom duration/timeout — twice internally, and its default timeout is
  // 10 *minutes*. A `skeleton`/`loading` entry that animates forever would
  // otherwise stall each such entry for the full 10 minutes before this
  // file could even attempt a fallback, which at manifest scale is not a
  // slow test, it's a broken CI job. Settling once here first, with an
  // explicit short timeout, means: if the tree genuinely settles (the
  // overwhelming majority of entries), `captureAtIntegerWidth`'s own two
  // internal `pumpAndSettle()` calls each return on their very first
  // `pump()` (nothing left scheduling frames) — free, not a second wait.
  // If it does not settle, `captureAtIntegerWidth` is skipped entirely (it
  // would hit the exact same unbounded wait) in favor of a single
  // fixed-phase raw capture, and the entry is marked `settled: false`
  // rather than silently reported as if animation-phase noise weren't a
  // factor in whatever this capture shows.
  if (entry.component == 'code-snippet') {
    // A highlighter loading grammar data need not schedule a frame until
    // its Future completes. pumpAndSettle alone can certify its loading
    // branch as settled. Mount and await that actual resource outside the
    // fake clock, as the CodeSnippet highlighting tests do. Other examples'
    // intentional loading futures are left alone.
    await tester.runAsync(() async {
      await tester.pumpWidget(buildApp(null));
      final builders = tester.widgetList<FutureBuilder<hl.Highlighter?>>(
        find.descendant(
          of: find.byType(CodeSnippet),
          matching: find.byType(FutureBuilder<hl.Highlighter?>),
        ),
      );
      await Future.wait([
        for (final builder in builders) ?builder.future,
      ]).timeout(const Duration(seconds: 10));
    });
    await tester.pump();
  } else {
    await tester.pumpWidget(buildApp(null));
  }
  // Before settling, so the capture below never depends on whether an
  // earlier entry in the run already decoded the same image — see
  // `settleImagesInTree`.
  await settleImagesInTree(tester);
  var settled = true;
  try {
    // The returned pump count isn't needed here — only whether settling
    // completed within the timeout (signaled by throwing, not by the
    // count) — but discarding it silently is itself flagged, so it's
    // captured and dropped explicitly, matching this codebase's existing
    // convention for a deliberately-unused awaited result (e.g.
    // `web_capture_backend.dart`'s `final _ = await page.goto(...)`).
    final _ = await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      .sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    // `pumpAndSettle` reports "never settles" by throwing a `FlutterError`;
    // there is no `Exception` subtype to catch instead.
    // ignore: avoid_catching_errors
  } on FlutterError {
    settled = false;
    captureNotes.add(
      'pumpAndSettle timed out (likely an indeterminate/looping animation, '
      'e.g. skeleton/loading) — captured at a fixed, unsettled phase '
      'instead of the usual integer-width two-pass capture.',
    );
    await tester.pump(const Duration(milliseconds: 16));
  }

  final ui.Image image;
  if (settled) {
    image = await captureAtIntegerWidth(
      tester,
      buildApp: buildApp,
      content: rootFinder,
      boundaryKey: repaintBoundaryKey,
    );
  } else {
    final captured = await tester.runAsync(() {
      final boundary =
          repaintBoundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      return boundary.toImage();
    });
    image = captured!;
  }

  // ── flutterFinder sanity check — the first line of defense against a
  // vacuous/wrong capture (`tester.allWidgets` is cheap; this is not a
  // primary lookup mechanism, only a corroborating check) ──
  final expectedClassName = rootProbe.byTypeClassName;
  if (expectedClassName != null &&
      !tester.allWidgets.any(
        (w) => w.runtimeType.toString() == expectedClassName,
      )) {
    captureNotes.add(
      'flutterFinder byType:$expectedClassName 이 tester.allWidgets 에 '
      '없음 — 레지스트리가 예상과 다른 서브트리를 반환했을 수 있다 (변형된 '
      'variant 처리·GlobalKey 잔존 등 조용한 오캡처의 1차 탐지기).',
    );
  }

  // ── text style (optional — many roots have no direct text) ──
  //
  // #3852 — `probeRootTextStyle` (not the naive "first Text found under
  // root, fully resolved") picks the text style that represents root's own
  // visual identity, matching Web's "root DOM element's own
  // getComputedStyle()" semantics — see that function's own doc comment for
  // the measured `dialog`/`card` cases this replaces (the naive probe could
  // read a trigger Button's own label style, or a deeper per-slot override,
  // neither of which is anything belonging to root itself). #3909 — no
  // longer takes root's own render geometry: `root_scoped_walk.dart`'s
  // structural single-path descent replaced the geometric size/position
  // tolerance this used to need.
  final textStyle = probeRootTextStyle(tester, rootFinder: rootFinder);

  // ── chrome node (structural rule — see chrome_node_probe.dart) ──
  final chromeMatch = findChromeNode(tester, rootFinder: rootFinder);

  // ── opacity — always measured (root_opacity_probe.dart) ──
  //
  // Web reads `getComputedStyle(root).opacity`, which every element has.
  // This side used to pass nothing, so every cell read
  // `opacity: flutter=null web=1.0` — 262 of 262 on the nightly T2 sweep,
  // the one field failing on all of them. A found root always yields a
  // number here; `1.0` is a measurement, not a guess.
  final opacity = probeRootOpacity(
    tester,
    rootFinder: rootFinder,
    chromeRenderObject: chromeMatch?.renderBox,
  );

  final decoration = chromeMatch?.decoration;
  final paddingPx = chromeMatch?.paddingPx;
  final flatColor = chromeMatch?.flatColor;
  final physicalModelRadius = chromeMatch?.physicalModelRadius;

  var effectiveDecoration = decoration;
  if (effectiveDecoration == null && flatColor != null) {
    // A [ColoredBox]/[PhysicalModel] match — normalize into the same
    // `BoxDecoration`-shaped intermediate `buildFlutterPropertySnapshotJson`
    // already knows how to read, rather than teaching that function a
    // second, chrome-match-shaped input.
    effectiveDecoration = BoxDecoration(
      color: flatColor,
      borderRadius: physicalModelRadius,
    );
  }

  final hasStage = entry.probes.any((probe) => probe.role == 'stage');
  final bodyGeometry = hasStage
      ? captureBodyGeometry(
          rootKey.currentContext!,
          repaintBoundaryKey.currentContext!,
        )
      : null;

  final rootJson = buildFlutterPropertySnapshotJson(
    key: entry.key,
    probeRole: 'root',
    textStyle: textStyle,
    decoration: effectiveDecoration,
    padding: paddingPx,
    opacity: opacity,
    // The rendered box, read off the same finder every other probe here
    // uses. This is the one value in the snapshot that the widget tree
    // does not merely *declare* — it is what layout actually produced,
    // which is why it is the field that can catch a size token one
    // platform honours and the other treats as a floor.
    size: bodyGeometry == null
        ? tester.getSize(rootFinder)
        : Size(bodyGeometry.width, bodyGeometry.height),
  );

  // #3652 — unconditional empty-capture guard. Deliberately runs on *every*
  // entry, not only ones where `findChromeNode` came up empty — gating this
  // check behind "only check entries the chrome rule already succeeded on"
  // is exactly the loophole it exists to close (a composite root the rule
  // *should* have matched but silently didn't would sail through
  // ungated). A vacuous snapshot is one where no chrome node was found
  // *and* no text was captured — every paint-relevant field null.
  //
  // Verified empirically (not assumed) which failure this actually
  // prevents: `normalizeWebSnapshot` (`web_property_normalizer.dart`)
  // constructs `PropertySnapshot` fields unconditionally from
  // `getComputedStyle()` strings, which are essentially never absent (a
  // browser always resolves a concrete value — `0px`, `rgba(0,0,0,0)` —
  // even for an element with no explicit chrome of its own); a role Web's
  // own selector doesn't match at all is instead `null` in `byRole` and
  // already throws its own `InfraFailure` one layer up
  // (`captureWebEntry`/`entry_loader.dart`). So the real Web side is
  // essentially never null for these fields. Constructing an unguarded
  // all-null Flutter snapshot and running it through `compare.dart`
  // against a real (fixture) Web snapshot did **not** produce the
  // `null==null → matches` pass `_withinTolerance` allows for in theory —
  // it produced 14/14 fields *failing* (`flutter=null web=<real value>`,
  // `PropertyDiffResult.hasFailures` came back true, exit code 1). That is
  // the actual
  // risk this guard closes: without it, a component this probe's
  // chrome-node heuristic doesn't yet cover (Tabs-shaped composites, the
  // real motivating case) reads as a *guaranteed field-by-field design
  // regression* on every single run, indistinguishable in the report from
  // an actual cross-platform defect — noise that would drown the real
  // signal Phase A's soak period is trying to measure. Omitting the role
  // instead reports it as what it actually is: this probe found nothing to
  // compare, not "Flutter and Web disagree about everything". `entry_loader
  // .dart`'s `loadFlutterPropertySnapshot` throws `InfraFailure` for the
  // missing (entry, role) downstream in `compare.dart`/`report.dart`
  // (confirmed: exit code 2, `[compare] 0 passed, 0 failed, N
  // infra-skipped`) — an honest "nothing to compare", neither a false pass
  // nor a false regression. This does not fail *this* flutter test — a
  // composite/wrapper-only root (Tabs-shaped: no single chrome box spans
  // the whole root, but its content is elsewhere in the tree, not
  // necessarily reachable as "root"'s own direct text either) is an
  // expected shape for some catalog components, not a bug in this file;
  // `captureNotes` still records it so it's auditable, not silent.
  final isVacuous = _isVacuousSnapshot(rootJson);
  final additiveOut = Platform.environment['PARITY_PADDING_OBSERVATIONS_OUT'];
  if (additiveOut != null && additiveOut.isNotEmpty) {
    final observation = observeAdditiveBoxPadding(
      key: entry.key,
      probes: entry.probes,
      legacyRootOmitted: isVacuous,
      captureRoot: rootKey.currentContext! as Element,
      canonicalFrame: chromeMatch?.renderBox,
      docsSceneConstructorResult: entry.variant.startsWith(docsScenePrefix)
          ? (rootKey.currentContext!.widget as KeyedSubtree).child
          : null,
    );
    final directory = Directory(additiveOut)..createSync(recursive: true);
    File(
      '${directory.path}/${entry.key}.padding-observation.json',
    ).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(observation),
    );
  }
  final pairedOut = Platform.environment['PARITY_PAIRED_BOX_OBSERVATIONS_OUT'];
  if (pairedOut != null && pairedOut.isNotEmpty) {
    ValidatedPreviewReceipt? mountedReceipt;
    final authority = sceneAuthority;
    if (receipts != null && authority != null) {
      try {
        mountedReceipt = receipts.requireMounted(
          captureRoot: rootKey.currentContext! as Element,
          entryKey: entry.key,
          component: entry.component,
          variant: entry.variant == 'default' ? null : entry.variant,
          epoch: receipts.epoch,
          sceneValueAuthority: authority,
        );
      } on BoxObservationError catch (error) {
        receiptError = error;
      }
    }
    final observation = observePairedNativePadding(
      key: entry.key,
      probes: entry.probes,
      captureRoot: rootKey.currentContext! as Element,
      registryResult: (rootKey.currentContext!.widget as KeyedSubtree).child,
      legacyRootOmitted: isVacuous,
      previewReceipt: mountedReceipt,
      previewReceiptError: receiptError,
    );
    final directory = Directory(pairedOut)..createSync(recursive: true);
    File(
      '${directory.path}/${entry.key}.native.box-padding.json',
    ).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(observation),
    );
  }
  if (isVacuous) {
    captureNotes.add(
      'root 스냅샷이 비어있음 (chrome 노드 미발견 + 텍스트 미발견) — '
      '"root" 역할을 <key>.flutter.json 에서 생략함. 아래 rootOmitted 마커가 '
      '이 생략을 기계가독으로 표시해, entry_loader 가 이를 진짜 인프라 '
      '실패(파일 부재/손상)와 구분해 "구조적 스킵" 으로 분류한다 — property '
      '비교만 건너뛰고 픽셀 회귀는 계속 돈다. 마커 없이 role 만 생략했다면 '
      'InfraFailure(exit 2) 로 오분류되고, 생략하지 않았다면 모든 필드가 '
      '"flutter=null web=<real>" 로 어긋나 확정적 실패(exit 1)가 됐을 것이다 '
      '(실측 확인 — Web 은 getComputedStyle() 이 항상 구체값을 내므로 '
      'null==null 항등 통과가 아니라 전면 불일치로 나타난다).',
    );
  }

  final byRole = <String, Map<String, Object?>>{
    if (!isVacuous) 'root': rootJson,
  };
  if (bodyGeometry != null) {
    byRole['stage'] = buildFlutterPropertySnapshotJson(
      key: entry.key,
      probeRole: 'stage',
      size: tester.getSize(rootFinder),
    );
  }

  File('${_capturedDir().path}/${entry.key}.flutter.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'key': entry.key,
      'byRole': byRole,
      // 구조적 생략 마커 — root 스냅샷이 *설계된 형태* 때문에 비어 role 을
      // 생략했음을 기계가독으로 표시한다 (multi-slot root 라 chrome walk 이
      // 형제 간 추측을 거부(#3904)했고 root 소유 텍스트도 없는 컴포넌트).
      // `entry_loader.dart` 가 이 마커로 "구조적 스킵"(property 만 스킵,
      // 픽셀 회귀는 계속) 과 진짜 인프라 실패(파일 부재/손상, exit 2)를
      // 구분한다. 값은 `entry_loader.dart` 의 `kRootOmittedNoChrome` 과
      // 같은 리터럴이어야 한다.
      if (isVacuous) 'rootOmitted': 'no-root-chrome',
      // Flutter-only sidecar fields — `loadFlutterPropertySnapshot` only
      // ever reads `key`/`byRole`, so these are ignored downstream, not a
      // schema break. Web's own capture writes an analogous
      // platform-specific extra (`chromeVersion`); these are this
      // platform's equivalents.
      'settled': settled,
      'capturePhase': kFixedTimeCaptureComponents.contains(entry.component)
          ? 'initial-frame'
          : settled
          ? 'settled-runtime'
          : 'unsettled-runtime',
      'captureNotes': captureNotes,
      if (bodyGeometry != null)
        'bodyBounds': {
          'left': bodyGeometry.left,
          'top': 0,
          'width': bodyGeometry.width,
          'height': bodyGeometry.height,
        },
    }),
  );

  // ── PNG — written even for a vacuous property snapshot: something *was*
  // rasterized, and a pixel-signal comparison can still be meaningful even
  // when this file's own chrome-attribution heuristic found nothing to
  // name. ──
  final stagePngBytes = await tester.runAsync(() async {
    final byteData = await image.toByteData(format: .png);
    return byteData!.buffer.asUint8List();
  });
  final pngBytes = bodyGeometry == null
      ? stagePngBytes!
      : captureBodyColumn(
          stagePngBytes!,
          left: bodyGeometry.left,
          width: bodyGeometry.width,
        );
  const minPlausiblePngBytes = 100;
  expect(
    pngBytes.length,
    greaterThan(minPlausiblePngBytes),
    reason: '${entry.key}: PNG 산출물이 비정상적으로 작음 — 빈 캡처일 가능성.',
  );
  File(
    '${_capturedDir().path}/${entry.key}.flutter.png',
  ).writeAsBytesSync(pngBytes);
  if (bodyGeometry != null) {
    File(
      '${_capturedDir().path}/${pixelArtifactKey(entry.key, 'stage')}.flutter.png',
    ).writeAsBytesSync(stagePngBytes);
  }

  // #3665 — opaque background guard, unconditional for every entry (not
  // Button-specific like the original proof-of-contract test): every
  // capture composites over `parityPageBackground()`, so every capture's
  // corner must be opaque, or every rounded component in the whole run
  // would carry the same fixed pixel-diff floor `parity_page_background
  // .dart`'s top comment measured (~2%).
  final decodedCorner = await tester.runAsync(() async {
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData();
    return byteData!.buffer.asUint8List();
  });
  // rawRgba byte layout is [r, g, b, a] per pixel — index 3 is the first
  // (top-left) pixel's alpha channel; a byte channel's fully-opaque value
  // is 255 (0xFF).
  const alphaChannelByteOffset = 3;
  const fullyOpaqueByteValue = 255;
  final cornerAlpha = decodedCorner![alphaChannelByteOffset];
  expect(
    cornerAlpha,
    fullyOpaqueByteValue,
    reason:
        '${entry.key}: top-left corner alpha is $cornerAlpha, not opaque — '
        'the capture target is not composited over parityPageBackground().',
  );

  // #3909 — regression pin, mirroring `flutter_capture_test.dart`'s own
  // `expectedCaptureWidthPx` pin (#3657) for the standalone single-`Button`
  // capture. `button-primary-light-defaultStyle`'s capture width is 56px
  // (same key, same registry entry
  // `flutter_capture_test.dart` already pins — see that file's pin comment
  // for the measurement) — if this
  // manifest's own
  // capture boundary regresses back to wrapping `Overlay` from the
  // outside (`Overlay` force-tight-sizing every root to the ambient
  // `flutter_test` view, #3909's own issue), this key's capture goes back
  // to 800×600 and this assertion is what catches it, rather than only the
  // (advisory, not run every PR) parity-report field counts this file's
  // sibling tooling produces.
  if (entry.key == 'button-primary-light-defaultStyle') {
    // 56: the docs example's '기본' label at weight 500 rounds to 56 — the
    // number `flutter_capture_test.dart` pins. What this pin guards is a
    // capture boundary that regressed to wrapping `Overlay`: that produces
    // 800x600, not 56.
    const expectedCaptureWidthPx = 56;
    const expectedCaptureHeightPx = 40;
    expect(
      image.width,
      expectedCaptureWidthPx,
      reason:
          '${entry.key}: capture width is ${image.width}px, not '
          '${expectedCaptureWidthPx}px — the capture boundary is no longer '
          "narrowed to the component's own natural size (#3909 regressed).",
    );
    expect(
      image.height,
      expectedCaptureHeightPx,
      reason:
          '${entry.key}: capture height is ${image.height}px, not '
          '${expectedCaptureHeightPx}px — the capture boundary is no '
          "longer narrowed to the component's own natural size (#3909 "
          'regressed).',
    );
  }
}

/// A `PropertySnapshot`-JSON map (`buildFlutterPropertySnapshotJson`'s
/// return value) counts as vacuous when every field that would actually
/// distinguish one component's render from another's is `null` — the
/// metadata-only fields (`key`/`platform`/`probeRole`) don't count, they're
/// present on every capture by construction.
bool _isVacuousSnapshot(Map<String, Object?> json) {
  const paintRelevantFields = [
    'fontFamily',
    'fontWeight',
    'fontSizePx',
    'lineHeightPx',
    'letterSpacingPx',
    'color',
    'backgroundColor',
    'borderColor',
    'borderWidthPx',
    'borderRadiusPx',
    'paddingPx',
    'outlineWidthPx',
    'outlineOffsetPx',
    'boxShadow',
    // `opacity` is deliberately absent: `probeRootOpacity` always yields a
    // number for a found root, so its presence says nothing about whether
    // the chrome walk or the text probe found anything root-owned — which
    // is the question this predicate answers. Listing it would make every
    // snapshot non-vacuous and re-open the all-null-vs-real comparison
    // this guard exists to prevent.
  ];
  return paintRelevantFields.every((field) => json[field] == null);
}
