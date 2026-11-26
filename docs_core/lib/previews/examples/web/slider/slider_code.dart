/// Returns a Web code snippet string for the Slider component.
String sliderCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class SliderChainExample extends StatefulComponent {
  const SliderChainExample({super.key});

  @override
  State<SliderChainExample> createState() => _SliderChainExampleState();
}

class _SliderChainExampleState extends State<SliderChainExample> {
  double _value = 50;

  @override
  Component build(BuildContext context) {
    return Slider(
          value: _value,
          min: 0,
          max: 100,
          onChanged: (v) => setState(() => _value = v),
        )
        .withStyle(
          const CoreSliderStyle(
            trackHeight: CoreSpace.space12,
            thumbSize: CoreSpace.space24,
            activeColor: CoreColor.token(CoreColors.tertiary),
          ),
        )
        .radius16;
  }
}
''',
    'disabled' =>
      '''
class SliderDisabledExample extends StatefulComponent {
  const SliderDisabledExample({super.key});

  @override
  State<SliderDisabledExample> createState() => _SliderDisabledExampleState();
}

class _SliderDisabledExampleState extends State<SliderDisabledExample> {
  double _value = 50;

  @override
  Component build(BuildContext context) {
    return Slider(
      value: _value,
      min: 0,
      max: 100,
      enabled: false,
      onChanged: (value) {
        setState(() {
          _value = value;
        });
      },
    );
  }
}''',
    _ =>
      '''
class SliderDefaultExample extends StatefulComponent {
  const SliderDefaultExample({super.key});

  @override
  State<SliderDefaultExample> createState() => _SliderDefaultExampleState();
}

class _SliderDefaultExampleState extends State<SliderDefaultExample> {
  double _value = 50;

  @override
  Component build(BuildContext context) {
    return Slider(
      value: _value,
      min: 0,
      max: 100,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}''',
  };
}
