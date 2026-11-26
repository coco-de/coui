// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'input_otp.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<InputOtpDemo, StoryArgs<InputOtpDemo>>;
typedef _Scenario = InputOtpDemoScenario;
typedef _Defaults = InputOtpDemoDefaults;
typedef _Story = InputOtpDemoStory;
typedef _Args = InputOtpDemoArgs;
final InputOtpDemoComponent = Component<InputOtpDemo, StoryArgs<InputOtpDemo>>(
  name: kComponentMeta.name ?? 'InputOtpDemo',
  path: kComponentMeta.path ?? 'component/input_otp',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Interactive demo host for [InputOtp] stories.

Tracks the last completed code so the OTP callback is observable
in the preview.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Large..$generatedName = 'Large',
  ],
);
typedef InputOtpDemoScenario = Scenario<InputOtpDemo, InputOtpDemoArgs>;
typedef InputOtpDemoDefaults = Defaults<InputOtpDemo, InputOtpDemoArgs>;

class InputOtpDemoStory extends Story<InputOtpDemo, InputOtpDemoArgs> {
  InputOtpDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    InputOtpDemoArgs? args,
    StoryWidgetBuilder<InputOtpDemo, InputOtpDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? InputOtpDemoArgs(),
         builder:
             builder ??
             (context, args) => InputOtpDemo(
               key: args.key,
               length: args.length,
               obscured: args.obscured,
               separatorInterval: args.separatorInterval,
               enabled: args.enabled,
               autofocus: args.autofocus,
               errorText: args.errorText,
               size: args.size,
             ),
       );
}

class InputOtpDemoArgs extends StoryArgs<InputOtpDemo> {
  InputOtpDemoArgs({
    Arg<Key?>? key,
    Arg<int>? length,
    Arg<bool>? obscured,
    Arg<int>? separatorInterval,
    Arg<bool>? enabled,
    Arg<bool>? autofocus,
    Arg<String?>? errorText,
    Arg<CoreInputOtpSize>? size,
  }) : this.keyArg = $initArg('key', key, null),
       this.lengthArg = $initArg('length', length, IntArg(_kDefaultLength))!,
       this.obscuredArg = $initArg('obscured', obscured, BoolArg(false))!,
       this.separatorIntervalArg = $initArg(
         'separatorInterval',
         separatorInterval,
         IntArg(_kDefaultSeparatorInterval),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.autofocusArg = $initArg('autofocus', autofocus, BoolArg(false))!,
       this.errorTextArg = $initArg(
         'errorText',
         errorText,
         NullableStringArg(null),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CoreInputOtpSize>(
           CoreInputOtpSize.defaultSize,
           values: CoreInputOtpSize.values,
         ),
       )!;

  InputOtpDemoArgs.fixed({
    Key? key,
    int length = _kDefaultLength,
    bool obscured = false,
    int separatorInterval = _kDefaultSeparatorInterval,
    bool enabled = true,
    bool autofocus = false,
    String? errorText = null,
    CoreInputOtpSize size = CoreInputOtpSize.defaultSize,
  }) : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
       this.lengthArg = $initArg('length', Arg.fixed(length), null)!,
       this.obscuredArg = $initArg('obscured', Arg.fixed(obscured), null)!,
       this.separatorIntervalArg = $initArg(
         'separatorInterval',
         Arg.fixed(separatorInterval),
         null,
       )!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.autofocusArg = $initArg('autofocus', Arg.fixed(autofocus), null)!,
       this.errorTextArg = $initArg(
         'errorText',
         errorText == null ? null : Arg.fixed(errorText),
         null,
       ),
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!;

  final Arg<Key?>? keyArg;

  final Arg<int> lengthArg;

  final Arg<bool> obscuredArg;

  final Arg<int> separatorIntervalArg;

  final Arg<bool> enabledArg;

  final Arg<bool> autofocusArg;

  final Arg<String?>? errorTextArg;

  final Arg<CoreInputOtpSize> sizeArg;

  Key? get key => keyArg?.value;

  int get length => lengthArg.value;

  bool get obscured => obscuredArg.value;

  int get separatorInterval => separatorIntervalArg.value;

  bool get enabled => enabledArg.value;

  bool get autofocus => autofocusArg.value;

  String? get errorText => errorTextArg?.value;

  CoreInputOtpSize get size => sizeArg.value;

  @override
  List<Arg?> get list => [
    keyArg,
    lengthArg,
    obscuredArg,
    separatorIntervalArg,
    enabledArg,
    autofocusArg,
    errorTextArg,
    sizeArg,
  ];
}
