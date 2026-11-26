import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/infra/outlined_container/outlined_container_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveCard` / `resolveOutlinedContainer` directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester, {ThemeData? theme}) {
  late BuildContext context;
  final capture = _ContextCapture((c) => context = c);
  if (theme == null) {
    pumpWithTheme(tester, capture);
  } else {
    tester.pumpComponent(Theme(data: theme, child: capture));
  }
  return context;
}

Set<String> _classes(WebElementChrome chrome) =>
    chrome.className.split(' ').where((c) => c.isNotEmpty).toSet();

/// Every rule of [css] whose declarations paint a material (a blur, a
/// translucent restated fill, an edge band), as `selector -> body`.
///
/// A flat split on `{`/`}` is enough for the preset blocks the theme emits —
/// they nest only inside `@media`, which the walk flattens by treating the
/// at-rule header as a prefix to ignore.
Map<String, String> _materialRules(String css) {
  final rules = <String, String>{};
  final pattern = RegExp(r'([^{}]+)\{([^{}]*)\}');
  for (final match in pattern.allMatches(css)) {
    final selector = match.group(1)!.trim();
    final body = match.group(2)!;
    final paints =
        body.contains('backdrop-filter:blur') ||
        body.contains('background-color:rgb(var(--coui-surface-rgb)') ||
        selector.contains('::after') ||
        selector.contains('::before');
    if (paints) rules[selector] = body;
  }
  return rules;
}

/// Whether a rule with [selector] could match an element carrying exactly
/// [classes], reading only the class names of the selector's last compound.
///
/// Deliberately over-approximate: attribute, pseudo-class and ancestor
/// conditions can only make a selector match *less*, so a rule that fails
/// even this test certainly does not reach the element.
bool _mightMatch(String selector, Set<String> classes) {
  // `@media (...){:root ... .x{}}` leaves the at-rule header glued to the
  // first selector; keep what follows the last `)` of a header.
  for (final alternative in selector.split(',')) {
    final compounds = alternative
        .replaceAll(RegExp(r'\([^)]*\)'), ' ')
        .split(RegExp(r'[\s>+~]+'))
        .where((c) => c.isNotEmpty);
    if (compounds.isEmpty) continue;
    final last = compounds.last.split('::').first.split(':').first;
    final needed = RegExp(
      r'\.([A-Za-z0-9_-]+)',
    ).allMatches(last).map((m) => m.group(1)!);
    if (needed.every(classes.contains)) return true;
  }
  return false;
}

void main() {
  testComponents(
    'menu popup carries local material and explicit command icons',
    (tester) async {
      pumpWithTheme(
        tester,
        const Menu(
          menuStyle: CoreMenuStyle(
            popupStyle: CorePopupStyle(surfaceStyle: .liquidGlass),
          ),
          items: [CoreMenuItem<Component>.action('복사', standardAction: .copy)],
        ),
      );
      final roots = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .where(
            (e) => e.classes?.contains('coui-material-liquidGlass') ?? false,
          );
      expect(roots, hasLength(1));
      expect(roots.single.attributes!['role'], 'menu');
      final icons = find
          .byType(Icon)
          .evaluate()
          .map((e) => e.component as Icon);
      expect(icons.any((icon) => icon.icon == LucideIcons.copy), isTrue);
    },
  );

  testComponents(
    'toolbar group exposes group semantics and omits empty surface',
    (tester) async {
      pumpWithTheme(
        tester,
        const ToolbarGroup(
          ariaLabel: 'History',
          popupStyle: CorePopupStyle(surfaceStyle: .liquidGlass),
          children: [
            Text('Undo'),
            ToolbarGroup(ariaLabel: 'Empty', children: []),
          ],
        ),
      );
      final roots = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .where((e) => e.attributes?['role'] == 'group');
      expect(roots, hasLength(1));
      expect(roots.single.attributes!['aria-label'], 'History');
      expect(roots.single.classes, contains('coui-material-liquidGlass'));
    },
  );

  testComponents('an instance can remove a component theme glass material', (
    tester,
  ) async {
    tester.pumpComponent(
      Theme(
        data: const ThemeData(
          coreComponentTheme: CoreComponentTheme(
            appBar: CoreAppBarTheme(
              style: CoreAppBarStyle(surfaceStyle: .liquidGlass),
            ),
          ),
        ),
        child: const AppBar(
          title: Text('Title'),
          appBarStyle: CoreAppBarStyle(surfaceStyle: .defaultStyle),
        ),
      ),
    );
    final roots = find
        .byType(DomComponent)
        .evaluate()
        .map((e) => e.component as DomComponent)
        .where(
          (e) => e.classes?.contains('coui-material-defaultStyle') ?? false,
        );
    expect(roots, hasLength(1));
    expect(roots.single.classes!.split(' '), isNot(contains('coui-surface')));
    expect(roots.single.styles!.properties, contains('--coui-surface-rgb'));
  });

  testComponents('navigation material reaches its own surface root', (
    tester,
  ) async {
    pumpWithTheme(
      tester,
      const NavigationBar(
        items: [],
        navigationBarStyle: CoreNavigationBarStyle(surfaceStyle: .liquidGlass),
      ),
    );
    expect(
      find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .any(
            (e) => e.classes?.contains('coui-material-liquidGlass') ?? false,
          ),
      isTrue,
    );
  });

  test(
    'local materials emit dark mode and accessibility rules without a global preset',
    () {
      final sheet = ThemeConfig.defaults().surfaceStyleVariableBlocks;
      const scope =
          '.coui-material-surface.coui-surface-functional.coui-material-liquidGlass';
      expect(sheet, contains('$scope{background-color:'));
      expect(sheet, contains('[data-theme="dark"] $scope{'));
      expect(sheet, contains('prefers-reduced-transparency:reduce){$scope{'));
      expect(sheet, contains('forced-colors:active){$scope{'));
      expect(
        sheet,
        isNot(contains('coui-material-defaultStyle{backdrop-filter:blur')),
      );
    },
  );

  group('content surfaces name their own material', () {
    // The marker is how Web says which material a surface draws: the
    // document-scoped one is read by whichever preset the page carries, the
    // local one only by the preset it names. Every case pairs the surface that
    // states a material with the sibling that does not.

    testComponents('a card swaps to the local marker', (tester) async {
      final context = _themedContext(tester);
      final opaque = resolveCard(
        context,
        variant: .outlined,
        hasMedia: false,
        interactive: false,
        cardStyle: const CoreCardStyle(surfaceStyle: .defaultStyle),
      );
      final inherited = resolveCard(
        context,
        variant: .outlined,
        hasMedia: false,
        interactive: false,
      );

      expect(
        _classes(opaque.root),
        containsAll([
          kWebLocalSurfaceMarker,
          'coui-material-defaultStyle',
          kWebSurfaceRoleContent,
        ]),
      );
      expect(_classes(opaque.root), isNot(contains(kWebSurfaceMarker)));
      // The control: a card that says nothing keeps the document marker.
      expect(_classes(inherited.root), contains(kWebSurfaceMarker));
      expect(
        _classes(inherited.root).where((c) => c.startsWith('coui-material-')),
        isEmpty,
      );
    });

    testComponents(
      'a card still publishes the fill a local material restates',
      (
        tester,
      ) async {
        // A local glass material restates the fill from this triplet, exactly
        // as the document one does; a marker without it resolves the rule's
        // colour to nothing and the background vanishes.
        final resolved = resolveCard(
          _themedContext(tester),
          variant: .outlined,
          hasMedia: false,
          interactive: false,
          cardStyle: const CoreCardStyle(surfaceStyle: .liquidGlass),
        );
        expect(
          resolved.root.inlineStyles!.properties,
          contains(kWebSurfaceFillVar),
        );
        expect(
          _classes(resolved.root),
          containsAll([kWebLocalSurfaceMarker, 'coui-material-liquidGlass']),
        );
      },
    );

    testComponents('a rendered card carries the local marker on its root', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Card(
          cardStyle: const CoreCardStyle(surfaceStyle: .defaultStyle),
          body: const Text('Opaque'),
        ),
      );
      final roots = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .where(
            (e) => e.classes?.contains('coui-material-defaultStyle') ?? false,
          );
      expect(roots, hasLength(1));
      expect(roots.single.classes!.split(' '), isNot(contains('coui-surface')));
      expect(roots.single.styles!.properties, contains(kWebSurfaceFillVar));
    });

    testComponents('an outlined container swaps to the local marker', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final opaque = resolveOutlinedContainer(
        context: context,
        containerStyle: const CoreOutlinedContainerStyle(
          surfaceStyle: .defaultStyle,
        ),
      );
      final inherited = resolveOutlinedContainer(context: context);

      expect(
        _classes(opaque.root),
        containsAll([kWebLocalSurfaceMarker, 'coui-material-defaultStyle']),
      );
      expect(_classes(opaque.root), isNot(contains(kWebSurfaceMarker)));
      expect(_classes(inherited.root), contains(kWebSurfaceMarker));
      expect(
        opaque.root.inlineStyles!.properties,
        contains(kWebSurfaceFillVar),
      );
    });

    testComponents("the role still decides which of the preset's materials", (
      tester,
    ) async {
      final context = _themedContext(tester);
      final floating = resolveOutlinedContainer(
        context: context,
        role: .functional,
        containerStyle: const CoreOutlinedContainerStyle(
          surfaceStyle: .liquidGlass,
        ),
      );
      expect(_classes(floating.root), contains(kWebSurfaceRoleFunctional));
      expect(_classes(floating.root), isNot(contains(kWebSurfaceRoleContent)));
    });

    testComponents("the theme's flat blur and opacity belong to the ambient "
        'material', (tester) async {
      // `ThemeData.surfaceBlur` / `surfaceOpacity` are a flat statement of the
      // surrounding material, and the Flutter twin replaces them with the
      // named preset's own values. Reading them for a surface that asked for
      // a different material would let app-wide translucency into a card
      // that asked to be opaque.
      final context = _themedContext(
        tester,
        theme: const ThemeData(surfaceBlur: 12, surfaceOpacity: 0.5),
      );

      final inheritedCard = resolveCard(
        context,
        variant: .outlined,
        hasMedia: false,
        interactive: false,
      );
      expect(
        inheritedCard.root.inlineStyles!.properties['backdrop-filter'],
        'blur(12.0px)',
        reason: 'the control: the flat fallback does reach a plain card',
      );
      final opaqueCard = resolveCard(
        context,
        variant: .outlined,
        hasMedia: false,
        interactive: false,
        cardStyle: const CoreCardStyle(surfaceStyle: .defaultStyle),
      );
      expect(
        opaqueCard.root.inlineStyles!.properties,
        isNot(contains('backdrop-filter')),
      );

      final inheritedBox = resolveOutlinedContainer(context: context);
      expect(
        inheritedBox.root.inlineStyles!.properties['backdrop-filter'],
        'blur(12.0px)',
      );
      expect(_classes(inheritedBox.root).any((c) => c.endsWith('/50')), isTrue);
      final opaqueBox = resolveOutlinedContainer(
        context: context,
        containerStyle: const CoreOutlinedContainerStyle(
          surfaceStyle: .defaultStyle,
        ),
      );
      expect(
        opaqueBox.root.inlineStyles!.properties,
        isNot(contains('backdrop-filter')),
      );
      expect(
        _classes(opaqueBox.root).any((c) => c.endsWith('/50')),
        isFalse,
        reason: 'the fill token keeps its own opacity',
      );
    });

    test(
      'no stylesheet rule that paints a material reaches an opaque card',
      () {
        final sheet = ThemeConfig.defaults().surfaceStyleVariableBlocks;
        final rules = _materialRules(sheet);
        expect(
          rules,
          isNotEmpty,
          reason: 'the sheet has to state materials for this to mean anything',
        );

        // The opaque card the resolver emits, as the class set a selector sees.
        const opaque = {
          kWebLocalSurfaceMarker,
          'coui-material-defaultStyle',
          kWebSurfaceRoleContent,
        };
        // The glass card under the same preset, as the control: the check has
        // to be able to find a rule, or "none found" proves nothing.
        const glass = {
          kWebLocalSurfaceMarker,
          'coui-material-liquidGlass',
          kWebSurfaceRoleContent,
        };

        final reachingOpaque = rules.keys.where(
          (rule) => _mightMatch(rule, opaque),
        );
        final reachingGlass = rules.keys.where(
          (rule) => _mightMatch(rule, glass),
        );
        expect(reachingGlass, isNotEmpty);
        expect(
          reachingOpaque,
          isEmpty,
          reason: 'a rule that paints glass matches the opaque card',
        );
        // And the document-scoped glass rule needs the document marker, which
        // the local one replaces rather than adds to.
        expect(
          rules.keys.where(
            (rule) => rule.contains('[data-coui-style="liquidGlass"]'),
          ),
          isNotEmpty,
        );
        expect(
          rules.keys
              .where((rule) => rule.contains('[data-coui-style="liquidGlass"]'))
              .where((rule) => _mightMatch(rule, opaque)),
          isEmpty,
        );
      },
    );
  });
}
