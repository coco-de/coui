/// Returns a Web code snippet string for the Fieldset component.
String fieldsetCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
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
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
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
            ).radius16.primary,
          ],
          classes: 'w-\${CoreSpace.scale.space256}',
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
                backgroundColor: CoreColor.token(CoreColors.tertiary),
                borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
                fieldSpacing: CoreSpace.space12,
                padding: CoreEdgeInsets.symmetric(
                  horizontal: CoreSpace.space24,
                  vertical: CoreSpace.space8,
                ),
              ),
            ),
          ],
          classes: 'w-\${CoreSpace.scale.space256}',
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'outlined' =>
      '''
class FieldsetOutlinedExample extends StatelessComponent {
  const FieldsetOutlinedExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Fieldset(
          variant: CoreFieldsetVariant.outlined,
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
      classes: 'w-\${CoreSpace.scale.space256}',
    );
  }
}''',
    'plain' =>
      '''
class FieldsetPlainExample extends StatelessComponent {
  const FieldsetPlainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        Fieldset(
          variant: CoreFieldsetVariant.plain,
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
      classes: 'w-\${CoreSpace.scale.space256}',
    );
  }
}''',
    _ =>
      '''
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
      classes: 'w-\${CoreSpace.scale.space256}',
    );
  }
}''',
  };
}
