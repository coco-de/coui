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
class TranslationsAr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsAr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ar,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <ar>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsAr _root = this; // ignore: unused_field

	@override 
	TranslationsAr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsAr(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsWidgetbookAr widgetbook = _TranslationsWidgetbookAr._(_root);
	@override late final _TranslationsDocsAr docs = _TranslationsDocsAr._(_root);
}

// Path: widgetbook
class _TranslationsWidgetbookAr extends TranslationsWidgetbookKo {
	_TranslationsWidgetbookAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsWidgetbookCommonAr common = _TranslationsWidgetbookCommonAr._(_root);
	@override late final _TranslationsWidgetbookLoadingAr loading = _TranslationsWidgetbookLoadingAr._(_root);
	@override late final _TranslationsWidgetbookTabsAr tabs = _TranslationsWidgetbookTabsAr._(_root);
	@override late final _TranslationsWidgetbookPaginationAr pagination = _TranslationsWidgetbookPaginationAr._(_root);
	@override late final _TranslationsWidgetbookTooltipAr tooltip = _TranslationsWidgetbookTooltipAr._(_root);
	@override late final _TranslationsWidgetbookRadioAr radio = _TranslationsWidgetbookRadioAr._(_root);
	@override late final _TranslationsWidgetbookCardAr card = _TranslationsWidgetbookCardAr._(_root);
	@override late final _TranslationsWidgetbookAlertAr alert = _TranslationsWidgetbookAlertAr._(_root);
	@override late final _TranslationsWidgetbookAccordionAr accordion = _TranslationsWidgetbookAccordionAr._(_root);
	@override late final _TranslationsWidgetbookSkeletonAr skeleton = _TranslationsWidgetbookSkeletonAr._(_root);
	@override late final _TranslationsWidgetbookToastAr toast = _TranslationsWidgetbookToastAr._(_root);
	@override late final _TranslationsWidgetbookChipAr chip = _TranslationsWidgetbookChipAr._(_root);
	@override late final _TranslationsWidgetbookCheckboxAr checkbox = _TranslationsWidgetbookCheckboxAr._(_root);
	@override late final _TranslationsWidgetbookToggleAr toggle = _TranslationsWidgetbookToggleAr._(_root);
	@override late final _TranslationsWidgetbookDialogAr dialog = _TranslationsWidgetbookDialogAr._(_root);
	@override late final _TranslationsWidgetbookPopoverAr popover = _TranslationsWidgetbookPopoverAr._(_root);
	@override late final _TranslationsWidgetbookTextFieldAr text_field = _TranslationsWidgetbookTextFieldAr._(_root);
	@override late final _TranslationsWidgetbookButtonAr button = _TranslationsWidgetbookButtonAr._(_root);
	@override late final _TranslationsWidgetbookTableAr table = _TranslationsWidgetbookTableAr._(_root);
	@override late final _TranslationsWidgetbookKSwitchAr k_switch = _TranslationsWidgetbookKSwitchAr._(_root);
	@override late final _TranslationsWidgetbookSwitchComponentAr switch_component = _TranslationsWidgetbookSwitchComponentAr._(_root);
	@override late final _TranslationsWidgetbookSelectAr select = _TranslationsWidgetbookSelectAr._(_root);
	@override late final _TranslationsWidgetbookBreadcrumbAr breadcrumb = _TranslationsWidgetbookBreadcrumbAr._(_root);
	@override late final _TranslationsWidgetbookBadgeAr badge = _TranslationsWidgetbookBadgeAr._(_root);
	@override late final _TranslationsWidgetbookThemePreviewAr theme_preview = _TranslationsWidgetbookThemePreviewAr._(_root);
	@override late final _TranslationsWidgetbookChatAr chat = _TranslationsWidgetbookChatAr._(_root);
	@override late final _TranslationsWidgetbookMultipleChoiceAr multiple_choice = _TranslationsWidgetbookMultipleChoiceAr._(_root);
	@override late final _TranslationsWidgetbookFormattedInputAr formatted_input = _TranslationsWidgetbookFormattedInputAr._(_root);
	@override late final _TranslationsWidgetbookSwiperAr swiper = _TranslationsWidgetbookSwiperAr._(_root);
}

// Path: docs
class _TranslationsDocsAr extends TranslationsDocsKo {
	_TranslationsDocsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsCommonAr common = _TranslationsDocsCommonAr._(_root);
	@override late final _TranslationsDocsBadgesAr badges = _TranslationsDocsBadgesAr._(_root);
	@override late final _TranslationsDocsFlavorsAr flavors = _TranslationsDocsFlavorsAr._(_root);
	@override late final _TranslationsDocsNavigationAr navigation = _TranslationsDocsNavigationAr._(_root);
	@override late final _TranslationsDocsPagesAr pages = _TranslationsDocsPagesAr._(_root);
	@override late final _TranslationsDocsComponentsAr components = _TranslationsDocsComponentsAr._(_root);
}

// Path: widgetbook.common
class _TranslationsWidgetbookCommonAr extends TranslationsWidgetbookCommonKo {
	_TranslationsWidgetbookCommonAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get increment_progress => 'زيادة التقدم';
	@override String selected_tab({required Object index}) => 'التبويب المحدد: ${index}';
	@override String current_page({required Object page}) => 'الصفحة الحالية: ${page}';
	@override String total_pages({required Object count}) => 'إجمالي الصفحات: ${count}';
	@override String page_of({required Object current, required Object total}) => '${current} صفحة / ${total}';
	@override String get hover_over_icon => 'مرر فوق الأيقونة';
	@override String counter({required Object count}) => 'عداد: ${count}';
	@override String selected_rows({required Object count}) => 'الصفوف المحددة: ${count}';
	@override String value({required Object value}) => 'القيمة: ${value}';
	@override String selected_cells({required Object count}) => 'الخلايا المحددة: ${count}';
}

// Path: widgetbook.loading
class _TranslationsWidgetbookLoadingAr extends TranslationsWidgetbookLoadingKo {
	_TranslationsWidgetbookLoadingAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get indeterminate => 'تحميل غير محدد';
	@override String with_value({required Object percent}) => 'مع قيمة (${percent}%)';
	@override String get custom_size => 'حجم مخصص';
	@override String get custom_height => 'ارتفاع مخصص';
	@override String get circular_progress => 'تقدم دائري';
	@override String get linear_progress => 'تقدم خطي';
}

// Path: widgetbook.tabs
class _TranslationsWidgetbookTabsAr extends TranslationsWidgetbookTabsKo {
	_TranslationsWidgetbookTabsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get home => 'الرئيسية';
	@override String get profile => 'الملف الشخصي';
	@override String get settings => 'الإعدادات';
	@override String get overview => 'نظرة عامة';
	@override String get details => 'تفاصيل';
	@override String get history => 'تاريخ';
	@override String get overview_content => 'محتوى النظرة العامة';
	@override String get details_content => 'محتوى التفاصيل';
	@override String get history_content => 'محتوى التاريخ';
	@override String get general_info => 'معلومات عامة عن العنصر';
	@override String get specifications => 'المواصفات والتفاصيل';
	@override String get timeline => 'جدول التغييرات والتحديثات';
}

// Path: widgetbook.pagination
class _TranslationsWidgetbookPaginationAr extends TranslationsWidgetbookPaginationKo {
	_TranslationsWidgetbookPaginationAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get show_skip_to_first => 'عرض تخطي إلى الأول';
	@override String get show_skip_to_last => 'عرض تخطي إلى الأخير';
	@override String get hide_previous_on_first => 'إخفاء السابق في الصفحة الأولى';
	@override String get hide_next_on_last => 'إخفاء التالي في الصفحة الأخيرة';
	@override String get max_visible_pages => 'أقصى عدد من الصفحات المرئية';
}

// Path: widgetbook.tooltip
class _TranslationsWidgetbookTooltipAr extends TranslationsWidgetbookTooltipKo {
	_TranslationsWidgetbookTooltipAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get helpful_message => 'رسالة Tooltip مفيدة';
	@override String get tooltip_above => 'Tooltip فوق';
	@override String get tooltip_below => 'Tooltip أدناه';
	@override String get tooltip_left => 'Tooltip على اليسار';
	@override String get tooltip_right => 'Tooltip على اليمين';
	@override String get top => 'الأعلى';
	@override String get bottom => 'الأسفل';
	@override String get left => 'اليسار';
	@override String get right => 'اليمين';
}

// Path: widgetbook.radio
class _TranslationsWidgetbookRadioAr extends TranslationsWidgetbookRadioKo {
	_TranslationsWidgetbookRadioAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get small => 'صغير';
	@override String get medium => 'متوسط';
	@override String get large => 'كبير';
}

// Path: widgetbook.card
class _TranslationsWidgetbookCardAr extends TranslationsWidgetbookCardKo {
	_TranslationsWidgetbookCardAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get card_content => 'محتوى البطاقة';
	@override String get gradient_card => 'بطاقة متدرجة';
	@override String get custom_decoration => 'بطاقة بزخرفة مخصصة';
}

// Path: widgetbook.alert
class _TranslationsWidgetbookAlertAr extends TranslationsWidgetbookAlertKo {
	_TranslationsWidgetbookAlertAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'عنوان التنبيه';
	@override String get message => 'هذه رسالة تنبيه.';
}

// Path: widgetbook.accordion
class _TranslationsWidgetbookAccordionAr extends TranslationsWidgetbookAccordionKo {
	_TranslationsWidgetbookAccordionAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get what_is_coui => 'ما هو CoUI Flutter؟';
	@override String get what_is_coui_answer => 'CoUI Flutter هي مكتبة مكونات واجهة مستخدم شاملة مصممة لبناء تطبيقات Flutter حديثة وقابلة للوصول باستخدام أنماط تصميم متناسقة.';
	@override String get how_to_install => 'كيف يتم التثبيت؟';
	@override String get how_to_install_answer => 'أضف coui_flutter إلى اعتماديات pubspec.yaml وشغل flutter pub get لتثبيت الحزمة.';
	@override String get is_customizable => 'هل يمكن تخصيصها؟';
	@override String get is_customizable_answer => 'نعم! توفر CoUI Flutter دعم موضوع شامل يسمح لك بتخصيص الألوان والطباعة والفجوات من خلال ThemeData.';
	@override String get getting_started => 'ابدأ';
	@override String get getting_started_answer => 'ابدأ بتثبيت الحزمة وإضافتها إلى مشروعك. لمزيد من تفاصيل إعداد التفاصيل، يرجى الرجوع إلى الوثائق.';
	@override String get features_expanded => 'الميزات (التوسيع الافتراضي)';
	@override String get features_answer => 'تشمل CoUI Flutter الأزرار والنماذج والصناديق الحوارية ومكونات التنقل. تم تصميم جميع المكونات مع مراعاة إمكانية الوصول والموضوع.';
	@override String get support => 'الدعم';
	@override String get support_answer => 'إذا كان لديك أي استفسارات أو تحتاج إلى دعم، قم بزيارة مستودع GitHub أو تحقق من الوثائق على docs.coui.dev.';
}

// Path: widgetbook.skeleton
class _TranslationsWidgetbookSkeletonAr extends TranslationsWidgetbookSkeletonKo {
	_TranslationsWidgetbookSkeletonAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get skeleton_enabled => 'تفعيل الهيكل العظمي:';
	@override String get title_text => 'هذا هو العنوان';
	@override String get description_text => 'هذا نص وصف طويل';
	@override String get short_text => 'نص قصير';
	@override String get without_skeleton => 'بدون الهيكل العظمي:';
	@override String get with_skeleton => 'مع الهيكل العظمي:';
	@override String get user_name => 'اسم المستخدم';
	@override String get user_email => 'user@example.com';
	@override String get article_title => 'عنوان المقال';
	@override String get posted_date => 'تاريخ النشر: 1 يناير 2024';
	@override String get bio_description => 'مطور يسجل حياته اليومية';
	@override String get show_content => 'عرض المحتوى';
	@override String get show_loading => 'عرض التحميل';
	@override String get article_content => 'هذا مثال لمحتوى المقال. يتم استبداله بالهيكل العظمي أثناء التحميل.';
}

// Path: widgetbook.toast
class _TranslationsWidgetbookToastAr extends TranslationsWidgetbookToastKo {
	_TranslationsWidgetbookToastAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get success => 'نجاح';
	@override String get operation_completed => 'تم إكمال العملية بنجاح';
	@override String get show_toast => 'عرض Toast';
	@override String toast_at({required Object location}) => 'Toast في ${location}';
	@override String get top_left => 'أعلى اليسار';
	@override String get top_center => 'الوسط العلوي';
	@override String get top_right => 'أعلى اليمين';
	@override String get bottom_left => 'أسفل اليسار';
	@override String get bottom_center => 'الوسط السفلي';
	@override String get bottom_right => 'أسفل اليمين';
}

// Path: widgetbook.chip
class _TranslationsWidgetbookChipAr extends TranslationsWidgetbookChipKo {
	_TranslationsWidgetbookChipAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get chip => 'شريحة';
}

// Path: widgetbook.checkbox
class _TranslationsWidgetbookCheckboxAr extends TranslationsWidgetbookCheckboxKo {
	_TranslationsWidgetbookCheckboxAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get accept_terms => 'أوافق على الشروط والأحكام';
	@override String get tristate => 'ثلاث حالات';
}

// Path: widgetbook.toggle
class _TranslationsWidgetbookToggleAr extends TranslationsWidgetbookToggleKo {
	_TranslationsWidgetbookToggleAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get toggle => 'تبديل';
}

// Path: widgetbook.dialog
class _TranslationsWidgetbookDialogAr extends TranslationsWidgetbookDialogKo {
	_TranslationsWidgetbookDialogAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic_dialog => 'حوار أساسي';
	@override String get basic_title => 'الحوار الأساسي';
	@override String get basic_content => 'حوار بسيط بعنوان ومحتوى.';
	@override String get simple_dialog_content => 'هذا حوار بسيط يحتوي على عنوان ومحتوى.';
	@override String get show_basic => 'عرض أساسي';
	@override String get show_basic_dialog => 'عرض الحوار الأساسي';
	@override String get confirm_action => 'تأكيد العمل';
	@override String get confirm_title => 'تأكيد';
	@override String get confirm_content => 'هل تريد حقًا إجراء هذه العملية؟';
	@override String get confirm_action_content => 'هل أنت متأكد أنك تريد تنفيذ هذا الإجراء؟ لا يمكن إلغاء هذا الإجراء.';
	@override String get cancel => 'إلغاء';
	@override String get confirm => 'تأكيد';
	@override String get show_confirmation => 'عرض التأكيد';
	@override String get show_confirmation_dialog => 'عرض حوار التأكيد';
	@override String get warning => 'تحذير';
	@override String get warning_title => 'تحذير';
	@override String get warning_content => 'قد يؤثر هذا الإجراء على البيانات. يرجى proceed بحذر.';
	@override String get dismiss => 'إغلاق';
	@override String get show_warning => 'عرض التحذير';
	@override String get show_warning_dialog => 'عرض حوار التحذير';
}

// Path: widgetbook.popover
class _TranslationsWidgetbookPopoverAr extends TranslationsWidgetbookPopoverKo {
	_TranslationsWidgetbookPopoverAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get popover_content => 'محتوى Popover';
	@override String get content_title => 'عنوان البوب أوفر';
	@override String get content_description => 'بوب أوفر بمحتوى قابل للتخصيص.';
	@override String get customizable_content => 'Popover بمحتوى قابل للتخصيص.';
	@override String get show_popover => 'عرض Popover';
	@override String popover_at({required Object position}) => 'Popover في ${position}';
	@override String get top => 'أعلى';
	@override String get bottom => 'أسفل';
	@override String get left => 'يسار';
	@override String get right => 'يمين';
}

// Path: widgetbook.text_field
class _TranslationsWidgetbookTextFieldAr extends TranslationsWidgetbookTextFieldKo {
	_TranslationsWidgetbookTextFieldAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get enter_name => 'أدخل الاسم';
	@override String get type_here => 'اكتب هنا';
}

// Path: widgetbook.button
class _TranslationsWidgetbookButtonAr extends TranslationsWidgetbookButtonKo {
	_TranslationsWidgetbookButtonAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get primary_button => 'زر أساسي';
	@override String get secondary_button => 'زر ثانوي';
	@override String get dashed_button => 'تحميل ملف';
	@override String get upload_file => 'تحميل ملف';
}

// Path: widgetbook.table
class _TranslationsWidgetbookTableAr extends TranslationsWidgetbookTableKo {
	_TranslationsWidgetbookTableAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get name => 'الاسم';
	@override String get email => 'البريد الإلكتروني';
	@override String get role => 'الدور';
	@override String get john_doe => 'جون دو';
	@override String get john_email => 'john@example.com';
	@override String get developer => 'مطور';
	@override String get jane_smith => 'جين سميث';
	@override String get jane_email => 'jane@example.com';
	@override String get designer => 'مصمم';
	@override String get bob_johnson => 'بوب جونسون';
	@override String get bob_email => 'bob@example.com';
	@override String get manager => 'مدير';
	@override String get select => 'تحديد';
	@override String get product => 'المنتج';
	@override String get price => 'السعر';
	@override String get stock => 'المخزون';
	@override String get laptop => 'حاسوب محمول';
	@override String get mouse => 'فأرة';
	@override String get keyboard => 'لوحة مفاتيح';
}

// Path: widgetbook.k_switch
class _TranslationsWidgetbookKSwitchAr extends TranslationsWidgetbookKSwitchKo {
	_TranslationsWidgetbookKSwitchAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get k_switch => 'تبديل';
}

// Path: widgetbook.switch_component
class _TranslationsWidgetbookSwitchComponentAr extends TranslationsWidgetbookSwitchComponentKo {
	_TranslationsWidgetbookSwitchComponentAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get switch_label => 'تسمية التبديل';
}

// Path: widgetbook.select
class _TranslationsWidgetbookSelectAr extends TranslationsWidgetbookSelectKo {
	_TranslationsWidgetbookSelectAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get apple => 'تفاح';
	@override String get banana => 'موز';
	@override String get cherry => 'كرز';
	@override String get date => 'تمر';
	@override String get choose_size => 'اختر الحجم';
	@override String get small => 'صغير';
	@override String get medium => 'متوسط';
	@override String get large => 'كبير';
	@override String get extra_large => 'كبير جدًا';
}

// Path: widgetbook.breadcrumb
class _TranslationsWidgetbookBreadcrumbAr extends TranslationsWidgetbookBreadcrumbKo {
	_TranslationsWidgetbookBreadcrumbAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get home => 'الرئيسية';
	@override String get products => 'المنتجات';
	@override String get electronics => 'الإلكترونيات';
	@override String get smartphones => 'الهاتف الذكي';
	@override String get documents => 'المستندات';
	@override String get projects => 'المشاريع';
	@override String get current_folder => 'المجلد الحالي';
	@override String current_path({required Object path}) => 'المسار الحالي: ${path}';
}

// Path: widgetbook.badge
class _TranslationsWidgetbookBadgeAr extends TranslationsWidgetbookBadgeKo {
	_TranslationsWidgetbookBadgeAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get primary => 'أساسي';
	@override String get secondary => 'ثانوي';
	@override String get outline => 'حدود';
	@override String get destructive => 'مدمر';
	@override String get featured => 'مميز';
	@override String get more => 'المزيد';
	@override String get verified => 'تم التحقق';
	@override String get error => 'خطأ';
	@override String get click_me => 'اضغط علي';
	@override String get clickable => 'يمكن النقر';
}

// Path: widgetbook.theme_preview
class _TranslationsWidgetbookThemePreviewAr extends TranslationsWidgetbookThemePreviewKo {
	_TranslationsWidgetbookThemePreviewAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'معاينة السمة';
	@override String get description => 'نظرة شاملة على جميع رموز السمات وأنماط المكونات.';
	@override String get color_palette => 'لوحة الألوان';
	@override String get brand_colors => 'ألوان العلامة التجارية';
	@override String get base_colors => 'الألوان الأساسية';
	@override String get status_colors => 'ألوان الحالة';
	@override String get buttons => 'الأزرار';
	@override String get primary_button => 'أساسي';
	@override String get secondary_button => 'ثانوي';
	@override String get outline_button => 'مخطط';
	@override String get ghost_button => 'شبح';
	@override String get destructive_button => 'مدمر';
	@override String get disabled_button => 'معطل';
	@override String get cards => 'البطاقات';
	@override String get card_title => 'عنوان البطاقة';
	@override String get card_description => 'هذا وصف نموذج البطاقة.';
	@override String get surface_card => 'بطاقة السطح';
	@override String get filled_variant => 'أسلوب مليء بخلفية';
	@override String get form_elements => 'عناصر النموذج';
	@override String get text_input_placeholder => 'أدخل النص هنا...';
	@override String get checkbox_checked => 'محدد';
	@override String get checkbox_unchecked => 'غير محدد';
	@override String get toggle_on => 'مفعل';
	@override String get toggle_off => 'معطل';
	@override String get alerts => 'التنبيهات';
	@override String get info_alert => 'تنبيه المعلومات';
	@override String get info_alert_message => 'هذه رسالة إرشادية.';
	@override String get error_alert => 'تنبيه الخطأ';
	@override String get error_alert_message => 'حدثت مشكلة.';
	@override String get badges_chips => 'شارات ورقائق';
	@override String get primary_badge => 'أساسي';
	@override String get secondary_badge => 'ثانوي';
	@override String get outline_badge => 'مخطط';
	@override String get destructive_badge => 'مدمر';
	@override String get chip_example => 'المفضلة';
	@override String get typography => 'الطباعة';
	@override String get heading_1 => 'العنوان 1';
	@override String get heading_2 => 'العنوان 2';
	@override String get heading_3 => 'العنوان 3';
	@override String get heading_4 => 'العنوان 4';
	@override String get body_text => 'نص الجسم بسمك عادي.';
	@override String get small_text => 'نص صغير للتعليقات.';
	@override String get muted_text => 'نص باهت للمعلومات الإضافية.';
	@override String get bold_text => 'نص عريض للتأكيد.';
	@override String get spacing_radius => 'فراغ & زوايا مدورة';
	@override String get border_radius => 'زاوية حدودية';
	@override String get loading_states => 'حالات التحميل';
}

// Path: widgetbook.chat
class _TranslationsWidgetbookChatAr extends TranslationsWidgetbookChatKo {
	_TranslationsWidgetbookChatAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get hello => 'مرحبا! كيف حالك؟';
	@override String get doing_great => 'بخير، شكرا!';
	@override String get nice_weather => 'الطقس جميل اليوم!';
	@override String get yes_beautiful => 'نعم، إنه جميل!';
	@override String get sender => 'المرسل';
	@override String get receiver => 'المستقبل';
}

// Path: widgetbook.multiple_choice
class _TranslationsWidgetbookMultipleChoiceAr extends TranslationsWidgetbookMultipleChoiceKo {
	_TranslationsWidgetbookMultipleChoiceAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get option_a => 'Option A';
	@override String get option_b => 'Option B';
	@override String get option_c => 'Option C';
	@override String get option_d => 'Option D';
	@override String selected_value({required Object value}) => 'المحدد: ${value}';
	@override String selected_values({required Object values}) => 'المحدد: ${values}';
}

// Path: widgetbook.formatted_input
class _TranslationsWidgetbookFormattedInputAr extends TranslationsWidgetbookFormattedInputKo {
	_TranslationsWidgetbookFormattedInputAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get date_format => 'صيغة التاريخ (MM/DD/YYYY)';
	@override String get time_format => 'صيغة الوقت (HH:MM)';
	@override String current_value({required Object value}) => 'القيمة الحالية: ${value}';
}

// Path: widgetbook.swiper
class _TranslationsWidgetbookSwiperAr extends TranslationsWidgetbookSwiperKo {
	_TranslationsWidgetbookSwiperAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get swipe_hint => 'اسحب أو اضغط للفتح';
	@override String get overlay_content => 'محتوى التراكب';
	@override String get close => 'إغلاق';
}

// Path: docs.common
class _TranslationsDocsCommonAr extends TranslationsDocsCommonKo {
	_TranslationsDocsCommonAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get app_name => 'coui_flutter';
	@override String get search_documentation => 'البحث في الوثائق...';
	@override String get docs => 'الوثائق';
	@override String get components => 'المكونات';
	@override String get close => 'إغلاق';
	@override String get on_this_page => 'فهرس هذه الصفحة';
	@override String get work_in_progress_title => 'قيد التطوير';
	@override String get work_in_progress_message => 'هذه الصفحة قيد التطوير. يرجى العودة لاحقًا.';
	@override String get add => 'إضافة';
	@override String get reset => 'إعادة تعيين';
	@override String get prev => 'السابق';
	@override String get next => 'التالي';
	@override String get finish => 'إنهاء';
	@override String get open => 'فتح';
	@override String get disabled => 'معطلة';
	@override String get refresh => 'تحديث';
	@override String get rebuild => 'إعادة بناء';
	@override String get change_color => 'تغيير اللون';
}

// Path: docs.badges
class _TranslationsDocsBadgesAr extends TranslationsDocsBadgesKo {
	_TranslationsDocsBadgesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get k_new => 'جديد';
	@override String get updated => 'محدث';
	@override String get wip => 'قيد التطوير';
	@override String get experimental => 'تجريبي';
}

// Path: docs.flavors
class _TranslationsDocsFlavorsAr extends TranslationsDocsFlavorsKo {
	_TranslationsDocsFlavorsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get local => 'محلي';
	@override String get experimental => 'تجريبي';
	@override String get unknown => 'غير معروف';
}

// Path: docs.navigation
class _TranslationsDocsNavigationAr extends TranslationsDocsNavigationKo {
	_TranslationsDocsNavigationAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get getting_started => 'البدء';
	@override String get animation => 'الرسوم المتحركة';
	@override String get control => 'التحكم';
	@override String get disclosure => 'الكشف';
	@override String get display => 'عرض';
	@override String get feedback => 'التعليقات';
	@override String get form => 'النموذج';
	@override String get layout => 'التخطيط';
	@override String get navigation => 'الملاحة';
	@override String get overlay => 'تراكب';
	@override String get utility => 'أداة';
	@override String get my_account => 'حسابي';
	@override String get profile => 'الملف الشخصي';
	@override String get settings => 'الإعدادات';
	@override String get team => 'الفريق';
	@override String get new_team => 'فريق جديد';
	@override String get billing => 'الفواتير';
	@override String get api => 'API';
	@override String get log_out => 'تسجيل الخروج';
	@override String get support => 'الدعم';
	@override String get invite_users => 'دعوة المستخدمين';
	@override String get more => 'المزيد';
	@override String get github => 'GitHub';
	@override String get note => 'ملاحظة';
	@override String get message => 'رسالة';
	@override String get keyboard_shortcuts => 'اختصارات لوحة المفاتيح';
}

// Path: docs.pages
class _TranslationsDocsPagesAr extends TranslationsDocsPagesKo {
	_TranslationsDocsPagesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsPagesIntroductionAr introduction = _TranslationsDocsPagesIntroductionAr._(_root);
	@override late final _TranslationsDocsPagesInstallationAr installation = _TranslationsDocsPagesInstallationAr._(_root);
	@override late final _TranslationsDocsPagesThemeAr theme = _TranslationsDocsPagesThemeAr._(_root);
	@override late final _TranslationsDocsPagesTypographyAr typography = _TranslationsDocsPagesTypographyAr._(_root);
	@override late final _TranslationsDocsPagesLayoutAr layout = _TranslationsDocsPagesLayoutAr._(_root);
	@override late final _TranslationsDocsPagesWebPreloaderAr web_preloader = _TranslationsDocsPagesWebPreloaderAr._(_root);
	@override late final _TranslationsDocsPagesComponentsListAr components_list = _TranslationsDocsPagesComponentsListAr._(_root);
	@override late final _TranslationsDocsPagesIconsAr icons = _TranslationsDocsPagesIconsAr._(_root);
	@override late final _TranslationsDocsPagesColorsAr colors = _TranslationsDocsPagesColorsAr._(_root);
	@override late final _TranslationsDocsPagesExternalAr external = _TranslationsDocsPagesExternalAr._(_root);
	@override late final _TranslationsDocsPagesStateAr state = _TranslationsDocsPagesStateAr._(_root);
}

// Path: docs.components
class _TranslationsDocsComponentsAr extends TranslationsDocsComponentsKo {
	_TranslationsDocsComponentsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsComponentsAccordionAr accordion = _TranslationsDocsComponentsAccordionAr._(_root);
	@override late final _TranslationsDocsComponentsAlertAr alert = _TranslationsDocsComponentsAlertAr._(_root);
	@override late final _TranslationsDocsComponentsAlertDialogAr alert_dialog = _TranslationsDocsComponentsAlertDialogAr._(_root);
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderAr animated_value_builder = _TranslationsDocsComponentsAnimatedValueBuilderAr._(_root);
	@override late final _TranslationsDocsComponentsAppBarAr app_bar = _TranslationsDocsComponentsAppBarAr._(_root);
	@override late final _TranslationsDocsComponentsAutocompleteAr autocomplete = _TranslationsDocsComponentsAutocompleteAr._(_root);
	@override late final _TranslationsDocsComponentsAvatarAr avatar = _TranslationsDocsComponentsAvatarAr._(_root);
	@override late final _TranslationsDocsComponentsAvatarGroupAr avatar_group = _TranslationsDocsComponentsAvatarGroupAr._(_root);
	@override late final _TranslationsDocsComponentsBadgeAr badge = _TranslationsDocsComponentsBadgeAr._(_root);
	@override late final _TranslationsDocsComponentsBreadcrumbAr breadcrumb = _TranslationsDocsComponentsBreadcrumbAr._(_root);
	@override late final _TranslationsDocsComponentsButtonAr button = _TranslationsDocsComponentsButtonAr._(_root);
	@override late final _TranslationsDocsComponentsCalendarAr calendar = _TranslationsDocsComponentsCalendarAr._(_root);
	@override late final _TranslationsDocsComponentsCardAr card = _TranslationsDocsComponentsCardAr._(_root);
	@override late final _TranslationsDocsComponentsCardImageAr card_image = _TranslationsDocsComponentsCardImageAr._(_root);
	@override late final _TranslationsDocsComponentsCarouselAr carousel = _TranslationsDocsComponentsCarouselAr._(_root);
	@override late final _TranslationsDocsComponentsCheckboxAr checkbox = _TranslationsDocsComponentsCheckboxAr._(_root);
	@override late final _TranslationsDocsComponentsChipAr chip = _TranslationsDocsComponentsChipAr._(_root);
	@override late final _TranslationsDocsComponentsChipInputAr chip_input = _TranslationsDocsComponentsChipInputAr._(_root);
	@override late final _TranslationsDocsComponentsCircularProgressAr circular_progress = _TranslationsDocsComponentsCircularProgressAr._(_root);
	@override late final _TranslationsDocsComponentsCodeSnippetAr code_snippet = _TranslationsDocsComponentsCodeSnippetAr._(_root);
	@override late final _TranslationsDocsComponentsCollapsibleAr collapsible = _TranslationsDocsComponentsCollapsibleAr._(_root);
	@override late final _TranslationsDocsComponentsColorPickerAr color_picker = _TranslationsDocsComponentsColorPickerAr._(_root);
	@override late final _TranslationsDocsComponentsCommandAr command = _TranslationsDocsComponentsCommandAr._(_root);
	@override late final _TranslationsDocsComponentsContextMenuAr context_menu = _TranslationsDocsComponentsContextMenuAr._(_root);
	@override late final _TranslationsDocsComponentsDatePickerAr date_picker = _TranslationsDocsComponentsDatePickerAr._(_root);
	@override late final _TranslationsDocsComponentsDialogAr dialog = _TranslationsDocsComponentsDialogAr._(_root);
	@override late final _TranslationsDocsComponentsDividerAr divider = _TranslationsDocsComponentsDividerAr._(_root);
	@override late final _TranslationsDocsComponentsDotIndicatorAr dot_indicator = _TranslationsDocsComponentsDotIndicatorAr._(_root);
	@override late final _TranslationsDocsComponentsDrawerAr drawer = _TranslationsDocsComponentsDrawerAr._(_root);
	@override late final _TranslationsDocsComponentsDropdownMenuAr dropdown_menu = _TranslationsDocsComponentsDropdownMenuAr._(_root);
	@override late final _TranslationsDocsComponentsExpandableSidebarAr expandable_sidebar = _TranslationsDocsComponentsExpandableSidebarAr._(_root);
	@override late final _TranslationsDocsComponentsFormAr form = _TranslationsDocsComponentsFormAr._(_root);
	@override late final _TranslationsDocsComponentsFormattedInputAr formatted_input = _TranslationsDocsComponentsFormattedInputAr._(_root);
	@override late final _TranslationsDocsComponentsHoverCardAr hover_card = _TranslationsDocsComponentsHoverCardAr._(_root);
	@override late final _TranslationsDocsComponentsInputAr input = _TranslationsDocsComponentsInputAr._(_root);
	@override late final _TranslationsDocsComponentsInputOtpAr input_otp = _TranslationsDocsComponentsInputOtpAr._(_root);
	@override late final _TranslationsDocsComponentsItemPickerAr item_picker = _TranslationsDocsComponentsItemPickerAr._(_root);
	@override late final _TranslationsDocsComponentsKeyboardDisplayAr keyboard_display = _TranslationsDocsComponentsKeyboardDisplayAr._(_root);
	@override late final _TranslationsDocsComponentsLinearProgressAr linear_progress = _TranslationsDocsComponentsLinearProgressAr._(_root);
	@override late final _TranslationsDocsComponentsMaterialAr material = _TranslationsDocsComponentsMaterialAr._(_root);
	@override late final _TranslationsDocsComponentsMenubarAr menubar = _TranslationsDocsComponentsMenubarAr._(_root);
	@override late final _TranslationsDocsComponentsMultiselectAr multiselect = _TranslationsDocsComponentsMultiselectAr._(_root);
	@override late final _TranslationsDocsComponentsNavigationBarAr navigation_bar = _TranslationsDocsComponentsNavigationBarAr._(_root);
	@override late final _TranslationsDocsComponentsNavigationMenuAr navigation_menu = _TranslationsDocsComponentsNavigationMenuAr._(_root);
	@override late final _TranslationsDocsComponentsNavigationRailAr navigation_rail = _TranslationsDocsComponentsNavigationRailAr._(_root);
	@override late final _TranslationsDocsComponentsNavigationSidebarAr navigation_sidebar = _TranslationsDocsComponentsNavigationSidebarAr._(_root);
	@override late final _TranslationsDocsComponentsNumberInputAr number_input = _TranslationsDocsComponentsNumberInputAr._(_root);
	@override late final _TranslationsDocsComponentsNumberTickerAr number_ticker = _TranslationsDocsComponentsNumberTickerAr._(_root);
	@override late final _TranslationsDocsComponentsOverflowMarqueeAr overflow_marquee = _TranslationsDocsComponentsOverflowMarqueeAr._(_root);
	@override late final _TranslationsDocsComponentsPaginationAr pagination = _TranslationsDocsComponentsPaginationAr._(_root);
	@override late final _TranslationsDocsComponentsPhoneInputAr phone_input = _TranslationsDocsComponentsPhoneInputAr._(_root);
	@override late final _TranslationsDocsComponentsPopoverAr popover = _TranslationsDocsComponentsPopoverAr._(_root);
	@override late final _TranslationsDocsComponentsProgressAr progress = _TranslationsDocsComponentsProgressAr._(_root);
	@override late final _TranslationsDocsComponentsRadioCardAr radio_card = _TranslationsDocsComponentsRadioCardAr._(_root);
	@override late final _TranslationsDocsComponentsRadioGroupAr radio_group = _TranslationsDocsComponentsRadioGroupAr._(_root);
	@override late final _TranslationsDocsComponentsRefreshTriggerAr refresh_trigger = _TranslationsDocsComponentsRefreshTriggerAr._(_root);
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderAr repeated_animation_builder = _TranslationsDocsComponentsRepeatedAnimationBuilderAr._(_root);
	@override late final _TranslationsDocsComponentsResizableAr resizable = _TranslationsDocsComponentsResizableAr._(_root);
	@override late final _TranslationsDocsComponentsScaffoldAr scaffold = _TranslationsDocsComponentsScaffoldAr._(_root);
	@override late final _TranslationsDocsComponentsSelectAr select = _TranslationsDocsComponentsSelectAr._(_root);
	@override late final _TranslationsDocsComponentsSheetAr sheet = _TranslationsDocsComponentsSheetAr._(_root);
	@override late final _TranslationsDocsComponentsSkeletonAr skeleton = _TranslationsDocsComponentsSkeletonAr._(_root);
	@override late final _TranslationsDocsComponentsSliderAr slider = _TranslationsDocsComponentsSliderAr._(_root);
	@override late final _TranslationsDocsComponentsSortableAr sortable = _TranslationsDocsComponentsSortableAr._(_root);
	@override late final _TranslationsDocsComponentsStarRatingAr star_rating = _TranslationsDocsComponentsStarRatingAr._(_root);
	@override late final _TranslationsDocsComponentsStepperAr stepper = _TranslationsDocsComponentsStepperAr._(_root);
	@override late final _TranslationsDocsComponentsStepsAr steps = _TranslationsDocsComponentsStepsAr._(_root);
	@override late final _TranslationsDocsComponentsSwiperAr swiper = _TranslationsDocsComponentsSwiperAr._(_root);
	@override late final _TranslationsDocsComponentsKSwitchAr k_switch = _TranslationsDocsComponentsKSwitchAr._(_root);
	@override late final _TranslationsDocsComponentsSwitcherAr switcher = _TranslationsDocsComponentsSwitcherAr._(_root);
	@override late final _TranslationsDocsComponentsTabListAr tab_list = _TranslationsDocsComponentsTabListAr._(_root);
	@override late final _TranslationsDocsComponentsTabPaneAr tab_pane = _TranslationsDocsComponentsTabPaneAr._(_root);
	@override late final _TranslationsDocsComponentsTableAr table = _TranslationsDocsComponentsTableAr._(_root);
	@override late final _TranslationsDocsComponentsTabsAr tabs = _TranslationsDocsComponentsTabsAr._(_root);
	@override late final _TranslationsDocsComponentsTextAreaAr text_area = _TranslationsDocsComponentsTextAreaAr._(_root);
	@override late final _TranslationsDocsComponentsTimePickerAr time_picker = _TranslationsDocsComponentsTimePickerAr._(_root);
	@override late final _TranslationsDocsComponentsTimelineAr timeline = _TranslationsDocsComponentsTimelineAr._(_root);
	@override late final _TranslationsDocsComponentsTimelineAnimationAr timeline_animation = _TranslationsDocsComponentsTimelineAnimationAr._(_root);
	@override late final _TranslationsDocsComponentsToastAr toast = _TranslationsDocsComponentsToastAr._(_root);
	@override late final _TranslationsDocsComponentsToggleAr toggle = _TranslationsDocsComponentsToggleAr._(_root);
	@override late final _TranslationsDocsComponentsTooltipAr tooltip = _TranslationsDocsComponentsTooltipAr._(_root);
	@override late final _TranslationsDocsComponentsTrackerAr tracker = _TranslationsDocsComponentsTrackerAr._(_root);
	@override late final _TranslationsDocsComponentsTreeAr tree = _TranslationsDocsComponentsTreeAr._(_root);
	@override late final _TranslationsDocsComponentsWindowAr window = _TranslationsDocsComponentsWindowAr._(_root);
}

// Path: docs.pages.introduction
class _TranslationsDocsPagesIntroductionAr extends TranslationsDocsPagesIntroductionKo {
	_TranslationsDocsPagesIntroductionAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'مقدمة';
	@override String get description => 'البدء مع coui_flutter';
	@override String get lead => 'الآن يمكنك استخدام مكونات مصممة بشكل جميل من Coui/UI على Flutter.';
	@override String get welcome_paragraph_1 => 'coui_flutter هو مجموعة شاملة ومتنوعة من مكونات واجهة المستخدم مصممة خصيصًا لتطبيقات Flutter على سطح المكتب والويب. مع ازدياد شعبية Flutter في بناء التطبيقات عبر الأنظمة الأساسية، أدركنا الحاجة إلى مجموعة أدوات تسلط الضوء على متطلبات التصميم الفريدة لواجهات سطح المكتب والويب.';
	@override String get welcome_paragraph_2 => 'توفر هذه الحزمة مجموعة واسعة من المكونات القابلة للتخصيص والاستجابة والتي تتماشى مع مبادئ التصميم المعاصر لسطح المكتب والويب. سواء كنت تبني تطبيقات أعمال متطورة أو لوحات معلومات أنيقة أو أدوات إنتاجية، تم تصميم مكوناتنا لمساعدتك في إنشاء واجهات مستخدم احترافية وأنيقة بسرعة وكفاءة.';
	@override String get features => 'الميزات الرئيسية';
	@override late final _TranslationsDocsPagesIntroductionFeaturesListAr features_list = _TranslationsDocsPagesIntroductionFeaturesListAr._(_root);
	@override String get notes => 'ملاحظات';
	@override String get notes_paragraph_1 => 'هذه الحزمة لا تزال قيد التطوير وقد يحدث تغييرات في المستقبل. يرجى توخي الحذر عند استخدام هذه الحزمة في الإنتاج.';
	@override String get notes_paragraph_2 => 'هذه الحزمة ليست مرتبطة بـ Coui/UI. هذه الحزمة مشروع يقوده المجتمع.';
	@override String get faq => 'الأسئلة الشائعة';
	@override String get faq_gorouter_q => 'هل يدعم GoRouter؟';
	@override String get faq_gorouter_a => 'نعم، يدعم. يمكنك استخدام GoRouter مع coui_flutter.';
	@override String get faq_usage_q => 'هل أستطيع استخدامه في مشروعي؟';
	@override String get faq_usage_a => 'نعم! يمكنك استخدامه مجانًا في المشاريع الشخصية والتجارية. لا حاجة للنسب إلى المؤلف.';
	@override String get faq_material_q => 'هل يمكن استخدامه مع مكونات Material/Cupertino؟';
	@override String get faq_material_a_1 => 'بالطبع!';
	@override String get faq_material_a_2 => 'يرجى الرجوع إلى هذه الصفحة!';
	@override String get faq_style_q => 'هل يمكنني تحديد أي نمط لاستخدامه؟ (افتراضي/نيويورك)';
	@override String get faq_style_a_1 => 'للأسف، لا يمكنك. تدعم هذه الحزمة نمط نيويورك فقط. ولكن إذا كنت ترغب في النمط الافتراضي لـ Coui/UI،';
	@override String get faq_style_a_2 => 'أوصي بهذه الحزمة:';
	@override String get faq_style_a_3 => 'المؤلف:';
	@override String get links => 'روابط';
	@override String get link_github => 'Github: ';
	@override String get link_pubdev => 'pub.dev: ';
	@override String get link_discord => 'Discord: ';
}

// Path: docs.pages.installation
class _TranslationsDocsPagesInstallationAr extends TranslationsDocsPagesInstallationKo {
	_TranslationsDocsPagesInstallationAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'التثبيت';
	@override String get description => 'تثبيت coui_flutter في المشروع';
	@override String get stable_version => 'النسخة المستقرة';
	@override String get experimental_version => 'النسخة التجريبية';
	@override String get step1_title => 'إنشاء مشروع فلاتر جديد';
	@override String get step1_content => 'استخدم الأمر التالي لإنشاء مشروع فلاتر جديد:';
	@override String get step2_title => 'إضافة الاعتماديات';
	@override String get step2_content => 'بعد ذلك، أضف اعتماديات coui_flutter إلى مشروعك.';
	@override String get step3_title => 'استيراد الحزمة';
	@override String get step3_content => 'الآن يمكنك استيراد الحزمة في كود Dart الخاص بك.';
	@override String get step4_title => 'إضافة عنصر واجهة CouiApp';
	@override String get step4_content => 'قم بإضافة عنصر واجهة CouiApp في دالة main.';
	@override String get step5_title => 'تشغيل التطبيق';
	@override String get step5_content => 'استخدم الأمر التالي لتشغيل التطبيق:';
	@override String get experimental_intro => 'النسخة التجريبية متاحة على GitHub.';
	@override String get experimental_usage => 'لاستخدام النسخة التجريبية، استخدم git بدلاً من رقم الإصدار في ملف pubspec.yaml:';
	@override String get see_page => 'راجع: ';
	@override String get this_page => 'هذه الصفحة';
	@override String get for_more_info => ' لمزيد من المعلومات.';
	@override String get warning_title => 'تحذير';
	@override String get warning_content => 'قد تحتوي النسخة التجريبية على تغييرات قد تكسر التوافق، ولا يُنصح باستخدامها في الإنتاج. هذه النسخة مخصصة للاختبار والتطوير فقط.';
}

// Path: docs.pages.theme
class _TranslationsDocsPagesThemeAr extends TranslationsDocsPagesThemeKo {
	_TranslationsDocsPagesThemeAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الموضوع';
	@override String get description => 'تخصيص الموضوع';
	@override String get custom_color_scheme => 'نظام الألوان المخصص';
	@override String get custom_color_scheme_desc => 'يمكنك تخصيص شكل ومظهر التطبيق باستخدام نظام ألوان مخصص.';
	@override String get premade_color_schemes => 'أنظمة الألوان الجاهزة';
	@override String get premade_color_schemes_desc => 'يمكنك تخصيص شكل ومظهر التطبيق باستخدام أنظمة ألوان جاهزة.';
	@override String get radius => 'نصف القطر';
	@override String get radius_desc => 'يمكنك تخصيص مدى انحناء التطبيق من خلال تغيير نصف القطر.';
	@override String get scaling => 'التكبير';
	@override String get scaling_desc => 'يمكنك تخصيص مقياس عناصر coui_flutter من خلال تغيير التكبير.';
	@override String get scaling_alert => 'لن يؤدي ذلك إلى تكبير أو تصغير التطبيق بأكمله. ستتأثر فقط عناصر coui_flutter.';
	@override String get surface_opacity => 'عتمة السطح';
	@override String get surface_opacity_desc => 'يمكنك تخصيص عتمة السطح من خلال تغيير عتمة السطح.';
	@override String get surface_blur => 'ضبابية السطح';
	@override String get surface_blur_desc => 'يمكنك تخصيص ضبابية السطح من خلال تغيير ضبابية السطح.';
	@override String get code => 'الكود';
	@override String get code_desc => 'استخدم الكود التالي لتطبيق نظام الألوان.';
}

// Path: docs.pages.typography
class _TranslationsDocsPagesTypographyAr extends TranslationsDocsPagesTypographyKo {
	_TranslationsDocsPagesTypographyAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الطباعة';
	@override String get description => 'أنماط النص';
	@override String get headline1 => 'العنوان 1';
	@override String get headline2 => 'العنوان 2';
	@override String get headline3 => 'العنوان 3';
	@override String get headline4 => 'العنوان 4';
	@override String get paragraph => 'فقرة';
	@override String get blockquote => 'اقتباس';
	@override String get list => 'قائمة';
	@override String get inline_code => 'كود مضمن';
	@override String get lead => 'رئيسي';
	@override String get large_text => 'نص كبير';
	@override String get small_text => 'نص صغير';
	@override String get muted_text => 'نص رمادي';
	@override String get sans => 'Sans';
	@override String get mono => 'Mono';
	@override String get extra_small => 'صغير جدًا';
	@override String get small => 'صغير';
	@override String get base => 'أساسي';
	@override String get large => 'كبير';
	@override String get extra_large => 'كبير جدًا';
	@override String get extra_2x_large => 'كبير جدًا 2x';
	@override String get extra_3x_large => 'كبير جدًا 3x';
	@override String get extra_4x_large => 'كبير جدًا 4x';
	@override String get extra_5x_large => 'كبير جدًا 5x';
	@override String get extra_6x_large => 'كبير جدًا 6x';
	@override String get extra_7x_large => 'كبير جدًا 7x';
	@override String get extra_8x_large => 'كبير جدًا 8x';
	@override String get extra_9x_large => 'كبير جدًا 9x';
	@override String get thin => 'رفيع';
	@override String get extra_light => 'خفيف جدًا';
	@override String get light => 'خفيف';
	@override String get normal => 'عادي';
	@override String get medium => 'متوسط';
	@override String get semi_bold => 'نصف غامق';
	@override String get bold => 'غامق';
	@override String get extra_bold => 'غامق جدًا';
	@override String get black => 'أسود';
	@override String get italic => 'مائل';
}

// Path: docs.pages.layout
class _TranslationsDocsPagesLayoutAr extends TranslationsDocsPagesLayoutKo {
	_TranslationsDocsPagesLayoutAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'التخطيط';
	@override String get description => 'ترتيب تخطيط الصفحة';
	@override String get padding => 'padding';
	@override String get margin => 'هامش';
	@override String get center => 'مركز';
	@override String get gapped_column => 'عمود بفواصل';
	@override String get gapped_row => 'صف بفواصل';
	@override String get separated_column => 'عمود مفصول';
	@override String get separated_row => 'صف مفصول';
	@override String get basic_layout => 'تخطيط أساسي';
}

// Path: docs.pages.web_preloader
class _TranslationsDocsPagesWebPreloaderAr extends TranslationsDocsPagesWebPreloaderKo {
	_TranslationsDocsPagesWebPreloaderAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'محمل الويب';
	@override String get description => 'شاشة تحميل الويب';
	@override String get step1_title => 'إنشاء دليل الويب';
	@override String get step1_content => 'إذا لم يكن هناك دليل للويب، قم بإنشائه.';
	@override String get step1_note => '* إذا كنت تستخدم Flutter ويب القديم، فقد تحتاج إلى استخدام الأمر أعلاه للتحديث.';
	@override String get step1_button => 'انقر هنا لمزيد من المعلومات.';
	@override String get step2_title => 'إضافة سكريبت';
	@override String get step2_content => 'ثم، اختر واحدة من التمهيديات الإعدادية التالية وانسخها:';
	@override String get step2_standard => 'تحميل قياسي';
	@override String get step3_title => 'لصق السكريبت';
	@override String get step3_content_1 => 'افتح ملفك ';
	@override String get step3_content_2 => ' والصق السكريبت داخل علامة ';
	@override String get step3_content_3 => '.';
	@override String get step3_example => 'على سبيل المثال:';
	@override String get step4_title => 'تشغيل التطبيق';
	@override String get step4_content => 'استخدم الأمر التالي لتشغيل التطبيق:';
	@override String get alert_title => 'للمساهمة';
	@override String get alert_content_1 => 'إذا كان لديك تمهيد تريد مشاركته، يرجى إنشاء طلب سحب إلى الدليل ';
	@override String get alert_button => 'web_loaders';
	@override String get alert_content_2 => '.';
}

// Path: docs.pages.components_list
class _TranslationsDocsPagesComponentsListAr extends TranslationsDocsPagesComponentsListKo {
	_TranslationsDocsPagesComponentsListAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'المكونات';
	@override String get description => 'قائمة المكونات القابلة لإعادة الاستخدام';
	@override String get work_in_progress => 'قيد العمل';
	@override String get animation => 'الرسوم المتحركة';
	@override String get disclosure => 'الكشف';
	@override String get feedback => 'التغذية الراجعة';
	@override String get forms => 'النماذج';
	@override String get layout => 'التخطيط';
	@override String get navigation => 'التنقل';
	@override String get surfaces => 'السطوح';
	@override String get data_display => 'عرض البيانات';
	@override String get utilities => 'الأدوات';
}

// Path: docs.pages.icons
class _TranslationsDocsPagesIconsAr extends TranslationsDocsPagesIconsKo {
	_TranslationsDocsPagesIconsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الرموز';
	@override String get description => 'نظام الرموز';
	@override String get use_this_code => 'لإظهار هذا الرمز، استخدم الكود التالي:';
	@override String get search_icons => 'ابحث عن الرموز';
	@override String get radix_icons => 'رموز Radix';
	@override String get bootstrap_icons => 'رموز Bootstrap';
	@override String get lucide_icons => 'رموز Lucide';
}

// Path: docs.pages.colors
class _TranslationsDocsPagesColorsAr extends TranslationsDocsPagesColorsKo {
	_TranslationsDocsPagesColorsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'الألوان';
	@override String get description => 'لوحة الألوان';
	@override String get use_this_code => 'لإظهار هذا اللون، استخدم الكود التالي:';
	@override String get color_and_colorshades => 'ثوابت اللون وظل اللون/لون البقعة';
	@override String get predefined_colors => 'ألوان محددة مسبقًا';
	@override String get generate_color => 'إنشاء لون';
	@override String get hue_shift => 'تحويل درجة اللون';
	@override String get saturation_step_up => 'زيادة درجة التشبع';
	@override String get saturation_step_down => 'تقليل درجة التشبع';
	@override String get lightness_step_up => 'زيادة الإضاءة';
	@override String get lightness_step_down => 'تقليل الإضاءة';
	@override String get cancel => 'إلغاء';
	@override String get reset_options => 'إعادة تعيين الخيارات';
	@override String get reset_confirmation => 'هل تريد إعادة تعيين الخيارات؟';
}

// Path: docs.pages.external
class _TranslationsDocsPagesExternalAr extends TranslationsDocsPagesExternalKo {
	_TranslationsDocsPagesExternalAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Material/Cupertino';
	@override String get description => 'استخدام الأدوات الأساسية Flutter';
}

// Path: docs.pages.state
class _TranslationsDocsPagesStateAr extends TranslationsDocsPagesStateKo {
	_TranslationsDocsPagesStateAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get title => 'إدارة الحالة';
	@override String get description => 'أنماط إدارة الحالة';
	@override String get intro_1 => 'في Flutter، كل شيء عبارة عن أدوات، ومكان تخزين البيانات هو نفسه.';
	@override String get intro_2 => 'داخليًا، يحتوي coui_flutter على نظام إدارة حالة خاص به. إذا كنت تستخدم بالفعل نظام إدارة حالات، يمكنك الاستمرار في استخدامه مع coui_flutter.';
	@override String get passing_data_to_children => 'تمرير البيانات إلى الأطفال';
	@override String get passing_data_desc => 'يمكنك استخدام أداة البيانات لتمرير البيانات إلى الأطفال. ستؤدي جميع التغييرات الحاصلة على البيانات إلى إعادة بناء الأطفال.';
	@override String get rebuild_difference_title => 'هل لاحظت الفرق في عدد عمليات إعادة البناء؟';
	@override String get rebuild_difference_content => 'MostInnerWidget يعاد بناؤه عندما تتغير البيانات، بينما InnerWidget لا يفعل ذلك. هذا لأن InnerWidget لا يستقبل البيانات.';
	@override String get setting_data_boundary => 'تعيين حدود البيانات';
	@override String get setting_data_boundary_desc => 'يمكنك تعيين الحدود بحيث لا يمكن للأطفال الوصول إلى البيانات.';
	@override String get data_methods_vs => 'Data.maybeOf/Data.of ضد Data.maybeFind/Data.find';
	@override String get data_methods_desc_1 => ' تستخدم البيانات وتقودها إلى إعادة البناء عندما تتغير.';
	@override String get data_methods_desc_2 => 'بينما ';
	@override String get data_methods_desc_3 => ' لا تستقبل البيانات، بل تعيدها فقط.';
	@override String get data_find_usage => 'تكون مناسبة للاستخدام في المكان الذي يتم فيه استدعاء العمليات مثل onPressed، onLongPressed.';
	@override String get data_of_usage => 'تكون مناسبة للاستخدام داخل طريقة build التي تحتاج إلى إعادة بناء عند تغيير البيانات.';
	@override String get getting_data_from_child => 'الحصول على البيانات من الطفل';
	@override String get getting_data_desc_1 => 'يمكن استخدام طريقة للحصول على البيانات من الأطفال. هذه الطريقة لا تستقبل التغييرات الحاصلة على البيانات.';
	@override String get getting_data_desc_2 => 'قد تحدث حلقة إعادة بناء غير منتهية عند استقبالك لتغييرات البيانات. إذا كنت بحاجة إلى البيانات، انتقل إلى الأداة الوالدية.';
	@override String get root_data_title => 'هل لاحظت البيانات الجذرية؟';
	@override String get root_data_content => 'تستخدم البيانات الأكثر داخلية البيانات الخاصة بها. لا يمكن للوالدين الحصول على البيانات إلا من أول طفل متصل.';
	@override String get setting_messenger_boundary => 'تعيين حدود DataMessenger';
	@override String get setting_messenger_boundary_desc => 'يمكنك أيضًا تعيين الحدود بحيث لا يمكن للأطفال الحصول على البيانات من والد معين.';
	@override String get multidata_widget => 'أداة MultiData';
	@override String get multidata_desc => 'باستخدام أداة MultiData، يمكنك تمرير بيانات متعددة إلى الأطفال. انظر المثال التالي:';
	@override String get multidata_avoid_nesting => 'يمكنك استخدام أداة MultiData لتجنب تعشيش الأدوات.';
	@override String get example => 'مثال';
	@override String get passing_state_as_controller => 'تمرير الحالة كتحكم';
	@override String get passing_state_controller_desc => 'يمكنك تمرير الحالة كتحكم إلى الأطفال. وبذلك، يمكن للأطفال استدعاء طرق الوالد.';
	@override String get databuilder => 'DataBuilder';
	@override String get databuilder_desc => 'باستخدام أداة DataBuilder، يمكنك إعادة بناء الأداة عند تغيير البيانات. مما يساعد على تجنب إعادة بناء الأداة بالكامل.';
	@override String get datanotifier => 'DataNotifier';
	@override String get datanotifier_desc => 'باستخدام DataNotifier، يمكنك تمرير قيمة من ValueListenable إلى الأطفال.';
	@override String get example_with_multidata => 'مثال باستخدام MultiData';
	@override String get passing_object_as_data => 'تمرير الكائن كبيانات';
	@override String get passing_object_desc => 'هناك بعض الأمور التي يجب مراعاتها عند تمرير الكائنات كبيانات:';
	@override String get override_equals_hashcode => '1. إعادة تعريف == و hashCode';
	@override String get override_equals_desc => 'عند عدم مطابقة كائن قديم مع كائن جديد، يتم إرسال إشعار إلى الأطفال. إذا لم تقم بتعريف == و hashCode، سيتم اعتباره مختلفًا حتى لو كانت قيم الحقول متشابهة.';
	@override String get use_distinctdata => '2. استخدام DistinctData';
	@override String get use_distinctdata_desc => 'DistinctData هو مزيج يمكنه إعلام الأطفال عندما تتغير حقول معينة.';
	@override String get passing_mutable_object => '3. تمرير كائن متغير إلى الأطفال';
	@override String get passing_mutable_object_desc => 'من الأفضل تمرير كائنات غير قابلة للتغيير للأطفال. لأن الكائنات المتغيرة (مثل القوائم، الخرائط، المجموعات، حالة الأدوات) قد لا تخبر الأطفال عندما تتغير.';
	@override String get passing_variable_to_children => 'تمرير متغيرات إلى الأطفال';
	@override String get passing_variable_desc => 'يمكنك استخدام أداة Model لتمرير المتغيرات إلى الأطفال. تشبه أداة البيانات ولكنها أكثر صرامة من حيث النوع والتسمية.';
	@override String get change_variable_from_children => 'تغيير المتغيرات من الأطفال';
	@override String get change_variable_desc => 'هناك طريقتان لتغيير قيمة النموذج من الأطفال:';
	@override String get modelnotifier => 'ModelNotifier';
	@override String get modelnotifier_desc => 'باستخدام ModelNotifier، يمكنك تمرير قيمة من ValueNotifier إلى الأطفال. ليس هناك حاجة لاستخدام setState في الأداة الوالدية.';
	@override String get modellistenable => 'ModelListenable';
	@override String get modellistenable_desc => 'ModelListenable هو ModelNotifier للقراءة فقط. يتمكن الأطفال فقط من استلام القيمة. قد يؤدي محاولتهم تغيير القيمة إلى خطأ.';
	@override String get modelbuilder => 'ModelBuilder';
	@override String get modelbuilder_desc => 'ModelBuilder يستقبل القيم وإعادة بناء الأداة عند التغيير. تشبه DataBuilder ولكنها أكثر صرامة من حيث النوع والتسمية.';
}

// Path: docs.components.accordion
class _TranslationsDocsComponentsAccordionAr extends TranslationsDocsComponentsAccordionKo {
	_TranslationsDocsComponentsAccordionAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'أكورديون';
	@override String get description => 'الأكورديون هو قائمة عناصر تتراص عمودياً. يمكن \'توسيع\' أو \'طي\' كل عنصر لعرض المحتوى المتعلق به.';
	@override late final _TranslationsDocsComponentsAccordionExamplesAr examples = _TranslationsDocsComponentsAccordionExamplesAr._(_root);
}

// Path: docs.components.alert
class _TranslationsDocsComponentsAlertAr extends TranslationsDocsComponentsAlertKo {
	_TranslationsDocsComponentsAlertAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'تنبيه';
	@override String get description => 'تُستخدم التنبيهات لنقل حالة تؤثر على النظام.';
	@override late final _TranslationsDocsComponentsAlertExamplesAr examples = _TranslationsDocsComponentsAlertExamplesAr._(_root);
	@override String get title => 'عنوان التنبيه';
	@override String get content => 'هذا هو محتوى التنبيه.';
}

// Path: docs.components.alert_dialog
class _TranslationsDocsComponentsAlertDialogAr extends TranslationsDocsComponentsAlertDialogKo {
	_TranslationsDocsComponentsAlertDialogAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'حوار التنبيه';
	@override String get description => 'يظهر حوار التنبيه معلومات مهمة تتطلب انتباه المستخدم.';
	@override late final _TranslationsDocsComponentsAlertDialogExamplesAr examples = _TranslationsDocsComponentsAlertDialogExamplesAr._(_root);
	@override String get click_here => 'اضغط هنا';
	@override String get alert_title => 'عنوان التنبيه';
	@override String get alert_content => 'لوريم إيبسوم دولور سيت أميت، كونسيكتيتور أديبيسكيغ إلليت.';
}

// Path: docs.components.animated_value_builder
class _TranslationsDocsComponentsAnimatedValueBuilderAr extends TranslationsDocsComponentsAnimatedValueBuilderKo {
	_TranslationsDocsComponentsAnimatedValueBuilderAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'منشئ القيمة المتحركة';
	@override String get description => 'منشئ يطبق الرسوم المتحركة تلقائيًا عند تغيير القيمة.';
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderExamplesAr examples = _TranslationsDocsComponentsAnimatedValueBuilderExamplesAr._(_root);
}

// Path: docs.components.app_bar
class _TranslationsDocsComponentsAppBarAr extends TranslationsDocsComponentsAppBarKo {
	_TranslationsDocsComponentsAppBarAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'شريط التطبيق';
	@override String get description => 'شريط التطبيق هو عنصر الملاحة الأساسي المعروض في أعلى التطبيق.';
	@override late final _TranslationsDocsComponentsAppBarExamplesAr examples = _TranslationsDocsComponentsAppBarExamplesAr._(_root);
}

// Path: docs.components.autocomplete
class _TranslationsDocsComponentsAutocompleteAr extends TranslationsDocsComponentsAutocompleteKo {
	_TranslationsDocsComponentsAutocompleteAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'الإكمال التلقائي';
	@override String get description => 'حقل إدخال يعرض الاقتراحات وفقًا لإدخال المستخدم.';
	@override late final _TranslationsDocsComponentsAutocompleteExamplesAr examples = _TranslationsDocsComponentsAutocompleteExamplesAr._(_root);
}

// Path: docs.components.avatar
class _TranslationsDocsComponentsAvatarAr extends TranslationsDocsComponentsAvatarKo {
	_TranslationsDocsComponentsAvatarAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'الصورة الرمزية';
	@override String get description => 'صورة أو أيقونة تمثل مستخدمًا أو كيانًا.';
	@override late final _TranslationsDocsComponentsAvatarExamplesAr examples = _TranslationsDocsComponentsAvatarExamplesAr._(_root);
}

// Path: docs.components.avatar_group
class _TranslationsDocsComponentsAvatarGroupAr extends TranslationsDocsComponentsAvatarGroupKo {
	_TranslationsDocsComponentsAvatarGroupAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'مجموعة الصور الرمزية';
	@override String get description => 'يعرض عدة صور رمزية معًا.';
	@override late final _TranslationsDocsComponentsAvatarGroupExamplesAr examples = _TranslationsDocsComponentsAvatarGroupExamplesAr._(_root);
}

// Path: docs.components.badge
class _TranslationsDocsComponentsBadgeAr extends TranslationsDocsComponentsBadgeKo {
	_TranslationsDocsComponentsBadgeAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'شارة';
	@override String get description => 'ملصق صغير يعرض حالة أو عدد الإشعارات.';
	@override late final _TranslationsDocsComponentsBadgeExamplesAr examples = _TranslationsDocsComponentsBadgeExamplesAr._(_root);
	@override String get primary => 'أساسي';
	@override String get secondary => 'ثانوي';
	@override String get outline => 'خط خارجي';
	@override String get destructive => 'مدمر';
}

// Path: docs.components.breadcrumb
class _TranslationsDocsComponentsBreadcrumbAr extends TranslationsDocsComponentsBreadcrumbKo {
	_TranslationsDocsComponentsBreadcrumbAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'فتات الخبز';
	@override String get description => 'فتات الخبز هو نظام ملاحة ثانوي يوضح موقع المستخدم في موقع الويب أو التطبيق.';
	@override late final _TranslationsDocsComponentsBreadcrumbExamplesAr examples = _TranslationsDocsComponentsBreadcrumbExamplesAr._(_root);
	@override String get home => 'الرئيسية';
	@override String get components => 'المكونات';
}

// Path: docs.components.button
class _TranslationsDocsComponentsButtonAr extends TranslationsDocsComponentsButtonKo {
	_TranslationsDocsComponentsButtonAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'زر';
	@override String get description => 'تتيح الأزرار للمستخدم تنفيذ إجراء أو اختيار بضغطة واحدة.';
	@override late final _TranslationsDocsComponentsButtonExamplesAr examples = _TranslationsDocsComponentsButtonExamplesAr._(_root);
	@override String get primary => 'أساسي';
	@override String get secondary => 'ثانوي';
	@override String get outlined => 'مؤطر';
	@override String get ghost => 'شبح';
	@override String get destructive => 'مدمر';
	@override String get link => 'رابط';
	@override String get outline => 'خط خارجي';
	@override String get text => 'نص';
	@override String get extra_small => 'إضافي صغير';
	@override String get small => 'صغير';
	@override String get normal => 'عادي';
	@override String get large => 'كبير';
	@override String get extra_large => 'إضافي كبير';
	@override String get save => 'حفظ';
	@override String get cancel => 'إلغاء';
	@override String get close => 'إغلاق';
	@override String get submit => 'إرسال';
	@override String get edit_profile => 'تعديل الملف الشخصي';
	@override String get save_changes => 'حفظ التغييرات';
	@override String get undo => 'تراجع';
	@override String get compact => 'مضغوط';
	@override String get dense => 'كثيف';
	@override String get comfortable => 'مريح';
	@override String get icon => 'أيقونة';
	@override String get icon_comfortable => 'أيقونة مريحة';
	@override String get rectangle => 'مستطيل';
	@override String get add => 'إضافة';
	@override String get focused => 'مركّز';
	@override String get hovered => 'مرر فوقها';
	@override String get pressed => 'ضغطت';
	@override String get text_button => 'زر نص';
	@override String get custom_button => 'زر مخصص';
}

// Path: docs.components.calendar
class _TranslationsDocsComponentsCalendarAr extends TranslationsDocsComponentsCalendarKo {
	_TranslationsDocsComponentsCalendarAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'التقويم';
	@override String get description => 'مكون التقويم لاختيار وعرض التواريخ.';
	@override late final _TranslationsDocsComponentsCalendarExamplesAr examples = _TranslationsDocsComponentsCalendarExamplesAr._(_root);
}

// Path: docs.components.card
class _TranslationsDocsComponentsCardAr extends TranslationsDocsComponentsCardKo {
	_TranslationsDocsComponentsCardAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'بطاقة';
	@override String get description => 'وصف';
	@override late final _TranslationsDocsComponentsCardExamplesAr examples = _TranslationsDocsComponentsCardExamplesAr._(_root);
	@override String get create_project => 'إنشاء مشروع';
	@override String get deploy_description => 'انشر مشروعًا جديدًا بنقرة واحدة';
	@override String get name => 'الاسم';
	@override String get name_placeholder => 'اسم المشروع';
	@override String get description_placeholder => 'وصف المشروع';
	@override String get deploy => 'نشر';
}

// Path: docs.components.card_image
class _TranslationsDocsComponentsCardImageAr extends TranslationsDocsComponentsCardImageKo {
	_TranslationsDocsComponentsCardImageAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'بطاقة الصورة';
	@override String get description => 'مكون بطاقة يتضمن صورة.';
	@override late final _TranslationsDocsComponentsCardImageExamplesAr examples = _TranslationsDocsComponentsCardImageExamplesAr._(_root);
	@override String get card_image_title => 'صورة البطاقة';
	@override String get card_clicked => 'تم النقر على صورة البطاقة';
	@override String card_number({required Object n}) => 'رقم البطاقة ${n}';
	@override String get lorem_ipsum => 'لوريم إيبسوم دولور سيت أميت';
}

// Path: docs.components.carousel
class _TranslationsDocsComponentsCarouselAr extends TranslationsDocsComponentsCarouselKo {
	_TranslationsDocsComponentsCarouselAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'دوار';
	@override String get description => 'مكون يعرض عناصر متعددة كتحريك.';
	@override late final _TranslationsDocsComponentsCarouselExamplesAr examples = _TranslationsDocsComponentsCarouselExamplesAr._(_root);
}

// Path: docs.components.checkbox
class _TranslationsDocsComponentsCheckboxAr extends TranslationsDocsComponentsCheckboxKo {
	_TranslationsDocsComponentsCheckboxAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'مربع اختيار';
	@override String get description => 'يمكن لمربع الاختيار أن يسمح للمستخدم باختيار عنصر أو أكثر من القائمة.';
	@override late final _TranslationsDocsComponentsCheckboxExamplesAr examples = _TranslationsDocsComponentsCheckboxExamplesAr._(_root);
	@override String get remember_me => 'تذكرني';
}

// Path: docs.components.chip
class _TranslationsDocsComponentsChipAr extends TranslationsDocsComponentsChipKo {
	_TranslationsDocsComponentsChipAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'شريحة';
	@override String get description => 'الشريحة هي عنصر صغير تمثل خصائص أو اختيارات أو إجراءات.';
	@override late final _TranslationsDocsComponentsChipExamplesAr examples = _TranslationsDocsComponentsChipExamplesAr._(_root);
	@override String get apple => 'تفاح';
	@override String get banana => 'موز';
	@override String get cherry => 'كرز';
	@override String get durian => 'دوريان';
	@override String get elderberry => 'توته';
}

// Path: docs.components.chip_input
class _TranslationsDocsComponentsChipInputAr extends TranslationsDocsComponentsChipInputKo {
	_TranslationsDocsComponentsChipInputAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'إدخال الشريحة';
	@override String get description => 'حقل إدخال يسمح بإدخال قيم متعددة على شكل شرائح.';
	@override late final _TranslationsDocsComponentsChipInputExamplesAr examples = _TranslationsDocsComponentsChipInputExamplesAr._(_root);
}

// Path: docs.components.circular_progress
class _TranslationsDocsComponentsCircularProgressAr extends TranslationsDocsComponentsCircularProgressKo {
	_TranslationsDocsComponentsCircularProgressAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'التقدم الدائري';
	@override String get description => 'مؤشر تقدم دائري.';
	@override late final _TranslationsDocsComponentsCircularProgressExamplesAr examples = _TranslationsDocsComponentsCircularProgressExamplesAr._(_root);
	@override String get increase_by_10 => 'زيادة بمقدار 10';
	@override String get decrease_by_10 => 'انخفاض بمقدار 10';
}

// Path: docs.components.code_snippet
class _TranslationsDocsComponentsCodeSnippetAr extends TranslationsDocsComponentsCodeSnippetKo {
	_TranslationsDocsComponentsCodeSnippetAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'قصاصة الشيفرة';
	@override String get description => 'مكون يعرض الشيفرة.';
	@override late final _TranslationsDocsComponentsCodeSnippetExamplesAr examples = _TranslationsDocsComponentsCodeSnippetExamplesAr._(_root);
}

// Path: docs.components.collapsible
class _TranslationsDocsComponentsCollapsibleAr extends TranslationsDocsComponentsCollapsibleKo {
	_TranslationsDocsComponentsCollapsibleAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'قابل للطي';
	@override String get description => 'حاوية محتوى يمكن طيها أو توسيعها.';
	@override late final _TranslationsDocsComponentsCollapsibleExamplesAr examples = _TranslationsDocsComponentsCollapsibleExamplesAr._(_root);
	@override String get starred_repositories => '@coco-de قد وضع نجوم على 3 مستودعات';
	@override String get collapse_all => 'طي الكل';
	@override String get expand_all => 'توسيع الكل';
	@override String get expand_icon => 'توسيع الأيقونة';
	@override String get use_path_branch => 'استخدام فرع المسار';
	@override String get recursive_selection => 'اختيار متكرر';
}

// Path: docs.components.color_picker
class _TranslationsDocsComponentsColorPickerAr extends TranslationsDocsComponentsColorPickerKo {
	_TranslationsDocsComponentsColorPickerAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'اختر اللون';
	@override String get description => 'مكون يتيح لك اختيار الألوان.';
	@override late final _TranslationsDocsComponentsColorPickerExamplesAr examples = _TranslationsDocsComponentsColorPickerExamplesAr._(_root);
	@override String get pick_color => 'اختر اللون';
	@override String color_label({required Object color}) => 'اللون: ${color}';
	@override String get select_color => 'اختر اللون';
	@override String get open_color_picker_popover => 'فتح نافذة اختيار اللون';
	@override String get open_color_picker_dialog => 'فتح حوار اختيار اللون';
}

// Path: docs.components.command
class _TranslationsDocsComponentsCommandAr extends TranslationsDocsComponentsCommandKo {
	_TranslationsDocsComponentsCommandAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'الأمر';
	@override String get description => 'الأمر هو مكون يتيح لك البحث عن العناصر.';
	@override late final _TranslationsDocsComponentsCommandExamplesAr examples = _TranslationsDocsComponentsCommandExamplesAr._(_root);
}

// Path: docs.components.context_menu
class _TranslationsDocsComponentsContextMenuAr extends TranslationsDocsComponentsContextMenuKo {
	_TranslationsDocsComponentsContextMenuAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'قائمة السياق';
	@override String get description => 'قائمة تظهر عند النقر بزر الفأرة الأيمن أو الضغط لفترة طويلة.';
	@override late final _TranslationsDocsComponentsContextMenuExamplesAr examples = _TranslationsDocsComponentsContextMenuExamplesAr._(_root);
}

// Path: docs.components.date_picker
class _TranslationsDocsComponentsDatePickerAr extends TranslationsDocsComponentsDatePickerKo {
	_TranslationsDocsComponentsDatePickerAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'اختيار التاريخ';
	@override String get description => 'حقل إدخال يتيح لك اختيار التاريخ.';
	@override late final _TranslationsDocsComponentsDatePickerExamplesAr examples = _TranslationsDocsComponentsDatePickerExamplesAr._(_root);
	@override String get select_date => 'اختر التاريخ';
	@override String get select_date_range => 'اختر نطاق التاريخ';
}

// Path: docs.components.dialog
class _TranslationsDocsComponentsDialogAr extends TranslationsDocsComponentsDialogKo {
	_TranslationsDocsComponentsDialogAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'حوار';
	@override String get description => 'الحوار هو نافذة modal تظهر فوق باقي أجزاء التطبيق.';
	@override late final _TranslationsDocsComponentsDialogExamplesAr examples = _TranslationsDocsComponentsDialogExamplesAr._(_root);
	@override String get edit_profile_title => 'تعديل الملف الشخصي';
	@override String get edit_profile_description => 'قم بتغيير ملفك الشخصي هنا. اضغط حفظ عند الانتهاء.';
	@override String get name_label => 'الاسم';
	@override String get username_label => 'اسم المستخدم';
	@override String get hello => 'مرحبا';
	@override String get material_dialog_content => 'هذا حوار Material.';
	@override String get cupertino_dialog_content => 'هذا حوار Cupertino.';
	@override String get alert_title => 'عنوان التنبيه';
	@override String get click_here => 'اضغط هنا';
	@override String get ok => 'موافق';
	@override String get open_material_dialog => 'فتح حوار Material';
	@override String get open_cupertino_dialog => 'فتح حوار Cupertino';
	@override String get open_coui_dialog => 'فتح حوار COUI';
}

// Path: docs.components.divider
class _TranslationsDocsComponentsDividerAr extends TranslationsDocsComponentsDividerKo {
	_TranslationsDocsComponentsDividerAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'فاصل';
	@override String get description => 'خط يفصل المحتوى بصريًا.';
	@override late final _TranslationsDocsComponentsDividerExamplesAr examples = _TranslationsDocsComponentsDividerExamplesAr._(_root);
	@override String get item_1 => 'العنصر 1';
	@override String get item_2 => 'العنصر 2';
	@override String get item_3 => 'العنصر 3';
	@override String get divider => 'فاصل';
}

// Path: docs.components.dot_indicator
class _TranslationsDocsComponentsDotIndicatorAr extends TranslationsDocsComponentsDotIndicatorKo {
	_TranslationsDocsComponentsDotIndicatorAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'مؤشر النقاط';
	@override String get description => 'مؤشر يُظهر الموقع الحالي كنقطة.';
	@override late final _TranslationsDocsComponentsDotIndicatorExamplesAr examples = _TranslationsDocsComponentsDotIndicatorExamplesAr._(_root);
}

// Path: docs.components.drawer
class _TranslationsDocsComponentsDrawerAr extends TranslationsDocsComponentsDrawerKo {
	_TranslationsDocsComponentsDrawerAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'درج';
	@override String get description => 'لوحة تنزلق من حافة الشاشة.';
	@override late final _TranslationsDocsComponentsDrawerExamplesAr examples = _TranslationsDocsComponentsDrawerExamplesAr._(_root);
	@override String get open_drawer => 'فتح الدرج';
	@override String get close_drawer => 'إغلاق الدرج';
	@override String get open_another_drawer => 'فتح درج آخر';
	@override String drawer_at({required Object count, required Object position}) => 'الدرج رقم ${count} عند ${position}';
}

// Path: docs.components.dropdown_menu
class _TranslationsDocsComponentsDropdownMenuAr extends TranslationsDocsComponentsDropdownMenuKo {
	_TranslationsDocsComponentsDropdownMenuAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'قائمة منسدلة';
	@override String get description => 'قائمة تعرض خيارات قابلة للاختيار.';
	@override late final _TranslationsDocsComponentsDropdownMenuExamplesAr examples = _TranslationsDocsComponentsDropdownMenuExamplesAr._(_root);
}

// Path: docs.components.expandable_sidebar
class _TranslationsDocsComponentsExpandableSidebarAr extends TranslationsDocsComponentsExpandableSidebarKo {
	_TranslationsDocsComponentsExpandableSidebarAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'شريط جانبي قابل للتوسيع';
	@override String get description => 'شريط جانبي يمكن توسيعه وطيه.';
	@override late final _TranslationsDocsComponentsExpandableSidebarExamplesAr examples = _TranslationsDocsComponentsExpandableSidebarExamplesAr._(_root);
}

// Path: docs.components.form
class _TranslationsDocsComponentsFormAr extends TranslationsDocsComponentsFormKo {
	_TranslationsDocsComponentsFormAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'نموذج';
	@override String get description => 'أداة مساعدة لإنشاء تحقق من صحة النموذج بسهولة.';
	@override late final _TranslationsDocsComponentsFormExamplesAr examples = _TranslationsDocsComponentsFormExamplesAr._(_root);
	@override String get username_label => 'اسم المستخدم';
	@override String get username_hint => 'الاسم المعروض علنًا';
	@override String get password_label => 'كلمة المرور';
	@override String get confirm_password_label => 'تأكيد كلمة المرور';
	@override String get passwords_do_not_match => 'كلمات المرور لا تتطابق';
	@override String get agree_terms => 'أوافق على الشروط والأحكام';
	@override String get must_agree_terms => 'يجب أن توافق على الشروط والأحكام';
	@override String get form_values_title => 'قيم النموذج';
	@override String get register => 'تسجيل';
	@override String get username_already_taken => 'اسم المستخدم مستخدم بالفعل';
	@override String get email => 'الإيميل';
	@override String username_display({required Object value}) => 'اسم المستخدم: ${value}';
	@override String password_display({required Object value}) => 'كلمة المرور: ${value}';
	@override String confirm_password_display({required Object value}) => 'تأكيد كلمة المرور: ${value}';
	@override String agree_display({required Object value}) => 'الاتفاق: ${value}';
	@override String json_display({required Object value}) => 'JSON: ${value}';
	@override String submitted_value_display({required Object value}) => 'القيمة المقدمة: ${value}';
	@override String get login => 'تسجيل الدخول';
	@override String get sign_up => 'التسجيل';
	@override String get dont_have_account => 'لا تملك حسابًا؟';
	@override String get already_have_account => 'هل لديك حساب بالفعل؟';
}

// Path: docs.components.formatted_input
class _TranslationsDocsComponentsFormattedInputAr extends TranslationsDocsComponentsFormattedInputKo {
	_TranslationsDocsComponentsFormattedInputAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'إدخال منسق';
	@override String get description => 'حقل نص يتطلب تنسيقًا معينًا.';
	@override late final _TranslationsDocsComponentsFormattedInputExamplesAr examples = _TranslationsDocsComponentsFormattedInputExamplesAr._(_root);
}

// Path: docs.components.hover_card
class _TranslationsDocsComponentsHoverCardAr extends TranslationsDocsComponentsHoverCardKo {
	_TranslationsDocsComponentsHoverCardAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'بطاقة هوفر';
	@override String get description => 'بطاقة تظهر عند تمرير الماوس.';
	@override late final _TranslationsDocsComponentsHoverCardExamplesAr examples = _TranslationsDocsComponentsHoverCardExamplesAr._(_root);
	@override String get flutter_handle => '@flutter';
	@override String get flutter_username => 'فلاتر';
	@override String get flutter_description => 'يقدم SDK فلاتر أدوات لبناء تطبيقات جميلة للجوّال والويب وسطح المكتب من قاعدة شيفرة واحدة.';
}

// Path: docs.components.input
class _TranslationsDocsComponentsInputAr extends TranslationsDocsComponentsInputKo {
	_TranslationsDocsComponentsInputAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'الإدخال';
	@override String get description => 'حقل إدخال النص.';
	@override late final _TranslationsDocsComponentsInputExamplesAr examples = _TranslationsDocsComponentsInputExamplesAr._(_root);
	@override String get enter_name => 'أدخل اسمك';
	@override String get enter_username => 'أدخل اسم المستخدم';
	@override String get username_already_taken => 'اسم المستخدم مستخدم بالفعل';
	@override String get hello_world => 'مرحبا بالعالم!';
	@override String get search_something => 'ابحث عن شيء...';
	@override String get email => 'البريد الإلكتروني';
	@override String get password => 'أدخل كلمة المرور';
	@override String get username_hint => 'هذا من أجل اسم المستخدم الخاص بك';
}

// Path: docs.components.input_otp
class _TranslationsDocsComponentsInputOtpAr extends TranslationsDocsComponentsInputOtpKo {
	_TranslationsDocsComponentsInputOtpAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'إدخال OTP';
	@override String get description => 'حقل لإدخال كلمة المرور المؤقتة.';
	@override late final _TranslationsDocsComponentsInputOtpExamplesAr examples = _TranslationsDocsComponentsInputOtpExamplesAr._(_root);
}

// Path: docs.components.item_picker
class _TranslationsDocsComponentsItemPickerAr extends TranslationsDocsComponentsItemPickerKo {
	_TranslationsDocsComponentsItemPickerAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'اختر عنصر';
	@override String get description => 'مكون يتيح لك اختيار عنصر من قائمة.';
	@override late final _TranslationsDocsComponentsItemPickerExamplesAr examples = _TranslationsDocsComponentsItemPickerExamplesAr._(_root);
}

// Path: docs.components.keyboard_display
class _TranslationsDocsComponentsKeyboardDisplayAr extends TranslationsDocsComponentsKeyboardDisplayKo {
	_TranslationsDocsComponentsKeyboardDisplayAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'عرض لوحة المفاتيح';
	@override String get description => 'مكون يعرض اختصارات لوحة المفاتيح.';
	@override late final _TranslationsDocsComponentsKeyboardDisplayExamplesAr examples = _TranslationsDocsComponentsKeyboardDisplayExamplesAr._(_root);
}

// Path: docs.components.linear_progress
class _TranslationsDocsComponentsLinearProgressAr extends TranslationsDocsComponentsLinearProgressKo {
	_TranslationsDocsComponentsLinearProgressAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'التقدم الخطي';
	@override String get description => 'مؤشر تقدم خطي.';
	@override late final _TranslationsDocsComponentsLinearProgressExamplesAr examples = _TranslationsDocsComponentsLinearProgressExamplesAr._(_root);
	@override String get increase => 'زيادة';
	@override String get decrease => 'انخفاض';
}

// Path: docs.components.material
class _TranslationsDocsComponentsMaterialAr extends TranslationsDocsComponentsMaterialKo {
	_TranslationsDocsComponentsMaterialAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Material/Cupertino';
	@override String get description => 'طريقة استخدام أدوات Material و Cupertino الأساسية في Flutter.';
	@override late final _TranslationsDocsComponentsMaterialExamplesAr examples = _TranslationsDocsComponentsMaterialExamplesAr._(_root);
	@override String get my_material_app => 'تطبيقي Material';
	@override String get my_cupertino_app => 'تطبيقي Cupertino';
	@override String you_pushed_button({required Object count}) => 'لقد ضغطت على الزر ${count} مرات';
	@override String get open_material_dialog => 'فتح حوار Material';
	@override String get open_cupertino_dialog => 'فتح حوار Cupertino';
	@override String get open_coui_dialog => 'فتح حوار COUI';
}

// Path: docs.components.menubar
class _TranslationsDocsComponentsMenubarAr extends TranslationsDocsComponentsMenubarKo {
	_TranslationsDocsComponentsMenubarAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'شريط القوائم';
	@override String get description => 'شريط قوائم أفقي.';
	@override late final _TranslationsDocsComponentsMenubarExamplesAr examples = _TranslationsDocsComponentsMenubarExamplesAr._(_root);
	@override String get file => 'ملف';
	@override String get edit => 'تحرير';
	@override String get new_tab => 'علامة تبويب جديدة';
	@override String get new_window => 'نافذة جديدة';
	@override String get new_incognito_window => 'نافذة جديدة في وضع التصفح المتخفي';
	@override String get email_link => 'رابط البريد الإلكتروني';
	@override String get messages => 'رسائل';
	@override String get notes => 'ملاحظات';
	@override String get share => 'مشاركة';
	@override String get print => 'طباعة';
	@override String get save_and_exit => 'حفظ ثم الخروج';
	@override String get discard_and_exit => 'إلغاء ثم الخروج';
	@override String get exit => 'خروج';
	@override String get undo => 'تراجع';
	@override String get redo => 'إعادة';
}

// Path: docs.components.multiselect
class _TranslationsDocsComponentsMultiselectAr extends TranslationsDocsComponentsMultiselectKo {
	_TranslationsDocsComponentsMultiselectAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'تحديد متعدد';
	@override String get description => 'مكون يتيح لك اختيار عناصر متعددة.';
	@override late final _TranslationsDocsComponentsMultiselectExamplesAr examples = _TranslationsDocsComponentsMultiselectExamplesAr._(_root);
}

// Path: docs.components.navigation_bar
class _TranslationsDocsComponentsNavigationBarAr extends TranslationsDocsComponentsNavigationBarKo {
	_TranslationsDocsComponentsNavigationBarAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'شريط الملاحة';
	@override String get description => 'شريط الملاحة السفلي.';
	@override late final _TranslationsDocsComponentsNavigationBarExamplesAr examples = _TranslationsDocsComponentsNavigationBarExamplesAr._(_root);
}

// Path: docs.components.navigation_menu
class _TranslationsDocsComponentsNavigationMenuAr extends TranslationsDocsComponentsNavigationMenuKo {
	_TranslationsDocsComponentsNavigationMenuAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'قائمة الملاحة';
	@override String get description => 'مكون قائمة الملاحة.';
	@override late final _TranslationsDocsComponentsNavigationMenuExamplesAr examples = _TranslationsDocsComponentsNavigationMenuExamplesAr._(_root);
}

// Path: docs.components.navigation_rail
class _TranslationsDocsComponentsNavigationRailAr extends TranslationsDocsComponentsNavigationRailKo {
	_TranslationsDocsComponentsNavigationRailAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'سكة الملاحة';
	@override String get description => 'سكة ملاحة جانبية.';
	@override late final _TranslationsDocsComponentsNavigationRailExamplesAr examples = _TranslationsDocsComponentsNavigationRailExamplesAr._(_root);
}

// Path: docs.components.navigation_sidebar
class _TranslationsDocsComponentsNavigationSidebarAr extends TranslationsDocsComponentsNavigationSidebarKo {
	_TranslationsDocsComponentsNavigationSidebarAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'شريط جانبي للملاحة';
	@override String get description => 'مكون شريط جانبي للملاحة.';
	@override late final _TranslationsDocsComponentsNavigationSidebarExamplesAr examples = _TranslationsDocsComponentsNavigationSidebarExamplesAr._(_root);
}

// Path: docs.components.number_input
class _TranslationsDocsComponentsNumberInputAr extends TranslationsDocsComponentsNumberInputKo {
	_TranslationsDocsComponentsNumberInputAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'إدخال رقم';
	@override String get description => 'حقل لإدخال الأرقام.';
	@override late final _TranslationsDocsComponentsNumberInputExamplesAr examples = _TranslationsDocsComponentsNumberInputExamplesAr._(_root);
	@override String value({required Object value}) => 'القيمة: ${value}';
}

// Path: docs.components.number_ticker
class _TranslationsDocsComponentsNumberTickerAr extends TranslationsDocsComponentsNumberTickerKo {
	_TranslationsDocsComponentsNumberTickerAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'عداد الأرقام';
	@override String get description => 'يظهر رسومًا متحركة عندما تتغير الأرقام.';
	@override late final _TranslationsDocsComponentsNumberTickerExamplesAr examples = _TranslationsDocsComponentsNumberTickerExamplesAr._(_root);
}

// Path: docs.components.overflow_marquee
class _TranslationsDocsComponentsOverflowMarqueeAr extends TranslationsDocsComponentsOverflowMarqueeKo {
	_TranslationsDocsComponentsOverflowMarqueeAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ماركي مفرط';
	@override String get description => 'يتحرك تلقائيًا عند تoverflow النص.';
	@override late final _TranslationsDocsComponentsOverflowMarqueeExamplesAr examples = _TranslationsDocsComponentsOverflowMarqueeExamplesAr._(_root);
}

// Path: docs.components.pagination
class _TranslationsDocsComponentsPaginationAr extends TranslationsDocsComponentsPaginationKo {
	_TranslationsDocsComponentsPaginationAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'التصفح';
	@override String get description => 'مكون يتم استخدامه لتصفح الصفحات.';
	@override late final _TranslationsDocsComponentsPaginationExamplesAr examples = _TranslationsDocsComponentsPaginationExamplesAr._(_root);
}

// Path: docs.components.phone_input
class _TranslationsDocsComponentsPhoneInputAr extends TranslationsDocsComponentsPhoneInputKo {
	_TranslationsDocsComponentsPhoneInputAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'إدخال رقم الهاتف';
	@override String get description => 'حقل لإدخال رقم الهاتف.';
	@override late final _TranslationsDocsComponentsPhoneInputExamplesAr examples = _TranslationsDocsComponentsPhoneInputExamplesAr._(_root);
}

// Path: docs.components.popover
class _TranslationsDocsComponentsPopoverAr extends TranslationsDocsComponentsPopoverKo {
	_TranslationsDocsComponentsPopoverAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'نافذة منبثقة';
	@override String get description => 'نافذة منبثقة تظهر فوق العنصر.';
	@override late final _TranslationsDocsComponentsPopoverExamplesAr examples = _TranslationsDocsComponentsPopoverExamplesAr._(_root);
	@override String get dimensions => 'الأبعاد';
	@override String get set_dimensions => 'حدد حجم الطبقة';
	@override String get width => 'العرض';
	@override String get max_width => 'أقصى عرض';
	@override String get height => 'الارتفاع';
	@override String get max_height => 'أقصى ارتفاع';
	@override String get open_popover => 'فتح النافذة المنبثقة';
	@override String get submit => 'إرسال';
}

// Path: docs.components.progress
class _TranslationsDocsComponentsProgressAr extends TranslationsDocsComponentsProgressKo {
	_TranslationsDocsComponentsProgressAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'التقدم';
	@override String get description => 'يعرض حالة التقدم.';
	@override late final _TranslationsDocsComponentsProgressExamplesAr examples = _TranslationsDocsComponentsProgressExamplesAr._(_root);
}

// Path: docs.components.radio_card
class _TranslationsDocsComponentsRadioCardAr extends TranslationsDocsComponentsRadioCardKo {
	_TranslationsDocsComponentsRadioCardAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'بطاقة الراديو';
	@override String get description => 'زر راديو على شكل بطاقة.';
	@override late final _TranslationsDocsComponentsRadioCardExamplesAr examples = _TranslationsDocsComponentsRadioCardExamplesAr._(_root);
}

// Path: docs.components.radio_group
class _TranslationsDocsComponentsRadioGroupAr extends TranslationsDocsComponentsRadioGroupKo {
	_TranslationsDocsComponentsRadioGroupAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'مجموعة الراديو';
	@override String get description => 'مجموعة أزرار الراديو.';
	@override late final _TranslationsDocsComponentsRadioGroupExamplesAr examples = _TranslationsDocsComponentsRadioGroupExamplesAr._(_root);
	@override String get option_1 => 'الخيار 1';
	@override String get option_2 => 'الخيار 2';
	@override String get option_3 => 'الخيار 3';
	@override String get selected => 'محدد';
}

// Path: docs.components.refresh_trigger
class _TranslationsDocsComponentsRefreshTriggerAr extends TranslationsDocsComponentsRefreshTriggerKo {
	_TranslationsDocsComponentsRefreshTriggerAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'م-trigger التحديث';
	@override String get description => 'يوفر ميزة سحب للتحديث.';
	@override late final _TranslationsDocsComponentsRefreshTriggerExamplesAr examples = _TranslationsDocsComponentsRefreshTriggerExamplesAr._(_root);
	@override String get pull_me => 'اسحبني';
	@override String get refresh => 'تحديث';
}

// Path: docs.components.repeated_animation_builder
class _TranslationsDocsComponentsRepeatedAnimationBuilderAr extends TranslationsDocsComponentsRepeatedAnimationBuilderKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'منشئ الرسوم المتحركة المتكررة';
	@override String get description => 'منشئ يقوم بتكرار الرسوم المتحركة.';
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesAr examples = _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesAr._(_root);
}

// Path: docs.components.resizable
class _TranslationsDocsComponentsResizableAr extends TranslationsDocsComponentsResizableKo {
	_TranslationsDocsComponentsResizableAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'قابل لتغيير الحجم';
	@override String get description => 'حاوية يمكن تغيير حجمها.';
	@override late final _TranslationsDocsComponentsResizableExamplesAr examples = _TranslationsDocsComponentsResizableExamplesAr._(_root);
}

// Path: docs.components.scaffold
class _TranslationsDocsComponentsScaffoldAr extends TranslationsDocsComponentsScaffoldKo {
	_TranslationsDocsComponentsScaffoldAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'هيكل';
	@override String get description => 'الهيكل هو الحاوية العليا للصفحة.';
	@override late final _TranslationsDocsComponentsScaffoldExamplesAr examples = _TranslationsDocsComponentsScaffoldExamplesAr._(_root);
}

// Path: docs.components.select
class _TranslationsDocsComponentsSelectAr extends TranslationsDocsComponentsSelectKo {
	_TranslationsDocsComponentsSelectAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'اختيار';
	@override String get description => 'يمكنك اختيار عنصر من قائمة الخيارات.';
	@override late final _TranslationsDocsComponentsSelectExamplesAr examples = _TranslationsDocsComponentsSelectExamplesAr._(_root);
	@override String get placeholder => 'اختر فاكهة';
	@override String get search_fruit => 'ابحث عن فاكهة';
	@override String get no_fruit_found => 'لا يمكن العثور على فاكهة';
	@override String get apple => 'تفاح';
	@override String get banana => 'موز';
	@override String get cherry => 'كرز';
	@override String get lemon => 'ليمون';
	@override String get tomato => 'طماطم';
	@override String get red_apple => 'تفاحة حمراء';
	@override String get green_apple => 'تفاحة خضراء';
	@override String get yellow_banana => 'موز أصفر';
	@override String get brown_banana => 'موز بني';
	@override String get yellow_lemon => 'ليمون أصفر';
	@override String get green_lemon => 'ليمون أخضر';
	@override String get red => 'أحمر';
	@override String get green => 'أخضر';
	@override String get yellow => 'أصفر';
	@override String get brown => 'بني';
}

// Path: docs.components.sheet
class _TranslationsDocsComponentsSheetAr extends TranslationsDocsComponentsSheetKo {
	_TranslationsDocsComponentsSheetAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ورقة';
	@override String get description => 'ورقة تظهر من الأسفل.';
	@override late final _TranslationsDocsComponentsSheetExamplesAr examples = _TranslationsDocsComponentsSheetExamplesAr._(_root);
}

// Path: docs.components.skeleton
class _TranslationsDocsComponentsSkeletonAr extends TranslationsDocsComponentsSkeletonKo {
	_TranslationsDocsComponentsSkeletonAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'هيكل عظمي';
	@override String get description => 'شاشة هيكل عظمي تعرض أثناء التحميل.';
	@override late final _TranslationsDocsComponentsSkeletonExamplesAr examples = _TranslationsDocsComponentsSkeletonExamplesAr._(_root);
}

// Path: docs.components.slider
class _TranslationsDocsComponentsSliderAr extends TranslationsDocsComponentsSliderKo {
	_TranslationsDocsComponentsSliderAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'شريط التمرير';
	@override String get description => 'يمكنك اختيار قيمة عن طريق التمرير.';
	@override late final _TranslationsDocsComponentsSliderExamplesAr examples = _TranslationsDocsComponentsSliderExamplesAr._(_root);
	@override String value_single({required Object value}) => 'القيمة: ${value}';
	@override String value_range({required Object start, required Object end}) => 'القيمة: ${start} - ${end}';
}

// Path: docs.components.sortable
class _TranslationsDocsComponentsSortableAr extends TranslationsDocsComponentsSortableKo {
	_TranslationsDocsComponentsSortableAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'قابل للفرز';
	@override String get description => 'يمكنك سحب العناصر لإعادة ترتيبها.';
	@override late final _TranslationsDocsComponentsSortableExamplesAr examples = _TranslationsDocsComponentsSortableExamplesAr._(_root);
}

// Path: docs.components.star_rating
class _TranslationsDocsComponentsStarRatingAr extends TranslationsDocsComponentsStarRatingKo {
	_TranslationsDocsComponentsStarRatingAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'تقييم بالنجوم';
	@override String get description => 'يمكنك اختيار تقييم بالنجوم.';
	@override late final _TranslationsDocsComponentsStarRatingExamplesAr examples = _TranslationsDocsComponentsStarRatingExamplesAr._(_root);
}

// Path: docs.components.stepper
class _TranslationsDocsComponentsStepperAr extends TranslationsDocsComponentsStepperKo {
	_TranslationsDocsComponentsStepperAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'عداد الخطوات';
	@override String get description => 'يظهر عملية خطوة بخطوة.';
	@override late final _TranslationsDocsComponentsStepperExamplesAr examples = _TranslationsDocsComponentsStepperExamplesAr._(_root);
	@override String get step_1 => 'الخطوة 1';
	@override String get step_2 => 'الخطوة 2';
	@override String get step_3 => 'الخطوة 3';
	@override String step_n({required Object n}) => 'الخطوة ${n}';
	@override String get optional_step => 'خطوة اختيارية';
	@override String get horizontal => 'أفقي';
	@override String get vertical => 'عمودي';
	@override String get toggle_error => 'تبديل الخطأ';
	@override String get circle => 'دائرة';
	@override String get circle_alt => 'دائرة بديلة';
	@override String get line => 'خط';
	@override String get small => 'صغير';
	@override String get medium => 'متوسط';
	@override String get large => 'كبير';
}

// Path: docs.components.steps
class _TranslationsDocsComponentsStepsAr extends TranslationsDocsComponentsStepsKo {
	_TranslationsDocsComponentsStepsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'الخطوات';
	@override String get description => 'تظهر تقدم العملية على شكل خطوات.';
	@override late final _TranslationsDocsComponentsStepsExamplesAr examples = _TranslationsDocsComponentsStepsExamplesAr._(_root);
}

// Path: docs.components.swiper
class _TranslationsDocsComponentsSwiperAr extends TranslationsDocsComponentsSwiperKo {
	_TranslationsDocsComponentsSwiperAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'سوايبر';
	@override String get description => 'مكون يمكن سحبه.';
	@override late final _TranslationsDocsComponentsSwiperExamplesAr examples = _TranslationsDocsComponentsSwiperExamplesAr._(_root);
}

// Path: docs.components.k_switch
class _TranslationsDocsComponentsKSwitchAr extends TranslationsDocsComponentsKSwitchKo {
	_TranslationsDocsComponentsKSwitchAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'زر التبديل';
	@override String get description => 'زر للتشغيل/الإيقاف.';
	@override late final _TranslationsDocsComponentsKSwitchExamplesAr examples = _TranslationsDocsComponentsKSwitchExamplesAr._(_root);
}

// Path: docs.components.switcher
class _TranslationsDocsComponentsSwitcherAr extends TranslationsDocsComponentsSwitcherKo {
	_TranslationsDocsComponentsSwitcherAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'مفتاح التغيير';
	@override String get description => 'يمكنك التبديل بين عدة مكونات.';
	@override late final _TranslationsDocsComponentsSwitcherExamplesAr examples = _TranslationsDocsComponentsSwitcherExamplesAr._(_root);
	@override String get switch_direction => 'تغيير الاتجاه';
	@override String get next_item => 'العنصر التالي';
}

// Path: docs.components.tab_list
class _TranslationsDocsComponentsTabListAr extends TranslationsDocsComponentsTabListKo {
	_TranslationsDocsComponentsTabListAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'قائمة التبويب';
	@override String get description => 'مكون قائمة التبويب.';
	@override late final _TranslationsDocsComponentsTabListExamplesAr examples = _TranslationsDocsComponentsTabListExamplesAr._(_root);
}

// Path: docs.components.tab_pane
class _TranslationsDocsComponentsTabPaneAr extends TranslationsDocsComponentsTabPaneKo {
	_TranslationsDocsComponentsTabPaneAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'لوحة التبويب';
	@override String get description => 'مكون لوحة تبويب.';
	@override late final _TranslationsDocsComponentsTabPaneExamplesAr examples = _TranslationsDocsComponentsTabPaneExamplesAr._(_root);
}

// Path: docs.components.table
class _TranslationsDocsComponentsTableAr extends TranslationsDocsComponentsTableKo {
	_TranslationsDocsComponentsTableAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'جدول';
	@override String get description => 'يعرض البيانات في شكل جدول.';
	@override late final _TranslationsDocsComponentsTableExamplesAr examples = _TranslationsDocsComponentsTableExamplesAr._(_root);
	@override String get invoice => 'فاتورة';
	@override String get status => 'الحالة';
	@override String get method => 'الطريقة';
	@override String get amount => 'المبلغ';
	@override String get total => 'المجموع';
	@override String get paid => 'مدفوع';
	@override String get pending => 'قيد الانتظار';
	@override String get unpaid => 'غير مدفوع';
	@override String get credit_card => 'بطاقة ائتمان';
	@override String get paypal => 'باي بال';
	@override String get bank_transfer => 'تحويل مصرفي';
}

// Path: docs.components.tabs
class _TranslationsDocsComponentsTabsAr extends TranslationsDocsComponentsTabsKo {
	_TranslationsDocsComponentsTabsAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'تبويبات';
	@override String get description => 'استخدام التبويب لتنظيم المحتوى.';
	@override late final _TranslationsDocsComponentsTabsExamplesAr examples = _TranslationsDocsComponentsTabsExamplesAr._(_root);
	@override String get tab_1 => 'التبويب 1';
	@override String get tab_2 => 'التبويب 2';
	@override String get tab_3 => 'التبويب 3';
	@override String tab_n({required Object n}) => 'التبويب ${n}';
}

// Path: docs.components.text_area
class _TranslationsDocsComponentsTextAreaAr extends TranslationsDocsComponentsTextAreaKo {
	_TranslationsDocsComponentsTextAreaAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'منطقة النص';
	@override String get description => 'يمكنك إدخال نص في عدة أسطر.';
	@override late final _TranslationsDocsComponentsTextAreaExamplesAr examples = _TranslationsDocsComponentsTextAreaExamplesAr._(_root);
	@override String get hello_world => 'مرحبا بالعالم!';
}

// Path: docs.components.time_picker
class _TranslationsDocsComponentsTimePickerAr extends TranslationsDocsComponentsTimePickerKo {
	_TranslationsDocsComponentsTimePickerAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'اختيار الوقت';
	@override String get description => 'يمكنك اختيار الوقت.';
	@override late final _TranslationsDocsComponentsTimePickerExamplesAr examples = _TranslationsDocsComponentsTimePickerExamplesAr._(_root);
	@override String get select_time => 'اختر الوقت';
}

// Path: docs.components.timeline
class _TranslationsDocsComponentsTimelineAr extends TranslationsDocsComponentsTimelineKo {
	_TranslationsDocsComponentsTimelineAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'الخط الزمني';
	@override String get description => 'يعرض الأحداث على شكل خط زمني.';
	@override late final _TranslationsDocsComponentsTimelineExamplesAr examples = _TranslationsDocsComponentsTimelineExamplesAr._(_root);
}

// Path: docs.components.timeline_animation
class _TranslationsDocsComponentsTimelineAnimationAr extends TranslationsDocsComponentsTimelineAnimationKo {
	_TranslationsDocsComponentsTimelineAnimationAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'رسوم متحركة للخط الزمني';
	@override String get description => 'رسوم متحركة تعتمد على الخط الزمني.';
	@override late final _TranslationsDocsComponentsTimelineAnimationExamplesAr examples = _TranslationsDocsComponentsTimelineAnimationExamplesAr._(_root);
}

// Path: docs.components.toast
class _TranslationsDocsComponentsToastAr extends TranslationsDocsComponentsToastKo {
	_TranslationsDocsComponentsToastAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'توست';
	@override String get description => 'تنبيه يعرض رسالة قصيرة.';
	@override late final _TranslationsDocsComponentsToastExamplesAr examples = _TranslationsDocsComponentsToastExamplesAr._(_root);
	@override String get event_created => 'تم إنشاء الحدث';
	@override String get event_date => 'الأحد، 7 يوليو 2024، الساعة 12:00 مساءً';
	@override String get show_bottom_left => 'عرض توست في الزاوية السفلى اليسرى';
	@override String get show_bottom_right => 'عرض توست في الزاوية السفلى اليمنى';
	@override String get show_top_left => 'عرض توست في الزاوية العليا اليسرى';
	@override String get show_top_right => 'عرض توست في الزاوية العليا اليمنى';
	@override String get show_bottom_center => 'عرض توست في المركز الأسفل';
	@override String get show_top_center => 'عرض توست في المركز الأعلى';
}

// Path: docs.components.toggle
class _TranslationsDocsComponentsToggleAr extends TranslationsDocsComponentsToggleKo {
	_TranslationsDocsComponentsToggleAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'تبديل';
	@override String get description => 'يمكنك التبديل بين الخيارات.';
	@override late final _TranslationsDocsComponentsToggleExamplesAr examples = _TranslationsDocsComponentsToggleExamplesAr._(_root);
	@override String get toggle => 'تبديل';
}

// Path: docs.components.tooltip
class _TranslationsDocsComponentsTooltipAr extends TranslationsDocsComponentsTooltipKo {
	_TranslationsDocsComponentsTooltipAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'تلميح';
	@override String get description => 'يعرض معلومات إضافية حول العنصر.';
	@override late final _TranslationsDocsComponentsTooltipExamplesAr examples = _TranslationsDocsComponentsTooltipExamplesAr._(_root);
	@override String get this_is_tooltip => 'هذا هو التلميح.';
	@override String get hover_over_me => 'مرر فوقي';
}

// Path: docs.components.tracker
class _TranslationsDocsComponentsTrackerAr extends TranslationsDocsComponentsTrackerKo {
	_TranslationsDocsComponentsTrackerAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'متعقب';
	@override String get description => 'يتعقب التقدم.';
	@override late final _TranslationsDocsComponentsTrackerExamplesAr examples = _TranslationsDocsComponentsTrackerExamplesAr._(_root);
	@override String get fine => 'جيد';
	@override String get warning => 'تحذير';
	@override String get critical => 'حرج';
	@override String get unknown => 'غير معروف';
	@override String get tracker_fine => 'متعقب جيد';
	@override String get tracker_warning => 'متعقب تحذير';
	@override String get tracker_critical => 'متعقب حرج';
	@override String get tracker_unknown => 'متعقب غير معروف';
}

// Path: docs.components.tree
class _TranslationsDocsComponentsTreeAr extends TranslationsDocsComponentsTreeKo {
	_TranslationsDocsComponentsTreeAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'الشجرة';
	@override String get description => 'يعرض البيانات الهيكلية في شكل شجرة.';
	@override late final _TranslationsDocsComponentsTreeExamplesAr examples = _TranslationsDocsComponentsTreeExamplesAr._(_root);
}

// Path: docs.components.window
class _TranslationsDocsComponentsWindowAr extends TranslationsDocsComponentsWindowKo {
	_TranslationsDocsComponentsWindowAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'نافذة';
	@override String get description => 'نافذة بأسلوب سطح المكتب.';
	@override late final _TranslationsDocsComponentsWindowExamplesAr examples = _TranslationsDocsComponentsWindowExamplesAr._(_root);
	@override String get window_1 => 'نافذة 1';
	@override String get window_2 => 'نافذة 2';
	@override String get desktop => 'سطح المكتب';
	@override String get add_window => 'إضافة نافذة';
}

// Path: docs.pages.introduction.features_list
class _TranslationsDocsPagesIntroductionFeaturesListAr extends TranslationsDocsPagesIntroductionFeaturesListKo {
	_TranslationsDocsPagesIntroductionFeaturesListAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get components_count => '84 مكونًا وما زال العدد في تزايد!';
	@override String get material_cupertino => 'يدعم مكونات Material وCupertino مع تعديلات تتوافق مع ثيمة coui_flutter الحالية.';
	@override String get premade_themes => 'ثيمات مسبقة الصنع من Coui/UI.';
	@override String get platform_support => 'دعم للأنظمة الأساسية للهاتف المحمول والويب وسطح المكتب.';
	@override String get middle_drag => 'دعم سحب منتصف الشاشة.';
	@override String get typography_extensions => 'توسعات متنوعة للخطوط.';
	@override String get webassembly => 'دعم WebAssembly لأداء أفضل.';
}

// Path: docs.components.accordion.examples
class _TranslationsDocsComponentsAccordionExamplesAr extends TranslationsDocsComponentsAccordionExamplesKo {
	_TranslationsDocsComponentsAccordionExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال أكورديون';
}

// Path: docs.components.alert.examples
class _TranslationsDocsComponentsAlertExamplesAr extends TranslationsDocsComponentsAlertExamplesKo {
	_TranslationsDocsComponentsAlertExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال تنبيه';
	@override String get destructive => 'مثال تنبيه خطر';
}

// Path: docs.components.alert_dialog.examples
class _TranslationsDocsComponentsAlertDialogExamplesAr extends TranslationsDocsComponentsAlertDialogExamplesKo {
	_TranslationsDocsComponentsAlertDialogExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال حوار التنبيه';
}

// Path: docs.components.animated_value_builder.examples
class _TranslationsDocsComponentsAnimatedValueBuilderExamplesAr extends TranslationsDocsComponentsAnimatedValueBuilderExamplesKo {
	_TranslationsDocsComponentsAnimatedValueBuilderExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال منشئ القيمة المتحركة';
}

// Path: docs.components.app_bar.examples
class _TranslationsDocsComponentsAppBarExamplesAr extends TranslationsDocsComponentsAppBarExamplesKo {
	_TranslationsDocsComponentsAppBarExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال شريط التطبيق';
}

// Path: docs.components.autocomplete.examples
class _TranslationsDocsComponentsAutocompleteExamplesAr extends TranslationsDocsComponentsAutocompleteExamplesKo {
	_TranslationsDocsComponentsAutocompleteExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال الإكمال التلقائي';
}

// Path: docs.components.avatar.examples
class _TranslationsDocsComponentsAvatarExamplesAr extends TranslationsDocsComponentsAvatarExamplesKo {
	_TranslationsDocsComponentsAvatarExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال الصورة الرمزية';
}

// Path: docs.components.avatar_group.examples
class _TranslationsDocsComponentsAvatarGroupExamplesAr extends TranslationsDocsComponentsAvatarGroupExamplesKo {
	_TranslationsDocsComponentsAvatarGroupExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال مجموعة الصور الرمزية';
}

// Path: docs.components.badge.examples
class _TranslationsDocsComponentsBadgeExamplesAr extends TranslationsDocsComponentsBadgeExamplesKo {
	_TranslationsDocsComponentsBadgeExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال شارة';
}

// Path: docs.components.breadcrumb.examples
class _TranslationsDocsComponentsBreadcrumbExamplesAr extends TranslationsDocsComponentsBreadcrumbExamplesKo {
	_TranslationsDocsComponentsBreadcrumbExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال فتات الخبز';
}

// Path: docs.components.button.examples
class _TranslationsDocsComponentsButtonExamplesAr extends TranslationsDocsComponentsButtonExamplesKo {
	_TranslationsDocsComponentsButtonExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get primary => 'مثال زر أساسي';
	@override String get secondary => 'مثال زر ثانوي';
	@override String get outline => 'مثال زر بخط خارجي';
	@override String get ghost => 'مثال زر شبح';
	@override String get destructive => 'مثال زر خطر';
	@override String get link => 'مثال زر رابط';
	@override String get text => 'مثال زر نص';
	@override String get disabled => 'مثال زر معطل';
	@override String get icon => 'مثال زر أيقونة';
	@override String get icon_with_label => 'مثال زر أيقونة مع تسمية';
	@override String get size => 'مثال حجم الزر';
	@override String get density => 'مثال كثافة الزر';
	@override String get shape => 'مثال شكل الزر';
	@override String get group => 'مثال مجموعة الأزرار';
	@override String get stated => 'مثال زر بالحالة';
	@override String get card => 'مثال زر بطاقة';
	@override String get custom => 'مثال زر مخصص';
}

// Path: docs.components.calendar.examples
class _TranslationsDocsComponentsCalendarExamplesAr extends TranslationsDocsComponentsCalendarExamplesKo {
	_TranslationsDocsComponentsCalendarExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال التقويم';
}

// Path: docs.components.card.examples
class _TranslationsDocsComponentsCardExamplesAr extends TranslationsDocsComponentsCardExamplesKo {
	_TranslationsDocsComponentsCardExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال بطاقة';
}

// Path: docs.components.card_image.examples
class _TranslationsDocsComponentsCardImageExamplesAr extends TranslationsDocsComponentsCardImageExamplesKo {
	_TranslationsDocsComponentsCardImageExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال بطاقة الصورة';
}

// Path: docs.components.carousel.examples
class _TranslationsDocsComponentsCarouselExamplesAr extends TranslationsDocsComponentsCarouselExamplesKo {
	_TranslationsDocsComponentsCarouselExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال دوار';
}

// Path: docs.components.checkbox.examples
class _TranslationsDocsComponentsCheckboxExamplesAr extends TranslationsDocsComponentsCheckboxExamplesKo {
	_TranslationsDocsComponentsCheckboxExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال مربع اختيار';
}

// Path: docs.components.chip.examples
class _TranslationsDocsComponentsChipExamplesAr extends TranslationsDocsComponentsChipExamplesKo {
	_TranslationsDocsComponentsChipExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال شريحة';
}

// Path: docs.components.chip_input.examples
class _TranslationsDocsComponentsChipInputExamplesAr extends TranslationsDocsComponentsChipInputExamplesKo {
	_TranslationsDocsComponentsChipInputExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال إدخال الشريحة';
}

// Path: docs.components.circular_progress.examples
class _TranslationsDocsComponentsCircularProgressExamplesAr extends TranslationsDocsComponentsCircularProgressExamplesKo {
	_TranslationsDocsComponentsCircularProgressExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال تقدم دائري';
}

// Path: docs.components.code_snippet.examples
class _TranslationsDocsComponentsCodeSnippetExamplesAr extends TranslationsDocsComponentsCodeSnippetExamplesKo {
	_TranslationsDocsComponentsCodeSnippetExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال قصاصة الشيفرة';
}

// Path: docs.components.collapsible.examples
class _TranslationsDocsComponentsCollapsibleExamplesAr extends TranslationsDocsComponentsCollapsibleExamplesKo {
	_TranslationsDocsComponentsCollapsibleExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال قابل للطي';
}

// Path: docs.components.color_picker.examples
class _TranslationsDocsComponentsColorPickerExamplesAr extends TranslationsDocsComponentsColorPickerExamplesKo {
	_TranslationsDocsComponentsColorPickerExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال اختيار اللون';
}

// Path: docs.components.command.examples
class _TranslationsDocsComponentsCommandExamplesAr extends TranslationsDocsComponentsCommandExamplesKo {
	_TranslationsDocsComponentsCommandExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال الأمر';
}

// Path: docs.components.context_menu.examples
class _TranslationsDocsComponentsContextMenuExamplesAr extends TranslationsDocsComponentsContextMenuExamplesKo {
	_TranslationsDocsComponentsContextMenuExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال قائمة السياق';
}

// Path: docs.components.date_picker.examples
class _TranslationsDocsComponentsDatePickerExamplesAr extends TranslationsDocsComponentsDatePickerExamplesKo {
	_TranslationsDocsComponentsDatePickerExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال اختيار التاريخ';
}

// Path: docs.components.dialog.examples
class _TranslationsDocsComponentsDialogExamplesAr extends TranslationsDocsComponentsDialogExamplesKo {
	_TranslationsDocsComponentsDialogExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال حوار';
}

// Path: docs.components.divider.examples
class _TranslationsDocsComponentsDividerExamplesAr extends TranslationsDocsComponentsDividerExamplesKo {
	_TranslationsDocsComponentsDividerExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال فاصل';
}

// Path: docs.components.dot_indicator.examples
class _TranslationsDocsComponentsDotIndicatorExamplesAr extends TranslationsDocsComponentsDotIndicatorExamplesKo {
	_TranslationsDocsComponentsDotIndicatorExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال مؤشر النقاط';
}

// Path: docs.components.drawer.examples
class _TranslationsDocsComponentsDrawerExamplesAr extends TranslationsDocsComponentsDrawerExamplesKo {
	_TranslationsDocsComponentsDrawerExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال درج';
}

// Path: docs.components.dropdown_menu.examples
class _TranslationsDocsComponentsDropdownMenuExamplesAr extends TranslationsDocsComponentsDropdownMenuExamplesKo {
	_TranslationsDocsComponentsDropdownMenuExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال قائمة منسدلة';
}

// Path: docs.components.expandable_sidebar.examples
class _TranslationsDocsComponentsExpandableSidebarExamplesAr extends TranslationsDocsComponentsExpandableSidebarExamplesKo {
	_TranslationsDocsComponentsExpandableSidebarExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال شريط جانبي قابل للتوسيع';
}

// Path: docs.components.form.examples
class _TranslationsDocsComponentsFormExamplesAr extends TranslationsDocsComponentsFormExamplesKo {
	_TranslationsDocsComponentsFormExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get table_layout => 'مثال النموذج (تخطيط جدول)';
	@override String get column_layout => 'مثال النموذج (تخطيط عمود)';
	@override String get validation_mode => 'مثال وضع التحقق من الصحة';
}

// Path: docs.components.formatted_input.examples
class _TranslationsDocsComponentsFormattedInputExamplesAr extends TranslationsDocsComponentsFormattedInputExamplesKo {
	_TranslationsDocsComponentsFormattedInputExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال إدخال منسق';
}

// Path: docs.components.hover_card.examples
class _TranslationsDocsComponentsHoverCardExamplesAr extends TranslationsDocsComponentsHoverCardExamplesKo {
	_TranslationsDocsComponentsHoverCardExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال بطاقة هوفر';
}

// Path: docs.components.input.examples
class _TranslationsDocsComponentsInputExamplesAr extends TranslationsDocsComponentsInputExamplesKo {
	_TranslationsDocsComponentsInputExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال إدخال';
}

// Path: docs.components.input_otp.examples
class _TranslationsDocsComponentsInputOtpExamplesAr extends TranslationsDocsComponentsInputOtpExamplesKo {
	_TranslationsDocsComponentsInputOtpExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال إدخال OTP';
}

// Path: docs.components.item_picker.examples
class _TranslationsDocsComponentsItemPickerExamplesAr extends TranslationsDocsComponentsItemPickerExamplesKo {
	_TranslationsDocsComponentsItemPickerExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال اختيار عنصر';
}

// Path: docs.components.keyboard_display.examples
class _TranslationsDocsComponentsKeyboardDisplayExamplesAr extends TranslationsDocsComponentsKeyboardDisplayExamplesKo {
	_TranslationsDocsComponentsKeyboardDisplayExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال عرض لوحة المفاتيح';
}

// Path: docs.components.linear_progress.examples
class _TranslationsDocsComponentsLinearProgressExamplesAr extends TranslationsDocsComponentsLinearProgressExamplesKo {
	_TranslationsDocsComponentsLinearProgressExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال تقدم خطي';
}

// Path: docs.components.material.examples
class _TranslationsDocsComponentsMaterialExamplesAr extends TranslationsDocsComponentsMaterialExamplesKo {
	_TranslationsDocsComponentsMaterialExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال Material/Cupertino';
}

// Path: docs.components.menubar.examples
class _TranslationsDocsComponentsMenubarExamplesAr extends TranslationsDocsComponentsMenubarExamplesKo {
	_TranslationsDocsComponentsMenubarExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال شريط القوائم';
}

// Path: docs.components.multiselect.examples
class _TranslationsDocsComponentsMultiselectExamplesAr extends TranslationsDocsComponentsMultiselectExamplesKo {
	_TranslationsDocsComponentsMultiselectExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال تحديد متعدد';
}

// Path: docs.components.navigation_bar.examples
class _TranslationsDocsComponentsNavigationBarExamplesAr extends TranslationsDocsComponentsNavigationBarExamplesKo {
	_TranslationsDocsComponentsNavigationBarExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال شريط الملاحة';
}

// Path: docs.components.navigation_menu.examples
class _TranslationsDocsComponentsNavigationMenuExamplesAr extends TranslationsDocsComponentsNavigationMenuExamplesKo {
	_TranslationsDocsComponentsNavigationMenuExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال قائمة الملاحة';
}

// Path: docs.components.navigation_rail.examples
class _TranslationsDocsComponentsNavigationRailExamplesAr extends TranslationsDocsComponentsNavigationRailExamplesKo {
	_TranslationsDocsComponentsNavigationRailExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال سكة الملاحة';
}

// Path: docs.components.navigation_sidebar.examples
class _TranslationsDocsComponentsNavigationSidebarExamplesAr extends TranslationsDocsComponentsNavigationSidebarExamplesKo {
	_TranslationsDocsComponentsNavigationSidebarExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال شريط جانبي للملاحة';
}

// Path: docs.components.number_input.examples
class _TranslationsDocsComponentsNumberInputExamplesAr extends TranslationsDocsComponentsNumberInputExamplesKo {
	_TranslationsDocsComponentsNumberInputExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال إدخال رقم';
}

// Path: docs.components.number_ticker.examples
class _TranslationsDocsComponentsNumberTickerExamplesAr extends TranslationsDocsComponentsNumberTickerExamplesKo {
	_TranslationsDocsComponentsNumberTickerExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال عداد الأرقام';
}

// Path: docs.components.overflow_marquee.examples
class _TranslationsDocsComponentsOverflowMarqueeExamplesAr extends TranslationsDocsComponentsOverflowMarqueeExamplesKo {
	_TranslationsDocsComponentsOverflowMarqueeExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال ماركي مفرط';
}

// Path: docs.components.pagination.examples
class _TranslationsDocsComponentsPaginationExamplesAr extends TranslationsDocsComponentsPaginationExamplesKo {
	_TranslationsDocsComponentsPaginationExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال التصفح';
}

// Path: docs.components.phone_input.examples
class _TranslationsDocsComponentsPhoneInputExamplesAr extends TranslationsDocsComponentsPhoneInputExamplesKo {
	_TranslationsDocsComponentsPhoneInputExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال إدخال رقم الهاتف';
}

// Path: docs.components.popover.examples
class _TranslationsDocsComponentsPopoverExamplesAr extends TranslationsDocsComponentsPopoverExamplesKo {
	_TranslationsDocsComponentsPopoverExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال نافذة منبثقة';
}

// Path: docs.components.progress.examples
class _TranslationsDocsComponentsProgressExamplesAr extends TranslationsDocsComponentsProgressExamplesKo {
	_TranslationsDocsComponentsProgressExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال التقدم';
}

// Path: docs.components.radio_card.examples
class _TranslationsDocsComponentsRadioCardExamplesAr extends TranslationsDocsComponentsRadioCardExamplesKo {
	_TranslationsDocsComponentsRadioCardExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال بطاقة الراديو';
}

// Path: docs.components.radio_group.examples
class _TranslationsDocsComponentsRadioGroupExamplesAr extends TranslationsDocsComponentsRadioGroupExamplesKo {
	_TranslationsDocsComponentsRadioGroupExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال مجموعة الراديو';
}

// Path: docs.components.refresh_trigger.examples
class _TranslationsDocsComponentsRefreshTriggerExamplesAr extends TranslationsDocsComponentsRefreshTriggerExamplesKo {
	_TranslationsDocsComponentsRefreshTriggerExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال م-trigger التحديث';
}

// Path: docs.components.repeated_animation_builder.examples
class _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesAr extends TranslationsDocsComponentsRepeatedAnimationBuilderExamplesKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال منشئ الرسوم المتحركة المتكررة';
}

// Path: docs.components.resizable.examples
class _TranslationsDocsComponentsResizableExamplesAr extends TranslationsDocsComponentsResizableExamplesKo {
	_TranslationsDocsComponentsResizableExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال قابل لتغيير الحجم';
}

// Path: docs.components.scaffold.examples
class _TranslationsDocsComponentsScaffoldExamplesAr extends TranslationsDocsComponentsScaffoldExamplesKo {
	_TranslationsDocsComponentsScaffoldExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال هيكل';
}

// Path: docs.components.select.examples
class _TranslationsDocsComponentsSelectExamplesAr extends TranslationsDocsComponentsSelectExamplesKo {
	_TranslationsDocsComponentsSelectExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال اختيار';
}

// Path: docs.components.sheet.examples
class _TranslationsDocsComponentsSheetExamplesAr extends TranslationsDocsComponentsSheetExamplesKo {
	_TranslationsDocsComponentsSheetExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال ورقة';
}

// Path: docs.components.skeleton.examples
class _TranslationsDocsComponentsSkeletonExamplesAr extends TranslationsDocsComponentsSkeletonExamplesKo {
	_TranslationsDocsComponentsSkeletonExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال هيكل عظمي';
}

// Path: docs.components.slider.examples
class _TranslationsDocsComponentsSliderExamplesAr extends TranslationsDocsComponentsSliderExamplesKo {
	_TranslationsDocsComponentsSliderExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال شريط التمرير';
}

// Path: docs.components.sortable.examples
class _TranslationsDocsComponentsSortableExamplesAr extends TranslationsDocsComponentsSortableExamplesKo {
	_TranslationsDocsComponentsSortableExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال قابل للفرز';
}

// Path: docs.components.star_rating.examples
class _TranslationsDocsComponentsStarRatingExamplesAr extends TranslationsDocsComponentsStarRatingExamplesKo {
	_TranslationsDocsComponentsStarRatingExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال تقييم بالنجوم';
}

// Path: docs.components.stepper.examples
class _TranslationsDocsComponentsStepperExamplesAr extends TranslationsDocsComponentsStepperExamplesKo {
	_TranslationsDocsComponentsStepperExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال عداد الخطوات';
}

// Path: docs.components.steps.examples
class _TranslationsDocsComponentsStepsExamplesAr extends TranslationsDocsComponentsStepsExamplesKo {
	_TranslationsDocsComponentsStepsExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال خطوات';
}

// Path: docs.components.swiper.examples
class _TranslationsDocsComponentsSwiperExamplesAr extends TranslationsDocsComponentsSwiperExamplesKo {
	_TranslationsDocsComponentsSwiperExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال سوايبر';
}

// Path: docs.components.k_switch.examples
class _TranslationsDocsComponentsKSwitchExamplesAr extends TranslationsDocsComponentsKSwitchExamplesKo {
	_TranslationsDocsComponentsKSwitchExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال زر التبديل';
}

// Path: docs.components.switcher.examples
class _TranslationsDocsComponentsSwitcherExamplesAr extends TranslationsDocsComponentsSwitcherExamplesKo {
	_TranslationsDocsComponentsSwitcherExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال مفتاح التغيير';
}

// Path: docs.components.tab_list.examples
class _TranslationsDocsComponentsTabListExamplesAr extends TranslationsDocsComponentsTabListExamplesKo {
	_TranslationsDocsComponentsTabListExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال قائمة التبويب';
}

// Path: docs.components.tab_pane.examples
class _TranslationsDocsComponentsTabPaneExamplesAr extends TranslationsDocsComponentsTabPaneExamplesKo {
	_TranslationsDocsComponentsTabPaneExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال لوحة التبويب';
}

// Path: docs.components.table.examples
class _TranslationsDocsComponentsTableExamplesAr extends TranslationsDocsComponentsTableExamplesKo {
	_TranslationsDocsComponentsTableExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال جدول';
}

// Path: docs.components.tabs.examples
class _TranslationsDocsComponentsTabsExamplesAr extends TranslationsDocsComponentsTabsExamplesKo {
	_TranslationsDocsComponentsTabsExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال تبويبات';
}

// Path: docs.components.text_area.examples
class _TranslationsDocsComponentsTextAreaExamplesAr extends TranslationsDocsComponentsTextAreaExamplesKo {
	_TranslationsDocsComponentsTextAreaExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال منطقة النص';
}

// Path: docs.components.time_picker.examples
class _TranslationsDocsComponentsTimePickerExamplesAr extends TranslationsDocsComponentsTimePickerExamplesKo {
	_TranslationsDocsComponentsTimePickerExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال اختيار الوقت';
}

// Path: docs.components.timeline.examples
class _TranslationsDocsComponentsTimelineExamplesAr extends TranslationsDocsComponentsTimelineExamplesKo {
	_TranslationsDocsComponentsTimelineExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال الخط الزمني';
}

// Path: docs.components.timeline_animation.examples
class _TranslationsDocsComponentsTimelineAnimationExamplesAr extends TranslationsDocsComponentsTimelineAnimationExamplesKo {
	_TranslationsDocsComponentsTimelineAnimationExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال رسوم متحركة للخط الزمني';
}

// Path: docs.components.toast.examples
class _TranslationsDocsComponentsToastExamplesAr extends TranslationsDocsComponentsToastExamplesKo {
	_TranslationsDocsComponentsToastExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال توست';
}

// Path: docs.components.toggle.examples
class _TranslationsDocsComponentsToggleExamplesAr extends TranslationsDocsComponentsToggleExamplesKo {
	_TranslationsDocsComponentsToggleExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال تبديل';
}

// Path: docs.components.tooltip.examples
class _TranslationsDocsComponentsTooltipExamplesAr extends TranslationsDocsComponentsTooltipExamplesKo {
	_TranslationsDocsComponentsTooltipExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال تلميح';
}

// Path: docs.components.tracker.examples
class _TranslationsDocsComponentsTrackerExamplesAr extends TranslationsDocsComponentsTrackerExamplesKo {
	_TranslationsDocsComponentsTrackerExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال متعقب';
}

// Path: docs.components.tree.examples
class _TranslationsDocsComponentsTreeExamplesAr extends TranslationsDocsComponentsTreeExamplesKo {
	_TranslationsDocsComponentsTreeExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال شجرة';
}

// Path: docs.components.window.examples
class _TranslationsDocsComponentsWindowExamplesAr extends TranslationsDocsComponentsWindowExamplesKo {
	_TranslationsDocsComponentsWindowExamplesAr._(TranslationsAr root) : this._root = root, super.internal(root);

	final TranslationsAr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'مثال نافذة';
}
