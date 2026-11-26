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
class TranslationsDe extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsDe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <de>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsDe _root = this; // ignore: unused_field

	@override 
	TranslationsDe $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsDe(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsWidgetbookDe widgetbook = _TranslationsWidgetbookDe._(_root);
	@override late final _TranslationsDocsDe docs = _TranslationsDocsDe._(_root);
}

// Path: widgetbook
class _TranslationsWidgetbookDe extends TranslationsWidgetbookKo {
	_TranslationsWidgetbookDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsWidgetbookCommonDe common = _TranslationsWidgetbookCommonDe._(_root);
	@override late final _TranslationsWidgetbookLoadingDe loading = _TranslationsWidgetbookLoadingDe._(_root);
	@override late final _TranslationsWidgetbookTabsDe tabs = _TranslationsWidgetbookTabsDe._(_root);
	@override late final _TranslationsWidgetbookPaginationDe pagination = _TranslationsWidgetbookPaginationDe._(_root);
	@override late final _TranslationsWidgetbookTooltipDe tooltip = _TranslationsWidgetbookTooltipDe._(_root);
	@override late final _TranslationsWidgetbookRadioDe radio = _TranslationsWidgetbookRadioDe._(_root);
	@override late final _TranslationsWidgetbookCardDe card = _TranslationsWidgetbookCardDe._(_root);
	@override late final _TranslationsWidgetbookAlertDe alert = _TranslationsWidgetbookAlertDe._(_root);
	@override late final _TranslationsWidgetbookAccordionDe accordion = _TranslationsWidgetbookAccordionDe._(_root);
	@override late final _TranslationsWidgetbookSkeletonDe skeleton = _TranslationsWidgetbookSkeletonDe._(_root);
	@override late final _TranslationsWidgetbookToastDe toast = _TranslationsWidgetbookToastDe._(_root);
	@override late final _TranslationsWidgetbookChipDe chip = _TranslationsWidgetbookChipDe._(_root);
	@override late final _TranslationsWidgetbookCheckboxDe checkbox = _TranslationsWidgetbookCheckboxDe._(_root);
	@override late final _TranslationsWidgetbookToggleDe toggle = _TranslationsWidgetbookToggleDe._(_root);
	@override late final _TranslationsWidgetbookDialogDe dialog = _TranslationsWidgetbookDialogDe._(_root);
	@override late final _TranslationsWidgetbookPopoverDe popover = _TranslationsWidgetbookPopoverDe._(_root);
	@override late final _TranslationsWidgetbookTextFieldDe text_field = _TranslationsWidgetbookTextFieldDe._(_root);
	@override late final _TranslationsWidgetbookButtonDe button = _TranslationsWidgetbookButtonDe._(_root);
	@override late final _TranslationsWidgetbookTableDe table = _TranslationsWidgetbookTableDe._(_root);
	@override late final _TranslationsWidgetbookKSwitchDe k_switch = _TranslationsWidgetbookKSwitchDe._(_root);
	@override late final _TranslationsWidgetbookSwitchComponentDe switch_component = _TranslationsWidgetbookSwitchComponentDe._(_root);
	@override late final _TranslationsWidgetbookSelectDe select = _TranslationsWidgetbookSelectDe._(_root);
	@override late final _TranslationsWidgetbookBreadcrumbDe breadcrumb = _TranslationsWidgetbookBreadcrumbDe._(_root);
	@override late final _TranslationsWidgetbookBadgeDe badge = _TranslationsWidgetbookBadgeDe._(_root);
	@override late final _TranslationsWidgetbookThemePreviewDe theme_preview = _TranslationsWidgetbookThemePreviewDe._(_root);
	@override late final _TranslationsWidgetbookChatDe chat = _TranslationsWidgetbookChatDe._(_root);
	@override late final _TranslationsWidgetbookMultipleChoiceDe multiple_choice = _TranslationsWidgetbookMultipleChoiceDe._(_root);
	@override late final _TranslationsWidgetbookFormattedInputDe formatted_input = _TranslationsWidgetbookFormattedInputDe._(_root);
	@override late final _TranslationsWidgetbookSwiperDe swiper = _TranslationsWidgetbookSwiperDe._(_root);
}

// Path: docs
class _TranslationsDocsDe extends TranslationsDocsKo {
	_TranslationsDocsDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsCommonDe common = _TranslationsDocsCommonDe._(_root);
	@override late final _TranslationsDocsBadgesDe badges = _TranslationsDocsBadgesDe._(_root);
	@override late final _TranslationsDocsFlavorsDe flavors = _TranslationsDocsFlavorsDe._(_root);
	@override late final _TranslationsDocsNavigationDe navigation = _TranslationsDocsNavigationDe._(_root);
	@override late final _TranslationsDocsPagesDe pages = _TranslationsDocsPagesDe._(_root);
	@override late final _TranslationsDocsComponentsDe components = _TranslationsDocsComponentsDe._(_root);
}

// Path: widgetbook.common
class _TranslationsWidgetbookCommonDe extends TranslationsWidgetbookCommonKo {
	_TranslationsWidgetbookCommonDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get increment_progress => 'Fortschritt erhöhen';
	@override String selected_tab({required Object index}) => 'Ausgewählte Registerkarte: ${index}';
	@override String current_page({required Object page}) => 'Aktuelle Seite: ${page}';
	@override String total_pages({required Object count}) => 'Gesamtseiten: ${count}';
	@override String page_of({required Object current, required Object total}) => '${current} Seite / ${total}';
	@override String get hover_over_icon => 'Fahren Sie mit der Maus über das Symbol';
	@override String counter({required Object count}) => 'Zähler: ${count}';
	@override String selected_rows({required Object count}) => 'Ausgewählte Zeilen: ${count}';
	@override String value({required Object value}) => 'Wert: ${value}';
	@override String selected_cells({required Object count}) => 'Ausgewählte Zellen: ${count}';
}

// Path: widgetbook.loading
class _TranslationsWidgetbookLoadingDe extends TranslationsWidgetbookLoadingKo {
	_TranslationsWidgetbookLoadingDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get indeterminate => 'Unbestimmtes Laden';
	@override String with_value({required Object percent}) => 'Wert enthalten (${percent}%)';
	@override String get custom_size => 'Benutzerdefinierte Größe';
	@override String get custom_height => 'Benutzerdefinierte Höhe';
	@override String get circular_progress => 'Kreisfortschritt';
	@override String get linear_progress => 'Linearer Fortschritt';
}

// Path: widgetbook.tabs
class _TranslationsWidgetbookTabsDe extends TranslationsWidgetbookTabsKo {
	_TranslationsWidgetbookTabsDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get home => 'Startseite';
	@override String get profile => 'Profil';
	@override String get settings => 'Einstellungen';
	@override String get overview => 'Übersicht';
	@override String get details => 'Details';
	@override String get history => 'Verlauf';
	@override String get overview_content => 'Inhaltsübersicht';
	@override String get details_content => 'Detailsinhalt';
	@override String get history_content => 'Verlaufsinhalt';
	@override String get general_info => 'Allgemeine Informationen zu dem Artikel';
	@override String get specifications => 'Detaillierte Spezifikationen und Eigenschaften';
	@override String get timeline => 'Änderungs- und Aktualisierungstimeline';
}

// Path: widgetbook.pagination
class _TranslationsWidgetbookPaginationDe extends TranslationsWidgetbookPaginationKo {
	_TranslationsWidgetbookPaginationDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get show_skip_to_first => 'Zum ersten überspringen anzeigen';
	@override String get show_skip_to_last => 'Zum letzten überspringen anzeigen';
	@override String get hide_previous_on_first => 'Vorherige auf der ersten Seite ausblenden';
	@override String get hide_next_on_last => 'Nächste auf der letzten Seite ausblenden';
	@override String get max_visible_pages => 'Maximale Anzahl der sichtbaren Seiten';
}

// Path: widgetbook.tooltip
class _TranslationsWidgetbookTooltipDe extends TranslationsWidgetbookTooltipKo {
	_TranslationsWidgetbookTooltipDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get helpful_message => 'Hilfreiche Tooltip-Nachricht';
	@override String get tooltip_above => 'Tooltip oben';
	@override String get tooltip_below => 'Tooltip unten';
	@override String get tooltip_left => 'Tooltip links';
	@override String get tooltip_right => 'Tooltip rechts';
	@override String get top => 'Oben';
	@override String get bottom => 'Unten';
	@override String get left => 'Links';
	@override String get right => 'Rechts';
}

// Path: widgetbook.radio
class _TranslationsWidgetbookRadioDe extends TranslationsWidgetbookRadioKo {
	_TranslationsWidgetbookRadioDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get small => 'Klein';
	@override String get medium => 'Mittel';
	@override String get large => 'Groß';
}

// Path: widgetbook.card
class _TranslationsWidgetbookCardDe extends TranslationsWidgetbookCardKo {
	_TranslationsWidgetbookCardDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get card_content => 'Karteninhalt';
	@override String get gradient_card => 'Verlaufskarte';
	@override String get custom_decoration => 'Karte mit benutzerdefinierter Dekoration';
}

// Path: widgetbook.alert
class _TranslationsWidgetbookAlertDe extends TranslationsWidgetbookAlertKo {
	_TranslationsWidgetbookAlertDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Benachrichtigungstitel';
	@override String get message => 'Das ist eine Benachrichtigungsnachricht.';
}

// Path: widgetbook.accordion
class _TranslationsWidgetbookAccordionDe extends TranslationsWidgetbookAccordionKo {
	_TranslationsWidgetbookAccordionDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get what_is_coui => 'Was ist CoUI Flutter?';
	@override String get what_is_coui_answer => 'CoUI Flutter ist eine umfassende UI-Komponentenbibliothek, die entwickelt wurde, um moderne und barrierefreie Flutter-Anwendungen mit konsistenten Designmustern zu erstellen.';
	@override String get how_to_install => 'Wie installiere ich?';
	@override String get how_to_install_answer => 'Fügen Sie `coui_flutter` zu den Abhängigkeiten in der `pubspec.yaml` hinzu und führen Sie `flutter pub get` aus, um das Paket zu installieren.';
	@override String get is_customizable => 'Ist es anpassbar?';
	@override String get is_customizable_answer => 'Ja! CoUI Flutter bietet umfassende Unterstützung für Themes, um Farben, Typografie, Abstände usw. über `ThemeData` anzupassen.';
	@override String get getting_started => 'Erste Schritte';
	@override String get getting_started_answer => 'Beginnen Sie mit der Installation des Pakets und dem Import in Ihr Projekt. Weitere Informationen zur Einrichtung finden Sie in der Dokumentation.';
	@override String get features_expanded => 'Funktionen (Basisausführung)';
	@override String get features_answer => 'CoUI Flutter umfasst Schaltflächen, Formulare, Dialoge, Navigationskomponenten und mehr. Alle Komponenten sind unter Berücksichtigung von Barrierefreiheit und Themen gestaltet.';
	@override String get support => 'Unterstützung';
	@override String get support_answer => 'Wenn Sie Fragen oder Unterstützung benötigen, besuchen Sie das GitHub-Repository oder schauen Sie sich die Dokumentation unter docs.coui.dev an.';
}

// Path: widgetbook.skeleton
class _TranslationsWidgetbookSkeletonDe extends TranslationsWidgetbookSkeletonKo {
	_TranslationsWidgetbookSkeletonDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get skeleton_enabled => 'Skeleton aktiviert:';
	@override String get title_text => 'Titel';
	@override String get description_text => 'Langer Beschreibungstext';
	@override String get short_text => 'Kurzer Text';
	@override String get without_skeleton => 'Ohne Skeleton:';
	@override String get with_skeleton => 'Mit Skeleton:';
	@override String get user_name => 'Benutzername';
	@override String get user_email => 'user@example.com';
	@override String get article_title => 'Artikel Titel';
	@override String get posted_date => 'Veröffentlicht am 1. Januar 2024';
	@override String get bio_description => 'Ein Entwickler, der das Alltagsleben aufzeichnet.';
	@override String get show_content => 'Inhalt anzeigen';
	@override String get show_loading => 'Laden anzeigen';
	@override String get article_content => 'Das ist ein Beispiel für den Inhalt eines Artikels. Während des Ladevorgangs wird dies durch ein Skeleton ersetzt.';
}

// Path: widgetbook.toast
class _TranslationsWidgetbookToastDe extends TranslationsWidgetbookToastKo {
	_TranslationsWidgetbookToastDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get success => 'Erfolg';
	@override String get operation_completed => 'Die Operation wurde erfolgreich abgeschlossen';
	@override String get show_toast => 'Toast anzeigen';
	@override String toast_at({required Object location}) => 'Toast bei ${location}';
	@override String get top_left => 'Oben links';
	@override String get top_center => 'Oben in der Mitte';
	@override String get top_right => 'Oben rechts';
	@override String get bottom_left => 'Unten links';
	@override String get bottom_center => 'Unten in der Mitte';
	@override String get bottom_right => 'Unten rechts';
}

// Path: widgetbook.chip
class _TranslationsWidgetbookChipDe extends TranslationsWidgetbookChipKo {
	_TranslationsWidgetbookChipDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get chip => 'Chip';
}

// Path: widgetbook.checkbox
class _TranslationsWidgetbookCheckboxDe extends TranslationsWidgetbookCheckboxKo {
	_TranslationsWidgetbookCheckboxDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get accept_terms => 'Ich stimme den Nutzungsbedingungen zu';
	@override String get tristate => 'Drei Zustände';
}

// Path: widgetbook.toggle
class _TranslationsWidgetbookToggleDe extends TranslationsWidgetbookToggleKo {
	_TranslationsWidgetbookToggleDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get toggle => 'Umschalter';
}

// Path: widgetbook.dialog
class _TranslationsWidgetbookDialogDe extends TranslationsWidgetbookDialogKo {
	_TranslationsWidgetbookDialogDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic_dialog => 'Grundlegender Dialog';
	@override String get basic_title => 'Basis-Dialog';
	@override String get basic_content => 'Ein einfacher Dialog mit Titel und Inhalt.';
	@override String get simple_dialog_content => 'Ein einfacher Dialog mit Titel und Inhalt.';
	@override String get show_basic => 'Basis anzeigen';
	@override String get show_basic_dialog => 'Grundlegenden Dialog anzeigen';
	@override String get confirm_action => 'Aktion bestätigen';
	@override String get confirm_title => 'Bestätigen';
	@override String get confirm_content => 'Möchten Sie wirklich diese Aktion durchführen?';
	@override String get confirm_action_content => 'Möchten Sie diese Aktion wirklich ausführen? Diese Aktion kann nicht rückgängig gemacht werden.';
	@override String get cancel => 'Abbrechen';
	@override String get confirm => 'Bestätigen';
	@override String get show_confirmation => 'Bestätigung anzeigen';
	@override String get show_confirmation_dialog => 'Bestätigungsdialog anzeigen';
	@override String get warning => 'Warnung';
	@override String get warning_title => 'Warnung';
	@override String get warning_content => 'Diese Aktion kann Daten beeinflussen. Bitte gehen Sie vorsichtig vor.';
	@override String get dismiss => 'Schließen';
	@override String get show_warning => 'Warnung anzeigen';
	@override String get show_warning_dialog => 'Warnungsdialog anzeigen';
}

// Path: widgetbook.popover
class _TranslationsWidgetbookPopoverDe extends TranslationsWidgetbookPopoverKo {
	_TranslationsWidgetbookPopoverDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get popover_content => 'Popover-Inhalt';
	@override String get content_title => 'Popover Titel';
	@override String get content_description => 'Popover mit anpassbarem Inhalt.';
	@override String get customizable_content => 'Popover mit anpassbarem Inhalt.';
	@override String get show_popover => 'Popover anzeigen';
	@override String popover_at({required Object position}) => '${position} zu Popover';
	@override String get top => 'Oben';
	@override String get bottom => 'Unten';
	@override String get left => 'Links';
	@override String get right => 'Rechts';
}

// Path: widgetbook.text_field
class _TranslationsWidgetbookTextFieldDe extends TranslationsWidgetbookTextFieldKo {
	_TranslationsWidgetbookTextFieldDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get enter_name => 'Bitte Namen eingeben';
	@override String get type_here => 'Hier eingeben';
}

// Path: widgetbook.button
class _TranslationsWidgetbookButtonDe extends TranslationsWidgetbookButtonKo {
	_TranslationsWidgetbookButtonDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get primary_button => 'Primäre Schaltfläche';
	@override String get secondary_button => 'Sekundäre Schaltfläche';
	@override String get dashed_button => 'Datei hochladen';
	@override String get upload_file => 'Datei hochladen';
}

// Path: widgetbook.table
class _TranslationsWidgetbookTableDe extends TranslationsWidgetbookTableKo {
	_TranslationsWidgetbookTableDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get name => 'Name';
	@override String get email => 'E-Mail';
	@override String get role => 'Rolle';
	@override String get john_doe => 'John Doe';
	@override String get john_email => 'john@example.com';
	@override String get developer => 'Entwickler';
	@override String get jane_smith => 'Jane Smith';
	@override String get jane_email => 'jane@example.com';
	@override String get designer => 'Designer';
	@override String get bob_johnson => 'Bob Johnson';
	@override String get bob_email => 'bob@example.com';
	@override String get manager => 'Manager';
	@override String get select => 'Auswählen';
	@override String get product => 'Produkt';
	@override String get price => 'Preis';
	@override String get stock => 'Bestand';
	@override String get laptop => 'Laptop';
	@override String get mouse => 'Maus';
	@override String get keyboard => 'Tastatur';
}

// Path: widgetbook.k_switch
class _TranslationsWidgetbookKSwitchDe extends TranslationsWidgetbookKSwitchKo {
	_TranslationsWidgetbookKSwitchDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get k_switch => 'Schalter';
}

// Path: widgetbook.switch_component
class _TranslationsWidgetbookSwitchComponentDe extends TranslationsWidgetbookSwitchComponentKo {
	_TranslationsWidgetbookSwitchComponentDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get switch_label => 'Schalterbeschriftung';
}

// Path: widgetbook.select
class _TranslationsWidgetbookSelectDe extends TranslationsWidgetbookSelectKo {
	_TranslationsWidgetbookSelectDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get apple => 'Apfel';
	@override String get banana => 'Banane';
	@override String get cherry => 'Kirsche';
	@override String get date => 'Dattel';
	@override String get choose_size => 'Größe auswählen';
	@override String get small => 'Klein';
	@override String get medium => 'Mittel';
	@override String get large => 'Groß';
	@override String get extra_large => 'Sehr groß';
}

// Path: widgetbook.breadcrumb
class _TranslationsWidgetbookBreadcrumbDe extends TranslationsWidgetbookBreadcrumbKo {
	_TranslationsWidgetbookBreadcrumbDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get home => 'Startseite';
	@override String get products => 'Produkte';
	@override String get electronics => 'Elektronik';
	@override String get smartphones => 'Smartphones';
	@override String get documents => 'Dokumente';
	@override String get projects => 'Projekte';
	@override String get current_folder => 'Aktueller Ordner';
	@override String current_path({required Object path}) => 'Aktueller Pfad: ${path}';
}

// Path: widgetbook.badge
class _TranslationsWidgetbookBadgeDe extends TranslationsWidgetbookBadgeKo {
	_TranslationsWidgetbookBadgeDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get primary => 'Primär';
	@override String get secondary => 'Sekundär';
	@override String get outline => 'Umriss';
	@override String get destructive => 'Zerstörerisch';
	@override String get featured => 'Empfohlen';
	@override String get more => 'Mehr anzeigen';
	@override String get verified => 'Verifiziert';
	@override String get error => 'Fehler';
	@override String get click_me => 'Klicken Sie hier';
	@override String get clickable => 'Klickbar';
}

// Path: widgetbook.theme_preview
class _TranslationsWidgetbookThemePreviewDe extends TranslationsWidgetbookThemePreviewKo {
	_TranslationsWidgetbookThemePreviewDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Themenvorschau';
	@override String get description => 'Umfassende Übersicht über alle Themen-Token und Komponenten-Stile';
	@override String get color_palette => 'Farbenpalette';
	@override String get brand_colors => 'Markenfarben';
	@override String get base_colors => 'Basisfarben';
	@override String get status_colors => 'Statusfarben';
	@override String get buttons => 'Schaltflächen';
	@override String get primary_button => 'Primär';
	@override String get secondary_button => 'Sekundär';
	@override String get outline_button => 'Umrandung';
	@override String get ghost_button => 'Geist';
	@override String get destructive_button => 'Zerstörerisch';
	@override String get disabled_button => 'Deaktiviert';
	@override String get cards => 'Karten';
	@override String get card_title => 'Kartentitel';
	@override String get card_description => 'Dies ist eine Beispielkartenbeschreibung.';
	@override String get surface_card => 'Oberflächenkarte';
	@override String get filled_variant => 'Füllstil mit Hintergrund';
	@override String get form_elements => 'Formularelemente';
	@override String get text_input_placeholder => 'Text eingeben...';
	@override String get checkbox_checked => 'Ausgewählt';
	@override String get checkbox_unchecked => 'Nicht ausgewählt';
	@override String get toggle_on => 'An';
	@override String get toggle_off => 'Aus';
	@override String get alerts => 'Benachrichtigungen';
	@override String get info_alert => 'Info-Benachrichtigung';
	@override String get info_alert_message => 'Dies ist eine Informationsnachricht.';
	@override String get error_alert => 'Fehlerbenachrichtigung';
	@override String get error_alert_message => 'Es ist ein Problem aufgetreten.';
	@override String get badges_chips => 'Abzeichen & Chips';
	@override String get primary_badge => 'Primär';
	@override String get secondary_badge => 'Sekundär';
	@override String get outline_badge => 'Umrandung';
	@override String get destructive_badge => 'Zerstörerisch';
	@override String get chip_example => 'Favorit';
	@override String get typography => 'Typografie';
	@override String get heading_1 => 'Überschrift 1';
	@override String get heading_2 => 'Überschrift 2';
	@override String get heading_3 => 'Überschrift 3';
	@override String get heading_4 => 'Überschrift 4';
	@override String get body_text => 'Normalgewichtiger Fließtext.';
	@override String get small_text => 'Kleiner Text für Beschriftungen.';
	@override String get muted_text => 'Gedämpfter Text für zusätzliche Informationen.';
	@override String get bold_text => 'Fetter Text zur Hervorhebung.';
	@override String get spacing_radius => 'Abstand & Rundungen';
	@override String get border_radius => 'Rahmenrundung';
	@override String get loading_states => 'Ladezustände';
}

// Path: widgetbook.chat
class _TranslationsWidgetbookChatDe extends TranslationsWidgetbookChatKo {
	_TranslationsWidgetbookChatDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get hello => 'Hallo! Wie geht es Ihnen?';
	@override String get doing_great => 'Sehr gut, danke!';
	@override String get nice_weather => 'Schönes Wetter heute!';
	@override String get yes_beautiful => 'Ja, wunderschön!';
	@override String get sender => 'Absender';
	@override String get receiver => 'Empfänger';
}

// Path: widgetbook.multiple_choice
class _TranslationsWidgetbookMultipleChoiceDe extends TranslationsWidgetbookMultipleChoiceKo {
	_TranslationsWidgetbookMultipleChoiceDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get option_a => 'Option A';
	@override String get option_b => 'Option B';
	@override String get option_c => 'Option C';
	@override String get option_d => 'Option D';
	@override String selected_value({required Object value}) => 'Ausgewählt: ${value}';
	@override String selected_values({required Object values}) => 'Ausgewählt: ${values}';
}

// Path: widgetbook.formatted_input
class _TranslationsWidgetbookFormattedInputDe extends TranslationsWidgetbookFormattedInputKo {
	_TranslationsWidgetbookFormattedInputDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get date_format => 'Datumsformat (MM/TT/JJJJ)';
	@override String get time_format => 'Zeitformat (HH:MM)';
	@override String current_value({required Object value}) => 'Aktueller Wert: ${value}';
}

// Path: widgetbook.swiper
class _TranslationsWidgetbookSwiperDe extends TranslationsWidgetbookSwiperKo {
	_TranslationsWidgetbookSwiperDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get swipe_hint => 'Wischen oder tippen zum Öffnen';
	@override String get overlay_content => 'Overlay-Inhalt';
	@override String get close => 'Schließen';
}

// Path: docs.common
class _TranslationsDocsCommonDe extends TranslationsDocsCommonKo {
	_TranslationsDocsCommonDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get app_name => 'coui_flutter';
	@override String get search_documentation => 'Dokumentation durchsuchen...';
	@override String get docs => 'Dokumente';
	@override String get components => 'Komponenten';
	@override String get close => 'Schließen';
	@override String get on_this_page => 'Inhaltsverzeichnis dieser Seite';
	@override String get work_in_progress_title => 'In Entwicklung';
	@override String get work_in_progress_message => 'Diese Seite ist noch in Entwicklung. Bitte später erneut besuchen.';
	@override String get add => 'Hinzufügen';
	@override String get reset => 'Zurücksetzen';
	@override String get prev => 'Vorher';
	@override String get next => 'Nächste';
	@override String get finish => 'Fertig';
	@override String get open => 'Öffnen';
	@override String get disabled => 'Deaktiviert';
	@override String get refresh => 'Aktualisieren';
	@override String get rebuild => 'Wieder aufbauen';
	@override String get change_color => 'Farbe ändern';
}

// Path: docs.badges
class _TranslationsDocsBadgesDe extends TranslationsDocsBadgesKo {
	_TranslationsDocsBadgesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get k_new => 'Neu';
	@override String get updated => 'Aktualisiert';
	@override String get wip => 'In Entwicklung';
	@override String get experimental => 'Experimentell';
}

// Path: docs.flavors
class _TranslationsDocsFlavorsDe extends TranslationsDocsFlavorsKo {
	_TranslationsDocsFlavorsDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get local => 'Lokal';
	@override String get experimental => 'Experimentell';
	@override String get unknown => 'Unbekannt';
}

// Path: docs.navigation
class _TranslationsDocsNavigationDe extends TranslationsDocsNavigationKo {
	_TranslationsDocsNavigationDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get getting_started => 'Erste Schritte';
	@override String get animation => 'Animation';
	@override String get control => 'Steuerung';
	@override String get disclosure => 'Offenlegung';
	@override String get display => 'Anzeige';
	@override String get feedback => 'Feedback';
	@override String get form => 'Formular';
	@override String get layout => 'Layout';
	@override String get navigation => 'Navigation';
	@override String get overlay => 'Overlay';
	@override String get utility => 'Dienstprogramm';
	@override String get my_account => 'Mein Konto';
	@override String get profile => 'Profil';
	@override String get settings => 'Einstellungen';
	@override String get team => 'Team';
	@override String get new_team => 'Neues Team';
	@override String get billing => 'Abrechnung';
	@override String get api => 'API';
	@override String get log_out => 'Abmelden';
	@override String get support => 'Unterstützung';
	@override String get invite_users => 'Benutzer einladen';
	@override String get more => 'Mehr';
	@override String get github => 'GitHub';
	@override String get note => 'Notiz';
	@override String get message => 'Nachricht';
	@override String get keyboard_shortcuts => 'Tastenkombinationen';
}

// Path: docs.pages
class _TranslationsDocsPagesDe extends TranslationsDocsPagesKo {
	_TranslationsDocsPagesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsPagesIntroductionDe introduction = _TranslationsDocsPagesIntroductionDe._(_root);
	@override late final _TranslationsDocsPagesInstallationDe installation = _TranslationsDocsPagesInstallationDe._(_root);
	@override late final _TranslationsDocsPagesThemeDe theme = _TranslationsDocsPagesThemeDe._(_root);
	@override late final _TranslationsDocsPagesTypographyDe typography = _TranslationsDocsPagesTypographyDe._(_root);
	@override late final _TranslationsDocsPagesLayoutDe layout = _TranslationsDocsPagesLayoutDe._(_root);
	@override late final _TranslationsDocsPagesWebPreloaderDe web_preloader = _TranslationsDocsPagesWebPreloaderDe._(_root);
	@override late final _TranslationsDocsPagesComponentsListDe components_list = _TranslationsDocsPagesComponentsListDe._(_root);
	@override late final _TranslationsDocsPagesIconsDe icons = _TranslationsDocsPagesIconsDe._(_root);
	@override late final _TranslationsDocsPagesColorsDe colors = _TranslationsDocsPagesColorsDe._(_root);
	@override late final _TranslationsDocsPagesExternalDe external = _TranslationsDocsPagesExternalDe._(_root);
	@override late final _TranslationsDocsPagesStateDe state = _TranslationsDocsPagesStateDe._(_root);
}

// Path: docs.components
class _TranslationsDocsComponentsDe extends TranslationsDocsComponentsKo {
	_TranslationsDocsComponentsDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsComponentsAccordionDe accordion = _TranslationsDocsComponentsAccordionDe._(_root);
	@override late final _TranslationsDocsComponentsAlertDe alert = _TranslationsDocsComponentsAlertDe._(_root);
	@override late final _TranslationsDocsComponentsAlertDialogDe alert_dialog = _TranslationsDocsComponentsAlertDialogDe._(_root);
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderDe animated_value_builder = _TranslationsDocsComponentsAnimatedValueBuilderDe._(_root);
	@override late final _TranslationsDocsComponentsAppBarDe app_bar = _TranslationsDocsComponentsAppBarDe._(_root);
	@override late final _TranslationsDocsComponentsAutocompleteDe autocomplete = _TranslationsDocsComponentsAutocompleteDe._(_root);
	@override late final _TranslationsDocsComponentsAvatarDe avatar = _TranslationsDocsComponentsAvatarDe._(_root);
	@override late final _TranslationsDocsComponentsAvatarGroupDe avatar_group = _TranslationsDocsComponentsAvatarGroupDe._(_root);
	@override late final _TranslationsDocsComponentsBadgeDe badge = _TranslationsDocsComponentsBadgeDe._(_root);
	@override late final _TranslationsDocsComponentsBreadcrumbDe breadcrumb = _TranslationsDocsComponentsBreadcrumbDe._(_root);
	@override late final _TranslationsDocsComponentsButtonDe button = _TranslationsDocsComponentsButtonDe._(_root);
	@override late final _TranslationsDocsComponentsCalendarDe calendar = _TranslationsDocsComponentsCalendarDe._(_root);
	@override late final _TranslationsDocsComponentsCardDe card = _TranslationsDocsComponentsCardDe._(_root);
	@override late final _TranslationsDocsComponentsCardImageDe card_image = _TranslationsDocsComponentsCardImageDe._(_root);
	@override late final _TranslationsDocsComponentsCarouselDe carousel = _TranslationsDocsComponentsCarouselDe._(_root);
	@override late final _TranslationsDocsComponentsCheckboxDe checkbox = _TranslationsDocsComponentsCheckboxDe._(_root);
	@override late final _TranslationsDocsComponentsChipDe chip = _TranslationsDocsComponentsChipDe._(_root);
	@override late final _TranslationsDocsComponentsChipInputDe chip_input = _TranslationsDocsComponentsChipInputDe._(_root);
	@override late final _TranslationsDocsComponentsCircularProgressDe circular_progress = _TranslationsDocsComponentsCircularProgressDe._(_root);
	@override late final _TranslationsDocsComponentsCodeSnippetDe code_snippet = _TranslationsDocsComponentsCodeSnippetDe._(_root);
	@override late final _TranslationsDocsComponentsCollapsibleDe collapsible = _TranslationsDocsComponentsCollapsibleDe._(_root);
	@override late final _TranslationsDocsComponentsColorPickerDe color_picker = _TranslationsDocsComponentsColorPickerDe._(_root);
	@override late final _TranslationsDocsComponentsCommandDe command = _TranslationsDocsComponentsCommandDe._(_root);
	@override late final _TranslationsDocsComponentsContextMenuDe context_menu = _TranslationsDocsComponentsContextMenuDe._(_root);
	@override late final _TranslationsDocsComponentsDatePickerDe date_picker = _TranslationsDocsComponentsDatePickerDe._(_root);
	@override late final _TranslationsDocsComponentsDialogDe dialog = _TranslationsDocsComponentsDialogDe._(_root);
	@override late final _TranslationsDocsComponentsDividerDe divider = _TranslationsDocsComponentsDividerDe._(_root);
	@override late final _TranslationsDocsComponentsDotIndicatorDe dot_indicator = _TranslationsDocsComponentsDotIndicatorDe._(_root);
	@override late final _TranslationsDocsComponentsDrawerDe drawer = _TranslationsDocsComponentsDrawerDe._(_root);
	@override late final _TranslationsDocsComponentsDropdownMenuDe dropdown_menu = _TranslationsDocsComponentsDropdownMenuDe._(_root);
	@override late final _TranslationsDocsComponentsExpandableSidebarDe expandable_sidebar = _TranslationsDocsComponentsExpandableSidebarDe._(_root);
	@override late final _TranslationsDocsComponentsFormDe form = _TranslationsDocsComponentsFormDe._(_root);
	@override late final _TranslationsDocsComponentsFormattedInputDe formatted_input = _TranslationsDocsComponentsFormattedInputDe._(_root);
	@override late final _TranslationsDocsComponentsHoverCardDe hover_card = _TranslationsDocsComponentsHoverCardDe._(_root);
	@override late final _TranslationsDocsComponentsInputDe input = _TranslationsDocsComponentsInputDe._(_root);
	@override late final _TranslationsDocsComponentsInputOtpDe input_otp = _TranslationsDocsComponentsInputOtpDe._(_root);
	@override late final _TranslationsDocsComponentsItemPickerDe item_picker = _TranslationsDocsComponentsItemPickerDe._(_root);
	@override late final _TranslationsDocsComponentsKeyboardDisplayDe keyboard_display = _TranslationsDocsComponentsKeyboardDisplayDe._(_root);
	@override late final _TranslationsDocsComponentsLinearProgressDe linear_progress = _TranslationsDocsComponentsLinearProgressDe._(_root);
	@override late final _TranslationsDocsComponentsMaterialDe material = _TranslationsDocsComponentsMaterialDe._(_root);
	@override late final _TranslationsDocsComponentsMenubarDe menubar = _TranslationsDocsComponentsMenubarDe._(_root);
	@override late final _TranslationsDocsComponentsMultiselectDe multiselect = _TranslationsDocsComponentsMultiselectDe._(_root);
	@override late final _TranslationsDocsComponentsNavigationBarDe navigation_bar = _TranslationsDocsComponentsNavigationBarDe._(_root);
	@override late final _TranslationsDocsComponentsNavigationMenuDe navigation_menu = _TranslationsDocsComponentsNavigationMenuDe._(_root);
	@override late final _TranslationsDocsComponentsNavigationRailDe navigation_rail = _TranslationsDocsComponentsNavigationRailDe._(_root);
	@override late final _TranslationsDocsComponentsNavigationSidebarDe navigation_sidebar = _TranslationsDocsComponentsNavigationSidebarDe._(_root);
	@override late final _TranslationsDocsComponentsNumberInputDe number_input = _TranslationsDocsComponentsNumberInputDe._(_root);
	@override late final _TranslationsDocsComponentsNumberTickerDe number_ticker = _TranslationsDocsComponentsNumberTickerDe._(_root);
	@override late final _TranslationsDocsComponentsOverflowMarqueeDe overflow_marquee = _TranslationsDocsComponentsOverflowMarqueeDe._(_root);
	@override late final _TranslationsDocsComponentsPaginationDe pagination = _TranslationsDocsComponentsPaginationDe._(_root);
	@override late final _TranslationsDocsComponentsPhoneInputDe phone_input = _TranslationsDocsComponentsPhoneInputDe._(_root);
	@override late final _TranslationsDocsComponentsPopoverDe popover = _TranslationsDocsComponentsPopoverDe._(_root);
	@override late final _TranslationsDocsComponentsProgressDe progress = _TranslationsDocsComponentsProgressDe._(_root);
	@override late final _TranslationsDocsComponentsRadioCardDe radio_card = _TranslationsDocsComponentsRadioCardDe._(_root);
	@override late final _TranslationsDocsComponentsRadioGroupDe radio_group = _TranslationsDocsComponentsRadioGroupDe._(_root);
	@override late final _TranslationsDocsComponentsRefreshTriggerDe refresh_trigger = _TranslationsDocsComponentsRefreshTriggerDe._(_root);
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderDe repeated_animation_builder = _TranslationsDocsComponentsRepeatedAnimationBuilderDe._(_root);
	@override late final _TranslationsDocsComponentsResizableDe resizable = _TranslationsDocsComponentsResizableDe._(_root);
	@override late final _TranslationsDocsComponentsScaffoldDe scaffold = _TranslationsDocsComponentsScaffoldDe._(_root);
	@override late final _TranslationsDocsComponentsSelectDe select = _TranslationsDocsComponentsSelectDe._(_root);
	@override late final _TranslationsDocsComponentsSheetDe sheet = _TranslationsDocsComponentsSheetDe._(_root);
	@override late final _TranslationsDocsComponentsSkeletonDe skeleton = _TranslationsDocsComponentsSkeletonDe._(_root);
	@override late final _TranslationsDocsComponentsSliderDe slider = _TranslationsDocsComponentsSliderDe._(_root);
	@override late final _TranslationsDocsComponentsSortableDe sortable = _TranslationsDocsComponentsSortableDe._(_root);
	@override late final _TranslationsDocsComponentsStarRatingDe star_rating = _TranslationsDocsComponentsStarRatingDe._(_root);
	@override late final _TranslationsDocsComponentsStepperDe stepper = _TranslationsDocsComponentsStepperDe._(_root);
	@override late final _TranslationsDocsComponentsStepsDe steps = _TranslationsDocsComponentsStepsDe._(_root);
	@override late final _TranslationsDocsComponentsSwiperDe swiper = _TranslationsDocsComponentsSwiperDe._(_root);
	@override late final _TranslationsDocsComponentsKSwitchDe k_switch = _TranslationsDocsComponentsKSwitchDe._(_root);
	@override late final _TranslationsDocsComponentsSwitcherDe switcher = _TranslationsDocsComponentsSwitcherDe._(_root);
	@override late final _TranslationsDocsComponentsTabListDe tab_list = _TranslationsDocsComponentsTabListDe._(_root);
	@override late final _TranslationsDocsComponentsTabPaneDe tab_pane = _TranslationsDocsComponentsTabPaneDe._(_root);
	@override late final _TranslationsDocsComponentsTableDe table = _TranslationsDocsComponentsTableDe._(_root);
	@override late final _TranslationsDocsComponentsTabsDe tabs = _TranslationsDocsComponentsTabsDe._(_root);
	@override late final _TranslationsDocsComponentsTextAreaDe text_area = _TranslationsDocsComponentsTextAreaDe._(_root);
	@override late final _TranslationsDocsComponentsTimePickerDe time_picker = _TranslationsDocsComponentsTimePickerDe._(_root);
	@override late final _TranslationsDocsComponentsTimelineDe timeline = _TranslationsDocsComponentsTimelineDe._(_root);
	@override late final _TranslationsDocsComponentsTimelineAnimationDe timeline_animation = _TranslationsDocsComponentsTimelineAnimationDe._(_root);
	@override late final _TranslationsDocsComponentsToastDe toast = _TranslationsDocsComponentsToastDe._(_root);
	@override late final _TranslationsDocsComponentsToggleDe toggle = _TranslationsDocsComponentsToggleDe._(_root);
	@override late final _TranslationsDocsComponentsTooltipDe tooltip = _TranslationsDocsComponentsTooltipDe._(_root);
	@override late final _TranslationsDocsComponentsTrackerDe tracker = _TranslationsDocsComponentsTrackerDe._(_root);
	@override late final _TranslationsDocsComponentsTreeDe tree = _TranslationsDocsComponentsTreeDe._(_root);
	@override late final _TranslationsDocsComponentsWindowDe window = _TranslationsDocsComponentsWindowDe._(_root);
}

// Path: docs.pages.introduction
class _TranslationsDocsPagesIntroductionDe extends TranslationsDocsPagesIntroductionKo {
	_TranslationsDocsPagesIntroductionDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Einführung';
	@override String get description => 'Erste Schritte mit coui_flutter';
	@override String get lead => 'Die schön gestalteten Komponenten von Coui/UI sind jetzt in Flutter verfügbar.';
	@override String get welcome_paragraph_1 => 'coui_flutter ist eine vielfältige und umfassende Sammlung von UI-Komponenten, die speziell für Flutter-Desktop- und Webanwendungen entwickelt wurde. Mit der zunehmenden Beliebtheit von Flutter zum Erstellen von plattformübergreifenden Apps haben wir die Notwendigkeit eines Toolkits erkannt, das die einzigartigen Designanforderungen von Desktop- und Webschnittstellen hervorhebt.';
	@override String get welcome_paragraph_2 => 'Dieses Paket bietet eine breite Palette von anpassbaren und reaktionsschnellen Komponenten, die modernen Desktop- und Webdesignprinzipien entsprechen. Egal, ob Sie komplexe Geschäftsanwendungen, elegante Dashboards oder Produktivitätswerkzeuge erstellen, unsere Komponenten sind darauf ausgelegt, Ihnen zu helfen, schnell und effizient professionelle und stilvolle UIs zu erstellen.';
	@override String get features => 'Hauptmerkmale';
	@override late final _TranslationsDocsPagesIntroductionFeaturesListDe features_list = _TranslationsDocsPagesIntroductionFeaturesListDe._(_root);
	@override String get notes => 'Hinweise';
	@override String get notes_paragraph_1 => 'Dieses Paket ist noch in Entwicklung und kann Änderungen unterliegen. Seien Sie vorsichtig, wenn Sie dieses Paket in der Produktion verwenden.';
	@override String get notes_paragraph_2 => 'Dieses Paket steht nicht in Verbindung mit Coui/UI. Es handelt sich um ein community-geführtes Projekt.';
	@override String get faq => 'Häufig gestellte Fragen';
	@override String get faq_gorouter_q => 'Unterstützt es GoRouter?';
	@override String get faq_gorouter_a => 'Ja, es wird unterstützt. Sie können GoRouter mit coui_flutter verwenden.';
	@override String get faq_usage_q => 'Kann ich es in meinem Projekt verwenden?';
	@override String get faq_usage_a => 'Ja! Sie können es kostenlos für persönliche und kommerzielle Projekte verwenden. Keine Urheberrechtsnennung erforderlich.';
	@override String get faq_material_q => 'Kann ich es mit Material/Cupertino-Widgets verwenden?';
	@override String get faq_material_a_1 => 'Natürlich!';
	@override String get faq_material_a_2 => 'Verweisen Sie auf diese Seite!';
	@override String get faq_style_q => 'Kann ich den Stil ändern? (Standard/New York)';
	@override String get faq_style_a_1 => 'Leider nicht. Dieses Paket unterstützt nur den New York-Stil. Wenn Sie jedoch den Standardstil von Coui/UI wünschen,';
	@override String get faq_style_a_2 => 'Diese Paket';
	@override String get faq_style_a_3 => 'wird empfohlen. Ersteller:';
	@override String get links => 'Links';
	@override String get link_github => 'Github: ';
	@override String get link_pubdev => 'pub.dev: ';
	@override String get link_discord => 'Discord: ';
}

// Path: docs.pages.installation
class _TranslationsDocsPagesInstallationDe extends TranslationsDocsPagesInstallationKo {
	_TranslationsDocsPagesInstallationDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Installation';
	@override String get description => 'Installieren von coui_flutter im Projekt';
	@override String get stable_version => 'Stabile Version';
	@override String get experimental_version => 'Experimental Version';
	@override String get step1_title => 'Neues Flutter-Projekt erstellen';
	@override String get step1_content => 'Erstellen Sie ein neues Flutter-Projekt mit dem folgenden Befehl:';
	@override String get step2_title => 'Abhängigkeiten hinzufügen';
	@override String get step2_content => 'Fügen Sie als Nächstes die Abhängigkeit coui_flutter zu Ihrem Projekt hinzu.';
	@override String get step3_title => 'Paket importieren';
	@override String get step3_content => 'Jetzt können Sie das Paket in Ihrem Dart-Code importieren.';
	@override String get step4_title => 'CouiApp-Widget hinzufügen';
	@override String get step4_content => 'Fügen Sie das CouiApp-Widget zur main-Funktion hinzu.';
	@override String get step5_title => 'App ausführen';
	@override String get step5_content => 'Führen Sie die App mit dem folgenden Befehl aus:';
	@override String get experimental_intro => 'Die experimentelle Version ist auf GitHub verfügbar.';
	@override String get experimental_usage => 'Um die experimentelle Version zu verwenden, nutzen Sie im pubspec.yaml anstelle der Versionsnummer git:';
	@override String get see_page => 'Siehe Seite: ';
	@override String get this_page => 'diese Seite';
	@override String get for_more_info => ' für weitere Informationen.';
	@override String get warning_title => 'Warnung';
	@override String get warning_content => 'Die experimentelle Version kann inkompatible Änderungen enthalten und wird nicht für den Produktionseinsatz empfohlen. Diese Version sollte nur zu Test- und Entwicklungszwecken verwendet werden.';
}

// Path: docs.pages.theme
class _TranslationsDocsPagesThemeDe extends TranslationsDocsPagesThemeKo {
	_TranslationsDocsPagesThemeDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Thema';
	@override String get description => 'Thema anpassen';
	@override String get custom_color_scheme => 'Benutzerdefiniertes Farbschema';
	@override String get custom_color_scheme_desc => 'Sie können das Aussehen und das Gefühl der App mit einem benutzerdefinierten Farbschema anpassen.';
	@override String get premade_color_schemes => 'Vorgefertigte Farbschemas';
	@override String get premade_color_schemes_desc => 'Sie können das Aussehen und das Gefühl der App mit vorgefertigten Farbschemas anpassen.';
	@override String get radius => 'Radius';
	@override String get radius_desc => 'Ändern Sie den Radius, um anzupassen, wie abgerundet die App aussieht.';
	@override String get scaling => 'Skalierung';
	@override String get scaling_desc => 'Ändern Sie die Skalierung, um die Größe der coui_flutter-Komponenten anzupassen.';
	@override String get scaling_alert => 'Es wird nicht die gesamte App vergrößert oder verkleinert. Nur die coui_flutter-Komponenten sind betroffen.';
	@override String get surface_opacity => 'Oberflächenopazität';
	@override String get surface_opacity_desc => 'Ändern Sie die Oberflächenopazität, um die Undurchsichtigkeit der Oberfläche anzupassen.';
	@override String get surface_blur => 'Oberflächenunschärfe';
	@override String get surface_blur_desc => 'Ändern Sie die Oberflächenunschärfe, um die Unschärfe der Oberfläche anzupassen.';
	@override String get code => 'Code';
	@override String get code_desc => 'Verwenden Sie den folgenden Code, um das Farbschema anzuwenden.';
}

// Path: docs.pages.typography
class _TranslationsDocsPagesTypographyDe extends TranslationsDocsPagesTypographyKo {
	_TranslationsDocsPagesTypographyDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Typografie';
	@override String get description => 'Textstil';
	@override String get headline1 => 'Überschrift 1';
	@override String get headline2 => 'Überschrift 2';
	@override String get headline3 => 'Überschrift 3';
	@override String get headline4 => 'Überschrift 4';
	@override String get paragraph => 'Absatz';
	@override String get blockquote => 'Zitat';
	@override String get list => 'Liste';
	@override String get inline_code => 'Inline-Code';
	@override String get lead => 'Leittext';
	@override String get large_text => 'Großer Text';
	@override String get small_text => 'Kleiner Text';
	@override String get muted_text => 'Grauer Text';
	@override String get sans => 'Sans';
	@override String get mono => 'Mono';
	@override String get extra_small => 'Sehr klein';
	@override String get small => 'Klein';
	@override String get base => 'Basis';
	@override String get large => 'Groß';
	@override String get extra_large => 'Sehr groß';
	@override String get extra_2x_large => 'Sehr 2x groß';
	@override String get extra_3x_large => 'Sehr 3x groß';
	@override String get extra_4x_large => 'Sehr 4x groß';
	@override String get extra_5x_large => 'Sehr 5x groß';
	@override String get extra_6x_large => 'Sehr 6x groß';
	@override String get extra_7x_large => 'Sehr 7x groß';
	@override String get extra_8x_large => 'Sehr 8x groß';
	@override String get extra_9x_large => 'Sehr 9x groß';
	@override String get thin => 'Dünn';
	@override String get extra_light => 'Sehr leicht';
	@override String get light => 'Leicht';
	@override String get normal => 'Normal';
	@override String get medium => 'Mittel';
	@override String get semi_bold => 'Semi Bold';
	@override String get bold => 'Bold';
	@override String get extra_bold => 'Sehr fett';
	@override String get black => 'Schwarz';
	@override String get italic => 'Kursiv';
}

// Path: docs.pages.layout
class _TranslationsDocsPagesLayoutDe extends TranslationsDocsPagesLayoutKo {
	_TranslationsDocsPagesLayoutDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Layout';
	@override String get description => 'Seitenlayout gestalten';
	@override String get padding => 'Padding';
	@override String get margin => 'Margin';
	@override String get center => 'Zentrum';
	@override String get gapped_column => 'Spalte mit Abstand';
	@override String get gapped_row => 'Reihe mit Abstand';
	@override String get separated_column => 'Getrennte Spalte';
	@override String get separated_row => 'Getrennte Reihe';
	@override String get basic_layout => 'Grundlegendes Layout';
}

// Path: docs.pages.web_preloader
class _TranslationsDocsPagesWebPreloaderDe extends TranslationsDocsPagesWebPreloaderKo {
	_TranslationsDocsPagesWebPreloaderDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Web-Preloader';
	@override String get description => 'Web-Ladebildschirm';
	@override String get step1_title => 'Webverzeichnis erstellen';
	@override String get step1_content => 'Erstellen Sie ein Webverzeichnis, falls nicht vorhanden.';
	@override String get step1_note => '* Wenn Sie das legacy Flutter Web verwenden, müssen Sie das Upgrade mit dem obigen Befehl durchführen.';
	@override String get step1_button => 'Klicken Sie hier für weitere Informationen.';
	@override String get step2_title => 'Skript hinzufügen';
	@override String get step2_content => 'Wählen Sie als Nächstes einen der vorgefertigten Preloader aus und kopieren Sie ihn:';
	@override String get step2_standard => 'Standard-Preloader';
	@override String get step3_title => 'Skript einfügen';
	@override String get step3_content_1 => 'Öffnen Sie Ihre ';
	@override String get step3_content_2 => ' Datei und fügen Sie das Skript in den ';
	@override String get step3_content_3 => ' Tag ein.';
	@override String get step3_example => 'Zum Beispiel:';
	@override String get step4_title => 'App ausführen';
	@override String get step4_content => 'Verwenden Sie den folgenden Befehl, um die App auszuführen:';
	@override String get alert_title => 'Beitragen';
	@override String get alert_content_1 => 'Wenn Sie einen Preloader haben, den Sie teilen möchten, erstellen Sie einen Pull-Request im ';
	@override String get alert_button => 'web_loaders';
	@override String get alert_content_2 => ' Verzeichnis.';
}

// Path: docs.pages.components_list
class _TranslationsDocsPagesComponentsListDe extends TranslationsDocsPagesComponentsListKo {
	_TranslationsDocsPagesComponentsListDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Komponenten';
	@override String get description => 'Liste wiederverwendbarer Komponenten';
	@override String get work_in_progress => 'In Arbeit';
	@override String get animation => 'Animation';
	@override String get disclosure => 'Offenlegung';
	@override String get feedback => 'Feedback';
	@override String get forms => 'Formen';
	@override String get layout => 'Layout';
	@override String get navigation => 'Navigation';
	@override String get surfaces => 'Oberflächen';
	@override String get data_display => 'Datenanzeige';
	@override String get utilities => 'Hilfsprogramme';
}

// Path: docs.pages.icons
class _TranslationsDocsPagesIconsDe extends TranslationsDocsPagesIconsKo {
	_TranslationsDocsPagesIconsDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Symbole';
	@override String get description => 'Symboldesignsystem';
	@override String get use_this_code => 'Verwenden Sie diesen Code, um dieses Symbol anzuzeigen:';
	@override String get search_icons => 'Symbole suchen';
	@override String get radix_icons => 'Radix-Symbole';
	@override String get bootstrap_icons => 'Bootstrap-Symbole';
	@override String get lucide_icons => 'Lucide-Symbole';
}

// Path: docs.pages.colors
class _TranslationsDocsPagesColorsDe extends TranslationsDocsPagesColorsKo {
	_TranslationsDocsPagesColorsDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Farben';
	@override String get description => 'Farben Palette';
	@override String get use_this_code => 'Verwenden Sie diesen Code, um diese Farbe anzuzeigen:';
	@override String get color_and_colorshades => 'Farbe und ColorShades/ColorSwatch-Konstanten';
	@override String get predefined_colors => 'Vordefinierte Farben';
	@override String get generate_color => 'Farbe generieren';
	@override String get hue_shift => 'Farbtonverschiebung';
	@override String get saturation_step_up => 'Farbsättigung erhöhen';
	@override String get saturation_step_down => 'Farbsättigung verringern';
	@override String get lightness_step_up => 'Helligkeit erhöhen';
	@override String get lightness_step_down => 'Helligkeit verringern';
	@override String get cancel => 'Abbrechen';
	@override String get reset_options => 'Optionen zurücksetzen';
	@override String get reset_confirmation => 'Möchten Sie die Optionen zurücksetzen?';
}

// Path: docs.pages.external
class _TranslationsDocsPagesExternalDe extends TranslationsDocsPagesExternalKo {
	_TranslationsDocsPagesExternalDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Material/Cupertino';
	@override String get description => 'Flutter Standard-Widgets';
}

// Path: docs.pages.state
class _TranslationsDocsPagesStateDe extends TranslationsDocsPagesStateKo {
	_TranslationsDocsPagesStateDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Zustandsverwaltung';
	@override String get description => 'Muster zur Zustandsverwaltung';
	@override String get intro_1 => 'In Flutter ist alles ein Widget, und wo die Daten gespeichert werden, ist das auch.';
	@override String get intro_2 => 'Intern hat coui_flutter ein eigenes Zustandsverwaltungssystem. Wenn Sie bereits ein Zustandsverwaltungssystem verwenden, können Sie es weiterhin zusammen mit coui_flutter verwenden.';
	@override String get passing_data_to_children => 'Daten an Kinder übergeben';
	@override String get passing_data_desc => 'Sie können den Data-Widget verwenden, um Daten an Kinder zu übergeben. Alle Änderungen an den Daten lösen ein erneutes Rendern der Kinder aus.';
	@override String get rebuild_difference_title => 'Haben Sie den Unterschied in den Wiederherstellungen bemerkt?';
	@override String get rebuild_difference_content => 'MostInnerWidget wird neu aufgebaut, wenn sich die Daten ändern, aber InnerWidget nicht. Dies liegt daran, dass InnerWidget keine Daten empfängt.';
	@override String get setting_data_boundary => 'Daten-Grenzen setzen';
	@override String get setting_data_boundary_desc => 'Sie können Grenzen setzen, um zu verhindern, dass Kinder auf die Daten zugreifen.';
	@override String get data_methods_vs => 'Data.maybeOf/Data.of vs Data.maybeFind/Data.find';
	@override String get data_methods_desc_1 => ' und ';
	@override String get data_methods_desc_2 => ' empfangen Daten und stellen die Widgets neu auf, wenn sich die Daten ändern. Während ';
	@override String get data_methods_desc_3 => ' empfängt keine Daten und gibt nur die Daten zurück.';
	@override String get data_find_usage => ' eignet sich gut für Methoden, bei denen onPressed, onLongPressed usw. einmal aufgerufen werden.';
	@override String get data_of_usage => ' eignet sich gut für den build-Methode, wo das Widget neu aufgebaut werden muss, wenn sich die Daten ändern.';
	@override String get getting_data_from_child => 'Daten von Kinder holen';
	@override String get getting_data_desc_1 => 'Sie können Daten von seinen Kindern mit der Methode erhalten. Diese Methode empfängt keine Änderungen an den Daten.';
	@override String get getting_data_desc_2 => 'Wenn die Daten von den Kindern empfangen werden, kann es zu einer unendlichen Wiederaufbau-Schleife kommen. Wenn Sie Daten im Eltern-Widget empfangen möchten, gehen Sie nach oben.';
	@override String get root_data_title => 'Haben Sie die Root-Daten bemerkt?';
	@override String get root_data_content => 'Nutzt die Daten des innenliegenden Data-Widgets auf der linken Seite. Ein Elternteil kann nur Daten vom ersten verbundenen Kind empfangen.';
	@override String get setting_messenger_boundary => 'DataMessenger-Grenze setzen';
	@override String get setting_messenger_boundary_desc => 'Sie können Grenzen setzen, um zu verhindern, dass Kinder Daten von einem bestimmten Elternteil erhalten.';
	@override String get multidata_widget => 'MultiData-Widget';
	@override String get multidata_desc => 'Mit dem MultiData-Widget können Sie mehrere Daten an Kinder übergeben. Schauen Sie sich das folgende Beispiel an:';
	@override String get multidata_avoid_nesting => 'Sie können Verschachtelungen vermeiden, indem Sie das MultiData-Widget verwenden.';
	@override String get example => 'Beispiel';
	@override String get passing_state_as_controller => 'Zustand als Controller übergeben';
	@override String get passing_state_controller_desc => 'Sie können den Zustand als Controller an Kinder übergeben. Dadurch können die Kinder Methoden des Eltern-Widgets aufrufen.';
	@override String get databuilder => 'DataBuilder';
	@override String get databuilder_desc => 'Mit dem DataBuilder-Widget können Sie ein Widget erneut aufbauen, wenn sich die Daten ändern. Dies vermeidet das erneute Rendern des gesamten Widgets.';
	@override String get datanotifier => 'DataNotifier';
	@override String get datanotifier_desc => 'Mit DataNotifier können Sie Werte vom ValueListenable an Kinder übergeben.';
	@override String get example_with_multidata => 'Beispiel mit MultiData';
	@override String get passing_object_as_data => 'Objekte als Daten übergeben';
	@override String get passing_object_desc => 'Wenn Sie ein Objekt als Daten übergeben, gibt es einige Dinge zu beachten:';
	@override String get override_equals_hashcode => '1. == und hashCode überschreiben';
	@override String get override_equals_desc => 'Wenn ein vorheriges Objekt nicht gleich dem neuen Objekt ist, wird eine Benachrichtigung an die Kinder gesendet. Wenn Sie == und hashCode nicht überschreiben, wird jedes Mal ein anderes Objekt angesehen, auch wenn die Feldwerte gleich sind.';
	@override String get use_distinctdata => '2. DistinctData verwenden';
	@override String get use_distinctdata_desc => 'DistinctData ist ein Mixin, das benachrichtigen kann, wenn sich ein bestimmtes Feld ändert.';
	@override String get passing_mutable_object => '3. Mutable Objekte an Kinder übergeben';
	@override String get passing_mutable_object_desc => 'Es ist besser, unveränderliche Objekte an Kinder zu übergeben. Mutable Objekte (wie Listen, Maps, Sets, Widget States) benachrichtigen die Kinder nicht, wenn sich die Objektreferenzen nicht ändern.';
	@override String get passing_variable_to_children => 'Variablen an Kinder übergeben';
	@override String get passing_variable_desc => 'Sie können das Model-Widget verwenden, um Variablen an Kinder zu übergeben. Es ist ähnlich wie das Data-Widget, hat jedoch strenge Typen und ist beschriftet.';
	@override String get change_variable_from_children => 'Variablen von Kindern ändern';
	@override String get change_variable_desc => 'Es gibt zwei Möglichkeiten, um Modellwerte von Kindern zu ändern:';
	@override String get modelnotifier => 'ModelNotifier';
	@override String get modelnotifier_desc => 'Mit ModelNotifier können Sie Werte vom ValueNotifier an Kinder übergeben, ohne dass setState im Eltern-Widget erforderlich ist.';
	@override String get modellistenable => 'ModelListenable';
	@override String get modellistenable_desc => 'ModelListenable ist ein schreibgeschützter ModelNotifier. Kinder können nur Werte empfangen. Wenn ein Kind versucht, die Werte zu ändern, wird ein Fehler angezeigt.';
	@override String get modelbuilder => 'ModelBuilder';
	@override String get modelbuilder_desc => 'ModelBuilder empfängt Werte und baut das Widget neu auf, wenn sich die Werte ändern. Es ist ähnlich wie DataBuilder, hat jedoch strenge Typen und ist beschriftet.';
}

// Path: docs.components.accordion
class _TranslationsDocsComponentsAccordionDe extends TranslationsDocsComponentsAccordionKo {
	_TranslationsDocsComponentsAccordionDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Accordion';
	@override String get description => 'Ein Accordion ist eine Liste von Elementen, die vertikal gestapelt sind. Jedes Element kann \'erweitert\' oder \'eingeklappt\' werden, um die damit verbundenen Inhalte anzuzeigen.';
	@override late final _TranslationsDocsComponentsAccordionExamplesDe examples = _TranslationsDocsComponentsAccordionExamplesDe._(_root);
}

// Path: docs.components.alert
class _TranslationsDocsComponentsAlertDe extends TranslationsDocsComponentsAlertKo {
	_TranslationsDocsComponentsAlertDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Benachrichtigung';
	@override String get description => 'Benachrichtigungen werden verwendet, um den Zustand zu übermitteln, der das System beeinflusst.';
	@override late final _TranslationsDocsComponentsAlertExamplesDe examples = _TranslationsDocsComponentsAlertExamplesDe._(_root);
	@override String get title => 'Benachrichtigung Titel';
	@override String get content => 'Inhalt der Benachrichtigung.';
}

// Path: docs.components.alert_dialog
class _TranslationsDocsComponentsAlertDialogDe extends TranslationsDocsComponentsAlertDialogKo {
	_TranslationsDocsComponentsAlertDialogDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Benachrichtigungsdialog';
	@override String get description => 'Der Benachrichtigungsdialog zeigt wichtige Informationen an, die die Aufmerksamkeit des Nutzers erfordern.';
	@override late final _TranslationsDocsComponentsAlertDialogExamplesDe examples = _TranslationsDocsComponentsAlertDialogExamplesDe._(_root);
	@override String get click_here => 'Hier klicken';
	@override String get alert_title => 'Benachrichtigung Titel';
	@override String get alert_content => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
}

// Path: docs.components.animated_value_builder
class _TranslationsDocsComponentsAnimatedValueBuilderDe extends TranslationsDocsComponentsAnimatedValueBuilderKo {
	_TranslationsDocsComponentsAnimatedValueBuilderDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Animierter Wert-Builder';
	@override String get description => 'Ein Builder, der automatisch Animationen anwendet, wenn sich der Wert ändert.';
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderExamplesDe examples = _TranslationsDocsComponentsAnimatedValueBuilderExamplesDe._(_root);
}

// Path: docs.components.app_bar
class _TranslationsDocsComponentsAppBarDe extends TranslationsDocsComponentsAppBarKo {
	_TranslationsDocsComponentsAppBarDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'App-Leiste';
	@override String get description => 'Die App-Leiste ist ein zentrales Navigationselement, das oben in der App angezeigt wird.';
	@override late final _TranslationsDocsComponentsAppBarExamplesDe examples = _TranslationsDocsComponentsAppBarExamplesDe._(_root);
}

// Path: docs.components.autocomplete
class _TranslationsDocsComponentsAutocompleteDe extends TranslationsDocsComponentsAutocompleteKo {
	_TranslationsDocsComponentsAutocompleteDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Autocomplete';
	@override String get description => 'Ein Eingabefeld, das Vorschläge basierend auf der Benutzereingabe anzeigt.';
	@override late final _TranslationsDocsComponentsAutocompleteExamplesDe examples = _TranslationsDocsComponentsAutocompleteExamplesDe._(_root);
}

// Path: docs.components.avatar
class _TranslationsDocsComponentsAvatarDe extends TranslationsDocsComponentsAvatarKo {
	_TranslationsDocsComponentsAvatarDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Avatar';
	@override String get description => 'Ein Bild oder Symbol, das einen Benutzer oder eine Entität darstellt.';
	@override late final _TranslationsDocsComponentsAvatarExamplesDe examples = _TranslationsDocsComponentsAvatarExamplesDe._(_root);
}

// Path: docs.components.avatar_group
class _TranslationsDocsComponentsAvatarGroupDe extends TranslationsDocsComponentsAvatarGroupKo {
	_TranslationsDocsComponentsAvatarGroupDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Avatar-Gruppe';
	@override String get description => 'Zeigt mehrere Avatare zusammen an.';
	@override late final _TranslationsDocsComponentsAvatarGroupExamplesDe examples = _TranslationsDocsComponentsAvatarGroupExamplesDe._(_root);
}

// Path: docs.components.badge
class _TranslationsDocsComponentsBadgeDe extends TranslationsDocsComponentsBadgeKo {
	_TranslationsDocsComponentsBadgeDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Badge';
	@override String get description => 'Ein kleines Label, das den Status oder eine Anzahl von Benachrichtigungen anzeigt.';
	@override late final _TranslationsDocsComponentsBadgeExamplesDe examples = _TranslationsDocsComponentsBadgeExamplesDe._(_root);
	@override String get primary => 'Primär';
	@override String get secondary => 'Sekundär';
	@override String get outline => 'Umriss';
	@override String get destructive => 'Zerstörerisch';
}

// Path: docs.components.breadcrumb
class _TranslationsDocsComponentsBreadcrumbDe extends TranslationsDocsComponentsBreadcrumbKo {
	_TranslationsDocsComponentsBreadcrumbDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Brotkrumen';
	@override String get description => 'Brotkrumen sind ein sekundäres Navigationssystem, das den Standort des Benutzers auf der Website oder Webanwendung darstellt.';
	@override late final _TranslationsDocsComponentsBreadcrumbExamplesDe examples = _TranslationsDocsComponentsBreadcrumbExamplesDe._(_root);
	@override String get home => 'Startseite';
	@override String get components => 'Komponenten';
}

// Path: docs.components.button
class _TranslationsDocsComponentsButtonDe extends TranslationsDocsComponentsButtonKo {
	_TranslationsDocsComponentsButtonDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Schaltfläche';
	@override String get description => 'Mit Schaltflächen kann der Benutzer mit einem einzigen Tippen eine Aktion durchführen oder eine Auswahl treffen.';
	@override late final _TranslationsDocsComponentsButtonExamplesDe examples = _TranslationsDocsComponentsButtonExamplesDe._(_root);
	@override String get primary => 'Primär';
	@override String get secondary => 'Sekundär';
	@override String get outlined => 'Umriss';
	@override String get ghost => 'Ghost';
	@override String get destructive => 'Zerstörerisch';
	@override String get link => 'Link';
	@override String get outline => 'Umrandung';
	@override String get text => 'Text';
	@override String get extra_small => 'Extra Klein';
	@override String get small => 'Klein';
	@override String get normal => 'Normal';
	@override String get large => 'Groß';
	@override String get extra_large => 'Extra Groß';
	@override String get save => 'Speichern';
	@override String get cancel => 'Abbrechen';
	@override String get close => 'Schließen';
	@override String get submit => 'Einreichen';
	@override String get edit_profile => 'Profil bearbeiten';
	@override String get save_changes => 'Änderungen speichern';
	@override String get undo => 'Rückgängig machen';
	@override String get compact => 'Kompakt';
	@override String get dense => 'Dicht';
	@override String get comfortable => 'Bequem';
	@override String get icon => 'Symbol';
	@override String get icon_comfortable => 'Bequeme Symbole';
	@override String get rectangle => 'Rechteck';
	@override String get add => 'Hinzufügen';
	@override String get focused => 'Fokussiert';
	@override String get hovered => 'Überfahren';
	@override String get pressed => 'Gedrückt';
	@override String get text_button => 'Text-Schaltfläche';
	@override String get custom_button => 'Benutzerdefinierte Schaltfläche';
}

// Path: docs.components.calendar
class _TranslationsDocsComponentsCalendarDe extends TranslationsDocsComponentsCalendarKo {
	_TranslationsDocsComponentsCalendarDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Kalender';
	@override String get description => 'Ein Komponenten zur Auswahl und Anzeige von Daten.';
	@override late final _TranslationsDocsComponentsCalendarExamplesDe examples = _TranslationsDocsComponentsCalendarExamplesDe._(_root);
}

// Path: docs.components.card
class _TranslationsDocsComponentsCardDe extends TranslationsDocsComponentsCardKo {
	_TranslationsDocsComponentsCardDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Karte';
	@override String get description => 'Beschreibung';
	@override late final _TranslationsDocsComponentsCardExamplesDe examples = _TranslationsDocsComponentsCardExamplesDe._(_root);
	@override String get create_project => 'Projekt erstellen';
	@override String get deploy_description => 'Ein Projekt mit einem Klick bereitstellen';
	@override String get name => 'Name';
	@override String get name_placeholder => 'Projektname';
	@override String get description_placeholder => 'Projektbeschreibung';
	@override String get deploy => 'Bereitstellen';
}

// Path: docs.components.card_image
class _TranslationsDocsComponentsCardImageDe extends TranslationsDocsComponentsCardImageKo {
	_TranslationsDocsComponentsCardImageDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Bildkarte';
	@override String get description => 'Eine Kartenkomponente mit einem Bild.';
	@override late final _TranslationsDocsComponentsCardImageExamplesDe examples = _TranslationsDocsComponentsCardImageExamplesDe._(_root);
	@override String get card_image_title => 'Kartenbild';
	@override String get card_clicked => 'Kartenbild wurde angeklickt';
	@override String card_number({required Object n}) => 'Kartennummer ${n}';
	@override String get lorem_ipsum => 'Lorem ipsum dolor sit amet';
}

// Path: docs.components.carousel
class _TranslationsDocsComponentsCarouselDe extends TranslationsDocsComponentsCarouselKo {
	_TranslationsDocsComponentsCarouselDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Karussell';
	@override String get description => 'Eine Komponente, die mehrere Elemente in einem Slider anzeigt.';
	@override late final _TranslationsDocsComponentsCarouselExamplesDe examples = _TranslationsDocsComponentsCarouselExamplesDe._(_root);
}

// Path: docs.components.checkbox
class _TranslationsDocsComponentsCheckboxDe extends TranslationsDocsComponentsCheckboxKo {
	_TranslationsDocsComponentsCheckboxDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Checkbox';
	@override String get description => 'Checkboxes ermöglichen es Benutzern, mehrere Elemente aus einer Liste auszuwählen.';
	@override late final _TranslationsDocsComponentsCheckboxExamplesDe examples = _TranslationsDocsComponentsCheckboxExamplesDe._(_root);
	@override String get remember_me => 'Erinnere dich an mich';
}

// Path: docs.components.chip
class _TranslationsDocsComponentsChipDe extends TranslationsDocsComponentsChipKo {
	_TranslationsDocsComponentsChipDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Chip';
	@override String get description => 'Ein Chip ist ein kleines Element, das Eigenschaften, Optionen oder Aktionen darstellt.';
	@override late final _TranslationsDocsComponentsChipExamplesDe examples = _TranslationsDocsComponentsChipExamplesDe._(_root);
	@override String get apple => 'Apfel';
	@override String get banana => 'Banane';
	@override String get cherry => 'Kirsche';
	@override String get durian => 'Durian';
	@override String get elderberry => 'Holunderbeere';
}

// Path: docs.components.chip_input
class _TranslationsDocsComponentsChipInputDe extends TranslationsDocsComponentsChipInputKo {
	_TranslationsDocsComponentsChipInputDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Chip-Eingabe';
	@override String get description => 'Ein Eingabefeld für mehrere Werte in Form von Chips.';
	@override late final _TranslationsDocsComponentsChipInputExamplesDe examples = _TranslationsDocsComponentsChipInputExamplesDe._(_root);
}

// Path: docs.components.circular_progress
class _TranslationsDocsComponentsCircularProgressDe extends TranslationsDocsComponentsCircularProgressKo {
	_TranslationsDocsComponentsCircularProgressDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Kreisfortschritt';
	@override String get description => 'Kreisförmiger Fortschrittsindikator.';
	@override late final _TranslationsDocsComponentsCircularProgressExamplesDe examples = _TranslationsDocsComponentsCircularProgressExamplesDe._(_root);
	@override String get increase_by_10 => 'Um 10 erhöhen';
	@override String get decrease_by_10 => 'Um 10 verringern';
}

// Path: docs.components.code_snippet
class _TranslationsDocsComponentsCodeSnippetDe extends TranslationsDocsComponentsCodeSnippetKo {
	_TranslationsDocsComponentsCodeSnippetDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Code-Snippet';
	@override String get description => 'Eine Komponente zur Anzeige von Code.';
	@override late final _TranslationsDocsComponentsCodeSnippetExamplesDe examples = _TranslationsDocsComponentsCodeSnippetExamplesDe._(_root);
}

// Path: docs.components.collapsible
class _TranslationsDocsComponentsCollapsibleDe extends TranslationsDocsComponentsCollapsibleKo {
	_TranslationsDocsComponentsCollapsibleDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Zusammenklappbar';
	@override String get description => 'Ein Inhaltscontainer, der zusammengeklappt oder ausgeklappt werden kann.';
	@override late final _TranslationsDocsComponentsCollapsibleExamplesDe examples = _TranslationsDocsComponentsCollapsibleExamplesDe._(_root);
	@override String get starred_repositories => '@coco-de hat 3 Repositories als Favoriten markiert.';
	@override String get collapse_all => 'Alles einklappen';
	@override String get expand_all => 'Alles ausklappen';
	@override String get expand_icon => 'Symbol ausklappen';
	@override String get use_path_branch => 'Nutzung des Pfad-Branches';
	@override String get recursive_selection => 'Rekursive Auswahl';
}

// Path: docs.components.color_picker
class _TranslationsDocsComponentsColorPickerDe extends TranslationsDocsComponentsColorPickerKo {
	_TranslationsDocsComponentsColorPickerDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Farbwähler';
	@override String get description => 'Eine Komponente, mit der Farben ausgewählt werden können.';
	@override late final _TranslationsDocsComponentsColorPickerExamplesDe examples = _TranslationsDocsComponentsColorPickerExamplesDe._(_root);
	@override String get pick_color => 'Farbe auswählen';
	@override String color_label({required Object color}) => 'Farbe: ${color}';
	@override String get select_color => 'Farbe auswählen';
	@override String get open_color_picker_popover => 'Farbwähler-Popover öffnen';
	@override String get open_color_picker_dialog => 'Farbwähler-Dialog öffnen';
}

// Path: docs.components.command
class _TranslationsDocsComponentsCommandDe extends TranslationsDocsComponentsCommandKo {
	_TranslationsDocsComponentsCommandDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Befehl';
	@override String get description => 'Ein Komponente zum Suchen von Elementen.';
	@override late final _TranslationsDocsComponentsCommandExamplesDe examples = _TranslationsDocsComponentsCommandExamplesDe._(_root);
}

// Path: docs.components.context_menu
class _TranslationsDocsComponentsContextMenuDe extends TranslationsDocsComponentsContextMenuKo {
	_TranslationsDocsComponentsContextMenuDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Kontextmenü';
	@override String get description => 'Ein Menü, das durch Rechtsklick oder langes Drücken angezeigt wird.';
	@override late final _TranslationsDocsComponentsContextMenuExamplesDe examples = _TranslationsDocsComponentsContextMenuExamplesDe._(_root);
}

// Path: docs.components.date_picker
class _TranslationsDocsComponentsDatePickerDe extends TranslationsDocsComponentsDatePickerKo {
	_TranslationsDocsComponentsDatePickerDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Datumswähler';
	@override String get description => 'Ein Eingabefeld zur Auswahl eines Datums.';
	@override late final _TranslationsDocsComponentsDatePickerExamplesDe examples = _TranslationsDocsComponentsDatePickerExamplesDe._(_root);
	@override String get select_date => 'Datum auswählen';
	@override String get select_date_range => 'Datumsbereich auswählen';
}

// Path: docs.components.dialog
class _TranslationsDocsComponentsDialogDe extends TranslationsDocsComponentsDialogKo {
	_TranslationsDocsComponentsDialogDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Dialog';
	@override String get description => 'Ein Dialog ist ein modales Fenster, das über den Rest der App angezeigt wird.';
	@override late final _TranslationsDocsComponentsDialogExamplesDe examples = _TranslationsDocsComponentsDialogExamplesDe._(_root);
	@override String get edit_profile_title => 'Profil bearbeiten';
	@override String get edit_profile_description => 'Ändern Sie hier Ihr Profil. Klicken Sie auf Speichern, wenn Sie fertig sind.';
	@override String get name_label => 'Name';
	@override String get username_label => 'Benutzername';
	@override String get hello => 'Hallo';
	@override String get material_dialog_content => 'Material-Dialog.';
	@override String get cupertino_dialog_content => 'Cupertino-Dialog.';
	@override String get alert_title => 'Benachrichtigung Titel';
	@override String get click_here => 'Hier klicken';
	@override String get ok => 'OK';
	@override String get open_material_dialog => 'Material-Dialog öffnen';
	@override String get open_cupertino_dialog => 'Cupertino-Dialog öffnen';
	@override String get open_coui_dialog => 'COUI-Dialog öffnen';
}

// Path: docs.components.divider
class _TranslationsDocsComponentsDividerDe extends TranslationsDocsComponentsDividerKo {
	_TranslationsDocsComponentsDividerDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Trennlinie';
	@override String get description => 'Eine Linie, die Inhalte visuell trennt.';
	@override late final _TranslationsDocsComponentsDividerExamplesDe examples = _TranslationsDocsComponentsDividerExamplesDe._(_root);
	@override String get item_1 => 'Element 1';
	@override String get item_2 => 'Element 2';
	@override String get item_3 => 'Element 3';
	@override String get divider => 'Trennlinie';
}

// Path: docs.components.dot_indicator
class _TranslationsDocsComponentsDotIndicatorDe extends TranslationsDocsComponentsDotIndicatorKo {
	_TranslationsDocsComponentsDotIndicatorDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Punktindikator';
	@override String get description => 'Ein Indikator, der die aktuelle Position durch Punkte anzeigt.';
	@override late final _TranslationsDocsComponentsDotIndicatorExamplesDe examples = _TranslationsDocsComponentsDotIndicatorExamplesDe._(_root);
}

// Path: docs.components.drawer
class _TranslationsDocsComponentsDrawerDe extends TranslationsDocsComponentsDrawerKo {
	_TranslationsDocsComponentsDrawerDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Schublade';
	@override String get description => 'Ein Panel, das von einem Bildschirmrand hereingleitet.';
	@override late final _TranslationsDocsComponentsDrawerExamplesDe examples = _TranslationsDocsComponentsDrawerExamplesDe._(_root);
	@override String get open_drawer => 'Schublade öffnen';
	@override String get close_drawer => 'Schublade schließen';
	@override String get open_another_drawer => 'Eine andere Schublade öffnen';
	@override String drawer_at({required Object count, required Object position}) => 'Schublade ${count} bei ${position}';
}

// Path: docs.components.dropdown_menu
class _TranslationsDocsComponentsDropdownMenuDe extends TranslationsDocsComponentsDropdownMenuKo {
	_TranslationsDocsComponentsDropdownMenuDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Dropdown-Menü';
	@override String get description => 'Ein Menü, das eine Liste wählbarer Optionen anzeigt.';
	@override late final _TranslationsDocsComponentsDropdownMenuExamplesDe examples = _TranslationsDocsComponentsDropdownMenuExamplesDe._(_root);
}

// Path: docs.components.expandable_sidebar
class _TranslationsDocsComponentsExpandableSidebarDe extends TranslationsDocsComponentsExpandableSidebarKo {
	_TranslationsDocsComponentsExpandableSidebarDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Erweiterbare Sidebar';
	@override String get description => 'Eine Sidebar, die aufgeklappt und eingeklappt werden kann.';
	@override late final _TranslationsDocsComponentsExpandableSidebarExamplesDe examples = _TranslationsDocsComponentsExpandableSidebarExamplesDe._(_root);
}

// Path: docs.components.form
class _TranslationsDocsComponentsFormDe extends TranslationsDocsComponentsFormKo {
	_TranslationsDocsComponentsFormDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Formular';
	@override String get description => 'Ein Hilfs-Widget, um Formularvalidierungen zu erleichtern.';
	@override late final _TranslationsDocsComponentsFormExamplesDe examples = _TranslationsDocsComponentsFormExamplesDe._(_root);
	@override String get username_label => 'Benutzername';
	@override String get username_hint => 'Das wird öffentlich angezeigt.';
	@override String get password_label => 'Passwort';
	@override String get confirm_password_label => 'Passwort bestätigen';
	@override String get passwords_do_not_match => 'Passwörter stimmen nicht überein.';
	@override String get agree_terms => 'Ich stimme den Nutzungsbedingungen zu.';
	@override String get must_agree_terms => 'Sie müssen den Nutzungsbedingungen zustimmen.';
	@override String get form_values_title => 'Formularwerte';
	@override String get register => 'Registrieren';
	@override String get username_already_taken => 'Benutzername bereits vergeben.';
	@override String get email => 'E-Mail';
	@override String username_display({required Object value}) => 'Benutzername: ${value}';
	@override String password_display({required Object value}) => 'Passwort: ${value}';
	@override String confirm_password_display({required Object value}) => 'Passwort bestätigen: ${value}';
	@override String agree_display({required Object value}) => 'Zustimmung: ${value}';
	@override String json_display({required Object value}) => 'JSON: ${value}';
	@override String submitted_value_display({required Object value}) => 'Übermittelte Werte: ${value}';
	@override String get login => 'Anmelden';
	@override String get sign_up => 'Registrieren';
	@override String get dont_have_account => 'Haben Sie kein Konto?';
	@override String get already_have_account => 'Haben Sie bereits ein Konto?';
}

// Path: docs.components.formatted_input
class _TranslationsDocsComponentsFormattedInputDe extends TranslationsDocsComponentsFormattedInputKo {
	_TranslationsDocsComponentsFormattedInputDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Formatierte Eingabe';
	@override String get description => 'Ein Textfeld, das auf ein bestimmtes Format ausgelegt ist.';
	@override late final _TranslationsDocsComponentsFormattedInputExamplesDe examples = _TranslationsDocsComponentsFormattedInputExamplesDe._(_root);
}

// Path: docs.components.hover_card
class _TranslationsDocsComponentsHoverCardDe extends TranslationsDocsComponentsHoverCardKo {
	_TranslationsDocsComponentsHoverCardDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Hover-Karte';
	@override String get description => 'Eine Karte, die beim Hover angezeigt wird.';
	@override late final _TranslationsDocsComponentsHoverCardExamplesDe examples = _TranslationsDocsComponentsHoverCardExamplesDe._(_root);
	@override String get flutter_handle => '@flutter';
	@override String get flutter_username => 'Flutter';
	@override String get flutter_description => 'Das Flutter SDK ist ein Werkzeug zum Erstellen schöner Apps für Mobilgeräte, Web und Desktop aus einer einzigen Codebasis.';
}

// Path: docs.components.input
class _TranslationsDocsComponentsInputDe extends TranslationsDocsComponentsInputKo {
	_TranslationsDocsComponentsInputDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Eingabe';
	@override String get description => 'Text-Eingabefeld.';
	@override late final _TranslationsDocsComponentsInputExamplesDe examples = _TranslationsDocsComponentsInputExamplesDe._(_root);
	@override String get enter_name => 'Geben Sie Ihren Namen ein';
	@override String get enter_username => 'Geben Sie Ihren Benutzernamen ein';
	@override String get username_already_taken => 'Benutzername bereits vergeben.';
	@override String get hello_world => 'Hallo Welt!';
	@override String get search_something => 'Etwas suchen...';
	@override String get email => 'E-Mail';
	@override String get password => 'Geben Sie Ihr Passwort ein';
	@override String get username_hint => 'Das ist für Ihren Benutzernamen';
}

// Path: docs.components.input_otp
class _TranslationsDocsComponentsInputOtpDe extends TranslationsDocsComponentsInputOtpKo {
	_TranslationsDocsComponentsInputOtpDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'OTP-Eingabe';
	@override String get description => 'Ein Feld zur Eingabe eines Einmalpassworts.';
	@override late final _TranslationsDocsComponentsInputOtpExamplesDe examples = _TranslationsDocsComponentsInputOtpExamplesDe._(_root);
}

// Path: docs.components.item_picker
class _TranslationsDocsComponentsItemPickerDe extends TranslationsDocsComponentsItemPickerKo {
	_TranslationsDocsComponentsItemPickerDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Artikelwähler';
	@override String get description => 'Eine Komponente, um Artikel aus einer Liste auszuwählen.';
	@override late final _TranslationsDocsComponentsItemPickerExamplesDe examples = _TranslationsDocsComponentsItemPickerExamplesDe._(_root);
}

// Path: docs.components.keyboard_display
class _TranslationsDocsComponentsKeyboardDisplayDe extends TranslationsDocsComponentsKeyboardDisplayKo {
	_TranslationsDocsComponentsKeyboardDisplayDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tastatur anzeigen';
	@override String get description => 'Eine Komponente zur Anzeige von Tastenkombinationen.';
	@override late final _TranslationsDocsComponentsKeyboardDisplayExamplesDe examples = _TranslationsDocsComponentsKeyboardDisplayExamplesDe._(_root);
}

// Path: docs.components.linear_progress
class _TranslationsDocsComponentsLinearProgressDe extends TranslationsDocsComponentsLinearProgressKo {
	_TranslationsDocsComponentsLinearProgressDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Linearer Fortschritt';
	@override String get description => 'Ein linearer Fortschrittsindikator.';
	@override late final _TranslationsDocsComponentsLinearProgressExamplesDe examples = _TranslationsDocsComponentsLinearProgressExamplesDe._(_root);
	@override String get increase => 'Erhöhen';
	@override String get decrease => 'Verringern';
}

// Path: docs.components.material
class _TranslationsDocsComponentsMaterialDe extends TranslationsDocsComponentsMaterialKo {
	_TranslationsDocsComponentsMaterialDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Material/Cupertino';
	@override String get description => 'So verwenden Sie die Standard Material- und Cupertino-Widgets von Flutter.';
	@override late final _TranslationsDocsComponentsMaterialExamplesDe examples = _TranslationsDocsComponentsMaterialExamplesDe._(_root);
	@override String get my_material_app => 'Meine Material-App';
	@override String get my_cupertino_app => 'Meine Cupertino-App';
	@override String you_pushed_button({required Object count}) => 'Sie haben die Schaltfläche ${count} mal gedrückt.';
	@override String get open_material_dialog => 'Material-Dialog öffnen';
	@override String get open_cupertino_dialog => 'Cupertino-Dialog öffnen';
	@override String get open_coui_dialog => 'COUI-Dialog öffnen';
}

// Path: docs.components.menubar
class _TranslationsDocsComponentsMenubarDe extends TranslationsDocsComponentsMenubarKo {
	_TranslationsDocsComponentsMenubarDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Menüleiste';
	@override String get description => 'Eine horizontale Menüleiste.';
	@override late final _TranslationsDocsComponentsMenubarExamplesDe examples = _TranslationsDocsComponentsMenubarExamplesDe._(_root);
	@override String get file => 'Datei';
	@override String get edit => 'Bearbeiten';
	@override String get new_tab => 'Neuer Tab';
	@override String get new_window => 'Neues Fenster';
	@override String get new_incognito_window => 'Neues Inkognito-Fenster';
	@override String get email_link => 'E-Mail-Link';
	@override String get messages => 'Nachrichten';
	@override String get notes => 'Notizen';
	@override String get share => 'Teilen';
	@override String get print => 'Drucken';
	@override String get save_and_exit => 'Speichern und Beenden';
	@override String get discard_and_exit => 'Verwerfen und Beenden';
	@override String get exit => 'Beenden';
	@override String get undo => 'Rückgängig machen';
	@override String get redo => 'Wiederherstellen';
}

// Path: docs.components.multiselect
class _TranslationsDocsComponentsMultiselectDe extends TranslationsDocsComponentsMultiselectKo {
	_TranslationsDocsComponentsMultiselectDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Mehrfachauswahl';
	@override String get description => 'Eine Komponente zur Auswahl mehrerer Artikel.';
	@override late final _TranslationsDocsComponentsMultiselectExamplesDe examples = _TranslationsDocsComponentsMultiselectExamplesDe._(_root);
}

// Path: docs.components.navigation_bar
class _TranslationsDocsComponentsNavigationBarDe extends TranslationsDocsComponentsNavigationBarKo {
	_TranslationsDocsComponentsNavigationBarDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Navigationsleiste';
	@override String get description => 'Eine untere Navigationsleiste.';
	@override late final _TranslationsDocsComponentsNavigationBarExamplesDe examples = _TranslationsDocsComponentsNavigationBarExamplesDe._(_root);
}

// Path: docs.components.navigation_menu
class _TranslationsDocsComponentsNavigationMenuDe extends TranslationsDocsComponentsNavigationMenuKo {
	_TranslationsDocsComponentsNavigationMenuDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Navigationsmenü';
	@override String get description => 'Eine Navigationsmenü-Komponente.';
	@override late final _TranslationsDocsComponentsNavigationMenuExamplesDe examples = _TranslationsDocsComponentsNavigationMenuExamplesDe._(_root);
}

// Path: docs.components.navigation_rail
class _TranslationsDocsComponentsNavigationRailDe extends TranslationsDocsComponentsNavigationRailKo {
	_TranslationsDocsComponentsNavigationRailDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Navigationsschiene';
	@override String get description => 'Eine seitliche Navigationsschiene.';
	@override late final _TranslationsDocsComponentsNavigationRailExamplesDe examples = _TranslationsDocsComponentsNavigationRailExamplesDe._(_root);
}

// Path: docs.components.navigation_sidebar
class _TranslationsDocsComponentsNavigationSidebarDe extends TranslationsDocsComponentsNavigationSidebarKo {
	_TranslationsDocsComponentsNavigationSidebarDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Navigationssidebar';
	@override String get description => 'Eine Navigationssidebar-Komponente.';
	@override late final _TranslationsDocsComponentsNavigationSidebarExamplesDe examples = _TranslationsDocsComponentsNavigationSidebarExamplesDe._(_root);
}

// Path: docs.components.number_input
class _TranslationsDocsComponentsNumberInputDe extends TranslationsDocsComponentsNumberInputKo {
	_TranslationsDocsComponentsNumberInputDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Zahleneingabe';
	@override String get description => 'Ein Feld zur Eingabe von Zahlen.';
	@override late final _TranslationsDocsComponentsNumberInputExamplesDe examples = _TranslationsDocsComponentsNumberInputExamplesDe._(_root);
	@override String value({required Object value}) => 'Wert: ${value}';
}

// Path: docs.components.number_ticker
class _TranslationsDocsComponentsNumberTickerDe extends TranslationsDocsComponentsNumberTickerKo {
	_TranslationsDocsComponentsNumberTickerDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Zahlenticker';
	@override String get description => 'Zeigt die Animation, wenn sich die Zahl ändert.';
	@override late final _TranslationsDocsComponentsNumberTickerExamplesDe examples = _TranslationsDocsComponentsNumberTickerExamplesDe._(_root);
}

// Path: docs.components.overflow_marquee
class _TranslationsDocsComponentsOverflowMarqueeDe extends TranslationsDocsComponentsOverflowMarqueeKo {
	_TranslationsDocsComponentsOverflowMarqueeDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Überlaufmarquee';
	@override String get description => 'Automatisches Scrollen, wenn der Text überläuft.';
	@override late final _TranslationsDocsComponentsOverflowMarqueeExamplesDe examples = _TranslationsDocsComponentsOverflowMarqueeExamplesDe._(_root);
}

// Path: docs.components.pagination
class _TranslationsDocsComponentsPaginationDe extends TranslationsDocsComponentsPaginationKo {
	_TranslationsDocsComponentsPaginationDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Seitenzahl';
	@override String get description => 'Eine Komponente zur Navigation durch Seiten.';
	@override late final _TranslationsDocsComponentsPaginationExamplesDe examples = _TranslationsDocsComponentsPaginationExamplesDe._(_root);
}

// Path: docs.components.phone_input
class _TranslationsDocsComponentsPhoneInputDe extends TranslationsDocsComponentsPhoneInputKo {
	_TranslationsDocsComponentsPhoneInputDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Telefonnummerneingabe';
	@override String get description => 'Ein Feld zur Eingabe einer Telefonnummer.';
	@override late final _TranslationsDocsComponentsPhoneInputExamplesDe examples = _TranslationsDocsComponentsPhoneInputExamplesDe._(_root);
}

// Path: docs.components.popover
class _TranslationsDocsComponentsPopoverDe extends TranslationsDocsComponentsPopoverKo {
	_TranslationsDocsComponentsPopoverDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Popover';
	@override String get description => 'Ein Popup, das über einem Element angezeigt wird.';
	@override late final _TranslationsDocsComponentsPopoverExamplesDe examples = _TranslationsDocsComponentsPopoverExamplesDe._(_root);
	@override String get dimensions => 'Dimensionen';
	@override String get set_dimensions => 'Legen Sie die Größe der Schicht fest';
	@override String get width => 'Breite';
	@override String get max_width => 'Maximale Breite';
	@override String get height => 'Höhe';
	@override String get max_height => 'Maximale Höhe';
	@override String get open_popover => 'Popover öffnen';
	@override String get submit => 'Einreichen';
}

// Path: docs.components.progress
class _TranslationsDocsComponentsProgressDe extends TranslationsDocsComponentsProgressKo {
	_TranslationsDocsComponentsProgressDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Fortschritt';
	@override String get description => 'Zeigt den Fortschritt an.';
	@override late final _TranslationsDocsComponentsProgressExamplesDe examples = _TranslationsDocsComponentsProgressExamplesDe._(_root);
}

// Path: docs.components.radio_card
class _TranslationsDocsComponentsRadioCardDe extends TranslationsDocsComponentsRadioCardKo {
	_TranslationsDocsComponentsRadioCardDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Radio-Karte';
	@override String get description => 'Ein Radio-Button im Kartenformat.';
	@override late final _TranslationsDocsComponentsRadioCardExamplesDe examples = _TranslationsDocsComponentsRadioCardExamplesDe._(_root);
}

// Path: docs.components.radio_group
class _TranslationsDocsComponentsRadioGroupDe extends TranslationsDocsComponentsRadioGroupKo {
	_TranslationsDocsComponentsRadioGroupDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Radiogruppe';
	@override String get description => 'Eine Gruppe von Radio-Buttons.';
	@override late final _TranslationsDocsComponentsRadioGroupExamplesDe examples = _TranslationsDocsComponentsRadioGroupExamplesDe._(_root);
	@override String get option_1 => 'Option 1';
	@override String get option_2 => 'Option 2';
	@override String get option_3 => 'Option 3';
	@override String get selected => 'Ausgewählt';
}

// Path: docs.components.refresh_trigger
class _TranslationsDocsComponentsRefreshTriggerDe extends TranslationsDocsComponentsRefreshTriggerKo {
	_TranslationsDocsComponentsRefreshTriggerDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Aktualisierungs-Trigger';
	@override String get description => 'Bietet die Möglichkeit, durch Ziehen zu aktualisieren.';
	@override late final _TranslationsDocsComponentsRefreshTriggerExamplesDe examples = _TranslationsDocsComponentsRefreshTriggerExamplesDe._(_root);
	@override String get pull_me => 'Ziehen Sie mich';
	@override String get refresh => 'Aktualisieren';
}

// Path: docs.components.repeated_animation_builder
class _TranslationsDocsComponentsRepeatedAnimationBuilderDe extends TranslationsDocsComponentsRepeatedAnimationBuilderKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Wiederholter Animations-Builder';
	@override String get description => 'Ein Builder, der Animationen wiederholt.';
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesDe examples = _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesDe._(_root);
}

// Path: docs.components.resizable
class _TranslationsDocsComponentsResizableDe extends TranslationsDocsComponentsResizableKo {
	_TranslationsDocsComponentsResizableDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Größenanpassbar';
	@override String get description => 'Ein Container, der skaliert werden kann.';
	@override late final _TranslationsDocsComponentsResizableExamplesDe examples = _TranslationsDocsComponentsResizableExamplesDe._(_root);
}

// Path: docs.components.scaffold
class _TranslationsDocsComponentsScaffoldDe extends TranslationsDocsComponentsScaffoldKo {
	_TranslationsDocsComponentsScaffoldDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Gerüst';
	@override String get description => 'Das Gerüst ist der oberste Container einer Seite.';
	@override late final _TranslationsDocsComponentsScaffoldExamplesDe examples = _TranslationsDocsComponentsScaffoldExamplesDe._(_root);
}

// Path: docs.components.select
class _TranslationsDocsComponentsSelectDe extends TranslationsDocsComponentsSelectKo {
	_TranslationsDocsComponentsSelectDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Auswahl';
	@override String get description => 'Wählen Sie ein Element aus einer Liste von Optionen.';
	@override late final _TranslationsDocsComponentsSelectExamplesDe examples = _TranslationsDocsComponentsSelectExamplesDe._(_root);
	@override String get placeholder => 'Wählen Sie ein Obst';
	@override String get search_fruit => 'Obst suchen';
	@override String get no_fruit_found => 'Kein Obst gefunden.';
	@override String get apple => 'Apfel';
	@override String get banana => 'Banane';
	@override String get cherry => 'Kirsche';
	@override String get lemon => 'Zitrone';
	@override String get tomato => 'Tomate';
	@override String get red_apple => 'Roter Apfel';
	@override String get green_apple => 'Grüner Apfel';
	@override String get yellow_banana => 'Gelbe Banane';
	@override String get brown_banana => 'Braune Banane';
	@override String get yellow_lemon => 'Gelbe Zitrone';
	@override String get green_lemon => 'Grüne Zitrone';
	@override String get red => 'Rot';
	@override String get green => 'Grün';
	@override String get yellow => 'Gelb';
	@override String get brown => 'Braun';
}

// Path: docs.components.sheet
class _TranslationsDocsComponentsSheetDe extends TranslationsDocsComponentsSheetKo {
	_TranslationsDocsComponentsSheetDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Blatt';
	@override String get description => 'Ein Blatt, das von unten hochkommt.';
	@override late final _TranslationsDocsComponentsSheetExamplesDe examples = _TranslationsDocsComponentsSheetExamplesDe._(_root);
}

// Path: docs.components.skeleton
class _TranslationsDocsComponentsSkeletonDe extends TranslationsDocsComponentsSkeletonKo {
	_TranslationsDocsComponentsSkeletonDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Skeleton';
	@override String get description => 'Der Skeleton-Screen, der während des Ladens angezeigt wird.';
	@override late final _TranslationsDocsComponentsSkeletonExamplesDe examples = _TranslationsDocsComponentsSkeletonExamplesDe._(_root);
}

// Path: docs.components.slider
class _TranslationsDocsComponentsSliderDe extends TranslationsDocsComponentsSliderKo {
	_TranslationsDocsComponentsSliderDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Slider';
	@override String get description => 'Ermöglicht die Auswahl eines Wertes durch Schieben.';
	@override late final _TranslationsDocsComponentsSliderExamplesDe examples = _TranslationsDocsComponentsSliderExamplesDe._(_root);
	@override String value_single({required Object value}) => 'Wert: ${value}';
	@override String value_range({required Object start, required Object end}) => 'Wert: ${start} - ${end}';
}

// Path: docs.components.sortable
class _TranslationsDocsComponentsSortableDe extends TranslationsDocsComponentsSortableKo {
	_TranslationsDocsComponentsSortableDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Sortierbar';
	@override String get description => 'Ermöglicht das Sortieren von Elementen durch Ziehen.';
	@override late final _TranslationsDocsComponentsSortableExamplesDe examples = _TranslationsDocsComponentsSortableExamplesDe._(_root);
}

// Path: docs.components.star_rating
class _TranslationsDocsComponentsStarRatingDe extends TranslationsDocsComponentsStarRatingKo {
	_TranslationsDocsComponentsStarRatingDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Sternbewertung';
	@override String get description => 'Ermöglicht die Auswahl einer Bewertung in Sternen.';
	@override late final _TranslationsDocsComponentsStarRatingExamplesDe examples = _TranslationsDocsComponentsStarRatingExamplesDe._(_root);
}

// Path: docs.components.stepper
class _TranslationsDocsComponentsStepperDe extends TranslationsDocsComponentsStepperKo {
	_TranslationsDocsComponentsStepperDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Stepper';
	@override String get description => 'Zeigt einen schrittweisen Prozess an.';
	@override late final _TranslationsDocsComponentsStepperExamplesDe examples = _TranslationsDocsComponentsStepperExamplesDe._(_root);
	@override String get step_1 => 'Schritt 1';
	@override String get step_2 => 'Schritt 2';
	@override String get step_3 => 'Schritt 3';
	@override String step_n({required Object n}) => 'Schritt ${n}';
	@override String get optional_step => 'Optionaler Schritt';
	@override String get horizontal => 'Horizontal';
	@override String get vertical => 'Vertikal';
	@override String get toggle_error => 'Fehler umschalten';
	@override String get circle => 'Kreis';
	@override String get circle_alt => 'Kreis Alternative';
	@override String get line => 'Linie';
	@override String get small => 'Klein';
	@override String get medium => 'Mittel';
	@override String get large => 'Groß';
}

// Path: docs.components.steps
class _TranslationsDocsComponentsStepsDe extends TranslationsDocsComponentsStepsKo {
	_TranslationsDocsComponentsStepsDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Schritte';
	@override String get description => 'Zeigt den Fortschritt in Schritten an.';
	@override late final _TranslationsDocsComponentsStepsExamplesDe examples = _TranslationsDocsComponentsStepsExamplesDe._(_root);
}

// Path: docs.components.swiper
class _TranslationsDocsComponentsSwiperDe extends TranslationsDocsComponentsSwiperKo {
	_TranslationsDocsComponentsSwiperDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Swiper';
	@override String get description => 'Eine wischbare Komponente.';
	@override late final _TranslationsDocsComponentsSwiperExamplesDe examples = _TranslationsDocsComponentsSwiperExamplesDe._(_root);
}

// Path: docs.components.k_switch
class _TranslationsDocsComponentsKSwitchDe extends TranslationsDocsComponentsKSwitchKo {
	_TranslationsDocsComponentsKSwitchDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Schalter';
	@override String get description => 'Ein Ein/Aus-Schalter.';
	@override late final _TranslationsDocsComponentsKSwitchExamplesDe examples = _TranslationsDocsComponentsKSwitchExamplesDe._(_root);
}

// Path: docs.components.switcher
class _TranslationsDocsComponentsSwitcherDe extends TranslationsDocsComponentsSwitcherKo {
	_TranslationsDocsComponentsSwitcherDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Wechsler';
	@override String get description => 'Wechselt zwischen mehreren Ansichten.';
	@override late final _TranslationsDocsComponentsSwitcherExamplesDe examples = _TranslationsDocsComponentsSwitcherExamplesDe._(_root);
	@override String get switch_direction => 'Richtung wechseln';
	@override String get next_item => 'Nächstes Element';
}

// Path: docs.components.tab_list
class _TranslationsDocsComponentsTabListDe extends TranslationsDocsComponentsTabListKo {
	_TranslationsDocsComponentsTabListDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tab-Liste';
	@override String get description => 'Eine Tab-Liste-Komponente.';
	@override late final _TranslationsDocsComponentsTabListExamplesDe examples = _TranslationsDocsComponentsTabListExamplesDe._(_root);
}

// Path: docs.components.tab_pane
class _TranslationsDocsComponentsTabPaneDe extends TranslationsDocsComponentsTabPaneKo {
	_TranslationsDocsComponentsTabPaneDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tab-Panel';
	@override String get description => 'Eine Tab-Panel-Komponente.';
	@override late final _TranslationsDocsComponentsTabPaneExamplesDe examples = _TranslationsDocsComponentsTabPaneExamplesDe._(_root);
}

// Path: docs.components.table
class _TranslationsDocsComponentsTableDe extends TranslationsDocsComponentsTableKo {
	_TranslationsDocsComponentsTableDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tabelle';
	@override String get description => 'Zeigt Daten in Tabellenform an.';
	@override late final _TranslationsDocsComponentsTableExamplesDe examples = _TranslationsDocsComponentsTableExamplesDe._(_root);
	@override String get invoice => 'Rechnung';
	@override String get status => 'Status';
	@override String get method => 'Methode';
	@override String get amount => 'Betrag';
	@override String get total => 'Gesamt';
	@override String get paid => 'Bezahlt';
	@override String get pending => 'Ausstehend';
	@override String get unpaid => 'Unbezahlt';
	@override String get credit_card => 'Kreditkarte';
	@override String get paypal => 'PayPal';
	@override String get bank_transfer => 'Banküberweisung';
}

// Path: docs.components.tabs
class _TranslationsDocsComponentsTabsDe extends TranslationsDocsComponentsTabsKo {
	_TranslationsDocsComponentsTabsDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tabs';
	@override String get description => 'Verwendet Tabs zur Organisation von Inhalten.';
	@override late final _TranslationsDocsComponentsTabsExamplesDe examples = _TranslationsDocsComponentsTabsExamplesDe._(_root);
	@override String get tab_1 => 'Tab 1';
	@override String get tab_2 => 'Tab 2';
	@override String get tab_3 => 'Tab 3';
	@override String tab_n({required Object n}) => 'Tab ${n}';
}

// Path: docs.components.text_area
class _TranslationsDocsComponentsTextAreaDe extends TranslationsDocsComponentsTextAreaKo {
	_TranslationsDocsComponentsTextAreaDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Textbereich';
	@override String get description => 'Erlaubt die Eingabe von mehreren Zeilen Text.';
	@override late final _TranslationsDocsComponentsTextAreaExamplesDe examples = _TranslationsDocsComponentsTextAreaExamplesDe._(_root);
	@override String get hello_world => 'Hallo, Welt!';
}

// Path: docs.components.time_picker
class _TranslationsDocsComponentsTimePickerDe extends TranslationsDocsComponentsTimePickerKo {
	_TranslationsDocsComponentsTimePickerDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Uhrzeitauswahl';
	@override String get description => 'Ermöglicht die Auswahl einer Uhrzeit.';
	@override late final _TranslationsDocsComponentsTimePickerExamplesDe examples = _TranslationsDocsComponentsTimePickerExamplesDe._(_root);
	@override String get select_time => 'Uhrzeit auswählen';
}

// Path: docs.components.timeline
class _TranslationsDocsComponentsTimelineDe extends TranslationsDocsComponentsTimelineKo {
	_TranslationsDocsComponentsTimelineDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Zeitlinie';
	@override String get description => 'Zeigt Ereignisse in einer Zeitlinie an.';
	@override late final _TranslationsDocsComponentsTimelineExamplesDe examples = _TranslationsDocsComponentsTimelineExamplesDe._(_root);
}

// Path: docs.components.timeline_animation
class _TranslationsDocsComponentsTimelineAnimationDe extends TranslationsDocsComponentsTimelineAnimationKo {
	_TranslationsDocsComponentsTimelineAnimationDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Zeitlinienanimation';
	@override String get description => 'Eine zeitlinienbasierte Animation.';
	@override late final _TranslationsDocsComponentsTimelineAnimationExamplesDe examples = _TranslationsDocsComponentsTimelineAnimationExamplesDe._(_root);
}

// Path: docs.components.toast
class _TranslationsDocsComponentsToastDe extends TranslationsDocsComponentsToastKo {
	_TranslationsDocsComponentsToastDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Toast';
	@override String get description => 'Eine Benachrichtigung, die eine kurze Nachricht anzeigt.';
	@override late final _TranslationsDocsComponentsToastExamplesDe examples = _TranslationsDocsComponentsToastExamplesDe._(_root);
	@override String get event_created => 'Ereignis wurde erstellt';
	@override String get event_date => 'Sonntag, 7. Juli 2024, 12:00 Uhr';
	@override String get show_bottom_left => 'Toast in der unteren linken Ecke anzeigen';
	@override String get show_bottom_right => 'Toast in der unteren rechten Ecke anzeigen';
	@override String get show_top_left => 'Toast in der oberen linken Ecke anzeigen';
	@override String get show_top_right => 'Toast in der oberen rechten Ecke anzeigen';
	@override String get show_bottom_center => 'Toast in der unteren Mitte anzeigen';
	@override String get show_top_center => 'Toast in der oberen Mitte anzeigen';
}

// Path: docs.components.toggle
class _TranslationsDocsComponentsToggleDe extends TranslationsDocsComponentsToggleKo {
	_TranslationsDocsComponentsToggleDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Toggle';
	@override String get description => 'Erlaubt das Umschalten zwischen Optionen.';
	@override late final _TranslationsDocsComponentsToggleExamplesDe examples = _TranslationsDocsComponentsToggleExamplesDe._(_root);
	@override String get toggle => 'Umschalten';
}

// Path: docs.components.tooltip
class _TranslationsDocsComponentsTooltipDe extends TranslationsDocsComponentsTooltipKo {
	_TranslationsDocsComponentsTooltipDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tooltip';
	@override String get description => 'Zeigt zusätzliche Informationen zu einem Element an.';
	@override late final _TranslationsDocsComponentsTooltipExamplesDe examples = _TranslationsDocsComponentsTooltipExamplesDe._(_root);
	@override String get this_is_tooltip => 'Das ist ein Tooltip.';
	@override String get hover_over_me => 'Über mich fahren';
}

// Path: docs.components.tracker
class _TranslationsDocsComponentsTrackerDe extends TranslationsDocsComponentsTrackerKo {
	_TranslationsDocsComponentsTrackerDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tracker';
	@override String get description => 'Verfolgt den Fortschritt.';
	@override late final _TranslationsDocsComponentsTrackerExamplesDe examples = _TranslationsDocsComponentsTrackerExamplesDe._(_root);
	@override String get fine => 'Gut';
	@override String get warning => 'Warnung';
	@override String get critical => 'Kritisch';
	@override String get unknown => 'Unbekannt';
	@override String get tracker_fine => 'Tracker gut';
	@override String get tracker_warning => 'Tracker Warnung';
	@override String get tracker_critical => 'Tracker kritisch';
	@override String get tracker_unknown => 'Tracker unbekannt';
}

// Path: docs.components.tree
class _TranslationsDocsComponentsTreeDe extends TranslationsDocsComponentsTreeKo {
	_TranslationsDocsComponentsTreeDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Baum';
	@override String get description => 'Zeigt hierarchische Daten in Form eines Baumes an.';
	@override late final _TranslationsDocsComponentsTreeExamplesDe examples = _TranslationsDocsComponentsTreeExamplesDe._(_root);
}

// Path: docs.components.window
class _TranslationsDocsComponentsWindowDe extends TranslationsDocsComponentsWindowKo {
	_TranslationsDocsComponentsWindowDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Fenster';
	@override String get description => 'Ein Desktop-Stil Fenster.';
	@override late final _TranslationsDocsComponentsWindowExamplesDe examples = _TranslationsDocsComponentsWindowExamplesDe._(_root);
	@override String get window_1 => 'Fenster 1';
	@override String get window_2 => 'Fenster 2';
	@override String get desktop => 'Desktop';
	@override String get add_window => 'Fenster hinzufügen';
}

// Path: docs.pages.introduction.features_list
class _TranslationsDocsPagesIntroductionFeaturesListDe extends TranslationsDocsPagesIntroductionFeaturesListKo {
	_TranslationsDocsPagesIntroductionFeaturesListDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get components_count => '84 Komponenten und es werden immer mehr!';
	@override String get material_cupertino => 'Unterstützung von Material- und Cupertino-Widgets, wobei das Thema an das aktuelle coui_flutter-Thema angepasst wird.';
	@override String get premade_themes => 'Vorgefertigte Themen von Coui/UI.';
	@override String get platform_support => 'Unterstützung für mobile, Web- und Desktop-Plattformen.';
	@override String get middle_drag => 'Unterstützung für mittles Drag-Scrollen.';
	@override String get typography_extensions => 'Verschiedene Widget-Erweiterungen für Typografie.';
	@override String get webassembly => 'WebAssembly-Unterstützung für bessere Leistung.';
}

// Path: docs.components.accordion.examples
class _TranslationsDocsComponentsAccordionExamplesDe extends TranslationsDocsComponentsAccordionExamplesKo {
	_TranslationsDocsComponentsAccordionExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Accordion-Beispiel';
}

// Path: docs.components.alert.examples
class _TranslationsDocsComponentsAlertExamplesDe extends TranslationsDocsComponentsAlertExamplesKo {
	_TranslationsDocsComponentsAlertExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Benachrichtigung Beispiel';
	@override String get destructive => 'Gefährliche Benachrichtigung Beispiel';
}

// Path: docs.components.alert_dialog.examples
class _TranslationsDocsComponentsAlertDialogExamplesDe extends TranslationsDocsComponentsAlertDialogExamplesKo {
	_TranslationsDocsComponentsAlertDialogExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Benachrichtigungsdialog Beispiel';
}

// Path: docs.components.animated_value_builder.examples
class _TranslationsDocsComponentsAnimatedValueBuilderExamplesDe extends TranslationsDocsComponentsAnimatedValueBuilderExamplesKo {
	_TranslationsDocsComponentsAnimatedValueBuilderExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Animierter Wert-Builder Beispiel';
}

// Path: docs.components.app_bar.examples
class _TranslationsDocsComponentsAppBarExamplesDe extends TranslationsDocsComponentsAppBarExamplesKo {
	_TranslationsDocsComponentsAppBarExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'App-Leiste Beispiel';
}

// Path: docs.components.autocomplete.examples
class _TranslationsDocsComponentsAutocompleteExamplesDe extends TranslationsDocsComponentsAutocompleteExamplesKo {
	_TranslationsDocsComponentsAutocompleteExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Autocomplete Beispiel';
}

// Path: docs.components.avatar.examples
class _TranslationsDocsComponentsAvatarExamplesDe extends TranslationsDocsComponentsAvatarExamplesKo {
	_TranslationsDocsComponentsAvatarExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Avatar Beispiel';
}

// Path: docs.components.avatar_group.examples
class _TranslationsDocsComponentsAvatarGroupExamplesDe extends TranslationsDocsComponentsAvatarGroupExamplesKo {
	_TranslationsDocsComponentsAvatarGroupExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Avatar-Gruppe Beispiel';
}

// Path: docs.components.badge.examples
class _TranslationsDocsComponentsBadgeExamplesDe extends TranslationsDocsComponentsBadgeExamplesKo {
	_TranslationsDocsComponentsBadgeExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Badge Beispiel';
}

// Path: docs.components.breadcrumb.examples
class _TranslationsDocsComponentsBreadcrumbExamplesDe extends TranslationsDocsComponentsBreadcrumbExamplesKo {
	_TranslationsDocsComponentsBreadcrumbExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Brotkrumen Beispiel';
}

// Path: docs.components.button.examples
class _TranslationsDocsComponentsButtonExamplesDe extends TranslationsDocsComponentsButtonExamplesKo {
	_TranslationsDocsComponentsButtonExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get primary => 'Primär-Schaltflächen Beispiel';
	@override String get secondary => 'Sekundär-Schaltflächen Beispiel';
	@override String get outline => 'Umriss-Schaltflächen Beispiel';
	@override String get ghost => 'Ghost-Schaltflächen Beispiel';
	@override String get destructive => 'Zerstörerische Schaltflächen Beispiel';
	@override String get link => 'Link-Schaltflächen Beispiel';
	@override String get text => 'Text-Schaltflächen Beispiel';
	@override String get disabled => 'Deaktivierte Schaltflächen Beispiel';
	@override String get icon => 'Icon-Schaltflächen Beispiel';
	@override String get icon_with_label => 'Icon-Schaltflächen mit Label Beispiel';
	@override String get size => 'Schaltflächen-Größe Beispiel';
	@override String get density => 'Schaltflächen-Dichte Beispiel';
	@override String get shape => 'Schaltflächen-Form Beispiel';
	@override String get group => 'Schaltflächen-Gruppe Beispiel';
	@override String get stated => 'Zustands-Schaltflächen Beispiel';
	@override String get card => 'Karten-Schaltflächen Beispiel';
	@override String get custom => 'Benutzerdefinierte Schaltflächen Beispiel';
}

// Path: docs.components.calendar.examples
class _TranslationsDocsComponentsCalendarExamplesDe extends TranslationsDocsComponentsCalendarExamplesKo {
	_TranslationsDocsComponentsCalendarExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Kalender Beispiel';
}

// Path: docs.components.card.examples
class _TranslationsDocsComponentsCardExamplesDe extends TranslationsDocsComponentsCardExamplesKo {
	_TranslationsDocsComponentsCardExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Karten Beispiel';
}

// Path: docs.components.card_image.examples
class _TranslationsDocsComponentsCardImageExamplesDe extends TranslationsDocsComponentsCardImageExamplesKo {
	_TranslationsDocsComponentsCardImageExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Bildkarte Beispiel';
}

// Path: docs.components.carousel.examples
class _TranslationsDocsComponentsCarouselExamplesDe extends TranslationsDocsComponentsCarouselExamplesKo {
	_TranslationsDocsComponentsCarouselExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Karussell Beispiel';
}

// Path: docs.components.checkbox.examples
class _TranslationsDocsComponentsCheckboxExamplesDe extends TranslationsDocsComponentsCheckboxExamplesKo {
	_TranslationsDocsComponentsCheckboxExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Checkbox Beispiel';
}

// Path: docs.components.chip.examples
class _TranslationsDocsComponentsChipExamplesDe extends TranslationsDocsComponentsChipExamplesKo {
	_TranslationsDocsComponentsChipExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Chip Beispiel';
}

// Path: docs.components.chip_input.examples
class _TranslationsDocsComponentsChipInputExamplesDe extends TranslationsDocsComponentsChipInputExamplesKo {
	_TranslationsDocsComponentsChipInputExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Chip-Eingabe Beispiel';
}

// Path: docs.components.circular_progress.examples
class _TranslationsDocsComponentsCircularProgressExamplesDe extends TranslationsDocsComponentsCircularProgressExamplesKo {
	_TranslationsDocsComponentsCircularProgressExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Kreisfortschritt Beispiel';
}

// Path: docs.components.code_snippet.examples
class _TranslationsDocsComponentsCodeSnippetExamplesDe extends TranslationsDocsComponentsCodeSnippetExamplesKo {
	_TranslationsDocsComponentsCodeSnippetExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Code-Snippet Beispiel';
}

// Path: docs.components.collapsible.examples
class _TranslationsDocsComponentsCollapsibleExamplesDe extends TranslationsDocsComponentsCollapsibleExamplesKo {
	_TranslationsDocsComponentsCollapsibleExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Zusammenklappbarer Beispiel';
}

// Path: docs.components.color_picker.examples
class _TranslationsDocsComponentsColorPickerExamplesDe extends TranslationsDocsComponentsColorPickerExamplesKo {
	_TranslationsDocsComponentsColorPickerExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Farbwähler Beispiel';
}

// Path: docs.components.command.examples
class _TranslationsDocsComponentsCommandExamplesDe extends TranslationsDocsComponentsCommandExamplesKo {
	_TranslationsDocsComponentsCommandExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Befehl Beispiel';
}

// Path: docs.components.context_menu.examples
class _TranslationsDocsComponentsContextMenuExamplesDe extends TranslationsDocsComponentsContextMenuExamplesKo {
	_TranslationsDocsComponentsContextMenuExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Kontextmenü Beispiel';
}

// Path: docs.components.date_picker.examples
class _TranslationsDocsComponentsDatePickerExamplesDe extends TranslationsDocsComponentsDatePickerExamplesKo {
	_TranslationsDocsComponentsDatePickerExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Datumswähler Beispiel';
}

// Path: docs.components.dialog.examples
class _TranslationsDocsComponentsDialogExamplesDe extends TranslationsDocsComponentsDialogExamplesKo {
	_TranslationsDocsComponentsDialogExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Dialog Beispiel';
}

// Path: docs.components.divider.examples
class _TranslationsDocsComponentsDividerExamplesDe extends TranslationsDocsComponentsDividerExamplesKo {
	_TranslationsDocsComponentsDividerExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Trennlinie Beispiel';
}

// Path: docs.components.dot_indicator.examples
class _TranslationsDocsComponentsDotIndicatorExamplesDe extends TranslationsDocsComponentsDotIndicatorExamplesKo {
	_TranslationsDocsComponentsDotIndicatorExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Punktindikator Beispiel';
}

// Path: docs.components.drawer.examples
class _TranslationsDocsComponentsDrawerExamplesDe extends TranslationsDocsComponentsDrawerExamplesKo {
	_TranslationsDocsComponentsDrawerExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Schublade Beispiel';
}

// Path: docs.components.dropdown_menu.examples
class _TranslationsDocsComponentsDropdownMenuExamplesDe extends TranslationsDocsComponentsDropdownMenuExamplesKo {
	_TranslationsDocsComponentsDropdownMenuExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Dropdown-Menü Beispiel';
}

// Path: docs.components.expandable_sidebar.examples
class _TranslationsDocsComponentsExpandableSidebarExamplesDe extends TranslationsDocsComponentsExpandableSidebarExamplesKo {
	_TranslationsDocsComponentsExpandableSidebarExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Erweiterbare Sidebar Beispiel';
}

// Path: docs.components.form.examples
class _TranslationsDocsComponentsFormExamplesDe extends TranslationsDocsComponentsFormExamplesKo {
	_TranslationsDocsComponentsFormExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get table_layout => 'Formular Beispiel (Tabellenlayout)';
	@override String get column_layout => 'Formular Beispiel (Spaltenlayout)';
	@override String get validation_mode => 'Beispiel für Validierungsmodus';
}

// Path: docs.components.formatted_input.examples
class _TranslationsDocsComponentsFormattedInputExamplesDe extends TranslationsDocsComponentsFormattedInputExamplesKo {
	_TranslationsDocsComponentsFormattedInputExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Formatierte Eingabe Beispiel';
}

// Path: docs.components.hover_card.examples
class _TranslationsDocsComponentsHoverCardExamplesDe extends TranslationsDocsComponentsHoverCardExamplesKo {
	_TranslationsDocsComponentsHoverCardExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Hover-Karte Beispiel';
}

// Path: docs.components.input.examples
class _TranslationsDocsComponentsInputExamplesDe extends TranslationsDocsComponentsInputExamplesKo {
	_TranslationsDocsComponentsInputExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Eingabe Beispiel';
}

// Path: docs.components.input_otp.examples
class _TranslationsDocsComponentsInputOtpExamplesDe extends TranslationsDocsComponentsInputOtpExamplesKo {
	_TranslationsDocsComponentsInputOtpExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'OTP-Eingabe Beispiel';
}

// Path: docs.components.item_picker.examples
class _TranslationsDocsComponentsItemPickerExamplesDe extends TranslationsDocsComponentsItemPickerExamplesKo {
	_TranslationsDocsComponentsItemPickerExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Artikelwähler Beispiel';
}

// Path: docs.components.keyboard_display.examples
class _TranslationsDocsComponentsKeyboardDisplayExamplesDe extends TranslationsDocsComponentsKeyboardDisplayExamplesKo {
	_TranslationsDocsComponentsKeyboardDisplayExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Tastatur anzeigen Beispiel';
}

// Path: docs.components.linear_progress.examples
class _TranslationsDocsComponentsLinearProgressExamplesDe extends TranslationsDocsComponentsLinearProgressExamplesKo {
	_TranslationsDocsComponentsLinearProgressExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Linearer Fortschritt Beispiel';
}

// Path: docs.components.material.examples
class _TranslationsDocsComponentsMaterialExamplesDe extends TranslationsDocsComponentsMaterialExamplesKo {
	_TranslationsDocsComponentsMaterialExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Material/Cupertino Beispiel';
}

// Path: docs.components.menubar.examples
class _TranslationsDocsComponentsMenubarExamplesDe extends TranslationsDocsComponentsMenubarExamplesKo {
	_TranslationsDocsComponentsMenubarExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Menüleiste Beispiel';
}

// Path: docs.components.multiselect.examples
class _TranslationsDocsComponentsMultiselectExamplesDe extends TranslationsDocsComponentsMultiselectExamplesKo {
	_TranslationsDocsComponentsMultiselectExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Mehrfachauswahl Beispiel';
}

// Path: docs.components.navigation_bar.examples
class _TranslationsDocsComponentsNavigationBarExamplesDe extends TranslationsDocsComponentsNavigationBarExamplesKo {
	_TranslationsDocsComponentsNavigationBarExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Navigationsleiste Beispiel';
}

// Path: docs.components.navigation_menu.examples
class _TranslationsDocsComponentsNavigationMenuExamplesDe extends TranslationsDocsComponentsNavigationMenuExamplesKo {
	_TranslationsDocsComponentsNavigationMenuExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Navigationsmenü Beispiel';
}

// Path: docs.components.navigation_rail.examples
class _TranslationsDocsComponentsNavigationRailExamplesDe extends TranslationsDocsComponentsNavigationRailExamplesKo {
	_TranslationsDocsComponentsNavigationRailExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Navigationsschiene Beispiel';
}

// Path: docs.components.navigation_sidebar.examples
class _TranslationsDocsComponentsNavigationSidebarExamplesDe extends TranslationsDocsComponentsNavigationSidebarExamplesKo {
	_TranslationsDocsComponentsNavigationSidebarExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Navigationssidebar Beispiel';
}

// Path: docs.components.number_input.examples
class _TranslationsDocsComponentsNumberInputExamplesDe extends TranslationsDocsComponentsNumberInputExamplesKo {
	_TranslationsDocsComponentsNumberInputExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Zahleneingabe Beispiel';
}

// Path: docs.components.number_ticker.examples
class _TranslationsDocsComponentsNumberTickerExamplesDe extends TranslationsDocsComponentsNumberTickerExamplesKo {
	_TranslationsDocsComponentsNumberTickerExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Zahlenticker Beispiel';
}

// Path: docs.components.overflow_marquee.examples
class _TranslationsDocsComponentsOverflowMarqueeExamplesDe extends TranslationsDocsComponentsOverflowMarqueeExamplesKo {
	_TranslationsDocsComponentsOverflowMarqueeExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Überlaufmarquee Beispiel';
}

// Path: docs.components.pagination.examples
class _TranslationsDocsComponentsPaginationExamplesDe extends TranslationsDocsComponentsPaginationExamplesKo {
	_TranslationsDocsComponentsPaginationExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Seitenzahl Beispiel';
}

// Path: docs.components.phone_input.examples
class _TranslationsDocsComponentsPhoneInputExamplesDe extends TranslationsDocsComponentsPhoneInputExamplesKo {
	_TranslationsDocsComponentsPhoneInputExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Telefonnummerneingabe Beispiel';
}

// Path: docs.components.popover.examples
class _TranslationsDocsComponentsPopoverExamplesDe extends TranslationsDocsComponentsPopoverExamplesKo {
	_TranslationsDocsComponentsPopoverExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Popover Beispiel';
}

// Path: docs.components.progress.examples
class _TranslationsDocsComponentsProgressExamplesDe extends TranslationsDocsComponentsProgressExamplesKo {
	_TranslationsDocsComponentsProgressExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Fortschritt Beispiel';
}

// Path: docs.components.radio_card.examples
class _TranslationsDocsComponentsRadioCardExamplesDe extends TranslationsDocsComponentsRadioCardExamplesKo {
	_TranslationsDocsComponentsRadioCardExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Radio-Karte Beispiel';
}

// Path: docs.components.radio_group.examples
class _TranslationsDocsComponentsRadioGroupExamplesDe extends TranslationsDocsComponentsRadioGroupExamplesKo {
	_TranslationsDocsComponentsRadioGroupExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Radiogruppe Beispiel';
}

// Path: docs.components.refresh_trigger.examples
class _TranslationsDocsComponentsRefreshTriggerExamplesDe extends TranslationsDocsComponentsRefreshTriggerExamplesKo {
	_TranslationsDocsComponentsRefreshTriggerExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Aktualisierungs-Trigger Beispiel';
}

// Path: docs.components.repeated_animation_builder.examples
class _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesDe extends TranslationsDocsComponentsRepeatedAnimationBuilderExamplesKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Wiederholter Animations-Builder Beispiel';
}

// Path: docs.components.resizable.examples
class _TranslationsDocsComponentsResizableExamplesDe extends TranslationsDocsComponentsResizableExamplesKo {
	_TranslationsDocsComponentsResizableExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Größenanpassbar Beispiel';
}

// Path: docs.components.scaffold.examples
class _TranslationsDocsComponentsScaffoldExamplesDe extends TranslationsDocsComponentsScaffoldExamplesKo {
	_TranslationsDocsComponentsScaffoldExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Gerüst Beispiel';
}

// Path: docs.components.select.examples
class _TranslationsDocsComponentsSelectExamplesDe extends TranslationsDocsComponentsSelectExamplesKo {
	_TranslationsDocsComponentsSelectExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Auswahl Beispiel';
}

// Path: docs.components.sheet.examples
class _TranslationsDocsComponentsSheetExamplesDe extends TranslationsDocsComponentsSheetExamplesKo {
	_TranslationsDocsComponentsSheetExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Blatt Beispiel';
}

// Path: docs.components.skeleton.examples
class _TranslationsDocsComponentsSkeletonExamplesDe extends TranslationsDocsComponentsSkeletonExamplesKo {
	_TranslationsDocsComponentsSkeletonExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Skeleton Beispiel';
}

// Path: docs.components.slider.examples
class _TranslationsDocsComponentsSliderExamplesDe extends TranslationsDocsComponentsSliderExamplesKo {
	_TranslationsDocsComponentsSliderExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Slider Beispiel';
}

// Path: docs.components.sortable.examples
class _TranslationsDocsComponentsSortableExamplesDe extends TranslationsDocsComponentsSortableExamplesKo {
	_TranslationsDocsComponentsSortableExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Sortierbar Beispiel';
}

// Path: docs.components.star_rating.examples
class _TranslationsDocsComponentsStarRatingExamplesDe extends TranslationsDocsComponentsStarRatingExamplesKo {
	_TranslationsDocsComponentsStarRatingExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Sternbewertung Beispiel';
}

// Path: docs.components.stepper.examples
class _TranslationsDocsComponentsStepperExamplesDe extends TranslationsDocsComponentsStepperExamplesKo {
	_TranslationsDocsComponentsStepperExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Stepper Beispiel';
}

// Path: docs.components.steps.examples
class _TranslationsDocsComponentsStepsExamplesDe extends TranslationsDocsComponentsStepsExamplesKo {
	_TranslationsDocsComponentsStepsExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Schritte Beispiel';
}

// Path: docs.components.swiper.examples
class _TranslationsDocsComponentsSwiperExamplesDe extends TranslationsDocsComponentsSwiperExamplesKo {
	_TranslationsDocsComponentsSwiperExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Swiper Beispiel';
}

// Path: docs.components.k_switch.examples
class _TranslationsDocsComponentsKSwitchExamplesDe extends TranslationsDocsComponentsKSwitchExamplesKo {
	_TranslationsDocsComponentsKSwitchExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Schalter Beispiel';
}

// Path: docs.components.switcher.examples
class _TranslationsDocsComponentsSwitcherExamplesDe extends TranslationsDocsComponentsSwitcherExamplesKo {
	_TranslationsDocsComponentsSwitcherExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Wechsler Beispiel';
}

// Path: docs.components.tab_list.examples
class _TranslationsDocsComponentsTabListExamplesDe extends TranslationsDocsComponentsTabListExamplesKo {
	_TranslationsDocsComponentsTabListExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Tab-Liste Beispiel';
}

// Path: docs.components.tab_pane.examples
class _TranslationsDocsComponentsTabPaneExamplesDe extends TranslationsDocsComponentsTabPaneExamplesKo {
	_TranslationsDocsComponentsTabPaneExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Tab-Panel Beispiel';
}

// Path: docs.components.table.examples
class _TranslationsDocsComponentsTableExamplesDe extends TranslationsDocsComponentsTableExamplesKo {
	_TranslationsDocsComponentsTableExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Tabellen Beispiel';
}

// Path: docs.components.tabs.examples
class _TranslationsDocsComponentsTabsExamplesDe extends TranslationsDocsComponentsTabsExamplesKo {
	_TranslationsDocsComponentsTabsExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Tabs Beispiel';
}

// Path: docs.components.text_area.examples
class _TranslationsDocsComponentsTextAreaExamplesDe extends TranslationsDocsComponentsTextAreaExamplesKo {
	_TranslationsDocsComponentsTextAreaExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Textbereich Beispiel';
}

// Path: docs.components.time_picker.examples
class _TranslationsDocsComponentsTimePickerExamplesDe extends TranslationsDocsComponentsTimePickerExamplesKo {
	_TranslationsDocsComponentsTimePickerExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Uhrzeitauswahl Beispiel';
}

// Path: docs.components.timeline.examples
class _TranslationsDocsComponentsTimelineExamplesDe extends TranslationsDocsComponentsTimelineExamplesKo {
	_TranslationsDocsComponentsTimelineExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Zeitlinie Beispiel';
}

// Path: docs.components.timeline_animation.examples
class _TranslationsDocsComponentsTimelineAnimationExamplesDe extends TranslationsDocsComponentsTimelineAnimationExamplesKo {
	_TranslationsDocsComponentsTimelineAnimationExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Zeitlinienanimation Beispiel';
}

// Path: docs.components.toast.examples
class _TranslationsDocsComponentsToastExamplesDe extends TranslationsDocsComponentsToastExamplesKo {
	_TranslationsDocsComponentsToastExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Toast Beispiel';
}

// Path: docs.components.toggle.examples
class _TranslationsDocsComponentsToggleExamplesDe extends TranslationsDocsComponentsToggleExamplesKo {
	_TranslationsDocsComponentsToggleExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Toggle Beispiel';
}

// Path: docs.components.tooltip.examples
class _TranslationsDocsComponentsTooltipExamplesDe extends TranslationsDocsComponentsTooltipExamplesKo {
	_TranslationsDocsComponentsTooltipExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Tooltip Beispiel';
}

// Path: docs.components.tracker.examples
class _TranslationsDocsComponentsTrackerExamplesDe extends TranslationsDocsComponentsTrackerExamplesKo {
	_TranslationsDocsComponentsTrackerExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Tracker Beispiel';
}

// Path: docs.components.tree.examples
class _TranslationsDocsComponentsTreeExamplesDe extends TranslationsDocsComponentsTreeExamplesKo {
	_TranslationsDocsComponentsTreeExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Baum Beispiel';
}

// Path: docs.components.window.examples
class _TranslationsDocsComponentsWindowExamplesDe extends TranslationsDocsComponentsWindowExamplesKo {
	_TranslationsDocsComponentsWindowExamplesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Fenster Beispiel';
}
