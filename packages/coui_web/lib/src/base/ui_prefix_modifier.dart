// ignore_for_file: format-comment, prefer-single-declaration-per-file
// ignore_for_file: prefer-named-parameters
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

enum PseudoState implements PrefixModifier {
  /// Active pseudo-class
  active('active', PrefixModifierType.pseudoClass),

  /// ::after pseudo-element
  after('after', PrefixModifierType.pseudoClass),

  /// ::backdrop
  backdrop('backdrop', PrefixModifierType.pseudoClass),

  /// ::before pseudo-element
  before('before', PrefixModifierType.pseudoClass),

  /// Form state disabled
  disabled('disabled', PrefixModifierType.pseudoClass),

  /// Even pseudo-class
  even('even', PrefixModifierType.pseudoClass),

  /// ::file
  file('file', PrefixModifierType.pseudoClass),

  /// First pseudo-class
  first('first', PrefixModifierType.pseudoClass),

  /// ::first-letter
  firstLetter('first-letter', PrefixModifierType.pseudoClass),

  /// ::first-line
  firstLine('first-line', PrefixModifierType.pseudoClass),

  /// Focus pseudo-class
  focus('focus', PrefixModifierType.pseudoClass),

  /// Hover pseudo-class
  hover('hover', PrefixModifierType.pseudoClass),

  /// Form state invalid
  invalid('invalid', PrefixModifierType.pseudoClass),

  /// Last pseudo-class
  last('last', PrefixModifierType.pseudoClass),

  /// ::marker
  marker('marker', PrefixModifierType.pseudoClass),

  /// Odd pseudo-class
  odd('odd', PrefixModifierType.pseudoClass),

  /// ::placeholder pseudo-element
  placeholder('placeholder', PrefixModifierType.pseudoClass),

  /// Form state required
  required('required', PrefixModifierType.pseudoClass),

  /// ::selection
  selection('selection', PrefixModifierType.pseudoClass);

  const PseudoState(this.prefixValue, this.type);

  @override
  final String prefixValue;

  @override
  final PrefixModifierType type;

  @override
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

mixin Breakpoints<T extends BaseStyle<T>> on BaseStyle<T> {
  T get atSm => at(Breakpoint.sm);
  T get atMd => at(Breakpoint.md);
  T get atLg => at(Breakpoint.lg);
  T get atXl => at(Breakpoint.xl);
  T get at2xl => at(Breakpoint.xl2);
}

enum Theme implements PrefixModifier {
  /// Dark mode
  dark('dark', PrefixModifierType.darkMode);

  const Theme(this.prefixValue, this.type);

  @override
  final String prefixValue;

  @override
  final PrefixModifierType type;

  @override
  String get prefix => '$prefixValue:';
}

enum Media implements PrefixModifier {
  /// contrast-less
  contrastLess('contrast-less', PrefixModifierType.variant),

  /// contrast-more
  contrastMore('contrast-more', PrefixModifierType.variant),

  /// forced-colors
  forcedColors('forced-colors', PrefixModifierType.variant),

  /// Landscape orientation
  landscape('landscape', PrefixModifierType.orientation),

  /// motion-reduce
  motionReduce('motion-reduce', PrefixModifierType.variant),

  /// motion-safe
  motionSafe('motion-safe', PrefixModifierType.variant),

  // not-forced-colors
  notForcedColors('not-forced-colors', PrefixModifierType.variant),

  /// Portrait orientation
  portrait('portrait', PrefixModifierType.orientation),

  /// print
  print('print', PrefixModifierType.variant);

  // TODO(dev): @supports
  // https://tailwindcss.com/docs/hover-focus-and-other-states#supports

  // TODO(dev): @starting-style
  // https://tailwindcss.com/docs/hover-focus-and-other-states#starting-style

  const Media(this.prefixValue, this.type);

  @override
  final String prefixValue;

  @override
  final PrefixModifierType type;

  @override
  String get prefix => '$prefixValue:';
}
