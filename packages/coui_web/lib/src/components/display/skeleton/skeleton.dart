import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/display/loading_region/loading_region.dart';
import 'package:coui_web/src/components/display/skeleton/skeleton_style.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform skeleton for CoUI Web
/// with token-based rendering.
///
/// Per Epic #1302 chrome / dimensional / animation overrides flow
/// through the single [skeletonStyle] slot. Sizing fields
/// ([width] / [height]) plus the semantic [variant] stay flat on the
/// widget.
///
/// Whether a skeleton is drawn is the caller's condition — render it
/// conditionally at the call site (`if (loading) Skeleton(...)`).
///
/// Per Epic #1603 (옵션 B 최종) the resolver finishes className +
/// inlineStyles synthesis once; `co_skeleton` reads the paint-ready
/// strings directly and never touches `CoreSkeletonStyle` itself.
///
/// Example:
/// ```dart
/// Skeleton(width: '200px', height: '20px')
/// Skeleton(
///   width: '200px',
///   height: '20px',
///   skeletonStyle: CoreSkeletonStyle(
///     backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
///   ),
/// )
/// ```
class Skeleton extends UiComponent implements CoreSkeletonContract {
  /// Creates a [Skeleton].
  Skeleton({
    super.key,
    this.width,
    this.height,
    this.variant = CoreSkeletonVariant.defaultVariant,
    this.skeletonStyle,
    super.id,
  }) : super(tag: _kDiv);

  /// Creates a circular skeleton (for avatars, icons).
  Skeleton.circle({
    required String size,
    super.key,
    this.skeletonStyle,
    super.id,
  }) : width = size,
       height = size,
       variant = CoreSkeletonVariant.circular,
       super(tag: _kDiv);

  /// Creates a multi-line text skeleton.
  Skeleton.text({
    super.key,
    this.skeletonStyle,
    super.id,
  }) : width = null,
       height = null,
       variant = CoreSkeletonVariant.text,
       super(tag: _kDiv);

  /// Width of the skeleton placeholder as a CSS value (e.g. '200px',
  /// '100%'). Flat, platform-typed sizing knob — not a contract member.
  final String? width;

  /// Height of the skeleton placeholder as a CSS value (e.g. '20px').
  /// Flat, platform-typed sizing knob — not a contract member.
  final String? height;

  @override
  final CoreSkeletonVariant variant;

  @override
  final CoreSkeletonStyle? skeletonStyle;

  // === Internal ===

  static const _kDiv = 'div';
  static const _kSpan = 'span';
  static const _kRoleAttr = 'role';
  static const _kAriaLabelAttr = 'aria-label';
  // `status` (not `progressbar`) — `progressbar` carries no implicit
  // live-region semantics, so nothing was actually announced. `status`
  // matches the Flutter twin's `Semantics(liveRegion: true, ...)` and the
  // sibling `Loading` component's own role, so a screen reader hears the
  // same "still loading" announcement on both platforms.
  static const _kStatusRole = 'status';
  @override
  Skeleton copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? width,
    String? height,
    CoreSkeletonVariant? variant,
    CoreSkeletonStyle? skeletonStyle,
  }) {
    return Skeleton(
      key: key ?? this.key,
      width: width ?? this.width,
      height: height ?? this.height,
      variant: variant ?? this.variant,
      skeletonStyle: skeletonStyle ?? this.skeletonStyle,
      id: id ?? this.id,
    );
  }

  @override
  Component build(BuildContext context) {
    // Resolver finishes className + inlineStyles synthesis (Epic #1601
    // PoC — `WebResolvedChrome` contract). `co_skeleton` reads the
    // paint-ready strings directly without invoking the top-level
    // builder helpers.
    final resolved = resolveSkeleton(
      context,
      variant: variant,
      width: width,
      height: height,
      skeletonStyle: skeletonStyle,
    );

    // Inside a `LoadingRegion` the region announces once for the whole
    // area; a skeleton announcing too would make ten placeholders ten
    // announcements.
    final announces = !LoadingRegionScope.existsAbove(context);
    // Read at render time, not a compile-time constant: a default
    // parameter value cannot reach the active locale, and the Flutter
    // twin has read this from localizations all along — so a locale
    // switch changed the label on one platform and not the other.
    final label = CouiLocalizations.of(context).loadingLabel;

    final attributes = {
      ...componentAttributes,
      if (announces) ...{_kRoleAttr: _kStatusRole, _kAriaLabelAttr: label},
    };

    return Component.element(
      tag: _kDiv,
      id: id,
      classes: resolved.root.className,
      styles: resolved.root.inlineStyles,
      attributes: attributes,
      children: [
        for (final line in resolved.textLines)
          Component.element(
            tag: _kDiv,
            classes: line.className,
            styles: line.inlineStyles,
          ),
        // A live region announces its content, not its name — the label
        // alone left the status with nothing to say.
        if (announces)
          Component.element(
            tag: _kSpan,
            classes: resolved.announcer.className,
            children: [Text(label)],
          ),
      ],
    );
  }
}

/// Chain sugar mirroring the Flutter `Skeleton.withStyle` extension —
/// merges a [CoreSkeletonStyle] patch into [Skeleton.skeletonStyle] via
/// the existing [Skeleton.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreSkeletonStyle.merge` right-side-wins semantics).
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
/// sets [CoreSkeletonStyle.borderRadius] and `.primary` sets
/// [CoreSkeletonStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// Skeleton(width: '200px', height: '20px').radius4.primary
/// ```
extension SkeletonStyleChain on Skeleton {
  /// Sets the background paint and preserves the other style fields.
  Skeleton backgroundColor(CoreColor value) =>
      withStyle(CoreSkeletonStyle(backgroundColor: value));

  /// Returns a copy of this [Skeleton] with [patch] merged into
  /// [skeletonStyle] (patch fields win on conflict).
  Skeleton withStyle(CoreSkeletonStyle patch) => copyWith(
    skeletonStyle: (skeletonStyle ?? const CoreSkeletonStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  Skeleton get radius0 =>
      withStyle(const CoreSkeletonStyle(borderRadius: CoreBorderRadius.zero));

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Skeleton get radius2 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Skeleton get radius4 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Skeleton get radius6 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Skeleton get radius8 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Skeleton get radius10 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Skeleton get radius12 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Skeleton get radius14 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Skeleton get radius16 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Skeleton get radius20 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Skeleton get radius24 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Skeleton get radius28 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Skeleton get radius32 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Skeleton get radius36 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Skeleton get radius40 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Skeleton get radius48 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Skeleton get radius56 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Skeleton get radius64 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Skeleton get radius9999 => withStyle(
    const CoreSkeletonStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Skeleton get primary => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Skeleton get secondary => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Skeleton get tertiary => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Skeleton get surface => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Skeleton get surfaceContainer => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Skeleton get error => withStyle(
    const CoreSkeletonStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Skeleton get success => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Skeleton get warning => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Skeleton get info => withStyle(
    const CoreSkeletonStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Skeleton get outline => withStyle(
    const CoreSkeletonStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Skeleton get transparent => withStyle(
    const CoreSkeletonStyle(backgroundColor: .transparent),
  );
}
