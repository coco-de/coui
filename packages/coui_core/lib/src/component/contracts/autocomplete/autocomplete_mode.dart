/// Suggestion application mode for `Autocomplete`.
library;

/// Text replacement strategy when an autocomplete suggestion is picked.
///
/// Behavioural field — stays flat on the widget.
enum CoreAutocompleteMode {
  /// Replace the entire input text with the selected suggestion.
  replaceAll,

  /// Replace only the current word with the selected suggestion.
  replaceWord,

  /// Append the selected suggestion to the existing text.
  append;

  /// Widget default mode. Flutter / Web `Autocomplete` constructors
  /// both reference this single source.
  static const CoreAutocompleteMode defaultMode = replaceWord;
}
