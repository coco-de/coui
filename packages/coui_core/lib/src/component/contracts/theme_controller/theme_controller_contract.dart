/// Platform-independent contract for theme controller components.
///
/// Defines the interface that all theme controller implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/color/core_color.dart';
import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/theme_controller/theme_controller_style.dart';
import 'package:coui_core/src/component/contracts/theme_controller/theme_controller_size.dart';
import 'package:meta/meta.dart';

/// A single selectable theme entry in a `ThemeController`.
///
/// Each option is identified by its [name] and previews up to four
/// palette colours. Platform-neutral — colours are [CoreColor] so the
/// same option list works on Flutter and Web.
@immutable
class CoreThemeOption {
  /// Creates a [CoreThemeOption].
  const CoreThemeOption({
    required this.name,
    required this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    this.neutralColor,
    this.enabled = true,
  });

  /// The theme name — also the identifier passed to `onThemeChanged`.
  final String name;

  /// The primary palette colour preview.
  final CoreColor primaryColor;

  /// The optional secondary palette colour preview.
  final CoreColor? secondaryColor;

  /// The optional accent palette colour preview.
  final CoreColor? accentColor;

  /// The optional neutral palette colour preview.
  final CoreColor? neutralColor;

  /// Whether this one theme can be picked.
  ///
  /// Separate from the control's own `enabled`, and the scopes are what
  /// make them two things rather than one: the control's flag locks the
  /// whole group (a form section is read-only), this one locks a single
  /// theme (a plan does not include it). A locked swatch keeps its
  /// place in the row — it is still a theme that exists — and states so
  /// by discarding its palette colours.
  final bool enabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreThemeOption &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          primaryColor == other.primaryColor &&
          secondaryColor == other.secondaryColor &&
          accentColor == other.accentColor &&
          neutralColor == other.neutralColor &&
          enabled == other.enabled;

  @override
  int get hashCode => Object.hash(
    name,
    primaryColor,
    secondaryColor,
    accentColor,
    neutralColor,
    enabled,
  );
}

/// Contract for a theme controller component.
///
/// `ThemeController` renders a grid of selectable theme swatches —
/// each shows the theme's palette colours and reports selection through
/// [onThemeChanged].
///
/// The behaviour / semantic fields (`themes` / `selectedTheme` /
/// `onThemeChanged` / `variant`) stay flat on the widget. All chrome /
/// dimensional overrides flow through [themeControllerStyle].
abstract interface class CoreThemeControllerContract {
  /// The selectable theme options, in display order.
  List<CoreThemeOption> get themes;

  /// The name of the currently selected theme, or `null` for none.
  String? get selectedTheme;

  /// Called with the option [CoreThemeOption.name] when the user picks
  /// a theme.
  CoreValueChanged<String> get onThemeChanged;

  /// The visual variant of the theme controller.
  CoreThemeControllerSize get size;

  /// Whether the whole control is interactive.
  ///
  /// Locks every swatch at once — distinct from
  /// [CoreThemeOption.enabled], which locks one.
  bool get enabled;

  /// Per-instance theme controller chrome / dimensional style.
  CoreThemeControllerStyle? get themeControllerStyle;
}
