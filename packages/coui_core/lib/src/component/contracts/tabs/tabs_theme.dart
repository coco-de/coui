/// Theme overrides for tab components.
library;

import 'package:coui_core/src/component/contracts/tabs/tab_pane_style.dart';
import 'package:coui_core/src/component/contracts/tabs/tab_pane_variant.dart';
import 'package:coui_core/src/component/contracts/tabs/tabs_style.dart';
import 'package:coui_core/src/component/contracts/tabs/tabs_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `Tabs`.
///
/// ### Resolve chain.
///
/// ```text
/// CoreTabsStyle.defaultX / defaultsByVariant   // design system default
///   → CoreTabsTheme.style                      // 프로젝트 공통
///   → CoreTabsTheme.variantStyles[variant]     // 프로젝트 variant 별
///   → widget per-instance tabsStyle            // 인스턴스별
/// ```
@immutable
class CoreTabsTheme {
  /// Creates a [CoreTabsTheme].
  const CoreTabsTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreTabsStyle? style;

  /// Per-variant override styles. `null` → no variant override.
  final Map<CoreTabVariant, CoreTabsStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTabsTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(
    style,
    variantStyles == null ? null : Object.hashAll(variantStyles!.entries),
  );

  static bool _mapEquals(
    Map<CoreTabVariant, CoreTabsStyle>? a,
    Map<CoreTabVariant, CoreTabsStyle>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Project-level theme overrides for `TabPane`.
///
/// ### Resolve chain.
///
/// ```text
/// CoreTabPaneStyle.defaultX / defaultsByVariant   // design system default
///   → CoreTabPaneTheme.style                      // 프로젝트 공통
///   → CoreTabPaneTheme.variantStyles[variant]     // 프로젝트 variant 별
///   → widget per-instance tabPaneStyle            // 인스턴스별
/// ```
@immutable
class CoreTabPaneTheme {
  /// Creates a [CoreTabPaneTheme].
  const CoreTabPaneTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreTabPaneStyle? style;

  /// Per-variant override styles. `null` → no variant override.
  final Map<CoreTabPaneVariant, CoreTabPaneStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTabPaneTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _paneMapEquals(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(
    style,
    variantStyles == null ? null : Object.hashAll(variantStyles!.entries),
  );

  static bool _paneMapEquals(
    Map<CoreTabPaneVariant, CoreTabPaneStyle>? a,
    Map<CoreTabPaneVariant, CoreTabPaneStyle>? b,
  ) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
