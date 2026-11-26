/// 콘텐츠 파일 경로 ↔ 라우트 매핑.
///
/// Jaspr 사이트가 쓰는 규칙을 그대로 미러링해서 두 앱의 URL 이 같게 한다:
/// 확장자를 떼고, `index` 는 부모 디렉터리로 접고, `_` 나 `.` 로 시작하는
/// 세그먼트가 하나라도 있으면 private 로 본다.
library;

import 'package:meta/meta.dart';

/// 문서 콘텐츠 asset 의 루트.
///
/// 콘텐츠는 `docs_site` 가 소유하고 asset 으로 노출한다 — 여기서는 사본이
/// 아니라 원본을 읽는다.
const kDocsContentRoot = 'packages/docs_core/content';

/// 콘텐츠 파일 하나에서 해석한 라우트.
@immutable
class DocsRoute {
  /// 라우트를 만든다.
  const DocsRoute({required this.assetKey, required this.path});

  /// Asset 키 (예: `packages/docs_core/content/components/button.md`).
  final String assetKey;

  /// 라우트 경로 (예: `/components/button`, 루트는 `/`).
  final String path;

  @override
  bool operator ==(Object other) =>
      other is DocsRoute && other.assetKey == assetKey && other.path == path;

  @override
  int get hashCode => Object.hash(assetKey, path);

  @override
  String toString() => 'DocsRoute($path)';
}

/// 콘텐츠 asset 키를 라우트로 해석한다. 라우트가 아니면 `null`.
///
/// 콘텐츠 루트 밖의 asset, `.md` 가 아닌 파일, private 세그먼트를 가진
/// 경로 (`_data/`, `_templates/`) 는 `null` 이 된다 — jaspr 쪽
/// `segments.any((s) => s.startsWith('_') || s.startsWith('.'))` 와
/// 동일하다.
DocsRoute? resolveDocsRoute(String assetKey) {
  if (!assetKey.startsWith('$kDocsContentRoot/')) return null;
  if (!assetKey.endsWith('.md')) return null;

  final relative = assetKey.substring(kDocsContentRoot.length + 1);
  final segments = relative.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return null;

  if (segments.any((s) => s.startsWith('_') || s.startsWith('.'))) return null;

  final last = segments.last;
  final baseName = last.substring(0, last.length - '.md'.length);
  final pathSegments = [
    ...segments.take(segments.length - 1),
    if (baseName != 'index') baseName,
  ];

  return DocsRoute(
    assetKey: assetKey,
    path: pathSegments.isEmpty ? '/' : '/${pathSegments.join('/')}',
  );
}
