import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart';

void _handleToggleChanged(bool value) {}
void _handleChipTapped() {}

const _kRamp = CoreStateLayer(hover: .25, focus: .25, pressed: .5);
const _kRawInk = CoreColor(0x8012a43c);
const _kTokenInk = CoreColor.token(CoreColors.error);
const _kRawBase = CoreColor(0xff334455);
const _kAlphaBase = CoreColor(0x80334455);
const _kTokenBase = CoreColor.token(CoreColors.primaryContainer);

Component _row(String id, Component child) => div(
  [child],
  attributes: {'data-paint-case': id},
  styles: const Styles(
    raw: {'padding': '20px', 'width': '600px', 'background-color': '#eeeeee'},
  ),
);

/// Original inline-base failures: 13 faces per theme, two state events each.
Component selectedBasePaintProbe() => Component.fragment([
  Style(styles: docsContentTheme().styles),
  const Component.element(
    tag: 'style',
    children: [
      RawText('.caller-important{background-color:#eeaa22 !important;}'),
    ],
  ),
  CoUIWeb(
    theme: ThemeData.coui,
    child: div([
      // Passive/disabled raw faces come first: no earlier interactive instance
      // may provide the CSS that makes their rest paint work.
      _row(
        'passive-first',
        Chip(
          label: 'Passive',
          chipStyle: const CoreChipStyle(backgroundColor: _kRawBase),
        ),
      ),
      _row(
        'disabled-first',
        Chip(
          label: 'Disabled',
          enabled: false,
          onTap: _handleChipTapped,
          chipStyle: const CoreChipStyle(backgroundColor: _kAlphaBase),
        ),
      ),
      for (final entry in {
        'token': _kTokenBase,
        'raw': _kRawBase,
        'alpha': _kAlphaBase,
      }.entries)
        for (final selected in [true, false])
          _row(
            'toggle-${entry.key}-$selected',
            Toggle(
              value: selected,
              onChanged: _handleToggleChanged,
              toggleStyle: CoreToggleStyle(
                trackActiveColor: entry.value,
                trackInactiveColor: entry.value,
                stateLayerActiveColor: entry.key == 'raw'
                    ? _kRawInk
                    : _kTokenInk,
                stateLayerInactiveColor: entry.key == 'raw'
                    ? _kRawInk
                    : _kTokenInk,
                stateLayer: _kRamp,
              ),
            ),
          ),
      for (final entry in {'raw': _kRawBase, 'alpha': _kAlphaBase}.entries)
        for (final selected in [true, false])
          _row(
            'chip-${entry.key}-$selected',
            Chip(
              label: 'Chosen',
              chipColor: CoreChipColor.primary,
              selected: selected,
              onTap: _handleChipTapped,
              chipStyle: CoreChipStyle(
                backgroundColor: entry.value,
                foregroundColor: entry.key == 'raw' ? _kRawInk : _kTokenInk,
                stateLayer: _kRamp,
              ),
            ),
          ),
      for (final kind in ['default', 'token', 'raw'])
        _row(
          'chip-transparent-$kind',
          Chip(
            label: 'Unselected',
            chipColor: CoreChipColor.primary,
            onTap: _handleChipTapped,
            chipStyle: kind == 'default'
                ? null
                : CoreChipStyle(
                    foregroundColor: kind == 'raw' ? _kRawInk : _kTokenInk,
                    stateLayer: _kRamp,
                  ),
          ),
        ),
      for (final entry in {'raw': _kRawBase, 'token': _kTokenBase}.entries)
        _row(
          'null-callback-${entry.key}',
          Toggle(
            value: true,
            enabled: true,
            toggleStyle: CoreToggleStyle(
              trackActiveColor: entry.value,
              stateLayerActiveColor: entry.key == 'raw' ? _kRawInk : _kTokenInk,
              stateLayer: _kRamp,
            ),
          ),
        ),
      for (final reversed in [false, true])
        for (final explicit in reversed ? [true, false] : [false, true])
          _row(
            'mode-$reversed-$explicit',
            Toggle(
              value: true,
              onChanged: _handleToggleChanged,
              toggleStyle: explicit
                  ? CoreToggleStyle(
                      trackActiveColor: CoreToggleStyle
                          .defaultsByVariant[CoreToggleVariant.defaultVariant]!
                          .activeTrack,
                    )
                  : null,
            ),
          ),
      for (final slot in ['prefix', 'suffix'])
        _row(
          'owner-$slot',
          Toggle(
            id: 'owner-outer-$slot',
            value: true,
            onChanged: _handleToggleChanged,
            toggleStyle: const CoreToggleStyle(trackActiveColor: _kAlphaBase),
            prefix: slot == 'prefix'
                ? Toggle(
                    id: 'owner-inner-$slot',
                    value: true,
                    onChanged: _handleToggleChanged,
                    toggleStyle: const CoreToggleStyle(
                      trackActiveColor: _kRawBase,
                    ),
                  )
                : null,
            suffix: slot == 'suffix'
                ? Toggle(
                    id: 'owner-inner-$slot',
                    value: true,
                    onChanged: _handleToggleChanged,
                    toggleStyle: const CoreToggleStyle(
                      trackActiveColor: _kRawBase,
                    ),
                  )
                : null,
          ),
        ),
      for (final kind in ['color', 'gradient', 'important'])
        _row(
          'caller-$kind',
          Chip(
            label: 'Caller',
            onTap: _handleChipTapped,
            selected: true,
            classes: kind == 'important' ? 'caller-important' : null,
            css: kind == 'color'
                ? const Styles(raw: {'background-color': '#eeaa22'})
                : kind == 'gradient'
                ? const Styles(
                    raw: {
                      'background-image': 'linear-gradient(#eeaa22,#eeaa22)',
                    },
                  )
                : null,
            chipStyle: const CoreChipStyle(
              backgroundColor: _kRawBase,
              foregroundColor: _kRawInk,
              stateLayer: _kRamp,
            ),
          ),
        ),
    ]),
  ),
]);
