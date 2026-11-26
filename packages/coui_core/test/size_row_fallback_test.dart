// `CoreComponentSize` is shared by the whole kit; the tables are not.
//
// A table that leaves a size out turns that choice into a crash under a
// bare `table[size]!`: the parameter accepts the whole enum, the analyser
// sees nothing wrong, and the null-check fires at render with no message.
// Measured on both platforms before `resolveSizeRow` existed —
// `Badge(size: .xl2)` and `TextArea(size: .xl2)` each threw `Null check
// operator used on a null value`. Both ladders now state all six tiers, so
// `resolveSizeRow`'s fallback is exercised on hand-made tables below.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('a size the table does not state falls to the nearest below', () {
    const table = {
      CoreComponentSize.sm: 'sm',
      CoreComponentSize.md: 'md',
      CoreComponentSize.xl: 'xl',
    };

    test('a stated size is returned exactly', () {
      expect(resolveSizeRow(table, CoreComponentSize.md), 'md');
    });

    test('an unstated size above the ladder takes the top of it', () {
      // Asserts fire in a debug build and this suite runs in one, so the
      // fallback is exercised through the throw rather than around it.
      expect(
        () => resolveSizeRow(table, CoreComponentSize.xl2),
        throwsA(isA<AssertionError>()),
      );
    });

    test('an unstated size in the middle reaches DOWN, not up', () {
      // `lg` is unstated. Reaching up would give `xl` — a size the table
      // states for a LARGER request, which is the worse guess: a component
      // stops at a step because the next one was not designed, so the step
      // below is what its author last decided.
      final error = _assertionFrom(
        () => resolveSizeRow(table, CoreComponentSize.lg),
      );
      expect(error, contains('md'));
      expect(error, isNot(contains('xl,')));
    });

    test('an unstated size below everything takes the smallest', () {
      final error = _assertionFrom(
        () => resolveSizeRow(table, CoreComponentSize.xs),
      );
      expect(error, contains('smallest is sm'));
    });

    test('the message names the size that was asked for', () {
      // The whole point of the assert over a silent clamp: whoever wrote
      // the call has to be able to find it.
      expect(
        _assertionFrom(() => resolveSizeRow(table, CoreComponentSize.xl2)),
        contains('xl2'),
      );
    });

    test('an empty table is a build failure, not a missing size', () {
      expect(
        () =>
            resolveSizeRow(<CoreComponentSize, String>{}, CoreComponentSize.md),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message.toString(),
            'message',
            contains('failed to build'),
          ),
        ),
      );
    });
  });

  group('the ladders that were once short now state every tier', () {
    test('Badge states the whole six-tier ladder', () {
      expect(
        CoreBadgeStyle.defaultsBySize.keys,
        contains(CoreComponentSize.xl2),
      );
      expect(CoreBadgeStyle.defaultsBySize, hasLength(6));
    });

    test('TextArea states the whole six-tier ladder', () {
      expect(
        CoreTextAreaStyle.defaultsBySize.keys,
        contains(CoreComponentSize.xl2),
      );
      expect(CoreTextAreaStyle.defaultsBySize, hasLength(6));
    });
  });

  // TextField and TextArea read their rows through `resolveSizeRow`, so a
  // tier can leave either ladder without the field crashing. The `xs`
  // retirement (`CoreTextFieldContract.retiringSizes`) ends with exactly
  // that removal; until then every tier still has its own row and the
  // reader must hand it back untouched.
  group('the field ladders survive losing their xs row', () {
    final ladders = {
      'TextField': CoreTextFieldStyle.defaultsBySize,
      'TextArea': CoreTextAreaStyle.defaultsBySize,
    };

    for (final MapEntry(key: name, value: ladder) in ladders.entries) {
      test('$name — every stated tier comes back as its own row', () {
        for (final size in CoreComponentSize.values) {
          expect(
            identical(resolveSizeRow(ladder, size), ladder[size]),
            isTrue,
            reason: '$name ${size.name}',
          );
        }
      });

      test('$name — without its xs row, xs falls to sm and says so', () {
        final withoutXs = {
          for (final entry in ladder.entries)
            if (entry.key != CoreComponentSize.xs) entry.key: entry.value,
        };
        final error = _assertionFrom(
          () => resolveSizeRow(withoutXs, CoreComponentSize.xs),
        );
        expect(error, contains('xs'));
        expect(error, contains('smallest is sm'));
      });
    }
  });
}

String _assertionFrom(void Function() body) {
  try {
    body();
  } on AssertionError catch (e) {
    return e.message.toString();
  }
  fail('expected an AssertionError, the fallback did not report itself');
}
