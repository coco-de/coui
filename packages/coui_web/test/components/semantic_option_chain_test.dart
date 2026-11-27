import 'package:coui_web/coui_web.dart';
import 'package:test/test.dart';

void main() {
  test('paint and semantic chains preserve Web markup', () {
    final chip = Chip(
      label: 'One',
      classes: 'tag',
      attributes: {'aria-label': 'Label'},
      eventHandlers: {
        'click': [(_) {}],
      },
    );
    final painted = chip.primary.backgroundColor(.secondary);
    expect(painted.classes, 'tag');
    expect(painted.userAttributes, chip.userAttributes);
    expect(painted.eventHandlers, same(chip.eventHandlers));
    const progress = Progress(attributes: {'aria-label': 'Loading'});
    expect(
      progress.success.fillColor(.success).userAttributes,
      progress.userAttributes,
    );
    const footer = Footer(sections: [], tag: 'aside');
    expect(footer.backgroundColor(.surface).tag, 'aside');
  });

  test('Button option getters compose with explicit style', () {
    const style = CoreButtonStyle(
      backgroundColor: .tertiary,
    );
    final base = Button(buttonStyle: style, child: const Text('Save'));
    const insets = CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16);
    final styled = base.outline
        .contentPadding(insets)
        .borderColor(.outline)
        .borderWidth(CoreStrokeWidth.stroke2)
        .foregroundColor(.onSurface);
    expect(styled.variant, base.outline.variant);
    expect(styled.buttonStyle?.padding, insets);
    expect(styled.buttonStyle?.borderColor, CoreColor.outline);
    expect(styled.buttonStyle?.borderWidth, CoreStrokeWidth.stroke2);
    expect(styled.buttonStyle?.backgroundColor, style.backgroundColor);
    expect(
      styled.borderColor(.primary).buttonStyle?.borderColor,
      CoreColor.primary,
    );
    expect(styled.buttonStyle?.foregroundColor, CoreColor.onSurface);
    final painted = base.primary.radius16.backgroundColor(.secondary);
    expect(painted.variant, CoreButtonVariant.primary);
    expect(painted.buttonStyle?.backgroundColor, CoreColor.secondary);
    expect(
      painted.buttonStyle?.borderRadius,
      base.radius16.buttonStyle?.borderRadius,
    );
    expect(painted.child, same(base.child));
    expect(painted.outline.buttonStyle?.backgroundColor, CoreColor.secondary);
    expect(base.buttonStyle?.backgroundColor, CoreColor.tertiary);
    expect(base.primary.variant, CoreButtonVariant.primary);
    expect(base.primary.buttonStyle, same(style));
    expect(base.secondary.variant, CoreButtonVariant.secondary);
    expect(base.secondary.buttonStyle, same(style));
    expect(base.outline.variant, CoreButtonVariant.outline);
    expect(base.outline.buttonStyle, same(style));
  });

  test('Badge option getters compose with explicit style', () {
    const style = CoreBadgeStyle(
      backgroundColor: .tertiary,
    );
    const base = Badge(badgeStyle: style, child: Text('Saved'));
    const insets = CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16);
    final styled = base.outline
        .contentPadding(insets)
        .borderColor(.outline)
        .borderWidth(CoreStrokeWidth.stroke2)
        .foregroundColor(.onSurface);
    expect(styled.variant, base.outline.variant);
    expect(styled.badgeStyle?.padding, insets);
    expect(styled.badgeStyle?.borderColor, CoreColor.outline);
    expect(styled.badgeStyle?.borderWidth, CoreStrokeWidth.stroke2);
    expect(styled.badgeStyle?.backgroundColor, style.backgroundColor);
    expect(
      styled.borderColor(.primary).badgeStyle?.borderColor,
      CoreColor.primary,
    );
    expect(styled.badgeStyle?.foregroundColor, CoreColor.onSurface);
    expect(base.primary.tone, CoreBadgeTone.primary);
    expect(base.primary.badgeStyle, same(style));
    expect(base.info.tone, CoreBadgeTone.info);
    expect(base.info.badgeStyle, same(style));
    expect(base.success.tone, CoreBadgeTone.success);
    expect(base.success.badgeStyle, same(style));
    expect(base.warning.tone, CoreBadgeTone.warning);
    expect(base.warning.badgeStyle, same(style));
    expect(base.outline.variant, CoreBadgeVariant.outlined);
    expect(base.outline.badgeStyle, same(style));
    expect(base.success.outline.tone, CoreBadgeTone.success);
    expect(base.success.warning.tone, CoreBadgeTone.warning);
  });

  test('Progress option getters compose with explicit style', () {
    const style = CoreProgressStyle(
      color: .tertiary,
    );
    const base = Progress(progressStyle: style);
    final painted = base.warning.fillColor(.info).backgroundColor(.surface);
    expect(painted.tone, CoreProgressTone.warning);
    expect(painted.progressStyle?.color, CoreColor.info);
    expect(painted.progressStyle?.backgroundColor, CoreColor.surface);
    expect(base.primary.tone, CoreProgressTone.primary);
    expect(base.primary.progressStyle, same(style));
    expect(base.success.tone, CoreProgressTone.success);
    expect(base.success.progressStyle, same(style));
    expect(base.warning.tone, CoreProgressTone.warning);
    expect(base.warning.progressStyle, same(style));
  });

  test('Chip option getters compose with explicit style', () {
    const style = CoreChipStyle(
      backgroundColor: .tertiary,
    );
    final base = Chip(label: 'One', selected: true, chipStyle: style);
    expect(base.primary.chipColor, CoreChipColor.primary);
    expect(base.primary.chipStyle, same(style));
    expect(base.outline.variant, CoreChipVariant.outlined);
    expect(base.outline.chipStyle, same(style));
    expect(base.primary.selected, isTrue);
  });

  test('Alert option getters compose with explicit style', () {
    const style = CoreAlertStyle(
      backgroundColor: .tertiary,
    );
    const base = Alert(title: 'Saved', alertStyle: style);
    expect(base.info.variant, CoreAlertVariant.info);
    expect(base.info.alertStyle, same(style));
    expect(base.success.variant, CoreAlertVariant.success);
    expect(base.success.alertStyle, same(style));
    expect(base.warning.variant, CoreAlertVariant.warning);
    expect(base.warning.alertStyle, same(style));
  });

  test('Banner option getters compose with explicit style', () {
    const style = CoreBannerStyle(
      backgroundColor: .tertiary,
    );
    const base = Banner(message: Text('Saved'), bannerStyle: style);
    expect(base.info.variant, CoreBannerVariant.info);
    expect(base.info.bannerStyle, same(style));
    expect(base.success.variant, CoreBannerVariant.success);
    expect(base.success.bannerStyle, same(style));
    expect(base.warning.variant, CoreBannerVariant.warning);
    expect(base.warning.bannerStyle, same(style));
  });

  test('TextField option getters compose with explicit style', () {
    const style = CoreTextFieldStyle(
      backgroundColor: .tertiary,
    );
    const base = TextField(errorText: 'Required', textFieldStyle: style);
    expect(base.error.variant, CoreTextFieldVariant.error);
    expect(base.error.textFieldStyle, same(style));
    expect(base.error.errorText, 'Required');
    expect(const TextField().error.errorText, isNull);
  });

  test('TextArea option getters compose with explicit style', () {
    const style = CoreTextAreaStyle(
      backgroundColor: .tertiary,
    );
    const base = TextArea(errorText: 'Required', textAreaStyle: style);
    expect(base.error.variant, CoreTextAreaVariant.error);
    expect(base.error.textAreaStyle, same(style));
    expect(base.error.errorText, 'Required');
    expect(const TextArea().error.errorText, isNull);
  });

  test('Card option getters compose with explicit style', () {
    const style = CoreCardStyle(
      backgroundColor: .tertiary,
    );
    const base = Card(cardStyle: style);
    const insets = CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16);
    final styled = base.outline
        .contentPadding(insets)
        .borderColor(.outline)
        .borderWidth(CoreStrokeWidth.stroke2);
    expect(styled.variant, base.outline.variant);
    expect(styled.cardStyle?.padding, insets);
    expect(styled.cardStyle?.borderColor, CoreColor.outline);
    expect(styled.cardStyle?.borderWidth, CoreStrokeWidth.stroke2);
    expect(styled.cardStyle?.backgroundColor, style.backgroundColor);
    expect(
      styled.borderColor(.primary).cardStyle?.borderColor,
      CoreColor.primary,
    );
    expect(base.outline.variant, CoreCardVariant.outlined);
    expect(base.outline.cardStyle, same(style));
  });

  test('DescriptionCard option getters compose with explicit style', () {
    const style = CoreDescriptionCardStyle(
      backgroundColor: .tertiary,
    );
    const base = DescriptionCard(rows: [], descriptionCardStyle: style);
    expect(base.outline.variant, CoreDescriptionCardVariant.outlined);
    expect(base.outline.descriptionCardStyle, same(style));
  });

  test('Fieldset option getters compose with explicit style', () {
    const style = CoreFieldsetStyle(
      backgroundColor: .tertiary,
    );
    const base = Fieldset(fieldsetStyle: style);
    expect(base.outline.variant, CoreFieldsetVariant.outlined);
    expect(base.outline.fieldsetStyle, same(style));
  });

  test('Stat option getters compose with explicit style', () {
    const style = CoreStatStyle(
      backgroundColor: .tertiary,
    );
    const base = Stat(label: 'Total', statStyle: style);
    expect(base.outline.variant, CoreStatVariant.outlined);
    expect(base.outline.statStyle, same(style));
  });
}
