// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'kbd.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Kbd, StoryArgs<Kbd>>;
typedef _Scenario = KbdScenario;
typedef _Defaults = KbdDefaults;
typedef _Story = KbdStory;
typedef _Args = KbdInputArgs;
final KbdComponent = Component<Kbd, StoryArgs<Kbd>>(
  name: kComponentMeta.name ?? 'Kbd',
  path: kComponentMeta.path ?? 'component/kbd',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Keyboard key display component.

Renders one or more keyboard keys side by side, in the order given. Each
key is a rounded box with monospace text, a hairline outline and its own
shadow; the boxes sit `keySeparatorSpacing` apart and nothing is drawn
between them. A shortcut written inside a sentence is text such as
"Ctrl+S", not a [Kbd].

One [Kbd] is one combination and is announced as **one** name — the keys
joined by a space ("Ctrl S"), never one fragment per key. An icon key is
announced only when it is named through [label].

Chrome / dimensional / text-style overrides flow through the single
[kbdStyle] slot per Epic #1302.

```dart
Kbd(keys: ['Ctrl', 'C'])
Kbd.single(keyText: '⌘')
Kbd.icon(keyContent: Icon(LucideIcons.cornerDownLeft), label: 'Enter')
```

surface:behind — whatever a key sits inline against (a sentence, a
shortcut list). Each key cap draws its own box rather than composing
`OutlinedContainer` — the Web twin's key-cap root is a fixed
`<span>`, and wrapping that in `OutlinedContainer`'s `<div>` breaks
the inline flow a key is meant to sit in (#4358) — so the marker is
restated on the key cap directly.

surface:content — a label-sized chip in the content layer, not a
floating affordance: no sticky, fixed, or overlay mount on either
platform.''',
  stories: [
    $Default..$generatedName = 'Default',
    $SingleKey..$generatedName = 'SingleKey',
    $TwoKeys..$generatedName = 'TwoKeys',
    $FourKeys..$generatedName = 'FourKeys',
  ],
);
typedef KbdScenario = Scenario<Kbd, KbdInputArgs>;
typedef KbdDefaults = Defaults<Kbd, KbdInputArgs>;

class KbdStory extends Story<Kbd, KbdInputArgs> {
  KbdStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    KbdInputArgs? args,
    StoryWidgetBuilder<Kbd, KbdInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? KbdInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class KbdInputArgs extends StoryArgs<Kbd> {
  KbdInputArgs({Arg<String>? keysText})
    : this.keysTextArg = $initArg(
        'keysText',
        keysText,
        StringArg(_kDefaultKeysText),
      )!;

  KbdInputArgs.fixed({String keysText = _kDefaultKeysText})
    : this.keysTextArg = $initArg('keysText', Arg.fixed(keysText), null)!;

  final Arg<String> keysTextArg;

  String get keysText => keysTextArg.value;

  @override
  List<Arg?> get list => [keysTextArg];
}
