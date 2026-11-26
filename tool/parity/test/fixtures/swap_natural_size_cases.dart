import 'package:coui_web/coui_web.dart';

Component swapNaturalSizeCases() =>
    CoUIWeb(theme: ThemeData.coui, child: const _Cases());
Component swapDirectResolverCases() =>
    CoUIWeb(theme: ThemeData.coui, child: const _DirectCases());
int _serial = 0;

class _DirectCases extends StatelessComponent {
  const _DirectCases();
  @override
  Component build(BuildContext context) {
    final resolved = resolveSwap(
      context,
      checked: false,
      animation: CoreSwapAnimation.none,
    );
    return div([
      for (final vertical in [false, true])
        div(
          id: 'case-${vertical ? 'vertical' : 'horizontal'}-direct',
          attributes: const {
            'data-checked': 'false',
            'data-context': 'tight',
            'data-animation': 'none',
            'data-callbacks': '0',
            'data-values': '[]',
          },
          [
            div(
              styles: const Styles(
                raw: {
                  'display': 'flex',
                  'align-items': 'flex-start',
                  'width': '24px',
                  'height': '24px',
                },
              ),
              [
                div(
                  id: 'swap-${vertical ? 'vertical' : 'horizontal'}-direct',
                  classes: resolved.root.className,
                  styles: resolved.root.inlineStyles,
                  [
                    div(
                      classes: resolved.offSlot.className,
                      styles: resolved.offSlot.inlineStyles,
                      [_Face('off', vertical ? 24 : 16, vertical ? 16 : 24)],
                    ),
                    div(
                      classes: resolved.onSlot.className,
                      styles: resolved.onSlot.inlineStyles,
                      [_Face('on', vertical ? 24 : 80, vertical ? 80 : 24)],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
    ]);
  }
}

class _Face extends StatefulComponent {
  const _Face(
    this.name,
    this.width,
    this.height, {
    this.relaxMax = false,
    this.useFrame = false,
    super.key,
  });
  final String name;
  final double width;
  final double height;
  final bool relaxMax;
  final bool useFrame;
  @override
  State<_Face> createState() => _FaceState();
}

class _FaceState extends State<_Face> {
  final int serial = ++_serial;
  @override
  Component build(BuildContext context) {
    if (component.useFrame) {
      return Frame(
        width: component.width,
        height: component.height,
        attributes: {'data-face': component.name, 'data-mount': '$serial'},
        backgroundColor: CoreColor(
          component.name == 'on' ? 0xff209060 : 0xff3050a0,
        ),
      );
    }
    return div(
      attributes: {'data-face': component.name, 'data-mount': '$serial'},
      styles: Styles(
        raw: {
          'width': '${component.width}px',
          'height': '${component.height}px',
          'background-color': component.name == 'on'
              ? 'rgb(32,144,96)'
              : 'rgb(48,80,160)',
          if (component.relaxMax) ...{
            'max-width': 'none',
            'max-height': 'none',
          },
        },
      ),
      const [],
    );
  }
}

class _Cases extends StatefulComponent {
  const _Cases();
  @override
  State<_Cases> createState() => _CasesState();
}

class _CasesState extends State<_Cases> {
  final checked = <String, bool>{};
  final callbacks = <String, List<bool>>{};
  final animations = <String, CoreSwapAnimation>{};
  int builds = 0;
  void set(String name, bool value) => setState(() => checked[name] = value);
  Component entry(
    String shape,
    CoreSwapAnimation animation, {
    bool interactive = false,
    String context = 'loose',
  }) {
    final name =
        '$shape-${animation.name}${interactive ? '-interactive' : ''}'
        '${context == 'loose' ? '' : '-$context'}';
    final vertical = shape == 'vertical';
    final same = shape == 'same-size';
    final offW = vertical || same ? 24.0 : 16.0;
    final offH = vertical ? 16.0 : 24.0;
    final onW = vertical || same ? 24.0 : 80.0;
    final onH = vertical ? 80.0 : 24.0;
    final value = checked[name] ?? false;
    final effectiveAnimation = animations[name] ?? animation;
    return div(
      id: 'case-$name',
      attributes: {
        'data-swap-case': name,
        'data-checked': '$value',
        'data-callbacks': '${callbacks[name]?.length ?? 0}',
        'data-values': '${callbacks[name] ?? <bool>[]}',
        'data-context': context,
        'data-animation': effectiveAnimation.name,
      },
      styles: const Styles(
        raw: {
          'display': 'inline-block',
          'vertical-align': 'top',
          'margin': '16px',
        },
      ),
      [
        div(styles: const Styles(raw: {'margin-bottom': '8px'}), [
          button(id: 'true-$name', onClick: () => set(name, true), [
            Text('true $name'),
          ]),
          button(id: 'false-$name', onClick: () => set(name, false), [
            Text('false $name'),
          ]),
          if (context == 'mode')
            for (final mode in CoreSwapAnimation.values)
              button(
                id: 'mode-${mode.name}-$name',
                onClick: () => setState(() => animations[name] = mode),
                [Text(mode.name)],
              ),
        ]),
        div(
          id: 'stage-$name',
          styles: Styles(
            raw: {
              'width':
                  context == 'tight' ||
                      context == 'child-max' ||
                      context == 'frame-tight'
                  ? '24px'
                  : '240px',
              'height':
                  context == 'tight' ||
                      context == 'child-max' ||
                      context == 'frame-tight'
                  ? '24px'
                  : '160px',
              'display': context == 'inline' ? 'block' : 'flex',
              'font-size': '14px',
              'line-height': '21px',
              'align-items': 'flex-start',
              'justify-content': 'flex-start',
            },
          ),
          [
            // Raw text deliberately supplies the surrounding HTML baseline.
            if (context == 'inline') const RawText('A'),
            Swap(
              id: 'swap-$name',
              key: ValueKey('swap-$name'),
              css: switch (context) {
                'caller-flex' => const Styles(raw: {'display': 'inline-flex'}),
                'caller-max' => const Styles(
                  raw: {'max-width': '12px', 'max-height': '12px'},
                ),
                'caller-important' => const Styles(
                  raw: {'max-width': '12px', 'max-height': '12px'},
                ),
                'caller-transform' => const Styles(
                  raw: {'transform': 'translateX(7px)'},
                ),
                'caller-padding' => const Styles(raw: {'padding': '8px'}),
                _ => null,
              },
              classes: context == 'caller-class'
                  ? 'swap-caller-limit'
                  : context == 'caller-important'
                  ? 'swap-caller-important'
                  : null,
              animation: effectiveAnimation,
              checked: value,
              offContent: _Face(
                'off',
                offW,
                offH,
                useFrame: context.startsWith('frame-'),
                key: ValueKey('off-$name'),
              ),
              onContent: _Face(
                'on',
                onW,
                onH,
                useFrame: context.startsWith('frame-'),
                relaxMax: context == 'child-max',
                key: ValueKey('on-$name'),
              ),
              onToggle: interactive
                  ? (v) {
                      callbacks.putIfAbsent(name, () => []).add(v);
                      set(name, v);
                    }
                  : null,
            ),
            if (context == 'inline') ...[
              const span(
                attributes: {'data-baseline': ''},
                styles: Styles(
                  raw: {'display': 'inline-block', 'width': '0', 'height': '0'},
                ),
                [],
              ),
              const RawText('Z'),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Component build(BuildContext context) {
    builds++;
    return div([
      const Component.element(
        tag: 'style',
        children: [
          RawText(
            '.swap-caller-limit{max-width:12px;max-height:12px}'
            '.swap-caller-important{max-width:14px!important;'
            'max-height:14px!important}',
          ),
        ],
      ),
      div(id: 'swap-ready', attributes: {'data-builds': '$builds'}, const []),
      for (final shape in ['horizontal', 'vertical', 'same-size'])
        for (final animation in CoreSwapAnimation.values)
          entry(shape, animation),
      for (final shape in ['horizontal', 'vertical'])
        entry(shape, CoreSwapAnimation.none, interactive: true),
      for (final shape in ['horizontal', 'vertical'])
        for (final animation in CoreSwapAnimation.values)
          entry(shape, animation, context: 'tight'),
      for (final animation in CoreSwapAnimation.values)
        entry('horizontal', animation, context: 'inline'),
      for (final shape in ['horizontal', 'vertical'])
        for (final animation in [
          CoreSwapAnimation.none,
          CoreSwapAnimation.rotate,
        ])
          entry(shape, animation, context: 'caller-flex'),
      for (final shape in ['horizontal', 'vertical'])
        for (final animation in [
          CoreSwapAnimation.none,
          CoreSwapAnimation.rotate,
        ])
          entry(shape, animation, context: 'tight', interactive: true),
      for (final shape in ['horizontal', 'vertical'])
        entry(shape, CoreSwapAnimation.none, context: 'mode'),
      for (final shape in ['horizontal', 'vertical'])
        entry(shape, CoreSwapAnimation.none, context: 'caller-max'),
      for (final shape in ['horizontal', 'vertical'])
        for (final context in ['caller-class', 'caller-important'])
          entry(shape, CoreSwapAnimation.none, context: context),
      entry('vertical', CoreSwapAnimation.none, context: 'child-max'),
      entry('horizontal', CoreSwapAnimation.flip, context: 'caller-transform'),
      entry('horizontal', CoreSwapAnimation.flip, context: 'caller-padding'),
      for (final shape in ['horizontal', 'vertical'])
        for (final animation in [
          CoreSwapAnimation.none,
          CoreSwapAnimation.rotate,
        ])
          for (final context in ['frame-loose', 'frame-tight'])
            entry(shape, animation, context: context),
    ]);
  }
}
