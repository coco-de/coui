/// Code snippet for Diff — variant-aware entry point.
String diffCode(String? variant) => switch (variant) {
  'chain' => diffChainCode(),
  'text' => diffTextCode(),
  _ => diffDefaultCode(),
};

String diffChainCode() {
  return r'''
class DiffChainExample extends StatelessComponent {
  const DiffChainExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Diff(
          ariaLabel: '보정 전과 보정 후 풍경 비교',
          beforeLabel: Text('전'),
          afterLabel: Text('후'),
          before: _Landscape(vivid: false),
          after: _Landscape(vivid: true),
        )
        .withStyle(
          const CoreDiffStyle(
            resizerColor: CoreColor.token(CoreColors.tertiary),
            resizerWidth: CoreStrokeWidth.stroke4,
            aspectRatio: 4 / 3,
          ),
        )
        .radius16;
  }
}

/// A sky, a sun and two hills drawn from colour tokens. Every size and
/// position is a fraction of the frame, so the scene scales with it.
class _Landscape extends StatelessComponent {
  const _Landscape({required this.vivid});

  /// Muted greys when false, the status colours when true.
  final bool vivid;

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    final sky = vivid ? cs.infoContainer : cs.surfaceContainer;
    final sun = vivid ? cs.warning : cs.outlineVariant;
    final farHill = vivid ? cs.info : cs.outlineVariant;
    final nearHill = vivid ? cs.success : cs.outline;

    return div(
      [
        _disc(sun, left: '42%', top: '12%', size: '16%'),
        _disc(farHill, left: '-42%', top: '55%', size: '160%'),
        _disc(nearHill, left: '15%', top: '72%', size: '130%'),
      ],
      classes: 'relative w-full h-full overflow-hidden bg-$sky',
    );
  }

  Component _disc(
    CoreColor? color, {
    required String left,
    required String top,
    required String size,
  }) {
    return div(
      const [],
      classes: 'absolute rounded-${CoreRadius.scale.radius9999} bg-$color',
      styles: Styles(
        raw: {'left': left, 'top': top, 'width': size, 'aspect-ratio': '1'},
      ),
    );
  }
}
''';
}

String diffDefaultCode() {
  return r'''
class DiffDefaultExample extends StatelessComponent {
  const DiffDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    return const Diff(
      ariaLabel: '보정 전과 보정 후 풍경 비교',
      beforeLabel: Text('전'),
      afterLabel: Text('후'),
      before: _Landscape(vivid: false),
      after: _Landscape(vivid: true),
    );
  }
}

/// A sky, a sun and two hills drawn from colour tokens. Every size and
/// position is a fraction of the frame, so the scene scales with it.
class _Landscape extends StatelessComponent {
  const _Landscape({required this.vivid});

  /// Muted greys when false, the status colours when true.
  final bool vivid;

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    final sky = vivid ? cs.infoContainer : cs.surfaceContainer;
    final sun = vivid ? cs.warning : cs.outlineVariant;
    final farHill = vivid ? cs.info : cs.outlineVariant;
    final nearHill = vivid ? cs.success : cs.outline;

    return div(
      [
        _disc(sun, left: '42%', top: '12%', size: '16%'),
        _disc(farHill, left: '-42%', top: '55%', size: '160%'),
        _disc(nearHill, left: '15%', top: '72%', size: '130%'),
      ],
      classes: 'relative w-full h-full overflow-hidden bg-$sky',
    );
  }

  Component _disc(
    CoreColor? color, {
    required String left,
    required String top,
    required String size,
  }) {
    return div(
      const [],
      classes: 'absolute rounded-${CoreRadius.scale.radius9999} bg-$color',
      styles: Styles(
        raw: {'left': left, 'top': top, 'width': size, 'aspect-ratio': '1'},
      ),
    );
  }
}
''';
}

String diffTextCode() {
  return r'''
class DiffTextExample extends StatelessComponent {
  const DiffTextExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    return Diff(
      ariaLabel: '채운 배경과 표면 배경 글자 비교',
      before: Component.element(
        tag: 'div',
        classes: 'w-full h-full grid place-content-center bg-${cs.primary}',
        children: [Text('CoUI').displayLarge.onPrimary],
      ),
      after: Component.element(
        tag: 'div',
        classes:
            'w-full h-full grid place-content-center '
            'bg-${cs.surfaceContainer}',
        children: [Text('CoUI').displayLarge.onSurface],
      ),
    );
  }
}
''';
}
