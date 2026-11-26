// Pins the decision a surface makes about the pass its filter reads from.
//
// The pass itself is the engine's. What an enclosure hands a program is
// measured on a device (`refraction_enclosing_pass_probe_test.dart`) because
// nothing a widget test runs can say. What is ours, and what this holds, is
// the two things the decision is made of: which layers above a surface count
// as saving a pass, and where the clips above one start in the root's space.
//
// The layer chains are built by hand, outermost first, under a root that
// scales like the render view's does, so a clip's position is read in device
// pixels the way it is on screen.
import 'dart:ui';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/infra/outlined_container/surface_backdrop_pass.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// A clip that starts away from the root's origin, in logical pixels: what a
/// card, a panel or a viewport looks like from above.
const _inset = Rect.fromLTWH(40, 40, 520, 320);

/// A clip that starts at the root's origin.
const _atOrigin = Rect.fromLTWH(0, 0, 600, 400);

/// The surface's own layer, under [above] (outermost first), under a root
/// that scales by [scale].
Layer _surfaceUnder(List<ContainerLayer> above, {double scale = 2}) {
  final root = TransformLayer(
    transform: Matrix4.diagonal3Values(scale, scale, 1),
  );
  addTearDown(root.dispose);
  ContainerLayer parent = root;
  for (final layer in above) {
    parent.append(layer);
    parent = layer;
  }
  final surface = BackdropFilterLayer();
  parent.append(surface);

  return surface;
}

/// A fresh clip layer of each kind, given a clip behaviour and a rectangle.
List<ContainerLayer Function(Clip clipBehavior, Rect rect)> _clipKinds() => [
  (behavior, rect) => ClipRectLayer(clipRect: rect, clipBehavior: behavior),
  (behavior, rect) => ClipRRectLayer(
    clipRRect: RRect.fromRectAndRadius(rect, const Radius.circular(12)),
    clipBehavior: behavior,
  ),
  (behavior, rect) => ClipPathLayer(
    clipPath: Path()..addRect(rect),
    clipBehavior: behavior,
  ),
  (behavior, rect) => ClipRSuperellipseLayer(
    clipRSuperellipse: RSuperellipse.fromRectAndRadius(
      rect,
      const Radius.circular(12),
    ),
    clipBehavior: behavior,
  ),
];

/// A fresh layer of each kind that saves a pass the size of the clip in
/// effect where it paints.
Map<String, ContainerLayer Function()> _clippedOpeners() => {
  'OpacityLayer': () => OpacityLayer(alpha: 128),
  'ShaderMaskLayer': ShaderMaskLayer.new,
  'ColorFilterLayer': ColorFilterLayer.new,
  'BackdropFilterLayer': BackdropFilterLayer.new,
};

void main() {
  group('a surface with no pass above it', () {
    test('reads the root', () {
      expect(backdropReadsRootPass(_surfaceUnder([])), isTrue);
    });

    test('reads the root under clips, however they are cut', () {
      for (final clip in _clipKinds()) {
        for (final behavior in [Clip.hardEdge, Clip.antiAlias]) {
          expect(
            backdropReadsRootPass(
              _surfaceUnder([clip(behavior, _inset)]),
            ),
            isTrue,
            reason: 'a clip that saves no layer opens no pass ($behavior)',
          );
        }
      }
    });

    test('reads the root under a plain offset or transform', () {
      expect(
        backdropReadsRootPass(
          _surfaceUnder([
            OffsetLayer(offset: const Offset(40, 40)),
            TransformLayer(transform: Matrix4.translationValues(30, 30, 0)),
          ]),
        ),
        isTrue,
      );
    });
  });

  group('a layer that saves a pass the size of its clip', () {
    test('leaves the root when no clip above it starts elsewhere', () {
      for (final entry in _clippedOpeners().entries) {
        expect(
          backdropReadsRootPass(_surfaceUnder([entry.value()])),
          isTrue,
          reason: '${entry.key} with nothing clipping it',
        );
        expect(
          backdropReadsRootPass(
            _surfaceUnder([ClipRectLayer(clipRect: _atOrigin), entry.value()]),
          ),
          isTrue,
          reason: '${entry.key} under a clip at the origin of the root',
        );
      }
    });

    test('is moved by a clip above it that starts elsewhere', () {
      for (final entry in _clippedOpeners().entries) {
        for (final clip in _clipKinds()) {
          expect(
            backdropReadsRootPass(
              _surfaceUnder([clip(Clip.hardEdge, _inset), entry.value()]),
            ),
            isFalse,
            reason: '${entry.key} under an inset clip',
          );
        }
      }
    });

    test('is not moved by a clip between it and the surface', () {
      for (final entry in _clippedOpeners().entries) {
        expect(
          backdropReadsRootPass(
            _surfaceUnder([entry.value(), ClipRectLayer(clipRect: _inset)]),
          ),
          isTrue,
          reason: '${entry.key} above an inset clip',
        );
      }
    });

    test('is moved by an inset clip however far above it sits', () {
      expect(
        backdropReadsRootPass(
          _surfaceUnder([
            ClipRectLayer(clipRect: _inset),
            OffsetLayer(),
            TransformLayer(transform: Matrix4.identity()),
            OpacityLayer(alpha: 128),
          ]),
        ),
        isFalse,
      );
    });
  });

  group('a clip that saves a layer', () {
    test('is a pass, and its own clip counts', () {
      for (final clip in _clipKinds()) {
        expect(
          backdropReadsRootPass(
            _surfaceUnder([clip(Clip.antiAliasWithSaveLayer, _inset)]),
          ),
          isFalse,
          reason: 'an inset clip that saves a layer',
        );
        expect(
          backdropReadsRootPass(
            _surfaceUnder([clip(Clip.antiAliasWithSaveLayer, _atOrigin)]),
          ),
          isTrue,
          reason: 'a clip that saves a layer and starts at the origin',
        );
      }
    });
  });

  group('an image filter', () {
    ImageFilterLayer filter() =>
        ImageFilterLayer(imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1));

    test('has no origin to state, wherever it sits', () {
      expect(backdropReadsRootPass(_surfaceUnder([filter()])), isFalse);
      expect(
        backdropReadsRootPass(
          _surfaceUnder([ClipRectLayer(clipRect: _atOrigin), filter()]),
        ),
        isFalse,
      );
    });

    test('moves everything inside it, including a pass that would be fine', () {
      expect(
        backdropReadsRootPass(
          _surfaceUnder([filter(), OpacityLayer(alpha: 128)]),
        ),
        isFalse,
      );
      expect(
        backdropReadsRootPass(
          _surfaceUnder([filter(), ClipRectLayer(clipRect: _atOrigin)]),
        ),
        isFalse,
      );
    });
  });

  group('where a clip starts', () {
    test('is read in the root space, through the layers above it', () {
      // The clip starts at the origin of its own layer, which an offset
      // layer above it puts away from the root's.
      expect(
        backdropReadsRootPass(
          _surfaceUnder([
            OffsetLayer(offset: const Offset(40, 40)),
            ClipRectLayer(clipRect: const Rect.fromLTWH(0, 0, 100, 100)),
            OpacityLayer(alpha: 128),
          ]),
        ),
        isFalse,
      );
    });

    test('can come back to the origin through the layers above it', () {
      // A clip that looks inset in its own space, pulled back by an offset.
      expect(
        backdropReadsRootPass(
          _surfaceUnder([
            OffsetLayer(offset: const Offset(-40, -40)),
            ClipRectLayer(clipRect: _inset),
            OpacityLayer(alpha: 128),
          ]),
        ),
        isTrue,
      );
    });

    test('follows a transform, not only an offset', () {
      expect(
        backdropReadsRootPass(
          _surfaceUnder([
            TransformLayer(
              transform: Matrix4.diagonal3Values(0.5, 0.5, 1)
                ..leftTranslateByDouble(80, 80, 0, 1),
            ),
            ClipRectLayer(clipRect: const Rect.fromLTWH(0, 0, 100, 100)),
            OpacityLayer(alpha: 128),
          ]),
        ),
        isFalse,
      );
    });

    test('only the side that starts later matters', () {
      // Starts at the left edge and a long way down.
      expect(
        backdropReadsRootPass(
          _surfaceUnder([
            ClipRectLayer(clipRect: const Rect.fromLTWH(0, 200, 600, 100)),
            OpacityLayer(alpha: 128),
          ]),
        ),
        isFalse,
      );
      // Starts a long way along and at the top edge.
      expect(
        backdropReadsRootPass(
          _surfaceUnder([
            ClipRectLayer(clipRect: const Rect.fromLTWH(200, 0, 100, 400)),
            OpacityLayer(alpha: 128),
          ]),
        ),
        isFalse,
      );
    });

    test('is the later of every clip above, not the nearest', () {
      // The nearer clip starts at the origin; the farther one does not.
      expect(
        backdropReadsRootPass(
          _surfaceUnder([
            ClipRectLayer(clipRect: _inset),
            ClipRectLayer(clipRect: _atOrigin),
            OpacityLayer(alpha: 128),
          ]),
        ),
        isFalse,
      );
    });

    test('is the root where a clip starts outside it', () {
      expect(
        backdropReadsRootPass(
          _surfaceUnder([
            ClipRectLayer(clipRect: const Rect.fromLTWH(-20, -20, 300, 300)),
            OpacityLayer(alpha: 128),
          ]),
        ),
        isTrue,
      );
    });

    test('is the root within a device pixel of it, and not past one', () {
      // At 2x, 0.4 logical pixels is 0.8 device pixels and 0.5 is one.
      expect(
        backdropReadsRootPass(
          _surfaceUnder([
            ClipRectLayer(clipRect: const Rect.fromLTWH(0.4, 0.4, 300, 300)),
            OpacityLayer(alpha: 128),
          ]),
        ),
        isTrue,
      );
      expect(
        backdropReadsRootPass(
          _surfaceUnder([
            ClipRectLayer(clipRect: const Rect.fromLTWH(0.5, 0.5, 300, 300)),
            OpacityLayer(alpha: 128),
          ]),
        ),
        isFalse,
      );
    });

    test('does not depend on the device pixel ratio', () {
      for (final scale in [1.0, 1.5, 2.0, 3.0]) {
        expect(
          backdropReadsRootPass(
            _surfaceUnder([
              ClipRectLayer(clipRect: _inset),
              OpacityLayer(alpha: 128),
            ], scale: scale),
          ),
          isFalse,
          reason: 'an inset clip at ${scale}x',
        );
        expect(
          backdropReadsRootPass(
            _surfaceUnder([
              ClipRectLayer(clipRect: _atOrigin),
              OpacityLayer(alpha: 128),
            ], scale: scale),
          ),
          isTrue,
          reason: 'a clip at the origin at ${scale}x',
        );
      }
    });
  });

  group('a pass inside a pass', () {
    test('is moved by the clips above the nearer one, those above the '
        'farther one included', () {
      expect(
        backdropReadsRootPass(
          _surfaceUnder([
            ClipRectLayer(clipRect: _inset),
            OpacityLayer(alpha: 128),
            ShaderMaskLayer(),
          ]),
        ),
        isFalse,
      );
    });

    test('reads the root when no clip above either starts elsewhere', () {
      expect(
        backdropReadsRootPass(
          _surfaceUnder([
            OpacityLayer(alpha: 128),
            ShaderMaskLayer(),
            ClipRectLayer(clipRect: _inset),
          ]),
        ),
        isTrue,
      );
    });

    test('is moved by a clip between them', () {
      expect(
        backdropReadsRootPass(
          _surfaceUnder([
            OpacityLayer(alpha: 128),
            ClipRectLayer(clipRect: _inset),
            BackdropFilterLayer(),
          ]),
        ),
        isFalse,
      );
    });
  });

  group('the render object', () {
    testWidgets('asks about the layer it paints', (tester) async {
      final program = await FragmentProgram.fromAsset(
        'shaders/surface_refraction.frag',
      );
      Widget surface() => SurfaceBackdrop(
        material: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        program: program,
        refraction: const CoreSurfaceRefraction(bezel: 0.2),
        cornerRadius: 12,
        devicePixelRatio: 1,
        child: const SizedBox(width: 80, height: 40),
      );
      // A clip whose box starts away from the root's origin.
      Widget inset(Widget child) => Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 40, top: 40),
          child: ClipRect(child: child),
        ),
      );
      bool reads() => tester
          .renderObject<RenderSurfaceBackdrop>(find.byType(SurfaceBackdrop))
          .debugReadsRootPass;

      await tester.pumpWidget(Center(child: surface()));
      expect(reads(), isTrue, reason: 'nothing above the surface');

      await tester.pumpWidget(inset(surface()));
      expect(reads(), isTrue, reason: 'a clip alone saves no pass');

      await tester.pumpWidget(inset(Opacity(opacity: 0.5, child: surface())));
      expect(reads(), isFalse, reason: 'an opacity under an inset clip');

      await tester.pumpWidget(
        Opacity(opacity: 0.5, child: inset(surface())),
      );
      expect(reads(), isTrue, reason: 'an opacity above an inset clip');

      await tester.pumpWidget(
        Center(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
            child: surface(),
          ),
        ),
      );
      expect(reads(), isFalse, reason: 'an image filter');

      await tester.pumpWidget(
        inset(
          SurfaceBackdrop(
            material: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            program: program,
            refraction: const CoreSurfaceRefraction(bezel: 0.2),
            cornerRadius: 12,
            devicePixelRatio: 1,
            child: Center(child: surface()),
          ),
        ),
      );
      expect(
        tester
            .renderObjectList<RenderSurfaceBackdrop>(
              find.byType(SurfaceBackdrop),
            )
            .map((render) => render.debugReadsRootPass),
        [isTrue, isFalse],
        reason:
            'the outer glass layer sits under a clip alone and reads the '
            'root; the one inside it is under a pass that starts at the clip',
      );
    });
  });
}
