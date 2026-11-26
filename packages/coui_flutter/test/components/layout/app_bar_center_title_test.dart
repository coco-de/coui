// A centred title sits on the centre of the whole bar — not on the space the
// clusters leave between them — in every material and single-row variant.
//
// Every test measures where the title is drawn. This is a placement rule, so
// a test that read the widget tree instead would pass against a bar that
// builds the right widgets and draws in the wrong place. The Web twin is a
// CSS grid; `tool/parity/test/web/app_bar_center_title_probe_test.dart`
// measures it in Chrome against the same rule.

import 'dart:math' as math;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const _leadingKey = Key('leading');
const _trailingKey = Key('trailing');
const _titleKey = Key('title');

// "back · title · two text actions" — the clusters of a header whose title
// the flex row centred between them, 40px off the bar's centre.
const _leadingWidth = 40.0;
const _trailingWidth = 120.0;

AppBar _bar({
  Widget? title,
  double titleWidth = 100,
  bool centerTitle = true,
  bool trailingExpanded = false,
  CoreAppBarVariant variant = .standard,
}) => AppBar(
  variant: variant,
  centerTitle: centerTitle,
  trailingExpanded: trailingExpanded,
  leading: const [
    SizedBox(key: _leadingKey, width: _leadingWidth, height: 24),
  ],
  trailing: const [
    SizedBox(key: _trailingKey, width: _trailingWidth, height: 24),
  ],
  title: title ?? SizedBox(key: _titleKey, width: titleWidth, height: 20),
);

/// Pumps [bar] and returns what its resolver answers, so the expectations
/// below derive from the spacing and insets the bar reads rather than from
/// numbers written here.
Future<ResolvedAppBar> _pump(
  WidgetTester tester,
  AppBar bar, {
  CoreSurfaceStyleId surfaceStyle = .defaultId,
  TextDirection textDirection = .ltr,
}) async {
  // The shell mounts its child through `Overlay.initialEntries`, which an
  // Overlay reads once — start from an empty tree so a second pump in the
  // same test renders the new bar.
  await tester.pumpWidget(const SizedBox());
  late ResolvedAppBar resolved;
  await pumpTestApp(
    tester,
    Builder(
      builder: (context) {
        resolved = resolveAppBar(context, variant: bar.variant);
        return bar;
      },
    ),
    surfaceStyle: surfaceStyle,
    textDirection: textDirection,
  );
  return resolved;
}

/// The bar's content box — the bar minus its own padding.
Rect _content(WidgetTester tester, ResolvedAppBar resolved) =>
    resolved.padding.deflateRect(tester.getRect(find.byType(AppBar)));

/// The room both platforms leave a centred title, in the content box: the
/// two sides are held at the wider cluster's width, so the room is
/// symmetric about the centre.
double _room({required double width, required double spacing}) =>
    width - 2 * math.max(_leadingWidth, _trailingWidth) - 2 * spacing;

void main() {
  group('a centred title sits on the whole bar', () {
    for (final surfaceStyle in [
      CoreSurfaceStyleId.defaultId,
      CoreSurfaceStyleId.liquidGlass,
    ]) {
      for (final variant in [
        CoreAppBarVariant.standard,
        CoreAppBarVariant.compact,
        CoreAppBarVariant.dense,
      ]) {
        testWidgets('${variant.name} · ${surfaceStyle.name}', (tester) async {
          final resolved = await _pump(
            tester,
            _bar(variant: variant),
            surfaceStyle: surfaceStyle,
          );
          final content = _content(tester, resolved);
          final title = tester.getRect(find.byKey(_titleKey));

          expect(
            title.center.dx,
            moreOrLessEquals(content.center.dx, epsilon: 0.01),
          );
          // Not the centre of the space between the clusters — the place the
          // flex row put it. The clusters are measured as laid out: glass
          // capsules are wider than the boxes they hold.
          Rect cluster(Key key) => tester.getRect(
            find.ancestor(of: find.byKey(key), matching: find.byType(LayoutId)),
          );
          final leading = cluster(_leadingKey);
          final trailing = cluster(_trailingKey);
          final between = (leading.right + trailing.left) / 2;
          expect(
            (title.center.dx - between).abs(),
            moreOrLessEquals(
              (trailing.width - leading.width) / 2,
              epsilon: 0.01,
            ),
          );
          expect(trailing.width - leading.width, greaterThan(40));
        });
      }
    }
  });

  testWidgets(
    'a title wider than the symmetric room stays centred and gives way',
    (tester) async {
      final probe = await _pump(tester, _bar());
      final width = _content(tester, probe).width;
      final pad = probe.titlePadding;
      final room = _room(width: width, spacing: probe.spacing);
      // 20px wider than the symmetric room: the old placement shifted it
      // toward the narrower cluster; now it is held to the room, centred.
      final resolved = await _pump(
        tester,
        _bar(titleWidth: room - pad.horizontal + 20),
      );
      final content = _content(tester, resolved);
      final title = tester.getRect(find.byKey(_titleKey));
      final trailing = tester.getRect(find.byKey(_trailingKey));

      expect(
        title.center.dx,
        moreOrLessEquals(content.center.dx, epsilon: 0.01),
      );
      expect(
        title.width + pad.horizontal,
        moreOrLessEquals(room, epsilon: 0.01),
      );
      // The wider cluster's gap is exactly the spacing; the narrower side
      // keeps more.
      expect(
        trailing.left - (title.right + pad.right),
        moreOrLessEquals(resolved.spacing, epsilon: 0.01),
      );
    },
  );

  testWidgets('a title that cannot fit gets the symmetric room and ends in '
      'an ellipsis', (tester) async {
    final resolved = await _pump(
      tester,
      _bar(title: Text('Title ' * 40, key: _titleKey)),
    );
    final content = _content(tester, resolved);
    final paragraph = tester.renderObject<RenderParagraph>(
      find.byKey(_titleKey),
    );
    final room =
        _room(width: content.width, spacing: resolved.spacing) -
        resolved.titlePadding.horizontal;

    expect(paragraph.didExceedMaxLines, isTrue);
    expect(paragraph.maxLines, 1);
    expect(paragraph.overflow, TextOverflow.ellipsis);
    expect(paragraph.size.width, moreOrLessEquals(room, epsilon: 0.01));
    expect(
      tester.getRect(find.byKey(_titleKey)).center.dx,
      moreOrLessEquals(content.center.dx, epsilon: 0.01),
    );
    // The clusters are not pushed.
    expect(
      tester.getRect(find.byKey(_leadingKey)).left,
      moreOrLessEquals(content.left, epsilon: 0.01),
    );
    expect(
      tester.getRect(find.byKey(_trailingKey)).right,
      moreOrLessEquals(content.right, epsilon: 0.01),
    );
  });

  testWidgets('a long title does not squeeze a cluster of words', (
    tester,
  ) async {
    const wordsKey = Key('words');
    AppBar words(String title) => AppBar(
      centerTitle: true,
      leading: const [
        SizedBox(key: _leadingKey, width: _leadingWidth, height: 24),
      ],
      trailing: const [Text('Search more actions', key: wordsKey)],
      title: Text(title, key: _titleKey),
    );

    await _pump(tester, words('Title'));
    final oneLine = tester.getRect(find.byKey(wordsKey));
    final resolved = await _pump(tester, words('Title ' * 40));
    final squeezed = tester.getRect(find.byKey(wordsKey));
    final content = _content(tester, resolved);

    // The cluster keeps its one-line width; the title gives way.
    expect(squeezed.width, moreOrLessEquals(oneLine.width, epsilon: 0.01));
    expect(squeezed.height, moreOrLessEquals(oneLine.height, epsilon: 0.01));
    expect(
      tester.renderObject<RenderParagraph>(find.byKey(_titleKey)).size.width,
      moreOrLessEquals(
        content.width -
            2 * math.max(_leadingWidth, squeezed.width) -
            2 * resolved.spacing -
            resolved.titlePadding.horizontal,
        epsilon: 0.01,
      ),
    );
  });

  testWidgets('right to left mirrors the clusters, not the centre', (
    tester,
  ) async {
    final resolved = await _pump(tester, _bar(), textDirection: .rtl);
    final content = _content(tester, resolved);

    expect(
      tester.getRect(find.byKey(_leadingKey)).right,
      moreOrLessEquals(content.right, epsilon: 0.01),
    );
    expect(
      tester.getRect(find.byKey(_trailingKey)).left,
      moreOrLessEquals(content.left, epsilon: 0.01),
    );
    expect(
      tester.getRect(find.byKey(_titleKey)).center.dx,
      moreOrLessEquals(content.center.dx, epsilon: 0.01),
    );
  });

  testWidgets('right to left holds a long title on the centre too', (
    tester,
  ) async {
    final probe = await _pump(tester, _bar(), textDirection: .rtl);
    final width = _content(tester, probe).width;
    final pad = probe.titlePadding;
    final room = _room(width: width, spacing: probe.spacing);

    final resolved = await _pump(
      tester,
      _bar(titleWidth: room - pad.horizontal + 20),
      textDirection: .rtl,
    );
    final content = _content(tester, resolved);
    final title = tester.getRect(find.byKey(_titleKey));
    final trailing = tester.getRect(find.byKey(_trailingKey));

    // The trailing cluster is on the left now; the title keeps the spacing
    // off it and stays on the centre — the mirror of left to right.
    expect(
      (title.left - pad.left) - trailing.right,
      moreOrLessEquals(resolved.spacing, epsilon: 0.01),
    );
    expect(
      title.center.dx,
      moreOrLessEquals(content.center.dx, epsilon: 0.01),
    );
  });

  group('the flex row stays where centring has no room', () {
    Future<void> expectStartPlaced(WidgetTester tester, AppBar bar) async {
      final resolved = await _pump(tester, bar);
      final content = _content(tester, resolved);

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(CustomMultiChildLayout),
        ),
        findsNothing,
      );
      expect(
        tester.getRect(find.byKey(_titleKey)).left,
        moreOrLessEquals(
          content.left +
              _leadingWidth +
              resolved.spacing +
              resolved.titlePadding.left,
          epsilon: 0.01,
        ),
      );
    }

    testWidgets('centerTitle: false', (tester) async {
      await expectStartPlaced(tester, _bar(centerTitle: false));
    });

    testWidgets('trailingExpanded — the trailing cluster takes the rest', (
      tester,
    ) async {
      await expectStartPlaced(tester, _bar(trailingExpanded: true));
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(Expanded),
        ),
        findsOneWidget,
      );
    });
  });
}
