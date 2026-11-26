import 'dart:io';

import 'package:docs_core/shared/component_catalog.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../src/manifest/tier1_policy.dart';

/// The tier1-policy literals — group ids, form slugs, and confirmed-defect
/// slugs — that are only allowed to live inside `tier1_policy.dart` itself.
/// A second copy anywhere else in the pipeline is a policy fork: it can
/// drift from the real policy silently, which is exactly the "커버리지가
/// 조용히 얕아지는" failure #3609 exists to prevent.
List<String> _tier1PolicyLiterals() => [
  ...kTier1GroupIds,
  ...kTier1FormSlugs,
  ...kConfirmedDefectSlugs,
];

/// The "~30" band's bounds — wide on purpose (see the test's own comment).
///
/// The band absorbs catalog growth rather than forcing an edit per new
/// component. A component is tier1 when its slug is named in the policy
/// (the surface-marker union, the form slugs, the confirmed-defect list) or
/// when its group is tier1 by group: every entry of the control group is,
/// so a control added to that group (the command palette's trigger) joins
/// tier1 without any slug being named. The upper bound of 70 leaves room
/// for that growth while staying well short of "almost everything".
const int _kTier1SizeLowerBound = 20;
const int _kTier1SizeUpperBound = 70;

void main() {
  test('Tier1 size against the whole catalog is actually ~30, not a guess', () {
    // #3609's completion definition asks this be confirmed "by output" —
    // printed here so a human reading the test run sees the real number,
    // and asserted against a range so a policy change that balloons or
    // guts Tier1 (e.g. a `kTier1GroupIds` typo matching every group) fails
    // the build instead of only showing up in a print nobody reads.
    final tier1Slugs = <String>[
      for (final group in kDocsComponentGroups)
        for (final component in group.items)
          if (isTier1(component.slug, group.id)) component.slug,
    ];
    // #3609 완료 정의가 요구하는 "출력으로 확인" 자체가 이 print 다.
    // ignore: avoid_print
    print('[tier1] ${tier1Slugs.length}개: ${tier1Slugs.join(', ')}');

    // "~30" per the architecture doc's own count (overlay 9 + menu 5 +
    // control 6 + 10 named form slugs + surface-marker holders not already
    // covered + confirmed-defect slugs, with set-union overlap collapsing
    // some of those). A wide band on purpose — the catalog and the policy
    // both grow over time, and this test's job is to catch the policy
    // classifying almost nothing or almost everything, not to pin an exact
    // count that would make catalog growth this test's problem to edit.
    expect(tier1Slugs.length, greaterThanOrEqualTo(_kTier1SizeLowerBound));
    expect(tier1Slugs.length, lessThanOrEqualTo(_kTier1SizeUpperBound));
    expect(tier1Slugs.toSet().length, tier1Slugs.length, reason: '중복 슬러그');
  });

  test(
    'adding a component only requires touching tier1_policy.dart, '
    'not the pipeline',
    () {
      // #3609's completion definition: "새 컴포넌트 추가 시 Tier 정책 파일만
      // (필요하면) 손대고 파이프라인 코드는 안 바뀜". The generic pipeline
      // caller (`ParityManifest._expand`) only ever calls
      // `isTier1(component.slug, group.id)` — if it, or the CLI, also
      // carried a literal copy of a group id / form slug / defect slug,
      // that copy could go stale the moment `tier1_policy.dart` changes
      // without it, and nobody would notice until a component silently
      // ran under the wrong tier.
      final repoRoot = Directory.current.path;
      final literals = _tier1PolicyLiterals();
      const pipelineFiles = [
        'tool/parity/manifest.dart',
        'tool/parity/src/manifest/parity_manifest.dart',
      ];

      for (final relative in pipelineFiles) {
        final file = File(p.join(repoRoot, relative));
        expect(file.existsSync(), isTrue, reason: '$relative 를 찾을 수 없다');
        final source = file.readAsStringSync();
        for (final literal in literals) {
          expect(
            source.contains("'$literal'"),
            isFalse,
            reason:
                "$relative 가 tier1 정책 리터럴 '$literal' 을 직접 참조한다 — "
                'isTier1() 호출로 위임해야 한다.',
          );
        }
      }
    },
  );

  group('isTier1', () {
    test('an entire tier1 group is tier1 regardless of slug', () {
      expect(isTier1('some-future-overlay-component', 'overlay'), isTrue);
      expect(isTier1('some-future-menu-component', 'menu'), isTrue);
      expect(isTier1('some-future-control-component', 'control'), isTrue);
    });

    test(
      'the ten named high-risk form slugs are tier1 '
      'even though `form` as a whole is not',
      () {
        for (final slug in kTier1FormSlugs) {
          expect(isTier1(slug, 'form'), isTrue, reason: slug);
        }
        // A fictional slug, not a real one — every real `form` slug
        // eventually earns a surface marker of its own (#4356/#4361
        // did exactly that to `object-input`, which is why this used
        // to name it), and `isTier1` unions in that separate set. Only
        // a slug nothing will ever mark stays a valid negative example.
        expect(isTier1('some-future-form-component', 'form'), isFalse);
      },
    );

    test('surface-marker holders are tier1 regardless of group', () {
      expect(isTier1('outlined-container', 'infra'), isTrue);
      expect(isTier1('scaffold', 'layout'), isTrue);
    });

    test('confirmed-defect components are always tier1', () {
      expect(isTier1('command', 'control'), isTrue);
      expect(isTier1('date-picker', 'form'), isTrue);
      expect(isTier1('dialog', 'overlay'), isTrue);
    });

    test('an unclassified component falls to tier2, not an error', () {
      expect(isTier1('divider', 'display'), isFalse);
    });
  });
}
