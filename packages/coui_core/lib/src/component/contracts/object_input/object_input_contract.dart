/// Platform-independent contract for unified object input components.
library;

import 'package:coui_core/src/component/contracts/object_input/object_input_field.dart';
import 'package:coui_core/src/component/contracts/object_input/object_input_style.dart';

/// Contract for a unified key-value object input component.
///
/// `ObjectInput` renders a row of structured key-value fields
/// separated by an optional [separator], emitting a `Map<String,
/// String>` of field key → value. It is the structured-data sibling of
/// `FormattedInput` (which masks a single string).
///
/// Per Epic #1302 chrome / dimensional overrides flow through the single
/// [objectInputStyle] slot. Behavioural / semantic fields (`fields`,
/// `values`, `separator`, `enabled`, `onChanged`, `leading`, `trailing`)
/// stay flat.
///
/// Type parameters:
/// - [Cb] — change callback type derived as
///   `void Function(Map<String, String>)?`.
/// - [W] — widget type of the `leading` / `trailing` composition slots.
abstract interface class CoreObjectInputContract<Cb, W> {
  /// Default upper bound (inclusive) of the short-field `maxLength`
  /// bucket. Shared by the Flutter / Web widget const constructors so a
  /// field with `maxLength: 2` lands in the same bucket on both.
  ///
  /// A `maxLength` bucket boundary decides *which* width applies, not
  /// what any width is — nothing is painted at this value, so it lives
  /// on the widget plane (`core/style-contract.md`: Style slots carry
  /// visual chrome only) rather than in `CoreObjectInputStyle`.
  static const int defaultShortFieldMaxChars = 2;

  /// Default upper bound (inclusive) of the medium-field `maxLength`
  /// bucket. See [defaultShortFieldMaxChars] for why this is a widget
  /// parameter and not a Style field.
  static const int defaultMediumFieldMaxChars = 4;

  /// The structured field definitions.
  List<CoreObjectInputField> get fields;

  /// Upper bound (inclusive) of the short-field `maxLength` bucket — a
  /// field whose `maxLength` is at most this wide uses the short
  /// bucket's max-width.
  int get shortFieldMaxChars;

  /// Upper bound (inclusive) of the medium-field `maxLength` bucket.
  /// Fields wider than this use the long bucket's max-width.
  int get mediumFieldMaxChars;

  /// Initial values map (field key → value).
  Map<String, String>? get values;

  /// Text displayed between adjacent fields, or `null` for none.
  String? get separator;

  /// Whether the input is interactive.
  bool get enabled;

  /// Called whenever any field value changes — receives the full map.
  Cb get onChanged;

  /// Optional widget displayed before the fields.
  W? get leading;

  /// Optional widget displayed after the fields.
  W? get trailing;

  /// Per-instance chrome / dimensional style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreObjectInputTheme.style
  ///   → parent component slot override
  ///   → widget.objectInputStyle
  /// ```
  CoreObjectInputStyle? get objectInputStyle;
}
