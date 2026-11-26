/// Word-boundary arithmetic for caret-relative editing.
///
/// Lives in `coui_core` because both platforms need the identical answer:
/// the Flutter `Autocomplete` reads the caret from its
/// `TextEditingController`, the Web one from the DOM `selectionStart`, but
/// the word they compute from it must not be allowed to drift apart. A
/// per-platform copy is the definition of that drift.
///
/// These are pure string arithmetic, not platform emit vocabulary, so Core
/// is their correct home.
library;

/// The start offset of the word under the caret, and the word itself.
typedef WordInfo = (int, String);

/// The start offset of the replaced word, and the resulting full text.
typedef ReplacementInfo = (int, String);

/// Returns the word surrounding [caret] in [text], with its start offset.
///
/// A "word" runs between the nearest [separator] characters on either side
/// of the caret. [separator] is a *set* of characters, not a delimiter
/// string — every character in it terminates a word.
///
/// Throws a [RangeError] when [caret] falls outside [text].
WordInfo getWordAtCaret(int caret, String text, [String separator = ' ']) {
  if (caret < 0 || caret > text.length) {
    throw RangeError('Caret position is out of bounds.');
  }

  int start = caret;
  while (start > 0 && !separator.contains(text[start - 1])) {
    start -= 1;
  }

  int end = caret;
  while (end < text.length && !separator.contains(text[end])) {
    end += 1;
  }

  return (start, text.substring(start, end));
}

/// Replaces the word surrounding [caret] in [text] with [replacement].
///
/// Returns the start offset of the replaced word together with the full
/// resulting text; the caller places the caret at
/// `start + replacement.length` to land just past what it inserted.
///
/// Throws a [RangeError] when [caret] falls outside [text].
ReplacementInfo replaceWordAtCaret(
  int caret,
  String replacement,
  String text, [
  String separator = ' ',
]) {
  if (caret < 0 || caret > text.length) {
    throw RangeError('Caret position is out of bounds.');
  }

  int start = caret;
  while (start > 0 && !separator.contains(text[start - 1])) {
    start -= 1;
  }

  int end = caret;
  while (end < text.length && !separator.contains(text[end])) {
    end += 1;
  }

  return (start, text.replaceRange(start, end, replacement));
}
