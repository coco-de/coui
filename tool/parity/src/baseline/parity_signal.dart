/// 비교·승인의 단위가 되는 신호 종류.
///
/// 픽셀만 승인 대상으로 두면 "속성이 바뀐 의도적 변경"을 승인할 방법이 없어
/// 개발자가 게이트를 통째로 우회한다. 그래서 allowlist 는 세 신호 전부에
/// 적용되고, 승인 단위는 픽셀 해시가 아니라 (키, 신호종류, 값 지문) 이다.
enum ParitySignal {
  /// 렌더된 PNG 의 픽셀 비교. baseline 은 Tier1 에만 커밋한다(리포 크기 통제).
  pixel('pixel', 'png'),

  /// 정규화된 렌더 속성 스냅샷(JSON) 비교.
  ///
  /// 1차 신호다 — 확인된 결함이 "같은 토큰인데 렌더만 다른" 유형이라
  /// 교차 플랫폼 픽셀 임계로는 잡히지 않는다. JSON 은 킬로바이트라
  /// baseline 을 전체 컴포넌트에 커밋해도 리포 부담이 없다.
  property('property', 'json'),

  /// 시계열 모션 샘플 비교.
  motion('motion', 'motion.json');

  const ParitySignal(this.wireName, this.fileExtension);

  /// `allowlist.yaml` 의 `signal:` 에 적히는 이름.
  final String wireName;

  /// baseline 파일 확장자 — `<key>.<platform>.<fileExtension>`.
  final String fileExtension;

  /// 알 수 없는 이름이면 `null` 을 돌려준다.
  ///
  /// 던지지 않는 이유는 호출자가 "몇 번째 항목인지·어느 파일인지" 를 붙여
  /// 훨씬 유용한 메시지를 만들 수 있기 때문이다.
  static ParitySignal? tryParse(String raw) {
    for (final signal in ParitySignal.values) {
      if (signal.wireName == raw) {
        return signal;
      }
    }
    return null;
  }

  /// 오류 메시지에 쓰는 허용값 목록.
  static String get wireNames =>
      ParitySignal.values.map((signal) => signal.wireName).join(' | ');
}
