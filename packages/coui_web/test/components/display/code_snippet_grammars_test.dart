/// The grammars `CodeSnippet` registers on Web are the files Flutter loads as
/// assets, compiled into this package because a Jaspr page has no asset
/// bundle. Two copies of a grammar are two readings of a language waiting to
/// drift apart, so the copy is generated and this test holds it to its
/// source.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/src/components/display/code_snippet/code_snippet_grammars.g.dart';
import 'package:test/test.dart';

import '../../../tool/gen_code_snippet_grammars.dart' as gen;

/// The shared vector table, relative to this package's root.
const _kVectorsPath = '../coui_core/test/fixtures/code_syntax_vectors.json';

void main() {
  test('the generated file is what the generator writes from the assets '
      'today', () async {
    expect(
      await gen.isUpToDate(),
      isTrue,
      reason:
          'Run: dart run packages/coui_web/tool/gen_code_snippet_grammars.dart',
    );
  });

  test('each compiled-in grammar is its asset file, byte for byte', () {
    for (final language in gen.kGeneratedLanguages) {
      expect(
        codeSnippetGrammarSource(language),
        gen.sourceOf(language),
        reason: language,
      );
    }
  });

  test('each compiled-in grammar is a grammar', () {
    for (final language in gen.kGeneratedLanguages) {
      final grammar =
          jsonDecode(codeSnippetGrammarSource(language)!)
              as Map<String, Object?>;
      expect(grammar['scopeName'], isA<String>(), reason: language);
      expect(grammar['patterns'], isA<List<Object?>>(), reason: language);
    }
  });

  // The contract's table names the grammar; this package has to hold it. A
  // name with nothing compiled in would be handed to the highlighter as a
  // language it was never given.
  test('every grammar the modes name, Dart aside, is compiled in', () {
    final doc =
        jsonDecode(File(_kVectorsPath).readAsStringSync())
            as Map<String, Object?>;
    final named = (doc['modes']! as Map).values.nonNulls.cast<String>().toSet()
      ..remove('dart');

    expect(named, gen.kGeneratedLanguages.toSet());
    for (final language in named) {
      expect(codeSnippetGrammarSource(language), isNotNull, reason: language);
    }
  });

  test('Dart has nothing compiled in — the highlighter embeds it', () {
    expect(codeSnippetGrammarSource('dart'), isNull);
    expect(codeSnippetGrammarSource('bash'), isNull);
  });
}
