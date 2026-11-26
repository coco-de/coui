import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/components/form/form_label/form_label_style.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;

/// A unified label for form fields for CoUI Web.
///
/// `FormLabel` renders descriptive text for a form input with an
/// optional required indicator (`*`) appended after the label. It is
/// the unified replacement for the legacy Web and Flutter `FormLabel`
/// — same parameter names, same semantics, full visual parity.
///
/// When [isRequired] is `true`, the [requiredIndicator] is shown after
/// the label; when no custom indicator is supplied an error-coloured
/// asterisk is rendered.
///
/// Every chrome / typography override flows through the single
/// [formLabelStyle] field — see [CoreFormLabelStyle] for the merge
/// chain.
///
/// Mirrors Flutter `FormLabel` 1:1 — same parameter names, same
/// semantics.
///
/// ```dart
/// FormLabel(label: Text('Email Address'))
/// FormLabel(label: Text('Password'), isRequired: true)
/// ```
class FormLabel extends UiComponent
    implements CoreFormLabelContract<Component> {
  /// Creates a [FormLabel].
  const FormLabel({
    this.label,
    this.isRequired = false,
    this.requiredIndicator,
    this.size = CoreFormLabelStyle.defaultSize,
    this.enabled = true,
    this.formLabelStyle,
    super.key,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
  }) : super(tag: 'label');

  @override
  final Component? label;

  @override
  final bool isRequired;

  @override
  final Component? requiredIndicator;

  @override
  final CoreComponentSize size;

  @override
  final bool enabled;

  @override
  final CoreFormLabelStyle? formLabelStyle;
  @override
  Component build(BuildContext context) {
    final resolved = resolveFormLabel(
      context,
      size: size,
      enabled: enabled,
      formLabelStyle: formLabelStyle,
    );

    final children = <Component>[
      ?label,
      if (isRequired)
        requiredIndicator ??
            Component.element(
              tag: 'span',
              classes: resolved.required.className,
              styles: resolved.required.inlineStyles,
              attributes: const {'aria-hidden': 'true'},
              children: [Text('*')],
            ),
    ];

    return Component.element(
      tag: tag,
      id: id,
      classes: [
        resolved.root.className,
        ?classes,
      ].join(' ').trim(),
      styles: Styles.combine([
        ?resolved.root.inlineStyles,
        ?css,
      ]),
      attributes: componentAttributes,
      events: events,
      children: children,
    );
  }

  @override
  FormLabel copyWith({
    Component? label,
    bool? isRequired,
    Component? requiredIndicator,
    CoreComponentSize? size,
    bool? enabled,
    CoreFormLabelStyle? formLabelStyle,
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
  }) {
    return FormLabel(
      key: key ?? this.key,
      label: label ?? this.label,
      isRequired: isRequired ?? this.isRequired,
      requiredIndicator: requiredIndicator ?? this.requiredIndicator,
      size: size ?? this.size,
      enabled: enabled ?? this.enabled,
      formLabelStyle: formLabelStyle ?? this.formLabelStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
    );
  }
}

/// Chain sugar mirroring the Flutter `FormLabel.withStyle` extension —
/// merges a [CoreFormLabelStyle] patch into [FormLabel.formLabelStyle] via
/// the existing [FormLabel.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFormLabelStyle.merge` right-side-wins semantics).
extension FormLabelStyleChain on FormLabel {
  /// Returns a copy of this [FormLabel] with [patch] merged into
  /// [formLabelStyle] (patch fields win on conflict).
  FormLabel withStyle(CoreFormLabelStyle patch) => copyWith(
    formLabelStyle: (formLabelStyle ?? const CoreFormLabelStyle()).merge(patch),
  );
}
