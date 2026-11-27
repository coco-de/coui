import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/surface_fade.dart';
import 'package:coui_flutter/src/components/infra/popup/popup_scroll_scope.dart';

/// A unified styled floating-panel container.
///
/// `Popup` is a chrome-styled surface for floating content such as
/// menus, dropdowns and tooltips. It lays its [children] out along
/// [direction] inside a bordered, elevated, rounded panel and shows /
/// hides through the [open] flag.
///
/// `Popup` is the unified replacement for the legacy Flutter
/// `MenuPopup` and Web `Popup` — same parameter names, same
/// semantics, full visual parity.
///
/// Mirrors Web `Popup` 1:1 — same parameter names, same semantics.
///
/// ```dart
/// Popup(
///   children: const [
///     Text('Profile'),
///     Text('Settings'),
///     Text('Sign out'),
///   ],
/// )
/// ```
///
/// surface:behind — a floating anchored panel — its host mounts it over page
/// content.
///
/// surface:functional — the anchored panel itself — its host mounts it over
/// page content.
class Popup extends StatelessWidget implements CorePopupContract<Widget> {
  /// Creates a [Popup].
  const Popup({
    required this.children,
    this.open = true,
    this.direction = CoreAxis.vertical,
    this.popupStyle,
    super.key,
  });

  @override
  final List<Widget> children;

  @override
  final bool open;

  @override
  final CoreAxis direction;

  @override
  final CorePopupStyle? popupStyle;

  /// Returns a copy of this [Popup] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Popup copyWith({
    Key? key,
    bool? open,
    CoreAxis? direction,
    CorePopupStyle? popupStyle,
    List<Widget>? children,
  }) {
    return Popup(
      key: key ?? this.key,
      open: open ?? this.open,
      direction: direction ?? this.direction,
      popupStyle: popupStyle ?? this.popupStyle,
      children: children ?? this.children,
    );
  }

  /// The vertical stack of [children] — scrolled when a [PopupScrollScope]
  /// above says this popup's content is a list, so that a panel the viewport
  /// cannot fit shows its rows by scrolling instead of overflowing.
  ///
  /// The scroll view takes the content's own height when there is room and
  /// the given height when there is not, so a panel with room is laid out
  /// exactly as one without a scroll view. It does not clip: the panel's own
  /// rounded clip bounds what is seen, and a row's focus ring, which reaches
  /// past the row, stays inside it. It paints nothing either — see the
  /// overscroll note below — so a panel that fits draws what it drew without
  /// one.
  Widget _buildColumn(BuildContext context, double spacing) {
    final column = Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      spacing: spacing,
      children: children,
    );
    if (!PopupScrollScope.of(context)) return column;

    // `primary: false`: the page's scroll controller belongs to the page, and
    // a floating panel must not take it over.
    //
    // No overscroll glow or stretch: the app's scroll behaviour paints one at
    // the ends of anything that scrolls, which suits a page's edge and not the
    // rounded box of a panel — and it would add a painter to every menu,
    // including the ones that never scroll.
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: SingleChildScrollView(
        primary: false,
        clipBehavior: .none,
        child: column,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!open) return const SizedBox.shrink();

    final resolved = resolvePopup(context, popupStyle: popupStyle);

    final content = direction == .vertical
        ? _buildColumn(context, resolved.spacing)
        : Row(
            mainAxisSize: .min,
            spacing: resolved.spacing,
            children: children,
          );

    // Content-width panel: `IntrinsicWidth` shrink-wraps the box to its
    // content with `min-width` as the floor, mirroring the Web `Popup`
    // (absolute-positioned → content-width). Every floating panel that
    // composes `Popup` (menus AND `Popover` consumers like ColorPicker /
    // Select) must therefore present intrinsic-measurable content — e.g. the
    // ColorPicker SV area is a fixed `SizedBox.square`, not a bare
    // `AspectRatio` over a `LayoutBuilder` (which throws on intrinsics).
    // Web twin puts a role on the popup surface.
    // The panel as it is drawn at [fadeProgress] of the way in view, or at rest
    // where it is null. A panel that is being faded by an opacity above it —
    // the common case, and every panel that draws no backdrop pass — is drawn
    // at rest.
    Widget drawPanel(double? fadeProgress) {
      Widget panel = InsetShadow(
        shadows: resolved.insetBoxShadow,
        radius: resolved.borderRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: resolved.backgroundColor,
            // `Border.all(width: 0)` paints a hairline in Flutter (≠ Web
            // `border-width: 0` which is none), so a zero-width panel (e.g.
            // menubar / inline submenu suppressor) must skip the border
            // entirely to keep cross-platform parity.
            border: resolved.borderWidth > 0
                ? Border.all(
                    color: resolved.borderColor,
                    width: resolved.borderWidth,
                  )
                : null,
            borderRadius: resolved.borderRadius,
            boxShadow: resolved.isGlass ? null : resolved.boxShadow,
          ),
          child: ClipRRect(
            borderRadius: resolved.borderRadius,
            child: Padding(
              padding: resolved.padding,
              // Ambient content text colour — override only the colour so
              // the content inherits the surrounding typography role.
              child: DefaultTextStyle(
                style: DefaultTextStyle.of(
                  context,
                ).style.copyWith(color: resolved.contentTextColor),
                child: content,
              ),
            ),
          ),
        ),
      );

      // The resolver hands this over only when the panel states a fill, so a
      // fill-less popup — a nested submenu drawn inside its parent's panel —
      // never stacks a second backdrop pass or gets a squared band.
      //
      // `borderRadius` is load-bearing: the `ClipRRect` above sits inside the
      // `DecoratedBox` and bounds the content, not the backdrop pass, which
      // would otherwise square off the corners it blurs.
      final effectiveBlur = resolved.surfaceBlur;
      if ((effectiveBlur != null && effectiveBlur > 0) ||
          resolved.surfaceSheen != null) {
        panel = SurfaceBlur(
          borderRadius: resolved.borderRadius,
          surfaceBlur: effectiveBlur,
          surfaceSaturation: resolved.surfaceSaturation,
          surfaceBackdropBrightness: resolved.surfaceBackdropBrightness,
          surfaceSheen: resolved.surfaceSheen,
          // The active material's bend. Every surface that draws the material
          // draws all of it — the frost and the chroma without the bend is a
          // blurred panel, not glass, and the bend is the term the material
          // is named for.
          //
          // Falls back rather than being required: a style that states no
          // refraction leaves this null and the surface simply does not
          // bend, which is how every preset but glass renders.
          refraction: resolved.refraction,
          fadeProgress: fadeProgress,
          child: panel,
        );
      }

      if (resolved.isGlass) {
        // The cast sits behind the panel, outside the opacity the fill and the
        // content fade under, so it fades by the progress itself here.
        panel = InjectedCast(
          shadows: fadeShadows(resolved.boxShadow, fadeProgress),
          borderRadius: resolved.borderRadius,
          child: panel,
        );
      }

      return panel;
    }

    // A panel under a host that fades it offers its surface the fade. A
    // surface that draws a backdrop pass takes it over — an opacity above a
    // backdrop filter would take the pass away — and one that does not leaves
    // the panel to be faded as a whole. With no host above, nothing is
    // mounted and the panel is built without a wrapper.
    final fadeScope = SurfaceFadeScope.maybeOf(context);
    final panel = fadeScope == null
        ? drawPanel(null)
        : SurfaceFadeAdopter(
            scope: fadeScope,
            drawsPass: surfaceDrawsBackdropPass(
              blur: resolved.surfaceBlur,
              refraction: resolved.refraction,
            ),
            builder: drawPanel,
          );

    // Web twin puts a role on the popup surface.
    return Semantics(
      container: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: resolved.minWidth,
          maxWidth: resolved.maxWidth,
        ),
        child: IntrinsicWidth(child: panel),
      ),
    );
  }
}

/// Chain sugar for merging a [CorePopupStyle] patch into
/// [Popup.popupStyle] without hand-reconstructing every field. Mirrors
/// the Web `Popup.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CorePopupStyle.merge` right-side-wins semantics).
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
/// sets [CorePopupStyle.borderRadius] and `.primary` sets
/// [CorePopupStyle.backgroundColor]. A semantic layer that names these
/// after component-specific intent (decided together with design) is
/// a follow-up once more components adopt this pattern.
///
/// ```dart
/// Popup(children: const [Text('Profile')]).radius4.surface
/// ```
extension PopupStyleChain on Popup {
  /// Sets the background paint and preserves the other style fields.
  Popup backgroundColor(CoreColor value) =>
      withStyle(CorePopupStyle(backgroundColor: value));

  /// Returns a copy of this [Popup] with [patch] merged into
  /// [popupStyle] (patch fields win on conflict).
  Popup withStyle(CorePopupStyle patch) => copyWith(
    popupStyle: (popupStyle ?? const CorePopupStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.zero`.
  Popup get radius0 =>
      withStyle(const CorePopupStyle(borderRadius: CoreBorderRadius.zero));

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  Popup get radius2 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  Popup get radius4 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  Popup get radius6 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  Popup get radius8 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  Popup get radius10 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  Popup get radius12 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  Popup get radius14 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  Popup get radius16 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  Popup get radius20 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  Popup get radius24 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  Popup get radius28 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  Popup get radius32 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  Popup get radius36 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  Popup get radius40 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  Popup get radius48 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  Popup get radius56 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  Popup get radius64 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  Popup get radius9999 => withStyle(
    const CorePopupStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  Popup get primary => withStyle(
    const CorePopupStyle(backgroundColor: CoreColor.token(CoreColors.primary)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  Popup get secondary => withStyle(
    const CorePopupStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  Popup get tertiary => withStyle(
    const CorePopupStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  Popup get surface => withStyle(
    const CorePopupStyle(backgroundColor: CoreColor.token(CoreColors.surface)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  Popup get surfaceContainer => withStyle(
    const CorePopupStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  Popup get error => withStyle(
    const CorePopupStyle(backgroundColor: CoreColor.token(CoreColors.error)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  Popup get success => withStyle(
    const CorePopupStyle(backgroundColor: CoreColor.token(CoreColors.success)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  Popup get warning => withStyle(
    const CorePopupStyle(backgroundColor: CoreColor.token(CoreColors.warning)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  Popup get info => withStyle(
    const CorePopupStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  Popup get outline => withStyle(
    const CorePopupStyle(backgroundColor: CoreColor.token(CoreColors.outline)),
  );

  /// `backgroundColor: CoreColor.transparent`.
  Popup get transparent =>
      withStyle(const CorePopupStyle(backgroundColor: .transparent));
}
