import 'package:coui_web/coui_web.dart';

/// Runtime configurations in separate inherited-style owners.
Component joinScopeCases() => CoUIWeb(
  theme: ThemeData.coui,
  child: const _Cases(),
);

class _Cases extends StatefulComponent {
  const _Cases();

  @override
  State<_Cases> createState() => _CasesState();
}

class _CasesState extends State<_Cases> {
  bool reverse = false;
  bool show = true;
  int builds = 0;
  int presses = 0;
  int rootClicks = 0;
  late final Join shared = join();

  Join join({
    Key? key,
    int count = 3,
    bool vertical = false,
    String? id,
    List<Component>? children,
    CoreJoinStyle? style,
  }) => Join(
    key: key,
    id: id,
    vertical: vertical,
    joinStyle: style,
    classes: 'caller-join-root',
    css: const Styles(raw: {'cursor': 'crosshair'}),
    attributes: const {'data-join-case': 'kept'},
    eventHandlers: {
      'click': [(_) => setState(() => rootClicks++)],
    },
    children:
        children ??
        [
          for (var i = 0; i < count; i++)
            Button(
              variant: CoreButtonVariant.outline,
              css: const Styles(
                raw: {'min-width': '73px', 'min-height': '27px'},
              ),
              onPressed: () => setState(() => presses++),
              child: Text('Item $i'),
            ),
        ],
  );

  Component owner(String id, Component child, {bool large = false}) => Theme(
    key: ValueKey('owner-$id'),
    data: ThemeData.coui.copyWith(
      coreComponentTheme: CoreComponentTheme(
        join: CoreJoinTheme(
          style: CoreJoinStyle(
            borderRadius: CoreBorderRadius.all(
              large ? CoreRadius.radius16 : CoreRadius.radius4,
            ),
          ),
        ),
      ),
    ),
    child: div(
      id: id,
      attributes: {'data-owner': id},
      styles: const Styles(raw: {'padding': '24px', 'width': '420px'}),
      [child],
    ),
  );

  @override
  Component build(BuildContext context) {
    builds++;
    final cases = [
      owner('unique-a', join()),
      owner('unique-b', join(), large: true),
      if (show) owner('shared-a', shared),
      owner('shared-b', shared, large: true),
      owner('equal-reference-a', join(count: 1)),
      owner('equal-reference-b', join(vertical: true), large: true),
      owner('equal-a', join(key: const ValueKey('equal-join'), count: 1)),
      owner(
        'equal-b',
        join(key: const ValueKey('equal-join'), vertical: true),
        large: true,
      ),
      for (final vertical in [false, true])
        for (final count in [0, 1, 2, 3])
          owner(
            'count-${vertical ? 'v' : 'h'}-$count',
            join(
              count: count,
              vertical: vertical,
            ),
          ),
      owner('caller', join(id: 'caller-join')),
      owner('special', join(id: 'join:user.a')),
      owner(
        'nested',
        join(
          children: [
            Button(child: const Text('Outer')),
            join(
              id: 'nested-inner',
              vertical: true,
              count: 2,
              style: const CoreJoinStyle(
                borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
              ),
            ),
          ],
        ),
      ),
      for (final vertical in [false, true])
        owner(
          'minimum-${vertical ? 'v' : 'h'}',
          join(
            vertical: vertical,
            children: [
              for (var i = 0; i < 3; i++)
                button(classes: 'caller-minimum', [Text('Minimum $i')]),
            ],
          ),
        ),
      owner(
        'focus-probe',
        join(
          children: [
            for (var i = 0; i < 3; i++)
              Button(
                onPressed: () {},
                variant: CoreButtonVariant.outline,
                buttonStyle: const CoreButtonStyle(
                  focusOutlineStyle: CoreFocusOutlineStyle(
                    borderColor: CoreColor(0xffb41428),
                    borderWidth: 3,
                    align: 6,
                    ringOpacity: 1,
                    offsetColor: CoreColor.transparent,
                  ),
                ),
                child: Text('Focus $i'),
              ),
          ],
        ),
      ),
    ];
    return div([
      button(id: 'rebuild', onClick: () => setState(() {}), const [
        Text('rebuild'),
      ]),
      button(
        id: 'reorder',
        onClick: () => setState(() => reverse = !reverse),
        const [Text('reorder')],
      ),
      button(id: 'mount', onClick: () => setState(() => show = !show), const [
        Text('mount'),
      ]),
      span(
        id: 'join-ready',
        attributes: {
          'data-builds': '$builds',
          'data-presses': '$presses',
          'data-root-clicks': '$rootClicks',
        },
        const [],
      ),
      ...reverse ? cases.reversed : cases,
      const Component.element(
        tag: 'style',
        children: [
          RawText(
            '.caller-minimum{min-width:73px;min-height:27px;} '
            '#caller-join > div:first-of-type > *{ '
            'border-top-left-radius:${CoreRadius.radius20}px !important;}',
          ),
        ],
      ),
    ]);
  }
}
