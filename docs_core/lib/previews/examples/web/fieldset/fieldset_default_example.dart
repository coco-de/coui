import 'package:coui_web/coui_web.dart';

/// 기본 변형(`filled`) — 범례 · 설명 · 필드 둘.
///
/// Fixed-width wrapper keeps the preview at the same width as
/// Flutter's `SizedBox(width: CoreSpace.space256)` — the docs
/// preview pane uses `align-items: center` for cross-platform
/// visual parity, so we anchor a known size instead of letting
/// the fieldset stretch to the pane's full inline-axis.
class FieldsetDefaultExample extends StatelessComponent {
  const FieldsetDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Fieldset(
          legend: const Text('계정'),
          description: const Text('로그인에 쓰는 정보예요.'),
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
        ),
      ],
      classes: 'w-${CoreSpace.scale.space256}',
    );
  }
}
