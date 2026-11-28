import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/internal/preview/flutter_card_view.dart';
import 'package:docs_core/internal/preview/flutter_stage.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

final _observations = <Map<String, Object?>>[];
final _boundary = GlobalKey();

Future<void> _mount(
  WidgetTester tester, {
  String? tone,
  bool dark = false,
  double scale = 1,
  String? height,
  bool preview = true,
  CoreCardStyle? themeCardStyle,
  Map<String, String> extraAttributes = const {},
  void Function(String)? onInternalLink,
  Widget? child,
}) async {
  await tester.pumpWidget(
    CoUIApp(
      theme: ThemeData.fromCore(
        (dark ? CoreThemePresets.previewDark : CoreThemePresets.previewLight).copyWith(
          sizeScaling: scale,
          textScaling: 1,
          radiusScaling: 1,
        ),
        coreComponentTheme: CoreComponentTheme(card: CoreCardTheme(style: themeCardStyle)),
      ),
      scaling: const AdaptiveScaling(),
      enableThemeAnimation: false,
      home: Center(
        child: SizedBox(
          width: 400,
          child: RepaintBoundary(
            key: _boundary,
            child: Builder(
              builder: (context) =>
                  child ??
                  buildNativeDocsCardView(
                    context: context,
                    attributes: {
                      if (preview) 'component': 'button',
                      'label': 'Action',
                      'tone': ?tone,
                      'height': ?height,
                      'eyebrow': 'Eyebrow',
                      'title': 'Caption',
                      ...extraAttributes,
                    },
                    rawBody: 'Body',
                    nested: (value) => Text(value),
                    onInternalLink: onInternalLink,
                  ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(CoreCardStyle.defaultChromeAnimationDuration);
}

Future<Color> _pixel(WidgetTester tester, int x, int y) async {
  final value = await tester.runAsync(() async {
    final image = await (_boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
    final index = (y * image.width + x) * 4;
    final color = Color.fromARGB(bytes[index + 3], bytes[index], bytes[index + 1], bytes[index + 2]);
    image.dispose();
    return color;
  });
  return value!;
}

RenderDecoratedBox _decoration(WidgetTester tester, Finder owner, {bool outerBorder = false}) {
  final width = tester.getSize(owner).width;
  return tester
      .renderObjectList<RenderDecoratedBox>(find.descendant(of: owner, matching: find.byType(DecoratedBox)))
      .firstWhere((box) {
        final decoration = box.decoration;
        return decoration is BoxDecoration &&
            box.size.width == width &&
            (!outerBorder || decoration.border is Border && (decoration.border! as Border).top.width > 0);
      });
}

void main() {
  tearDownAll(() {
    final output = Platform.environment['COUI_DOCS_TONE_EVIDENCE'];
    if (output != null) {
      Directory(output).createSync(recursive: true);
      File('$output/observations.json').writeAsStringSync(const JsonEncoder.withIndent('  ').convert(_observations));
    }
  });
  for (final dark in [false, true]) {
    for (final tone in ['do', 'dont']) {
      testWidgets('authored $tone uses semantic Card/eyebrow/stage paint, dark=$dark', (tester) async {
        await _mount(tester, tone: tone, dark: dark);
        final theme = Theme.of(tester.element(find.byType(Card)));
        final card = _decoration(tester, find.byType(Card), outerBorder: true).decoration as BoxDecoration;
        final stage = _decoration(tester, find.byType(DocsStage)).decoration as BoxDecoration;
        final eyebrow = tester.renderObject<RenderParagraph>(find.text('Eyebrow')).text.style!.color;
        final cardBorder = (card.border! as Border).top.color;
        final bottom = (stage.border as Border?)?.bottom;
        Color color(CoreColorToken token) => theme.colorScheme.resolve(CoreColor.token(token)).toValue();
        final expectedBorder = color(tone == 'do' ? CoreColors.successContainer : CoreColors.errorContainer);
        final expectedEyebrow = color(tone == 'do' ? CoreColors.onSuccessContainer : CoreColors.onErrorContainer);
        final expectedBottom = color(tone == 'do' ? CoreColors.success : CoreColors.error);
        final stageRect = tester.getRect(find.byType(DocsStage));
        final button = tester.getRect(find.byType(Button));
        _observations.add({
          'tone': tone,
          'dark': dark,
          'cardBorder': cardBorder.toARGB32(),
          'eyebrow': eyebrow?.toARGB32(),
          'stageBottom': bottom?.color.toARGB32(),
          'stageStroke': bottom?.width,
          'expectedCardBorder': expectedBorder.toARGB32(),
          'expectedEyebrow': expectedEyebrow.toARGB32(),
          'expectedStageBottom': expectedBottom.toARGB32(),
          'stageHeight': stageRect.height,
          'childCenterFromStageTop': button.center.dy - stageRect.top,
        });
        expect(cardBorder, expectedBorder);
        expect(eyebrow, expectedEyebrow);
        expect(bottom?.color, expectedBottom);
        expect(bottom?.width, 2);
        expect(stageRect.height, 140);
        expect(button.center.dy - stageRect.center.dy, -1);
        final cardRect = tester.getRect(find.byType(Card));
        final bottomPixel = await _pixel(tester, 200, (stageRect.bottom - cardRect.top - 1).floor());
        final outerPixel = await _pixel(tester, 200, 0);
        expect(bottomPixel, expectedBottom);
        expect(outerPixel, expectedBorder);
        _observations.add({
          'case': 'actual-painted-pixels',
          'tone': tone,
          'dark': dark,
          'stageBottom': bottomPixel.toARGB32(),
          'outerTop': outerPixel.toARGB32(),
        });
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final scale in [1.0, 1.5]) {
    for (final height in [null, '240', 'hug']) {
      for (final tone in ['do', 'dont']) {
        testWidgets('$tone border deflates content within outer height=$height, scale=$scale', (tester) async {
          await _mount(tester, scale: scale, height: height);
          final neutral = tester.getRect(find.byType(DocsStage));
          final neutralChild = tester.getRect(find.byType(Button));
          final state = tester.state(find.byType(Button));
          await _mount(tester, tone: tone, scale: scale, height: height);
          final stage = tester.getRect(find.byType(DocsStage));
          final button = tester.getRect(find.byType(Button));
          final border = ((_decoration(tester, find.byType(DocsStage)).decoration as BoxDecoration).border! as Border);
          final stroke = 2 * scale;
          expect(border.bottom.width, stroke);
          expect(border.top.width, 0);
          expect(border.left.width, 0);
          expect(border.right.width, 0);
          expect(stage.width, neutral.width);
          expect(stage.height, height == 'hug' ? neutral.height + stroke : neutral.height);
          expect(
            stage.height,
            height == 'hug'
                ? button.height + 48 + stroke
                : height == '240'
                ? 240
                : 140,
          );
          expect(button.size, neutralChild.size);
          expect(button.center.dy - stage.center.dy, -stroke / 2);
          expect(button.center.dx, stage.center.dx);
          expect(identical(tester.state(find.byType(Button)), state), isTrue);
          _observations.add({
            'case': 'border-box',
            'tone': tone,
            'height': height,
            'scale': scale,
            'neutralStageHeight': neutral.height,
            'toneStageHeight': stage.height,
            'childHeight': button.height,
            'stroke': border.bottom.width,
            'centerDelta': button.center.dy - stage.center.dy,
          });
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('absent and unknown tones keep neutral paint and geometry', (tester) async {
    await _mount(tester);
    final card = tester.getRect(find.byType(Card));
    final stage = tester.getRect(find.byType(DocsStage));
    final border = (_decoration(tester, find.byType(Card), outerBorder: true).decoration as BoxDecoration).border;
    final eyebrow = tester.renderObject<RenderParagraph>(find.text('Eyebrow')).text;
    for (final unknown in ['other', 'DO', 'dont ']) {
      await _mount(tester, tone: unknown);
      expect(tester.getRect(find.byType(Card)), card);
      expect(tester.getRect(find.byType(DocsStage)), stage);
      expect((_decoration(tester, find.byType(Card), outerBorder: true).decoration as BoxDecoration).border, border);
      expect((_decoration(tester, find.byType(DocsStage)).decoration as BoxDecoration).border, isNull);
      expect(tester.renderObject<RenderParagraph>(find.text('Eyebrow')).text, eyebrow);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('live tone and theme changes preserve preview State, Element and keyboard focus', (tester) async {
    await _mount(tester);
    final state = tester.state(find.byType(Button));
    final element = tester.element(find.byType(Button));
    final render = tester.renderObject(find.byType(Button));
    final focus = Focus.of(tester.element(find.text('Action')));
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isTrue);
    for (final (tone, dark) in [(null, false), ('do', false), ('dont', true), ('other', true), (null, false)]) {
      await _mount(tester, tone: tone, dark: dark);
      expect(identical(tester.state(find.byType(Button)), state), isTrue);
      expect(identical(tester.element(find.byType(Button)), element), isTrue);
      expect(identical(tester.renderObject(find.byType(Button)), render), isTrue);
      expect(focus.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    }
    _observations.add({'case': 'live-lifetime', 'transitions': 5, 'stateElementRenderFocusPreserved': true});
  });

  for (final dark in [false, true]) {
    for (final tone in ['do', 'dont']) {
      testWidgets('nonpreview $tone tints the eyebrow, keeps a neutral border and the link, dark=$dark', (
        tester,
      ) async {
        final links = <String>[];
        await _mount(
          tester,
          tone: tone,
          dark: dark,
          preview: false,
          extraAttributes: const {'href': '/target', 'more': 'Read'},
          onInternalLink: links.add,
        );
        expect(find.byType(DocsStage), findsNothing);
        final card = tester.getRect(find.byType(Card));
        final eyebrow = tester.getRect(find.text('Eyebrow'));
        // 면 카드 — 테두리 1 + 안쪽 여백 24.
        expect(eyebrow.left - card.left, 25);
        expect(eyebrow.top - card.top, 25);
        final theme = Theme.of(tester.element(find.byType(Card)));
        Color color(CoreColorToken token) => theme.colorScheme.resolve(CoreColor.token(token)).toValue();
        // 문서 페이지의 카드는 이름표가 종류를 거든다 — 테두리는 다른 카드와 같다
        // (사이트의 `.docs-card--do:not(.docs-card--preview)`).
        expect(
          ((_decoration(tester, find.byType(Card), outerBorder: true).decoration as BoxDecoration).border! as Border)
              .top
              .color,
          color(CoreColors.outlineSubtle),
        );
        expect(
          tester.renderObject<RenderParagraph>(find.text('Eyebrow')).text.style!.color,
          color(tone == 'do' ? CoreColors.success : CoreColors.error),
        );
        // 링크는 밑줄 글자다 — 화살표가 없다.
        expect(find.text('Read →'), findsNothing);
        await tester.tap(find.text('Read'));
        await tester.pump();
        expect(links, ['/target']);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final scale in [1.0, 1.5]) {
    testWidgets('semantic instance border preserves themed width/padding, scale=$scale', (tester) async {
      const style = CoreCardStyle(
        borderColor: CoreColor(0xff7a33aa),
        borderWidth: 2,
        padding: CoreEdgeInsets.only(left: 12, right: 18, top: 10, bottom: 14),
      );
      await _mount(tester, scale: scale, themeCardStyle: style);
      final neutral =
          (_decoration(tester, find.byType(Card), outerBorder: true).decoration as BoxDecoration).border! as Border;
      expect(neutral.top.color, const Color(0xff7a33aa));
      for (final tone in ['do', 'dont']) {
        await _mount(tester, tone: tone, scale: scale, themeCardStyle: style);
        final theme = Theme.of(tester.element(find.byType(Card)));
        final border =
            (_decoration(tester, find.byType(Card), outerBorder: true).decoration as BoxDecoration).border! as Border;
        expect(
          border.top.color,
          theme.colorScheme
              .resolve(CoreColor.token(tone == 'do' ? CoreColors.successContainer : CoreColors.errorContainer))
              .toValue(),
        );
        expect(border.top.width, 2 * scale);
        final card = tester.getRect(find.byType(Card));
        final stage = tester.getRect(find.byType(DocsStage));
        final eyebrow = tester.getRect(find.text('Eyebrow'));
        final body = tester.getRect(find.text('Body'));
        expect(eyebrow.left - stage.left, 12 * scale);
        expect(eyebrow.top - stage.bottom, 10 * scale);
        expect(card.bottom - body.bottom, 16 * scale);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('ordinary standalone Preview ignores Card tone', (tester) async {
    await _mount(tester, child: const DocsStage(attributes: {'component': 'button'}));
    final neutral = tester.getRect(find.byType(DocsStage));
    for (final tone in ['do', 'dont']) {
      await _mount(tester, child: DocsStage(attributes: {'component': 'button', 'tone': tone}));
      final stage = tester.getRect(find.byType(DocsStage));
      final button = tester.getRect(find.byType(Button));
      expect((_decoration(tester, find.byType(DocsStage)).decoration as BoxDecoration).border, isNull);
      // Standalone Center receives the host's bounded height; compare its
      // existing neutral geometry instead of treating min-height as a height.
      expect(stage.size, neutral.size);
      expect(button.center.dy, stage.center.dy);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('tone media without captions still omits the padded body', (tester) async {
    for (final tone in ['do', 'dont']) {
      await _mount(
        tester,
        child: Builder(
          builder: (context) => buildNativeDocsCardView(
            context: context,
            attributes: {'component': 'button', 'tone': tone},
            rawBody: '  ',
            nested: (_) => throw StateError('empty body must not render'),
            onInternalLink: null,
          ),
        ),
      );
      final card = tester.getRect(find.byType(Card));
      final stage = tester.getRect(find.byType(DocsStage));
      expect(tester.widget<Card>(find.byType(Card)).body, isNull);
      expect(card.height, stage.height + 2);
      expect(stage.height, 140);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('nonpreview shapes follow the site — filled by default, the group variant, a card override', (
    tester,
  ) async {
    Future<(Rect, Rect, BoxDecoration)> mountShape({String? group, String? own, String? value}) async {
      await _mount(
        tester,
        child: Builder(
          builder: (context) => buildNativeDocsCardView(
            context: context,
            attributes: {'eyebrow': 'Eyebrow', 'title': 'Caption', 'variant': ?own, 'value': ?value},
            rawBody: 'Body',
            nested: (value) => Text(value),
            onInternalLink: null,
            variant: group,
          ),
        ),
      );
      final decoration = _decoration(tester, find.byType(Card), outerBorder: true).decoration as BoxDecoration;
      return (tester.getRect(find.byType(Card)), tester.getRect(find.text('Eyebrow')), decoration);
    }

    final (filledCard, filledEyebrow, filled) = await mountShape();
    final theme = Theme.of(tester.element(find.byType(Card)));
    Color color(CoreColorToken token) => theme.colorScheme.resolve(CoreColor.token(token)).toValue();
    expect(filled.borderRadius, BorderRadius.circular(CoreRadius.radius20));
    expect(filled.color, color(CoreColors.surfaceContainer));
    expect(filledEyebrow.left - filledCard.left, 25);
    expect(tester.widget<Card>(find.byType(Card)).variant, CoreCardVariant.filled);

    final (outlinedCard, outlinedEyebrow, outlined) = await mountShape(group: 'outlined');
    expect(outlined.borderRadius, BorderRadius.circular(CoreRadiusRole.panel));
    expect(outlinedEyebrow.left - outlinedCard.left, 21);
    expect(tester.widget<Card>(find.byType(Card)).variant, CoreCardVariant.outlined);

    await mountShape(group: 'outlined', own: 'filled');
    expect(tester.widget<Card>(find.byType(Card)).variant, CoreCardVariant.filled);

    await mountShape(group: 'outline');
    expect(tester.widget<Card>(find.byType(Card)).variant, CoreCardVariant.filled);

    await mountShape(group: 'outlined', value: '34');
    expect(find.text('34'), findsOneWidget);
    expect(tester.getRect(find.text('34')).top, lessThan(tester.getRect(find.text('Caption')).top));
    expect(tester.takeException(), isNull);
  });
}
