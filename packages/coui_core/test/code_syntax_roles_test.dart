// The scope names below are the fixture data — naming each one would hide the
// scope the assertion is about.

/// The syntax role table: which scope is which role, which slot each role
/// reads, and what the result measures on the faces code is shown on.
///
/// The table is the one place a scope becomes a colour; Flutter and Web both
/// read it. These tests pin it without a highlighter (the platform tests run
/// the real highlighter against the shared vectors), so the lookup the
/// highlighter performs is restated here as a small reference.
library;

import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

/// The highlighter's lookup, restated: for each scope of a span from the
/// outermost in, the most specific dotted prefix that has a key wins, and the
/// first scope with any hit decides; no hit is [CoreSyntaxRole.plain].
CoreSyntaxRole _roleFor(List<String> scopes) {
  for (final scope in scopes) {
    final parts = scope.split('.');
    for (var length = parts.length; length > 0; length--) {
      final role = CoreSyntaxScopes.roles[parts.sublist(0, length).join('.')];
      if (role != null) return role;
    }
  }
  return CoreSyntaxRole.plain;
}

/// Every scope the four bundled grammars (Dart, JSON, YAML, SQL) emit, with
/// the role it takes. Written out by hand from the grammars, not derived from
/// the table, so a key that moved shows up here.
const _kObserved = <String, CoreSyntaxRole>{
  // Dart
  'comment.line.double-slash.dart': .comment,
  'comment.block.documentation.dart': .comment,
  'comment.block.dart': .comment,
  'constant.language.dart': .keyword,
  'constant.numeric.dart': .type,
  'constant.character.escape.dart': .string,
  'entity.name.function.dart': .function,
  'keyword.control.dart': .keyword,
  'keyword.control.catch-exception.dart': .keyword,
  'keyword.declaration.dart': .keyword,
  'keyword.cast.dart': .keyword,
  'keyword.other.import.dart': .keyword,
  'keyword.operator.assignment.dart': .punctuation,
  'keyword.operator.logical.dart': .punctuation,
  'keyword.operator.closure.dart': .punctuation,
  'storage.modifier.dart': .keyword,
  'storage.type.primitive.dart': .keyword,
  'storage.type.annotation.dart': .keyword,
  'string.interpolated.single.dart': .string,
  'string.quoted.double.dart': .string,
  'support.class.dart': .type,
  'variable.language.dart': .keyword,
  'variable.parameter.dart': .plain,
  'punctuation.terminator.dart': .punctuation,
  'punctuation.comma.dart': .punctuation,
  'punctuation.dot.dart': .punctuation,
  'other.source.dart': .punctuation,
  'invalid.string.newline': .invalid,
  // JSON
  'support.type.property-name.json': .function,
  'string.quoted.double.json': .string,
  'constant.language.json': .keyword,
  'constant.numeric.json': .type,
  'invalid.illegal.expected-dictionary-separator.json': .type,
  'invalid.illegal.expected-array-separator.json': .type,
  'invalid.illegal.unrecognized-string-escape.json': .invalid,
  'punctuation.definition.dictionary.begin.json': .punctuation,
  'punctuation.separator.dictionary.pair.json': .punctuation,
  'comment.line.double-slash.js': .comment,
  // YAML
  'entity.name.tag.yaml': .function,
  'string.quoted.double.yaml': .string,
  'comment.line.number-sign.yaml': .comment,
  'punctuation.separator.key-value.yaml': .punctuation,
  // SQL
  'keyword.other.sql.postgres': .keyword,
  'keyword.other.postgres': .keyword,
  'keyword.control.postgres': .keyword,
  'keyword.operator.postgres': .punctuation,
  'support.function.builtin.postgres': .function,
  'entity.name.function.postgres': .function,
  'entity.name.type.postgres': .type,
  'storage.type.postgres': .keyword,
  'string.quoted.single.postgres': .string,
  'constant.numeric.postgres': .type,
  'constant.language.postgres': .keyword,
  'comment.line.double-dash.postgres': .comment,
  'variable.other.postgres': .plain,
};

void main() {
  group('CoreSyntaxRole — which slot each role reads', () {
    test("plain reads no slot — it is the snippet's own ink", () {
      expect(CoreSyntaxRole.plain.token, isNull);
    });

    test('keyword, type, function and string read the syntax slots', () {
      expect(CoreSyntaxRole.keyword.token, CoreColors.syntaxKeyword);
      expect(CoreSyntaxRole.type.token, CoreColors.syntaxType);
      expect(CoreSyntaxRole.function.token, CoreColors.syntaxFunction);
      expect(CoreSyntaxRole.string.token, CoreColors.syntaxString);
    });

    test('punctuation and comment read onSurfaceVariant, as two roles', () {
      // onSurfaceSubtle is the quieter tier but measures 4.45:1 on the face
      // in light, under the 4.5 code text owes — so the comment reads the
      // variant tier until a slot of its own clears the bar.
      expect(CoreSyntaxRole.punctuation.token, CoreColors.onSurfaceVariant);
      expect(CoreSyntaxRole.comment.token, CoreColors.onSurfaceVariant);
      expect(CoreSyntaxRole.punctuation, isNot(CoreSyntaxRole.comment));
    });

    test('invalid reads onErrorContainer — error is 4.47:1 on the face', () {
      expect(CoreSyntaxRole.invalid.token, CoreColors.onErrorContainer);
    });
  });

  group('CoreSyntaxScopes — the table', () {
    test('every role names at least one scope', () {
      for (final role in CoreSyntaxRole.values) {
        expect(
          CoreSyntaxScopes.scopesOf(role),
          isNotEmpty,
          reason: role.name,
        );
      }
    });

    test('scopesOf covers the whole table exactly once', () {
      final all = [
        for (final role in CoreSyntaxRole.values)
          ...CoreSyntaxScopes.scopesOf(role),
      ];
      expect(all.toSet(), CoreSyntaxScopes.roles.keys.toSet());
      expect(all.length, CoreSyntaxScopes.roles.length);
    });

    test('there are no broad keys', () {
      // A key on a wrapper scope would win (outermost first) over the scope
      // inside it and paint the wrong thing.
      const broad = {
        'meta',
        'source',
        'other',
        'entity',
        'entity.name',
        'support',
        'constant',
        'scalar',
      };
      expect(CoreSyntaxScopes.roles.keys.toSet().intersection(broad), isEmpty);
    });

    test('a more specific key overrides its parent where they differ', () {
      const overrides = {
        'keyword.operator': ('keyword', CoreSyntaxRole.punctuation),
        'variable.language': ('variable', CoreSyntaxRole.keyword),
        'support.type.property-name': ('support.type', CoreSyntaxRole.function),
        'invalid.illegal.expected-array-separator': (
          'invalid',
          CoreSyntaxRole.type,
        ),
        'invalid.illegal.expected-dictionary-separator': (
          'invalid',
          CoreSyntaxRole.type,
        ),
      };
      for (final MapEntry(key: child, value: (parent, role))
          in overrides.entries) {
        expect(CoreSyntaxScopes.roles[child], role, reason: child);
        expect(CoreSyntaxScopes.roles[parent], isNot(role), reason: parent);
      }
    });

    test('an outer scope wins over the scope it holds', () {
      // A string stays one colour through an interpolation; a comment through
      // the identifiers in it.
      expect(
        _roleFor([
          'string.interpolated.single.dart',
          'string.interpolated.expression.dart',
          'variable.parameter.dart',
        ]),
        CoreSyntaxRole.string,
      );
      expect(
        _roleFor(['comment.block.documentation.dart', 'variable.name.source']),
        CoreSyntaxRole.comment,
      );
    });

    test('a wrapper scope falls through to the scope inside it', () {
      expect(
        _roleFor([
          'meta.declaration.dart',
          'keyword.other.import.dart',
        ]),
        CoreSyntaxRole.keyword,
      );
      expect(
        _roleFor([
          'meta.structure.dictionary.json',
          'meta.structure.dictionary.value.json',
          'invalid.illegal.expected-dictionary-separator.json',
        ]),
        CoreSyntaxRole.type,
        reason: 'a JSON number is scoped as an error by the bundled grammar',
      );
    });

    test('a scope nothing names is plain', () {
      expect(_roleFor(['meta.preprocessor.script.dart']), CoreSyntaxRole.plain);
      expect(_roleFor(const []), CoreSyntaxRole.plain);
    });

    for (final MapEntry(key: scope, value: role) in _kObserved.entries) {
      test('$scope is ${role.name}', () {
        expect(_roleFor([scope]), role);
      });
    }
  });

  group(
    'CoreSyntaxRole — what the roles measure on the faces code sits on',
    () {
      // 4.5:1 is what code text owes. The faces are the page and the container
      // rung the block sits on by default, in all four modes.
      final modes = <String, CoreColorScheme>{
        'Light': CouiColorPresets.source.light().resolved(.light),
        'Dark': CouiColorPresets.source.dark().resolved(.dark),
        'HCLight': CouiColorPresets.source.highContrastLight().resolved(.light),
        'HCDark': CouiColorPresets.source.highContrastDark().resolved(.dark),
      };
      final faces = <String, CoreColorToken>{
        'surface': CoreColors.surface,
        'surfaceContainerLow': CoreColors.surfaceContainerLow,
      };

      for (final MapEntry(key: mode, value: scheme) in modes.entries) {
        for (final MapEntry(key: faceName, value: faceToken) in faces.entries) {
          for (final role in CoreSyntaxRole.values) {
            final token = role.token;
            if (token == null) continue;
            test('${role.name} on $faceName, $mode', () {
              expect(
                CoreContrast.ratio(
                  token.read(scheme)!,
                  faceToken.read(scheme)!,
                ),
                greaterThanOrEqualTo(4.5),
              );
            });
          }
        }
      }
    },
  );

  group('CoreSyntaxFaces — which faces the role colours apply on', () {
    // The solid role fills a caller can state as a face. None is a tone the
    // audit certifies the syntax slots on.
    const solidFaces = <CoreColorToken>[
      CoreColors.primary,
      CoreColors.secondary,
      CoreColors.tertiary,
      CoreColors.error,
      CoreColors.success,
      CoreColors.warning,
      CoreColors.info,
      CoreColors.outline,
    ];
    // Tones that look like surfaces but are not in the audit's list.
    const otherSurfaces = <CoreColorToken>[
      CoreColors.surfaceContainerLowest,
      CoreColors.surfaceContainerHighest,
      CoreColors.surfaceDim,
      CoreColors.surfaceBright,
      CoreColors.inverseSurface,
      CoreColors.primaryContainer,
    ];

    String kebab(String camel) => camel.replaceAllMapped(
      RegExp('[A-Z]'),
      (match) => '-${match.group(0)!.toLowerCase()}',
    );

    test('the admitted tones are the tones the contrast audit certifies the '
        'syntax slots on', () {
      // The audit (`tool/check_contrast.dart`) states its tones as strings, so
      // the list is read from its source: a tone added to one and not the
      // other fails here instead of drifting.
      final source = File('tool/check_contrast.dart').readAsStringSync();
      final body = RegExp(
        r'const _kSyntaxTones = \[(.*?)\];',
        dotAll: true,
      ).firstMatch(source)!.group(1)!;
      final audited = [
        for (final match in RegExp(r"'(\w+)'").allMatches(body))
          kebab(match.group(1)!),
      ];
      expect(audited, hasLength(8));
      expect(
        CoreSyntaxFaces.tones.map((tone) => tone.name),
        unorderedEquals(audited),
      );
      expect(
        CoreSyntaxFaces.tones.toSet(),
        hasLength(CoreSyntaxFaces.tones.length),
        reason: 'no tone is listed twice',
      );
    });

    test('a plain, opaque token of an admitted tone admits the roles', () {
      for (final tone in CoreSyntaxFaces.tones) {
        expect(
          CoreSyntaxFaces.admits(CoreColor.token(tone)),
          isTrue,
          reason: tone.name,
        );
      }
    });

    test('the default face and the surface getter faces are admitted', () {
      expect(
        CoreSyntaxFaces.admits(CoreCodeSnippetStyle.defaultBackgroundColor),
        isTrue,
      );
      expect(
        CoreSyntaxFaces.admits(const CoreColor.token(CoreColors.surface)),
        isTrue,
      );
      expect(
        CoreSyntaxFaces.admits(
          const CoreColor.token(CoreColors.surfaceContainer),
        ),
        isTrue,
      );
    });

    test('a solid role fill does not admit them', () {
      for (final solid in solidFaces) {
        expect(
          CoreSyntaxFaces.admits(CoreColor.token(solid)),
          isFalse,
          reason: solid.name,
        );
      }
    });

    test('a tone outside the audit list does not admit them', () {
      for (final tone in otherSurfaces) {
        expect(
          CoreSyntaxFaces.admits(CoreColor.token(tone)),
          isFalse,
          reason: tone.name,
        );
      }
    });

    test('a token at less than full opacity does not admit them', () {
      // What shows through a translucent face is unknown, so nothing
      // certifies the slots on it.
      for (final tone in CoreSyntaxFaces.tones) {
        expect(
          CoreSyntaxFaces.admits(CoreColor.token(tone, opacity: 0.99)),
          isFalse,
          reason: tone.name,
        );
        expect(
          CoreSyntaxFaces.admits(CoreColor.token(tone, opacity: 0)),
          isFalse,
          reason: tone.name,
        );
      }
    });

    test('a raw colour does not admit them, whatever its value', () {
      // Identity, not value: a raw colour that happens to equal an admitted
      // tone's ARGB is still a raw colour.
      final scheme = CouiColorPresets.source.light().resolved(.light);
      final surface = CoreColors.surface.read(scheme)!;
      expect(CoreSyntaxFaces.admits(CoreColor(surface.argb)), isFalse);
      expect(CoreSyntaxFaces.admits(CoreColor.transparent), isFalse);
      expect(CoreSyntaxFaces.admits(const CoreColor(0xFFFFFFFF)), isFalse);
    });

    final modes = <String, CoreColorScheme>{
      'Light': CouiColorPresets.source.light().resolved(.light),
      'Dark': CouiColorPresets.source.dark().resolved(.dark),
      'HCLight': CouiColorPresets.source.highContrastLight().resolved(.light),
      'HCDark': CouiColorPresets.source.highContrastDark().resolved(.dark),
    };

    for (final MapEntry(key: mode, value: scheme) in modes.entries) {
      for (final tone in CoreSyntaxFaces.tones) {
        final face = tone.read(scheme)!;
        for (final role in CoreSyntaxRole.values) {
          // `plain` reads the snippet's own ink — `onSurface` by default.
          final token = role.token ?? CoreColors.onSurface;
          test('${role.name} on ${tone.name}, $mode', () {
            expect(
              CoreContrast.ratio(token.read(scheme)!, face),
              greaterThanOrEqualTo(4.5),
            );
          });
        }
      }
    }

    test('every solid role fill fails the bar somewhere — the reason it is '
        'not admitted', () {
      // The rule's other half: a solid face would be admitted if the slots
      // read on it. For each, some role slot in some mode is under 4.5:1.
      for (final solid in solidFaces) {
        var worst = double.infinity;
        for (final scheme in modes.values) {
          final face = solid.read(scheme)!;
          for (final role in CoreSyntaxRole.values) {
            final token = role.token;
            if (token == null) continue;
            final ratio = CoreContrast.ratio(token.read(scheme)!, face);
            if (ratio < worst) worst = ratio;
          }
        }
        expect(worst, lessThan(4.5), reason: solid.name);
      }
    });
  });

  group('the shared vectors', () {
    final doc =
        jsonDecode(
              File('test/fixtures/code_syntax_vectors.json').readAsStringSync(),
            )
            as Map<String, Object?>;
    final vectors = (doc['vectors']! as List).cast<Map<String, Object?>>();
    final modes = (doc['modes']! as Map).cast<String, String?>();

    test('the table is not empty and covers every language', () {
      expect(vectors, isNotEmpty);
      expect(
        vectors.map((v) => v['mode']).toSet(),
        {'dart', 'json', 'yaml', 'sql'},
      );
    });

    // Which grammar a mode runs is one table for both platforms. The fixture
    // states it by hand, so a spelling added to or dropped from the contract
    // shows up here rather than as one platform painting what the other
    // leaves plain.
    for (final MapEntry(key: mode, value: grammar) in modes.entries) {
      test('mode ${jsonEncode(mode)} runs ${grammar ?? 'no grammar'}', () {
        expect(CoreCodeSnippetContract.grammarOf(mode), grammar);
      });
    }

    test('every grammar is a mode of its own name', () {
      for (final grammar in modes.values.nonNulls.toSet()) {
        expect(CoreCodeSnippetContract.grammarOf(grammar), grammar);
      }
    });

    test('the vectors cover exactly the grammars the modes name', () {
      expect(
        vectors.map((v) => v['mode']).toSet(),
        modes.values.nonNulls.toSet(),
      );
    });

    test('every run names a role, and the runs spell the code', () {
      final roleNames = {for (final r in CoreSyntaxRole.values) r.name};
      for (final vector in vectors) {
        final runs = (vector['runs']! as List).cast<List<Object?>>();
        expect(
          runs.map((run) => run[0]).join(),
          vector['code'],
          reason: 'runs of ${vector['code']}',
        );
        for (final run in runs) {
          expect(roleNames, contains(run[1]), reason: '${run[0]}');
        }
      }
    });

    test('no two adjacent runs share a role (runs are maximal)', () {
      for (final vector in vectors) {
        final runs = (vector['runs']! as List).cast<List<Object?>>();
        for (var i = 1; i < runs.length; i++) {
          expect(
            runs[i][1],
            isNot(runs[i - 1][1]),
            reason: '${runs[i - 1][0]} | ${runs[i][0]}',
          );
        }
      }
    });
  });
}
