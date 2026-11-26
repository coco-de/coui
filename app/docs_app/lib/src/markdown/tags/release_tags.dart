/// 릴리스 태그 — `<CurrentVersion />` · `<ChangelogPreview />` ·
/// `<ReleaseTimeline />`.
///
/// 둘 다 값을 문서에 박지 않고 패키지의 `pubspec.yaml` / `CHANGELOG.md` 를
/// 읽는다. **무엇을 보여줄지는 docs_site 와 같은 함수가 정한다** —
/// `currentVersionView` / `changelogPreviewView`(docs_core). 여기서 하는
/// 일은 그 원본을 번들에서 꺼내는 것과 결과를 Flutter 로 그리는 것뿐이라,
/// 두 표면이 같은 CHANGELOG 에서 다른 항목·다른 버전을 낼 수 없다.
///
/// 원본은 `pubspec.yaml` 의 `release/` 자산이다 — `packages/<pkg>/` 로 가는
/// 심링크라 릴리스가 파일을 바꾸면 다음 빌드가 그대로 따라온다.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_tag_registry.dart';
import 'package:docs_app/src/markdown/inline_renderer.dart';
import 'package:docs_core/markdown/changelog.dart';
import 'package:docs_core/markdown/current_version.dart';
import 'package:flutter/foundation.dart' show mapEquals;

/// `<pkg>` 의 `pubspec.yaml` 이 번들에 실리는 키.
String docsReleasePubspecKey(String package) => 'release/$package.pubspec.yaml';

/// `<pkg>` 의 `CHANGELOG.md` 가 번들에 실리는 키.
String docsReleaseChangelogKey(String package) =>
    'release/$package.CHANGELOG.md';

/// 릴리스 태그 이름 → 빌더.
Map<String, DocsTagBuilder> docsReleaseTagBuilders() => {
  'CurrentVersion': (context, tag) =>
      _CurrentVersionView(attributes: tag.attributes),
  'ChangelogPreview': (context, tag) =>
      _ChangelogPreviewView(attributes: tag.attributes),
  'ReleaseTimeline': (context, tag) => const _ReleaseTimelineView(),
};

/// 읽기 실패가 "번들에 그 키가 없음" 인지.
///
/// `AssetBundle.load` 는 키가 없을 때 [FlutterError] 를 던진다 — 그것만
/// "없음" 으로 읽고, 다른 실패(디코딩 등)는 "읽을 수 없음" 으로 남긴다.
/// docs_site 가 파일이 없을 때와 읽다 실패했을 때를 가르는 것과 같은 선이다.
bool _isMissingAsset(Object error) => error is FlutterError;

/// 원본을 한 번만 읽고, 번들이나 속성이 바뀔 때만 다시 읽는다.
///
/// 번들은 inherited 라 `initState` 에서 읽을 수 없어 `didChangeDependencies`
/// 에서 잡는다.
abstract class _AssetReaderState<T extends StatefulWidget, V> extends State<T> {
  AssetBundle? _bundle;
  Future<V>? _view;

  Map<String, String> get attributes;

  Future<V> read(AssetBundle bundle);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    if (!identical(bundle, _bundle)) {
      _bundle = bundle;
      _view = read(bundle);
    }
  }

  /// [oldWidget] 의 속성 — 같은 내용이면 다시 읽지 않는다.
  Map<String, String> attributesOf(T oldWidget);

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 마크다운이 다시 그려질 때마다 태그 위젯은 새 속성 맵과 함께 온다.
    // 내용이 같으면 원본도 같으므로 다시 읽을 이유가 없다.
    final bundle = _bundle;
    if (bundle != null && !mapEquals(attributesOf(oldWidget), attributes)) {
      _view = read(bundle);
    }
  }

  Widget buildView(BuildContext context, V view);

  @override
  Widget build(BuildContext context) => FutureBuilder<V>(
    future: _view,
    builder: (context, snapshot) {
      final view = snapshot.data;
      // 자산 한 개를 읽는 짧은 틈 — 자리만 비워 둔다. 스켈레톤을 두면
      // 거의 매번 한 프레임 번쩍이고 끝난다.
      return view == null ? const SizedBox.shrink() : buildView(context, view);
    },
  );
}

// ── CurrentVersion ──────────────────────────────────────────────────

class _CurrentVersionView extends StatefulWidget {
  const _CurrentVersionView({required this.attributes});

  final Map<String, String> attributes;

  @override
  State<_CurrentVersionView> createState() => _CurrentVersionViewState();
}

class _CurrentVersionViewState
    extends _AssetReaderState<_CurrentVersionView, CurrentVersionView> {
  @override
  Map<String, String> get attributes => widget.attributes;

  @override
  Map<String, String> attributesOf(_CurrentVersionView oldWidget) =>
      oldWidget.attributes;

  @override
  Future<CurrentVersionView> read(AssetBundle bundle) async {
    final package = currentVersionPackage(attributes);
    if (package == null) return kCurrentVersionMissingPackageNotice;

    final String source;
    try {
      source = await bundle.loadString(docsReleasePubspecKey(package));
    } on Object catch (error) {
      // docs_site 도 pubspec 이 없든 못 읽든 같은 문구 하나를 낸다.
      return currentVersionUnreadableNotice(package, error);
    }
    return currentVersionView(
      package: package,
      attributes: attributes,
      pubspecSource: source,
    );
  }

  @override
  Widget buildView(BuildContext context, CurrentVersionView view) =>
      switch (view) {
        // docs_site 는 `<code>` 로 낸다 — 문단 속 인라인 코드와 같은 모양.
        CurrentVersionText(:final text) => Text.rich(
          TextSpan(text: text, style: docsInlineCodeStyle(context)),
        ).bodyMedium.onSurface,
        CurrentVersionNotice(:final message) => _Notice(message),
      };
}

// ── ChangelogPreview ────────────────────────────────────────────────

class _ChangelogPreviewView extends StatefulWidget {
  const _ChangelogPreviewView({required this.attributes});

  final Map<String, String> attributes;

  @override
  State<_ChangelogPreviewView> createState() => _ChangelogPreviewViewState();
}

class _ChangelogPreviewViewState
    extends _AssetReaderState<_ChangelogPreviewView, ChangelogPreviewView> {
  @override
  Map<String, String> get attributes => widget.attributes;

  @override
  Map<String, String> attributesOf(_ChangelogPreviewView oldWidget) =>
      oldWidget.attributes;

  @override
  Future<ChangelogPreviewView> read(AssetBundle bundle) async {
    final package = changelogPreviewPackage(attributes);
    if (package == null) return kChangelogPreviewMissingPackageNotice;

    final String source;
    try {
      source = await bundle.loadString(docsReleaseChangelogKey(package));
    } on Object catch (error) {
      return _isMissingAsset(error)
          ? changelogPreviewMissingNotice(package)
          : changelogPreviewUnreadableNotice(package, error);
    }
    return changelogPreviewView(
      package: package,
      attributes: attributes,
      changelogSource: source,
    );
  }

  @override
  Widget buildView(BuildContext context, ChangelogPreviewView view) =>
      switch (view) {
        ChangelogPreviewEntries(:final entries) => Column(
          crossAxisAlignment: .stretch,
          children: [
            for (final (index, entry) in entries.indexed) ...[
              if (index > 0)
                const Padding(
                  padding: .symmetric(vertical: CoreSpace.space16),
                  child: Divider(),
                ),
              _EntryView(entry: entry),
            ],
          ],
        ),
        ChangelogPreviewNotice(:final message) => _Notice(message),
      };
}

/// 릴리스 한 건 — 버전 · 날짜 머리 + 섹션별 불릿.
class _EntryView extends StatelessWidget {
  const _EntryView({required this.entry});

  final ChangelogEntry entry;

  @override
  Widget build(BuildContext context) {
    final sections = [
      for (final section in entry.sections.entries)
        if (section.value.isNotEmpty) section,
    ];

    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          crossAxisAlignment: .baseline,
          textBaseline: .alphabetic,
          children: [
            Text(entry.version).bodyMedium.mono.semiBold.onSurface,
            const Gap.space8(),
            Text(entry.date).labelMedium.onSurfaceVariant,
          ],
        ),
        for (final section in sections) ...[
          const Gap.space8(),
          Text(section.key).labelMedium.onSurfaceVariant,
          const Gap.space4(),
          for (final bullet in section.value)
            Padding(
              padding: const .only(top: CoreSpace.space4),
              child: Row(
                crossAxisAlignment: .start,
                children: [
                  SizedBox(
                    width: CoreSpace.space24,
                    child: const Text('•').bodyMedium.onSurfaceVariant,
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          for (final span in changelogBulletSpans(bullet))
                            TextSpan(
                              text: span.text,
                              style: switch (span.kind) {
                                ChangelogSpanKind.text => null,
                                ChangelogSpanKind.strong => TextStyle(
                                  fontWeight: fontWeightFromInt(
                                    CoreFontWeight.semiBold,
                                  ),
                                ),
                                ChangelogSpanKind.code => docsInlineCodeStyle(
                                  context,
                                ),
                              },
                            ),
                        ],
                      ),
                    ).bodyMedium.onSurface,
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// ── ReleaseTimeline ─────────────────────────────────────────────────

/// Changelog 페이지의 릴리스 — 패키지마다 최근 릴리스.
///
/// 사이트는 같은 패키지 목록(`kReleaseTimelinePackages`)에서 패키지마다
/// `kReleaseTimelinePerPackage` 개를 읽어 버전으로 묶고, 최근 몇 개 뒤를
/// "이전 버전 더 보기" 로 접는다. 여기서는 그림 대신 같은 릴리스를 패키지별
/// 목록으로 그린다 — 사이트에서 펼쳐 볼 수 있는 릴리스는 여기서도 모두
/// 보인다. 항목은 `<ChangelogPreview>` 와 같은 함수가 고른다.
class _ReleaseTimelineView extends StatelessWidget {
  const _ReleaseTimelineView();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      for (final (index, package) in kReleaseTimelinePackages.indexed) ...[
        if (index > 0) const Gap.space32(),
        Text(package).titleLarge.semiBold.onSurface,
        const Gap.space12(),
        _ChangelogPreviewView(
          attributes: {
            'package': package,
            'count': '$kReleaseTimelinePerPackage',
          },
        ),
      ],
    ],
  );
}

/// 보여줄 수 없을 때의 한 줄 — docs_site 의 저하 문구와 같은 문장.
class _Notice extends StatelessWidget {
  const _Notice(this.message);

  final String message;

  @override
  Widget build(BuildContext context) =>
      Text(message).bodySmall.italic.onSurfaceVariant;
}
