@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/markdown/repo_root.dart';
import 'package:test/test.dart';

void main() {
  test('finds the monorepo root from the docs_core test working directory', () {
    final root = findRepoRoot();
    expect(Directory('${root.path}/packages/coui_flutter').existsSync(), isTrue);
    expect(Directory('${root.path}/docs_core').existsSync(), isTrue);
  });

  test('finds the root when starting from a nested directory', () {
    final root = findRepoRoot(from: Directory('${Directory.current.path}/lib/markdown'));
    expect(Directory('${root.path}/packages').existsSync(), isTrue);
  });

  test('throws when no ancestor looks like the repo root', () {
    expect(() => findRepoRoot(from: Directory('/')), throwsStateError);
  });
}
