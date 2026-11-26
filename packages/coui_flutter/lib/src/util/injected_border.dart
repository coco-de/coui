/// The boundary a surface style injects into surfaces that draw none of
/// their own.
library;

import 'package:coui_flutter/coui_flutter.dart';

/// The active style's contributed boundary, as a paint-ready [Border].
///
/// The twin of `resolveInjectedCast`, and it exists for the same reason.
/// A style's stroke floor can only raise a width that is already being
/// painted; a surface that draws no border has nothing for the floor to
/// lift, so a style whose identity is that everything is boxed has to
/// contribute the border outright.
///
/// Returns `null` under every style that contributes none, so a resolver
/// can hand the result straight to `BoxDecoration.border` without asking
/// which style is active.
///
/// The colour is the palette's `outline` rather than anything stated
/// alongside the width — see `CoreSurfaceGeometryConstraint.controlBorder`
/// for why that decision lives in one place.
///
/// Callers pass what the component already authored. A surface that
/// paints its own border keeps it: the contributed one is for the empty
/// case only, exactly as the cast is, and a surface that authored
/// something bends it through the stroke floor instead of receiving this
/// on top.
Border? resolveInjectedBorder(ThemeData theme, {double authoredWidth = 0}) {
  final spec = resolveInjectedBorderSpec(theme, authoredWidth: authoredWidth);
  if (spec == null) return null;

  return Border.all(
    color: theme.colorScheme.resolve(spec.color).toValue(),
    width: spec.width,
  );
}

/// The same contributed boundary, described in Core terms.
///
/// For a surface that **composes** its box (`OutlinedContainer`) instead
/// of painting one. That component runs `scheme.resolve` /
/// `geometry.stroke` / scaling itself, so handing it the paint-ready
/// [Border] above would bend the geometry twice — it has to receive Core
/// values like every other slot it is given.
///
/// Split out rather than duplicated because the decision this encodes —
/// *when* a style contributes, and that the colour is `outline` — is the
/// thing that has to stay in one place. Two copies would let a composing
/// surface and a self-painting one disagree about whether they are boxed
/// under the same style, which is precisely the inconsistency the style's
/// identity is.
({CoreColor color, double width})? resolveInjectedBorderSpec(
  ThemeData theme, {
  double authoredWidth = 0,
}) {
  if (authoredWidth > 0) return null;
  final width = theme.geometry.controlBorder;
  if (width == null) return null;

  return (color: const CoreColor.token(CoreColors.outline), width: width);
}
