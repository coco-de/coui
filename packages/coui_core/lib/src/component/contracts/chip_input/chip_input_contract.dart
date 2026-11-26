/// Platform-independent contract for unified chip input components.
///
/// Defines the interface that all `ChipInput` implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/chip_input/chip_input_style.dart';
import 'package:coui_core/src/size/size.dart';

/// Contract for a unified chip input component.
///
/// `ChipInput` is a multi-value text input — users type text and press
/// Enter to add chips; each chip carries a remove button. The chip list
/// is a `List<String>` so the API is identical on Flutter and Web.
///
/// Per Epic #1302 chrome / dimensional overrides flow through the single
/// [chipInputStyle] slot. Behavioural / semantic fields (`chips`,
/// `placeholder`, `enabled`, `maxChips`, callbacks) stay flat.
///
/// Type parameters:
/// - [ChipsCb] — chip-list change callback `void Function(List<String>)?`.
/// - [SubmitCb] — text submit callback `void Function(String)?`.
abstract interface class CoreChipInputContract<ChipsCb, SubmitCb> {
  /// Current list of chip values.
  List<String> get chips;

  /// Placeholder text shown in the text-entry field.
  String? get placeholder;

  /// Whether the input is interactive.
  bool get enabled;

  /// Maximum number of chips allowed. `null` → unlimited.
  int? get maxChips;

  /// Called when the chip list changes (chip added / removed).
  ChipsCb get onChanged;

  /// Called when text is submitted (Enter pressed) with non-empty text.
  SubmitCb get onSubmitted;

  /// Splits pasted text into chip values.
  ///
  /// `null` — the default — leaves pasting alone: the text lands in the
  /// entry buffer and waits for Enter, exactly as it did before this
  /// existed. Supplying a splitter opts into "a paste becomes chips", so
  /// text with no separator in it becomes a single chip rather than
  /// sitting in the buffer.
  ///
  /// Values that come back empty (or whitespace-only) are dropped, and
  /// `maxChips` still caps the result — a paste cannot overfill a field a
  /// caller has bounded.
  ///
  /// The signature is byte-identical on both platforms, so it needs no
  /// type parameter of its own.
  List<String> Function(String pasted)? get pasteSplitter;

  /// The width the inline entry field needs, padding included (logical px),
  /// before it may share a row with the chips — a usability floor for the
  /// editable region, not a design token. A field that cannot get this much
  /// of the current row opens the next one. Past the floor the field is not
  /// sized by its text: it takes whatever is left of its row, so a long tag
  /// typed into it scrolls inside the field and never moves it to another
  /// row.
  ///
  /// One constant both platforms read, so the two break rows alike.
  static const double defaultInputMinWidth = CoreSize.size80;

  /// A [pasteSplitter] that cuts on [separator].
  ///
  /// Shared so the two platforms and the docs examples run one
  /// implementation rather than three that drift. Trimming and
  /// empty-dropping happen where the paste is applied, so this stays a
  /// plain split.
  static List<String> Function(String) splitOn(Pattern separator) =>
      (pasted) => pasted.split(separator);

  /// A [pasteSplitter] that cuts on commas, semicolons, newlines and tabs.
  ///
  /// The separators a list of addresses or tags arrives with when it is
  /// copied out of a mail client, a spreadsheet or a text file.
  static List<String> splitOnCommonSeparators(String pasted) =>
      pasted.split(RegExp(r'[,;\n\r\t]'));

  /// The chip list [existing] becomes when [pasted] is split by
  /// [splitter].
  ///
  /// Both platforms route their paste through here so the trimming, the
  /// empty-dropping and the [maxChips] cap are one implementation rather
  /// than two that agree until someone edits one of them.
  ///
  /// Returns [existing] unchanged when the paste contributes nothing —
  /// callers can compare identity to decide whether to notify.
  static List<String> chipsAfterPaste({
    required List<String> existing,
    required String pasted,
    required List<String> Function(String) splitter,
    int? maxChips,
  }) {
    final additions = splitter(
      pasted,
    ).map((value) => value.trim()).where((value) => value.isNotEmpty);

    final room = maxChips == null
        ? additions.length
        : maxChips - existing.length;
    if (room <= 0) return existing;

    final accepted = additions.take(room).toList();

    return accepted.isEmpty ? existing : [...existing, ...accepted];
  }

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreChipInputTheme.style
  ///   → parent component slot override
  ///   → widget.chipInputStyle
  /// ```
  CoreChipInputStyle? get chipInputStyle;
}
