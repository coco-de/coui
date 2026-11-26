import 'package:coui_web/coui_web.dart';

/// Real runtime configurations mounted under independently themed parents.
Component dotIndicatorScopeCases({bool dark = false}) => CoUIWeb(
  theme: dark ? ThemeData.dark : ThemeData.coui,
  child: _DotScopeCases(dark: dark),
);

class _DotScopeCases extends StatefulComponent {
  const _DotScopeCases({required this.dark});
  final bool dark;

  @override
  State<_DotScopeCases> createState() => _DotScopeCasesState();
}

class _DotScopeCasesState extends State<_DotScopeCases> {
  bool reversed = false;
  bool showFirst = true;
  bool rtl = false;
  int builds = 0;
  int changes = 0;
  int lastIndex = -1;
  late final DotIndicator sharedRuntime = indicator(
    key: const ValueKey('shared-runtime'),
  );

  DotIndicator indicator({
    Key? key,
    CoreAxis direction = CoreAxis.horizontal,
    bool clickable = true,
    int length = 3,
    String? id,
    CoreDotIndicatorStyle? dotStyle,
  }) => DotIndicator(
    key: key,
    index: 0,
    id: id,
    direction: direction,
    dotIndicatorStyle: dotStyle,
    length: length,
    onChanged: !clickable
        ? null
        : (value) => setState(() {
            changes++;
            lastIndex = value;
          }),
    classes: 'caller-dot-root caller-shadow',
    css: const Styles(raw: {'cursor': 'crosshair'}),
    attributes: const {'data-caller': 'kept'},
  );

  CoreDotIndicatorStyle style(bool blue, {bool band = false}) =>
      CoreDotIndicatorStyle(
        hoverBorderColor: CoreColor(blue ? 0xff1428b4 : 0xffb41428),
        inactiveBorderWidth: 2,
        transitionDuration: Duration.zero,
        spacing: blue ? 12 : 6,
        activeLength: blue ? 24 : 18,
        focusOutlineStyle: CoreFocusOutlineStyle(
          borderColor: CoreColor(blue ? 0xff1428b4 : 0xffb41428),
          borderWidth: blue ? 3.5 : 2.5,
          align: blue ? 8.25 : 6.25,
          ringOpacity: blue ? 0.5 : 0.625,
          offsetColor: band
              ? CoreColor(blue ? 0xff556677 : 0xff778899)
              : CoreColor.transparent,
        ),
      );

  Component owner(
    String name,
    Component child, {
    required bool blue,
    bool band = false,
  }) => Theme(
    key: ValueKey('owner-$name'),
    data: (component.dark ? ThemeData.dark : ThemeData.coui).copyWith(
      coreComponentTheme: CoreComponentTheme(
        dotIndicator: CoreDotIndicatorTheme(style: style(blue, band: band)),
      ),
    ),
    child: div(
      id: name,
      attributes: {'data-case': name},
      styles: const Styles(raw: {'padding': '24px', 'width': '260px'}),
      [child],
    ),
  );

  @override
  Component build(BuildContext context) {
    builds++;
    final cases = <Component>[
      owner(
        'unique-a',
        indicator(key: const ValueKey('unique-a')),
        blue: false,
      ),
      owner('unique-b', indicator(key: const ValueKey('unique-b')), blue: true),
      if (showFirst) owner('shared-a', sharedRuntime, blue: false),
      owner('shared-b', sharedRuntime, blue: true),
      owner(
        'equal-a',
        indicator(key: const ValueKey('equal-local')),
        blue: false,
      ),
      owner(
        'equal-b',
        indicator(key: const ValueKey('equal-local')),
        blue: true,
      ),
      owner(
        'band-a',
        indicator(key: const ValueKey('band-local')),
        blue: false,
        band: true,
      ),
      owner(
        'band-b',
        indicator(key: const ValueKey('band-local')),
        blue: true,
        band: true,
      ),
      owner(
        'vertical-a',
        indicator(
          key: const ValueKey('vertical-local'),
          direction: CoreAxis.vertical,
        ),
        blue: false,
      ),
      owner(
        'vertical-b',
        indicator(
          key: const ValueKey('vertical-local'),
          direction: CoreAxis.vertical,
        ),
        blue: true,
      ),
      owner(
        'caller-special',
        indicator(id: 'dot:user.a', key: const ValueKey('caller')),
        blue: false,
      ),
      owner('passive', indicator(clickable: false), blue: false),
      owner('empty', indicator(length: 0), blue: false),
      owner(
        'token',
        indicator(
          dotStyle: const CoreDotIndicatorStyle(
            hoverBorderColor: CoreColor.token(CoreColors.primary),
            focusOutlineStyle: CoreFocusOutlineStyle(
              borderColor: CoreFocusOutlineStyle.defaultBorderColor,
              borderWidth: CoreFocusOutlineStyle.defaultBorderWidth,
              align: CoreFocusOutlineStyle.defaultAlign,
              offsetColor: CoreFocusOutlineStyle.defaultOffsetColor,
              ringOpacity: CoreFocusOutlineStyle.defaultRingOpacity,
            ),
          ),
        ),
        blue: false,
      ),
      owner(
        'mixed-band-a',
        indicator(key: const ValueKey('mixed-band')),
        blue: false,
        band: true,
      ),
      owner(
        'mixed-band-b',
        indicator(key: const ValueKey('mixed-band')),
        blue: true,
      ),
      owner(
        'mixed-plain-a',
        indicator(key: const ValueKey('mixed-plain')),
        blue: false,
      ),
      owner(
        'mixed-plain-b',
        indicator(key: const ValueKey('mixed-plain')),
        blue: true,
        band: true,
      ),
    ];
    return div(
      attributes: {'dir': rtl ? 'rtl' : 'ltr'},
      [
        button(id: 'rebuild', onClick: () => setState(() {}), const [
          Text('rebuild'),
        ]),
        button(
          id: 'reorder',
          onClick: () => setState(() => reversed = !reversed),
          const [Text('reorder')],
        ),
        button(
          id: 'mount',
          onClick: () => setState(() => showFirst = !showFirst),
          const [Text('mount')],
        ),
        button(id: 'rtl', onClick: () => setState(() => rtl = !rtl), const [
          Text('rtl'),
        ]),
        span(
          id: 'scope-ready',
          attributes: {
            'data-ready': 'true',
            'data-builds': '$builds',
            'data-changes': '$changes',
            'data-last-index': '$lastIndex',
          },
          const [],
        ),
        ...reversed ? cases.reversed : cases,
      ],
    );
  }
}
