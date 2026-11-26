/// Returns a Flutter code snippet string for the Join component.
String joinCode(String? variant) {
  return switch (variant) {
    'chain' =>
      '''
class JoinChainExample extends StatelessWidget {
  const JoinChainExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Join(
          children: [
            Button(
              variant: CoreButtonVariant.outline,
              onPressed: () {},
              child: const Text('1'),
            ),
            Button(
              variant: CoreButtonVariant.outline,
              onPressed: () {},
              child: const Text('2'),
            ),
            Button(
              variant: CoreButtonVariant.outline,
              onPressed: () {},
              child: const Text('3'),
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
// The field's width in the strip — a `Row` gives its children unbounded
// width, so the field is told how wide to be.
const double _kFieldWidth = 200;

class JoinInputExample extends StatelessWidget {
  const JoinInputExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Join(
      children: [
        SizedBox(
          width: _kFieldWidth,
          child: TextField(placeholder: const Text('이메일 주소')),
        ),
        Button(onPressed: () {}, child: const Text('구독하기')),
      ],
    );
  }
}''',
    'vertical' =>
      '''
class JoinVerticalExample extends StatelessWidget {
  const JoinVerticalExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Join(
      vertical: true,
      children: [
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: const Text('A'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: const Text('B'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: const Text('C'),
        ),
      ],
    );
  }
}''',
    _ =>
      '''
class JoinDefaultExample extends StatelessWidget {
  const JoinDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Join(
      children: [
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: const Text('1'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: const Text('2'),
        ),
        Button(
          variant: CoreButtonVariant.outline,
          onPressed: () {},
          child: const Text('3'),
        ),
      ],
    );
  }
}''',
  };
}
