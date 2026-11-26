import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

const String _kCardId = 'role-probe-card';

/// The classes the card's own box carries in the served markup.
///
/// Read off the rendered document rather than off the resolver, because
/// the Web half of this axis *is* a class on an element: a role that
/// resolves correctly and never reaches the class list changes nothing,
/// and only the markup can tell those two apart.
Future<String> _rootClasses(
  ServerTester tester,
  CoreSurfaceRole role,
) async {
  tester.pumpComponent(
    CoUIWeb(
      theme: .coui,
      child: Card(body: const Text('bio'), role: role, id: _kCardId),
    ),
  );
  final response = await tester.request('/');

  return response.document!.querySelector('#$_kCardId')!.className;
}

void main() {
  group('the role reaches the class the stylesheet keys on', () {
    testServer('a card in the page flow carries the content marker', (
      tester,
    ) async {
      final classes = (await _rootClasses(
        tester,
        .content,
      )).split(' ');

      expect(classes, contains(kWebSurfaceMarker));
      expect(classes, contains(kWebSurfaceRoleContent));
      expect(classes, isNot(contains(kWebSurfaceRoleFunctional)));
    });

    testServer('a card a host floats carries the floating marker', (
      tester,
    ) async {
      // The other half of the `hover_card` fix. Its Flutter twin reads the
      // painted alpha; here the material is a CSS rule scoped to this
      // class, so what has to be true is that the class changed.
      final classes = (await _rootClasses(
        tester,
        .functional,
      )).split(' ');

      expect(classes, contains(kWebSurfaceMarker));
      expect(classes, contains(kWebSurfaceRoleFunctional));
      expect(classes, isNot(contains(kWebSurfaceRoleContent)));
    });

    testServer('the base marker rides along with either role', (tester) async {
      // Dropping it for the role class would take the forced-colours
      // boundary correction with it — that rule is keyed on the base
      // marker, and nothing else in the sheet would match.
      for (final role in CoreSurfaceRole.values) {
        expect(
          (await _rootClasses(tester, role)).split(' '),
          contains(kWebSurfaceMarker),
        );
      }
    });
  });

  group('the other four presets cannot see a role at all', () {
    test('every role-keyed rule is scoped to the one style that has two', () {
      // The acceptance condition, on the side where a role is a class
      // rather than a value: this story flips `hover_card` from one role
      // class to the other, and the four non-glass presets must render
      // exactly as before. That is true iff no rule outside the glass
      // scope ever mentions a role class — checked here rather than
      // argued, because a future style could add one and nothing else
      // would notice until a screenshot moved.
      final sheet = ThemeConfig.defaults().surfaceStyleVariableBlocks;
      final glassScope =
          '[$kSurfaceStyleAttribute='
          '"${CoreSurfaceStyleId.liquidGlass.name}"]';

      final roleRules = sheet
          .split('}')
          .where(
            (rule) =>
                rule.contains(kWebSurfaceRoleContent) ||
                rule.contains(kWebSurfaceRoleFunctional),
          )
          .toList();

      expect(
        roleRules,
        isNotEmpty,
        reason: 'no role rules at all would make the check vacuous',
      );
      for (final rule in roleRules) {
        expect(
          rule,
          anyOf(contains(glassScope), contains('coui-material-liquidGlass')),
          reason:
              'a role-keyed rule outside the glass scope would make '
              'the role switch visible on a preset this story promised '
              'not to touch',
        );
      }
    });
  });
}
