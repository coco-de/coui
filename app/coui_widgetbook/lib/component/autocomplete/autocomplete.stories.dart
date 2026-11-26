import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'autocomplete.stories.g.dart';

const _kEmptyQuery = '';

/// Interactive demo host for [Autocomplete] stories.
class AutocompleteDemo extends StatefulWidget {
  /// Creates an [AutocompleteDemo].
  const AutocompleteDemo({
    super.key,
    this.placeholder = 'Type to search...',
    this.enabled = true,
  });

  /// Placeholder text shown while the field is empty.
  final String placeholder;

  /// Whether the field accepts input.
  final bool enabled;

  @override
  State<AutocompleteDemo> createState() => _AutocompleteDemoState();
}

class _AutocompleteDemoState extends State<AutocompleteDemo> {
  static const _allSuggestions = [
    'Apple',
    'Apricot',
    'Banana',
    'Blackberry',
    'Blueberry',
    'Cherry',
    'Grape',
    'Kiwi',
    'Lemon',
    'Mango',
    'Orange',
    'Papaya',
    'Peach',
    'Pear',
    'Pineapple',
    'Raspberry',
    'Strawberry',
    'Watermelon',
  ];

  String _query = _kEmptyQuery;

  List<String> get _filteredSuggestions {
    final text = _query.toLowerCase();
    if (text.isEmpty) return const [];

    return _allSuggestions
        .where((item) => item.toLowerCase().contains(text))
        .toList();
  }

  void handleChanged(String value) {
    setState(() => _query = value);
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete(
      onChanged: handleChanged,
      suggestions: _filteredSuggestions,
      value: _query,
      placeholder: widget.placeholder,
      enabled: widget.enabled,
    );
  }
}

/// Navigation metadata for the Autocomplete component.
const kComponentMeta = ComponentMeta(name: 'Autocomplete', path: 'form');

/// Story metadata for [AutocompleteDemo].
const kMeta = Meta(AutocompleteDemo.new);

/// Fruit search autocomplete with editable knobs.
final $Default = _Story();

/// Disabled autocomplete field.
final $Disabled = _Story(args: _Args(enabled: BoolArg(false)));
