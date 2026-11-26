// ignore_for_file: avoid_web_libraries_in_flutter, depend_on_referenced_packages
@JS()
library;

import 'dart:js_interop';

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/internal/preview/flutter_selection.dart';
import 'package:docs_core/internal/preview/selection.dart';

import 'package:docs_core/previews/flutter_chain_registry.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:docs_core/previews/preview_focus_gate.dart';
import 'package:docs_core/previews/props/flutter_prop_previews.dart';
import 'package:docs_core/shared/chain_permutations.dart';
import 'package:docs_core/shared/chain_shuffle_store.dart';
import 'package:docs_core/shared/docs_locale.dart';
import 'package:docs_core/shared/glass_preview_backdrop.dart';
import 'package:docs_core/shared/playground_spec.dart';
import 'package:docs_core/shared/playground_store.dart';
import 'package:docs_core/shared/preview_constraints.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import 'glass_preview_backdrop_painter.dart';

/// Calls JavaScript `eval()` in the global scope.
@JS('eval')
external void _jsEval(String code);

/// Evaluates JS expression and returns a string result.
@JS('eval')
external String? _jsEvalString(String code);

/// Returns true if docs_site is in dark mode.
bool _isDarkMode() {
  if (!kIsWeb) return false;
  try {
    return _jsEvalString(
          "document.documentElement.getAttribute('data-theme')",
        ) ==
        'dark';
  } catch (_) {
    return false;
  }
}

/// The title the page already carries.
///
/// `CoUIApp` hands its `title` to Flutter's `Title`, and on the web that
/// widget writes `document.title` every time it builds. An embed left at the
/// default empty title therefore blanks the browser tab of the page it sits
/// in — every component page lost its title the moment its first preview
/// loaded. The embed does not name the page, so it hands back the name the
/// page has.
String _documentTitle() {
  if (!kIsWeb) return '';
  try {
    return _jsEvalString('document.title') ?? '';
  } catch (_) {
    return '';
  }
}

/// The surface style docs_site currently has selected.
///
/// Read from the same document attribute the Web previews key their CSS
/// off, so the two halves of a side-by-side preview cannot disagree about
/// which style is active.
CoreSurfaceStyleId _selectedSurfaceStyle() {
  if (!kIsWeb) return CoreSurfaceStyleId.defaultId;
  try {
    final value = _jsEvalString(
      "document.documentElement.getAttribute('$kSurfaceStyleAttribute')",
    );
    for (final id in CoreSurfaceStyleId.values) {
      if (id.name == value) return id;
    }
  } catch (_) {
    // Fall through to the default.
  }

  return CoreSurfaceStyleId.defaultId;
}

/// Flutter half of a docs live preview, embedded through `FlutterEmbedView`.
///
/// Renders the component and nothing else — it does not size itself. The
/// height of the view it lives in is the tier chosen on the jaspr side
/// before the view is created (`shared/preview_constraints.dart`): a Flutter
/// web view takes its size from the `ViewConstraints` passed to `addView`
/// and never resizes afterwards, so measuring from in here is too late to
/// matter.
class PreviewApp extends StatefulWidget {
  const PreviewApp({
    super.key,
    required this.component,
    this.variant,
    this.panelId,
  });

  final String component;
  final String? variant;

  /// chain 패널의 인스턴스-유일 id — 셔플 스토어 구독 키이자 임베드
  /// 컨테이너 id 파생 근거. non-chain 프리뷰는 null.
  final String? panelId;

  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  bool _isDark = false;
  CoreSurfaceStyleId _surfaceStyle = CoreSurfaceStyleId.defaultId;

  @override
  void initState() {
    super.initState();
    _isDark = _isDarkMode();
    _surfaceStyle = _selectedSurfaceStyle();
    if (kIsWeb) {
      _observeThemeChanges();
    }
    // chain 패널이면 아일랜드(버튼)와 같은 Dart 힙의 스토어를 직접 구독 —
    // DOM attribute·폴링 경유 없는 직결 채널. 임베드 lazy 로딩 중의
    // 클릭은 스토어가 step 을 보유하므로 이 initState 이후 첫 build 의
    // stepOf 읽기로 수렴한다.
    if (widget.variant == 'chain' && widget.panelId != null) {
      chainShuffleStore.addListener(widget.panelId!, handleChainStep);
    }
    // 플레이그라운드 — 컨트롤 아일랜드가 같은 힙의 스토어에 쓴 속성을 받는다.
    if (_isPlayground) {
      playgroundStore.addListener(widget.panelId!, handleChainStep);
    }
  }

  /// 플레이그라운드의 Flutter 쪽인가 — 속성은 스토어에서 온다.
  bool get _isPlayground => widget.variant == kPlaygroundVariant && widget.panelId != null;

  @override
  void dispose() {
    if (widget.variant == 'chain' && widget.panelId != null) {
      chainShuffleStore.removeListener(widget.panelId!, handleChainStep);
    }
    if (_isPlayground) {
      playgroundStore.removeListener(widget.panelId!, handleChainStep);
    }
    super.dispose();
  }

  /// 스토어 통지 → 다음 프레임 재렌더 (좌표 해석은 build 의 stepOf 읽기).
  void handleChainStep() {
    setState(() {});
  }

  void _observeThemeChanges() {
    _jsEval(
      'new MutationObserver(function(){'
      'var d=document.documentElement.getAttribute("data-theme")==="dark";'
      'window._flutterThemeChanged&&window._flutterThemeChanged(d);'
      '}).observe(document.documentElement,{attributes:true,attributeFilter:["data-theme"]})',
    );
    // Register callback that Flutter can receive.
    _jsEval(
      'window._flutterThemeChanged=function(d){'
      'window._flutterDarkMode=d;'
      '}',
    );
    // Poll for changes (MutationObserver callback can't directly
    // call Dart, so we poll the flag).
    Future.doWhile(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return false;
      final dark = _isDarkMode();
      final style = _selectedSurfaceStyle();
      if (dark != _isDark || style != _surfaceStyle) {
        setState(() {
          _isDark = dark;
          _surfaceStyle = style;
        });
      }
      return mounted;
    });
  }

  /// The preview widget for this component/variant.
  ///
  /// chain 패널(T1)은 셔플 스토어의 현재 step 좌표를 순열 렌더러로 —
  /// 그 외는 registry 빌더 그대로. 렌더러가 없는 chain(T2/T3)은 registry
  /// 빌더가 chain 예제를 정적으로 그린다.
  Widget _preview() {
    if (_isPlayground) {
      final spec = kDocsPlaygrounds[widget.component];
      final props = playgroundStore.propsOf(widget.panelId!) ?? spec?.initial ?? const {};
      final propBuilder = kFlutterPropPreviews[widget.component];
      if (propBuilder != null) {
        return renderFlutterSelection(PreviewSelection.properties(widget.component, props, spec?.label))!;
      }
    }
    final builder = kFlutterPreviewRegistry[widget.component];
    if (builder == null) {
      return const Text('Preview not available');
    }
    final chainRenderer = widget.variant == 'chain' && widget.panelId != null
        ? kFlutterChainRegistry[widget.component]
        : null;

    return chainRenderer != null
        ? chainRenderer(
            chainPermutationAt(chainShuffleStore.stepOf(widget.panelId!)),
          )
        : builder(widget.variant);
  }

  /// The app, behind the gate that keeps it from taking the page's focus.
  ///
  /// An app focuses its first route as it starts, and its view answers that
  /// by taking the page's DOM focus — on load, and again for every variant
  /// the reader picks. The app's shortcuts then keep the arrow keys and Tab
  /// from the page. [PreviewFocusGate] lets the app hold focus only while
  /// the reader is in its view.
  @override
  Widget build(BuildContext context) => PreviewFocusGate(child: _app());

  Widget _app() {
    final coreTheme = _isDark ? CoreThemePresets.previewDark : CoreThemePresets.previewLight;

    final couiThemeData = coui.ThemeData.fromCore(
      coreTheme.copyWith(
        sizeScaling: 1.0,
        textScaling: 1.0,
        radiusScaling: 1.0,
      ),
    );

    return coui.CoUIApp(
      // The page's own title, read back — see [_documentTitle].
      title: _documentTitle(),
      theme: couiThemeData,
      surfaceStyle: _surfaceStyle,
      // `CoUIApp.background` defaults to transparent (right for an app
      // embedded inside another Flutter app that already paints a
      // backdrop), but this embed IS the whole page for its iframe — with
      // nothing set, a fully-transparent widget (e.g. the chain preview's
      // `.transparent` permutation) falls through to the raw canvas, and
      // CanvasKit's clear colour there is black, not the surrounding
      // page. `.preview-pane` paints the current CoUI surface behind both
      // panes (site_head.dart), so match it explicitly instead of trusting
      // canvas transparency to reveal it — without this, a transparent
      // Command panel rendered white on the Web pane and black on the
      // Flutter pane.
      // The playground stage is the card surface (`--site-card`), not the
      // gray tile: a variant filled with the container colour (secondary)
      // would vanish into a tile of the same colour. The Flutter pane paints
      // the same surface so the two panes read as one stage.
      background: couiThemeData.colorScheme.resolve(couiThemeData.colorScheme.surface).toValue(),
      // Stated rather than left to `CoUIApp`'s default: the docs preview
      // must render at the same scale as the un-scaled Web preview whatever
      // platform the browser reports.
      scaling: const coui.AdaptiveScaling(),
      // Pinned for the same reason: this view is a preview pane, not the
      // screen, so its width is the pane's — the viewport tier would step
      // the headings down for a narrow pane while the page around it reads
      // desktop. The Web preview pins the same tier.
      typographyTier: CoreBreakpointTier.desktop,
      // The site's language, stated with the Web pane's — without it the
      // components' own text (weekdays, previous / next, empty states)
      // resolves to English in this pane only. `supportedLocales` has to
      // name it too: a locale outside that list falls back to its first
      // entry, which defaults to en-US.
      locale: const Locale(kDocsLanguageCode),
      supportedLocales: const [Locale(kDocsLanguageCode)],
      debugShowCheckedModeBanner: false,
      // jaspr embed has no platform channel for browser context menu —
      // skip the call to avoid an init-time throw inside CoUIApp.
      disableBrowserContextMenu: false,
      // Theme lerp interpolates ColorScheme tokens through nullable
      // intermediate frames; disable so docs preview survives the
      // light↔dark switch without hitting null-assertion throws on
      // ColorScheme.onSurface / primary / etc.
      enableThemeAnimation: false,
      home: Stack(
        children: [
          // The liquidGlass demo backdrop (`docs_core`'s single-source
          // `glass_preview_backdrop.dart`, same values `site_head.dart`
          // emits as CSS for the Web pane's `.preview-pane`). Painted as an
          // opaque layer, not a transparent one — see
          // `GlassPreviewBackdropLayer`'s doc comment for why this pane
          // never relies on the canvas itself being see-through.
          //
          // Fills the whole view (`CoUIApp.home`'s own size, which — like
          // any Flutter app's root — is whatever the surrounding view
          // gives it, here `ViewConstraints.maxHeight`) rather than
          // shrink-wrapping the card. A shrink-wrapped version was tried:
          // nesting this `Stack` inside the `Padding` below instead of
          // around it. `Stack` sizes to its non-positioned children under
          // loose constraints, so that version *did* hug the card — and
          // left the rest of this still-much-taller-than-the-card view
          // (the docs pane reserves headroom via `ViewConstraints` that
          // the card itself doesn't need) as a plain rectangle next to a
          // small patterned one, which reads as more broken than a
          // uniformly patterned pane whose washes land a bit differently
          // than Web's for a shorter box. `GlassBand._bandPaint` already
          // corrects for the aspect-ratio mismatch this leaves (the band's
          // angle is exact regardless of how tall the box is); the washes
          // settle for being positioned as percentages of a taller box,
          // which is the "coarse on purpose" tolerance
          // `glass_preview_backdrop.dart` documents.
          if (_surfaceStyle == CoreSurfaceStyleId.liquidGlass)
            Positioned.fill(
              child: GlassPreviewBackdropLayer(
                recipe: _isDark ? kGlassPreviewBackdropDark : kGlassPreviewBackdropLight,
              ),
            ),
          Align(
            // The playground stage centres its Web pane; its Flutter pane
            // has to put the component in the same place.
            alignment: _isPlayground ? Alignment.center : Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: kDocsPreviewContentInset,
              ),
              child: _preview(),
            ),
          ),
        ],
      ),
    );
  }
}
