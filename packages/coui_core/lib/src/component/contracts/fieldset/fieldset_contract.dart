/// Platform-independent contract for fieldset components.
///
/// Defines the interface that all fieldset implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/fieldset/fieldset_style.dart';
import 'package:coui_core/src/component/contracts/fieldset/fieldset_variant.dart';
import 'package:coui_core/src/size/component_size.dart';

/// Contract for a fieldset component — a grouped form section container.
///
/// Per Epic #1302, every chrome / dimensional / nested-slot override
/// flows through the single [fieldsetStyle] field (a
/// [CoreFieldsetStyle]); the contract keeps only semantic / behaviour /
/// composition fields flat.
///
/// Type parameter:
/// - [W] platform widget (`Widget` for Flutter, `Component` for Web).
abstract interface class CoreFieldsetContract<W> {
  /// Optional legend/title displayed at the top of the fieldset.
  W? get legend;

  /// Optional short description under the legend — the secondary line that
  /// says what the group is for. Drawn only when stated.
  W? get description;

  /// Child widgets grouped inside the fieldset.
  List<W> get children;

  /// Whether the fieldset and its children are enabled.
  bool get enabled;

  /// How the group's boundary is drawn — a panel (`filled`, the default),
  /// the hairline edge alone (`outlined`), or no box (`plain`). Selects the
  /// box row from [CoreFieldsetStyle.defaultsByVariant].
  CoreFieldsetVariant get variant;

  /// Size tier — selects the legend typography rung from
  /// [CoreFieldsetStyle.defaultsBySize] (`md`/`lg` are the
  /// canvas-confirmed pivots; the rest extend to the nearest one).
  CoreComponentSize get size;

  /// Per-instance composite chrome / dimensional / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreFieldsetTheme.style
  ///   → CoreFieldsetTheme.variantStyles[variant]
  ///   → parent component slot override
  ///   → widget.fieldsetStyle
  /// ```
  CoreFieldsetStyle? get fieldsetStyle;
}
