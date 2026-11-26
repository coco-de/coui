/// Theme overrides for the unified footer.
library;

import 'package:coui_core/src/component/contracts/footer/footer_style.dart';
import 'package:meta/meta.dart';

/// Project-level style overrides for a unified footer.
///
/// Mirrors the Core scheme of other component themes — platform-agnostic
/// values that both Flutter and Web consume through their respective
/// `resolveFooter` helpers.
///
/// One slot, no `variantStyles` map: `Footer` has no variant enum to key
/// one by. Its one axis is [CoreFooterStyle.layout], and that is a style
/// field rather than a variant — the layouts are the same footer arranged
/// differently, not chrome sets a project would tone separately, so a
/// per-layout override map would have nothing distinct to hold
/// (style-contract.md "variant enum 이 아예 없는 컴포넌트만 `variantStyles`
/// 를 생략하고 `style` 단일 슬롯").
///
/// Chrome (background / text colour / padding / block and row spacing) and
/// the nested text / `Divider` / `Collapsible` slots all flow through the
/// composite [style] slot — see [CoreFooterStyle].
@immutable
class CoreFooterTheme {
  /// Creates a [CoreFooterTheme].
  const CoreFooterTheme({
    this.style,
  });

  /// Project-wide composite style applied to every `Footer`.
  ///
  /// Resolved before any per-instance `widget.footerStyle`. A `layout`
  /// set here applies only when the caller left `Footer(layout:)` null —
  /// the widget prop wins, so a project default cannot stomp a caller
  /// that asked for a particular arrangement.
  final CoreFooterStyle? style;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CoreFooterTheme && other.style == style;
  }

  @override
  int get hashCode => style.hashCode;
}
