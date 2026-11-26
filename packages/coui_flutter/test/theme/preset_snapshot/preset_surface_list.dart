// #4355 — the surface list this snapshot covers, derived rather than typed.
//
// The Project's other artefacts (`docs/surface-preset-axis.md`, the role
// sweep of #4348/#4349) count surfaces from one place:
// `docs/_glass-survey-full.json`, where every catalogue entry carries the
// role it was judged into. Re-typing the list here would make a second
// count that drifts from the first the moment either moves — the exact
// failure `.claude/rules/principles/single-source-of-truth.md` names, and
// the reason this file parses the survey instead.
//
// `content` and `functional` are the two roles that *are* surfaces;
// `not-a-surface` is the third and is excluded by the same judgement that
// wrote it. Nothing here re-judges an entry.
import 'dart:convert';
import 'dart:io';

/// The survey artefact both this snapshot and the role sweep read.
const String kGlassSurveyRelativePath = 'docs/_glass-survey-full.json';

/// Roles that name a surface. `not-a-surface` is the complement.
const Set<String> kSurfaceRoles = {'content', 'functional'};

/// Walks up from [start] until a directory containing
/// [kGlassSurveyRelativePath] is found.
///
/// The working directory differs by how the suite is invoked — `melos run
/// test:flutter` cds into `packages/coui_flutter/`, a repo-root `flutter
/// test packages/coui_flutter/...` does not — and a path that assumed one
/// of those would fail as "file not found" in the other, which reads like
/// a broken checkout rather than a wrong relative path. Throws rather than
/// returning null: a snapshot that cannot find its own surface list has
/// nothing to assert, and skipping quietly is how a gate stops being one.
Directory findRepoRoot([Directory? start]) {
  final origin = start ?? .current;
  var dir = origin;
  while (true) {
    if (File('${dir.path}/$kGlassSurveyRelativePath').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError(
        '$kGlassSurveyRelativePath 를 ${origin.path} '
        '위쪽 어디에서도 찾지 못했다 — 스냅샷이 덮을 표면 목록의 출처다. '
        '레포 밖에서 실행됐거나 그 파일이 옮겨졌다.',
      );
    }
    dir = parent;
  }
}

/// Every surface slug the survey judged into [kSurfaceRoles], sorted.
///
/// Sorted so the baseline's key order is a property of the set rather than
/// of the survey file's own ordering — a survey rewritten in a different
/// order would otherwise rewrite every baseline with no change of meaning.
List<String> readSurfaceSlugs(Directory repoRoot) {
  final file = File('${repoRoot.path}/$kGlassSurveyRelativePath');
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! List) {
    throw StateError(
      '$kGlassSurveyRelativePath 가 리스트가 아니다: ${decoded.runtimeType}',
    );
  }

  final slugs = <String>[];
  for (final entry in decoded) {
    if (entry is! Map<String, Object?>) {
      throw StateError('$kGlassSurveyRelativePath 항목이 객체가 아니다: $entry');
    }
    final role = entry['role'];
    final slug = entry['slug'];
    if (role is! String || slug is! String) {
      throw StateError('$kGlassSurveyRelativePath 항목에 role/slug 가 없다: $entry');
    }
    if (kSurfaceRoles.contains(role)) slugs.add(slug);
  }

  if (slugs.isEmpty) {
    // An empty selection is not "nothing to check" — it is a filter that
    // stopped matching (a renamed role, a rewritten survey). A suite that
    // asserted over zero surfaces would report green while covering
    // nothing.
    throw StateError(
      '$kGlassSurveyRelativePath 에서 role ∈ $kSurfaceRoles 인 항목이 0개다 — '
      '필터가 더 이상 매칭되지 않는다(역할 이름이 바뀌었거나 서베이가 다시 쓰였다).',
    );
  }

  slugs.sort();
  return slugs;
}
