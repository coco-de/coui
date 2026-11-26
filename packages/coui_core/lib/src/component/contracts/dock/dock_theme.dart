/// Theme overrides for Dock.
library;

import 'package:coui_core/src/component/contracts/dock/dock_style.dart';
import 'package:meta/meta.dart';

/// Project-level style overrides for `Dock`.
///
/// 시각 chrome 은 전부 [style] 슬롯으로만 흐른다 (style-contract.md
/// "CoreXxxTheme — style + variantStyles 슬롯만"). `Dock` has no
/// variant enum, so only the [style] slot is present. The semantic
/// `size` identifier is **widget-only** — a theme override of a semantic
/// identifier would stomp the caller's `size:` and split Flutter from Web
/// (which already resolves `size` from the widget), so it is not carried
/// here.
///
/// ### Resolve chain.
///
/// ```text
/// design system default (CoreDockStyle.defaultX / defaultsBySize[size])
///   → CoreDockTheme.style                       // 프로젝트 공통
///   → parent component slot override
///   → widget.dockStyle                          // 인스턴스별
/// ```
@immutable
class CoreDockTheme {
  /// Creates a [CoreDockTheme].
  const CoreDockTheme({this.style});

  /// Project-wide composite style applied to every `Dock`.
  ///
  /// Resolved before any per-instance `widget.dockStyle`.
  final CoreDockStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreDockTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
