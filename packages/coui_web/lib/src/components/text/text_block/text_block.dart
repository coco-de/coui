import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_component.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart';

import 'text_block_style.dart';

/// A text styling wrapper component for web.
///
/// Renders a semantic HTML element ([CoreTextBlockElement] — `p`,
/// `span`, `h1`-`h6`, `blockquote`, etc.) with Tailwind CSS typography
/// presets. Use it for headings, paragraphs, quotes and inline text
/// utilities while keeping the document outline accessible.
///
/// Key features:
/// - **Semantic HTML**: renders the appropriate element for the role.
/// - **Typography presets**: pre-built heading / paragraph / utility
///   styles exposed as static helpers.
/// - **Rich text**: can contain child components for inline formatting.
/// - **Token-driven**: presets reference CoUI design tokens, not raw
///   Tailwind literals.
///
/// Example:
/// ```dart
/// TextBlock(
///   text: 'Hello World',
///   element: CoreTextBlockElement.h1,
///   presets: [TextBlock.heading1(context)],
/// )
/// TextBlock(
///   text: 'A muted subtitle',
///   presets: [TextBlock.muted(context)],
/// )
/// ```
class TextBlock extends UiComponent
    implements CoreTextBlockContract<Component> {
  /// Creates a [TextBlock] component.
  ///
  /// - [text]: text content to display. Ignored when [children] is set.
  /// - [element]: the semantic HTML element to render.
  /// - [presets]: typography presets applied to the root element.
  /// - [textBlockStyle]: per-instance override for the `blockquote` /
  ///   `pre` box chrome (border / radius / padding).
  /// - [children]: child components for rich-text content.
  const TextBlock({
    super.key,
    this.text,
    this.element = CoreTextBlockElement.defaultElement,
    this.presets,
    this.textBlockStyle,
    super.id,
    super.classes,
    super.css,
    super.attributes,
    super.eventHandlers,
    this.children,
  }) : super(tag: 'div');

  /// Text content to display. Ignored when [children] is provided.
  @override
  final String? text;

  /// The semantic HTML element to render.
  @override
  final CoreTextBlockElement element;

  /// Typography presets applied to the root element.
  ///
  /// Build presets with the static helpers below
  /// (`TextBlock.paragraph`, `TextBlock.heading1(context)`, …).
  final List<TextBlockStyle>? presets;

  /// Per-instance override for the `blockquote` / `pre` box chrome —
  /// accent-border colour / width, indent padding, surface fill and
  /// corner radius. Flows through [resolveTextBlock]'s merge chain.
  @override
  final CoreTextBlockStyle? textBlockStyle;

  @override
  final List<Component>? children;

  // --- Text presets (context-independent) ---

  /// Paragraph preset with comfortable line height.
  ///
  /// `leading-7` is a fixed `1.75rem` line-height (the prose paragraph
  /// standard). Not a design token — `CoreLineHeight` exposes unitless
  /// ratio multipliers (`h160` = 1.6×), not fixed-rem leading, so it
  /// cannot represent this value without changing the rendered metrics.
  static const TextBlockStyle paragraph = TextBlockStyle('leading-7');

  /// Bold text preset.
  static final TextBlockStyle bold = TextBlockStyle(
    'font-${CoreFontWeight.scale.bold}',
  );

  /// Italic text preset.
  static const TextBlockStyle italic = TextBlockStyle('italic');

  /// Blockquote preset.
  ///
  /// The left accent border (colour + width) + indent pull their values
  /// from `CoreTextBlockStyle` design-system defaults so Flutter and
  /// Web stay in sync. The border colour routes through the Web colour
  /// adapter (`tailwindColor` → `border-{outlineVariant}`, matching
  /// Flutter's `scheme.resolve(outlineVariant)`), the width through the
  /// stroke adapter (`tailwindStroke`), and the padding through the
  /// four-side `CoreEdgeInsets` adapter (`tailwindClasses('p')`) so
  /// symmetric and asymmetric overrides both round-trip cleanly. The
  /// design-system padding default is left-only — the other three sides
  /// emit `p[trb]-space0` (a no-op Tailwind class).
  static final TextBlockStyle quote = TextBlockStyle(
    // Logical sides, not left and right. A blockquote's rule and its
    // indent are both statements about the margin the text starts at —
    // in an Arabic locale that is the right, and a physical spelling put
    // the rule on one side and the indent on the other.
    'border-s-${CoreTextBlockStyle.defaultBlockQuoteBorderWidth.tailwindStroke} '
    'border-${CoreTextBlockStyle.defaultBlockQuoteBorderColor.tailwindColor} '
    '${CoreTextBlockStyle.defaultBlockQuotePadding.tailwindLogicalClasses('p')} '
    'italic',
  );

  /// Truncated text with ellipsis.
  static const TextBlockStyle truncate = TextBlockStyle(WebLayout.truncate);

  /// Text that wraps and breaks words.
  static const TextBlockStyle wrap = TextBlockStyle(WebLayout.breakWords);

  // --- Heading presets (context-dependent) ---

  /// Heading 1 preset.
  static TextBlockStyle heading1(BuildContext context) {
    return TextBlockStyle(
      'scroll-m-${CoreSpace.scale.space80} text-${CoreTextStyles.displaySmall.name} '
      'tracking-${CoreLetterSpacing.scale.tight}',
    );
  }

  /// Heading 2 preset.
  static TextBlockStyle heading2(BuildContext context) {
    return TextBlockStyle(
      'scroll-m-${CoreSpace.scale.space80} text-${CoreTextStyles.headlineLarge.name} '
      'tracking-${CoreLetterSpacing.scale.tight}',
    );
  }

  /// Heading 3 preset.
  static TextBlockStyle heading3(BuildContext context) {
    return TextBlockStyle(
      'scroll-m-${CoreSpace.scale.space80} text-${CoreTextStyles.headlineSmall.name} '
      'tracking-${CoreLetterSpacing.scale.tight}',
    );
  }

  /// Heading 4 preset.
  static TextBlockStyle heading4(BuildContext context) {
    return TextBlockStyle(
      'scroll-m-${CoreSpace.scale.space80} text-${CoreTextStyles.titleLarge.name} '
      'tracking-${CoreLetterSpacing.scale.tight}',
    );
  }

  /// Large text preset.
  static TextBlockStyle lg(BuildContext context) {
    return TextBlockStyle('text-${CoreTextStyles.titleMedium.name}');
  }

  /// Small text preset.
  static TextBlockStyle sm(BuildContext context) {
    return TextBlockStyle(
      'text-${CoreTextStyles.labelLarge.name} leading-none',
    );
  }

  /// Muted text preset.
  ///
  /// The muted foreground colour routes through the Web colour adapter
  /// (`tailwindColor` → `text-{onSurfaceVariant}`) so it stays in sync
  /// with Flutter's `scheme.resolve(onSurfaceVariant)`.
  static TextBlockStyle muted(BuildContext context) {
    return TextBlockStyle(
      'text-${CoreTextStyles.bodySmall.name} '
      'text-${CoreTextBlockStyle.defaultMutedForegroundColor.tailwindColor}',
    );
  }

  /// Lead text (subtitle) preset.
  ///
  /// Shares the `muted` foreground token so the subtitle colour stays a
  /// single source of truth with Flutter.
  static TextBlockStyle lead(BuildContext context) {
    return TextBlockStyle(
      'text-${CoreTextStyles.titleLarge.name} '
      'text-${CoreTextBlockStyle.defaultMutedForegroundColor.tailwindColor}',
    );
  }

  /// Inline code preset.
  ///
  /// The surface-box fill colour + radius + horizontal / vertical
  /// padding pull their values from `CoreTextBlockStyle` design-system
  /// defaults so Flutter (`_InlineCodeBox`) and Web stay in sync; the
  /// fill colour routes through the Web colour adapter (`tailwindColor`
  /// → `bg-{surfaceContainer}`, matching Flutter's
  /// `scheme.resolve(surfaceContainer)`) and the radius / padding
  /// through the Web radius / spacing adapters (`tailwindRadius` /
  /// `tailwindSpace`) rather than hardcoded arbitrary classes.
  static TextBlockStyle inlineCode(BuildContext context) {
    return TextBlockStyle(
      '${WebLayout.relative} rounded-${CoreTextBlockStyle.defaultInlineCodeRadius.tailwindRadius} '
      'bg-${CoreTextBlockStyle.defaultInlineCodeBackgroundColor.tailwindColor} '
      'px-${CoreTextBlockStyle.defaultInlineCodePadding.left.tailwindSpace} '
      'py-${CoreTextBlockStyle.defaultInlineCodePadding.top.tailwindSpace} '
      'font-${CoreFontFamily.scale.mono} text-${CoreTextStyles.bodySmall.name} '
      'font-${CoreFontWeight.scale.semibold}',
    );
  }

  @override
  Component build(BuildContext context) {
    final resolved = resolveTextBlock(
      context,
      element: element,
      presets: presets,
      textBlockStyle: textBlockStyle,
    );
    final currentText = text;
    final currentChildren = children;

    final contentChildren =
        currentChildren ??
        (currentText != null ? [Component.text(currentText)] : <Component>[]);

    return Component.element(
      tag: textBlockElementTag(element),
      id: id,
      classes: mergeClasses(resolved.root.className, this.classes),
      styles: css != null
          ? Styles.combine([?resolved.root.inlineStyles, css!])
          : resolved.root.inlineStyles,
      attributes: componentAttributes,
      events: events,
      children: contentChildren,
    );
  }

  @override
  TextBlock copyWith({
    String? id,
    String? classes,
    Styles? css,
    Map<String, String>? attributes,
    Map<String, List<UiEventHandler>>? eventHandlers,
    Key? key,
    String? text,
    CoreTextBlockElement? element,
    List<TextBlockStyle>? presets,
    CoreTextBlockStyle? textBlockStyle,
    List<Component>? children,
  }) {
    return TextBlock(
      key: key ?? this.key,
      text: text ?? this.text,
      element: element ?? this.element,
      presets: presets ?? this.presets,
      textBlockStyle: textBlockStyle ?? this.textBlockStyle,
      id: id ?? this.id,
      classes: mergeClasses(this.classes, classes),
      css: css ?? this.css,
      attributes: attributes ?? userProvidedAttributes,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      children: children ?? this.children,
    );
  }
}

/// Chain sugar mirroring the Flutter `TextBlock.withStyle` extension —
/// merges a [CoreTextBlockStyle] patch into [TextBlock.textBlockStyle]
/// via the existing [TextBlock.copyWith].
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreTextBlockStyle.merge` right-side-wins semantics).
///
/// ```dart
/// TextBlock(
///   text: 'Quoted text',
///   element: CoreTextBlockElement.blockquote,
/// ).withStyle(
///   CoreTextBlockStyle(blockQuoteBorderWidth: CoreStrokeWidth.stroke4),
/// )
/// ```
extension TextBlockStyleChain on TextBlock {
  /// Returns a copy of this [TextBlock] with [patch] merged into
  /// [textBlockStyle] (patch fields win on conflict).
  TextBlock withStyle(CoreTextBlockStyle patch) => copyWith(
    textBlockStyle: (textBlockStyle ?? const CoreTextBlockStyle()).merge(
      patch,
    ),
  );
}
