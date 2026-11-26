// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'code_diff.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<CodeDiff, StoryArgs<CodeDiff>>;
typedef _Scenario = CodeDiffScenario;
typedef _Defaults = CodeDiffDefaults;
typedef _Story = CodeDiffStory;
typedef _Args = CodeDiffInputArgs;
final CodeDiffComponent = Component<CodeDiff, StoryArgs<CodeDiff>>(
  name: kComponentMeta.name ?? 'CodeDiff',
  path: kComponentMeta.path ?? 'component/code_diff',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''코드 변경 사항을 라인 단위로 표시하는 viewer 컴포넌트 (Flutter).

Web `CodeDiff` 와 동일한 API/렌더링.

```dart
CodeDiff(
  lines: [
    CoreCodeDiffLine(text: 'unchanged', type: CoreCodeDiffLineType.unchanged),
    CoreCodeDiffLine(text: 'removed',   type: CoreCodeDiffLineType.removed),
    CoreCodeDiffLine(text: 'added',     type: CoreCodeDiffLineType.added),
  ],
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithoutLineNumbers..$generatedName = 'WithoutLineNumbers',
  ],
);
typedef CodeDiffScenario = Scenario<CodeDiff, CodeDiffInputArgs>;
typedef CodeDiffDefaults = Defaults<CodeDiff, CodeDiffInputArgs>;

class CodeDiffStory extends Story<CodeDiff, CodeDiffInputArgs> {
  CodeDiffStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CodeDiffInputArgs? args,
    StoryWidgetBuilder<CodeDiff, CodeDiffInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? CodeDiffInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class CodeDiffInputArgs extends StoryArgs<CodeDiff> {
  CodeDiffInputArgs({Arg<bool>? showLineNumbers})
    : this.showLineNumbersArg = $initArg(
        'showLineNumbers',
        showLineNumbers,
        BoolArg(true),
      )!;

  CodeDiffInputArgs.fixed({bool showLineNumbers = true})
    : this.showLineNumbersArg = $initArg(
        'showLineNumbers',
        Arg.fixed(showLineNumbers),
        null,
      )!;

  final Arg<bool> showLineNumbersArg;

  bool get showLineNumbers => showLineNumbersArg.value;

  @override
  List<Arg?> get list => [showLineNumbersArg];
}
