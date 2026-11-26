import 'package:coui_core/src/component/contracts/mockup/mockup_browser_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `MockupBrowser`.
///
/// All fields flow through [style]. The shared `CoreMockupTheme.style`
/// applies cross-variant defaults (background / border / borderRadius)
/// for project-wide mockup recolouring.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreMockupTheme.style (shared cross-variant)
///   → CoreMockupBrowserTheme.style                    // 프로젝트 공통
///   → parent component slot override
///   → widget per-instance mockupBrowserStyle
/// ```
@immutable
class CoreMockupBrowserTheme {
  /// Creates a [CoreMockupBrowserTheme].
  const CoreMockupBrowserTheme({this.style});

  /// Project-wide composite style applied to every `MockupBrowser`.
  ///
  /// Resolved before any per-instance `widget.mockupBrowserStyle`.
  final CoreMockupBrowserStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreMockupBrowserTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
