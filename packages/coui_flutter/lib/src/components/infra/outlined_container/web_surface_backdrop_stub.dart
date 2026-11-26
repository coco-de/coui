import 'package:coui_core/coui_core.dart';
import 'package:flutter/widgets.dart';

/// Native backends keep the existing Impeller path.
bool get webSurfaceRefractionSupported => false;

/// Signature twin of the browser adapter; never paints a platform view here.
class WebSurfaceBackdrop extends StatelessWidget {
  const WebSurfaceBackdrop({
    required this.refraction,
    required this.borderRadius,
    required this.child,
    this.background,
    this.blur = 0,
    this.saturation = 1,
    this.brightness = 1,
    this.activation = 1,
    this.mapSize,
    super.key,
  });

  final CoreSurfaceRefraction refraction;
  final BorderRadius borderRadius;
  final Widget child;
  final Widget? background;
  final double blur;
  final double saturation;
  final double brightness;
  final double activation;
  final Size? mapSize;

  @override
  Widget build(BuildContext context) => child;
}
