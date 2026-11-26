import 'dart:io';

import 'package:test/test.dart';

import '../src/baseline/allowlist.dart';
import '../src/baseline/artifact_name.dart';
import '../src/baseline/baseline_store.dart';
import '../src/baseline/parity_platform.dart';
import '../src/baseline/parity_signal.dart';
import '../src/baseline/promoter.dart';

void main() {
  group('ArtifactName.tryParse', () {
    test('키·플랫폼·신호를 분해한다', () {
      final parsed = ArtifactName.tryParse('dialog-default-dark.flutter.png');

      expect(parsed?.key, 'dialog-default-dark');
      expect(parsed?.platform, ParityPlatform.flutter);
      expect(parsed?.signal, ParitySignal.pixel);
    });

    test('motion.json 을 json 보다 먼저 대조한다', () {
      // 확장자가 짧은 것부터 보면 모션 산출물이 속성으로 잘못 분류된다.
      final parsed = ArtifactName.tryParse('k.web.motion.json');

      expect(parsed?.signal, ParitySignal.motion);
      expect(parsed?.key, 'k');
      expect(
        ArtifactName.tryParse('k.web.json')?.signal,
        ParitySignal.property,
      );
    });

    test('규칙에 안 맞으면 null', () {
      expect(ArtifactName.tryParse('README.md'), isNull);
      expect(ArtifactName.tryParse('k.android.png'), isNull);
      expect(ArtifactName.tryParse('.flutter.png'), isNull);
    });

    test('파일 이름으로 되돌아간다', () {
      const name = 'card-outlined.web.json';

      expect(ArtifactName.tryParse(name)?.fileName, name);
    });
  });

  group('BaselinePromoter', () {
    late Directory root;
    late BaselineStore store;

    setUp(() {
      root = Directory.systemTemp.createTempSync('coui_parity_promote_');
      Directory(
        '${root.path}/${BaselineStore.capturedDirName}',
      ).createSync(recursive: true);
      Directory(
        '${root.path}/${BaselineStore.baselineDirName}',
      ).createSync(recursive: true);
      store = BaselineStore(root: root, allowlist: Allowlist.empty);
    });

    tearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });

    void writeCaptured(String fileName, String contents) {
      File(
        '${root.path}/${BaselineStore.capturedDirName}/$fileName',
      ).writeAsStringSync(contents);
    }

    void writeBaseline(String fileName, String contents) {
      File(
        '${root.path}/${BaselineStore.baselineDirName}/$fileName',
      ).writeAsStringSync(contents);
    }

    String baselineContents(String fileName) => File(
      '${root.path}/${BaselineStore.baselineDirName}/$fileName',
    ).readAsStringSync();

    test('추가 · 변경 · 동일을 분류한다', () {
      writeCaptured('new.flutter.json', 'fresh');
      writeCaptured('moved.flutter.json', 'after');
      writeBaseline('moved.flutter.json', 'before');
      writeCaptured('same.flutter.json', 'identical');
      writeBaseline('same.flutter.json', 'identical');

      final result = BaselinePromoter(store).promote();

      expect(result.added.map((item) => item.artifact.key), <String>['new']);
      expect(result.changed.map((item) => item.artifact.key), <String>[
        'moved',
      ]);
      expect(result.unchanged.map((item) => item.artifact.key), <String>[
        'same',
      ]);
      expect(baselineContents('moved.flutter.json'), 'after');
      expect(baselineContents('new.flutter.json'), 'fresh');
    });

    test('동일 항목은 writtenPaths 에 들어가지 않는다', () {
      writeCaptured('same.flutter.json', 'x');
      writeBaseline('same.flutter.json', 'x');

      final result = BaselinePromoter(store).promote();

      expect(result.writtenPaths, isEmpty);
      expect(result.hasWrites, isFalse);
    });

    test('단일 모드는 그 키만 승격한다', () {
      writeCaptured('wanted.flutter.json', 'a');
      writeCaptured('other.flutter.json', 'b');

      final result = BaselinePromoter(store).promote(onlyKey: 'wanted');

      expect(result.items, hasLength(1));
      expect(result.items.single.artifact.key, 'wanted');
      expect(
        File(
          '${root.path}/${BaselineStore.baselineDirName}/other.flutter.json',
        ).existsSync(),
        isFalse,
      );
    });

    test('dry-run 은 분류만 하고 파일을 쓰지 않는다', () {
      writeCaptured('k.flutter.json', 'new');
      writeBaseline('k.flutter.json', 'old');

      final result = BaselinePromoter(store).promote(dryRun: true);

      expect(result.changed, hasLength(1));
      expect(baselineContents('k.flutter.json'), 'old');
    });

    test('이름 규칙에 안 맞는 파일은 조용히 무시하지 않고 보고한다', () {
      // 캡처가 이름을 잘못 붙이면 승격이 "0건 성공" 으로 보이면서 실제로는
      // 아무것도 갱신되지 않는다.
      writeCaptured('typo.flutterr.png', 'x');
      writeCaptured('ok.flutter.png', 'y');

      final result = BaselinePromoter(store).promote();

      expect(result.skipped, <String>['typo.flutterr.png']);
      expect(result.added, hasLength(1));
    });

    test('captured 디렉터리가 없으면 명확히 실패한다', () {
      Directory('${root.path}/${BaselineStore.capturedDirName}').deleteSync();

      expect(
        () => BaselinePromoter(store).promote(),
        throwsA(
          isA<PromotionUnavailable>().having(
            (error) => error.message,
            'message',
            contains('캡처'),
          ),
        ),
      );
    });

    group('커밋 메시지', () {
      test('변경 항목은 지문 전후를 함께 싣는다', () {
        // 리뷰어가 커밋만 보고도 무엇이 바뀌었는지 알아야 한다.
        writeCaptured('k.flutter.json', 'after');
        writeBaseline('k.flutter.json', 'before');

        final result = BaselinePromoter(store).promote();
        final message = result.commitMessage();
        final before = BaselineStore.fingerprintOfString('before');
        final after = BaselineStore.fingerprintOfString('after');

        expect(message, contains('변경 1'));
        expect(message, contains('k.flutter.json'));
        expect(message, contains(before.substring(0, 12)));
        expect(message, contains(after.substring(0, 12)));
      });

      test('전체·단일 모드가 제목에 드러난다', () {
        writeCaptured('k.flutter.json', 'x');

        final result = BaselinePromoter(store).promote();

        expect(
          result.commitMessage(),
          startsWith('chore(parity): baseline 승격 (전체)'),
        );
        expect(result.commitMessage(onlyKey: 'k'), contains('(`k`)'));
      });

      test('건너뛴 파일도 메시지에 남는다', () {
        writeCaptured('bad-name.txt', 'x');
        writeCaptured('k.flutter.json', 'y');

        final message = BaselinePromoter(store).promote().commitMessage();

        expect(message, contains('건너뜀'));
        expect(message, contains('bad-name.txt'));
      });
    });
  });
}
