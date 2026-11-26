/// Platform-neutral AsYouType masking engine for `FormattedInput`.
///
/// `CoreFormattedInputMaskEngine` turns a raw platform edit (old text +
/// selection, new text + selection, exactly as reported by a native
/// `TextField`/`<input>`) into a single reformatted value with a correct
/// caret position. Both Flutter (`TextInputFormatter.formatEditUpdate`)
/// and Web (native `input` event) feed the same old/new value pair into
/// [CoreFormattedInputMaskEngine.apply] so a phone / credit-card / custom
/// mask behaves identically on both platforms — one real input, no
/// segment-to-segment focus jumps, natural backspace through literals.
///
/// This does not reuse `CoreInputFormatter` — that contract is explicitly
/// selection-blind ("It never touches selection / cursor state"), while
/// deleting the digit before a literal (rather than the literal itself)
/// is only representable with old *and* new cursor position in hand.
library;

import 'package:coui_core/src/component/contracts/formatted_input/formatted_input_part.dart';
import 'package:meta/meta.dart';

/// A text value plus its selection, as reported by a native text field.
///
/// [selectionStart] and [selectionEnd] are equal for a collapsed caret.
@immutable
class CoreFormattedInputEditValue {
  /// Creates a [CoreFormattedInputEditValue].
  const CoreFormattedInputEditValue({
    required this.text,
    required this.selectionStart,
    required this.selectionEnd,
  });

  /// The full text content.
  final String text;

  /// Start offset of the selection (or the caret, if collapsed).
  final int selectionStart;

  /// End offset of the selection (or the caret, if collapsed).
  final int selectionEnd;
}

/// The result of applying a mask edit: the reformatted text, the raw
/// (literal-free) value, and where the caret belongs in the new text.
@immutable
class CoreFormattedInputEditResult {
  /// Creates a [CoreFormattedInputEditResult].
  const CoreFormattedInputEditResult({
    required this.text,
    required this.cursorOffset,
    required this.rawValue,
  });

  /// The reformatted display text (literals inserted, editable slots
  /// filled up to however much the user has typed).
  final String text;

  /// Caret offset within [text] after the edit.
  final int cursorOffset;

  /// Concatenated content of all editable segments, with no literals —
  /// this is `CoreFormattedInputContract.value`.
  final String rawValue;
}

/// One position in the flattened mask template: either a fixed literal
/// character or an editable slot constrained by an optional pattern.
@immutable
class _MaskSlot {
  const _MaskSlot.literal(String char) : _char = char, pattern = null;

  const _MaskSlot.editable(this.pattern) : _char = null;

  /// The literal character this slot renders, or `null` for an editable
  /// slot.
  final RegExp? pattern;

  final String? _char;

  bool get isLiteral => _char != null;

  String get literalChar => _char!;
}

/// Turns platform text-field edits into single-field masked output.
///
/// `parts` is the same `List<CoreFormattedInputPart>` the widget already
/// receives — nothing about the public mask API changes. This engine only
/// changes how that list drives a *single* editable field instead of one
/// field per segment.
abstract final class CoreFormattedInputMaskEngine {
  const CoreFormattedInputMaskEngine._();

  /// Formats [rawValue] (editable-slot content only, no literals) against
  /// [parts], stopping as soon as the raw content runs out — a literal is
  /// only emitted once the digit that follows it has been typed, exactly
  /// like a native AsYouType phone/card field.
  static String format(List<CoreFormattedInputPart> parts, String rawValue) {
    final template = _buildTemplate(parts);
    final raw = [for (var i = 0; i < rawValue.length; i++) rawValue[i]];
    return _formatFromRaw(raw, template);
  }

  /// Applies a single platform edit and returns the reformatted result.
  ///
  /// [oldValue] is the value immediately before this edit (always a
  /// previously-formatted string, or empty). [newValue] is exactly what
  /// the native widget produced *before* any of our formatting ran — the
  /// user's keystroke/paste/deletion already applied to the old text.
  static CoreFormattedInputEditResult apply({
    required List<CoreFormattedInputPart> parts,
    required CoreFormattedInputEditValue oldValue,
    required CoreFormattedInputEditValue newValue,
  }) {
    final template = _buildTemplate(parts);
    final capacity = template.where((slot) => !slot.isLiteral).length;

    final oldRaw = _extractRawFromFormatted(oldValue.text, template);
    final newRawFromEdit = _extractRawCandidates(newValue.text, template);
    final isDeletion = newValue.text.length < oldValue.text.length;

    List<String> newRaw;
    int rawCursorIndex;

    if (isDeletion &&
        newRawFromEdit.length >= oldRaw.length &&
        oldRaw.isNotEmpty) {
      // The character(s) removed at the platform level were exclusively
      // literals (the raw digit stream did not shrink even though the
      // text did) — a Backspace that landed on/around a literal boundary.
      // Deleting nothing would be a dead keystroke, so the nearest raw
      // character before the old caret is dropped instead (DDR-05).
      final oldCursorRawCount = _extractRawCandidates(
        oldValue.text.substring(
          0,
          oldValue.selectionStart.clamp(0, oldValue.text.length),
        ),
        template,
      ).length;
      final dropIndex = (oldCursorRawCount - 1).clamp(0, oldRaw.length - 1);
      newRaw = [
        for (var i = 0; i < oldRaw.length; i++)
          if (i != dropIndex) oldRaw[i],
      ];
      rawCursorIndex = dropIndex;
    } else {
      newRaw = newRawFromEdit;
      rawCursorIndex = _extractRawCandidates(
        newValue.text.substring(
          0,
          newValue.selectionStart.clamp(0, newValue.text.length),
        ),
        template,
      ).length;
    }

    if (newRaw.length > capacity) {
      newRaw = newRaw.sublist(0, capacity);
    }
    rawCursorIndex = rawCursorIndex.clamp(0, newRaw.length);

    final formatted = _formatFromRaw(newRaw, template);
    final cursorOffset = _formatFromRaw(
      newRaw.sublist(0, rawCursorIndex),
      template,
    ).length;

    return CoreFormattedInputEditResult(
      text: formatted,
      cursorOffset: cursorOffset,
      rawValue: newRaw.join(),
    );
  }

  static List<_MaskSlot> _buildTemplate(List<CoreFormattedInputPart> parts) {
    return [
      for (final part in parts)
        if (part.editable)
          for (var i = 0; i < part.length; i++)
            _MaskSlot.editable(
              part.pattern == null ? null : RegExp(part.pattern!),
            )
        else
          for (var i = 0; i < (part.text ?? '').length; i++)
            _MaskSlot.literal((part.text ?? '')[i]),
    ];
  }

  /// Walks [raw] in order, auto-inserting literals as soon as the digit
  /// that follows them is placed, and stopping once [raw] is exhausted —
  /// never emitting a trailing literal or placeholder for input the user
  /// has not typed yet.
  static String _formatFromRaw(List<String> raw, List<_MaskSlot> template) {
    final buffer = StringBuffer();
    var templateIndex = 0;
    for (final char in raw) {
      while (templateIndex < template.length &&
          template[templateIndex].isLiteral) {
        buffer.write(template[templateIndex].literalChar);
        templateIndex++;
      }
      if (templateIndex >= template.length) break;
      buffer.write(char);
      templateIndex++;
    }
    return buffer.toString();
  }

  /// Extracts raw editable-slot content from a string that is already a
  /// valid [_formatFromRaw] output — every character lines up with the
  /// template at the same index, so this is a direct positional zip
  /// rather than a pattern search.
  static List<String> _extractRawFromFormatted(
    String formatted,
    List<_MaskSlot> template,
  ) {
    final length = formatted.length < template.length
        ? formatted.length
        : template.length;
    return [
      for (var i = 0; i < length; i++)
        if (!template[i].isLiteral) formatted[i],
    ];
  }

  /// Extracts characters from an *unformatted* edit result that could
  /// plausibly belong to some editable slot in [template] — i.e. matches
  /// at least one editable part's [CoreFormattedInputPart.pattern] (an
  /// unconstrained slot accepts anything that is not itself one of the
  /// mask's own literal characters). Characters matching neither are
  /// dropped, exactly like `FilteringTextInputFormatter.allow`.
  static List<String> _extractRawCandidates(
    String text,
    List<_MaskSlot> template,
  ) {
    return [
      for (var i = 0; i < text.length; i++)
        if (_matchesAnyEditableSlot(text[i], template)) text[i],
    ];
  }

  static bool _matchesAnyEditableSlot(String char, List<_MaskSlot> template) {
    final literalChars = {
      for (final slot in template)
        if (slot.isLiteral) slot.literalChar,
    };
    for (final slot in template) {
      if (slot.isLiteral) continue;
      final pattern = slot.pattern;
      if (pattern == null) {
        if (!literalChars.contains(char)) return true;
      } else if (pattern.hasMatch(char)) {
        return true;
      }
    }
    return false;
  }
}

/// Platform-neutral autofill intent for a `FormattedInput` mask preset.
///
/// Flutter and Web adapters translate each value into their own
/// vocabulary (`AutofillHints.*` / the HTML `autocomplete` attribute) —
/// `coui_core` stays free of both. See `core/style-contract.md` → "Enum
/// self-conversion + 어휘 extension 분리".
enum CoreFormattedInputAutofillHint {
  /// The mask represents a telephone number.
  telephoneNumber,

  /// The mask represents a credit-card number.
  creditCardNumber,
}
