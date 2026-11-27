import 'package:coui_flutter/coui_flutter.dart';

/// Demonstrates radius and explicit paint on [Fieldset].
class FieldsetChainExample extends StatelessWidget {
  const FieldsetChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Fixed-width wrappers so the preview matches Web's
    // `w-${CoreSpace.scale.space256}` wrapper — the docs preview
    // pane is already centred, we just need a known cross-axis
    // size to keep both platforms visually identical.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 팔레트 미리보기에서는 색을 직접 지정한다.
        SizedBox(
          width: CoreSpace.space256,
          child: Fieldset(
            legend: const Text('계정'),
            children: [
              TextField(
                autofillHints: const [AutofillHints.name],
                placeholder: const Text('이름'),
              ),
              TextField(
                autofillHints: const [AutofillHints.email],
                placeholder: const Text('이메일'),
              ),
            ],
          ).radius16.backgroundColor(.primary),
        ),
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(padding)까지 한 번에.
        SizedBox(
          width: CoreSpace.space256,
          child:
              Fieldset(
                legend: const Text('계정'),
                children: [
                  TextField(
                    autofillHints: const [AutofillHints.name],
                    placeholder: const Text('이름'),
                  ),
                  TextField(
                    autofillHints: const [AutofillHints.email],
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
        ),
      ],
    );
  }
}
