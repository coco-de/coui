import 'dart:io';

/// Locates the monorepo root from wherever the current process's working
/// directory happens to be.
///
/// `docs_site`'s `jaspr build`/`jaspr serve` run with cwd `docs_site/`, and
/// `docs_core`'s own tests run with cwd `docs_core/` — both one level
/// below the root, so `'../'` already works for both today
/// (`main.server.dart`'s `FilesystemLoader('../docs_core/content')` relies
/// on exactly this). This walks upward instead of hardcoding `'../'` so a
/// third consumer at a different depth (or a differently-configured CI
/// working directory) does not silently read the wrong `CHANGELOG.md` —
/// it fails loudly via the `StateError` below rather than reading nothing.
///
/// The root is identified by having both a `packages/` and a `docs_core/`
/// child directory — distinctive enough that no package subdirectory
/// mistakes itself for the root.
Directory findRepoRoot({Directory? from}) {
  var dir = from ?? Directory.current;
  for (var i = 0; i < 8; i++) {
    final looksLikeRoot =
        Directory('${dir.path}/packages').existsSync() && Directory('${dir.path}/docs_core').existsSync();
    if (looksLikeRoot) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) break; // Reached filesystem root.
    dir = parent;
  }
  throw StateError(
    'findRepoRoot: no ancestor of ${(from ?? Directory.current).path} has '
    'both packages/ and docs_core/ — are we running from inside the coui '
    'monorepo checkout?',
  );
}
