/// 컴포넌트 검색 팔레트.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/shared/docs_search_index.dart';

/// 검색 팔레트를 띄운다.
///
/// 인덱스는 공유 [buildDocsSearchIndex] (`docs_core/lib/shared/docs_search_index.dart`)
/// 에서 온다 — Web(docs_site)도 같은 함수로 만든 인덱스를 쓴다(#3577). 검색
/// 전용 목록을 플랫폼마다 따로 두지 않는다 — 예전 docs_site 는 검색 인덱스
/// 사본을 따로 들고 있었고, 그게 컴포넌트마다 손 편집이 하나 더 필요한
/// 이유였다.
Future<void> showDocsSearch(
  BuildContext context, {
  required void Function(String path) onNavigate,
}) {
  return showDialog(
    context: context,
    builder: (context) => _DocsSearchDialog(onNavigate: onNavigate),
  );
}

/// 검색 팔레트 본체.
///
/// `Command` 는 양 플랫폼 모두 제어형(controlled)이다 — 필터는 `query` 만
/// 읽고, 입력은 `onQueryChanged` 로 부모에게 넘길 뿐 스스로 들고 있지 않는다.
/// 그래서 검색어 상태는 여기(호출자)가 소유한다. Web(docs_site 의
/// `docs_search.dart`)도 같은 형태로 `_query` 를 들고 배선한다 — 이 배선이
/// 빠지면 입력은 보이지만 `query` 가 늘 빈 문자열이라 목록이 걸러지지 않는다.
class _DocsSearchDialog extends StatefulWidget {
  const _DocsSearchDialog({required this.onNavigate});
  final void Function(String path) onNavigate;

  @override
  State<_DocsSearchDialog> createState() => _DocsSearchDialogState();
}

class _DocsSearchDialogState extends State<_DocsSearchDialog> {
  String _query = '';

  void _handleQueryChanged(String query) {
    setState(() => _query = query);
  }

  void _handleSelect(String value) {
    Navigator.of(context).pop();
    widget.onNavigate(docsSearchPath(value));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 420),
        child: Command(
          groups: [
            for (final group in buildDocsSearchIndex())
              CoreCommandGroup<Widget>(
                items: [
                  for (final item in group.items)
                    CoreCommandItem<Widget>(
                      value: item.value,
                      label: item.label,
                      keywords: item.keywords,
                    ),
                ],
                heading: group.heading,
              ),
          ],
          query: _query,
          onQueryChanged: _handleQueryChanged,
          onSelect: _handleSelect,
        ),
      ),
      onClose: () => Navigator.of(context).pop(),
      // `Command` already paints its own background / border / 20px
      // corner radius (the modal role, matches `Dialog`'s own panel) — it's
      // meant to BE the visible surface wherever it's mounted, not
      // float inside a second one. Without this the panel's default
      // 24px padding + the unconditional pre-content section gap
      // (16px — meant to separate a header from the body; this dialog
      // has no header) stack into 40px of empty frame around Command,
      // plus a redundant second border. Web's `docs_search.dart` mirrors
      // this — see that file for the shadcn `CommandDialog` comparison.
    ).withStyle(
      const CoreDialogStyle(
        panelPadding: CoreEdgeInsets.zero,
        panelBorderWidth: 0,
        sectionGapStyle: CoreGapStyle(size: 0),
      ),
    );
  }
}
