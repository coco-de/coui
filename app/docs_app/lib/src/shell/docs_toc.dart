/// 현재 페이지의 목차 (table of contents).
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_heading.dart';

/// 목차가 차지하는 가로 폭.
const double kDocsTocWidth = CoreSpace.space192;

/// 이 레벨(h3)부터 h2 아래로 한 단 들여쓴다.
const _kIndentedHeadingLevel = 3;

/// 페이지 헤딩 목록을 목차로 그린다.
///
/// 들어오는 헤딩은 h2 / h3 뿐이고 (헤딩 추출 쪽 계약), h3 은 h2 아래로
/// 들여쓴다.
class DocsToc extends StatelessWidget {
  /// 목차를 만든다.
  const DocsToc({required this.headings, required this.onTap, super.key});

  /// 그릴 헤딩들 — 문서에 나타난 순서 그대로.
  final List<DocsHeading> headings;

  /// 항목을 눌렀을 때 그 헤딩으로 호출된다.
  final void Function(DocsHeading) onTap;

  @override
  Widget build(BuildContext context) {
    if (headings.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: kDocsTocWidth,
      child: ScrollArea(
        child: Padding(
          padding: const .symmetric(
            vertical: CoreSpace.space16,
            horizontal: CoreSpace.space12,
          ),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            spacing: CoreSpace.space2,
            children: [
              Padding(
                padding: const .only(
                  left: CoreSpace.space8,
                  bottom: CoreSpace.space4,
                ),
                child: const Text(
                  '이 페이지에서',
                ).labelSmall.onSurfaceVariant.semiBold,
              ),
              for (final heading in headings)
                _TocEntry(onTap: onTap, heading: heading),
            ],
          ),
        ),
      ),
    );
  }
}

class _TocEntry extends StatefulWidget {
  const _TocEntry({required this.heading, required this.onTap});

  final DocsHeading heading;
  final void Function(DocsHeading) onTap;

  @override
  State<_TocEntry> createState() => _TocEntryState();
}

class _TocEntryState extends State<_TocEntry> {
  bool _hovered = false;

  void handleHover({required bool hovered}) {
    setState(() => _hovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    final heading = widget.heading;
    // h3 은 h2 아래 한 단 들여쓴다. h2 는 최상위라 들여쓰기가 없다.
    final indent = heading.level >= _kIndentedHeadingLevel
        ? CoreSpace.space20
        : CoreSpace.space8;
    final text = _hovered
        ? Text(heading.text).labelSmall.onSurface
        : Text(heading.text).labelSmall.onSurfaceVariant;

    return Clickable(
      onPressed: () => widget.onTap(heading),
      onHover: (hovered) => handleHover(hovered: hovered),
      child: Padding(
        padding: .only(
          left: indent,
          right: CoreSpace.space8,
          top: CoreSpace.space4,
          bottom: CoreSpace.space4,
        ),
        child: Align(alignment: .centerLeft, child: text),
      ),
    );
  }
}
