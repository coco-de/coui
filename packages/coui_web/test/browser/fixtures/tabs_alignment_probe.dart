import 'package:coui_web/coui_web.dart';

/// One tree for server layout and the optimized hydration regression.
Component tabsAlignmentProbe() => Theme.defaults(child: const _Probe());

class _Probe extends StatefulComponent {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  int _selected = 0;
  int _closed = 0;

  Component _case(
    String id, {
    CoreTabVariant variant = .underline,
    CoreTabsSize size = .md,
    CoreDensity density = .standard,
    double thickness = 2,
    bool closable = false,
    bool disabledSelected = false,
    bool rawColor = false,
  }) => div(
    [
      Tabs(
        variant: variant,
        size: size,
        selectedIndex: disabledSelected ? 2 : _selected,
        onChanged: (index) => setState(() => _selected = index),
        tabsStyle: CoreTabsStyle(
          activeIndicatorThickness: thickness,
          activeIndicatorColor: rawColor ? const CoreColor(0xFF123456) : null,
        ),
        tabs: [
          for (final label in ['Selected', 'Inactive', 'Disabled'])
            CoreTabItem<Component>(
              label: label,
              enabled: label != 'Disabled',
              onClose: closable ? () => setState(() => _closed++) : null,
            ),
        ],
      ),
    ],
    attributes: {
      'data-tabs-case': id,
      'data-variant': variant.name,
      kDensityAttribute: density.name,
    },
    styles: const Styles(raw: {'min-width': '0'}),
  );

  @override
  Component build(BuildContext context) => div(
    [
      div(
        const [],
        id: 'probe-state',
        attributes: {'data-selected': '$_selected', 'data-closed': '$_closed'},
        styles: const Styles(raw: {'display': 'none'}),
      ),
      for (final variant in CoreTabVariant.values)
        for (final size in CoreTabsSize.values)
          for (final density in CoreDensity.values)
            for (final thickness in [0.0, 2.0, 6.0])
              _case(
                '${variant.name}-${size.name}-${density.name}-'
                '${thickness.toInt()}',
                variant: variant,
                size: size,
                density: density,
                thickness: thickness,
              ),
      _case('closable', closable: true),
      _case('disabled-selected', disabledSelected: true),
      _case('raw-color', thickness: 6, rawColor: true),
    ],
    classes: 'preview-content not-content bg-surface text-on-surface',
    styles: const Styles(
      raw: {
        'display': 'grid',
        'grid-template-columns': 'repeat(3, minmax(0, 1fr))',
        'gap': '12px',
        'padding': '12px',
      },
    ),
  );
}
