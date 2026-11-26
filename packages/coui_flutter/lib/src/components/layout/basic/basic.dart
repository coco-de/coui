import 'package:coui_flutter/coui_flutter.dart';

/// Unified slot-based layout.
///
/// Arranges up to five slots — [leading], [title], [subtitle], [content],
/// [trailing] — inside a single row. Title/subtitle/content stack vertically
/// in the middle cell; leading and trailing occupy the outer cells with their
/// own alignment.
///
/// Replaces legacy `Basic` and `BasicLayout` — the `forceTextStyle` flag
/// chooses between the two behaviours:
///
/// - `true` (default): applies CoUI's default text styles
///   (title = labelXl/semiBold, subtitle = bodySmall muted, content =
///   bodySmall), as legacy [Basic] did with its own styles.
/// - `false`: slots are rendered without any enforced typography. Matches
///   legacy `BasicLayout`.
///
/// ```dart
/// Basic(
///   leading: Icon(LucideIcons.star),
///   title: Text('Awesome'),
///   subtitle: Text('Shiny'),
///   content: Text('Long description ...'),
///   trailing: Icon(LucideIcons.chevronRight),
/// )
/// ```
class Basic extends StatelessWidget implements CoreBasicContract<Widget> {
  /// Creates a [Basic].
  const Basic({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.content,
    this.trailing,
    this.trailingText,
    this.showSubtitle = CoreBasicContract.defaultShowSubtitle,
    this.showTrailingIcon = CoreBasicContract.defaultShowTrailingIcon,
    this.forceTextStyle = true,
    this.basicStyle,
  });

  @override
  final Widget? leading;

  @override
  final Widget? title;

  @override
  final Widget? subtitle;

  @override
  final Widget? content;

  @override
  final Widget? trailing;

  @override
  final Widget? trailingText;

  @override
  final bool showSubtitle;

  @override
  final bool showTrailingIcon;

  @override
  final bool forceTextStyle;

  @override
  final CoreBasicStyle? basicStyle;

  /// Returns a copy of this [Basic] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  Basic copyWith({
    Key? key,
    Widget? leading,
    Widget? title,
    Widget? subtitle,
    Widget? content,
    Widget? trailing,
    Widget? trailingText,
    bool? showSubtitle,
    bool? showTrailingIcon,
    bool? forceTextStyle,
    CoreBasicStyle? basicStyle,
  }) {
    return Basic(
      key: key ?? this.key,
      leading: leading ?? this.leading,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      content: content ?? this.content,
      trailing: trailing ?? this.trailing,
      trailingText: trailingText ?? this.trailingText,
      showSubtitle: showSubtitle ?? this.showSubtitle,
      showTrailingIcon: showTrailingIcon ?? this.showTrailingIcon,
      forceTextStyle: forceTextStyle ?? this.forceTextStyle,
      basicStyle: basicStyle ?? this.basicStyle,
    );
  }

  /// Wraps a slot [child] in a `DefaultTextStyle.merge` carrying the
  /// resolver's paint-ready [style] when non-null, or returns the raw
  /// child unchanged when [style] is `null` (`forceTextStyle == false`).
  /// The widget never assembles typography itself — `resolveBasic`
  /// materialised [style] (render-only).
  Widget _slotChild(Widget child, TextStyle? style) {
    if (style == null) return child;
    return DefaultTextStyle.merge(style: style, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveBasic(
      context,
      forceTextStyle: forceTextStyle,
      basicStyle: basicStyle,
    );

    final subtitle = showSubtitle ? this.subtitle : null;
    final trailingEnd =
        trailing ??
        (showTrailingIcon
            ? Icon(
                LucideIcons.chevronRight,
                iconStyle: resolved.trailingIconStyle,
              )
            : null);
    final hasTrailing = trailingText != null || trailingEnd != null;
    final hasBodySlot = title != null || subtitle != null || content != null;
    final hasAnySlot = hasBodySlot || leading != null || hasTrailing;

    final body = hasBodySlot
        ? Column(
            mainAxisAlignment: resolved.mainAxisAlignment,
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              if (title != null)
                Align(
                  alignment: resolved.titleAlignment,
                  child: _slotChild(title!, resolved.titleTextStyle),
                ),
              if (title != null && subtitle != null)
                Gap(gapStyle: resolved.titleSubtitleGapStyle),
              if (subtitle != null)
                Align(
                  alignment: resolved.subtitleAlignment,
                  child: _slotChild(subtitle, resolved.subtitleTextStyle),
                ),
              if ((title != null || subtitle != null) && content != null)
                Gap(gapStyle: resolved.leadingTitleGapStyle),
              if (content != null)
                Align(
                  alignment: resolved.contentAlignment,
                  child: _slotChild(content!, resolved.contentTextStyle),
                ),
            ],
          )
        : null;

    final rowChildren = <Widget>[
      if (leading != null)
        Align(alignment: resolved.leadingAlignment, child: leading),
      if (leading != null && body != null)
        Gap(gapStyle: resolved.titleContentGapStyle),
      if (body != null) Expanded(child: body),
      if (hasTrailing && hasAnySlot && trailing != leading)
        Gap(gapStyle: resolved.titleContentGapStyle),
      if (hasTrailing)
        Align(
          alignment: resolved.trailingAlignment,
          child: Row(
            mainAxisSize: .min,
            children: [
              if (trailingText != null)
                _slotChild(trailingText!, resolved.trailingTextStyle),
              if (trailingText != null && trailingEnd != null)
                Gap(gapStyle: resolved.trailingGapStyle),
              ?trailingEnd,
            ],
          ),
        ),
    ];

    Widget row = Row(
      mainAxisAlignment: resolved.mainAxisAlignment,
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: rowChildren,
    );

    if (forceTextStyle) {
      row = IntrinsicWidth(child: IntrinsicHeight(child: row));
    }

    return Padding(padding: resolved.padding, child: row);
  }
}

/// Chain sugar for merging a [CoreBasicStyle] patch into
/// [Basic.basicStyle] without hand-reconstructing every field. Mirrors
/// the Web `Basic.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreBasicStyle.merge` right-side-wins semantics).
extension BasicStyleChain on Basic {
  /// Returns a copy of this [Basic] with [patch] merged into
  /// [basicStyle] (patch fields win on conflict).
  Basic withStyle(CoreBasicStyle patch) =>
      copyWith(basicStyle: (basicStyle ?? const CoreBasicStyle()).merge(patch));
}
