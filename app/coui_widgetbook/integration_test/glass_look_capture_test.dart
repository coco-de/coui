// Not a measurement — a picture. Renders the shipped liquid-glass Dock over a
// backdrop shaped like the reference (dark field, saturated red blobs behind
// the bar) on a real Impeller device and writes the PNG, so the look can be
// judged with the same scene before and after each rendering change.
//
//   flutter test integration_test/glass_look_capture_test.dart \
//     -d macos --dart-define=PROBE_DEVICE_ID=macos --dart-define=LOOK_LABEL=before
//
// The scene sits in the middle of the screen and is never wider than it, so a
// phone does not cut the bar off. A scene pinned to the top-left corner is in
// the one place the window's own edge reads as the surface's: a bend measured
// there looks right whether or not the coordinates are. `LOOK_PLACEMENT=edge`
// puts it back in that corner, for the edge reading beside the centre one.
//
// The capture boundary is the whole screen, not the scene, and the PNG is the
// scene cut out of it. `toImage` makes its boundary the render target while a
// surface reports its rectangle relative to the screen, so the bend lands where
// the surface is only when the boundary starts where the screen does. A
// boundary around a centred scene renders the bar's bend in the wrong place,
// with nothing to say so.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart' hide Icon;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

const kLabel = String.fromEnvironment('LOOK_LABEL', defaultValue: 'look');

/// `centre` (the default) or `edge`: where on the screen the scene sits.
const kPlacement = String.fromEnvironment(
  'LOOK_PLACEMENT',
  defaultValue: 'centre',
);

/// The scene's design box, and the room it keeps from the screen's sides.
const double _kSceneWidth = 420;
const double _kSceneHeight = 260;
const double _kSceneMargin = 16;

/// The scene's own field, which the screen around it carries on, so what the
/// glass samples past the scene's edge is more of the same dark.
const Color _kField = Color(0xFF0E0E10);

/// Where the scene sits: the middle of the screen, or the corner for the edge
/// reading.
Alignment _placement() =>
    kPlacement == 'edge' ? Alignment.topLeft : Alignment.center;

// The bar's Radio and Library glyphs. They are not in the bundle CoUI's own
// chrome draws from, so left to the resolver they come from the disk cache or
// the network and are on screen only if that finished before the capture: a
// different icon missing from run to run, and none offline. Registered, they
// are there on the first frame.
const _kLucideGroup =
    '<g fill="none" stroke="currentColor" stroke-linecap="round" '
    'stroke-linejoin="round" stroke-width="2">';
const _kRadioWaves =
    'M16.247 7.761a6 6 0 0 1 0 8.478m2.828-11.306a10 10 0 0 1 0 '
    '14.134m-14.15 0a10 10 0 0 1 0-14.134m2.828 11.306a6 6 0 0 1 0-8.478';
const _kRadioHub = '<circle cx="12" cy="12" r="2"/>';
const _kMusicNotes =
    '<circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/>';
const _kRadioGlyph = IconSvgData(
  body: '$_kLucideGroup<path d="$_kRadioWaves"/>$_kRadioHub</g>',
);
const _kMusicGlyph = IconSvgData(
  body: '$_kLucideGroup<path d="M9 18V5l12-2v13"/>$_kMusicNotes</g>',
);

/// [image] cut down to [rect], pixel for pixel.
Future<ui.Image> _crop(ui.Image image, Rect rect) {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    image,
    rect,
    Offset.zero & rect.size,
    Paint()..filterQuality = ui.FilterQuality.none,
  );

  return recorder.endRecording().toImage(
    rect.width.round(),
    rect.height.round(),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('liquid-glass dock over a reference-like backdrop', (
    tester,
  ) async {
    final program = await tester.runAsync(SurfaceRefractionProgram.warmUp);
    debugPrint(
      'LOOK  shaderFilterSupported=${ui.ImageFilter.isShaderFilterSupported}  program=${program != null}',
    );
    IconResolver.instance
      ..register(LucideIcons.radio.id, _kRadioGlyph)
      ..register(LucideIcons.music.id, _kMusicGlyph);
    final dpr = tester.view.devicePixelRatio;
    final screenKey = GlobalKey();
    final sceneKey = GlobalKey();
    var index = 1;
    await tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(CoreThemePresets.dark),
        themeMode: CoreThemeMode.dark,
        surfaceStyle: CoreSurfaceStyleId.liquidGlass,
        home: RepaintBoundary(
          key: screenKey,
          child: ColoredBox(
            color: _kField,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The scene's size and place are whole device pixels. A scene
                // half a pixel off the grid has every hard edge drawn with
                // other coverage, so the same scene would differ from one
                // placement, and one device, to the next.
                double snap(double logical) =>
                    (logical * dpr).floorToDouble() / dpr;
                // The design box, narrowed to what the screen has room for.
                final width = snap(
                  math.min(
                    _kSceneWidth,
                    constraints.maxWidth - 2 * _kSceneMargin,
                  ),
                );
                final height = snap(width * _kSceneHeight / _kSceneWidth);
                final offset = _placement().alongSize(
                  Size(
                    constraints.maxWidth - width,
                    constraints.maxHeight - height,
                  ),
                );

                return Stack(
                  children: [
                    Positioned(
                      left: snap(offset.dx),
                      top: snap(offset.dy),
                      child: SizedBox(
                        key: sceneKey,
                        width: width,
                        height: height,
                        child: Stack(
                          children: [
                            const Positioned.fill(
                              child: CustomPaint(painter: _ReferenceBackdrop()),
                            ),
                            Positioned(
                              left: 24,
                              right: 24,
                              bottom: 24,
                              child: StatefulBuilder(
                                builder: (context, setState) => Dock(
                                  // A pill, as the reference's bar is. The radius is the app's
                                  // geometry, not the style's — the capture chooses it the way
                                  // an app would, so the corner arcs are wide enough to show
                                  // what the rim does there.
                                  dockStyle: const CoreDockStyle(
                                    barRadius: CoreBorderRadius.all(
                                      CoreRadius.radius9999,
                                    ),
                                  ),
                                  items: [
                                    for (final (i, icon, label) in [
                                      (0, LucideIcons.house, 'Home'),
                                      (1, LucideIcons.radio, 'Radio'),
                                      (2, LucideIcons.music, 'Library'),
                                      (3, LucideIcons.search, 'Search'),
                                    ])
                                      CoreDockItemData<Widget>(
                                        icon: Icon(icon),
                                        label: label,
                                        isActive: index == i,
                                        onPressed: () =>
                                            setState(() => index = i),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final screen =
        screenKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final scene = sceneKey.currentContext!.findRenderObject()! as RenderBox;
    // The boundary has to start where the screen does (see the header), or the
    // picture is of a bend in the wrong place.
    expect(
      screen.localToGlobal(Offset.zero),
      Offset.zero,
      reason: 'the capture boundary must sit at the screen origin',
    );
    // The scene's rectangle in the screen's pixels, rounded to whole pixels so
    // the cut is a copy and not a resample.
    final at = scene.localToGlobal(Offset.zero, ancestor: screen);
    final sceneRect = Rect.fromLTWH(
      (at.dx * dpr).roundToDouble(),
      (at.dy * dpr).roundToDouble(),
      (scene.size.width * dpr).roundToDouble(),
      (scene.size.height * dpr).roundToDouble(),
    );
    Future<void> capture(String suffix) => tester.runAsync(() async {
      final whole = await screen.toImage(pixelRatio: dpr);
      final image = await _crop(whole, sceneRect);
      whole.dispose();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final file = File(
        '${Directory.systemTemp.path}/glass-look-$kLabel$suffix.png',
      );
      await file.writeAsBytes(png!.buffer.asUint8List());
      debugPrint('LOOK  wrote ${file.path}');
    });
    await capture('');

    // The pill in flight: tap the far item and freeze a frame a little way
    // into the spring, where the departing and arriving pills are still one
    // body with a neck between them.
    await tester.tap(find.text('Search'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    await capture('-flight');
    await tester.pumpAndSettle();
    await capture('-landed');
  });
}

/// Near-black field with soft saturated red blobs — what the reference's
/// album art looked like through its bar.
class _ReferenceBackdrop extends CustomPainter {
  const _ReferenceBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn in the 420 x 260 design box and scaled to the size it is given,
    // so a narrower scene is the same picture smaller, not a cropped one.
    canvas
      ..save()
      ..scale(size.width / _kSceneWidth);
    const design = Size(_kSceneWidth, _kSceneHeight);
    canvas.drawRect(
      Offset.zero & design,
      Paint()..color = const Color(0xFF0E0E10),
    );
    final red = Paint()..color = const Color(0xFFE8334A);
    for (final c in [
      const Offset(90, 120),
      const Offset(200, 150),
      const Offset(320, 120),
      const Offset(260, 230),
    ]) {
      canvas.drawCircle(c, 46, red);
    }
    final dark = Paint()..color = const Color(0xFF7A1F2B);
    canvas.drawCircle(const Offset(150, 230), 40, dark);
    canvas.drawCircle(const Offset(360, 220), 34, dark);
    // A few hard edges so the bend has something crisp to move.
    final white = Paint()..color = const Color(0xFFFFFFFF);
    for (var x = 0.0; x < design.width; x += 60) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, design.height), white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
