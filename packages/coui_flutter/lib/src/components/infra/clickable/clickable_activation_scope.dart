import 'package:flutter/foundation.dart' show internal;
import 'package:flutter/widgets.dart';

/// Internal opt-in callback for a containing control's trigger activation.
///
/// Intentionally absent from coui_flutter.dart, like TriggerTapDetector and
/// PopupScrollScope. It carries no style/state and creates no render object.
@internal
class ClickableActivationScope extends InheritedWidget {
  const ClickableActivationScope({
    required this.onActivate,
    required super.child,
    super.key,
  });

  final VoidCallback onActivate;

  static void activate(BuildContext context) {
    context
        .getInheritedWidgetOfExactType<ClickableActivationScope>()
        ?.onActivate();
  }

  @override
  bool updateShouldNotify(ClickableActivationScope oldWidget) =>
      onActivate != oldWidget.onActivate;
}
