import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'code_snippet.stories.g.dart';

const _kDartSample = '''
void main() {
  print('Hello, World!');
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Demo')),
        body: Center(child: Text('Hello!')),
      ),
    );
  }
}
''';

const _kPythonSample = '''
def greet(name):
    return f"Hello, {name}!"

if __name__ == "__main__":
    print(greet("World"))
''';

const _kJsonSample = '''
{
  "name": "example",
  "version": "1.0.0",
  "dependencies": {
    "flutter": ">=3.0.0"
  }
}
''';

/// Highlight language options for [CodeSnippet] stories.
enum CodeSnippetLanguage {
  /// Dart sample code.
  dart,

  /// JavaScript highlight mode (renders the Dart sample).
  javascript,

  /// JSON sample code.
  json,

  /// Python sample code.
  python,

  /// YAML highlight mode (renders the Dart sample).
  yaml,
}

/// Knob input for [CodeSnippet] stories.
class CodeSnippetInput {
  /// Creates a [CodeSnippetInput].
  const CodeSnippetInput({this.language = CodeSnippetLanguage.dart});

  /// Syntax-highlight language of the snippet.
  final CodeSnippetLanguage language;
}

/// Navigation metadata for the CodeSnippet component.
const kComponentMeta = ComponentMeta(name: 'CodeSnippet', path: 'display');

/// Story metadata for [CodeSnippet].
const kMeta = Meta(CodeSnippet.new, argsType: CodeSnippetInput.new);

/// Default builder mapping [CodeSnippetInput] args to a [CodeSnippet].
final CodeSnippetDefaults defaults = _Defaults(
  setup: (context, child, args) => Padding(
    padding: const .all(CoreSpace.space16),
    child: child,
  ),
  builder: (context, args) {
    final code = switch (args.language) {
      .python => _kPythonSample,
      .json => _kJsonSample,
      .dart || .javascript || .yaml => _kDartSample,
    };

    return CodeSnippet(
      code: code,
      mode: args.language.name,
    );
  },
);

/// Syntax-highlighted snippet with a language knob.
final $Default = _Story();
