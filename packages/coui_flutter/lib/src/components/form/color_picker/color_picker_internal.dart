import 'dart:async';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// ============================================================================
// Local Constants for Color Picker Component
// ============================================================================

/// Maximum recent colors capacity.
const _kMaxRecentColors = 50;

/// Default preview scale factor.
const _kDefaultPreviewScale = 8.0;

/// Byte stride for RGBA pixel data.
const _kByteStride = 4;

/// Offset for green channel in RGBA bytes.
const _kGreenChannelOffset = 1;

/// Offset for blue channel in RGBA bytes.
const _kBlueChannelOffset = 2;

/// Offset for alpha channel in RGBA bytes.
const _kAlphaChannelOffset = 3;

/// Half divisor for center calculations.
const _kHalfDivisor = 2.0;

/// Preview label vertical offset multiplier.
const _kPreviewLabelOffset = -18.0;

/// Stroke width divisor for paint calculations.
const _kStrokeWidthDivisor = 2.0;

/// Single increment for iteration.
const _kSingleIncrement = 1;

/// Formats [color] as a `#RRGGBB` (or `#AARRGGBB` when [showAlpha]) hex string.
String colorToHex(Color color, [bool showAlpha = true]) {
  return showAlpha
      ? '#${color.toARGB32().toRadixString(CoreColorConversion.hexRadix)}'
      : '#${color.toARGB32().toRadixString(CoreColorConversion.hexRadix).substring(CoreColorConversion.hexPrefixLength)}';
}

abstract class ColorHistoryStorage implements Listenable {
  void addHistory(Color color);

  void setHistory(List<Color> colors);

  void clear();
  int get capacity;
  List<Color> get recentColors;

  static ColorHistoryStorage of(BuildContext context) {
    return Data.of(context);
  }
}

class RecentColorsScope extends StatefulWidget {
  const RecentColorsScope({
    required this.child,
    this.initialRecentColors = const [],
    super.key,
    this.maxRecentColors = _kMaxRecentColors,
    this.onRecentColorsChanged,
  });

  final List<Color> initialRecentColors;
  final int maxRecentColors;
  final ValueChanged<List<Color>>? onRecentColorsChanged;

  final Widget child;

  @override
  State<RecentColorsScope> createState() => RecentColorsScopeState();
}

class _ColorListNotifier extends ChangeNotifier {
  _ColorListNotifier(this._recentColors);

  List<Color> _recentColors;

  void _notify() {
    notifyListeners();
  }
}

class RecentColorsScopeState extends State<RecentColorsScope>
    implements ColorHistoryStorage {
  late _ColorListNotifier _recentColors;

  @override
  int get capacity => widget.maxRecentColors;

  @override
  void initState() {
    super.initState();
    _recentColors = _ColorListNotifier(List.of(widget.initialRecentColors));
  }

  @override
  List<Color> get recentColors => .unmodifiable(_recentColors._recentColors);

  @override
  void addHistory(Color color) {
    final recentColors = _recentColors._recentColors;
    final newRecentColors = recentColors.where((col) => col != color).toList();
    newRecentColors.insert(CoreColorConversion.channelMin, color);
    if (newRecentColors.length > widget.maxRecentColors) {
      _recentColors._recentColors = newRecentColors.sublist(
        0,
        widget.maxRecentColors,
      );
    } else {
      _recentColors._recentColors = newRecentColors;
    }
    widget.onRecentColorsChanged?.call(_recentColors._recentColors);
    _recentColors._notify();
  }

  @override
  void dispose() {
    _recentColors.dispose();
    super.dispose();
  }

  @override
  void clear() {
    _recentColors._recentColors = [];
    widget.onRecentColorsChanged?.call(recentColors);
    _recentColors._notify();
  }

  @override
  void setHistory(List<Color> colors) {
    _recentColors._recentColors = colors;
    widget.onRecentColorsChanged?.call(recentColors);
    _recentColors._notify();
  }

  @override
  void addListener(VoidCallback listener) {
    _recentColors.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _recentColors.removeListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    return Data<ColorHistoryStorage>.inherit(
      data: this,
      child: widget.child,
    );
  }
}

typedef PreviewLabelBuilder =
    Widget Function(BuildContext context, Color color);

class ColorPickingLayer extends StatefulWidget {
  const ColorPickingLayer({
    required this.child,
    super.key,
    this.previewAlignment,
    this.previewLabelBuilder,
    this.previewScale = _kDefaultPreviewScale,
    this.previewSize,
    this.showPreview = true,
  });

  final Widget child;
  final AlignmentGeometry? previewAlignment;
  final bool showPreview;
  final Size? previewSize;
  final double previewScale;

  final PreviewLabelBuilder? previewLabelBuilder;

  @override
  State<ColorPickingLayer> createState() => _ColorPickingLayerState();
}

class _ScreenshotResult {
  const _ScreenshotResult(this.colors, this.image, this.size);

  final List<Color> colors;
  final Size size;

  final ImageProvider? image;

  Color operator [](Offset position) {
    final index = (position.dy.floor() * size.width + position.dx.floor())
        .toInt();

    return colors[index];
  }
}

class _ScreenshotImage extends ImageProvider<_ScreenshotImage> {
  const _ScreenshotImage(this.bytes, this.format, this.height, this.width);

  final Uint8List bytes;
  final int width;
  final int height;
  final ui.PixelFormat format;

  @override
  Future<_ScreenshotImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _ScreenshotImage key,
    ImageDecoderCallback decode,
  ) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(bytes, width, height, format, completer.complete);

    return OneFrameImageStreamCompleter(
      completer.future.then((ui.Image image) => ImageInfo(image: image)),
    );
  }
}

class _ColorPickingCompleter {
  const _ColorPickingCompleter(this.completer, this.recentColorsScope);
  final Completer<Color?> completer;

  final Set<ColorHistoryStorage> recentColorsScope;
}

class _ColorPickingLayerState extends State<ColorPickingLayer>
    implements ColorPickingLayerScope {
  final _repaintKey = GlobalKey();
  _ScreenshotResult? _currentPicking;
  ColorPickingResult? _preview;
  Offset? _currentPosition;
  _ColorPickingCompleter? _session;

  Widget _buildPreviewLabel(BuildContext context, Color color) {
    return widget.previewLabelBuilder != null
        ? widget.previewLabelBuilder!(context, color)
        : Text(colorToHex(color, false)).bodySmall().onSurface();
  }

  Future<_ScreenshotResult?> _screenshotWidget() async {
    final currentContext = _repaintKey.currentContext;
    if (currentContext == null) return null;
    final boundary =
        currentContext.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final byteData = await image.toByteData();
    if (byteData == null) return null;
    final colors = <Color>[];
    for (
      int i = CoreColorConversion.channelMin;
      i < byteData.lengthInBytes;
      i += _kByteStride
    ) {
      final r = byteData.getUint8(i);
      final g = byteData.getUint8(i + _kGreenChannelOffset);
      final b = byteData.getUint8(i + _kBlueChannelOffset);
      final a = byteData.getUint8(i + _kAlphaChannelOffset);
      colors.add(Color.fromARGB(a, r, g, b));
    }
    final img = _ScreenshotImage(
      byteData.buffer.asUint8List(),
      ui.PixelFormat.rgba8888,
      image.height,
      image.width,
    );

    return _ScreenshotResult(
      colors,
      img,
      Size(image.width.toDouble(), image.height.toDouble()),
    );
  }

  ColorPickingResult? _getPreview(Offset globalPosition, Size size) {
    final image = _currentPicking;
    if (image == null) return null;
    final colors = <Color>[];
    for (
      int y = -size.height ~/ _kHalfDivisor;
      y < size.height ~/ _kHalfDivisor;
      y += _kSingleIncrement
    ) {
      for (
        int x = -size.width ~/ _kHalfDivisor;
        x < size.width ~/ _kHalfDivisor;
        x += _kSingleIncrement
      ) {
        final localPosition = globalPosition.translate(
          x.toDouble(),
          y.toDouble(),
        );
        if (localPosition.dx < CoreColorConversion.channelMin ||
            localPosition.dy < CoreColorConversion.channelMin ||
            localPosition.dx >= image.size.width ||
            localPosition.dy >= image.size.height) {
          colors.add(Colors.transparent);
        } else {
          colors.add(image[localPosition]);
        }
      }
    }
    final globalIndex =
        globalPosition.dy.floor() * image.size.width.floor() +
        globalPosition.dx.floor();
    final pickedColor = image.colors[globalIndex];

    return ColorPickingResult(colors, size, pickedColor);
  }

  @override
  Future<Color?> promptPickColor([ColorHistoryStorage? historyStorage]) async {
    if (!mounted) {
      return Future.value();
    }
    if (_session != null) {
      return historyStorage != null &&
              _session!.recentColorsScope.add(historyStorage)
          ? _session!.completer.future.then((value) {
              if (value != null) {
                historyStorage.addHistory(value);
              }

              return value;
            })
          : _session!.completer.future;
    }
    final completer = Completer<Color?>();
    final screenshot = await _screenshotWidget();
    if (!mounted) {
      return Future.value();
    }
    setState(() {
      _session = _ColorPickingCompleter(
        completer,
        historyStorage == null ? {} : {historyStorage},
      );
      _currentPicking = screenshot;
    });
    final result = await completer.future;
    if (historyStorage != null && result != null) {
      historyStorage.addHistory(result);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewSize =
        widget.previewSize ??
        (Size(
              CoreColorConversion.percentMax.toDouble(),
              CoreColorConversion.percentMax.toDouble(),
            ) *
            theme.scaling);

    return Data<ColorPickingLayerScope>.inherit(
      data: this,
      child: GestureDetector(
        onTapDown: _preview != null && _session != null
            ? (details) {
                _session!.completer.complete(_preview!.pickedColor);
                if (mounted) {
                  setState(() {
                    _session = null;
                    _preview = null;
                    _currentPicking = null;
                    _currentPosition = null;
                  });
                }
              }
            : null,
        behavior: .translucent,
        child: MouseRegion(
          onHover: _session == null
              ? null
              : (details) {
                  setState(() {
                    _preview = _getPreview(
                      details.localPosition,
                      previewSize / widget.previewScale,
                    );
                    _currentPosition = details.localPosition;
                  });
                },
          hitTestBehavior: .translucent,
          child: IgnorePointer(
            ignoring: _session != null,
            child: Stacks(
              fit: .passthrough,
              children: [
                RepaintBoundary(key: _repaintKey, child: widget.child),
                if (_currentPicking != null)
                  Position.fill(
                    child: Image(
                      image: _currentPicking!.image!,
                      semanticLabel: CoUILocalizations.of(
                        context,
                      ).colorPickerPreviewLabel,
                      fit: .fill,
                    ),
                  ),
                if (widget.showPreview &&
                    _preview != null &&
                    widget.previewAlignment != null)
                  Position(
                    top: CoreColorConversion.slMinimum,
                    right: CoreColorConversion.slMinimum,
                    bottom: CoreColorConversion.slMinimum,
                    left: CoreColorConversion.slMinimum,
                    child: Padding(
                      padding: .all(
                        theme.scaling * theme.geometry.space(CoreSpace.space32),
                      ),
                      child: Align(
                        alignment: widget.previewAlignment!,
                        child: Stacks(
                          alignment: .bottomCenter,
                          fit: .passthrough,
                          clipBehavior: .none,
                          children: [
                            SizedBox(
                              width: previewSize.width,
                              height: previewSize.height,
                              child: CustomPaint(
                                painter: _ColorPreviewPainter(
                                  _preview!.colors,
                                  _preview!.size,
                                  theme.colorScheme.outline.toValue(),
                                  theme.scaling * CoreStrokeWidth.stroke1,
                                  theme.colorScheme.primary.toValue(),
                                  theme.scaling * CoreStrokeWidth.stroke2,
                                ),
                              ),
                            ),
                            Position(
                              bottom: _kPreviewLabelOffset * theme.scaling,
                              child: _buildPreviewLabel(
                                context,
                                _preview!.pickedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (widget.showPreview &&
                    _preview != null &&
                    widget.previewAlignment == null)
                  Position(
                    top: _currentPosition!.dy,
                    left: _currentPosition!.dx,
                    child: Stacks(
                      alignment: .bottomCenter,
                      fit: .passthrough,
                      clipBehavior: .none,
                      children: [
                        SizedBox(
                          width: previewSize.width,
                          height: previewSize.height,
                          child: CustomPaint(
                            painter: _ColorPreviewPainter(
                              _preview!.colors,
                              _preview!.size,
                              theme.colorScheme.outline.toValue(),
                              theme.scaling * 1,
                              theme.colorScheme.primary.toValue(),
                              theme.scaling * 2,
                            ),
                          ),
                        ),
                        Position(
                          bottom: _kPreviewLabelOffset * theme.scaling,
                          child: _buildPreviewLabel(
                            context,
                            _preview!.pickedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<Color?> pickColorFromScreen(
  BuildContext context, [
  ColorHistoryStorage? storage,
]) {
  final scope = ColorPickingLayerScope.find(context);

  return scope.promptPickColor(storage);
}

class _ColorPreviewPainter extends CustomPainter {
  const _ColorPreviewPainter(
    this.colors,
    this.size,
    this.borderColor,
    this.borderWidth,
    this.selectedBorderColor,
    this.selectedBorderWidth,
  );

  final List<Color> colors;
  final Size size;
  final Color borderColor;
  final double borderWidth;
  final Color selectedBorderColor;

  final double selectedBorderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    /// Clip it to circle.
    final clipPath = Path()
      ..addOval(
        Rect.fromLTWH(
          0,
          0,
          size.width.floorToDouble(),
          size.height.floorToDouble(),
        ),
      );
    canvas.clipPath(clipPath);
    final paint = Paint();
    final cellSize = Size(
      size.width.floor() / this.size.width.floor(),
      size.height.floor() / this.size.height.floor(),
    );
    for (
      int y = CoreColorConversion.channelMin;
      y < this.size.height.floor();
      y += _kSingleIncrement
    ) {
      for (
        int x = CoreColorConversion.channelMin;
        x < this.size.width.floor();
        x += _kSingleIncrement
      ) {
        final color = colors[y * this.size.width.floor() + x];
        paint.color = color;
        paint.style = .fill;
        canvas.drawRect(
          Rect.fromLTWH(
            (x * cellSize.width).floorToDouble(),
            (y * cellSize.height).floorToDouble(),
            cellSize.width.floorToDouble(),
            cellSize.height.floorToDouble(),
          ),
          paint,
        );
        paint.color = borderColor;
        paint.style = .stroke;
        paint.strokeWidth = borderWidth;

        /// Draw a border.
        canvas.drawRect(
          Rect.fromLTWH(
            (x * cellSize.width).floorToDouble(),
            (y * cellSize.height).floorToDouble(),
            cellSize.width.floorToDouble(),
            cellSize.height.floorToDouble(),
          ).inflate(paint.strokeWidth / _kStrokeWidthDivisor),
          paint,
        );
      }
    }

    /// Draw a rect for the selected color at center.
    paint.color = selectedBorderColor;
    paint.style = .stroke;
    paint.strokeWidth = selectedBorderWidth;
    final centerX = size.width ~/ _kHalfDivisor;
    final centerY = size.height ~/ _kHalfDivisor;
    final cellX = centerX ~/ cellSize.width;
    final cellY = centerY ~/ cellSize.height;
    canvas.drawRect(
      Rect.fromLTWH(
        (cellX * cellSize.width).floorToDouble(),
        (cellY * cellSize.height).floorToDouble(),
        cellSize.width.floorToDouble(),
        cellSize.height.floorToDouble(),
      ),
      paint,
    );

    /// Add circle border, and make sure it is not clipped.
    paint.color = borderColor;
    paint.style = .stroke;
    paint.strokeWidth = borderWidth;
    canvas.drawOval(
      Rect.fromLTWH(
        0,
        0,
        size.width.floorToDouble(),
        size.height.floorToDouble(),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ColorPreviewPainter oldDelegate) {
    return !listEquals(oldDelegate.colors, colors) ||
        oldDelegate.size != size ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.selectedBorderColor != selectedBorderColor ||
        oldDelegate.selectedBorderWidth != selectedBorderWidth;
  }
}

abstract class ColorPickingLayerScope {
  Future<Color?> promptPickColor([ColorHistoryStorage? historyStorage]);

  static ColorPickingLayerScope findRoot(BuildContext context) {
    return Data.findRoot(context);
  }

  static ColorPickingLayerScope find(BuildContext context) {
    return Data.find(context);
  }
}

class ColorPickingResult {
  const ColorPickingResult(this.colors, this.size, this.pickedColor);

  final Size size;
  final List<Color> colors;

  final Color pickedColor;

  Color operator [](Offset position) {
    final index = (position.dy.floor() * size.width + position.dx.floor())
        .toInt();

    return colors[index];
  }
}
