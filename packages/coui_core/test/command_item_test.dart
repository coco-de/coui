import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreCommandItem.matchesQuery', () {
    const calendar = CoreCommandItem<Never>(
      value: 'calendar',
      label: 'Calendar',
      keywords: ['date', 'schedule'],
    );

    test('empty query matches every row', () {
      expect(calendar.matchesQuery(''), isTrue);
      expect(calendar.matchesQuery('   '), isTrue);
    });

    test('label substring still hits', () {
      expect(calendar.matchesQuery('Cal'), isTrue);
      expect(calendar.matchesQuery('endar'), isTrue);
    });

    test('a keyword hits when the label misses', () {
      expect(calendar.matchesQuery('date'), isTrue);
      expect(calendar.matchesQuery('SCHED'), isTrue);
    });

    test('neither label nor keyword is a miss', () {
      expect(calendar.matchesQuery('zzz'), isFalse);
    });

    test('overline is not a filter target', () {
      const item = CoreCommandItem<Never>(
        value: 'profile',
        label: 'Profile',
        overline: 'Account',
      );
      expect(item.matchesQuery('Account'), isFalse);
      expect(item.matchesQuery('Profile'), isTrue);
    });
  });

  group('CoreCommandItem equality', () {
    test('keywords participate in == and hashCode', () {
      const a = CoreCommandItem<Never>(
        value: 'x',
        label: 'X',
        keywords: ['a'],
      );
      const b = CoreCommandItem<Never>(
        value: 'x',
        label: 'X',
        keywords: ['a'],
      );
      const c = CoreCommandItem<Never>(
        value: 'x',
        label: 'X',
        keywords: ['b'],
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
