/// Style slot single entry point for `Diff`.
///
/// Houses `ResolvedDiff` (the struct the widget reads) plus
/// `resolveDiff` (the merge + token conversion entry point).
library;

import 'package:coui_flutter/coui_flutter.dart';

/// Resolver output for [Diff].
///
/// Single struct that the widget reads — every field has had the
/// nested-merge chain applied (theme.style → widget.diffStyle), the
/// design-system default fallback (`CoreDiffStyle.defaultX`), and
/// the platform token conversion.
///
/// Widget tree (`diff.dart` decides which optional branches render):
///
/// ```text
/// Stacks (clipBehavior: none)
///   ├─ ClipRRect (borderRadius)
///   │    └─ Stacks
///   │         ├─ after                       // full frame
///   │         ├─ before                      // clipped to the left of the split
///   │         ├─ resizer line                // resizerColor + resizerShadow
///   │         ├─ beforeLabel / afterLabel    // Badge, labelInset in from the top corners
///   │         └─ frame edge                  // borderColor × borderWidth, inside
///   └─ handle zone (handleHitSize wide, full height)
///        └─ FocusOutline → handle disc       // interactive only
///             └─ Icon (handleIconStyle)
/// ```
class ResolvedDiff {
  /// Creates a [ResolvedDiff].
  const ResolvedDiff({
    required this.borderRadius,
    required this.borderColor,
    required this.borderWidth,
    required this.resizerColor,
    required this.resizerWidth,
    required this.resizerShadow,
    required this.handleSize,
    required this.handleHitSize,
    required this.handleColor,
    required this.handleBorderColor,
    required this.handleBorderWidth,
    required this.handleShadow,
    required this.handleHoverShadow,
    required this.handlePressedShadow,
    required this.handlePressedScale,
    required this.handleTransitionDuration,
    required this.handleIconStyle,
    required this.labelInset,
    required this.labelBadgeStyle,
    required this.focusOutlineStyle,
    required this.aspectRatio,
    required this.initialPosition,
    required this.keyboardStep,
    required this.keyboardPageStep,
  });

  /// Effective container border radius (already scaled).
  final BorderRadius borderRadius;

  /// Effective frame edge colour (resolved through the theme scheme).
  final Color borderColor;

  /// Effective frame edge width (px). `0` draws no edge.
  final double borderWidth;

  /// Effective resizer line colour (resolved through the theme scheme).
  final Color resizerColor;

  /// Effective resizer line width (px, already scaled).
  final double resizerWidth;

  /// Effective resizer line cast.
  final List<BoxShadow> resizerShadow;

  /// Effective handle diameter (px, already scaled).
  final double handleSize;

  /// Effective width of the grab area around the handle (px, already
  /// scaled).
  final double handleHitSize;

  /// Effective handle fill.
  final Color handleColor;

  /// Effective handle edge colour.
  final Color handleBorderColor;

  /// Effective handle edge width (px).
  final double handleBorderWidth;

  /// Handle cast at rest.
  final List<BoxShadow> handleShadow;

  /// Handle cast while the pointer is over it.
  final List<BoxShadow> handleHoverShadow;

  /// Handle cast while it is being dragged.
  final List<BoxShadow> handlePressedShadow;

  /// Handle scale while it is being dragged (ratio of its own size).
  final double handlePressedScale;

  /// Time the handle takes to change between rest, hover and pressed
  /// (already passed through the reduced-motion policy).
  final Duration handleTransitionDuration;

  /// Raw-forwarded glyph style for the handle's `Icon` (the icon
  /// resolver does its own scaling).
  final CoreIconStyle handleIconStyle;

  /// Distance of the label chips from the frame's top corners (already
  /// scaled).
  final EdgeInsets labelInset;

  /// Raw-forwarded style for each label's `Badge`.
  final CoreBadgeStyle labelBadgeStyle;

  /// Raw-forwarded focus ring for the handle's `FocusOutline`.
  final CoreFocusOutlineStyle focusOutlineStyle;

  /// Effective canvas aspect ratio (width / height). Non-positive
  /// disables the [AspectRatio] wrapper.
  final double aspectRatio;

  /// Effective initial split position (`[0, 1]`).
  final double initialPosition;

  /// Effective arrow-key step (`[0, 1]` units).
  final double keyboardStep;

  /// Effective Page Up / Page Down step (`[0, 1]` units).
  final double keyboardPageStep;
}

/// Resolves [ResolvedDiff] for [Diff].
///
/// Merge chain:
///
/// ```text
/// CoreDiffStyle.defaultX
///   → CoreDiffTheme.style                           // 프로젝트 공통
///   → widget.diffStyle                              // 인스턴스별
/// ```
///
/// `scaling` is applied here so the widget reads ready-to-paint
/// values.
ResolvedDiff resolveDiff(
  BuildContext context, {
  CoreDiffStyle? diffStyle,
}) {
  final theme = Theme.of(context);
  final scaling = theme.scaling;
  final scheme = theme.colorScheme;
  final compTheme = theme.coreComponentTheme?.diff;

  // Merge chain.
  final merged = resolveStyleChain(const CoreDiffStyle(), [
    compTheme?.style,
    diffStyle,
  ]);

  // Cast base colour — every cast layer draws in the scheme's shadow slot.
  final shadowBase = scheme
      .resolve(const CoreColor.token(CoreColors.shadow))
      .toValue();

  // Border radius.
  final borderRadius =
      (merged.borderRadius ?? CoreDiffStyle.defaultBorderRadius).toValue(
        geometry: theme.geometry,
      );

  // Frame edge.
  final borderColor = scheme
      .resolve(merged.borderColor ?? CoreDiffStyle.defaultBorderColor)
      .toValue();
  final borderWidth = theme.geometry.stroke(
    merged.borderWidth ?? CoreDiffStyle.defaultBorderWidth,
    scaling: scaling,
  );

  // Resizer line.
  final resizerColor = scheme
      .resolve(merged.resizerColor ?? CoreDiffStyle.defaultResizerColor)
      .toValue();
  final resizerWidth =
      (merged.resizerWidth ?? CoreDiffStyle.defaultResizerWidth) * scaling;
  final resizerShadow =
      (merged.resizerShadow ?? CoreDiffStyle.defaultResizerShadow).toValue(
        base: shadowBase,
        geometry: theme.geometry,
        scale: scaling,
      );

  // Handle.
  final handleSize =
      (merged.handleSize ?? CoreDiffStyle.defaultHandleSize) * scaling;
  final handleHitSize =
      (merged.handleHitSize ?? CoreDiffStyle.defaultHandleHitSize) * scaling;
  final handleColor = scheme
      .resolve(merged.handleColor ?? CoreDiffStyle.defaultHandleColor)
      .toValue();
  final handleBorderColor = scheme
      .resolve(
        merged.handleBorderColor ?? CoreDiffStyle.defaultHandleBorderColor,
      )
      .toValue();
  final handleBorderWidth = theme.geometry.stroke(
    merged.handleBorderWidth ?? CoreDiffStyle.defaultHandleBorderWidth,
    scaling: scaling,
  );
  final handleShadow =
      (merged.handleShadow ?? CoreDiffStyle.defaultHandleShadow).toValue(
        base: shadowBase,
        geometry: theme.geometry,
        scale: scaling,
      );
  final handleHoverShadow =
      (merged.handleHoverShadow ?? CoreDiffStyle.defaultHandleHoverShadow)
          .toValue(
            base: shadowBase,
            geometry: theme.geometry,
            scale: scaling,
          );
  final handlePressedShadow =
      (merged.handlePressedShadow ?? CoreDiffStyle.defaultHandlePressedShadow)
          .toValue(
            base: shadowBase,
            geometry: theme.geometry,
            scale: scaling,
          );
  final handlePressedScale =
      merged.handlePressedScale ?? CoreDiffStyle.defaultHandlePressedScale;
  final handleTransitionDuration = resolveMotionDuration(
    context,
    merged.handleTransitionDuration ??
        CoreDiffStyle.defaultHandleTransitionDuration,
  );

  // Nested slots — raw-forwarded, the child resolvers scale their own.
  final handleIconStyle = CoreDiffStyle.defaultHandleIconStyle.merge(
    merged.handleIconStyle,
  );
  final labelBadgeStyle = CoreDiffStyle.defaultLabelBadgeStyle.merge(
    merged.labelBadgeStyle,
  );
  final focusOutlineStyle = CoreDiffStyle.defaultFocusOutlineStyle.merge(
    merged.focusOutlineStyle,
  );

  // Label placement.
  final labelInset =
      (merged.labelInset ?? CoreDiffStyle.defaultLabelInset).toValue(
        geometry: theme.geometry,
      ) *
      scaling;

  // Geometry.
  final aspectRatio = merged.aspectRatio ?? CoreDiffStyle.defaultAspectRatio;
  final initialPosition =
      (merged.initialPosition ?? CoreDiffStyle.defaultInitialPosition).clamp(
        0.0,
        1.0,
      );
  final keyboardStep = merged.keyboardStep ?? CoreDiffStyle.defaultKeyboardStep;
  final keyboardPageStep =
      merged.keyboardPageStep ?? CoreDiffStyle.defaultKeyboardPageStep;

  return ResolvedDiff(
    borderRadius: borderRadius,
    borderColor: borderColor,
    borderWidth: borderWidth,
    resizerColor: resizerColor,
    resizerWidth: resizerWidth,
    resizerShadow: resizerShadow,
    handleSize: handleSize,
    handleHitSize: handleHitSize,
    handleColor: handleColor,
    handleBorderColor: handleBorderColor,
    handleBorderWidth: handleBorderWidth,
    handleShadow: handleShadow,
    handleHoverShadow: handleHoverShadow,
    handlePressedShadow: handlePressedShadow,
    handlePressedScale: handlePressedScale,
    handleTransitionDuration: handleTransitionDuration,
    handleIconStyle: handleIconStyle,
    labelInset: labelInset,
    labelBadgeStyle: labelBadgeStyle,
    focusOutlineStyle: focusOutlineStyle,
    aspectRatio: aspectRatio,
    initialPosition: initialPosition,
    keyboardStep: keyboardStep,
    keyboardPageStep: keyboardPageStep,
  );
}
