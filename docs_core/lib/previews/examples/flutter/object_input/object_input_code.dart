/// Returns a Flutter code snippet string for the ObjectInput component.
String objectInputCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class ObjectInputChainExample extends StatelessWidget {
  const ObjectInputChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          onChanged: (values) => debugPrint('\$values'),
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
          onChanged: (values) => debugPrint('\$values'),
        ).withStyle(
          const CoreObjectInputStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderColor: CoreColor.token(CoreColors.tertiary),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
            borderWidth: CoreStrokeWidth.stroke2,
          ),
        ),
      ],
    );
  }
}''',
    _ =>
      '''
class ObjectInputDefaultExample extends StatelessWidget {
  const ObjectInputDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return ObjectInput(
      fields: const [
        CoreObjectInputField(key: 'year', placeholder: 'YYYY', maxLength: 4, pattern: r'\\d'),
        CoreObjectInputField(key: 'month', placeholder: 'MM', maxLength: 2, pattern: r'\\d'),
        CoreObjectInputField(key: 'day', placeholder: 'DD', maxLength: 2, pattern: r'\\d'),
      ],
      separator: '/',
      onChanged: (values) => debugPrint('\$values'),
    );
  }
}''',
  };
}
