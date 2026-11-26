// `CoreTextFieldStyle.boxMinHeight` is the one floor rule both resolvers
// read. Each branch is pinned here because the platform tests only reach
// the shipped sizes — a branch that returned the cap whenever one was
// stated, or dropped a caller's own minimum next to a fixed height, would
// pass every widget test that happens to sit on the default path.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

double? floorOf({
  double? height,
  double? minHeight,
  double? maxHeight,
  double? sizeFloor = 40,
}) => CoreTextFieldStyle.boxMinHeight(
  height: height,
  minHeight: minHeight,
  maxHeight: maxHeight,
  sizeFloor: sizeFloor,
);

void main() {
  test('nothing stated — the size row floor', () {
    expect(floorOf(), 40);
  });

  test('a caller minHeight replaces the floor, in either direction', () {
    expect(floorOf(minHeight: 30), 30);
    expect(floorOf(minHeight: 52), 52);
  });

  test('minHeight 0 states no floor', () {
    expect(floorOf(minHeight: 0), 0);
  });

  test('a fixed height drops the size floor', () {
    expect(floorOf(height: 36), isNull);
  });

  test('a fixed height keeps a caller minHeight (it clamps the height)', () {
    expect(floorOf(height: 36, minHeight: 44), 44);
  });

  test('a caller maxHeight below the floor caps it', () {
    expect(floorOf(maxHeight: 38), 38);
  });

  test('a caller maxHeight at or above the floor leaves it alone', () {
    expect(floorOf(maxHeight: 40), 40);
    expect(floorOf(maxHeight: 120), 40);
  });

  test('a caller minHeight is not capped by maxHeight here', () {
    // Two caller statements that disagree are the caller's to resolve;
    // the cap only ever trims the DEFAULT floor.
    expect(floorOf(minHeight: 50, maxHeight: 30), 50);
  });

  test('no size floor and nothing stated — no floor', () {
    expect(floorOf(sizeFloor: null), isNull);
  });

  test('every shipped size row states its control height as the floor', () {
    const control = {
      CoreComponentSize.xs: CoreControlSize.heightXs,
      CoreComponentSize.sm: CoreControlSize.heightSm,
      CoreComponentSize.md: CoreControlSize.heightMd,
      CoreComponentSize.lg: CoreControlSize.heightLg,
      CoreComponentSize.xl: CoreControlSize.heightXl,
      CoreComponentSize.xl2: CoreControlSize.heightXl2,
    };
    for (final size in CoreComponentSize.values) {
      final row = CoreTextFieldStyle.defaultsBySize[size]!;
      expect(row.minHeight, control[size], reason: size.name);
      expect(
        row.height,
        isNull,
        reason:
            '${size.name} — a fixed height '
            'in the row would pin every field',
      );
    }
  });
}
