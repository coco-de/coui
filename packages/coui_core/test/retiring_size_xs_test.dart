// `xs` retires from TextField, TextArea and Toggle together.
//
// Each component states its own `retiringSizes`, and the notice it logs
// makes two promises about the ladder: which row replaces `xs`, and whether
// the look changes at all. Both are pinned to the ladder itself here — the
// `fallback` must be the row `xs` lands on once its own row is gone, and
// `alreadyFallsBack` must be true exactly where the row is already gone
// today. The release it names is a schedule, not a ladder fact; this only
// checks that the three components name the same one.
//
// Button is deliberately not among them — its `xs` stays.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  final retiring = {
    'TextField': CoreTextFieldContract.retiringSizes,
    'TextArea': CoreTextAreaContract.retiringSizes,
    'Toggle': CoreToggleContract.retiringSizes,
  };
  final ladders = <String, Map<CoreComponentSize, Object>>{
    'TextField': CoreTextFieldStyle.defaultsBySize,
    'TextArea': CoreTextAreaStyle.defaultsBySize,
    'Toggle': CoreToggleStyle.defaultsBySize,
  };

  test('the three retire xs, and only xs, toward sm on one release', () {
    for (final MapEntry(key: name, value: list) in retiring.entries) {
      expect(list, hasLength(1), reason: name);
      final step = list.single;
      expect(step.size, CoreComponentSize.xs, reason: name);
      expect(step.fallback, CoreComponentSize.sm, reason: name);
    }
    final releases = {
      for (final list in retiring.values) list.single.removedIn,
    };
    expect(releases, hasLength(1), reason: 'one decision, one release');
  });

  for (final MapEntry(key: name, value: ladder) in ladders.entries) {
    group(name, () {
      final step = retiring[name]!.single;

      test('says it already falls back exactly when the row is gone', () {
        expect(step.alreadyFallsBack, isNot(ladder.containsKey(step.size)));
      });

      test('the fallback is the row xs lands on once its own is gone', () {
        // `resolveSizeRow` takes the nearest stated row below, else the
        // smallest stated one; nothing sits below `xs`, so it is the
        // smallest row left once `xs` is out of the table.
        final left = [
          for (final size in CoreComponentSize.values)
            if (size != step.size && ladder.containsKey(size)) size,
        ];
        expect(left.first, step.fallback);
      });
    });
  }

  test('Toggle draws its fallback today, so its look holds', () {
    final step = CoreToggleContract.retiringSizes.single;
    expect(
      identical(
        CoreToggleStyle.sizeDefaults(step.size),
        CoreToggleStyle.sizeDefaults(step.fallback),
      ),
      isTrue,
    );
  });
}
