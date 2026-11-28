import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/internal/preview/flutter_card_view.dart';
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

final _boundary = GlobalKey();

Future<void> _mount(
  WidgetTester tester, {
  required bool dark,
  CoreCardTheme? cardTheme,
  bool standalone = false,
  bool originalScene = false,
  String component = 'button',
}) async {
  final scene = originalScene
      ? readDocsScenes('button').firstWhere((scene) => scene.tag == 'Card' && !scene.attributes.containsKey('tone'))
      : null;
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(
        (dark ? CoreThemePresets.previewDark : CoreThemePresets.previewLight).copyWith(
          sizeScaling: 1,
          textScaling: 1,
          radiusScaling: 1,
        ),
        coreComponentTheme: CoreComponentTheme(card: cardTheme),
      ),
      scaling: const AdaptiveScaling(),
      enableThemeAnimation: false,
      home: Center(
        child: SizedBox(
          width: 400,
          child: RepaintBoundary(
            key: _boundary,
            child: standalone
                ? const Card(variant: CoreCardVariant.outlined, child: Text('Kit content'))
                : scene != null
                ? buildFlutterDocsCardScene(scene.nativeCardAttributes!, scene.nativeCardBody!)
                : FlutterDocsCardView(
                    attributes: {
                      'component': component,
                      if (component == 'card') 'example': 'default',
                      'label': 'Action',
                      'title': 'Caption',
                    },
                    rawBody: 'Body',
                  ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(CoreCardStyle.defaultChromeAnimationDuration);
}

Border _paintedBorder(WidgetTester tester, {Finder? card, bool visible = true}) {
  final owner = card ?? find.byType(Card);
  expect(owner, findsOneWidget);
  final size = tester.getSize(owner);
  final boxes = tester
      .renderObjectList<RenderDecoratedBox>(find.descendant(of: owner, matching: find.byType(DecoratedBox)))
      .where((box) {
        final decoration = box.decoration;
        return box.size == size &&
            decoration is BoxDecoration &&
            decoration.border is Border &&
            ((decoration.border! as Border).top.width > 0) == visible;
      })
      .toList();
  expect(boxes, hasLength(1));
  return (boxes.single.decoration as BoxDecoration).border! as Border;
}

Color _color(WidgetTester tester, CoreColorToken token) =>
    Theme.of(tester.element(find.byType(Card).first)).colorScheme.resolve(CoreColor.token(token)).toValue();

Future<Color> _borderPixel(WidgetTester tester) async {
  final pixel = await tester.runAsync(() async {
    final image = await (_boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
    // The middle of the straight left edge, below the rounded top corner.
    final index = 20 * image.width * 4;
    final result = Color.fromARGB(data[index + 3], data[index], data[index + 1], data[index + 2]);
    image.dispose();
    return result;
  });
  return pixel!;
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('no-tone documentation Card paints the site line, dark=$dark', (tester) async {
      await _mount(tester, dark: dark, originalScene: true);
      final expected = _color(tester, CoreColors.outlineSubtle);
      // Verify actual frame paint as well as the rendered decoration.
      expect(await _borderPixel(tester), expected);
      final border = _paintedBorder(tester);
      for (final side in [border.top, border.right, border.bottom, border.left]) {
        expect(side.color, expected);
        expect(side.width, 1);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('documentation Card preserves an explicit base theme color, dark=$dark', (tester) async {
      const color = Color(0xff7a33aa);
      await _mount(
        tester,
        dark: dark,
        cardTheme: const CoreCardTheme(style: CoreCardStyle(borderColor: CoreColor(0xff7a33aa))),
      );
      expect(_paintedBorder(tester).top.color, color);
      expect(await _borderPixel(tester), color);
      expect(tester.takeException(), isNull);
    });

    testWidgets('documentation Card preserves outlined theme precedence, dark=$dark', (tester) async {
      await _mount(
        tester,
        dark: dark,
        cardTheme: const CoreCardTheme(
          style: CoreCardStyle(borderColor: CoreColor(0xff7a33aa)),
          variantStyles: {CoreCardVariant.outlined: CoreCardStyle(borderColor: CoreColor(0xff227755))},
        ),
      );
      expect(_paintedBorder(tester).top.color, const Color(0xff227755));
      expect(tester.takeException(), isNull);
    });

    testWidgets('explicit kit-default color remains an override in documentation, dark=$dark', (tester) async {
      await _mount(
        tester,
        dark: dark,
        cardTheme: const CoreCardTheme(
          variantStyles: {
            CoreCardVariant.outlined: CoreCardStyle(borderColor: CoreColor.token(CoreColors.outlineVariant)),
          },
        ),
      );
      // Presence of an override matters, even when its color equals the kit default.
      expect(_paintedBorder(tester).top.color, _color(tester, CoreColors.outlineVariant));
      expect(tester.takeException(), isNull);
    });

    testWidgets('documentation Card preserves an explicitly transparent border, dark=$dark', (tester) async {
      await _mount(
        tester,
        dark: dark,
        cardTheme: const CoreCardTheme(style: CoreCardStyle(borderColor: CoreColor.transparent)),
      );
      final border = _paintedBorder(tester, visible: false);
      expect(border.top.color, const Color(0x00000000));
      expect(border.top.width, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('documentation fallback preserves theme width and padding, dark=$dark', (tester) async {
      await _mount(
        tester,
        dark: dark,
        cardTheme: const CoreCardTheme(
          style: CoreCardStyle(
            borderWidth: 2,
            padding: CoreEdgeInsets.only(left: 12, right: 18, top: 10, bottom: 14),
          ),
        ),
      );
      final border = _paintedBorder(tester);
      expect(border.top.color, _color(tester, CoreColors.outlineSubtle));
      expect(border.top.width, 2);
      final card = tester.getRect(find.byType(Card));
      expect(tester.getRect(find.text('Caption')).left - card.left, 14);
      expect(tester.takeException(), isNull);
    });

    testWidgets('documentation fallback stays outside the original Card preview theme, dark=$dark', (tester) async {
      const cardTheme = CoreCardTheme(style: CoreCardStyle(borderWidth: 2));
      await _mount(tester, dark: dark, cardTheme: cardTheme, component: 'card');
      final cards = find.byType(Card);
      expect(cards, findsNWidgets(2));
      expect(_paintedBorder(tester, card: cards.first).top.color, _color(tester, CoreColors.outlineSubtle));
      final preview = tester.widget<Card>(cards.last);
      expect(preview.variant, CoreCardVariant.filled);
      expect(preview.cardStyle, isNull);
      expect(Theme.of(tester.element(cards.last)).coreComponentTheme?.card, same(cardTheme));
      // The original filled preview retains its transparent, collapsed border;
      // the documentation frame fallback must not become an inherited style.
      final previewBorder = _paintedBorder(tester, card: cards.last, visible: false);
      expect(previewBorder.top.color, const Color(0x00000000));
      expect(previewBorder.top.width, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('standalone kit outlined Card keeps its existing default, dark=$dark', (tester) async {
      await _mount(tester, dark: dark, standalone: true);
      final expected = _color(tester, CoreColors.outlineVariant);
      expect(_paintedBorder(tester).top.color, expected);
      if (!dark) {
        expect(expected, isNot(_color(tester, CoreColors.outlineSubtle)));
      }
      expect(await _borderPixel(tester), expected);
      expect(tester.takeException(), isNull);
    });
  }
}
