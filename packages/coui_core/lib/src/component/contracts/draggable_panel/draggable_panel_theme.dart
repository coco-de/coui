/// Theme data for DraggablePanel customization.
library;

import 'package:coui_core/src/component/contracts/draggable_panel/draggable_panel_style.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `DraggablePanel`.
///
/// Holds the project [style] applied to every `DraggablePanel` whose
/// widget-level `draggablePanelStyle` is null.
///
/// 시각 chrome 은 전부 [style] 슬롯으로만 흐른다
/// (style-contract.md "CoreXxxTheme — style + variantStyles 슬롯만").
/// `DraggablePanel` 은 chrome variant 가 없어 `variantStyles` 슬롯을
/// 노출하지 않는다 (separator 와 동일). `dockType` 같은 semantic /
/// behaviour 식별자는 **widget-only** — Theme 이 override 하면 caller 의도를
/// 짓밟고 Flutter 가 Web 과 갈라진다.
///
/// ### Resolve chain.
///
/// ```text
/// CoreDraggablePanelStyle.defaultX
///   → CoreDraggablePanelTheme.style              // 프로젝트 공통
///   → widget per-instance draggablePanelStyle
/// ```
@immutable
class CoreDraggablePanelTheme {
  /// Creates a [CoreDraggablePanelTheme].
  const CoreDraggablePanelTheme({this.style});

  /// Project-wide composite style applied to every `DraggablePanel`.
  ///
  /// Resolved before any per-instance `widget.draggablePanelStyle`.
  final CoreDraggablePanelStyle? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDraggablePanelTheme &&
          runtimeType == other.runtimeType &&
          style == other.style;

  @override
  int get hashCode => style.hashCode;
}
