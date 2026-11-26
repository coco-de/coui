/// Platform-independent horizontal alignment for `DescriptionCard` rows.
library;

/// 수평 레이아웃의 라벨-값 정렬.
enum CoreDescriptionCardAlignment {
  /// 라벨 너비 고정, 값이 남은 공간 채움.
  fixed,

  /// 라벨과 값을 양 끝에 배치.
  spaceBetween,
}
