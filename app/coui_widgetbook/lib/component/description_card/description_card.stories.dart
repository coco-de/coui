import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'description_card.stories.g.dart';

/// Order summary rows (default dataset).
const List<CoreDescriptionRow<Widget>> _kOrderRows = [
  DescriptionRow(label: 'Order', value: 'ORD-2025-00391'),
  DescriptionRow(label: 'Item', value: 'AirPods Pro 2'),
  DescriptionRow(label: 'Total', value: r'$369.00', isEmphasized: true),
];

/// Plant-care rows (vertical layout dataset).
const List<CoreDescriptionRow<Widget>> _kPlantRows = [
  DescriptionRow(label: 'Species', value: 'Monstera Deliciosa'),
  DescriptionRow(label: 'Watering', value: 'Every 7 days'),
  DescriptionRow(label: 'Light', value: 'Indirect bright light'),
];

/// Contact rows with missing values (empty-value dataset).
const List<CoreDescriptionRow<Widget>> _kContactRows = [
  DescriptionRow(label: 'Name', value: 'Hong Gildong'),
  DescriptionRow(label: 'Phone'),
  DescriptionRow(label: 'Email'),
  DescriptionRow(label: 'Address', value: 'Seoul, Gangnam-gu'),
];

/// Row dataset options for [DescriptionCard] stories.
enum DescriptionCardDataset {
  /// Contact rows containing empty values.
  contact,

  /// Order summary rows.
  order,

  /// Plant-care rows.
  plantCare,
}

/// Knob input for [DescriptionCard] stories.
class DescriptionCardInput {
  /// Creates a [DescriptionCardInput].
  const DescriptionCardInput({
    this.title = 'Order Detail',
    this.dataset = DescriptionCardDataset.order,
    this.variant = CoreDescriptionCardVariant.outlined,
    this.layout = CoreDescriptionCardLayout.horizontal,
    this.rowWeight = CoreDescriptionCardRowWeight.valueProminent,
    this.emptyValueBehavior = CoreDescriptionCardEmptyBehavior.hide,
    this.emptyPlaceholder = 'Not provided',
    this.showRowDividers = false,
    this.showTitleIcon = false,
  });

  /// Card title text.
  final String title;

  /// Which sample row dataset is rendered.
  final DescriptionCardDataset dataset;

  /// Card chrome variant.
  final CoreDescriptionCardVariant variant;

  /// Label/value layout direction per row.
  final CoreDescriptionCardLayout layout;

  /// Which of label/value is rendered prominently.
  final CoreDescriptionCardRowWeight rowWeight;

  /// How rows with a null value are handled.
  final CoreDescriptionCardEmptyBehavior emptyValueBehavior;

  /// Placeholder text for empty values.
  final String emptyPlaceholder;

  /// Whether dividers are drawn between rows.
  final bool showRowDividers;

  /// Whether an info icon leads the title.
  final bool showTitleIcon;
}

/// Navigation metadata for the DescriptionCard component.
const kComponentMeta = ComponentMeta(name: 'DescriptionCard', path: 'display');

/// Story metadata for [DescriptionCard].
const kMeta = Meta(DescriptionCard.new, argsType: DescriptionCardInput.new);

/// Default builder mapping [DescriptionCardInput] args to a
/// [DescriptionCard].
final DescriptionCardDefaults defaults = _Defaults(
  builder: (context, args) => DescriptionCard(
    rows: switch (args.dataset) {
      .order => _kOrderRows,
      .plantCare => _kPlantRows,
      .contact => _kContactRows,
    },
    layout: args.layout,
    variant: args.variant,
    title: args.title,
    titleLeading: args.showTitleIcon
        ? const Icon(
            LucideIcons.info,
            iconStyle: CoreIconStyle(size: CoreSpace.space16),
          )
        : null,
    showRowDividers: args.showRowDividers,
    rowWeight: args.rowWeight,
    emptyValueBehavior: args.emptyValueBehavior,
    emptyPlaceholder: args.emptyPlaceholder,
  ),
);

/// Order summary card with variant / divider knobs.
final $Default = _Story();

/// Vertical label-over-value layout with a leading title icon.
final $VerticalLayout = _Story(
  name: 'Vertical Layout',
  args: _Args(
    title: StringArg('Plant Care'),
    dataset: EnumArg(
      DescriptionCardDataset.plantCare,
      values: DescriptionCardDataset.values,
    ),
    layout: EnumArg(
      CoreDescriptionCardLayout.vertical,
      values: CoreDescriptionCardLayout.values,
    ),
    rowWeight: EnumArg(
      CoreDescriptionCardRowWeight.labelProminent,
      values: CoreDescriptionCardRowWeight.values,
    ),
    showTitleIcon: BoolArg(true),
  ),
);

/// Empty-value handling with a behavior knob (hide / placeholder).
final $EmptyValues = _Story(
  name: 'Empty Values',
  args: _Args(
    title: StringArg('Empty Rows'),
    dataset: EnumArg(
      DescriptionCardDataset.contact,
      values: DescriptionCardDataset.values,
    ),
    emptyValueBehavior: EnumArg(
      CoreDescriptionCardEmptyBehavior.placeholder,
      values: CoreDescriptionCardEmptyBehavior.values,
    ),
  ),
);
