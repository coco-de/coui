// Banner's message line, the trailing group's wrap, and the two colours the
// redesign moved — read off the rendered tree, never off the constants.
//
// The wrap is a layout promise that only holds in pixels: the trailing group
// (action + dismiss) stays beside the message column while the column keeps
// `contentMinWidth`, and otherwise drops to its own line `trailingRunSpacing`
// below, starting where the message TEXT starts — after the icon, not under
// it. Each half can break without the other: a layout that always wraps
// still puts the trailing group at the text's start, and one that never
// wraps keeps the wide layout perfect.
//
// Only the coui barrel is imported: `package:flutter/widgets.dart` would
// bring back Flutter's own `Banner`.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

const _kMessage = 'Your trial ends in three days.';
const _kDescription = 'Upgrade to keep your projects.';
const _kActionKey = Key('banner-action');

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  CoreBannerVariant variant = CoreBannerVariant.info,
  CoreBannerEmphasis emphasis = CoreBannerEmphasis.weak,
  bool withAction = true,
}) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: Banner(
            message: const Text(_kMessage),
            description: const Text(_kDescription),
            variant: variant,
            emphasis: emphasis,
            onDismiss: () {},
            action: withAction
                ? Button(
                    key: _kActionKey,
                    variant: .outline,
                    size: .sm,
                    onPressed: () {},
                    child: const Text('Upgrade'),
                  )
                : null,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Rect _rect(WidgetTester tester, Finder finder) => tester.getRect(finder);

Finder get _message => find.text(_kMessage);
Finder get _description => find.text(_kDescription);

/// The leading variant icon — the banner's first `Icon`.
Finder get _variantIcon =>
    find.descendant(of: find.byType(Banner), matching: find.byType(Icon)).first;

/// The dismiss button — the banner's last `Button`.
Finder get _dismissButton => find.byType(Button).last;

/// The message column — the `Column` holding the message and description.
Finder get _column =>
    find.ancestor(of: _message, matching: find.byType(Column)).first;

/// The trailing group's own box — the `Row` holding the action and dismiss.
Finder get _trailing => find
    .ancestor(of: find.byKey(_kActionKey), matching: find.byType(Row))
    .first;

TextStyle _paintedStyle(WidgetTester tester, Finder text) => tester
    .renderObject<RenderParagraph>(
      find.descendant(of: text, matching: find.byType(RichText)),
    )
    .text
    .style!;

/// True when the trailing group shares the message column's line.
bool _oneLine(WidgetTester tester) =>
    _rect(tester, _trailing).top < _rect(tester, _column).bottom;

void main() {
  group('Banner message', () {
    testWidgets("the title paints at labelLarge's own medium weight", (
      tester,
    ) async {
      await _pump(tester, width: 600);
      expect(_paintedStyle(tester, _message).fontWeight, FontWeight.w500);
    });

    for (final variant in CoreBannerVariant.values) {
      testWidgets('weak $variant description is onSurfaceVariant', (
        tester,
      ) async {
        await _pump(tester, width: 600, variant: variant);
        final scheme = Theme.of(tester.element(_message)).colorScheme;
        final expected = scheme
            .resolve(const CoreColor.token(CoreColors.onSurfaceVariant))
            .toValue();
        expect(_paintedStyle(tester, _description).color, expected);
      });
    }
  });

  group('Banner trailing wrap', () {
    testWidgets('at a wide width the trailing group shares the line', (
      tester,
    ) async {
      await _pump(tester, width: 600);
      expect(_oneLine(tester), isTrue);
      final column = _rect(tester, _column);
      final trailing = _rect(tester, _trailing);
      // Centre cross-alignment, as the former single Row placed them.
      expect(trailing.center.dy, moreOrLessEquals(column.center.dy));
      // The one-line gap is the action's leading gap (12), not the wrap's.
      expect(trailing.left - column.right, moreOrLessEquals(12));
    });

    testWidgets('at 320 the trailing group wraps under the message text', (
      tester,
    ) async {
      await _pump(tester, width: 320);
      expect(_oneLine(tester), isFalse);
      final column = _rect(tester, _column);
      final trailing = _rect(tester, _trailing);
      final textLeft = _rect(tester, _message).left;
      // Starts where the message text starts — after the icon, not under it.
      expect(trailing.left, moreOrLessEquals(textLeft));
      expect(
        _rect(tester, find.byKey(_kActionKey)).left,
        moreOrLessEquals(
          textLeft,
        ),
      );
      // `trailingRunSpacing` (8) between the column and the wrapped line.
      expect(trailing.top - column.bottom, moreOrLessEquals(8));
      // The column takes the full width beside the icon once alone.
      expect(column.right, greaterThan(trailing.right));
    });

    testWidgets('wrapped, the icon centres on the message block', (
      tester,
    ) async {
      await _pump(tester, width: 320);
      expect(_oneLine(tester), isFalse);
      final icon = _rect(tester, _variantIcon);
      final column = _rect(tester, _column);
      expect(icon.center.dy, moreOrLessEquals(column.center.dy));
      // And it still sits before the text by the icon gap (12).
      expect(_rect(tester, _message).left - icon.right, moreOrLessEquals(12));
    });

    testWidgets('on one line, the icon centres on the row', (tester) async {
      await _pump(tester, width: 600);
      final icon = _rect(tester, _variantIcon);
      expect(
        icon.center.dy,
        moreOrLessEquals(_rect(tester, _column).center.dy),
      );
      expect(
        icon.center.dy,
        moreOrLessEquals(_rect(tester, _trailing).center.dy),
      );
    });

    testWidgets('a dismiss-only banner keeps the dismiss gap on one line', (
      tester,
    ) async {
      await _pump(tester, width: 600, withAction: false);
      final column = _rect(tester, _column);
      final dismiss = _rect(
        tester,
        _dismissButton,
      );
      expect(dismiss.left - column.right, moreOrLessEquals(8));
    });

    testWidgets('the column is never narrower than 240 while on one line', (
      tester,
    ) async {
      var sawOneLine = false;
      var sawWrapped = false;
      for (var width = 280.0; width <= 560; width += 4) {
        await _pump(tester, width: width);
        if (_oneLine(tester)) {
          sawOneLine = true;
          expect(
            _rect(tester, _column).width,
            greaterThanOrEqualTo(240),
            reason: 'one line at $width',
          );
        } else {
          sawWrapped = true;
        }
      }
      // Both poses were actually reached, so the loop measured something.
      expect(sawOneLine, isTrue);
      expect(sawWrapped, isTrue);
    });
  });
}
