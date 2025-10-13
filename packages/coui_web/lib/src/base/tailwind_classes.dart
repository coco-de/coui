/// Tailwind CSS utility classes for common patterns.
///
/// This provides constants for frequently used Tailwind CSS class combinations
/// following the shadcn-ui patterns.

/// Common layout classes.
abstract final class TailwindLayout {
  const TailwindLayout._();

  /// Flex container with centered items.
  static const flexCenter = 'flex items-center justify-center';

  /// Flex container with items aligned to start.
  static const flexStart = 'flex items-center justify-start';

  /// Flex container with items aligned to end.
  static const flexEnd = 'flex items-center justify-end';

  /// Flex container with items spaced between.
  static const flexBetween = 'flex items-center justify-between';

  /// Inline flex container with centered items.
  static const inlineFlex = 'inline-flex items-center justify-center';

  /// Grid container with gap.
  static const grid = 'grid gap-4';

  /// Absolute positioning (full coverage).
  static const absoluteFull = 'absolute inset-0';

  /// Fixed positioning (full coverage).
  static const fixedFull = 'fixed inset-0';
}

/// Common spacing classes.
abstract final class TailwindSpacing {
  const TailwindSpacing._();

  /// Standard padding for components.
  static const padding = 'px-4 py-2';

  /// Small padding.
  static const paddingSm = 'px-3 py-1.5';

  /// Large padding.
  static const paddingLg = 'px-6 py-3';

  /// Standard margin.
  static const margin = 'mx-4 my-2';

  /// Standard gap for flex/grid.
  static const gap = 'gap-4';

  /// Small gap.
  static const gapSm = 'gap-2';

  /// Large gap.
  static const gapLg = 'gap-6';
}

/// Common typography classes.
abstract final class TailwindTypography {
  const TailwindTypography._();

  /// Base text styling.
  static const base = 'text-sm font-medium';

  /// Large text.
  static const lg = 'text-lg font-semibold';

  /// Small text.
  static const sm = 'text-xs';

  /// Muted text color.
  static const muted = 'text-muted-foreground';

  /// Truncate text with ellipsis.
  static const truncate = 'truncate';

  /// Text alignment center.
  static const center = 'text-center';
}

/// Common border classes.
abstract final class TailwindBorder {
  const TailwindBorder._();

  /// Standard border.
  static const base = 'border';

  /// Rounded borders.
  static const rounded = 'rounded-md';

  /// Fully rounded borders.
  static const roundedFull = 'rounded-full';

  /// Large rounded borders.
  static const roundedLg = 'rounded-lg';

  /// Border with input color.
  static const input = 'border border-input';
}

/// Common shadow classes.
abstract final class TailwindShadow {
  const TailwindShadow._();

  /// Small shadow.
  static const sm = 'shadow-sm';

  /// Medium shadow.
  static const md = 'shadow-md';

  /// Large shadow.
  static const lg = 'shadow-lg';

  /// No shadow.
  static const none = 'shadow-none';
}

/// Common transition classes.
abstract final class TailwindTransition {
  const TailwindTransition._();

  /// All properties transition.
  static const all = 'transition-all';

  /// Colors transition.
  static const colors = 'transition-colors';

  /// Opacity transition.
  static const opacity = 'transition-opacity';

  /// Transform transition.
  static const transform = 'transition-transform';

  /// Standard duration.
  static const duration = 'duration-200';
}

/// Common focus classes following shadcn-ui patterns.
abstract final class TailwindFocus {
  const TailwindFocus._();

  /// Focus visible with ring.
  static const ring =
      'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2';

  /// Focus visible with ring (no offset).
  static const ringNoOffset =
      'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring';

  /// Focus within styling.
  static const within = 'focus-within:ring-2 focus-within:ring-ring';
}

/// Common disabled state classes.
abstract final class TailwindDisabled {
  const TailwindDisabled._();

  /// Disabled state styling.
  static const base = 'disabled:cursor-not-allowed disabled:opacity-50';

  /// Disabled pointer events.
  static const pointerEvents = 'disabled:pointer-events-none';
}

/// Common hover classes.
abstract final class TailwindHover {
  const TailwindHover._();

  /// Hover background accent.
  static const bgAccent = 'hover:bg-accent hover:text-accent-foreground';

  /// Hover opacity change.
  static const opacity = 'hover:opacity-80';

  /// Hover scale effect.
  static const scale = 'hover:scale-105';
}

/// Common animation classes.
abstract final class TailwindAnimation {
  const TailwindAnimation._();

  /// Pulse animation.
  static const pulse = 'animate-pulse';

  /// Spin animation.
  static const spin = 'animate-spin';

  /// Bounce animation.
  static const bounce = 'animate-bounce';

  /// Fade in animation.
  static const fadeIn = 'animate-in fade-in';

  /// Fade out animation.
  static const fadeOut = 'animate-out fade-out';

  /// Slide in from top.
  static const slideInFromTop = 'animate-in slide-in-from-top';

  /// Slide in from bottom.
  static const slideInFromBottom = 'animate-in slide-in-from-bottom';
}

/// Common positioning classes.
abstract final class TailwindPosition {
  const TailwindPosition._();

  /// Relative positioning.
  static const relative = 'relative';

  /// Absolute positioning.
  static const absolute = 'absolute';

  /// Fixed positioning.
  static const fixed = 'fixed';

  /// Sticky positioning.
  static const sticky = 'sticky';

  /// Z-index layers.
  static const z10 = 'z-10';
  static const z20 = 'z-20';
  static const z30 = 'z-30';
  static const z40 = 'z-40';
  static const z50 = 'z-50';
}

/// Common sizing classes.
abstract final class TailwindSize {
  const TailwindSize._();

  /// Full width.
  static const wFull = 'w-full';

  /// Full height.
  static const hFull = 'h-full';

  /// Full width and height.
  static const full = 'w-full h-full';

  /// Auto width.
  static const wAuto = 'w-auto';

  /// Auto height.
  static const hAuto = 'h-auto';

  /// Fit content.
  static const fitContent = 'w-fit h-fit';
}

/// Common display classes.
abstract final class TailwindDisplay {
  const TailwindDisplay._();

  /// Block display.
  static const block = 'block';

  /// Inline block display.
  static const inlineBlock = 'inline-block';

  /// Flex display.
  static const flex = 'flex';

  /// Inline flex display.
  static const inlineFlex = 'inline-flex';

  /// Grid display.
  static const grid = 'grid';

  /// Hidden.
  static const hidden = 'hidden';

  /// Screen reader only (accessible but visually hidden).
  static const srOnly = 'sr-only';
}

/// Common overflow classes.
abstract final class TailwindOverflow {
  const TailwindOverflow._();

  /// Auto overflow.
  static const auto = 'overflow-auto';

  /// Hidden overflow.
  static const hidden = 'overflow-hidden';

  /// Scroll overflow.
  static const scroll = 'overflow-scroll';

  /// Y-axis auto overflow.
  static const yAuto = 'overflow-y-auto';

  /// X-axis auto overflow.
  static const xAuto = 'overflow-x-auto';
}
