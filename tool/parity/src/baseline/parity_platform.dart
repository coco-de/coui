/// baseline 이 어느 플랫폼의 렌더인지.
///
/// regression 비교는 같은 플랫폼끼리 하고(이번 Flutter 렌더 vs 지난 Flutter
/// baseline), parity 비교는 두 플랫폼끼리 한다. 두 비교가 같은 파일을 보면
/// "회귀" 와 "플랫폼 간 불일치" 가 한 신호로 뭉개지므로 baseline 파일은
/// 플랫폼별로 나뉜다.
enum ParityPlatform {
  flutter('flutter'),
  web('web');

  const ParityPlatform(this.wireName);

  /// baseline 파일명에 들어가는 이름 — `<key>.<wireName>.<ext>`.
  final String wireName;
}
