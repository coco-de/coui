/// Input type for `Input`.
library;

/// Platform-neutral text input type.
///
/// Maps to the HTML `<input type="...">` attribute on Web and to the
/// keyboard / obscuring behaviour on Flutter. Behavioural field — stays
/// flat on the widget.
enum CoreInputType {
  /// Plain single-line text.
  text('text'),

  /// Password (obscured) input.
  password('password'),

  /// Email address input.
  email('email'),

  /// Numeric input.
  number('number'),

  /// Telephone number input.
  tel('tel'),

  /// URL input.
  url('url'),

  /// Search input.
  search('search');

  const CoreInputType(this.htmlType);

  /// The HTML `type` attribute value for this input type.
  final String htmlType;

  /// Widget default input type. Flutter / Web `Input` constructors
  /// both reference this single source.
  static const CoreInputType defaultType = text;
}
