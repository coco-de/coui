import 'dart:ui' show CheckedState;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: child),
  ),
);

/// The merged semantics node for [finder].
SemanticsData _semanticsOf(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).getSemanticsData();

void main() {
  group('Clickable announces itself as a control', () {
    testWidgets('exposes the button role', (tester) async {
      await tester.pumpWidget(
        _app(Clickable(onPressed: () {}, child: const Text('Go'))),
      );
      final data = _semanticsOf(tester, find.text('Go'));
      expect(
        data.hasFlag(SemanticsFlag.isButton),
        isTrue,
        reason:
            'A control a screen reader cannot identify as a control is '
            'unreachable, not merely unlabelled.',
      );
      expect(data.hasFlag(SemanticsFlag.isEnabled), isTrue);
    });

    testWidgets('reports disabled', (tester) async {
      await tester.pumpWidget(
        _app(
          const Clickable(enabled: false, child: Text('Go')),
        ),
      );
      final data = _semanticsOf(tester, find.text('Go'));
      expect(data.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
      expect(data.hasFlag(SemanticsFlag.isEnabled), isFalse);
    });

    testWidgets('yields the button role to a more specific control', (
      tester,
    ) async {
      // Mirrors the Web twin, where a composing component overrides the
      // generic `role="button"` with its own via attributes.
      await tester.pumpWidget(
        _app(
          const Clickable(semanticsButton: false, child: Text('Go')),
        ),
      );
      expect(
        _semanticsOf(tester, find.text('Go')).hasFlag(SemanticsFlag.isButton),
        isFalse,
      );
    });
  });

  group('state reaches assistive technology', () {
    testWidgets('Checkbox reports checked', (tester) async {
      await tester.pumpWidget(
        _app(
          Checkbox(checked: true, onChanged: (_) {}),
        ),
      );
      // The node carrying the state is the one the annotation merges
      // into, and `getSemantics` only ever walks *up* from the element it
      // is given. The checkbox's outermost render object is a pointer-
      // target proxy that creates no node, so starting from `Checkbox`
      // walks straight past the annotation. The tree is unchanged — this
      // is where the node has always been.
      final data = _semanticsOf(tester, find.byType(Clickable));
      expect(data.hasFlag(SemanticsFlag.hasCheckedState), isTrue);
      expect(data.hasFlag(SemanticsFlag.isChecked), isTrue);
      expect(
        data.hasFlag(SemanticsFlag.isButton),
        isFalse,
        reason: 'A checkbox should not be announced as a plain button.',
      );
    });

    testWidgets('Checkbox takes its name from its label', (tester) async {
      // The docs promise the name comes from the row's own text, the same
      // as the Web root whose contents name the `role=checkbox` element.
      // Read from the node that carries the checked state, so a label that
      // landed on some sibling node would not count.
      await tester.pumpWidget(
        _app(Checkbox(checked: false, label: 'Terms', onChanged: (_) {})),
      );
      final data = _semanticsOf(tester, find.byType(Clickable));
      expect(data.flagsCollection.isChecked, CheckedState.isFalse);
      expect(data.label, 'Terms');
    });

    testWidgets('Checkbox reports the indeterminate state distinctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Checkbox(
            checked: null,
            onChanged: (_) {},
          ),
        ),
      );
      // The node carrying the state is the one the annotation merges
      // into, and `getSemantics` only ever walks *up* from the element it
      // is given. The checkbox's outermost render object is a pointer-
      // target proxy that creates no node, so starting from `Checkbox`
      // walks straight past the annotation. The tree is unchanged — this
      // is where the node has always been.
      final data = _semanticsOf(tester, find.byType(Clickable));
      expect(
        data.hasFlag(SemanticsFlag.isCheckStateMixed),
        isTrue,
        reason:
            'Without the mixed flag an indeterminate box reads as simply '
            'unchecked, which is a different statement.',
      );
    });

    testWidgets('Toggle reports its on/off state', (tester) async {
      await tester.pumpWidget(
        _app(Toggle(value: true, onChanged: (_) {})),
      );
      // Same reasoning as the indeterminate-Checkbox case above: `Toggle`'s
      // outermost render object is now the pointer-target proxy
      // (`TouchTarget`, #3457), which creates no semantics node, so
      // `getSemantics` starting from `Toggle` walks straight past the
      // `toggled:` annotation. `Clickable` is the node it actually merges
      // into.
      final data = _semanticsOf(tester, find.byType(Clickable));
      expect(data.hasFlag(SemanticsFlag.hasToggledState), isTrue);
      expect(data.hasFlag(SemanticsFlag.isToggled), isTrue);
    });

    testWidgets('Progress announces its position', (tester) async {
      await tester.pumpWidget(_app(const Progress(value: 0.42)));
      expect(_semanticsOf(tester, find.byType(Progress)).value, equals('42%'));
    });

    testWidgets('an indeterminate Progress reports no misleading number', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const Progress()));
      final value = _semanticsOf(tester, find.byType(Progress)).value;
      expect(value, isNotEmpty);
      expect(
        value,
        isNot(contains('%')),
        reason:
            'A percentage on an indeterminate bar reads as progress stalled '
            'at that number.',
      );
    });
  });

  group('a heading reaches the outline, not just the type scale', () {
    // Web renders `<h2>` and the browser puts it in the document
    // outline. Flutter drew the same words larger and told assistive
    // technology nothing, so the outline stopped at the platform
    // boundary — identical on screen, absent to a screen reader.
    for (final (element, level) in const [
      (CoreTextBlockElement.h1, 1),
      (CoreTextBlockElement.h2, 2),
      (CoreTextBlockElement.h3, 3),
      (CoreTextBlockElement.h4, 4),
      (CoreTextBlockElement.h5, 5),
      (CoreTextBlockElement.h6, 6),
    ]) {
      testWidgets('${element.name} states level $level', (tester) async {
        await tester.pumpWidget(_app(TextBlock(text: 'T', element: element)));

        expect(
          _semanticsOf(tester, find.text('T')).headingLevel,
          level,
        );
      });
    }

    testWidgets('and a paragraph states none', (tester) async {
      // `SemanticsData.headingLevel` is a non-nullable int defaulting to
      // 0, so "no heading" reads as 0 here while the enum says null —
      // and null is what it must say, because Flutter asserts a stated
      // level is within 1..6 and a `0` throws on the way in.
      await tester.pumpWidget(
        _app(TextBlock(text: 'T', element: CoreTextBlockElement.p)),
      );

      expect(_semanticsOf(tester, find.text('T')).headingLevel, 0);
    });
  });

  group('a landmark is a role, not a noun in the label', () {
    testWidgets('a footer states the contentinfo landmark', (tester) async {
      // What this replaced: `label: 'footer'`. That announces the word
      // "footer" and states no landmark at all, so the region a
      // screen-reader user wants to jump to was not in the landmark
      // list — while looking, in code, like it had been handled.
      await tester.pumpWidget(
        _app(
          const Footer(
            sections: [
              CoreFooterNavData(title: 'S', children: [Text('c')]),
            ],
          ),
        ),
      );
      final data = _semanticsOf(tester, find.text('c'));

      expect(data.role, SemanticsRole.contentInfo);
      expect(
        data.label.toLowerCase(),
        isNot('footer'),
        reason: 'the label is still the role spelled out',
      );
    });

    testWidgets('and it carries a name', (tester) async {
      // Every landmark on a page needs one. A list that reads
      // "navigation, navigation, navigation" is a list nobody can
      // choose from, which is why the adapter states `label` as a
      // precondition for all of them rather than only for `region`.
      await tester.pumpWidget(
        _app(
          const Footer(
            sections: [
              CoreFooterNavData(title: 'S', children: [Text('c')]),
            ],
          ),
        ),
      );

      expect(_semanticsOf(tester, find.text('c')).label, isNotEmpty);
    });
  });

  group('an unnamed landmark is dropped rather than announced', () {
    testWidgets('a contentinfo without a label states no role', (
      tester,
    ) async {
      // Tested at the seat, not through a component: every landmark
      // call site currently supplies a name, so the precondition never
      // fires there and a test through one of them would pass whether
      // the adapter stated it or not.
      //
      // What it prevents is an anonymous entry in the landmark list —
      // "navigation" with nothing to distinguish it from the other two.
      // The SDK rejects an unnamed region outright and accepts the rest,
      // which is the worse failure because nothing says so.
      await tester.pumpWidget(
        _app(
          const CoUISemantics(
            role: CoreSemanticRole.contentInfo,
            child: Text('c'),
          ),
        ),
      );

      expect(
        _semanticsOf(tester, find.text('c')).role,
        isNot(SemanticsRole.contentInfo),
      );
    });

    testWidgets('and states it once named', (tester) async {
      await tester.pumpWidget(
        _app(
          const CoUISemantics(
            role: CoreSemanticRole.contentInfo,
            label: 'Site footer',
            child: Text('c'),
          ),
        ),
      );

      expect(
        _semanticsOf(tester, find.text('c')).role,
        SemanticsRole.contentInfo,
      );
    });
  });

  group('the page has one main landmark, around the content', () {
    testWidgets('a scaffold states main on the body, not the root', (
      tester,
    ) async {
      // Around the content and not the root: `main` is what a
      // screen-reader user jumps to in order to *skip* the header and
      // navigation, so a landmark that included them would make the jump
      // land where the reader already was.
      await tester.pumpWidget(
        _app(
          const Scaffold(
            headers: [Text('h')],
            child: Text('body'),
          ),
        ),
      );

      expect(_semanticsOf(tester, find.text('body')).role, SemanticsRole.main);
      expect(
        _semanticsOf(tester, find.text('h')).role,
        isNot(SemanticsRole.main),
        reason: 'the header is inside the main landmark',
      );
    });
  });

  group('a status dot names its state or says nothing', () {
    testWidgets('an unnamed status announces no label', (tester) async {
      // What this replaced: `label: 'status'`, which announced the word
      // "status" and nothing about which state the dot was in — the one
      // thing a reader needed. Web emitted nothing here at all, so
      // saying nothing is also what makes the two agree.
      await tester.pumpWidget(_app(const Status()));

      // Reading the node the dot itself produces, not a sibling's: a
      // first version asserted on the neighbouring text and passed
      // whatever the dot announced, which is the same as not testing it.
      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .map((w) => w.properties.label)
            .whereType<String>(),
        isNot(contains('status')),
      );
    });

    testWidgets('and a named one announces the state', (tester) async {
      await tester.pumpWidget(_app(const Status(semanticLabel: 'Online')));

      expect(
        _semanticsOf(tester, find.byType(Status)).label,
        'Online',
      );
    });
  });
}
