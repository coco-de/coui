import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/label/label_default_example.dart';
import 'package:docs_core/previews/examples/flutter/label/label_disabled_example.dart';
import 'package:docs_core/previews/examples/flutter/label/label_required_example.dart';
import 'package:docs_core/previews/examples/flutter/label/label_with_icon_example.dart';
import 'package:docs_core/previews/examples/flutter/link/link_default_example.dart';
import 'package:docs_core/previews/examples/flutter/link/link_external_example.dart';
import 'package:docs_core/previews/examples/flutter/link/link_icons_example.dart';
import 'package:docs_core/previews/examples/flutter/link/link_muted_example.dart';
import 'package:docs_core/previews/examples/flutter/link/link_underline_example.dart';
import 'package:flutter/rendering.dart' show RenderFlex, RenderStack;
import 'package:flutter/widgets.dart'
    show
        AnimatedDefaultTextStyle,
        BoxDecoration,
        Builder,
        Container,
        EdgeInsets,
        Element,
        FocusableActionDetector,
        GestureDetector,
        IconTheme,
        KeyedSubtree,
        Listener,
        MainAxisSize,
        MouseRegion,
        Opacity,
        Positioned,
        Row,
        SelectionContainer,
        Semantics,
        Stack,
        StackFit,
        Transform,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

/// A closed source witness, created after validating the mounted route.
///
/// The absence concerns this generated host's own allocation operation. Foreign
/// child padding, icon gaps and positioned focus-ring paint remain separate.
/// Source-frozen component/framework operations supply authority; private RTTI
/// and a same-looking Row alone do not authenticate an operation.
class InlineHostBoxSourceBinding {
  InlineHostBoxSourceBinding._({
    required this.authority,
    required this.registryResultElement,
    required this.fieldUnitElement,
    required this.paddingSource,
    required this.frameSource,
    required this.scope,
    required this.absenceKind,
    required Element producer,
    required Widget registryResultWidget,
    required Widget producerWidget,
  }) : _producer = producer,
       _registryResultWidget = registryResultWidget,
       _producerWidget = producerWidget;

  final String authority;
  final Element registryResultElement;
  final Element fieldUnitElement;
  final Element paddingSource;
  final Element frameSource;
  final BoxProducerScope scope;
  final String absenceKind;
  final Element _producer;
  final Widget _registryResultWidget;
  final Widget _producerWidget;

  String get readerId => 'inline-host-declared-absence-v1';

  /// Revalidates this particular live host before reporting supported absence.
  ///
  /// This is not a generic missing-Padding fallback. The constructor is private
  /// and the source route, actual render class and frame allocation are checked
  /// again on every read; no measured value is used to select an owner.
  BoxPaddingObservation readDeclaredAbsence() {
    if (!_producer.mounted || !registryResultElement.mounted) {
      throw _changed('the still-mounted construction result');
    }
    if (!identical(registryResultElement.widget, _registryResultWidget) ||
        !identical(_producer.widget, _producerWidget)) {
      throw _changed('the originally bound construction Widget identities');
    }
    final frame = absenceKind == 'label-row-no-own-inset'
        ? _label(_producer, scope)
        : _link(_producer, scope);
    if (!identical(frame, frameSource)) {
      throw _changed('the originally bound generated frame');
    }
    scope.requireOwned(frame);
    return BoxPaddingObservation(
      value: EdgeInsets.zero,
      quantity: PaddingQuantityKind.declaredNoOwnPadding,
      owner: frame,
      producer: _producer,
      contentBoundary: frame,
      paddingElement: null,
      currentRenderPadding: EdgeInsets.zero,
      allocatedDecorationInsets: EdgeInsets.zero,
      excludedMargin: EdgeInsets.zero,
      generatedSlots: [
        {'sourceContract': absenceKind, 'authority': authority},
      ],
      frameOwner: frame,
    );
  }
}

/// Binds an exact official example/public component without invoking its build.
InlineHostBoxSourceBinding? bindInlineHostBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  final label = switch (source.logicalUnitId) {
    'label-generated-inline-host' => true,
    'link-generated-inline-host' => false,
    _ => null,
  };
  if (label == null) return null;
  if (source.schemaVersion != 1) {
    throw const BoxObservationError(
      'UNSUPPORTED_BOX_SOURCE_VERSION',
      'The inline host requires source schema 1.',
    );
  }
  final adapter = '${source.logicalUnitId}-v1';
  if (source.quantityId != BoxObservationSourceSpec.quantity ||
      source.nativeAdapterId != adapter ||
      source.webAdapterId != adapter) {
    throw const BoxObservationError(
      'BOX_SOURCE_ADAPTER_UNIT_MISMATCH',
      'The closed inline host and both source adapters must agree.',
    );
  }
  final root = captureRoot.widget;
  if (!identical(root, registryResult) &&
      !(root.runtimeType == KeyedSubtree &&
          identical((root as KeyedSubtree).child, registryResult))) {
    throw _changed('the capture result Widget identity');
  }
  final result = _identity(captureRoot, registryResult);
  final producerType = label ? coui.Label : coui.Link;
  final examples = label
      ? const <Type>[
          LabelDefaultExample,
          LabelRequiredExample,
          LabelWithIconExample,
          LabelDisabledExample,
        ]
      : const <Type>[
          LinkDefaultExample,
          LinkMutedExample,
          LinkUnderlineExample,
          LinkExternalExample,
          LinkIconsExample,
        ];
  if (registryResult.runtimeType != producerType &&
      !examples.contains(registryResult.runtimeType)) {
    throw const BoxObservationError(
      'UNREGISTERED_COMPONENT_CONSTRUCTION',
      'Only the exact public producer or frozen official example is supported.',
    );
  }
  final producer = registryResult.runtimeType == producerType
      ? result
      : _only(result);
  _concrete(producer, producerType);
  final supplied = label
      ? <Widget>[?(producer.widget as coui.Label).icon]
      : <Widget>[
          ?(producer.widget as coui.Link).child,
          ?(producer.widget as coui.Link).leading,
          ?(producer.widget as coui.Link).trailing,
        ];
  // Validate multiplicity before the shared scope's membership Set is built.
  // A duplicate slot/actual Element must never disappear through de-duplication.
  for (var i = 0; i < supplied.length; i++) {
    if (supplied.take(i).any((slot) => identical(slot, supplied[i]))) {
      throw const BoxObservationError(
        'DUPLICATE_SUPPLIED_SLOT_IDENTITY',
        'The inline source requires a unique actual identity per public slot.',
      );
    }
  }
  for (final slot in supplied) {
    _identity(producer, slot);
  }
  final declared = DeclaredBoxProducer.bind(
    producer: producer,
    sourceContract: 'renderer-frame-padding-v1',
  );
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declared.scope.foreignBoundaries,
  );
  final frame = label ? _label(producer, scope) : _link(producer, scope);
  return InlineHostBoxSourceBinding._(
    authority:
        'Exact returned Widget identity and frozen component/framework build '
        'operations; ${declared.authority}; own generated host only. Foreign '
        'content and positioned overlays cannot donate an inset.',
    registryResultElement: result,
    fieldUnitElement: frame,
    paddingSource: frame,
    frameSource: frame,
    scope: scope,
    absenceKind: label
        ? 'label-row-no-own-inset'
        : 'link-interaction-stack-no-own-inset',
    producer: producer,
    registryResultWidget: registryResult,
    producerWidget: producer.widget,
  );
}

Element _label(Element producer, BoxProducerScope scope) {
  _concrete(producer, coui.Label);
  final widget = producer.widget as coui.Label;
  var row = _only(producer);
  // The two optional source Semantics wrappers do not allocate an inset.
  for (var i = 0; i < 2 && row.widget.runtimeType == Semantics; i++) {
    row = _child(row, (row.widget as Semantics).child);
  }
  if (widget.disabled) {
    _concrete(row, MouseRegion);
    row = _child(row, (row.widget as MouseRegion).child);
    _concrete(row, Opacity);
    row = _child(row, (row.widget as Opacity).child);
  }
  _concrete(row, Row);
  final host = row.widget as Row;
  if (host.mainAxisSize != MainAxisSize.min) {
    throw _changed('Label source Row allocation');
  }
  final children = host.children;
  final icon = widget.icon;
  final expected = 1 + (icon == null ? 0 : 2) + (widget.isRequired ? 2 : 0);
  if (children.length != expected) throw _changed('Label generated cells');
  var index = 0;
  if (icon != null) {
    final iconTheme = _child(row, children[index++]);
    _concrete(iconTheme, IconTheme);
    if (!identical((iconTheme.widget as IconTheme).child, icon)) {
      throw _changed('the supplied Label icon identity');
    }
    _concrete(_child(row, children[index++]), coui.Gap);
  }
  _concrete(_child(row, children[index++]), coui.Text);
  if (widget.isRequired) {
    _concrete(_child(row, children[index++]), coui.Gap);
    _concrete(_child(row, children[index]), coui.Text);
  }
  scope.requireOwned(row);
  if (row.renderObject.runtimeType != RenderFlex) {
    throw _changed('the actual generated RenderFlex');
  }
  return row;
}

Element _link(Element producer, BoxProducerScope scope) {
  _concrete(producer, coui.Link);
  final widget = producer.widget as coui.Link;
  if (widget.onPressed != null) {
    throw _changed('the navigation-only Link branch');
  }
  final clickable = _only(producer);
  _concrete(clickable, coui.Clickable);
  final interaction = clickable.widget as coui.Clickable;
  if (!interaction.enabled ||
      !interaction.focusOutline ||
      interaction.marginAlignment != null) {
    throw _changed('Link source interaction allocation');
  }
  final text = _child(clickable, interaction.child);
  _concrete(text, AnimatedDefaultTextStyle);
  final content = _child(text, (text.widget as AnimatedDefaultTextStyle).child);
  _concrete(content, Semantics);
  _linkContent(content, widget, scope);

  final outline = _only(clickable);
  _concrete(outline, coui.FocusOutline);
  final semantic = _child(outline, (outline.widget as coui.FocusOutline).child);
  _concrete(semantic, Semantics);
  final stacks = _only(outline);
  _concrete(stacks, coui.Stacks);
  final layers = (stacks.widget as coui.Stacks).children;
  if (layers.length < 2 ||
      layers.length > 3 ||
      layers.where((child) => identical(child, semantic.widget)).length != 1 ||
      layers.any(
        (child) =>
            !identical(child, semantic.widget) &&
            child.runtimeType != coui.Position,
      )) {
    throw _changed('the single non-positioned Link content layer');
  }
  final stack = _only(stacks);
  _concrete(stack, Stack);
  final frame = stack.widget as Stack;
  if (frame.fit != StackFit.passthrough ||
      frame.children.length != layers.length ||
      !List.generate(
        layers.length,
        (i) => identical(layers[i], frame.children[i]),
      ).every((same) => same)) {
    throw _changed('the actual passthrough Stack child identities');
  }
  for (final layer in layers.where(
    (child) => child.runtimeType == coui.Position,
  )) {
    final position = _child(stacks, layer);
    final positioned = _only(position);
    _concrete(positioned, Positioned);
    if (!identical(
      (positioned.widget as Positioned).child,
      (position.widget as coui.Position).child,
    )) {
      throw _changed('the source-positioned decorative overlay');
    }
  }
  final listener = _child(semantic, (semantic.widget as Semantics).child);
  _concrete(listener, Listener);
  final detector = _child(listener, (listener.widget as Listener).child);
  _concrete(detector, GestureDetector);
  final focus = _child(detector, (detector.widget as GestureDetector).child);
  _concrete(focus, FocusableActionDetector);
  final feedback = _child(
    focus,
    (focus.widget as FocusableActionDetector).child,
  );
  var transform = _only(feedback);
  if (transform.widget.runtimeType == Container) {
    final container = transform.widget as Container;
    if (container.padding != null ||
        container.margin != null ||
        container.constraints != null ||
        container.alignment != null ||
        container.foregroundDecoration != null ||
        (container.decoration != null &&
            (container.decoration.runtimeType != BoxDecoration ||
                (container.decoration! as BoxDecoration).border != null))) {
      throw _changed('feedback chrome without layout allocation');
    }
    transform = _child(transform, container.child);
  }
  _concrete(transform, Transform);
  final selection = _child(transform, (transform.widget as Transform).child);
  _concrete(selection, SelectionContainer);
  if (!identical((selection.widget as SelectionContainer).child, text.widget)) {
    throw _changed('the feedback public content identity');
  }
  scope
    ..requireOwned(text)
    ..requireOwned(content)
    ..requireOwned(stack);
  if (stack.renderObject.runtimeType != RenderStack) {
    throw _changed('the actual interaction RenderStack');
  }
  return stack;
}

void _linkContent(Element content, coui.Link widget, BoxProducerScope scope) {
  var label = _child(content, (content.widget as Semantics).child);
  if (widget.leading == null && widget.trailing == null) {
    if (widget.child != null && !identical(label.widget, widget.child)) {
      throw _changed('the supplied Link child identity');
    }
    if (widget.child == null) _concrete(label, coui.Text);
    return;
  }
  // IconTheme.merge is the frozen framework Builder operation, not RTTI for
  // the Link's private State and not a second invocation of its builder.
  _concrete(label, Builder);
  label = _only(label);
  _concrete(label, IconTheme);
  final row = _child(label, (label.widget as IconTheme).child);
  _concrete(row, Row);
  scope.requireOwned(row);
  final children = (row.widget as Row).children;
  if (children.length !=
      1 +
          (widget.leading == null ? 0 : 2) +
          (widget.trailing == null ? 0 : 2)) {
    throw _changed('Link icon cells');
  }
  var index = 0;
  if (widget.leading != null) {
    if (!identical(children[index++], widget.leading)) {
      throw _changed('the supplied leading Link identity');
    }
    _concrete(_child(row, children[index++]), coui.Gap);
  }
  if (widget.child != null && !identical(children[index], widget.child)) {
    throw _changed('the supplied Link label identity');
  }
  if (widget.child == null) _concrete(_child(row, children[index]), coui.Text);
  index++;
  if (widget.trailing != null) {
    _concrete(_child(row, children[index++]), coui.Gap);
    if (!identical(children[index], widget.trailing)) {
      throw _changed('the supplied trailing Link identity');
    }
  }
}

Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(
    children,
    'the exact inline source operation child',
  );
}

Element _identity(Element parent, Widget widget) => requireOneBoxOwner(
  boxElements(parent).where((element) => identical(element.widget, widget)),
  'the actual inline source Widget identity',
);

Element _child(Element parent, Widget? child) {
  if (child == null) throw _changed('a required generated child');
  return _identity(parent, child);
}

void _concrete(Element element, Type type) {
  if (element.widget.runtimeType != type) {
    throw _changed('the exact concrete source Widget $type');
  }
}

BoxObservationError _changed(String slot) => BoxObservationError(
  'INLINE_HOST_SOURCE_CHANGED',
  'Unsupported or missing $slot; no owner or absent value is inferred.',
);
