// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'footer.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Footer, StoryArgs<Footer>>;
typedef _Scenario = FooterScenario;
typedef _Defaults = FooterDefaults;
typedef _Story = FooterStory;
typedef _Args = FooterInputArgs;
final FooterComponent = Component<Footer, StoryArgs<Footer>>(
  name: kComponentMeta.name ?? 'Footer',
  path: kComponentMeta.path ?? 'component/footer',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified page footer for Flutter.

Stacks an optional full-bleed top rule ([showDivider]) above a padded
content box holding the navigation band ([aside] + [sections]) and the
legal block ([company] / the business-info disclosure / [links] /
[copyright]). Every block is skipped when its slots are empty, so a
footer that carries only navigation renders exactly what it did
before the legal block existed.

Colours, padding, and default text style flow from the widget →
`CoreComponentTheme.footer` → design system defaults.

```dart
Footer(
  aside: Logo(),
  sections: [
    CoreFooterNavData<Widget>(
      title: 'Services',
      children: [
        Link(href: '/branding', child: const Text('Branding')),
        Link(href: '/design', child: const Text('Design')),
      ],
    ),
  ],
  company: const Text('Cocode Inc.'),
  businessInfoLabel: const Text('Business info'),
  businessInfo: const Text('CEO Jane Doe · Registration no. …'),
  links: [Link(href: '/terms', child: const Text('Terms of service'))],
  copyright: const Text('© 2026 Cocode Inc.'),
)
```

surface:content — a page-flow band, not something mounted over
content.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Vertical..$generatedName = 'Vertical',
    $Center..$generatedName = 'Center',
  ],
);
typedef FooterScenario = Scenario<Footer, FooterInputArgs>;
typedef FooterDefaults = Defaults<Footer, FooterInputArgs>;

class FooterStory extends Story<Footer, FooterInputArgs> {
  FooterStory({
    super.name,
    super.designLink,
    SetupBuilder<Footer, FooterInputArgs>? setup,
    super.modes,
    FooterInputArgs? args,
    StoryWidgetBuilder<Footer, FooterInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? FooterInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class FooterInputArgs extends StoryArgs<Footer> {
  FooterInputArgs({Arg<CoreFooterLayout>? layout})
    : this.layoutArg = $initArg(
        'layout',
        layout,
        EnumArg<CoreFooterLayout>(
          CoreFooterLayout.horizontal,
          values: CoreFooterLayout.values,
        ),
      )!;

  FooterInputArgs.fixed({CoreFooterLayout layout = CoreFooterLayout.horizontal})
    : this.layoutArg = $initArg('layout', Arg.fixed(layout), null)!;

  final Arg<CoreFooterLayout> layoutArg;

  CoreFooterLayout get layout => layoutArg.value;

  @override
  List<Arg?> get list => [layoutArg];
}
