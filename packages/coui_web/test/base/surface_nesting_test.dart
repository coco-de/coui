import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/theme_config.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:test/test.dart';

/// The sheet the page actually gets — a builder can return the right
/// rule while nothing calls it.
String get _sheet => ThemeConfig.defaults().surfaceStyleVariableBlocks;

String _scope(
  CoreSurfaceStyleId id, {
  required int depth,
  required String role,
}) {
  final ancestors = List.filled(depth, '.$kWebSurfaceMarker ').join();
  return '[data-coui-style="${id.name}"] $ancestors.$kWebSurfaceMarker.$role';
}

void main() {
  group('glass does not stack on glass', () {
    // Found by walking the rendered catalog rather than by reading code:
    // an item card inside the column card that holds it ran a second
    // backdrop pass over a surface that had already been blurred. Both
    // components are right to be surfaces — only the pair is wrong, and
    // only the cascade can see a pair.
    //
    // The rule used to be written here in the emitter. It is now the
    // recipe's nesting table, for a reason this file could not see: the
    // policy existed on the Web alone, so Flutter never had it and ran
    // the second pass at full strength — measured at two σ-16 filters,
    // composing to σ≈22.6 where the Web drew σ-16.
    // Both roles, because both are glass under this preset: a card in a
    // dialog and a menu in a dialog are the same situation. The loop is
    // what keeps a role from quietly regaining a second pass — a single
    // named role would leave the other unasserted.
    for (final role in const [
      kWebSurfaceRoleContent,
      kWebSurfaceRoleFunctional,
    ]) {
      test('a nested $role surface drops its backdrop pass', () {
        final scope = _scope(.liquidGlass, depth: 1, role: role);
        final at = _sheet.indexOf('$scope{');

        expect(at, greaterThan(-1), reason: 'no depth-1 rule for $role');
        expect(
          _sheet.substring(at, _sheet.indexOf('}', at) + 1),
          contains('backdrop-filter:none;'),
        );
      });

      test('and a nested $role surface keeps its fill and its band', () {
        // Deliberate: a nested surface still reads as translucent and
        // still draws its own edge. It just stops sampling through a
        // parent that already did.
        final scope = _scope(.liquidGlass, depth: 1, role: role);
        final at = _sheet.indexOf('$scope{');
        final rule = _sheet.substring(at, _sheet.indexOf('}', at) + 1);

        expect(rule, contains('background-color:'));
        expect(_sheet, contains('$scope::after'));
      });

      test('the base $role rule still blurs', () {
        // The half that proves the rule above is about *nesting* and not
        // about the style having quietly lost its material.
        final scope = _scope(.liquidGlass, depth: 0, role: role);
        final at = _sheet.indexOf('$scope{');

        expect(at, greaterThan(-1), reason: 'no base rule for $role');
        expect(
          _sheet.substring(at, _sheet.indexOf('}', at) + 1),
          contains('backdrop-filter:blur('),
        );
      });
    }

    test('depth outranks role, so the two axes cannot tie', () {
      // A nested rule spelled `.s .s` would be one attribute and two
      // classes — the same specificity as the floating role's base rule,
      // `.s.s-functional`. A floating panel inside a card would then take
      // whichever rule someone wrote first, which is the coincidence
      // `theme-axis-composition.md` names as the failure mode for two
      // axes meeting on one field.
      //
      // Both roles carrying a class is what makes the ladder strict.
      final baseFunctional = _scope(
        .liquidGlass,
        depth: 0,
        role: kWebSurfaceRoleFunctional,
      );
      final nestedContent = _scope(
        .liquidGlass,
        depth: 1,
        role: kWebSurfaceRoleContent,
      );

      expect(
        _classCount(nestedContent),
        greaterThan(_classCount(baseFunctional)),
      );
    });

    test('a preset with no material states no nesting rule', () {
      // Nothing to suppress, and a rule that turns off a filter nobody
      // set is noise in every sheet that carries it.
      expect(
        _sheet,
        isNot(
          contains(
            _scope(.neoBrutalism, depth: 1, role: kWebSurfaceRoleContent),
          ),
        ),
      );
    });

    test('the selector does not repeat the style scope', () {
      // `$scope $scope` was the first attempt and matched nothing: the
      // scope carries the `[data-coui-style]` attribute selector and
      // only the document element has that attribute, so it asked for a
      // second styled root inside the first. It emitted, it parsed, and
      // it was inert — the audit still reported the nesting.
      expect(
        _sheet,
        isNot(
          contains(
            '[data-coui-style="liquidGlass"] .$kWebSurfaceMarker '
            '[data-coui-style="liquidGlass"]',
          ),
        ),
      );
    });

    test('and the styles that state no material emit no material rule', () {
      // The Epic's standing claim — "비-유리 프리셋 4 개가 한 픽셀도 안
      // 바뀐다" — checked rather than asserted. Three axes landed on this
      // sheet (a dimming term, a role, a nesting depth) and none of them
      // may reach a style that never said it was a material.
      //
      // Counted by walking the sheet rather than matching one selector
      // shape, so a rule arriving in a spelling nobody predicted still
      // moves the number.
      for (final id in CoreSurfaceStyleId.values) {
        if (id == CoreSurfaceStyleId.liquidGlass) continue;

        final needle = '[data-coui-style="${id.name}"] ';
        final found = <String>[];
        var at = _sheet.indexOf(needle);
        while (at >= 0) {
          final selector = _sheet.substring(at, _sheet.indexOf('{', at));
          // The forced-colours boundary is not a material — it is the
          // a11y fallback every style owes, and it predates all of this.
          final forced = _sheet
              .substring(0, at)
              .endsWith('@media (forced-colors:active){');
          if (selector.contains(kWebSurfaceMarker) && !forced) {
            found.add(selector);
          }
          at = _sheet.indexOf(needle, at + 1);
        }

        expect(found, isEmpty, reason: '${id.name} grew a surface rule');
      }
    });
  });
}

/// Class-selector count — the middle term of CSS specificity.
int _classCount(String selector) => '.'.allMatches(selector).length;
