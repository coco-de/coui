import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/widgets.dart'
    show
        ConstrainedBox,
        Element,
        Focus,
        MouseRegion,
        Opacity,
        Semantics,
        SizedBox,
        Widget;

import 'box_padding_observation.dart';

/// An input omitted by an explicit production build branch, not by a search.
typedef SourceOmittedBoxSlot = ({Widget widget, String authority});

/// An actual primitive reached through its producer's declared build slot.
typedef SourceOwnedOutlinedFrame = ({Element primitive, String authority});

/// Source ownership only. The shared observer reads any measured values.
typedef AdditionalBoxProducerSource = ({
  String authority,
  List<Widget> supplied,
  List<SourceOmittedBoxSlot> sourceOmitted,
  SourceOwnedOutlinedFrame? outlinedFrame,
});

/// Describes audited public inputs and, where proven, their own shared frame.
///
/// A null description or frame does not establish padding zero. Unknown
/// producers and snapshot-derived content remain unsupported. No callback,
/// style resolver, measured value or canonical frame is used here.
AdditionalBoxProducerSource? describeAdditionalBoxProducerSource(
  Element producer,
) {
  final widget = producer.widget;
  if (widget is coui.CodeDiff && widget.runtimeType == coui.CodeDiff) {
    return _describe(
      producer,
      authority: 'CodeDiff accepts CoreCodeDiffLine data and void callbacks',
      supplied: const [],
      frame: _directOutlined(producer, 'CodeDiff.build return'),
    );
  }
  if (widget is coui.MockupCode && widget.runtimeType == coui.MockupCode) {
    return _describe(
      producer,
      authority: 'MockupCode accepts CoreCodeLine text data',
      supplied: const [],
      frame: _directOutlined(producer, 'MockupCode.build return'),
    );
  }
  if (widget is coui.MockupBrowser &&
      widget.runtimeType == coui.MockupBrowser) {
    return _describe(
      producer,
      authority: 'MockupBrowser.child',
      supplied: [?widget.child],
      frame: _directOutlined(producer, 'MockupBrowser.build return'),
    );
  }
  if (widget is coui.CodeSnippet && widget.runtimeType == coui.CodeSnippet) {
    final semantics = _generatedChild(producer);
    final semanticsWidget = semantics.widget;
    if (semanticsWidget is! Semantics ||
        semanticsWidget.child is! coui.Stacks) {
      throw _changed('CodeSnippet.build Semantics.child Stacks');
    }
    final stack = semanticsWidget.child! as coui.Stacks;
    if (stack.children.isEmpty ||
        stack.children[0] is! coui.OutlinedContainer) {
      throw _changed('CodeSnippet Stacks.children[0]');
    }
    final stackElement = _declaredChild(semantics, stack);
    return _describe(
      producer,
      authority: 'CodeSnippet.actions; onCopy returns void, not a Widget',
      supplied: widget.actions,
      frame: (
        primitive: _declaredChild(stackElement, stack.children[0]),
        authority: 'CodeSnippet.build Semantics.child Stacks.children[0]',
      ),
    );
  }
  if (widget is coui.ItemPicker && widget.runtimeType == coui.ItemPicker) {
    final mouse = _generatedChild(producer);
    final mouseWidget = mouse.widget;
    if (mouseWidget is! MouseRegion || mouseWidget.child == null) {
      throw _changed('ItemPicker.build MouseRegion.child');
    }
    return _describe(
      producer,
      authority: 'ItemPicker accepts String items and void callbacks',
      supplied: const [],
      frame: _outlinedChild(
        mouse,
        mouseWidget.child!,
        'ItemPicker MouseRegion',
      ),
    );
  }
  if (widget is coui.Command && widget.runtimeType == coui.Command) {
    final focus = _generatedChild(producer);
    final focusWidget = focus.widget;
    if (focusWidget is! Focus || focusWidget.child is! ConstrainedBox) {
      throw _changed('Command.build Focus.child ConstrainedBox');
    }
    final constrained = focusWidget.child as ConstrainedBox;
    final constrainedElement = _declaredChild(focus, constrained);
    if (constrained.child == null) {
      throw _changed('Command constrained panel');
    }
    return _describe(
      producer,
      authority: 'Command.emptyIcon/emptyAction and every group item.icon',
      supplied: [
        ?widget.emptyIcon,
        ?widget.emptyAction,
        for (final group in widget.groups)
          for (final item in group.items) ?item.icon,
      ],
      // Filtered or virtualized item slots are not declared absent by looking
      // at this tree. Missing originals therefore remain unsupported below.
      frame: _outlinedChild(
        constrainedElement,
        constrained.child!,
        'Command Focus.child ConstrainedBox.child',
      ),
    );
  }
  if (widget is coui.ObjectInput && widget.runtimeType == coui.ObjectInput) {
    final focus = _generatedChild(producer);
    final focusWidget = focus.widget;
    if (focusWidget is! Focus || focusWidget.child is! MouseRegion) {
      throw _changed('ObjectInput.build Focus.child MouseRegion');
    }
    final mouse = focusWidget.child as MouseRegion;
    if (mouse.child == null) throw _changed('ObjectInput MouseRegion.child');
    return _describe(
      producer,
      authority:
          'ObjectInput.leading/trailing; field models contain no Widgets',
      supplied: [?widget.leading, ?widget.trailing],
      frame: _outlinedChild(
        _declaredChild(focus, mouse),
        mouse.child!,
        'ObjectInput Focus.child MouseRegion.child',
      ),
    );
  }
  if (widget is coui.Fieldset && widget.runtimeType == coui.Fieldset) {
    final opacity = _generatedChild(producer);
    final opacityWidget = opacity.widget;
    if (opacityWidget is! Opacity || opacityWidget.child is! SizedBox) {
      throw _changed('Fieldset.build Opacity.child SizedBox');
    }
    final sized = opacityWidget.child! as SizedBox;
    final cast = sized.child;
    if (cast is! coui.InjectedCast) {
      throw _changed('Fieldset SizedBox.child InjectedCast');
    }
    final sizedElement = _declaredChild(opacity, sized);
    return _describe(
      producer,
      authority: 'Fieldset.legend/description/children',
      supplied: [?widget.legend, ?widget.description, ...widget.children],
      frame: _outlinedChild(
        _declaredChild(sizedElement, cast),
        cast.child,
        'Fieldset InjectedCast.child',
      ),
    );
  }
  if (widget is coui.TrendChart && widget.runtimeType == coui.TrendChart) {
    return _describe(
      producer,
      authority: 'TrendChart.summary/empty; valueFormatter returns String',
      supplied: [?widget.summary, ?widget.empty],
      sourceOmitted: [
        if (widget.points.isNotEmpty && widget.empty != null)
          (
            widget: widget.empty!,
            authority: 'TrendChart.build includes empty only if points.isEmpty',
          ),
      ],
    );
  }
  if (widget is coui.Accordion && widget.runtimeType == coui.Accordion) {
    return _describe(
      producer,
      authority: 'Accordion.items; private scope route not bound here',
      supplied: widget.items,
    );
  }
  if (widget is coui.AspectRatioBox &&
      widget.runtimeType == coui.AspectRatioBox) {
    return _describe(
      producer,
      authority: 'AspectRatioBox.child',
      supplied: [widget.child],
    );
  }
  if (widget is coui.Clickable && widget.runtimeType == coui.Clickable) {
    return _describe(
      producer,
      authority: 'Clickable.child',
      supplied: [widget.child],
    );
  }
  if (widget is coui.FocusOutline && widget.runtimeType == coui.FocusOutline) {
    return _describe(
      producer,
      authority: 'FocusOutline.child',
      supplied: [widget.child],
    );
  }
  if (widget is coui.Hover && widget.runtimeType == coui.Hover) {
    return _describe(
      producer,
      authority: 'Hover.child',
      supplied: [?widget.child],
    );
  }
  if (widget is coui.Indicator && widget.runtimeType == coui.Indicator) {
    return _describe(
      producer,
      authority: 'Indicator.child/item',
      supplied: [widget.child, widget.item],
    );
  }
  if (widget is coui.RefreshTrigger &&
      widget.runtimeType == coui.RefreshTrigger) {
    return _describe(
      producer,
      authority: 'RefreshTrigger.child; stage indicator is a separate unit',
      supplied: [widget.child],
    );
  }
  if (widget is coui.Stepper && widget.runtimeType == coui.Stepper) {
    return _describe(
      producer,
      authority:
          'Stepper CoreStepItem text data; per-item frames are separate units',
      supplied: const [],
    );
  }
  if (widget is coui.Steps && widget.runtimeType == coui.Steps) {
    return _describe(
      producer,
      authority: 'Steps CoreStepData data; per-item frames are separate units',
      supplied: const [],
    );
  }
  if (widget is coui.SwitchField && widget.runtimeType == coui.SwitchField) {
    return _describe(
      producer,
      authority: 'SwitchField String slots; nested Toggle is a separate unit',
      supplied: const [],
    );
  }
  if (widget is coui.MockupDevice && widget.runtimeType == coui.MockupDevice) {
    return _describe(
      producer,
      authority: 'MockupDevice.child; background frame is not a content owner',
      supplied: [widget.child],
    );
  }
  // Foldable snapshot ownership and Swiper's external overlay require their
  // own logical-unit declarations. Neither can be inferred from an ancestor.
  return null;
}

AdditionalBoxProducerSource _describe(
  Element producer, {
  required String authority,
  required List<Widget> supplied,
  List<SourceOmittedBoxSlot> sourceOmitted = const [],
  SourceOwnedOutlinedFrame? frame,
}) {
  final elements = boxElements(producer);
  for (final omission in sourceOmitted) {
    if (!supplied.any((input) => identical(input, omission.widget)) ||
        elements.any((element) => identical(element.widget, omission.widget))) {
      throw const BoxObservationError(
        'SOURCE_OMISSION_MISMATCH',
        'An omitted input must be supplied and absent at its declared branch.',
      );
    }
  }
  final scope = BoxProducerScope(
    producer: producer,
    suppliedSlots: supplied.where(
      (input) =>
          !sourceOmitted.any((omission) => identical(input, omission.widget)),
    ),
  );
  if (frame != null) scope.requireOwned(frame.primitive);
  return (
    authority: authority,
    supplied: List.unmodifiable(supplied),
    sourceOmitted: List.unmodifiable(sourceOmitted),
    outlinedFrame: frame,
  );
}

SourceOwnedOutlinedFrame _directOutlined(Element producer, String authority) {
  final frame = _generatedChild(producer);
  if (frame.widget is! coui.OutlinedContainer) throw _changed(authority);
  return (primitive: frame, authority: authority);
}

SourceOwnedOutlinedFrame _outlinedChild(
  Element parent,
  Widget child,
  String authority,
) {
  if (child is! coui.OutlinedContainer) throw _changed(authority);
  return (primitive: _declaredChild(parent, child), authority: authority);
}

Element _generatedChild(Element producer) {
  final children = <Element>[];
  producer.visitChildren(children.add);
  return requireOneBoxOwner(children, 'the declared production build return');
}

Element _declaredChild(Element parent, Widget child) => requireOneBoxOwner(
  boxElements(parent).where((element) => identical(element.widget, child)),
  'the exact Widget object in a declared production child slot',
);

BoxObservationError _changed(String authority) => BoxObservationError(
  'ADDITIONAL_BOX_SOURCE_CHANGED',
  'The actual build no longer matches $authority.',
);
