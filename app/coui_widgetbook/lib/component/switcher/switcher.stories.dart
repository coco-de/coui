import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'switcher.stories.g.dart';

const _kSwitcherHeight = 200.0;
const _kMaxPageIndex = 2;
const _kTotalPages = 3;
const _kPage1Color = Color(0xFF3B82F6);
const _kPage2Color = Color(0xFF22C55E);
const _kPage3Color = Color(0xFFF97316);
const _kPageForeground = Color(0xFFFFFFFF);

/// Interactive demo host for [Switcher] stories.
///
/// Owns the current page index and exposes previous / next buttons so
/// the transition can be triggered without gestures as well.
class SwitcherDemo extends StatefulWidget {
  /// Creates a [SwitcherDemo].
  const SwitcherDemo({
    super.key,
    this.direction = CoreSwitcherDirection.right,
    this.gestureEnabled = true,
  });

  /// Slide direction of the transition.
  final CoreSwitcherDirection direction;

  /// Whether drag gestures switch pages.
  final bool gestureEnabled;

  @override
  State<SwitcherDemo> createState() => _SwitcherDemoState();
}

class _SwitcherDemoState extends State<SwitcherDemo> {
  int _index = 0;

  void handlePrevious() {
    setState(() => _index -= 1);
  }

  void handleNext() {
    setState(() => _index += 1);
  }

  static Widget _page(String label, Color color) {
    return ColoredBox(
      color: color,
      child: Center(
        child: Text(label, style: const TextStyle(color: _kPageForeground)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      spacing: CoreSpace.space16,
      children: [
        SizedBox(
          height: _kSwitcherHeight,
          child: Switcher(
            items: [
              _page('Page 1', _kPage1Color),
              _page('Page 2', _kPage2Color),
              _page('Page 3', _kPage3Color),
            ],
            index: _index,
            direction: widget.direction,
            gestureEnabled: widget.gestureEnabled,
            onIndexChanged: (index) => setState(() => _index = index),
          ),
        ),
        Row(
          mainAxisAlignment: .center,
          spacing: CoreSpace.space8,
          children: [
            Button(
              onPressed: _index > 0 ? handlePrevious : null,
              variant: .outline,
              child: const Text('Previous'),
            ),
            Text('Page ${_index + 1} of $_kTotalPages'),
            Button(
              onPressed: _index < _kMaxPageIndex ? handleNext : null,
              variant: .outline,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Navigation metadata for the Switcher component.
const kComponentMeta = ComponentMeta(name: 'Switcher', path: 'navigation');

/// Story metadata for [SwitcherDemo].
const kMeta = Meta(SwitcherDemo.new);

/// Interactive switcher with direction and gesture knobs.
final $Default = _Story();
