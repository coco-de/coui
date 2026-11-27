// #3605 — WebCaptureBackend: SSR (jaspr) → offline harness assembly →
// puppeteer capture. Produces the PNG + raw-property-JSON pair for one
// `MatrixEntry`, matching Component ③'s three-stage responsibility list in
// `.bmad/architecture-*.md`.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:coui_web/coui_web.dart';
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/scenes.dart';
import 'package:docs_core/internal/preview/web_scene.dart';
import 'package:docs_core/markdown/repo_root.dart';
import 'package:docs_core/previews/web_registry.dart';
import 'package:docs_core/site_head.dart' show docsContentTheme;
import 'package:path/path.dart' as p;
import 'package:puppeteer/protocol/network.dart' show ResourceType;
import 'package:puppeteer/puppeteer.dart' show Browser, DeviceViewport;

import '../manifest/capture_probes.dart';
import '../model/capture_body.dart';
import '../model/capture_clock.dart';
import '../model/capture_motion.dart';
import '../model/capture_surface.dart';
import '../model/matrix_entry.dart';
import '../model/network_image_fixture.dart';
import '../model/property_field.dart';
import 'bottom_action_bar_ssr_source.dart';
import 'box_padding_observation_probe.dart';
import 'breakpoint_showcase_ssr_source.dart';
import 'client_box_source_protocol.dart';
import 'computed_style_probe.dart';
import 'data_overlay_ssr_source.dart';
import 'element_capture.dart';
import 'framed_collection_ssr_source.dart';
import 'navigation_trigger_ssr_source.dart';
import 'offline_tailwind_harness.dart';
import 'public_wrapper_ssr_source.dart';
import 'runtime_capture.dart';
import 'showcase_allocation_ssr_source.dart';
import 'ssr_render.dart';
import 'text_showcase_ssr_source.dart';
import 'visual_value_ssr_source.dart';

/// The `data-parity-key` wrapper's `display` value.
///
/// `flex`, not `block` or `inline-block` — the wrapped component is a **flex
/// item**, which is the position it has on the docs site: the docs preview
/// stage centres its example in a flex column (the rule
/// `.preview-content > div[id^="web-"] > div.w-full` in `docs_site`), so the
/// example root is a flex item there. An item sizes to its content unless it
/// declares a width, so:
///
/// - a content-sized root — a plain `div`, a `Button`, a `Badge` — renders at
///   its own width, as it does on the docs site and as the Flutter host lets
///   its twin (`capture_host.dart`);
/// - a `w-full` root resolves its percentage against the wrapper's explicit
///   [kCaptureAvailableWidthCss], so it still fills the available width.
///
/// With `inline-block` a block-level root filled the whole wrapper (CSS 2.1
/// §10.3.3: a block-level box takes its containing block's width) while the
/// docs site and Flutter shrink-wrapped the same root — 110 default-style
/// cells read `widthPx: flutter=88 web=800`.
///
/// A root its Flutter twin *fills* is not content-sized on the Flutter side,
/// so the stage states the width for it: `kWebPreviewRegistry` wraps those
/// previews in a `w-full` box (`kDocsFillWidthPreviews`), which the docs site
/// builds its Web side from too. The component itself is untouched.
///
/// The explicit width stays: a `flex` container without one would size to its
/// content, and a `w-full` descendant would have nothing definite to resolve
/// against (#3665). The PNG's own bounding box is unaffected either way — the
/// screenshot target is the wrapper's child (`[data-parity-key] > *`,
/// `probe_spec.dart`'s `rootProbeSpec`), not the wrapper itself.
const String _kWrapperDisplay = 'flex';

/// Default page navigation timeout (ms) — matches puppeteer's own built-in
/// default; named so [captureWebEntry]'s `timeoutMs` default is
/// self-documenting rather than a bare literal repeated at the call site.
const int _kDefaultTimeoutMs = 30000;

/// Canonical browser capture script shared by explicit transports.
const String kCaptureIconifyReadyScript = '''
() => {
  const api = customElements.get('iconify-icon');
  if (!api) return true;
  return [...document.querySelectorAll('iconify-icon')].every(el => {
    const icon = el.icon;
    const available = typeof icon === 'object' && icon?.body ||
      typeof icon === 'string' && api.getIcon(icon);
    return !available || el.status === 'rendered';
  });
}
''';

/// Canonical browser capture script shared by explicit transports.
const String kCaptureFontsReadyScript =
    '() => document.fonts ? document.fonts.ready.then(() => {}) '
    ': Promise.resolve()';

/// Canonical browser capture script shared by explicit transports.
const String kCaptureImageDecodeScript = '''
async () => {
  const images = [...document.images].filter(image =>
    /^https?:/.test(image.currentSrc || image.src));
  for (const image of images) image.loading = 'eager';
  await Promise.all(images.map(image => image.decode()));
}
''';

/// Canonical browser capture script shared by explicit transports.
const String kCaptureInitialAnimationScript = '''
() => {
  for (const animation of document.getAnimations()) {
    // Only time-based clocks accept milliseconds. Scroll/ViewTimeline use
    // progress values (and can be inactive), so preserve their geometry-driven
    // state. A null timeline still accepts an absolute hold time; retain the
    // existing capture policy for these detached clocks.
    const timeline = animation.timeline;
    if (timeline !== null && !(timeline instanceof DocumentTimeline)) continue;
    animation.pause();
    animation.currentTime = 0;
  }
}
''';

/// Canonical browser capture script shared by explicit transports.
const String kCaptureTwoFramesScript =
    '() => new Promise(done => requestAnimationFrame(() => '
    'requestAnimationFrame(done)))';

/// Canonical browser capture script shared by explicit transports.
const String kCaptureContextScript = '''
() => {
  const root = document.querySelector('[data-parity-key] > *');
  const box = root?.getBoundingClientRect();
  const inner = root?.firstElementChild;
  const innerCss = inner && getComputedStyle(inner);
  return JSON.stringify({
    viewportWidth: innerWidth,
    viewportHeight: innerHeight,
    text: root?.textContent.trim(),
    layout: {
      width: box?.width,
      height: box?.height,
      direction: root && getComputedStyle(root).flexDirection,
      innerPaddingLeft: innerCss?.paddingLeft,
      innerPaddingRight: innerCss?.paddingRight,
      children: [...(root?.children || [])].map(el => {
        const r = el.getBoundingClientRect();
        return {x:r.x, y:r.y, width:r.width, height:r.height};
      })
    },
    animationTimes: document.getAnimations().map(a => a.currentTime),
    animationStates: document.getAnimations().map(a => a.playState)
  });
}
''';

/// One matrix cell's Web capture output — still **raw** (Normalizer, #3606,
/// converts this to the common `PropertySnapshot` schema).
class WebCaptureResult {
  const WebCaptureResult({
    required this.pngBytes,
    required this.rawPropertyByRole,
    required this.chromeVersion,
    this.renderPhase = 'ssr',
    this.captureContext = const {},
    this.pngByRole = const {},
    this.boxPaddingByRole = const {},
  });

  final Uint8List pngBytes;

  /// Raw `getComputedStyle()` values, JSON-able, one entry per
  /// `entry.probes[i].role` — not just `root`, so a future `ProbeSpec`
  /// (an item label, a focus ring) is captured the moment #3604 declares
  /// it, with no change needed here. A role's value is `null` if its
  /// selector matched nothing (a component that renders differently than
  /// expected, or a role that genuinely isn't present for this variant) —
  /// captured as `null` rather than dropped or an empty map, so "found
  /// nothing" and "found an empty style" stay distinguishable downstream.
  final Map<String, Map<String, Object?>?> rawPropertyByRole;

  /// `browser.version` (e.g. `HeadlessChrome/123.0.0.0`) — recorded so a
  /// baseline re-promotion can tell whether a diff followed a Chrome
  /// upgrade (completion definition: "Chrome 버전을 산출물 사이드카에
  /// 기록").
  final String chromeVersion;

  /// The execution state actually measured, retained in the sidecar.
  final String renderPhase;

  /// Actual host and readiness evidence, separate from product properties.
  final Map<String, Object?> captureContext;

  /// Supplementary full stages when root measures a capped body.
  final Map<String, Uint8List> pngByRole;

  final Map<String, Map<String, Object?>> boxPaddingByRole;
}

/// Builds the SSR'd, `CoUIWeb`-wrapped, `data-parity-key`-tagged body HTML
/// for [entry].
///
/// `CoUIWeb` mirrors what `docs_core/lib/components/web_preview.dart`
/// already wraps every live preview with — the same ambient `Theme` +
/// `OverlayHost` context a real page provides, which
/// `Popover`/`Tooltip`/`Dialog`-family components (a third of Tier1: the
/// whole `overlay` catalog group) need to render their floating panel
/// content at all, not just their trigger.
///
/// The wrapper `<div data-parity-key>` carries no chrome of its own beyond
/// [_kWrapperDisplay] + [availableWidthPx] (§ capture-width contract,
/// `capture_surface.dart`) — so the wrapped component is the only thing
/// the wrapper's bounding box or its first element child's computed style
/// can reflect.
///
/// [availableWidthPx] defaults to [kCaptureAvailableWidthPx] — the value
/// every real (non-test) call site uses. It is a parameter, not a hard-coded
/// reference to the constant in the wrapper's own `styles:` literal, so a
/// test can prove the wrapper's width is a genuine function of *this*
/// input (inject 400 and 800, expect two different rendered widths) rather
/// than a coincidental page/viewport default that happens to already equal
/// 800 regardless of what this function does — the G1 guard in
/// `web_capture_backend_test.dart`.
///
/// Also mounts `docsContentTheme().styles` — the same reset
/// `docs_core/lib/embed/embed_page.dart` renders every preview under. Its
/// own comment names why: native form elements (`<button>`, `<input>`)
/// don't inherit `font-family`/`background`/`border` from an ancestor by
/// default, so without an explicit `button { font-family: inherit; … }`
/// reset they keep the browser's UA default chrome — grey fill, outset
/// border, `Arial` — regardless of what font-family class the ancestor
/// tree resolves to.
Future<String> renderCaptureBodyHtml(
  MatrixEntry entry, {
  int availableWidthPx = kCaptureAvailableWidthPx,
  void Function(Map<String, Object?>)? onCurrentBoxSource,
}) async {
  final sourceRecorder = onCurrentBoxSource == null
      ? null
      : PublicWrapperSsrSource.forEntry(entry) ??
            BottomActionBarSsrSource.forEntry(entry) ??
            ShowcaseAllocationSsrSource.forEntry(entry) ??
            BreakpointShowcaseSsrSource.forEntry(entry) ??
            TextShowcaseSsrSource.forEntry(entry) ??
            FramedCollectionSsrSource.forEntry(entry) ??
            NavigationTriggerSsrSource.forEntry(entry) ??
            DataOverlaySsrSource.forEntry(entry) ??
            VisualValueSsrSource.forEntry(entry);
  Map<String, Object?>? sourceWitness;
  final builder = kWebPreviewRegistry[entry.component];
  if (builder == null) {
    throw StateError(
      "'${entry.component}' 이 kWebPreviewRegistry 에 없음 — 카탈로그와 "
      '프리뷰 레지스트리가 갈렸다.',
    );
  }

  Component build(BuildContext context) {
    final variant = entry.variant == 'default' ? null : entry.variant;
    final scene = entry.variant.startsWith(docsScenePrefix)
        ? resolveDocsScene(entry.component, entry.variant)
        : null;
    final content = builder(context, variant);
    final capture = div(
      [
        if (scene == null) content else docsSceneHost(scene, content),
      ],
      styles: Styles(
        raw: {'display': _kWrapperDisplay, 'width': '${availableWidthPx}px'},
      ),
      attributes: {'data-parity-key': entry.key},
    );
    sourceRecorder?.recordBuild(content, capture);
    return capture;
  }

  // The calendar reads today from the clock — render at the fixed moment
  // the Flutter harness also uses, not at the wall clock.
  final html = await withClock(
    Clock.fixed(kCaptureNow),
    () => renderComponentBodyHtml(
      _BuildContextlessWrapper(innerBuilder: build),
      onMountedRoot: sourceRecorder == null
          ? null
          : (root) {
              try {
                sourceWitness = sourceRecorder.observe(root);
              } on Object catch (error) {
                sourceWitness = {'error': '$error'};
              }
            },
    ),
  );
  if (sourceRecorder is PublicWrapperSsrSource &&
      sourceWitness?['publicWrapperSourceAwaitingExactSerializedBody'] ==
          true) {
    try {
      sourceWitness = sourceRecorder.completeWithSerializedBody(html);
    } on Object catch (error) {
      sourceWitness = {'error': '$error'};
    }
  }
  final witness = sourceWitness;
  if (witness != null) onCurrentBoxSource?.call(witness);
  return html;
}

/// A minimal [StatelessComponent] whose sole purpose is handing an actual
/// `BuildContext` to [build] — [kWebPreviewRegistry] entries are plain
/// functions that need one, and SSR only ever provides a `BuildContext`
/// inside a component's own `build` method.
class _BuildContextlessWrapper extends StatelessComponent {
  const _BuildContextlessWrapper({required this.innerBuilder});

  final Component Function(BuildContext context) innerBuilder;

  @override
  Component build(BuildContext context) => .fragment([
    Style(styles: docsContentTheme().styles),
    CoUIWeb(theme: .coui, child: innerBuilder(context)),
  ]);
}

/// Assembles the offline harness HTML for [entry] and writes it to
/// [harnessDir], returning the file. `theme` is fixed to `entry.theme.name`
/// (`'light'`/`'dark'`) — the harness's `data-theme` attribute, resolved
/// entirely by CSS (D-3/AD-5), is what actually selects the palette;
/// nothing about the SSR'd body changes with it.
///
/// [iconifyHeadHtml] is `local_icons.dart`'s `buildLocalIconifyHeadHtml()`
/// output — loaded **once** by the CLI entrypoint and threaded through here
/// as a plain string, same reason [vendoredTailwindScript]/[fontFaceCss]
/// are: the Lucide collection JSON is large enough that re-reading it from
/// disk on every one of a full manifest's ~600 entries would be wasteful.
File writeHarnessFile({
  required MatrixEntry entry,
  required String bodyHtml,
  required ThemeConfig themeConfig,
  required String vendoredTailwindScript,
  required String fontFaceCss,
  required String iconifyHeadHtml,
  required Directory harnessDir,
}) {
  final surfaceStyleId = entry.surfaceStyle.name == 'defaultStyle'
      ? null
      : entry.surfaceStyle.name;

  final docsScene = entry.variant.startsWith(docsScenePrefix)
      ? resolveDocsScene(entry.component, entry.variant)
      : null;
  if (docsScene != null) requireWebScene(docsScene);
  final docsCss = docsScene == null
      ? ''
      : File(
          '${findRepoRoot().path}/docs_site/web/docs-shell.css',
        ).readAsStringSync();
  final docsScript = docsScene == null
      ? ''
      : File(
          '${findRepoRoot().path}/docs_site/web/docs-shell.js',
        ).readAsStringSync();
  final docsHead = docsScene == null
      ? ''
      : '<style>$docsCss</style>'
            '<script defer src="data:text/javascript;base64,'
            '${base64Encode(utf8.encode(docsScript))}"></script>';
  // Chrome blinks the native caret outside CSS animation timelines. Hide it
  // in the still image while retaining the component's focus styling.
  const caretStyle =
      '<style>:focus { caret-color: transparent !important; }</style>';
  final html = buildOfflineTailwindHarnessHtml(
    bodyHtml: bodyHtml,
    themeConfig: themeConfig,
    vendoredTailwindScript: vendoredTailwindScript,
    theme: entry.theme.name,
    surfaceStyleId: surfaceStyleId,
    additionalHeadHtml:
        '<style>$fontFaceCss</style>\n$iconifyHeadHtml$docsHead$caretStyle',
    animationFreezeCss: kFixedTimeCaptureComponents.contains(entry.component)
        ? kCaptureInitialAnimationCss
        : kCaptureAnimationFreezeCss,
  );

  harnessDir.createSync(recursive: true);
  final file = File(p.join(harnessDir.path, '${entry.key}.html'))
    ..writeAsStringSync(html);
  return file;
}

/// Prepares the same canonical SSR/runtime HTML for either browser transport.
Future<File> prepareWebCaptureHarness({
  required MatrixEntry entry,
  required ThemeConfig themeConfig,
  required String vendoredTailwindScript,
  required String fontFaceCss,
  required String iconifyHeadHtml,
  required Directory harnessDir,
  int availableWidthPx = kCaptureAvailableWidthPx,
  void Function(Map<String, Object?>)? onCurrentBoxSource,
}) async {
  requireCaptureProbes(
    component: entry.component,
    variant: entry.variant,
    roles: entry.probes.map((probe) => probe.role),
    boxObservationSources: entry.probes.map(
      (probe) => probe.boxObservationSource,
    ),
  );
  final clientCapture = requiresClientCapture(entry);
  final initialBody =
      !clientCapture || entry.variant.startsWith(docsScenePrefix)
      ? await renderCaptureBodyHtml(
          entry,
          availableWidthPx: availableWidthPx,
          onCurrentBoxSource: onCurrentBoxSource,
        )
      : '';
  final bodyHtml = clientCapture
      ? '$initialBody<script>${await loadRuntimeCaptureScript()}</script>'
      : initialBody;
  return writeHarnessFile(
    entry: entry,
    bodyHtml: bodyHtml,
    themeConfig: themeConfig,
    vendoredTailwindScript: vendoredTailwindScript,
    fontFaceCss: fontFaceCss,
    iconifyHeadHtml: iconifyHeadHtml,
    harnessDir: harnessDir,
  );
}

/// Captures [entry] end to end: SSR → harness file → puppeteer PNG +
/// computed style. [browser] is shared across many calls by the CLI loop
/// (performance requirement: "브라우저는 공유, 항목마다 재기동 금지") —
/// this function only ever opens/closes one page per call.
///
/// [availableWidthPx] forwards to [renderCaptureBodyHtml] — see that
/// parameter's doc comment for why it exists as a parameter rather than a
/// call-site-fixed constant.
Future<WebCaptureResult> captureWebEntry({
  required Browser browser,
  required MatrixEntry entry,
  required ThemeConfig themeConfig,
  required String vendoredTailwindScript,
  required String fontFaceCss,
  required String iconifyHeadHtml,
  required Directory harnessDir,
  bool keepHarness = false,
  bool additiveBoxObservations = false,
  int timeoutMs = _kDefaultTimeoutMs,
  int availableWidthPx = kCaptureAvailableWidthPx,
}) async {
  final clientCapture = requiresClientCapture(entry);
  final currentClientBoxSource = clientBoxSourceDescriptor(
    entry,
    additiveBoxObservations: additiveBoxObservations,
  );
  final requiredCurrentSsrKind = additiveBoxObservations
      ? requiredPublicWrapperSsrKind(entry) ??
            requiredShowcaseAllocationSsrKind(entry) ??
            requiredBreakpointShowcaseSsrKind(entry) ??
            requiredBottomActionBarSsrKind(entry) ??
            requiredTextShowcaseSsrKind(entry) ??
            requiredFramedCollectionSsrKind(entry)
      : null;
  Map<String, Object?>? currentSsrSource;
  final harnessFile = await prepareWebCaptureHarness(
    entry: entry,
    themeConfig: themeConfig,
    vendoredTailwindScript: vendoredTailwindScript,
    fontFaceCss: fontFaceCss,
    iconifyHeadHtml: iconifyHeadHtml,
    harnessDir: harnessDir,
    availableWidthPx: availableWidthPx,
    onCurrentBoxSource: additiveBoxObservations && !clientCapture
        ? (witness) => currentSsrSource = witness
        : null,
  );

  final rootProbes = entry.probes.where((probe) => probe.role == 'root');
  if (rootProbes.isEmpty) {
    throw StateError(
      '${entry.key}의 probes 에 root 역할이 없음 — PNG 스크린샷은 항상 '
      'root 를 대상으로 한다 (#3604 의 매트릭스 산출물은 항상 root 를 '
      '포함해야 한다).',
    );
  }

  try {
    final page = await browser.newPage();
    try {
      // CSS media queries observe the viewport even in SSR captures.
      // Match Flutter's view as well as the wrapper's available width.
      await page.setViewport(
        DeviceViewport(width: availableWidthPx, height: 1200),
      );
      // Flutter already stubs NetworkImage. Match its exact test input here,
      // on this capture page only; runtime probes and real docs keep photos.
      final imageBytes = loadParityNetworkImageBytes();
      final interceptionFailure = Completer<void>();
      await page.setRequestInterception(true);
      page.onRequest.listen((request) async {
        try {
          if (isCaptureHttpImageRequest(
            request.url,
            image: request.resourceType == ResourceType.image,
          )) {
            await request.respond(
              status: 200,
              contentType: 'image/png',
              headers: {'access-control-allow-origin': '*'},
              body: imageBytes,
            );
          } else {
            await request.continueRequest();
          }
        } on Object catch (error, stack) {
          if (!interceptionFailure.isCompleted) {
            interceptionFailure.completeError(error, stack);
          }
        }
      });
      await page.setOfflineMode(true);
      await Future.any<void>([
        page
            .goto(
              // `Uri.file` on a relative path returns a schemeless string (no
              // `file://`), which Chrome's CDP rejects outright as "Cannot
              // navigate to invalid URL" — `harnessDir` is passed in as a
              // repo-root-relative path by the CLI, so this must resolve to
              // absolute before building the URI.
              Uri.file(harnessFile.absolute.path)
                  .replace(
                    fragment: clientCapture
                        ? jsonEncode({
                            'key': entry.key,
                            'component': entry.component,
                            'variant': entry.variant,
                            'currentClientBoxSource': ?currentClientBoxSource,
                            'width': availableWidthPx,
                            if (entry.variant.startsWith(docsScenePrefix))
                              'scene': resolveDocsScene(
                                entry.component,
                                entry.variant,
                              ).toJson(),
                          })
                        : null,
                  )
                  .toString(),
              timeout: Duration(milliseconds: timeoutMs),
              wait: .load,
            )
            .then((_) {}),
        interceptionFailure.future,
      ]);
      if (clientCapture) {
        await page.waitForFunction(
          runtimeCaptureReadyPredicate(entry, availableWidthPx),
          timeout: Duration(milliseconds: timeoutMs),
        );
      }
      // Iconify queues its first render with setTimeout, even for registered
      // data. A load event can precede that render (a rail's user glyph was
      // intermittently blank). The head registers data and the normalizer
      // before hosts, so the first completed render uses the normalized copy.
      // Unknown/missing data keeps the harness's existing blank-icon behavior.
      await page.waitForFunction(
        kCaptureIconifyReadyScript,
        timeout: Duration(milliseconds: timeoutMs),
      );
      // Fixed local fonts (NFR-006) still need the browser to finish
      // parsing/decoding them before layout is final — a fixed sleep would
      // either race a slow decode or waste time on a fast one.
      final _ = await page.evaluate<void>(
        kCaptureFontsReadyScript,
      );
      await Future.any<void>([
        page
            .evaluate<void>(kCaptureImageDecodeScript)
            .timeout(Duration(milliseconds: timeoutMs)),
        interceptionFailure.future,
      ]);

      final fixedTime = kFixedTimeCaptureComponents.contains(entry.component);
      if (fixedTime) {
        await page.evaluate<void>(kCaptureInitialAnimationScript);
      }
      // Let font/layout observers paint their result. This is a frame
      // boundary, not a guessed time delay; predicates are checked again.
      await page.evaluate<void>(
        kCaptureTwoFramesScript,
      );
      if (clientCapture) {
        await page.waitForFunction(
          runtimeCaptureReadyPredicate(entry, availableWidthPx),
          timeout: Duration(milliseconds: timeoutMs),
        );
      }
      final contextJson = await page.evaluate<String>(kCaptureContextScript);

      // Through a box-less wrapper to the box it holds — the same element
      // the computed-style probe measures.
      final element = await findBoxRoot(page, rootProbes.first.webSelector);
      if (element == null) {
        throw StateError(
          'DegenerateCapture: ${entry.key}/${rootProbes.first.role} '
          "(selector '${rootProbes.first.webSelector}') 가 아무것도 찾지 못함.",
        );
      }

      // Guards the capture-width contract this file exists to keep, rather
      // than trusting it silently — checked *before* `.screenshot()`, not
      // after, and deliberately not left to `ElementHandle.screenshot()`'s
      // own internal `assert(boundingBox.width != 0, …)`
      // (`package:puppeteer`'s `js_handle.dart`): that assertion (a) is
      // compiled out entirely under `--no-enable-asserts` / a release
      // build, so it is not a guarantee in every environment this backend
      // runs in, and (b) its message ("Node has 0 width.") names neither
      // the matrix entry nor which probe role failed. Named so a CI
      // failure reads as "the capture pipeline is broken for this
      // specific entry" rather than an opaque downstream
      // `PixelDiffResult.dimensionMismatch`, which only ever compares two
      // *already*-degenerate captures against each other and has no way
      // to say which one (or both) rendered at 0×0.
      final box = await element.boundingBox;
      if (box == null || box.width == 0 || box.height == 0) {
        throw StateError(
          'DegenerateCapture: ${entry.key}/${rootProbes.first.role} '
          "(selector '${rootProbes.first.webSelector}') 가 "
          '${box?.width ?? 0}x${box?.height ?? 0} 로 렌더됨 — '
          'availableWidthPx=$availableWidthPx 가 w-full 컴포넌트에 닿지 '
          '않았거나, 컴포넌트가 실제로 렌더되지 않았다.',
        );
      }

      final stageProbes = entry.probes.where((p) => p.role == 'stage').toList();
      var pngBytes = stageProbes.isEmpty
          ? await captureElementPng(page, element)
          : Uint8List(0);

      final rawPropertyByRole = <String, Map<String, Object?>?>{};
      final boxPaddingByRole = <String, Map<String, Object?>>{};
      for (final probe in entry.probes) {
        if (!additiveBoxObservations) {
          rawPropertyByRole[probe.role] = await captureComputedStyle(
            page,
            probe.webSelector,
          );
        } else {
          final encoded = await page.evaluate<String>(
            computedStyleAndBoxObservationScript,
            args: [
              {
                'selector': probe.webSelector,
                'layoutSelector': probe.webSelector,
                'requested': probe.fields.contains(PropertyField.paddingPx),
                'currentClientBoxSource': ?currentClientBoxSource,
                'source': probe.boxObservationSource?.toJson(),
                'requiredCurrentSsrKind': ?requiredCurrentSsrKind,
                'currentSsrSource': currentSsrSource == null
                    ? null
                    : {
                        ...currentSsrSource!,
                        'harnessURL': harnessFile.absolute.uri.toString(),
                      },
              },
            ],
          );
          final observation = (jsonDecode(encoded) as Map)
              .cast<String, Object?>();
          rawPropertyByRole[probe.role] = (observation['legacy'] as Map?)
              ?.cast<String, Object?>();
          boxPaddingByRole[probe.role] = (observation['box']! as Map)
              .cast<String, Object?>();
        }
      }
      final pngByRole = <String, Uint8List>{};
      Map<String, Object?>? bodyBounds;
      for (final probe in stageProbes) {
        final stage = await findBoxRoot(page, probe.webSelector);
        final stageBox = await stage?.boundingBox;
        if (stageBox == null) {
          throw StateError(
            '${entry.key}: root body must span the stage height',
          );
        }
        final stagePng = await captureElementPng(page, stage!);
        final body = captureStageBodyColumn(
          key: entry.key,
          stagePng: stagePng,
          rootLeft: box.left.toDouble(),
          rootTop: box.top.toDouble(),
          rootWidth: box.width.toDouble(),
          rootHeight: box.height.toDouble(),
          stageLeft: stageBox.left.toDouble(),
          stageTop: stageBox.top.toDouble(),
          stageWidth: stageBox.width.toDouble(),
          stageHeight: stageBox.height.toDouble(),
        );
        pngBytes = body.pngBytes;
        pngByRole[probe.role] = stagePng;
        bodyBounds = body.bounds;
      }
      final chromeVersion = await browser.version;

      return WebCaptureResult(
        pngBytes: pngBytes,
        pngByRole: pngByRole,
        rawPropertyByRole: rawPropertyByRole,
        boxPaddingByRole: boxPaddingByRole,
        chromeVersion: chromeVersion,
        renderPhase: clientCapture
            ? 'client-settled'
            : fixedTime
            ? 'initial-frame'
            : 'ssr',
        captureContext: {
          if (entry.variant.startsWith(docsScenePrefix))
            'docsScene': resolveDocsScene(
              entry.component,
              entry.variant,
            ).toJson(),
          ...jsonDecode(contextJson) as Map<String, Object?>,
          'availableWidth': availableWidthPx,
          'bodyBounds': ?bodyBounds,
        },
      );
    } finally {
      await page.close();
    }
  } finally {
    if (!keepHarness) {
      if (harnessFile.existsSync()) harnessFile.deleteSync();
    }
  }
}

/// Writes [result] to `<outDir>/<key>.web.png` + `<key>.web.json`.
void writeWebCaptureArtifacts({
  required WebCaptureResult result,
  required MatrixEntry entry,
  required Directory outDir,
  Directory? boxObservationOutDir,
}) {
  outDir.createSync(recursive: true);
  File(
    p.join(outDir.path, '${entry.key}.web.png'),
  ).writeAsBytesSync(result.pngBytes);
  for (final probe in entry.probes.where((p) => p.role == 'stage')) {
    final bytes = result.pngByRole[probe.role];
    if (bytes == null) {
      throw StateError('${entry.key}: declared stage PNG is missing');
    }
    File(
      p.join(
        outDir.path,
        '${pixelArtifactKey(entry.key, probe.role)}.web.png',
      ),
    ).writeAsBytesSync(bytes);
  }
  if (boxObservationOutDir != null) {
    if (result.boxPaddingByRole.length != entry.probes.length) {
      throw StateError(
        '${entry.key}: additive box observations are incomplete',
      );
    }
    boxObservationOutDir.createSync(recursive: true);
    File(
      p.join(boxObservationOutDir.path, '${entry.key}.web.box-padding.json'),
    ).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'key': entry.key,
        'mode': 'additive-only',
        'canonicalComparisonEligible': false,
        'byRole': result.boxPaddingByRole,
      }),
    );
  }
  File(p.join(outDir.path, '${entry.key}.web.json')).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'key': entry.key,
      'chromeVersion': result.chromeVersion,
      'renderPhase': result.renderPhase,
      'captureContext': result.captureContext,
      'byRole': result.rawPropertyByRole,
    }),
  );
}

/// The existing image substitution predicate, shared with transport checks.
bool isCaptureHttpImageRequest(String url, {required bool image}) {
  final uri = Uri.tryParse(url);
  return (uri?.scheme == 'http' || uri?.scheme == 'https') && image;
}

/// CDP applies the same HTTP-image classification before pausing requests.
const kCaptureImageRequestPatterns = [
  {
    'urlPattern': 'http://*',
    'resourceType': 'Image',
    'requestStage': 'Request',
  },
  {
    'urlPattern': 'https://*',
    'resourceType': 'Image',
    'requestStage': 'Request',
  },
];

/// Validates the established stage/body relation and applies the canonical crop.
({Uint8List pngBytes, Map<String, Object?> bounds}) captureStageBodyColumn({
  required String key,
  required Uint8List stagePng,
  required double rootLeft,
  required double rootTop,
  required double rootWidth,
  required double rootHeight,
  required double stageLeft,
  required double stageTop,
  required double stageWidth,
  required double stageHeight,
}) {
  if ((rootTop - stageTop).abs() > 0.000001 ||
      (rootHeight - stageHeight).abs() > 0.000001 ||
      ((rootLeft - stageLeft) - (stageWidth - rootWidth) / 2).abs() >
          0.000001) {
    throw StateError('$key: root body must span the stage height');
  }
  final left = rootLeft - stageLeft;
  return (
    pngBytes: captureBodyColumn(stagePng, left: left, width: rootWidth),
    bounds: {
      'left': left,
      'top': rootTop - stageTop,
      'width': rootWidth,
      'height': rootHeight,
    },
  );
}
