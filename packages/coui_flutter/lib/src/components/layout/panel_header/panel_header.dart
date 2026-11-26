import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/layout/page_header/header_wrap_layout.dart';

/// Unified cross-platform panel head — the panel's title, and one action at
/// the end of the row.
///
/// Uses [CorePanelHeaderContract] from `coui_core`, so the Web `PanelHeader`
/// takes the same named properties. The title takes the width the action
/// leaves and wraps; once that would fall under
/// [CorePanelHeaderStyle.minTitleWidth], the action moves under the title,
/// start aligned — the rule `PageHeader` follows.
///
/// ```dart
/// PanelHeader(
///   title: Text('Recent files'),
///   action: Button(
///     variant: .plain,
///     size: .sm,
///     onPressed: showAll,
///     child: Text('All'),
///   ),
/// )
/// ```
class PanelHeader extends StatelessWidget
    implements CorePanelHeaderContract<Widget> {
  /// Creates a [PanelHeader].
  const PanelHeader({
    required this.title,
    super.key,
    this.action,
    this.headingLevel = CorePanelHeaderContract.defaultHeadingLevel,
    this.panelHeaderStyle,
  }) : assert(
         headingLevel >= 1 && headingLevel <= 6,
         'a heading level is 1–6',
       );

  @override
  final Widget title;

  @override
  final Widget? action;

  @override
  final int headingLevel;

  @override
  final CorePanelHeaderStyle? panelHeaderStyle;

  /// Returns a copy of this header with the supplied non-null fields
  /// overridden.
  PanelHeader copyWith({
    Key? key,
    Widget? title,
    Widget? action,
    int? headingLevel,
    CorePanelHeaderStyle? panelHeaderStyle,
  }) {
    return PanelHeader(
      key: key ?? this.key,
      title: title ?? this.title,
      action: action ?? this.action,
      headingLevel: headingLevel ?? this.headingLevel,
      panelHeaderStyle: panelHeaderStyle ?? this.panelHeaderStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolvePanelHeader(
      context,
      panelHeaderStyle: panelHeaderStyle,
    );
    final heading = Semantics(
      headingLevel: headingLevel,
      child: DefaultTextStyle(style: resolved.titleTextStyle, child: title),
    );
    return Padding(
      padding: resolved.padding,
      child: switch (action) {
        null => heading,
        // Centred against each other while side by side, the way the Web
        // twin's `align-items: center` row does.
        final action => HeaderWrapLayout(
          minLeadingWidth: resolved.minTitleWidth,
          spacing: resolved.titleActionSpacing,
          crossAxisAlignment: .center,
          textDirection: Directionality.of(context),
          children: [heading, action],
        ),
      },
    );
  }
}

/// Chain sugar for merging a [CorePanelHeaderStyle] patch into
/// [PanelHeader.panelHeaderStyle] without hand-reconstructing every field.
/// Mirrors the Web `PanelHeader.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CorePanelHeaderStyle.merge` right-side-wins semantics).
extension PanelHeaderStyleChain on PanelHeader {
  /// Returns a copy of this [PanelHeader] with [patch] merged into
  /// [panelHeaderStyle] (patch fields win on conflict).
  PanelHeader withStyle(CorePanelHeaderStyle patch) => copyWith(
    panelHeaderStyle: (panelHeaderStyle ?? const CorePanelHeaderStyle()).merge(
      patch,
    ),
  );
}
