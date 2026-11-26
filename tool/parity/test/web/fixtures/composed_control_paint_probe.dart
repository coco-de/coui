// The seven public callers whose VM composition checks accompany this fixture.
// Official docs foundations and the same tree run under SSR and O2.
import 'package:coui_web/coui_web.dart';
import 'package:docs_core/site_head.dart';

void _handleChangedBool(bool _) {}
void _handleChangedChoice(String? _) {}
void _handleTapped() {}

const _kOptions = <CoreMultipleChoiceOption<String>>[
  (value: 'a', label: 'Apple'),
  (value: 'b', label: 'Banana'),
];

Component _scene(String id, Component child) => div(
  [
    button(
      [Text('Keyboard start $id')],
      attributes: {'data-keyboard-start': id},
    ),
    div([child], attributes: {'data-component-case': id}),
  ],
  attributes: {'data-case': id},
  styles: const Styles(
    raw: {
      'padding': '32px',
      'width': '640px',
      'margin-bottom': '24px',
    },
  ),
);

Component _carousel(CoreCarouselVariant variant, {CoreCarouselStyle? style}) =>
    Carousel(
      items: [
        for (var i = 0; i < 3; i++)
          div([
            Text('Slide $i'),
          ], styles: const Styles(raw: {'height': '120px'})),
      ],
      variant: variant,
      wrap: false,
      autoPlay: false,
      draggable: false,
      showNavigation: false,
      carouselStyle: style,
    );

Component composedControlPaintProbe() => Component.fragment([
  Style(styles: docsContentTheme().styles),
  CoUIWeb(
    theme: ThemeData.coui,
    child: div([
      _scene(
        'switch-off',
        SwitchField(label: 'Alerts', onChanged: _handleChangedBool),
      ),
      _scene(
        'switch-on',
        SwitchField(
          label: 'Alerts',
          value: true,
          onChanged: _handleChangedBool,
        ),
      ),
      _scene(
        'multiple-flat',
        const MultipleChoice<String>(
          options: _kOptions,
          value: 'a',
          onChanged: _handleChangedChoice,
          multipleChoiceStyle: CoreMultipleChoiceStyle(
            // Deliberately exercise the deprecated public compatibility slot.
            // ignore: deprecated_member_use
            selectedBackgroundColor: CoreColor(0xFFAA0000),
            // Deliberately exercise the deprecated public compatibility slot.
            // ignore: deprecated_member_use
            unselectedBackgroundColor: CoreColor(0xFF00AA00),
          ),
        ),
      ),
      _scene(
        'chip-ramp',
        Chip(
          label: 'Chip ramp',
          onTap: _handleTapped,
        ),
      ),
      _scene('carousel-slide', _carousel(CoreCarouselVariant.slide)),
      _scene('carousel-banner', _carousel(CoreCarouselVariant.banner)),
      _scene(
        'carousel-caller',
        _carousel(
          CoreCarouselVariant.slide,
          style: const CoreCarouselStyle(
            overlayIndicatorFocusOutlineStyle: CoreFocusOutlineStyle(
              offsetColor: CoreColor.transparent,
            ),
          ),
        ),
      ),
    ]),
  ),
]);
