// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'badge.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Badge, StoryArgs<Badge>>;
typedef _Scenario = BadgeScenario;
typedef _Defaults = BadgeDefaults;
typedef _Story = BadgeStory;
typedef _Args = BadgeInputArgs;
final BadgeComponent = Component<Badge, StoryArgs<Badge>>(
  name: kComponentMeta.name ?? 'Badge',
  path: kComponentMeta.path ?? 'component/badge',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified cross-platform badge with token-based rendering.

Every chrome / dimensional / nested-slot override flows through the
single [badgeStyle] (a [CoreBadgeStyle]). The design axes (`tone` /
`variant` / `form` / `size` / `showDot`) and behaviour fields (`child` /
`leading` / `trailing` / `onPressed`) stay flat on the widget.

```text
design system default for size × form × tone × variant
  → CoreBadgeTheme.style                  // 프로젝트 공통
  → CoreBadgeTheme.toneStyles[tone]
  → CoreBadgeTheme.variantStyles[variant]
  → parent component slot override
  → widget.badgeStyle                     // 인스턴스별
```

Example:
```dart
// A status label — tonal, a word, md.
Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('Done'))

// An unread count.
Badge(
  tone: CoreBadgeTone.info,
  variant: CoreBadgeVariant.filled,
  form: CoreBadgeForm.count,
  size: CoreComponentSize.xs,
  child: Text('3'),
)
```

surface:behind — whatever the badge is set inline against (a
sentence, a card, the page). It draws its own box rather than
composing `OutlinedContainer` — the Web twin's root is a fixed
`<span>`, and wrapping that in `OutlinedContainer`'s `<div>` breaks
the inline flow a badge is meant to sit in (#4358) — so the marker
is restated here directly, the same restatement Button (#4360) does
for the same "can't compose" reason.

surface:content — a label-sized chip in the content layer, not a
floating affordance: no sticky, fixed, or overlay mount on either
platform.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Status..$generatedName = 'Status',
    $Count..$generatedName = 'Count',
    $Outlined..$generatedName = 'Outlined',
    $Dot..$generatedName = 'Dot',
    $WithLeadingIcon..$generatedName = 'WithLeadingIcon',
    $Clickable..$generatedName = 'Clickable',
  ],
);
typedef BadgeScenario = Scenario<Badge, BadgeInputArgs>;
typedef BadgeDefaults = Defaults<Badge, BadgeInputArgs>;

class BadgeStory extends Story<Badge, BadgeInputArgs> {
  BadgeStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    BadgeInputArgs? args,
    StoryWidgetBuilder<Badge, BadgeInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? BadgeInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class BadgeInputArgs extends StoryArgs<Badge> {
  BadgeInputArgs({
    Arg<String>? text,
    Arg<CoreBadgeTone>? tone,
    Arg<CoreBadgeVariant>? variant,
    Arg<CoreBadgeForm>? form,
    Arg<CoreComponentSize>? size,
    Arg<bool>? showDot,
    Arg<bool>? showLeadingIcon,
    Arg<bool>? showTrailingIcon,
    Arg<bool>? clickable,
  }) : this.textArg = $initArg('text', text, StringArg('Badge'))!,
       this.toneArg = $initArg(
         'tone',
         tone,
         EnumArg<CoreBadgeTone>(
           CoreBadgeTone.defaultTone,
           values: CoreBadgeTone.values,
         ),
       )!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreBadgeVariant>(
           CoreBadgeVariant.defaultVariant,
           values: CoreBadgeVariant.values,
         ),
       )!,
       this.formArg = $initArg(
         'form',
         form,
         EnumArg<CoreBadgeForm>(
           CoreBadgeForm.defaultForm,
           values: CoreBadgeForm.values,
         ),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CoreComponentSize>(
           CoreBadgeContract.defaultSize,
           values: CoreComponentSize.values,
         ),
       )!,
       this.showDotArg = $initArg(
         'showDot',
         showDot,
         BoolArg(CoreBadgeContract.defaultShowDot),
       )!,
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
       this.clickableArg = $initArg('clickable', clickable, BoolArg(false))!;

  BadgeInputArgs.fixed({
    String text = 'Badge',
    CoreBadgeTone tone = CoreBadgeTone.defaultTone,
    CoreBadgeVariant variant = CoreBadgeVariant.defaultVariant,
    CoreBadgeForm form = CoreBadgeForm.defaultForm,
    CoreComponentSize size = CoreBadgeContract.defaultSize,
    bool showDot = CoreBadgeContract.defaultShowDot,
    bool showLeadingIcon = false,
    bool showTrailingIcon = false,
    bool clickable = false,
  }) : this.textArg = $initArg('text', Arg.fixed(text), null)!,
       this.toneArg = $initArg('tone', Arg.fixed(tone), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.formArg = $initArg('form', Arg.fixed(form), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.showDotArg = $initArg('showDot', Arg.fixed(showDot), null)!,
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
       this.clickableArg = $initArg('clickable', Arg.fixed(clickable), null)!;

  final Arg<String> textArg;

  final Arg<CoreBadgeTone> toneArg;

  final Arg<CoreBadgeVariant> variantArg;

  final Arg<CoreBadgeForm> formArg;

  final Arg<CoreComponentSize> sizeArg;

  final Arg<bool> showDotArg;

  final Arg<bool> showLeadingIconArg;

  final Arg<bool> showTrailingIconArg;

  final Arg<bool> clickableArg;

  String get text => textArg.value;

  CoreBadgeTone get tone => toneArg.value;

  CoreBadgeVariant get variant => variantArg.value;

  CoreBadgeForm get form => formArg.value;

  CoreComponentSize get size => sizeArg.value;

  bool get showDot => showDotArg.value;

  bool get showLeadingIcon => showLeadingIconArg.value;

  bool get showTrailingIcon => showTrailingIconArg.value;

  bool get clickable => clickableArg.value;

  @override
  List<Arg?> get list => [
    textArg,
    toneArg,
    variantArg,
    formArg,
    sizeArg,
    showDotArg,
    showLeadingIconArg,
    showTrailingIconArg,
    clickableArg,
  ];
}
