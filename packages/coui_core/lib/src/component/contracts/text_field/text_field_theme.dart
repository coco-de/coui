/// Theme data for `TextField` customisation.
library;

import 'package:coui_core/src/component/contracts/text_field/text_field_style.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `TextField`.
///
/// Holds the project [style] applied to every `TextField` whose
/// widget-level `textFieldStyle` is null, plus optional [variantStyles]
/// keyed by [CoreTextFieldVariant] for variant-specific overrides
/// (looked up by [CoreTextFieldVariant.of] — `error` only while the field
/// has `errorText` **and** is enabled: `disabled > error`).
///
/// 시각 chrome 은 전부 [style] / [variantStyles] 슬롯으로만 흐른다
/// (style-contract.md "CoreXxxTheme — style + variantStyles 슬롯만").
/// 프로젝트 단위 에러 chrome·에러 메시지 오버라이드는
/// `variantStyles[CoreTextFieldVariant.error]` 에 둔다. disabled 필드는
/// 에러가 있어도 박스 chrome 에 그 행을 쓰지 않지만, 에러 메시지 스타일
/// (`errorStyle` / `errorColor`) 은 계속 그 행에서 읽는다. 입력 정책 boolean (autocorrect /
/// selection / cursor blink / IME) 같은 behaviour 기본값은 Theme 이
/// 아니라 Contract 의 `static const` (`CoreTextFieldContract.defaultXxx`)
/// 단일 출처에서 온다.
///
/// ### Resolve chain.
///
/// ```text
/// design system default for variant
///   → CoreTextFieldTheme.style                          // 프로젝트 공통
///   → CoreTextFieldTheme.variantStyles[variant]         // CoreTextFieldVariant.of
///   → parent component slot override
///   → widget per-instance textFieldStyle
/// ```
@immutable
class CoreTextFieldTheme {
  /// Creates a [CoreTextFieldTheme].
  const CoreTextFieldTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreTextFieldStyle? style;

  /// Per-variant override styles. Looked up by the field's resolved
  /// [CoreTextFieldVariant] ([CoreTextFieldVariant.of] — `error` only
  /// while the field has `errorText` and is enabled), merged on top of
  /// [style]. A disabled field with `errorText` still reads the `error`
  /// entry's `errorStyle` / `errorColor` for its error message; its box
  /// chrome reads the entry for its non-error variant.
  final Map<CoreTextFieldVariant, CoreTextFieldStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTextFieldTheme &&
          runtimeType == other.runtimeType &&
          style == other.style &&
          _mapEquals(variantStyles, other.variantStyles);

  @override
  int get hashCode => Object.hash(style, variantStyles);

  static bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
