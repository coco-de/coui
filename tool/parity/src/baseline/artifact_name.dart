import 'parity_platform.dart';
import 'parity_signal.dart';

/// `<key>.<platform>.<ext>` 형태의 산출물 파일 이름.
///
/// baseline 과 captured 가 같은 규칙을 쓴다 — 승격이 단순 복사가 되려면
/// 두 디렉터리의 이름 규칙이 갈리면 안 된다.
class ArtifactName {
  const ArtifactName({
    required this.key,
    required this.platform,
    required this.signal,
  });

  /// 규칙에 맞지 않으면 `null`.
  ///
  /// 확장자가 긴 것부터 대조한다 — `motion.json` 을 `json` 보다 먼저 보지
  /// 않으면 모션 산출물이 속성 산출물로 잘못 분류된다.
  static ArtifactName? tryParse(String fileName) {
    final signals = <ParitySignal>[...ParitySignal.values]
      ..sort(
        (a, b) => b.fileExtension.length.compareTo(a.fileExtension.length),
      );

    for (final signal in signals) {
      for (final platform in ParityPlatform.values) {
        final suffix = '.${platform.wireName}.${signal.fileExtension}';
        if (fileName.endsWith(suffix) && fileName.length > suffix.length) {
          return ArtifactName(
            key: fileName.substring(0, fileName.length - suffix.length),
            platform: platform,
            signal: signal,
          );
        }
      }
    }

    return null;
  }

  final String key;
  final ParityPlatform platform;
  final ParitySignal signal;

  /// 파일 이름으로 되돌린다.
  String get fileName => '$key.${platform.wireName}.${signal.fileExtension}';

  @override
  String toString() => fileName;
}
