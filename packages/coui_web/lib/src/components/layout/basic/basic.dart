import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/web_element_chrome.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/layout/basic/basic_style.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// Unified slot-based layout for CoUI Web.
///
/// Arranges up to five slots — [leading], [title], [subtitle], [content],
/// [trailing] — inside a single flex row. Title/subtitle/content stack
/// vertically in the middle cell; leading and trailing occupy the outer
/// cells with their own alignment.
///
/// When [forceTextStyle] is `true` (default), Basic applies CoUI's default
/// typography to each slot (title = labelXl/semiBold, subtitle = bodySmall
/// muted, content = bodySmall). Pass `false` to render slots without any
/// enforced text style.
class Basic extends UiComponent implements CoreBasicContract<Component> {
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
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component? leading;

  @override
  final Component? title;

  @override
  final Component? subtitle;

  @override
  final Component? content;

  @override
  final Component? trailing;

  @override
  final Component? trailingText;

  @override
  final bool showSubtitle;

  @override
  final bool showTrailingIcon;

  @override
  final bool forceTextStyle;

  @override
  final CoreBasicStyle? basicStyle;

  @override
  Basic copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    Component? leading,
    Component? title,
    Component? subtitle,
    Component? content,
    Component? trailing,
    Component? trailingText,
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
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
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

    final horizontalGap = Gap(gapStyle: resolved.titleContentGapStyle);

    final children = <Component>[];
    if (leading != null) {
      children.add(_wrap(leading!, resolved.leadingSlot));
    }
    if (leading != null && hasBodySlot) {
      children.add(horizontalGap);
    }
    if (hasBodySlot) {
      children.add(_buildBody(resolved, subtitle));
    }
    final hasAnyBeforeTrailing = leading != null || hasBodySlot;
    if (hasTrailing && hasAnyBeforeTrailing) {
      children.add(horizontalGap);
    }
    if (hasTrailing) {
      children.add(
        _wrap(
          div(
            [
              if (trailingText != null)
                div(
                  [trailingText!],
                  classes: resolved.trailingText.className,
                  styles: resolved.trailingText.inlineStyles,
                ),
              if (trailingText != null && trailingEnd != null)
                Gap(gapStyle: resolved.trailingGapStyle),
              ?trailingEnd,
            ],
            classes: resolved.trailingCell.className,
            styles: resolved.trailingCell.inlineStyles,
          ),
          resolved.trailingSlot,
        ),
      );
    }

    return div(
      children,
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: componentAttributes.isEmpty ? null : componentAttributes,
      events: events.isEmpty ? null : events,
    );
  }

  /// Wraps a slot child with the pre-resolved slot wrapper chrome.
  Component _wrap(Component child, WebElementChrome chrome) => div(
    [child],
    classes: chrome.className,
    styles: chrome.inlineStyles,
  );

  Component _buildBody(ResolvedBasic resolved, Component? subtitle) {
    final items = <Component>[];
    if (title != null) {
      items.add(_wrap(title!, resolved.titleSlot));
    }
    if (title != null && subtitle != null) {
      items.add(Gap(gapStyle: resolved.titleSubtitleGapStyle));
    }
    if (subtitle != null) {
      items.add(_wrap(subtitle, resolved.subtitleSlot));
    }
    if ((title != null || subtitle != null) && content != null) {
      items.add(Gap(gapStyle: resolved.leadingTitleGapStyle));
    }
    if (content != null) {
      items.add(_wrap(content!, resolved.contentSlot));
    }

    return div(
      items,
      classes: resolved.body.className,
      styles: resolved.body.inlineStyles,
    );
  }
}

/// Chain sugar mirroring the Flutter `Basic.withStyle` extension —
/// merges a [CoreBasicStyle] patch into [Basic.basicStyle] via the
/// existing [Basic.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreBasicStyle.merge` right-side-wins semantics).
extension BasicStyleChain on Basic {
  /// Sets the content padding.
  Basic contentPadding(CoreEdgeInsets value) =>
      withStyle(CoreBasicStyle(padding: value));

  /// Returns a copy of this [Basic] with [patch] merged into
  /// [basicStyle] (patch fields win on conflict).
  Basic withStyle(CoreBasicStyle patch) =>
      copyWith(basicStyle: (basicStyle ?? const CoreBasicStyle()).merge(patch));
}
