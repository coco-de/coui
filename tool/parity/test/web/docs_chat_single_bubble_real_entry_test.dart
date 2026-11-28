// Authored source only until the explicit bounded SDK qualification.
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:coui_web/coui_web.dart' as coui;
import 'package:docs_core/previews/web_registry.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html;
import 'package:jaspr/dom.dart' show Styles, div;
import 'package:jaspr/server.dart';
import 'package:test/test.dart';

import '../../src/manifest/capture_probes.dart';
import '../../src/model/matrix_entry.dart';
import '../../src/web/docs_chat_single_bubble_ssr_source.dart';
import '../../src/web/ssr_render.dart';

const kChatVariants = <String>[
  'neutral',
  'primary',
  'secondary',
  'accent',
  'info',
  'success',
  'warning',
  'error',
];
const _kExampleTypes = <String, String>{
  'neutral': 'ChatNeutralExample',
  'primary': 'ChatPrimaryExample',
  'secondary': 'ChatSecondaryExample',
  'accent': 'ChatAccentExample',
  'info': 'ChatInfoExample',
  'success': 'ChatSuccessExample',
  'warning': 'ChatWarningExample',
  'error': 'ChatErrorExample',
};

typedef ChatFixture = ({
  MatrixEntry entry,
  String body,
  Map<String, Object?>? receipt,
  html_dom.Element capture,
  html_dom.Element owner,
  int builds,
  int observations,
});

MatrixEntry chatEntry(String variant, String theme) {
  final key = 'chat-$variant-$theme-defaultStyle';
  return MatrixEntry.fromJson({
    'component': 'chat',
    'variant': variant,
    'theme': theme,
    'surfaceStyle': 'defaultStyle',
    'tier': 't2',
    'probes': captureProbes(
      key: key,
      component: 'chat',
      variant: variant,
      flutterClassName: _kExampleTypes[variant]!,
    ).map((p) => p.toJson()).toList(),
  });
}

/// One normal registry invocation and normal SSR response per fixture.
/// The test supplies only the not-yet-integrated capture-tool observer hook.
Future<ChatFixture> renderChatFixture(
  String variant,
  String theme, {
  bool requested = true,
  coui.ThemeData? themeData,
  void Function(Element root, div capture)? beforeObserve,
  void Function(Element root, div capture)? afterObserve,
  void Function(Element root, div capture)? afterResponseBeforeComplete,
}) async {
  final entry = chatEntry(variant, theme);
  final recorder = requested
      ? DocsChatSingleBubbleSsrSource.forEntry(entry)!
      : null;
  var builds = 0;
  var observations = 0;
  Element? normalRoot;
  div? normalCapture;
  final body = await renderComponentBodyHtml(
    _OriginalChatBuild(
      entry,
      recorder,
      themeData ?? coui.ThemeData.coui,
      () => builds++,
      (capture) => normalCapture = capture,
    ),
    onMountedRoot: recorder == null
        ? null
        : (root) {
            observations++;
            normalRoot = root;
            beforeObserve?.call(root, normalCapture!);
            try {
              recorder.observe(root);
            } finally {
              afterObserve?.call(root, normalCapture!);
            }
          },
  );
  if (normalRoot != null) {
    afterResponseBeforeComplete?.call(normalRoot!, normalCapture!);
  }
  final receipt = recorder?.completeWithSerializedBody(body);
  final fragment = html.parseFragment(body);
  return (
    entry: entry,
    body: body,
    receipt: receipt,
    capture: fragment.querySelectorAll('[data-parity-key]').single,
    owner: fragment.querySelectorAll(entry.probes.single.webSelector).single,
    builds: builds,
    observations: observations,
  );
}

class _OriginalChatBuild extends StatelessComponent {
  const _OriginalChatBuild(
    this.entry,
    this.recorder,
    this.themeData,
    this.onBuild,
    this.onCapture,
  );
  final MatrixEntry entry;
  final DocsChatSingleBubbleSsrSource? recorder;
  final coui.ThemeData themeData;
  final void Function() onBuild;
  final void Function(div capture) onCapture;

  @override
  Component build(BuildContext context) {
    onBuild();
    final result = kWebPreviewRegistry[entry.component]!(
      context,
      entry.variant,
    );
    final capture = div(
      [result],
      styles: const Styles(raw: {'display': 'flex', 'width': '800px'}),
      attributes: {'data-parity-key': entry.key},
    );
    onCapture(capture);
    recorder?.recordBuild(result, capture);
    return coui.CoUIWeb(theme: themeData, child: capture);
  }
}

Element _sole(Element element) {
  final children = <Element>[];
  element.visitChildren(children.add);
  expect(children, hasLength(1));
  return children.single;
}

/// Prefix search stops at the exact test-owned capture. After it, only the
/// normal owned Example/Chat/row/column/scope edges are visited; body opaque.
({Element chat, Element bubble}) chatElements(Element root, div capture) {
  final matches = <Element>[];
  void visit(Element element) {
    if (identical(element.component, capture)) {
      matches.add(element);
      return;
    }
    element.visitChildren(visit);
  }

  visit(root);
  expect(matches, hasLength(1));
  final example = _sole(_sole(matches.single));
  // Typed div -> DomElement -> original Example, then its current Chat.
  final chat = _sole(example);
  expect(chat.component.runtimeType, coui.Chat);
  final row = _sole(chat);
  final rowDom = _sole(row);
  final column = _sole(rowDom);
  final columnDom = _sole(column);
  final scope = _sole(columnDom);
  expect(scope.component.runtimeType, coui.ChatAlignmentScope);
  final bubble = _sole(scope);
  expect(bubble.component.runtimeType, coui.ChatBubble);
  return (chat: chat, bubble: bubble);
}

class _PoisonHandlers extends MapBase<String, List<coui.UiEventHandler>> {
  int reads = 0;
  Never _read() {
    reads++;
    throw StateError('POISON_EVENT_MAP_GETTER_REPLAY');
  }

  @override
  Iterable<String> get keys => _read();
  @override
  int get length => _read();
  @override
  bool get isEmpty => _read();
  @override
  bool get isNotEmpty => _read();
  @override
  Iterable<MapEntry<String, List<coui.UiEventHandler>>> get entries => _read();
  @override
  bool containsKey(Object? key) => _read();
  @override
  List<coui.UiEventHandler>? operator [](Object? key) => _read();
  @override
  void operator []=(String key, List<coui.UiEventHandler> value) => _read();
  @override
  void clear() => _read();
  @override
  List<coui.UiEventHandler>? remove(Object? key) => _read();
}

coui.ThemeData nondefaultChannelTheme() => const coui.ThemeData(
  coreComponentTheme: coui.CoreComponentTheme(
    chatBubble: coui.CoreChatBubbleTheme(
      style: coui.CoreChatBubbleStyle(
        padding: coui.CoreEdgeInsets.all(17),
        backgroundColor: coui.CoreColor.token(
          coui.CoreColors.warning,
          opacity: .4,
        ),
        textStyle: coui.CoreTextStyle.token(
          coui.CoreTextStyles.codeMd,
          color: coui.CoreColor.token(coui.CoreColors.primary, opacity: .6),
        ),
      ),
    ),
  ),
);

// Fresh library state gives both normal mounts the same initial provider
// counters. Only plain data crosses the isolate boundary; no Element, receipt
// object, live reference, counter reset or package:test assertion crosses it.
Future<({String body, int builds, int observations, bool receiptPresent})>
_freshNormalResponse(bool requested) => Isolate.run(() async {
  final actual = await renderChatFixture(
    'neutral',
    'light',
    requested: requested,
  );
  return (
    body: actual.body,
    builds: actual.builds,
    observations: actual.observations,
    receiptPresent: actual.receipt != null,
  );
});

void main() {
  for (final variant in kChatVariants) {
    for (final theme in ['light', 'dark']) {
      test('original single-bubble source / $variant / $theme', () async {
        final actual = await renderChatFixture(variant, theme);
        expect(actual.builds, 1);
        expect(actual.observations, 1);
        expect(actual.receipt!['entryKey'], actual.entry.key);
        final raw = actual.receipt!['currentRaw']! as Map;
        expect(raw['variant'], variant);
        final parameters = raw['rawParameters']! as Map;
        expect(parameters['bubbleAlignment'], isNull);
        expect(parameters['bubbleTail'], isNull);
        expect(parameters['instanceStyle'], isNull);
        expect(parameters['scopeChildIsOriginalBubble'], true);
        expect(raw['opaqueInteriorsRead'], false);
        final retain = Platform.environment['PARITY_CHAT_FIXTURE_OUT'];
        if (retain != null) {
          final out = Directory(retain)..createSync(recursive: true);
          File(
            '${out.path}/${actual.entry.key}.normal-body.html',
          ).writeAsStringSync(actual.body);
          File(
            '${out.path}/${actual.entry.key}.source-receipt.json',
          ).writeAsStringSync(jsonEncode(actual.receipt));
        }
      });
    }
  }

  test('requested observer preserves one fresh normal response', () async {
    final requested = await _freshNormalResponse(true);
    final unrequested = await _freshNormalResponse(false);
    final retain = Platform.environment['PARITY_CHAT_FIXTURE_OUT'];
    if (retain != null) {
      final out = Directory('$retain/fresh-pair')..createSync(recursive: true);
      File(
        '${out.path}/requested.normal-body.html',
      ).writeAsStringSync(requested.body);
      File(
        '${out.path}/unrequested.normal-body.html',
      ).writeAsStringSync(unrequested.body);
      File('${out.path}/plain-result-counts.json').writeAsStringSync(
        jsonEncode({
          'requested': {
            'builds': requested.builds,
            'observations': requested.observations,
            'receiptPresent': requested.receiptPresent,
          },
          'unrequested': {
            'builds': unrequested.builds,
            'observations': unrequested.observations,
            'receiptPresent': unrequested.receiptPresent,
          },
        }),
      );
    }
    expect(requested.body, unrequested.body);
    expect(requested.builds, 1);
    expect(requested.observations, 1);
    expect(requested.receiptPresent, true);
    expect(unrequested.builds, 1);
    expect(unrequested.observations, 0);
    expect(unrequested.receiptPresent, false);
  });

  test('custom event map rejected before every collection getter', () async {
    final poison = _PoisonHandlers();
    Element? changed;
    Component? original;
    await expectLater(
      renderChatFixture(
        'neutral',
        'light',
        beforeObserve: (root, capture) {
          changed = chatElements(root, capture).chat;
          original = changed!.component;
          final replacement = (original! as coui.Chat).copyWith(
            eventHandlers: poison,
          );
          // Public Element.update only changes the current configuration;
          // no didUpdate/rebuild/resolve/render callback is invoked here.
          changed!.update(replacement);
        },
        afterObserve: (_, _) => changed!.update(original!),
      ),
      throwsA(
        isA<StateError>().having(
          (e) => '$e',
          'reason',
          contains('unproved event-handler Map provenance'),
        ),
      ),
    );
    expect(poison.reads, 0);
  });

  test('normal completion rereads current public configuration', () async {
    await expectLater(
      renderChatFixture(
        'neutral',
        'light',
        afterResponseBeforeComplete: (root, capture) {
          final element = chatElements(root, capture).chat;
          element.update(
            (element.component as coui.Chat).copyWith(
              alignment: coui.CoreChatAlignment.end,
            ),
          );
        },
      ),
      throwsA(
        isA<StateError>().having(
          (e) => '$e',
          'reason',
          contains('original single no-slot Chat'),
        ),
      ),
    );
  });

  test(
    'normal nondefault declaration channels keep raw padding authority',
    () async {
      final actual = await renderChatFixture(
        'neutral',
        'light',
        themeData: nondefaultChannelTheme(),
      );
      final raw = actual.receipt!['currentRaw']! as Map;
      final theme = (raw['rawParameters']! as Map)['themePadding']! as Map;
      expect(theme['baseStylePresent'], true);
      expect(theme['basePadding'], isA<int>());
      expect(theme['variantMapPresent'], false);
      // Class values are checked only as declaration-channel evidence.
      // No color/typography value becomes an inset premise or expected vector.
      expect(
        (raw['bodyDeclaration']! as Map)['class'],
        contains('text-code-md text-primary/60 bg-warning/40'),
      );
    },
  );
}
