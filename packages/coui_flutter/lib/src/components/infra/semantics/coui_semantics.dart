import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/src/util/core_to_flutter.dart';
import 'package:flutter/widgets.dart';

/// Announces what a widget *is* to assistive technology, from a
/// platform-neutral [CoreSemanticRole].
///
/// This is the Flutter counterpart of the Web side's attribute
/// passthrough: one place that knows how a Core role becomes Flutter's
/// vocabulary. Without it the translation would be copied into each of
/// the ~90 hand-written `Semantics(` sites, and the degradations it
/// performs would have to be right ninety times instead of once.
///
/// ## Why some roles quietly do not reach the tree
///
/// Flutter validates several roles with a debug assert that runs
/// inside `SemanticsNode._addToUpdate` — which means it runs in every
/// widget test that touches semantics, not only in a running app. Some
/// of those obligations are visible from here (a `region` needs a
/// label); others describe the shape of the subtree (a `menuItem`
/// needs a `menu` ancestor) and are the component's to satisfy.
///
/// When an obligation this widget *can* see is unmet, the role is
/// dropped rather than emitted. A role carries no information when its
/// precondition fails — an unlabelled region says nothing a screen
/// reader can use — so dropping it loses nothing and crashing the
/// caller's debug build would lose a great deal.
class CoUISemantics extends StatelessWidget {
  /// Creates a [CoUISemantics].
  const CoUISemantics({
    required this.child,
    super.key,
    this.role,
    this.label,
    this.selected,
    this.expanded,
    this.checked,
    this.toggled,
    this.enabled,
    this.value,
    this.minValue,
    this.maxValue,
    this.onTap,
    this.container = false,
    this.explicitChildNodes = false,
  });

  /// What this subtree announces itself to be.
  final CoreSemanticRole? role;

  /// The accessible name.
  final String? label;

  /// Selection state — also the precondition Flutter puts on
  /// [CoreSemanticRole.tab].
  final bool? selected;

  /// Whether the thing this controls is showing.
  ///
  /// Null for a control that never expands anything — which is not the
  /// same as `false`, and a reader announces the difference: `false`
  /// says "collapsed, activate to open" where null says nothing.
  final bool? expanded;

  /// Checked state. This is how [CoreSemanticRole.checkbox] and
  /// [CoreSemanticRole.radio] are announced on Flutter; the role alone
  /// cannot know it.
  final bool? checked;

  /// Toggled state — how [CoreSemanticRole.toggleSwitch] is announced.
  final bool? toggled;

  /// Whether the control accepts input.
  final bool? enabled;

  /// The current value, as announced.
  final String? value;

  /// The low end of [value]'s range. Required, with [maxValue] and
  /// [value], by [CoreSemanticRole.progressBar].
  final String? minValue;

  /// The high end of [value]'s range. See [minValue].
  final String? maxValue;

  /// Tap action — also the second precondition Flutter puts on
  /// [CoreSemanticRole.tab].
  final VoidCallback? onTap;

  /// Whether this node introduces a semantics boundary.
  final bool container;

  /// Whether children keep their own semantics nodes.
  final bool explicitChildNodes;

  /// The widget this wraps.
  final Widget child;

  /// Whether [condition] holds given what this widget can see.
  ///
  /// The conditions travel with the role rather than being re-derived
  /// here, so a new role is asked the question at the adapter — the one
  /// exhaustive switch — instead of silently defaulting to "no
  /// obligation" at each wrapper.
  bool _isMet(SemanticRolePrecondition condition) => switch (condition) {
    .none => true,
    .label => label != null && label!.isNotEmpty,
    .selectionAndTap => selected != null && onTap != null,
    .checkedState => checked != null,
    .valueRange => value != null && minValue != null && maxValue != null,
  };

  @override
  Widget build(BuildContext context) {
    final resolved = role?.toValue() ?? const FlutterSemanticRole();

    if (resolved.excludeSemantics) {
      return ExcludeSemantics(child: child);
    }

    return Semantics(
      onTap: onTap,
      container: container || resolved.container,
      explicitChildNodes: explicitChildNodes,
      enabled: enabled,
      checked: checked,
      selected: selected,
      toggled: toggled,
      button: resolved.button,
      slider: resolved.slider,
      link: resolved.link,
      header: resolved.header,
      inMutuallyExclusiveGroup: resolved.inMutuallyExclusiveGroup,
      image: resolved.image,
      liveRegion: resolved.liveRegion,
      expanded: expanded,
      label: label,
      value: value,
      role: _isMet(resolved.precondition) ? resolved.role : null,
      minValue: minValue,
      maxValue: maxValue,
      child: child,
    );
  }
}
