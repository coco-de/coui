// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'description_card.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<DescriptionCard, StoryArgs<DescriptionCard>>;
typedef _Scenario = DescriptionCardScenario;
typedef _Defaults = DescriptionCardDefaults;
typedef _Story = DescriptionCardStory;
typedef _Args = DescriptionCardInputArgs;
final DescriptionCardComponent =
    Component<DescriptionCard, StoryArgs<DescriptionCard>>(
      name: kComponentMeta.name ?? 'DescriptionCard',
      path: kComponentMeta.path ?? 'component/description_card',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''레이블-값 쌍을 동적으로 나열하는 메타데이터 카드 컴포넌트.

Web `DescriptionCard` 와 동일한 API/렌더링.

```dart
DescriptionCard(
  title: '주문 상세',
  variant: CoreDescriptionCardVariant.outlined,
  rows: [
    DescriptionRow(label: '주문번호', value: 'ORD-2025-00391'),
    DescriptionRow(label: '결제금액', value: '₩369,000', isEmphasized: true),
  ],
  descriptionCardStyle: CoreDescriptionCardStyle(
    padding: EdgeInsets.all(24),
  ),
)
```

surface:behind — draws its own box rather than composing `Card`, so what shows
through it is the page it is laid on.

surface:content — draws its own box in the page flow, the same layer
`Card` sits on.''',
      stories: [
        $Default..$generatedName = 'Default',
        $VerticalLayout..$generatedName = 'VerticalLayout',
        $EmptyValues..$generatedName = 'EmptyValues',
      ],
    );
typedef DescriptionCardScenario =
    Scenario<DescriptionCard, DescriptionCardInputArgs>;
typedef DescriptionCardDefaults =
    Defaults<DescriptionCard, DescriptionCardInputArgs>;

class DescriptionCardStory
    extends Story<DescriptionCard, DescriptionCardInputArgs> {
  DescriptionCardStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    DescriptionCardInputArgs? args,
    StoryWidgetBuilder<DescriptionCard, DescriptionCardInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? DescriptionCardInputArgs(),
         builder: builder ?? defaults.builder!,
       );
}

class DescriptionCardInputArgs extends StoryArgs<DescriptionCard> {
  DescriptionCardInputArgs({
    Arg<String>? title,
    Arg<DescriptionCardDataset>? dataset,
    Arg<CoreDescriptionCardVariant>? variant,
    Arg<CoreDescriptionCardLayout>? layout,
    Arg<CoreDescriptionCardRowWeight>? rowWeight,
    Arg<CoreDescriptionCardEmptyBehavior>? emptyValueBehavior,
    Arg<String>? emptyPlaceholder,
    Arg<bool>? showRowDividers,
    Arg<bool>? showTitleIcon,
  }) : this.titleArg = $initArg('title', title, StringArg('Order Detail'))!,
       this.datasetArg = $initArg(
         'dataset',
         dataset,
         EnumArg<DescriptionCardDataset>(
           DescriptionCardDataset.order,
           values: DescriptionCardDataset.values,
         ),
       )!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreDescriptionCardVariant>(
           CoreDescriptionCardVariant.outlined,
           values: CoreDescriptionCardVariant.values,
         ),
       )!,
       this.layoutArg = $initArg(
         'layout',
         layout,
         EnumArg<CoreDescriptionCardLayout>(
           CoreDescriptionCardLayout.horizontal,
           values: CoreDescriptionCardLayout.values,
         ),
       )!,
       this.rowWeightArg = $initArg(
         'rowWeight',
         rowWeight,
         EnumArg<CoreDescriptionCardRowWeight>(
           CoreDescriptionCardRowWeight.valueProminent,
           values: CoreDescriptionCardRowWeight.values,
         ),
       )!,
       this.emptyValueBehaviorArg = $initArg(
         'emptyValueBehavior',
         emptyValueBehavior,
         EnumArg<CoreDescriptionCardEmptyBehavior>(
           CoreDescriptionCardEmptyBehavior.hide,
           values: CoreDescriptionCardEmptyBehavior.values,
         ),
       )!,
       this.emptyPlaceholderArg = $initArg(
         'emptyPlaceholder',
         emptyPlaceholder,
         StringArg('Not provided'),
       )!,
       this.showRowDividersArg = $initArg(
         'showRowDividers',
         showRowDividers,
         BoolArg(false),
       )!,
       this.showTitleIconArg = $initArg(
         'showTitleIcon',
         showTitleIcon,
         BoolArg(false),
       )!;

  DescriptionCardInputArgs.fixed({
    String title = 'Order Detail',
    DescriptionCardDataset dataset = DescriptionCardDataset.order,
    CoreDescriptionCardVariant variant = CoreDescriptionCardVariant.outlined,
    CoreDescriptionCardLayout layout = CoreDescriptionCardLayout.horizontal,
    CoreDescriptionCardRowWeight rowWeight =
        CoreDescriptionCardRowWeight.valueProminent,
    CoreDescriptionCardEmptyBehavior emptyValueBehavior =
        CoreDescriptionCardEmptyBehavior.hide,
    String emptyPlaceholder = 'Not provided',
    bool showRowDividers = false,
    bool showTitleIcon = false,
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.datasetArg = $initArg('dataset', Arg.fixed(dataset), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.layoutArg = $initArg('layout', Arg.fixed(layout), null)!,
       this.rowWeightArg = $initArg('rowWeight', Arg.fixed(rowWeight), null)!,
       this.emptyValueBehaviorArg = $initArg(
         'emptyValueBehavior',
         Arg.fixed(emptyValueBehavior),
         null,
       )!,
       this.emptyPlaceholderArg = $initArg(
         'emptyPlaceholder',
         Arg.fixed(emptyPlaceholder),
         null,
       )!,
       this.showRowDividersArg = $initArg(
         'showRowDividers',
         Arg.fixed(showRowDividers),
         null,
       )!,
       this.showTitleIconArg = $initArg(
         'showTitleIcon',
         Arg.fixed(showTitleIcon),
         null,
       )!;

  final Arg<String> titleArg;

  final Arg<DescriptionCardDataset> datasetArg;

  final Arg<CoreDescriptionCardVariant> variantArg;

  final Arg<CoreDescriptionCardLayout> layoutArg;

  final Arg<CoreDescriptionCardRowWeight> rowWeightArg;

  final Arg<CoreDescriptionCardEmptyBehavior> emptyValueBehaviorArg;

  final Arg<String> emptyPlaceholderArg;

  final Arg<bool> showRowDividersArg;

  final Arg<bool> showTitleIconArg;

  String get title => titleArg.value;

  DescriptionCardDataset get dataset => datasetArg.value;

  CoreDescriptionCardVariant get variant => variantArg.value;

  CoreDescriptionCardLayout get layout => layoutArg.value;

  CoreDescriptionCardRowWeight get rowWeight => rowWeightArg.value;

  CoreDescriptionCardEmptyBehavior get emptyValueBehavior =>
      emptyValueBehaviorArg.value;

  String get emptyPlaceholder => emptyPlaceholderArg.value;

  bool get showRowDividers => showRowDividersArg.value;

  bool get showTitleIcon => showTitleIconArg.value;

  @override
  List<Arg?> get list => [
    titleArg,
    datasetArg,
    variantArg,
    layoutArg,
    rowWeightArg,
    emptyValueBehaviorArg,
    emptyPlaceholderArg,
    showRowDividersArg,
    showTitleIconArg,
  ];
}
