// What the `MockupFoldable` tests share: the app they pump, the parts they
// find on its stage, the pose table they read, and the pixels they read back.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The keys `MockupFoldable` gives the parts it places on its stage.
const Key kInnerPart = ValueKey('inner');
const Key kCoverPart = ValueKey('cover');
const Key kEdgeLeftPart = ValueKey('edgeLeft');
const Key kEdgeRightPart = ValueKey('edgeRight');

/// The keys it gives the parts of a screen's status island.
const Key kIslandCamera = ValueKey('islandCamera');
const Key kIslandClock = ValueKey('islandClock');
const Key kIslandIndicator = ValueKey('islandIndicator');

/// A style under which a change of angle is the new angle at once.
const CoreMockupFoldableStyle kAtOnce = CoreMockupFoldableStyle(
  duration: Duration.zero,
);

/// What the app paints behind the device. No part of a device is green, and
/// the tests put nothing green on its screens, so a pixel that is still this
/// colour — or this colour under a shadow — has no part of the device on it.
const Color kBackdrop = Color(0xFF00FF00);

/// Space left around the stage, so what the device draws outside its box is
/// in the picture.
const double kMargin = 60;

/// The table the Core rules, the Flutter widget and the Web component all
/// read: where each part of the device is drawn at each angle.
const String _kVectorsPath =
    '../coui_core/test/fixtures/mockup_fold_vectors.json';

/// Pumps [foldable] in an app with the kit's theme around it.
///
/// A [boundary] puts the whole view in a `RepaintBoundary` [capture] can
/// read. [hostFolds] are folds of the page the app runs in — never of the
/// mockup's own screen. [textDirection] is the way the app around the device
/// reads.
Widget foldableApp(
  Widget foldable, {
  double scaling = 1,
  CoreComponentTheme? componentTheme,
  bool reducedMotion = false,
  List<ui.DisplayFeature> hostFolds = const [],
  TextDirection textDirection = TextDirection.ltr,
  Key? boundary,
}) => Directionality(
  textDirection: textDirection,
  child: Builder(
    builder: (context) => MediaQuery(
      data: MediaQueryData.fromView(View.of(context)).copyWith(
        disableAnimations: reducedMotion,
        displayFeatures: hostFolds,
      ),
      child: Theme(
        data: ThemeData(
          scaling: scaling,
          colorScheme: CoreThemePresets.lightColorScheme,
          coreComponentTheme: componentTheme,
        ),
        child: RepaintBoundary(
          key: boundary,
          child: ColoredBox(
            color: kBackdrop,
            child: Padding(
              padding: const EdgeInsets.all(kMargin),
              child: foldable,
            ),
          ),
        ),
      ),
    ),
  ),
);

/// The device's stage: the open body's box, whatever the angle.
RenderBox stageOf(WidgetTester tester) => tester.renderObject<RenderBox>(
  find
      .descendant(
        of: find.byType(MockupFoldable),
        matching: find.byType(SizedBox),
      )
      .first,
);

/// The two `MockupDevice`s a foldable is made of.
Finder faceOf(CoreMockupDevice device) => find.byWidgetPredicate(
  (widget) => widget is MockupDevice && widget.device == device,
);

/// The screen of one of the two faces — the box its `MockupDevice` clips its
/// screen to.
RenderBox screenBoxOf(WidgetTester tester, CoreMockupDevice device) =>
    tester.renderObject<RenderBox>(
      find
          .descendant(of: faceOf(device), matching: find.byType(ClipRRect))
          .first,
    );

/// What the Core rules state for a device [width] wide and otherwise as the
/// design system leaves it — the statement the Web twin makes too.
CoreMockupFoldableLayout defaultFoldableLayout({
  double width = CoreMockupFoldableStyle.defaultWidth,
  double thickness = CoreMockupFoldableStyle.defaultThickness,
  double perspective = CoreMockupFoldableStyle.defaultPerspective,
}) => CoreMockupFoldableLayout.compute(
  width: width,
  innerDeviceStyle: CoreMockupFoldableStyle.defaultInnerDeviceStyle,
  coverDeviceStyle: CoreMockupFoldableStyle.defaultCoverDeviceStyle,
  thickness: thickness,
  perspective: perspective,
  islandWidth: CoreMockupFoldableStyle.defaultIslandWidth,
  islandOffset: CoreMockupFoldableStyle.defaultIslandOffset,
  islandCameraSize: CoreMockupFoldableStyle.defaultIslandCameraSize,
);

/// The box an edge is painted in.
Finder edgeBox(Key part) =>
    find.descendant(of: find.byKey(part), matching: find.byType(CustomPaint));

/// Where the four corners of [box] are drawn on [stage] — top-left,
/// top-right, bottom-left, bottom-right — through every transform between.
List<Offset> cornersOn(RenderBox stage, RenderBox box) => [
  Offset.zero,
  Offset(box.size.width, 0),
  Offset(0, box.size.height),
  Offset(box.size.width, box.size.height),
].map((point) => box.localToGlobal(point, ancestor: stage)).toList();

/// One part of the device at one angle, as the table states it.
typedef FoldPartVector = ({bool visible, List<Offset> corners});

/// How a slab's outer edge ends at one angle, as the table states it: which
/// side of the edge's box the device's outline is on, and the corners that
/// side is rounded by.
typedef FoldEdgeCutVector = ({bool outlineAtEnd, Radius top, Radius bottom});

/// The device at one angle, as the table states it.
class FoldVector {
  const FoldVector({
    required this.angle,
    required this.activeScreen,
    required this.isFlat,
    required this.foldState,
    required this.innerScreenDim,
    required this.coverScreenDim,
    required this.parts,
    required this.edgeCuts,
  });

  final double angle;
  final String activeScreen;
  final bool isFlat;
  final String foldState;
  final double innerScreenDim;
  final double coverScreenDim;
  final Map<String, FoldPartVector> parts;

  /// `right` and `left`; null where that edge is not drawn.
  final Map<String, FoldEdgeCutVector?> edgeCuts;
}

/// The shared pose table.
class FoldTable {
  const FoldTable({
    required this.width,
    required this.height,
    required this.thickness,
    required this.perspective,
    required this.innerCorner,
    required this.coverCorner,
    required this.vectors,
  });

  factory FoldTable.read() {
    final doc =
        jsonDecode(File(_kVectorsPath).readAsStringSync())
            as Map<String, dynamic>;
    final geometry = doc['geometry'] as Map<String, dynamic>;
    double number(Object? value) => (value! as num).toDouble();
    Radius radius(Object? pair) {
      final values = (pair! as List<dynamic>).cast<num>();

      return Radius.elliptical(
        values.first.toDouble(),
        values.last.toDouble(),
      );
    }

    return FoldTable(
      width: number(geometry['width']),
      height: number(geometry['height']),
      thickness: number(geometry['thickness']),
      perspective: number(geometry['perspective']),
      innerCorner: radius(geometry['innerCorner']),
      coverCorner: radius(geometry['coverCorner']),
      vectors: [
        for (final vector
            in (doc['vectors'] as List<dynamic>).cast<Map<String, dynamic>>())
          FoldVector(
            angle: number(vector['angle']),
            activeScreen: vector['activeScreen'] as String,
            isFlat: vector['isFlat'] as bool,
            foldState: vector['foldState'] as String,
            innerScreenDim: number(vector['innerScreenDim']),
            coverScreenDim: number(vector['coverScreenDim']),
            parts: {
              for (final part
                  in (vector['parts'] as Map<String, dynamic>).entries)
                part.key: (
                  visible:
                      (part.value as Map<String, dynamic>)['visible'] as bool,
                  corners: [
                    for (final corner
                        in ((part.value as Map<String, dynamic>)['corners']
                                as List<dynamic>)
                            .cast<List<dynamic>>())
                      Offset(number(corner.first), number(corner.last)),
                  ],
                ),
            },
            edgeCuts: {
              for (final cut
                  in (vector['edgeCuts'] as Map<String, dynamic>).entries)
                cut.key: switch (cut.value) {
                  final Map<String, dynamic> stated => (
                    outlineAtEnd: stated['outlineAtEnd'] as bool,
                    top: radius(stated['top']),
                    bottom: radius(stated['bottom']),
                  ),
                  _ => null,
                },
            },
          ),
      ],
    );
  }

  final double width;
  final double height;
  final double thickness;
  final double perspective;

  /// The open body's corners the table's edge cuts are stated for.
  final Radius innerCorner;

  /// The cover's corners away from the hinge the table's edge cuts are
  /// stated for — not the body's own, so a cut read from the wrong face
  /// shows.
  final Radius coverCorner;

  final List<FoldVector> vectors;

  Size get size => Size(width, height);

  /// The style under which a foldable [width] wide is the table's device:
  /// as tall, as deep and seen from as far, at the angle asked for at once.
  ///
  /// The open body gets its height from its screen's proportions, so the
  /// proportions stated here are the screen that leaves a body [height] tall.
  CoreMockupFoldableStyle get style {
    final inset = defaultFoldableLayout(
      width: width,
      thickness: thickness,
      perspective: perspective,
    ).innerScreen.left;

    return CoreMockupFoldableStyle(
      innerDeviceStyle: CoreMockupDeviceStyle(
        screenAspectWidth: width - inset * 2,
        screenAspectHeight: height - inset * 2,
      ),
      thickness: thickness,
      perspective: perspective,
      duration: Duration.zero,
    );
  }

  /// [style] with the two faces' corners stated as the table's edge cuts
  /// are derived for.
  CoreMockupFoldableStyle get styleWithTableCorners => style.merge(
    CoreMockupFoldableStyle(
      innerDeviceStyle: CoreMockupDeviceStyle(
        borderRadius: CoreBorderRadius.all(innerCorner.x),
      ),
      coverDeviceStyle: CoreMockupDeviceStyle(
        borderRadius: CoreBorderRadius.only(
          topRight: coverCorner.x,
          bottomRight: coverCorner.x,
        ),
      ),
    ),
  );
}

/// The pixels of a view, one logical pixel each.
class Pixels {
  const Pixels(this.width, this.height, this._rgba);

  final int width;
  final int height;
  final Uint8List _rgba;

  /// The colour at [x], [y] of the view.
  Color at(int x, int y) {
    final i = (y * width + x) * 4;

    return Color.fromARGB(_rgba[i + 3], _rgba[i], _rgba[i + 1], _rgba[i + 2]);
  }

  /// The colour at a point of the stage.
  Color onStage(Offset point) =>
      at((point.dx + kMargin).floor(), (point.dy + kMargin).floor());

  /// Whether a part of the device is painted at [x], [y].
  ///
  /// The backdrop is green, with or without a shadow over it, and no part of
  /// a device is: a pixel counts once what covers it is mostly the device. A
  /// strip a pixel or two wide is anti-aliased on both sides, so a stricter
  /// reading would lose it.
  bool isDevice(int x, int y) {
    final color = at(x, y);

    return color.g - math.max(color.r, color.b) < 0.25;
  }

  /// How far the device reaches to the left and to the right along the stage
  /// row [y], in stage pixels: its first and its last column.
  ({double left, double right}) reachOnStageRow(double y) {
    final row = (y + kMargin).floor();
    final columns = [
      for (var x = 0; x < width; x++)
        if (isDevice(x, row)) x,
    ];

    return (
      left: columns.first - kMargin,
      // The last column ends one pixel on.
      right: columns.last + 1 - kMargin,
    );
  }
}

/// Reads back what is painted under [boundary], one logical pixel each.
///
/// Sets the view to one device pixel per logical pixel first: a still of the
/// bent screen is taken at the view's ratio.
Future<Pixels> capture(WidgetTester tester, GlobalKey boundary) async {
  final render =
      boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late Pixels pixels;
  await tester.runAsync(() async {
    final image = await render.toImage();
    final data = await image.toByteData();
    pixels = Pixels(image.width, image.height, data!.buffer.asUint8List());
    image.dispose();
  });

  return pixels;
}

/// A view of one device pixel per logical pixel, exactly a stage [stage]
/// large with [kMargin] around it — so a stage point is a view point plus the
/// margin.
void useOneToOneView(WidgetTester tester, Size stage) {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = Size(
      stage.width + kMargin * 2,
      stage.height + kMargin * 2,
    );
  addTearDown(tester.view.reset);
}
