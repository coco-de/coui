// The code strings and the role names are the fixture data — naming each one
// would hide the text the assertion is about.

/// What the Web `CodeSnippet` emits for highlighted code: the colour of every
/// run of it, read off the rendered `<code>` element.
///
/// The shared vector table
/// (`coui_core/test/fixtures/code_syntax_vectors.json`) says which role each
/// run takes; the token a role reads says which CSS variable that is. Nothing
/// in between is restated here, so a theme that painted stock Dark+ hex, left
/// a span unthemed, or let the highlighter's bracket rainbow through fails
/// here.
///
/// Every row is read: Web runs the grammars Flutter does. Which grammar a
/// mode runs is the same table's `modes` — a mode it gives none is shown as
/// plain text, and the first group here holds that.
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/jaspr.dart' as jaspr show Text;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The shared vector table, relative to this package's root.
const _kVectorsPath = '../coui_core/test/fixtures/code_syntax_vectors.json';

/// An emitted stretch of code and its colour — `null` when it inherits the
/// code colour.
typedef _Run = (String text, String? color);

List<Map<String, Object?>> _vectors() {
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  return (doc['vectors']! as List).cast<Map<String, Object?>>();
}

/// The grammar each mode is painted with, as the shared table states it —
/// `null` for a mode shown as plain text.
Map<String, String?> _modes() {
  final doc =
      jsonDecode(File(_kVectorsPath).readAsStringSync())
          as Map<String, Object?>;
  return (doc['modes']! as Map).cast<String, String?>();
}

/// A vector's code, read in the vector's own mode.
String _title(Map<String, Object?> vector) =>
    '${vector['mode']} ${jsonEncode(vector['code'])}';

/// The colour a role is emitted in, as the CSS variable reference the
/// resolver publishes — `null` for [CoreSyntaxRole.plain], which inherits.
String? _variable(CoreSyntaxRole role) {
  final token = role.token;
  return token == null ? null : 'rgb(var(--coui-${token.name}))';
}

/// [roles] is whether the face admits the role colours; when it does not,
/// no run states a colour and all of them inherit the code ink.
List<_Run> _expected(Map<String, Object?> vector, {bool roles = true}) {
  final out = <_Run>[];
  for (final run in (vector['runs']! as List).cast<List<Object?>>()) {
    final role = CoreSyntaxRole.values.byName(run[1]! as String);
    _append(out, run[0]! as String, roles ? _variable(role) : null);
  }
  return out;
}

void _append(List<_Run> out, String text, String? color) {
  if (out.isNotEmpty && out.last.$2 == color) {
    out[out.length - 1] = (out.last.$1 + text, color);
  } else {
    out.add((text, color));
  }
}

/// The runs under the `<code>` element: every text node with the colour of
/// the nearest `<span>` that states one, adjacent runs of one colour joined.
List<_Run> _emitted(ComponentTester tester) {
  final out = <_Run>[];
  void visit(Element element, String? color) {
    final component = element.component;
    if (component is jaspr.Text) {
      _append(out, component.text, color);
      return;
    }
    final own = component is DomComponent && component.tag == 'span'
        ? component.styles?.properties['color']
        : null;
    element.visitChildren((child) => visit(child, own ?? color));
  }

  visit(find.tag('code').evaluate().single, null);
  return out;
}

/// Every inline `color` the `<code>` subtree states.
List<String> _inlineColors(ComponentTester tester) {
  final colors = <String>[];
  void visit(Element element) {
    final component = element.component;
    if (component is DomComponent) {
      final color = component.styles?.properties['color'];
      if (color != null) colors.add(color);
    }
    element.visitChildren(visit);
  }

  visit(find.tag('code').evaluate().single);
  return colors;
}

/// Every inline `color` a highlighted `<span>` under `<code>` states — the
/// code element's own ink is the wrapper's, not a span's.
List<String> _spanColors(ComponentTester tester) {
  final colors = <String>[];
  void visit(Element element) {
    final component = element.component;
    if (component is DomComponent && component.tag == 'span') {
      final color = component.styles?.properties['color'];
      if (color != null) colors.add(color);
    }
    element.visitChildren(visit);
  }

  visit(find.tag('code').evaluate().single);
  return colors;
}

/// Every `<span>` the `<code>` subtree emits. A span exists to state a
/// colour: one that states none is markup for nothing.
List<DomComponent> _spans(ComponentTester tester) {
  final spans = <DomComponent>[];
  void visit(Element element) {
    final component = element.component;
    if (component is DomComponent && component.tag == 'span') {
      spans.add(component);
    }
    element.visitChildren(visit);
  }

  visit(find.tag('code').evaluate().single);
  return spans;
}

void _pumpSnippet(
  ComponentTester tester,
  String code, {
  String mode = 'dart',
  CoreCodeSnippetStyle? style,
  CoreCodeSnippetStyle? themeStyle,
  bool showLineNumbers = false,
}) {
  final snippet = CodeSnippet(
    code: code,
    mode: mode,
    showLineNumbers: showLineNumbers,
    showCopyButton: false,
    codeSnippetStyle: style,
  );
  if (themeStyle == null) {
    pumpWithTheme(tester, snippet);
    return;
  }
  tester.pumpComponent(
    Theme(
      data: ThemeData.coui.copyWith(
        coreComponentTheme: CoreComponentTheme(
          codeSnippet: CoreCodeSnippetTheme(style: themeStyle),
        ),
      ),
      child: snippet,
    ),
  );
}

/// Pumps a vector's code in the vector's own mode.
void _pumpVector(
  ComponentTester tester,
  Map<String, Object?> vector, {
  CoreCodeSnippetStyle? style,
  CoreCodeSnippetStyle? themeStyle,
}) => _pumpSnippet(
  tester,
  vector['code']! as String,
  mode: vector['mode']! as String,
  style: style,
  themeStyle: themeStyle,
);

void main() {
  // A grammar is only ever applied to its own language. Painting YAML with
  // the Dart grammar is not "less highlighting" but wrong highlighting: the
  // `//` of a URL becomes a comment and runs to the end of the line.
  group('mode decides which grammar runs', () {
    const yaml = 'url: https://github.com/coco-de/coui.git';

    for (final MapEntry(key: mode, value: grammar) in _modes().entries) {
      if (grammar == null) {
        testComponents('`$mode` is shown as plain text', (tester) async {
          _pumpSnippet(tester, yaml, mode: mode);

          expect(_spans(tester), isEmpty);
          expect(_emitted(tester), [(yaml, null)]);
        });
        continue;
      }

      // The mode is painted exactly as the grammar's own name paints it —
      // an alias is another spelling, never another reading.
      testComponents('`$mode` is painted with the $grammar grammar', (
        tester,
      ) async {
        final vector = _vectors().firstWhere((v) => v['mode'] == grammar);
        _pumpSnippet(tester, vector['code']! as String, mode: mode);

        expect(_emitted(tester), _expected(vector));
      });
    }

    testComponents('YAML leaves the `//` of a URL unpainted', (tester) async {
      _pumpSnippet(tester, yaml, mode: 'yaml');

      // The key and each colon are painted; the `//…` after the scheme is
      // text, as it is in the file.
      expect(_emitted(tester), [
        ('url', _variable(CoreSyntaxRole.function)),
        (':', _variable(CoreSyntaxRole.punctuation)),
        (' https', null),
        (':', _variable(CoreSyntaxRole.punctuation)),
        ('//github.com/coco-de/coui.git', null),
      ]);
    });

    testComponents('the same text under `dart` reads that `//` as a comment', (
      tester,
    ) async {
      // The control for the test above: the two grammars read this line
      // differently, so which one ran is visible in what was emitted. Dart
      // paints no key, and paints the `//…` to the end of the line — joined
      // here with the colon before it, since punctuation and comment share
      // an ink.
      _pumpSnippet(tester, yaml);

      expect(_variable(CoreSyntaxRole.comment), isNotNull);
      expect(
        _variable(CoreSyntaxRole.comment),
        _variable(CoreSyntaxRole.punctuation),
      );
      expect(_emitted(tester), [
        ('url', null),
        (':', _variable(CoreSyntaxRole.punctuation)),
        (' https', null),
        ('://github.com/coco-de/coui.git', _variable(CoreSyntaxRole.comment)),
      ]);
    });

    testComponents('snippets of different modes on one page each keep their '
        'own grammar', (tester) async {
      // The highlighters are shared across snippets, one per grammar: a
      // second mode must not replace the first.
      final byMode = {
        for (final vector in _vectors()) vector['mode']! as String: vector,
      };
      for (final vector in [...byMode.values, ...byMode.values]) {
        _pumpVector(tester, vector);
        expect(_emitted(tester), _expected(vector), reason: _title(vector));
      }
    });
  });

  group('emitted span colours — the shared vectors', () {
    for (final vector in _vectors()) {
      testComponents(
        "every run is in its role's variable: ${_title(vector)}",
        (
          tester,
        ) async {
          _pumpVector(tester, vector);
          expect(_emitted(tester), _expected(vector));
        },
      );
    }

    testComponents('every colour is a variable reference, never a hex', (
      tester,
    ) async {
      for (final vector in _vectors()) {
        _pumpVector(tester, vector);
        final colors = _inlineColors(tester);
        expect(colors, isNotEmpty);
        for (final color in colors) {
          expect(
            color,
            matches(RegExp(r'^rgb\(var\(--coui-[a-z-]+\)\)$')),
            reason: '$color in ${vector['code']}',
          );
        }
      }
    });

    testComponents('no stock Dark+ or bracket-rainbow colour is emitted', (
      tester,
    ) async {
      // The hex the snippet used to paint in every mode, and the
      // highlighter's own bracket colours.
      const stock = [
        'd4d4d4',
        '569cd6',
        'ce9178',
        'dcdcaa',
        '4ec9b0',
        'c586c0',
        '6a9955',
        '608b4e',
        '5caeef',
        'dfb976',
        'c172d9',
        '4fb1bc',
        '97c26c',
        'abb2c0',
        'ff0000',
      ];
      for (final vector in _vectors()) {
        _pumpVector(tester, vector);
        final joined = _inlineColors(tester).join(' ').toLowerCase();
        for (final hex in stock) {
          expect(joined, isNot(contains(hex)), reason: hex);
        }
      }
    });

    testComponents('plain text states no colour and follows the code ink', (
      tester,
    ) async {
      // Plain runs inherit; a restated code colour moves them and leaves the
      // slots alone — the code ink is the wrapper's, the slots are the
      // scheme's.
      _pumpSnippet(
        tester,
        'final answer = 42;',
        style: const CoreCodeSnippetStyle(
          codeTextStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.onPrimary),
          ),
        ),
      );
      expect(_emitted(tester), [
        ('final', 'rgb(var(--coui-syntax-keyword))'),
        (' answer ', null),
        ('=', 'rgb(var(--coui-on-surface-variant))'),
        (' ', null),
        ('42', 'rgb(var(--coui-syntax-type))'),
        (';', 'rgb(var(--coui-on-surface-variant))'),
      ]);
    });

    testComponents('only a run that states a colour gets a span', (
      tester,
    ) async {
      // Plain text is bare text inside the `<code>`: a span around it would be
      // an element with no class and no style.
      for (final vector in _vectors()) {
        _pumpVector(tester, vector);
        final spans = _spans(tester);
        expect(spans, isNotEmpty, reason: '${vector['code']}');
        for (final span in spans) {
          expect(
            span.styles?.properties['color'],
            isNotNull,
            reason: 'a span with no colour in ${vector['code']}',
          );
        }
      }
    });

    testComponents('the gutter and the highlighted code both render', (
      tester,
    ) async {
      _pumpSnippet(tester, 'final a = 1;\nfinal b = 2;', showLineNumbers: true);
      expect(_emitted(tester).where((r) => r.$2 != null), isNotEmpty);
      expect(find.text('1'), findsComponents);
      expect(find.text('2'), findsComponents);
    });
  });

  group('emitted span colours — by face', () {
    // The role colours apply on a face the audit certifies them on and
    // nowhere else. On any other face no highlighted span states a colour:
    // every run inherits the code ink the content wrapper carries.
    const base = CodeSnippet(code: '', mode: 'dart');
    final admitted = <String, CoreCodeSnippetStyle?>{
      'the default face': null,
      '.surface': base.surface.codeSnippetStyle,
      '.surfaceContainer': base.surfaceContainer.codeSnippetStyle,
      for (final tone in CoreSyntaxFaces.tones)
        'tone ${tone.name}': CoreCodeSnippetStyle(
          backgroundColor: CoreColor.token(tone),
        ),
    };
    final off = <String, CoreCodeSnippetStyle?>{
      '.primary': base.primary.codeSnippetStyle,
      '.secondary': base.secondary.codeSnippetStyle,
      '.tertiary': base.tertiary.codeSnippetStyle,
      '.error': base.error.codeSnippetStyle,
      '.success': base.success.codeSnippetStyle,
      '.warning': base.warning.codeSnippetStyle,
      '.info': base.info.codeSnippetStyle,
      '.outline': base.outline.codeSnippetStyle,
      '.transparent': base.transparent.codeSnippetStyle,
      'a raw colour': const CoreCodeSnippetStyle(
        backgroundColor: CoreColor(0xFF1E2430),
      ),
      'a tone at 99% opacity': const CoreCodeSnippetStyle(
        backgroundColor: CoreColor.token(
          CoreColors.surfaceContainerLow,
          opacity: 0.99,
        ),
      ),
      'a tone outside the audit list': const CoreCodeSnippetStyle(
        backgroundColor: CoreColor.token(CoreColors.surfaceContainerHighest),
      ),
    };

    for (final MapEntry(key: faceName, value: style) in admitted.entries) {
      testComponents('$faceName — every run is in its role variable', (
        tester,
      ) async {
        for (final vector in _vectors()) {
          _pumpVector(tester, vector, style: style);
          expect(
            _emitted(tester),
            _expected(vector),
            reason: '${vector['code']}',
          );
        }
      });
    }

    for (final MapEntry(key: faceName, value: style) in off.entries) {
      testComponents('$faceName — no span states a colour, every run '
          'inherits the ink', (tester) async {
        for (final vector in _vectors()) {
          _pumpVector(tester, vector, style: style);
          expect(
            _emitted(tester),
            _expected(vector, roles: false),
            reason: '${vector['code']}',
          );
          expect(
            _spanColors(tester),
            isEmpty,
            reason: '${vector['code']} on $faceName',
          );
          expect(
            _spans(tester),
            isEmpty,
            reason:
                'no run states anything, so none is wrapped: '
                '${vector['code']} on $faceName',
          );
        }
      });
    }
  });

  group('emitted span colours — the face from the project theme', () {
    // The gate reads the merged style, so a face stated in the project theme
    // (`CoreCodeSnippetTheme.style`) switches the role colours exactly as an
    // instance-level one does.
    const base = CodeSnippet(code: '', mode: 'dart');
    const solidTheme = CoreCodeSnippetStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
      codeTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onPrimary),
      ),
    );
    const toneTheme = CoreCodeSnippetStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
    );
    final themed =
        <
          String,
          ({
            CoreCodeSnippetStyle themeStyle,
            CoreCodeSnippetStyle? style,
            bool roles,
          })
        >{
          'a solid face in the theme': (
            themeStyle: solidTheme,
            style: null,
            roles: false,
          ),
          'a tone in the theme': (
            themeStyle: toneTheme,
            style: null,
            roles: true,
          ),
          'a solid theme face under an instance .surface': (
            themeStyle: solidTheme,
            style: base.surface.codeSnippetStyle,
            roles: true,
          ),
          'a tone theme face under an instance .error': (
            themeStyle: toneTheme,
            style: base.error.codeSnippetStyle,
            roles: false,
          ),
        };

    for (final MapEntry(key: faceName, value: face) in themed.entries) {
      testComponents(
        face.roles
            ? '$faceName — every run is in its role variable'
            : '$faceName — no span states a colour, every run inherits the ink',
        (tester) async {
          for (final vector in _vectors()) {
            _pumpVector(
              tester,
              vector,
              style: face.style,
              themeStyle: face.themeStyle,
            );
            expect(
              _emitted(tester),
              _expected(vector, roles: face.roles),
              reason: '${vector['code']}',
            );
            if (!face.roles) expect(_spans(tester), isEmpty);
          }
        },
      );
    }

    testComponents('an ink stated alone leaves the face rule where it was', (
      tester,
    ) async {
      const ink = CoreCodeSnippetStyle(
        codeTextStyle: CoreTextStyle(
          color: CoreColor.token(CoreColors.onError),
        ),
      );
      for (final vector in _vectors()) {
        final code = vector['code']! as String;
        // On a tone the roles stay on …
        _pumpVector(tester, vector, style: ink);
        expect(_emitted(tester), _expected(vector), reason: code);
        // … and on a solid face they stay off.
        _pumpVector(
          tester,
          vector,
          style: base.primary.codeSnippetStyle!.merge(ink),
        );
        expect(_emitted(tester), _expected(vector, roles: false), reason: code);
        expect(_spans(tester), isEmpty, reason: code);
      }
    });
  });

  group('syntax theme — roles, not colours', () {
    test('the shared theme is one instance and names only role sentinels', () {
      expect(
        identical(
          ResolvedCodeSnippet.syntaxTheme,
          ResolvedCodeSnippet.syntaxTheme,
        ),
        isTrue,
      );
      final scopes = ResolvedCodeSnippet.syntaxTheme.scopes;
      expect(scopes, isNotEmpty);
      for (final style in scopes.values) {
        final argb = style.foreground.argb;
        expect(argb >> 24, 0xFF);
        expect(
          argb & 0xFFFFFF,
          inInclusiveRange(1, CoreSyntaxRole.values.length),
        );
      }
    });
  });
}
