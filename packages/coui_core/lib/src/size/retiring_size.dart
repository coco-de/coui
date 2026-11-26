import 'package:coui_core/src/size/component_size.dart';
import 'package:meta/meta.dart';

/// A size a component is scheduled to stop accepting.
///
/// Dropping a step from a component's size ladder is announced before it
/// happens: during the notice passing the step renders exactly as it does
/// today. Once it is gone — in [removedIn] at the earliest — a build that
/// strips asserts draws [fallback] for it, and anything running with
/// asserts on stops on it. A component lists its retiring steps and hands
/// them to [noticeRetiringSize] wherever it resolves its size.
@immutable
class CoreRetiringSize {
  /// Creates a retiring step: [size] renders as today until it is removed
  /// ([removedIn] at the earliest), and as [fallback] from then on.
  const CoreRetiringSize({
    required this.size,
    required this.fallback,
    required this.removedIn,
    this.alreadyFallsBack = false,
  });

  /// The step being retired.
  final CoreComponentSize size;

  /// What the component draws for [size] once the step is gone — the row
  /// `resolveSizeRow` falls to when the table no longer states [size].
  final CoreComponentSize fallback;

  /// The coui_core release that stops accepting [size], spelled
  /// `<major>.<minor>` like a deprecation's `since` marker (e.g. `0.153`).
  ///
  /// coui_core's number, whichever package the component ships in: the
  /// ladder that loses the row lives there, and the platform packages
  /// number their releases independently — a Flutter app on coui_flutter
  /// 0.153 can be long past coui_core 0.153 or not yet at it.
  ///
  /// It is the release the removal is scheduled for and no earlier — not a
  /// promise that it goes in exactly that one, since a release can slip.
  /// The notice says "at the earliest" for that reason.
  final String removedIn;

  /// Whether the component already draws [fallback] for [size] today — its
  /// ladder lost the row earlier and clamps. Then nothing changes on
  /// screen when the step goes; what changes is that runs with asserts on
  /// stop on it, and the notice says exactly that instead of promising a
  /// new look.
  final bool alreadyFallsBack;

  @override
  bool operator ==(Object other) =>
      other is CoreRetiringSize &&
      other.size == size &&
      other.fallback == fallback &&
      other.removedIn == removedIn &&
      other.alreadyFallsBack == alreadyFallsBack;

  @override
  int get hashCode => Object.hash(size, fallback, removedIn, alreadyFallsBack);
}

/// Where retiring-size notices are written. `null` writes them with `print`.
///
/// A test swaps this to read what was said; nothing else should.
@visibleForTesting
void Function(String message)? debugRetiringSizeNoticeSink;

/// Forgets which notices were already given, so a test can see the first
/// one again.
@visibleForTesting
void debugResetRetiringSizeNotices() => _noticed = const {};

// One entry per component × size already announced this run. Process-wide on
// purpose: the notice is about the caller's code, which is the same for every
// screen and every request, so repeating it per build says nothing new.
Set<String> _noticed = const {};

/// Says — once per run, only where asserts are on — that [component] was
/// asked for a [size] it is about to stop accepting.
///
/// This is the notice half of retiring a step, and it deliberately does
/// less than `resolveSizeRow`. That function asserts, because a size the
/// table does not state is a mistake to fix now; a retiring size is still
/// correct today, so failing the caller's debug run — an error screen over
/// an app that renders fine — would turn an announcement into a breakage.
/// So this only writes to the log:
///
/// - **asserts-on only** — the whole body sits inside an `assert`, so a
///   build that strips asserts (a release Flutter app, a compiled Web
///   client) does nothing here. Jaspr's static generation prerenders with
///   asserts on even for a release build, so its build log shows the
///   notice too — a line in a log, never a failed page.
/// - **never throws** — the screen renders as it did; nothing is raised.
/// - **once** — the same component and size are announced the first time
///   they are asked for, not on every build.
///
/// The message names the step that replaces it, whether the look changes
/// at all ([CoreRetiringSize.alreadyFallsBack]), and the earliest release
/// that makes the switch, so whoever reads it knows what will change and
/// from when. A [size] that is not in [retiring] is silent.
void noticeRetiringSize({
  required String component,
  required CoreComponentSize size,
  required Iterable<CoreRetiringSize> retiring,
}) {
  assert(
    () {
      for (final step in retiring) {
        if (step.size != size) continue;
        final key = '$component.${size.name}';
        if (_noticed.contains(key)) return true;
        _noticed = {..._noticed, key};
        const stoppers =
            'anything running with asserts on (debug builds, Jaspr static '
            'prerendering) stops on it';
        final message = step.alreadyFallsBack
            ? 'CoUI · $component: size `${size.name}` is retiring. It '
                  'already renders as `${step.fallback.name}`, so nothing '
                  'changes on screen; from coui_core ${step.removedIn} at '
                  'the earliest $stoppers. Pass `${step.fallback.name}` '
                  'instead.'
            : 'CoUI · $component: size `${size.name}` is retiring. From '
                  'coui_core ${step.removedIn} at the earliest it renders as '
                  '`${step.fallback.name}`, and $stoppers. Pass '
                  '`${step.fallback.name}` (or another size $component '
                  'keeps) instead.';
        final sink = debugRetiringSizeNoticeSink;
        if (sink != null) {
          sink(message);
        } else {
          // coui_core is plain Dart, so Flutter's `debugPrint` is out of
          // reach; `print` reaches the console on every platform it runs on,
          // and the enclosing assert keeps it out of builds that strip
          // asserts.
          // ignore: avoid_print
          print(message);
        }
        return true;
      }
      return true;
    }(),
    'unreachable — the notice never fails the caller',
  );
}
