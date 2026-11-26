// Sanity-checks the census computations against the real repo — the
// exact ratchet numbers live in `bin/check_reader_census.dart` itself
// (single source of truth, so a baseline bump only happens in one place);
// this test asserts the computation is well-formed and stays in sync with
// that baseline, not a second copy of the numbers.
import 'dart:io';

import 'package:test/test.dart';

import '../bin/check_reader_census.dart';
import '../bin/figma_reader/ast_value.dart';
import '../bin/figma_reader/emit.dart';

void main() {
  test('the census resolves defaults from outside contracts', () {
    final repo = readCensusRepo();
    expect(repo.classesByName, isNot(contains('CoreColor')));
    expect(repo.resolutionRegistry, contains('CoreColor'));
    final color = emitColor(
      EmitContext(tokenScale: const {}, classRegistry: repo.resolutionRegistry),
      const RefValue(owner: 'CoreColor', member: 'transparent'),
      currentClass: 'CoreNavigationBarStyle',
    );
    expect(color, containsPair('argb', 0));
  });

  test(
    'dart run bin/check_reader_census.dart exits 0 against the current repo',
    () {
      final result = Process.runSync('dart', [
        'run',
        'bin/check_reader_census.dart',
        '--ci',
      ]);
      expect(
        result.exitCode,
        0,
        reason:
            'Census gate failed — either a real regression, or '
            "bin/check_reader_census.dart's baseline constants are stale "
            'relative to the current coui_core sources:\n${result.stdout}',
      );
    },
  );

  test('two consecutive runs report identical counts (determinism)', () {
    final first = Process.runSync('dart', [
      'run',
      'bin/check_reader_census.dart',
    ]);
    final second = Process.runSync('dart', [
      'run',
      'bin/check_reader_census.dart',
    ]);
    expect(second.stdout, first.stdout);
  });
}
