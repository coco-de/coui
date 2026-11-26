/// Per-instance style for `DropdownMenu` / `ContextMenu`.
library;

import 'package:coui_core/src/component/contracts/menu/menu_style.dart';
import 'package:coui_core/src/component/core_style.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:meta/meta.dart';

/// Immutable style for a `DropdownMenu` / `ContextMenu`.
///
/// A `DropdownMenu` / `ContextMenu` is a `Menu` shown in a trigger-anchored
/// overlay, so its chrome is the composed `Menu`'s chrome plus the
/// placement gap. Following child-component-composition (nest the *direct*
/// child's `CoreXxxStyle`), this carries the whole [menuStyle]
/// ([CoreMenuStyle] — panel box via `popupStyle`, the per-row `MenuItem`
/// chrome via `itemStyle`, the divider, the heading typography …)
/// raw-forwarded to the inner `Menu`, plus the dropdown-specific placement
/// [menuOffset]. Semantic enums / behaviour live on the widget.
///
/// ```text
/// CoreMenuTheme.style                              // 전역 메뉴 공통
///   → CoreDropdownMenuTheme.style.menuStyle        // 드롭다운/컨텍스트 공통
///   → widget.dropdownMenuStyle.menuStyle           // 인스턴스별
/// ```
@immutable
class CoreDropdownMenuStyle implements CoreStyle<CoreDropdownMenuStyle> {
  /// Creates a [CoreDropdownMenuStyle].
  const CoreDropdownMenuStyle({this.menuStyle, this.menuOffset});

  // ── Design-system defaults ──

  /// Default gap between the trigger and the menu panel along the
  /// placement axis (`bottomStart` → vertical). Web feeds this as the
  /// `OverlayPositioner` gap; Flutter as the `PopoverOverlayHandler`
  /// placement offset. Mirrors `CoreMenubarStyle.defaultMenuOffset`.
  static const double defaultMenuOffset = CoreSpace.space4;

  /// Default partial for the composed `Menu`'s style slot.
  ///
  /// A dropdown / context menu wants the `Menu`'s own chrome unchanged, so
  /// this partial diverges in **nothing** and every field stays null — the
  /// `Menu` resolver fills its own defaults, which is what
  /// `core/style-contract.md` requires of a nested slot ("자식 default 에
  /// reach 하지 마라"). It exists as the named forward point both
  /// resolvers hand to `Menu` (`defaultMenuStyle.merge(merged.menuStyle)`),
  /// so [menuStyle] has the `default*` pair every chrome field owes
  /// (1:1:1:1:1:1) instead of being an orphan field. Fill a field here only
  /// when a dropdown's menu should differ from a standalone `Menu`.
  static const CoreMenuStyle defaultMenuStyle = CoreMenuStyle();

  // ── Slot styles (nested) ──

  /// Style of the `Menu` inside — the whole menu's look: the panel box via
  /// [CoreMenuStyle.popupStyle], each `MenuItem` row via
  /// [CoreMenuStyle.itemStyle], the divider, the heading typography and so
  /// on. Passed to the inner `Menu`'s `menuStyle` as is, where it is laid
  /// over `CoreMenuTheme.style`; `null` leaves the inner `Menu` at its
  /// design-system defaults.
  final CoreMenuStyle? menuStyle;

  /// Per-instance gap between the trigger and the menu panel along the
  /// placement axis — `null` falls back to [defaultMenuOffset]. A single
  /// placement-axis scalar (not a multi-side inset), so it stays a flat
  /// `double` field (mirrors `CoreMenubarStyle.menuOffset`).
  final double? menuOffset;

  /// Returns a copy of this style with non-null fields from [other]
  /// overriding the matching fields here. The nested [menuStyle] slot is
  /// merged recursively.
  @override
  CoreDropdownMenuStyle merge(CoreDropdownMenuStyle? other) {
    if (other == null) return this;
    return CoreDropdownMenuStyle(
      menuStyle: _mergeMenu(menuStyle, other.menuStyle),
      menuOffset: other.menuOffset ?? menuOffset,
    );
  }

  /// Returns a copy of this style with the supplied non-null fields
  /// overridden.
  CoreDropdownMenuStyle copyWith({
    CoreMenuStyle? menuStyle,
    double? menuOffset,
  }) {
    return CoreDropdownMenuStyle(
      menuStyle: menuStyle ?? this.menuStyle,
      menuOffset: menuOffset ?? this.menuOffset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreDropdownMenuStyle &&
          runtimeType == other.runtimeType &&
          menuStyle == other.menuStyle &&
          menuOffset == other.menuOffset;

  @override
  int get hashCode => Object.hash(menuStyle, menuOffset);

  static CoreMenuStyle? _mergeMenu(CoreMenuStyle? base, CoreMenuStyle? other) {
    if (base == null) return other;
    if (other == null) return base;
    return base.merge(other);
  }
}
