import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../src/manifest/surface_marker_registry.dart';

/// Re-derives the surface-marker component set by grepping
/// `packages/coui_web/lib/src/components/` for `_style.dart` files that
/// call `webSurfaceMarkerFor` — the same check a human ran by hand to
/// write [kSurfaceMarkerComponentSlugs] down. Running it as a test means a
/// future component adding or dropping the marker fails this test instead
/// of silently drifting the pruning rule (`core/theme-axis-composition.md`).
Set<String> _deriveSurfaceMarkerSlugsFromSource(String repoRoot) {
  final componentsDir = Directory(
    p.join(repoRoot, 'packages', 'coui_web', 'lib', 'src', 'components'),
  );
  final slugs = <String>{};
  for (final entity in componentsDir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('_style.dart')) continue;
    // The helper, not the bare constant. A surface marks itself through
    // `webSurfaceMarkerFor(role)`, which takes its role as a required
    // argument — matching the constant instead would find only the one
    // comment that still mentions it, derive an empty set, and fail with
    // a message about drift that had not happened.
    if (!entity.readAsStringSync().contains('webSurfaceMarkerFor')) continue;
    final componentDirName = p.basename(p.dirname(entity.path));
    slugs.add(componentDirName.replaceAll('_', '-'));
  }
  return slugs;
}

void main() {
  test(
    'kSurfaceMarkerComponentSlugs matches the actual marker call sites',
    () {
      final repoRoot = Directory.current.path;
      final derived = _deriveSurfaceMarkerSlugsFromSource(repoRoot);
      expect(
        kSurfaceMarkerComponentSlugs,
        derived,
        reason:
            'surface_marker_registry.dart 의 목록이 실제 소스와 갈렸다 — '
            '컴포넌트가 표면 마커를 추가/제거했다면 그 목록도 '
            '같이 갱신하라.',
      );
    },
  );
}
