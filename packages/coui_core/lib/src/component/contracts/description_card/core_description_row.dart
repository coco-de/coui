/// Platform-independent row data for `DescriptionCard`.
library;

import 'package:coui_core/src/typography/text_style_token.dart';

/// `DescriptionCard`의 개별 행 데이터.
///
/// Per-row text overrides flow through nested [CoreTextStyle] slots
/// ([labelTextStyle] / [valueTextStyle]) — full typographic surface
/// (`fontSize` / `fontWeight` / `letterSpacing` / `color`).
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
class CoreDescriptionRow<W> {
  /// Creates a [CoreDescriptionRow].
  const CoreDescriptionRow({
    required this.label,
    this.value,
    this.valueWidget,
    this.leading,
    this.trailing,
    this.onTap,
    this.labelTextStyle,
    this.valueTextStyle,
    this.isEmphasized = false,
  });

  /// 라벨 텍스트.
  final String label;

  /// 값 텍스트. null 이면 emptyValueBehavior 적용.
  final String? value;

  /// 커스텀 값 위젯/컴포넌트. [value] 보다 우선.
  final W? valueWidget;

  /// 라벨 앞 위젯/컴포넌트 (아이콘, 배지 등).
  final W? leading;

  /// 값 뒤 위젯/컴포넌트 (메뉴, 편집 아이콘 등).
  final W? trailing;

  /// 행별 탭 콜백.
  final void Function()? onTap;

  /// Per-row label text slot override (full typographic surface).
  /// Layered on top of the card's default/emphasis label slot.
  final CoreTextStyle? labelTextStyle;

  /// Per-row value text slot override (full typographic surface).
  /// Layered on top of the card's default/emphasis value slot.
  final CoreTextStyle? valueTextStyle;

  /// 강조 행 여부.
  final bool isEmphasized;
}
