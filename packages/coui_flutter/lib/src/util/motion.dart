/// The Flutter seat for the reduced-motion accessibility axis.
///
/// The policy — which durations the request is about — lives once in
/// `coui_core`'s [CoreReducedMotion]; this file only supplies the platform's
/// answer to "has the user asked for it". The Web side reads the same policy
/// from `prefers-reduced-motion` through the `--coui-duration-*` variables,
/// and browsers map iOS's "Reduce Motion" onto that query.
///
/// On Flutter the answer has two sources, because the platforms set
/// different flags for the same request:
///
/// * `MediaQuery.disableAnimations` — Android's "Remove animations".
/// * `AccessibilityFeatures.reduceMotion` — iOS's "Reduce Motion". Flutter
///   documents that iOS does not set the first flag, and `MediaQueryData`
///   has no field for this one, so a change that flips only this flag does
///   not rebuild `MediaQuery` dependents.
///
/// [resolveReducedMotion] joins the two and is the only place either is read
/// for the request: a component that read `MediaQuery.disableAnimations`
/// itself would honour Android and ignore iOS. Both flags get one answer —
/// transition-tier motion is instant.
///
/// Resolvers call [resolveMotionDuration] on every duration they emit; they
/// do not decide which durations are affected. That decision is the policy's,
/// and centralising it is the point — a component that classified its own
/// motion would be a component that could classify it wrongly, and the
/// resulting bug (a spinner that stops, or a slide that does not) is one
/// nobody notices without the OS setting turned on.
library;

import 'dart:ui' show FlutterView;

import 'package:coui_core/coui_core.dart';
import 'package:flutter/widgets.dart';

/// Whether the platform has asked for reduced motion at [context].
///
/// True when `MediaQuery.disableAnimations` is set (Android) or
/// `AccessibilityFeatures.reduceMotion` is set (iOS). Both are read on every
/// call, so the answer is current whenever it is asked.
///
/// A dependent is told when `disableAnimations` changes, through `MediaQuery`.
/// The iOS flag has no `MediaQuery` aspect: under a [ReducedMotionScope] —
/// `CoUIApp` mounts one — a change while the app runs rebuilds what called
/// this. Without one the flag is read from the view's platform dispatcher, so
/// a dependent that builds sees it, but the change alone triggers no build.
///
/// Outside any [MediaQuery] and view the answer is "not requested": a
/// resolver used there must animate normally rather than behave as if the
/// user asked for less.
bool resolveReducedMotion(BuildContext context) {
  final disableAnimations =
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  final reduceMotion = _reduceMotionOf(context);

  return disableAnimations || reduceMotion;
}

/// [duration] adjusted for the ambient reduced-motion preference.
///
/// Transition-tier motion collapses to [Duration.zero]; display timing
/// (spinners, progress cycles, how long a toast stays) is left alone. See
/// [CoreReducedMotion] for where that line sits and why.
///
/// Safe to call on every duration a resolver emits — when the user has not
/// asked for reduced motion this returns [duration] unchanged.
Duration resolveMotionDuration(BuildContext context, Duration duration) {
  return CoreReducedMotion.resolve(
    duration,
    reduce: resolveReducedMotion(context),
  );
}

/// Whether a loading placeholder pulses under the ambient reduced-motion
/// preference — a display-tier loop the request does stop. See
/// [CoreReducedMotion.runsPlaceholderPulse] for why.
bool resolvePlaceholderPulse(BuildContext context) {
  return CoreReducedMotion.runsPlaceholderPulse(
    reduce: resolveReducedMotion(context),
  );
}

/// The iOS "Reduce Motion" flag at [context]: the scope's value when one is
/// above, else the view's platform dispatcher read now.
bool _reduceMotionOf(BuildContext context) {
  final scope = context
      .dependOnInheritedWidgetOfExactType<_ReducedMotionInherited>();
  if (scope != null) return scope.reduceMotion;

  final view = View.maybeOf(context);

  return view?.platformDispatcher.accessibilityFeatures.reduceMotion ?? false;
}

/// Publishes `AccessibilityFeatures.reduceMotion` to a subtree and rebuilds
/// its dependents when the user changes the setting.
///
/// `MediaQuery` carries `disableAnimations` but not this flag, so without a
/// subscription of its own a change made while the app runs — Settings →
/// Accessibility → Motion → Reduce Motion, then back to the app — would reach
/// nothing that had already built. This listens through
/// [WidgetsBindingObserver.didChangeAccessibilityFeatures] and rebuilds only
/// when the flag itself changed.
///
/// `CoUIApp` mounts one at its root. Components never read the scope;
/// [resolveReducedMotion] does, so every component that routes its motion
/// through the Flutter seat is covered without knowing the scope exists. An
/// app that hosts CoUI widgets without `CoUIApp` can mount one itself to get
/// the live update; without it the flag is still honoured when a dependent
/// builds.
///
/// There is no Web counterpart: the browser reports the setting through
/// `prefers-reduced-motion`, and a media query is already live.
class ReducedMotionScope extends StatefulWidget {
  /// Creates a scope publishing the platform's reduce-motion flag to [child].
  const ReducedMotionScope({required this.child, super.key});

  /// The subtree that reads the flag through [resolveReducedMotion].
  final Widget child;

  @override
  State<ReducedMotionScope> createState() => _ReducedMotionScopeState();
}

class _ReducedMotionScopeState extends State<ReducedMotionScope>
    with WidgetsBindingObserver {
  FlutterView? _view;
  bool _reduceMotion = false;

  bool _readFlag() =>
      _view?.platformDispatcher.accessibilityFeatures.reduceMotion ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The view is an inherited lookup, so it cannot be read in `initState`.
    // The flag is re-read here as well as in the observer callback: a scope
    // moved under another view reads that view's dispatcher.
    _view = View.maybeOf(context);
    _reduceMotion = _readFlag();
  }

  @override
  void didChangeAccessibilityFeatures() {
    final next = _readFlag();
    if (next == _reduceMotion) return;

    setState(() => _reduceMotion = next);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ReducedMotionInherited(
      reduceMotion: _reduceMotion,
      child: widget.child,
    );
  }
}

class _ReducedMotionInherited extends InheritedWidget {
  const _ReducedMotionInherited({
    required this.reduceMotion,
    required super.child,
  });

  final bool reduceMotion;

  @override
  bool updateShouldNotify(_ReducedMotionInherited oldWidget) =>
      reduceMotion != oldWidget.reduceMotion;
}
