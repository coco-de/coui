/// Platform-independent contract for unified FAB components.
///
/// Defines the interface that all `Fab` implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/fab/fab_action.dart';
import 'package:coui_core/src/component/contracts/fab/fab_expand_direction.dart';
import 'package:coui_core/src/component/contracts/fab/fab_size.dart';
import 'package:coui_core/src/component/contracts/fab/fab_style.dart';
import 'package:coui_core/src/component/contracts/menu_item/menu_item_size.dart';
import 'package:coui_core/src/size/component_size.dart';

/// Contract for a unified Floating Action Button component.
///
/// Every chrome / dimensional override flows through the single
/// [fabStyle] field — see [CoreFabStyle] for the merge chain. Semantic
/// fields (`expandDirection`) and behaviour
/// fields (`trigger` / `actions` / `onPressed` / `open` /
/// `onOpenChanged`) stay flat on the contract.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
abstract interface class CoreFabContract<W> {
  /// The composed `MenuItem` size every speed-dial action row takes.
  ///
  /// The FAB is a phone pattern and its rows are tapped with a thumb, so
  /// they sit on the touch-target rung: `lg`, the 48px row of the
  /// `MenuItem` ladder. The size is chosen from the ladder rather than
  /// stated as a height because the ladder's height is a **minimum** — a
  /// larger text scale has to be able to grow the row.
  ///
  /// This is the ladder row every size starts from. What differs by the
  /// FAB's own [size] — the insets, icon, gap and label, and a taller row
  /// for `large` — is stated in `CoreFabStyle.defaultsBySize`, which never
  /// takes a row below this height.
  ///
  /// Both platform widgets read this constant (stating it on one side only
  /// would let the two drift silently).
  static const CoreMenuItemSize actionItemSize = CoreMenuItemSize.lg;

  /// The composed `Button` size the action rows took while they were
  /// `Button(variant: .menu)` rows. Nothing reads it — the rows are
  /// `MenuItem` rows at [actionItemSize].
  @Deprecated(
    'Use actionItemSize (since 0.164) — the action rows are MenuItem rows '
    'now, sized on the MenuItem ladder.',
  )
  static const CoreComponentSize actionButtonSize = CoreComponentSize.lg;

  /// The main, always-visible content of the FAB (typically an icon).
  W get trigger;

  /// Optional label beside [trigger] — its presence makes this an
  /// **Extended** FAB.
  ///
  /// `null` 이면 원형, non-null 이면 라벨을 가진 알약이다. 별도 boolean 을
  /// 두지 않는 것은 라벨의 유무가 곧 그 결정이기 때문이다.
  ///
  /// [actions] 와 함께 쓸 수 없다 — 라벨이 이미 액션을 특정했는데 다시
  /// 액션 목록을 여는 것은 의미가 겹친다. 양 플랫폼 생성자가 assert 로
  /// 막는다.
  W? get label;

  /// Callback when the main FAB is pressed.
  ///
  /// When [actions] is non-empty, pressing the FAB toggles the speed
  /// dial instead of invoking this callback.
  ///
  /// `CoreVoidCallback` is structurally identical to the Flutter
  /// `VoidCallback` (`void Function()`), so the Flutter `Fab` can
  /// keep its native callback type when overriding.
  CoreVoidCallback? get onPressed;

  /// The list of speed-dial actions.
  ///
  /// When non-empty, the FAB acts as a speed-dial trigger.
  List<CoreFabAction<W>>? get actions;

  /// Whether the speed dial is currently open.
  bool get open;

  /// Callback invoked when the speed-dial open state should change.
  CoreValueChanged<bool>? get onOpenChanged;

  /// Size of the FAB.
  CoreFabSize get size;

  /// Direction in which the speed-dial actions expand.
  CoreFabExpandDirection get expandDirection;

  /// Content shown inside the FAB while the speed dial is open.
  ///
  /// When `null` a close (X) icon is rendered.
  W? get closeIcon;

  /// Tooltip text shown for the main FAB.
  String? get tooltip;

  /// Per-instance FAB chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default (CoreFabStyle.defaultX)
  ///   → CoreFabTheme.style
  ///   → parent component slot override
  ///   → widget.fabStyle
  /// ```
  CoreFabStyle? get fabStyle;
}
