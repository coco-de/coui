// The code strings and the role names are the fixture data — naming each one
// would hide the text the assertion is about.

/// Highlighting of `CodeSnippet`: that each supported mode reaches the
/// rich-text branch, and what colour each span is painted in.
///
/// The colour half reads the painted `TextSpan` tree and compares it with the
/// scheme's own slots — the shared vector table
/// (`coui_core/test/fixtures/code_syntax_vectors.json`) says which role each
/// run of code takes, the scheme says what colour a role is, and nothing in
/// between is restated here. A theme that painted stock Dark+ colours, left a
/// span black, or let the highlighter's rainbow through on a bracket fails
/// here, in whichever mode it shows.
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';
import 'package:syntax_highlight_lite/syntax_highlight_lite.dart' as hl;

/// The shared vector table, relative to this package's root.
const _kVectorsPath = '../coui_core/test/fixtures/code_syntax_vectors.json';

/// A painted stretch of code and the colour it is drawn in.
typedef _Run = (String text, Color color);

/// The four shipped schemes the highlight is read under, each with the theme
/// data that carries it.
final _kModes = <String, ({CoreThemeData theme, CoreColorScheme scheme})>{
  'Light': (
    theme: CoreThemePresets.light,
    scheme: CoreThemePresets.lightColorScheme,
  ),
  'Dark': (
    theme: CoreThemePresets.dark,
    scheme: CoreThemePresets.darkColorScheme,
  ),
  'HCLight': (
    theme: CoreThemePresets.highContrastLight,
    scheme: CoreThemePresets.highContrastLightColorScheme,
  ),
  'HCDark': (
    theme: CoreThemePresets.highContrastDark,
    scheme: CoreThemePresets.highContrastDarkColorScheme,
  ),
};

/// The colour a scheme gives [token], as Flutter draws it.
Color _slot(CoreColorScheme scheme, CoreColorToken token) =>
    Color(token.read(scheme)!.argb);

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

/// The runs a vector expects under [scheme] — each role mapped to its colour
/// (plain to [ink], the snippet's own), adjacent runs of one colour joined
/// (punctuation and comment share a slot).
///
/// [roles] is whether the face admits the role colours; when it does not,
/// every run is the snippet's own ink.
List<_Run> _expected(
  Map<String, Object?> vector,
  CoreColorScheme scheme,
  Color ink, {
  bool roles = true,
}) {
  final out = <_Run>[];
  for (final run in (vector['runs']! as List).cast<List<Object?>>()) {
    final role = CoreSyntaxRole.values.byName(run[1]! as String);
    final token = role.token;
    final color = token == null || !roles ? ink : _slot(scheme, token);
    _append(out, run[0]! as String, color);
  }
  return out;
}

void _append(List<_Run> out, String text, Color color) {
  if (out.isNotEmpty && out.last.$2 == color) {
    out[out.length - 1] = (out.last.$1 + text, color);
  } else {
    out.add((text, color));
  }
}

/// The runs a painted tree draws: every text leaf with the colour it ends up
/// in (its own, else the nearest ancestor's), adjacent runs of one colour
/// joined.
List<_Run> _painted(TextSpan root) {
  final out = <_Run>[];
  void visit(TextSpan span, Color inherited) {
    final color = span.style?.color ?? inherited;
    if (span.text != null) _append(out, span.text!, color);
    for (final child in span.children ?? const <InlineSpan>[]) {
      if (child is TextSpan) visit(child, color);
    }
  }

  visit(root, root.style!.color!);
  return out;
}

TextSpan _paintedRoot(WidgetTester tester) {
  final text = tester.widget<material.SelectableText>(
    find.byType(material.SelectableText),
  );
  expect(
    text.textSpan,
    isNotNull,
    reason: 'must not stop at the plain-text fallback',
  );
  return text.textSpan!;
}

double _ratio(Color a, Color b) =>
    CoreContrast.ratio(CoreColor(a.toARGB32()), CoreColor(b.toARGB32()));

/// The title of a painted-by-face test: what the runs are drawn in.
String _paintedTitle(bool applied, String face, String mode) => applied
    ? '$face — runs are drawn in their role slots — $mode'
    : '$face — every run is drawn in the code ink — $mode';

Widget _snippet(
  String code,
  String mode, {
  CoreThemeData? theme,
  CoreCodeSnippetStyle? style,
  CoreCodeSnippetStyle? themeStyle,
}) {
  return material.MaterialApp(
    home: Theme(
      data: theme == null
          ? const ThemeData()
          : ThemeData.fromCore(
              theme,
              coreComponentTheme: themeStyle == null
                  ? null
                  : CoreComponentTheme(
                      codeSnippet: CoreCodeSnippetTheme(style: themeStyle),
                    ),
            ),
      child: CodeSnippet(
        code: code,
        mode: mode,
        showCopyButton: false,
        codeSnippetStyle: style,
      ),
    ),
  );
}

Future<void> _pumpSnippet(
  WidgetTester tester,
  String code,
  String mode, {
  CoreThemeData? theme,
  CoreCodeSnippetStyle? style,
  CoreCodeSnippetStyle? themeStyle,
}) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      _snippet(code, mode, theme: theme, style: style, themeStyle: themeStyle),
    );
    final builder = tester.widget<FutureBuilder<hl.Highlighter?>>(
      find.byType(FutureBuilder<hl.Highlighter?>),
    );
    await builder.future;
  });
  await tester.pumpAndSettle();
}

void main() {
  // The contract's table names the grammar; this package has to hold it. A
  // name with no asset behind it is a mode that throws while loading instead
  // of painting.
  test('every grammar the modes name, Dart aside, is a bundled asset', () {
    final grammars = _modes().values.nonNulls.toSet()..remove('dart');
    expect(grammars, isNotEmpty);
    for (final grammar in grammars) {
      expect(
        File('assets/syntax_grammars/$grammar.json').existsSync(),
        isTrue,
        reason: grammar,
      );
    }
  });

  // These examples must reach the rich-text branch, not just the plain-text
  // loading fallback. Lite embeds only Dart; the other grammars are assets.
  const examples = {
    'dart': 'final answer = 42;',
    'json': '{"answer": true}',
    'yaml': 'answer: "yes"',
    'sql': "SeLeCt 'yes', 42 FrOm questions;",
  };

  testWidgets('lite highlights supported modes, aliases and repeated use', (
    tester,
  ) async {
    for (final example in examples.entries) {
      await _pumpSnippet(tester, example.value, example.key);

      expect(
        find.byType(material.SelectableText),
        findsOneWidget,
        reason: '${example.key} must finish loading',
      );
      final text = tester.widget<material.SelectableText>(
        find.byType(material.SelectableText),
      );
      final span = text.textSpan;
      expect(
        span,
        isNotNull,
        reason: 'must not stop at the plain-text fallback',
      );
      expect(span!.toPlainText(), example.value);
      final colors = <Color>{};
      span.visitChildren((child) {
        final color = child.style?.color;
        if (color != null) colors.add(color);
        return true;
      });
      expect(colors.length, greaterThan(1), reason: example.key);
      expect(tester.takeException(), isNull);
    }
    await _pumpSnippet(tester, 'final first = 1;', 'dart');
    await _pumpSnippet(tester, 'const second = 2;', 'js');
    final highlighted = tester.widget<material.SelectableText>(
      find.byType(material.SelectableText),
    );
    expect(highlighted.textSpan?.toPlainText(), 'const second = 2;');

    await _pumpSnippet(tester, '<unknown>', 'unknown');
    final plain = tester.widget<material.SelectableText>(
      find.byType(material.SelectableText),
    );
    expect(plain.data, '<unknown>');
    expect(tester.takeException(), isNull);
  });

  // The same table Web reads: a mode it gives a grammar is painted, a mode it
  // gives none is shown as it is written.
  testWidgets('each mode of the shared table is painted or left plain', (
    tester,
  ) async {
    const code = 'answer: 42';
    for (final MapEntry(key: mode, value: grammar) in _modes().entries) {
      await _pumpSnippet(tester, code, mode);
      final text = tester.widget<material.SelectableText>(
        find.byType(material.SelectableText),
      );
      expect(
        text.textSpan != null,
        grammar != null,
        reason: 'mode ${jsonEncode(mode)}',
      );
      expect(
        text.textSpan?.toPlainText() ?? text.data,
        code,
        reason: 'mode ${jsonEncode(mode)}',
      );
      expect(tester.takeException(), isNull);
    }
  });

  group('painted span colours — the shared vectors, per mode', () {
    final vectors = _vectors();

    for (final MapEntry(key: modeName, value: mode) in _kModes.entries) {
      testWidgets("every run is drawn in its role's slot — $modeName", (
        tester,
      ) async {
        final ink = _slot(mode.scheme, CoreColors.onSurface);
        for (final vector in vectors) {
          final language = vector['mode']! as String;
          final code = vector['code']! as String;
          await _pumpSnippet(tester, code, language, theme: mode.theme);

          expect(
            _painted(_paintedRoot(tester)),
            _expected(vector, mode.scheme, ink),
            reason: '$language: $code',
          );
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets("no span is the highlighter's own rainbow", (
      tester,
    ) async {
      // Stock colours that must never reach the screen: the bracket rainbow
      // and its failed-bracket red. (The unthemed black default is not listed:
      // high-contrast light's `onSurface` is black. A span left unthemed is
      // caught by the per-mode vectors above, which expect each one's colour.)
      const stock = {
        0xFF5CAEEF,
        0xFFDFB976,
        0xFFC172D9,
        0xFF4FB1BC,
        0xFF97C26C,
        0xFFABB2C0,
        0xFFFF0000,
        // The Dark+ palette the snippet used to paint in every mode.
        0xFFD4D4D4,
        0xFF569CD6,
        0xFFCE9178,
        0xFFDCDCAA,
        0xFF4EC9B0,
        0xFFC586C0,
        0xFF6A9955,
        0xFF608B4E,
      };
      for (final mode in _kModes.values) {
        for (final vector in _vectors()) {
          await _pumpSnippet(
            tester,
            vector['code']! as String,
            vector['mode']! as String,
            theme: mode.theme,
          );
          for (final run in _painted(_paintedRoot(tester))) {
            expect(
              stock,
              isNot(contains(run.$2.toARGB32())),
              reason: '${run.$1} in ${vector['mode']}',
            );
          }
        }
      }
    });

    testWidgets('a theme change repaints the same highlighted snippet', (
      tester,
    ) async {
      // The theme names roles, not colours, so switching brightness under a
      // mounted snippet needs no new highlighter: the spans are converted on
      // the next build with the new scheme's slots.
      const code = 'final answer = 42; // note';
      await _pumpSnippet(tester, code, 'dart', theme: CoreThemePresets.light);
      final light = _painted(_paintedRoot(tester));

      await tester.pumpWidget(
        _snippet(code, 'dart', theme: CoreThemePresets.dark),
      );
      await tester.pump();
      final dark = _painted(_paintedRoot(tester));

      expect(dark.map((r) => r.$1), light.map((r) => r.$1));
      expect(
        dark.first.$2,
        _slot(CoreThemePresets.darkColorScheme, CoreColors.syntaxKeyword),
      );
      expect(
        light.first.$2,
        _slot(CoreThemePresets.lightColorScheme, CoreColors.syntaxKeyword),
      );
      expect(dark.first.$2, isNot(light.first.$2));
    });

    testWidgets('plain text follows a restated code colour, slots stay', (
      tester,
    ) async {
      // The code ink is the snippet's own (`codeTextStyle.color`); the syntax
      // slots are the scheme's. Restating the first moves plain text and
      // nothing else.
      const code = 'final answer = 42;';
      await tester.runAsync(() async {
        await tester.pumpWidget(
          material.MaterialApp(
            home: Theme(
              data: ThemeData.fromCore(CoreThemePresets.light),
              child: const CodeSnippet(
                code: code,
                mode: 'dart',
                showCopyButton: false,
                codeSnippetStyle: CoreCodeSnippetStyle(
                  codeTextStyle: CoreTextStyle(
                    color: CoreColor.token(CoreColors.onPrimary),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester
            .widget<FutureBuilder<hl.Highlighter?>>(
              find.byType(FutureBuilder<hl.Highlighter?>),
            )
            .future;
      });
      await tester.pumpAndSettle();

      final scheme = CoreThemePresets.lightColorScheme;
      expect(_painted(_paintedRoot(tester)), [
        ('final', _slot(scheme, CoreColors.syntaxKeyword)),
        (' answer ', _slot(scheme, CoreColors.onPrimary)),
        ('=', _slot(scheme, CoreColors.onSurfaceVariant)),
        (' ', _slot(scheme, CoreColors.onPrimary)),
        ('42', _slot(scheme, CoreColors.syntaxType)),
        (';', _slot(scheme, CoreColors.onSurfaceVariant)),
      ]);
    });
  });

  group('painted span colours — by face', () {
    // The role colours apply on a face the audit certifies them on and
    // nowhere else. On any other face every highlighted span paints in the
    // snippet's own ink — the painted tree, read run by run against the shared
    // vectors, in all four modes.
    final vectors = _vectors();

    // The faces the roles apply on: the default, and the two surface-tone
    // getters.
    final admitted =
        <String, ({CoreCodeSnippetStyle? style, CoreColorToken ink})>{
          'default face (surfaceContainerLow)': (
            style: null,
            ink: CoreColors.onSurface,
          ),
          '.surface': (
            style: const CodeSnippet(
              code: '',
              mode: 'dart',
            ).surface.codeSnippetStyle,
            ink: CoreColors.onSurface,
          ),
          '.surfaceContainer': (
            style: const CodeSnippet(
              code: '',
              mode: 'dart',
            ).surfaceContainer.codeSnippetStyle,
            ink: CoreColors.onSurface,
          ),
        };

    // The faces they do not: the eight solid role getters (each with its ink),
    // a raw colour, a token at 99% opacity, and the transparent getter.
    const base = CodeSnippet(code: '', mode: 'dart');
    final off = <String, ({CoreCodeSnippetStyle? style, CoreColorToken ink})>{
      'primary': (
        style: base.primary.codeSnippetStyle,
        ink: CoreColors.onPrimary,
      ),
      'secondary': (
        style: base.secondary.codeSnippetStyle,
        ink: CoreColors.onSecondary,
      ),
      'tertiary': (
        style: base.tertiary.codeSnippetStyle,
        ink: CoreColors.onTertiary,
      ),
      'error': (style: base.error.codeSnippetStyle, ink: CoreColors.onError),
      'success': (
        style: base.success.codeSnippetStyle,
        ink: CoreColors.onSuccess,
      ),
      'warning': (
        style: base.warning.codeSnippetStyle,
        ink: CoreColors.onWarning,
      ),
      'info': (style: base.info.codeSnippetStyle, ink: CoreColors.onInfo),
      'outline': (
        style: base.outline.codeSnippetStyle,
        ink: CoreColors.surface,
      ),
      'a raw colour': (
        style: const CoreCodeSnippetStyle(
          backgroundColor: CoreColor(0xFF1E2430),
        ),
        ink: CoreColors.onSurface,
      ),
      'a tone at 99% opacity': (
        style: const CoreCodeSnippetStyle(
          backgroundColor: CoreColor.token(
            CoreColors.surfaceContainerLow,
            opacity: 0.99,
          ),
        ),
        ink: CoreColors.onSurface,
      ),
      '.transparent': (
        style: base.transparent.codeSnippetStyle,
        ink: CoreColors.onSurface,
      ),
    };

    // The face a run is drawn on — the snippet's own tone, or the page for the
    // transparent getter, which shows it through. A raw colour has no tone to
    // name: the code ink on it is the caller's to make legible, so the
    // contrast is not measured there (`legible` is false) and only the colours
    // are pinned.
    Color faceOf(CoreColorScheme scheme, CoreCodeSnippetStyle? style) {
      final face =
          style?.backgroundColor ?? CoreCodeSnippetStyle.defaultBackgroundColor;
      return face.token == null
          ? _slot(scheme, CoreColors.surface)
          : _slot(scheme, face.token!);
    }

    const rawFaces = {'a raw colour'};

    void define(
      Map<String, ({CoreCodeSnippetStyle? style, CoreColorToken ink})> faces, {
      required bool roles,
    }) {
      for (final MapEntry(key: faceName, value: face) in faces.entries) {
        final legible = !rawFaces.contains(faceName);
        for (final MapEntry(key: modeName, value: mode) in _kModes.entries) {
          testWidgets(
            roles
                ? '$faceName — runs are drawn in their role slots, 4.5:1 — '
                      '$modeName'
                : '$faceName — every run is drawn in the code ink'
                      '${legible ? ', 4.5:1' : ''} — $modeName',
            (tester) async {
              final ink = _slot(mode.scheme, face.ink);
              final onFace = faceOf(mode.scheme, face.style);
              for (final vector in vectors) {
                final language = vector['mode']! as String;
                final code = vector['code']! as String;
                await _pumpSnippet(
                  tester,
                  code,
                  language,
                  theme: mode.theme,
                  style: face.style,
                );
                final painted = _painted(_paintedRoot(tester));
                expect(
                  painted,
                  _expected(vector, mode.scheme, ink, roles: roles),
                  reason: '$language: $code',
                );
                if (legible) {
                  for (final run in painted) {
                    expect(
                      _ratio(run.$2, onFace),
                      greaterThanOrEqualTo(4.5),
                      reason: '"${run.$1}" on $faceName in $modeName',
                    );
                  }
                }
                expect(tester.takeException(), isNull);
              }
            },
          );
        }
      }
    }

    define(admitted, roles: true);
    define(off, roles: false);

    // The face can come from the project theme instead of the instance: the
    // gate reads the merged style, so the painted spans follow it the same.
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
            CoreColorToken ink,
            bool roles,
          })
        >{
          'a solid face in the project theme': (
            themeStyle: solidTheme,
            style: null,
            ink: CoreColors.onPrimary,
            roles: false,
          ),
          'a tone in the project theme': (
            themeStyle: toneTheme,
            style: null,
            ink: CoreColors.onSurface,
            roles: true,
          ),
          'a solid theme face under an instance .surface': (
            themeStyle: solidTheme,
            style: base.surface.codeSnippetStyle,
            ink: CoreColors.onSurface,
            roles: true,
          ),
          'a tone theme face under an instance .error': (
            themeStyle: toneTheme,
            style: base.error.codeSnippetStyle,
            ink: CoreColors.onError,
            roles: false,
          ),
        };
    for (final MapEntry(key: faceName, value: face) in themed.entries) {
      for (final MapEntry(key: modeName, value: mode) in _kModes.entries) {
        testWidgets(
          _paintedTitle(face.roles, faceName, modeName),
          (tester) async {
            final ink = _slot(mode.scheme, face.ink);
            for (final vector in vectors) {
              await _pumpSnippet(
                tester,
                vector['code']! as String,
                vector['mode']! as String,
                theme: mode.theme,
                style: face.style,
                themeStyle: face.themeStyle,
              );
              expect(
                _painted(_paintedRoot(tester)),
                _expected(vector, mode.scheme, ink, roles: face.roles),
                reason: '${vector['mode']}: ${vector['code']}',
              );
              expect(tester.takeException(), isNull);
            }
          },
        );
      }
    }
  });

  group('syntax colours — the resolved side', () {
    Future<ResolvedCodeSnippet> resolveUnder(
      WidgetTester tester,
      CoreThemeData theme,
    ) async {
      late ResolvedCodeSnippet resolved;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: ThemeData.fromCore(theme),
            child: Builder(
              builder: (context) {
                resolved = resolveCodeSnippet(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      return resolved;
    }

    for (final MapEntry(key: modeName, value: mode) in _kModes.entries) {
      testWidgets('each role resolves to its slot — $modeName', (
        tester,
      ) async {
        final resolved = await resolveUnder(tester, mode.theme);
        for (final role in CoreSyntaxRole.values) {
          final token = role.token;
          if (token == null) {
            expect(resolved.syntaxColors, isNot(contains(role)));
            continue;
          }
          expect(
            resolved.syntaxColors[role],
            _slot(mode.scheme, token),
            reason: role.name,
          );
        }
      });
    }

    testWidgets('a bare bracket reads as punctuation, not the rainbow', (
      tester,
    ) async {
      final resolved = await resolveUnder(tester, CoreThemePresets.light);
      final punctuation = resolved.syntaxColors[CoreSyntaxRole.punctuation];

      // The highlighter's own bracket span: styled, scope-less, with text.
      final bracket = hl.TextSpan(
        text: '{',
        style: hl.TextStyle(foreground: const hl.Color(0xFF5CAEEF)),
      );
      expect(resolved.syntaxColorOf(bracket), punctuation);

      // The same style on a scoped span is not a bracket: it is left alone.
      final scoped = hl.TextSpan(
        text: 'x',
        style: hl.TextStyle(foreground: const hl.Color(0xFF5CAEEF)),
        scopes: ['meta.unknown'],
      );
      expect(resolved.syntaxColorOf(scoped), isNull);

      // Unstyled text, and the style-only root, inherit the code colour.
      expect(resolved.syntaxColorOf(hl.TextSpan(text: 'x')), isNull);
      expect(
        resolved.syntaxColorOf(
          hl.TextSpan(
            style: hl.TextStyle(foreground: const hl.Color(0xFF5CAEEF)),
          ),
        ),
        isNull,
      );
    });

    testWidgets('the theme is one shared instance and names no palette', (
      tester,
    ) async {
      expect(
        identical(
          ResolvedCodeSnippet.syntaxTheme,
          ResolvedCodeSnippet.syntaxTheme,
        ),
        isTrue,
      );
      // Every entry of the shared theme is a role sentinel (`0xFF00000N`) —
      // a state the palette could never have produced.
      final theme = ResolvedCodeSnippet.syntaxTheme;
      expect(theme.scopes, isNotEmpty);
      for (final style in theme.scopes.values) {
        final n = style.foreground.argb;
        expect(n >> 24, 0xFF);
        expect(n & 0xFFFFFF, inInclusiveRange(1, CoreSyntaxRole.values.length));
      }
    });
  });
}
