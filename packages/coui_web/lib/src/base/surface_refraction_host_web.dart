/// Attaches the active material's refraction to every marked surface.
///
/// ## Why this is one document-level thing and not per component
///
/// The first attempt put the fallback inside `OutlinedContainer`, on the
/// reading that it is the surface primitive. On Flutter that is true — the
/// surfaces compose it. On Web it is not: **two** components compose
/// `OutlinedContainer` (`card_image`, `window`), and the other eight draw
/// their own box and add `kWebSurfaceMarker` to it. So the fallback
/// reached almost nothing, and the browser said so — the card's surface
/// element had no id at all, meaning it never entered the refraction path.
///
/// The marker is already how the stylesheet finds these surfaces: the
/// preset's translucency, blur, chroma and edge band are all one rule
/// scoped to `.coui-surface`. Refraction is the same statement about the
/// same set, so it is aimed the same way. Wiring it per component instead
/// would be eight places to remember, and the ninth surface someone adds
/// would be glass without a rim, silently.
///
/// ## What it does not do
///
/// It does not decide *whether* a surface bends — the recipe does, and a
/// style stating no refraction detaches everything. It does not measure
/// anything either: each element keeps its own [SurfaceRefractionRuntime],
/// which reads that element's rectangle and rebuilds on resize exactly as
/// it did when a caller passed the request by hand.
library;

import 'dart:js_interop';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/adaptive_quality_scope.dart';
import 'package:coui_web/src/base/surface_runtime_inputs.dart';
import 'package:coui_web/src/base/surface_style_scope.dart';
import 'package:coui_web/src/components/infra/outlined_container/refraction_map.dart';
import 'package:coui_web/src/overlay/coui_web_dom.dart'
    show
        markSvgBackdropSupport,
        prefersDarkColorScheme,
        prefersPlainSurfaces,
        registerDarkColorSchemeListener,
        registerPlainSurfacesListener;
import 'package:coui_web/src/util/web_constants.dart';
import 'package:web/web.dart' as web;

/// The document attribute that carries the palette.
///
/// A scope sets it on its own element too, so the palette of a surface is
/// the one on its nearest ancestor that carries it.
const String _kThemeAttribute = 'data-theme';

/// Instance counter for surfaces this host had to name.
///
/// A surface only needs an id because the runtime finds its element by
/// one. Minted here rather than required of the component, so a component
/// that never asked for refraction keeps the markup it had.
int _hostIdSeed = 0;

/// Drives refraction for every marked surface in the document.
class SurfaceRefractionHost {
  SurfaceRefractionHost._();

  static SurfaceRefractionHost? _installed;

  final Map<web.Element, _Attachment> _runtimes = {};
  web.MutationObserver? _observer;
  void Function()? _disposeColorScheme;
  void Function()? _disposePlainSurfaces;
  bool _syncQueued = false;

  /// Installs the host, once per document.
  ///
  /// Idempotent: a second app root in the same page adopts the first
  /// host rather than starting a second one, which would attach two
  /// filters to every surface and composite the bend twice.
  ///
  /// Also says which browser this is to the stylesheet: the frost and the
  /// body shade are SVG filters in a surface's `backdrop-filter` list, a
  /// browser that does not draw them draws nothing for the list, and the
  /// sheet's rule for them is keyed on the attribute this writes (WebKit does
  /// not wait for it: the sheet answers that engine from the first paint). The
  /// host is the one document-level runtime every app root installs, so the
  /// answer is given once per page and from the same fact the refraction reads.
  static void install() {
    if (_installed != null) return;

    markSvgBackdropSupport();
    final host = SurfaceRefractionHost._().._sync();
    _installed = host;
    // Material changes, mounting/unmounting and framework identity/style
    // changes bring work. Animated styles on untracked elements are ignored.
    //
    // The third is not hypothetical — it is what this host was failing on.
    // The framework owns every attribute on these elements, so an id it
    // does not carry in its own model is removed on the next render, and
    // the runtime that finds its element by that id goes silently dead.
    // Watching `id` turns that into a re-attach instead.
    //
    // Re-setting the id from inside the callback cannot loop: the sync
    // returns early when the id it finds is the one it attached under.
    host._observer =
        web.MutationObserver(
          (JSArray<web.MutationRecord> records, web.MutationObserver observer) {
            // Only marked surfaces' style changes matter. Moving an unmarked
            // lens every frame must not rescan the document at frame rate.
            if (records.toDart.any(
              (record) =>
                  record.attributeName != 'style' ||
                  host._runtimes.containsKey(record.target),
            )) {
              host._queueSync();
            }
          }.toJS,
        )..observe(
          web.document.documentElement!,
          web.MutationObserverInit(
            attributes: true,
            attributeFilter: [
              kSurfaceStyleAttribute.toJS,
              // The palette. A theme switch writes this attribute and
              // rebuilds nothing, and the runtime appended its filter to
              // the list the stylesheet computed *for the palette it
              // attached under* — written inline, where it outranks the
              // other palette's rules. Without watching the mode, a switch
              // leaves the dimming and the chroma lift of the old one on
              // every refracted surface.
              _kThemeAttribute.toJS,
              // The adaptive-quality tier. A governor's step writes this
              // attribute and rebuilds nothing, and the bend is something
              // this host adds to a surface — so the host is what has to
              // take it away, and give it back.
              kQualityAttribute.toJS,
              'id'.toJS,
              'class'.toJS,
              'style'.toJS,
            ].toJS,
            childList: true,
            subtree: true,
          ),
        );
    // The other way a mode changes: the OS preference, for a page that
    // carries no palette attribute of its own.
    host._disposeColorScheme = registerDarkColorSchemeListener(
      ({required isDark}) => host._queueSync(),
    );
    // And the two preferences that take the stylesheet's frost and shade
    // away. The runtime copies the computed filter list onto the surface, so
    // a list computed before the preference flipped would keep the terms the
    // media query just removed — inline outranks the stylesheet.
    host._disposePlainSurfaces = registerPlainSurfacesListener(
      host._queueSync,
    );
  }

  /// Detaches everything and forgets the installation. For tests.
  static void uninstall() {
    final host = _installed;
    if (host == null) return;

    host._observer?.disconnect();
    host._disposeColorScheme?.call();
    host._disposePlainSurfaces?.call();
    for (final attachment in host._runtimes.values) {
      attachment.runtime.dispose();
    }
    host._runtimes.clear();
    _installed = null;
  }

  /// Coalesces a burst of mutations into one pass.
  ///
  /// A render commits many nodes, and syncing per record would walk the
  /// whole surface set once per node. One frame's worth is one walk.
  void _queueSync() {
    if (_syncQueued) return;

    _syncQueued = true;
    final _ = web.window.requestAnimationFrame(
      (JSNumber _) {
        _syncQueued = false;
        _sync();
      }.toJS,
    );
  }

  void _sync() {
    // Read live rather than cached: the style is a document attribute and
    // switching it rebuilds nothing, so a value read once goes stale on
    // the next switch — which is the same reason the material itself is
    // emitted as a CSS rule instead of resolved in Dart.
    final globalStyle = SurfaceStyleScope.currentSurfaceStyle();
    // Read live for the same reason, and answered by the same ladder the
    // other seats ask: a tier that goes without the bend is a tier the
    // ladder says withholds it.
    final bendWithheld = CoreQualityLadder.standard.withholds(
      AdaptiveQualityScope.currentTier(),
      CoreQualityEffect.refraction,
    );

    // Every marked surface, whatever its role. Which role a node is comes
    // off its own class below; what that role gets comes off the recipe.
    final marked = web.document.querySelectorAll(
      '.$kWebSurfaceMarker, .$kWebLocalSurfaceMarker',
    );
    final present = <web.Element>{};
    // Whether the filter lists this pass reads were computed under a
    // preference that takes the frost and the shade away. Per pass, not per
    // surface: it is the document's, and every surface reads the same.
    final plain = prefersPlainSurfaces;
    // Read at most once per pass, and only by a surface that carries no
    // palette attribute above it.
    CoreBrightness? system;
    CoreBrightness modeOf(web.Element node) {
      switch (node
          .closest('[$_kThemeAttribute]')
          ?.getAttribute(_kThemeAttribute)) {
        case 'dark':
          return CoreBrightness.dark;
        case 'light':
          return CoreBrightness.light;
      }

      return system ??= prefersDarkColorScheme
          ? CoreBrightness.dark
          : CoreBrightness.light;
    }

    for (var i = 0; i < marked.length; i++) {
      final Object? node = marked.item(i);
      if (node is! web.Element) continue;

      present.add(node);
      final localStyles = CoreSurfaceStyleId.values.where(
        (id) => node.classList.contains('coui-material-${id.name}'),
      );
      final style = localStyles.firstOrNull ?? globalStyle;
      final mode = modeOf(node);
      final recipe = CoreSurfaceRecipe.of(style);
      final refraction = recipe.refraction;
      bool rimOn(CoreSurfaceRole role) =>
          recipe.surfaceFor(role)?.sheen?.bevel?.drawsRim ?? false;

      // Re-asserted every pass rather than trusted once.
      //
      // The id is not ours to keep: it is a DOM attribute on an element
      // the framework re-renders, and a render that does not carry it in
      // its own model strips it. Measured — the filters were all built,
      // all five surfaces then had no id, and every filter pointed at an
      // element `getElementById` could no longer find. A `containsKey`
      // check alone skipped those elements forever, because they were the
      // same nodes the host had already seen.
      final tracked = _runtimes[node];
      if (tracked != null) {
        final inline = (node as web.HTMLElement).style;
        final filter = inline.getPropertyValue('backdrop-filter');
        final keepsBend =
            !tracked.hasBend || filter.contains(refractionFilterId(tracked.id));
        final keepsRim =
            !tracked.hasRim ||
            inline.getPropertyValue(kWebSurfaceRimSweepVar).isNotEmpty;
        if (node.id == tracked.id &&
            tracked.style == style &&
            tracked.mode == mode &&
            tracked.bendWithheld == bendWithheld &&
            tracked.plain == plain &&
            keepsBend &&
            keepsRim)
          continue;

        // Framework style updates can remove our filter without changing the
        // id or material. Rebind against the newly authored base, preserving
        // a caller's changed blur and allowing a new CSS material to resolve.
        tracked.runtime.dispose();
        if (filter.isEmpty || filter.contains(refractionFilterId(tracked.id))) {
          if (inline.getPropertyValue('backdrop-filter').isNotEmpty) {
            inline.removeProperty('backdrop-filter');
          }
        } else if (inline.getPropertyValue('backdrop-filter') != filter) {
          inline.setProperty('backdrop-filter', filter);
        }
        _runtimes.remove(node);
      }

      final role = node.classList.contains(kWebSurfaceRoleFunctional)
          ? CoreSurfaceRole.functional
          : CoreSurfaceRole.content;
      // What the stylesheet states about this surface that the preset does
      // not — an app's tuned light and law. Empty for an untuned sheet.
      final computed = web.window.getComputedStyle(node);
      // Not a tear-off of `getPropertyValue`: dart2js refuses to tear off an
      // external member of an interop type.
      String property(String name) => computed.getPropertyValue(name);
      final inputs = SurfaceRuntimeInputs.read(property);
      final rims = rimOn(role)
          ? inputs.rimsFor(recipe.surfaceFor(role)!.sheen!.bevel!)
          : null;
      final rim = rims?.light;

      // The bend goes only where there is a backdrop pass to bend. A
      // nested surface dropped its pass (the stylesheet says `none`), and
      // Flutter mounts no shader there either — a filter appended to
      // `none` is an invalid list the browser throws away, so this is
      // parity rather than economy.
      //
      // Nor where the browser cannot draw the filter. The runtime writes
      // nothing there, and a host that had counted on a bend would find its
      // filter missing on every pass and rebuild the attachment each time.
      //
      // A surface whose caller already stated a refraction has its own
      // runtime; a second one here would append a second filter and bend
      // the backdrop twice. It still gets the rim from here — the rim is
      // the theme's, not the caller's.
      //
      // "Carries a refraction" is asked of the refraction's own id, not of any
      // `url()`: the stylesheet puts filters of its own in the same list (the
      // frost, the body shade), and a surface with one of those would
      // otherwise read as already bent and never be bent.
      final existing = computed.getPropertyValue('backdrop-filter');
      final hasPass = existing.isNotEmpty && existing != 'none';
      // And not where the adaptive-quality tier goes without it: the bend is
      // the one effect this host adds on top of the stylesheet's material, so
      // it is the one a lower tier has to be told to leave out. The rim stays
      // — it is the edge band, which every tier keeps.
      final bend =
          !bendWithheld &&
              refraction != null &&
              hasPass &&
              !existing.contains('#$kRefractionFilterIdPrefix') &&
              webSurfaceRefractionSupported
          ? inputs.refractionFor(refraction)
          : null;
      if (bend == null && rim == null) continue;

      final id = node.id.isEmpty
          ? 'coui-refracted-${(_hostIdSeed++).toRadixString(36)}'
          : node.id;
      if (node.id != id) node.id = id;
      _runtimes[node] = _Attachment(
        id,
        style,
        mode,
        SurfaceRefractionRuntime(elementId: id)
          ..attach(bend, rim: rim, rimInDarkMode: rims?.dark),
        hasBend: bend != null,
        hasRim: rim != null,
        bendWithheld: bendWithheld,
        plain: plain,
      );
    }

    // Surfaces that left the document take their runtime with them —
    // otherwise the SVG filter host it appended outlives the element it
    // was built for, once per mount, for the life of the page.
    _runtimes.removeWhere((element, attachment) {
      if (present.contains(element)) return false;

      attachment.runtime.dispose();

      return true;
    });
  }
}

/// One surface's runtime and the id it was attached under.
///
/// The id is kept beside the runtime because it is the only way to tell
/// that the attachment has gone stale: the runtime finds its element by
/// id, so an element whose id the framework stripped has a runtime that
/// can no longer reach it.
class _Attachment {
  const _Attachment(
    this.id,
    this.style,
    this.mode,
    this.runtime, {
    required this.hasBend,
    required this.hasRim,
    required this.bendWithheld,
    required this.plain,
  });

  /// Whether the filter list the runtime appended to was computed under a
  /// preference that takes the frost and the shade away (more contrast, or a
  /// forced palette). It is as stale as the palette is when that flips.
  final bool plain;

  final bool hasBend;
  final bool hasRim;

  /// Whether the quality tier the surface was attached under went without
  /// the bend. Kept so that a step either way makes the attachment stale:
  /// one made while the bend was withheld cannot be the one that gives it
  /// back, and one that carries it cannot be the one that withholds it.
  final bool bendWithheld;

  final CoreSurfaceStyleId style;

  /// The palette the filter was appended under. The base list the runtime
  /// appends to is the one the stylesheet computed for it, so an attachment
  /// made under the other palette is stale the moment the palette changes.
  final CoreBrightness mode;

  final String id;
  final SurfaceRefractionRuntime runtime;
}
