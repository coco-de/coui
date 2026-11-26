/// Platform-independent value overflow handling for `DescriptionCard`.
library;

/// `DescriptionCard` 값 텍스트 오버플로우 처리.
enum CoreDescriptionCardOverflow {
  /// 줄바꿈.
  wrap,

  /// 말줄임표.
  ellipsis,
}
