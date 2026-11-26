// The height floor both surfaces gained, and what it is actually worth.
//
// The promise is a pairing: a `minHeight` floor and a centre cross-axis
// alignment. Either alone looks right in the case you happen to have open
// and wrong in the other — the floor without the centring gives a
// description-less band its height and then pins the content to the top of
// it; the centring without the floor lets the band collapse around a single
// line. Removing either is silent: nothing throws, nothing misrenders in
// isolation, and a row of banners just stops lining up on the one page
// where some have a description and some do not.
//
// What this file does NOT claim is that every banner is exactly 72 tall.
// The floor is a floor. At this kit's own text metrics a two-line band
// comes out a shade over it, so a test demanding equality there would be
// asserting a number that only holds at one width and one text scale — and
// the way to make it pass would be to clip real content, which is worse
// than the misalignment the floor set out to fix.
//
// Only the coui barrel is imported: pulling in `package:flutter/widgets.dart`
// as well re-introduces Flutter's own `Banner`, which that barrel hides
// precisely so this name can be the kit's.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// The rendered height of [child], plus the scaling the theme applied.
///
/// The scaling is read back rather than assumed: the floor is a token in
/// logical px and the resolver multiplies it by `theme.scaling`, so a test
/// that hardcoded the token value would be asserting the default platform
/// density rather than the invariant.
Future<({double height, double scaling})> _measure(
  WidgetTester tester,
  Widget child, {
  double width = 600,
}) async {
  late double scaling;
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Center(
        child: SizedBox(
          width: width,
          child: Builder(
            builder: (context) {
              scaling = Theme.of(context).scaling;
              return child;
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (
    height: tester.getSize(find.byWidget(child)).height,
    scaling: scaling,
  );
}

void main() {
  group('the floor holds when the content is short', () {
    testWidgets('banner with no description sits exactly on its floor', (
      tester,
    ) async {
      // The regression this exists for: drop `minHeight` and this collapses
      // to one line of text plus padding.
      final m = await _measure(tester, const Banner(message: Text('Message')));
      expect(m.height, CoreBannerStyle.defaultMinHeight * m.scaling);
    });

    testWidgets('alert with no description sits exactly on its floor', (
      tester,
    ) async {
      // Drop `minHeight` and this collapses to the title line plus padding
      // (about 44), short of the 64 a two-line alert measures — "about
      // right" rather than visibly broken, which is exactly why it needs
      // measuring rather than looking at.
      final m = await _measure(tester, const Alert(title: 'Title'));
      expect(m.height, CoreAlertStyle.defaultMinHeight * m.scaling);
    });

    testWidgets('both banner emphases land on the same height', (tester) async {
      // `weak` draws a bottom rule and `solid` does not. Drawn outside the
      // box that rule makes `weak` exactly one stroke taller — a difference
      // nobody notices until two banners sit adjacent, and one this repo
      // has already been bitten by on the CSS side of the same component.
      final weak = await _measure(
        tester,
        const Banner(
          message: Text('Message'),
          emphasis: CoreBannerEmphasis.weak,
        ),
      );
      final solid = await _measure(
        tester,
        const Banner(
          message: Text('Message'),
          emphasis: CoreBannerEmphasis.solid,
        ),
      );
      expect(
        weak.height,
        solid.height,
        reason: 'the bottom rule must not add to the outer height',
      );
    });
  });

  group('the floor is a minimum, not a fixed height', () {
    testWidgets('a wrapping description grows the alert', (tester) async {
      final m = await _measure(
        tester,
        const Alert(
          title: 'Title',
          description:
              'A description long enough to wrap onto several lines at this '
              'width, which the card has to grow to contain rather than clip '
              'away in the name of a tidy row.',
        ),
        width: 320,
      );
      expect(
        m.height,
        greaterThan(CoreAlertStyle.defaultMinHeight * m.scaling),
      );
    });

    testWidgets('a wrapping description grows the banner', (tester) async {
      final m = await _measure(
        tester,
        const Banner(
          message: Text('Message'),
          description: Text(
            'A description long enough to wrap onto several lines at this '
            'width, which the band has to grow to contain rather than clip.',
          ),
        ),
        width: 320,
      );
      expect(
        m.height,
        greaterThan(CoreBannerStyle.defaultMinHeight * m.scaling),
      );
    });
  });

  group('the inline strip has no floor', () {
    // The other side of the pairing above: the inline layout states no
    // floor, so a strip is exactly as tall as its content — 10 above, 10
    // below, and whatever the tallest of glyph, title and leading is in
    // between. Keeping the stacked 64 here would hold every status strip
    // open to a panel's height, which is what the layout exists to avoid.
    final inline = CoreAlertStyle.defaultsByLayout[CoreAlertLayout.inline]!;
    final vertical = inline.padding!.top + inline.padding!.bottom;

    testWidgets('title alone — the title line plus its padding', (
      tester,
    ) async {
      final m = await _measure(
        tester,
        const Alert(layout: CoreAlertLayout.inline, title: 'Synced'),
      );
      final line = tester.getSize(find.text('Synced')).height;

      expect(m.height, moreOrLessEquals(line + vertical * m.scaling));
      expect(m.height, lessThan(CoreAlertStyle.defaultMinHeight * m.scaling));
    });

    testWidgets('with an md badge as leading — 10 + 24 + 10 = 44', (
      tester,
    ) async {
      final m = await _measure(
        tester,
        const Alert(
          layout: CoreAlertLayout.inline,
          leading: Badge(
            tone: CoreBadgeTone.success,
            showDot: true,
            child: Text('Done'),
          ),
          title: 'All changes saved',
        ),
      );
      final badge = tester.getSize(find.byType(Badge)).height;

      // The badge is the tallest thing in the row, so it sets the height.
      expect(m.height, moreOrLessEquals(badge + vertical * m.scaling));
      expect(m.height, moreOrLessEquals(44 * m.scaling));
    });

    testWidgets('a description does not add a second line', (tester) async {
      final withDescription = await _measure(
        tester,
        const Alert(
          layout: CoreAlertLayout.inline,
          title: 'Synced',
          description: 'This line is not drawn inline.',
        ),
      );
      final without = await _measure(
        tester,
        const Alert(layout: CoreAlertLayout.inline, title: 'Synced'),
      );

      expect(withDescription.height, without.height);
    });
  });

  group("the glyph sits on the row's middle", () {
    // The pairing this file already guards is floor + centring. This is the
    // third leg: which point inside that box the leading glyph lands on.
    //
    // It is worth its own measurement because the wrong answer is not a
    // crash or a clipped layout — it is a glyph riding the title line while
    // the description hangs below it, which looks like a layout choice
    // rather than a bug. The row is centred, so the glyph, the text block,
    // the action and the dismiss mark all share its middle.
    Future<({double glyph, double title, double box})> measure(
      WidgetTester tester,
      Widget alert,
    ) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: Center(child: SizedBox(width: 420, child: alert)),
        ),
      );
      await tester.pumpAndSettle();
      final iconRect = tester.getRect(find.byType(Icon).first);
      final titleRect = tester.getRect(find.text('Alert title'));
      final boxRect = tester.getRect(find.byType(Alert));
      return (
        glyph: iconRect.center.dy,
        title: titleRect.center.dy,
        box: boxRect.center.dy,
      );
    }

    testWidgets('with a description, at the middle — not on the title', (
      tester,
    ) async {
      final m = await measure(
        tester,
        const Alert(
          title: 'Alert title',
          description: 'This is an alert description.',
        ),
      );
      expect(m.glyph, moreOrLessEquals(m.box, epsilon: 0.5));
      // And demonstrably NOT the title line — otherwise this test would
      // still pass with the alignment reverted, since the two coincide
      // whenever there is only one line.
      expect((m.glyph - m.title).abs(), greaterThan(2));
    });

    testWidgets('title alone — glyph, title and box all agree', (tester) async {
      final m = await measure(tester, const Alert(title: 'Alert title'));
      expect(m.glyph, moreOrLessEquals(m.title, epsilon: 0.5));
      expect(m.glyph, moreOrLessEquals(m.box, epsilon: 0.5));
    });
  });

  group('the dismiss mark shares that middle', () {
    // Found by looking at the two platforms side by side, not by a test:
    // each had once placed its dismiss on a different line. Both looked
    // plausible alone.
    //
    // Asserting it against the BOX rather than against the leading glyph
    // matters — the two affordances could drift together and still be
    // wrong, and it is the row's middle they are supposed to share.
    testWidgets('with a description', (tester) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: Center(
            child: SizedBox(
              width: 420,
              child: Alert(
                title: 'Alert title',
                description: 'This is an alert description.',
                onDismiss: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final title = tester.getRect(find.text('Alert title')).center.dy;
      final mark = tester.getRect(find.byType(Icon).last).center.dy;
      final box = tester.getRect(find.byType(Alert)).center.dy;

      expect(mark, moreOrLessEquals(box, epsilon: 0.5));
      // And not the title line — with a description the two differ, which
      // is what makes this assertion say something.
      expect((mark - title).abs(), greaterThan(2));
    });

    testWidgets('title alone — everything on one line', (tester) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: Center(
            child: SizedBox(
              width: 420,
              child: Alert(title: 'Alert title', onDismiss: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final title = tester.getRect(find.text('Alert title')).center.dy;
      final glyph = tester.getRect(find.byType(Icon).first).center.dy;
      final mark = tester.getRect(find.byType(Icon).last).center.dy;
      final box = tester.getRect(find.byType(Alert)).center.dy;

      for (final v in [glyph, mark, box]) {
        expect(v, moreOrLessEquals(title, epsilon: 0.5));
      }
    });
  });
}
