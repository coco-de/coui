/// Platform-independent contract for text area components.
library;

import 'package:characters/characters.dart';
import 'package:coui_core/src/component/callback_types.dart';
import 'package:coui_core/src/component/contracts/text_area/text_area_style.dart';
import 'package:coui_core/src/component/contracts/text_area/text_area_variant.dart';
import 'package:coui_core/src/size/component_size.dart';
import 'package:coui_core/src/size/retiring_size.dart';
import 'package:coui_core/src/spacing/edge_insets.dart';
import 'package:coui_core/src/spacing/spacing.dart';
import 'package:coui_core/src/typography/text_overflow.dart';

/// Contract for a multi-line text area component.
///
/// `TextArea` owns its own [CoreTextAreaStyle] (Epic #1696 #1698 — sibling
/// to `TextField` but with its own chrome). Multi-line specifics
/// (`rows` / `expandableHeight` / `expandableWidth`) live on the contract
/// as behaviour flags rather than inside the Style.
///
/// Type parameters:
/// - [W] — platform widget type (Flutter `Widget`, Web `Component`).
/// - [Ctrl] — text editing controller
///   (Flutter `TextEditingController?`, Web `Null`).
/// - [Focus] — focus node type
///   (Flutter `FocusNode?`, Web `Null`).
/// - [TapOutCb] — tap-outside callback (Flutter `TapRegionCallback`, Web
///   `void Function()`). The web listens on the document rather than
///   inside a tap region, so its binding carries no event argument.
/// - [InputFmt] — input formatter list (Flutter
///   `List<TextInputFormatter>`, Web `List<CoreInputFormatter>`).
abstract interface class CoreTextAreaContract<
  W,
  Ctrl,
  Focus,
  TapOutCb,
  InputFmt
> {
  /// The sizes this area is retiring — handed to `noticeRetiringSize`
  /// by both platform resolvers, which log it once wherever asserts are on.
  ///
  /// `xs` (announced in coui_core 0.141): from coui_core 0.153 at the
  /// earliest its ladder row is gone, so `xs` renders the `sm` row and a
  /// run with asserts on stops on it.
  static const List<CoreRetiringSize> retiringSizes = [
    CoreRetiringSize(
      size: CoreComponentSize.xs,
      fallback: CoreComponentSize.sm,
      removedIn: '0.153',
    ),
  ];

  // === Behaviour defaults (project-wide policy — single source) ===
  //
  // Input-policy booleans are not chrome, so they live on the contract
  // as `static const` (not in `CoreTextAreaTheme`, which is
  // `{style, variantStyles}` only). Both platform widgets default their
  // constructor flags to these so Flutter ↔ Web stay in sync.

  /// Default for selecting all text on focus.
  static const bool defaultSelectAllOnFocus = false;

  /// Default for [showCounter] — no count unless the caller asks (#5747).
  static const bool defaultShowCounter = false;

  /// The character count [showCounter] shows for [text] — `n / max` with a
  /// [maxLength], `n` without (#5747). Counted in grapheme clusters, so an
  /// emoji or a composed Hangul syllable is one character, the unit the
  /// person typing sees. One function both platforms call, so the two
  /// counts cannot read differently.
  static String counterLabel(String text, {int? maxLength}) {
    final count = text.characters.length;
    return maxLength == null ? '$count' : '$count / $maxLength';
  }

  /// Autocorrect where the platform has nothing to infer from.
  ///
  /// Not a constructor default — [autocorrect] is nullable so null can
  /// mean "the platform decides". This is the value a platform falls back
  /// to when it has no inference of its own, which on the web is always.
  static const bool defaultAutocorrect = true;

  /// Default for showing input method suggestions.
  static const bool defaultEnableSuggestions = true;

  /// Default for enabling interactive text selection.
  static const bool defaultEnableInteractiveSelection = true;

  /// Default for enabling IME personalised learning.
  static const bool defaultEnableIMEPersonalizedLearning = true;

  /// Default for stylus handwriting input.
  static const bool defaultStylusHandwritingEnabled = true;

  /// Default for cursor opacity animation (blink).
  static const bool defaultCursorOpacityAnimates = true;

  /// Character drawn in place of each glyph while the area is obscured.
  ///
  /// The round dot is the one mask shape both platforms draw natively —
  /// Flutter paints the character, the web maps it to
  /// `-webkit-text-security: disc`.
  static const String defaultObscuringCharacter = '•';

  /// Default inset used when the field is scrolled into view — 20
  /// logical/CSS px on all four sides. Shared by the Flutter / Web
  /// widget const constructors.
  ///
  /// Flutter hands this to `EditableText.scrollPadding`, whose own doc
  /// calls it the padding around the scrollable when the field is
  /// scrolled into view; nothing is painted at any value, so it lives on
  /// the widget plane (`core/style-contract.md`: Style slots carry
  /// visual chrome only) rather than in `CoreTextAreaStyle`.
  static const CoreEdgeInsets defaultScrollPadding = CoreEdgeInsets.all(
    CoreSpace.space20,
  );

  // === Content ===

  /// Placeholder text displayed when the text area is empty.
  String? get placeholder;

  /// Initial text value for uncontrolled mode.
  String? get initialValue;

  /// Callback when the text value changes.
  CoreValueChanged<String>? get onChanged;

  /// Callback when the text is submitted (blur on Web / submitted on Flutter).
  CoreValueChanged<String>? get onSubmitted;

  // === Input state ===

  /// Whether the text area is enabled for user interaction.
  bool get enabled;

  /// Inset kept clear when the field is scrolled into view. Behaviour,
  /// not chrome — Flutter forwards it to `EditableText.scrollPadding`
  /// and Web emits it as the input's `scroll-padding`; neither paints
  /// anything.
  CoreEdgeInsets get scrollPadding;

  /// Whether the text area is read-only.
  bool get readOnly;

  /// Whether the text area should automatically receive focus.
  bool get autofocus;

  /// Whether to select all existing text when the text area receives focus.
  bool get selectAllOnFocus;

  /// Whether to enable autocorrect during typing, or null to let the
  /// platform infer it.
  ///
  /// Null is the useful default rather than a missing value: Flutter reads
  /// the autofill hints and turns autocorrect off for a username or
  /// password field, and a stated `true` silently replaces that.
  ///
  /// An obscured text area disables autocorrect regardless of what is
  /// stated here.
  bool? get autocorrect;

  /// Whether to show input method suggestions.
  bool get enableSuggestions;

  /// Whether interactive selection is enabled.
  bool get enableInteractiveSelection;

  /// Whether IME personalised learning is enabled.
  bool get enableIMEPersonalizedLearning;

  /// Whether stylus handwriting input is enabled.
  bool get stylusHandwritingEnabled;

  /// Whether the cursor blink opacity animates.
  bool get cursorOpacityAnimates;

  /// Spell check configuration.
  ///
  /// Ignored while the area is obscured — spell check sends the text to a
  /// platform service, and an obscured area's text must not go there.
  ///
  /// Flutter: `SpellCheckConfiguration?`. Web: `Object?` — the web states
  /// spell check as an element attribute rather than a configuration
  /// object, so this stays null there and the attribute carries it.
  Object? get spellCheckConfiguration;

  /// The loupe shown while dragging a selection on touch.
  ///
  /// Flutter: `TextMagnifierConfiguration?` — null picks the platform's own
  /// magnifier. Web: `Object?`, always null — the browser draws its own
  /// selection loupe on touch devices.
  Object? get magnifierConfiguration;

  // === Semantic identity (widget params, not chrome) ===

  /// The visual size variant.
  ///
  /// `xs` is accepted but retiring on this field (since 0.141) — see
  /// `CoreTextAreaStyle.defaultsBySize` for why and [retiringSizes] for
  /// when. Until its row is removed (coui_core 0.153 at the earliest) it
  /// still renders its own row, so passing it is not an error (a run with
  /// asserts on logs a notice once); new call sites should pick `sm`
  /// instead.
  CoreComponentSize get size;

  /// The visual variant — [CoreTextAreaVariant.defaultTextAreaVariant] or
  /// [CoreTextAreaVariant.filled] (#5747). A set [errorText] outranks it
  /// while the area is enabled ([CoreTextAreaVariant.of]).
  CoreTextAreaVariant get variant;

  // === Style (chrome / dimensional / cursor / slot text + icon) ===

  /// Per-instance style covering chrome + dimensional + cursor +
  /// resize handle + nested label / placeholder / value / description /
  /// error text styles. text_area owns its own Style (sibling to
  /// text_field, not wrapping it).
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default for variant
  ///   → CoreTextAreaTheme.style
  ///   → CoreTextAreaTheme.variantStyles[variant]
  ///   → parent component slot override
  ///   → widget.textAreaStyle
  /// ```
  CoreTextAreaStyle? get textAreaStyle;

  // === Validation / Meta ===

  /// Label text displayed above the text area.
  String? get label;

  /// Maximum number of lines for [label] before it overflows.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  int? get labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  CoreTextOverflow? get labelOverflow;

  /// Description/helper text below the text area.
  String? get description;

  /// Error message. When non-null, the error variant is used.
  String? get errorText;

  /// Whether the text area is required.
  bool get required;

  /// Form field name for submission.
  String? get name;

  // === Text behaviour ===

  /// Maximum number of characters allowed.
  int? get maxLength;

  /// Whether the helper row ends in a character count (#5747) — `n / max`
  /// when [maxLength] is set, `n` otherwise. Off by default
  /// ([defaultShowCounter]).
  bool get showCounter;

  /// Number of visible text rows.
  ///
  /// On Web, maps to the HTML `rows` attribute.
  /// On Flutter, used as `minLines` for the internal editable.
  int? get rows;

  /// Whether the text being edited is obscured (password mode).
  ///
  /// HTML has no masked multi-line *control*, but it has a masked
  /// *rendering*: `-webkit-text-security` replaces every glyph with a
  /// shape. Both platforms therefore keep an obscured area's text away
  /// from the platform text services — spell check, autocorrect, the
  /// keyboard dictionary.
  ///
  /// **Reach, stated honestly**: `-webkit-text-security` is non-standard
  /// and implemented by Blink and WebKit only. On an engine without it the
  /// text services are still suppressed, but the glyphs render in the
  /// clear — so a Web multi-line password field is not masked everywhere.
  /// Use a single-line `TextField` (native `<input type="password">`) when
  /// masking has to hold on every engine. This is a platform reach limit,
  /// not a wiring gap: the emit is correct and tested, and the failure is
  /// invisible to review because the rendering looks right wherever the
  /// property is supported.
  bool get obscureText;

  /// Character drawn in place of each glyph while [obscureText] is true.
  ///
  /// Flutter paints this character literally. The web expresses masking as
  /// one of three shapes, so a character outside `•` (disc), `◦` / `○`
  /// (circle) and `▪` / `■` (square) renders there as the nearest shape.
  /// [defaultObscuringCharacter] is the dot both platforms draw exactly.
  String get obscuringCharacter;

  // === Cursor ===

  /// Whether to show the text cursor, or null to defer to the platform.
  bool? get showCursor;

  // === Keyboard ===

  /// Keyboard type.
  ///
  /// Flutter: `TextInputType?`. Web: `String?` — the HTML `inputmode`
  /// attribute value, which is how a browser picks the on-screen keyboard.
  Object? get keyboardType;

  /// Action key shown on the software keyboard.
  ///
  /// Flutter: `TextInputAction?`. Web: `String?` — the HTML `enterkeyhint`
  /// attribute value.
  Object? get textInputAction;

  /// Automatic capitalisation behaviour.
  ///
  /// Flutter: `TextCapitalization`. Web: `String?` — the HTML
  /// `autocapitalize` attribute value.
  ///
  /// An obscured area capitalises nothing on either platform: the
  /// keyboard's dictionary is one of the services [obscureText] closes.
  Object? get textCapitalization;

  // === Input formatting ===

  /// Formatters applied to the text as it changes.
  ///
  /// Flutter: `List<TextInputFormatter>?`.
  /// Web: `List<CoreInputFormatter>?`.
  InputFmt? get inputFormatters;

  // === Callbacks ===

  /// Called when editing completes.
  ///
  /// On the web this is the `change` event, which a `<textarea>` fires on
  /// commit (blur) — Enter inserts a newline in a text area rather than
  /// submitting, so there is no key to key on.
  CoreVoidCallback? get onEditingComplete;

  /// Called when the text area is tapped.
  CoreVoidCallback? get onTap;

  /// Called when a pointer goes down outside the text area.
  ///
  /// Flutter: `TapRegionCallback?`. Web: `void Function()?` — a document
  /// `pointerdown` listener that skips events inside the area's own root.
  TapOutCb? get onTapOutside;

  // === Resize callbacks ===

  /// Called with the area's new height when the user resizes it
  /// vertically — logical pixels on Flutter, CSS pixels on the web.
  ///
  /// Fires only while [expandableHeight] is true. A height change the
  /// user did not drag (a reflow, a font swap) is not a resize, and
  /// reporting it would make the callback mean something different on
  /// each platform.
  CoreValueChanged<double>? get onHeightChanged;

  /// Called with the area's new width when the user resizes it
  /// horizontally. Fires only while [expandableWidth] is true — see
  /// [onHeightChanged] for why the axis gates it.
  CoreValueChanged<double>? get onWidthChanged;

  // === Prefix/Suffix ===

  /// Widget displayed before the text content.
  W? get prefix;

  /// Widget displayed after the text content.
  W? get suffix;

  // === Footer ===

  /// One line under the text, inside the area's box — the actions and
  /// accessories that go with what is being written (send, attach). What
  /// goes in it is the caller's; the area only places it,
  /// [CoreTextAreaStyle.footerGapStyle] below the text and inside the same
  /// padding.
  ///
  /// The footer is not part of the editing surface. A tap on it reaches its
  /// own content and neither places a caret nor takes focus — on the web it
  /// sits outside the `<textarea>`, so Flutter keeps it outside its text
  /// gestures for the two to agree. It is still inside the field for
  /// [onTapOutside]: a tap on a footer action is not a tap away from the
  /// area.
  W? get footer;

  // === Resize ===

  /// Whether the text area can be resized vertically.
  bool get expandableHeight;

  /// Whether the text area can be resized horizontally.
  bool get expandableWidth;

  // === Controllers (Flutter only) ===

  /// Controller for the text content.
  Ctrl get controller;

  /// Focus node for keyboard focus management.
  Focus get focusNode;
}
