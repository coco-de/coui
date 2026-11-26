/// Theme data for `TextArea` customisation.
library;

import 'package:coui_core/src/component/contracts/text_area/text_area_style.dart';
import 'package:coui_core/src/component/contracts/text_field/text_field_variant.dart';
import 'package:meta/meta.dart';

/// Project-level theme overrides for `TextArea`.
///
/// Holds the project [style] applied to every `TextArea` whose
/// widget-level `textAreaStyle` is null, plus optional [variantStyles]
/// keyed by the field's error state — `true` only while the area has
/// `errorText` **and** is enabled (`disabled > error`, see
/// [CoreTextFieldVariant.showsErrorChrome]).
///
/// 시각 chrome 은 전부 [style] / [variantStyles] 슬롯으로만 흐른다
/// (style-contract.md "CoreXxxTheme — style + variantStyles 슬롯만").
/// 프로젝트 단위 에러 chrome·에러 메시지 오버라이드는 [variantStyles] 의
/// `true` 엔트리에 둔다. disabled 영역은 에러가 있어도 박스 chrome 에 그
/// 행을 쓰지 않지만, 에러 메시지 스타일(`errorStyle` / `errorTextColor`)
/// 은 계속 그 행에서 읽는다. 입력 정책 boolean (autocorrect / selection /
/// cursor blink / IME) 같은 behaviour 기본값은 Theme 이 아니라 Contract 의
/// `static const` (`CoreTextAreaContract.defaultXxx`) 단일 출처에서 온다.
///
/// ### Resolve chain.
///
/// ```text
/// design system default
///   → CoreTextAreaTheme.style                       // 프로젝트 공통
///   → CoreTextAreaTheme.variantStyles[showsError]    // hasError && enabled
///   → parent component slot override
///   → widget per-instance textAreaStyle
/// ```
@immutable
class CoreTextAreaTheme {
  /// Creates a [CoreTextAreaTheme].
  const CoreTextAreaTheme({this.style, this.variantStyles});

  /// Project-level base style. `null` → no project override.
  final CoreTextAreaStyle? style;

  /// Per-error-state override styles, merged on top of [style]. `true`
  /// is looked up only while the area has `errorText` and is enabled
  /// (`disabled > error`). A disabled area with `errorText` still reads
  /// the `true` entry's `errorStyle` / `errorTextColor` for its error
  /// message; its box chrome reads the `false` entry.
  final Map<bool, CoreTextAreaStyle>? variantStyles;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoreTextAreaTheme &&
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
