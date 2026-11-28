import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/internal/preview/flutter_card_view.dart';
import 'package:docs_core/internal/preview/flutter_stage.dart';
import 'package:docs_core/internal/preview/native_paragraph_body.dart';
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _bodyKey = ValueKey('docs-card-body');
final _observations = <Map<String, Object?>>[];

Widget _card({
  Map<String, String> attributes = const {'component': 'button', 'title': 'Caption'},
  String? body,
  void Function(String)? onInternalLink,
}) => Builder(
  builder: (context) => buildNativeDocsCardView(
    context: context,
    attributes: attributes,
    rawBody: body,
    nested: (markdown) => SizedBox(key: _bodyKey, width: 52, height: 18, child: Text(markdown)),
    onInternalLink: onInternalLink,
  ),
);

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  double width = 400,
  double scale = 1,
  bool dark = false,
  CoreCardStyle? cardStyle,
}) => tester.pumpWidget(
  CoUIApp(
    theme: ThemeData.fromCore(
      (dark ? CoreThemePresets.previewDark : CoreThemePresets.previewLight).copyWith(
        sizeScaling: scale,
        textScaling: 1,
        radiusScaling: 1,
      ),
      coreComponentTheme: CoreComponentTheme(card: CoreCardTheme(style: cardStyle)),
    ),
    scaling: const AdaptiveScaling(),
    enableThemeAnimation: false,
    home: Center(
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(child: child),
      ),
    ),
  ),
);

List<double> _box(Rect value) => [value.left, value.top, value.width, value.height];

void main() {
  tearDownAll(() {
    final directory = Platform.environment['COUI_DOCS_CARD_EVIDENCE'];
    if (directory != null) {
      Directory(directory).createSync(recursive: true);
      File('$directory/observations.json').writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(_observations),
      );
    }
  });

  testWidgets('preview occupies the media edge and preserves caption padding', (tester) async {
    await _mount(tester, _card(body: 'Body'));
    final card = tester.getRect(find.byType(Card));
    final stage = tester.getRect(find.byType(DocsStage));
    final caption = tester.getRect(find.text('Caption'));
    final body = tester.getRect(find.byKey(_bodyKey));
    final clips = tester.widgetList<ClipPath>(
      find.descendant(
        of: find.byType(Card),
        matching: find.ancestor(of: find.byType(DocsStage), matching: find.byType(ClipPath)),
      ),
    );
    _observations.add({
      'case': 'preview',
      'card': _box(card),
      'stage': _box(stage),
      'caption': _box(caption),
      'body': _box(body),
      'clipModes': clips.map((clip) => clip.clipBehavior.name).toList(),
    });
    // Outlined Card owns a 1px border. Media has no content padding.
    expect(stage.left - card.left, 1);
    expect(stage.top - card.top, 1);
    expect(card.right - stage.right, 1);
    // The caption still uses Card's existing 24H/20V content padding.
    expect(caption.left - card.left, 25);
    expect(caption.top - stage.bottom, 20);
    expect(card.bottom - body.bottom, 21);
    expect(clips.any((clip) => clip.clipBehavior == Clip.antiAlias), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview without a caption has no empty padded content', (tester) async {
    await _mount(tester, _card(attributes: const {'component': 'button'}, body: '  '));
    final card = tester.getRect(find.byType(Card));
    final stage = tester.getRect(find.byType(DocsStage));
    _observations.add({'case': 'empty-caption', 'card': _box(card), 'stage': _box(stage)});
    expect(card.height, stage.height + 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-preview keeps its padded custom-child layout — filled 24, outlined 20', (tester) async {
    // 면 카드(기본) — 테두리 1 + 안쪽 여백 24(사이트의 `.docs-card`).
    await _mount(tester, _card(attributes: const {}, body: 'Body'));
    var card = tester.getRect(find.byType(Card));
    var body = tester.getRect(find.byKey(_bodyKey));
    _observations.add({'case': 'non-preview', 'card': _box(card), 'body': _box(body)});
    expect(find.byType(DocsStage), findsNothing);
    expect(body.left - card.left, 25);
    expect(body.top - card.top, 25);
    expect(card.bottom - body.bottom, 25);
    expect(tester.widget<Card>(find.byType(Card)).child, isNotNull);

    // 선 카드 — 테두리 1 + 안쪽 여백 20(사이트의 `.docs-card--outlined`).
    await _mount(tester, _card(attributes: const {'variant': 'outlined'}, body: 'Body'));
    // 같은 카드가 모양만 바꾸면 킷의 카드가 여백을 이어 옮긴다 — 다 옮긴 뒤 잰다.
    await tester.pumpAndSettle();
    card = tester.getRect(find.byType(Card));
    body = tester.getRect(find.byKey(_bodyKey));
    expect(body.left - card.left, 21);
    expect(body.top - card.top, 21);
    expect(card.bottom - body.bottom, 21);
    expect(tester.takeException(), isNull);
  });

  testWidgets('caption more retains the existing outer link callback', (tester) async {
    final links = <String>[];
    await _mount(
      tester,
      _card(
        attributes: const {'component': 'button', 'title': 'Caption', 'href': '/target', 'more': 'Read'},
        onInternalLink: links.add,
      ),
    );
    await tester.tap(find.text('Read →'));
    await tester.pump();
    expect(links, ['/target']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all caption branches retain order and the existing internal gaps', (tester) async {
    await _mount(
      tester,
      _card(
        attributes: const {
          'component': 'button',
          'eyebrow': 'Eyebrow',
          'title': 'Caption',
          'badge': 'Badge',
          'href': '/target',
          'more': 'Read',
        },
        body: 'Body',
      ),
    );
    final stage = tester.getRect(find.byType(DocsStage));
    final eyebrow = tester.getRect(find.text('Eyebrow'));
    final caption = tester.getRect(find.text('Caption'));
    final badge = tester.getRect(find.byType(Badge));
    final body = tester.getRect(find.byKey(_bodyKey));
    final more = tester.getRect(find.text('Read →'));
    expect(eyebrow.top - stage.bottom, 20);
    expect(caption.top, greaterThanOrEqualTo(eyebrow.bottom + 8));
    expect(body.top - badge.bottom, 8);
    expect(more.top - body.bottom, 8);
    expect(eyebrow.left, body.left);
    expect(more.left, body.left);
    _observations.add({
      'case': 'all-caption',
      'stage': _box(stage),
      'eyebrow': _box(eyebrow),
      'title': _box(caption),
      'badge': _box(badge),
      'body': _box(body),
      'more': _box(more),
    });
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 1.5]) {
    testWidgets('themed body padding scales once and leaves media unpadded, scale=$scale', (tester) async {
      await _mount(
        tester,
        _card(body: 'Body'),
        scale: scale,
        cardStyle: const CoreCardStyle(padding: CoreEdgeInsets.only(left: 12, right: 18, top: 10, bottom: 14)),
      );
      final card = tester.getRect(find.byType(Card));
      final stage = tester.getRect(find.byType(DocsStage));
      final caption = tester.getRect(find.text('Caption'));
      final body = tester.getRect(find.byKey(_bodyKey));
      expect(stage.left - card.left, 1 * scale);
      expect(card.right - stage.right, 1 * scale);
      expect(stage.top - card.top, 1 * scale);
      expect(caption.left - stage.left, 12 * scale);
      expect(stage.right - caption.right, 18 * scale);
      expect(caption.top - stage.bottom, 10 * scale);
      expect(card.bottom - body.bottom, 15 * scale);
      _observations.add({
        'case': 'themed-padding',
        'scale': scale,
        'card': _box(card),
        'stage': _box(stage),
        'caption': _box(caption),
        'body': _box(body),
      });
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('body-only, badge-only and explicit empty title remain real captions', (tester) async {
    for (final attributes in [
      const {'component': 'button'},
      const {'component': 'button', 'badge': 'Badge'},
      const {'component': 'button', 'title': ''},
    ]) {
      final bodyOnly = attributes.length == 1;
      await _mount(tester, _card(attributes: attributes, body: bodyOnly ? 'Body' : null));
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.body, isNotNull);
      expect(card.child, isNull);
      final rect = tester.getRect(find.byType(Card));
      final stage = tester.getRect(find.byType(DocsStage));
      expect(rect.bottom - stage.bottom, greaterThanOrEqualTo(41));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('nested paragraph links and outer keyboard activation keep distinct routes', (tester) async {
    final links = <String>[];
    await _mount(
      tester,
      Builder(
        builder: (context) => buildNativeDocsCardView(
          context: context,
          attributes: const {'component': 'button', 'title': 'Caption', 'href': '/outer'},
          rawBody: '[Nested](/nested)',
          nested: (markdown) => FlutterDocsParagraphBody(markdown: markdown, onInternalLink: links.add),
          onInternalLink: links.add,
        ),
      ),
    );
    await tester.tap(find.text('Nested', findRichText: true));
    await tester.pump();
    expect(links, ['/nested']);
    Focus.of(tester.element(find.byType(Card))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(links, ['/nested', '/outer']);
    // Clickable's normal keyboard activation owns a 100ms press pulse.
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('href without a callback remains a safe semantic link', (tester) async {
    final handle = tester.ensureSemantics();
    await _mount(tester, _card(attributes: const {'component': 'button', 'title': 'Caption', 'href': '/target'}));
    expect(find.byWidgetPredicate((widget) => widget is Semantics && widget.properties.link == true), findsOneWidget);
    await tester.tap(find.text('Caption'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  for (final width in [400.0, 600.0]) {
    testWidgets('multiple cards retain wrap widths and keep each media at its own edge, width=$width', (tester) async {
      await _mount(
        tester,
        FlutterDocsCardsLayout(
          cards: [
            _card(attributes: const {'component': 'button', 'title': 'First'}),
            _card(attributes: const {'component': 'button', 'title': 'Second'}),
          ],
        ),
        width: width,
      );
      final cards = tester.getRect(find.byType(Card).at(0));
      final other = tester.getRect(find.byType(Card).at(1));
      final stages = [for (var i = 0; i < 2; i++) tester.getRect(find.byType(DocsStage).at(i))];
      expect(cards.width, width == 600 ? 292 : 400);
      expect(other.width, cards.width);
      if (width == 600) {
        expect(other.left - cards.right, 16);
        expect(other.top, cards.top);
      } else {
        expect(other.top - cards.bottom, 16);
        expect(other.left, cards.left);
      }
      for (final (index, card) in [cards, other].indexed) {
        expect(stages[index].left - card.left, 1);
        expect(stages[index].width, card.width - 2);
      }
      _observations.add({
        'case': 'multiple',
        'width': width,
        'cards': [_box(cards), _box(other)],
      });
      expect(tester.takeException(), isNull);
    });
  }

  for (final component in ['button', 'text-field']) {
    for (final scene in readDocsScenes(component).where((scene) => scene.tag == 'Card')) {
      for (final dark in [false, true]) {
        testWidgets('canonical $component/${scene.reference} media bounds, dark=$dark', (tester) async {
          await _mount(
            tester,
            buildFlutterDocsCardScene(scene.nativeCardAttributes!, scene.nativeCardBody!),
            dark: dark,
          );
          final card = tester.getRect(find.byType(Card).first);
          final stage = tester.getRect(find.byType(DocsStage).first);
          expect(stage.left - card.left, 1);
          expect(stage.top - card.top, 1);
          expect(card.right - stage.right, 1);
          expect(tester.takeException(), isNull);
          _observations.add({
            'case': 'canonical',
            'component': component,
            'reference': scene.reference,
            'dark': dark,
            'card': _box(card),
            'stage': _box(stage),
          });
        });
      }
    }
  }
}
