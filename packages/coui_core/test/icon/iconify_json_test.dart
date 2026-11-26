/// Iconify input metadata must survive resolution into drawable SVG data.
library;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kBody = '<path d="M2 1h7v3H2z"/>';

IconifyJson _collection({
  Map<String, dynamic> defaults = const {},
  Map<String, dynamic> icon = const {},
  Map<String, dynamic> aliases = const {},
}) => IconifyJson.fromJson({
  'width': 30,
  'height': 20,
  ...defaults,
  'icons': {
    'base': {'body': _kBody, ...icon},
  },
  'aliases': aliases,
});

// Apply the emitted SVG matrix to a known authored point. Expected positions
// below come from the viewBox edges, independently of the parser's arithmetic.
(num, num) _point(IconSvgData data, num x, num y) {
  final match = RegExp(r'^<g transform="matrix\(([^)]+)\)">').firstMatch(
    data.body,
  );
  if (match == null) {
    expect(data.body, _kBody);
    return (x, y);
  }
  final values = match.group(1)!.split(RegExp('[ ,]+')).map(num.parse).toList();
  expect(values, hasLength(6));
  final [a, b, c, d, e, f] = values;
  return (a * x + c * y + e, b * x + d * y + f);
}

void main() {
  test(
    'standalone SVG data keeps its existing constructor and JSON defaults',
    () {
      const data = IconSvgData(body: _kBody);
      expect(data.width, 24);
      expect(data.height, 24);
      expect(
        IconSvgData.fromJson(const {'body': _kBody}).toJson(),
        data.toJson(),
      );
      expect(data.toJson(), {'body': _kBody, 'width': 24, 'height': 24});
    },
  );

  test('a collection without dimensions uses the Iconify 16-unit viewBox', () {
    final collection = IconifyJson.fromJson({
      'icons': {
        'base': {'body': _kBody},
      },
    });
    expect(collection.defaultWidth, 16);
    expect(collection.defaultHeight, 16);
    expect(collection.resolve('base')!.toJson(), {
      'body': _kBody,
      'width': 16,
      'height': 16,
    });
  });

  test('untransformed bodies and alias dimension precedence stay intact', () {
    final collection = _collection(
      icon: {'width': 28},
      aliases: {
        'parent': {'parent': 'base', 'width': 26, 'height': 18},
        'leaf': {'parent': 'parent', 'width': 22},
      },
    );
    expect(collection.resolve('base')!.toJson(), {
      'body': _kBody,
      'width': 28,
      'height': 20,
    });
    expect(collection.resolve('leaf')!.toJson(), {
      'body': _kBody,
      'width': 22,
      'height': 18,
    });
    expect(collection.names, ['base', 'parent', 'leaf']);
  });

  for (final (name, properties, point, dimensions)
      in <(String, Map<String, dynamic>, (num, num), (int, int))>[
        ('horizontal', {'hFlip': true}, (28, 1), (30, 20)),
        ('vertical', {'vFlip': true}, (2, 19), (30, 20)),
        ('both', {'hFlip': true, 'vFlip': true}, (28, 19), (30, 20)),
        ('clockwise', {'rotate': 1}, (19, 2), (20, 30)),
        ('half turn', {'rotate': 2}, (28, 19), (30, 20)),
        ('counterclockwise', {'rotate': 3}, (1, 28), (20, 30)),
        ('negative rotation', {'rotate': -1}, (1, 28), (20, 30)),
        ('extra rotation', {'rotate': 5}, (19, 2), (20, 30)),
        ('flip then rotate', {'hFlip': true, 'rotate': 1}, (19, 28), (20, 30)),
      ]) {
    for (final direct in [true, false]) {
      test('$name metadata on ${direct ? 'an icon' : 'an alias'}', () {
        final collection = _collection(
          icon: direct ? properties : const {},
          aliases: {
            'alias': {'parent': 'base', if (!direct) ...properties},
          },
        );
        final data = collection.resolve(direct ? 'base' : 'alias')!;
        expect((data.width, data.height), dimensions);
        expect(_point(data, 2, 1), point);
        expect(data.body, contains(_kBody));
      });
    }
  }

  test('collection, icon and chained alias transformations compose', () {
    final collection = _collection(
      defaults: {'hFlip': true, 'rotate': 1},
      icon: {'vFlip': true, 'rotate': 1},
      aliases: {
        'parent': {'parent': 'base', 'hFlip': true, 'rotate': 1},
        'leaf': {'parent': 'parent', 'vFlip': true},
      },
    );
    final data = collection.resolve('leaf')!;
    expect((data.width, data.height), (20, 30));
    expect(_point(data, 2, 1), (1, 28));
  });

  test(
    'flips toggle and rotations cancel without rewriting an identity body',
    () {
      final collection = _collection(
        icon: {'hFlip': true, 'rotate': 1},
        aliases: {
          'alias': {'parent': 'base', 'hFlip': true, 'rotate': -1},
        },
      );
      expect(collection.resolve('alias')!.body, _kBody);
      expect(
        _collection(
          icon: {'hFlip': true, 'vFlip': true, 'rotate': 2},
        ).resolve('base')!.body,
        _kBody,
      );
    },
  );

  test('alias dimensions apply before odd rotations swap the viewBox axes', () {
    final data = _collection(
      aliases: {
        'alias': {'parent': 'base', 'width': 40, 'rotate': 1},
      },
    ).resolve('alias')!;
    expect((data.width, data.height), (20, 40));
    expect(_point(data, 2, 1), (19, 2));
  });

  for (final (left, top) in [(10, 20), (10.5, 20.25)]) {
    test(
      'viewBox origin $left/$top survives alias and rotation resolution',
      () {
        final data = _collection(
          defaults: {'left': left, 'top': top},
          aliases: {
            'alias': {'parent': 'base', 'rotate': 1},
          },
        ).resolve('alias')!;
        expect((data.width, data.height), (20, 30));
        expect(_point(data, left + 2, top + 1), (19, 2));
      },
    );
  }

  test('a leaf can override inherited viewBox origins with zero', () {
    final data = _collection(
      defaults: {'left': 10, 'top': 20},
      icon: {'left': 5},
      aliases: {
        'alias': {'parent': 'base', 'left': 0, 'top': 0},
      },
    ).resolve('alias')!;
    expect(data.body, _kBody);
  });

  test(
    'unknown parents, cycles and the existing ten-alias limit stay bounded',
    () {
      final collection = _collection(
        aliases: {
          'missing': {'parent': 'absent'},
          'cycle-a': {'parent': 'cycle-b', 'rotate': 1},
          'cycle-b': {'parent': 'cycle-a'},
          for (var depth = 1; depth <= 11; depth++)
            'depth-$depth': {
              'parent': depth == 1 ? 'base' : 'depth-${depth - 1}',
            },
        },
      );
      expect(collection.resolve('absent'), isNull);
      expect(collection.resolve('missing'), isNull);
      expect(collection.resolve('cycle-a'), isNull);
      expect(collection.resolve('depth-10')!.body, _kBody);
      expect(collection.resolve('depth-11'), isNull);
    },
  );
}
