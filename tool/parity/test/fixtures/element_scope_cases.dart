import 'package:coui_web/coui_web.dart';

/// Public components used by the scoped-CSS browser contracts.
Component elementScopeCases() => const _Cases();

/// The four additional primitive consumers qualified for integration.
Component elementScopePrimitiveCases() => const _Cases(primitives: true);

/// A server-only owner beside a hydrated island.
Component elementScopeStaticOwner() => const _PartialOwner(staticOwner: true);

/// An independent raw-colour reference with a caller-provided unique id.
Component elementScopeStaticReference() =>
    const _PartialOwner(staticOwner: true, reference: true);

/// The independently hydrated owner.
Component elementScopeClientOwner() => const _PartialOwner(staticOwner: false);

const _kCallerCss = Styles(raw: {'cursor': 'crosshair'});
const _kCallerAttributes = {'data-caller': 'kept'};
const _kSharedBadge = Badge(
  onPressed: _handlePressed,
  child: Text('Badge'),
  classes: 'caller-root',
  css: _kCallerCss,
  attributes: _kCallerAttributes,
);
const _kSharedProgress = Progress(
  label: _Caller(),
  caption: Text('Caption'),
  classes: 'caller-root',
  css: _kCallerCss,
  attributes: _kCallerAttributes,
);

final _sharedButton = Button(
  onPressed: _handlePressed,
  child: const Text('Button'),
  classes: 'caller-root',
  css: _kCallerCss,
  attributes: _kCallerAttributes,
);
const _kSharedPagination = Pagination(
  page: 1,
  totalPages: 3,
  onPageChanged: _handlePageChanged,
  classes: 'caller-root',
  css: _kCallerCss,
  attributes: _kCallerAttributes,
);
const _kSharedDisclosure = Disclosure(
  title: 'Disclosure',
  content: Text('Content'),
  classes: 'caller-root',
  css: _kCallerCss,
  attributes: _kCallerAttributes,
);
const _kSharedChipInput = ChipInput(
  onSubmitted: _handleSubmitted,
  classes: 'caller-root',
  css: _kCallerCss,
  attributes: _kCallerAttributes,
);
void _handlePageChanged(int _) => _presses.value++;
void _handleSubmitted(String _) => _presses.value++;
CoreColor _color(bool blue) => CoreColor(blue ? 0xff1428b4 : 0xffb41428);
CoreButtonStyle _buttonStyle(bool blue) => CoreButtonStyle(
  hoverBackgroundColor: _color(blue),
  hoverForegroundColor: CoreColor(blue ? 0xff000000 : 0xffffffff),
);
CorePaginationStyle _paginationStyle(bool blue) => CorePaginationStyle(
  hoverBackgroundColor: _color(blue),
  hoverTextStyle: CoreTextStyle(
    color: CoreColor(blue ? 0xff000000 : 0xffffffff),
  ),
);
CoreDisclosureStyle _disclosureStyle(bool blue) => CoreDisclosureStyle(
  clickableStyle: CoreClickableStyle(
    focusOutlineStyle: CoreFocusOutlineStyle(
      borderColor: _color(blue),
      borderWidth: 3,
      align: 6,
    ),
  ),
);
CoreChipInputStyle _chipInputStyle(bool blue) =>
    CoreChipInputStyle(hoverBorderColor: _color(blue));

final _presses = ValueNotifier<int>(0);
void _handlePressed() => _presses.value++;

CoreBadgeStyle _badgeStyle(bool blue) => CoreBadgeStyle(
  backgroundColor: CoreColor(blue ? 0xff1428b4 : 0xffb41428),
  foregroundColor: CoreColor(blue ? 0xff000000 : 0xffffffff),
);
CoreProgressStyle _progressStyle(bool blue) => CoreProgressStyle(
  indeterminateFillRatio: blue ? 0.7 : 0.2,
  indeterminateDuration: Duration(milliseconds: blue ? 1700 : 700),
);

class _Cases extends StatefulComponent {
  const _Cases({this.primitives = false});
  final bool primitives;
  @override
  State<_Cases> createState() => _CasesState();
}

class _CasesState extends State<_Cases> {
  bool reverse = false;
  bool show = true;
  bool dark = false;
  bool swapped = false;
  bool ready = false;

  @override
  void initState() {
    super.initState();
    _presses.addListener(_handleCounter);
  }

  void _handleCounter() => setState(() {});

  @override
  void dispose() {
    _presses.removeListener(_handleCounter);
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    if (kIsWeb && !ready) {
      ready = true;
      context.binding.addPostFrameCallback(() {
        CoUIThemeController.setTheme('light');
      });
    }
    final owners = [
      for (final type
          in component.primitives
              ? ['button', 'pagination', 'disclosure', 'chipinput']
              : ['badge', 'progress'])
        for (final mode in [
          'unique',
          'local-key',
          'unkeyed',
          'const',
          'public-id',
        ])
          for (final blue in [false, true])
            if (show || mode != 'const' || !blue) _owner(type, mode, blue),
    ];
    return CoUIWeb(
      theme: ThemeData.coui,
      darkTheme: ThemeData.dark,
      themeMode: dark ? CoreThemeMode.dark : CoreThemeMode.light,
      child: div([
        div(
          const [Text('Palette')],
          id: 'scope-palette',
          styles: Styles(
            raw: {
              'color': const CoreColor.token(CoreColors.onSurface).toValue(),
              'background-color': const CoreColor.token(
                CoreColors.surface,
              ).toValue(),
            },
          ),
        ),
        div(
          const [],
          id: 'scope-ready',
          attributes: {
            'data-ready': '$kIsWeb',
            'data-presses': '${_presses.value}',
          },
        ),
        button(
          const [Text('rebuild')],
          id: 'scope-rebuild',
          onClick: () {
            setState(() => swapped = !swapped);
          },
        ),
        button(
          const [Text('reorder')],
          id: 'scope-reorder',
          onClick: () {
            setState(() => reverse = !reverse);
          },
        ),
        button(
          const [Text('presence')],
          id: 'scope-presence',
          onClick: () {
            setState(() => show = !show);
          },
        ),
        button(
          const [Text('theme')],
          id: 'scope-theme',
          onClick: () {
            setState(() => dark = !dark);
            context.binding.addPostFrameCallback(() {
              CoUIThemeController.setTheme(dark ? 'dark' : 'light');
            });
          },
        ),
        ...(reverse ? owners.reversed : owners),
      ]),
    );
  }

  Component _owner(String type, String mode, bool blue) {
    final side = blue ? 'b' : 'a';
    final name = '$type-$mode-$side';
    final paintBlue = blue != swapped;
    final key = switch (mode) {
      'unique' => ValueKey(name),
      'local-key' || 'public-id' => const ValueKey('same'),
      _ => null,
    };
    final id = mode == 'public-id' ? 'caller-$type-$side' : null;
    final Component child;
    if (mode == 'const') {
      child = switch (type) {
        'badge' => _kSharedBadge,
        'progress' => _kSharedProgress,
        'button' => _sharedButton,
        'pagination' => _kSharedPagination,
        'disclosure' => _kSharedDisclosure,
        'chipinput' => _kSharedChipInput,
        _ => throw StateError(type),
      };
    } else {
      child = switch (type) {
        'badge' => Badge(
          key: key,
          id: id,
          onPressed: _handlePressed,
          child: const Text('Badge'),
          badgeStyle: _badgeStyle(paintBlue),
          classes: 'caller-root',
          css: _kCallerCss,
          attributes: _kCallerAttributes,
        ),
        'progress' => Progress(
          key: key,
          id: id,
          label: const _Caller(),
          caption: const Text('Caption'),
          progressStyle: _progressStyle(paintBlue),
          classes: 'caller-root',
          css: _kCallerCss,
          attributes: _kCallerAttributes,
        ),
        'button' => Button(
          key: key,
          id: id,
          onPressed: _handlePressed,
          child: const Text('Button'),
          buttonStyle: _buttonStyle(paintBlue),
          classes: 'caller-root',
          css: _kCallerCss,
          attributes: _kCallerAttributes,
        ),
        'pagination' => Pagination(
          key: key,
          id: id,
          page: 1,
          totalPages: 3,
          onPageChanged: _handlePageChanged,
          paginationStyle: _paginationStyle(paintBlue),
          classes: 'caller-root',
          css: _kCallerCss,
          attributes: _kCallerAttributes,
        ),
        'disclosure' => Disclosure(
          key: key,
          id: id,
          title: 'Disclosure',
          content: const Text('Content'),
          disclosureStyle: _disclosureStyle(paintBlue),
          classes: 'caller-root',
          css: _kCallerCss,
          attributes: _kCallerAttributes,
        ),
        'chipinput' => ChipInput(
          key: key,
          id: id,
          onSubmitted: _handleSubmitted,
          chipInputStyle: _chipInputStyle(paintBlue),
          classes: 'caller-root',
          css: _kCallerCss,
          attributes: _kCallerAttributes,
        ),
        _ => throw StateError(type),
      };
    }
    return div(
      key: ValueKey(name),
      id: 'case-$name',
      attributes: {'data-case': name},
      styles: const Styles(raw: {'width': '240px', 'margin': '12px'}),
      [
        _Owner(
          name: name,
          child: Theme(
            data: (blue ? ThemeData.dark : ThemeData.coui).copyWith(
              coreComponentTheme: CoreComponentTheme(
                badge: CoreBadgeTheme(style: _badgeStyle(paintBlue)),
                button: CoreButtonTheme(style: _buttonStyle(paintBlue)),
                pagination: CorePaginationTheme(
                  style: _paginationStyle(paintBlue),
                ),
                disclosure: CoreDisclosureTheme(
                  style: _disclosureStyle(paintBlue),
                ),
                chipInput: CoreChipInputTheme(
                  style: _chipInputStyle(paintBlue),
                ),
                progress: CoreProgressTheme(style: _progressStyle(paintBlue)),
              ),
            ),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _Owner extends InheritedComponent {
  const _Owner({required this.name, required super.child});
  final String name;
  @override
  bool updateShouldNotify(covariant _Owner oldComponent) =>
      name != oldComponent.name;
}

class _Caller extends StatefulComponent {
  const _Caller();
  @override
  State<_Caller> createState() => _CallerState();
}

class _CallerState extends State<_Caller> {
  int count = 1;
  @override
  Component build(BuildContext context) {
    final name = context.dependOnInheritedComponentOfExactType<_Owner>()!.name;
    return div(
      id: 'payload-$name',
      attributes: {'data-count': '$count'},
      [
        button(
          [Text('$count')],
          id: 'count-$name',
          onClick: () {
            setState(() => count++);
          },
        ),
        Component.element(
          tag: 'input',
          attributes: {
            'id': 'input-$name',
            'aria-label': 'Caller $name',
          },
        ),
      ],
    );
  }
}

class _PartialOwner extends StatefulComponent {
  const _PartialOwner({required this.staticOwner, this.reference = false});
  final bool staticOwner;
  final bool reference;
  @override
  State<_PartialOwner> createState() => _PartialOwnerState();
}

class _PartialOwnerState extends State<_PartialOwner> {
  @override
  Component build(BuildContext context) {
    return CoUIWeb(
      theme: ThemeData.coui,
      child: div(
        id: component.reference
            ? 'static-reference-host'
            : component.staticOwner
            ? 'static-a'
            : 'client-b',
        [
          Badge(
            onPressed: _handlePressed,
            child: const Text('Partial owner'),
            id: component.reference ? 'static-reference' : null,
            badgeStyle: _badgeStyle(!component.staticOwner),
          ),
          if (!component.staticOwner)
            const div(
              [],
              id: 'partial-ready',
              attributes: {'data-ready': '$kIsWeb'},
            ),
        ],
      ),
    );
  }
}
