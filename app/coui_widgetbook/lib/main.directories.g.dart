// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:coui_widgetbook/component/avatar.dart'
    as _coui_widgetbook_component_avatar;
import 'package:coui_widgetbook/component/badge.dart'
    as _coui_widgetbook_component_badge;
import 'package:coui_widgetbook/component/button.dart'
    as _coui_widgetbook_component_button;
import 'package:coui_widgetbook/component/card/card.dart'
    as _coui_widgetbook_component_card_card;
import 'package:coui_widgetbook/component/chip.dart'
    as _coui_widgetbook_component_chip;
import 'package:coui_widgetbook/component/circular_progress_indicator.dart'
    as _coui_widgetbook_component_circular_progress_indicator;
import 'package:coui_widgetbook/component/divider.dart'
    as _coui_widgetbook_component_divider;
import 'package:coui_widgetbook/component/linear_progress_indicator.dart'
    as _coui_widgetbook_component_linear_progress_indicator;
import 'package:coui_widgetbook/component/switch.dart'
    as _coui_widgetbook_component_switch;
import 'package:coui_widgetbook/component/text_field.dart'
    as _coui_widgetbook_component_text_field;
import 'package:coui_widgetbook/foundation/surface.dart'
    as _coui_widgetbook_foundation_surface;
import 'package:coui_widgetbook/foundation/typography.dart'
    as _coui_widgetbook_foundation_typography;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookCategory(
    name: 'Foundation',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'ColorScheme',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'ColorScheme',
            builder: _coui_widgetbook_foundation_surface.buildColorUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'TextStyle',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Typography',
            builder: _coui_widgetbook_foundation_typography
                .buildTypographyThemeDataUseCase,
          ),
        ],
      ),
    ],
  ),
  _widgetbook.WidgetbookFolder(
    name: 'components',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'control',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'Button',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'destructive',
                builder: _coui_widgetbook_component_button
                    .buildButtonDestructiveUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'ghost',
                builder:
                    _coui_widgetbook_component_button.buildButtonGhostUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'link',
                builder:
                    _coui_widgetbook_component_button.buildButtonLinkUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'outline',
                builder:
                    _coui_widgetbook_component_button.buildButtonOutlineUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'primary',
                builder:
                    _coui_widgetbook_component_button.buildButtonPrimaryUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'secondary',
                builder: _coui_widgetbook_component_button
                    .buildButtonSecondaryUseCase,
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
                name: 'default',
                builder:
                    _coui_widgetbook_component_avatar.buildAvatarDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'with badge',
                builder: _coui_widgetbook_component_avatar
                    .buildAvatarWithBadgeUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'with image',
                builder: _coui_widgetbook_component_avatar
                    .buildAvatarWithImageUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'AvatarGroup',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'group',
                builder:
                    _coui_widgetbook_component_avatar.buildAvatarGroupUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'Chip',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'default',
                builder:
                    _coui_widgetbook_component_chip.buildChipDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'interactive',
                builder:
                    _coui_widgetbook_component_chip.buildChipInteractiveUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'with leading',
                builder:
                    _coui_widgetbook_component_chip.buildChipWithLeadingUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'with trailing',
                builder: _coui_widgetbook_component_chip
                    .buildChipWithTrailingUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'CircularProgressIndicator',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'default',
                builder: _coui_widgetbook_component_circular_progress_indicator
                    .buildCircularProgressIndicatorDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'determinate',
                builder: _coui_widgetbook_component_circular_progress_indicator
                    .buildCircularProgressIndicatorDeterminateUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'DestructiveBadge',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'destructive',
                builder: _coui_widgetbook_component_badge
                    .buildDestructiveBadgeUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'Divider',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'default',
                builder: _coui_widgetbook_component_divider
                    .buildDividerDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'with child',
                builder: _coui_widgetbook_component_divider
                    .buildDividerWithChildUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'LinearProgressIndicator',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'default',
                builder: _coui_widgetbook_component_linear_progress_indicator
                    .buildLinearProgressIndicatorDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'determinate',
                builder: _coui_widgetbook_component_linear_progress_indicator
                    .buildLinearProgressIndicatorDeterminateUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'with sparks',
                builder: _coui_widgetbook_component_linear_progress_indicator
                    .buildLinearProgressIndicatorWithSparksUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'OutlineBadge',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'outline',
                builder:
                    _coui_widgetbook_component_badge.buildOutlineBadgeUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'PrimaryBadge',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'primary',
                builder:
                    _coui_widgetbook_component_badge.buildPrimaryBadgeUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'SecondaryBadge',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'secondary',
                builder:
                    _coui_widgetbook_component_badge.buildSecondaryBadgeUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'VerticalDivider',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'default',
                builder: _coui_widgetbook_component_divider
                    .buildVerticalDividerDefaultUseCase,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'form',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'Switch',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'default',
                builder:
                    _coui_widgetbook_component_switch.buildSwitchDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'disabled',
                builder: _coui_widgetbook_component_switch
                    .buildSwitchDisabledUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'with_label',
                builder: _coui_widgetbook_component_switch
                    .buildSwitchWithLabelUseCase,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'TextField',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'default',
                builder: _coui_widgetbook_component_text_field
                    .buildTextFieldDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'password',
                builder: _coui_widgetbook_component_text_field
                    .buildTextFieldPasswordUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'with features',
                builder: _coui_widgetbook_component_text_field
                    .buildTextFieldWithFeaturesUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'with placeholder',
                builder: _coui_widgetbook_component_text_field
                    .buildTextFieldWithPlaceholderUseCase,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'layout',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'Card',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'default',
                builder: _coui_widgetbook_component_card_card
                    .buildCardDefaultUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'filled',
                builder:
                    _coui_widgetbook_component_card_card.buildCardFilledUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'with border',
                builder: _coui_widgetbook_component_card_card
                    .buildCardWithBorderUseCase,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'with shadow',
                builder: _coui_widgetbook_component_card_card
                    .buildCardWithShadowUseCase,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
