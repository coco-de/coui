import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:widgetbook/widgetbook.dart';

part 'swiper.stories.g.dart';

const _kSwiperWidth = 400.0;
const _kSwiperHeight = 300.0;

/// Interactive demo host for [Swiper] stories.
class SwiperDemo extends StatefulWidget {
  /// Creates a [SwiperDemo].
  const SwiperDemo({
    super.key,
    this.position = CoreSwiperPosition.bottom,
    this.variant = CoreSwiperVariant.drawer,
    this.enabled = true,
    this.showDragHandle = true,
    this.barrierDismissible = true,
  });

  /// Edge from which the overlay slides in.
  final CoreSwiperPosition position;

  /// Overlay chrome variant.
  final CoreSwiperVariant variant;

  /// Whether the swiper reacts to gestures.
  final bool enabled;

  /// Whether the drag handle is shown.
  final bool showDragHandle;

  /// Whether tapping the barrier dismisses the overlay.
  final bool barrierDismissible;

  @override
  State<SwiperDemo> createState() => _SwiperDemoState();
}

class _SwiperDemoState extends State<SwiperDemo> {
  bool _open = false;

  void handleOpenChanged(bool open) {
    setState(() {
      _open = open;
    });
  }

  @override
  Widget build(BuildContext context) {
    final swiperStrings = t.widgetbook.swiper;

    return SizedBox(
      width: _kSwiperWidth,
      height: _kSwiperHeight,
      child: Swiper(
        overlayContent: Center(
          child: Padding(
            padding: const .all(CoreSpace.space24),
            child: Text(swiperStrings.overlay_content).bodyLarge(),
          ),
        ),
        position: widget.position,
        variant: widget.variant,
        open: _open,
        onOpenChanged: handleOpenChanged,
        enabled: widget.enabled,
        showDragHandle: widget.showDragHandle,
        barrierDismissible: widget.barrierDismissible,
        child: Center(
          child: Text(swiperStrings.swipe_hint).medium().onSurface(),
        ),
      ),
    );
  }
}

/// Navigation metadata for the Swiper component.
const kComponentMeta = ComponentMeta(name: 'Swiper', path: 'overlay');

/// Story metadata for [SwiperDemo].
const kMeta = Meta(SwiperDemo.new);

/// Bottom-edge swiper with editable knobs.
final $Default = _Story();
