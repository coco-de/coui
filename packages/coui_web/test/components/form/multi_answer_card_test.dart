import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/multi_answer_card/multi_answer_card_style.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveMultiAnswerCard` directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

List<String> _classes(WebElementChrome chrome) => chrome.className.split(' ');

void main() {
  group('MultiAnswerCard resolver', () {
    testComponents('every state keeps the same 1 px border, so the height '
        'never changes with selection', (tester) async {
      final resolved = resolveMultiAnswerCard(_themedContext(tester));
      final widths = {
        for (final state in [
          resolved.root,
          resolved.hoverRoot,
          resolved.selectedRoot,
          resolved.disabledRoot,
        ])
          _inline(state)['border-width'],
      };
      expect(widths, hasLength(1));
      // No thickening inset layer: the selected state adds no spread.
      expect(
        _inline(resolved.selectedRoot)['box-shadow'],
        startsWith('inset 0 0 0 0.0rem'),
      );
      // …and the padding carries no border compensation.
      expect(
        _inline(resolved.selectedRoot)['padding'],
        isNot(contains('calc')),
      );
    });

    testComponents('border colours: outline-variant resting, outline hover, '
        'primary selected, disabled-outline disabled', (tester) async {
      final resolved = resolveMultiAnswerCard(_themedContext(tester));
      expect(
        _inline(resolved.root)['border-color'],
        const CoreColor.token(CoreColors.outlineVariant).toValue(),
      );
      expect(
        _inline(resolved.hoverRoot)['border-color'],
        const CoreColor.token(CoreColors.outline).toValue(),
      );
      expect(
        _inline(resolved.selectedRoot)['border-color'],
        const CoreColor.token(CoreColors.primary).toValue(),
      );
      expect(
        _inline(resolved.disabledRoot)['border-color'],
        const CoreColor.token(CoreColors.disabledOutline).toValue(),
      );
    });

    testComponents('fills: primary-container selected, disabled-container '
        'disabled', (tester) async {
      final resolved = resolveMultiAnswerCard(_themedContext(tester));
      expect(
        _classes(resolved.selectedRoot),
        contains('bg-primary-container'),
      );
      expect(
        _classes(resolved.disabledRoot),
        contains('bg-disabled-container'),
      );
    });

    testComponents('text: body-large resting, label-xl selected, disabled '
        'content when disabled', (tester) async {
      final resolved = resolveMultiAnswerCard(_themedContext(tester));
      expect(_classes(resolved.root), contains('text-body-large'));
      expect(_classes(resolved.selectedRoot), contains('text-label-xl'));
      expect(_classes(resolved.disabledRoot), contains('text-body-large'));
      expect(
        _classes(resolved.disabledRoot),
        contains('text-disabled-content'),
      );
      // The selected label keeps the resting 150% line, so the card does not
      // change height when the weight does — drawn on the whole pixel
      // Flutter's engine lays the line out in.
      expect(
        _inline(resolved.selectedRoot)['line-height'],
        CssVariableGenerator.lineHeightCss(1.5),
      );
    });

    testComponents('is a flex row with the trailing lg checkbox slot', (
      tester,
    ) async {
      final resolved = resolveMultiAnswerCard(_themedContext(tester));
      expect(_classes(resolved.root), containsAll(['flex', 'items-center']));
      expect(resolved.checkboxSize, CoreComponentSize.lg);
      expect(resolved.checkboxGapStyle.size, CoreSpace.space12);
      expect(_inline(resolved.root)['border-radius'], isNotNull);
    });
  });

  group('MultiAnswerCard DOM', () {
    testServer('renders the answer and a checkbox that follows the selection', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: MultiAnswerCard<String>(
            value: 'a',
            selected: true,
            onChanged: (_) {},
            child: const Text('Answer A'),
          ),
        ),
      );
      final response = await tester.request('/');
      final card = response.document?.querySelector('[aria-pressed="true"]');
      expect(card, isNotNull);
      expect(card!.text, contains('Answer A'));
      expect(card.querySelector('[role="checkbox"]'), isNotNull);
      expect(card.querySelector('[aria-checked="true"]'), isNotNull);
    });
  });
}
