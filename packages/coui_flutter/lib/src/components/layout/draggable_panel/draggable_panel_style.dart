import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/components/infra/inset_shadow/inset_shadow_style.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/outlined_container_internal.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/outlined_container_style.dart';
import 'package:coui_flutter/src/theme/theme.dart';
import 'package:coui_flutter/src/util/core_to_flutter.dart';
import 'package:coui_flutter/src/util/motion.dart';
import 'package:flutter/widgets.dart';

/// Paint-ready chrome for Flutter `DraggablePanel`.
///
/// Widget tree (`co_draggable_panel.dart` decides which branches render):
///
/// ```text
/// Stack
///   ├─ child                              // Positioned.fill — caller subtree
///   ├─ AnimatedPositioned (handle)        // DecoratedBox(handle*) → handle?
///   └─ AnimatedPositioned (panel)         // open only — DecoratedBox(panel*)
/// ```
///
/// `co_draggable_panel.dart` reads each field straight from `resolved.X` —
/// no merge / fallback / token resolution in the widget body.
@immutable
class ResolvedDraggablePanel {
  /// Creates a [ResolvedDraggablePanel].
  const ResolvedDraggablePanel({
    required this.panelBackgroundColor,
    required this.panelBorderColor,
    required this.panelBorderWidth,
    required this.panelBorderRadius,
    required this.panelPadding,
    required this.panelWidth,
    required this.panelShadow,
    required this.panelInsetShadow,
    required this.handleSize,
    required this.handleBackgroundColor,
    required this.handleForegroundColor,
    required this.handleBorderRadius,
    required this.handleIconStyle,
    required this.handleShadow,
    required this.animationDuration,
    required this.surfaceBlur,
    required this.surfaceSaturation,
    required this.surfaceBackdropBrightness,
    required this.surfaceSheen,
  });

  /// Backdrop blur sigma for the panel, `null` when the active theme
  /// states no material or the panel states no fill to blur behind.
  final double? surfaceBlur;

  /// Chroma lift riding the same backdrop pass as [surfaceBlur].
  final double? surfaceSaturation;

  /// How far the active style dims what shows through this surface, or
  /// null for no material.
  ///
  /// Rides the same backdrop pass as [surfaceSaturation].
  final double? surfaceBackdropBrightness;

  /// Edge light riding the same material treatment as [surfaceBlur].
  final ResolvedSurfaceSheen? surfaceSheen;

  /// Panel surface fill, with `surfaceOpacity` already folded in — a
  /// blur behind an opaque fill is painted and then covered.
  final Color panelBackgroundColor;

  /// Panel surface border colour.
  final Color panelBorderColor;

  /// Panel surface border width (scaled).
  final double panelBorderWidth;

  /// Panel surface corner radius (scaled).
  final BorderRadius panelBorderRadius;

  /// Panel content padding (scaled).
  final EdgeInsets panelPadding;

  /// Panel surface width (scaled).
  final double panelWidth;

  /// Panel surface drop shadow.
  final List<BoxShadow> panelShadow;

  /// The inset rim the active surface style adds over the panel.
  final List<BoxShadow> panelInsetShadow;

  /// Square handle edge length (scaled).
  final double handleSize;

  /// Handle button fill.
  final Color handleBackgroundColor;

  /// Default handle glyph colour.
  final Color handleForegroundColor;

  /// Nested icon chrome for the default handle icon — raw-forwarded to
  /// the unified `Icon` (which owns its own resolve / scaling step).
  final CoreIconStyle handleIconStyle;

  /// Handle button corner radius (scaled).
  final BorderRadius handleBorderRadius;

  /// Handle button drop shadow.
  final List<BoxShadow> handleShadow;

  /// Open/close + dock-snap animation duration.
  final Duration animationDuration;
}

/// Single entry point that folds theme + per-instance overrides into the
/// paint-ready [ResolvedDraggablePanel] for Flutter `DraggablePanel`.
ResolvedDraggablePanel resolveDraggablePanel(
  BuildContext context, {
  CoreDraggablePanelStyle? draggablePanelStyle,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final scaling = theme.scaling;
  final panelTheme = theme.coreComponentTheme?.draggablePanel;

  // Stage 1 — RESOLVE (identical to Web): empty base + override layers.
  final merged = resolveStyleChain(const CoreDraggablePanelStyle(), [
    panelTheme?.style,
    draggablePanelStyle,
  ]);

  // Stage 2 — EMIT (Flutter, theme-dependent). Colours via scheme.resolve,
  // dimensional values * scaling, shadows tinted by the resolved base.
  final shadowBase = scheme
      .resolve(
        merged.shadowBaseColor ??
            CoreDraggablePanelStyle.defaultShadowBaseColor,
      )
      .toValue();

  // A panel dragged around over the page has that page behind it the
  // whole time. Both halves of the material come off the theme —
  // translucency without a blur is a lighter panel, and a blur behind
  // an opaque fill is painted and then covered.
  // 이 표면은 콘텐츠 위에 뜬다. 스타일이 두 재질을 진술하면 그중 떠
  // 있는 쪽을 받고, 하나만 진술하면 그것을 받는다 — 역할을 안 쓰는
  // 프리셋에게 이 축은 공짜다.
  final material = theme.surfaceFor(
    CoreSurfaceRole.functional,
    depth: SurfaceDepth.of(context),
  );
  final surfaceOpacity = material?.opacityIn(theme);
  final panelBackgroundCore =
      merged.panelBackgroundColor ??
      CoreDraggablePanelStyle.defaultPanelBackgroundColor;
  final panelBackgroundColor = scheme
      .resolve(
        surfaceOpacity == null
            ? panelBackgroundCore
            : panelBackgroundCore.scaleAlpha(surfaceOpacity),
      )
      .toValue();
  final hasFill = panelBackgroundColor.a > 0;
  final surfaceBlur = hasFill ? material?.blurRadius : null;
  final surfaceSaturation = hasFill ? material?.saturation : null;
  final surfaceBackdropBrightness = hasFill
      ? material?.backdropBrightnessIn(theme)
      : null;
  final surfaceSheen = hasFill
      ? resolveSurfaceSheen(theme, role: CoreSurfaceRole.functional)
      : null;
  // Through the shared helper, like every surface that resolves its own
  // stroke: a material that draws its own edge suppresses the component
  // border, and a surface that skips this keeps a border its siblings
  // have dropped.
  final panelBorderColor = resolveSurfaceStroke(
    theme,
    scheme
        .resolve(
          merged.panelBorderColor ??
              CoreDraggablePanelStyle.defaultPanelBorderColor,
        )
        .toValue(),
    role: CoreSurfaceRole.functional,
  );
  final panelBorderWidth = theme.geometry.stroke(
    merged.panelBorderWidth ?? CoreDraggablePanelStyle.defaultPanelBorderWidth,
    scaling: scaling,
  );
  final panelBorderRadius =
      (merged.panelBorderRadius ??
              CoreDraggablePanelStyle.defaultPanelBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;
  final panelPadding =
      (merged.panelPadding ?? CoreDraggablePanelStyle.defaultPanelPadding)
          .toValue(geometry: theme.geometry) *
      scaling;
  final panelWidth =
      (merged.panelWidth ?? CoreDraggablePanelStyle.defaultPanelWidth) *
      scaling;
  final panelStack =
      merged.panelShadow ?? CoreDraggablePanelStyle.defaultPanelShadow;
  final panelShadow = panelStack.toValue(
    base: shadowBase,
    geometry: theme.geometry,
  );
  // The panel is a surface and gets the rim; the drag handle beside it
  // is an affordance and does not. The rim is derived from the page
  // surface, so it only belongs on something filled with that surface.
  final panelInsetShadow = resolveSurfaceRim(context, stack: panelStack);

  final handleSize =
      (merged.handleSize ?? CoreDraggablePanelStyle.defaultHandleSize) *
      scaling;
  final handleBackgroundColor = scheme
      .resolve(
        merged.handleBackgroundColor ??
            CoreDraggablePanelStyle.defaultHandleBackgroundColor,
      )
      .toValue();
  final handleForegroundColor = scheme
      .resolve(
        merged.handleForegroundColor ??
            CoreDraggablePanelStyle.defaultHandleForegroundColor,
      )
      .toValue();
  final handleBorderRadius =
      (merged.handleBorderRadius ??
              CoreDraggablePanelStyle.defaultHandleBorderRadius)
          .toValue(geometry: theme.geometry) *
      scaling;
  final handleShadow =
      (merged.handleShadow ?? CoreDraggablePanelStyle.defaultHandleShadow)
          .toValue(base: shadowBase, geometry: theme.geometry);
  final animationDuration = resolveMotionDuration(
    context,
    merged.animationDuration ??
        CoreDraggablePanelStyle.defaultAnimationDuration,
  );
  final handleIconStyle = CoreDraggablePanelStyle.defaultHandleIconStyle.merge(
    merged.handleIconStyle,
  );

  return ResolvedDraggablePanel(
    panelBackgroundColor: panelBackgroundColor,
    panelBorderColor: panelBorderColor,
    panelBorderWidth: panelBorderWidth,
    panelBorderRadius: panelBorderRadius,
    panelPadding: panelPadding,
    panelWidth: panelWidth,
    panelShadow: panelShadow,
    panelInsetShadow: panelInsetShadow,
    handleSize: handleSize,
    handleBackgroundColor: handleBackgroundColor,
    handleForegroundColor: handleForegroundColor,
    handleBorderRadius: handleBorderRadius,
    handleIconStyle: handleIconStyle,
    handleShadow: handleShadow,
    animationDuration: animationDuration,
    surfaceBlur: surfaceBlur,
    surfaceSaturation: surfaceSaturation,
    surfaceBackdropBrightness: surfaceBackdropBrightness,
    surfaceSheen: surfaceSheen,
  );
}
