/// Code snippet for [Mask] Web examples.
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
class MaskDefaultExample extends StatelessComponent {
  const MaskDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Mask(
      child: div(
        [],
        classes: 'w-\${CoreSpace.scale.space64} h-\${CoreSpace.scale.space64} '
            'bg-\${cs.primary}',
      ),
    );
  }
}
''';

const _circleCode = '''
class MaskCircleExample extends StatelessComponent {
  const MaskCircleExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Mask(
      shape: .circle,
      child: div(
        [],
        classes: 'w-\${CoreSpace.scale.space64} h-\${CoreSpace.scale.space64} '
            'bg-\${cs.primary}',
      ),
    );
  }
}
''';

const _heartCode = '''
class MaskHeartExample extends StatelessComponent {
  const MaskHeartExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Mask(
      shape: .heart,
      child: div(
        [],
        classes: 'w-\${CoreSpace.scale.space64} h-\${CoreSpace.scale.space64} '
            'bg-\${cs.primary}',
      ),
    );
  }
}
''';

const _hexagonCode = '''
class MaskHexagonExample extends StatelessComponent {
  const MaskHexagonExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Mask(
      shape: .hexagon,
      child: div(
        [],
        classes: 'w-\${CoreSpace.scale.space64} h-\${CoreSpace.scale.space64} '
            'bg-\${cs.primary}',
      ),
    );
  }
}
''';

const _starCode = '''
class MaskStarExample extends StatelessComponent {
  const MaskStarExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Mask(
      shape: .star,
      child: div(
        [],
        classes: 'w-\${CoreSpace.scale.space64} h-\${CoreSpace.scale.space64} '
            'bg-\${cs.primary}',
      ),
    );
  }
}
''';

const _triangleCode = '''
class MaskTriangleExample extends StatelessComponent {
  const MaskTriangleExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Mask(
      shape: .triangle,
      child: div(
        [],
        classes: 'w-\${CoreSpace.scale.space64} h-\${CoreSpace.scale.space64} '
            'bg-\${cs.primary}',
      ),
    );
  }
}
''';
