// What a chat bubble that states nothing takes from the side it sits on.
//
// A thread tells the two senders apart by default: the `end` side is the
// reader's own message — a `primary` bubble with its tail on that side — and
// the `start` side is what was received, the neutral surface with no tail.
// Both platforms read these two functions, so the table below is the whole
// of what "by default" means; the platform tests check that a bubble reads it
// and that a bubble that states a value keeps it.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreChatBubbleContract.defaultVariantFor', () {
    test('start: the neutral default variant', () {
      expect(
        CoreChatBubbleContract.defaultVariantFor(CoreChatAlignment.start),
        CoreChatBubbleVariant.neutral,
      );
      expect(
        CoreChatBubbleContract.defaultVariantFor(CoreChatAlignment.start),
        CoreChatBubbleVariant.defaultVariant,
      );
    });

    test('end: primary', () {
      expect(
        CoreChatBubbleContract.defaultVariantFor(CoreChatAlignment.end),
        CoreChatBubbleVariant.primary,
      );
    });

    test('every alignment answers — the table has no gap', () {
      for (final alignment in CoreChatAlignment.values) {
        expect(
          () => CoreChatBubbleContract.defaultVariantFor(alignment),
          returnsNormally,
          reason: '$alignment',
        );
      }
    });
  });

  group('CoreChatBubbleContract.defaultTailFor', () {
    test('start: no tail — the resting pose of a bubble', () {
      expect(
        CoreChatBubbleContract.defaultTailFor(CoreChatAlignment.start),
        isFalse,
      );
      expect(
        CoreChatBubbleContract.defaultTailFor(CoreChatAlignment.start),
        CoreChatBubbleContract.defaultTail,
      );
    });

    test('end: a tail', () {
      expect(
        CoreChatBubbleContract.defaultTailFor(CoreChatAlignment.end),
        isTrue,
      );
    });

    test('every alignment answers — the table has no gap', () {
      for (final alignment in CoreChatAlignment.values) {
        expect(
          () => CoreChatBubbleContract.defaultTailFor(alignment),
          returnsNormally,
          reason: '$alignment',
        );
      }
    });
  });

  test('the end side asks for a variant that paints a fill for its tail', () {
    // A tail is the fill carried past the bubble's box; a default variant with
    // no fill would make the default tail a no-op the caller never sees.
    final variant = CoreChatBubbleContract.defaultVariantFor(
      CoreChatAlignment.end,
    );
    final row = CoreChatBubbleStyle.defaultsByVariant[variant]!;

    expect(row.backgroundColor, isNot(CoreColor.transparent));
  });
}
