/// Returns a Flutter code snippet string for the NumberInput component.
String numberInputCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class NumberInputChainExample extends StatelessWidget {
  const NumberInputChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NumberInput(
      label: '인원',
      initialValue: 2,
      min: 1,
      max: 8,
      onChanged: (value) => debugPrint('Guests: \$value'),
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
class NumberInputSizesExample extends StatelessWidget {
  const NumberInputSizesExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const NumberInput(size: CoreNumberInputSize.sm, initialValue: 1, min: 0),
        const Gap.space12(),
        const NumberInput(size: CoreNumberInputSize.md, initialValue: 1, min: 0),
        const Gap.space12(),
        const NumberInput(size: CoreNumberInputSize.lg, initialValue: 1, min: 0),
      ],
    );
  }
}''',
    'filled' =>
      '''
class NumberInputFilledExample extends StatelessWidget {
  const NumberInputFilledExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NumberInput(
      label: '수량',
      initialValue: 1,
      min: 1,
      variant: CoreNumberInputVariant.filled,
      onChanged: (value) => debugPrint('Quantity: \$value'),
    );
  }
}''',
    'error' =>
      '''
class NumberInputErrorExample extends StatelessWidget {
  const NumberInputErrorExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NumberInput(
      label: '인원',
      errorText: '8명을 넘길 수 없어요',
      initialValue: 8,
      min: 1,
      max: 8,
      variant: CoreNumberInputVariant.error,
      onChanged: (value) => debugPrint('Guests: \$value'),
    );
  }
}''',
    'disabled' =>
      '''
class NumberInputDisabledExample extends StatelessWidget {
  const NumberInputDisabledExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NumberInput(
      label: '인원',
      initialValue: 2,
      enabled: false,
    );
  }
}''',
    _ =>
      '''
class NumberInputDefaultExample extends StatelessWidget {
  const NumberInputDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return NumberInput(
      label: '인원',
      description: '최대 8명까지 예약할 수 있어요',
      initialValue: 2,
      min: 1,
      max: 8,
      size: CoreNumberInputSize.lg,
      onChanged: (value) => debugPrint('Guests: \$value'),
    );
  }
}''',
  };
}
