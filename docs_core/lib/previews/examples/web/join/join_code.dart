/// Returns a Web code snippet string for the Join component.
String joinCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class JoinChainExample extends StatelessComponent {
  const JoinChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return Join(
          children: [
            Button(
              variant: CoreButtonVariant.outline,
              onPressed: () {},
              child: Text('1'),
            ),
            Button(
              variant: CoreButtonVariant.outline,
              onPressed: () {},
              child: Text('2'),
            ),
            Button(
              variant: CoreButtonVariant.outline,
              onPressed: () {},
              child: Text('3'),
            ),
          ],
        )
        .withStyle(
          const CoreJoinStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          ),
        )
        .radius16;
  }
}''',
    'input' =>
      '''
// The field's width in the strip.
const String _kFieldWidth = '200px';

class JoinInputExample extends StatelessComponent {
  const JoinInputExample({super.key});

  @override
  Component build(BuildContext context) {
    return Join(
      children: [
        div(
          [TextField(placeholder: const Text('이메일 주소'))],
          styles: const Styles(raw: {'width': _kFieldWidth}),
        ),
        Button(onPressed: () {}, child: Text('구독하기')),
      ],
    );
  }
}''',
    'vertical' =>
      '''
class JoinVerticalExample extends StatelessComponent {
  const JoinVerticalExample({super.key});

  @override
  Component build(BuildContext context) {
    return Join(
      vertical: true,
      children: [
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: Text('A'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: Text('B'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: Text('C'),
        ),
      ],
    );
  }
}''',
    _ =>
      '''
class JoinDefaultExample extends StatelessComponent {
  const JoinDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return Join(
      children: [
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: Text('1'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: Text('2'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: Text('3'),
        ),
      ],
    );
  }
}''',
  };
}
