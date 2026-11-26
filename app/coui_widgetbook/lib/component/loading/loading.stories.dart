import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:widgetbook/widgetbook.dart';

part 'loading.stories.g.dart';

// Loading widgetbook constants.
const _kContainerWidth = 300.0;
const _kProgressIncrement = 0.1;
const _kPercentMultiplier = 100;

/// Interactive demo host for [Loading] stories.
///
/// Shows the [Loading] indicator itself, or — in progress mode — an
/// interactive radial / linear progress showcase driven by a button.
class LoadingDemo extends StatefulWidget {
  /// Creates a [LoadingDemo].
  const LoadingDemo({
    super.key,
    this.variant = CoreLoadingVariant.spinner,
    this.componentSize,
    this.showProgress = false,
  });

  /// Loading indicator variant.
  final CoreLoadingVariant variant;

  /// Loading indicator size.
  final CoreComponentSize? componentSize;

  /// Whether the interactive radial / linear progress showcase is
  /// shown instead of the plain indicator.
  final bool showProgress;

  @override
  State<LoadingDemo> createState() => _LoadingDemoState();
}

class _LoadingDemoState extends State<LoadingDemo> {
  double _progress = 0;

  void handleIncrementProgress() {
    setState(() {
      _progress = (_progress + _kProgressIncrement).clamp(0.0, 1.0);
      if (_progress >= 1.0) {
        _progress = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showProgress) {
      return Loading(
        variant: widget.variant,
        componentSize: widget.componentSize,
      );
    }

    final loadingLabels = t.widgetbook.loading;
    final percentText = '${(_progress * _kPercentMultiplier).toInt()}%';

    return Column(
      mainAxisSize: .min,
      spacing: CoreSpace.space16,
      children: [
        Button(
          onPressed: handleIncrementProgress,
          child: Text(t.widgetbook.common.increment_progress),
        ),
        SizedBox(
          width: _kContainerWidth,
          child: Column(
            spacing: CoreSpace.space16,
            children: [
              Column(
                mainAxisSize: .min,
                spacing: CoreSpace.space8,
                children: [
                  Text(loadingLabels.circular_progress).semiBold(),
                  RadialProgress(value: _progress),
                  Text(percentText).bodySmall().onSurface(),
                ],
              ),
              Column(
                mainAxisSize: .min,
                spacing: CoreSpace.space8,
                children: [
                  Text(loadingLabels.linear_progress).semiBold(),
                  Progress(value: _progress),
                  Text(percentText).bodySmall().onSurface(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Navigation metadata for the Loading component.
const kComponentMeta = ComponentMeta(name: 'Loading', path: 'display');

/// Story metadata for [LoadingDemo].
const kMeta = Meta(LoadingDemo.new);

/// Loading spinner with an editable variant knob.
final $Spinner = _Story();

/// Default loading indicator (keeps the existing catalog route).
final $Default = _Story();

/// Three dots fading in and out sequentially.
final $Dots = _Story(
  args: _Args(
    variant: EnumArg(
      CoreLoadingVariant.dots,
      values: CoreLoadingVariant.values,
    ),
  ),
);

/// Pulsing indicator.
final $Pulse = _Story(
  args: _Args(
    variant: EnumArg(
      CoreLoadingVariant.pulse,
      values: CoreLoadingVariant.values,
    ),
  ),
);

/// Sliding horizontal bar indicator.
final $Bar = _Story(
  args: _Args(
    variant: EnumArg(CoreLoadingVariant.bar, values: CoreLoadingVariant.values),
  ),
);

/// Interactive radial and linear progress showcase.
final $WithProgress = _Story(
  name: 'With Progress',
  args: _Args(showProgress: BoolArg(true)),
);
