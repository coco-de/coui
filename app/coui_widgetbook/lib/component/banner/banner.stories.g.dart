// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'banner.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Banner, StoryArgs<Banner>>;
typedef _Scenario = BannerScenario;
typedef _Defaults = BannerDefaults;
typedef _Story = BannerStory;
typedef _Args = BannerInputArgs;
final BannerComponent = Component<Banner, StoryArgs<Banner>>(
  name: kComponentMeta.name ?? 'Banner',
  path: kComponentMeta.path ?? 'component/banner',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment:
      r'''A unified banner component for important announcements or alerts.

Renders a full-bleed band with variant-based styling, a hairline
bottom rule on the `weak` emphasis, optional icon, dismiss button,
and action widget.

Per Epic #1302 / #1696 every chrome / dimensional / nested-slot
override flows through the single [bannerStyle] (a [CoreBannerStyle]).
The semantic enum (`variant`) and behaviour fields (`message` /
`description` / `action` / `onDismiss` / `showIcon`) stay flat on
the widget.

```text
design system default for banner
  → CoreBannerTheme.style                  // 프로젝트 공통
  → parent component slot override
  → widget.bannerStyle                     // 인스턴스별
```

Example:
```dart
Banner(
  message: Text('Your session will expire in 5 minutes.'),
  variant: CoreBannerVariant.warning,
  onDismiss: () => setState(() => _show = false),
  action: Button(
    variant: CoreButtonVariant.outline,
    onPressed: () => extendSession(),
    child: Text('Extend'),
  ),
)
```

surface:behind — dismissible and full-width, commonly pinned atop
scrollable content as a top-of-page announcement the way a host shell
stacks `Dock` or `NavigationBar` over a scrolling body.

surface:content — a face in the page flow: what shows through it is
whatever content it announces over, not a parent panel.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Warning..$generatedName = 'Warning',
    $Destructive..$generatedName = 'Destructive',
    $Success..$generatedName = 'Success',
    $Neutral..$generatedName = 'Neutral',
  ],
);
typedef BannerScenario = Scenario<Banner, BannerInputArgs>;
typedef BannerDefaults = Defaults<Banner, BannerInputArgs>;

class BannerStory extends Story<Banner, BannerInputArgs> {
  BannerStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    BannerInputArgs? args,
    StoryWidgetBuilder<Banner, BannerInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? BannerInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class BannerInputArgs extends StoryArgs<Banner> {
  BannerInputArgs({
    Arg<String>? message,
    Arg<CoreBannerVariant>? variant,
    Arg<bool>? showIcon,
    Arg<bool>? dismissible,
  }) : this.messageArg = $initArg(
         'message',
         message,
         StringArg('This is a message banner'),
       )!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreBannerVariant>(
           CoreBannerVariant.info,
           values: CoreBannerVariant.values,
         ),
       )!,
       this.showIconArg = $initArg('showIcon', showIcon, BoolArg(true))!,
       this.dismissibleArg = $initArg(
         'dismissible',
         dismissible,
         BoolArg(false),
       )!;

  BannerInputArgs.fixed({
    String message = 'This is a message banner',
    CoreBannerVariant variant = CoreBannerVariant.info,
    bool showIcon = true,
    bool dismissible = false,
  }) : this.messageArg = $initArg('message', Arg.fixed(message), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.showIconArg = $initArg('showIcon', Arg.fixed(showIcon), null)!,
       this.dismissibleArg = $initArg(
         'dismissible',
         Arg.fixed(dismissible),
         null,
       )!;

  final Arg<String> messageArg;

  final Arg<CoreBannerVariant> variantArg;

  final Arg<bool> showIconArg;

  final Arg<bool> dismissibleArg;

  String get message => messageArg.value;

  CoreBannerVariant get variant => variantArg.value;

  bool get showIcon => showIconArg.value;

  bool get dismissible => dismissibleArg.value;

  @override
  List<Arg?> get list => [messageArg, variantArg, showIconArg, dismissibleArg];
}
