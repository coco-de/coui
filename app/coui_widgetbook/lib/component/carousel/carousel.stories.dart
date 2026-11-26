import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'carousel.stories.g.dart';

// Carousel widgetbook constants.
const _kDefaultItemCount = 5;
const _kSpacing = 16.0;
const _kCarouselHeight = 200.0;
const _kItemRadius = 12.0;
const _kItemMargin = 8.0;
const _kItemFontSize = 20.0;
const _kSlideGap = 16.0;
const _kAutoPlayInterval = Duration(seconds: 3);
const _kIndicatorAnimateDuration = Duration(milliseconds: 300);
const _kItemTextColor = Color(0xFFFFFFFF);

/// Item background colors cycled by the carousel demo.
const _kItemColors = [
  Color(0xFF64B5F6),
  Color(0xFF81C784),
  Color(0xFFFFB74D),
  Color(0xFFBA68C8),
  Color(0xFFE57373),
  Color(0xFF4DB6AC),
  Color(0xFFF06292),
  Color(0xFF7986CB),
  Color(0xFFFFD54F),
  Color(0xFF4DD0E1),
];

/// Interactive demo host for [Carousel] stories.
///
/// Owns the [CarouselController] shared by the carousel and the
/// clickable [DotIndicator] below it.
class CarouselDemo extends StatefulWidget {
  /// Creates a [CarouselDemo].
  const CarouselDemo({
    super.key,
    this.itemCount = _kDefaultItemCount,
    this.autoPlay = true,
    this.showIndicator = true,
  });

  /// Number of items in the carousel.
  final int itemCount;

  /// Whether the carousel advances automatically.
  final bool autoPlay;

  /// Whether the dot indicator is shown below the carousel.
  final bool showIndicator;

  @override
  State<CarouselDemo> createState() => _CarouselDemoState();
}

class _CarouselDemoState extends State<CarouselDemo> {
  final CarouselController _controller = CarouselController();

  Widget handleItemBuild(int index) {
    final actualIndex = index % widget.itemCount;

    return Container(
      decoration: BoxDecoration(
        color: _kItemColors[actualIndex % _kItemColors.length],
        borderRadius: const .all(
          .circular(_kItemRadius),
        ),
      ),
      margin: const .symmetric(horizontal: _kItemMargin),
      child: Center(
        child: Text(
          'Item ${actualIndex + 1}',
          style: const TextStyle(
            color: _kItemTextColor,
            fontSize: _kItemFontSize,
            fontWeight: .bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: .min,
        spacing: _kSpacing,
        children: [
          SizedBox(
            height: _kCarouselHeight,
            child: Carousel(
              itemBuilder: (_, index) => handleItemBuild(index),
              itemCount: widget.itemCount,
              transition: const CarouselTransition.sliding(gap: _kSlideGap),
              // The knob maps straight onto the widget's own flag. It used to
              // be translated into `duration: … : null` because the Flutter
              // widget ignored `autoPlay` and read the interval instead.
              autoPlay: widget.autoPlay,
              duration: _kAutoPlayInterval,
              controller: _controller,
            ),
          ),
          if (widget.showIndicator)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final current =
                    _controller.getCurrentIndex(widget.itemCount).round() %
                    widget.itemCount;

                return DotIndicator(
                  onChanged: (i) => _controller.animateTo(
                    i.toDouble(),
                    _kIndicatorAnimateDuration,
                  ),
                  index: current,
                  length: widget.itemCount,
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Navigation metadata for the Carousel component.
const kComponentMeta = ComponentMeta(name: 'Carousel', path: 'display');

/// Story metadata for [CarouselDemo].
const kMeta = Meta(CarouselDemo.new);

/// Auto-playing carousel with a clickable dot indicator.
final $Default = _Story();
