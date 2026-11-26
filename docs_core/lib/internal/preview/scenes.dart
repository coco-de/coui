/// Visible documentation inputs; this file owns no component or design values.
library;

import 'dart:convert';

import 'package:jaspr_content/jaspr_content.dart' as content;

import '../../shared/size_spec.dart';
import 'selection.dart';
import 'native_docs_tag.dart' as native;

const String docsScenePrefix = 'docs-v2-';

class DocsScene {
  DocsScene({
    required this.tag,
    required this.attributes,
    required this.selections,
    required this.origins,
    this.anatomyParts = const [],
    this.cardBody = const [],
    this.cardIndex = 0,
    this.nativeCardAttributes,
    this.nativeCardBody,
    this.anatomyBody = const [],
  });

  factory DocsScene.fromJson(Map<String, Object?> json) {
    if (json['tag'] == 'Card' && (json['captureUnit'] != 'whole-card' || json['cardIndex'] != 0)) {
      throw const FormatException('Card references must declare the canonical whole-card capture unit');
    }
    return DocsScene(
      tag: json['tag']! as String,
      attributes: (json['attributes']! as Map).cast<String, String>(),
      selections: [for (final value in json['selections']! as List) PreviewSelection.fromJson((value as Map).cast())],
      origins: (json['origins']! as List).cast<String>(),
      anatomyParts: (json['anatomyParts']! as List).cast<String>(),
      cardBody: json['tag'] == 'Card'
          ? [for (final node in json['cardBody']! as List) _nodeFromJson((node as Map).cast())]
          : const [],
      cardIndex: json['tag'] == 'Card' ? json['cardIndex']! as int : 0,
      nativeCardAttributes: json['tag'] == 'Card'
          ? (json['nativeCardAttributes']! as Map).cast<String, String>()
          : null,
      nativeCardBody: json['tag'] == 'Card' ? json['nativeCardBody']! as String : null,
      anatomyBody: json['tag'] == 'Anatomy'
          ? [for (final node in json['anatomyBody']! as List) _nodeFromJson((node as Map).cast())]
          : const [],
    );
  }

  final String tag;
  final Map<String, String> attributes;
  final List<PreviewSelection> selections;
  final List<String> origins;
  final List<String> anatomyParts;
  final List<content.Node> cardBody;
  final int cardIndex;
  final Map<String, String>? nativeCardAttributes;
  final String? nativeCardBody;
  final List<content.Node> anatomyBody;

  String get flutterOwnerType => switch (tag) {
    'Playground' => '_PlaygroundFrame',
    'SizeSpec' => 'FlutterDocsSizeSpec',
    'Card' => 'FlutterDocsCardView',
    _ => 'DocsStage',
  };

  Map<String, Object?> toJson() => {
    'tag': tag,
    'attributes': {for (final key in attributes.keys.toList()..sort()) key: attributes[key]},
    'selections': selections.map((selection) => selection.toJson()).toList(),
    'origins': origins,
    'anatomyParts': anatomyParts,
    if (tag == 'Card') 'cardBody': cardBody.map(_nodeToJson).toList(),
    if (tag == 'Card') 'cardIndex': cardIndex,
    if (tag == 'Card') 'captureUnit': 'whole-card',
    if (tag == 'Card')
      'nativeCardAttributes': {
        for (final key in nativeCardAttributes!.keys.toList()..sort()) key: nativeCardAttributes![key],
      },
    if (tag == 'Card') 'nativeCardBody': nativeCardBody!,
    if (tag == 'Anatomy') 'anatomyBody': anatomyBody.map(_nodeToJson).toList(),
  };

  /// The full input accompanies the reference, so collisions cannot alias scenes.
  String get identity => jsonEncode({...toJson()}..remove('origins'));

  String get reference {
    // FNV-1a-128 is a deterministic filename identifier, not a security digest.
    // BigInt keeps server and JavaScript arithmetic identical.
    var hash = BigInt.parse('6c62272e07bb014262b821756295c58d', radix: 16);
    final prime = BigInt.parse('1000000000000000000013b', radix: 16);
    final mask = (BigInt.one << 128) - BigInt.one;
    for (final byte in utf8.encode(identity)) {
      hash = ((hash ^ BigInt.from(byte)) * prime) & mask;
    }
    return '$docsScenePrefix${hash.toRadixString(16).padLeft(32, '0')}';
  }
}

List<DocsScene> visibleDocsScenes(String source, {required String sourcePath}) {
  final scenes = <String, DocsScene>{};
  late final Map<String, Map<String, _NativeCardInput>> nativeCards;

  void visit(List<content.Node> nodes, String path) {
    for (final (index, node) in nodes.indexed) {
      if (node is! content.ElementNode) continue;
      final origin = '$path:${node.tag}[$index]';
      final attributes = node.attributes;
      final visible =
          const {'Preview', 'VariantRow', 'Anatomy', 'SizeSpec', 'Playground', 'Card'}.contains(node.tag) &&
          (attributes.containsKey('component') || attributes.containsKey('demo'));
      if (visible) {
        final List<PreviewSelection> selections;
        if (node.tag == 'Playground') {
          selections = [PreviewSelection.playground(attributes['component']!)];
        } else if (node.tag == 'SizeSpec') {
          final component = attributes['component'];
          final spec = component == null ? null : docsSizeSpecFor(component);
          if (spec == null) throw StateError('$origin: no SizeSpec for "$component"');
          selections = [
            for (final row in spec.rows) PreviewSelection.attributes(attributes, extraProps: {'size': row.size.name}),
          ];
        } else {
          selections = [PreviewSelection.attributes(attributes)];
        }
        final _NativeCardInput? nativeCard;
        if (node.tag == 'Card') {
          final matches = nativeCards[_cardFingerprint(node)];
          if (matches == null || matches.length != 1) {
            throw StateError('$origin: original Native Card source is missing or ambiguous');
          }
          nativeCard = matches.values.single;
        } else {
          nativeCard = null;
        }
        final scene = DocsScene(
          tag: node.tag,
          attributes: attributes,
          selections: selections,
          origins: [origin],
          cardBody: node.tag == 'Card' ? node.children ?? const [] : const [],
          // The source location remains in origins; standalone Card layout
          // always uses the original single-card branch's index zero.
          cardIndex: 0,
          nativeCardAttributes: nativeCard?.attributes,
          nativeCardBody: nativeCard?.rawBody,
          anatomyBody: node.tag == 'Anatomy' ? node.children ?? const [] : const [],
          anatomyParts: node.tag == 'Anatomy'
              ? [
                  for (final child in node.children ?? const <content.Node>[])
                    if (child is content.ElementNode && child.tag == 'AnatomyItem')
                      '${child.attributes['select'] ?? child.attributes['part'] ?? ''}@${child.attributes['side'] ?? ''}',
                ]
              : const [],
        );
        final previous = scenes[scene.reference];
        if (previous != null) {
          if (previous.identity != scene.identity) throw StateError('$origin: documentation scene reference collision');
          previous.origins.add(origin);
        } else {
          scenes[scene.reference] = scene;
        }
      }
      visit(node.children ?? const [], origin);
    }
  }

  final page = content.Page(
    path: sourcePath.replaceAll('\\', '/'),
    url: '/',
    content: source,
    config: const content.PageConfig(parsers: [content.MarkdownParser()]),
    loader: content.MemoryLoader(pages: []),
  );
  page.parseFrontmatter();
  final nodes = page.parseNodes();
  final neededCards = <String>{};
  void collectVisibleCards(List<content.Node> nodes) {
    for (final node in nodes.whereType<content.ElementNode>()) {
      if (node.tag == 'Card' && (node.attributes.containsKey('component') || node.attributes.containsKey('demo'))) {
        neededCards.add(_cardFingerprint(node));
      }
      collectVisibleCards(node.children ?? const []);
    }
  }

  collectVisibleCards(nodes);
  nativeCards = neededCards.isEmpty ? {} : _nativeCardInputs(page.content, neededCards);
  visit(nodes, sourcePath);
  return scenes.values.toList();
}

Map<String, Object?> _nodeToJson(content.Node node) => switch (node) {
  content.TextNode() => {'text': node.text, 'raw': node.raw},
  content.ElementNode() => {
    'tag': node.tag,
    'attributes': {for (final key in node.attributes.keys.toList()..sort()) key: node.attributes[key]},
    'children': node.children?.map(_nodeToJson).toList(),
  },
  content.ComponentNode() => throw StateError('A source scene cannot serialize an already-built component'),
};

content.Node _nodeFromJson(Map<String, Object?> json) {
  if (json.containsKey('text')) return content.TextNode(json['text']! as String, raw: json['raw']! as bool);
  return content.ElementNode(
    json['tag']! as String,
    (json['attributes']! as Map).cast<String, String>(),
    (json['children'] as List?)?.map((node) => _nodeFromJson((node as Map).cast())).toList(),
  );
}

class _NativeCardInput {
  const _NativeCardInput(this.attributes, this.rawBody);
  final Map<String, String> attributes;
  final String rawBody;

  String get identity => jsonEncode({
    'attributes': {for (final key in attributes.keys.toList()..sort()) key: attributes[key]},
    'rawBody': rawBody,
  });
}

String _cardFingerprint(content.ElementNode node) => jsonEncode({
  'attributes': {for (final key in node.attributes.keys.toList()..sort()) key: node.attributes[key]},
  'body': (node.children ?? const <content.Node>[]).map(_nodeToJson).toList(),
});

Map<String, Map<String, _NativeCardInput>> _nativeCardInputs(String source, Set<String> neededCards) {
  final result = <String, Map<String, _NativeCardInput>>{};
  void collect(String markdown) {
    for (final match in native.findDocsTags(markdown)) {
      final tag = match.tag;
      if (tag.name == 'Card') {
        final fragment = markdown.substring(match.start, match.end);
        final page = content.Page(
          path: 'native-card-fragment.md',
          url: '/',
          content: fragment,
          config: const content.PageConfig(parsers: [content.MarkdownParser()]),
          loader: content.MemoryLoader(pages: []),
        );
        final cards = page.parseNodes().whereType<content.ElementNode>().where((node) => node.tag == 'Card').toList();
        // The original Native parser can recognize tags in code/comments.
        // Only actual visible AST inputs may request a Native counterpart.
        if (cards.length == 1) {
          final fingerprint = _cardFingerprint(cards.single);
          if (neededCards.contains(fingerprint)) {
            final input = _NativeCardInput(tag.attributes, tag.innerMarkdown ?? '');
            (result[fingerprint] ??= {})[input.identity] = input;
          }
        }
      }
      if (tag.innerMarkdown != null) collect(tag.innerMarkdown!);
    }
  }

  collect(source);
  return result;
}
