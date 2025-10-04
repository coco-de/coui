// Pseudo-class styling based on parent state
// Styling based on sibling state (peer-{modifier})
// https://tailwindcss.com/docs/hover-focus-and-other-states#styling-based-on-parent-state

import 'package:coui_web/src/base/base_style.dart';

enum PrefixModifierType {
  breakpoint,
  darkMode,
  orientation,
  pseudoClass,
  variant,
}

/// Representing the Tailwind CSS prefix modifiers.
class PrefixModifier {
  const PrefixModifier(this.prefixValue, this.type);
  final String prefixValue;
  final PrefixModifierType type;
  String get prefix => '$prefixValue:';
}

// TODOContainer queries @container @md:flex-row
// https://tailwindcss.com/docs/responsive-design#container-queries
enum Breakpoint implements PrefixModifier {
  /// Large breakpoint
  lg('lg', PrefixModifierType.breakpoint),

  /// Medium breakpoint
  md('md', PrefixModifierType.breakpoint),

  /// Small breakpoint
  sm('sm', PrefixModifierType.breakpoint),

  /// Extra large breakpoint
  xl('xl', PrefixModifierType.breakpoint),

  /// 2xl breakpoint
  xl2('2xl', PrefixModifierType.breakpoint);

  const Breakpoint(this.prefixValue, this.type);

  @override
  final String prefixValue;

  @override
  final PrefixModifierType type;

  @override
  String get prefix => '$prefixValue:';
}

mixin Breakpoints<T extends BaseStyle<T>> on BaseStyle<T> {}
