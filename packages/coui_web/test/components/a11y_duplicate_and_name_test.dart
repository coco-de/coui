// The rendered DOM, read the way a screen reader and a browser read it —
// by counting what the markup actually carries, not by trusting the
// widget tree that produced it.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

void main() {
  group('Checkbox — one control, one set of identities', () {
    // The inner box used to receive the same `id`, `role`, `aria-*` and
    // `tabindex` as the interactive root it sits in. Two elements with one
    // id is invalid HTML, and two nested `role=checkbox` stops made a
    // screen reader announce one control twice with a dead second Tab.
    testServer('the id appears exactly once', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: Checkbox(
            id: 'terms',
            checked: true,
            onChanged: (_) {},
          ),
        ),
      );
      final doc = (await tester.request('/')).document!;
      expect(doc.querySelectorAll('#terms'), hasLength(1));
    });

    testServer('exactly one checkbox role and one Tab stop', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: Checkbox(onChanged: (_) {}),
        ),
      );
      final doc = (await tester.request('/')).document!;
      expect(doc.querySelectorAll('[role="checkbox"]'), hasLength(1));
      // The hidden form input is `tabindex=-1`; count only stops a
      // keyboard actually lands on.
      expect(doc.querySelectorAll('[tabindex="0"]'), hasLength(1));
    });
  });

  group('components that route their identity down more than one path', () {
    // The checkbox defect was one build emitting the caller's identity on
    // two nested elements. The components below each hand `id` and the
    // caller's attributes to one of several elements depending on a branch
    // (a badge, a label wrapper, a tap handler), so each branch is where
    // the same defect would come back. Swept by reading every Web build
    // that touches the caller's attributes more than once; these are the
    // ones whose branches actually render, pinned by counting the result.
    Future<void> expectOnce(
      ServerTester tester,
      Component child, {
      bool attributes = true,
    }) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: child));
      final doc = (await tester.request('/')).document!;
      expect(doc.querySelectorAll('#probe'), hasLength(1));
      if (attributes) {
        expect(doc.querySelectorAll('[data-probe]'), hasLength(1));
      }
    }

    const probe = {'data-probe': 'x'};

    testServer('Avatar — plain', (tester) async {
      await expectOnce(
        tester,
        Avatar(initials: 'AB', id: 'probe', attributes: probe),
      );
    });

    testServer('Avatar — with a badge', (tester) async {
      await expectOnce(
        tester,
        Avatar(
          initials: 'AB',
          badge: const Text('1'),
          id: 'probe',
          attributes: probe,
        ),
      );
    });

    testServer('Avatar — with a ring', (tester) async {
      await expectOnce(
        tester,
        Avatar(initials: 'AB', ring: true, id: 'probe', attributes: probe),
      );
    });

    testServer('Chip — display-only', (tester) async {
      await expectOnce(
        tester,
        Chip(label: 'a', id: 'probe', attributes: probe),
      );
    });

    testServer('Chip — tappable', (tester) async {
      await expectOnce(
        tester,
        Chip(label: 'a', onTap: () {}, id: 'probe', attributes: probe),
      );
    });

    testServer('Radio — bare circle', (tester) async {
      await expectOnce(
        tester,
        const Radio(value: 'a', id: 'probe', attributes: probe),
      );
    });

    testServer('Radio — labelled', (tester) async {
      await expectOnce(
        tester,
        const Radio(value: 'a', label: 'A', id: 'probe', attributes: probe),
      );
    });

    testServer('Card — static', (tester) async {
      await expectOnce(
        tester,
        Card(body: const Text('b'), id: 'probe', attributes: probe),
      );
    });

    testServer('Card — tappable', (tester) async {
      await expectOnce(
        tester,
        Card(
          body: const Text('b'),
          onTap: () {},
          id: 'probe',
          attributes: probe,
        ),
      );
    });

    testServer('Link — href only', (tester) async {
      await expectOnce(
        tester,
        const Link(
          href: '/x',
          id: 'probe',
          attributes: probe,
          child: Text('x'),
        ),
      );
    });

    testServer('Link — with a press handler', (tester) async {
      await expectOnce(
        tester,
        Link(
          href: '/x',
          onPressed: () {},
          id: 'probe',
          attributes: probe,
          child: const Text('x'),
        ),
      );
    });

    testServer('Toggle', (tester) async {
      await expectOnce(
        tester,
        Toggle(onChanged: (_) {}, id: 'probe'),
        attributes: false,
      );
    });
  });

  group('Chip — the remove button is named', () {
    // Icon-only, so it carried no text at all. A row of removable chips
    // announced as a row of identical unnamed buttons.
    testServer('names the chip it removes', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: Chip(label: 'Design', onRemove: () {}),
        ),
      );
      final doc = (await tester.request('/')).document!;
      final named = doc.querySelectorAll('[aria-label="Remove Design"]');
      expect(named, hasLength(1));
      // Interpolated, not a literal placeholder — an escaped `\$label`
      // would compile and render the text "$label".
      expect(doc.outerHtml, isNot(contains(r'$label')));
    });

    testServer('follows the active locale', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: CouiLocalizationsScope(
            localizations: KoCouiLocalizations.instance,
            child: Chip(label: '디자인', onRemove: () {}),
          ),
        ),
      );
      final doc = (await tester.request('/')).document!;
      expect(doc.querySelectorAll('[aria-label="디자인 제거"]'), hasLength(1));
    });

    // `ChipInput` draws its chips with `Chip`; the multiplicity is what
    // the name exists for — N remove buttons must be N different names.
    testServer('ChipInput — each chip names itself', (tester) async {
      const chips = ['Flutter', 'Dart', 'Jaspr'];
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: ChipInput(onChanged: (_) {}, chips: chips),
        ),
      );
      final doc = (await tester.request('/')).document!;
      for (final chip in chips) {
        expect(
          doc.querySelectorAll('[aria-label="Remove $chip"]'),
          hasLength(1),
        );
      }
      expect(
        doc.querySelectorAll('[aria-label^="Remove "]'),
        hasLength(chips.length),
      );
    });
  });
}
