import 'package:coui_web/src/overlay/positioning/registry.dart';
import 'package:test/test.dart';

/// Minimal entry used by the tests; counts how many times it was asked to close.
class _CountingEntry implements OverlayPositionEntry {
  int closeCount = 0;

  @override
  void requestClose() {
    closeCount += 1;
  }
}

void main() {
  setUp(OverlayPositionRegistry.debugReset);

  group('OverlayPositionRegistry', () {
    test('initial state has no active entry', () {
      expect(OverlayPositionRegistry.hasActive, isFalse);
    });

    test('open registers the entry', () {
      final e = _CountingEntry();
      OverlayPositionRegistry.open(e);
      expect(OverlayPositionRegistry.hasActive, isTrue);
    });

    test('close clears only when the entry is active', () {
      final a = _CountingEntry();
      final b = _CountingEntry();
      OverlayPositionRegistry.open(a);
      OverlayPositionRegistry.close(b);
      // b was never active so close is a no-op.
      expect(OverlayPositionRegistry.hasActive, isTrue);

      OverlayPositionRegistry.close(a);
      expect(OverlayPositionRegistry.hasActive, isFalse);
    });

    test('opening a second entry closes the first', () {
      final first = _CountingEntry();
      final second = _CountingEntry();
      OverlayPositionRegistry.open(first);
      OverlayPositionRegistry.open(second);
      expect(first.closeCount, 1);
      expect(second.closeCount, 0);
      expect(OverlayPositionRegistry.hasActive, isTrue);
    });

    test('re-opening the same entry is a no-op', () {
      final e = _CountingEntry();
      OverlayPositionRegistry.open(e);
      OverlayPositionRegistry.open(e);
      expect(e.closeCount, 0);
    });
  });
}
