// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'disclosure_badge.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<DisclosureBadge, StoryArgs<DisclosureBadge>>;
typedef _Scenario = DisclosureBadgeScenario;
typedef _Defaults = DisclosureBadgeDefaults;
typedef _Story = DisclosureBadgeStory;
typedef _Args = DisclosureBadgeInputArgs;
final DisclosureBadgeComponent =
    Component<DisclosureBadge, StoryArgs<DisclosureBadge>>(
      name: kComponentMeta.name ?? 'DisclosureBadge',
      path: kComponentMeta.path ?? 'component/disclosure_badge',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''A static marker stating whether one piece of evidence can be opened
right now.

```dart
DisclosureBadge(
  kind: CoreDisclosureKind.private,
  label: '비공개 · NDA',
)
```

### Why this is not a `Chip`, a `Badge`, or a `ValidationBadge`

* `ValidationBadge` is form-validation vocabulary and is filled by
  default — wrong domain, wrong emphasis.
* A `Chip` brings a fill and hover feedback with it, so a reader reads
  it as something to press. This badge is never pressable, and a
  reader who taps a "비공개" chip and gets nothing has been lied to by
  the styling.
* `Badge`'s variants are colours (`primary` / `destructive`), not
  meanings, so nothing stops "openable" and "not openable" from ending
  up the same shape.

### The four things this component enforces

1. **Unfilled.** Outline and text only. There is no `backgroundColor`
   slot on [CoreDisclosureBadgeStyle] to add one through.
2. **Shape, not just colour.** `open` is a solid outline, `commitment`
   a solid outline with a marker dot, `private` a dashed outline.
   Those live on [CoreDisclosureKind], out of reach of any theme, so
   the three states stay distinct for a colour-blind reader and on the
   black-and-white printout a 실사 담당자 actually works from
   (WCAG 1.4.1).
3. **The state is written down.** [label] is a required, non-empty
   `String`; an empty one throws rather than rendering a wordless
   outline.
4. **No pointer feedback.** No hover, no press, no animation, no
   cursor change, no `Clickable`. A `StatelessWidget` with no gesture
   and no state, because a static marker that reacts to a pointer is
   claiming to be a control.

### What Flutter has to draw by hand

Flutter's `Border` carries no dash pattern — `BorderStyle` offers only
`solid` and `none` — so `private`'s broken outline is painted by a
[CustomPainter] rather than being expressed in a `BoxDecoration`. That
is deliberate work rather than a colour substitution: the gaps in the
stroke are the signal that survives greyscale, and swapping them for a
different hue would leave the three kinds separated by colour alone,
which is exactly the failure this component exists to prevent.

Chrome overrides flow through the single [disclosureBadgeStyle] slot;
see [CoreDisclosureBadgeStyle] for the merge chain.''',
      stories: [
        $Default..$generatedName = 'Default',
        $Commitment..$generatedName = 'Commitment',
        $Private..$generatedName = 'Private',
      ],
    );
typedef DisclosureBadgeScenario =
    Scenario<DisclosureBadge, DisclosureBadgeInputArgs>;
typedef DisclosureBadgeDefaults =
    Defaults<DisclosureBadge, DisclosureBadgeInputArgs>;

class DisclosureBadgeStory
    extends Story<DisclosureBadge, DisclosureBadgeInputArgs> {
  DisclosureBadgeStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    DisclosureBadgeInputArgs? args,
    StoryWidgetBuilder<DisclosureBadge, DisclosureBadgeInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? DisclosureBadgeInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class DisclosureBadgeInputArgs extends StoryArgs<DisclosureBadge> {
  DisclosureBadgeInputArgs({Arg<CoreDisclosureKind>? kind, Arg<String>? label})
    : this.kindArg = $initArg(
        'kind',
        kind,
        EnumArg<CoreDisclosureKind>(
          CoreDisclosureKind.open,
          values: CoreDisclosureKind.values,
        ),
      )!,
      this.labelArg = $initArg(
        'label',
        label,
        StringArg('Evidence available'),
      )!;

  DisclosureBadgeInputArgs.fixed({
    CoreDisclosureKind kind = CoreDisclosureKind.open,
    String label = 'Evidence available',
  }) : this.kindArg = $initArg('kind', Arg.fixed(kind), null)!,
       this.labelArg = $initArg('label', Arg.fixed(label), null)!;

  final Arg<CoreDisclosureKind> kindArg;

  final Arg<String> labelArg;

  CoreDisclosureKind get kind => kindArg.value;

  String get label => labelArg.value;

  @override
  List<Arg?> get list => [kindArg, labelArg];
}
