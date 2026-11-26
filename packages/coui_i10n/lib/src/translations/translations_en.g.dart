///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'translations.g.dart';

// Path: <root>
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsWidgetbookEn widgetbook = _TranslationsWidgetbookEn._(_root);
	@override late final _TranslationsDocsEn docs = _TranslationsDocsEn._(_root);
}

// Path: widgetbook
class _TranslationsWidgetbookEn extends TranslationsWidgetbookKo {
	_TranslationsWidgetbookEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsWidgetbookCommonEn common = _TranslationsWidgetbookCommonEn._(_root);
	@override late final _TranslationsWidgetbookLoadingEn loading = _TranslationsWidgetbookLoadingEn._(_root);
	@override late final _TranslationsWidgetbookTabsEn tabs = _TranslationsWidgetbookTabsEn._(_root);
	@override late final _TranslationsWidgetbookPaginationEn pagination = _TranslationsWidgetbookPaginationEn._(_root);
	@override late final _TranslationsWidgetbookTooltipEn tooltip = _TranslationsWidgetbookTooltipEn._(_root);
	@override late final _TranslationsWidgetbookRadioEn radio = _TranslationsWidgetbookRadioEn._(_root);
	@override late final _TranslationsWidgetbookCardEn card = _TranslationsWidgetbookCardEn._(_root);
	@override late final _TranslationsWidgetbookAlertEn alert = _TranslationsWidgetbookAlertEn._(_root);
	@override late final _TranslationsWidgetbookAccordionEn accordion = _TranslationsWidgetbookAccordionEn._(_root);
	@override late final _TranslationsWidgetbookSkeletonEn skeleton = _TranslationsWidgetbookSkeletonEn._(_root);
	@override late final _TranslationsWidgetbookToastEn toast = _TranslationsWidgetbookToastEn._(_root);
	@override late final _TranslationsWidgetbookChipEn chip = _TranslationsWidgetbookChipEn._(_root);
	@override late final _TranslationsWidgetbookCheckboxEn checkbox = _TranslationsWidgetbookCheckboxEn._(_root);
	@override late final _TranslationsWidgetbookToggleEn toggle = _TranslationsWidgetbookToggleEn._(_root);
	@override late final _TranslationsWidgetbookDialogEn dialog = _TranslationsWidgetbookDialogEn._(_root);
	@override late final _TranslationsWidgetbookPopoverEn popover = _TranslationsWidgetbookPopoverEn._(_root);
	@override late final _TranslationsWidgetbookTextFieldEn text_field = _TranslationsWidgetbookTextFieldEn._(_root);
	@override late final _TranslationsWidgetbookButtonEn button = _TranslationsWidgetbookButtonEn._(_root);
	@override late final _TranslationsWidgetbookCommandEn command = _TranslationsWidgetbookCommandEn._(_root);
	@override late final _TranslationsWidgetbookFabEn fab = _TranslationsWidgetbookFabEn._(_root);
	@override late final _TranslationsWidgetbookTableEn table = _TranslationsWidgetbookTableEn._(_root);
	@override late final _TranslationsWidgetbookKSwitchEn k_switch = _TranslationsWidgetbookKSwitchEn._(_root);
	@override late final _TranslationsWidgetbookSwitchComponentEn switch_component = _TranslationsWidgetbookSwitchComponentEn._(_root);
	@override late final _TranslationsWidgetbookSelectEn select = _TranslationsWidgetbookSelectEn._(_root);
	@override late final _TranslationsWidgetbookBreadcrumbEn breadcrumb = _TranslationsWidgetbookBreadcrumbEn._(_root);
	@override late final _TranslationsWidgetbookBadgeEn badge = _TranslationsWidgetbookBadgeEn._(_root);
	@override late final _TranslationsWidgetbookThemePreviewEn theme_preview = _TranslationsWidgetbookThemePreviewEn._(_root);
	@override late final _TranslationsWidgetbookChatEn chat = _TranslationsWidgetbookChatEn._(_root);
	@override late final _TranslationsWidgetbookMultipleChoiceEn multiple_choice = _TranslationsWidgetbookMultipleChoiceEn._(_root);
	@override late final _TranslationsWidgetbookFormattedInputEn formatted_input = _TranslationsWidgetbookFormattedInputEn._(_root);
	@override late final _TranslationsWidgetbookSwiperEn swiper = _TranslationsWidgetbookSwiperEn._(_root);
}

// Path: docs
class _TranslationsDocsEn extends TranslationsDocsKo {
	_TranslationsDocsEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsCommonEn common = _TranslationsDocsCommonEn._(_root);
	@override late final _TranslationsDocsBadgesEn badges = _TranslationsDocsBadgesEn._(_root);
	@override late final _TranslationsDocsFlavorsEn flavors = _TranslationsDocsFlavorsEn._(_root);
	@override late final _TranslationsDocsNavigationEn navigation = _TranslationsDocsNavigationEn._(_root);
	@override late final _TranslationsDocsPagesEn pages = _TranslationsDocsPagesEn._(_root);
	@override late final _TranslationsDocsComponentsEn components = _TranslationsDocsComponentsEn._(_root);
}

// Path: widgetbook.common
class _TranslationsWidgetbookCommonEn extends TranslationsWidgetbookCommonKo {
	_TranslationsWidgetbookCommonEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get increment_progress => 'Increment Progress';
	@override String selected_tab({required Object index}) => 'Selected Tab: ${index}';
	@override String current_page({required Object page}) => 'Current Page: ${page}';
	@override String total_pages({required Object count}) => 'Total Pages: ${count}';
	@override String page_of({required Object current, required Object total}) => 'Page ${current} of ${total}';
	@override String get hover_over_icon => 'Hover over the icon';
	@override String counter({required Object count}) => 'Counter: ${count}';
	@override String selected_rows({required Object count}) => 'Selected rows: ${count}';
	@override String selected_cells({required Object count}) => 'Selected cells: ${count}';
	@override String value({required Object value}) => 'Value: ${value}';
}

// Path: widgetbook.loading
class _TranslationsWidgetbookLoadingEn extends TranslationsWidgetbookLoadingKo {
	_TranslationsWidgetbookLoadingEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get indeterminate => 'Indeterminate';
	@override String with_value({required Object percent}) => 'With Value (${percent}%)';
	@override String get custom_size => 'Custom Size';
	@override String get custom_height => 'Custom Height';
	@override String get circular_progress => 'Circular Progress';
	@override String get linear_progress => 'Linear Progress';
}

// Path: widgetbook.tabs
class _TranslationsWidgetbookTabsEn extends TranslationsWidgetbookTabsKo {
	_TranslationsWidgetbookTabsEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get home => 'Home';
	@override String get profile => 'Profile';
	@override String get settings => 'Settings';
	@override String get overview => 'Overview';
	@override String get details => 'Details';
	@override String get history => 'History';
	@override String get overview_content => 'Overview Content';
	@override String get details_content => 'Details Content';
	@override String get history_content => 'History Content';
	@override String get general_info => 'General information about the item';
	@override String get specifications => 'Detailed specifications and properties';
	@override String get timeline => 'Timeline of changes and updates';
}

// Path: widgetbook.pagination
class _TranslationsWidgetbookPaginationEn extends TranslationsWidgetbookPaginationKo {
	_TranslationsWidgetbookPaginationEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get show_skip_to_first => 'Show skip to first';
	@override String get show_skip_to_last => 'Show skip to last';
	@override String get hide_previous_on_first => 'Hide previous on first';
	@override String get hide_next_on_last => 'Hide next on last';
	@override String get max_visible_pages => 'Max visible pages';
}

// Path: widgetbook.tooltip
class _TranslationsWidgetbookTooltipEn extends TranslationsWidgetbookTooltipKo {
	_TranslationsWidgetbookTooltipEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get helpful_message => 'This is a helpful tooltip message';
	@override String get tooltip_above => 'Tooltip above';
	@override String get tooltip_below => 'Tooltip below';
	@override String get tooltip_left => 'Tooltip on left';
	@override String get tooltip_right => 'Tooltip on right';
	@override String get top => 'Top';
	@override String get bottom => 'Bottom';
	@override String get left => 'Left';
	@override String get right => 'Right';
}

// Path: widgetbook.radio
class _TranslationsWidgetbookRadioEn extends TranslationsWidgetbookRadioKo {
	_TranslationsWidgetbookRadioEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get small => 'Small';
	@override String get medium => 'Medium';
	@override String get large => 'Large';
}

// Path: widgetbook.card
class _TranslationsWidgetbookCardEn extends TranslationsWidgetbookCardKo {
	_TranslationsWidgetbookCardEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get card_content => 'Card Content';
	@override String get gradient_card => 'Gradient Card';
	@override String get custom_decoration => 'Card with custom decoration';
}

// Path: widgetbook.alert
class _TranslationsWidgetbookAlertEn extends TranslationsWidgetbookAlertKo {
	_TranslationsWidgetbookAlertEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Alert Title';
	@override String get message => 'This is an alert message.';
}

// Path: widgetbook.accordion
class _TranslationsWidgetbookAccordionEn extends TranslationsWidgetbookAccordionKo {
	_TranslationsWidgetbookAccordionEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get what_is_coui => 'What is CoUI Flutter?';
	@override String get what_is_coui_answer => 'CoUI Flutter is a comprehensive UI component library designed to help you build modern and accessible Flutter applications with consistent design patterns.';
	@override String get how_to_install => 'How do I install it?';
	@override String get how_to_install_answer => 'Add coui_flutter to your pubspec.yaml dependencies and run flutter pub get to install the package.';
	@override String get is_customizable => 'Is it customizable?';
	@override String get is_customizable_answer => 'Yes! CoUI Flutter provides extensive theming support allowing you to customize colors, typography, spacing and more via ThemeData.';
	@override String get getting_started => 'Getting Started';
	@override String get getting_started_answer => 'Start by installing the package and importing it into your project. Refer to the documentation for detailed setup instructions.';
	@override String get features_expanded => 'Features (Expanded by default)';
	@override String get features_answer => 'CoUI Flutter includes buttons, forms, dialogs, navigation components and more. All components are designed with accessibility and theming in mind.';
	@override String get support => 'Support';
	@override String get support_answer => 'For questions or support, visit our GitHub repository or check the documentation at docs.coui.dev.';
	@override String get coui_description => 'CoUI Flutter is a comprehensive UI component library for Flutter with 90+ widgets, optimized for desktop and web platforms.';
	@override String get install_description => 'Add it as a dependency in your pubspec.yaml. It\'s available on pub.dev.';
	@override String get customizable_description => 'Yes! All components are fully customizable through the theming system.';
}

// Path: widgetbook.skeleton
class _TranslationsWidgetbookSkeletonEn extends TranslationsWidgetbookSkeletonKo {
	_TranslationsWidgetbookSkeletonEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get skeleton_enabled => 'Skeleton Enabled:';
	@override String get title_text => 'This is a title';
	@override String get description_text => 'This is a longer description text';
	@override String get short_text => 'Short text';
	@override String get without_skeleton => 'Without Skeleton:';
	@override String get with_skeleton => 'With Skeleton:';
	@override String get user_name => 'User Name';
	@override String get user_email => 'user@example.com';
	@override String get article_title => 'Article Title';
	@override String get posted_date => 'Posted on Jan 1, 2024';
	@override String get bio_description => 'A developer documenting daily life';
	@override String get show_content => 'Show Content';
	@override String get show_loading => 'Show Loading';
	@override String get article_content => 'This is an example of article content. It will be replaced by skeleton when loading.';
}

// Path: widgetbook.toast
class _TranslationsWidgetbookToastEn extends TranslationsWidgetbookToastKo {
	_TranslationsWidgetbookToastEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get success => 'Success';
	@override String get operation_completed => 'Operation completed successfully';
	@override String get show_toast => 'Show Toast';
	@override String toast_at({required Object location}) => 'Toast at ${location}';
	@override String get top_left => 'Top Left';
	@override String get top_center => 'Top Center';
	@override String get top_right => 'Top Right';
	@override String get bottom_left => 'Bottom Left';
	@override String get bottom_center => 'Bottom Center';
	@override String get bottom_right => 'Bottom Right';
}

// Path: widgetbook.chip
class _TranslationsWidgetbookChipEn extends TranslationsWidgetbookChipKo {
	_TranslationsWidgetbookChipEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get chip => 'Chip';
}

// Path: widgetbook.checkbox
class _TranslationsWidgetbookCheckboxEn extends TranslationsWidgetbookCheckboxKo {
	_TranslationsWidgetbookCheckboxEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get accept_terms => 'I accept the terms and conditions';
	@override String get tristate => 'Tristate';
}

// Path: widgetbook.toggle
class _TranslationsWidgetbookToggleEn extends TranslationsWidgetbookToggleKo {
	_TranslationsWidgetbookToggleEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get toggle => 'Toggle';
}

// Path: widgetbook.dialog
class _TranslationsWidgetbookDialogEn extends TranslationsWidgetbookDialogKo {
	_TranslationsWidgetbookDialogEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic_dialog => 'Basic Dialog';
	@override String get basic_title => 'Basic Dialog';
	@override String get basic_content => 'This is a simple dialog with title and content.';
	@override String get simple_dialog_content => 'This is a simple dialog with title and content.';
	@override String get show_basic => 'Show Basic';
	@override String get show_basic_dialog => 'Show Basic Dialog';
	@override String get confirm_action => 'Confirm Action';
	@override String get confirm_title => 'Confirm';
	@override String get confirm_content => 'Are you sure you want to perform this action?';
	@override String get confirm_action_content => 'Are you sure you want to perform this action? This cannot be undone.';
	@override String get cancel => 'Cancel';
	@override String get confirm => 'Confirm';
	@override String get show_confirmation => 'Show Confirmation';
	@override String get show_confirmation_dialog => 'Show Confirmation Dialog';
	@override String get warning => 'Warning';
	@override String get warning_title => 'Warning';
	@override String get warning_content => 'This action may affect your data. Please proceed carefully.';
	@override String get dismiss => 'Dismiss';
	@override String get show_warning => 'Show Warning';
	@override String get show_warning_dialog => 'Show Warning Dialog';
}

// Path: widgetbook.popover
class _TranslationsWidgetbookPopoverEn extends TranslationsWidgetbookPopoverKo {
	_TranslationsWidgetbookPopoverEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get popover_content => 'Popover Content';
	@override String get content_title => 'Popover Title';
	@override String get content_description => 'This is a popover with customizable content.';
	@override String get customizable_content => 'This is a popover with customizable content.';
	@override String get show_popover => 'Show Popover';
	@override String popover_at({required Object position}) => 'Popover at ${position}';
	@override String get top => 'Top';
	@override String get bottom => 'Bottom';
	@override String get left => 'Left';
	@override String get right => 'Right';
}

// Path: widgetbook.text_field
class _TranslationsWidgetbookTextFieldEn extends TranslationsWidgetbookTextFieldKo {
	_TranslationsWidgetbookTextFieldEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get enter_name => 'Enter your name';
	@override String get type_here => 'Type here';
}

// Path: widgetbook.button
class _TranslationsWidgetbookButtonEn extends TranslationsWidgetbookButtonKo {
	_TranslationsWidgetbookButtonEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get primary_button => 'Primary Button';
	@override String get secondary_button => 'Secondary Button';
	@override String get dashed_button => 'Upload File';
	@override String get upload_file => 'Upload File';
}

// Path: widgetbook.command
class _TranslationsWidgetbookCommandEn extends TranslationsWidgetbookCommandKo {
	_TranslationsWidgetbookCommandEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get placeholder => 'Search commands...';
	@override String get item => 'Item';
	@override String get category_recent => 'Recent';
	@override String get category_actions => 'Actions';
	@override String get recent_item_1 => 'Recent File 1';
	@override String get recent_item_2 => 'Recent File 2';
	@override String get action_new => 'New';
	@override String get action_open => 'Open';
	@override String get action_save => 'Save';
}

// Path: widgetbook.fab
class _TranslationsWidgetbookFabEn extends TranslationsWidgetbookFabKo {
	_TranslationsWidgetbookFabEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get default_tooltip => 'Add';
	@override String get actions_tooltip => 'Open Menu';
	@override String get mini_tooltip => 'Mini FAB';
	@override String get fan_tooltip => 'Fan Menu';
	@override String get body_text => 'Click the FAB button';
	@override String get action_edit => 'Edit';
	@override String get action_edit_tooltip => 'Edit';
	@override String get action_share => 'Share';
	@override String get action_share_tooltip => 'Share';
	@override String get action_delete => 'Delete';
	@override String get action_delete_tooltip => 'Delete';
	@override String get action_camera => 'Camera';
	@override String get action_gallery => 'Gallery';
	@override String get action_video => 'Video';
	@override String get action_audio => 'Audio';
}

// Path: widgetbook.table
class _TranslationsWidgetbookTableEn extends TranslationsWidgetbookTableKo {
	_TranslationsWidgetbookTableEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get name => 'Name';
	@override String get email => 'Email';
	@override String get role => 'Role';
	@override String get john_doe => 'John Doe';
	@override String get john_email => 'john@example.com';
	@override String get developer => 'Developer';
	@override String get jane_smith => 'Jane Smith';
	@override String get jane_email => 'jane@example.com';
	@override String get designer => 'Designer';
	@override String get bob_johnson => 'Bob Johnson';
	@override String get bob_email => 'bob@example.com';
	@override String get manager => 'Manager';
	@override String get select => 'Select';
	@override String get product => 'Product';
	@override String get price => 'Price';
	@override String get stock => 'Stock';
	@override String get laptop => 'Laptop';
	@override String get mouse => 'Mouse';
	@override String get keyboard => 'Keyboard';
}

// Path: widgetbook.k_switch
class _TranslationsWidgetbookKSwitchEn extends TranslationsWidgetbookKSwitchKo {
	_TranslationsWidgetbookKSwitchEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get k_switch => 'Switch';
}

// Path: widgetbook.switch_component
class _TranslationsWidgetbookSwitchComponentEn extends TranslationsWidgetbookSwitchComponentKo {
	_TranslationsWidgetbookSwitchComponentEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get switch_label => 'Switch Label';
}

// Path: widgetbook.select
class _TranslationsWidgetbookSelectEn extends TranslationsWidgetbookSelectKo {
	_TranslationsWidgetbookSelectEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get apple => 'Apple';
	@override String get banana => 'Banana';
	@override String get cherry => 'Cherry';
	@override String get date => 'Date';
	@override String get choose_size => 'Choose a size';
	@override String get small => 'Small';
	@override String get medium => 'Medium';
	@override String get large => 'Large';
	@override String get extra_large => 'Extra Large';
	@override String get citrus_fruits => 'Citrus Fruits';
	@override String get orange => 'Orange';
	@override String get lemon => 'Lemon';
	@override String get grapefruit => 'Grapefruit';
	@override String get berries => 'Berries';
	@override String get strawberry => 'Strawberry';
	@override String get blueberry => 'Blueberry';
	@override String get raspberry => 'Raspberry';
}

// Path: widgetbook.breadcrumb
class _TranslationsWidgetbookBreadcrumbEn extends TranslationsWidgetbookBreadcrumbKo {
	_TranslationsWidgetbookBreadcrumbEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get home => 'Home';
	@override String get products => 'Products';
	@override String get electronics => 'Electronics';
	@override String get smartphones => 'Smartphones';
	@override String get documents => 'Documents';
	@override String get projects => 'Projects';
	@override String get current_folder => 'Current Folder';
	@override String current_path({required Object path}) => 'Current path: ${path}';
}

// Path: widgetbook.badge
class _TranslationsWidgetbookBadgeEn extends TranslationsWidgetbookBadgeKo {
	_TranslationsWidgetbookBadgeEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get primary => 'Primary';
	@override String get secondary => 'Secondary';
	@override String get outline => 'Outline';
	@override String get destructive => 'Destructive';
	@override String get featured => 'Featured';
	@override String get more => 'More';
	@override String get verified => 'Verified';
	@override String get error => 'Error';
	@override String get click_me => 'Click me';
	@override String get clickable => 'Clickable';
}

// Path: widgetbook.theme_preview
class _TranslationsWidgetbookThemePreviewEn extends TranslationsWidgetbookThemePreviewKo {
	_TranslationsWidgetbookThemePreviewEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Theme Preview';
	@override String get description => 'Comprehensive overview of all theme tokens and component styles';
	@override String get color_palette => 'Color Palette';
	@override String get brand_colors => 'Brand Colors';
	@override String get base_colors => 'Base Colors';
	@override String get status_colors => 'Status Colors';
	@override String get buttons => 'Buttons';
	@override String get primary_button => 'Primary';
	@override String get secondary_button => 'Secondary';
	@override String get outline_button => 'Outline';
	@override String get ghost_button => 'Ghost';
	@override String get destructive_button => 'Destructive';
	@override String get disabled_button => 'Disabled';
	@override String get cards => 'Cards';
	@override String get card_title => 'Card Title';
	@override String get card_description => 'This is a sample card description.';
	@override String get surface_card => 'Surface Card';
	@override String get filled_variant => 'Filled variant with background';
	@override String get form_elements => 'Form Elements';
	@override String get text_input_placeholder => 'Enter text here...';
	@override String get checkbox_checked => 'Checked';
	@override String get checkbox_unchecked => 'Unchecked';
	@override String get toggle_on => 'On';
	@override String get toggle_off => 'Off';
	@override String get alerts => 'Alerts';
	@override String get info_alert => 'Info Alert';
	@override String get info_alert_message => 'This is an informational message.';
	@override String get error_alert => 'Error Alert';
	@override String get error_alert_message => 'Something went wrong.';
	@override String get badges_chips => 'Badges & Chips';
	@override String get primary_badge => 'Primary';
	@override String get secondary_badge => 'Secondary';
	@override String get outline_badge => 'Outline';
	@override String get destructive_badge => 'Destructive';
	@override String get chip_example => 'Starred';
	@override String get typography => 'Typography';
	@override String get heading_1 => 'Heading 1';
	@override String get heading_2 => 'Heading 2';
	@override String get heading_3 => 'Heading 3';
	@override String get heading_4 => 'Heading 4';
	@override String get body_text => 'This is body text with normal weight.';
	@override String get small_text => 'This is smaller text for captions.';
	@override String get muted_text => 'This is muted text for secondary information.';
	@override String get bold_text => 'This is bold text for emphasis.';
	@override String get spacing_radius => 'Spacing & Radius';
	@override String get border_radius => 'Border Radius';
	@override String get loading_states => 'Loading States';
}

// Path: widgetbook.chat
class _TranslationsWidgetbookChatEn extends TranslationsWidgetbookChatKo {
	_TranslationsWidgetbookChatEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get hello => 'Hello! How are you?';
	@override String get doing_great => 'Doing great, thanks!';
	@override String get nice_weather => 'Nice weather today!';
	@override String get yes_beautiful => 'Yes, it\'s beautiful!';
	@override String get sender => 'Sender';
	@override String get receiver => 'Receiver';
}

// Path: widgetbook.multiple_choice
class _TranslationsWidgetbookMultipleChoiceEn extends TranslationsWidgetbookMultipleChoiceKo {
	_TranslationsWidgetbookMultipleChoiceEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get option_a => 'Option A';
	@override String get option_b => 'Option B';
	@override String get option_c => 'Option C';
	@override String get option_d => 'Option D';
	@override String selected_value({required Object value}) => 'Selected: ${value}';
	@override String selected_values({required Object values}) => 'Selected: ${values}';
}

// Path: widgetbook.formatted_input
class _TranslationsWidgetbookFormattedInputEn extends TranslationsWidgetbookFormattedInputKo {
	_TranslationsWidgetbookFormattedInputEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get date_format => 'Date Format (MM/DD/YYYY)';
	@override String get time_format => 'Time Format (HH:MM)';
	@override String current_value({required Object value}) => 'Current value: ${value}';
}

// Path: widgetbook.swiper
class _TranslationsWidgetbookSwiperEn extends TranslationsWidgetbookSwiperKo {
	_TranslationsWidgetbookSwiperEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get swipe_hint => 'Swipe or tap to open';
	@override String get overlay_content => 'Overlay Content';
	@override String get close => 'Close';
}

// Path: docs.common
class _TranslationsDocsCommonEn extends TranslationsDocsCommonKo {
	_TranslationsDocsCommonEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get app_name => 'coui_flutter';
	@override String get search_documentation => 'Search documentation...';
	@override String get docs => 'Documentation';
	@override String get components => 'Components';
	@override String get close => 'Close';
	@override String get on_this_page => 'Table of contents on this page';
	@override String get work_in_progress_title => 'In Development';
	@override String get work_in_progress_message => 'This page is still under development. Please come back later.';
	@override String get add => 'Add';
	@override String get reset => 'Reset';
	@override String get prev => 'Previous';
	@override String get next => 'Next';
	@override String get finish => 'Finish';
	@override String get open => 'Open';
	@override String get disabled => 'Disabled';
	@override String get refresh => 'Refresh';
	@override String get rebuild => 'Rebuild';
	@override String get change_color => 'Change Color';
}

// Path: docs.badges
class _TranslationsDocsBadgesEn extends TranslationsDocsBadgesKo {
	_TranslationsDocsBadgesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get k_new => 'New';
	@override String get updated => 'Updated';
	@override String get wip => 'Work in Progress';
	@override String get experimental => 'Experimental';
}

// Path: docs.flavors
class _TranslationsDocsFlavorsEn extends TranslationsDocsFlavorsKo {
	_TranslationsDocsFlavorsEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get local => 'Local';
	@override String get experimental => 'Experimental';
	@override String get unknown => 'Unknown';
}

// Path: docs.navigation
class _TranslationsDocsNavigationEn extends TranslationsDocsNavigationKo {
	_TranslationsDocsNavigationEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get getting_started => 'Getting Started';
	@override String get animation => 'Animation';
	@override String get control => 'Control';
	@override String get disclosure => 'Disclosure';
	@override String get display => 'Display';
	@override String get feedback => 'Feedback';
	@override String get form => 'Form';
	@override String get layout => 'Layout';
	@override String get navigation => 'Navigation';
	@override String get overlay => 'Overlay';
	@override String get utility => 'Utility';
	@override String get my_account => 'My Account';
	@override String get profile => 'Profile';
	@override String get settings => 'Settings';
	@override String get team => 'Team';
	@override String get new_team => 'New Team';
	@override String get billing => 'Billing';
	@override String get api => 'API';
	@override String get log_out => 'Log Out';
	@override String get support => 'Support';
	@override String get invite_users => 'Invite Users';
	@override String get more => 'More';
	@override String get github => 'GitHub';
	@override String get note => 'Note';
	@override String get message => 'Message';
	@override String get keyboard_shortcuts => 'Keyboard Shortcuts';
}

// Path: docs.pages
class _TranslationsDocsPagesEn extends TranslationsDocsPagesKo {
	_TranslationsDocsPagesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsPagesIntroductionEn introduction = _TranslationsDocsPagesIntroductionEn._(_root);
	@override late final _TranslationsDocsPagesInstallationEn installation = _TranslationsDocsPagesInstallationEn._(_root);
	@override late final _TranslationsDocsPagesThemeEn theme = _TranslationsDocsPagesThemeEn._(_root);
	@override late final _TranslationsDocsPagesTypographyEn typography = _TranslationsDocsPagesTypographyEn._(_root);
	@override late final _TranslationsDocsPagesLayoutEn layout = _TranslationsDocsPagesLayoutEn._(_root);
	@override late final _TranslationsDocsPagesWebPreloaderEn web_preloader = _TranslationsDocsPagesWebPreloaderEn._(_root);
	@override late final _TranslationsDocsPagesComponentsListEn components_list = _TranslationsDocsPagesComponentsListEn._(_root);
	@override late final _TranslationsDocsPagesIconsEn icons = _TranslationsDocsPagesIconsEn._(_root);
	@override late final _TranslationsDocsPagesColorsEn colors = _TranslationsDocsPagesColorsEn._(_root);
	@override late final _TranslationsDocsPagesExternalEn external = _TranslationsDocsPagesExternalEn._(_root);
	@override late final _TranslationsDocsPagesStateEn state = _TranslationsDocsPagesStateEn._(_root);
}

// Path: docs.components
class _TranslationsDocsComponentsEn extends TranslationsDocsComponentsKo {
	_TranslationsDocsComponentsEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsComponentsAccordionEn accordion = _TranslationsDocsComponentsAccordionEn._(_root);
	@override late final _TranslationsDocsComponentsAlertEn alert = _TranslationsDocsComponentsAlertEn._(_root);
	@override late final _TranslationsDocsComponentsEmptyStateEn empty_state = _TranslationsDocsComponentsEmptyStateEn._(_root);
	@override late final _TranslationsDocsComponentsFadeScrollEn fade_scroll = _TranslationsDocsComponentsFadeScrollEn._(_root);
	@override late final _TranslationsDocsComponentsValidationBadgeEn validation_badge = _TranslationsDocsComponentsValidationBadgeEn._(_root);
	@override late final _TranslationsDocsComponentsBannerEn banner = _TranslationsDocsComponentsBannerEn._(_root);
	@override late final _TranslationsDocsComponentsAlertDialogEn alert_dialog = _TranslationsDocsComponentsAlertDialogEn._(_root);
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderEn animated_value_builder = _TranslationsDocsComponentsAnimatedValueBuilderEn._(_root);
	@override late final _TranslationsDocsComponentsAppBarEn app_bar = _TranslationsDocsComponentsAppBarEn._(_root);
	@override late final _TranslationsDocsComponentsFabEn fab = _TranslationsDocsComponentsFabEn._(_root);
	@override late final _TranslationsDocsComponentsHoverEn hover = _TranslationsDocsComponentsHoverEn._(_root);
	@override late final _TranslationsDocsComponentsScrollbarEn scrollbar = _TranslationsDocsComponentsScrollbarEn._(_root);
	@override late final _TranslationsDocsComponentsAutocompleteEn autocomplete = _TranslationsDocsComponentsAutocompleteEn._(_root);
	@override late final _TranslationsDocsComponentsAvatarEn avatar = _TranslationsDocsComponentsAvatarEn._(_root);
	@override late final _TranslationsDocsComponentsAvatarGroupEn avatar_group = _TranslationsDocsComponentsAvatarGroupEn._(_root);
	@override late final _TranslationsDocsComponentsBadgeEn badge = _TranslationsDocsComponentsBadgeEn._(_root);
	@override late final _TranslationsDocsComponentsBreadcrumbEn breadcrumb = _TranslationsDocsComponentsBreadcrumbEn._(_root);
	@override late final _TranslationsDocsComponentsButtonEn button = _TranslationsDocsComponentsButtonEn._(_root);
	@override late final _TranslationsDocsComponentsCalendarEn calendar = _TranslationsDocsComponentsCalendarEn._(_root);
	@override late final _TranslationsDocsComponentsCardEn card = _TranslationsDocsComponentsCardEn._(_root);
	@override late final _TranslationsDocsComponentsCardImageEn card_image = _TranslationsDocsComponentsCardImageEn._(_root);
	@override late final _TranslationsDocsComponentsCarouselEn carousel = _TranslationsDocsComponentsCarouselEn._(_root);
	@override late final _TranslationsDocsComponentsCheckboxEn checkbox = _TranslationsDocsComponentsCheckboxEn._(_root);
	@override late final _TranslationsDocsComponentsChipEn chip = _TranslationsDocsComponentsChipEn._(_root);
	@override late final _TranslationsDocsComponentsChipInputEn chip_input = _TranslationsDocsComponentsChipInputEn._(_root);
	@override late final _TranslationsDocsComponentsCircularProgressEn circular_progress = _TranslationsDocsComponentsCircularProgressEn._(_root);
	@override late final _TranslationsDocsComponentsCodeSnippetEn code_snippet = _TranslationsDocsComponentsCodeSnippetEn._(_root);
	@override late final _TranslationsDocsComponentsCollapsibleEn collapsible = _TranslationsDocsComponentsCollapsibleEn._(_root);
	@override late final _TranslationsDocsComponentsColorPickerEn color_picker = _TranslationsDocsComponentsColorPickerEn._(_root);
	@override late final _TranslationsDocsComponentsCommandEn command = _TranslationsDocsComponentsCommandEn._(_root);
	@override late final _TranslationsDocsComponentsContextMenuEn context_menu = _TranslationsDocsComponentsContextMenuEn._(_root);
	@override late final _TranslationsDocsComponentsDatePickerEn date_picker = _TranslationsDocsComponentsDatePickerEn._(_root);
	@override late final _TranslationsDocsComponentsDialogEn dialog = _TranslationsDocsComponentsDialogEn._(_root);
	@override late final _TranslationsDocsComponentsDividerEn divider = _TranslationsDocsComponentsDividerEn._(_root);
	@override late final _TranslationsDocsComponentsDotIndicatorEn dot_indicator = _TranslationsDocsComponentsDotIndicatorEn._(_root);
	@override late final _TranslationsDocsComponentsDrawerEn drawer = _TranslationsDocsComponentsDrawerEn._(_root);
	@override late final _TranslationsDocsComponentsDropdownMenuEn dropdown_menu = _TranslationsDocsComponentsDropdownMenuEn._(_root);
	@override late final _TranslationsDocsComponentsExpandableSidebarEn expandable_sidebar = _TranslationsDocsComponentsExpandableSidebarEn._(_root);
	@override late final _TranslationsDocsComponentsFormEn form = _TranslationsDocsComponentsFormEn._(_root);
	@override late final _TranslationsDocsComponentsFormattedInputEn formatted_input = _TranslationsDocsComponentsFormattedInputEn._(_root);
	@override late final _TranslationsDocsComponentsHoverCardEn hover_card = _TranslationsDocsComponentsHoverCardEn._(_root);
	@override late final _TranslationsDocsComponentsInputEn input = _TranslationsDocsComponentsInputEn._(_root);
	@override late final _TranslationsDocsComponentsInputOtpEn input_otp = _TranslationsDocsComponentsInputOtpEn._(_root);
	@override late final _TranslationsDocsComponentsItemPickerEn item_picker = _TranslationsDocsComponentsItemPickerEn._(_root);
	@override late final _TranslationsDocsComponentsKeyboardDisplayEn keyboard_display = _TranslationsDocsComponentsKeyboardDisplayEn._(_root);
	@override late final _TranslationsDocsComponentsLinearProgressEn linear_progress = _TranslationsDocsComponentsLinearProgressEn._(_root);
	@override late final _TranslationsDocsComponentsMaterialEn material = _TranslationsDocsComponentsMaterialEn._(_root);
	@override late final _TranslationsDocsComponentsMenubarEn menubar = _TranslationsDocsComponentsMenubarEn._(_root);
	@override late final _TranslationsDocsComponentsMultiselectEn multiselect = _TranslationsDocsComponentsMultiselectEn._(_root);
	@override late final _TranslationsDocsComponentsNavigationBarEn navigation_bar = _TranslationsDocsComponentsNavigationBarEn._(_root);
	@override late final _TranslationsDocsComponentsNavigationMenuEn navigation_menu = _TranslationsDocsComponentsNavigationMenuEn._(_root);
	@override late final _TranslationsDocsComponentsNavigationRailEn navigation_rail = _TranslationsDocsComponentsNavigationRailEn._(_root);
	@override late final _TranslationsDocsComponentsNavigationSidebarEn navigation_sidebar = _TranslationsDocsComponentsNavigationSidebarEn._(_root);
	@override late final _TranslationsDocsComponentsNumberInputEn number_input = _TranslationsDocsComponentsNumberInputEn._(_root);
	@override late final _TranslationsDocsComponentsNumberTickerEn number_ticker = _TranslationsDocsComponentsNumberTickerEn._(_root);
	@override late final _TranslationsDocsComponentsOverflowMarqueeEn overflow_marquee = _TranslationsDocsComponentsOverflowMarqueeEn._(_root);
	@override late final _TranslationsDocsComponentsPaginationEn pagination = _TranslationsDocsComponentsPaginationEn._(_root);
	@override late final _TranslationsDocsComponentsPhoneInputEn phone_input = _TranslationsDocsComponentsPhoneInputEn._(_root);
	@override late final _TranslationsDocsComponentsPopoverEn popover = _TranslationsDocsComponentsPopoverEn._(_root);
	@override late final _TranslationsDocsComponentsProgressEn progress = _TranslationsDocsComponentsProgressEn._(_root);
	@override late final _TranslationsDocsComponentsRadioCardEn radio_card = _TranslationsDocsComponentsRadioCardEn._(_root);
	@override late final _TranslationsDocsComponentsRadioGroupEn radio_group = _TranslationsDocsComponentsRadioGroupEn._(_root);
	@override late final _TranslationsDocsComponentsRefreshTriggerEn refresh_trigger = _TranslationsDocsComponentsRefreshTriggerEn._(_root);
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderEn repeated_animation_builder = _TranslationsDocsComponentsRepeatedAnimationBuilderEn._(_root);
	@override late final _TranslationsDocsComponentsResizableEn resizable = _TranslationsDocsComponentsResizableEn._(_root);
	@override late final _TranslationsDocsComponentsScaffoldEn scaffold = _TranslationsDocsComponentsScaffoldEn._(_root);
	@override late final _TranslationsDocsComponentsSelectEn select = _TranslationsDocsComponentsSelectEn._(_root);
	@override late final _TranslationsDocsComponentsSheetEn sheet = _TranslationsDocsComponentsSheetEn._(_root);
	@override late final _TranslationsDocsComponentsSkeletonEn skeleton = _TranslationsDocsComponentsSkeletonEn._(_root);
	@override late final _TranslationsDocsComponentsSliderEn slider = _TranslationsDocsComponentsSliderEn._(_root);
	@override late final _TranslationsDocsComponentsSortableEn sortable = _TranslationsDocsComponentsSortableEn._(_root);
	@override late final _TranslationsDocsComponentsStarRatingEn star_rating = _TranslationsDocsComponentsStarRatingEn._(_root);
	@override late final _TranslationsDocsComponentsStepperEn stepper = _TranslationsDocsComponentsStepperEn._(_root);
	@override late final _TranslationsDocsComponentsStepsEn steps = _TranslationsDocsComponentsStepsEn._(_root);
	@override late final _TranslationsDocsComponentsSwiperEn swiper = _TranslationsDocsComponentsSwiperEn._(_root);
	@override late final _TranslationsDocsComponentsKSwitchEn k_switch = _TranslationsDocsComponentsKSwitchEn._(_root);
	@override late final _TranslationsDocsComponentsSwitcherEn switcher = _TranslationsDocsComponentsSwitcherEn._(_root);
	@override late final _TranslationsDocsComponentsTabContainerEn tab_container = _TranslationsDocsComponentsTabContainerEn._(_root);
	@override late final _TranslationsDocsComponentsTabListEn tab_list = _TranslationsDocsComponentsTabListEn._(_root);
	@override late final _TranslationsDocsComponentsTabPaneEn tab_pane = _TranslationsDocsComponentsTabPaneEn._(_root);
	@override late final _TranslationsDocsComponentsTableEn table = _TranslationsDocsComponentsTableEn._(_root);
	@override late final _TranslationsDocsComponentsTabsEn tabs = _TranslationsDocsComponentsTabsEn._(_root);
	@override late final _TranslationsDocsComponentsTextAreaEn text_area = _TranslationsDocsComponentsTextAreaEn._(_root);
	@override late final _TranslationsDocsComponentsTimePickerEn time_picker = _TranslationsDocsComponentsTimePickerEn._(_root);
	@override late final _TranslationsDocsComponentsTimelineEn timeline = _TranslationsDocsComponentsTimelineEn._(_root);
	@override late final _TranslationsDocsComponentsTimelineAnimationEn timeline_animation = _TranslationsDocsComponentsTimelineAnimationEn._(_root);
	@override late final _TranslationsDocsComponentsToastEn toast = _TranslationsDocsComponentsToastEn._(_root);
	@override late final _TranslationsDocsComponentsToggleEn toggle = _TranslationsDocsComponentsToggleEn._(_root);
	@override late final _TranslationsDocsComponentsTooltipEn tooltip = _TranslationsDocsComponentsTooltipEn._(_root);
	@override late final _TranslationsDocsComponentsTrackerEn tracker = _TranslationsDocsComponentsTrackerEn._(_root);
	@override late final _TranslationsDocsComponentsTreeEn tree = _TranslationsDocsComponentsTreeEn._(_root);
	@override late final _TranslationsDocsComponentsWindowEn window = _TranslationsDocsComponentsWindowEn._(_root);
}

// Path: docs.pages.introduction
class _TranslationsDocsPagesIntroductionEn extends TranslationsDocsPagesIntroductionKo {
	_TranslationsDocsPagesIntroductionEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Introduction';
	@override String get description => 'Getting started with coui_flutter';
	@override String get lead => 'Beautifully designed components from Coui/UI are now available in Flutter.';
	@override String get welcome_paragraph_1 => 'coui_flutter is a diverse and comprehensive set of UI components specifically designed for Flutter desktop and web applications. As the popularity of Flutter for building cross-platform apps increases, we recognized the need for a toolkit that highlights the unique design requirements of desktop and web interfaces.';
	@override String get welcome_paragraph_2 => 'This package provides a wide range of customizable and responsive components that adhere to modern desktop and web design principles. Whether you\'re building sophisticated business applications, polished dashboards, or productivity tools, our components are designed to help you create professional and sleek UIs quickly and efficiently.';
	@override String get features => 'Key Features';
	@override late final _TranslationsDocsPagesIntroductionFeaturesListEn features_list = _TranslationsDocsPagesIntroductionFeaturesListEn._(_root);
	@override String get notes => 'Notes';
	@override String get notes_paragraph_1 => 'This package is still in development and may have future changes. Please exercise caution when using this package in production.';
	@override String get notes_paragraph_2 => 'This package is not affiliated with Coui/UI. It is a community-driven project.';
	@override String get faq => 'Frequently Asked Questions';
	@override String get faq_gorouter_q => 'Does it support GoRouter?';
	@override String get faq_gorouter_a => 'Yes, it does. You can use GoRouter with coui_flutter.';
	@override String get faq_usage_q => 'Can I use it in my project?';
	@override String get faq_usage_a => 'Yes! You can use it freely in personal and commercial projects. No attribution required.';
	@override String get faq_material_q => 'Can I use it with Material/Cupertino widgets?';
	@override String get faq_material_a_1 => 'Absolutely!';
	@override String get faq_material_a_2 => 'Refer to this page!';
	@override String get faq_style_q => 'Can I set which style to use? (Default/New York)';
	@override String get faq_style_a_1 => 'Unfortunately, you cannot. This package only supports the New York style. However, if you want the default style from Coui/UI,';
	@override String get faq_style_a_2 => 'I recommend';
	@override String get faq_style_a_3 => 'this package. Creator:';
	@override String get links => 'Links';
	@override String get link_github => 'Github: ';
	@override String get link_pubdev => 'pub.dev: ';
	@override String get link_discord => 'Discord: ';
}

// Path: docs.pages.installation
class _TranslationsDocsPagesInstallationEn extends TranslationsDocsPagesInstallationKo {
	_TranslationsDocsPagesInstallationEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Installation';
	@override String get description => 'Installing coui_flutter in your project';
	@override String get stable_version => 'Stable Version';
	@override String get experimental_version => 'Experimental Version';
	@override String get step1_title => 'Create a new Flutter project';
	@override String get step1_content => 'Create a new Flutter project using the following command:';
	@override String get step2_title => 'Add dependencies';
	@override String get step2_content => 'Next, add the coui_flutter dependency to your project.';
	@override String get step3_title => 'Import package';
	@override String get step3_content => 'Now you can import the package in your Dart code.';
	@override String get step4_title => 'Add CouiApp widget';
	@override String get step4_content => 'Add the CouiApp widget to your main function.';
	@override String get step5_title => 'Run the app';
	@override String get step5_content => 'Use the following command to run the app:';
	@override String get experimental_intro => 'The experimental version is available on GitHub.';
	@override String get experimental_usage => 'To use the experimental version, use git instead of a version number in your pubspec.yaml file:';
	@override String get see_page => 'Refer to: ';
	@override String get this_page => 'this page';
	@override String get for_more_info => ' for more information.';
	@override String get warning_title => 'Warning';
	@override String get warning_content => 'The experimental version may include breaking changes and is not recommended for production use. This version is for testing and development purposes only.';
}

// Path: docs.pages.theme
class _TranslationsDocsPagesThemeEn extends TranslationsDocsPagesThemeKo {
	_TranslationsDocsPagesThemeEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Theme';
	@override String get description => 'Customizing themes';
	@override String get custom_color_scheme => 'Custom Color Scheme';
	@override String get custom_color_scheme_desc => 'Use a custom color scheme to customize the look and feel of your app.';
	@override String get premade_color_schemes => 'Premade Color Schemes';
	@override String get premade_color_schemes_desc => 'Use premade color schemes to customize the look and feel of your app.';
	@override String get radius => 'Radius';
	@override String get radius_desc => 'Change the radius to customize how round your app looks.';
	@override String get scaling => 'Scaling';
	@override String get scaling_desc => 'Change scaling to customize the scale of coui_flutter components.';
	@override String get scaling_alert => 'Does not scale the entire app; only affects coui_flutter components.';
	@override String get surface_opacity => 'Surface Opacity';
	@override String get surface_opacity_desc => 'Change surface opacity to customize the opacity of surfaces.';
	@override String get surface_blur => 'Surface Blur';
	@override String get surface_blur_desc => 'Change surface blur to customize the blur of surfaces.';
	@override String get code => 'Code';
	@override String get code_desc => 'Use the following code to apply the color scheme.';
}

// Path: docs.pages.typography
class _TranslationsDocsPagesTypographyEn extends TranslationsDocsPagesTypographyKo {
	_TranslationsDocsPagesTypographyEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Typography';
	@override String get description => 'Text styles';
}

// Path: docs.pages.layout
class _TranslationsDocsPagesLayoutEn extends TranslationsDocsPagesLayoutKo {
	_TranslationsDocsPagesLayoutEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Layout';
	@override String get description => 'Organizing page layout';
	@override String get padding => 'Padding';
	@override String get margin => 'Margin';
	@override String get center => 'Center';
	@override String get gapped_column => 'Gapped Column';
	@override String get gapped_row => 'Gapped Row';
	@override String get separated_column => 'Separated Column';
	@override String get separated_row => 'Separated Row';
	@override String get basic_layout => 'Basic Layout';
}

// Path: docs.pages.web_preloader
class _TranslationsDocsPagesWebPreloaderEn extends TranslationsDocsPagesWebPreloaderKo {
	_TranslationsDocsPagesWebPreloaderEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Web Preloader';
	@override String get description => 'Web loading screen';
}

// Path: docs.pages.components_list
class _TranslationsDocsPagesComponentsListEn extends TranslationsDocsPagesComponentsListKo {
	_TranslationsDocsPagesComponentsListEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Components';
	@override String get description => 'List of reusable components';
}

// Path: docs.pages.icons
class _TranslationsDocsPagesIconsEn extends TranslationsDocsPagesIconsKo {
	_TranslationsDocsPagesIconsEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Icons';
	@override String get description => 'Icon system';
	@override String get use_this_code => 'Use the following code to display this icon:';
	@override String get search_icons => 'Search Icons';
	@override String get radix_icons => 'Radix Icons';
	@override String get bootstrap_icons => 'Bootstrap Icons';
	@override String get lucide_icons => 'Lucide Icons';
	@override String get hero_icons => 'Hero Icons';
}

// Path: docs.pages.colors
class _TranslationsDocsPagesColorsEn extends TranslationsDocsPagesColorsKo {
	_TranslationsDocsPagesColorsEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Colors';
	@override String get description => 'Color palette';
	@override String get use_this_code => 'Use the following code to display this color:';
	@override String get color_and_colorshades => 'Color and ColorShades/ColorSwatch Constants';
	@override String get predefined_colors => 'Predefined Colors';
	@override String get generate_color => 'Generate Color';
	@override String get hue_shift => 'Hue Shift';
	@override String get saturation_step_up => 'Saturation Step Up';
	@override String get saturation_step_down => 'Saturation Step Down';
	@override String get lightness_step_up => 'Lightness Step Up';
	@override String get lightness_step_down => 'Lightness Step Down';
	@override String get cancel => 'Cancel';
	@override String get reset_options => 'Reset Options';
	@override String get reset_confirmation => 'Would you like to reset the options?';
}

// Path: docs.pages.external
class _TranslationsDocsPagesExternalEn extends TranslationsDocsPagesExternalKo {
	_TranslationsDocsPagesExternalEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Material/Cupertino';
	@override String get description => 'Flutter\'s basic widgets';
}

// Path: docs.pages.state
class _TranslationsDocsPagesStateEn extends TranslationsDocsPagesStateKo {
	_TranslationsDocsPagesStateEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'State Management';
	@override String get description => 'State management patterns';
}

// Path: docs.components.accordion
class _TranslationsDocsComponentsAccordionEn extends TranslationsDocsComponentsAccordionKo {
	_TranslationsDocsComponentsAccordionEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Accordion';
	@override String get description => 'An accordion is a list of items stacked vertically. You can \'expand\' or \'collapse\' each item to reveal content related to that item.';
	@override late final _TranslationsDocsComponentsAccordionExamplesEn examples = _TranslationsDocsComponentsAccordionExamplesEn._(_root);
}

// Path: docs.components.alert
class _TranslationsDocsComponentsAlertEn extends TranslationsDocsComponentsAlertKo {
	_TranslationsDocsComponentsAlertEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Alert';
	@override String get description => 'Alerts are used to convey a state that affects the system.';
	@override late final _TranslationsDocsComponentsAlertExamplesEn examples = _TranslationsDocsComponentsAlertExamplesEn._(_root);
	@override String get title => 'Alert Title';
	@override String get content => 'This is the alert content.';
}

// Path: docs.components.empty_state
class _TranslationsDocsComponentsEmptyStateEn extends TranslationsDocsComponentsEmptyStateKo {
	_TranslationsDocsComponentsEmptyStateEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Empty State';
	@override String get description => 'A component that displays a message and optional action when there is no content to show.';
	@override late final _TranslationsDocsComponentsEmptyStateExamplesEn examples = _TranslationsDocsComponentsEmptyStateExamplesEn._(_root);
	@override String get no_data => 'No data available';
	@override String get no_data_description => 'There is no data to display yet.';
	@override String get no_results => 'No results found';
	@override String get no_results_description => 'Try adjusting your search criteria.';
	@override String get no_files => 'No files';
	@override String get no_files_description => 'Upload files to get started.';
	@override String get upload_files => 'Upload Files';
}

// Path: docs.components.fade_scroll
class _TranslationsDocsComponentsFadeScrollEn extends TranslationsDocsComponentsFadeScrollKo {
	_TranslationsDocsComponentsFadeScrollEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Fade Scroll';
	@override String get description => 'Applies a fade effect to the edges of scrollable content to visually indicate more content is available.';
	@override late final _TranslationsDocsComponentsFadeScrollExamplesEn examples = _TranslationsDocsComponentsFadeScrollExamplesEn._(_root);
}

// Path: docs.components.validation_badge
class _TranslationsDocsComponentsValidationBadgeEn extends TranslationsDocsComponentsValidationBadgeKo {
	_TranslationsDocsComponentsValidationBadgeEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Validation Badge';
	@override String get description => 'A badge component that visually displays form field validation results.';
	@override late final _TranslationsDocsComponentsValidationBadgeExamplesEn examples = _TranslationsDocsComponentsValidationBadgeExamplesEn._(_root);
	@override String get valid_label => 'Valid';
	@override String get invalid_label => 'Invalid';
	@override String get pending_label => 'Pending';
	@override String get min_length => 'Min 8 characters';
	@override String get has_number => 'Has number';
	@override String get has_special => 'Has special character';
	@override String get extra_small => 'Extra Small';
	@override String get small => 'Small';
	@override String get medium => 'Medium';
}

// Path: docs.components.banner
class _TranslationsDocsComponentsBannerEn extends TranslationsDocsComponentsBannerKo {
	_TranslationsDocsComponentsBannerEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Banner';
	@override String get description => 'A banner displays prominent messages for important announcements or system alerts that require user attention.';
	@override late final _TranslationsDocsComponentsBannerExamplesEn examples = _TranslationsDocsComponentsBannerExamplesEn._(_root);
	@override String get content => 'This is an important banner message.';
}

// Path: docs.components.alert_dialog
class _TranslationsDocsComponentsAlertDialogEn extends TranslationsDocsComponentsAlertDialogKo {
	_TranslationsDocsComponentsAlertDialogEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Alert Dialog';
	@override String get description => 'An alert dialog displays important information that needs user attention.';
	@override late final _TranslationsDocsComponentsAlertDialogExamplesEn examples = _TranslationsDocsComponentsAlertDialogExamplesEn._(_root);
	@override String get click_here => 'Click here';
	@override String get alert_title => 'Alert Title';
	@override String get alert_content => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
}

// Path: docs.components.animated_value_builder
class _TranslationsDocsComponentsAnimatedValueBuilderEn extends TranslationsDocsComponentsAnimatedValueBuilderKo {
	_TranslationsDocsComponentsAnimatedValueBuilderEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Animated Value Builder';
	@override String get description => 'A builder that automatically applies animation when the value changes.';
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderExamplesEn examples = _TranslationsDocsComponentsAnimatedValueBuilderExamplesEn._(_root);
}

// Path: docs.components.app_bar
class _TranslationsDocsComponentsAppBarEn extends TranslationsDocsComponentsAppBarKo {
	_TranslationsDocsComponentsAppBarEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'App Bar';
	@override String get description => 'The app bar is a fundamental navigation element displayed at the top of the app.';
	@override late final _TranslationsDocsComponentsAppBarExamplesEn examples = _TranslationsDocsComponentsAppBarExamplesEn._(_root);
}

// Path: docs.components.fab
class _TranslationsDocsComponentsFabEn extends TranslationsDocsComponentsFabKo {
	_TranslationsDocsComponentsFabEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'FAB';
	@override String get description => 'A floating action button for quick primary actions. Optionally supports the speed dial pattern with expandable actions.';
	@override late final _TranslationsDocsComponentsFabExamplesEn examples = _TranslationsDocsComponentsFabExamplesEn._(_root);
	@override String get edit => 'Edit';
	@override String get share => 'Share';
	@override String get delete => 'Delete';
}

// Path: docs.components.hover
class _TranslationsDocsComponentsHoverEn extends TranslationsDocsComponentsHoverKo {
	_TranslationsDocsComponentsHoverEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Hover';
	@override String get description => 'A utility widget that tracks mouse cursor hover state. Makes it easy to implement hover effects.';
	@override late final _TranslationsDocsComponentsHoverExamplesEn examples = _TranslationsDocsComponentsHoverExamplesEn._(_root);
	@override String get hovered => 'Hovered';
	@override String get not_hovered => 'Not hovered';
	@override String get active => 'Active';
	@override String get inactive => 'Inactive';
}

// Path: docs.components.scrollbar
class _TranslationsDocsComponentsScrollbarEn extends TranslationsDocsComponentsScrollbarKo {
	_TranslationsDocsComponentsScrollbarEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Scrollbar';
	@override String get description => 'Displays a custom scrollbar for scrollable content.';
	@override late final _TranslationsDocsComponentsScrollbarExamplesEn examples = _TranslationsDocsComponentsScrollbarExamplesEn._(_root);
}

// Path: docs.components.autocomplete
class _TranslationsDocsComponentsAutocompleteEn extends TranslationsDocsComponentsAutocompleteKo {
	_TranslationsDocsComponentsAutocompleteEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Autocomplete';
	@override String get description => 'An input field that displays suggestions based on user input.';
	@override late final _TranslationsDocsComponentsAutocompleteExamplesEn examples = _TranslationsDocsComponentsAutocompleteExamplesEn._(_root);
}

// Path: docs.components.avatar
class _TranslationsDocsComponentsAvatarEn extends TranslationsDocsComponentsAvatarKo {
	_TranslationsDocsComponentsAvatarEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Avatar';
	@override String get description => 'An image or icon representing a user or entity.';
	@override late final _TranslationsDocsComponentsAvatarExamplesEn examples = _TranslationsDocsComponentsAvatarExamplesEn._(_root);
}

// Path: docs.components.avatar_group
class _TranslationsDocsComponentsAvatarGroupEn extends TranslationsDocsComponentsAvatarGroupKo {
	_TranslationsDocsComponentsAvatarGroupEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Avatar Group';
	@override String get description => 'Displays multiple avatars together.';
	@override late final _TranslationsDocsComponentsAvatarGroupExamplesEn examples = _TranslationsDocsComponentsAvatarGroupExamplesEn._(_root);
}

// Path: docs.components.badge
class _TranslationsDocsComponentsBadgeEn extends TranslationsDocsComponentsBadgeKo {
	_TranslationsDocsComponentsBadgeEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Badge';
	@override String get description => 'A small label that indicates a status or notification count.';
	@override late final _TranslationsDocsComponentsBadgeExamplesEn examples = _TranslationsDocsComponentsBadgeExamplesEn._(_root);
	@override String get primary => 'Primary';
	@override String get secondary => 'Secondary';
	@override String get outline => 'Outline';
	@override String get destructive => 'Destructive';
}

// Path: docs.components.breadcrumb
class _TranslationsDocsComponentsBreadcrumbEn extends TranslationsDocsComponentsBreadcrumbKo {
	_TranslationsDocsComponentsBreadcrumbEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Breadcrumb';
	@override String get description => 'Breadcrumbs are a secondary navigation scheme that indicates a user\'s location within a website or web application.';
	@override late final _TranslationsDocsComponentsBreadcrumbExamplesEn examples = _TranslationsDocsComponentsBreadcrumbExamplesEn._(_root);
	@override String get home => 'Home';
	@override String get components => 'Components';
}

// Path: docs.components.button
class _TranslationsDocsComponentsButtonEn extends TranslationsDocsComponentsButtonKo {
	_TranslationsDocsComponentsButtonEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Button';
	@override String get description => 'Buttons allow users to perform an action or make a selection with a single tap.';
	@override late final _TranslationsDocsComponentsButtonExamplesEn examples = _TranslationsDocsComponentsButtonExamplesEn._(_root);
	@override String get primary => 'Primary';
	@override String get secondary => 'Secondary';
	@override String get outlined => 'Outlined';
	@override String get ghost => 'Ghost';
	@override String get destructive => 'Destructive';
	@override String get link => 'Link';
	@override String get outline => 'Outline';
	@override String get text => 'Text';
	@override String get extra_small => 'Extra Small';
	@override String get small => 'Small';
	@override String get normal => 'Normal';
	@override String get large => 'Large';
	@override String get extra_large => 'Extra Large';
	@override String get save => 'Save';
	@override String get cancel => 'Cancel';
	@override String get close => 'Close';
	@override String get submit => 'Submit';
	@override String get edit_profile => 'Edit Profile';
	@override String get save_changes => 'Save Changes';
	@override String get undo => 'Undo';
	@override String get compact => 'Compact';
	@override String get dense => 'Dense';
	@override String get comfortable => 'Comfortable';
	@override String get icon => 'Icon';
	@override String get icon_comfortable => 'Icon Comfortable';
	@override String get rectangle => 'Rectangle';
	@override String get add => 'Add';
	@override String get focused => 'Focused';
	@override String get hovered => 'Hovered';
	@override String get pressed => 'Pressed';
	@override String get text_button => 'Text Button';
	@override String get custom_button => 'Custom Button';
}

// Path: docs.components.calendar
class _TranslationsDocsComponentsCalendarEn extends TranslationsDocsComponentsCalendarKo {
	_TranslationsDocsComponentsCalendarEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Calendar';
	@override String get description => 'A calendar component for selecting and displaying dates.';
	@override late final _TranslationsDocsComponentsCalendarExamplesEn examples = _TranslationsDocsComponentsCalendarExamplesEn._(_root);
}

// Path: docs.components.card
class _TranslationsDocsComponentsCardEn extends TranslationsDocsComponentsCardKo {
	_TranslationsDocsComponentsCardEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Card';
	@override String get description => 'Description';
	@override late final _TranslationsDocsComponentsCardExamplesEn examples = _TranslationsDocsComponentsCardExamplesEn._(_root);
	@override String get create_project => 'Create Project';
	@override String get deploy_description => 'Deploy a new project with one click';
	@override String get name => 'Name';
	@override String get name_placeholder => 'Project Name';
	@override String get description_placeholder => 'Project Description';
	@override String get deploy => 'Deploy';
}

// Path: docs.components.card_image
class _TranslationsDocsComponentsCardImageEn extends TranslationsDocsComponentsCardImageKo {
	_TranslationsDocsComponentsCardImageEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Image Card';
	@override String get description => 'A card component with an image.';
	@override late final _TranslationsDocsComponentsCardImageExamplesEn examples = _TranslationsDocsComponentsCardImageExamplesEn._(_root);
	@override String get card_image_title => 'Card Image';
	@override String get card_clicked => 'Card image clicked';
	@override String card_number({required Object n}) => 'Card Number ${n}';
	@override String get lorem_ipsum => 'Lorem ipsum dolor sit amet';
}

// Path: docs.components.carousel
class _TranslationsDocsComponentsCarouselEn extends TranslationsDocsComponentsCarouselKo {
	_TranslationsDocsComponentsCarouselEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Carousel';
	@override String get description => 'A component that displays multiple items in a sliding manner.';
	@override late final _TranslationsDocsComponentsCarouselExamplesEn examples = _TranslationsDocsComponentsCarouselExamplesEn._(_root);
}

// Path: docs.components.checkbox
class _TranslationsDocsComponentsCheckboxEn extends TranslationsDocsComponentsCheckboxKo {
	_TranslationsDocsComponentsCheckboxEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Checkbox';
	@override String get description => 'Checkboxes allow users to select one or more items from a list.';
	@override late final _TranslationsDocsComponentsCheckboxExamplesEn examples = _TranslationsDocsComponentsCheckboxExamplesEn._(_root);
	@override String get remember_me => 'Remember Me';
}

// Path: docs.components.chip
class _TranslationsDocsComponentsChipEn extends TranslationsDocsComponentsChipKo {
	_TranslationsDocsComponentsChipEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Chip';
	@override String get description => 'A chip represents an attribute, option, or action.';
	@override late final _TranslationsDocsComponentsChipExamplesEn examples = _TranslationsDocsComponentsChipExamplesEn._(_root);
	@override String get apple => 'Apple';
	@override String get banana => 'Banana';
	@override String get cherry => 'Cherry';
	@override String get durian => 'Durian';
	@override String get elderberry => 'Elderberry';
}

// Path: docs.components.chip_input
class _TranslationsDocsComponentsChipInputEn extends TranslationsDocsComponentsChipInputKo {
	_TranslationsDocsComponentsChipInputEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Chip Input';
	@override String get description => 'An input field for entering multiple values in chip form.';
	@override late final _TranslationsDocsComponentsChipInputExamplesEn examples = _TranslationsDocsComponentsChipInputExamplesEn._(_root);
}

// Path: docs.components.circular_progress
class _TranslationsDocsComponentsCircularProgressEn extends TranslationsDocsComponentsCircularProgressKo {
	_TranslationsDocsComponentsCircularProgressEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Circular Progress';
	@override String get description => 'A circular progress indicator.';
	@override late final _TranslationsDocsComponentsCircularProgressExamplesEn examples = _TranslationsDocsComponentsCircularProgressExamplesEn._(_root);
	@override String get increase_by_10 => 'Increase by 10';
	@override String get decrease_by_10 => 'Decrease by 10';
}

// Path: docs.components.code_snippet
class _TranslationsDocsComponentsCodeSnippetEn extends TranslationsDocsComponentsCodeSnippetKo {
	_TranslationsDocsComponentsCodeSnippetEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Code Snippet';
	@override String get description => 'A component for displaying code.';
	@override late final _TranslationsDocsComponentsCodeSnippetExamplesEn examples = _TranslationsDocsComponentsCodeSnippetExamplesEn._(_root);
}

// Path: docs.components.collapsible
class _TranslationsDocsComponentsCollapsibleEn extends TranslationsDocsComponentsCollapsibleKo {
	_TranslationsDocsComponentsCollapsibleEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Collapsible';
	@override String get description => 'A content container that can be collapsed or expanded.';
	@override late final _TranslationsDocsComponentsCollapsibleExamplesEn examples = _TranslationsDocsComponentsCollapsibleExamplesEn._(_root);
	@override String get starred_repositories => '@coco-de starred 3 repositories';
	@override String get collapse_all => 'Collapse All';
	@override String get expand_all => 'Expand All';
	@override String get expand_icon => 'Expand Icon';
	@override String get use_path_branch => 'Use Path Branch';
	@override String get recursive_selection => 'Recursive Selection';
}

// Path: docs.components.color_picker
class _TranslationsDocsComponentsColorPickerEn extends TranslationsDocsComponentsColorPickerKo {
	_TranslationsDocsComponentsColorPickerEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Color Picker';
	@override String get description => 'A component for selecting colors.';
	@override late final _TranslationsDocsComponentsColorPickerExamplesEn examples = _TranslationsDocsComponentsColorPickerExamplesEn._(_root);
	@override String get pick_color => 'Pick Color';
	@override String color_label({required Object color}) => 'Color: ${color}';
	@override String get select_color => 'Select Color';
	@override String get open_color_picker_popover => 'Open Color Picker Popover';
	@override String get open_color_picker_dialog => 'Open Color Picker Dialog';
}

// Path: docs.components.command
class _TranslationsDocsComponentsCommandEn extends TranslationsDocsComponentsCommandKo {
	_TranslationsDocsComponentsCommandEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Command';
	@override String get description => 'The command component allows searching for items.';
	@override late final _TranslationsDocsComponentsCommandExamplesEn examples = _TranslationsDocsComponentsCommandExamplesEn._(_root);
}

// Path: docs.components.context_menu
class _TranslationsDocsComponentsContextMenuEn extends TranslationsDocsComponentsContextMenuKo {
	_TranslationsDocsComponentsContextMenuEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Context Menu';
	@override String get description => 'A menu that appears on right-click or long press.';
	@override late final _TranslationsDocsComponentsContextMenuExamplesEn examples = _TranslationsDocsComponentsContextMenuExamplesEn._(_root);
}

// Path: docs.components.date_picker
class _TranslationsDocsComponentsDatePickerEn extends TranslationsDocsComponentsDatePickerKo {
	_TranslationsDocsComponentsDatePickerEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Date Picker';
	@override String get description => 'An input field for selecting a date.';
	@override late final _TranslationsDocsComponentsDatePickerExamplesEn examples = _TranslationsDocsComponentsDatePickerExamplesEn._(_root);
	@override String get select_date => 'Select Date';
	@override String get select_date_range => 'Select Date Range';
}

// Path: docs.components.dialog
class _TranslationsDocsComponentsDialogEn extends TranslationsDocsComponentsDialogKo {
	_TranslationsDocsComponentsDialogEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Dialog';
	@override String get description => 'A dialog is a modal window that overlays the rest of the app.';
	@override late final _TranslationsDocsComponentsDialogExamplesEn examples = _TranslationsDocsComponentsDialogExamplesEn._(_root);
	@override String get edit_profile_title => 'Edit Profile';
	@override String get edit_profile_description => 'Change your profile here. Click save when done.';
	@override String get name_label => 'Name';
	@override String get username_label => 'Username';
	@override String get hello => 'Hello';
	@override String get material_dialog_content => 'This is a Material Dialog';
	@override String get cupertino_dialog_content => 'This is a Cupertino Dialog';
	@override String get alert_title => 'Alert Title';
	@override String get click_here => 'Click here';
	@override String get ok => 'OK';
	@override String get open_material_dialog => 'Open Material Dialog';
	@override String get open_cupertino_dialog => 'Open Cupertino Dialog';
	@override String get open_coui_dialog => 'Open COUI Dialog';
}

// Path: docs.components.divider
class _TranslationsDocsComponentsDividerEn extends TranslationsDocsComponentsDividerKo {
	_TranslationsDocsComponentsDividerEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Divider';
	@override String get description => 'A line that visually separates content.';
	@override late final _TranslationsDocsComponentsDividerExamplesEn examples = _TranslationsDocsComponentsDividerExamplesEn._(_root);
	@override String get item_1 => 'Item 1';
	@override String get item_2 => 'Item 2';
	@override String get item_3 => 'Item 3';
	@override String get divider => 'Divider';
}

// Path: docs.components.dot_indicator
class _TranslationsDocsComponentsDotIndicatorEn extends TranslationsDocsComponentsDotIndicatorKo {
	_TranslationsDocsComponentsDotIndicatorEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Dot Indicator';
	@override String get description => 'An indicator that shows the current position with dots.';
	@override late final _TranslationsDocsComponentsDotIndicatorExamplesEn examples = _TranslationsDocsComponentsDotIndicatorExamplesEn._(_root);
}

// Path: docs.components.drawer
class _TranslationsDocsComponentsDrawerEn extends TranslationsDocsComponentsDrawerKo {
	_TranslationsDocsComponentsDrawerEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Drawer';
	@override String get description => 'A panel that slides in from the edge of the screen.';
	@override late final _TranslationsDocsComponentsDrawerExamplesEn examples = _TranslationsDocsComponentsDrawerExamplesEn._(_root);
	@override String get open_drawer => 'Open Drawer';
	@override String get close_drawer => 'Close Drawer';
	@override String get open_another_drawer => 'Open Another Drawer';
	@override String drawer_at({required Object count, required Object position}) => 'Drawer ${count} at ${position}';
}

// Path: docs.components.dropdown_menu
class _TranslationsDocsComponentsDropdownMenuEn extends TranslationsDocsComponentsDropdownMenuKo {
	_TranslationsDocsComponentsDropdownMenuEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Dropdown Menu';
	@override String get description => 'A menu that displays a list of selectable options.';
	@override late final _TranslationsDocsComponentsDropdownMenuExamplesEn examples = _TranslationsDocsComponentsDropdownMenuExamplesEn._(_root);
}

// Path: docs.components.expandable_sidebar
class _TranslationsDocsComponentsExpandableSidebarEn extends TranslationsDocsComponentsExpandableSidebarKo {
	_TranslationsDocsComponentsExpandableSidebarEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Expandable Sidebar';
	@override String get description => 'A sidebar that can be expanded and collapsed.';
	@override late final _TranslationsDocsComponentsExpandableSidebarExamplesEn examples = _TranslationsDocsComponentsExpandableSidebarExamplesEn._(_root);
}

// Path: docs.components.form
class _TranslationsDocsComponentsFormEn extends TranslationsDocsComponentsFormKo {
	_TranslationsDocsComponentsFormEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Form';
	@override String get description => 'A helper widget for easily creating form validation.';
	@override late final _TranslationsDocsComponentsFormExamplesEn examples = _TranslationsDocsComponentsFormExamplesEn._(_root);
	@override String get username_label => 'Username';
	@override String get username_hint => 'The name displayed publicly';
	@override String get password_label => 'Password';
	@override String get confirm_password_label => 'Confirm Password';
	@override String get passwords_do_not_match => 'Passwords do not match';
	@override String get agree_terms => 'I agree to the terms and conditions';
	@override String get must_agree_terms => 'You must agree to the terms and conditions';
	@override String get form_values_title => 'Form Values';
	@override String get register => 'Register';
	@override String get username_already_taken => 'Username already taken';
	@override String get email => 'Email';
	@override String username_display({required Object value}) => 'Username: ${value}';
	@override String password_display({required Object value}) => 'Password: ${value}';
	@override String confirm_password_display({required Object value}) => 'Confirm Password: ${value}';
	@override String agree_display({required Object value}) => 'Agree: ${value}';
	@override String json_display({required Object value}) => 'JSON: ${value}';
	@override String submitted_value_display({required Object value}) => 'Submitted Value: ${value}';
	@override String get login => 'Login';
	@override String get sign_up => 'Sign Up';
	@override String get dont_have_account => 'Don\'t have an account?';
	@override String get already_have_account => 'Already have an account?';
}

// Path: docs.components.formatted_input
class _TranslationsDocsComponentsFormattedInputEn extends TranslationsDocsComponentsFormattedInputKo {
	_TranslationsDocsComponentsFormattedInputEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Formatted Input';
	@override String get description => 'A text field that receives input in a specific format.';
	@override late final _TranslationsDocsComponentsFormattedInputExamplesEn examples = _TranslationsDocsComponentsFormattedInputExamplesEn._(_root);
}

// Path: docs.components.hover_card
class _TranslationsDocsComponentsHoverCardEn extends TranslationsDocsComponentsHoverCardKo {
	_TranslationsDocsComponentsHoverCardEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Hover Card';
	@override String get description => 'A card that appears on hover.';
	@override late final _TranslationsDocsComponentsHoverCardExamplesEn examples = _TranslationsDocsComponentsHoverCardExamplesEn._(_root);
	@override String get flutter_handle => '@flutter';
	@override String get flutter_username => 'Flutter';
	@override String get flutter_description => 'The Flutter SDK provides tools to build beautiful apps for mobile, web, and desktop from a single codebase.';
}

// Path: docs.components.input
class _TranslationsDocsComponentsInputEn extends TranslationsDocsComponentsInputKo {
	_TranslationsDocsComponentsInputEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Input';
	@override String get description => 'A text input field.';
	@override late final _TranslationsDocsComponentsInputExamplesEn examples = _TranslationsDocsComponentsInputExamplesEn._(_root);
	@override String get enter_name => 'Enter your name';
	@override String get enter_username => 'Enter your username';
	@override String get username_already_taken => 'Username already taken';
	@override String get hello_world => 'Hello World!';
	@override String get search_something => 'Type to search...';
	@override String get email => 'Email';
	@override String get password => 'Enter Password';
	@override String get username_hint => 'Enter your username';
}

// Path: docs.components.input_otp
class _TranslationsDocsComponentsInputOtpEn extends TranslationsDocsComponentsInputOtpKo {
	_TranslationsDocsComponentsInputOtpEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'OTP Input';
	@override String get description => 'A field for entering a one-time password.';
	@override late final _TranslationsDocsComponentsInputOtpExamplesEn examples = _TranslationsDocsComponentsInputOtpExamplesEn._(_root);
}

// Path: docs.components.item_picker
class _TranslationsDocsComponentsItemPickerEn extends TranslationsDocsComponentsItemPickerKo {
	_TranslationsDocsComponentsItemPickerEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Item Picker';
	@override String get description => 'A component that allows selecting an item from a list.';
	@override late final _TranslationsDocsComponentsItemPickerExamplesEn examples = _TranslationsDocsComponentsItemPickerExamplesEn._(_root);
}

// Path: docs.components.keyboard_display
class _TranslationsDocsComponentsKeyboardDisplayEn extends TranslationsDocsComponentsKeyboardDisplayKo {
	_TranslationsDocsComponentsKeyboardDisplayEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Keyboard Display';
	@override String get description => 'A component that displays keyboard shortcuts.';
	@override late final _TranslationsDocsComponentsKeyboardDisplayExamplesEn examples = _TranslationsDocsComponentsKeyboardDisplayExamplesEn._(_root);
}

// Path: docs.components.linear_progress
class _TranslationsDocsComponentsLinearProgressEn extends TranslationsDocsComponentsLinearProgressKo {
	_TranslationsDocsComponentsLinearProgressEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Linear Progress';
	@override String get description => 'A linear progress indicator.';
	@override late final _TranslationsDocsComponentsLinearProgressExamplesEn examples = _TranslationsDocsComponentsLinearProgressExamplesEn._(_root);
	@override String get increase => 'Increase';
	@override String get decrease => 'Decrease';
}

// Path: docs.components.material
class _TranslationsDocsComponentsMaterialEn extends TranslationsDocsComponentsMaterialKo {
	_TranslationsDocsComponentsMaterialEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Material/Cupertino';
	@override String get description => 'Using Flutter\'s basic Material and Cupertino widgets.';
	@override late final _TranslationsDocsComponentsMaterialExamplesEn examples = _TranslationsDocsComponentsMaterialExamplesEn._(_root);
	@override String get my_material_app => 'My Material App';
	@override String get my_cupertino_app => 'My Cupertino App';
	@override String you_pushed_button({required Object count}) => 'You pushed the button ${count} times';
	@override String get open_material_dialog => 'Open Material Dialog';
	@override String get open_cupertino_dialog => 'Open Cupertino Dialog';
	@override String get open_coui_dialog => 'Open COUI Dialog';
}

// Path: docs.components.menubar
class _TranslationsDocsComponentsMenubarEn extends TranslationsDocsComponentsMenubarKo {
	_TranslationsDocsComponentsMenubarEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Menu Bar';
	@override String get description => 'A horizontal menu bar.';
	@override late final _TranslationsDocsComponentsMenubarExamplesEn examples = _TranslationsDocsComponentsMenubarExamplesEn._(_root);
	@override String get file => 'File';
	@override String get edit => 'Edit';
	@override String get new_tab => 'New Tab';
	@override String get new_window => 'New Window';
	@override String get new_incognito_window => 'New Incognito Window';
	@override String get email_link => 'Email Link';
	@override String get messages => 'Messages';
	@override String get notes => 'Notes';
	@override String get share => 'Share';
	@override String get print => 'Print';
	@override String get save_and_exit => 'Save and Exit';
	@override String get discard_and_exit => 'Discard and Exit';
	@override String get exit => 'Exit';
	@override String get undo => 'Undo';
	@override String get redo => 'Redo';
}

// Path: docs.components.multiselect
class _TranslationsDocsComponentsMultiselectEn extends TranslationsDocsComponentsMultiselectKo {
	_TranslationsDocsComponentsMultiselectEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Multi Select';
	@override String get description => 'A component that allows selecting multiple items.';
	@override late final _TranslationsDocsComponentsMultiselectExamplesEn examples = _TranslationsDocsComponentsMultiselectExamplesEn._(_root);
}

// Path: docs.components.navigation_bar
class _TranslationsDocsComponentsNavigationBarEn extends TranslationsDocsComponentsNavigationBarKo {
	_TranslationsDocsComponentsNavigationBarEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Navigation Bar';
	@override String get description => 'A bottom navigation bar.';
	@override late final _TranslationsDocsComponentsNavigationBarExamplesEn examples = _TranslationsDocsComponentsNavigationBarExamplesEn._(_root);
}

// Path: docs.components.navigation_menu
class _TranslationsDocsComponentsNavigationMenuEn extends TranslationsDocsComponentsNavigationMenuKo {
	_TranslationsDocsComponentsNavigationMenuEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Navigation Menu';
	@override String get description => 'A navigation menu component.';
	@override late final _TranslationsDocsComponentsNavigationMenuExamplesEn examples = _TranslationsDocsComponentsNavigationMenuExamplesEn._(_root);
}

// Path: docs.components.navigation_rail
class _TranslationsDocsComponentsNavigationRailEn extends TranslationsDocsComponentsNavigationRailKo {
	_TranslationsDocsComponentsNavigationRailEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Navigation Rail';
	@override String get description => 'A side navigation rail.';
	@override late final _TranslationsDocsComponentsNavigationRailExamplesEn examples = _TranslationsDocsComponentsNavigationRailExamplesEn._(_root);
}

// Path: docs.components.navigation_sidebar
class _TranslationsDocsComponentsNavigationSidebarEn extends TranslationsDocsComponentsNavigationSidebarKo {
	_TranslationsDocsComponentsNavigationSidebarEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Navigation Sidebar';
	@override String get description => 'A navigation sidebar component.';
	@override late final _TranslationsDocsComponentsNavigationSidebarExamplesEn examples = _TranslationsDocsComponentsNavigationSidebarExamplesEn._(_root);
}

// Path: docs.components.number_input
class _TranslationsDocsComponentsNumberInputEn extends TranslationsDocsComponentsNumberInputKo {
	_TranslationsDocsComponentsNumberInputEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Number Input';
	@override String get description => 'A field for entering numbers.';
	@override late final _TranslationsDocsComponentsNumberInputExamplesEn examples = _TranslationsDocsComponentsNumberInputExamplesEn._(_root);
	@override String value({required Object value}) => 'Value: ${value}';
}

// Path: docs.components.number_ticker
class _TranslationsDocsComponentsNumberTickerEn extends TranslationsDocsComponentsNumberTickerKo {
	_TranslationsDocsComponentsNumberTickerEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Number Ticker';
	@override String get description => 'Shows an animation when the number changes.';
	@override late final _TranslationsDocsComponentsNumberTickerExamplesEn examples = _TranslationsDocsComponentsNumberTickerExamplesEn._(_root);
}

// Path: docs.components.overflow_marquee
class _TranslationsDocsComponentsOverflowMarqueeEn extends TranslationsDocsComponentsOverflowMarqueeKo {
	_TranslationsDocsComponentsOverflowMarqueeEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Overflow Marquee';
	@override String get description => 'Automatically scrolls when text overflows.';
	@override late final _TranslationsDocsComponentsOverflowMarqueeExamplesEn examples = _TranslationsDocsComponentsOverflowMarqueeExamplesEn._(_root);
}

// Path: docs.components.pagination
class _TranslationsDocsComponentsPaginationEn extends TranslationsDocsComponentsPaginationKo {
	_TranslationsDocsComponentsPaginationEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Pagination';
	@override String get description => 'A component for navigating pages.';
	@override late final _TranslationsDocsComponentsPaginationExamplesEn examples = _TranslationsDocsComponentsPaginationExamplesEn._(_root);
}

// Path: docs.components.phone_input
class _TranslationsDocsComponentsPhoneInputEn extends TranslationsDocsComponentsPhoneInputKo {
	_TranslationsDocsComponentsPhoneInputEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Phone Number Input';
	@override String get description => 'A field for entering a phone number.';
	@override late final _TranslationsDocsComponentsPhoneInputExamplesEn examples = _TranslationsDocsComponentsPhoneInputExamplesEn._(_root);
}

// Path: docs.components.popover
class _TranslationsDocsComponentsPopoverEn extends TranslationsDocsComponentsPopoverKo {
	_TranslationsDocsComponentsPopoverEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Popover';
	@override String get description => 'A popup displayed over an element.';
	@override late final _TranslationsDocsComponentsPopoverExamplesEn examples = _TranslationsDocsComponentsPopoverExamplesEn._(_root);
	@override String get dimensions => 'Dimensions';
	@override String get set_dimensions => 'Set the size of the layer';
	@override String get width => 'Width';
	@override String get max_width => 'Max Width';
	@override String get height => 'Height';
	@override String get max_height => 'Max Height';
	@override String get open_popover => 'Open Popover';
	@override String get submit => 'Submit';
}

// Path: docs.components.progress
class _TranslationsDocsComponentsProgressEn extends TranslationsDocsComponentsProgressKo {
	_TranslationsDocsComponentsProgressEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Progress';
	@override String get description => 'Displays the progress state.';
	@override late final _TranslationsDocsComponentsProgressExamplesEn examples = _TranslationsDocsComponentsProgressExamplesEn._(_root);
}

// Path: docs.components.radio_card
class _TranslationsDocsComponentsRadioCardEn extends TranslationsDocsComponentsRadioCardKo {
	_TranslationsDocsComponentsRadioCardEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Radio Card';
	@override String get description => 'A radio button in card form.';
	@override late final _TranslationsDocsComponentsRadioCardExamplesEn examples = _TranslationsDocsComponentsRadioCardExamplesEn._(_root);
}

// Path: docs.components.radio_group
class _TranslationsDocsComponentsRadioGroupEn extends TranslationsDocsComponentsRadioGroupKo {
	_TranslationsDocsComponentsRadioGroupEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Radio Group';
	@override String get description => 'A group of radio buttons.';
	@override late final _TranslationsDocsComponentsRadioGroupExamplesEn examples = _TranslationsDocsComponentsRadioGroupExamplesEn._(_root);
	@override String get option_1 => 'Option 1';
	@override String get option_2 => 'Option 2';
	@override String get option_3 => 'Option 3';
	@override String get selected => 'Selected';
}

// Path: docs.components.refresh_trigger
class _TranslationsDocsComponentsRefreshTriggerEn extends TranslationsDocsComponentsRefreshTriggerKo {
	_TranslationsDocsComponentsRefreshTriggerEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Refresh Trigger';
	@override String get description => 'Provides pull-to-refresh functionality.';
	@override late final _TranslationsDocsComponentsRefreshTriggerExamplesEn examples = _TranslationsDocsComponentsRefreshTriggerExamplesEn._(_root);
	@override String get pull_me => 'Pull me';
	@override String get refresh => 'Refresh';
}

// Path: docs.components.repeated_animation_builder
class _TranslationsDocsComponentsRepeatedAnimationBuilderEn extends TranslationsDocsComponentsRepeatedAnimationBuilderKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Repeated Animation Builder';
	@override String get description => 'A builder that repeats the animation.';
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesEn examples = _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesEn._(_root);
}

// Path: docs.components.resizable
class _TranslationsDocsComponentsResizableEn extends TranslationsDocsComponentsResizableKo {
	_TranslationsDocsComponentsResizableEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Resizable';
	@override String get description => 'A container that can be resized.';
	@override late final _TranslationsDocsComponentsResizableExamplesEn examples = _TranslationsDocsComponentsResizableExamplesEn._(_root);
}

// Path: docs.components.scaffold
class _TranslationsDocsComponentsScaffoldEn extends TranslationsDocsComponentsScaffoldKo {
	_TranslationsDocsComponentsScaffoldEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Scaffold';
	@override String get description => 'The scaffold is the top-level container for a page.';
	@override late final _TranslationsDocsComponentsScaffoldExamplesEn examples = _TranslationsDocsComponentsScaffoldExamplesEn._(_root);
}

// Path: docs.components.select
class _TranslationsDocsComponentsSelectEn extends TranslationsDocsComponentsSelectKo {
	_TranslationsDocsComponentsSelectEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Select';
	@override String get description => 'Allows selecting an item from a list of options.';
	@override late final _TranslationsDocsComponentsSelectExamplesEn examples = _TranslationsDocsComponentsSelectExamplesEn._(_root);
	@override String get placeholder => 'Select a fruit';
	@override String get search_fruit => 'Search for a fruit';
	@override String get no_fruit_found => 'No fruit found';
	@override String get apple => 'Apple';
	@override String get banana => 'Banana';
	@override String get cherry => 'Cherry';
	@override String get lemon => 'Lemon';
	@override String get tomato => 'Tomato';
	@override String get red_apple => 'Red Apple';
	@override String get green_apple => 'Green Apple';
	@override String get yellow_banana => 'Yellow Banana';
	@override String get brown_banana => 'Brown Banana';
	@override String get yellow_lemon => 'Yellow Lemon';
	@override String get green_lemon => 'Green Lemon';
	@override String get red => 'Red';
	@override String get green => 'Green';
	@override String get yellow => 'Yellow';
	@override String get brown => 'Brown';
}

// Path: docs.components.sheet
class _TranslationsDocsComponentsSheetEn extends TranslationsDocsComponentsSheetKo {
	_TranslationsDocsComponentsSheetEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Sheet';
	@override String get description => 'A sheet that comes up from the bottom.';
	@override late final _TranslationsDocsComponentsSheetExamplesEn examples = _TranslationsDocsComponentsSheetExamplesEn._(_root);
}

// Path: docs.components.skeleton
class _TranslationsDocsComponentsSkeletonEn extends TranslationsDocsComponentsSkeletonKo {
	_TranslationsDocsComponentsSkeletonEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Skeleton';
	@override String get description => 'A skeleton screen displayed during loading.';
	@override late final _TranslationsDocsComponentsSkeletonExamplesEn examples = _TranslationsDocsComponentsSkeletonExamplesEn._(_root);
}

// Path: docs.components.slider
class _TranslationsDocsComponentsSliderEn extends TranslationsDocsComponentsSliderKo {
	_TranslationsDocsComponentsSliderEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Slider';
	@override String get description => 'Allows selecting a value by sliding.';
	@override late final _TranslationsDocsComponentsSliderExamplesEn examples = _TranslationsDocsComponentsSliderExamplesEn._(_root);
	@override String value_single({required Object value}) => 'Value: ${value}';
	@override String value_range({required Object start, required Object end}) => 'Value: ${start} - ${end}';
}

// Path: docs.components.sortable
class _TranslationsDocsComponentsSortableEn extends TranslationsDocsComponentsSortableKo {
	_TranslationsDocsComponentsSortableEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Sortable';
	@override String get description => 'Allows dragging items to sort.';
	@override late final _TranslationsDocsComponentsSortableExamplesEn examples = _TranslationsDocsComponentsSortableExamplesEn._(_root);
}

// Path: docs.components.star_rating
class _TranslationsDocsComponentsStarRatingEn extends TranslationsDocsComponentsStarRatingKo {
	_TranslationsDocsComponentsStarRatingEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Star Rating';
	@override String get description => 'Allows selecting a rating in stars.';
	@override late final _TranslationsDocsComponentsStarRatingExamplesEn examples = _TranslationsDocsComponentsStarRatingExamplesEn._(_root);
}

// Path: docs.components.stepper
class _TranslationsDocsComponentsStepperEn extends TranslationsDocsComponentsStepperKo {
	_TranslationsDocsComponentsStepperEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Stepper';
	@override String get description => 'Displays a step-by-step process.';
	@override late final _TranslationsDocsComponentsStepperExamplesEn examples = _TranslationsDocsComponentsStepperExamplesEn._(_root);
	@override String get step_1 => 'Step 1';
	@override String get step_2 => 'Step 2';
	@override String get step_3 => 'Step 3';
	@override String step_n({required Object n}) => 'Step ${n}';
	@override String get optional_step => 'Optional Step';
	@override String get horizontal => 'Horizontal';
	@override String get vertical => 'Vertical';
	@override String get toggle_error => 'Toggle Error';
	@override String get circle => 'Circle';
	@override String get circle_alt => 'Alternative Circle';
	@override String get line => 'Line';
	@override String get small => 'Small';
	@override String get medium => 'Medium';
	@override String get large => 'Large';
}

// Path: docs.components.steps
class _TranslationsDocsComponentsStepsEn extends TranslationsDocsComponentsStepsKo {
	_TranslationsDocsComponentsStepsEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Steps';
	@override String get description => 'Displays progress in steps.';
	@override late final _TranslationsDocsComponentsStepsExamplesEn examples = _TranslationsDocsComponentsStepsExamplesEn._(_root);
}

// Path: docs.components.swiper
class _TranslationsDocsComponentsSwiperEn extends TranslationsDocsComponentsSwiperKo {
	_TranslationsDocsComponentsSwiperEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Swiper';
	@override String get description => 'A component that can be swiped.';
	@override late final _TranslationsDocsComponentsSwiperExamplesEn examples = _TranslationsDocsComponentsSwiperExamplesEn._(_root);
}

// Path: docs.components.k_switch
class _TranslationsDocsComponentsKSwitchEn extends TranslationsDocsComponentsKSwitchKo {
	_TranslationsDocsComponentsKSwitchEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Switch';
	@override String get description => 'A toggle switch.';
	@override late final _TranslationsDocsComponentsKSwitchExamplesEn examples = _TranslationsDocsComponentsKSwitchExamplesEn._(_root);
}

// Path: docs.components.switcher
class _TranslationsDocsComponentsSwitcherEn extends TranslationsDocsComponentsSwitcherKo {
	_TranslationsDocsComponentsSwitcherEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Switcher';
	@override String get description => 'Allows switching between multiple views.';
	@override late final _TranslationsDocsComponentsSwitcherExamplesEn examples = _TranslationsDocsComponentsSwitcherExamplesEn._(_root);
	@override String get switch_direction => 'Toggle Direction';
	@override String get next_item => 'Next Item';
}

// Path: docs.components.tab_container
class _TranslationsDocsComponentsTabContainerEn extends TranslationsDocsComponentsTabContainerKo {
	_TranslationsDocsComponentsTabContainerEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tab Container';
	@override String get description => 'A base container that manages tab selection state and custom rendering.';
	@override late final _TranslationsDocsComponentsTabContainerExamplesEn examples = _TranslationsDocsComponentsTabContainerExamplesEn._(_root);
}

// Path: docs.components.tab_list
class _TranslationsDocsComponentsTabListEn extends TranslationsDocsComponentsTabListKo {
	_TranslationsDocsComponentsTabListEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tab List';
	@override String get description => 'A tab list component.';
	@override late final _TranslationsDocsComponentsTabListExamplesEn examples = _TranslationsDocsComponentsTabListExamplesEn._(_root);
}

// Path: docs.components.tab_pane
class _TranslationsDocsComponentsTabPaneEn extends TranslationsDocsComponentsTabPaneKo {
	_TranslationsDocsComponentsTabPaneEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tab Pane';
	@override String get description => 'A tab pane component.';
	@override late final _TranslationsDocsComponentsTabPaneExamplesEn examples = _TranslationsDocsComponentsTabPaneExamplesEn._(_root);
}

// Path: docs.components.table
class _TranslationsDocsComponentsTableEn extends TranslationsDocsComponentsTableKo {
	_TranslationsDocsComponentsTableEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Table';
	@override String get description => 'Displays data in a table format.';
	@override late final _TranslationsDocsComponentsTableExamplesEn examples = _TranslationsDocsComponentsTableExamplesEn._(_root);
	@override String get invoice => 'Invoice';
	@override String get status => 'Status';
	@override String get method => 'Method';
	@override String get amount => 'Amount';
	@override String get total => 'Total';
	@override String get paid => 'Paid';
	@override String get pending => 'Pending';
	@override String get unpaid => 'Unpaid';
	@override String get credit_card => 'Credit Card';
	@override String get paypal => 'PayPal';
	@override String get bank_transfer => 'Bank Transfer';
}

// Path: docs.components.tabs
class _TranslationsDocsComponentsTabsEn extends TranslationsDocsComponentsTabsKo {
	_TranslationsDocsComponentsTabsEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tabs';
	@override String get description => 'Uses tabs to organize content.';
	@override late final _TranslationsDocsComponentsTabsExamplesEn examples = _TranslationsDocsComponentsTabsExamplesEn._(_root);
	@override String get tab_1 => 'Tab 1';
	@override String get tab_2 => 'Tab 2';
	@override String get tab_3 => 'Tab 3';
	@override String tab_n({required Object n}) => 'Tab ${n}';
}

// Path: docs.components.text_area
class _TranslationsDocsComponentsTextAreaEn extends TranslationsDocsComponentsTextAreaKo {
	_TranslationsDocsComponentsTextAreaEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Text Area';
	@override String get description => 'A field for entering multiple lines of text.';
	@override late final _TranslationsDocsComponentsTextAreaExamplesEn examples = _TranslationsDocsComponentsTextAreaExamplesEn._(_root);
	@override String get hello_world => 'Hello, World!';
}

// Path: docs.components.time_picker
class _TranslationsDocsComponentsTimePickerEn extends TranslationsDocsComponentsTimePickerKo {
	_TranslationsDocsComponentsTimePickerEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Time Picker';
	@override String get description => 'A component for selecting time.';
	@override late final _TranslationsDocsComponentsTimePickerExamplesEn examples = _TranslationsDocsComponentsTimePickerExamplesEn._(_root);
	@override String get select_time => 'Select Time';
}

// Path: docs.components.timeline
class _TranslationsDocsComponentsTimelineEn extends TranslationsDocsComponentsTimelineKo {
	_TranslationsDocsComponentsTimelineEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Timeline';
	@override String get description => 'Displays events in a timeline.';
	@override late final _TranslationsDocsComponentsTimelineExamplesEn examples = _TranslationsDocsComponentsTimelineExamplesEn._(_root);
}

// Path: docs.components.timeline_animation
class _TranslationsDocsComponentsTimelineAnimationEn extends TranslationsDocsComponentsTimelineAnimationKo {
	_TranslationsDocsComponentsTimelineAnimationEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Timeline Animation';
	@override String get description => 'Timeline-based animation.';
	@override late final _TranslationsDocsComponentsTimelineAnimationExamplesEn examples = _TranslationsDocsComponentsTimelineAnimationExamplesEn._(_root);
}

// Path: docs.components.toast
class _TranslationsDocsComponentsToastEn extends TranslationsDocsComponentsToastKo {
	_TranslationsDocsComponentsToastEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Toast';
	@override String get description => 'A notification that displays a short message.';
	@override late final _TranslationsDocsComponentsToastExamplesEn examples = _TranslationsDocsComponentsToastExamplesEn._(_root);
	@override String get event_created => 'An event has been created';
	@override String get event_date => 'Sunday, July 7, 2024, at 12:00 PM';
	@override String get show_bottom_left => 'Show toast at bottom left';
	@override String get show_bottom_right => 'Show toast at bottom right';
	@override String get show_top_left => 'Show toast at top left';
	@override String get show_top_right => 'Show toast at top right';
	@override String get show_bottom_center => 'Show toast at bottom center';
	@override String get show_top_center => 'Show toast at top center';
}

// Path: docs.components.toggle
class _TranslationsDocsComponentsToggleEn extends TranslationsDocsComponentsToggleKo {
	_TranslationsDocsComponentsToggleEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Toggle';
	@override String get description => 'Allows toggling between options.';
	@override late final _TranslationsDocsComponentsToggleExamplesEn examples = _TranslationsDocsComponentsToggleExamplesEn._(_root);
	@override String get toggle => 'Toggle';
}

// Path: docs.components.tooltip
class _TranslationsDocsComponentsTooltipEn extends TranslationsDocsComponentsTooltipKo {
	_TranslationsDocsComponentsTooltipEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tooltip';
	@override String get description => 'Displays additional information about an element.';
	@override late final _TranslationsDocsComponentsTooltipExamplesEn examples = _TranslationsDocsComponentsTooltipExamplesEn._(_root);
	@override String get this_is_tooltip => 'This is a tooltip.';
	@override String get hover_over_me => 'Hover over me';
}

// Path: docs.components.tracker
class _TranslationsDocsComponentsTrackerEn extends TranslationsDocsComponentsTrackerKo {
	_TranslationsDocsComponentsTrackerEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tracker';
	@override String get description => 'Tracks progress.';
	@override late final _TranslationsDocsComponentsTrackerExamplesEn examples = _TranslationsDocsComponentsTrackerExamplesEn._(_root);
	@override String get fine => 'Fine';
	@override String get warning => 'Warning';
	@override String get critical => 'Critical';
	@override String get unknown => 'Unknown';
	@override String get tracker_fine => 'Tracker Fine';
	@override String get tracker_warning => 'Tracker Warning';
	@override String get tracker_critical => 'Tracker Critical';
	@override String get tracker_unknown => 'Tracker Unknown';
}

// Path: docs.components.tree
class _TranslationsDocsComponentsTreeEn extends TranslationsDocsComponentsTreeKo {
	_TranslationsDocsComponentsTreeEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tree';
	@override String get description => 'Displays hierarchical data in a tree format.';
	@override late final _TranslationsDocsComponentsTreeExamplesEn examples = _TranslationsDocsComponentsTreeExamplesEn._(_root);
}

// Path: docs.components.window
class _TranslationsDocsComponentsWindowEn extends TranslationsDocsComponentsWindowKo {
	_TranslationsDocsComponentsWindowEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Window';
	@override String get description => 'A desktop-style window.';
	@override late final _TranslationsDocsComponentsWindowExamplesEn examples = _TranslationsDocsComponentsWindowExamplesEn._(_root);
	@override String get window_1 => 'Window 1';
	@override String get window_2 => 'Window 2';
	@override String get desktop => 'Desktop';
	@override String get add_window => 'Add Window';
}

// Path: docs.pages.introduction.features_list
class _TranslationsDocsPagesIntroductionFeaturesListEn extends TranslationsDocsPagesIntroductionFeaturesListKo {
	_TranslationsDocsPagesIntroductionFeaturesListEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get components_count => '84 components and counting!';
	@override String get material_cupertino => 'Supports Material and Cupertino widgets and themes are currently tailored to the coui_flutter theme.';
	@override String get premade_themes => 'Premade themes from Coui/UI.';
	@override String get platform_support => 'Support for mobile, web, and desktop platforms.';
	@override String get middle_drag => 'Supports middle drag scrolling.';
	@override String get typography_extensions => 'Various widget extensions for typography.';
	@override String get webassembly => 'WebAssembly support for better performance.';
}

// Path: docs.components.accordion.examples
class _TranslationsDocsComponentsAccordionExamplesEn extends TranslationsDocsComponentsAccordionExamplesKo {
	_TranslationsDocsComponentsAccordionExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Accordion Example';
}

// Path: docs.components.alert.examples
class _TranslationsDocsComponentsAlertExamplesEn extends TranslationsDocsComponentsAlertExamplesKo {
	_TranslationsDocsComponentsAlertExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Alert Example';
	@override String get destructive => 'Destructive Alert Example';
}

// Path: docs.components.empty_state.examples
class _TranslationsDocsComponentsEmptyStateExamplesEn extends TranslationsDocsComponentsEmptyStateExamplesKo {
	_TranslationsDocsComponentsEmptyStateExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Basic Empty State';
	@override String get compact => 'Compact Empty State';
	@override String get with_action => 'Empty State with Action';
}

// Path: docs.components.fade_scroll.examples
class _TranslationsDocsComponentsFadeScrollExamplesEn extends TranslationsDocsComponentsFadeScrollExamplesKo {
	_TranslationsDocsComponentsFadeScrollExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get vertical => 'Vertical Fade Scroll';
	@override String get horizontal => 'Horizontal Fade Scroll';
}

// Path: docs.components.validation_badge.examples
class _TranslationsDocsComponentsValidationBadgeExamplesEn extends TranslationsDocsComponentsValidationBadgeExamplesKo {
	_TranslationsDocsComponentsValidationBadgeExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get states => 'Validation States';
	@override String get from_bool => 'Boolean-based Creation';
	@override String get sizes => 'Size Variants';
}

// Path: docs.components.banner.examples
class _TranslationsDocsComponentsBannerExamplesEn extends TranslationsDocsComponentsBannerExamplesKo {
	_TranslationsDocsComponentsBannerExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Basic Banner';
	@override String get variants => 'Banner Variants';
	@override String get with_action => 'Banner with Action';
}

// Path: docs.components.alert_dialog.examples
class _TranslationsDocsComponentsAlertDialogExamplesEn extends TranslationsDocsComponentsAlertDialogExamplesKo {
	_TranslationsDocsComponentsAlertDialogExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Alert Dialog Example';
}

// Path: docs.components.animated_value_builder.examples
class _TranslationsDocsComponentsAnimatedValueBuilderExamplesEn extends TranslationsDocsComponentsAnimatedValueBuilderExamplesKo {
	_TranslationsDocsComponentsAnimatedValueBuilderExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Animated Value Builder Example';
}

// Path: docs.components.app_bar.examples
class _TranslationsDocsComponentsAppBarExamplesEn extends TranslationsDocsComponentsAppBarExamplesKo {
	_TranslationsDocsComponentsAppBarExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'App Bar Example';
}

// Path: docs.components.fab.examples
class _TranslationsDocsComponentsFabExamplesEn extends TranslationsDocsComponentsFabExamplesKo {
	_TranslationsDocsComponentsFabExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Basic FAB';
	@override String get sizes => 'Size Variants';
	@override String get speed_dial => 'Speed Dial';
}

// Path: docs.components.hover.examples
class _TranslationsDocsComponentsHoverExamplesEn extends TranslationsDocsComponentsHoverExamplesKo {
	_TranslationsDocsComponentsHoverExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Basic Hover';
	@override String get activity => 'Hover Activity';
}

// Path: docs.components.scrollbar.examples
class _TranslationsDocsComponentsScrollbarExamplesEn extends TranslationsDocsComponentsScrollbarExamplesKo {
	_TranslationsDocsComponentsScrollbarExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Basic Scrollbar';
}

// Path: docs.components.autocomplete.examples
class _TranslationsDocsComponentsAutocompleteExamplesEn extends TranslationsDocsComponentsAutocompleteExamplesKo {
	_TranslationsDocsComponentsAutocompleteExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Autocomplete Example';
}

// Path: docs.components.avatar.examples
class _TranslationsDocsComponentsAvatarExamplesEn extends TranslationsDocsComponentsAvatarExamplesKo {
	_TranslationsDocsComponentsAvatarExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Avatar Example';
}

// Path: docs.components.avatar_group.examples
class _TranslationsDocsComponentsAvatarGroupExamplesEn extends TranslationsDocsComponentsAvatarGroupExamplesKo {
	_TranslationsDocsComponentsAvatarGroupExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Avatar Group Example';
}

// Path: docs.components.badge.examples
class _TranslationsDocsComponentsBadgeExamplesEn extends TranslationsDocsComponentsBadgeExamplesKo {
	_TranslationsDocsComponentsBadgeExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Badge Example';
}

// Path: docs.components.breadcrumb.examples
class _TranslationsDocsComponentsBreadcrumbExamplesEn extends TranslationsDocsComponentsBreadcrumbExamplesKo {
	_TranslationsDocsComponentsBreadcrumbExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Breadcrumb Example';
}

// Path: docs.components.button.examples
class _TranslationsDocsComponentsButtonExamplesEn extends TranslationsDocsComponentsButtonExamplesKo {
	_TranslationsDocsComponentsButtonExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get primary => 'Primary Button Example';
	@override String get secondary => 'Secondary Button Example';
	@override String get outline => 'Outline Button Example';
	@override String get ghost => 'Ghost Button Example';
	@override String get destructive => 'Destructive Button Example';
	@override String get link => 'Link Button Example';
	@override String get text => 'Text Button Example';
	@override String get disabled => 'Disabled Button Example';
	@override String get icon => 'Icon Button Example';
	@override String get icon_with_label => 'Icon Button with Label Example';
	@override String get size => 'Button Size Example';
	@override String get density => 'Button Density Example';
	@override String get shape => 'Button Shape Example';
	@override String get group => 'Button Group Example';
	@override String get stated => 'Stated Button Example';
	@override String get card => 'Card Button Example';
	@override String get custom => 'Custom Button Example';
}

// Path: docs.components.calendar.examples
class _TranslationsDocsComponentsCalendarExamplesEn extends TranslationsDocsComponentsCalendarExamplesKo {
	_TranslationsDocsComponentsCalendarExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Calendar Example';
}

// Path: docs.components.card.examples
class _TranslationsDocsComponentsCardExamplesEn extends TranslationsDocsComponentsCardExamplesKo {
	_TranslationsDocsComponentsCardExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Card Example';
}

// Path: docs.components.card_image.examples
class _TranslationsDocsComponentsCardImageExamplesEn extends TranslationsDocsComponentsCardImageExamplesKo {
	_TranslationsDocsComponentsCardImageExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Image Card Example';
}

// Path: docs.components.carousel.examples
class _TranslationsDocsComponentsCarouselExamplesEn extends TranslationsDocsComponentsCarouselExamplesKo {
	_TranslationsDocsComponentsCarouselExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Carousel Example';
}

// Path: docs.components.checkbox.examples
class _TranslationsDocsComponentsCheckboxExamplesEn extends TranslationsDocsComponentsCheckboxExamplesKo {
	_TranslationsDocsComponentsCheckboxExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Checkbox Example';
}

// Path: docs.components.chip.examples
class _TranslationsDocsComponentsChipExamplesEn extends TranslationsDocsComponentsChipExamplesKo {
	_TranslationsDocsComponentsChipExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Chip Example';
}

// Path: docs.components.chip_input.examples
class _TranslationsDocsComponentsChipInputExamplesEn extends TranslationsDocsComponentsChipInputExamplesKo {
	_TranslationsDocsComponentsChipInputExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Chip Input Example';
}

// Path: docs.components.circular_progress.examples
class _TranslationsDocsComponentsCircularProgressExamplesEn extends TranslationsDocsComponentsCircularProgressExamplesKo {
	_TranslationsDocsComponentsCircularProgressExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Circular Progress Example';
}

// Path: docs.components.code_snippet.examples
class _TranslationsDocsComponentsCodeSnippetExamplesEn extends TranslationsDocsComponentsCodeSnippetExamplesKo {
	_TranslationsDocsComponentsCodeSnippetExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Code Snippet Example';
}

// Path: docs.components.collapsible.examples
class _TranslationsDocsComponentsCollapsibleExamplesEn extends TranslationsDocsComponentsCollapsibleExamplesKo {
	_TranslationsDocsComponentsCollapsibleExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Collapsible Example';
}

// Path: docs.components.color_picker.examples
class _TranslationsDocsComponentsColorPickerExamplesEn extends TranslationsDocsComponentsColorPickerExamplesKo {
	_TranslationsDocsComponentsColorPickerExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Color Picker Example';
}

// Path: docs.components.command.examples
class _TranslationsDocsComponentsCommandExamplesEn extends TranslationsDocsComponentsCommandExamplesKo {
	_TranslationsDocsComponentsCommandExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Command Example';
}

// Path: docs.components.context_menu.examples
class _TranslationsDocsComponentsContextMenuExamplesEn extends TranslationsDocsComponentsContextMenuExamplesKo {
	_TranslationsDocsComponentsContextMenuExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Context Menu Example';
}

// Path: docs.components.date_picker.examples
class _TranslationsDocsComponentsDatePickerExamplesEn extends TranslationsDocsComponentsDatePickerExamplesKo {
	_TranslationsDocsComponentsDatePickerExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Date Picker Example';
}

// Path: docs.components.dialog.examples
class _TranslationsDocsComponentsDialogExamplesEn extends TranslationsDocsComponentsDialogExamplesKo {
	_TranslationsDocsComponentsDialogExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Dialog Example';
}

// Path: docs.components.divider.examples
class _TranslationsDocsComponentsDividerExamplesEn extends TranslationsDocsComponentsDividerExamplesKo {
	_TranslationsDocsComponentsDividerExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Divider Example';
}

// Path: docs.components.dot_indicator.examples
class _TranslationsDocsComponentsDotIndicatorExamplesEn extends TranslationsDocsComponentsDotIndicatorExamplesKo {
	_TranslationsDocsComponentsDotIndicatorExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Dot Indicator Example';
}

// Path: docs.components.drawer.examples
class _TranslationsDocsComponentsDrawerExamplesEn extends TranslationsDocsComponentsDrawerExamplesKo {
	_TranslationsDocsComponentsDrawerExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Drawer Example';
}

// Path: docs.components.dropdown_menu.examples
class _TranslationsDocsComponentsDropdownMenuExamplesEn extends TranslationsDocsComponentsDropdownMenuExamplesKo {
	_TranslationsDocsComponentsDropdownMenuExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Dropdown Menu Example';
}

// Path: docs.components.expandable_sidebar.examples
class _TranslationsDocsComponentsExpandableSidebarExamplesEn extends TranslationsDocsComponentsExpandableSidebarExamplesKo {
	_TranslationsDocsComponentsExpandableSidebarExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Expandable Sidebar Example';
}

// Path: docs.components.form.examples
class _TranslationsDocsComponentsFormExamplesEn extends TranslationsDocsComponentsFormExamplesKo {
	_TranslationsDocsComponentsFormExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get table_layout => 'Form Example (Table Layout)';
	@override String get column_layout => 'Form Example (Column Layout)';
	@override String get validation_mode => 'Validation Mode Example';
}

// Path: docs.components.formatted_input.examples
class _TranslationsDocsComponentsFormattedInputExamplesEn extends TranslationsDocsComponentsFormattedInputExamplesKo {
	_TranslationsDocsComponentsFormattedInputExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Formatted Input Example';
}

// Path: docs.components.hover_card.examples
class _TranslationsDocsComponentsHoverCardExamplesEn extends TranslationsDocsComponentsHoverCardExamplesKo {
	_TranslationsDocsComponentsHoverCardExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Hover Card Example';
}

// Path: docs.components.input.examples
class _TranslationsDocsComponentsInputExamplesEn extends TranslationsDocsComponentsInputExamplesKo {
	_TranslationsDocsComponentsInputExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Input Example';
}

// Path: docs.components.input_otp.examples
class _TranslationsDocsComponentsInputOtpExamplesEn extends TranslationsDocsComponentsInputOtpExamplesKo {
	_TranslationsDocsComponentsInputOtpExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'OTP Input Example';
}

// Path: docs.components.item_picker.examples
class _TranslationsDocsComponentsItemPickerExamplesEn extends TranslationsDocsComponentsItemPickerExamplesKo {
	_TranslationsDocsComponentsItemPickerExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Item Picker Example';
}

// Path: docs.components.keyboard_display.examples
class _TranslationsDocsComponentsKeyboardDisplayExamplesEn extends TranslationsDocsComponentsKeyboardDisplayExamplesKo {
	_TranslationsDocsComponentsKeyboardDisplayExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Keyboard Display Example';
}

// Path: docs.components.linear_progress.examples
class _TranslationsDocsComponentsLinearProgressExamplesEn extends TranslationsDocsComponentsLinearProgressExamplesKo {
	_TranslationsDocsComponentsLinearProgressExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Linear Progress Example';
}

// Path: docs.components.material.examples
class _TranslationsDocsComponentsMaterialExamplesEn extends TranslationsDocsComponentsMaterialExamplesKo {
	_TranslationsDocsComponentsMaterialExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Material/Cupertino Example';
}

// Path: docs.components.menubar.examples
class _TranslationsDocsComponentsMenubarExamplesEn extends TranslationsDocsComponentsMenubarExamplesKo {
	_TranslationsDocsComponentsMenubarExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Menu Bar Example';
}

// Path: docs.components.multiselect.examples
class _TranslationsDocsComponentsMultiselectExamplesEn extends TranslationsDocsComponentsMultiselectExamplesKo {
	_TranslationsDocsComponentsMultiselectExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Multi Select Example';
}

// Path: docs.components.navigation_bar.examples
class _TranslationsDocsComponentsNavigationBarExamplesEn extends TranslationsDocsComponentsNavigationBarExamplesKo {
	_TranslationsDocsComponentsNavigationBarExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Navigation Bar Example';
}

// Path: docs.components.navigation_menu.examples
class _TranslationsDocsComponentsNavigationMenuExamplesEn extends TranslationsDocsComponentsNavigationMenuExamplesKo {
	_TranslationsDocsComponentsNavigationMenuExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Navigation Menu Example';
}

// Path: docs.components.navigation_rail.examples
class _TranslationsDocsComponentsNavigationRailExamplesEn extends TranslationsDocsComponentsNavigationRailExamplesKo {
	_TranslationsDocsComponentsNavigationRailExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Navigation Rail Example';
}

// Path: docs.components.navigation_sidebar.examples
class _TranslationsDocsComponentsNavigationSidebarExamplesEn extends TranslationsDocsComponentsNavigationSidebarExamplesKo {
	_TranslationsDocsComponentsNavigationSidebarExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Navigation Sidebar Example';
}

// Path: docs.components.number_input.examples
class _TranslationsDocsComponentsNumberInputExamplesEn extends TranslationsDocsComponentsNumberInputExamplesKo {
	_TranslationsDocsComponentsNumberInputExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Number Input Example';
}

// Path: docs.components.number_ticker.examples
class _TranslationsDocsComponentsNumberTickerExamplesEn extends TranslationsDocsComponentsNumberTickerExamplesKo {
	_TranslationsDocsComponentsNumberTickerExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Number Ticker Example';
}

// Path: docs.components.overflow_marquee.examples
class _TranslationsDocsComponentsOverflowMarqueeExamplesEn extends TranslationsDocsComponentsOverflowMarqueeExamplesKo {
	_TranslationsDocsComponentsOverflowMarqueeExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Overflow Marquee Example';
}

// Path: docs.components.pagination.examples
class _TranslationsDocsComponentsPaginationExamplesEn extends TranslationsDocsComponentsPaginationExamplesKo {
	_TranslationsDocsComponentsPaginationExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Pagination Example';
}

// Path: docs.components.phone_input.examples
class _TranslationsDocsComponentsPhoneInputExamplesEn extends TranslationsDocsComponentsPhoneInputExamplesKo {
	_TranslationsDocsComponentsPhoneInputExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Phone Number Input Example';
}

// Path: docs.components.popover.examples
class _TranslationsDocsComponentsPopoverExamplesEn extends TranslationsDocsComponentsPopoverExamplesKo {
	_TranslationsDocsComponentsPopoverExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Popover Example';
}

// Path: docs.components.progress.examples
class _TranslationsDocsComponentsProgressExamplesEn extends TranslationsDocsComponentsProgressExamplesKo {
	_TranslationsDocsComponentsProgressExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Progress Example';
}

// Path: docs.components.radio_card.examples
class _TranslationsDocsComponentsRadioCardExamplesEn extends TranslationsDocsComponentsRadioCardExamplesKo {
	_TranslationsDocsComponentsRadioCardExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Radio Card Example';
}

// Path: docs.components.radio_group.examples
class _TranslationsDocsComponentsRadioGroupExamplesEn extends TranslationsDocsComponentsRadioGroupExamplesKo {
	_TranslationsDocsComponentsRadioGroupExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Radio Group Example';
}

// Path: docs.components.refresh_trigger.examples
class _TranslationsDocsComponentsRefreshTriggerExamplesEn extends TranslationsDocsComponentsRefreshTriggerExamplesKo {
	_TranslationsDocsComponentsRefreshTriggerExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Refresh Trigger Example';
}

// Path: docs.components.repeated_animation_builder.examples
class _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesEn extends TranslationsDocsComponentsRepeatedAnimationBuilderExamplesKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Repeated Animation Builder Example';
}

// Path: docs.components.resizable.examples
class _TranslationsDocsComponentsResizableExamplesEn extends TranslationsDocsComponentsResizableExamplesKo {
	_TranslationsDocsComponentsResizableExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Resizable Example';
}

// Path: docs.components.scaffold.examples
class _TranslationsDocsComponentsScaffoldExamplesEn extends TranslationsDocsComponentsScaffoldExamplesKo {
	_TranslationsDocsComponentsScaffoldExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Scaffold Example';
}

// Path: docs.components.select.examples
class _TranslationsDocsComponentsSelectExamplesEn extends TranslationsDocsComponentsSelectExamplesKo {
	_TranslationsDocsComponentsSelectExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Select Example';
}

// Path: docs.components.sheet.examples
class _TranslationsDocsComponentsSheetExamplesEn extends TranslationsDocsComponentsSheetExamplesKo {
	_TranslationsDocsComponentsSheetExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Sheet Example';
}

// Path: docs.components.skeleton.examples
class _TranslationsDocsComponentsSkeletonExamplesEn extends TranslationsDocsComponentsSkeletonExamplesKo {
	_TranslationsDocsComponentsSkeletonExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Skeleton Example';
}

// Path: docs.components.slider.examples
class _TranslationsDocsComponentsSliderExamplesEn extends TranslationsDocsComponentsSliderExamplesKo {
	_TranslationsDocsComponentsSliderExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Slider Example';
}

// Path: docs.components.sortable.examples
class _TranslationsDocsComponentsSortableExamplesEn extends TranslationsDocsComponentsSortableExamplesKo {
	_TranslationsDocsComponentsSortableExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Sortable Example';
}

// Path: docs.components.star_rating.examples
class _TranslationsDocsComponentsStarRatingExamplesEn extends TranslationsDocsComponentsStarRatingExamplesKo {
	_TranslationsDocsComponentsStarRatingExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Star Rating Example';
}

// Path: docs.components.stepper.examples
class _TranslationsDocsComponentsStepperExamplesEn extends TranslationsDocsComponentsStepperExamplesKo {
	_TranslationsDocsComponentsStepperExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Stepper Example';
}

// Path: docs.components.steps.examples
class _TranslationsDocsComponentsStepsExamplesEn extends TranslationsDocsComponentsStepsExamplesKo {
	_TranslationsDocsComponentsStepsExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Steps Example';
}

// Path: docs.components.swiper.examples
class _TranslationsDocsComponentsSwiperExamplesEn extends TranslationsDocsComponentsSwiperExamplesKo {
	_TranslationsDocsComponentsSwiperExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Swiper Example';
}

// Path: docs.components.k_switch.examples
class _TranslationsDocsComponentsKSwitchExamplesEn extends TranslationsDocsComponentsKSwitchExamplesKo {
	_TranslationsDocsComponentsKSwitchExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Switch Example';
}

// Path: docs.components.switcher.examples
class _TranslationsDocsComponentsSwitcherExamplesEn extends TranslationsDocsComponentsSwitcherExamplesKo {
	_TranslationsDocsComponentsSwitcherExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Switcher Example';
}

// Path: docs.components.tab_container.examples
class _TranslationsDocsComponentsTabContainerExamplesEn extends TranslationsDocsComponentsTabContainerExamplesKo {
	_TranslationsDocsComponentsTabContainerExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Tab Container Example';
}

// Path: docs.components.tab_list.examples
class _TranslationsDocsComponentsTabListExamplesEn extends TranslationsDocsComponentsTabListExamplesKo {
	_TranslationsDocsComponentsTabListExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Tab List Example';
}

// Path: docs.components.tab_pane.examples
class _TranslationsDocsComponentsTabPaneExamplesEn extends TranslationsDocsComponentsTabPaneExamplesKo {
	_TranslationsDocsComponentsTabPaneExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Tab Pane Example';
}

// Path: docs.components.table.examples
class _TranslationsDocsComponentsTableExamplesEn extends TranslationsDocsComponentsTableExamplesKo {
	_TranslationsDocsComponentsTableExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Table Example';
}

// Path: docs.components.tabs.examples
class _TranslationsDocsComponentsTabsExamplesEn extends TranslationsDocsComponentsTabsExamplesKo {
	_TranslationsDocsComponentsTabsExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Tabs Example';
}

// Path: docs.components.text_area.examples
class _TranslationsDocsComponentsTextAreaExamplesEn extends TranslationsDocsComponentsTextAreaExamplesKo {
	_TranslationsDocsComponentsTextAreaExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Text Area Example';
}

// Path: docs.components.time_picker.examples
class _TranslationsDocsComponentsTimePickerExamplesEn extends TranslationsDocsComponentsTimePickerExamplesKo {
	_TranslationsDocsComponentsTimePickerExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Time Picker Example';
}

// Path: docs.components.timeline.examples
class _TranslationsDocsComponentsTimelineExamplesEn extends TranslationsDocsComponentsTimelineExamplesKo {
	_TranslationsDocsComponentsTimelineExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Timeline Example';
}

// Path: docs.components.timeline_animation.examples
class _TranslationsDocsComponentsTimelineAnimationExamplesEn extends TranslationsDocsComponentsTimelineAnimationExamplesKo {
	_TranslationsDocsComponentsTimelineAnimationExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Timeline Animation Example';
}

// Path: docs.components.toast.examples
class _TranslationsDocsComponentsToastExamplesEn extends TranslationsDocsComponentsToastExamplesKo {
	_TranslationsDocsComponentsToastExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Toast Example';
}

// Path: docs.components.toggle.examples
class _TranslationsDocsComponentsToggleExamplesEn extends TranslationsDocsComponentsToggleExamplesKo {
	_TranslationsDocsComponentsToggleExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Toggle Example';
}

// Path: docs.components.tooltip.examples
class _TranslationsDocsComponentsTooltipExamplesEn extends TranslationsDocsComponentsTooltipExamplesKo {
	_TranslationsDocsComponentsTooltipExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Tooltip Example';
}

// Path: docs.components.tracker.examples
class _TranslationsDocsComponentsTrackerExamplesEn extends TranslationsDocsComponentsTrackerExamplesKo {
	_TranslationsDocsComponentsTrackerExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Tracker Example';
}

// Path: docs.components.tree.examples
class _TranslationsDocsComponentsTreeExamplesEn extends TranslationsDocsComponentsTreeExamplesKo {
	_TranslationsDocsComponentsTreeExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Tree Example';
}

// Path: docs.components.window.examples
class _TranslationsDocsComponentsWindowExamplesEn extends TranslationsDocsComponentsWindowExamplesKo {
	_TranslationsDocsComponentsWindowExamplesEn._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Window Example';
}
