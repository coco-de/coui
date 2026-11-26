import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'toast.stories.g.dart';

/// Default toast display duration in seconds.
const _kDefaultDurationSeconds = 3;

/// Interactive demo host for [Toast] stories.
///
/// Renders a trigger button that shows a [Toast] through the app-level
/// [ToastLayer] when pressed.
class ToastDemo extends StatelessWidget {
  /// Creates a [ToastDemo].
  const ToastDemo({
    super.key,
    this.location = ToastLocation.bottomRight,
    this.durationSeconds = _kDefaultDurationSeconds,
    this.message = 'Changes saved.',
    this.description = 'Your data has been updated successfully.',
  });

  /// Screen location where the toast appears.
  final ToastLocation location;

  /// How long the toast stays visible, in seconds.
  final int durationSeconds;

  /// Toast headline message.
  final String message;

  /// Toast supporting description.
  final String description;

  /// Shows a [Toast] at [location] for [durationSeconds] seconds.
  void handleShowToast(BuildContext context) {
    final _ = showToast(
      context: context,
      location: location,
      showDuration: Duration(seconds: durationSeconds),
      builder: (context, overlay) => Toast(
        message: message,
        description: description,
        onDismiss: overlay.close,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () => handleShowToast(context),
      child: const Text('Show Toast'),
    );
  }
}

/// Navigation metadata for the Toast component.
const kComponentMeta = ComponentMeta(name: 'Toast', path: 'overlay');

/// Story metadata for [ToastDemo].
const kMeta = Meta(ToastDemo.new);

/// Trigger button showing a toast with editable knobs.
final $Default = _Story();

/// Toast anchored to the top-left corner.
final $TopLeft = _Story(
  name: 'Top Left',
  args: _Args(
    location: EnumArg(ToastLocation.topLeft, values: ToastLocation.values),
  ),
);

/// Toast anchored to the top-center edge.
final $TopCenter = _Story(
  name: 'Top Center',
  args: _Args(
    location: EnumArg(ToastLocation.topCenter, values: ToastLocation.values),
  ),
);

/// Toast anchored to the top-right corner.
final $TopRight = _Story(
  name: 'Top Right',
  args: _Args(
    location: EnumArg(ToastLocation.topRight, values: ToastLocation.values),
  ),
);

/// Toast anchored to the bottom-left corner.
final $BottomLeft = _Story(
  name: 'Bottom Left',
  args: _Args(
    location: EnumArg(ToastLocation.bottomLeft, values: ToastLocation.values),
  ),
);

/// Toast anchored to the bottom-center edge.
final $BottomCenter = _Story(
  name: 'Bottom Center',
  args: _Args(
    location: EnumArg(
      ToastLocation.bottomCenter,
      values: ToastLocation.values,
    ),
  ),
);

/// Toast anchored to the bottom-right corner (default location).
final $BottomRight = _Story(
  name: 'Bottom Right',
  args: _Args(
    location: EnumArg(
      ToastLocation.bottomRight,
      values: ToastLocation.values,
    ),
  ),
);
