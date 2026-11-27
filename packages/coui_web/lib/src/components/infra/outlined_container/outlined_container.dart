import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container_style.dart';
import 'package:coui_web/src/components/infra/outlined_container/refraction_map.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Unified cross-platform outlined-container chrome primitive (Web).
///
/// Mirrors `OutlinedContainer` (Flutter) — wraps a single `child` in
/// a `<div>` chrome (border + radius + optional padding + shadow +
/// blur). Defaults read from `CoreOutlinedContainerTheme` via
/// `context.theme.coreComponentTheme.outlinedContainer`.
///
/// All chrome / dimensional overrides flow through the single
/// [containerStyle] (a [CoreOutlinedContainerStyle]) so the
/// nested-merge chain (`theme.outlinedContainer.style` ←
/// `widget.containerStyle`) works uniformly per Epic #1302.
///
/// surface:behind — the box every in-flow panel composes. What shows through it is the
/// page it is laid on, not a parent panel.
///
/// surface:content — the default for a box with no evidence that it
/// floats. A caller that has that evidence says so through [role].
class OutlinedContainer extends UiComponent
    implements CoreOutlinedContainerContract<Component> {
  /// Creates a [OutlinedContainer].
  const OutlinedContainer({
    this.child,
    this.containerStyle,
    this.refraction,
    this.role = .defaultRole,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component? child;

  @override
  final CoreOutlinedContainerStyle? containerStyle;

  @override
  final CoreSurfaceRefraction? refraction;

  @override
  final CoreSurfaceRole role;

  @override
  Component build(BuildContext context) {
    final resolved = resolveOutlinedContainer(
      context: context,
      containerStyle: containerStyle,
      role: role,
    );

    // Only the opt-in path gains an id and a lifecycle. A surface that
    // asked for nothing keeps the markup and the component type it had —
    // promoting the whole class to stateful would put a hydration boundary
    // under every card in the kit to serve the few that requested bending.
    final refraction = this.refraction;
    final surfaceId = id ?? (refraction == null ? null : _nextSurfaceId());

    final element = Component.element(
      tag: tag,
      id: surfaceId,
      classes: [
        resolved.root.className,
        ?classes,
      ].join(' ').trim(),
      styles: Styles.combine([
        ?resolved.root.inlineStyles,
        ?css,
      ]),
      attributes: componentAttributes,
      events: events,
      children: [
        // Dashed/dotted border — an SVG overlay stroking with
        // `currentColor` (colour class rides the `<svg>` itself so the
        // arbitrary child keeps its own inherited colour),
        // pattern-deterministic across browsers and tunable via the
        // `dashLength`/`dashSpacing` slots.
        if (resolved.dashOverlay != null && resolved.dashRect != null)
          Component.element(
            tag: 'svg',
            classes: resolved.dashOverlay!.className,
            styles: resolved.dashOverlay!.inlineStyles,
            attributes: const {'aria-hidden': 'true'},
            children: [
              Component.element(
                tag: 'rect',
                styles: resolved.dashRect!.inlineStyles,
                children: const [],
              ),
            ],
          ),
        ?child,
      ],
    );

    if (refraction == null) return element;

    return _RefractingSurface(
      elementId: surfaceId!,
      refraction: refraction,
      child: element,
    );
  }

  @override
  OutlinedContainer copyWith({
    Component? child,
    CoreOutlinedContainerStyle? containerStyle,
    CoreSurfaceRefraction? refraction,
    CoreSurfaceRole? role,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return OutlinedContainer(
      key: key ?? this.key,
      containerStyle: containerStyle ?? this.containerStyle,
      refraction: refraction ?? this.refraction,
      role: role ?? this.role,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      child: child ?? this.child,
    );
  }
}

/// Chain sugar mirroring the Flutter `OutlinedContainer.withStyle`
/// extension — merges a [CoreOutlinedContainerStyle] patch into
/// [OutlinedContainer.containerStyle] via the existing
/// [OutlinedContainer.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreOutlinedContainerStyle.merge` right-side-wins semantics).
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
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreOutlinedContainerStyle.borderRadius] and `.primary` sets
/// [CoreOutlinedContainerStyle.backgroundColor]. A semantic layer that
/// names these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// OutlinedContainer(child: text('Card body')).radius4.primary
/// ```
extension OutlinedContainerStyleChain on OutlinedContainer {
  /// Sets the content padding.
  OutlinedContainer contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreOutlinedContainerStyle(padding: value));

  /// Sets the border color.
  OutlinedContainer borderColor(CoreColor value) =>
      withStyle(CoreOutlinedContainerStyle(borderColor: value));

  /// Sets the border width in logical pixels.
  OutlinedContainer borderWidth(double value) =>
      withStyle(CoreOutlinedContainerStyle(borderWidth: value));

  /// Sets the background paint and preserves the other style fields.
  OutlinedContainer backgroundColor(CoreColor value) =>
      withStyle(CoreOutlinedContainerStyle(backgroundColor: value));

  /// Returns a copy of this [OutlinedContainer] with [patch] merged into
  /// [containerStyle] (patch fields win on conflict).
  OutlinedContainer withStyle(CoreOutlinedContainerStyle patch) => copyWith(
    containerStyle: (containerStyle ?? const CoreOutlinedContainerStyle())
        .merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  OutlinedContainer get radius0 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  OutlinedContainer get radius2 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  OutlinedContainer get radius4 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  OutlinedContainer get radius6 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  OutlinedContainer get radius8 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  OutlinedContainer get radius10 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  OutlinedContainer get radius12 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  OutlinedContainer get radius14 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  OutlinedContainer get radius16 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  OutlinedContainer get radius20 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  OutlinedContainer get radius24 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  OutlinedContainer get radius28 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  OutlinedContainer get radius32 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  OutlinedContainer get radius36 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  OutlinedContainer get radius40 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  OutlinedContainer get radius48 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  OutlinedContainer get radius56 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  OutlinedContainer get radius64 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  OutlinedContainer get radius9999 => withStyle(
    const CoreOutlinedContainerStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  OutlinedContainer get primary => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  OutlinedContainer get secondary => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  OutlinedContainer get tertiary => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  OutlinedContainer get surface => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  OutlinedContainer get surfaceContainer => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  OutlinedContainer get error => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  OutlinedContainer get success => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  OutlinedContainer get warning => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  OutlinedContainer get info => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.info),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  OutlinedContainer get outline => withStyle(
    const CoreOutlinedContainerStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  OutlinedContainer get transparent => withStyle(
    const CoreOutlinedContainerStyle(backgroundColor: .transparent),
  );
}

/// Instance counter for surfaces that asked for bending.
///
/// The runtime finds its surface by id, so one is minted here when the
/// caller supplied none. Only the opt-in path pays for it.
int _surfaceIdSeed = 0;

String _nextSurfaceId() =>
    'coui-surface-${(_surfaceIdSeed++).toRadixString(36)}';

/// Owns the refraction runtime for one surface.
///
/// Separate from [OutlinedContainer] so a surface that asked for nothing
/// stays stateless. It renders its child unchanged and adds no element of
/// its own — the only thing it contributes is a lifecycle to hang the
/// attach and the teardown on.
class _RefractingSurface extends StatefulComponent {
  const _RefractingSurface({
    required this.elementId,
    required this.refraction,
    required this.child,
  });

  final String elementId;
  final CoreSurfaceRefraction refraction;
  final Component child;

  @override
  State<_RefractingSurface> createState() => _RefractingSurfaceState();
}

class _RefractingSurfaceState extends State<_RefractingSurface> {
  SurfaceRefractionRuntime? _runtime;

  @override
  void initState() {
    super.initState();
    _attach();
  }

  @override
  void didUpdateComponent(_RefractingSurface oldComponent) {
    super.didUpdateComponent(oldComponent);
    if (oldComponent.refraction == component.refraction) return;

    _runtime?.dispose();
    _runtime = null;
    _attach();
  }

  /// Attaches only on the client, and only after the element exists.
  ///
  /// The server must emit no refraction at all: the displacement map is
  /// generated from a measured rectangle, so markup that referenced one
  /// would point at a map nothing had built. Hydration is the first moment
  /// there is anything to measure.
  void _attach() {
    if (!kIsWeb) return;

    (_runtime ??= SurfaceRefractionRuntime(
      elementId: component.elementId,
    )).attach(component.refraction);
  }

  @override
  void dispose() {
    _runtime?.dispose();
    _runtime = null;
    super.dispose();
  }

  @override
  Component build(BuildContext context) => component.child;
}
