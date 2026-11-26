import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/infra/liquid_morph/liquid_morph_clip.dart';
import 'package:coui_web/src/components/layout/dock/dock_flight_dom.dart';
import 'package:coui_web/src/components/layout/dock/dock_style.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/overlay/coui_web_dom.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified bottom dock navigation for CoUI Web.
///
/// Mirrors Flutter `Dock` — takes a data-only [items] list
/// ([CoreDockItemData] of [Component]) and renders each one. Uses CoUI
/// design tokens / Tailwind instead of DaisyUI `dock-*` classes.
///
/// Per Epic #1603 (옵션 B 최종) every chrome / dimensional / nested-slot
/// override flows through the single [dockStyle] (a [CoreDockStyle]).
/// The semantic [size] preset and [semanticLabel] stay flat on the
/// component.
///
/// ```text
/// design system default
///   → CoreDockTheme.style                  // 프로젝트 공통
///   → component.dockStyle                  // 인스턴스별
/// ```
///
/// Example:
/// ```dart
/// Dock(
///   size: CoreDockSize.md,
///   items: [
///     CoreDockItemData(icon: Icon(LucideIcons.house), label: 'Home'),
///     CoreDockItemData(
///       icon: Icon(LucideIcons.settings),
///       label: 'Settings',
///       isActive: true,
///     ),
///   ],
/// )
/// ```
///
/// surface:behind — the shell stacks this bar over a body that scrolls
/// beneath it.
///
/// surface:functional — the shell stacks this bar over a body that scrolls
/// beneath it.
///
/// ## The active pill, and how it travels
///
/// The active item sits in a pill. When a different item becomes active
/// the departing pill and the arriving one are handed to the morph engine
/// as two bodies, and for the length of a spring a fill over the whole bar
/// is carved into one silhouette — the same `LiquidMorphClip` a popover
/// leaves its trigger through, on the same Core outline the Flutter twin
/// carves. The pill reads as one thing stretching across.
///
/// The flight is measured on the client at the moment the active index
/// changes — three `getBoundingClientRect`s — and never on the server,
/// which renders the settled pill under the active item and nothing in
/// flight. Under reduced motion there is no flight either.
///
/// ## The bar's height
///
/// `CoreDockStyle.height` is the bar's minimum height, not its height: the bar
/// is `min-height` over a flex row. While the item row — and the room kept
/// above and below it for the active pill — fits, the bar is exactly that
/// tall, with the items centred in it; when the row needs more (a larger label
/// style, a taller icon) the bar is as tall as the row asks, so it grows
/// instead of clipping the content a user asked to see larger.
class Dock extends UiStatefulComponent implements CoreDockContract<Component> {
  /// Creates a [Dock].
  const Dock({
    required this.items,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
    this.size,
    this.semanticLabel,
    this.dockStyle,
  });

  @override
  final List<CoreDockItemData<Component>> items;

  @override
  final CoreDockSize? size;

  @override
  final String? semanticLabel;

  @override
  final CoreDockStyle? dockStyle;

  @override
  State<Dock> createState() => _DockState();

  /// Returns a copy of this [Dock] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Dock copyWith({
    List<CoreDockItemData<Component>>? items,
    CoreDockSize? size,
    String? semanticLabel,
    CoreDockStyle? dockStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return Dock(
      key: key ?? this.key,
      items: items ?? this.items,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      size: size ?? this.size,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      dockStyle: dockStyle ?? this.dockStyle,
    );
  }
}

/// Instance counter for the ids the flight is measured by.
///
/// A dock only needs ids because the measurement finds elements by them.
/// Minted here rather than required of the caller, so a dock that never
/// changes its active item keeps the markup it had.
int _dockIdSeed = 0;

/// The two pills of one flight and the tempo it runs at.
class _DockFlight {
  const _DockFlight({
    required this.anchor,
    required this.panel,
    required this.spring,
  });

  final CoreMorphBlob anchor;
  final CoreMorphBlob panel;
  final CoreMorphSpring spring;
}

class _DockState extends State<Dock> {
  late final String _scope = 'coui-dock-${(_dockIdSeed++).toRadixString(36)}';
  _DockFlight? _flight;
  Timer? _settle;

  /// The element the flight is measured against and positioned in — the
  /// caller's id when it gave one, so the two cannot name different boxes.
  String get _trackId => component.id ?? _scope;
  String get _flightId => '$_scope-flight';
  String _itemId(int index) => '$_scope-i$index';

  static int? _activeIndexOf(List<CoreDockItemData<Component>> items) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].isActive) return i;
    }

    return null;
  }

  @override
  void didUpdateComponent(Dock oldComponent) {
    super.didUpdateComponent(oldComponent);
    final from = _activeIndexOf(oldComponent.items);
    final to = _activeIndexOf(component.items);
    if (from == null || to == null || from == to) return;
    if (oldComponent.items.length != component.items.length) return;
    // Client only — the measurement needs a document — and not under
    // reduced motion: a morph is transition-tier motion, and this kit
    // suppresses that tier to zero rather than speeding it up. The Web
    // clip has no reduced-motion check of its own, so this is the gate.
    if (!kIsWeb || prefersReducedMotion) return;

    _launch(from, to);
  }

  void _launch(int from, int to) {
    final runtime = resolveDockIndicatorRuntime(
      context,
      resolved: resolveDock(
        context,
        size: component.size,
        dockStyle: component.dockStyle,
      ),
      size: component.size,
    );
    // The overhang as the page draws it — the settled pill reads each
    // side through a spacing variable a density re-maps, so the flight
    // takes the measured value rather than the authored one.
    final measured = measureDockFlight(
      trackId: _trackId,
      fromId: _itemId(from),
      toId: _itemId(to),
      padding: runtime.padding,
    );
    if (measured == null) return;

    final pad = measured.pad;

    CoreMorphBlob pill(DockFlightBox box) {
      final width = box.width + pad.left + pad.right;
      final height = box.height + pad.top + pad.bottom;

      return CoreMorphBlob(
        centerX: box.left - pad.left + (width / 2),
        centerY: box.top - pad.top + (height / 2),
        halfWidth: width / 2,
        halfHeight: height / 2,
        radius: runtime.radius,
      );
    }

    final spring = runtime.spring;
    _settle?.cancel();
    _settle = Timer(
      Duration(
        microseconds: (spring.settleSeconds() * Duration.microsecondsPerSecond)
            .round(),
      ),
      () {
        if (!_isMounted) return;
        setState(() => _flight = null);
      },
    );
    setState(() {
      _flight = _DockFlight(
        anchor: pill(measured.from),
        panel: pill(measured.to),
        spring: spring,
      );
    });
  }

  bool _isMounted = true;

  @override
  void dispose() {
    _isMounted = false;
    _settle?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis (`WebResolvedChrome`
    // contract). The component reads the paint-ready strings directly
    // without invoking the top-level builder helpers.
    final resolved = resolveDock(
      context,
      size: component.size,
      dockStyle: component.dockStyle,
    );
    // Effective dock size — behavioural identifier (gates per-item label
    // slot + picks per-size defaults). Resolved off the same chain as the
    // chrome resolver but kept off `ResolvedDock` (pure chrome) per the
    // number_ticker separate-resolver pattern.
    final effectiveSize = resolveDockSize(context, size: component.size);
    final flight = _flight;

    return div(
      [
        // The flight: a fill over the whole track, carved by the morph
        // clip into the silhouette the two pills make right now. Wrapped,
        // not nested — the clip renders its child unchanged and writes
        // `clip-path` onto the element carrying `_flightId`.
        if (flight != null)
          LiquidMorphClip(
            elementId: _flightId,
            anchor: flight.anchor,
            panel: flight.panel,
            spring: flight.spring,
            child: div(
              const [],
              id: _flightId,
              classes: resolved.flight.className,
              styles: resolved.flight.inlineStyles,
              attributes: const {'aria-hidden': 'true'},
            ),
          ),
        for (final (index, item) in component.items.indexed)
          _buildItem(
            context,
            resolved,
            effectiveSize,
            item,
            id: _itemId(index),
            // While the pill is in flight it is the flight; the settled
            // pill would sit under the destination a spring early.
            showIndicator: item.isActive && flight == null,
          ),
      ],
      id: _trackId,
      classes: component.rootClasses(resolved.root.className),
      styles: component.css != null
          ? Styles.combine([?resolved.root.inlineStyles, component.css!])
          : resolved.root.inlineStyles,
      // Landmark name, falling back to the locale like the Flutter twin.
      // A page with several landmarks and no names reads as "navigation,
      // navigation, contentinfo" — the list tells a user nothing about
      // which is which. Fallback first, so an explicit `semanticLabel`
      // and any caller `attributes` still override it.
      attributes: {
        'role': CoreSemanticRole.navigation.ariaRole,
        'aria-label':
            component.semanticLabel ?? CouiLocalizations.of(context).dockLabel,
        ...component.componentAttributes,
      },
      events: component.events,
    );
  }

  Component _buildItem(
    BuildContext context,
    ResolvedDock resolved,
    CoreDockSize size,
    CoreDockItemData<Component> item, {
    required String id,
    required bool showIndicator,
  }) {
    final itemChrome = resolveDockItem(
      context,
      resolved: resolved,
      size: size,
      isActive: item.isActive,
      hasLabel: item.label != null,
      showIndicator: showIndicator,
      tappable: item.onPressed != null,
    );

    final children = <Component>[
      // The icon row — the box the plate is laid against and the box the
      // flight measures, so it carries the id.
      div(
        [
          // The settled plate, under the icon: a positioned child that
          // overhangs the icon row by the indicator padding, so the row's
          // own layout is exactly what it is without one.
          if (itemChrome.indicator != null)
            div(
              const [],
              classes: itemChrome.indicator!.className,
              styles: itemChrome.indicator!.inlineStyles,
              attributes: const {'aria-hidden': 'true'},
            ),
          // Nearest `IconTheme` so the dock icon size outranks the
          // app-root ambient `IconTheme` — the holder's CSS
          // `font-size` only reaches an `Icon` through CSS
          // inheritance, which the Dart-channel ambient silently
          // outranks (mirrors the Flutter twin's per-item
          // `IconTheme.merge`).
          IconTheme(
            data: IconThemeData(size: itemChrome.iconStyle.size),
            child: item.icon,
          ),
        ],
        id: id,
        classes: itemChrome.icon.className,
        styles: itemChrome.icon.inlineStyles,
      ),
      if (itemChrome.label != null) ...[
        Gap(gapStyle: itemChrome.itemIconLabelGapStyle),
        div(
          [Text(item.label!)],
          classes: itemChrome.label!.className,
          styles: itemChrome.label!.inlineStyles,
        ),
      ],
    ];

    final itemBody = div(
      children,
      classes: itemChrome.root.className,
      styles: itemChrome.root.inlineStyles,
    );

    // Non-interactive item (`onPressed == null`) — plain container, no
    // role="button" / tabindex pollution (chip conditional-wrap
    // precedent).
    if (item.onPressed == null) {
      return itemBody;
    }

    // Web twin of the Flutter dock item: the composed Clickable owns
    // tap / keyboard activation / cursor / press feedback / focus
    // ring. The active item advertises itself as the current page. The
    // Clickable is the bar's flex item, so the room kept for the pill rides
    // on its root (`css`) — margins, which the focus ring around its border
    // box leaves out.
    return Clickable(
      onPressed: item.onPressed,
      attributes: item.isActive ? const {'aria-current': 'page'} : null,
      css: itemChrome.clickable?.inlineStyles,
      clickableStyle: resolved.clickableStyle,
      child: itemBody,
    );
  }
}

/// Chain sugar mirroring the Flutter `Dock.withStyle` extension —
/// merges a [CoreDockStyle] patch into [Dock.dockStyle] via the
/// existing [Dock.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreDockStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.primary`
/// sets [CoreDockStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Dock(items: items).surface
/// ```
extension DockStyleChain on Dock {
  /// Returns a copy of this [Dock] with [patch] merged into [dockStyle]
  /// (patch fields win on conflict).
  Dock withStyle(CoreDockStyle patch) =>
      copyWith(dockStyle: (dockStyle ?? const CoreDockStyle()).merge(patch));

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Dock get primary => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Dock get secondary => withStyle(
    const CoreDockStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Dock get tertiary => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.tertiary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Dock get surface => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Dock get surfaceContainer => withStyle(
    const CoreDockStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Dock get error => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Dock get success => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Dock get warning => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Dock get info => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Dock get outline => withStyle(
    const CoreDockStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Dock get transparent =>
      withStyle(const CoreDockStyle(backgroundColor: .transparent));
}
