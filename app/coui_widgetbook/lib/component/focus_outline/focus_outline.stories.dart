import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook/widgetbook.dart';

part 'focus_outline.stories.g.dart';

/// Knob input for [FocusOutline] stories.
class FocusOutlineInput {
  /// Creates a [FocusOutlineInput].
  const FocusOutlineInput({
    this.focused = true,
    this.shape = CoreFocusOutlineShape.rectangle,
  });

  /// Whether the focus ring is visible.
  final bool focused;

  /// Outline shape.
  final CoreFocusOutlineShape shape;
}

/// Navigation metadata for the FocusOutline component.
const kComponentMeta = ComponentMeta(name: 'FocusOutline', path: 'infra');

/// Story metadata for [FocusOutline].
const kMeta = Meta(FocusOutline.new, argsType: FocusOutlineInput.new);

/// Default builder mapping [FocusOutlineInput] args to a [FocusOutline].
final FocusOutlineDefaults defaults = _Defaults(
  builder: (context, args) => FocusOutline(
    focused: args.focused,
    shape: args.shape,
    child: Container(
      padding: const .symmetric(
        vertical: CoreSpace.space8,
        horizontal: CoreSpace.space16,
      ),
      decoration: const BoxDecoration(
        border: Border.fromBorderSide(
          .new(color: material.Colors.grey),
        ),
        borderRadius: .all(
          .circular(CoreRadius.radius4),
        ),
      ),
      child: const Text('Focusable Element'),
    ),
  ),
);

/// Focused rectangle outline with editable knobs.
final $Default = _Story();

/// Circle-shaped focus outline.
final $Circle = _Story(
  args: _Args(
    shape: EnumArg(
      CoreFocusOutlineShape.circle,
      values: CoreFocusOutlineShape.values,
    ),
  ),
);
