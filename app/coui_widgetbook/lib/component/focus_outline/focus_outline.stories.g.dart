// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'focus_outline.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<FocusOutline, StoryArgs<FocusOutline>>;
typedef _Scenario = FocusOutlineScenario;
typedef _Defaults = FocusOutlineDefaults;
typedef _Story = FocusOutlineStory;
typedef _Args = FocusOutlineInputArgs;
final FocusOutlineComponent = Component<FocusOutline, StoryArgs<FocusOutline>>(
  name: kComponentMeta.name ?? 'FocusOutline',
  path: kComponentMeta.path ?? 'component/focus_outline',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''A focus outline wrapper that draws a ring around [child] when
[focused] is `true`.

`FocusOutline` is a pure visual wrapper — it draws the ring and
nothing else. Focus tracking is the **caller's** responsibility,
because the right "focus" depends on the call site:

- a text field tracks `_focusNode.hasFocus`,
- a radio cell tracks `_focusing && isSelected`,
- an accordion trigger tracks `FocusableActionDetector.onShowFocusHighlight`.

The Web implementation has the same contract: callers wire focus
state and pass the resulting boolean. Both platforms agree on the
shape (`focused: bool`, default `false`) so cross-platform code
stays identical.

Per Epic #1302 chrome / dimensional / animation overrides flow
through the single [focusOutlineStyle] slot. Behavioural fields
(`child`, `focused`, `shape`) stay flat on the widget.

```dart
FocusOutline(
  focused: focusNode.hasFocus,
  focusOutlineStyle: CoreFocusOutlineStyle(
    borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
  ),
  child: TextField(...),
)
```''',
  stories: [
    $Default..$generatedName = 'Default',
    $Circle..$generatedName = 'Circle',
  ],
);
typedef FocusOutlineScenario = Scenario<FocusOutline, FocusOutlineInputArgs>;
typedef FocusOutlineDefaults = Defaults<FocusOutline, FocusOutlineInputArgs>;

class FocusOutlineStory extends Story<FocusOutline, FocusOutlineInputArgs> {
  FocusOutlineStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    FocusOutlineInputArgs? args,
    StoryWidgetBuilder<FocusOutline, FocusOutlineInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? FocusOutlineInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class FocusOutlineInputArgs extends StoryArgs<FocusOutline> {
  FocusOutlineInputArgs({Arg<bool>? focused, Arg<CoreFocusOutlineShape>? shape})
    : this.focusedArg = $initArg('focused', focused, BoolArg(true))!,
      this.shapeArg = $initArg(
        'shape',
        shape,
        EnumArg<CoreFocusOutlineShape>(
          CoreFocusOutlineShape.rectangle,
          values: CoreFocusOutlineShape.values,
        ),
      )!;

  FocusOutlineInputArgs.fixed({
    bool focused = true,
    CoreFocusOutlineShape shape = CoreFocusOutlineShape.rectangle,
  }) : this.focusedArg = $initArg('focused', Arg.fixed(focused), null)!,
       this.shapeArg = $initArg('shape', Arg.fixed(shape), null)!;

  final Arg<bool> focusedArg;

  final Arg<CoreFocusOutlineShape> shapeArg;

  bool get focused => focusedArg.value;

  CoreFocusOutlineShape get shape => shapeArg.value;

  @override
  List<Arg?> get list => [focusedArg, shapeArg];
}
