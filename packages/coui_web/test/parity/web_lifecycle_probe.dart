/// EPIC-004 (#3597) child #3613 — WebLifecycleProbe.
///
/// FR-017's Web half: verify an exit animation exists by checking that a
/// closing component **survives** its exit window in the DOM/tree instead
/// of vanishing the instant the close is triggered — a component with a
/// real exit transition defers actually removing itself until a
/// `Future.delayed`/`Timer` tied to that transition resolves, so the
/// outgoing content is still there to find right after the trigger. One
/// with no exit transition at all has nothing deferring the removal, so
/// it is already gone.
///
/// #3644 correction — the original version of this probe drove the
/// open→close transition with two `ComponentTester.pumpComponent(...)`
/// calls. That does not observe the transition at all:
/// `pumpComponent` always mounts a **fresh root** element tree rather than
/// updating the existing one in place, so `State.didUpdateComponent` never
/// fires on the probed component and any exit-deferral logic gated on that
/// lifecycle hook never runs — a fresh `pumpComponent(open: false)` render
/// looks identical to a fresh `pumpComponent(open: false)` render with no
/// prior `open: true` pump at all, whether or not an exit transition
/// exists. `dialog_lifecycle_probe_test.dart`'s original assertion passed
/// on both a lineage that had the exit-window fix (#3621) and one that did
/// not, which is the definition of tautological.
///
/// The fix: drive the *same* component instance through the open→close
/// transition via a **child rebuild** instead — [ExitWindowHost] owns the
/// open/visible flag itself and rebuilds the probed component as its
/// child on `setState`, which does reach `didUpdateComponent`. This
/// mirrors the shape `dialog_test.dart`'s
/// `stays mounted through the exit window` regression test already uses.
/// [survivesImmediatelyAfterCloseTrigger] is still the right assertion to
/// check afterwards — what changed is *how the caller reaches the state
/// that makes checking it meaningful*, not what it checks.
///
/// A caveat on timing: `jaspr_test`'s `TestComponentsBinding` schedules
/// rebuilds triggered by `State.setState` through `Future.microtask`
/// (`scheduleFrame`), so a single `await tester.pump()` after the
/// close-triggering `setState` call is required to actually apply that
/// rebuild (`pumpEventQueue()` drains the microtask queue) before
/// [survivesImmediatelyAfterCloseTrigger] is checked — unlike
/// `pumpComponent`, `setState` does not apply synchronously. What that one
/// `pump()` does *not* do is advance real wall-clock time: `jaspr_test` has
/// no simulated clock the way Flutter's `WidgetTester.pump(Duration)` does
/// (`#3611`'s `FlutterMotionProbe`), so a component's exit-transition
/// `Timer` (real milliseconds) cannot have fired yet at that point — this
/// is what makes "right after that one pump" the meaningful checkpoint,
/// and also why this probe cannot sample intermediate timestamps across a
/// real duration the way the Flutter side does.
library;

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import 'package:coui_web/src/util/core_to_css.dart' show durationMsCss;

/// Whether [finder] still matches an element in the tree, checked
/// immediately after the single `tester.pump()` that applies the
/// close-triggering child rebuild (see the library doc comment for why it
/// must be a child rebuild — via [ExitWindowHost] or an equivalent
/// wrapper — rather than a second `tester.pumpComponent(...)` call, and
/// why exactly one `pump()` is both necessary and sufficient here).
///
/// A `false` result here is the DOM-survival signature of "no exit
/// transition at all".
bool survivesImmediatelyAfterCloseTrigger(Finder finder) =>
    finder.evaluate().isNotEmpty;

/// Test harness that owns an `open` flag and rebuilds [builder] as a
/// **child** on every [ExitWindowHostState.setOpen] call — the only way to
/// reach `State.didUpdateComponent` on the probed component, since
/// `ComponentTester.pumpComponent` always mounts a fresh root instead of
/// updating the existing tree in place (see the library doc comment).
///
/// Generalizes `dialog_test.dart`'s private `_DialogHost` so every
/// `WebLifecycleProbe` consumer — not just Dialog — can drive an in-place
/// open→close transition without re-deriving this wrapper.
class ExitWindowHost extends StatefulComponent {
  /// Creates an [ExitWindowHost].
  const ExitWindowHost({
    required this.builder,
    required this.onState,
    super.key,
  });

  /// Builds the probed component from the current open/visible flag.
  final Component Function(bool open) builder;

  /// Called on every build with the live [ExitWindowHostState] so a test
  /// can drive [ExitWindowHostState.setOpen] from outside the component
  /// tree (`setState` itself is `@protected`).
  final void Function(ExitWindowHostState state) onState;

  @override
  State<ExitWindowHost> createState() => ExitWindowHostState();
}

/// State for [ExitWindowHost].
class ExitWindowHostState extends State<ExitWindowHost> {
  /// The current open/visible flag passed to [ExitWindowHost.builder].
  bool open = true;

  /// Flips [open] and schedules a rebuild — the child-rebuild path that
  /// reaches `State.didUpdateComponent` on the probed component. Callers
  /// must `await tester.pump()` once afterwards to apply it (see the
  /// library doc comment).
  void setOpen(bool value) => setState(() => open = value);

  @override
  Component build(BuildContext context) {
    component.onState(this);
    return component.builder(open);
  }
}

/// Asserts that [finder] resolves to exactly one rendered element whose
/// inline `animation` CSS shorthand plays [exitKeyframeName] for
/// [expectedDuration] — the assertion #3644 adds on top of
/// [survivesImmediatelyAfterCloseTrigger].
///
/// DOM survival alone only proves *something* deferred the unmount; it
/// cannot tell a real exit transition from an unrelated stray timer, and
/// it cannot tell the *correct* exit transition from a wrong one — the
/// enter keyframe played by mistake while closing, or the right keyframe
/// at a desynced duration (the same "same token, different render"
/// failure class #3593 catalogued for Command/DatePicker). This reads the
/// actual `animation` value Jaspr rendered: [exitKeyframeName] must
/// appear in it, and so must the CSS custom-property form
/// [expectedDuration] resolves to ([durationMsCss] — `--coui-duration-N`
/// for `CoreDuration` scale steps), not merely *some* duration.
void expectExitAnimation(
  Finder finder, {
  required String exitKeyframeName,
  required Duration expectedDuration,
}) {
  final elements = finder
      .evaluate()
      .map((e) => e.component)
      .whereType<DomComponent>()
      .toList();
  expect(
    elements,
    hasLength(1),
    reason:
        'expectExitAnimation requires exactly one matching element to read '
        'the animation off of — found ${elements.length}.',
  );
  final animation = elements.single.styles?.properties['animation'] ?? '';
  expect(
    animation,
    contains(exitKeyframeName),
    reason:
        'rendered animation "$animation" does not play the exit keyframe '
        '"$exitKeyframeName" — either the wrong keyframe is playing while '
        'closing, or the animation was dropped entirely.',
  );
  final expectedDurationCss = durationMsCss(expectedDuration.inMilliseconds);
  expect(
    animation,
    contains(expectedDurationCss),
    reason:
        'rendered animation "$animation" does not carry the expected '
        'duration token "$expectedDurationCss" — the exit transition '
        "duration desynced from the token it's supposed to derive from.",
  );
}
