/// Code snippet for [Mask] Flutter examples.
String maskCode(String? variant) {
  return switch (variant) {
    'circle' => _circleCode,
    'heart' => _heartCode,
    'hexagon' => _hexagonCode,
    'star' => _starCode,
    'triangle' => _triangleCode,
    _ => _defaultCode,
  };
}

const _defaultCode = '''
class MaskDefaultExample extends StatelessWidget {
  const MaskDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space64,
      height: CoreSpace.space64,
      child: Mask(
        child: Container(color: Theme.of(context).colorScheme.primary.toValue()),
      ),
    );
  }
}
''';

const _circleCode = '''
class MaskCircleExample extends StatelessWidget {
  const MaskCircleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space64,
      height: CoreSpace.space64,
      child: Mask(
        shape: .circle,
        child: Container(color: Theme.of(context).colorScheme.primary.toValue()),
      ),
    );
  }
}
''';

const _heartCode = '''
class MaskHeartExample extends StatelessWidget {
  const MaskHeartExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space64,
      height: CoreSpace.space64,
      child: Mask(
        shape: .heart,
        child: Container(color: Theme.of(context).colorScheme.primary.toValue()),
      ),
    );
  }
}
''';

const _hexagonCode = '''
class MaskHexagonExample extends StatelessWidget {
  const MaskHexagonExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space64,
      height: CoreSpace.space64,
      child: Mask(
        shape: .hexagon,
        child: Container(color: Theme.of(context).colorScheme.primary.toValue()),
      ),
    );
  }
}
''';

const _starCode = '''
class MaskStarExample extends StatelessWidget {
  const MaskStarExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space64,
      height: CoreSpace.space64,
      child: Mask(
        shape: .star,
        child: Container(color: Theme.of(context).colorScheme.primary.toValue()),
      ),
    );
  }
}
''';

const _triangleCode = '''
class MaskTriangleExample extends StatelessWidget {
  const MaskTriangleExample({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CoreSpace.space64,
      height: CoreSpace.space64,
      child: Mask(
        shape: .triangle,
        child: Container(color: Theme.of(context).colorScheme.primary.toValue()),
      ),
    );
  }
}
''';
