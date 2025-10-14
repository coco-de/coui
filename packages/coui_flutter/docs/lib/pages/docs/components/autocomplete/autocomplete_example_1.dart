// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:coui_flutter/coui_flutter.dart';

class AutoCompleteExample1 extends StatefulWidget {
  const AutoCompleteExample1({super.key});

  @override
  State<AutoCompleteExample1> createState() => _AutoCompleteExample1State();
}

class _AutoCompleteExample1State extends State<AutoCompleteExample1> {
  final List<String> suggestions = [
    'Apple',
    'Banana',
    'Cherry',
    'Date',
    'Grape',
    'Kiwi',
    'Lemon',
    'Mango',
    'Orange',
    'Peach',
    'Pear',
    'Pineapple',
    'Strawberry',
    'Watermelon',
  ];

  List<String> _currentSuggestions = [];
  final TextEditingController _controller = TextEditingController();

  void _updateSuggestions(String value) {
    String? currentWord = _controller.currentWord;
    if (currentWord == null || currentWord.isEmpty) {
      setState(() {
        _currentSuggestions = [];
      });
      return;
    }
    setState(() {
      _currentSuggestions = suggestions
          .where(
            (element) =>
                element.toLowerCase().contains(currentWord.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AutoComplete(
      suggestions: _currentSuggestions,
      child: TextField(
        controller: _controller,
        features: [
          InputFeature.trailing(
            const IconButton.text(
              icon: Icon(Icons.clear),
              onPressed: clearActiveTextInput,
              density: ButtonDensity.compact,
            ),
          ),
        ],
        onChanged: _updateSuggestions,
      ),
    );
  }
}
