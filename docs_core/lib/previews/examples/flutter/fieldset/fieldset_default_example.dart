import 'package:coui_flutter/coui_flutter.dart';

/// 기본 변형(`filled`) — 범례 · 설명 · 필드 둘.
///
/// Fixed-width wrapper so the preview matches Web's
/// `w-${CoreSpace.scale.space256}` wrapper — the docs preview
/// pane is already centred, we just need a known cross-axis
/// size to keep both platforms visually identical.
class FieldsetDefaultExample extends StatelessWidget {
  const FieldsetDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space256,
      child: Fieldset(
        legend: const Text('계정'),
        description: const Text('로그인에 쓰는 정보예요.'),
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
      ),
    );
  }
}
