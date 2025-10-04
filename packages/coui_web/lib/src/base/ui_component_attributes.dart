// ignore_for_file: avoid_collection_mutating_methods, avoid_missing_interpolation

/// A builder class for creating a map of HTML attributes.
///
/// This utility helps in constructing the `Map<String, String>` of attributes
/// that can be passed to UI components. It provides convenient methods for
/// adding
/// common types of attributes, such as standard HTML attributes, ARIA
/// attributes, and data attributes.
///
/// Example:
/// ```dart
/// final attributesBuilder = UiComponentAttributes()
///   ..add('tabindex', '0')
///   ..addAria('label', 'Close button')
///   ..addData('testid', 'submit-action')
///   ..addRole('button');
///
/// final Map<String, String> htmlAttributes = attributesBuilder.build();
/// ```
class UiComponentAttributes {
  /// Creates an instance of [UiComponentAttributes].
  ///
  /// An optional [initialAttributes] map can be provided to pre-populate
  /// the builder.
  UiComponentAttributes([Map<String, String>? initialAttributes])
    : _attributes = initialAttributes == null
          ? <String, String>{}
          : Map.of(initialAttributes);

  final Map<String, String> _attributes;

  /// Adds a standard HTML attribute.
  ///
  /// If an attribute with the same [name] already exists, its value will be
  /// overwritten.
  ///
  /// [name]: The name of the attribute (e.g., "href", "target").
  /// [value]: The value of the attribute.
  void add(String name, String value) {
    _attributes[name] = value; // ignore: avoid-collection-mutating-methods - Builder pattern requires mutation
  }

  /// Adds an ARIA (Accessible Rich Internet Applications) attribute.
  /// The 'aria-' prefix will be automatically prepended to the [name].
  ///
  /// Example: `addAria('label', 'Description')` results in
  /// `aria-label="Description"`.
  /// If an attribute with the same 'aria-[name]' already exists, its value
  /// will be overwritten.
  ///
  /// [name]: The ARIA attribute name without the 'aria-' prefix (e.g.,
  /// "label", "hidden").
  /// [value]: The value of the ARIA attribute.
  void addAria(String name, String value) {
    _attributes['aria-$name'] = value; // ignore: avoid-collection-mutating-methods - Builder pattern requires mutation
  }

  /// Adds or updates the 'role' ARIA attribute.
  /// This is a convenience method for `addAttribute('role', role)`.
  ///
  /// [role]: The ARIA role value (e.g., "button", "navigation", "dialog").
  void addRole(String role) {
    _attributes['role'] = role;
  }

  /// Merges another map of attributes into the current set.
  ///
  /// Attributes from the [other] map will be added. If an attribute name
  /// exists in both the current set and the [other] map, the value from
  /// the [other] map will overwrite the existing value.
  ///
  /// If [other] is null, no changes are made.
  void merge(Map<String, String>? other) {
    if (other != null) {
      _attributes.addAll(other); // ignore: avoid-collection-mutating-methods - Builder pattern requires mutation
    }
  }

  /// Builds and returns an unmodifiable map of the configured
  /// attributes.
  ///
  /// This prevents accidental modification of the attribute map after it has
  /// been built.
  Map<String, String> get build {
    return Map.unmodifiable(_attributes);
  }
}
