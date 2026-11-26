// The key → index arithmetic every Web composite collection (menu ·
// menubar · tree · listbox · tablist) shares. The live keydown dispatch is
// not exercised here — `universal_web`'s `KeyboardEvent.key` getter throws
// on the VM this suite runs on — so the pure half is pinned instead, and
// each collection's SSR test pins the roving attributes it renders.
import 'package:coui_web/src/base/roving_focus.dart';
import 'package:jaspr_test/jaspr_test.dart';

void main() {
  group('rovingTargetIndex', () {
    int? move(
      String key, {
      int current = 1,
      int count = 4,
      bool vertical = true,
      bool wrap = true,
    }) => rovingTargetIndex(
      key,
      current: current,
      count: count,
      vertical: vertical,
      wrap: wrap,
    );

    test('a vertical collection walks Up/Down and ignores Left/Right', () {
      expect(move('ArrowDown'), 2);
      expect(move('ArrowUp'), 0);
      // The cross axis is not this collection's — a tree uses it for
      // expand/collapse, a menubar's submenu for opening.
      expect(move('ArrowLeft'), isNull);
      expect(move('ArrowRight'), isNull);
    });

    test('a horizontal collection walks Left/Right and ignores Up/Down', () {
      expect(move('ArrowRight', vertical: false), 2);
      expect(move('ArrowLeft', vertical: false), 0);
      expect(move('ArrowDown', vertical: false), isNull);
      expect(move('ArrowUp', vertical: false), isNull);
    });

    test('Home and End jump to the ends', () {
      expect(move('Home'), 0);
      expect(move('End'), 3);
    });

    test('with wrap the ends join', () {
      expect(move('ArrowDown', current: 3), 0);
      expect(move('ArrowUp', current: 0), 3);
    });

    test('without wrap the ends are walls', () {
      expect(move('ArrowDown', current: 3, wrap: false), 3);
      expect(move('ArrowUp', current: 0, wrap: false), 0);
    });

    test('keys the collection does not own are not consumed', () {
      expect(move('Enter'), isNull);
      expect(move('a'), isNull);
      expect(move('Tab'), isNull);
    });

    group('in a grid', () {
      // 3 columns, 7 items:  0 1 2 / 3 4 5 / 6
      int? step(String key, int current) => rovingTargetIndex(
        key,
        current: current,
        count: 7,
        vertical: true,
        columns: 3,
      );

      test('Left/Right step one item, Up/Down one row', () {
        expect(step('ArrowRight', 1), 2);
        expect(step('ArrowLeft', 1), 0);
        expect(step('ArrowDown', 1), 4);
        expect(step('ArrowUp', 4), 1);
      });

      test('a step off the grid leaves focus where it is', () {
        expect(step('ArrowUp', 1), 1);
        expect(step('ArrowDown', 4), 4);
        expect(step('ArrowRight', 6), 6);
        expect(step('ArrowLeft', 0), 0);
      });

      test('Home and End still jump to the ends', () {
        expect(step('Home', 4), 0);
        expect(step('End', 1), 6);
      });
    });

    test('an empty collection has nowhere to go', () {
      expect(move('ArrowDown', count: 0), isNull);
      expect(move('Home', count: 0), isNull);
    });
  });

  group('isRovingTypeaheadKey', () {
    test('one printable character is typeahead, with or without Shift', () {
      expect(isRovingTypeaheadKey('a'), isTrue);
      expect(isRovingTypeaheadKey('A'), isTrue);
    });

    test('named keys and command chords are not', () {
      expect(isRovingTypeaheadKey('ArrowDown'), isFalse);
      expect(isRovingTypeaheadKey('a', ctrl: true), isFalse);
      expect(isRovingTypeaheadKey('a', meta: true), isFalse);
      expect(isRovingTypeaheadKey('a', alt: true), isFalse);
    });
  });

  group('RovingTypeahead', () {
    const labels = ['Apple', 'Banana', 'Blueberry', 'Cherry'];

    late DateTime now;
    late RovingTypeahead typeahead;

    setUp(() {
      now = DateTime(2026);
      typeahead = RovingTypeahead(clock: () => now);
    });

    test('a letter jumps to the next label starting with it', () {
      expect(typeahead.next('b', labels: labels, current: 0), 1);
    });

    test('repeating one letter cycles the labels that share it', () {
      expect(typeahead.next('b', labels: labels, current: 0), 1);
      expect(typeahead.next('b', labels: labels, current: 1), 2);
      expect(typeahead.next('b', labels: labels, current: 2), 1);
    });

    test('letters typed inside the window build one search', () {
      expect(typeahead.next('b', labels: labels, current: 0), 1);
      expect(typeahead.next('l', labels: labels, current: 1), 2);
    });

    test('a pause longer than the window starts a new search', () {
      expect(typeahead.next('b', labels: labels, current: 0), 1);
      now = now.add(kRovingTypeaheadWindow + const Duration(milliseconds: 1));
      expect(typeahead.next('c', labels: labels, current: 1), 3);
    });

    test('matching ignores case', () {
      expect(typeahead.next('C', labels: labels, current: 0), 3);
    });

    test('a space that would start a run is activation, not a search', () {
      expect(typeahead.next(' ', labels: const [' x'], current: 0), isNull);
    });

    test('with nothing active the search starts from the top', () {
      expect(typeahead.next('b', labels: labels, current: -1), 1);
    });

    test('no match leaves focus where it is', () {
      expect(typeahead.next('z', labels: labels, current: 0), isNull);
    });
  });

  group('rovingItemAttributes', () {
    test('only the active item is a tab stop, and each is host-scoped', () {
      expect(rovingItemAttributes('host', 2, active: true), {
        'tabindex': '0',
        kRovingItemAttribute: 'host:2',
      });
      expect(rovingItemAttributes('host', 3, active: false), {
        'tabindex': '-1',
        kRovingItemAttribute: 'host:3',
      });
    });
  });
}
