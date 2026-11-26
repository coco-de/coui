import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/theme/theme.dart';
import 'package:flutter/widgets.dart';

/// Renders [child] at the typography [tier], whatever width the viewport
/// around it resolves to.
///
/// The subtree takes the app's type scale as folded for that tier — the
/// display and headline roles at the tier's sizes, the surface style's
/// weight floor and the scaling as the app has them. Everything else stays
/// the surrounding theme's.
///
/// A component states this for the glyphs that fill a box of its own — a
/// box whose size no tier changes, sized so the glyph fills it, like an
/// avatar's initials. The component does not read the tier; it says which
/// tier its box was drawn for, the way a surface says it is a surface.
///
/// Named and shaped identically to the Web scope so an app reads the same
/// call on both platforms. Only the transport differs: here the subtree gets
/// a theme with that tier's type scale, while on the Web the wrapper carries
/// `data-coui-typography-tier` ([kTypographyTierAttribute]), whose rules
/// restate the type variables for everything inside it.
///
/// The type scale comes from [AppTypographyTiers], which `CoUIApp` publishes,
/// and the scale around the scope is what tells which tier the surroundings
/// are at. Around one of the published scales, the scope takes the app's
/// scale at its own tier. Around a scale that draws the sizes of one of them
/// but differs otherwise — a face or a weight a subtree changed, a theme
/// switch caught halfway — the scope steps that scale from the tier it is
/// drawn at, so what the subtree changed stays. A scale whose sizes are none
/// of the app's is the subtree's own: a `Theme` that set a type scale of its
/// own, or a root outside `CoUIApp` (a test harness, a hand-built root). It
/// is taken as authored, the desktop one, and stepped from there — a desktop
/// scope leaves it as it is.
///
/// ```dart
/// // A marketing hero that keeps its desktop headline on every width.
/// TypographyTierScope(tier: CoreBreakpointTier.desktop, child: hero)
/// ```
class TypographyTierScope extends StatelessWidget {
  /// Creates a scope rendering [child] at the typography [tier].
  const TypographyTierScope({
    required this.tier,
    required this.child,
    super.key,
  });

  /// The typography tier [child] renders at.
  final CoreBreakpointTier tier;

  /// The subtree that renders at [tier].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final around = Theme.of(context);
    final tiers = AppTypographyTiers.maybeOf(context);
    final drawnAt = tiers?.tierOf(around.typography);
    final CoreTypography typography;
    if (tiers == null || drawnAt == null) {
      // None of the app's sizes: the subtree's own scale, as authored.
      typography = around.typography.atTier(tier);
    } else if (around.typography == tiers.at(drawnAt)) {
      // The app's own scale: the app's fold at this tier.
      typography = tiers.at(tier);
    } else {
      // The app's sizes with something else changed below it: this scale,
      // stepped from where it is.
      typography = around.typography.atTier(tier, from: drawnAt);
    }

    // Always a `Theme`, even when the scale is the one around: whether the
    // wrapper is there must not depend on the viewport, or every crossing
    // of a tier boundary would remount the subtree and drop its state — a
    // focused field, a scroll offset.
    return Theme(
      data: typography == around.typography
          ? around
          : around.copyWith(typography: () => typography),
      child: child,
    );
  }
}

/// The app's type scale at each typography tier — published by `CoUIApp`
/// so a [TypographyTierScope] renders what the app would render at that
/// tier.
///
/// Each is folded the way the active theme is: the high-contrast set when
/// the preference is on, the surface style's weight floor, the scaling. The
/// tier the viewport resolves to is the active theme's own scale.
///
/// A widget that changes the sizes of its subtree's type scale the same way
/// at every tier publishes the three again, changed that way, so the scale
/// around a scope below it still draws the sizes of one of them —
/// [AdaptiveScaler] does. Like a
/// theme, the published scales travel into a panel opened below them
/// (`InheritedTheme.capture`), so a scope in the panel finds them beside the
/// theme they match.
class AppTypographyTiers extends InheritedTheme {
  /// Creates the published scales.
  const AppTypographyTiers({
    required this.mobile,
    required this.tablet,
    required this.desktop,
    required super.child,
    super.key,
  });

  /// The scales published above [context], or `null` when nothing above
  /// publishes them.
  static AppTypographyTiers? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppTypographyTiers>();

  /// The app's type scale below 768px.
  final CoreTypography mobile;

  /// The app's type scale from 768px to below 1024px.
  final CoreTypography tablet;

  /// The app's type scale from 1024px — the scale as authored.
  final CoreTypography desktop;

  /// The app's type scale at [tier].
  CoreTypography at(CoreBreakpointTier tier) => switch (tier) {
    .mobile => mobile,
    .tablet => tablet,
    .desktop => desktop,
  };

  /// The tier [typography] is drawn at, when it draws the sizes of one of the
  /// published scales — that scale itself, or that scale with a face or a
  /// weight changed below the app — and `null` when it draws other sizes.
  ///
  /// The published scales differ in their headings' sizes, which a face or a
  /// weight leaves alone, so the sizes are what tells the tier.
  CoreBreakpointTier? tierOf(CoreTypography typography) {
    for (final tier in CoreBreakpointTier.values) {
      final published = at(tier);
      if (CoreTextStyles.values.every(
        (token) =>
            token.read(typography).fontSize == token.read(published).fontSize,
      )) {
        return tier;
      }
    }

    return null;
  }

  @override
  Widget wrap(BuildContext context, Widget child) => AppTypographyTiers(
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    child: child,
  );

  @override
  bool updateShouldNotify(AppTypographyTiers oldWidget) =>
      mobile != oldWidget.mobile ||
      tablet != oldWidget.tablet ||
      desktop != oldWidget.desktop;
}
