@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/shared/preview_variants.dart';
import 'package:test/test.dart';

/// `chain="off"` 저자 큐레이션의 **페이지당 chain ≥1 불변식**을 게이트한다.
///
/// opt-out 은 복수-태그 페이지의 chain 중복 노출을 끄는 플래그이지 chain
/// 자체를 끄는 스위치가 아니다 — 한 페이지에서 어떤 chain-capable
/// 컴포넌트의 태그가 **전부** off 면 그 문서에서 chain 표면이 통째로
/// 사라져 "Style 슬롯 보유 전 컴포넌트 문서에서 chain 노출" 계약(AC-1)이
/// 조용히 깨진다. 태그가 `variants` 에 `chain` 을 직접 선언하면 그것도
/// chain 표면으로 센다 (PoC 하네스 형태).
void main() {
  final tagPattern = RegExp(r'<LivePreview\s+([^>]*?)/?>');
  final componentPattern = RegExp(r'component="([a-z0-9-]+)"');
  final variantsPattern = RegExp(r'variants="([^"]*)"');

  test('chain="off" 페이지도 컴포넌트당 chain 표면 ≥1 을 유지한다', () {
    final violations = <String>[];

    for (final file in Directory('content').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.md')) continue;
      final source = file.readAsStringSync();

      // component → (chain 표면 남았는가) — 표면 = off 아님 || chain 직접 선언.
      final hasChainSurface = <String, bool>{};
      for (final tag in tagPattern.allMatches(source)) {
        final attrs = tag.group(1)!;
        final component = componentPattern.firstMatch(attrs)?.group(1);
        if (component == null) continue;
        if (!docsComponentHasChainPreview(component)) continue;

        final declaresChain = (variantsPattern.firstMatch(attrs)?.group(1) ?? '')
            .split(',')
            .map((v) => v.trim())
            .contains('chain');
        final optedOut = attrs.contains('chain="off"');
        hasChainSurface[component] = (hasChainSurface[component] ?? false) || !optedOut || declaresChain;
      }

      for (final entry in hasChainSurface.entries) {
        if (!entry.value) {
          violations.add('${file.path}: ${entry.key} — 전 태그 chain="off"');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          '페이지당 chain ≥1 불변식 위반 — off 하나를 되돌리거나 '
          'chain 선언 태그를 남겨라',
    );
  });
}
