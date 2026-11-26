/// Returns a Web code snippet string for the ObjectInput component.
String objectInputCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ObjectInputChainExample extends StatelessComponent {
  const ObjectInputChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        // 토큰-정확 getter combo — 이름이 곧 값 (getter 이름 = Core 토큰 상수 1:1).
        ObjectInput(
          fields: const [
            CoreObjectInputField(
              key: 'year',
              placeholder: 'YYYY',
              maxLength: 4,
              pattern: r'\\d',
            ),
            CoreObjectInputField(
              key: 'month',
              placeholder: 'MM',
              maxLength: 2,
              pattern: r'\\d',
            ),
            CoreObjectInputField(
              key: 'day',
              placeholder: 'DD',
              maxLength: 2,
              pattern: r'\\d',
            ),
          ],
          separator: '/',
          onChanged: (values) => print('\$values'),
        ).radius16.primary,
        const Gap.space12(),
        // withStyle full-control — getter 가 없는 필드(borderColor·borderWidth)까지 한 번에.
        ObjectInput(
          fields: const [
            CoreObjectInputField(
              key: 'year',
              placeholder: 'YYYY',
              maxLength: 4,
              pattern: r'\\d',
            ),
            CoreObjectInputField(
              key: 'month',
              placeholder: 'MM',
              maxLength: 2,
              pattern: r'\\d',
            ),
            CoreObjectInputField(
              key: 'day',
              placeholder: 'DD',
              maxLength: 2,
              pattern: r'\\d',
            ),
          ],
          separator: '/',
          onChanged: (values) => print('\$values'),
        ).withStyle(
          const CoreObjectInputStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    _ =>
      '''
class ObjectInputDefaultExample extends StatelessComponent {
  const ObjectInputDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return ObjectInput(
      fields: const [
        CoreObjectInputField(key: 'year', placeholder: 'YYYY', maxLength: 4, pattern: r'\\d'),
        CoreObjectInputField(key: 'month', placeholder: 'MM', maxLength: 2, pattern: r'\\d'),
        CoreObjectInputField(key: 'day', placeholder: 'DD', maxLength: 2, pattern: r'\\d'),
      ],
      separator: '/',
      onChanged: (values) => print('\$values'),
    );
  }
}''',
  };
}
