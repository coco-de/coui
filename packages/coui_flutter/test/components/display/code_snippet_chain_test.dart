// The getter names and token names are the fixture data — naming each one
// would hide the pair the assertion is about.

/// The colour getters of `CodeSnippet` (`.primary`, `.error`, …): each patches
/// the face to a token and the code colour to the partner that reads on it.
///
/// The code colour defaults to `onSurface`, which only reads on a surface
/// tone, so a getter that changed the face alone would leave unreadable code
/// (`.primary` is near-white in dark — `onSurface` on it is 1:1). The pair is
/// stated together, in one patch, so whichever getter comes last owns the
/// face and the code colour.
///
/// The line numbers and the copy glyph are not the getters' to state. The
/// resolver gives a solid role face's ink to both
/// (`CoreCodeSnippetStyle.inkOnFace`), so they follow the face the chain ends
/// on, in any order — a surface-tone getter after a solid one puts them back
/// on their defaults. Syntax highlighting is off on the eight solid role
/// faces (the role colours are not certified there); the surface-tone faces
/// keep it.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

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

final _kModes = <String, CoreThemeData>{
  'Light': CoreThemePresets.light,
  'Dark': CoreThemePresets.dark,
  'HCLight': CoreThemePresets.highContrastLight,
  'HCDark': CoreThemePresets.highContrastDark,
};

/// Everything the snippet resolves under [core]: the resolved output, the
/// scheme its tokens read, and the face the code is drawn on.
///
/// [themeStyle] installs a project-level `CoreCodeSnippetTheme`, so the merge
/// chain runs the way the widget runs it.
Future<({ResolvedCodeSnippet resolved, ColorScheme scheme, Color face})>
_resolvedIn(
  WidgetTester tester,
  CoreThemeData core,
  CoreCodeSnippetStyle? style, {
  CoreCodeSnippetStyle? themeStyle,
}) async {
  late ResolvedCodeSnippet resolved;
  late ColorScheme scheme;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: ThemeData.fromCore(
          core,
          coreComponentTheme: themeStyle == null
              ? null
              : CoreComponentTheme(
                  codeSnippet: CoreCodeSnippetTheme(style: themeStyle),
                ),
        ),
        child: Builder(
          builder: (context) {
            scheme = Theme.of(context).colorScheme;
            resolved = resolveCodeSnippet(context, codeSnippetStyle: style);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return (
    resolved: resolved,
    scheme: scheme,
    face: _faceOf(scheme, resolved.containerStyle.backgroundColor!),
  );
}

/// The colour the code is drawn on: a token face is its own tone (opaque — a
/// token laid over at 99% is read as the tone), a raw colour is itself, and
/// the transparent face is the page it shows through.
Color _faceOf(ColorScheme scheme, CoreColor face) {
  if (face == CoreColor.transparent) {
    return scheme.resolve(const CoreColor.token(CoreColors.surface)).toValue();
  }
  final token = face.token;
  return scheme
      .resolve(token == null ? face : CoreColor.token(token))
      .toValue();
}

double _ratio(Color a, Color b) =>
    CoreContrast.ratio(CoreColor(a.toARGB32()), CoreColor(b.toARGB32()));

/// The plain variant the copy button is, whose foreground the glyph inherits
/// when its icon states none.
final CoreButtonVariantStyle _kPlain =
    CoreButtonStyle.defaultsByVariant[CoreButtonVariant.plain]!;

/// The colour the copy glyph rests in: the one its icon states, else the
/// copy button's. `code_snippet_glyph_test.dart` reads it off the mounted tree.
Color _glyphAtRest(ResolvedCodeSnippet resolved, ColorScheme scheme) => scheme
    .resolve(resolved.copyIconStyle.color ?? _kPlain.foregroundColor)
    .toValue();

/// The colour the copy glyph takes on hover.
Color _glyphOnHover(ResolvedCodeSnippet resolved, ColorScheme scheme) => scheme
    .resolve(resolved.copyIconStyle.color ?? _kPlain.hoverForegroundColor!)
    .toValue();

/// The colour [token] resolves to in [scheme].
Color _slot(ColorScheme scheme, CoreColorToken token) =>
    scheme.resolve(CoreColor.token(token)).toValue();

void main() {
  group('CodeSnippet colour getters — the face and its ink go together', () {
    for (final MapEntry(key: name, value: pair) in _kPairs.entries) {
      test('.$name states the face and the code colour in one patch', () {
        final style = pair.get(_kSnippet).codeSnippetStyle!;
        expect(style.backgroundColor, CoreColor.token(pair.face));
        expect(style.codeTextStyle?.color, CoreColor.token(pair.ink));
      });

      for (final MapEntry(key: modeName, value: core) in _kModes.entries) {
        testWidgets('.$name reads 4.5:1 on its face — $modeName', (
          tester,
        ) async {
          final painted = await _resolvedIn(
            tester,
            core,
            pair.get(_kSnippet).codeSnippetStyle,
          );
          expect(
            _ratio(painted.resolved.codeStyle.color!, painted.face),
            greaterThanOrEqualTo(4.5),
          );
        });
      }
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

    testWidgets('the unpaired default would not read: onSurface on .primary', (
      tester,
    ) async {
      // What the pair prevents, measured: the default ink on a getter face.
      final painted = await _resolvedIn(
        tester,
        CoreThemePresets.dark,
        const CoreCodeSnippetStyle(
          backgroundColor: CoreColor.token(CoreColors.primary),
        ),
      );
      expect(
        _ratio(painted.resolved.codeStyle.color!, painted.face),
        lessThan(1.5),
      );
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
    // read the way Flutter paints them: the gutter colour, the glyph colour at
    // rest and on hover, and the code ink, each against the face the chain
    // ends on. A solid role face puts its ink on all of them; any other face
    // leaves the gutter on `onSurfaceVariant` and the glyph on the copy
    // button's foreground.
    final everyGetter = {
      for (final name in _kSolidFaces) name: _kPairs[name]!,
      for (final name in ['surface', 'surfaceContainer']) name: _kPairs[name]!,
      'transparent': (
        get: (CodeSnippet snippet) => snippet.transparent,
        face: CoreColors.surface,
        ink: CoreColors.onSurface,
      ),
    };

    for (final MapEntry(key: modeName, value: core) in _kModes.entries) {
      testWidgets('a solid getter alone puts its ink on the code, the gutter '
          'and the glyph — $modeName', (tester) async {
        for (final name in _kSolidFaces) {
          final pair = _kPairs[name]!;
          final painted = await _resolvedIn(
            tester,
            core,
            pair.get(_kSnippet).codeSnippetStyle,
          );
          final resolved = painted.resolved;
          final ink = _slot(painted.scheme, pair.ink);
          expect(resolved.codeStyle.color, ink, reason: '.$name code');
          expect(resolved.lineNumberStyle.color, ink, reason: '.$name gutter');
          expect(
            resolved.copyIconStyle.color,
            CoreColor.token(pair.ink),
            reason: '.$name glyph',
          );
          expect(_glyphAtRest(resolved, painted.scheme), ink);
          expect(
            _glyphOnHover(resolved, painted.scheme),
            ink,
            reason: '.$name glyph keeps the ink on hover',
          );
          for (final entry in {
            'code': ink,
            'gutter': resolved.lineNumberStyle.color!,
            'glyph': _glyphAtRest(resolved, painted.scheme),
          }.entries) {
            expect(
              _ratio(entry.value, painted.face),
              greaterThanOrEqualTo(4.5),
              reason: '${entry.key} on .$name in $modeName',
            );
          }
        }
      });

      testWidgets('two getters in either order read on the face they end on '
          '— $modeName', (tester) async {
        for (final MapEntry(key: first, value: a) in everyGetter.entries) {
          for (final MapEntry(key: second, value: b) in everyGetter.entries) {
            if (first == second) continue;
            final style = b.get(a.get(_kSnippet)).codeSnippetStyle;
            final painted = await _resolvedIn(tester, core, style);
            final resolved = painted.resolved;
            final scheme = painted.scheme;
            final chain = '.$first.$second in $modeName';
            final ink = _slot(scheme, b.ink);

            // The last getter owns the face and the code colour.
            expect(resolved.codeStyle.color, ink, reason: '$chain: code');
            // The gutter and the glyph follow that face.
            if (_kSolidFaces.contains(second)) {
              expect(
                resolved.lineNumberStyle.color,
                ink,
                reason: '$chain: gutter',
              );
              expect(
                _glyphAtRest(resolved, scheme),
                ink,
                reason: '$chain: glyph',
              );
              expect(
                _glyphOnHover(resolved, scheme),
                ink,
                reason: '$chain: glyph on hover',
              );
            } else {
              expect(
                resolved.lineNumberStyle.color,
                _slot(scheme, CoreColors.onSurfaceVariant),
                reason: '$chain: gutter back on its default',
              );
              expect(
                resolved.copyIconStyle.color,
                isNull,
                reason: '$chain: glyph follows the button again',
              );
              expect(
                _glyphAtRest(resolved, scheme),
                _slot(scheme, CoreColors.onSurfaceVariant),
                reason: '$chain: glyph at rest',
              );
              expect(
                _glyphOnHover(resolved, scheme),
                _slot(scheme, CoreColors.onSurface),
                reason: '$chain: glyph on hover',
              );
            }
            // And every text element reads on it.
            for (final entry in {
              'code': resolved.codeStyle.color!,
              'gutter': resolved.lineNumberStyle.color!,
              'glyph at rest': _glyphAtRest(resolved, scheme),
              'glyph on hover': _glyphOnHover(resolved, scheme),
            }.entries) {
              expect(
                _ratio(entry.value, painted.face),
                greaterThanOrEqualTo(4.5),
                reason: '${entry.key} of $chain',
              );
            }
          }
        }
      });
    }

    testWidgets('a solid face stated without a getter still puts its ink on '
        'the gutter and the glyph', (tester) async {
      // `withStyle(backgroundColor: …)` states the face and not the code
      // colour, so the code stays `onSurface` — the caller's to state. The
      // gutter and the glyph are the resolver's, and read.
      final painted = await _resolvedIn(
        tester,
        CoreThemePresets.dark,
        const CoreCodeSnippetStyle(
          backgroundColor: CoreColor.token(CoreColors.tertiary),
        ),
      );
      final ink = _slot(painted.scheme, CoreColors.onTertiary);
      expect(painted.resolved.lineNumberStyle.color, ink);
      expect(_glyphAtRest(painted.resolved, painted.scheme), ink);
      expect(
        painted.resolved.codeStyle.color,
        _slot(painted.scheme, CoreColors.onSurface),
      );
    });

    for (final MapEntry(key: modeName, value: core) in _kModes.entries) {
      testWidgets('the docs chain example instance (withStyle) reads — '
          '$modeName', (tester) async {
        // `withStyle(backgroundColor: tertiary, codeTextStyle: onTertiary, …)`
        // states the face and the code colour and nothing of the gutter or the
        // glyph; the resolver puts the face's ink on both.
        final painted = await _resolvedIn(
          tester,
          core,
          const CoreCodeSnippetStyle(
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
        final resolved = painted.resolved;
        for (final entry in {
          'code': resolved.codeStyle.color!,
          'gutter': resolved.lineNumberStyle.color!,
          'glyph at rest': _glyphAtRest(resolved, painted.scheme),
          'glyph on hover': _glyphOnHover(resolved, painted.scheme),
        }.entries) {
          expect(
            _ratio(entry.value, painted.face),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key} on tertiary in $modeName',
          );
        }
      });
    }

    testWidgets('a colour the caller states on the gutter or the glyph wins '
        'over the face ink', (tester) async {
      final painted = await _resolvedIn(
        tester,
        CoreThemePresets.light,
        _kSnippet.primary
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
      expect(
        painted.resolved.lineNumberStyle.color,
        _slot(painted.scheme, CoreColors.onError),
      );
      expect(
        painted.resolved.copyIconStyle.color,
        const CoreColor.token(CoreColors.onSuccess),
      );
    });

    testWidgets('a solid token at less than full opacity is not a solid face '
        '— the defaults stay', (tester) async {
      final painted = await _resolvedIn(
        tester,
        CoreThemePresets.light,
        const CoreCodeSnippetStyle(
          backgroundColor: CoreColor.token(CoreColors.primary, opacity: 0.5),
        ),
      );
      expect(
        painted.resolved.lineNumberStyle.color,
        _slot(painted.scheme, CoreColors.onSurfaceVariant),
      );
      expect(painted.resolved.copyIconStyle.color, isNull);
    });

    test('inkOnFace states the ink on the gutter, the glyph and the copy '
        "button's focus ring, and nothing else", () {
      final style = CoreCodeSnippetStyle.inkOnFace(
        const CoreColor.token(CoreColors.error),
      )!;
      expect(
        style,
        const CoreCodeSnippetStyle(
          lineNumberTextStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.onError),
          ),
          copyButtonStyle: CoreButtonStyle(
            focusOutlineStyle: CoreFocusOutlineStyle(
              borderColor: CoreColor.token(CoreColors.onError),
            ),
          ),
          copyIconStyle: CoreIconStyle(
            color: CoreColor.token(CoreColors.onError),
          ),
        ),
      );
      for (final face in [
        const CoreColor.token(CoreColors.surfaceContainerLow),
        const CoreColor.token(CoreColors.primaryContainer),
        const CoreColor(0xFF1E2430),
        CoreColor.transparent,
        const CoreColor.token(CoreColors.primary, opacity: 0.99),
      ]) {
        expect(CoreCodeSnippetStyle.inkOnFace(face), isNull);
      }
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
    final sevenRoles = unorderedEquals([
      for (final role in CoreSyntaxRole.values)
        if (role.token != null) role,
    ]);

    for (final MapEntry(key: modeName, value: core) in _kModes.entries) {
      testWidgets('a solid face in the theme turns highlighting off and inks '
          'the gutter and the glyph — $modeName', (tester) async {
        final painted = await _resolvedIn(
          tester,
          core,
          null,
          themeStyle: solidTheme,
        );
        final ink = _slot(painted.scheme, CoreColors.onPrimary);
        expect(painted.resolved.syntaxColors, isEmpty);
        expect(painted.resolved.codeStyle.color, ink);
        expect(painted.resolved.lineNumberStyle.color, ink);
        expect(_glyphAtRest(painted.resolved, painted.scheme), ink);
        expect(_glyphOnHover(painted.resolved, painted.scheme), ink);
      });

      testWidgets('an admitted tone in the theme keeps highlighting — '
          '$modeName', (tester) async {
        final painted = await _resolvedIn(
          tester,
          core,
          null,
          themeStyle: const CoreCodeSnippetStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainerHigh),
          ),
        );
        expect(painted.resolved.syntaxColors.keys, sevenRoles);
        expect(painted.resolved.copyIconStyle.color, isNull);
      });

      testWidgets('an instance tone over a solid theme face brings the roles '
          'and the defaults back — $modeName', (tester) async {
        final painted = await _resolvedIn(
          tester,
          core,
          _kSnippet.surface.codeSnippetStyle,
          themeStyle: solidTheme,
        );
        expect(painted.resolved.syntaxColors.keys, sevenRoles);
        expect(painted.resolved.copyIconStyle.color, isNull);
        expect(
          painted.resolved.lineNumberStyle.color,
          _slot(painted.scheme, CoreColors.onSurfaceVariant),
        );
      });

      testWidgets('an instance solid face over a tone theme face turns them '
          'off — $modeName', (tester) async {
        final painted = await _resolvedIn(
          tester,
          core,
          _kSnippet.error.codeSnippetStyle,
          themeStyle: const CoreCodeSnippetStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
          ),
        );
        expect(painted.resolved.syntaxColors, isEmpty);
        final ink = _slot(painted.scheme, CoreColors.onError);
        expect(painted.resolved.lineNumberStyle.color, ink);
        expect(_glyphAtRest(painted.resolved, painted.scheme), ink);
      });

      testWidgets('a gutter or glyph colour in the theme wins over the face '
          'ink — $modeName', (tester) async {
        final painted = await _resolvedIn(
          tester,
          core,
          _kSnippet.primary.codeSnippetStyle,
          themeStyle: const CoreCodeSnippetStyle(
            lineNumberTextStyle: CoreTextStyle(
              color: CoreColor.token(CoreColors.onError),
            ),
            copyIconStyle: CoreIconStyle(
              color: CoreColor.token(CoreColors.onSuccess),
            ),
          ),
        );
        expect(
          painted.resolved.lineNumberStyle.color,
          _slot(painted.scheme, CoreColors.onError),
        );
        expect(
          painted.resolved.copyIconStyle.color,
          const CoreColor.token(CoreColors.onSuccess),
        );
      });
    }

    testWidgets('a code colour stated alone does not change the face rule', (
      tester,
    ) async {
      // An ink-only override leaves the face where it was: roles stay off on a
      // solid face and on on an admitted one.
      final onSolid = await _resolvedIn(
        tester,
        CoreThemePresets.light,
        _kSnippet.primary
            .withStyle(
              const CoreCodeSnippetStyle(
                codeTextStyle: CoreTextStyle(
                  color: CoreColor.token(CoreColors.onError),
                ),
              ),
            )
            .codeSnippetStyle,
      );
      expect(onSolid.resolved.syntaxColors, isEmpty);
      expect(
        onSolid.resolved.codeStyle.color,
        _slot(onSolid.scheme, CoreColors.onError),
      );
      final onTone = await _resolvedIn(
        tester,
        CoreThemePresets.light,
        const CoreCodeSnippetStyle(
          codeTextStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.onError),
          ),
        ),
      );
      expect(onTone.resolved.syntaxColors.keys, sevenRoles);
    });
  });

  group('CodeSnippet faces — what every text element reads on its face', () {
    // Every text element a snippet paints, measured on the colours Flutter
    // resolves: the code ink, the gutter, the copy glyph at rest and on hover,
    // and each role colour that remains. The glyph is read off the mounted
    // button in `code_snippet_glyph_test.dart`, where its colour comes from.
    //
    // Where the roles apply (an admitted tone) the seven role colours are
    // separate slots and each is measured; where they do not (a solid role
    // fill, a raw colour, a token with opacity) the map is empty and the
    // spans paint in the code ink.
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
      for (final MapEntry(key: modeName, value: core) in _kModes.entries) {
        testWidgets('$faceName — gutter, ink, glyph and all seven role colours '
            'read 4.5:1 — $modeName', (tester) async {
          final painted = await _resolvedIn(tester, core, style);
          final resolved = painted.resolved;
          expect(
            resolved.syntaxColors.keys,
            unorderedEquals([
              for (final role in CoreSyntaxRole.values)
                if (role.token != null) role,
            ]),
          );
          final colours = {
            'ink': resolved.codeStyle.color!,
            'gutter': resolved.lineNumberStyle.color!,
            'glyph at rest': _glyphAtRest(resolved, painted.scheme),
            'glyph on hover': _glyphOnHover(resolved, painted.scheme),
            for (final MapEntry(key: role, value: colour)
                in resolved.syntaxColors.entries)
              'role ${role.name}': colour,
          };
          expect(colours, hasLength(4 + 7));
          for (final MapEntry(key: what, value: colour) in colours.entries) {
            expect(
              _ratio(colour, painted.face),
              greaterThanOrEqualTo(4.5),
              reason: '$what on $faceName in $modeName',
            );
          }
          // Each role colour is its own slot, not the ink.
          for (final MapEntry(key: role, value: colour)
              in resolved.syntaxColors.entries) {
            expect(
              colour,
              _slot(painted.scheme, role.token!),
              reason: role.name,
            );
          }
        });
      }
    }

    for (final name in _kSolidFaces) {
      final pair = _kPairs[name]!;
      for (final MapEntry(key: modeName, value: core) in _kModes.entries) {
        testWidgets('.$name — one ink for the code, the gutter and the glyph, '
            'highlighting off — $modeName', (tester) async {
          final painted = await _resolvedIn(
            tester,
            core,
            pair.get(_kSnippet).codeSnippetStyle,
          );
          final resolved = painted.resolved;
          final ink = _slot(painted.scheme, pair.ink);
          expect(resolved.codeStyle.color, ink);
          expect(resolved.lineNumberStyle.color, ink);
          expect(
            painted.scheme.resolve(resolved.copyIconStyle.color!).toValue(),
            ink,
          );
          // Highlighting off: no role resolves, so every highlighted span
          // inherits the ink.
          expect(resolved.syntaxColors, isEmpty);
          for (final entry in {
            'ink': resolved.codeStyle.color!,
            'gutter': resolved.lineNumberStyle.color!,
            'glyph at rest': _glyphAtRest(resolved, painted.scheme),
            'glyph on hover': _glyphOnHover(resolved, painted.scheme),
          }.entries) {
            expect(
              _ratio(entry.value, painted.face),
              greaterThanOrEqualTo(4.5),
              reason: '${entry.key} on .$name in $modeName',
            );
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
      for (final MapEntry(key: modeName, value: core) in _kModes.entries) {
        testWidgets(
          '$faceName — highlighting off, spans read the code ink, the gutter '
          'and the glyph keep their defaults — $modeName',
          (tester) async {
            final painted = await _resolvedIn(tester, core, face.style);
            final resolved = painted.resolved;
            expect(resolved.syntaxColors, isEmpty);
            final inkToken =
                face.style.codeTextStyle?.color ??
                CoreCodeSnippetStyle.defaultCodeTextStyle.color!;
            expect(
              resolved.codeStyle.color,
              painted.scheme.resolve(inkToken).toValue(),
            );
            expect(
              resolved.lineNumberStyle.color,
              _slot(painted.scheme, CoreColors.onSurfaceVariant),
            );
            expect(resolved.copyIconStyle.color, isNull);
            if (face.legible) {
              for (final entry in {
                'ink': resolved.codeStyle.color!,
                'gutter': resolved.lineNumberStyle.color!,
                'glyph at rest': _glyphAtRest(resolved, painted.scheme),
              }.entries) {
                expect(
                  _ratio(entry.value, painted.face),
                  greaterThanOrEqualTo(4.5),
                  reason: '${entry.key} on $faceName in $modeName',
                );
              }
            }
          },
        );
      }
    }
  });
}
