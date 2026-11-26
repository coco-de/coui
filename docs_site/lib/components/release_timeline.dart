import 'dart:io';

import 'package:coui_web/coui_web.dart' hide Document, Style, css;
import 'package:docs_core/markdown/changelog.dart';
import 'package:docs_core/markdown/repo_root.dart';
import 'package:jaspr_content/jaspr_content.dart';

const _releaseFilters = {'all': '전체', 'feature': 'Feature', 'fix': 'Fix', 'update': 'Update'};

typedef _ReleaseVersion = ({String version, String date});
typedef _PackageRelease = ({String package, ChangelogEntry entry});

/// Resolves both the timeline and its navigation from the package changelogs.
class ReleaseTimeline implements PageExtension {
  const ReleaseTimeline();

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    if (page.url != '/changelog') return nodes;

    final root = findRepoRoot();
    final releases = <_ReleaseVersion, List<_PackageRelease>>{};
    for (final package in kReleaseTimelinePackages) {
      final file = File('${root.path}/packages/$package/CHANGELOG.md');
      if (!await file.exists()) continue;
      for (final entry in parseChangelogEntries(await file.readAsString(), limit: kReleaseTimelinePerPackage)) {
        releases.putIfAbsent((version: entry.version, date: entry.date), () => []).add((
          package: package,
          entry: entry,
        ));
      }
    }
    final versions = releases.keys.toList()
      ..sort((first, second) {
        final date = second.date.compareTo(first.date);
        if (date != 0) return date;
        final left = first.version.split('.').map(int.tryParse).toList();
        final right = second.version.split('.').map(int.tryParse).toList();
        for (var i = 0; i < left.length && i < right.length; i++) {
          final order = (right[i] ?? 0).compareTo(left[i] ?? 0);
          if (order != 0) return order;
        }
        return second.version.compareTo(first.version);
      });
    final latest = versions.take(kReleaseTimelineVisible);
    final older = versions.skip(kReleaseTimelineVisible);

    page.apply(
      data: {
        'toc': TableOfContents([
          for (final version in latest) TocEntry('v${version.version}', _releaseId(version), []),
          if (older.isNotEmpty) TocEntry('이전 버전', 'release-history', []),
        ]),
      },
    );

    final view = versions.isEmpty
        ? p([Component.text('표시할 릴리스가 없습니다. 전체 이력은 아래의 패키지별 CHANGELOG 링크에서 볼 수 있습니다.')])
        : div(
            classes: 'release-timeline not-content',
            attributes: const {'data-release-timeline': ''},
            [
              div(
                classes: 'release-filters',
                attributes: const {'role': 'group', 'aria-label': '변경 유형'},
                [
                  for (final filter in _releaseFilters.entries)
                    Button(
                      enabled: true,
                      variant: CoreButtonVariant.outline,
                      size: CoreComponentSize.sm,
                      classes: 'catalog-filter',
                      attributes: {'data-release-filter': filter.key, 'aria-pressed': '${filter.key == 'all'}'},
                      child: Text(filter.value),
                    ),
                ],
              ),
              p(
                classes: 'release-empty',
                attributes: const {'data-release-empty': '', 'hidden': '', 'role': 'status'},
                [Component.text('이 유형의 릴리스가 없습니다.')],
              ),
              for (final version in latest) _release(version, releases[version]!),
              if (older.isNotEmpty)
                details(id: 'release-history', classes: 'release-history', [
                  summary([Text('이전 버전 더 보기').labelLarge]),
                  for (final version in older) _release(version, releases[version]!),
                ]),
            ],
          );

    return [
      for (final node in nodes)
        if (node is ElementNode && node.tag == 'ReleaseTimeline') ComponentNode(view) else node,
    ];
  }
}

String _releaseId(_ReleaseVersion version) => 'release-${version.version}-${version.date}';

String _releaseType(String section) {
  final title = section.toLowerCase();
  if (title == '기능' || title.startsWith('feat')) return 'feature';
  if (title == '버그 수정' || title.contains('fix')) return 'fix';
  return 'update';
}

Component _release(_ReleaseVersion version, List<_PackageRelease> releases) => article(
  id: _releaseId(version),
  classes: 'release-entry',
  attributes: const {'data-release-entry': ''},
  [
    header(classes: 'release-version', [
      code([Component.text('v${version.version}')]),
      Component.element(
        tag: 'time',
        attributes: {'datetime': version.date},
        children: [
          Text(version.date.replaceAll('-', '.')).bodySmall.onSurfaceVariant,
        ],
      ),
    ]),
    div(classes: 'release-packages', [
      for (final release in releases)
        section(
          classes: 'release-package',
          attributes: const {'data-release-package': ''},
          [
            h2([Text(release.package).titleLarge.semiBold.onSurface]),
            for (final section in release.entry.sections.entries)
              if (section.value.isNotEmpty)
                div(
                  classes: 'release-section',
                  attributes: {'data-release-type': _releaseType(section.key)},
                  [
                    span(classes: 'release-type', [Text(_releaseFilters[_releaseType(section.key)]!).labelSmall]),
                    h3([Text(section.key).titleSmall.semiBold.onSurface]),
                    ul([
                      for (final bullet in section.value) li(_bulletSpans(bullet)),
                    ]),
                  ],
                ),
          ],
        ),
    ]),
  ],
);

/// 항목의 굵게 · 인라인 코드를 표시 그대로 낸다 — 나누는 규칙은
/// [changelogBulletSpans] 한 곳이고, 앱도 같은 함수로 그린다.
List<Component> _bulletSpans(String bullet) => [
  for (final span in changelogBulletSpans(bullet))
    switch (span.kind) {
      ChangelogSpanKind.text => Component.text(span.text),
      ChangelogSpanKind.strong => strong([Component.text(span.text)]),
      ChangelogSpanKind.code => code([Component.text(span.text)]),
    },
];
