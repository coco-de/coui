/// Platform-independent null-row handling for `DescriptionCard`.
library;

/// Null 값 행 처리 방식.
enum CoreDescriptionCardEmptyBehavior {
  /// Null 행 숨기기.
  hide,

  /// Placeholder 텍스트 표시.
  placeholder,
}
