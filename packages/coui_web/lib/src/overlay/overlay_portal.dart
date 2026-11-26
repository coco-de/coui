/// `InheritedComponent` exposing a [OverlayController] to
/// descendants — the Web equivalent of Flutter `Overlay.of(context)`
/// + `OverlayManagerLayer` lookup.
library;

import 'package:coui_web/src/base/brightness_scope.dart';
import 'package:coui_web/src/base/typography_tier_scope.dart';
import 'package:coui_web/src/overlay/overlay_controller.dart';
import 'package:jaspr/jaspr.dart';

/// Provides a [OverlayController] to descendants. Look up via
/// `OverlayPortal.of(context).controller` — typically from inside a
/// floating component's `_handleOpen` to mount its panel on the root
/// overlay layer. Pass the panel through [capture] first so it keeps the
/// brightness and the typography tier of the place it opened from.
class OverlayPortal extends InheritedComponent {
  /// Creates a portal provider. Wired by `OverlayHost.build`.
  const OverlayPortal({
    required this.controller,
    required super.child,
    super.key,
  });

  /// The controller hosted by the nearest ancestor `OverlayHost`.
  final OverlayController controller;

  /// Returns the nearest [OverlayPortal] in the ancestor chain, or
  /// `null` if no `OverlayHost` exists above [context].
  ///
  /// Floating components fall back to inline rendering when this
  /// returns null so they keep working in test contexts that don't
  /// wrap their tree with `CoUIWeb` / `OverlayHost`.
  static OverlayPortal? maybeOf(BuildContext context) {
    return context.dependOnInheritedComponentOfExactType();
  }

  /// Returns the nearest [OverlayPortal]. Asserts a host is wrapped
  /// somewhere above [context].
  static OverlayPortal of(BuildContext context) {
    final portal = maybeOf(context);
    assert(
      portal != null,
      'No OverlayHost found in context. '
      'Wrap your app with CoUIWeb or OverlayHost to enable '
      'portal-based overlays.',
    );
    return portal!;
  }

  /// [panel] wrapped in the `BrightnessScope` and `TypographyTierScope` it
  /// leaves behind when it is mounted on this host — the brightness and
  /// typography tier part of what Flutter's
  /// `InheritedTheme.capture(from: context, to: overlay.context)` carries
  /// into a panel.
  ///
  /// A portalled panel renders in the host's layer, not under the subtree
  /// that opened it, so the scopes' wrapper attributes around [context] no
  /// longer reach it. A popover, menu, tooltip, hover card or dialog passes
  /// its panel through here, built where it was opened, and mounts what this
  /// returns: the panel inside scopes stating the brightness and the tier of
  /// the place it opened from.
  ///
  /// A drawer is not passed through here: it renders in the brightness and
  /// at the tier around the host it mounts on, as the Flutter drawer route
  /// builds its panel without capturing the theme of the place it was
  /// opened.
  ///
  /// Each wrapper is there whenever the nearest scope of its kind above
  /// [context] sits below this host, whatever that scope states — a wrapper
  /// that came and went with the value would remount an open panel and lose
  /// its focus and input state. A scope around the host already reaches the
  /// host's layers, so a panel opened under it gets no wrapper for it.
  /// `null` — a closed panel — stays `null`.
  Component? capture(BuildContext context, Component? panel) {
    if (panel == null) return null;
    final host = context
        .getElementForInheritedComponentOfExactType<OverlayPortal>();
    if (host == null) return panel;
    final tier = typographyTierBetween(context, host);
    final brightness = brightnessBetween(context, host);
    final tiered = tier == null
        ? panel
        : TypographyTierScope(tier: tier, child: panel);

    return brightness == null
        ? tiered
        : BrightnessScope(brightness: brightness, child: tiered);
  }

  @override
  bool updateShouldNotify(covariant OverlayPortal oldComponent) {
    return controller != oldComponent.controller;
  }
}
