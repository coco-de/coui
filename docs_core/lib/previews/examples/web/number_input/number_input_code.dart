/// Returns a Web code snippet string for the NumberInput component.
String numberInputCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class NumberInputChainExample extends StatelessComponent {
  const NumberInputChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return NumberInput(
      label: '인원',
      initialValue: 2,
      min: 1,
      max: 8,
      onChanged: (value) => print('Guests: \$value'),
    ).withStyle(
      const CoreNumberInputStyle(
        buttonStyle: CoreButtonStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
        ),
      ),
    );
  }
}''',
    'sizes' =>
      '''
class NumberInputSizesExample extends StatelessComponent {
  const NumberInputSizesExample({super.key});

  @override
  Component build(BuildContext context) {
    return div(
      [
        const NumberInput(size: CoreNumberInputSize.sm, initialValue: 1, min: 0),
        const Gap.space12(),
        const NumberInput(size: CoreNumberInputSize.md, initialValue: 1, min: 0),
        const Gap.space12(),
        const NumberInput(size: CoreNumberInputSize.lg, initialValue: 1, min: 0),
      ],
      classes: 'flex flex-col items-start',
    );
  }
}''',
    'filled' =>
      '''
class NumberInputFilledExample extends StatelessComponent {
  const NumberInputFilledExample({super.key});

  @override
  Component build(BuildContext context) {
    return NumberInput(
      label: '수량',
      initialValue: 1,
      min: 1,
      variant: CoreNumberInputVariant.filled,
      onChanged: (value) => print('Quantity: \$value'),
    );
  }
}''',
    'error' =>
      '''
class NumberInputErrorExample extends StatelessComponent {
  const NumberInputErrorExample({super.key});

  @override
  Component build(BuildContext context) {
    return NumberInput(
      label: '인원',
      errorText: '8명을 넘길 수 없어요',
      initialValue: 8,
      min: 1,
      max: 8,
      variant: CoreNumberInputVariant.error,
      onChanged: (value) => print('Guests: \$value'),
    );
  }
}''',
    'disabled' =>
      '''
class NumberInputDisabledExample extends StatelessComponent {
  const NumberInputDisabledExample({super.key});

  @override
  Component build(BuildContext context) {
    return NumberInput(
      label: '인원',
      initialValue: 2,
      enabled: false,
    );
  }
}''',
    _ =>
      '''
class NumberInputDefaultExample extends StatelessComponent {
  const NumberInputDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return NumberInput(
      label: '인원',
      description: '최대 8명까지 예약할 수 있어요',
      initialValue: 2,
      min: 1,
      max: 8,
      size: CoreNumberInputSize.lg,
      onChanged: (value) => print('Guests: \$value'),
    );
  }
}''',
  };
}
