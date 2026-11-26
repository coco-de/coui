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
class TranslationsRu extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsRu({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ru,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <ru>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsRu _root = this; // ignore: unused_field

	@override 
	TranslationsRu $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsRu(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsWidgetbookRu widgetbook = _TranslationsWidgetbookRu._(_root);
	@override late final _TranslationsDocsRu docs = _TranslationsDocsRu._(_root);
}

// Path: widgetbook
class _TranslationsWidgetbookRu extends TranslationsWidgetbookKo {
	_TranslationsWidgetbookRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsWidgetbookCommonRu common = _TranslationsWidgetbookCommonRu._(_root);
	@override late final _TranslationsWidgetbookLoadingRu loading = _TranslationsWidgetbookLoadingRu._(_root);
	@override late final _TranslationsWidgetbookTabsRu tabs = _TranslationsWidgetbookTabsRu._(_root);
	@override late final _TranslationsWidgetbookPaginationRu pagination = _TranslationsWidgetbookPaginationRu._(_root);
	@override late final _TranslationsWidgetbookTooltipRu tooltip = _TranslationsWidgetbookTooltipRu._(_root);
	@override late final _TranslationsWidgetbookRadioRu radio = _TranslationsWidgetbookRadioRu._(_root);
	@override late final _TranslationsWidgetbookCardRu card = _TranslationsWidgetbookCardRu._(_root);
	@override late final _TranslationsWidgetbookAlertRu alert = _TranslationsWidgetbookAlertRu._(_root);
	@override late final _TranslationsWidgetbookAccordionRu accordion = _TranslationsWidgetbookAccordionRu._(_root);
	@override late final _TranslationsWidgetbookSkeletonRu skeleton = _TranslationsWidgetbookSkeletonRu._(_root);
	@override late final _TranslationsWidgetbookToastRu toast = _TranslationsWidgetbookToastRu._(_root);
	@override late final _TranslationsWidgetbookChipRu chip = _TranslationsWidgetbookChipRu._(_root);
	@override late final _TranslationsWidgetbookCheckboxRu checkbox = _TranslationsWidgetbookCheckboxRu._(_root);
	@override late final _TranslationsWidgetbookToggleRu toggle = _TranslationsWidgetbookToggleRu._(_root);
	@override late final _TranslationsWidgetbookDialogRu dialog = _TranslationsWidgetbookDialogRu._(_root);
	@override late final _TranslationsWidgetbookPopoverRu popover = _TranslationsWidgetbookPopoverRu._(_root);
	@override late final _TranslationsWidgetbookTextFieldRu text_field = _TranslationsWidgetbookTextFieldRu._(_root);
	@override late final _TranslationsWidgetbookButtonRu button = _TranslationsWidgetbookButtonRu._(_root);
	@override late final _TranslationsWidgetbookTableRu table = _TranslationsWidgetbookTableRu._(_root);
	@override late final _TranslationsWidgetbookKSwitchRu k_switch = _TranslationsWidgetbookKSwitchRu._(_root);
	@override late final _TranslationsWidgetbookSwitchComponentRu switch_component = _TranslationsWidgetbookSwitchComponentRu._(_root);
	@override late final _TranslationsWidgetbookSelectRu select = _TranslationsWidgetbookSelectRu._(_root);
	@override late final _TranslationsWidgetbookBreadcrumbRu breadcrumb = _TranslationsWidgetbookBreadcrumbRu._(_root);
	@override late final _TranslationsWidgetbookBadgeRu badge = _TranslationsWidgetbookBadgeRu._(_root);
	@override late final _TranslationsWidgetbookThemePreviewRu theme_preview = _TranslationsWidgetbookThemePreviewRu._(_root);
	@override late final _TranslationsWidgetbookChatRu chat = _TranslationsWidgetbookChatRu._(_root);
	@override late final _TranslationsWidgetbookMultipleChoiceRu multiple_choice = _TranslationsWidgetbookMultipleChoiceRu._(_root);
	@override late final _TranslationsWidgetbookFormattedInputRu formatted_input = _TranslationsWidgetbookFormattedInputRu._(_root);
	@override late final _TranslationsWidgetbookSwiperRu swiper = _TranslationsWidgetbookSwiperRu._(_root);
}

// Path: docs
class _TranslationsDocsRu extends TranslationsDocsKo {
	_TranslationsDocsRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsCommonRu common = _TranslationsDocsCommonRu._(_root);
	@override late final _TranslationsDocsBadgesRu badges = _TranslationsDocsBadgesRu._(_root);
	@override late final _TranslationsDocsFlavorsRu flavors = _TranslationsDocsFlavorsRu._(_root);
	@override late final _TranslationsDocsNavigationRu navigation = _TranslationsDocsNavigationRu._(_root);
	@override late final _TranslationsDocsPagesRu pages = _TranslationsDocsPagesRu._(_root);
	@override late final _TranslationsDocsComponentsRu components = _TranslationsDocsComponentsRu._(_root);
}

// Path: widgetbook.common
class _TranslationsWidgetbookCommonRu extends TranslationsWidgetbookCommonKo {
	_TranslationsWidgetbookCommonRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get increment_progress => 'Увеличить прогресс';
	@override String selected_tab({required Object index}) => 'Выбранная вкладка: ${index}';
	@override String current_page({required Object page}) => 'Текущая страница: ${page}';
	@override String total_pages({required Object count}) => 'Всего страниц: ${count}';
	@override String page_of({required Object current, required Object total}) => '${current} страница / ${total}';
	@override String get hover_over_icon => 'Наведите курсор на иконку';
	@override String counter({required Object count}) => 'Счетчик: ${count}';
	@override String selected_rows({required Object count}) => 'Выбранные строки: ${count}';
	@override String value({required Object value}) => 'Значение: ${value}';
	@override String selected_cells({required Object count}) => 'Выбранные ячейки: ${count}';
}

// Path: widgetbook.loading
class _TranslationsWidgetbookLoadingRu extends TranslationsWidgetbookLoadingKo {
	_TranslationsWidgetbookLoadingRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get indeterminate => 'Неопределенная загрузка';
	@override String with_value({required Object percent}) => 'Включая значение (${percent}%)';
	@override String get custom_size => 'Пользовательский размер';
	@override String get custom_height => 'Пользовательская высота';
	@override String get circular_progress => 'Круговой прогресс';
	@override String get linear_progress => 'Линейный прогресс';
}

// Path: widgetbook.tabs
class _TranslationsWidgetbookTabsRu extends TranslationsWidgetbookTabsKo {
	_TranslationsWidgetbookTabsRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get home => 'Главная';
	@override String get profile => 'Профиль';
	@override String get settings => 'Настройки';
	@override String get overview => 'Обзор';
	@override String get details => 'Детали';
	@override String get history => 'История';
	@override String get overview_content => 'Контент обзора';
	@override String get details_content => 'Контент деталей';
	@override String get history_content => 'Контент истории';
	@override String get general_info => 'Общая информация о элементе';
	@override String get specifications => 'Детальные спецификации и свойства';
	@override String get timeline => 'График изменений и обновлений';
}

// Path: widgetbook.pagination
class _TranslationsWidgetbookPaginationRu extends TranslationsWidgetbookPaginationKo {
	_TranslationsWidgetbookPaginationRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get show_skip_to_first => 'Показать пропуск к первому';
	@override String get show_skip_to_last => 'Показать пропуск к последнему';
	@override String get hide_previous_on_first => 'Скрыть предыдущую на первой странице';
	@override String get hide_next_on_last => 'Скрыть следующую на последней странице';
	@override String get max_visible_pages => 'Максимальное количество видимых страниц';
}

// Path: widgetbook.tooltip
class _TranslationsWidgetbookTooltipRu extends TranslationsWidgetbookTooltipKo {
	_TranslationsWidgetbookTooltipRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get helpful_message => 'Полезное сообщение в подсказке';
	@override String get tooltip_above => 'Подсказка сверху';
	@override String get tooltip_below => 'Подсказка снизу';
	@override String get tooltip_left => 'Подсказка слева';
	@override String get tooltip_right => 'Подсказка справа';
	@override String get top => 'Сверху';
	@override String get bottom => 'Снизу';
	@override String get left => 'Слева';
	@override String get right => 'Справа';
}

// Path: widgetbook.radio
class _TranslationsWidgetbookRadioRu extends TranslationsWidgetbookRadioKo {
	_TranslationsWidgetbookRadioRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get small => 'Маленький';
	@override String get medium => 'Средний';
	@override String get large => 'Большой';
}

// Path: widgetbook.card
class _TranslationsWidgetbookCardRu extends TranslationsWidgetbookCardKo {
	_TranslationsWidgetbookCardRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get card_content => 'Содержимое карточки';
	@override String get gradient_card => 'Градиентная карточка';
	@override String get custom_decoration => 'Карточка с пользовательским оформлением';
}

// Path: widgetbook.alert
class _TranslationsWidgetbookAlertRu extends TranslationsWidgetbookAlertKo {
	_TranslationsWidgetbookAlertRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Заголовок оповещения';
	@override String get message => 'Это сообщение оповещения.';
}

// Path: widgetbook.accordion
class _TranslationsWidgetbookAccordionRu extends TranslationsWidgetbookAccordionKo {
	_TranslationsWidgetbookAccordionRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get what_is_coui => 'Что такое CoUI Flutter?';
	@override String get what_is_coui_answer => 'CoUI Flutter - это комплексная библиотека UI-компонентов, разработанная для создания современных и доступных приложений Flutter с согласованными шаблонами дизайна.';
	@override String get how_to_install => 'Как установить?';
	@override String get how_to_install_answer => 'Добавьте coui_flutter в зависимости pubspec.yaml и выполните команду flutter pub get для установки пакета.';
	@override String get is_customizable => 'Можно ли настраивать?';
	@override String get is_customizable_answer => 'Да! CoUI Flutter предлагает обширную поддержку тем, позволяющую настраивать цвета, типографику, пробелы и многое другое через ThemeData.';
	@override String get getting_started => 'Начало работы';
	@override String get getting_started_answer => 'Начните с установки пакета и добавления его в проект. Пожалуйста, обратитесь к документации для подробных настроек.';
	@override String get features_expanded => 'Функции (по умолчанию расширены)';
	@override String get features_answer => 'CoUI Flutter включает кнопки, формы, диалоги, компоненты навигации и др. Все компоненты разработаны с учетом доступности и тем.';
	@override String get support => 'Поддержка';
	@override String get support_answer => 'Если у вас есть вопросы или нужна помощь, посетите репозиторий GitHub или ознакомьтесь с документацией на docs.coui.dev.';
}

// Path: widgetbook.skeleton
class _TranslationsWidgetbookSkeletonRu extends TranslationsWidgetbookSkeletonKo {
	_TranslationsWidgetbookSkeletonRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get skeleton_enabled => 'Скелет активирован:';
	@override String get title_text => 'Это заголовок';
	@override String get description_text => 'Длинный текст описания';
	@override String get short_text => 'Короткий текст';
	@override String get without_skeleton => 'Без скелета:';
	@override String get with_skeleton => 'С скелетом:';
	@override String get user_name => 'Имя пользователя';
	@override String get user_email => 'user@example.com';
	@override String get article_title => 'Заголовок статьи';
	@override String get posted_date => 'Опубликовано 1 января 2024 года';
	@override String get bio_description => 'Разработчик, записывающий повседневную жизнь';
	@override String get show_content => 'Показать контент';
	@override String get show_loading => 'Показать загрузку';
	@override String get article_content => 'Это пример содержимого статьи. Во время загрузки он будет заменен скелетом.';
}

// Path: widgetbook.toast
class _TranslationsWidgetbookToastRu extends TranslationsWidgetbookToastKo {
	_TranslationsWidgetbookToastRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get success => 'Успех';
	@override String get operation_completed => 'Операция успешно завершена';
	@override String get show_toast => 'Показать тост';
	@override String toast_at({required Object location}) => 'Тост на ${location}';
	@override String get top_left => 'Слева сверху';
	@override String get top_center => 'Сверху по центру';
	@override String get top_right => 'Справа сверху';
	@override String get bottom_left => 'Снизу слева';
	@override String get bottom_center => 'Снизу по центру';
	@override String get bottom_right => 'Снизу справа';
}

// Path: widgetbook.chip
class _TranslationsWidgetbookChipRu extends TranslationsWidgetbookChipKo {
	_TranslationsWidgetbookChipRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get chip => 'Чип';
}

// Path: widgetbook.checkbox
class _TranslationsWidgetbookCheckboxRu extends TranslationsWidgetbookCheckboxKo {
	_TranslationsWidgetbookCheckboxRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get accept_terms => 'Я согласен с условиями использования';
	@override String get tristate => 'Три состояния';
}

// Path: widgetbook.toggle
class _TranslationsWidgetbookToggleRu extends TranslationsWidgetbookToggleKo {
	_TranslationsWidgetbookToggleRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get toggle => 'Переключатель';
}

// Path: widgetbook.dialog
class _TranslationsWidgetbookDialogRu extends TranslationsWidgetbookDialogKo {
	_TranslationsWidgetbookDialogRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic_dialog => 'Основной диалог';
	@override String get basic_title => 'Основной диалог';
	@override String get basic_content => 'Простой диалог с заголовком и содержанием.';
	@override String get simple_dialog_content => 'Простой диалог с заголовком и содержанием.';
	@override String get show_basic => 'Показать основной';
	@override String get show_basic_dialog => 'Показать основной диалог';
	@override String get confirm_action => 'Подтвердить действие';
	@override String get confirm_title => 'Подтверждение';
	@override String get confirm_content => 'Вы действительно хотите выполнить это действие?';
	@override String get confirm_action_content => 'Вы действительно хотите выполнить это действие? Его невозможно отменить.';
	@override String get cancel => 'Отмена';
	@override String get confirm => 'Подтвердить';
	@override String get show_confirmation => 'Показать подтверждение';
	@override String get show_confirmation_dialog => 'Показать диалог подтверждения';
	@override String get warning => 'Предупреждение';
	@override String get warning_title => 'Предупреждение';
	@override String get warning_content => 'Это действие может повлиять на данные. Пожалуйста, будьте осторожны.';
	@override String get dismiss => 'Закрыть';
	@override String get show_warning => 'Показать предупреждение';
	@override String get show_warning_dialog => 'Показать предупредительный диалог';
}

// Path: widgetbook.popover
class _TranslationsWidgetbookPopoverRu extends TranslationsWidgetbookPopoverKo {
	_TranslationsWidgetbookPopoverRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get popover_content => 'Контент поповера';
	@override String get content_title => 'Заголовок поповера';
	@override String get content_description => 'Поповер с настраиваемым содержимым.';
	@override String get customizable_content => 'Поповер с настраиваемым контентом.';
	@override String get show_popover => 'Показать поповер';
	@override String popover_at({required Object position}) => '${position} поповер';
	@override String get top => 'Сверху';
	@override String get bottom => 'Снизу';
	@override String get left => 'Слева';
	@override String get right => 'Справа';
}

// Path: widgetbook.text_field
class _TranslationsWidgetbookTextFieldRu extends TranslationsWidgetbookTextFieldKo {
	_TranslationsWidgetbookTextFieldRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get enter_name => 'Введите имя';
	@override String get type_here => 'Введите здесь';
}

// Path: widgetbook.button
class _TranslationsWidgetbookButtonRu extends TranslationsWidgetbookButtonKo {
	_TranslationsWidgetbookButtonRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get primary_button => 'Основная кнопка';
	@override String get secondary_button => 'Вторичная кнопка';
	@override String get dashed_button => 'Загрузить файл';
	@override String get upload_file => 'Загрузить файл';
}

// Path: widgetbook.table
class _TranslationsWidgetbookTableRu extends TranslationsWidgetbookTableKo {
	_TranslationsWidgetbookTableRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get name => 'Имя';
	@override String get email => 'Электронная почта';
	@override String get role => 'Роль';
	@override String get john_doe => 'Джон Доу';
	@override String get john_email => 'john@example.com';
	@override String get developer => 'Разработчик';
	@override String get jane_smith => 'Джейн Смит';
	@override String get jane_email => 'jane@example.com';
	@override String get designer => 'Дизайнер';
	@override String get bob_johnson => 'Боб Джонсон';
	@override String get bob_email => 'bob@example.com';
	@override String get manager => 'Менеджер';
	@override String get select => 'Выбрать';
	@override String get product => 'Продукт';
	@override String get price => 'Цена';
	@override String get stock => 'Запас';
	@override String get laptop => 'Ноутбук';
	@override String get mouse => 'Мышь';
	@override String get keyboard => 'Клавиатура';
}

// Path: widgetbook.k_switch
class _TranslationsWidgetbookKSwitchRu extends TranslationsWidgetbookKSwitchKo {
	_TranslationsWidgetbookKSwitchRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get k_switch => 'Переключатель';
}

// Path: widgetbook.switch_component
class _TranslationsWidgetbookSwitchComponentRu extends TranslationsWidgetbookSwitchComponentKo {
	_TranslationsWidgetbookSwitchComponentRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get switch_label => 'Метка переключателя';
}

// Path: widgetbook.select
class _TranslationsWidgetbookSelectRu extends TranslationsWidgetbookSelectKo {
	_TranslationsWidgetbookSelectRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get apple => 'Яблоко';
	@override String get banana => 'Банан';
	@override String get cherry => 'Вишня';
	@override String get date => 'Финик';
	@override String get choose_size => 'Выберите размер';
	@override String get small => 'Маленький';
	@override String get medium => 'Средний';
	@override String get large => 'Большой';
	@override String get extra_large => 'Очень большой';
}

// Path: widgetbook.breadcrumb
class _TranslationsWidgetbookBreadcrumbRu extends TranslationsWidgetbookBreadcrumbKo {
	_TranslationsWidgetbookBreadcrumbRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get home => 'Главная';
	@override String get products => 'Продукты';
	@override String get electronics => 'Электроника';
	@override String get smartphones => 'Смартфоны';
	@override String get documents => 'Документы';
	@override String get projects => 'Проекты';
	@override String get current_folder => 'Текущая папка';
	@override String current_path({required Object path}) => 'Текущий путь: ${path}';
}

// Path: widgetbook.badge
class _TranslationsWidgetbookBadgeRu extends TranslationsWidgetbookBadgeKo {
	_TranslationsWidgetbookBadgeRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get primary => 'Основной';
	@override String get secondary => 'Вторичный';
	@override String get outline => 'Контурный';
	@override String get destructive => 'Разрушительный';
	@override String get featured => 'Рекомендуемый';
	@override String get more => 'Еще';
	@override String get verified => 'Проверенный';
	@override String get error => 'Ошибка';
	@override String get click_me => 'Нажмите на меня';
	@override String get clickable => 'Кликабельный';
}

// Path: widgetbook.theme_preview
class _TranslationsWidgetbookThemePreviewRu extends TranslationsWidgetbookThemePreviewKo {
	_TranslationsWidgetbookThemePreviewRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Предварительный просмотр темы';
	@override String get description => 'Все темы токенов и комплексный обзор стилей компонентов';
	@override String get color_palette => 'Цветовая палитра';
	@override String get brand_colors => 'Цвета бренда';
	@override String get base_colors => 'Базовые цвета';
	@override String get status_colors => 'Цвета статуса';
	@override String get buttons => 'Кнопки';
	@override String get primary_button => 'Основная';
	@override String get secondary_button => 'Вторичная';
	@override String get outline_button => 'Контурная';
	@override String get ghost_button => 'Призрак';
	@override String get destructive_button => 'Разрушающая';
	@override String get disabled_button => 'Отключено';
	@override String get cards => 'Карты';
	@override String get card_title => 'Заголовок карты';
	@override String get card_description => 'Описание образца карты.';
	@override String get surface_card => 'Карта поверхности';
	@override String get filled_variant => 'Заполненный стиль с фоном';
	@override String get form_elements => 'Элементы формы';
	@override String get text_input_placeholder => 'Введите текст...';
	@override String get checkbox_checked => 'Выбрано';
	@override String get checkbox_unchecked => 'Не выбрано';
	@override String get toggle_on => 'Включено';
	@override String get toggle_off => 'Выключено';
	@override String get alerts => 'Уведомления';
	@override String get info_alert => 'Информационное уведомление';
	@override String get info_alert_message => 'Сообщение для информации.';
	@override String get error_alert => 'Уведомление об ошибке';
	@override String get error_alert_message => 'Произошла проблема.';
	@override String get badges_chips => 'Значки и чипы';
	@override String get primary_badge => 'Основной';
	@override String get secondary_badge => 'Вторичный';
	@override String get outline_badge => 'Контурный';
	@override String get destructive_badge => 'Разрушающий';
	@override String get chip_example => 'Избранное';
	@override String get typography => 'Типографика';
	@override String get heading_1 => 'Заголовок 1';
	@override String get heading_2 => 'Заголовок 2';
	@override String get heading_3 => 'Заголовок 3';
	@override String get heading_4 => 'Заголовок 4';
	@override String get body_text => 'Текст основного тела с обычной толщиной.';
	@override String get small_text => 'Маленький текст для подписи.';
	@override String get muted_text => 'Размытый текст для дополнительной информации.';
	@override String get bold_text => 'Жирный текст для акцентов.';
	@override String get spacing_radius => 'Промежутки и радиусы';
	@override String get border_radius => 'Закругление границ';
	@override String get loading_states => 'Состояния загрузки';
}

// Path: widgetbook.chat
class _TranslationsWidgetbookChatRu extends TranslationsWidgetbookChatKo {
	_TranslationsWidgetbookChatRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get hello => 'Привет! Как дела?';
	@override String get doing_great => 'Отлично, спасибо!';
	@override String get nice_weather => 'Сегодня хорошая погода!';
	@override String get yes_beautiful => 'Да, красиво!';
	@override String get sender => 'Отправитель';
	@override String get receiver => 'Получатель';
}

// Path: widgetbook.multiple_choice
class _TranslationsWidgetbookMultipleChoiceRu extends TranslationsWidgetbookMultipleChoiceKo {
	_TranslationsWidgetbookMultipleChoiceRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get option_a => 'Option A';
	@override String get option_b => 'Option B';
	@override String get option_c => 'Option C';
	@override String get option_d => 'Option D';
	@override String selected_value({required Object value}) => 'Выбрано: ${value}';
	@override String selected_values({required Object values}) => 'Выбрано: ${values}';
}

// Path: widgetbook.formatted_input
class _TranslationsWidgetbookFormattedInputRu extends TranslationsWidgetbookFormattedInputKo {
	_TranslationsWidgetbookFormattedInputRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get date_format => 'Формат даты (ММ/ДД/ГГГГ)';
	@override String get time_format => 'Формат времени (ЧЧ:ММ)';
	@override String current_value({required Object value}) => 'Текущее значение: ${value}';
}

// Path: widgetbook.swiper
class _TranslationsWidgetbookSwiperRu extends TranslationsWidgetbookSwiperKo {
	_TranslationsWidgetbookSwiperRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get swipe_hint => 'Проведите или нажмите, чтобы открыть';
	@override String get overlay_content => 'Содержимое оверлея';
	@override String get close => 'Закрыть';
}

// Path: docs.common
class _TranslationsDocsCommonRu extends TranslationsDocsCommonKo {
	_TranslationsDocsCommonRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get app_name => 'coui_flutter';
	@override String get search_documentation => 'Поиск документации...';
	@override String get docs => 'Документация';
	@override String get components => 'Компоненты';
	@override String get close => 'Закрыть';
	@override String get on_this_page => 'Содержание на этой странице';
	@override String get work_in_progress_title => 'В процессе разработки';
	@override String get work_in_progress_message => 'Эта страница все еще находится в разработке. Пожалуйста, вернитесь позже.';
	@override String get add => 'Добавить';
	@override String get reset => 'Сбросить';
	@override String get prev => 'Назад';
	@override String get next => 'Вперед';
	@override String get finish => 'Завершить';
	@override String get open => 'Открыть';
	@override String get disabled => 'Отключен';
	@override String get refresh => 'Обновить';
	@override String get rebuild => 'Пересобрать';
	@override String get change_color => 'Изменить цвет';
}

// Path: docs.badges
class _TranslationsDocsBadgesRu extends TranslationsDocsBadgesKo {
	_TranslationsDocsBadgesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get k_new => 'новый';
	@override String get updated => 'обновлено';
	@override String get wip => 'в разработке';
	@override String get experimental => 'экспериментальный';
}

// Path: docs.flavors
class _TranslationsDocsFlavorsRu extends TranslationsDocsFlavorsKo {
	_TranslationsDocsFlavorsRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get local => 'локальный';
	@override String get experimental => 'экспериментальный';
	@override String get unknown => 'неизвестно';
}

// Path: docs.navigation
class _TranslationsDocsNavigationRu extends TranslationsDocsNavigationKo {
	_TranslationsDocsNavigationRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get getting_started => 'Начало работы';
	@override String get animation => 'Анимация';
	@override String get control => 'Управление';
	@override String get disclosure => 'Раскрытие';
	@override String get display => 'Отображение';
	@override String get feedback => 'Обратная связь';
	@override String get form => 'Форма';
	@override String get layout => 'Макет';
	@override String get navigation => 'Навигация';
	@override String get overlay => 'Накладка';
	@override String get utility => 'Утилиты';
	@override String get my_account => 'Мой аккаунт';
	@override String get profile => 'Профиль';
	@override String get settings => 'Настройки';
	@override String get team => 'Команда';
	@override String get new_team => 'Новая команда';
	@override String get billing => 'Счет';
	@override String get api => 'API';
	@override String get log_out => 'Выйти';
	@override String get support => 'Поддержка';
	@override String get invite_users => 'Пригласить пользователей';
	@override String get more => 'Еще';
	@override String get github => 'GitHub';
	@override String get note => 'Заметка';
	@override String get message => 'Сообщение';
	@override String get keyboard_shortcuts => 'Клавиатурные shortcuts';
}

// Path: docs.pages
class _TranslationsDocsPagesRu extends TranslationsDocsPagesKo {
	_TranslationsDocsPagesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsPagesIntroductionRu introduction = _TranslationsDocsPagesIntroductionRu._(_root);
	@override late final _TranslationsDocsPagesInstallationRu installation = _TranslationsDocsPagesInstallationRu._(_root);
	@override late final _TranslationsDocsPagesThemeRu theme = _TranslationsDocsPagesThemeRu._(_root);
	@override late final _TranslationsDocsPagesTypographyRu typography = _TranslationsDocsPagesTypographyRu._(_root);
	@override late final _TranslationsDocsPagesLayoutRu layout = _TranslationsDocsPagesLayoutRu._(_root);
	@override late final _TranslationsDocsPagesWebPreloaderRu web_preloader = _TranslationsDocsPagesWebPreloaderRu._(_root);
	@override late final _TranslationsDocsPagesComponentsListRu components_list = _TranslationsDocsPagesComponentsListRu._(_root);
	@override late final _TranslationsDocsPagesIconsRu icons = _TranslationsDocsPagesIconsRu._(_root);
	@override late final _TranslationsDocsPagesColorsRu colors = _TranslationsDocsPagesColorsRu._(_root);
	@override late final _TranslationsDocsPagesExternalRu external = _TranslationsDocsPagesExternalRu._(_root);
	@override late final _TranslationsDocsPagesStateRu state = _TranslationsDocsPagesStateRu._(_root);
}

// Path: docs.components
class _TranslationsDocsComponentsRu extends TranslationsDocsComponentsKo {
	_TranslationsDocsComponentsRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsComponentsAccordionRu accordion = _TranslationsDocsComponentsAccordionRu._(_root);
	@override late final _TranslationsDocsComponentsAlertRu alert = _TranslationsDocsComponentsAlertRu._(_root);
	@override late final _TranslationsDocsComponentsAlertDialogRu alert_dialog = _TranslationsDocsComponentsAlertDialogRu._(_root);
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderRu animated_value_builder = _TranslationsDocsComponentsAnimatedValueBuilderRu._(_root);
	@override late final _TranslationsDocsComponentsAppBarRu app_bar = _TranslationsDocsComponentsAppBarRu._(_root);
	@override late final _TranslationsDocsComponentsAutocompleteRu autocomplete = _TranslationsDocsComponentsAutocompleteRu._(_root);
	@override late final _TranslationsDocsComponentsAvatarRu avatar = _TranslationsDocsComponentsAvatarRu._(_root);
	@override late final _TranslationsDocsComponentsAvatarGroupRu avatar_group = _TranslationsDocsComponentsAvatarGroupRu._(_root);
	@override late final _TranslationsDocsComponentsBadgeRu badge = _TranslationsDocsComponentsBadgeRu._(_root);
	@override late final _TranslationsDocsComponentsBreadcrumbRu breadcrumb = _TranslationsDocsComponentsBreadcrumbRu._(_root);
	@override late final _TranslationsDocsComponentsButtonRu button = _TranslationsDocsComponentsButtonRu._(_root);
	@override late final _TranslationsDocsComponentsCalendarRu calendar = _TranslationsDocsComponentsCalendarRu._(_root);
	@override late final _TranslationsDocsComponentsCardRu card = _TranslationsDocsComponentsCardRu._(_root);
	@override late final _TranslationsDocsComponentsCardImageRu card_image = _TranslationsDocsComponentsCardImageRu._(_root);
	@override late final _TranslationsDocsComponentsCarouselRu carousel = _TranslationsDocsComponentsCarouselRu._(_root);
	@override late final _TranslationsDocsComponentsCheckboxRu checkbox = _TranslationsDocsComponentsCheckboxRu._(_root);
	@override late final _TranslationsDocsComponentsChipRu chip = _TranslationsDocsComponentsChipRu._(_root);
	@override late final _TranslationsDocsComponentsChipInputRu chip_input = _TranslationsDocsComponentsChipInputRu._(_root);
	@override late final _TranslationsDocsComponentsCircularProgressRu circular_progress = _TranslationsDocsComponentsCircularProgressRu._(_root);
	@override late final _TranslationsDocsComponentsCodeSnippetRu code_snippet = _TranslationsDocsComponentsCodeSnippetRu._(_root);
	@override late final _TranslationsDocsComponentsCollapsibleRu collapsible = _TranslationsDocsComponentsCollapsibleRu._(_root);
	@override late final _TranslationsDocsComponentsColorPickerRu color_picker = _TranslationsDocsComponentsColorPickerRu._(_root);
	@override late final _TranslationsDocsComponentsCommandRu command = _TranslationsDocsComponentsCommandRu._(_root);
	@override late final _TranslationsDocsComponentsContextMenuRu context_menu = _TranslationsDocsComponentsContextMenuRu._(_root);
	@override late final _TranslationsDocsComponentsDatePickerRu date_picker = _TranslationsDocsComponentsDatePickerRu._(_root);
	@override late final _TranslationsDocsComponentsDialogRu dialog = _TranslationsDocsComponentsDialogRu._(_root);
	@override late final _TranslationsDocsComponentsDividerRu divider = _TranslationsDocsComponentsDividerRu._(_root);
	@override late final _TranslationsDocsComponentsDotIndicatorRu dot_indicator = _TranslationsDocsComponentsDotIndicatorRu._(_root);
	@override late final _TranslationsDocsComponentsDrawerRu drawer = _TranslationsDocsComponentsDrawerRu._(_root);
	@override late final _TranslationsDocsComponentsDropdownMenuRu dropdown_menu = _TranslationsDocsComponentsDropdownMenuRu._(_root);
	@override late final _TranslationsDocsComponentsExpandableSidebarRu expandable_sidebar = _TranslationsDocsComponentsExpandableSidebarRu._(_root);
	@override late final _TranslationsDocsComponentsFormRu form = _TranslationsDocsComponentsFormRu._(_root);
	@override late final _TranslationsDocsComponentsFormattedInputRu formatted_input = _TranslationsDocsComponentsFormattedInputRu._(_root);
	@override late final _TranslationsDocsComponentsHoverCardRu hover_card = _TranslationsDocsComponentsHoverCardRu._(_root);
	@override late final _TranslationsDocsComponentsInputRu input = _TranslationsDocsComponentsInputRu._(_root);
	@override late final _TranslationsDocsComponentsInputOtpRu input_otp = _TranslationsDocsComponentsInputOtpRu._(_root);
	@override late final _TranslationsDocsComponentsItemPickerRu item_picker = _TranslationsDocsComponentsItemPickerRu._(_root);
	@override late final _TranslationsDocsComponentsKeyboardDisplayRu keyboard_display = _TranslationsDocsComponentsKeyboardDisplayRu._(_root);
	@override late final _TranslationsDocsComponentsLinearProgressRu linear_progress = _TranslationsDocsComponentsLinearProgressRu._(_root);
	@override late final _TranslationsDocsComponentsMaterialRu material = _TranslationsDocsComponentsMaterialRu._(_root);
	@override late final _TranslationsDocsComponentsMenubarRu menubar = _TranslationsDocsComponentsMenubarRu._(_root);
	@override late final _TranslationsDocsComponentsMultiselectRu multiselect = _TranslationsDocsComponentsMultiselectRu._(_root);
	@override late final _TranslationsDocsComponentsNavigationBarRu navigation_bar = _TranslationsDocsComponentsNavigationBarRu._(_root);
	@override late final _TranslationsDocsComponentsNavigationMenuRu navigation_menu = _TranslationsDocsComponentsNavigationMenuRu._(_root);
	@override late final _TranslationsDocsComponentsNavigationRailRu navigation_rail = _TranslationsDocsComponentsNavigationRailRu._(_root);
	@override late final _TranslationsDocsComponentsNavigationSidebarRu navigation_sidebar = _TranslationsDocsComponentsNavigationSidebarRu._(_root);
	@override late final _TranslationsDocsComponentsNumberInputRu number_input = _TranslationsDocsComponentsNumberInputRu._(_root);
	@override late final _TranslationsDocsComponentsNumberTickerRu number_ticker = _TranslationsDocsComponentsNumberTickerRu._(_root);
	@override late final _TranslationsDocsComponentsOverflowMarqueeRu overflow_marquee = _TranslationsDocsComponentsOverflowMarqueeRu._(_root);
	@override late final _TranslationsDocsComponentsPaginationRu pagination = _TranslationsDocsComponentsPaginationRu._(_root);
	@override late final _TranslationsDocsComponentsPhoneInputRu phone_input = _TranslationsDocsComponentsPhoneInputRu._(_root);
	@override late final _TranslationsDocsComponentsPopoverRu popover = _TranslationsDocsComponentsPopoverRu._(_root);
	@override late final _TranslationsDocsComponentsProgressRu progress = _TranslationsDocsComponentsProgressRu._(_root);
	@override late final _TranslationsDocsComponentsRadioCardRu radio_card = _TranslationsDocsComponentsRadioCardRu._(_root);
	@override late final _TranslationsDocsComponentsRadioGroupRu radio_group = _TranslationsDocsComponentsRadioGroupRu._(_root);
	@override late final _TranslationsDocsComponentsRefreshTriggerRu refresh_trigger = _TranslationsDocsComponentsRefreshTriggerRu._(_root);
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderRu repeated_animation_builder = _TranslationsDocsComponentsRepeatedAnimationBuilderRu._(_root);
	@override late final _TranslationsDocsComponentsResizableRu resizable = _TranslationsDocsComponentsResizableRu._(_root);
	@override late final _TranslationsDocsComponentsScaffoldRu scaffold = _TranslationsDocsComponentsScaffoldRu._(_root);
	@override late final _TranslationsDocsComponentsSelectRu select = _TranslationsDocsComponentsSelectRu._(_root);
	@override late final _TranslationsDocsComponentsSheetRu sheet = _TranslationsDocsComponentsSheetRu._(_root);
	@override late final _TranslationsDocsComponentsSkeletonRu skeleton = _TranslationsDocsComponentsSkeletonRu._(_root);
	@override late final _TranslationsDocsComponentsSliderRu slider = _TranslationsDocsComponentsSliderRu._(_root);
	@override late final _TranslationsDocsComponentsSortableRu sortable = _TranslationsDocsComponentsSortableRu._(_root);
	@override late final _TranslationsDocsComponentsStarRatingRu star_rating = _TranslationsDocsComponentsStarRatingRu._(_root);
	@override late final _TranslationsDocsComponentsStepperRu stepper = _TranslationsDocsComponentsStepperRu._(_root);
	@override late final _TranslationsDocsComponentsStepsRu steps = _TranslationsDocsComponentsStepsRu._(_root);
	@override late final _TranslationsDocsComponentsSwiperRu swiper = _TranslationsDocsComponentsSwiperRu._(_root);
	@override late final _TranslationsDocsComponentsKSwitchRu k_switch = _TranslationsDocsComponentsKSwitchRu._(_root);
	@override late final _TranslationsDocsComponentsSwitcherRu switcher = _TranslationsDocsComponentsSwitcherRu._(_root);
	@override late final _TranslationsDocsComponentsTabListRu tab_list = _TranslationsDocsComponentsTabListRu._(_root);
	@override late final _TranslationsDocsComponentsTabPaneRu tab_pane = _TranslationsDocsComponentsTabPaneRu._(_root);
	@override late final _TranslationsDocsComponentsTableRu table = _TranslationsDocsComponentsTableRu._(_root);
	@override late final _TranslationsDocsComponentsTabsRu tabs = _TranslationsDocsComponentsTabsRu._(_root);
	@override late final _TranslationsDocsComponentsTextAreaRu text_area = _TranslationsDocsComponentsTextAreaRu._(_root);
	@override late final _TranslationsDocsComponentsTimePickerRu time_picker = _TranslationsDocsComponentsTimePickerRu._(_root);
	@override late final _TranslationsDocsComponentsTimelineRu timeline = _TranslationsDocsComponentsTimelineRu._(_root);
	@override late final _TranslationsDocsComponentsTimelineAnimationRu timeline_animation = _TranslationsDocsComponentsTimelineAnimationRu._(_root);
	@override late final _TranslationsDocsComponentsToastRu toast = _TranslationsDocsComponentsToastRu._(_root);
	@override late final _TranslationsDocsComponentsToggleRu toggle = _TranslationsDocsComponentsToggleRu._(_root);
	@override late final _TranslationsDocsComponentsTooltipRu tooltip = _TranslationsDocsComponentsTooltipRu._(_root);
	@override late final _TranslationsDocsComponentsTrackerRu tracker = _TranslationsDocsComponentsTrackerRu._(_root);
	@override late final _TranslationsDocsComponentsTreeRu tree = _TranslationsDocsComponentsTreeRu._(_root);
	@override late final _TranslationsDocsComponentsWindowRu window = _TranslationsDocsComponentsWindowRu._(_root);
}

// Path: docs.pages.introduction
class _TranslationsDocsPagesIntroductionRu extends TranslationsDocsPagesIntroductionKo {
	_TranslationsDocsPagesIntroductionRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Введение';
	@override String get description => 'Начало работы с coui_flutter';
	@override String get lead => 'Теперь удивительно разработанные компоненты Coui/UI доступны в Flutter.';
	@override String get welcome_paragraph_1 => 'coui_flutter — это набор разнообразных и обширных компонентов пользовательского интерфейса, специально разработанный для настольных и веб-приложений Flutter. С ростом популярности Flutter для создания кросс-платформенных приложений мы осознали необходимость в наборе инструментов, подчеркивающем уникальные требования дизайна настольных и веб-интерфейсов.';
	@override String get welcome_paragraph_2 => 'Этот пакет предлагает широкий выбор настраиваемых и отзывчивых компонентов, соответствующих современным принципам дизайна для настольных и веб-приложений. Будь то создание сложного бизнес-приложения, стильной панели мониторинга или инструмента для повышения производительности, наши компоненты были разработаны, чтобы помочь вам быстро и эффективно создать профессиональный и стильный пользовательский интерфейс.';
	@override String get features => 'Основные функции';
	@override late final _TranslationsDocsPagesIntroductionFeaturesListRu features_list = _TranslationsDocsPagesIntroductionFeaturesListRu._(_root);
	@override String get notes => 'Примечания';
	@override String get notes_paragraph_1 => 'Этот пакет все еще находится в разработке и может претерпеть изменения в будущем. Будьте осторожны, используя этот пакет в производстве.';
	@override String get notes_paragraph_2 => 'Этот пакет не аффилирован с Coui/UI. Этот пакет является проектом, который ведется сообществом.';
	@override String get faq => 'Часто задаваемые вопросы';
	@override String get faq_gorouter_q => 'Поддерживает ли GoRouter?';
	@override String get faq_gorouter_a => 'Да, поддерживает. Вы можете использовать GoRouter с coui_flutter.';
	@override String get faq_usage_q => 'Можно ли использовать в моем проекте?';
	@override String get faq_usage_a => 'Да! Вы можете использовать его бесплатно как в личных, так и в коммерческих проектах. Не требуется атрибуция.';
	@override String get faq_material_q => 'Можно ли использовать с виджетами Material/Cupertino?';
	@override String get faq_material_a_1 => 'Конечно!';
	@override String get faq_material_a_2 => 'Смотрите эту страницу!';
	@override String get faq_style_q => 'Можно ли настроить стиль? (Default/New York)';
	@override String get faq_style_a_1 => 'К сожалению, нет. Этот пакет поддерживает только стиль New York. Но если вам нужен базовый стиль Coui/UI,';
	@override String get faq_style_a_2 => 'рекомендуем этот пакет.';
	@override String get faq_style_a_3 => 'Создатель:';
	@override String get links => 'Ссылки';
	@override String get link_github => 'Github: ';
	@override String get link_pubdev => 'pub.dev: ';
	@override String get link_discord => 'Discord: ';
}

// Path: docs.pages.installation
class _TranslationsDocsPagesInstallationRu extends TranslationsDocsPagesInstallationKo {
	_TranslationsDocsPagesInstallationRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Установка';
	@override String get description => 'Установите coui_flutter в проект';
	@override String get stable_version => 'Стабильная версия';
	@override String get experimental_version => 'Экспериментальная версия';
	@override String get step1_title => 'Создание нового проекта Flutter';
	@override String get step1_content => 'Создайте новый проект Flutter, используя следующую команду:';
	@override String get step2_title => 'Добавление зависимостей';
	@override String get step2_content => 'Далее добавьте зависимость coui_flutter в проект.';
	@override String get step3_title => 'Импорт пакета';
	@override String get step3_content => 'Теперь вы можете импортировать пакет в коде Dart.';
	@override String get step4_title => 'Добавление виджета CouiApp';
	@override String get step4_content => 'Добавьте виджет CouiApp в функцию main.';
	@override String get step5_title => 'Запуск приложения';
	@override String get step5_content => 'Запустите приложение, используя следующую команду:';
	@override String get experimental_intro => 'Экспериментальная версия доступна на GitHub.';
	@override String get experimental_usage => 'Чтобы использовать экспериментальную версию, используйте git вместо номера версии в файле pubspec.yaml:';
	@override String get see_page => 'Смотрите страницу: ';
	@override String get this_page => 'Эта страница';
	@override String get for_more_info => ' для получения дополнительной информации.';
	@override String get warning_title => 'Предупреждение';
	@override String get warning_content => 'Экспериментальная версия может содержать изменения, нарушающие совместимость, и не рекомендуется для использования в производстве. Эта версия предназначена только для тестирования и разработки.';
}

// Path: docs.pages.theme
class _TranslationsDocsPagesThemeRu extends TranslationsDocsPagesThemeKo {
	_TranslationsDocsPagesThemeRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Тема';
	@override String get description => 'Настройка темы';
	@override String get custom_color_scheme => 'Пользовательская цветовая схема';
	@override String get custom_color_scheme_desc => 'Вы можете настроить внешний вид и ощущение вашего приложения, используя пользовательскую цветовую схему.';
	@override String get premade_color_schemes => 'Предоставленные цветовые схемы';
	@override String get premade_color_schemes_desc => 'Вы можете настроить внешний вид и ощущение вашего приложения, используя предоставленные цветовые схемы.';
	@override String get radius => 'Радиус';
	@override String get radius_desc => 'Вы можете изменить радиус, чтобы настроить, насколько округлым будет выглядеть приложение.';
	@override String get scaling => 'Масштабирование';
	@override String get scaling_desc => 'Вы можете настроить масштаб coui_flutter компонентов, изменяя масштабирование.';
	@override String get scaling_alert => 'Это не масштабирует все приложение. Это влияет только на компоненты coui_flutter.';
	@override String get surface_opacity => 'Непрозрачность поверхности';
	@override String get surface_opacity_desc => 'Вы можете настроить непрозрачность поверхности, изменяя непрозрачность.';
	@override String get surface_blur => 'Размытие поверхности';
	@override String get surface_blur_desc => 'Вы можете настроить размытие поверхности, изменяя его значение.';
	@override String get code => 'Код';
	@override String get code_desc => 'Используйте следующий код, чтобы применить цветовую схему.';
}

// Path: docs.pages.typography
class _TranslationsDocsPagesTypographyRu extends TranslationsDocsPagesTypographyKo {
	_TranslationsDocsPagesTypographyRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Типография';
	@override String get description => 'Стиль текста';
	@override String get headline1 => 'Заголовок 1';
	@override String get headline2 => 'Заголовок 2';
	@override String get headline3 => 'Заголовок 3';
	@override String get headline4 => 'Заголовок 4';
	@override String get paragraph => 'Абзац';
	@override String get blockquote => 'Цитата';
	@override String get list => 'Список';
	@override String get inline_code => 'Встраиваемый код';
	@override String get lead => 'Вводный текст';
	@override String get large_text => 'Большой текст';
	@override String get small_text => 'Маленький текст';
	@override String get muted_text => 'Серый текст';
	@override String get sans => 'Без засечек';
	@override String get mono => 'Моно';
	@override String get extra_small => 'Очень маленький';
	@override String get small => 'Маленький';
	@override String get base => 'Базовый';
	@override String get large => 'Большой';
	@override String get extra_large => 'Очень большой';
	@override String get extra_2x_large => 'В два раза больше';
	@override String get extra_3x_large => 'В три раза больше';
	@override String get extra_4x_large => 'В четыре раза больше';
	@override String get extra_5x_large => 'В пять раз больше';
	@override String get extra_6x_large => 'В шесть раз больше';
	@override String get extra_7x_large => 'В семь раз больше';
	@override String get extra_8x_large => 'В восемь раз больше';
	@override String get extra_9x_large => 'В девять раз больше';
	@override String get thin => 'Тонкий';
	@override String get extra_light => 'Очень легкий';
	@override String get light => 'Легкий';
	@override String get normal => 'Нормальный';
	@override String get medium => 'Средний';
	@override String get semi_bold => 'Полужирный';
	@override String get bold => 'Жирный';
	@override String get extra_bold => 'Очень жирный';
	@override String get black => 'Черный';
	@override String get italic => 'Курсив';
}

// Path: docs.pages.layout
class _TranslationsDocsPagesLayoutRu extends TranslationsDocsPagesLayoutKo {
	_TranslationsDocsPagesLayoutRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Макет';
	@override String get description => 'Структура страницы';
	@override String get padding => 'отступ';
	@override String get margin => 'поле';
	@override String get center => 'центр';
	@override String get gapped_column => 'колонка с пропусками';
	@override String get gapped_row => 'ряд с пропусками';
	@override String get separated_column => 'разделенная колонка';
	@override String get separated_row => 'разделенный ряд';
	@override String get basic_layout => 'основной макет';
}

// Path: docs.pages.web_preloader
class _TranslationsDocsPagesWebPreloaderRu extends TranslationsDocsPagesWebPreloaderKo {
	_TranslationsDocsPagesWebPreloaderRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Веб Прелоадер';
	@override String get description => 'Экран загрузки веба';
	@override String get step1_title => 'Создание веб-директории';
	@override String get step1_content => 'Создайте веб-директорию, если ее нет.';
	@override String get step1_note => '* Если вы используете устаревший Flutter Web, вам необходимо обновить с помощью приведенной выше команды.';
	@override String get step1_button => 'Нажмите здесь для получения дополнительной информации.';
	@override String get step2_title => 'Добавление скрипта';
	@override String get step2_content => 'Затем выберите и скопируйте один из следующих заранее созданных прелоадеров:';
	@override String get step2_standard => 'Стандартный прелоадер';
	@override String get step3_title => 'Вставьте скрипт';
	@override String get step3_content_1 => 'Откройте';
	@override String get step3_content_2 => 'файл и вставьте скрипт в теге';
	@override String get step3_content_3 => '.';
	@override String get step3_example => 'Например:';
	@override String get step4_title => 'Запуск приложения';
	@override String get step4_content => 'Запустите приложение с помощью следующей команды:';
	@override String get alert_title => 'Сделать вклад';
	@override String get alert_content_1 => 'Если у вас есть прелоадер, которым вы хотите поделиться, создайте pull request в каталоге ';
	@override String get alert_button => 'web_loaders';
	@override String get alert_content_2 => '.';
}

// Path: docs.pages.components_list
class _TranslationsDocsPagesComponentsListRu extends TranslationsDocsPagesComponentsListKo {
	_TranslationsDocsPagesComponentsListRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Компоненты';
	@override String get description => 'Список повторно используемых компонентов';
	@override String get work_in_progress => 'В процессе работы';
	@override String get animation => 'Анимация';
	@override String get disclosure => 'Раскрытие';
	@override String get feedback => 'Обратная связь';
	@override String get forms => 'Формы';
	@override String get layout => 'Вёрстка';
	@override String get navigation => 'Навигация';
	@override String get surfaces => 'Поверхности';
	@override String get data_display => 'Отображение данных';
	@override String get utilities => 'Утилиты';
}

// Path: docs.pages.icons
class _TranslationsDocsPagesIconsRu extends TranslationsDocsPagesIconsKo {
	_TranslationsDocsPagesIconsRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Иконки';
	@override String get description => 'Система иконок';
	@override String get use_this_code => 'Чтобы отобразить этот значок, используйте следующий код:';
	@override String get search_icons => 'Поиск значков';
	@override String get radix_icons => 'Иконки Radix';
	@override String get bootstrap_icons => 'Иконки Bootstrap';
	@override String get lucide_icons => 'Иконки Lucide';
}

// Path: docs.pages.colors
class _TranslationsDocsPagesColorsRu extends TranslationsDocsPagesColorsKo {
	_TranslationsDocsPagesColorsRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Цвета';
	@override String get description => 'Цветовая палитра';
	@override String get use_this_code => 'Чтобы отобразить этот цвет, используйте следующий код:';
	@override String get color_and_colorshades => 'Константы Color и ColorShades/ColorSwatch';
	@override String get predefined_colors => 'Предопределенные цвета';
	@override String get generate_color => 'Генерация цвета';
	@override String get hue_shift => 'Смещение оттенка';
	@override String get saturation_step_up => 'Шаг увеличения насыщенности';
	@override String get saturation_step_down => 'Шаг уменьшения насыщенности';
	@override String get lightness_step_up => 'Шаг увеличения светлоты';
	@override String get lightness_step_down => 'Шаг уменьшения светлоты';
	@override String get cancel => 'отмена';
	@override String get reset_options => 'Сбросить параметры';
	@override String get reset_confirmation => 'Вы уверены, что хотите сбросить параметры?';
}

// Path: docs.pages.external
class _TranslationsDocsPagesExternalRu extends TranslationsDocsPagesExternalKo {
	_TranslationsDocsPagesExternalRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Material/Cupertino';
	@override String get description => 'Использование стандартных виджетов Flutter';
}

// Path: docs.pages.state
class _TranslationsDocsPagesStateRu extends TranslationsDocsPagesStateKo {
	_TranslationsDocsPagesStateRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get title => 'Управление состоянием';
	@override String get description => 'Шаблоны управления состоянием';
	@override String get intro_1 => 'В Flutter все является виджетом, в том числе и место, где хранятся данные.';
	@override String get intro_2 => 'Внутри coui_flutter есть собственная система управления состоянием. Если вы уже используете систему управления состоянием, вы можете продолжать использовать ее вместе с coui_flutter.';
	@override String get passing_data_to_children => 'Передача данных дочерним элементам';
	@override String get passing_data_desc => 'Данные можно передавать дочерним компонентам с помощью виджета Data. Все изменения данных вызовут повторную сборку дочерних элементов.';
	@override String get rebuild_difference_title => 'Вы заметили разницу в количестве повторных сборок?';
	@override String get rebuild_difference_content => 'MostInnerWidget пересоздается при изменении данных, в то время как InnerWidget не пересоздается. Это связано с тем, что InnerWidget не получает данные.';
	@override String get setting_data_boundary => 'Установка границы данных';
	@override String get setting_data_boundary_desc => 'Вы можете установить границу, чтобы дочерние элементы не могли получить доступ к данным.';
	@override String get data_methods_vs => 'Data.maybeOf/Data.of против Data.maybeFind/Data.find';
	@override String get data_methods_desc_1 => 'и';
	@override String get data_methods_desc_2 => 'принимают данные и пересобирают виджет при их изменении. В то время как';
	@override String get data_methods_desc_3 => 'не принимают данные и лишь возвращают их.';
	@override String get data_find_usage => 'Удобно использовать в местах, где методы вызываются один раз, таких как onPressed, onLongPressed и т.д.';
	@override String get data_of_usage => 'Удобно использовать в методе build, где виджеты нужно пересобрать при изменении данных.';
	@override String get getting_data_from_child => 'Получение данных от дочерних элементов';
	@override String get getting_data_desc_1 => 'Метод можно использовать для получения данных от дочерних элементов. Этот метод не будет получать изменения данных.';
	@override String get getting_data_desc_2 => 'Если вы получите данные от дочернего элемента, это может привести к бесконечному циклу сборки. Если вы должны получать данные, переместите их в родительский виджет.';
	@override String get root_data_title => 'Вы заметили корневые данные?';
	@override String get root_data_content => 'Данные используются из самых внутренних данных слева. Родитель может получать данные только из первого подключенного дочернего элемента.';
	@override String get setting_messenger_boundary => 'Установка границы DataMessenger';
	@override String get setting_messenger_boundary_desc => 'Вы можете установить границу, чтобы дочерние элементы не могли получить данные от определённого родителя.';
	@override String get multidata_widget => 'Виджет MultiData';
	@override String get multidata_desc => 'Используйте виджет MultiData для передачи нескольких данных дочерним элементам. Вот пример:';
	@override String get multidata_avoid_nesting => 'С помощью виджета MultiData можно избежать вложенности.';
	@override String get example => 'Пример';
	@override String get passing_state_as_controller => 'Передача состояния в качестве контроллера';
	@override String get passing_state_controller_desc => 'Состояние можно передать как контроллер дочерним элементам. Это позволяет дочерним виджетам вызывать методы родительского виджета.';
	@override String get databuilder => 'DataBuilder';
	@override String get databuilder_desc => 'Используйте виджет DataBuilder, чтобы пересобрать виджет при изменении данных. Это помогает избежать полной пересборки виджета.';
	@override String get datanotifier => 'DataNotifier';
	@override String get datanotifier_desc => 'С помощью DataNotifier можно передавать значения дочерним элементам через ValueListenable.';
	@override String get example_with_multidata => 'Пример с использованием MultiData';
	@override String get passing_object_as_data => 'Передача объекта как данных';
	@override String get passing_object_desc => 'Вот несколько моментов, на которые стоит обратить внимание при передаче объекта как данных:';
	@override String get override_equals_hashcode => '1. Переопределите == и hashCode';
	@override String get override_equals_desc => 'Если предыдущий объект не равен новому, уведомление будет отправлено дочернему элементу. Если вы не переопределите == и hashCode, каждый раз будет считаться, что объект отличается, даже если значения полей одинаковы.';
	@override String get use_distinctdata => '2. Используйте DistinctData';
	@override String get use_distinctdata_desc => 'DistinctData - это миксин, который может уведомлять дочерние элементы при изменении определенного поля.';
	@override String get passing_mutable_object => '3. Передача изменяемого объекта дочерним элементам';
	@override String get passing_mutable_object_desc => 'Рекомендуется передавать дочерним элементам неизменяемые объекты. Изменяемые объекты (например, List, Map, Set, Widget State) не уведомят дочерние элементы при изменении объекта, если ссылка на объект не меняется.';
	@override String get passing_variable_to_children => 'Передача переменной дочерним элементам';
	@override String get passing_variable_desc => 'Можно использовать виджет Model для передачи переменной дочерним элементам. Это похоже на виджет Data, но более строгий по типам и имеет метки.';
	@override String get change_variable_from_children => 'Изменение переменной из дочерних элементов';
	@override String get change_variable_desc => 'Есть два способа изменить значение модели из дочерних элементов:';
	@override String get modelnotifier => 'ModelNotifier';
	@override String get modelnotifier_desc => 'С помощью ModelNotifier можно передавать значения дочерним элементам через ValueNotifier, не используя setState родительским виджетом.';
	@override String get modellistenable => 'ModelListenable';
	@override String get modellistenable_desc => 'ModelListenable - это только для чтения ModelNotifier. Дочерние элементы могут только получать значения. Если они попытаются изменить значение, возникнет ошибка.';
	@override String get modelbuilder => 'ModelBuilder';
	@override String get modelbuilder_desc => 'ModelBuilder получает значения и пересобирает виджет, когда они изменяются. Это похоже на DataBuilder, но более строгий по типам и имеет метки.';
}

// Path: docs.components.accordion
class _TranslationsDocsComponentsAccordionRu extends TranslationsDocsComponentsAccordionKo {
	_TranslationsDocsComponentsAccordionRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Аккордеон';
	@override String get description => 'Аккордеон — это список элементов, расположенных вертикально. Каждый элемент можно \'развернуть\' или \'свернуть\', чтобы отобразить связанный с ним контент.';
	@override late final _TranslationsDocsComponentsAccordionExamplesRu examples = _TranslationsDocsComponentsAccordionExamplesRu._(_root);
}

// Path: docs.components.alert
class _TranslationsDocsComponentsAlertRu extends TranslationsDocsComponentsAlertKo {
	_TranslationsDocsComponentsAlertRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Уведомление';
	@override String get description => 'Уведомления используются для передачи состояния, влияющего на систему.';
	@override late final _TranslationsDocsComponentsAlertExamplesRu examples = _TranslationsDocsComponentsAlertExamplesRu._(_root);
	@override String get title => 'Заголовок уведомления';
	@override String get content => 'Содержимое уведомления.';
}

// Path: docs.components.alert_dialog
class _TranslationsDocsComponentsAlertDialogRu extends TranslationsDocsComponentsAlertDialogKo {
	_TranslationsDocsComponentsAlertDialogRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Диалоговое уведомление';
	@override String get description => 'Диалоговое уведомление отображает важную информацию, требующую внимания пользователя.';
	@override late final _TranslationsDocsComponentsAlertDialogExamplesRu examples = _TranslationsDocsComponentsAlertDialogExamplesRu._(_root);
	@override String get click_here => 'Нажмите сюда';
	@override String get alert_title => 'Заголовок уведомления';
	@override String get alert_content => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
}

// Path: docs.components.animated_value_builder
class _TranslationsDocsComponentsAnimatedValueBuilderRu extends TranslationsDocsComponentsAnimatedValueBuilderKo {
	_TranslationsDocsComponentsAnimatedValueBuilderRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Строитель анимированных значений';
	@override String get description => 'Строитель, который автоматически применяет анимацию при изменении значений.';
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderExamplesRu examples = _TranslationsDocsComponentsAnimatedValueBuilderExamplesRu._(_root);
}

// Path: docs.components.app_bar
class _TranslationsDocsComponentsAppBarRu extends TranslationsDocsComponentsAppBarKo {
	_TranslationsDocsComponentsAppBarRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Панель приложения';
	@override String get description => 'Панель приложения — это основной элемент навигации, отображаемый в верхней части приложения.';
	@override late final _TranslationsDocsComponentsAppBarExamplesRu examples = _TranslationsDocsComponentsAppBarExamplesRu._(_root);
}

// Path: docs.components.autocomplete
class _TranslationsDocsComponentsAutocompleteRu extends TranslationsDocsComponentsAutocompleteKo {
	_TranslationsDocsComponentsAutocompleteRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Ававтоматическая подсказка';
	@override String get description => 'Поле ввода, отображающее предложения в зависимости от ввода пользователя.';
	@override late final _TranslationsDocsComponentsAutocompleteExamplesRu examples = _TranslationsDocsComponentsAutocompleteExamplesRu._(_root);
}

// Path: docs.components.avatar
class _TranslationsDocsComponentsAvatarRu extends TranslationsDocsComponentsAvatarKo {
	_TranslationsDocsComponentsAvatarRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Аватар';
	@override String get description => 'Изображение или иконка, представляющая пользователя или объект.';
	@override late final _TranslationsDocsComponentsAvatarExamplesRu examples = _TranslationsDocsComponentsAvatarExamplesRu._(_root);
}

// Path: docs.components.avatar_group
class _TranslationsDocsComponentsAvatarGroupRu extends TranslationsDocsComponentsAvatarGroupKo {
	_TranslationsDocsComponentsAvatarGroupRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Группа аватаров';
	@override String get description => 'Отображает несколько аватаров вместе.';
	@override late final _TranslationsDocsComponentsAvatarGroupExamplesRu examples = _TranslationsDocsComponentsAvatarGroupExamplesRu._(_root);
}

// Path: docs.components.badge
class _TranslationsDocsComponentsBadgeRu extends TranslationsDocsComponentsBadgeKo {
	_TranslationsDocsComponentsBadgeRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Значок';
	@override String get description => 'Небольшая метка, отображающая статус или количество уведомлений.';
	@override late final _TranslationsDocsComponentsBadgeExamplesRu examples = _TranslationsDocsComponentsBadgeExamplesRu._(_root);
	@override String get primary => 'Основной';
	@override String get secondary => 'Вторичный';
	@override String get outline => 'Контур';
	@override String get destructive => 'Опасный';
}

// Path: docs.components.breadcrumb
class _TranslationsDocsComponentsBreadcrumbRu extends TranslationsDocsComponentsBreadcrumbKo {
	_TranslationsDocsComponentsBreadcrumbRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Хлебные крошки';
	@override String get description => 'Хлебные крошки — это вспомогательная навигационная система, указывающая местоположение пользователя на веб-сайте или в веб-приложении.';
	@override late final _TranslationsDocsComponentsBreadcrumbExamplesRu examples = _TranslationsDocsComponentsBreadcrumbExamplesRu._(_root);
	@override String get home => 'Главная';
	@override String get components => 'Компоненты';
}

// Path: docs.components.button
class _TranslationsDocsComponentsButtonRu extends TranslationsDocsComponentsButtonKo {
	_TranslationsDocsComponentsButtonRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Кнопка';
	@override String get description => 'Кнопки позволяют пользователю выполнять действия и делать выбор одним нажатием.';
	@override late final _TranslationsDocsComponentsButtonExamplesRu examples = _TranslationsDocsComponentsButtonExamplesRu._(_root);
	@override String get primary => 'Основной';
	@override String get secondary => 'Вторичный';
	@override String get outlined => 'Контурный';
	@override String get ghost => 'Призрак';
	@override String get destructive => 'Опасный';
	@override String get link => 'Ссылка';
	@override String get outline => 'Контур';
	@override String get text => 'Текст';
	@override String get extra_small => 'Супер маленький';
	@override String get small => 'Маленький';
	@override String get normal => 'Нормальный';
	@override String get large => 'Большой';
	@override String get extra_large => 'Супер большой';
	@override String get save => 'Сохранить';
	@override String get cancel => 'Отменить';
	@override String get close => 'Закрыть';
	@override String get submit => 'Подтвердить';
	@override String get edit_profile => 'Редактировать профиль';
	@override String get save_changes => 'Сохранить изменения';
	@override String get undo => 'Отменить';
	@override String get compact => 'Компактный';
	@override String get dense => 'Плотный';
	@override String get comfortable => 'Удобный';
	@override String get icon => 'Иконка';
	@override String get icon_comfortable => 'Удобная иконка';
	@override String get rectangle => 'Прямоугольник';
	@override String get add => 'Добавить';
	@override String get focused => 'В фокусе';
	@override String get hovered => 'Нависший';
	@override String get pressed => 'Нажатый';
	@override String get text_button => 'Текстовая кнопка';
	@override String get custom_button => 'Пользовательская кнопка';
}

// Path: docs.components.calendar
class _TranslationsDocsComponentsCalendarRu extends TranslationsDocsComponentsCalendarKo {
	_TranslationsDocsComponentsCalendarRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Календарь';
	@override String get description => 'Компонент для выбора и отображения даты.';
	@override late final _TranslationsDocsComponentsCalendarExamplesRu examples = _TranslationsDocsComponentsCalendarExamplesRu._(_root);
}

// Path: docs.components.card
class _TranslationsDocsComponentsCardRu extends TranslationsDocsComponentsCardKo {
	_TranslationsDocsComponentsCardRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Карточка';
	@override String get description => 'Описание';
	@override late final _TranslationsDocsComponentsCardExamplesRu examples = _TranslationsDocsComponentsCardExamplesRu._(_root);
	@override String get create_project => 'Создать проект';
	@override String get deploy_description => 'Разверните новый проект одним кликом';
	@override String get name => 'Имя';
	@override String get name_placeholder => 'Название проекта';
	@override String get description_placeholder => 'Описание проекта';
	@override String get deploy => 'Развернуть';
}

// Path: docs.components.card_image
class _TranslationsDocsComponentsCardImageRu extends TranslationsDocsComponentsCardImageKo {
	_TranslationsDocsComponentsCardImageRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Карточка с изображением';
	@override String get description => 'Компонент карточки с изображением.';
	@override late final _TranslationsDocsComponentsCardImageExamplesRu examples = _TranslationsDocsComponentsCardImageExamplesRu._(_root);
	@override String get card_image_title => 'Изображение карточки';
	@override String get card_clicked => 'Кликнули на изображение карточки';
	@override String card_number({required Object n}) => 'Карточка номер ${n}';
	@override String get lorem_ipsum => 'Lorem ipsum dolor sit amet';
}

// Path: docs.components.carousel
class _TranslationsDocsComponentsCarouselRu extends TranslationsDocsComponentsCarouselKo {
	_TranslationsDocsComponentsCarouselRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Карусель';
	@override String get description => 'Компонент для отображения нескольких элементов с помощью слайдов.';
	@override late final _TranslationsDocsComponentsCarouselExamplesRu examples = _TranslationsDocsComponentsCarouselExamplesRu._(_root);
}

// Path: docs.components.checkbox
class _TranslationsDocsComponentsCheckboxRu extends TranslationsDocsComponentsCheckboxKo {
	_TranslationsDocsComponentsCheckboxRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Чекбокс';
	@override String get description => 'Чекбокс позволяет пользователю выбрать один или несколько элементов из списка.';
	@override late final _TranslationsDocsComponentsCheckboxExamplesRu examples = _TranslationsDocsComponentsCheckboxExamplesRu._(_root);
	@override String get remember_me => 'Запомнить меня';
}

// Path: docs.components.chip
class _TranslationsDocsComponentsChipRu extends TranslationsDocsComponentsChipKo {
	_TranslationsDocsComponentsChipRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Чип';
	@override String get description => 'Чипы — это небольшие элементы, представляющие атрибуты, варианты или действия.';
	@override late final _TranslationsDocsComponentsChipExamplesRu examples = _TranslationsDocsComponentsChipExamplesRu._(_root);
	@override String get apple => 'Яблоко';
	@override String get banana => 'Банан';
	@override String get cherry => 'Вишня';
	@override String get durian => 'Дуриан';
	@override String get elderberry => 'Бузина';
}

// Path: docs.components.chip_input
class _TranslationsDocsComponentsChipInputRu extends TranslationsDocsComponentsChipInputKo {
	_TranslationsDocsComponentsChipInputRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Ввод чипов';
	@override String get description => 'Поле ввода, позволяющее вводить несколько значений в виде чипов.';
	@override late final _TranslationsDocsComponentsChipInputExamplesRu examples = _TranslationsDocsComponentsChipInputExamplesRu._(_root);
}

// Path: docs.components.circular_progress
class _TranslationsDocsComponentsCircularProgressRu extends TranslationsDocsComponentsCircularProgressKo {
	_TranslationsDocsComponentsCircularProgressRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Круговой прогресс';
	@override String get description => 'Круговой индикатор прогресса.';
	@override late final _TranslationsDocsComponentsCircularProgressExamplesRu examples = _TranslationsDocsComponentsCircularProgressExamplesRu._(_root);
	@override String get increase_by_10 => 'Увеличить на 10';
	@override String get decrease_by_10 => 'Уменьшить на 10';
}

// Path: docs.components.code_snippet
class _TranslationsDocsComponentsCodeSnippetRu extends TranslationsDocsComponentsCodeSnippetKo {
	_TranslationsDocsComponentsCodeSnippetRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Фрагмент кода';
	@override String get description => 'Компонент для отображения кода.';
	@override late final _TranslationsDocsComponentsCodeSnippetExamplesRu examples = _TranslationsDocsComponentsCodeSnippetExamplesRu._(_root);
}

// Path: docs.components.collapsible
class _TranslationsDocsComponentsCollapsibleRu extends TranslationsDocsComponentsCollapsibleKo {
	_TranslationsDocsComponentsCollapsibleRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Складной';
	@override String get description => 'Контейнер с контентом, который можно свернуть или развернуть.';
	@override late final _TranslationsDocsComponentsCollapsibleExamplesRu examples = _TranslationsDocsComponentsCollapsibleExamplesRu._(_root);
	@override String get starred_repositories => '@coco-de руководитель выделил 3 репозитория';
	@override String get collapse_all => 'Свернуть все';
	@override String get expand_all => 'Развернуть все';
	@override String get expand_icon => 'Иконка развертывания';
	@override String get use_path_branch => 'Использовать ветвь пути';
	@override String get recursive_selection => 'Рекурсивный выбор';
}

// Path: docs.components.color_picker
class _TranslationsDocsComponentsColorPickerRu extends TranslationsDocsComponentsColorPickerKo {
	_TranslationsDocsComponentsColorPickerRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Выбор цвета';
	@override String get description => 'Компонент для выбора цвета.';
	@override late final _TranslationsDocsComponentsColorPickerExamplesRu examples = _TranslationsDocsComponentsColorPickerExamplesRu._(_root);
	@override String get pick_color => 'Выберите цвет';
	@override String color_label({required Object color}) => 'Цвет: ${color}';
	@override String get select_color => 'Выберите цвет';
	@override String get open_color_picker_popover => 'Открыть всплывающее окно выбора цвета';
	@override String get open_color_picker_dialog => 'Открыть диалог выбора цвета';
}

// Path: docs.components.command
class _TranslationsDocsComponentsCommandRu extends TranslationsDocsComponentsCommandKo {
	_TranslationsDocsComponentsCommandRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Команда';
	@override String get description => 'Компонент, позволяющий искать элементы.';
	@override late final _TranslationsDocsComponentsCommandExamplesRu examples = _TranslationsDocsComponentsCommandExamplesRu._(_root);
}

// Path: docs.components.context_menu
class _TranslationsDocsComponentsContextMenuRu extends TranslationsDocsComponentsContextMenuKo {
	_TranslationsDocsComponentsContextMenuRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Контекстное меню';
	@override String get description => 'Меню, отображаемое при правом клике или долгом нажатии.';
	@override late final _TranslationsDocsComponentsContextMenuExamplesRu examples = _TranslationsDocsComponentsContextMenuExamplesRu._(_root);
}

// Path: docs.components.date_picker
class _TranslationsDocsComponentsDatePickerRu extends TranslationsDocsComponentsDatePickerKo {
	_TranslationsDocsComponentsDatePickerRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Выбор даты';
	@override String get description => 'Поле ввода для выбора даты.';
	@override late final _TranslationsDocsComponentsDatePickerExamplesRu examples = _TranslationsDocsComponentsDatePickerExamplesRu._(_root);
	@override String get select_date => 'Выберите дату';
	@override String get select_date_range => 'Выберите диапазон дат';
}

// Path: docs.components.dialog
class _TranslationsDocsComponentsDialogRu extends TranslationsDocsComponentsDialogKo {
	_TranslationsDocsComponentsDialogRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Диалог';
	@override String get description => 'Диалог — это модальное окно, отображаемое поверх остальной части приложения.';
	@override late final _TranslationsDocsComponentsDialogExamplesRu examples = _TranslationsDocsComponentsDialogExamplesRu._(_root);
	@override String get edit_profile_title => 'Редактировать профиль';
	@override String get edit_profile_description => 'Измените ваш профиль здесь. Нажмите сохранить, когда закончите.';
	@override String get name_label => 'Имя';
	@override String get username_label => 'Имя пользователя';
	@override String get hello => 'Здравствуйте';
	@override String get material_dialog_content => 'Материальный диалог.';
	@override String get cupertino_dialog_content => 'Cupertino диалог.';
	@override String get alert_title => 'Заголовок уведомления';
	@override String get click_here => 'Нажмите сюда';
	@override String get ok => 'ОК';
	@override String get open_material_dialog => 'Открыть материальный диалог';
	@override String get open_cupertino_dialog => 'Открыть Cupertino диалог';
	@override String get open_coui_dialog => 'Открыть COUI диалог';
}

// Path: docs.components.divider
class _TranslationsDocsComponentsDividerRu extends TranslationsDocsComponentsDividerKo {
	_TranslationsDocsComponentsDividerRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Делитель';
	@override String get description => 'Линия, визуально разделяющая контент.';
	@override late final _TranslationsDocsComponentsDividerExamplesRu examples = _TranslationsDocsComponentsDividerExamplesRu._(_root);
	@override String get item_1 => 'Элемент 1';
	@override String get item_2 => 'Элемент 2';
	@override String get item_3 => 'Элемент 3';
	@override String get divider => 'Делитель';
}

// Path: docs.components.dot_indicator
class _TranslationsDocsComponentsDotIndicatorRu extends TranslationsDocsComponentsDotIndicatorKo {
	_TranslationsDocsComponentsDotIndicatorRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Точечный индикатор';
	@override String get description => 'Индикатор, показывающий текущее положение с помощью точки.';
	@override late final _TranslationsDocsComponentsDotIndicatorExamplesRu examples = _TranslationsDocsComponentsDotIndicatorExamplesRu._(_root);
}

// Path: docs.components.drawer
class _TranslationsDocsComponentsDrawerRu extends TranslationsDocsComponentsDrawerKo {
	_TranslationsDocsComponentsDrawerRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Выдвижной ящик';
	@override String get description => 'Панель, выдвигающаяся с края экрана.';
	@override late final _TranslationsDocsComponentsDrawerExamplesRu examples = _TranslationsDocsComponentsDrawerExamplesRu._(_root);
	@override String get open_drawer => 'Открыть выдвижной ящик';
	@override String get close_drawer => 'Закрыть выдвижной ящик';
	@override String get open_another_drawer => 'Открыть другой выдвижной ящик';
	@override String drawer_at({required Object count, required Object position}) => 'Выдвижной ящик ${count} на ${position}';
}

// Path: docs.components.dropdown_menu
class _TranslationsDocsComponentsDropdownMenuRu extends TranslationsDocsComponentsDropdownMenuKo {
	_TranslationsDocsComponentsDropdownMenuRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Выпадающее меню';
	@override String get description => 'Меню, отображающее список доступных опций.';
	@override late final _TranslationsDocsComponentsDropdownMenuExamplesRu examples = _TranslationsDocsComponentsDropdownMenuExamplesRu._(_root);
}

// Path: docs.components.expandable_sidebar
class _TranslationsDocsComponentsExpandableSidebarRu extends TranslationsDocsComponentsExpandableSidebarKo {
	_TranslationsDocsComponentsExpandableSidebarRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Расширяемая боковая панель';
	@override String get description => 'Боковая панель, которая может быть расширена и свернута.';
	@override late final _TranslationsDocsComponentsExpandableSidebarExamplesRu examples = _TranslationsDocsComponentsExpandableSidebarExamplesRu._(_root);
}

// Path: docs.components.form
class _TranslationsDocsComponentsFormRu extends TranslationsDocsComponentsFormKo {
	_TranslationsDocsComponentsFormRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Форма';
	@override String get description => 'Утилитный виджет для простой валидации форм.';
	@override late final _TranslationsDocsComponentsFormExamplesRu examples = _TranslationsDocsComponentsFormExamplesRu._(_root);
	@override String get username_label => 'Имя пользователя';
	@override String get username_hint => 'Имя, отображаемое публично';
	@override String get password_label => 'Пароль';
	@override String get confirm_password_label => 'Подтверждение пароля';
	@override String get passwords_do_not_match => 'Пароли не совпадают';
	@override String get agree_terms => 'Согласен с условиями использования';
	@override String get must_agree_terms => 'Вы должны согласиться с условиями использования';
	@override String get form_values_title => 'Значения формы';
	@override String get register => 'Регистрация';
	@override String get username_already_taken => 'Имя пользователя уже занято';
	@override String get email => 'Электронная почта';
	@override String username_display({required Object value}) => 'Имя пользователя: ${value}';
	@override String password_display({required Object value}) => 'Пароль: ${value}';
	@override String confirm_password_display({required Object value}) => 'Подтверждение пароля: ${value}';
	@override String agree_display({required Object value}) => 'Согласие: ${value}';
	@override String json_display({required Object value}) => 'JSON: ${value}';
	@override String submitted_value_display({required Object value}) => 'Отправленное значение: ${value}';
	@override String get login => 'Вход';
	@override String get sign_up => 'Регистрация';
	@override String get dont_have_account => 'Нет аккаунта?';
	@override String get already_have_account => 'Уже есть аккаунт?';
}

// Path: docs.components.formatted_input
class _TranslationsDocsComponentsFormattedInputRu extends TranslationsDocsComponentsFormattedInputKo {
	_TranslationsDocsComponentsFormattedInputRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Форматированный ввод';
	@override String get description => 'Поле ввода текста, соответствующее определенному формату.';
	@override late final _TranslationsDocsComponentsFormattedInputExamplesRu examples = _TranslationsDocsComponentsFormattedInputExamplesRu._(_root);
}

// Path: docs.components.hover_card
class _TranslationsDocsComponentsHoverCardRu extends TranslationsDocsComponentsHoverCardKo {
	_TranslationsDocsComponentsHoverCardRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Карточка при наведении';
	@override String get description => 'Карточка, показываемая при наведении.';
	@override late final _TranslationsDocsComponentsHoverCardExamplesRu examples = _TranslationsDocsComponentsHoverCardExamplesRu._(_root);
	@override String get flutter_handle => '@flutter';
	@override String get flutter_username => 'Flutter';
	@override String get flutter_description => 'Flutter SDK предоставляет инструменты для создания красивых приложений для мобильных, веб- и настольных платформ из одной кодовой базы.';
}

// Path: docs.components.input
class _TranslationsDocsComponentsInputRu extends TranslationsDocsComponentsInputKo {
	_TranslationsDocsComponentsInputRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Ввод';
	@override String get description => 'Поле текстового ввода.';
	@override late final _TranslationsDocsComponentsInputExamplesRu examples = _TranslationsDocsComponentsInputExamplesRu._(_root);
	@override String get enter_name => 'Введите ваше имя';
	@override String get enter_username => 'Введите имя пользователя';
	@override String get username_already_taken => 'Имя пользователя уже занято';
	@override String get hello_world => 'Hello World!';
	@override String get search_something => 'Найдите что-то...';
	@override String get email => 'Электронная почта';
	@override String get password => 'Введите ваш пароль';
	@override String get username_hint => 'Это для вашего имени пользователя';
}

// Path: docs.components.input_otp
class _TranslationsDocsComponentsInputOtpRu extends TranslationsDocsComponentsInputOtpKo {
	_TranslationsDocsComponentsInputOtpRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Ввод OTP';
	@override String get description => 'Поле для ввода одноразового пароля.';
	@override late final _TranslationsDocsComponentsInputOtpExamplesRu examples = _TranslationsDocsComponentsInputOtpExamplesRu._(_root);
}

// Path: docs.components.item_picker
class _TranslationsDocsComponentsItemPickerRu extends TranslationsDocsComponentsItemPickerKo {
	_TranslationsDocsComponentsItemPickerRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Выбор элемента';
	@override String get description => 'Компонент для выбора элементов из списка.';
	@override late final _TranslationsDocsComponentsItemPickerExamplesRu examples = _TranslationsDocsComponentsItemPickerExamplesRu._(_root);
}

// Path: docs.components.keyboard_display
class _TranslationsDocsComponentsKeyboardDisplayRu extends TranslationsDocsComponentsKeyboardDisplayKo {
	_TranslationsDocsComponentsKeyboardDisplayRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Отображение клавиатуры';
	@override String get description => 'Компонент для отображения клавиатурных сочетаний.';
	@override late final _TranslationsDocsComponentsKeyboardDisplayExamplesRu examples = _TranslationsDocsComponentsKeyboardDisplayExamplesRu._(_root);
}

// Path: docs.components.linear_progress
class _TranslationsDocsComponentsLinearProgressRu extends TranslationsDocsComponentsLinearProgressKo {
	_TranslationsDocsComponentsLinearProgressRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Линейный прогресс';
	@override String get description => 'Линейный индикатор прогресса.';
	@override late final _TranslationsDocsComponentsLinearProgressExamplesRu examples = _TranslationsDocsComponentsLinearProgressExamplesRu._(_root);
	@override String get increase => 'Увеличить';
	@override String get decrease => 'Уменьшить';
}

// Path: docs.components.material
class _TranslationsDocsComponentsMaterialRu extends TranslationsDocsComponentsMaterialKo {
	_TranslationsDocsComponentsMaterialRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Material/Cupertino';
	@override String get description => 'Как использовать стандартные виджеты Material и Cupertino в Flutter.';
	@override late final _TranslationsDocsComponentsMaterialExamplesRu examples = _TranslationsDocsComponentsMaterialExamplesRu._(_root);
	@override String get my_material_app => 'Мое Material Приложение';
	@override String get my_cupertino_app => 'Мое Cupertino Приложение';
	@override String you_pushed_button({required Object count}) => 'Вы нажали кнопку ${count} раз';
	@override String get open_material_dialog => 'Открыть материальный диалог';
	@override String get open_cupertino_dialog => 'Открыть Cupertino диалог';
	@override String get open_coui_dialog => 'Открыть COUI диалог';
}

// Path: docs.components.menubar
class _TranslationsDocsComponentsMenubarRu extends TranslationsDocsComponentsMenubarKo {
	_TranslationsDocsComponentsMenubarRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Меню';
	@override String get description => 'Горизонтальная панель меню.';
	@override late final _TranslationsDocsComponentsMenubarExamplesRu examples = _TranslationsDocsComponentsMenubarExamplesRu._(_root);
	@override String get file => 'Файл';
	@override String get edit => 'Редактировать';
	@override String get new_tab => 'Новая вкладка';
	@override String get new_window => 'Новое окно';
	@override String get new_incognito_window => 'Новое Инкогнито окно';
	@override String get email_link => 'Ссылка на почту';
	@override String get messages => 'Сообщения';
	@override String get notes => 'Заметки';
	@override String get share => 'Поделиться';
	@override String get print => 'Печать';
	@override String get save_and_exit => 'Сохранить и выйти';
	@override String get discard_and_exit => 'Отменить и выйти';
	@override String get exit => 'Выход';
	@override String get undo => 'Отменить';
	@override String get redo => 'Повторить';
}

// Path: docs.components.multiselect
class _TranslationsDocsComponentsMultiselectRu extends TranslationsDocsComponentsMultiselectKo {
	_TranslationsDocsComponentsMultiselectRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Множественный выбор';
	@override String get description => 'Компонент, позволяющий выбирать несколько элементов.';
	@override late final _TranslationsDocsComponentsMultiselectExamplesRu examples = _TranslationsDocsComponentsMultiselectExamplesRu._(_root);
}

// Path: docs.components.navigation_bar
class _TranslationsDocsComponentsNavigationBarRu extends TranslationsDocsComponentsNavigationBarKo {
	_TranslationsDocsComponentsNavigationBarRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Навигационная панель';
	@override String get description => 'Нижняя навигационная панель.';
	@override late final _TranslationsDocsComponentsNavigationBarExamplesRu examples = _TranslationsDocsComponentsNavigationBarExamplesRu._(_root);
}

// Path: docs.components.navigation_menu
class _TranslationsDocsComponentsNavigationMenuRu extends TranslationsDocsComponentsNavigationMenuKo {
	_TranslationsDocsComponentsNavigationMenuRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Навигационное меню';
	@override String get description => 'Компонент навигационного меню.';
	@override late final _TranslationsDocsComponentsNavigationMenuExamplesRu examples = _TranslationsDocsComponentsNavigationMenuExamplesRu._(_root);
}

// Path: docs.components.navigation_rail
class _TranslationsDocsComponentsNavigationRailRu extends TranslationsDocsComponentsNavigationRailKo {
	_TranslationsDocsComponentsNavigationRailRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Боковая навигационная панель';
	@override String get description => 'Боковая навигационная панель.';
	@override late final _TranslationsDocsComponentsNavigationRailExamplesRu examples = _TranslationsDocsComponentsNavigationRailExamplesRu._(_root);
}

// Path: docs.components.navigation_sidebar
class _TranslationsDocsComponentsNavigationSidebarRu extends TranslationsDocsComponentsNavigationSidebarKo {
	_TranslationsDocsComponentsNavigationSidebarRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Навигационная боковая панель';
	@override String get description => 'Компонент навигационной боковой панели.';
	@override late final _TranslationsDocsComponentsNavigationSidebarExamplesRu examples = _TranslationsDocsComponentsNavigationSidebarExamplesRu._(_root);
}

// Path: docs.components.number_input
class _TranslationsDocsComponentsNumberInputRu extends TranslationsDocsComponentsNumberInputKo {
	_TranslationsDocsComponentsNumberInputRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Ввод числа';
	@override String get description => 'Поле для ввода числа.';
	@override late final _TranslationsDocsComponentsNumberInputExamplesRu examples = _TranslationsDocsComponentsNumberInputExamplesRu._(_root);
	@override String value({required Object value}) => 'Значение: ${value}';
}

// Path: docs.components.number_ticker
class _TranslationsDocsComponentsNumberTickerRu extends TranslationsDocsComponentsNumberTickerKo {
	_TranslationsDocsComponentsNumberTickerRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Тикер числа';
	@override String get description => 'Отображает анимацию при изменении числа.';
	@override late final _TranslationsDocsComponentsNumberTickerExamplesRu examples = _TranslationsDocsComponentsNumberTickerExamplesRu._(_root);
}

// Path: docs.components.overflow_marquee
class _TranslationsDocsComponentsOverflowMarqueeRu extends TranslationsDocsComponentsOverflowMarqueeKo {
	_TranslationsDocsComponentsOverflowMarqueeRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Пробел для переполнения';
	@override String get description => 'Автоматически прокручивается, когда текст переполняет.';
	@override late final _TranslationsDocsComponentsOverflowMarqueeExamplesRu examples = _TranslationsDocsComponentsOverflowMarqueeExamplesRu._(_root);
}

// Path: docs.components.pagination
class _TranslationsDocsComponentsPaginationRu extends TranslationsDocsComponentsPaginationKo {
	_TranslationsDocsComponentsPaginationRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Пагинация';
	@override String get description => 'Компонент для навигации по страницам.';
	@override late final _TranslationsDocsComponentsPaginationExamplesRu examples = _TranslationsDocsComponentsPaginationExamplesRu._(_root);
}

// Path: docs.components.phone_input
class _TranslationsDocsComponentsPhoneInputRu extends TranslationsDocsComponentsPhoneInputKo {
	_TranslationsDocsComponentsPhoneInputRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Телефонный ввод';
	@override String get description => 'Поле для ввода телефонного номера.';
	@override late final _TranslationsDocsComponentsPhoneInputExamplesRu examples = _TranslationsDocsComponentsPhoneInputExamplesRu._(_root);
}

// Path: docs.components.popover
class _TranslationsDocsComponentsPopoverRu extends TranslationsDocsComponentsPopoverKo {
	_TranslationsDocsComponentsPopoverRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Поповер';
	@override String get description => 'Всплывающее окно, отображаемое над элементом.';
	@override late final _TranslationsDocsComponentsPopoverExamplesRu examples = _TranslationsDocsComponentsPopoverExamplesRu._(_root);
	@override String get dimensions => 'Размеры';
	@override String get set_dimensions => 'Установите размеры слоя';
	@override String get width => 'Ширина';
	@override String get max_width => 'Максимальная ширина';
	@override String get height => 'Высота';
	@override String get max_height => 'Максимальная высота';
	@override String get open_popover => 'Открыть поповер';
	@override String get submit => 'Подтвердить';
}

// Path: docs.components.progress
class _TranslationsDocsComponentsProgressRu extends TranslationsDocsComponentsProgressKo {
	_TranslationsDocsComponentsProgressRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Прогресс';
	@override String get description => 'Отображает состояние прогресса.';
	@override late final _TranslationsDocsComponentsProgressExamplesRu examples = _TranslationsDocsComponentsProgressExamplesRu._(_root);
}

// Path: docs.components.radio_card
class _TranslationsDocsComponentsRadioCardRu extends TranslationsDocsComponentsRadioCardKo {
	_TranslationsDocsComponentsRadioCardRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Карточка радиокнопки';
	@override String get description => 'Радиокнопка в форме карточки.';
	@override late final _TranslationsDocsComponentsRadioCardExamplesRu examples = _TranslationsDocsComponentsRadioCardExamplesRu._(_root);
}

// Path: docs.components.radio_group
class _TranslationsDocsComponentsRadioGroupRu extends TranslationsDocsComponentsRadioGroupKo {
	_TranslationsDocsComponentsRadioGroupRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Группа радиокнопок';
	@override String get description => 'Группа радиокнопок.';
	@override late final _TranslationsDocsComponentsRadioGroupExamplesRu examples = _TranslationsDocsComponentsRadioGroupExamplesRu._(_root);
	@override String get option_1 => 'Опция 1';
	@override String get option_2 => 'Опция 2';
	@override String get option_3 => 'Опция 3';
	@override String get selected => 'Выбран';
}

// Path: docs.components.refresh_trigger
class _TranslationsDocsComponentsRefreshTriggerRu extends TranslationsDocsComponentsRefreshTriggerKo {
	_TranslationsDocsComponentsRefreshTriggerRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Триггер обновления';
	@override String get description => 'Предоставляет возможность обновления путем перетаскивания.';
	@override late final _TranslationsDocsComponentsRefreshTriggerExamplesRu examples = _TranslationsDocsComponentsRefreshTriggerExamplesRu._(_root);
	@override String get pull_me => 'Потяните';
	@override String get refresh => 'Обновить';
}

// Path: docs.components.repeated_animation_builder
class _TranslationsDocsComponentsRepeatedAnimationBuilderRu extends TranslationsDocsComponentsRepeatedAnimationBuilderKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Строитель повторяющейся анимации';
	@override String get description => 'Строитель, который повторяет анимацию.';
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesRu examples = _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesRu._(_root);
}

// Path: docs.components.resizable
class _TranslationsDocsComponentsResizableRu extends TranslationsDocsComponentsResizableKo {
	_TranslationsDocsComponentsResizableRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Изменяемый размер';
	@override String get description => 'Контейнер, размер которого можно изменить.';
	@override late final _TranslationsDocsComponentsResizableExamplesRu examples = _TranslationsDocsComponentsResizableExamplesRu._(_root);
}

// Path: docs.components.scaffold
class _TranslationsDocsComponentsScaffoldRu extends TranslationsDocsComponentsScaffoldKo {
	_TranslationsDocsComponentsScaffoldRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Скaffold';
	@override String get description => 'Скaffold — это контейнер верхнего уровня для страницы.';
	@override late final _TranslationsDocsComponentsScaffoldExamplesRu examples = _TranslationsDocsComponentsScaffoldExamplesRu._(_root);
}

// Path: docs.components.select
class _TranslationsDocsComponentsSelectRu extends TranslationsDocsComponentsSelectKo {
	_TranslationsDocsComponentsSelectRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Выбор';
	@override String get description => 'Позволяет выбрать элемент из списка опций.';
	@override late final _TranslationsDocsComponentsSelectExamplesRu examples = _TranslationsDocsComponentsSelectExamplesRu._(_root);
	@override String get placeholder => 'Выберите фрукт';
	@override String get search_fruit => 'Искать фрукты';
	@override String get no_fruit_found => 'Фрукты не найдены';
	@override String get apple => 'Яблоко';
	@override String get banana => 'Банан';
	@override String get cherry => 'Вишня';
	@override String get lemon => 'Лимон';
	@override String get tomato => 'Помидор';
	@override String get red_apple => 'Красное яблоко';
	@override String get green_apple => 'Зеленое яблоко';
	@override String get yellow_banana => 'Желтый банан';
	@override String get brown_banana => 'Коричневый банан';
	@override String get yellow_lemon => 'Желтый лимон';
	@override String get green_lemon => 'Зеленый лимон';
	@override String get red => 'Красный';
	@override String get green => 'Зеленый';
	@override String get yellow => 'Желтый';
	@override String get brown => 'Коричневый';
}

// Path: docs.components.sheet
class _TranslationsDocsComponentsSheetRu extends TranslationsDocsComponentsSheetKo {
	_TranslationsDocsComponentsSheetRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Лист';
	@override String get description => 'Лист, выдвигающийся снизу.';
	@override late final _TranslationsDocsComponentsSheetExamplesRu examples = _TranslationsDocsComponentsSheetExamplesRu._(_root);
}

// Path: docs.components.skeleton
class _TranslationsDocsComponentsSkeletonRu extends TranslationsDocsComponentsSkeletonKo {
	_TranslationsDocsComponentsSkeletonRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Скелет';
	@override String get description => 'Скелетный экран, отображаемый во время загрузки.';
	@override late final _TranslationsDocsComponentsSkeletonExamplesRu examples = _TranslationsDocsComponentsSkeletonExamplesRu._(_root);
}

// Path: docs.components.slider
class _TranslationsDocsComponentsSliderRu extends TranslationsDocsComponentsSliderKo {
	_TranslationsDocsComponentsSliderRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Слайдер';
	@override String get description => 'Позволяет выбрать значение, перемещая слайдер.';
	@override late final _TranslationsDocsComponentsSliderExamplesRu examples = _TranslationsDocsComponentsSliderExamplesRu._(_root);
	@override String value_single({required Object value}) => 'Значение: ${value}';
	@override String value_range({required Object start, required Object end}) => 'Значение: ${start} - ${end}';
}

// Path: docs.components.sortable
class _TranslationsDocsComponentsSortableRu extends TranslationsDocsComponentsSortableKo {
	_TranslationsDocsComponentsSortableRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Сортируемый';
	@override String get description => 'Позволяет сортировать элементы перетаскиванием.';
	@override late final _TranslationsDocsComponentsSortableExamplesRu examples = _TranslationsDocsComponentsSortableExamplesRu._(_root);
}

// Path: docs.components.star_rating
class _TranslationsDocsComponentsStarRatingRu extends TranslationsDocsComponentsStarRatingKo {
	_TranslationsDocsComponentsStarRatingRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Рейтинг звезды';
	@override String get description => 'Позволяет выбрать рейтинг в звездах.';
	@override late final _TranslationsDocsComponentsStarRatingExamplesRu examples = _TranslationsDocsComponentsStarRatingExamplesRu._(_root);
}

// Path: docs.components.stepper
class _TranslationsDocsComponentsStepperRu extends TranslationsDocsComponentsStepperKo {
	_TranslationsDocsComponentsStepperRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Степпер';
	@override String get description => 'Отображает процесс по этапам.';
	@override late final _TranslationsDocsComponentsStepperExamplesRu examples = _TranslationsDocsComponentsStepperExamplesRu._(_root);
	@override String get step_1 => 'Шаг 1';
	@override String get step_2 => 'Шаг 2';
	@override String get step_3 => 'Шаг 3';
	@override String step_n({required Object n}) => 'Шаг ${n}';
	@override String get optional_step => 'Необязательный шаг';
	@override String get horizontal => 'Горизонтальный';
	@override String get vertical => 'Вертикальный';
	@override String get toggle_error => 'Переключить ошибку';
	@override String get circle => 'Круг';
	@override String get circle_alt => 'Круг альтернативный';
	@override String get line => 'Линия';
	@override String get small => 'Маленький';
	@override String get medium => 'Средний';
	@override String get large => 'Большой';
}

// Path: docs.components.steps
class _TranslationsDocsComponentsStepsRu extends TranslationsDocsComponentsStepsKo {
	_TranslationsDocsComponentsStepsRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Шаги';
	@override String get description => 'Отображает прогресс по шагам.';
	@override late final _TranslationsDocsComponentsStepsExamplesRu examples = _TranslationsDocsComponentsStepsExamplesRu._(_root);
}

// Path: docs.components.swiper
class _TranslationsDocsComponentsSwiperRu extends TranslationsDocsComponentsSwiperKo {
	_TranslationsDocsComponentsSwiperRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Свайпер';
	@override String get description => 'Компонент, который можно провести.';
	@override late final _TranslationsDocsComponentsSwiperExamplesRu examples = _TranslationsDocsComponentsSwiperExamplesRu._(_root);
}

// Path: docs.components.k_switch
class _TranslationsDocsComponentsKSwitchRu extends TranslationsDocsComponentsKSwitchKo {
	_TranslationsDocsComponentsKSwitchRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Переключатель';
	@override String get description => 'Переключатель для включения/выключения.';
	@override late final _TranslationsDocsComponentsKSwitchExamplesRu examples = _TranslationsDocsComponentsKSwitchExamplesRu._(_root);
}

// Path: docs.components.switcher
class _TranslationsDocsComponentsSwitcherRu extends TranslationsDocsComponentsSwitcherKo {
	_TranslationsDocsComponentsSwitcherRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Переключатель';
	@override String get description => 'Позволяет переключаться между несколькими представлениями.';
	@override late final _TranslationsDocsComponentsSwitcherExamplesRu examples = _TranslationsDocsComponentsSwitcherExamplesRu._(_root);
	@override String get switch_direction => 'Переключить направление';
	@override String get next_item => 'Следующий элемент';
}

// Path: docs.components.tab_list
class _TranslationsDocsComponentsTabListRu extends TranslationsDocsComponentsTabListKo {
	_TranslationsDocsComponentsTabListRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Список вкладок';
	@override String get description => 'Компонент списка вкладок.';
	@override late final _TranslationsDocsComponentsTabListExamplesRu examples = _TranslationsDocsComponentsTabListExamplesRu._(_root);
}

// Path: docs.components.tab_pane
class _TranslationsDocsComponentsTabPaneRu extends TranslationsDocsComponentsTabPaneKo {
	_TranslationsDocsComponentsTabPaneRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Панель вкладок';
	@override String get description => 'Компонент панели вкладок.';
	@override late final _TranslationsDocsComponentsTabPaneExamplesRu examples = _TranslationsDocsComponentsTabPaneExamplesRu._(_root);
}

// Path: docs.components.table
class _TranslationsDocsComponentsTableRu extends TranslationsDocsComponentsTableKo {
	_TranslationsDocsComponentsTableRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Таблица';
	@override String get description => 'Отображает данные в табличном формате.';
	@override late final _TranslationsDocsComponentsTableExamplesRu examples = _TranslationsDocsComponentsTableExamplesRu._(_root);
	@override String get invoice => 'Счет';
	@override String get status => 'Статус';
	@override String get method => 'Метод';
	@override String get amount => 'Сумма';
	@override String get total => 'Итого';
	@override String get paid => 'Оплачено';
	@override String get pending => 'Ожидает';
	@override String get unpaid => 'Неоплачено';
	@override String get credit_card => 'Кредитная карта';
	@override String get paypal => 'PayPal';
	@override String get bank_transfer => 'Банковский перевод';
}

// Path: docs.components.tabs
class _TranslationsDocsComponentsTabsRu extends TranslationsDocsComponentsTabsKo {
	_TranslationsDocsComponentsTabsRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Вкладки';
	@override String get description => 'Позволяют организовать контент по вкладкам.';
	@override late final _TranslationsDocsComponentsTabsExamplesRu examples = _TranslationsDocsComponentsTabsExamplesRu._(_root);
	@override String get tab_1 => 'Вкладка 1';
	@override String get tab_2 => 'Вкладка 2';
	@override String get tab_3 => 'Вкладка 3';
	@override String tab_n({required Object n}) => 'Вкладка ${n}';
}

// Path: docs.components.text_area
class _TranslationsDocsComponentsTextAreaRu extends TranslationsDocsComponentsTextAreaKo {
	_TranslationsDocsComponentsTextAreaRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Текстовая область';
	@override String get description => 'Позволяет вводить многострочный текст.';
	@override late final _TranslationsDocsComponentsTextAreaExamplesRu examples = _TranslationsDocsComponentsTextAreaExamplesRu._(_root);
	@override String get hello_world => 'Здравствуйте, мир!';
}

// Path: docs.components.time_picker
class _TranslationsDocsComponentsTimePickerRu extends TranslationsDocsComponentsTimePickerKo {
	_TranslationsDocsComponentsTimePickerRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Выбор времени';
	@override String get description => 'Позволяет выбрать время.';
	@override late final _TranslationsDocsComponentsTimePickerExamplesRu examples = _TranslationsDocsComponentsTimePickerExamplesRu._(_root);
	@override String get select_time => 'Выберите время';
}

// Path: docs.components.timeline
class _TranslationsDocsComponentsTimelineRu extends TranslationsDocsComponentsTimelineKo {
	_TranslationsDocsComponentsTimelineRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Таймлайн';
	@override String get description => 'Отображает события на таймлайне.';
	@override late final _TranslationsDocsComponentsTimelineExamplesRu examples = _TranslationsDocsComponentsTimelineExamplesRu._(_root);
}

// Path: docs.components.timeline_animation
class _TranslationsDocsComponentsTimelineAnimationRu extends TranslationsDocsComponentsTimelineAnimationKo {
	_TranslationsDocsComponentsTimelineAnimationRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Анимация таймлайна';
	@override String get description => 'Анимация на основе таймлайна.';
	@override late final _TranslationsDocsComponentsTimelineAnimationExamplesRu examples = _TranslationsDocsComponentsTimelineAnimationExamplesRu._(_root);
}

// Path: docs.components.toast
class _TranslationsDocsComponentsToastRu extends TranslationsDocsComponentsToastKo {
	_TranslationsDocsComponentsToastRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Тост';
	@override String get description => 'Уведомление, отображающее короткие сообщения.';
	@override late final _TranslationsDocsComponentsToastExamplesRu examples = _TranslationsDocsComponentsToastExamplesRu._(_root);
	@override String get event_created => 'Событие создано';
	@override String get event_date => 'Воскресенье, 7 июля 2024 года, 12:00';
	@override String get show_bottom_left => 'Показать тост в левом нижнем углу';
	@override String get show_bottom_right => 'Показать тост в правом нижнем углу';
	@override String get show_top_left => 'Показать тост в левом верхнем углу';
	@override String get show_top_right => 'Показать тост в правом верхнем углу';
	@override String get show_bottom_center => 'Показать тост в центре снизу';
	@override String get show_top_center => 'Показать тост в центре сверху';
}

// Path: docs.components.toggle
class _TranslationsDocsComponentsToggleRu extends TranslationsDocsComponentsToggleKo {
	_TranslationsDocsComponentsToggleRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Переключатель';
	@override String get description => 'Позволяет переключаться между опциями.';
	@override late final _TranslationsDocsComponentsToggleExamplesRu examples = _TranslationsDocsComponentsToggleExamplesRu._(_root);
	@override String get toggle => 'Переключить';
}

// Path: docs.components.tooltip
class _TranslationsDocsComponentsTooltipRu extends TranslationsDocsComponentsTooltipKo {
	_TranslationsDocsComponentsTooltipRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Всплывающая подсказка';
	@override String get description => 'Показывает дополнительную информацию о элементе.';
	@override late final _TranslationsDocsComponentsTooltipExamplesRu examples = _TranslationsDocsComponentsTooltipExamplesRu._(_root);
	@override String get this_is_tooltip => 'Это всплывающая подсказка.';
	@override String get hover_over_me => 'Наведите курсор на меня';
}

// Path: docs.components.tracker
class _TranslationsDocsComponentsTrackerRu extends TranslationsDocsComponentsTrackerKo {
	_TranslationsDocsComponentsTrackerRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Трекер';
	@override String get description => 'Отслеживает прогресс.';
	@override late final _TranslationsDocsComponentsTrackerExamplesRu examples = _TranslationsDocsComponentsTrackerExamplesRu._(_root);
	@override String get fine => 'Хорошо';
	@override String get warning => 'Предупреждение';
	@override String get critical => 'Критично';
	@override String get unknown => 'Неизвестно';
	@override String get tracker_fine => 'Трекер в порядке';
	@override String get tracker_warning => 'Трекер с предупреждением';
	@override String get tracker_critical => 'Трекер критичен';
	@override String get tracker_unknown => 'Трекер неизвестен';
}

// Path: docs.components.tree
class _TranslationsDocsComponentsTreeRu extends TranslationsDocsComponentsTreeKo {
	_TranslationsDocsComponentsTreeRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Дерево';
	@override String get description => 'Отображает иерархические данные в виде дерева.';
	@override late final _TranslationsDocsComponentsTreeExamplesRu examples = _TranslationsDocsComponentsTreeExamplesRu._(_root);
}

// Path: docs.components.window
class _TranslationsDocsComponentsWindowRu extends TranslationsDocsComponentsWindowKo {
	_TranslationsDocsComponentsWindowRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Окно';
	@override String get description => 'Окно в стиле настольного интерфейса.';
	@override late final _TranslationsDocsComponentsWindowExamplesRu examples = _TranslationsDocsComponentsWindowExamplesRu._(_root);
	@override String get window_1 => 'Окно 1';
	@override String get window_2 => 'Окно 2';
	@override String get desktop => 'Рабочий стол';
	@override String get add_window => 'Добавить окно';
}

// Path: docs.pages.introduction.features_list
class _TranslationsDocsPagesIntroductionFeaturesListRu extends TranslationsDocsPagesIntroductionFeaturesListKo {
	_TranslationsDocsPagesIntroductionFeaturesListRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get components_count => '84 компонента и продолжаем расти!';
	@override String get material_cupertino => 'Поддерживает виджеты Material и Cupertino, темы в настоящее время настроены под тему coui_flutter.';
	@override String get premade_themes => 'Предварительно созданные темы Coui/UI.';
	@override String get platform_support => 'Поддержка мобильных, веб- и настольных платформ.';
	@override String get middle_drag => 'Поддержка прокрутки со средним перетаскиванием.';
	@override String get typography_extensions => 'Разнообразные расширения виджетов для типографики.';
	@override String get webassembly => 'Поддержка WebAssembly для повышения производительности.';
}

// Path: docs.components.accordion.examples
class _TranslationsDocsComponentsAccordionExamplesRu extends TranslationsDocsComponentsAccordionExamplesKo {
	_TranslationsDocsComponentsAccordionExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример аккордеона';
}

// Path: docs.components.alert.examples
class _TranslationsDocsComponentsAlertExamplesRu extends TranslationsDocsComponentsAlertExamplesKo {
	_TranslationsDocsComponentsAlertExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример уведомления';
	@override String get destructive => 'Пример опасного уведомления';
}

// Path: docs.components.alert_dialog.examples
class _TranslationsDocsComponentsAlertDialogExamplesRu extends TranslationsDocsComponentsAlertDialogExamplesKo {
	_TranslationsDocsComponentsAlertDialogExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример диалогового уведомления';
}

// Path: docs.components.animated_value_builder.examples
class _TranslationsDocsComponentsAnimatedValueBuilderExamplesRu extends TranslationsDocsComponentsAnimatedValueBuilderExamplesKo {
	_TranslationsDocsComponentsAnimatedValueBuilderExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример строителя анимированных значений';
}

// Path: docs.components.app_bar.examples
class _TranslationsDocsComponentsAppBarExamplesRu extends TranslationsDocsComponentsAppBarExamplesKo {
	_TranslationsDocsComponentsAppBarExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример панели приложения';
}

// Path: docs.components.autocomplete.examples
class _TranslationsDocsComponentsAutocompleteExamplesRu extends TranslationsDocsComponentsAutocompleteExamplesKo {
	_TranslationsDocsComponentsAutocompleteExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример автоматической подсказки';
}

// Path: docs.components.avatar.examples
class _TranslationsDocsComponentsAvatarExamplesRu extends TranslationsDocsComponentsAvatarExamplesKo {
	_TranslationsDocsComponentsAvatarExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример аватара';
}

// Path: docs.components.avatar_group.examples
class _TranslationsDocsComponentsAvatarGroupExamplesRu extends TranslationsDocsComponentsAvatarGroupExamplesKo {
	_TranslationsDocsComponentsAvatarGroupExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример группы аватаров';
}

// Path: docs.components.badge.examples
class _TranslationsDocsComponentsBadgeExamplesRu extends TranslationsDocsComponentsBadgeExamplesKo {
	_TranslationsDocsComponentsBadgeExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример значка';
}

// Path: docs.components.breadcrumb.examples
class _TranslationsDocsComponentsBreadcrumbExamplesRu extends TranslationsDocsComponentsBreadcrumbExamplesKo {
	_TranslationsDocsComponentsBreadcrumbExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример хлебных крошек';
}

// Path: docs.components.button.examples
class _TranslationsDocsComponentsButtonExamplesRu extends TranslationsDocsComponentsButtonExamplesKo {
	_TranslationsDocsComponentsButtonExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get primary => 'Пример основной кнопки';
	@override String get secondary => 'Пример вторичной кнопки';
	@override String get outline => 'Пример контурной кнопки';
	@override String get ghost => 'Пример кнопки-призрака';
	@override String get destructive => 'Пример опасной кнопки';
	@override String get link => 'Пример кнопки-ссылки';
	@override String get text => 'Пример текстовой кнопки';
	@override String get disabled => 'Пример отключенной кнопки';
	@override String get icon => 'Пример кнопки с иконкой';
	@override String get icon_with_label => 'Пример кнопки с иконкой и надписью';
	@override String get size => 'Пример размеров кнопки';
	@override String get density => 'Пример плотности кнопки';
	@override String get shape => 'Пример формы кнопки';
	@override String get group => 'Пример группы кнопок';
	@override String get stated => 'Пример кнопки с состоянием';
	@override String get card => 'Пример кнопки для карты';
	@override String get custom => 'Пример пользовательской кнопки';
}

// Path: docs.components.calendar.examples
class _TranslationsDocsComponentsCalendarExamplesRu extends TranslationsDocsComponentsCalendarExamplesKo {
	_TranslationsDocsComponentsCalendarExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример календаря';
}

// Path: docs.components.card.examples
class _TranslationsDocsComponentsCardExamplesRu extends TranslationsDocsComponentsCardExamplesKo {
	_TranslationsDocsComponentsCardExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример карточки';
}

// Path: docs.components.card_image.examples
class _TranslationsDocsComponentsCardImageExamplesRu extends TranslationsDocsComponentsCardImageExamplesKo {
	_TranslationsDocsComponentsCardImageExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример карточки с изображением';
}

// Path: docs.components.carousel.examples
class _TranslationsDocsComponentsCarouselExamplesRu extends TranslationsDocsComponentsCarouselExamplesKo {
	_TranslationsDocsComponentsCarouselExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример карусели';
}

// Path: docs.components.checkbox.examples
class _TranslationsDocsComponentsCheckboxExamplesRu extends TranslationsDocsComponentsCheckboxExamplesKo {
	_TranslationsDocsComponentsCheckboxExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример чекбокса';
}

// Path: docs.components.chip.examples
class _TranslationsDocsComponentsChipExamplesRu extends TranslationsDocsComponentsChipExamplesKo {
	_TranslationsDocsComponentsChipExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример чипа';
}

// Path: docs.components.chip_input.examples
class _TranslationsDocsComponentsChipInputExamplesRu extends TranslationsDocsComponentsChipInputExamplesKo {
	_TranslationsDocsComponentsChipInputExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример ввода чипов';
}

// Path: docs.components.circular_progress.examples
class _TranslationsDocsComponentsCircularProgressExamplesRu extends TranslationsDocsComponentsCircularProgressExamplesKo {
	_TranslationsDocsComponentsCircularProgressExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример кругового прогресса';
}

// Path: docs.components.code_snippet.examples
class _TranslationsDocsComponentsCodeSnippetExamplesRu extends TranslationsDocsComponentsCodeSnippetExamplesKo {
	_TranslationsDocsComponentsCodeSnippetExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример фрагмента кода';
}

// Path: docs.components.collapsible.examples
class _TranslationsDocsComponentsCollapsibleExamplesRu extends TranslationsDocsComponentsCollapsibleExamplesKo {
	_TranslationsDocsComponentsCollapsibleExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример складного';
}

// Path: docs.components.color_picker.examples
class _TranslationsDocsComponentsColorPickerExamplesRu extends TranslationsDocsComponentsColorPickerExamplesKo {
	_TranslationsDocsComponentsColorPickerExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример выбора цвета';
}

// Path: docs.components.command.examples
class _TranslationsDocsComponentsCommandExamplesRu extends TranslationsDocsComponentsCommandExamplesKo {
	_TranslationsDocsComponentsCommandExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример команды';
}

// Path: docs.components.context_menu.examples
class _TranslationsDocsComponentsContextMenuExamplesRu extends TranslationsDocsComponentsContextMenuExamplesKo {
	_TranslationsDocsComponentsContextMenuExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример контекстного меню';
}

// Path: docs.components.date_picker.examples
class _TranslationsDocsComponentsDatePickerExamplesRu extends TranslationsDocsComponentsDatePickerExamplesKo {
	_TranslationsDocsComponentsDatePickerExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример выбора даты';
}

// Path: docs.components.dialog.examples
class _TranslationsDocsComponentsDialogExamplesRu extends TranslationsDocsComponentsDialogExamplesKo {
	_TranslationsDocsComponentsDialogExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример диалога';
}

// Path: docs.components.divider.examples
class _TranslationsDocsComponentsDividerExamplesRu extends TranslationsDocsComponentsDividerExamplesKo {
	_TranslationsDocsComponentsDividerExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример делителя';
}

// Path: docs.components.dot_indicator.examples
class _TranslationsDocsComponentsDotIndicatorExamplesRu extends TranslationsDocsComponentsDotIndicatorExamplesKo {
	_TranslationsDocsComponentsDotIndicatorExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример точечного индикатора';
}

// Path: docs.components.drawer.examples
class _TranslationsDocsComponentsDrawerExamplesRu extends TranslationsDocsComponentsDrawerExamplesKo {
	_TranslationsDocsComponentsDrawerExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример выдвижного ящика';
}

// Path: docs.components.dropdown_menu.examples
class _TranslationsDocsComponentsDropdownMenuExamplesRu extends TranslationsDocsComponentsDropdownMenuExamplesKo {
	_TranslationsDocsComponentsDropdownMenuExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример выпадающего меню';
}

// Path: docs.components.expandable_sidebar.examples
class _TranslationsDocsComponentsExpandableSidebarExamplesRu extends TranslationsDocsComponentsExpandableSidebarExamplesKo {
	_TranslationsDocsComponentsExpandableSidebarExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример расширяемой боковой панели';
}

// Path: docs.components.form.examples
class _TranslationsDocsComponentsFormExamplesRu extends TranslationsDocsComponentsFormExamplesKo {
	_TranslationsDocsComponentsFormExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get table_layout => 'Пример формы (табличная компоновка)';
	@override String get column_layout => 'Пример формы (колоночная компоновка)';
	@override String get validation_mode => 'Пример валидационного режима';
}

// Path: docs.components.formatted_input.examples
class _TranslationsDocsComponentsFormattedInputExamplesRu extends TranslationsDocsComponentsFormattedInputExamplesKo {
	_TranslationsDocsComponentsFormattedInputExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример форматированного ввода';
}

// Path: docs.components.hover_card.examples
class _TranslationsDocsComponentsHoverCardExamplesRu extends TranslationsDocsComponentsHoverCardExamplesKo {
	_TranslationsDocsComponentsHoverCardExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример карточки при наведении';
}

// Path: docs.components.input.examples
class _TranslationsDocsComponentsInputExamplesRu extends TranslationsDocsComponentsInputExamplesKo {
	_TranslationsDocsComponentsInputExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример ввода';
}

// Path: docs.components.input_otp.examples
class _TranslationsDocsComponentsInputOtpExamplesRu extends TranslationsDocsComponentsInputOtpExamplesKo {
	_TranslationsDocsComponentsInputOtpExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример ввода OTP';
}

// Path: docs.components.item_picker.examples
class _TranslationsDocsComponentsItemPickerExamplesRu extends TranslationsDocsComponentsItemPickerExamplesKo {
	_TranslationsDocsComponentsItemPickerExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример выбора элемента';
}

// Path: docs.components.keyboard_display.examples
class _TranslationsDocsComponentsKeyboardDisplayExamplesRu extends TranslationsDocsComponentsKeyboardDisplayExamplesKo {
	_TranslationsDocsComponentsKeyboardDisplayExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример отображения клавиатуры';
}

// Path: docs.components.linear_progress.examples
class _TranslationsDocsComponentsLinearProgressExamplesRu extends TranslationsDocsComponentsLinearProgressExamplesKo {
	_TranslationsDocsComponentsLinearProgressExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример линейного прогресса';
}

// Path: docs.components.material.examples
class _TranslationsDocsComponentsMaterialExamplesRu extends TranslationsDocsComponentsMaterialExamplesKo {
	_TranslationsDocsComponentsMaterialExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример Material/Cupertino';
}

// Path: docs.components.menubar.examples
class _TranslationsDocsComponentsMenubarExamplesRu extends TranslationsDocsComponentsMenubarExamplesKo {
	_TranslationsDocsComponentsMenubarExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример меню';
}

// Path: docs.components.multiselect.examples
class _TranslationsDocsComponentsMultiselectExamplesRu extends TranslationsDocsComponentsMultiselectExamplesKo {
	_TranslationsDocsComponentsMultiselectExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример множественного выбора';
}

// Path: docs.components.navigation_bar.examples
class _TranslationsDocsComponentsNavigationBarExamplesRu extends TranslationsDocsComponentsNavigationBarExamplesKo {
	_TranslationsDocsComponentsNavigationBarExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример навигационной панели';
}

// Path: docs.components.navigation_menu.examples
class _TranslationsDocsComponentsNavigationMenuExamplesRu extends TranslationsDocsComponentsNavigationMenuExamplesKo {
	_TranslationsDocsComponentsNavigationMenuExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример навигационного меню';
}

// Path: docs.components.navigation_rail.examples
class _TranslationsDocsComponentsNavigationRailExamplesRu extends TranslationsDocsComponentsNavigationRailExamplesKo {
	_TranslationsDocsComponentsNavigationRailExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример боковой навигационной панели';
}

// Path: docs.components.navigation_sidebar.examples
class _TranslationsDocsComponentsNavigationSidebarExamplesRu extends TranslationsDocsComponentsNavigationSidebarExamplesKo {
	_TranslationsDocsComponentsNavigationSidebarExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример навигационной боковой панели';
}

// Path: docs.components.number_input.examples
class _TranslationsDocsComponentsNumberInputExamplesRu extends TranslationsDocsComponentsNumberInputExamplesKo {
	_TranslationsDocsComponentsNumberInputExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример ввода числа';
}

// Path: docs.components.number_ticker.examples
class _TranslationsDocsComponentsNumberTickerExamplesRu extends TranslationsDocsComponentsNumberTickerExamplesKo {
	_TranslationsDocsComponentsNumberTickerExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример тикера числа';
}

// Path: docs.components.overflow_marquee.examples
class _TranslationsDocsComponentsOverflowMarqueeExamplesRu extends TranslationsDocsComponentsOverflowMarqueeExamplesKo {
	_TranslationsDocsComponentsOverflowMarqueeExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример пробела для переполнения';
}

// Path: docs.components.pagination.examples
class _TranslationsDocsComponentsPaginationExamplesRu extends TranslationsDocsComponentsPaginationExamplesKo {
	_TranslationsDocsComponentsPaginationExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример пагинации';
}

// Path: docs.components.phone_input.examples
class _TranslationsDocsComponentsPhoneInputExamplesRu extends TranslationsDocsComponentsPhoneInputExamplesKo {
	_TranslationsDocsComponentsPhoneInputExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример телефонного ввода';
}

// Path: docs.components.popover.examples
class _TranslationsDocsComponentsPopoverExamplesRu extends TranslationsDocsComponentsPopoverExamplesKo {
	_TranslationsDocsComponentsPopoverExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример поповера';
}

// Path: docs.components.progress.examples
class _TranslationsDocsComponentsProgressExamplesRu extends TranslationsDocsComponentsProgressExamplesKo {
	_TranslationsDocsComponentsProgressExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример прогресса';
}

// Path: docs.components.radio_card.examples
class _TranslationsDocsComponentsRadioCardExamplesRu extends TranslationsDocsComponentsRadioCardExamplesKo {
	_TranslationsDocsComponentsRadioCardExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример карточки радиокнопки';
}

// Path: docs.components.radio_group.examples
class _TranslationsDocsComponentsRadioGroupExamplesRu extends TranslationsDocsComponentsRadioGroupExamplesKo {
	_TranslationsDocsComponentsRadioGroupExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример группы радиокнопок';
}

// Path: docs.components.refresh_trigger.examples
class _TranslationsDocsComponentsRefreshTriggerExamplesRu extends TranslationsDocsComponentsRefreshTriggerExamplesKo {
	_TranslationsDocsComponentsRefreshTriggerExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример триггера обновления';
}

// Path: docs.components.repeated_animation_builder.examples
class _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesRu extends TranslationsDocsComponentsRepeatedAnimationBuilderExamplesKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример строителя повторяющейся анимации';
}

// Path: docs.components.resizable.examples
class _TranslationsDocsComponentsResizableExamplesRu extends TranslationsDocsComponentsResizableExamplesKo {
	_TranslationsDocsComponentsResizableExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример изменяемого размера';
}

// Path: docs.components.scaffold.examples
class _TranslationsDocsComponentsScaffoldExamplesRu extends TranslationsDocsComponentsScaffoldExamplesKo {
	_TranslationsDocsComponentsScaffoldExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример скaffold';
}

// Path: docs.components.select.examples
class _TranslationsDocsComponentsSelectExamplesRu extends TranslationsDocsComponentsSelectExamplesKo {
	_TranslationsDocsComponentsSelectExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример выбора';
}

// Path: docs.components.sheet.examples
class _TranslationsDocsComponentsSheetExamplesRu extends TranslationsDocsComponentsSheetExamplesKo {
	_TranslationsDocsComponentsSheetExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример листа';
}

// Path: docs.components.skeleton.examples
class _TranslationsDocsComponentsSkeletonExamplesRu extends TranslationsDocsComponentsSkeletonExamplesKo {
	_TranslationsDocsComponentsSkeletonExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример скелета';
}

// Path: docs.components.slider.examples
class _TranslationsDocsComponentsSliderExamplesRu extends TranslationsDocsComponentsSliderExamplesKo {
	_TranslationsDocsComponentsSliderExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример слайдера';
}

// Path: docs.components.sortable.examples
class _TranslationsDocsComponentsSortableExamplesRu extends TranslationsDocsComponentsSortableExamplesKo {
	_TranslationsDocsComponentsSortableExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример сортируемого';
}

// Path: docs.components.star_rating.examples
class _TranslationsDocsComponentsStarRatingExamplesRu extends TranslationsDocsComponentsStarRatingExamplesKo {
	_TranslationsDocsComponentsStarRatingExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример рейтинга звезды';
}

// Path: docs.components.stepper.examples
class _TranslationsDocsComponentsStepperExamplesRu extends TranslationsDocsComponentsStepperExamplesKo {
	_TranslationsDocsComponentsStepperExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример степпера';
}

// Path: docs.components.steps.examples
class _TranslationsDocsComponentsStepsExamplesRu extends TranslationsDocsComponentsStepsExamplesKo {
	_TranslationsDocsComponentsStepsExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример шагов';
}

// Path: docs.components.swiper.examples
class _TranslationsDocsComponentsSwiperExamplesRu extends TranslationsDocsComponentsSwiperExamplesKo {
	_TranslationsDocsComponentsSwiperExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример свайпера';
}

// Path: docs.components.k_switch.examples
class _TranslationsDocsComponentsKSwitchExamplesRu extends TranslationsDocsComponentsKSwitchExamplesKo {
	_TranslationsDocsComponentsKSwitchExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример переключателя';
}

// Path: docs.components.switcher.examples
class _TranslationsDocsComponentsSwitcherExamplesRu extends TranslationsDocsComponentsSwitcherExamplesKo {
	_TranslationsDocsComponentsSwitcherExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример переключателя';
}

// Path: docs.components.tab_list.examples
class _TranslationsDocsComponentsTabListExamplesRu extends TranslationsDocsComponentsTabListExamplesKo {
	_TranslationsDocsComponentsTabListExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример списка вкладок';
}

// Path: docs.components.tab_pane.examples
class _TranslationsDocsComponentsTabPaneExamplesRu extends TranslationsDocsComponentsTabPaneExamplesKo {
	_TranslationsDocsComponentsTabPaneExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример панели вкладок';
}

// Path: docs.components.table.examples
class _TranslationsDocsComponentsTableExamplesRu extends TranslationsDocsComponentsTableExamplesKo {
	_TranslationsDocsComponentsTableExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример таблицы';
}

// Path: docs.components.tabs.examples
class _TranslationsDocsComponentsTabsExamplesRu extends TranslationsDocsComponentsTabsExamplesKo {
	_TranslationsDocsComponentsTabsExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример вкладок';
}

// Path: docs.components.text_area.examples
class _TranslationsDocsComponentsTextAreaExamplesRu extends TranslationsDocsComponentsTextAreaExamplesKo {
	_TranslationsDocsComponentsTextAreaExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример текстовой области';
}

// Path: docs.components.time_picker.examples
class _TranslationsDocsComponentsTimePickerExamplesRu extends TranslationsDocsComponentsTimePickerExamplesKo {
	_TranslationsDocsComponentsTimePickerExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример выбора времени';
}

// Path: docs.components.timeline.examples
class _TranslationsDocsComponentsTimelineExamplesRu extends TranslationsDocsComponentsTimelineExamplesKo {
	_TranslationsDocsComponentsTimelineExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример таймлайна';
}

// Path: docs.components.timeline_animation.examples
class _TranslationsDocsComponentsTimelineAnimationExamplesRu extends TranslationsDocsComponentsTimelineAnimationExamplesKo {
	_TranslationsDocsComponentsTimelineAnimationExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример анимации таймлайна';
}

// Path: docs.components.toast.examples
class _TranslationsDocsComponentsToastExamplesRu extends TranslationsDocsComponentsToastExamplesKo {
	_TranslationsDocsComponentsToastExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример тоста';
}

// Path: docs.components.toggle.examples
class _TranslationsDocsComponentsToggleExamplesRu extends TranslationsDocsComponentsToggleExamplesKo {
	_TranslationsDocsComponentsToggleExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример переключателя';
}

// Path: docs.components.tooltip.examples
class _TranslationsDocsComponentsTooltipExamplesRu extends TranslationsDocsComponentsTooltipExamplesKo {
	_TranslationsDocsComponentsTooltipExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример всплывающей подсказки';
}

// Path: docs.components.tracker.examples
class _TranslationsDocsComponentsTrackerExamplesRu extends TranslationsDocsComponentsTrackerExamplesKo {
	_TranslationsDocsComponentsTrackerExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример трекера';
}

// Path: docs.components.tree.examples
class _TranslationsDocsComponentsTreeExamplesRu extends TranslationsDocsComponentsTreeExamplesKo {
	_TranslationsDocsComponentsTreeExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример дерева';
}

// Path: docs.components.window.examples
class _TranslationsDocsComponentsWindowExamplesRu extends TranslationsDocsComponentsWindowExamplesKo {
	_TranslationsDocsComponentsWindowExamplesRu._(TranslationsRu root) : this._root = root, super.internal(root);

	final TranslationsRu _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Пример окна';
}
