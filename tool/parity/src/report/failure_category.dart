/// The six failure buckets `report.dart` (#3617) classifies every parity
/// failure into.
///
/// "실패했다"만 알고 "왜"를 모르면 개발자는 원인 규명 대신 allowlist 로
/// 우회하는 쪽을 택한다 — 그 순간 게이트는 형식만 남는다. 카테고리 자체가
/// 원인의 1차 진단이 되도록, 매 실패는 반드시 이 여섯 중 하나로 분류된다
/// (분류 불가능한 "기타" 버킷은 없다 — `motion_failure_classifier.dart`
/// 참조).
enum FailureCategory {
  /// 동일 플랫폼(this run vs 커밋된 baseline) 픽셀 diff 가 임계 초과 —
  /// 승인되지 않았거나 승인 지문과 다른 새 변경.
  regression('regression', '동일 플랫폼 vs baseline 픽셀 초과'),

  /// 교차 플랫폼 정규화 렌더 속성(computed style)이 다르다 — 어느
  /// 필드가 어떻게 다른지가 `ClassifiedFailure.summary` 에 구조화되어
  /// 실린다.
  parityProperty('parity-property', '교차 플랫폼 속성 불일치'),

  /// 픽셀 diff 가 교차 플랫폼 임계를 초과. 속성 비교의 실행 여부와
  /// 측정 결과는 `ClassifiedFailure.summary` 에 따로 기록한다.
  parityPixel('parity-pixel', '교차 플랫폼 픽셀 초과'),

  /// 애니메이션이 있어야 하는 자리에 즉시 종료/즉시 언마운트만 관측됨.
  motionMissing('motion-missing', '애니메이션 부재 (transition 0s / 즉시 언마운트)'),

  /// 애니메이션 자체는 존재하지만 duration·easing 이 토큰과 다르다.
  motionTiming('motion-timing', 'duration·easing 토큰 불일치'),

  /// allowlist 승인은 있었으나 만료됨.
  allowlistExpired('allowlist-expired', '승인 만료');

  const FailureCategory(this.wireName, this.description);

  /// PR 코멘트/콘솔 요약에 그대로 실리는 짧은 식별자 — 이슈 본문의
  /// 6-카테고리 표에 적힌 이름과 1:1.
  final String wireName;

  /// 사람이 읽는 한 줄 설명.
  final String description;

  /// 알 수 없는 이름이면 `null`.
  static FailureCategory? tryParse(String raw) {
    for (final category in FailureCategory.values) {
      if (category.wireName == raw) return category;
    }
    return null;
  }
}
