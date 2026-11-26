import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/navigation/sidebar_section/sidebar_section_style.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

/// A quiet heading above a run of `Sidebar` rows for CoUI Web, with an
/// optional action at its far end.
///
/// A heading, not a destination: it takes no focus of its own.
class SidebarSection extends UiComponent
    implements CoreSidebarSectionContract<Component> {
  /// Creates a [SidebarSection].
  const SidebarSection({
    required this.label,
    super.key,
    this.action,
    this.sidebarSectionStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'div');

  @override
  final Component label;

  @override
  final Component? action;

  @override
  final CoreSidebarSectionStyle? sidebarSectionStyle;

  @override
  SidebarSection copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    Component? label,
    Component? action,
    CoreSidebarSectionStyle? sidebarSectionStyle,
  }) {
    return SidebarSection(
      key: key ?? this.key,
      label: label ?? this.label,
      action: action ?? this.action,
      sidebarSectionStyle: sidebarSectionStyle ?? this.sidebarSectionStyle,
      id: id ?? this.id,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      attributes: attributes ?? userAttributes,
      eventHandlers: eventHandlers,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveSidebarSection(
      context,
      sidebarSectionStyle: sidebarSectionStyle,
    );
    return Component.element(
      tag: 'div',
      id: id,
      classes: rootClasses(resolved.root.className),
      styles: Styles.combine([?resolved.root.inlineStyles, ?css]),
      attributes: componentAttributes,
      events: events.isEmpty ? null : events,
      children: [
        // The label is the heading; the action beside it is not part of it.
        Component.element(
          tag: 'h2',
          classes: resolved.label.className,
          styles: resolved.label.inlineStyles,
          children: [label],
        ),
        if (action != null)
          Component.element(
            tag: 'div',
            classes: resolved.action.className,
            styles: resolved.action.inlineStyles,
            children: [
              IconTheme(
                data: IconThemeData(size: resolved.actionIconStyle.size),
                child: action!,
              ),
            ],
          ),
      ],
    );
  }
}

/// Chain sugar mirroring the Flutter `SidebarSection.withStyle` extension.
extension SidebarSectionStyleChain on SidebarSection {
  /// Returns a copy with [patch] merged into [sidebarSectionStyle] (patch
  /// fields win on conflict).
  SidebarSection withStyle(CoreSidebarSectionStyle patch) => copyWith(
    sidebarSectionStyle:
        (sidebarSectionStyle ?? const CoreSidebarSectionStyle()).merge(patch),
  );
}
