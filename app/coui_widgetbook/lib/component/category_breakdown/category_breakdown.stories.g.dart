// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'category_breakdown.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<CategoryBreakdown, StoryArgs<CategoryBreakdown>>;
typedef _Scenario = CategoryBreakdownScenario;
typedef _Defaults = CategoryBreakdownDefaults;
typedef _Story = CategoryBreakdownStory;
typedef _Args = CategoryBreakdownInputArgs;
final CategoryBreakdownComponent =
    Component<CategoryBreakdown, StoryArgs<CategoryBreakdown>>(
      name: kComponentMeta.name ?? 'CategoryBreakdown',
      path: kComponentMeta.path ?? 'component/category_breakdown',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment:
          r'''Unified cross-platform category breakdown — each category's share of a
total, drawn as horizontal bars (default) or a donut with a legend.

Every row reads label, value and share together, so no category is
told apart by colour alone. Uses [CoreCategoryBreakdownContract] from
`coui_core`, so the Web `CategoryBreakdown` takes the same named
properties.

Example:
```dart
CategoryBreakdown(
  semanticLabel: '문의 유형별 분포',
  items: const [
    CoreCategoryBreakdownItem(label: '결제', value: 128, valueLabel: '128건'),
    CoreCategoryBreakdownItem(label: '배송', value: 61, valueLabel: '61건'),
  ],
)
```''',
      stories: [$Default..$generatedName = 'Default'],
    );
typedef CategoryBreakdownScenario =
    Scenario<CategoryBreakdown, CategoryBreakdownInputArgs>;
typedef CategoryBreakdownDefaults =
    Defaults<CategoryBreakdown, CategoryBreakdownInputArgs>;

class CategoryBreakdownStory
    extends Story<CategoryBreakdown, CategoryBreakdownInputArgs> {
  CategoryBreakdownStory({
    super.name,
    super.designLink,
    SetupBuilder<CategoryBreakdown, CategoryBreakdownInputArgs>? setup,
    super.modes,
    CategoryBreakdownInputArgs? args,
    StoryWidgetBuilder<CategoryBreakdown, CategoryBreakdownInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? CategoryBreakdownInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class CategoryBreakdownInputArgs extends StoryArgs<CategoryBreakdown> {
  CategoryBreakdownInputArgs({
    Arg<double>? width,
    Arg<CoreCategoryBreakdownVariant>? variant,
  }) : this.widthArg = $initArg(
         'width',
         width,
         DoubleArg(_kCategoryBreakdownWidth),
       )!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreCategoryBreakdownVariant>(
           CoreCategoryBreakdownVariant.bar,
           values: CoreCategoryBreakdownVariant.values,
         ),
       )!;

  CategoryBreakdownInputArgs.fixed({
    double width = _kCategoryBreakdownWidth,
    CoreCategoryBreakdownVariant variant = CoreCategoryBreakdownVariant.bar,
  }) : this.widthArg = $initArg('width', Arg.fixed(width), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!;

  final Arg<double> widthArg;

  final Arg<CoreCategoryBreakdownVariant> variantArg;

  double get width => widthArg.value;

  CoreCategoryBreakdownVariant get variant => variantArg.value;

  @override
  List<Arg?> get list => [widthArg, variantArg];
}
