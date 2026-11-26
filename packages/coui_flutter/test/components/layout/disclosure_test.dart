import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(
      body: Align(child: SizedBox(width: 400, child: child)),
    ),
  ),
);

void main() {
  group('open is a seed the widget then owns', () {
    testWidgets('open: true shows the body on first build', (tester) async {
      await tester.pumpWidget(
        _app(
          const Disclosure(
            title: 'Question',
            open: true,
            content: Text('Answer'),
          ),
        ),
      );

      expect(find.text('Answer'), findsOneWidget);
    });

    testWidgets('open: false keeps the body out of the tree', (tester) async {
      await tester.pumpWidget(
        _app(const Disclosure(title: 'Question', content: Text('Answer'))),
      );

      // Out of the tree, not merely invisible — that is what the Web twin
      // does, where the browser does not render a closed section's
      // content either, and it keeps the body off the reading order
      // without an `inert` to remember.
      expect(find.text('Answer'), findsNothing);
    });

    testWidgets('tapping the header opens it', (tester) async {
      await tester.pumpWidget(
        _app(const Disclosure(title: 'Question', content: Text('Answer'))),
      );

      await tester.tap(find.text('Question'));
      await tester.pumpAndSettle();

      expect(find.text('Answer'), findsOneWidget);
    });

    testWidgets('onToggle reports the state the widget moved to', (
      tester,
    ) async {
      final seen = <bool>[];
      await tester.pumpWidget(
        _app(
          Disclosure(
            title: 'Question',
            onToggle: seen.add,
            content: const Text('Answer'),
          ),
        ),
      );

      await tester.tap(find.text('Question'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Question'));
      await tester.pumpAndSettle();

      expect(seen, [true, false]);
    });

    testWidgets('returning without acting does not re-close the section', (
      tester,
    ) async {
      // The callback is observational — the caller never owned the state,
      // so ignoring it has to leave the section open. A controlled
      // component would snap shut here, and that difference is the whole
      // reason `Collapsible` still exists beside this one.
      await tester.pumpWidget(
        _app(
          Disclosure(
            title: 'Question',
            onToggle: (_) {},
            content: const Text('Answer'),
          ),
        ),
      );

      await tester.tap(find.text('Question'));
      await tester.pumpAndSettle();

      expect(find.text('Answer'), findsOneWidget);
    });

    testWidgets('a rebuild that does not change open leaves it alone', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const Disclosure(title: 'Question', content: Text('Answer'))),
      );
      await tester.tap(find.text('Question'));
      await tester.pumpAndSettle();

      // Same `open: false` as before — a re-seed here would slam the
      // section shut under the reader on any ancestor rebuild.
      await tester.pumpWidget(
        _app(const Disclosure(title: 'Question', content: Text('Answer'))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Answer'), findsOneWidget);
    });

    testWidgets('changing open re-seeds the section', (tester) async {
      await tester.pumpWidget(
        _app(const Disclosure(title: 'Question', content: Text('Answer'))),
      );
      await tester.pumpWidget(
        _app(
          const Disclosure(
            title: 'Question',
            open: true,
            content: Text('Answer'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Answer'), findsOneWidget);
    });
  });

  group('header slots', () {
    testWidgets('a trigger widget wins over the title string', (tester) async {
      await tester.pumpWidget(
        _app(
          const Disclosure(
            title: 'Question',
            trigger: Text('Custom'),
            content: Text('Answer'),
          ),
        ),
      );

      expect(find.text('Custom'), findsOneWidget);
      expect(find.text('Question'), findsNothing);
    });

    testWidgets('the header announces itself as an expandable button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Disclosure(
            title: 'Question',
            open: true,
            content: Text('Answer'),
          ),
        ),
      );

      // Web gets this from `<details>/<summary>` for free; Flutter has to
      // state it, and the two have to agree. Walking up from the header
      // text rather than reading one node checks the flag actually
      // reaches an ancestor of what the reader focuses — a `Semantics`
      // sitting outside that path would satisfy a shallower probe while
      // announcing nothing.
      final handle = tester.ensureSemantics();
      await tester.pumpAndSettle();

      var announced = false;
      for (
        SemanticsNode? node = tester.getSemantics(find.text('Question'));
        node != null;
        node = node.parent
      ) {
        final flags = node.getSemanticsData().flagsCollection;
        if (flags.isButton && flags.isExpanded.toBoolOrNull() == true) {
          announced = true;
        }
      }

      expect(
        announced,
        isTrue,
        reason: 'no ancestor announced itself as an expanded button',
      );
      handle.dispose();
    });
  });

  group('DisclosureGroup', () {
    testWidgets('sections open independently of one another', (tester) async {
      await tester.pumpWidget(
        _app(
          const DisclosureGroup(
            items: [
              Disclosure(title: 'First', open: true, content: Text('One')),
              Disclosure(title: 'Second', open: true, content: Text('Two')),
            ],
          ),
        ),
      );

      // Both open at once — the distinction from `Accordion`, which would
      // have closed one when the other opened.
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
    });
  });

  group('chrome flows through the style slot', () {
    testWidgets('contentInset override reaches the resolved inset', (
      tester,
    ) async {
      late ResolvedDisclosure resolved;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              resolved = resolveDisclosure(
                context,
                disclosureStyle: const CoreDisclosureStyle(
                  contentInset: CoreEdgeInsets.all(CoreSpace.space24),
                ),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.contentInset.left, CoreSpace.space24);
    });

    testWidgets('a partial ring override is forwarded, not flattened', (
      tester,
    ) async {
      // Raw-forwarded on purpose: the composed `Clickable`'s own resolver
      // fills the rest of the slot. Web has no such child and fills it
      // from the same constant — the two must agree, and a resolver that
      // flattened the partial here would silently disagree.
      late ResolvedDisclosure resolved;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              resolved = resolveDisclosure(
                context,
                disclosureStyle: const CoreDisclosureStyle(
                  clickableStyle: CoreClickableStyle(
                    focusOutlineStyle: CoreFocusOutlineStyle(
                      borderColor: CoreColor.token(CoreColors.primary),
                    ),
                  ),
                ),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        resolved.clickableStyle.focusOutlineStyle?.borderColor,
        const CoreColor.token(CoreColors.primary),
      );
      // The press-scale partial this component states is still there —
      // merging the override must not drop it.
      expect(resolved.clickableStyle.pressedScale, 1);
    });

    testWidgets('the theme slot resolves before the per-instance slot', (
      tester,
    ) async {
      late ResolvedDisclosure resolved;
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: const ThemeData(
              coreComponentTheme: CoreComponentTheme(
                disclosure: CoreDisclosureTheme(
                  style: CoreDisclosureStyle(itemSpacing: CoreSpace.space24),
                ),
              ),
            ),
            child: Builder(
              builder: (context) {
                resolved = resolveDisclosure(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolved.itemSpacing, CoreSpace.space24);
    });
  });
}
