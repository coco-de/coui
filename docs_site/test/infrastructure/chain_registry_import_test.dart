import 'dart:io';

import 'package:test/test.dart';

/// Flutter chain registry 의 **클라이언트 경로 전용** 계약을 게이트한다.
///
/// registry 는 Flutter Widget(→ `dart:ui`)을 나르므로 SSG(서버) 경로가
/// import 하면 정적 빌드가 깨진다. 허용된 유일한 소비자는 임베드 위젯
/// (`lib/widgets/preview_app.dart`) — `@Import.onWeb` 뒤의 web-only
/// 컴파일 경로다. 새 파일이 실수로 import 하면 여기서 먼저 깨진다.
void main() {
  test('flutter_chain_registry 는 preview_app 만 import 한다', () {
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.endsWith('lib/widgets/preview_app.dart')) continue;
      if (file.readAsStringSync().contains('flutter_chain_registry')) {
        offenders.add(file.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'dart:ui 를 나르는 registry 가 서버 경로에 유입됐다',
    );
  });
}
