import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/components/display/label/label_style.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// Unified cross-platform label for CoUI Web.
///
/// Renders a `<span>`-based static text label suitable for form fields,
/// with an optional leading icon and required indicator (`*`).
///
/// Chrome / dimensional / text-style overrides flow through the single
/// [labelStyle] slot. Style resolution is delegated to [resolveLabel]
/// in `label_style.dart` (single entry point).
///
/// Example:
/// ```dart
/// Label(
///   text: 'Email',
///   isRequired: true,
/// )
/// ```
class Label extends UiComponent implements CoreLabelContract<Component> {
  /// Creates a [Label].
  const Label({
    required this.text,
    super.key,
    this.icon,
    this.isRequired = false,
    this.disabled = false,
    this.semanticLabel,
    @Deprecated(
      'Label does not wire htmlFor to a control on either platform — use '
      'FormField, which links label and control (since 0.147)',
    )
    this.htmlFor,
    this.labelStyle,
    super.attributes,
    super.classes,
    super.css,
    super.id,
  }) : super(tag: 'span');

  @override
  final String text;

  @override
  final Component? icon;

  @override
  final bool isRequired;

  @override
  final bool disabled;

  @override
  final String? semanticLabel;

  @override
  @Deprecated(
    'Label does not wire htmlFor to a control on either platform — use '
    'FormField, which links label and control (since 0.147)',
  )
  final String? htmlFor;

  @override
  final CoreLabelStyle? labelStyle;

  @override
  Label copyWith({
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    String? id,
    Key? key,
    String? text,
    Component? icon,
    bool? isRequired,
    bool? disabled,
    String? semanticLabel,
    @Deprecated(
      'Label does not wire htmlFor to a control on either platform — use '
      'FormField, which links label and control (since 0.147)',
    )
    String? htmlFor,
    CoreLabelStyle? labelStyle,
  }) {
    return Label(
      key: key ?? this.key,
      text: text ?? this.text,
      icon: icon ?? this.icon,
      isRequired: isRequired ?? this.isRequired,
      disabled: disabled ?? this.disabled,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      htmlFor: htmlFor ?? this.htmlFor,
      labelStyle: labelStyle ?? this.labelStyle,
      attributes: attributes ?? componentAttributes,
      classes: mergeClasses(classes, this.classes),
      css: css ?? this.css,
      id: id ?? this.id,
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveLabel(
      context,
      disabled: disabled,
      labelStyle: labelStyle,
    );

    final containerClasses = <String>[
      resolved.root.className,
      if (classes case final extra? when extra.isNotEmpty) extra,
    ].join(' ');

    final containerInline = resolved.root.inlineStyles;
    final mergedCss = containerInline == null
        ? css
        : Styles.combine([containerInline, ?css]);

    final attrs = <String, String>{...componentAttributes};
    // Deprecated — `for` is meaningless on a `<span>` (HTML only wires
    // it on `<label>`/`<output>`). Kept only for source compatibility
    // until the two-minor removal window closes. Use `FormField` for
    // an actual label/control association.
    final forAttr = htmlFor;
    if (forAttr != null) attrs['for'] = forAttr;
    final aria = semanticLabel;
    if (aria != null) attrs['aria-label'] = aria;

    final iconChild = icon;

    return Component.element(
      tag: 'span',
      id: id,
      classes: containerClasses,
      styles: mergedCss,
      attributes: attrs,
      events: events,
      children: [
        if (iconChild != null) ...[
          span(
            [
              IconTheme(
                data: IconThemeData(size: resolved.iconStyle.size),
                child: iconChild,
              ),
            ],
            classes: resolved.iconWrapper.className,
            styles: resolved.iconWrapper.inlineStyles,
          ),
          Gap(gapStyle: resolved.iconLabelGapStyle),
        ],
        Text(text),
        if (isRequired) ...[
          Gap(gapStyle: resolved.labelRequiredGapStyle),
          span(
            const [Text('*')],
            classes: resolved.requiredIndicator.className,
            styles: resolved.requiredIndicator.inlineStyles,
          ),
        ],
      ],
    );
  }
}

/// Chain sugar mirroring the Flutter `Label.withStyle` extension —
/// merges a [CoreLabelStyle] patch into [Label.labelStyle] via the
/// existing [Label.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreLabelStyle.merge` right-side-wins semantics).
extension LabelStyleChain on Label {
  /// Returns a copy of this [Label] with [patch] merged into
  /// [labelStyle] (patch fields win on conflict).
  Label withStyle(CoreLabelStyle patch) =>
      copyWith(labelStyle: (labelStyle ?? const CoreLabelStyle()).merge(patch));
}
