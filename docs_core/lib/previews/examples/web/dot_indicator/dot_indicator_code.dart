/// Returns a Web code snippet string for the DotIndicator component.
String dotIndicatorCode(String? variant) {
  return switch (variant) {
    'vertical' =>
      '''
class DotIndicatorVerticalExample extends StatefulComponent {
  const DotIndicatorVerticalExample({super.key});

  @override
  State<DotIndicatorVerticalExample> createState() => _DotIndicatorVerticalExampleState();
}

class _DotIndicatorVerticalExampleState extends State<DotIndicatorVerticalExample> {
  int _index = 2;

  @override
  Component build(BuildContext context) {
    return DotIndicator(
      index: _index,
      length: 3,
      direction: CoreAxis.vertical,
      onChanged: (v) => setState(() => _index = v),
    );
  }
}''',
    'passive' =>
      '''
class DotIndicatorPassiveExample extends StatelessComponent {
  const DotIndicatorPassiveExample({super.key});

  @override
  Component build(BuildContext context) => DotIndicator(index: 1, length: 3);
}''',
    'chain' =>
      '''
class DotIndicatorChainExample extends StatefulComponent {
  const DotIndicatorChainExample({super.key});

  @override
  State<DotIndicatorChainExample> createState() => _DotIndicatorChainExampleState();
}

class _DotIndicatorChainExampleState extends State<DotIndicatorChainExample> {
  int _index = 2;

  @override
  Component build(BuildContext context) {
    return DotIndicator(
          index: _index,
          length: 5,
          onChanged: (v) => setState(() => _index = v),
        )
        .withStyle(
          const CoreDotIndicatorStyle(
            activeColor: CoreColor.token(CoreColors.tertiary),
            dotSize: CoreSpace.space16,
            spacing: CoreSpace.space12,
          ),
        )
        .radius16;
  }
}''',
    _ =>
      '''
class DotIndicatorDefaultExample extends StatefulComponent {
  const DotIndicatorDefaultExample({super.key});

  @override
  State<DotIndicatorDefaultExample> createState() =>
      _DotIndicatorDefaultExampleState();
}

class _DotIndicatorDefaultExampleState
    extends State<DotIndicatorDefaultExample> {
  int _index = 2;

  @override
  Component build(BuildContext context) {
    return DotIndicator(
      index: _index,
      length: 5,
      onChanged: (v) => setState(() => _index = v),
    );
  }
}''',
  };
}
