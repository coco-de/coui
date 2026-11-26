import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

/// The padding a resolved inset produces, resolved against [direction].
///
/// Resolving is the whole point: a directional value has no left until a
/// text direction says which side that is. A guard can see that the
/// *declaration* is directional; only this can see that the pixels move.
EdgeInsets _resolved(EdgeInsetsGeometry insets, TextDirection direction) =>
    insets.resolve(direction);

void main() {
  group('a start-side inset follows the reading direction', () {
    test('a blockquote indents from the left in English', () {
      final insets = CoreTextBlockStyle.defaultBlockQuotePadding.toGeometry();

      expect(_resolved(insets, TextDirection.ltr).left, greaterThan(0));
      expect(_resolved(insets, TextDirection.rtl).left, 0);
    });

    test('and from the right in Arabic', () {
      // The half that makes this a real assertion. A physical value
      // passes the first case and fails here — and it passed the first
      // case for as long as the kit had no right-to-left locale to try.
      final insets = CoreTextBlockStyle.defaultBlockQuotePadding.toGeometry();

      expect(_resolved(insets, TextDirection.rtl).right, greaterThan(0));
      expect(_resolved(insets, TextDirection.ltr).right, 0);
    });

    test('the timeline title carries no inset by default, either way', () {
      // The default is symmetric (none), so there is no start side to
      // mirror — the title begins on the content column's edge.
      final insets = CoreTimelineStyle.defaultTitlePadding.toGeometry();

      expect(_resolved(insets, TextDirection.ltr), EdgeInsets.zero);
      expect(_resolved(insets, TextDirection.rtl), EdgeInsets.zero);
    });

    for (final (direction, startSide) in [
      (TextDirection.ltr, 'left'),
      (TextDirection.rtl, 'right'),
    ]) {
      testWidgets(
        'a caller-set timeline title inset lands on the $startSide in '
        '${direction.name}',
        (tester) async {
          // The machinery stays covered at the component, where the
          // pixels are: a directional inset a caller states on the title
          // is applied to the start side of the built tree.
          await pumpTestApp(
            tester,
            const SizedBox(
              width: 600,
              child: Timeline(
                items: [CoreTimelineItem(title: 'Account created')],
                timelineStyle: CoreTimelineStyle(
                  titlePadding: CoreEdgeInsets.directional(start: 16),
                ),
              ),
            ),
            textDirection: direction,
          );

          final padding = tester
              .widget<Padding>(
                find
                    .ancestor(
                      of: find.text('Account created'),
                      matching: find.byType(Padding),
                    )
                    .first,
              )
              .padding
              .resolve(direction);

          expect(
            direction == TextDirection.ltr ? padding.left : padding.right,
            16,
          );
          expect(
            direction == TextDirection.ltr ? padding.right : padding.left,
            0,
          );
        },
      );
    }
  });

  group('an end-side inset does too', () {
    test('a step is separated from the next one', () {
      final insets = CoreStepsStyle.defaultStepPaddingHorizontal.toGeometry();

      expect(_resolved(insets, TextDirection.ltr).right, greaterThan(0));
      expect(_resolved(insets, TextDirection.rtl).left, greaterThan(0));
    });

    test('and a dismissible toast reserves room for its close button', () {
      // Both horizontal values are non-zero here and merely unequal, so
      // this catches a subtler mistake than the cases above: swapping
      // them keeps padding on both sides and moves the extra room to the
      // wrong edge, where the button overlaps the text.
      final insets = CoreToastStyle.defaultPanelPaddingWithDismiss.toGeometry();
      final ltr = _resolved(insets, TextDirection.ltr);
      final rtl = _resolved(insets, TextDirection.rtl);

      expect(ltr.right, greaterThan(ltr.left));
      expect(rtl.left, greaterThan(rtl.right));
    });
  });

  group('a symmetric inset needs none of this', () {
    test('it resolves the same either way', () {
      // Why the sweep stopped at four defaults rather than every padding
      // in the kit: a value that is equal on both sides is already
      // direction-invariant, and converting it would add a flag that
      // changes nothing.
      const insets = CoreEdgeInsets.all(8);
      final geometry = insets.toGeometry();

      expect(
        _resolved(geometry, TextDirection.ltr),
        _resolved(geometry, TextDirection.rtl),
      );
    });
  });

  group('a directional value refuses the physical path', () {
    test('flattening throws instead of rendering wrongly', () {
      // A directional value silently flattened is correct in English and
      // wrong in Arabic with nothing to see in between — so the
      // conversion that cannot express it refuses rather than guessing.
      expect(
        () => CoreTextBlockStyle.defaultBlockQuotePadding.toValue(),
        throwsArgumentError,
      );
    });

    test('and a physical one still takes it', () {
      expect(const CoreEdgeInsets.all(8).toValue(), const EdgeInsets.all(8));
    });
  });
}
