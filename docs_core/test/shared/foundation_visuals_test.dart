import 'dart:io';

import 'package:docs_core/shared/docs_navigation.dart';
import 'package:docs_core/shared/foundation_visuals.dart';
import 'package:flutter_test/flutter_test.dart';

/// 콘텐츠의 `<FoundationVisual kind="…" />` 와 그 그림이 읽는 값의 계약.
///
/// 사이트와 앱은 모르는 `kind` 를 조용히 건너뛴다. 오타 하나가 그림 한 칸을
/// 두 표면에서 함께 지우므로, 콘텐츠가 쓰는 값이 전부 알려진 종류인지 여기서
/// 본다. 반대로 콘텐츠가 쓰지 않는 종류는 아무도 읽지 않는 그림이다.
void main() {
  final pattern = RegExp(r'<FoundationVisual\s+kind="([^"]*)"');

  List<String> usedKinds() => [
    for (final file in Directory('content').listSync(recursive: true))
      if (file is File && file.path.endsWith('.md'))
        for (final match in pattern.allMatches(file.readAsStringSync())) match.group(1)!,
  ];

  test('콘텐츠가 쓰는 kind 는 전부 알려진 종류다', () {
    final unknown = usedKinds().where((kind) => FoundationVisualKind.parse(kind) == null);

    expect(unknown, isEmpty);
  });

  test('모든 종류를 콘텐츠가 한 번 이상 쓴다', () {
    final used = usedKinds().toSet();
    final unused = [
      for (final kind in FoundationVisualKind.values)
        if (!used.contains(kind.attribute)) kind.attribute,
    ];

    expect(unused, isEmpty);
  });

  test('개요의 설명은 Foundations 탭의 페이지마다 하나씩 있다', () {
    final pages = docsNavTabFor('/tokens/overview').pages.map((page) => page.path).toSet();

    expect(kFoundationTopicDescriptions.keys.toSet(), pages.difference({'/tokens/overview'}));
  });

  test('브랜드 예제의 색은 그 색 소스가 라이트 모드에서 만드는 값이다', () {
    for (final sample in kBrandSamples) {
      final colors = foundationBrandColors(sample.brandColor);

      expect(colors.primary.argb, isNot(colors.onPrimary.argb), reason: sample.label);
      // 토큰 이름을 들고 있으면 Web 이 페이지 테마의 primary 로 칠한다.
      expect(colors.primary.token, isNull, reason: sample.label);
      expect(colors.onPrimary.token, isNull, reason: sample.label);
    }
  });

  test('cubic-bezier 값은 소수점 없는 정수를 그대로 쓴다', () {
    expect(foundationCubicBezier((x1: 0.42, y1: 0, x2: 0.58, y2: 1)), '0.42, 0, 0.58, 1');
  });

  test('아이콘 수는 천 단위로 쉼표를 찍는다', () {
    expect(foundationCount(5355), '5,355');
    expect(foundationCount(332), '332');
    expect(foundationCount(1234567), '1,234,567');
  });
}
