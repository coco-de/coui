import 'package:coui_web/coui_web.dart';

/// Demonstrates radius and explicit paint on [Fieldset].
class FieldsetChainExample extends StatelessComponent {
  const FieldsetChainExample({super.key});

  @override
  Component build(BuildContext context) {
    // Fixed-width wrappers keep the preview at the same width as
    // Flutter's `SizedBox(width: CoreSpace.space256)` — the docs
    // preview pane uses `align-items: center` for cross-platform
    // visual parity, so we anchor a known size instead of letting
    // the fieldset stretch to the pane's full inline-axis.
    return div(
      [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        div(
          [
            Fieldset(
              legend: const Text('계정'),
              children: [
                TextField(
                  autofillHints: const ['name'],
                  placeholder: const Text('이름'),
                ),
                TextField(
                  autofillHints: const ['email'],
                  placeholder: const Text('이메일'),
                ),
              ],
            ).radius16.backgroundColor(.primary),
          ],
          classes: 'w-${CoreSpace.scale.space256}',
        ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        div(
          [
            Fieldset(
              legend: const Text('계정'),
              children: [
                TextField(
                  autofillHints: const ['name'],
                  placeholder: const Text('이름'),
                ),
                TextField(
                  autofillHints: const ['email'],
                  placeholder: const Text('이메일'),
                ),
              ],
            ).withStyle(
              const CoreFieldsetStyle(
                backgroundColor: .tertiary,
                borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
                fieldSpacing: CoreSpace.space12,
                padding: CoreEdgeInsets.symmetric(
                  horizontal: CoreSpace.space24,
                  vertical: CoreSpace.space8,
                ),
              ),
            ),
          ],
          classes: 'w-${CoreSpace.scale.space256}',
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}
