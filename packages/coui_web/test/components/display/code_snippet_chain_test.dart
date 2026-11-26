// The getter names and token names are the fixture data — naming each one
// would hide the pair the assertion is about.

/// The colour getters of `CodeSnippet` (`.primary`, `.error`, …): each patches
/// the face to a token and the code colour to the partner that reads on it —
/// the same patch as the Flutter twin, under the same names.
///
/// The code colour defaults to `onSurface`, which only reads on a surface
/// tone, so a getter that changed the face alone would leave unreadable code.
/// The pair is stated together, in one patch, so whichever getter comes last
/// owns the face and the code colour.
///
/// The line numbers and the copy glyph are not the getters' to state. The
/// resolver gives a solid role face's ink to both
/// (`CoreCodeSnippetStyle.inkOnFace`), so they follow the face the chain ends
/// on, in any order — a surface-tone getter after a solid one puts them back
/// on their defaults. Syntax highlighting is off on the eight solid role
/// faces (the role colours are not certified there); the surface-tone faces
/// keep it.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

const _kSnippet = CodeSnippet(code: 'x', mode: 'dart');

/// The face token and the code-colour token each getter states.
final _kPairs =
    <
      String,
      ({
        CodeSnippet Function(CodeSnippet) get,
        CoreColorToken face,
        CoreColorToken ink,
      })
    >{
      'primary': (
        get: (snippet) => snippet.primary,
        face: CoreColors.primary,
        ink: CoreColors.onPrimary,
      ),
      'secondary': (
        get: (snippet) => snippet.secondary,
        face: CoreColors.secondary,
        ink: CoreColors.onSecondary,
      ),
      'tertiary': (
        get: (snippet) => snippet.tertiary,
        face: CoreColors.tertiary,
        ink: CoreColors.onTertiary,
      ),
      'surface': (
        get: (snippet) => snippet.surface,
        face: CoreColors.surface,
        ink: CoreColors.onSurface,
      ),
      'surfaceContainer': (
        get: (snippet) => snippet.surfaceContainer,
        face: CoreColors.surfaceContainer,
        ink: CoreColors.onSurface,
      ),
      'error': (
        get: (snippet) => snippet.error,
        face: CoreColors.error,
        ink: CoreColors.onError,
      ),
      'success': (
        get: (snippet) => snippet.success,
        face: CoreColors.success,
        ink: CoreColors.onSuccess,
      ),
      'warning': (
        get: (snippet) => snippet.warning,
        face: CoreColors.warning,
        ink: CoreColors.onWarning,
      ),
      'info': (
        get: (snippet) => snippet.info,
        face: CoreColors.info,
        ink: CoreColors.onInfo,
      ),
      'outline': (
        get: (snippet) => snippet.outline,
        face: CoreColors.outline,
        ink: CoreColors.surface,
      ),
    };

/// The eight getters that paint a solid role fill.
const _kSolidFaces = [
  'primary',
  'secondary',
  'tertiary',
  'error',
  'success',
  'warning',
  'info',
  'outline',
];

/// The four shipped schemes the emitted names resolve against — what the
/// browser's `--coui-*` variables hold in each mode.
final _kModes = <String, CoreColorScheme>{
  'Light': CouiColorPresets.source.light().resolved(.light),
  'Dark': CouiColorPresets.source.dark().resolved(.dark),
  'HCLight': CouiColorPresets.source.highContrastLight().resolved(.light),
  'HCDark': CouiColorPresets.source.highContrastDark().resolved(.dark),
};

/// Every token the snippet can emit, by the CSS name the browser resolves.
final Map<String, CoreColorToken> _kTokensByName = {
  for (final token in <CoreColorToken>[
    CoreColors.onSurface,
    CoreColors.onSurfaceVariant,
    CoreColors.onErrorContainer,
    CoreColors.syntaxKeyword,
    CoreColors.syntaxType,
    CoreColors.syntaxFunction,
    CoreColors.syntaxString,
    CoreColors.onPrimary,
    CoreColors.onSecondary,
    CoreColors.onTertiary,
    CoreColors.onError,
    CoreColors.onSuccess,
    CoreColors.onWarning,
    CoreColors.onInfo,
    CoreColors.surface,
  ])
    token.name: token,
};

/// The token a `rgb(var(--coui-X))` reference names.
CoreColorToken _tokenOfVar(String css) {
  final name = RegExp('--coui-([a-z-]+)').firstMatch(css)!.group(1)!;
  return _kTokensByName[name] ??
      (throw StateError('no token named $name in $css'));
}

/// The token the one `text-X` colour class in [classes] names.
CoreColorToken _tokenOfClasses(String classes) {
  final tokens = [
    for (final name in classes.split(' '))
      if (name.startsWith('text-') &&
          _kTokensByName[name.substring('text-'.length)] != null)
        _kTokensByName[name.substring('text-'.length)]!,
  ];
  expect(tokens, hasLength(1), reason: classes);
  return tokens.single;
}

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

/// A build context under the default theme, optionally with a project-level
/// `CoreCodeSnippetTheme` installed so the merge chain runs the way the widget
/// runs it.
BuildContext _themedContext(
  ComponentTester tester, {
  CoreCodeSnippetStyle? themeStyle,
}) {
  late BuildContext context;
  tester.pumpComponent(
    Theme(
      data: themeStyle == null
          ? ThemeData.coui
          : ThemeData.coui.copyWith(
              coreComponentTheme: CoreComponentTheme(
                codeSnippet: CoreCodeSnippetTheme(style: themeStyle),
              ),
            ),
      child: _ContextCapture((c) => context = c),
    ),
  );
  return context;
}

/// The code colour token the snippet emits: the inline variable when the
/// ink is stated, else the default class on the content wrapper.
CoreColorToken _inkOf(ResolvedCodeSnippet resolved) {
  final color = resolved.contentWrapper.inlineStyles?.properties['color'];
  return color != null
      ? _tokenOfVar(color)
      : _tokenOfClasses(resolved.contentWrapper.className);
}

/// The gutter colour token the snippet emits.
CoreColorToken _gutterOf(ResolvedCodeSnippet resolved) =>
    _tokenOfClasses(resolved.lineNumber.className);

/// The plain variant the copy button is, whose foreground the glyph inherits
/// when its icon states none.
final CoreButtonVariantStyle _kPlain =
    CoreButtonStyle.defaultsByVariant[CoreButtonVariant.plain]!;

/// The token the copy glyph rests in: the one its icon states, else the copy
/// button's. `code_snippet_glyph_test.dart` reads the emitted markup.
CoreColorToken _glyphAtRest(ResolvedCodeSnippet resolved) =>
    resolved.iconStyle.color?.token ?? _kPlain.foregroundColor.token!;

/// The token the copy glyph takes on hover.
CoreColorToken _glyphOnHover(ResolvedCodeSnippet resolved) =>
    resolved.iconStyle.color?.token ?? _kPlain.hoverForegroundColor!.token!;

/// The face the code is drawn on in [scheme]: a token face is its own tone, a
/// raw colour is itself, and the transparent face is the page.
CoreColor _faceIn(CoreColorScheme scheme, CoreColor face) {
  if (face == CoreColor.transparent) {
    return CoreColors.surface.read(scheme)!;
  }
  return face.token?.read(scheme) ?? face;
}

double _ratioIn(
  CoreColorScheme scheme,
  CoreColorToken colour,
  CoreColor face,
) => CoreContrast.ratio(colour.read(scheme)!, _faceIn(scheme, face));

void main() {
  group('CodeSnippet colour getters — the face and its ink go together', () {
    for (final MapEntry(key: name, value: pair) in _kPairs.entries) {
      test('.$name states the face and the code colour in one patch', () {
        final style = pair.get(_kSnippet).codeSnippetStyle!;
        expect(style.backgroundColor, CoreColor.token(pair.face));
        expect(style.codeTextStyle?.color, CoreColor.token(pair.ink));
      });

      testComponents('.$name reaches the face and the emitted ink', (
        tester,
      ) async {
        final style = pair.get(_kSnippet).codeSnippetStyle;
        final resolved = resolveCodeSnippet(
          _themedContext(tester),
          lineCount: 1,
          codeSnippetStyle: style,
        );
        expect(
          resolved.containerStyle.backgroundColor,
          CoreColor.token(pair.face),
        );
        // A token ink replaces the default class with an inline variable.
        expect(
          resolved.contentWrapper.inlineStyles!.properties['color'],
          CoreColor.token(pair.ink).toValue(),
        );
      });
    }

    test('.transparent shows the page, so the code reads the page ink', () {
      final style = _kSnippet.transparent.codeSnippetStyle!;
      expect(style.backgroundColor, CoreColor.transparent);
      expect(
        style.codeTextStyle?.color,
        const CoreColor.token(CoreColors.onSurface),
      );
    });

    test('the last getter owns the face and the code colour', () {
      // `.primary.transparent` is not onPrimary code on the page.
      final transparentLast = _kSnippet.primary.transparent.codeSnippetStyle!;
      expect(transparentLast.backgroundColor, CoreColor.transparent);
      expect(
        transparentLast.codeTextStyle?.color,
        const CoreColor.token(CoreColors.onSurface),
      );
      final primaryLast = _kSnippet.transparent.primary.codeSnippetStyle!;
      expect(
        primaryLast.backgroundColor,
        const CoreColor.token(CoreColors.primary),
      );
      expect(
        primaryLast.codeTextStyle?.color,
        const CoreColor.token(CoreColors.onPrimary),
      );
    });

    test('a radius getter leaves the code colour alone', () {
      final style = _kSnippet.radius8.codeSnippetStyle!;
      expect(style.codeTextStyle, isNull);
      expect(style.backgroundColor, isNull);
    });
  });

  group('CodeSnippet colour getters — they state no gutter and no glyph', () {
    // The line numbers and the glyph are the resolver's: a getter that stated
    // them would leave its colour behind when a later getter changes the face.
    for (final MapEntry(key: name, value: pair) in _kPairs.entries) {
      test('.$name leaves the gutter and the glyph to the resolver', () {
        final style = pair.get(_kSnippet).codeSnippetStyle!;
        expect(style.lineNumberTextStyle, isNull);
        expect(style.copyIconStyle, isNull);
      });
    }

    test('.transparent leaves the gutter and the glyph to the resolver', () {
      final style = _kSnippet.transparent.codeSnippetStyle!;
      expect(style.lineNumberTextStyle, isNull);
      expect(style.copyIconStyle, isNull);
    });

    test('a radius getter leaves the gutter and the glyph alone', () {
      final style = _kSnippet.radius8.codeSnippetStyle!;
      expect(style.lineNumberTextStyle, isNull);
      expect(style.copyIconStyle, isNull);
    });

    test('the Core face → ink table is the eight solid getters, pair for '
        'pair', () {
      // The getters state the code colour with the face; the resolver states
      // the same ink on the gutter and the glyph from `solidFaceInks`. The two
      // cannot drift apart without this failing.
      expect(
        CoreCodeSnippetStyle.solidFaceInks,
        hasLength(_kSolidFaces.length),
      );
      for (final name in _kSolidFaces) {
        final pair = _kPairs[name]!;
        final style = pair.get(_kSnippet).codeSnippetStyle!;
        final listed = CoreCodeSnippetStyle.solidFaceInks.where(
          (entry) => entry.face == style.backgroundColor!.token,
        );
        expect(listed, hasLength(1), reason: name);
        expect(listed.single.face, pair.face, reason: name);
        expect(listed.single.ink, pair.ink, reason: name);
        expect(
          style.codeTextStyle!.color!.token,
          listed.single.ink,
          reason: '$name: the getter states the table ink on the code',
        );
      }
    });
  });

  group('CodeSnippet — the gutter and the glyph follow the face the chain '
      'ends on', () {
    // Every colour getter alone, and every pair of getters in both orders,
    // read the way the browser resolves the emitted names: the gutter class,
    // the glyph's own class or the button's, and the code ink, each against
    // the face the chain ends on. A solid role face puts its ink on all of
    // them; any other face leaves the gutter on `onSurfaceVariant` and the
    // glyph on the copy button's foreground.
    final everyGetter = {
      for (final name in _kSolidFaces) name: _kPairs[name]!,
      for (final name in ['surface', 'surfaceContainer']) name: _kPairs[name]!,
      'transparent': (
        get: (CodeSnippet snippet) => snippet.transparent,
        face: CoreColors.surface,
        ink: CoreColors.onSurface,
      ),
    };

    for (final MapEntry(key: modeName, value: scheme) in _kModes.entries) {
      testComponents('a solid getter alone puts its ink on the code, the '
          'gutter and the glyph — $modeName', (tester) async {
        for (final name in _kSolidFaces) {
          final pair = _kPairs[name]!;
          final resolved = resolveCodeSnippet(
            _themedContext(tester),
            lineCount: 1,
            codeSnippetStyle: pair.get(_kSnippet).codeSnippetStyle,
          );
          final face = resolved.containerStyle.backgroundColor!;
          expect(_inkOf(resolved), pair.ink, reason: '.$name code');
          expect(_gutterOf(resolved), pair.ink, reason: '.$name gutter');
          expect(
            resolved.iconStyle.color,
            CoreColor.token(pair.ink),
            reason: '.$name glyph',
          );
          expect(_glyphAtRest(resolved), pair.ink);
          expect(
            _glyphOnHover(resolved),
            pair.ink,
            reason: '.$name glyph keeps the ink on hover',
          );
          for (final entry in {
            'code': _inkOf(resolved),
            'gutter': _gutterOf(resolved),
            'glyph': _glyphAtRest(resolved),
          }.entries) {
            expect(
              _ratioIn(scheme, entry.value, face),
              greaterThanOrEqualTo(4.5),
              reason: '${entry.key} on .$name in $modeName',
            );
          }
        }
      });

      testComponents('two getters in either order read on the face they end '
          'on — $modeName', (tester) async {
        for (final MapEntry(key: first, value: a) in everyGetter.entries) {
          for (final MapEntry(key: second, value: b) in everyGetter.entries) {
            if (first == second) continue;
            final resolved = resolveCodeSnippet(
              _themedContext(tester),
              lineCount: 1,
              codeSnippetStyle: b.get(a.get(_kSnippet)).codeSnippetStyle,
            );
            final chain = '.$first.$second in $modeName';

            // The last getter owns the face and the code colour.
            expect(_inkOf(resolved), b.ink, reason: '$chain: code');
            // The gutter and the glyph follow that face.
            if (_kSolidFaces.contains(second)) {
              expect(_gutterOf(resolved), b.ink, reason: '$chain: gutter');
              expect(_glyphAtRest(resolved), b.ink, reason: '$chain: glyph');
              expect(
                _glyphOnHover(resolved),
                b.ink,
                reason: '$chain: glyph on hover',
              );
            } else {
              expect(
                _gutterOf(resolved),
                CoreColors.onSurfaceVariant,
                reason: '$chain: gutter back on its default',
              );
              expect(
                resolved.iconStyle.color,
                isNull,
                reason: '$chain: glyph follows the button again',
              );
              expect(
                _glyphAtRest(resolved),
                CoreColors.onSurfaceVariant,
                reason: '$chain: glyph at rest',
              );
              expect(
                _glyphOnHover(resolved),
                CoreColors.onSurface,
                reason: '$chain: glyph on hover',
              );
            }
            // And every text element reads on it.
            final face = resolved.containerStyle.backgroundColor!;
            for (final entry in {
              'code': _inkOf(resolved),
              'gutter': _gutterOf(resolved),
              'glyph at rest': _glyphAtRest(resolved),
              'glyph on hover': _glyphOnHover(resolved),
            }.entries) {
              expect(
                _ratioIn(scheme, entry.value, face),
                greaterThanOrEqualTo(4.5),
                reason: '${entry.key} of $chain',
              );
            }
          }
        }
      });
    }

    testComponents('a solid face stated without a getter still puts its ink '
        'on the gutter and the glyph', (tester) async {
      // `withStyle(backgroundColor: …)` states the face and not the code
      // colour, so the code stays `onSurface` — the caller's to state. The
      // gutter and the glyph are the resolver's, and read.
      final resolved = resolveCodeSnippet(
        _themedContext(tester),
        lineCount: 1,
        codeSnippetStyle: const CoreCodeSnippetStyle(
          backgroundColor: CoreColor.token(CoreColors.tertiary),
        ),
      );
      expect(_gutterOf(resolved), CoreColors.onTertiary);
      expect(_glyphAtRest(resolved), CoreColors.onTertiary);
      expect(_inkOf(resolved), CoreColors.onSurface);
    });

    for (final MapEntry(key: modeName, value: scheme) in _kModes.entries) {
      testComponents('the docs chain example instance (withStyle) reads — '
          '$modeName', (tester) async {
        // `withStyle(backgroundColor: tertiary, codeTextStyle: onTertiary, …)`
        // states the face and the code colour and nothing of the gutter or the
        // glyph; the resolver puts the face's ink on both.
        final resolved = resolveCodeSnippet(
          _themedContext(tester),
          lineCount: 3,
          codeSnippetStyle: const CoreCodeSnippetStyle(
            backgroundColor: CoreColor.token(CoreColors.tertiary),
            codeTextStyle: CoreTextStyle(
              color: CoreColor.token(CoreColors.onTertiary),
            ),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
            padding: CoreEdgeInsets.symmetric(
              horizontal: CoreSpace.space24,
              vertical: CoreSpace.space8,
            ),
          ),
        );
        final face = resolved.containerStyle.backgroundColor!;
        for (final entry in {
          'code': _inkOf(resolved),
          'gutter': _gutterOf(resolved),
          'glyph at rest': _glyphAtRest(resolved),
          'glyph on hover': _glyphOnHover(resolved),
        }.entries) {
          expect(
            _ratioIn(scheme, entry.value, face),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key} on tertiary in $modeName',
          );
        }
      });
    }

    testComponents('a colour the caller states on the gutter or the glyph '
        'wins over the face ink', (tester) async {
      final resolved = resolveCodeSnippet(
        _themedContext(tester),
        lineCount: 1,
        codeSnippetStyle: _kSnippet.primary
            .withStyle(
              const CoreCodeSnippetStyle(
                lineNumberTextStyle: CoreTextStyle(
                  color: CoreColor.token(CoreColors.onError),
                ),
                copyIconStyle: CoreIconStyle(
                  color: CoreColor.token(CoreColors.onSuccess),
                ),
              ),
            )
            .codeSnippetStyle,
      );
      expect(_gutterOf(resolved), CoreColors.onError);
      expect(
        resolved.iconStyle.color,
        const CoreColor.token(CoreColors.onSuccess),
      );
    });

    testComponents('a solid token at less than full opacity is not a solid '
        'face — the defaults stay', (tester) async {
      final resolved = resolveCodeSnippet(
        _themedContext(tester),
        lineCount: 1,
        codeSnippetStyle: const CoreCodeSnippetStyle(
          backgroundColor: CoreColor.token(CoreColors.primary, opacity: 0.5),
        ),
      );
      expect(_gutterOf(resolved), CoreColors.onSurfaceVariant);
      expect(resolved.iconStyle.color, isNull);
    });
  });

  group('CodeSnippet — a project theme states the face', () {
    // The face is read from the merged style, so a project-level
    // `CoreCodeSnippetTheme` decides everything an instance-level face does:
    // whether the role colours apply, and the ink of the gutter and the glyph.
    const solidTheme = CoreCodeSnippetStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
      codeTextStyle: CoreTextStyle(
        color: CoreColor.token(CoreColors.onPrimary),
      ),
    );

    /// Whether any role of [resolved] states a colour.
    bool highlights(ResolvedCodeSnippet resolved) => [
      for (final chrome in resolved.syntax) chrome.inlineStyles,
    ].any((styles) => styles != null);

    /// The roles that state a colour: all seven, or none.
    int roles(ResolvedCodeSnippet resolved) =>
        resolved.syntax.where((chrome) => chrome.inlineStyles != null).length;

    testComponents('a solid face in the theme turns highlighting off and inks '
        'the gutter and the glyph', (tester) async {
      final resolved = resolveCodeSnippet(
        _themedContext(tester, themeStyle: solidTheme),
        lineCount: 1,
      );
      expect(highlights(resolved), isFalse);
      expect(_inkOf(resolved), CoreColors.onPrimary);
      expect(_gutterOf(resolved), CoreColors.onPrimary);
      expect(_glyphAtRest(resolved), CoreColors.onPrimary);
      expect(_glyphOnHover(resolved), CoreColors.onPrimary);
    });

    testComponents('an admitted tone in the theme keeps highlighting', (
      tester,
    ) async {
      final resolved = resolveCodeSnippet(
        _themedContext(
          tester,
          themeStyle: const CoreCodeSnippetStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
          ),
        ),
        lineCount: 1,
      );
      expect(roles(resolved), 7);
      expect(resolved.iconStyle.color, isNull);
    });

    testComponents('an instance tone over a solid theme face brings the roles '
        'and the defaults back', (tester) async {
      final resolved = resolveCodeSnippet(
        _themedContext(tester, themeStyle: solidTheme),
        lineCount: 1,
        codeSnippetStyle: _kSnippet.surface.codeSnippetStyle,
      );
      expect(roles(resolved), 7);
      expect(resolved.iconStyle.color, isNull);
      expect(_gutterOf(resolved), CoreColors.onSurfaceVariant);
    });

    testComponents('an instance solid face over a tone theme face turns them '
        'off', (tester) async {
      final resolved = resolveCodeSnippet(
        _themedContext(
          tester,
          themeStyle: const CoreCodeSnippetStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
          ),
        ),
        lineCount: 1,
        codeSnippetStyle: _kSnippet.error.codeSnippetStyle,
      );
      expect(highlights(resolved), isFalse);
      expect(_gutterOf(resolved), CoreColors.onError);
      expect(_glyphAtRest(resolved), CoreColors.onError);
    });

    testComponents('a gutter or glyph colour in the theme wins over the face '
        'ink', (tester) async {
      final resolved = resolveCodeSnippet(
        _themedContext(
          tester,
          themeStyle: const CoreCodeSnippetStyle(
            lineNumberTextStyle: CoreTextStyle(
              color: CoreColor.token(CoreColors.onError),
            ),
            copyIconStyle: CoreIconStyle(
              color: CoreColor.token(CoreColors.onSuccess),
            ),
          ),
        ),
        lineCount: 1,
        codeSnippetStyle: _kSnippet.primary.codeSnippetStyle,
      );
      expect(_gutterOf(resolved), CoreColors.onError);
      expect(
        resolved.iconStyle.color,
        const CoreColor.token(CoreColors.onSuccess),
      );
    });

    testComponents('a code colour stated alone does not change the face rule', (
      tester,
    ) async {
      // An ink-only override leaves the face where it was: roles stay off on a
      // solid face and on on an admitted one.
      final onSolid = resolveCodeSnippet(
        _themedContext(tester),
        lineCount: 1,
        codeSnippetStyle: _kSnippet.primary
            .withStyle(
              const CoreCodeSnippetStyle(
                codeTextStyle: CoreTextStyle(
                  color: CoreColor.token(CoreColors.onError),
                ),
              ),
            )
            .codeSnippetStyle,
      );
      expect(highlights(onSolid), isFalse);
      expect(_inkOf(onSolid), CoreColors.onError);
      final onTone = resolveCodeSnippet(
        _themedContext(tester),
        lineCount: 1,
        codeSnippetStyle: const CoreCodeSnippetStyle(
          codeTextStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.onError),
          ),
        ),
      );
      expect(roles(onTone), 7);
    });
  });

  group('CodeSnippet faces — what every text element reads on its face', () {
    // Every colour the snippet emits, modelled the way the browser resolves
    // it: the emitted `--coui-X` reference or `text-X` class names a token,
    // and the token reads the scheme of the mode. The ink, the gutter, the
    // copy glyph and each role colour that remains are measured against the
    // face's own token.
    final highlightFaces = <String, CoreCodeSnippetStyle?>{
      'default face (surfaceContainerLow)': null,
      for (final name in ['surface', 'surfaceContainer'])
        '.$name': _kPairs[name]!.get(_kSnippet).codeSnippetStyle,
      for (final tone in CoreSyntaxFaces.tones)
        'tone ${tone.name}': CoreCodeSnippetStyle(
          backgroundColor: CoreColor.token(tone),
        ),
    };

    for (final MapEntry(key: faceName, value: style)
        in highlightFaces.entries) {
      for (final MapEntry(key: modeName, value: scheme) in _kModes.entries) {
        testComponents('$faceName — ink, gutter, glyph and all seven role '
            'colours read 4.5:1 — $modeName', (tester) async {
          final resolved = resolveCodeSnippet(
            _themedContext(tester),
            lineCount: 1,
            codeSnippetStyle: style,
          );
          final face = resolved.containerStyle.backgroundColor!;
          final colours = <String, CoreColorToken>{
            'ink': _inkOf(resolved),
            'gutter': _gutterOf(resolved),
            'glyph at rest': _glyphAtRest(resolved),
            'glyph on hover': _glyphOnHover(resolved),
            for (final role in CoreSyntaxRole.values)
              if (role.token != null)
                'role ${role.name}': _tokenOfVar(
                  resolved
                      .syntax[role.index]
                      .inlineStyles!
                      .properties['color']!,
                ),
          };
          expect(colours, hasLength(4 + 7));
          for (final MapEntry(key: what, value: colour) in colours.entries) {
            expect(
              _ratioIn(scheme, colour, face),
              greaterThanOrEqualTo(4.5),
              reason: '$what on $faceName in $modeName',
            );
          }
          expect(
            colours['gutter'],
            CoreColors.onSurfaceVariant,
            reason: 'the gutter keeps its default ink',
          );
        });
      }
    }

    for (final name in _kSolidFaces) {
      final pair = _kPairs[name]!;
      for (final MapEntry(key: modeName, value: scheme) in _kModes.entries) {
        testComponents('.$name — ink, gutter and glyph read 4.5:1, nothing '
            'else is coloured — $modeName', (tester) async {
          final resolved = resolveCodeSnippet(
            _themedContext(tester),
            lineCount: 1,
            codeSnippetStyle: pair.get(_kSnippet).codeSnippetStyle,
          );
          final face = resolved.containerStyle.backgroundColor!;
          for (final entry in {
            'ink': _inkOf(resolved),
            'gutter': _gutterOf(resolved),
            'glyph at rest': _glyphAtRest(resolved),
            'glyph on hover': _glyphOnHover(resolved),
          }.entries) {
            expect(entry.value, pair.ink, reason: '${entry.key} is the ink');
            expect(
              _ratioIn(scheme, entry.value, face),
              greaterThanOrEqualTo(4.5),
              reason: '${entry.key} on .$name in $modeName',
            );
          }
          for (final chrome in resolved.syntax) {
            expect(chrome.inlineStyles, isNull);
          }
        });
      }
    }

    // Faces the roles are not certified on, other than the eight getters.
    // Token faces (and the page behind `.transparent`) owe the 4.5:1 to the
    // ink, the gutter and the glyph at rest. A raw colour is the caller's to
    // make legible — the snippet cannot know it — so only the colours it
    // states are pinned, not their contrast.
    final offFaces = <String, ({CoreCodeSnippetStyle style, bool legible})>{
      'a raw colour': (
        style: const CoreCodeSnippetStyle(
          backgroundColor: CoreColor(0xFF1E2430),
        ),
        legible: false,
      ),
      'a tone at 99% opacity': (
        style: const CoreCodeSnippetStyle(
          backgroundColor: CoreColor.token(
            CoreColors.surfaceContainerLow,
            opacity: 0.99,
          ),
        ),
        legible: true,
      ),
      'a tone outside the audit list': (
        style: const CoreCodeSnippetStyle(
          backgroundColor: CoreColor.token(CoreColors.surfaceContainerHighest),
        ),
        legible: true,
      ),
      '.transparent': (
        style: _kSnippet.transparent.codeSnippetStyle!,
        legible: true,
      ),
    };
    for (final MapEntry(key: faceName, value: face) in offFaces.entries) {
      testComponents('$faceName — no span states a colour, the gutter and the '
          'glyph keep their defaults', (tester) async {
        final resolved = resolveCodeSnippet(
          _themedContext(tester),
          lineCount: 1,
          codeSnippetStyle: face.style,
        );
        for (final chrome in resolved.syntax) {
          expect(chrome.inlineStyles, isNull);
          expect(chrome.className, isEmpty);
        }
        expect(resolved.iconStyle.color, isNull);
        expect(_gutterOf(resolved), CoreColors.onSurfaceVariant);
      });

      if (!face.legible) continue;
      for (final MapEntry(key: modeName, value: scheme) in _kModes.entries) {
        testComponents('$faceName — ink, gutter and glyph read 4.5:1 — '
            '$modeName', (tester) async {
          final resolved = resolveCodeSnippet(
            _themedContext(tester),
            lineCount: 1,
            codeSnippetStyle: face.style,
          );
          final onFace = resolved.containerStyle.backgroundColor!;
          for (final entry in {
            'ink': _inkOf(resolved),
            'gutter': _gutterOf(resolved),
            'glyph at rest': _glyphAtRest(resolved),
          }.entries) {
            expect(
              _ratioIn(scheme, entry.value, onFace),
              greaterThanOrEqualTo(4.5),
              reason: '${entry.key} on $faceName in $modeName',
            );
          }
        });
      }
    }
  });
}
