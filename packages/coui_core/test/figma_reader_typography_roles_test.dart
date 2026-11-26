// The role table `components.json` carries at its root — what the Figma
// builder draws a role-only text style at.
//
// The table is read from source, not from the running constant, so a role
// written in a shape the reader cannot follow comes out `null` and the
// canvas falls back to a default without a sound. Each role is therefore
// compared with the value `CoreTypography.coui` actually holds, field by
// field: a disagreement here is a role the canvas would draw wrong.
//
// The code roles are the case that motivated two of the fields. Their family
// (`CoreFontFamily.mono`) and their fixed line box (`CoreLineBox.px21`) are
// not token namespaces, so a reader that resolved only through the token
// table returned `null` for both and the builder drew mono code in the text
// face on a multiplier line.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

import '../bin/figma_reader/emit.dart';
import '../bin/figma_reader/repo_reader.dart';
import '../bin/figma_reader/style_reader.dart';
import '../bin/figma_reader/token_scale.dart';
import '../bin/figma_reader/typography_roles.dart';

void main() {
  group('readTypographyRoles — against the real scale', () {
    late Map<String, RoleMetrics> roles;

    setUpAll(() {
      final repo = readContracts(
        repoRoot: '.',
        contractsRoot: 'lib/src/component/contracts',
        referenceRoot: 'lib/src',
      );
      final ctx = EmitContext(
        tokenScale: resolveNamespaces(repoRoot: '.', srcRoot: 'lib/src'),
        classRegistry: repo.resolutionRegistry,
      );
      roles = readTypographyRoles(srcRoot: 'lib/src', ctx: ctx);
    });

    String camelOf(String kebab) => kebab.replaceAllMapped(
      RegExp('-([a-z0-9])'),
      (m) => m[1]!.toUpperCase(),
    );

    test('one entry per role, in scale order', () {
      expect(roles.keys.toList(), [
        for (final t in CoreTextStyles.values) camelOf(t.name),
      ]);
      expect(roles, hasLength(22));
    });

    test('every field equals what CoreTypography.coui holds', () {
      for (final token in CoreTextStyles.values) {
        final role = token.read(CoreTypography.coui);
        final read = roles[camelOf(token.name)]!;
        expect(
          read.toJson(),
          {
            'fontSize': role.fontSize,
            'lineHeight': role.lineHeight,
            'fontWeight': role.fontWeight,
            'letterSpacing': role.letterSpacing,
            'fontFamily': role.fontFamily,
            'lineHeightPx': role.lineHeightPx,
          },
          reason: token.name,
        );
      }
    });

    test('a code role names its family and its box, not a multiplier', () {
      expect(roles['codeSm']!.toJson(), {
        'fontSize': 12.0,
        'lineHeight': null,
        'fontWeight': 400,
        'letterSpacing': 0.0,
        'fontFamily': 'Geist Mono',
        'lineHeightPx': 21.0,
      });
    });

    test('a text role names neither, and keeps its multiplier', () {
      expect(roles['bodyMedium']!.toJson(), {
        'fontSize': 14.0,
        'lineHeight': 1.5,
        'fontWeight': 400,
        'letterSpacing': -0.01,
        'fontFamily': null,
        'lineHeightPx': null,
      });
      expect(roles['headlineLarge']!.fontWeight, 700);
      expect(roles['labelXs']!.fontSize, 11.0);
    });
  });

  // A component that states a box on its own text style must not lose it on
  // the way to the canvas — the same "keeps every field" property the role
  // table needs, on the per-component text leaf. Fixture, because no
  // component states one today.
  test('a component text leaf keeps a stated line box (fixture)', () {
    final classes = readCompilationUnit('test.dart', '''
      abstract final class CoreLineBox {
        static const px21 = 21.0;
      }
      @immutable
      class CoreFooStyle implements CoreStyle<CoreFooStyle> {
        const CoreFooStyle({this.labelStyle});
        final CoreTextStyle? labelStyle;
        static const CoreTextStyle defaultLabelStyle =
            CoreTextStyle(lineHeightPx: CoreLineBox.px21);
      }
    ''')!;
    final registry = {for (final c in classes) c.name: c};
    final value = registry['CoreFooStyle']!.staticMembers
        .singleWhere((m) => m.name == 'defaultLabelStyle')
        .value;

    final leaf = emitText(
      EmitContext(tokenScale: const {}, classRegistry: registry),
      value,
      currentClass: 'CoreFooStyle',
    );

    expect(leaf, {'role': null, 'lineHeightPx': 21.0});
  });
}
