import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

/// How many space-separated tokens a shadow layer's offset/blur/spread
/// prefix takes before the colour term starts.
const _kShapeTokenCount = 4;

/// A one-layer control cast, matching the shape neo-brutalism actually
/// authors (`surface_recipe.dart`'s `controlShadow`) — a single hard
/// layer thrown down-and-right, no blur.
const _kCast = [
  (
    offsetX: 4.0,
    offsetY: 4.0,
    blurRadius: 0.0,
    spreadRadius: 0.0,
    opacity: 1.0,
    inset: false,
  ),
];

const _kFixture = CoreSurfaceGeometryConstraint(
  shadowOffsetAdd: (dx: 4, dy: 4),
  controlShadow: _kCast,
);

void main() {
  final config = ThemeConfig.defaults();

  group('the ghost twin [kControlShadowGhostVar] describes', () {
    test(
      'is published alongside the real cast for a style that states one',
      () {
        final block = config.surfaceStyleGeometryBlock(
          .neoBrutalism,
          _kFixture,
        );

        expect(block, contains('--coui-control-shadow:'));
        expect(block, contains('--coui-control-shadow-ghost:'));
      },
    );

    test('matches the real cast\'s offset, blur and spread exactly', () {
      final block = config.surfaceStyleGeometryBlock(.neoBrutalism, _kFixture);

      // Read each declaration's shape prefix back out and compare —
      // reads the resolver's actual output rather than assuming a
      // rem-conversion format, so a change to that format cannot make
      // this test pass while the shapes have actually diverged.
      String shapeOf(String varName) {
        final start = block.indexOf('$varName:') + varName.length + 1;
        final end = block.indexOf(';', start);
        final value = block.substring(start, end);
        // Drop the colour term (the part that legitimately differs) —
        // everything up to and including the offset/blur/spread tokens.
        return value.split(' ').take(_kShapeTokenCount).join(' ');
      }

      expect(
        shapeOf('--coui-control-shadow'),
        shapeOf('--coui-control-shadow-ghost'),
        reason:
            'a mismatched shape is exactly what risks the '
            'mismatched-layer-count black flash (process/verify.md '
            '§7-24) — the shapes must be identical, only colour alpha '
            'may differ',
      );
    });

    test(
      'differs from the real cast only in colour alpha — same rgb() '
      'token, not a color-mix() collapse to transparent',
      () {
        final block = config.surfaceStyleGeometryBlock(
          .neoBrutalism,
          _kFixture,
        );
        final ghostStart =
            block.indexOf('--coui-control-shadow-ghost:') +
            '--coui-control-shadow-ghost:'.length;
        final ghostValue = block.substring(
          ghostStart,
          block.indexOf(';', ghostStart),
        );
        final realStart =
            block.indexOf('--coui-control-shadow:') +
            '--coui-control-shadow:'.length;
        final realValue = block.substring(
          realStart,
          block.indexOf(';', realStart),
        );

        expect(
          ghostValue,
          contains('rgb(var(--coui-shadow) / 0%)'),
          reason:
              'the rgb() slash-alpha form keeps the colour channel — '
              'color-mix(in srgb, X 0%, transparent) is defined as '
              'exactly transparent (rgba(0,0,0,0)), dropping X\'s colour '
              'entirely rather than keeping it at zero alpha. Measured '
              'in a real browser (headless Chrome, #4405): the '
              'color-mix form read back as color(srgb 0 0 0 / 0) '
              'against a real cast of rgb(255 255 255) — different '
              'colours, not the same colour at different alphas.',
        );
        expect(realValue, contains('rgb(var(--coui-shadow))'));
        expect(
          realValue,
          isNot(contains('color-mix')),
          reason:
              'confirms the two differ only in the rgb() alpha term, '
              'not in which colour-producing function is used',
        );
      },
    );

    test('a style that states no controlShadow publishes nothing new', () {
      final block = config.surfaceStyleGeometryBlock(
        .neoBrutalism,
        const CoreSurfaceGeometryConstraint(),
      );

      expect(block, isNot(contains('--coui-control-shadow-ghost:')));
    });

    test('the root default is the same "nothing" layer real cast uses', () {
      expect(
        config.cssVariables,
        contains('--coui-control-shadow-ghost:0 0 0 0 transparent;'),
      );
    });
  });

  group('the reverse-offset pair mirrors the real offset', () {
    test('is negated dx/dy, published alongside the real pair', () {
      final block = config.surfaceStyleGeometryBlock(.neoBrutalism, _kFixture);

      expect(block, contains('--coui-control-shadow-offset-x:4.0px;'));
      expect(block, contains('--coui-control-shadow-offset-y:4.0px;'));
      expect(block, contains('--coui-control-shadow-offset-x-reverse:-4.0px;'));
      expect(block, contains('--coui-control-shadow-offset-y-reverse:-4.0px;'));
    });

    test('a style that states no shadowOffsetAdd publishes neither pair', () {
      final block = config.surfaceStyleGeometryBlock(
        .neoBrutalism,
        const CoreSurfaceGeometryConstraint(),
      );

      expect(block, isNot(contains('--coui-control-shadow-offset-x-reverse')));
      expect(block, isNot(contains('--coui-control-shadow-offset-y-reverse')));
    });
  });
}
