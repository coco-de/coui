// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'mockup_code.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<MockupCode, StoryArgs<MockupCode>>;
typedef _Scenario = MockupCodeScenario;
typedef _Defaults = MockupCodeDefaults;
typedef _Story = MockupCodeStory;
typedef _Args = MockupCodeInputArgs;
final MockupCodeComponent = Component<MockupCode, StoryArgs<MockupCode>>(
  name: kComponentMeta.name ?? 'MockupCode',
  path: kComponentMeta.path ?? 'component/mockup_code',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified cross-platform code mockup with token-based rendering.

Displays a code editor frame with optional line numbers.
Uses [CoreMockupCodeContract] from `coui_core` for consistent
cross-platform API. Chrome / colour overrides flow through the
single [mockupCodeStyle] slot per Epic #1302.

Example:
```dart
MockupCode.fromString('void main() {\n  print("hello");\n}')
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $CustomPrefixes..$generatedName = 'CustomPrefixes',
  ],
);
typedef MockupCodeScenario = Scenario<MockupCode, MockupCodeInputArgs>;
typedef MockupCodeDefaults = Defaults<MockupCode, MockupCodeInputArgs>;

class MockupCodeStory extends Story<MockupCode, MockupCodeInputArgs> {
  MockupCodeStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    MockupCodeInputArgs? args,
    StoryWidgetBuilder<MockupCode, MockupCodeInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? MockupCodeInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class MockupCodeInputArgs extends StoryArgs<MockupCode> {
  MockupCodeInputArgs({
    Arg<String>? code,
    Arg<bool>? showLineNumbers,
    Arg<bool>? diffPrefixes,
    Arg<CoreCodeLineTone>? tone,
  }) : this.codeArg = $initArg('code', code, StringArg(_kSampleCode))!,
       this.showLineNumbersArg = $initArg(
         'showLineNumbers',
         showLineNumbers,
         BoolArg(true),
       )!,
       this.diffPrefixesArg = $initArg(
         'diffPrefixes',
         diffPrefixes,
         BoolArg(false),
       )!,
       this.toneArg = $initArg(
         'tone',
         tone,
         EnumArg<CoreCodeLineTone>(
           CoreCodeLineTone.defaultTone,
           values: CoreCodeLineTone.values,
         ),
       )!;

  MockupCodeInputArgs.fixed({
    String code = _kSampleCode,
    bool showLineNumbers = true,
    bool diffPrefixes = false,
    CoreCodeLineTone tone = CoreCodeLineTone.defaultTone,
  }) : this.codeArg = $initArg('code', Arg.fixed(code), null)!,
       this.showLineNumbersArg = $initArg(
         'showLineNumbers',
         Arg.fixed(showLineNumbers),
         null,
       )!,
       this.diffPrefixesArg = $initArg(
         'diffPrefixes',
         Arg.fixed(diffPrefixes),
         null,
       )!,
       this.toneArg = $initArg('tone', Arg.fixed(tone), null)!;

  final Arg<String> codeArg;

  final Arg<bool> showLineNumbersArg;

  final Arg<bool> diffPrefixesArg;

  final Arg<CoreCodeLineTone> toneArg;

  String get code => codeArg.value;

  bool get showLineNumbers => showLineNumbersArg.value;

  bool get diffPrefixes => diffPrefixesArg.value;

  CoreCodeLineTone get tone => toneArg.value;

  @override
  List<Arg?> get list => [
    codeArg,
    showLineNumbersArg,
    diffPrefixesArg,
    toneArg,
  ];
}
