// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'card.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Card, StoryArgs<Card>>;
typedef _Scenario = CardScenario;
typedef _Defaults = CardDefaults;
typedef _Story = CardStory;
typedef _Args = CardInputArgs;
final CardComponent = Component<Card, StoryArgs<Card>>(
  name: kComponentMeta.name ?? 'Card',
  path: kComponentMeta.path ?? 'component/card',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified cross-platform card with slot-based layout.

Provides five layout slots: [media], [header], [body], [footer],
and [overlay]. The [media] slot renders at the top without padding,
while [header]/[body]/[footer] render below with padding.

Visual style is controlled by [variant] (filled/outlined). Sizing,
elevation, clip-behavior, and all chrome / dimensional overrides
flow through the single [cardStyle] (a [CoreCardStyle]).

Example:
```dart
Card(
  variant: CoreCardVariant.outlined,
  cardStyle: CoreCardStyle(elevation: CoreCardElevation.soft),
  media: Image.network(url, height: 120, fit: BoxFit.cover),
  header: Text('Product Name'),
  body: Text('Description'),
  footer: Button(
    variant: CoreButtonVariant.primary,
    onPressed: () {},
    child: Text('Buy Now'),
  ),
)
```

surface:content — a face in the page flow: what shows through it is the
page it is laid on. A caller that floats a card says so through [role].''',
  stories: [
    $Default..$generatedName = 'Default',
    $WithHeader..$generatedName = 'WithHeader',
    $Filled..$generatedName = 'Filled',
    $Elevated..$generatedName = 'Elevated',
    $ProductCard..$generatedName = 'ProductCard',
    $TravelCard..$generatedName = 'TravelCard',
  ],
);
typedef CardScenario = Scenario<Card, CardInputArgs>;
typedef CardDefaults = Defaults<Card, CardInputArgs>;

class CardStory extends Story<Card, CardInputArgs> {
  CardStory({
    super.name,
    super.designLink,
    SetupBuilder<Card, CardInputArgs>? setup,
    super.modes,
    CardInputArgs? args,
    StoryWidgetBuilder<Card, CardInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? CardInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class CardInputArgs extends StoryArgs<Card> {
  CardInputArgs({
    Arg<CoreCardVariant>? variant,
    Arg<CoreCardElevation>? elevation,
    Arg<String>? headerText,
    Arg<String>? bodyText,
    Arg<String>? footerText,
    Arg<String>? badgeText,
    Arg<bool>? showMedia,
    Arg<bool>? showOverlayBadge,
  }) : this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreCardVariant>(
           CoreCardVariant.defaultVariant,
           values: CoreCardVariant.values,
         ),
       )!,
       this.elevationArg = $initArg(
         'elevation',
         elevation,
         EnumArg<CoreCardElevation>(
           CoreCardElevation.none,
           values: CoreCardElevation.values,
         ),
       )!,
       this.headerTextArg = $initArg('headerText', headerText, StringArg(''))!,
       this.bodyTextArg = $initArg(
         'bodyText',
         bodyText,
         StringArg('This is the card content with some description text.'),
       )!,
       this.footerTextArg = $initArg('footerText', footerText, StringArg(''))!,
       this.badgeTextArg = $initArg('badgeText', badgeText, StringArg('NEW'))!,
       this.showMediaArg = $initArg('showMedia', showMedia, BoolArg(false))!,
       this.showOverlayBadgeArg = $initArg(
         'showOverlayBadge',
         showOverlayBadge,
         BoolArg(false),
       )!;

  CardInputArgs.fixed({
    CoreCardVariant variant = CoreCardVariant.defaultVariant,
    CoreCardElevation elevation = CoreCardElevation.none,
    String headerText = '',
    String bodyText = 'This is the card content with some description text.',
    String footerText = '',
    String badgeText = 'NEW',
    bool showMedia = false,
    bool showOverlayBadge = false,
  }) : this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.elevationArg = $initArg('elevation', Arg.fixed(elevation), null)!,
       this.headerTextArg = $initArg(
         'headerText',
         Arg.fixed(headerText),
         null,
       )!,
       this.bodyTextArg = $initArg('bodyText', Arg.fixed(bodyText), null)!,
       this.footerTextArg = $initArg(
         'footerText',
         Arg.fixed(footerText),
         null,
       )!,
       this.badgeTextArg = $initArg('badgeText', Arg.fixed(badgeText), null)!,
       this.showMediaArg = $initArg('showMedia', Arg.fixed(showMedia), null)!,
       this.showOverlayBadgeArg = $initArg(
         'showOverlayBadge',
         Arg.fixed(showOverlayBadge),
         null,
       )!;

  final Arg<CoreCardVariant> variantArg;

  final Arg<CoreCardElevation> elevationArg;

  final Arg<String> headerTextArg;

  final Arg<String> bodyTextArg;

  final Arg<String> footerTextArg;

  final Arg<String> badgeTextArg;

  final Arg<bool> showMediaArg;

  final Arg<bool> showOverlayBadgeArg;

  CoreCardVariant get variant => variantArg.value;

  CoreCardElevation get elevation => elevationArg.value;

  String get headerText => headerTextArg.value;

  String get bodyText => bodyTextArg.value;

  String get footerText => footerTextArg.value;

  String get badgeText => badgeTextArg.value;

  bool get showMedia => showMediaArg.value;

  bool get showOverlayBadge => showOverlayBadgeArg.value;

  @override
  List<Arg?> get list => [
    variantArg,
    elevationArg,
    headerTextArg,
    bodyTextArg,
    footerTextArg,
    badgeTextArg,
    showMediaArg,
    showOverlayBadgeArg,
  ];
}
