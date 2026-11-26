/// Canonical structural-layout class strings for Web resolvers.
///
/// Resolvers compose layout from Tailwind structural utilities by the
/// hundreds. This namespace is the single source for that vocabulary so
/// no layout class is a raw literal in a resolver: a typo cannot silently
/// diverge one call site, and the whole layout surface is greppable.
///
/// Pure structure only - no chrome, no design-token values. Every constant
/// is display / flex / align / position / intrinsic-size / overflow /
/// text-wrap / a11y, values that never change with the theme. Theme-driven
/// classes (color / spacing / radius / z-index / shadow / duration) stay
/// token-interpolated at the call site. That keeps these compile-time
/// `const` strings, usable inside `const WebElementChrome(...)`, and makes
/// every literal-to-constant migration byte-identical.
///
/// Two layers: atoms (one Tailwind utility each) and a small set of combos
/// (recurring multi-token alignment / fill / position patterns). A
/// multi-token layout that is not a named combo is composed from atoms
/// (`'\${WebLayout.flex} \${WebLayout.flexCol}'`). Non-layout classes
/// (`cursor-*` / `select-none` / `transition-*`) are not part of this
/// vocabulary - they compose onto a layout class.
///
/// Names mirror the emitted Tailwind class (Web-internal vocabulary); they
/// are not named after Flutter widgets - this className layer is a
/// render-engine artifact Flutter does not share, and most atoms have no
/// widget counterpart.
abstract final class WebLayout {
  const WebLayout._();

  // -- Display --
  /// `block`.
  static const block = 'block';

  /// `contents`.
  static const contents = 'contents';

  /// `flex`.
  static const flex = 'flex';

  /// `grid`.
  static const grid = 'grid';

  /// `hidden`.
  static const hidden = 'hidden';

  /// `invisible` — `visibility: hidden`: keeps layout space (unlike
  /// [hidden]), excluded from selection / copy / screen readers. Used
  /// for width-reservation layers.
  static const invisible = 'invisible';

  /// `inline-block`.
  static const inlineBlock = 'inline-block';

  /// `inline-flex`.
  static const inlineFlex = 'inline-flex';

  /// `inline-flex align-top` — inline-level, aligned to the top of its line
  /// rather than to the baseline. An inline-level box in a block container
  /// sits on the container's text baseline, and a box with no text of its own
  /// (an empty swatch) has its baseline on its bottom edge, so the line box
  /// keeps the strut's descent below it. Top alignment makes the line box
  /// exactly as tall as the box.
  static const inlineFlexAlignTop = 'inline-flex align-top';

  // -- Direction / wrap --
  /// `flex-col`.
  static const flexCol = 'flex-col';

  /// `flex-nowrap`.
  static const flexNowrap = 'flex-nowrap';

  /// `flex-row`.
  static const flexRow = 'flex-row';

  /// `flex-row-reverse`.
  static const flexRowReverse = 'flex-row-reverse';

  /// `flex-wrap`.
  static const flexWrap = 'flex-wrap';

  // -- Flex sizing --
  /// `flex-1`.
  static const flex1 = 'flex-1';

  /// `grow`.
  static const grow = 'grow';

  /// `grow-0`.
  static const growZero = 'grow-0';

  /// `shrink-0`.
  static const shrinkZero = 'shrink-0';

  // -- Align items --
  /// `items-baseline`.
  static const itemsBaseline = 'items-baseline';

  /// `items-center`.
  static const itemsCenter = 'items-center';

  /// `items-end`.
  static const itemsEnd = 'items-end';

  /// `items-start`.
  static const itemsStart = 'items-start';

  /// `items-stretch`.
  static const itemsStretch = 'items-stretch';

  // -- Justify content --
  /// `justify-around`.
  static const justifyAround = 'justify-around';

  /// `justify-between`.
  static const justifyBetween = 'justify-between';

  /// `justify-center`.
  static const justifyCenter = 'justify-center';

  /// `justify-end`.
  static const justifyEnd = 'justify-end';

  /// `justify-evenly`.
  static const justifyEvenly = 'justify-evenly';

  /// `justify-start`.
  static const justifyStart = 'justify-start';

  // -- Justify items --
  /// `justify-items-center`.
  static const justifyItemsCenter = 'justify-items-center';

  // -- Align self --
  /// `self-stretch`.
  static const selfStretch = 'self-stretch';

  // -- Position --
  /// `absolute`.
  static const absolute = 'absolute';

  /// `fixed`.
  static const fixed = 'fixed';

  /// `relative`.
  static const relative = 'relative';

  /// `sticky`.
  static const sticky = 'sticky';

  // -- Inset / translate --
  /// `-translate-x-1/2`.
  static const negTranslateXHalf = '-translate-x-1/2';

  /// `-translate-y-1/2`.
  static const negTranslateYHalf = '-translate-y-1/2';

  /// `bottom-0`.
  static const bottomZero = 'bottom-0';

  /// `inset-0`.
  static const insetZero = 'inset-0';

  /// `inset-x-0`.
  static const insetXZero = 'inset-x-0';

  /// `inset-y-0`.
  static const insetYZero = 'inset-y-0';

  /// `left-0`.
  static const leftZero = 'left-0';

  /// `left-1/2`.
  static const leftHalf = 'left-1/2';

  /// `right-0`.
  static const rightZero = 'right-0';

  /// `top-0`.
  static const topZero = 'top-0';

  /// `top-1/2`.
  static const topHalf = 'top-1/2';

  /// `top-full`.
  static const topFull = 'top-full';

  // -- Intrinsic size --
  /// `h-full`.
  static const hFull = 'h-full';

  /// `min-h-0`.
  static const minHZero = 'min-h-0';

  /// `max-w-full`.
  static const maxWFull = 'max-w-full';

  /// `min-w-fit` — `min-width: fit-content`: never narrower than its content
  /// laid out in the room it is given — its natural width, capped at that
  /// room, but never under its narrowest.
  static const minWFit = 'min-w-fit';

  /// `min-w-0`.
  static const minWZero = 'min-w-0';

  /// `w-1/2`.
  static const wHalf = 'w-1/2';

  /// `w-fit`.
  static const wFit = 'w-fit';

  /// `w-full`.
  static const wFull = 'w-full';

  /// `w-max`.
  static const wMax = 'w-max';

  // -- Overflow --
  /// `overflow-auto`.
  static const overflowAuto = 'overflow-auto';

  /// `overflow-hidden`.
  static const overflowHidden = 'overflow-hidden';

  /// `overflow-visible`.
  static const overflowVisible = 'overflow-visible';

  /// `overflow-x-auto`.
  static const overflowXAuto = 'overflow-x-auto';

  /// `overflow-x-hidden`.
  static const overflowXHidden = 'overflow-x-hidden';

  /// `overflow-y-auto`.
  static const overflowYAuto = 'overflow-y-auto';

  /// `overflow-y-hidden`.
  static const overflowYHidden = 'overflow-y-hidden';

  // -- Text wrap --
  /// `break-words`.
  static const breakWords = 'break-words';

  /// `truncate`.
  static const truncate = 'truncate';

  /// `whitespace-normal`.
  static const whitespaceNormal = 'whitespace-normal';

  /// `whitespace-nowrap`.
  static const whitespaceNowrap = 'whitespace-nowrap';

  /// `whitespace-pre`.
  static const whitespacePre = 'whitespace-pre';

  /// `whitespace-pre-wrap`.
  static const whitespacePreWrap = 'whitespace-pre-wrap';

  // -- Aspect --
  /// `aspect-square`.
  static const aspectSquare = 'aspect-square';

  // -- Interaction layout --
  /// `pointer-events-none`.
  static const pointerEventsNone = 'pointer-events-none';

  // -- Accessibility --
  /// `sr-only`.
  static const srOnly = 'sr-only';

  /// `sr-only fixed` — visually hidden text that also stays out of the
  /// document's scrollable overflow.
  ///
  /// Plain `sr-only` is `position: absolute` with no offsets, so it sits at its
  /// static position but is clipped by its nearest POSITIONED ancestor, not by
  /// the scroller it is inside. Put one in every item of a horizontal
  /// `overflow-x-auto` list and the page itself scrolls sideways (measured: a
  /// 500px page became 2432px wide with twenty items). `fixed` takes the box
  /// out of scrollable overflow and, like `absolute`, out of flex layout, so
  /// it still adds no gap. `fixed` wins over `sr-only`'s `absolute` because
  /// Tailwind emits the accessibility utilities before the position ones.
  static const srOnlyFixed = 'sr-only fixed';

  // -- Combo shortcuts (recurring multi-token patterns) --
  /// `absolute inset-0`.
  static const absoluteFull = 'absolute inset-0';

  /// `absolute h-full`.
  static const absoluteHFull = 'absolute h-full';

  /// `flex items-center justify-between`.
  static const flexBetween = 'flex items-center justify-between';

  /// `flex items-center justify-center`.
  static const flexCenter = 'flex items-center justify-center';

  /// `flex flex-col w-full`.
  static const flexColFull = 'flex flex-col w-full';

  /// `flex flex-col items-center`.
  static const flexColItemsCenter = 'flex flex-col items-center';

  /// `flex flex-col items-start`.
  static const flexColItemsStart = 'flex flex-col items-start';

  /// `flex flex-col items-stretch`.
  static const flexColItemsStretch = 'flex flex-col items-stretch';

  /// `flex w-full`.
  static const flexFull = 'flex w-full';

  /// `flex w-full items-center`.
  static const flexFullItemsCenter = 'flex w-full items-center';

  /// `flex items-center`.
  static const flexItemsCenter = 'flex items-center';

  /// `flex items-center w-full`.
  static const flexItemsCenterFull = 'flex items-center w-full';

  /// `flex items-start`.
  static const flexItemsStart = 'flex items-start';

  /// `flex justify-center`.
  static const flexJustifyCenter = 'flex justify-center';

  /// `flex flex-row items-center`.
  static const flexRowItemsCenter = 'flex flex-row items-center';

  /// `flex flex-row items-center w-full`.
  static const flexRowItemsCenterFull = 'flex flex-row items-center w-full';

  /// `flex flex-row items-start`.
  static const flexRowItemsStart = 'flex flex-row items-start';

  /// `flex flex-row items-start w-full`.
  static const flexRowItemsStartFull = 'flex flex-row items-start w-full';

  /// `flex flex-row items-stretch`.
  static const flexRowItemsStretch = 'flex flex-row items-stretch';

  /// `grid w-full`.
  static const gridFull = 'grid w-full';

  /// `grid grid-cols-1 h-full` — a wrapper that adds no geometry of its own.
  ///
  /// The Flutter twin of such a wrapper (`MouseRegion`, `Listener`, …) hands
  /// its parent's constraints to its child unchanged: a child under a tight
  /// height fills it, one under a loose height keeps its own. A plain block
  /// does neither — a fixed-height parent leaves the child at its own height,
  /// and an inline-level child opens a line box whose strut grows the block.
  /// A single-track grid does both the way Flutter does: the one
  /// `minmax(0, 1fr)` column keeps the block's fill-the-width behaviour, the
  /// auto row stretches to a definite parent height and the item stretches
  /// into it, and `h-full` is a no-op under an auto-height parent
  /// (percentage heights resolve to auto there).
  static const gridTransparent = 'grid grid-cols-1 h-full';

  /// `inline-flex items-center justify-center`.
  static const inlineFlexCenter = 'inline-flex items-center justify-center';

  /// `inline-flex items-center justify-center whitespace-nowrap`.
  static const inlineFlexCenterNoWrap =
      'inline-flex items-center justify-center whitespace-nowrap';

  /// `inline-flex w-full items-stretch`.
  static const inlineFlexFullItemsStretch = 'inline-flex w-full items-stretch';

  /// `inline-flex items-stretch` — content-fit sibling of
  /// [inlineFlexFullItemsStretch] (no `w-full`).
  static const inlineFlexItemsStretch = 'inline-flex items-stretch';

  /// `inline-flex items-center`.
  static const inlineFlexItemsCenter = 'inline-flex items-center';

  /// `inline-flex flex-row items-center`.
  static const inlineFlexRowItemsCenter = 'inline-flex flex-row items-center';

  /// `relative flex items-center w-full`.
  static const relativeFlexItemsCenterFull =
      'relative flex items-center w-full';

  /// `relative w-full`.
  static const relativeFull = 'relative w-full';

  /// `relative inline-block`.
  static const relativeInlineBlock = 'relative inline-block';

  /// `relative overflow-hidden`.
  static const relativeOverflowHidden = 'relative overflow-hidden';
}
