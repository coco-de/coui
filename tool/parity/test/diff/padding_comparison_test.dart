import 'package:test/test.dart';

import '../../src/diff/property_diff.dart';
import '../../src/model/property_snapshot.dart';

PropertySnapshot _snapshot(
  FourSidePx? padding, {
  double border = 1,
  String platform = 'flutter',
}) => PropertySnapshot(
  key: 'captured-insets',
  platform: platform,
  probeRole: 'root',
  paddingPx: padding,
  borderWidthPx: border,
);

FieldDivergence _padding(PropertyDiffResult result) =>
    result.fields.singleWhere((field) => field.field == 'paddingPx');

void main() {
  group(
    'captured padding is compared without reconstructing authored values',
    () {
      for (final entry in [
        (
          name: 'equal captured insets with a one-pixel border',
          native: const FourSidePx(3, 3, 3, 3),
          web: const FourSidePx(3, 3, 3, 3),
          border: 1.0,
          matches: true,
        ),
        (
          name: 'equal captured zero with a one-pixel border',
          native: const FourSidePx(0, 0, 0, 0),
          web: const FourSidePx(0, 0, 0, 0),
          border: 1.0,
          matches: true,
        ),
        (
          name: 'equal captured insets with a two-pixel border',
          native: const FourSidePx(8, 16, 8, 16),
          web: const FourSidePx(8, 16, 8, 16),
          border: 2.0,
          matches: true,
        ),
        (
          name: 'a real one-pixel vertical difference stays visible',
          native: const FourSidePx(7, 16, 7, 16),
          web: const FourSidePx(8, 16, 8, 16),
          border: 1.0,
          matches: false,
        ),
        (
          name: 'a signed captured value is neither offset nor clamped',
          native: const FourSidePx(-1, 0, -1, 0),
          web: const FourSidePx(0, 0, 0, 0),
          border: 1.0,
          matches: false,
        ),
        (
          name: 'a fractional border cannot change reported inset values',
          native: const FourSidePx(2.25, 4, 3.75, 6),
          web: const FourSidePx(2.25, 4, 3.75, 6),
          border: 0.25,
          matches: true,
        ),
      ]) {
        test(entry.name, () {
          final native = _snapshot(entry.native, border: entry.border);
          final web = _snapshot(
            entry.web,
            border: entry.border,
            platform: 'web',
          );
          final field = _padding(
            comparePropertySnapshots(flutter: native, web: web),
          );

          expect(field.matches, entry.matches);
          expect(field.flutterDescription, entry.native.toString());
          expect(field.webDescription, entry.web.toString());
          expect(native.paddingPx, entry.native);
          expect(web.paddingPx, entry.web);
        });
      }
    },
  );

  group('existing absent/zero padding semantics', () {
    for (final entry in <({FourSidePx? native, FourSidePx? web, bool matches})>[
      (native: null, web: null, matches: true),
      (native: null, web: const FourSidePx(0, 0, 0, 0), matches: true),
      (native: const FourSidePx(0, 0, 0, 0), web: null, matches: true),
      (native: null, web: const FourSidePx(2, 0, 2, 0), matches: false),
    ]) {
      test('${entry.native} vs ${entry.web}', () {
        final field = _padding(
          comparePropertySnapshots(
            flutter: _snapshot(entry.native),
            web: _snapshot(entry.web, platform: 'web'),
          ),
        );
        expect(field.matches, entry.matches);
        expect(field.flutterDescription, entry.native?.toString() ?? 'null');
        expect(field.webDescription, entry.web?.toString() ?? 'null');
      });
    }
  });

  test('equal captured values also match their expected inset', () {
    const insets = FourSidePx(3, 3, 3, 3);
    final field = _padding(
      comparePropertySnapshots(
        flutter: _snapshot(insets),
        web: _snapshot(insets, platform: 'web'),
        expected: _snapshot(insets),
      ),
    );
    expect(field.matches, isTrue);
    expect(field.tokenDivergence, TokenDivergence.neitherDiverges);
  });

  test('expected inset identifies the actual differing captured side', () {
    final field = _padding(
      comparePropertySnapshots(
        flutter: _snapshot(const FourSidePx(7, 16, 7, 16)),
        web: _snapshot(const FourSidePx(8, 16, 8, 16), platform: 'web'),
        expected: _snapshot(const FourSidePx(8, 16, 8, 16)),
      ),
    );
    expect(field.matches, isFalse);
    expect(field.tokenDivergence, TokenDivergence.flutterDiverges);
  });

  test(
    'existing same-platform caller flag remains accepted without an offset',
    () {
      final snapshot = _snapshot(const FourSidePx(3, 3, 3, 3));
      final samePlatform = _padding(
        comparePropertySnapshots(
          flutter: snapshot,
          web: snapshot,
          reconcilePlatforms: false,
        ),
      );
      final defaultCall = _padding(
        comparePropertySnapshots(flutter: snapshot, web: snapshot),
      );
      expect(samePlatform.matches, isTrue);
      expect(defaultCall.matches, samePlatform.matches);
      expect(defaultCall.flutterDescription, samePlatform.flutterDescription);
    },
  );

  for (final (difference, matches) in [(0.5, true), (0.51, false)]) {
    test('existing half-pixel tolerance: delta $difference', () {
      final field = _padding(
        comparePropertySnapshots(
          flutter: _snapshot(FourSidePx(3 + difference, 3, 3, 3)),
          web: _snapshot(const FourSidePx(3, 3, 3, 3), platform: 'web'),
        ),
      );
      expect(field.matches, matches);
    });
  }
}
