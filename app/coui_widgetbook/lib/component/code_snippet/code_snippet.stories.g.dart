// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'code_snippet.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<CodeSnippet, StoryArgs<CodeSnippet>>;
typedef _Scenario = CodeSnippetScenario;
typedef _Defaults = CodeSnippetDefaults;
typedef _Story = CodeSnippetStory;
typedef _Args = CodeSnippetInputArgs;
final CodeSnippetComponent = Component<CodeSnippet, StoryArgs<CodeSnippet>>(
  name: kComponentMeta.name ?? 'CodeSnippet',
  path: kComponentMeta.path ?? 'component/code_snippet',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified cross-platform code snippet with syntax highlighting
and clipboard copy functionality.

Uses dark background ([inverseSurface]) with syntax highlighting
and a copy button that toggles to a check icon on copy. All chrome /
dimensional / nested text style overrides flow through the single
[codeSnippetStyle] slot (Epic #1415 option D).

Example:
```dart
CodeSnippet(
  code: "void main() {\n  print('Hello!');\n}",
  mode: 'dart',
)
```''',
  stories: [$Default..$generatedName = 'Default'],
);
typedef CodeSnippetScenario = Scenario<CodeSnippet, CodeSnippetInputArgs>;
typedef CodeSnippetDefaults = Defaults<CodeSnippet, CodeSnippetInputArgs>;

class CodeSnippetStory extends Story<CodeSnippet, CodeSnippetInputArgs> {
  CodeSnippetStory({
    super.name,
    super.designLink,
    SetupBuilder<CodeSnippet, CodeSnippetInputArgs>? setup,
    super.modes,
    CodeSnippetInputArgs? args,
    StoryWidgetBuilder<CodeSnippet, CodeSnippetInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? CodeSnippetInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class CodeSnippetInputArgs extends StoryArgs<CodeSnippet> {
  CodeSnippetInputArgs({Arg<CodeSnippetLanguage>? language})
    : this.languageArg = $initArg(
        'language',
        language,
        EnumArg<CodeSnippetLanguage>(
          CodeSnippetLanguage.dart,
          values: CodeSnippetLanguage.values,
        ),
      )!;

  CodeSnippetInputArgs.fixed({
    CodeSnippetLanguage language = CodeSnippetLanguage.dart,
  }) : this.languageArg = $initArg('language', Arg.fixed(language), null)!;

  final Arg<CodeSnippetLanguage> languageArg;

  CodeSnippetLanguage get language => languageArg.value;

  @override
  List<Arg?> get list => [languageArg];
}
