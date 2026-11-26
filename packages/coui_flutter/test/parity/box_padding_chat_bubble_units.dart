import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/chat/chat_accent_example.dart';
import 'package:docs_core/previews/examples/flutter/chat/chat_error_example.dart';
import 'package:docs_core/previews/examples/flutter/chat/chat_info_example.dart';
import 'package:docs_core/previews/examples/flutter/chat/chat_neutral_example.dart';
import 'package:docs_core/previews/examples/flutter/chat/chat_primary_example.dart';
import 'package:docs_core/previews/examples/flutter/chat/chat_secondary_example.dart';
import 'package:docs_core/previews/examples/flutter/chat/chat_success_example.dart';
import 'package:docs_core/previews/examples/flutter/chat/chat_warning_example.dart';
import 'package:flutter/rendering.dart' show RenderDecoratedBox, RenderPadding;
import 'package:flutter/widgets.dart'
    show
        BoxDecoration,
        Builder,
        Column,
        ConstrainedBox,
        DecoratedBox,
        DefaultTextStyle,
        Element,
        KeyedSubtree,
        LayoutBuilder,
        Padding,
        Widget;

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

const _kUnit = 'documentation-chat-single-bubble-frame';
const _kAdapter = 'docs-chat-single-bubble-frame-v1';

/// A descendant body unit created by an exact parameterless official Example.
/// General Chat.bubble remains foreign; it is never promoted by this binder.
class ChatBubbleBoxSourceBinding {
  ChatBubbleBoxSourceBinding._(this._capture, this._resultWidget, this._route)
    : _chatWidget = _route.chat.widget,
      _bubbleWidget = _route.bubble.widget;

  final Element _capture;
  final Widget _resultWidget;
  final Widget _chatWidget;
  final Widget _bubbleWidget;
  final _Route _route;

  String get authority =>
      'Exact parameterless official Example owns its single source-created '
      'Chat.bubble; ChatBubble.child remains foreign. Mounted LayoutBuilder '
      'result and public child references bind the no-tail/no-border body; '
      'no builder, resolver or expected padding is evaluated.';
  Element get registryResultElement => _route.result;
  Element get fieldUnitElement => _route.frame;
  Element get paddingSource => _route.padding;
  Element get frameSource => _route.frame;
  BoxProducerScope get scope => _route.scope;
  String get readerId => 'current-render-padding-v1';

  /// Original inputs must remain current; generated frame Widgets may rebuild.
  void validateCurrentConstruction() {
    for (final pair in [
      (_route.result, _resultWidget),
      (_route.chat, _chatWidget),
      (_route.bubble, _bubbleWidget),
    ]) {
      if (!pair.$1.mounted || !identical(pair.$1.widget, pair.$2)) {
        throw _error('STALE_CHAT_BUBBLE_CONSTRUCTION');
      }
    }
    final current = _locate(_capture, _resultWidget);
    if (!identical(current.result, _route.result) ||
        !identical(current.chat, _route.chat) ||
        !identical(current.bubble, _route.bubble) ||
        !identical(current.frame, _route.frame) ||
        !identical(current.padding, _route.padding)) {
      throw _error('CHAT_BUBBLE_SOURCE_CHANGED');
    }
    for (final boundary in current.scope.foreignBoundaries) {
      if (!_route.scope.foreignBoundaries.any(
        (old) => identical(old, boundary),
      )) {
        throw _error('CHAT_BUBBLE_FOREIGN_BOUNDARY_CHANGED');
      }
    }
    if (current.scope.foreignBoundaries.length !=
        _route.scope.foreignBoundaries.length) {
      throw _error('CHAT_BUBBLE_FOREIGN_BOUNDARY_CHANGED');
    }
  }
}

/// Returns references only. The shared reader owns numeric observation.
ChatBubbleBoxSourceBinding? bindChatBubbleBoxSource({
  required Element captureRoot,
  required Widget registryResult,
  required BoxObservationSourceSpec source,
}) {
  if (source.logicalUnitId != _kUnit) return null;
  if (source.schemaVersion != 1) {
    throw _error('UNSUPPORTED_BOX_SOURCE_VERSION');
  }
  if (source.quantityId != BoxObservationSourceSpec.quantity ||
      source.nativeAdapterId != _kAdapter ||
      source.webAdapterId != _kAdapter) {
    throw _error('BOX_SOURCE_ADAPTER_UNIT_MISMATCH');
  }
  return ChatBubbleBoxSourceBinding._(
    captureRoot,
    registryResult,
    _locate(captureRoot, registryResult),
  );
}

typedef _Route = ({
  Element result,
  Element chat,
  Element bubble,
  Element frame,
  Element padding,
  BoxProducerScope scope,
});

_Route _locate(Element capture, Widget resultWidget) {
  const examples = <Type>{
    ChatAccentExample,
    ChatErrorExample,
    ChatInfoExample,
    ChatNeutralExample,
    ChatPrimaryExample,
    ChatSecondaryExample,
    ChatSuccessExample,
    ChatWarningExample,
  };
  if (!examples.contains(resultWidget.runtimeType)) {
    throw _error('UNREGISTERED_CHAT_BUBBLE_EXAMPLE');
  }
  final wrapper = capture.widget;
  if (!identical(wrapper, resultWidget) &&
      !(wrapper.runtimeType == KeyedSubtree &&
          identical((wrapper as KeyedSubtree).child, resultWidget))) {
    throw _error('MISMATCHED_CHAT_EXAMPLE_RESULT');
  }
  final result = _identity(capture, resultWidget);
  final column = _only(result);
  _concrete(column, Column);
  final children = (column.widget as Column).children;
  if (children.length != 1) throw _error('CHAT_SINGLE_EXAMPLE_CHANGED');
  final chat = _child(column, children.single);
  _concrete(chat, coui.Chat);
  final row = chat.widget as coui.Chat;
  if (row.avatar != null ||
      row.header != null ||
      row.footer != null ||
      row.chatStyle != null ||
      row.alignment != coui.CoreChatAlignment.start) {
    throw _error('CHAT_SINGLE_EXAMPLE_CHANGED');
  }
  final bubble = _identity(chat, row.bubble);
  _concrete(bubble, coui.ChatBubble);
  final input = bubble.widget as coui.ChatBubble;
  if (input.tail != null ||
      input.alignment != null ||
      input.chatBubbleStyle != null) {
    throw _error('CHAT_BUBBLE_INPUT_CHANGED');
  }
  // These Examples, not an arbitrary Chat caller, create this exact child.
  final declaration = DeclaredBoxProducer.bind(
    producer: bubble,
    sourceContract: 'renderer-frame-padding-v1',
  );
  final child = _identity(bubble, input.child);
  if (!declaration.scope.foreignBoundaries.any((e) => identical(e, child))) {
    throw _error('CHAT_BUBBLE_FOREIGN_BOUNDARY_CHANGED');
  }
  final layout = _only(bubble);
  _concrete(layout, LayoutBuilder);
  var frame = _only(layout); // The mounted result; never calls builder.
  _concrete(frame, ConstrainedBox);
  frame = _child(frame, (frame.widget as ConstrainedBox).child);
  if (frame.widget.runtimeType == coui.SurfaceBlur) {
    frame = _child(frame, (frame.widget as coui.SurfaceBlur).child);
  }
  // A tail Stacks/Position is not silently unwrapped into a body.
  _concrete(frame, DecoratedBox);
  final render = frame.renderObject;
  final decoration = (frame.widget as DecoratedBox).decoration;
  if (render is! RenderDecoratedBox ||
      decoration.runtimeType != BoxDecoration ||
      render.decoration.runtimeType != BoxDecoration ||
      (decoration as BoxDecoration).border != null ||
      (render.decoration as BoxDecoration).border != null) {
    throw _error('CHAT_BODY_BORDER_ALLOCATION_CHANGED');
  }
  final padding = _child(frame, (frame.widget as DecoratedBox).child);
  _concrete(padding, Padding);
  if (padding.renderObject is! RenderPadding) {
    throw _error('CHAT_BODY_RENDER_SOURCE_CHANGED');
  }
  // SDK3.50 DefaultTextStyle.merge returns this existing Builder. Its
  // mounted result, not a new callback invocation, is the actual style node.
  final styleBuilder = _child(padding, (padding.widget as Padding).child);
  _concrete(styleBuilder, Builder);
  final textStyle = _only(styleBuilder);
  _concrete(textStyle, DefaultTextStyle);
  if (!identical((textStyle.widget as DefaultTextStyle).child, input.child) ||
      !identical(_child(textStyle, input.child), child)) {
    throw _error('CHAT_BUBBLE_FOREIGN_BOUNDARY_CHANGED');
  }
  final scope = BoxProducerScope(
    producer: result,
    suppliedSlots: const [],
    derivedSuppliedElements: declaration.scope.foreignBoundaries,
  );
  [chat, bubble, frame, padding, styleBuilder, textStyle].forEach(
    scope.requireOwned,
  );
  return (
    result: result,
    chat: chat,
    bubble: bubble,
    frame: frame,
    padding: padding,
    scope: scope,
  );
}

Element _only(Element parent) {
  final children = <Element>[];
  parent.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the current ChatBubble source child');
}

Element _identity(Element parent, Widget widget) => requireOneBoxOwner(
  boxElements(parent).where((e) => identical(e.widget, widget)),
  'the exact source-created ChatBubble Widget identity',
);
Element _child(Element parent, Widget? child) {
  if (child == null) throw _error('CHAT_BUBBLE_SOURCE_CHANGED');
  return _identity(parent, child);
}

void _concrete(Element element, Type type) {
  if (element.widget.runtimeType != type) {
    throw _error('CHAT_BUBBLE_SOURCE_CHANGED');
  }
}

BoxObservationError _error(String code) => BoxObservationError(
  code,
  'The closed Example-owned bubble source is incomplete; no owner/value inferred.',
);
