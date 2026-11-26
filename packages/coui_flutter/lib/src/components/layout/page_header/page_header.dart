import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/layout/page_header/header_wrap_layout.dart';

/// Unified cross-platform page head — a short eyebrow over the page title,
/// an optional sentence under it, and the page's actions at the end of the
/// row.
///
/// Uses [CorePageHeaderContract] from `coui_core`, so the Web `PageHeader`
/// takes the same named properties. The text block takes the width the
/// actions leave; once that would fall under
/// [CorePageHeaderStyle.minTextWidth], the actions move under the text,
/// start aligned, and wrap among themselves if a line of their own is still
/// too narrow — so the header never overflows.
///
/// ```dart
/// PageHeader(
///   eyebrow: Text('Workspace'),
///   title: Text('Settings'),
///   actions: [
///     Button(variant: .secondary, onPressed: cancel, child: Text('Cancel')),
///     Button(onPressed: save, child: Text('Save')),
///   ],
/// )
/// ```
class PageHeader extends StatelessWidget
    implements CorePageHeaderContract<Widget> {
  /// Creates a [PageHeader].
  const PageHeader({
    required this.title,
    super.key,
    this.eyebrow,
    this.description,
    this.actions = const [],
    this.headingLevel = CorePageHeaderContract.defaultHeadingLevel,
    this.pageHeaderStyle,
  }) : assert(
         headingLevel >= 1 && headingLevel <= 6,
         'a heading level is 1–6',
       );

  @override
  final Widget? eyebrow;

  @override
  final Widget title;

  @override
  final Widget? description;

  @override
  final List<Widget> actions;

  @override
  final int headingLevel;

  @override
  final CorePageHeaderStyle? pageHeaderStyle;

  /// Returns a copy of this header with the supplied non-null fields
  /// overridden.
  PageHeader copyWith({
    Key? key,
    Widget? eyebrow,
    Widget? title,
    Widget? description,
    List<Widget>? actions,
    int? headingLevel,
    CorePageHeaderStyle? pageHeaderStyle,
  }) {
    return PageHeader(
      key: key ?? this.key,
      eyebrow: eyebrow ?? this.eyebrow,
      title: title ?? this.title,
      description: description ?? this.description,
      actions: actions ?? this.actions,
      headingLevel: headingLevel ?? this.headingLevel,
      pageHeaderStyle: pageHeaderStyle ?? this.pageHeaderStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolvePageHeader(
      context,
      pageHeaderStyle: pageHeaderStyle,
    );
    final heading = Semantics(
      headingLevel: headingLevel,
      child: DefaultTextStyle(style: resolved.titleTextStyle, child: title),
    );
    // The actions share the title's line, centred on it, and move under the
    // title when the line leaves the title less than its floor — the Web
    // twin's wrapping title row.
    final titleRow = actions.isEmpty
        ? heading
        : HeaderWrapLayout(
            minLeadingWidth: resolved.minTextWidth,
            spacing: resolved.textActionsSpacing,
            crossAxisAlignment: .center,
            textDirection: Directionality.of(context),
            children: [
              heading,
              Wrap(
                spacing: resolved.actionSpacing,
                runSpacing: resolved.actionSpacing,
                crossAxisAlignment: .center,
                children: actions,
              ),
            ],
          );

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      spacing: resolved.textSpacing,
      children: [
        if (eyebrow case final eyebrow?)
          DefaultTextStyle(style: resolved.eyebrowTextStyle, child: eyebrow),
        titleRow,
        // Under the title row, at the header's full width — it wraps there.
        if (description case final description?)
          DefaultTextStyle(
            style: resolved.descriptionTextStyle,
            child: description,
          ),
      ],
    );
  }
}

/// Chain sugar for merging a [CorePageHeaderStyle] patch into
/// [PageHeader.pageHeaderStyle] without hand-reconstructing every field.
/// Mirrors the Web `PageHeader.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CorePageHeaderStyle.merge` right-side-wins semantics).
extension PageHeaderStyleChain on PageHeader {
  /// Returns a copy of this [PageHeader] with [patch] merged into
  /// [pageHeaderStyle] (patch fields win on conflict).
  PageHeader withStyle(CorePageHeaderStyle patch) => copyWith(
    pageHeaderStyle: (pageHeaderStyle ?? const CorePageHeaderStyle()).merge(
      patch,
    ),
  );
}
