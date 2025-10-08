// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:coui_widgetbook/component/alert/alert.dart'
    as _coui_widgetbook_component_alert_alert;
import 'package:coui_widgetbook/component/avatar/avatar.dart'
    as _coui_widgetbook_component_avatar_avatar;
import 'package:coui_widgetbook/component/button/button.dart'
    as _coui_widgetbook_component_button_button;
import 'package:coui_widgetbook/component/calendar/calendar.dart'
    as _coui_widgetbook_component_calendar_calendar;
import 'package:coui_widgetbook/component/card/card.dart'
    as _coui_widgetbook_component_card_card;
import 'package:coui_widgetbook/component/chip/chip.dart'
    as _coui_widgetbook_component_chip_chip;
import 'package:coui_widgetbook/component/circular_progress_indicator/circular_progress_indicator.dart'
    as _coui_widgetbook_component_circular_progress_indicator_circular_progress_indicator;
import 'package:coui_widgetbook/component/divider/divider.dart'
    as _coui_widgetbook_component_divider_divider;
import 'package:coui_widgetbook/component/linear_progress_indicator/linear_progress_indicator.dart'
    as _coui_widgetbook_component_linear_progress_indicator_linear_progress_indicator;
import 'package:coui_widgetbook/component/switch/switch.dart'
    as _coui_widgetbook_component_switch_switch;
import 'package:coui_widgetbook/component/toggle/toggle.dart'
    as _coui_widgetbook_component_toggle_toggle;
import 'package:coui_widgetbook/foundation/colors.dart'
    as _coui_widgetbook_foundation_colors;
import 'package:coui_widgetbook/foundation/misc.dart'
    as _coui_widgetbook_foundation_misc;
import 'package:coui_widgetbook/foundation/typography.dart'
    as _coui_widgetbook_foundation_typography;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'components',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'control',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'PrimaryButton',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Primary',
                builder: _coui_widgetbook_component_button_button
                    .buildPrimaryButtonUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'SecondaryButton',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Secondary',
                builder: _coui_widgetbook_component_button_button
                    .buildSecondaryButtonUseCase,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'display',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'Avatar',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _coui_widgetbook_component_avatar_avatar.buildAvatarUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'Calendar',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _coui_widgetbook_component_calendar_calendar
                    .buildCalendarUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'Chip',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _coui_widgetbook_component_chip_chip.buildChipUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CircularProgressIndicator',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _coui_widgetbook_component_circular_progress_indicator_circular_progress_indicator
                        .buildCircularProgressIndicatorUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'Divider',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _coui_widgetbook_component_divider_divider
                    .buildDividerUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'LinearProgressIndicator',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _coui_widgetbook_component_linear_progress_indicator_linear_progress_indicator
                        .buildLinearProgressIndicatorUseCase,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'form',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'Toggle',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _coui_widgetbook_component_toggle_toggle.buildToggleUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Switch Default',
                builder:
                    _coui_widgetbook_component_switch_switch.buildSwitchUseCase,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'layout',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'Alert',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _coui_widgetbook_component_alert_alert.buildAlertUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'Card',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _coui_widgetbook_component_card_card.buildCardUseCase,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'material',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'ColorScheme',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'colors',
            builder: _coui_widgetbook_foundation_colors.buildColorSchemeUseCase,
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'painting',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'BorderRadius',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'radius',
            builder: _coui_widgetbook_foundation_misc.buildRadiusUseCase,
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'theme',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'Typography',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'typography',
            builder:
                _coui_widgetbook_foundation_typography.buildTypographyUseCase,
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'widgets',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'IconThemeData',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'icon sizes',
            builder: _coui_widgetbook_foundation_misc.buildIconSizesUseCase,
          ),
        ],
      ),
    ],
  ),
];
