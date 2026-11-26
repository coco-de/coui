// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'button.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Button, StoryArgs<Button>>;
typedef _Scenario = ButtonScenario;
typedef _Defaults = ButtonDefaults;
typedef _Story = ButtonStory;
typedef _Args = ButtonInputArgs;
final ButtonComponent = Component<Button, StoryArgs<Button>>(
  name: kComponentMeta.name ?? 'Button',
  path: kComponentMeta.path ?? 'component/button',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified cross-platform button with token-based rendering.

Per Epic #1302 원칙 6/7, the semantic enums (`variant`, `size`,
`shape`) stay as widget parameters because they identify the
button instance — the design system maps each to a known chrome
look. All chrome / dimensional / nested-slot overrides flow
through the single [buttonStyle] (a [CoreButtonStyle]) so the
nested-merge chain works uniformly:

```text
design system default for variant
  → CoreButtonTheme.style
  → CoreButtonTheme.variantStyles[variant]
  → parent component slot override
  → widget.buttonStyle
```

Example:
```dart
Button(
  variant: CoreButtonVariant.primary,
  size: CoreComponentSize.lg,
  onPressed: () => submit(),
  buttonStyle: CoreButtonStyle(
    width: 200,
    padding: CoreEdgeInsets.symmetric(horizontal: 24),
  ),
  child: Text('Submit'),
)
```

surface:content — a control face in the page flow: what shows through a
translucent fill is the page it is laid on, not something floating over
it. A caller that composes a button into a floating affordance (a
toolbar, a menu row) the button itself has no way to detect says so
through [role].''',
  stories: [
    $Primary..$generatedName = 'Primary',
    $Secondary..$generatedName = 'Secondary',
    $Tonal..$generatedName = 'Tonal',
    $Outline..$generatedName = 'Outline',
    $Ghost..$generatedName = 'Ghost',
    $Destructive..$generatedName = 'Destructive',
    $WithIcon..$generatedName = 'WithIcon',
    $Dashed..$generatedName = 'Dashed',
  ],
);
typedef ButtonScenario = Scenario<Button, ButtonInputArgs>;
typedef ButtonDefaults = Defaults<Button, ButtonInputArgs>;

class ButtonStory extends Story<Button, ButtonInputArgs> {
  ButtonStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ButtonInputArgs? args,
    StoryWidgetBuilder<Button, ButtonInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ButtonInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class ButtonInputArgs extends StoryArgs<Button> {
  ButtonInputArgs({
    Arg<String>? text,
    Arg<CoreButtonVariant>? variant,
    Arg<CoreComponentSize>? size,
    Arg<CoreButtonShape>? shape,
    Arg<bool>? enabled,
    Arg<bool>? showLeadingIcon,
    Arg<bool>? showTrailingIcon,
    Arg<bool>? dashedBorder,
  }) : this.textArg = $initArg('text', text, StringArg('Button'))!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreButtonVariant>(
           CoreButtonVariant.primary,
           values: CoreButtonVariant.values,
         ),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CoreComponentSize>(
           CoreComponentSize.md,
           values: CoreComponentSize.values,
         ),
       )!,
       this.shapeArg = $initArg(
         'shape',
         shape,
         EnumArg<CoreButtonShape>(
           CoreButtonShape.rectangle,
           values: CoreButtonShape.values,
         ),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(true))!,
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         showLeadingIcon,
         BoolArg(false),
       )!,
       this.showTrailingIconArg = $initArg(
         'showTrailingIcon',
         showTrailingIcon,
         BoolArg(false),
       )!,
       this.dashedBorderArg = $initArg(
         'dashedBorder',
         dashedBorder,
         BoolArg(false),
       )!;

  ButtonInputArgs.fixed({
    String text = 'Button',
    CoreButtonVariant variant = CoreButtonVariant.primary,
    CoreComponentSize size = CoreComponentSize.md,
    CoreButtonShape shape = CoreButtonShape.rectangle,
    bool enabled = true,
    bool showLeadingIcon = false,
    bool showTrailingIcon = false,
    bool dashedBorder = false,
  }) : this.textArg = $initArg('text', Arg.fixed(text), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.shapeArg = $initArg('shape', Arg.fixed(shape), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.showLeadingIconArg = $initArg(
         'showLeadingIcon',
         Arg.fixed(showLeadingIcon),
         null,
       )!,
       this.showTrailingIconArg = $initArg(
         'showTrailingIcon',
         Arg.fixed(showTrailingIcon),
         null,
       )!,
       this.dashedBorderArg = $initArg(
         'dashedBorder',
         Arg.fixed(dashedBorder),
         null,
       )!;

  final Arg<String> textArg;

  final Arg<CoreButtonVariant> variantArg;

  final Arg<CoreComponentSize> sizeArg;

  final Arg<CoreButtonShape> shapeArg;

  final Arg<bool> enabledArg;

  final Arg<bool> showLeadingIconArg;

  final Arg<bool> showTrailingIconArg;

  final Arg<bool> dashedBorderArg;

  String get text => textArg.value;

  CoreButtonVariant get variant => variantArg.value;

  CoreComponentSize get size => sizeArg.value;

  CoreButtonShape get shape => shapeArg.value;

  bool get enabled => enabledArg.value;

  bool get showLeadingIcon => showLeadingIconArg.value;

  bool get showTrailingIcon => showTrailingIconArg.value;

  bool get dashedBorder => dashedBorderArg.value;

  @override
  List<Arg?> get list => [
    textArg,
    variantArg,
    sizeArg,
    shapeArg,
    enabledArg,
    showLeadingIconArg,
    showTrailingIconArg,
    dashedBorderArg,
  ];
}
