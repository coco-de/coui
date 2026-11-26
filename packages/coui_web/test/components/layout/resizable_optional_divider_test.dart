// Pins `optionalDivider` on Web.
//
// The byte-identical default is the load-bearing case. A knob that changes
// what everyone already renders is not opt-in, and on Web the failure would
// be quiet: the hover / focus classes still fire, so a wrongly-hidden divider
// looks fine the moment you point at it and wrong only at rest.
//
// The hover and focus-visible classes are asserted to SURVIVE hiding — they
// are what makes the divider appear on interaction, so dropping them would
// hide it permanently.

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/layout/resizable/resizable_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kPanes = <CoreResizablePaneData<Component>>[
  CoreResizablePaneData(content: Text('left')),
  CoreResizablePaneData(content: Text('right')),
];

/// Every class string in the rendered tree, joined.
String _allClasses() {
  final buffer = StringBuffer();
  for (final element in find.tag('div').evaluate()) {
    final dom = element.component as DomComponent;
    buffer.write(' ${dom.classes ?? ''}');
  }

  return buffer.toString();
}

/// Bare `bg-*` classes — pseudo-prefixed ones excluded, since those are
/// present in both configurations.
List<String> _idleBackgroundClasses() => _allClasses()
    .split(RegExp(r'\s+'))
    .where((c) => c.startsWith('bg-'))
    .toList();

/// Every inline declaration in the rendered tree, flattened.
String _allInline() {
  final buffer = StringBuffer();
  for (final element in find.tag('div').evaluate()) {
    final dom = element.component as DomComponent;
    (dom.styles?.properties ?? const <String, String>{}).forEach((k, v) {
      buffer.write(' $k:$v;');
    });
  }

  return buffer.toString();
}

void main() {
  group('Resizable optionalDivider', () {
    testComponents('the default emits an idle background token class', (
      tester,
    ) async {
      pumpWithTheme(tester, const Resizable(panes: _kPanes));

      // A bare `bg-*` — not a `group-hover:` / `group-focus-visible:` one,
      // which are present in both configurations and would make a plain
      // `contains('bg-')` pass either way.
      expect(_idleBackgroundClasses(), isNotEmpty);
    });

    testComponents('optionalDivider drops the idle background class', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Resizable(panes: _kPanes, optionalDivider: true),
      );

      expect(
        _idleBackgroundClasses(),
        isEmpty,
        reason: 'the idle token class is replaced, not layered over',
      );
      // `CoreColor.transparent` is a raw sentinel, so it leaves the class
      // path and emits inline with zero alpha.
      expect(_allInline(), contains('rgba(0, 0, 0, 0.00)'));
    });

    testComponents('hiding keeps the hover and focus classes', (tester) async {
      // These are what reveal the divider on interaction — losing them would
      // hide it permanently rather than optionally.
      pumpWithTheme(
        tester,
        const Resizable(panes: _kPanes, optionalDivider: true),
      );

      final classes = _allClasses();
      expect(classes, contains('group-hover:'));
      expect(classes, contains('group-focus-visible:'));
    });

    testComponents('the default output is unchanged by the knob existing', (
      tester,
    ) async {
      pumpWithTheme(tester, const Resizable(panes: _kPanes));
      final withoutKnob = '${_allClasses()}|${_allInline()}';

      pumpWithTheme(
        tester,
        const Resizable(panes: _kPanes, optionalDivider: false),
      );
      final explicitlyOff = '${_allClasses()}|${_allInline()}';

      expect(explicitlyOff, equals(withoutKnob));
    });

    testComponents('the knob survives copyWith', (tester) async {
      const original = Resizable(panes: _kPanes, optionalDivider: true);
      final copy = original.copyWith(showDragHandle: true);

      expect(copy.optionalDivider, isTrue);
      expect(copy.showDragHandle, isTrue);
    });
  });

  group('optionalDivider — the dragged divider stays visible', () {
    // A drag has no CSS pseudo-class to ride: it outlives hover, because
    // the divider pins at its bound while the pointer keeps travelling and
    // because a touch pointer never hovers at all. So the reveal cannot be
    // left to `group-hover:` — the resolver ships a second chrome and the
    // widget picks it.
    //
    // What this group does NOT cover, stated so the coverage is not read as
    // wider than it is: the widget's *pick*. Entering a drag needs a
    // `web.MouseEvent` on `pointerdown`, which cannot be constructed on the
    // VM, and there is no browser lane — so replacing the selection with a
    // hardcoded `resolved.dividerLine` leaves every test below green
    // (verified by injection). The behaviour itself is pinned by the
    // Flutter twin, which drives a real gesture; here the pair the widget
    // chooses between and the listener that switches them are what can be
    // held. Closing this needs a browser-target lane, the same one Epic A's
    // keyboard path and Epic D's pointer path are waiting on.

    testComponents('the dragging chrome drops the hiding transparent fill', (
      tester,
    ) async {
      late ResolvedResizable resolved;
      pumpWithTheme(
        tester,
        _ResolverProbe(
          optionalDivider: true,
          onResolved: (r) => resolved = r,
        ),
      );

      // Idle is hidden; the dragging twin is not. Comparing the two is
      // what makes this fail if they are ever resolved the same way.
      expect(
        resolved.dividerLine.className,
        isNot(equals(resolved.dividerLineDragging.className)),
        reason: 'a hidden divider and a dragged one cannot look the same',
      );
      expect(
        resolved.dividerLineDragging.className.split(' '),
        contains(startsWith('bg-')),
        reason: 'the dragged divider carries a real idle colour class',
      );
    });

    testComponents('the default drags as a heavier primary line', (
      tester,
    ) async {
      // A dragged divider is held: the `primary` line at the dragging
      // thickness, with no hover class of its own to compete with — a
      // hovered, dragged line stays `primary`. The resting line stays the
      // quiet `outlineVariant` one with its hover crossfade.
      late ResolvedResizable resolved;
      pumpWithTheme(
        tester,
        _ResolverProbe(
          optionalDivider: false,
          onResolved: (r) => resolved = r,
        ),
      );

      expect(resolved.dividerLineDragging.className, equals('bg-primary'));
      expect(
        resolved.dividerLine.className,
        equals('bg-outline-variant group-hover:bg-outline'),
      );
    });

    testComponents('the divider still owns the entry point that switches it', (
      tester,
    ) async {
      // Deleting the listener would leave every assertion above green
      // while the divider became undraggable — and so never revealed.
      pumpWithTheme(
        tester,
        const Resizable(panes: _kPanes, optionalDivider: true),
      );

      final wrapper = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .firstWhere((c) => (c.attributes ?? const {})['role'] == 'separator');
      expect(wrapper.events?.keys, contains('pointerdown'));
    });
  });
}

/// Calls the resolver with a live `BuildContext` and hands the result back.
///
/// The widget picks between two chromes at drag time, and that pick cannot
/// be driven here — so the pair itself is what gets asserted.
class _ResolverProbe extends StatelessComponent {
  const _ResolverProbe({
    required this.optionalDivider,
    required this.onResolved,
  });

  final bool optionalDivider;
  final void Function(ResolvedResizable resolved) onResolved;

  @override
  Component build(BuildContext context) {
    onResolved(
      resolveResizable(
        context,
        direction: CoreResizableDirection.horizontal,
        paneFlexes: const [1, 1],
        showDragHandle: false,
        optionalDivider: optionalDivider,
      ),
    );
    return div(const []);
  }
}
