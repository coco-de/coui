import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String flutterPreviewSource;

  setUpAll(() {
    flutterPreviewSource = File(
      'lib/components/flutter_preview.dart',
    ).readAsStringSync();
  });

  group('FlutterPreview component', () {
    test('uses @client annotation for client-side hydration', () {
      expect(flutterPreviewSource, contains('@client'));
    });

    test('uses @Import.onWeb for conditional Flutter import', () {
      expect(flutterPreviewSource, contains('@Import.onWeb'));
    });

    test('imports PreviewApp widget', () {
      expect(flutterPreviewSource, contains('PreviewApp'));
    });

    test('uses FlutterEmbedView for rendering', () {
      expect(flutterPreviewSource, contains('FlutterEmbedView'));
    });

    test('uses kIsWeb guard for Flutter widget', () {
      expect(flutterPreviewSource, contains('kIsWeb'));
    });

    test('includes PreviewSkeleton as loader', () {
      expect(flutterPreviewSource, contains('PreviewSkeleton'));
    });

    test('generates unique IDs via the shared derivation helper', () {
      // id 파생식은 preview_panel_id.dart 단일 출처다 — 임베드 생성·높이
      // 적용 JS·chain 패널이 같은 함수를 부른다. 여기서 리터럴을 다시
      // 조립하면 세 호출부가 갈라진다.
      expect(flutterPreviewSource, contains('flutterEmbedElementId('));
      expect(
        flutterPreviewSource,
        isNot(contains(r"'flutter-$component-")),
        reason: '파생식 손 복제는 단일 출처를 우회한다',
      );
    });
  });

  group('Constraint categories', () {
    // 제약 티어(5단 값·순서)와 조회 순서(per-variant → chain 하한 →
    // component → 기본값)는 단일 출처인 docs_core 의
    // `shared/preview_constraints.dart`(`docsPreviewConstraintsFor`)가
    // 소유하고 그 패키지의 테스트가 값으로 검증한다. 이 소비자는 그
    // 함수를 조회해 ViewConstraints 로 변환만 해야 한다 — 조회 체인을
    // 손으로 복제하면 Web 팬과 세로가 갈라진다.
    test('resolves constraints via the shared lookup (no local tiers)', () {
      expect(
        flutterPreviewSource,
        contains('docsPreviewConstraintsFor('),
        reason: '공유 조회 함수를 거쳐야 두 팬(Web/Flutter)이 같은 높이를 쓴다',
      );
      expect(
        flutterPreviewSource,
        isNot(matches(RegExp(r'k\w+Constraints\s*=\s*ViewConstraints\('))),
        reason: '로컬 티어 재정의는 공유 단일 출처를 우회한다',
      );
      expect(
        flutterPreviewSource,
        isNot(matches(RegExp(r'\?\?\s*\n?\s*kDocsDefaultConstraints'))),
        reason: '폴백 체인 손 복제는 조회 단일 출처를 우회한다',
      );
    });
  });
}
