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
class TranslationsIt extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsIt({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.it,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <it>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsIt _root = this; // ignore: unused_field

	@override 
	TranslationsIt $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsIt(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsWidgetbookIt widgetbook = _TranslationsWidgetbookIt._(_root);
	@override late final _TranslationsDocsIt docs = _TranslationsDocsIt._(_root);
}

// Path: widgetbook
class _TranslationsWidgetbookIt extends TranslationsWidgetbookKo {
	_TranslationsWidgetbookIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsWidgetbookCommonIt common = _TranslationsWidgetbookCommonIt._(_root);
	@override late final _TranslationsWidgetbookLoadingIt loading = _TranslationsWidgetbookLoadingIt._(_root);
	@override late final _TranslationsWidgetbookTabsIt tabs = _TranslationsWidgetbookTabsIt._(_root);
	@override late final _TranslationsWidgetbookPaginationIt pagination = _TranslationsWidgetbookPaginationIt._(_root);
	@override late final _TranslationsWidgetbookTooltipIt tooltip = _TranslationsWidgetbookTooltipIt._(_root);
	@override late final _TranslationsWidgetbookRadioIt radio = _TranslationsWidgetbookRadioIt._(_root);
	@override late final _TranslationsWidgetbookCardIt card = _TranslationsWidgetbookCardIt._(_root);
	@override late final _TranslationsWidgetbookAlertIt alert = _TranslationsWidgetbookAlertIt._(_root);
	@override late final _TranslationsWidgetbookAccordionIt accordion = _TranslationsWidgetbookAccordionIt._(_root);
	@override late final _TranslationsWidgetbookSkeletonIt skeleton = _TranslationsWidgetbookSkeletonIt._(_root);
	@override late final _TranslationsWidgetbookToastIt toast = _TranslationsWidgetbookToastIt._(_root);
	@override late final _TranslationsWidgetbookChipIt chip = _TranslationsWidgetbookChipIt._(_root);
	@override late final _TranslationsWidgetbookCheckboxIt checkbox = _TranslationsWidgetbookCheckboxIt._(_root);
	@override late final _TranslationsWidgetbookToggleIt toggle = _TranslationsWidgetbookToggleIt._(_root);
	@override late final _TranslationsWidgetbookDialogIt dialog = _TranslationsWidgetbookDialogIt._(_root);
	@override late final _TranslationsWidgetbookPopoverIt popover = _TranslationsWidgetbookPopoverIt._(_root);
	@override late final _TranslationsWidgetbookTextFieldIt text_field = _TranslationsWidgetbookTextFieldIt._(_root);
	@override late final _TranslationsWidgetbookButtonIt button = _TranslationsWidgetbookButtonIt._(_root);
	@override late final _TranslationsWidgetbookTableIt table = _TranslationsWidgetbookTableIt._(_root);
	@override late final _TranslationsWidgetbookKSwitchIt k_switch = _TranslationsWidgetbookKSwitchIt._(_root);
	@override late final _TranslationsWidgetbookSwitchComponentIt switch_component = _TranslationsWidgetbookSwitchComponentIt._(_root);
	@override late final _TranslationsWidgetbookSelectIt select = _TranslationsWidgetbookSelectIt._(_root);
	@override late final _TranslationsWidgetbookBreadcrumbIt breadcrumb = _TranslationsWidgetbookBreadcrumbIt._(_root);
	@override late final _TranslationsWidgetbookBadgeIt badge = _TranslationsWidgetbookBadgeIt._(_root);
	@override late final _TranslationsWidgetbookThemePreviewIt theme_preview = _TranslationsWidgetbookThemePreviewIt._(_root);
	@override late final _TranslationsWidgetbookChatIt chat = _TranslationsWidgetbookChatIt._(_root);
	@override late final _TranslationsWidgetbookMultipleChoiceIt multiple_choice = _TranslationsWidgetbookMultipleChoiceIt._(_root);
	@override late final _TranslationsWidgetbookFormattedInputIt formatted_input = _TranslationsWidgetbookFormattedInputIt._(_root);
	@override late final _TranslationsWidgetbookSwiperIt swiper = _TranslationsWidgetbookSwiperIt._(_root);
}

// Path: docs
class _TranslationsDocsIt extends TranslationsDocsKo {
	_TranslationsDocsIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsCommonIt common = _TranslationsDocsCommonIt._(_root);
	@override late final _TranslationsDocsBadgesIt badges = _TranslationsDocsBadgesIt._(_root);
	@override late final _TranslationsDocsFlavorsIt flavors = _TranslationsDocsFlavorsIt._(_root);
	@override late final _TranslationsDocsNavigationIt navigation = _TranslationsDocsNavigationIt._(_root);
	@override late final _TranslationsDocsPagesIt pages = _TranslationsDocsPagesIt._(_root);
	@override late final _TranslationsDocsComponentsIt components = _TranslationsDocsComponentsIt._(_root);
}

// Path: widgetbook.common
class _TranslationsWidgetbookCommonIt extends TranslationsWidgetbookCommonKo {
	_TranslationsWidgetbookCommonIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get increment_progress => 'Incrementa il progresso';
	@override String selected_tab({required Object index}) => 'Scheda selezionata: ${index}';
	@override String current_page({required Object page}) => 'Pagina attuale: ${page}';
	@override String total_pages({required Object count}) => 'Pagine totali: ${count}';
	@override String page_of({required Object current, required Object total}) => '${current}Pagina / ${total}';
	@override String get hover_over_icon => 'Passa il mouse sopra l\'icona';
	@override String counter({required Object count}) => 'Contatore: ${count}';
	@override String selected_rows({required Object count}) => 'Righe selezionate: ${count}';
	@override String value({required Object value}) => 'Valore: ${value}';
	@override String selected_cells({required Object count}) => 'Celle selezionate: ${count}';
}

// Path: widgetbook.loading
class _TranslationsWidgetbookLoadingIt extends TranslationsWidgetbookLoadingKo {
	_TranslationsWidgetbookLoadingIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get indeterminate => 'Caricamento infinito';
	@override String with_value({required Object percent}) => 'Incluso valore (${percent}%)';
	@override String get custom_size => 'Dimensione personalizzata';
	@override String get custom_height => 'Altezza personalizzata';
	@override String get circular_progress => 'Progresso circolare';
	@override String get linear_progress => 'Progresso lineare';
}

// Path: widgetbook.tabs
class _TranslationsWidgetbookTabsIt extends TranslationsWidgetbookTabsKo {
	_TranslationsWidgetbookTabsIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get home => 'Home';
	@override String get profile => 'Profilo';
	@override String get settings => 'Impostazioni';
	@override String get overview => 'Panoramica';
	@override String get details => 'Dettagli';
	@override String get history => 'Storia';
	@override String get overview_content => 'Contenuto panoramico';
	@override String get details_content => 'Contenuto dettagliato';
	@override String get history_content => 'Contenuto della storia';
	@override String get general_info => 'Informazioni generali sull\'elemento';
	@override String get specifications => 'Specifiche dettagliate e attributi';
	@override String get timeline => 'Cronologia delle modifiche e aggiornamenti';
}

// Path: widgetbook.pagination
class _TranslationsWidgetbookPaginationIt extends TranslationsWidgetbookPaginationKo {
	_TranslationsWidgetbookPaginationIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get show_skip_to_first => 'Mostra salto alla prima';
	@override String get show_skip_to_last => 'Mostra salto all\'ultima';
	@override String get hide_previous_on_first => 'Nascondi precedente nella prima pagina';
	@override String get hide_next_on_last => 'Nascondi successivo nell\'ultima pagina';
	@override String get max_visible_pages => 'Numero massimo di pagine visibili';
}

// Path: widgetbook.tooltip
class _TranslationsWidgetbookTooltipIt extends TranslationsWidgetbookTooltipKo {
	_TranslationsWidgetbookTooltipIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get helpful_message => 'Messaggio tooltip utile';
	@override String get tooltip_above => 'Tooltip sopra';
	@override String get tooltip_below => 'Tooltip sotto';
	@override String get tooltip_left => 'Tooltip a sinistra';
	@override String get tooltip_right => 'Tooltip a destra';
	@override String get top => 'Alto';
	@override String get bottom => 'Basso';
	@override String get left => 'Sinistra';
	@override String get right => 'Destra';
}

// Path: widgetbook.radio
class _TranslationsWidgetbookRadioIt extends TranslationsWidgetbookRadioKo {
	_TranslationsWidgetbookRadioIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get small => 'Piccolo';
	@override String get medium => 'Medio';
	@override String get large => 'Grande';
}

// Path: widgetbook.card
class _TranslationsWidgetbookCardIt extends TranslationsWidgetbookCardKo {
	_TranslationsWidgetbookCardIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get card_content => 'Contenuto della scheda';
	@override String get gradient_card => 'Carta sfumata';
	@override String get custom_decoration => 'Carta con decorazione personalizzata';
}

// Path: widgetbook.alert
class _TranslationsWidgetbookAlertIt extends TranslationsWidgetbookAlertKo {
	_TranslationsWidgetbookAlertIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titolo dell\'allerta';
	@override String get message => 'Questo è un messaggio di allerta.';
}

// Path: widgetbook.accordion
class _TranslationsWidgetbookAccordionIt extends TranslationsWidgetbookAccordionKo {
	_TranslationsWidgetbookAccordionIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get what_is_coui => 'Che cos\'è CoUI Flutter?';
	@override String get what_is_coui_answer => 'CoUI Flutter è una libreria di componenti UI completa progettata per costruire applicazioni Flutter moderne e accessibili con schemi di design coerenti.';
	@override String get how_to_install => 'Come si installa?';
	@override String get how_to_install_answer => 'Aggiungi coui_flutter alle dipendenze di pubspec.yaml ed esegui flutter pub get per installare il pacchetto.';
	@override String get is_customizable => 'È personalizzabile?';
	@override String get is_customizable_answer => 'Sì! CoUI Flutter offre un supporto tematico completo per personalizzare colori, tipografia, spaziature, ecc. tramite ThemeData.';
	@override String get getting_started => 'Iniziare';
	@override String get getting_started_answer => 'Inizia installando il pacchetto e importandolo nel tuo progetto. Per dettagli su come configurarlo, consulta la documentazione.';
	@override String get features_expanded => 'Funzionalità (di base estesa)';
	@override String get features_answer => 'CoUI Flutter include componenti quali pulsanti, moduli, finestre di dialogo, componenti di navigazione, ecc. Tutti i componenti sono progettati tenendo conto dell\'accessibilità e del tema.';
	@override String get support => 'Supporto';
	@override String get support_answer => 'Se hai domande o necessiti di supporto, visita il repository GitHub o controlla la documentazione su docs.coui.dev.';
}

// Path: widgetbook.skeleton
class _TranslationsWidgetbookSkeletonIt extends TranslationsWidgetbookSkeletonKo {
	_TranslationsWidgetbookSkeletonIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get skeleton_enabled => 'Skeleton attivato:';
	@override String get title_text => 'Titolo';
	@override String get description_text => 'Testo descrittivo lungo';
	@override String get short_text => 'Testo breve';
	@override String get without_skeleton => 'Senza skeleton:';
	@override String get with_skeleton => 'Con skeleton:';
	@override String get user_name => 'Nome utente';
	@override String get user_email => 'user@example.com';
	@override String get article_title => 'Titolo dell\'articolo';
	@override String get posted_date => 'Pubblicato il 1 gennaio 2024';
	@override String get bio_description => 'Sviluppatore che registra la quotidianità';
	@override String get show_content => 'Mostra contenuto';
	@override String get show_loading => 'Mostra caricamento';
	@override String get article_content => 'Questo è un esempio del contenuto di un articolo. Viene sostituito con uno skeleton durante il caricamento.';
}

// Path: widgetbook.toast
class _TranslationsWidgetbookToastIt extends TranslationsWidgetbookToastKo {
	_TranslationsWidgetbookToastIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get success => 'Successo';
	@override String get operation_completed => 'Operazione completata con successo';
	@override String get show_toast => 'Mostra toast';
	@override String toast_at({required Object location}) => 'Toast a ${location}';
	@override String get top_left => 'In alto a sinistra';
	@override String get top_center => 'In alto al centro';
	@override String get top_right => 'In alto a destra';
	@override String get bottom_left => 'In basso a sinistra';
	@override String get bottom_center => 'In basso al centro';
	@override String get bottom_right => 'In basso a destra';
}

// Path: widgetbook.chip
class _TranslationsWidgetbookChipIt extends TranslationsWidgetbookChipKo {
	_TranslationsWidgetbookChipIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get chip => 'Chip';
}

// Path: widgetbook.checkbox
class _TranslationsWidgetbookCheckboxIt extends TranslationsWidgetbookCheckboxKo {
	_TranslationsWidgetbookCheckboxIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get accept_terms => 'Accetto i termini e le condizioni';
	@override String get tristate => 'Tre stati';
}

// Path: widgetbook.toggle
class _TranslationsWidgetbookToggleIt extends TranslationsWidgetbookToggleKo {
	_TranslationsWidgetbookToggleIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get toggle => 'Attiva/Disattiva';
}

// Path: widgetbook.dialog
class _TranslationsWidgetbookDialogIt extends TranslationsWidgetbookDialogKo {
	_TranslationsWidgetbookDialogIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic_dialog => 'Dialogo di base';
	@override String get basic_title => 'Dialogo di base';
	@override String get basic_content => 'Un semplice dialogo con titolo e contenuto.';
	@override String get simple_dialog_content => 'Dialogo semplice con titolo e contenuto.';
	@override String get show_basic => 'Mostra di base';
	@override String get show_basic_dialog => 'Mostra dialogo di base';
	@override String get confirm_action => 'Conferma azione';
	@override String get confirm_title => 'Conferma';
	@override String get confirm_content => 'Sei sicuro di voler eseguire questa operazione?';
	@override String get confirm_action_content => 'Sei sicuro di voler eseguire quest\'azione? Questa azione non può essere annullata.';
	@override String get cancel => 'Annulla';
	@override String get confirm => 'Conferma';
	@override String get show_confirmation => 'Mostra conferma';
	@override String get show_confirmation_dialog => 'Mostra dialogo di conferma';
	@override String get warning => 'Avviso';
	@override String get warning_title => 'Avviso';
	@override String get warning_content => 'Questa azione potrebbe influenzare i dati. Procedere con cautela.';
	@override String get dismiss => 'Chiudi';
	@override String get show_warning => 'Mostra avviso';
	@override String get show_warning_dialog => 'Mostra dialogo di avviso';
}

// Path: widgetbook.popover
class _TranslationsWidgetbookPopoverIt extends TranslationsWidgetbookPopoverKo {
	_TranslationsWidgetbookPopoverIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get popover_content => 'Contenuto del popover';
	@override String get content_title => 'Titolo del popover';
	@override String get content_description => 'Popover con contenuto personalizzabile.';
	@override String get customizable_content => 'Popover con contenuto personalizzabile.';
	@override String get show_popover => 'Mostra popover';
	@override String popover_at({required Object position}) => '${position} popover';
	@override String get top => 'Superiore';
	@override String get bottom => 'Inferiore';
	@override String get left => 'Sinistra';
	@override String get right => 'Destra';
}

// Path: widgetbook.text_field
class _TranslationsWidgetbookTextFieldIt extends TranslationsWidgetbookTextFieldKo {
	_TranslationsWidgetbookTextFieldIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get enter_name => 'Inserisci il nome';
	@override String get type_here => 'Digita qui';
}

// Path: widgetbook.button
class _TranslationsWidgetbookButtonIt extends TranslationsWidgetbookButtonKo {
	_TranslationsWidgetbookButtonIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get primary_button => 'Pulsante principale';
	@override String get secondary_button => 'Pulsante secondario';
	@override String get dashed_button => 'Carica file';
	@override String get upload_file => 'Carica file';
}

// Path: widgetbook.table
class _TranslationsWidgetbookTableIt extends TranslationsWidgetbookTableKo {
	_TranslationsWidgetbookTableIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get name => 'Nome';
	@override String get email => 'Email';
	@override String get role => 'Ruolo';
	@override String get john_doe => 'Giovanni Rossi';
	@override String get john_email => 'rossi@example.com';
	@override String get developer => 'Sviluppatore';
	@override String get jane_smith => 'Maria Bianchi';
	@override String get jane_email => 'bianchi@example.com';
	@override String get designer => 'Designer';
	@override String get bob_johnson => 'Pietro Verdi';
	@override String get bob_email => 'verdi@example.com';
	@override String get manager => 'Manager';
	@override String get select => 'Seleziona';
	@override String get product => 'Prodotto';
	@override String get price => 'Prezzo';
	@override String get stock => 'Magazzino';
	@override String get laptop => 'Portatile';
	@override String get mouse => 'Mouse';
	@override String get keyboard => 'Tastiera';
}

// Path: widgetbook.k_switch
class _TranslationsWidgetbookKSwitchIt extends TranslationsWidgetbookKSwitchKo {
	_TranslationsWidgetbookKSwitchIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get k_switch => 'Interruttore';
}

// Path: widgetbook.switch_component
class _TranslationsWidgetbookSwitchComponentIt extends TranslationsWidgetbookSwitchComponentKo {
	_TranslationsWidgetbookSwitchComponentIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get switch_label => 'Etichetta dell\'interruttore';
}

// Path: widgetbook.select
class _TranslationsWidgetbookSelectIt extends TranslationsWidgetbookSelectKo {
	_TranslationsWidgetbookSelectIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get apple => 'Mela';
	@override String get banana => 'Banana';
	@override String get cherry => 'Ciliegia';
	@override String get date => 'Dattero';
	@override String get choose_size => 'Scegli la dimensione';
	@override String get small => 'Piccolo';
	@override String get medium => 'Medio';
	@override String get large => 'Grande';
	@override String get extra_large => 'Molto grande';
}

// Path: widgetbook.breadcrumb
class _TranslationsWidgetbookBreadcrumbIt extends TranslationsWidgetbookBreadcrumbKo {
	_TranslationsWidgetbookBreadcrumbIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get home => 'Home';
	@override String get products => 'Prodotti';
	@override String get electronics => 'Elettronica';
	@override String get smartphones => 'Smartphone';
	@override String get documents => 'Documenti';
	@override String get projects => 'Progetti';
	@override String get current_folder => 'Cartella attuale';
	@override String current_path({required Object path}) => 'Percorso attuale: ${path}';
}

// Path: widgetbook.badge
class _TranslationsWidgetbookBadgeIt extends TranslationsWidgetbookBadgeKo {
	_TranslationsWidgetbookBadgeIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get primary => 'Primario';
	@override String get secondary => 'Secondario';
	@override String get outline => 'Contorno';
	@override String get destructive => 'Distruttivo';
	@override String get featured => 'In primo piano';
	@override String get more => 'Di più';
	@override String get verified => 'Verificato';
	@override String get error => 'Errore';
	@override String get click_me => 'Clicca qui';
	@override String get clickable => 'Cliccabile';
}

// Path: widgetbook.theme_preview
class _TranslationsWidgetbookThemePreviewIt extends TranslationsWidgetbookThemePreviewKo {
	_TranslationsWidgetbookThemePreviewIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Anteprima del tema';
	@override String get description => 'Una panoramica completa di tutti i token tematici e degli stili dei componenti';
	@override String get color_palette => 'Palette dei colori';
	@override String get brand_colors => 'Colori del marchio';
	@override String get base_colors => 'Colori di base';
	@override String get status_colors => 'Colori di stato';
	@override String get buttons => 'Pulsanti';
	@override String get primary_button => 'Primario';
	@override String get secondary_button => 'Secondario';
	@override String get outline_button => 'Outline';
	@override String get ghost_button => 'Ghost';
	@override String get destructive_button => 'Distruttivo';
	@override String get disabled_button => 'Disabilitato';
	@override String get cards => 'Carte';
	@override String get card_title => 'Titolo della carta';
	@override String get card_description => 'Descrizione della carta di esempio.';
	@override String get surface_card => 'Carta superficie';
	@override String get filled_variant => 'Stile filled con sfondo';
	@override String get form_elements => 'Elementi del modulo';
	@override String get text_input_placeholder => 'Inserisci il testo...';
	@override String get checkbox_checked => 'Selezionato';
	@override String get checkbox_unchecked => 'Non selezionato';
	@override String get toggle_on => 'Acceso';
	@override String get toggle_off => 'Spento';
	@override String get alerts => 'Avvisi';
	@override String get info_alert => 'Avviso informativo';
	@override String get info_alert_message => 'Messaggio informativo.';
	@override String get error_alert => 'Avviso di errore';
	@override String get error_alert_message => 'Si è verificato un problema.';
	@override String get badges_chips => 'Badge & Chip';
	@override String get primary_badge => 'Primario';
	@override String get secondary_badge => 'Secondario';
	@override String get outline_badge => 'Outline';
	@override String get destructive_badge => 'Distruttivo';
	@override String get chip_example => 'Preferito';
	@override String get typography => 'Tipografia';
	@override String get heading_1 => 'Titolo 1';
	@override String get heading_2 => 'Titolo 2';
	@override String get heading_3 => 'Titolo 3';
	@override String get heading_4 => 'Titolo 4';
	@override String get body_text => 'Testo del corpo con spessore normale.';
	@override String get small_text => 'Testo piccolo per didascalie.';
	@override String get muted_text => 'Testo attenuato per informazioni aggiuntive.';
	@override String get bold_text => 'Testo in grassetto per enfasi.';
	@override String get spacing_radius => 'Spaziatura & Raggio';
	@override String get border_radius => 'Raggio del bordo';
	@override String get loading_states => 'Stati di caricamento';
}

// Path: widgetbook.chat
class _TranslationsWidgetbookChatIt extends TranslationsWidgetbookChatKo {
	_TranslationsWidgetbookChatIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get hello => 'Ciao! Come stai?';
	@override String get doing_great => 'Benissimo, grazie!';
	@override String get nice_weather => 'Bel tempo oggi!';
	@override String get yes_beautiful => 'Sì, è bellissimo!';
	@override String get sender => 'Mittente';
	@override String get receiver => 'Destinatario';
}

// Path: widgetbook.multiple_choice
class _TranslationsWidgetbookMultipleChoiceIt extends TranslationsWidgetbookMultipleChoiceKo {
	_TranslationsWidgetbookMultipleChoiceIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get option_a => 'Option A';
	@override String get option_b => 'Option B';
	@override String get option_c => 'Option C';
	@override String get option_d => 'Option D';
	@override String selected_value({required Object value}) => 'Selezionato: ${value}';
	@override String selected_values({required Object values}) => 'Selezionati: ${values}';
}

// Path: widgetbook.formatted_input
class _TranslationsWidgetbookFormattedInputIt extends TranslationsWidgetbookFormattedInputKo {
	_TranslationsWidgetbookFormattedInputIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get date_format => 'Formato data (MM/GG/AAAA)';
	@override String get time_format => 'Formato ora (HH:MM)';
	@override String current_value({required Object value}) => 'Valore attuale: ${value}';
}

// Path: widgetbook.swiper
class _TranslationsWidgetbookSwiperIt extends TranslationsWidgetbookSwiperKo {
	_TranslationsWidgetbookSwiperIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get swipe_hint => 'Scorri o tocca per aprire';
	@override String get overlay_content => 'Contenuto overlay';
	@override String get close => 'Chiudi';
}

// Path: docs.common
class _TranslationsDocsCommonIt extends TranslationsDocsCommonKo {
	_TranslationsDocsCommonIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get app_name => 'coui_flutter';
	@override String get search_documentation => 'Cerca documentazione...';
	@override String get docs => 'Documentazione';
	@override String get components => 'Componenti';
	@override String get close => 'Chiudi';
	@override String get on_this_page => 'Indice di questa pagina';
	@override String get work_in_progress_title => 'In fase di sviluppo';
	@override String get work_in_progress_message => 'Questa pagina è ancora in fase di sviluppo. Torna a trovarci più tardi.';
	@override String get add => 'Aggiungi';
	@override String get reset => 'Ripristina';
	@override String get prev => 'Precedente';
	@override String get next => 'Successivo';
	@override String get finish => 'Completa';
	@override String get open => 'Apri';
	@override String get disabled => 'Disabilitato';
	@override String get refresh => 'Aggiorna';
	@override String get rebuild => 'Ricostruisci';
	@override String get change_color => 'Cambia colore';
}

// Path: docs.badges
class _TranslationsDocsBadgesIt extends TranslationsDocsBadgesKo {
	_TranslationsDocsBadgesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get k_new => 'Nuovo';
	@override String get updated => 'Aggiornato';
	@override String get wip => 'In sviluppo';
	@override String get experimental => 'Sperimentale';
}

// Path: docs.flavors
class _TranslationsDocsFlavorsIt extends TranslationsDocsFlavorsKo {
	_TranslationsDocsFlavorsIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get local => 'Locale';
	@override String get experimental => 'Sperimentale';
	@override String get unknown => 'Sconosciuto';
}

// Path: docs.navigation
class _TranslationsDocsNavigationIt extends TranslationsDocsNavigationKo {
	_TranslationsDocsNavigationIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get getting_started => 'Inizia';
	@override String get animation => 'Animazione';
	@override String get control => 'Controllo';
	@override String get disclosure => 'Divulgazione';
	@override String get display => 'Visualizzazione';
	@override String get feedback => 'Feedback';
	@override String get form => 'Modulo';
	@override String get layout => 'Layout';
	@override String get navigation => 'Navigazione';
	@override String get overlay => 'Sovrapposizione';
	@override String get utility => 'Utility';
	@override String get my_account => 'Il mio account';
	@override String get profile => 'Profilo';
	@override String get settings => 'Impostazioni';
	@override String get team => 'Team';
	@override String get new_team => 'Nuovo team';
	@override String get billing => 'Fatturazione';
	@override String get api => 'API';
	@override String get log_out => 'Disconnetti';
	@override String get support => 'Supporto';
	@override String get invite_users => 'Invita utenti';
	@override String get more => 'Altro';
	@override String get github => 'GitHub';
	@override String get note => 'Nota';
	@override String get message => 'Messaggio';
	@override String get keyboard_shortcuts => 'Scorciatoie da tastiera';
}

// Path: docs.pages
class _TranslationsDocsPagesIt extends TranslationsDocsPagesKo {
	_TranslationsDocsPagesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsPagesIntroductionIt introduction = _TranslationsDocsPagesIntroductionIt._(_root);
	@override late final _TranslationsDocsPagesInstallationIt installation = _TranslationsDocsPagesInstallationIt._(_root);
	@override late final _TranslationsDocsPagesThemeIt theme = _TranslationsDocsPagesThemeIt._(_root);
	@override late final _TranslationsDocsPagesTypographyIt typography = _TranslationsDocsPagesTypographyIt._(_root);
	@override late final _TranslationsDocsPagesLayoutIt layout = _TranslationsDocsPagesLayoutIt._(_root);
	@override late final _TranslationsDocsPagesWebPreloaderIt web_preloader = _TranslationsDocsPagesWebPreloaderIt._(_root);
	@override late final _TranslationsDocsPagesComponentsListIt components_list = _TranslationsDocsPagesComponentsListIt._(_root);
	@override late final _TranslationsDocsPagesIconsIt icons = _TranslationsDocsPagesIconsIt._(_root);
	@override late final _TranslationsDocsPagesColorsIt colors = _TranslationsDocsPagesColorsIt._(_root);
	@override late final _TranslationsDocsPagesExternalIt external = _TranslationsDocsPagesExternalIt._(_root);
	@override late final _TranslationsDocsPagesStateIt state = _TranslationsDocsPagesStateIt._(_root);
}

// Path: docs.components
class _TranslationsDocsComponentsIt extends TranslationsDocsComponentsKo {
	_TranslationsDocsComponentsIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsComponentsAccordionIt accordion = _TranslationsDocsComponentsAccordionIt._(_root);
	@override late final _TranslationsDocsComponentsAlertIt alert = _TranslationsDocsComponentsAlertIt._(_root);
	@override late final _TranslationsDocsComponentsAlertDialogIt alert_dialog = _TranslationsDocsComponentsAlertDialogIt._(_root);
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderIt animated_value_builder = _TranslationsDocsComponentsAnimatedValueBuilderIt._(_root);
	@override late final _TranslationsDocsComponentsAppBarIt app_bar = _TranslationsDocsComponentsAppBarIt._(_root);
	@override late final _TranslationsDocsComponentsAutocompleteIt autocomplete = _TranslationsDocsComponentsAutocompleteIt._(_root);
	@override late final _TranslationsDocsComponentsAvatarIt avatar = _TranslationsDocsComponentsAvatarIt._(_root);
	@override late final _TranslationsDocsComponentsAvatarGroupIt avatar_group = _TranslationsDocsComponentsAvatarGroupIt._(_root);
	@override late final _TranslationsDocsComponentsBadgeIt badge = _TranslationsDocsComponentsBadgeIt._(_root);
	@override late final _TranslationsDocsComponentsBreadcrumbIt breadcrumb = _TranslationsDocsComponentsBreadcrumbIt._(_root);
	@override late final _TranslationsDocsComponentsButtonIt button = _TranslationsDocsComponentsButtonIt._(_root);
	@override late final _TranslationsDocsComponentsCalendarIt calendar = _TranslationsDocsComponentsCalendarIt._(_root);
	@override late final _TranslationsDocsComponentsCardIt card = _TranslationsDocsComponentsCardIt._(_root);
	@override late final _TranslationsDocsComponentsCardImageIt card_image = _TranslationsDocsComponentsCardImageIt._(_root);
	@override late final _TranslationsDocsComponentsCarouselIt carousel = _TranslationsDocsComponentsCarouselIt._(_root);
	@override late final _TranslationsDocsComponentsCheckboxIt checkbox = _TranslationsDocsComponentsCheckboxIt._(_root);
	@override late final _TranslationsDocsComponentsChipIt chip = _TranslationsDocsComponentsChipIt._(_root);
	@override late final _TranslationsDocsComponentsChipInputIt chip_input = _TranslationsDocsComponentsChipInputIt._(_root);
	@override late final _TranslationsDocsComponentsCircularProgressIt circular_progress = _TranslationsDocsComponentsCircularProgressIt._(_root);
	@override late final _TranslationsDocsComponentsCodeSnippetIt code_snippet = _TranslationsDocsComponentsCodeSnippetIt._(_root);
	@override late final _TranslationsDocsComponentsCollapsibleIt collapsible = _TranslationsDocsComponentsCollapsibleIt._(_root);
	@override late final _TranslationsDocsComponentsColorPickerIt color_picker = _TranslationsDocsComponentsColorPickerIt._(_root);
	@override late final _TranslationsDocsComponentsCommandIt command = _TranslationsDocsComponentsCommandIt._(_root);
	@override late final _TranslationsDocsComponentsContextMenuIt context_menu = _TranslationsDocsComponentsContextMenuIt._(_root);
	@override late final _TranslationsDocsComponentsDatePickerIt date_picker = _TranslationsDocsComponentsDatePickerIt._(_root);
	@override late final _TranslationsDocsComponentsDialogIt dialog = _TranslationsDocsComponentsDialogIt._(_root);
	@override late final _TranslationsDocsComponentsDividerIt divider = _TranslationsDocsComponentsDividerIt._(_root);
	@override late final _TranslationsDocsComponentsDotIndicatorIt dot_indicator = _TranslationsDocsComponentsDotIndicatorIt._(_root);
	@override late final _TranslationsDocsComponentsDrawerIt drawer = _TranslationsDocsComponentsDrawerIt._(_root);
	@override late final _TranslationsDocsComponentsDropdownMenuIt dropdown_menu = _TranslationsDocsComponentsDropdownMenuIt._(_root);
	@override late final _TranslationsDocsComponentsExpandableSidebarIt expandable_sidebar = _TranslationsDocsComponentsExpandableSidebarIt._(_root);
	@override late final _TranslationsDocsComponentsFormIt form = _TranslationsDocsComponentsFormIt._(_root);
	@override late final _TranslationsDocsComponentsFormattedInputIt formatted_input = _TranslationsDocsComponentsFormattedInputIt._(_root);
	@override late final _TranslationsDocsComponentsHoverCardIt hover_card = _TranslationsDocsComponentsHoverCardIt._(_root);
	@override late final _TranslationsDocsComponentsInputIt input = _TranslationsDocsComponentsInputIt._(_root);
	@override late final _TranslationsDocsComponentsInputOtpIt input_otp = _TranslationsDocsComponentsInputOtpIt._(_root);
	@override late final _TranslationsDocsComponentsItemPickerIt item_picker = _TranslationsDocsComponentsItemPickerIt._(_root);
	@override late final _TranslationsDocsComponentsKeyboardDisplayIt keyboard_display = _TranslationsDocsComponentsKeyboardDisplayIt._(_root);
	@override late final _TranslationsDocsComponentsLinearProgressIt linear_progress = _TranslationsDocsComponentsLinearProgressIt._(_root);
	@override late final _TranslationsDocsComponentsMaterialIt material = _TranslationsDocsComponentsMaterialIt._(_root);
	@override late final _TranslationsDocsComponentsMenubarIt menubar = _TranslationsDocsComponentsMenubarIt._(_root);
	@override late final _TranslationsDocsComponentsMultiselectIt multiselect = _TranslationsDocsComponentsMultiselectIt._(_root);
	@override late final _TranslationsDocsComponentsNavigationBarIt navigation_bar = _TranslationsDocsComponentsNavigationBarIt._(_root);
	@override late final _TranslationsDocsComponentsNavigationMenuIt navigation_menu = _TranslationsDocsComponentsNavigationMenuIt._(_root);
	@override late final _TranslationsDocsComponentsNavigationRailIt navigation_rail = _TranslationsDocsComponentsNavigationRailIt._(_root);
	@override late final _TranslationsDocsComponentsNavigationSidebarIt navigation_sidebar = _TranslationsDocsComponentsNavigationSidebarIt._(_root);
	@override late final _TranslationsDocsComponentsNumberInputIt number_input = _TranslationsDocsComponentsNumberInputIt._(_root);
	@override late final _TranslationsDocsComponentsNumberTickerIt number_ticker = _TranslationsDocsComponentsNumberTickerIt._(_root);
	@override late final _TranslationsDocsComponentsOverflowMarqueeIt overflow_marquee = _TranslationsDocsComponentsOverflowMarqueeIt._(_root);
	@override late final _TranslationsDocsComponentsPaginationIt pagination = _TranslationsDocsComponentsPaginationIt._(_root);
	@override late final _TranslationsDocsComponentsPhoneInputIt phone_input = _TranslationsDocsComponentsPhoneInputIt._(_root);
	@override late final _TranslationsDocsComponentsPopoverIt popover = _TranslationsDocsComponentsPopoverIt._(_root);
	@override late final _TranslationsDocsComponentsProgressIt progress = _TranslationsDocsComponentsProgressIt._(_root);
	@override late final _TranslationsDocsComponentsRadioCardIt radio_card = _TranslationsDocsComponentsRadioCardIt._(_root);
	@override late final _TranslationsDocsComponentsRadioGroupIt radio_group = _TranslationsDocsComponentsRadioGroupIt._(_root);
	@override late final _TranslationsDocsComponentsRefreshTriggerIt refresh_trigger = _TranslationsDocsComponentsRefreshTriggerIt._(_root);
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderIt repeated_animation_builder = _TranslationsDocsComponentsRepeatedAnimationBuilderIt._(_root);
	@override late final _TranslationsDocsComponentsResizableIt resizable = _TranslationsDocsComponentsResizableIt._(_root);
	@override late final _TranslationsDocsComponentsScaffoldIt scaffold = _TranslationsDocsComponentsScaffoldIt._(_root);
	@override late final _TranslationsDocsComponentsSelectIt select = _TranslationsDocsComponentsSelectIt._(_root);
	@override late final _TranslationsDocsComponentsSheetIt sheet = _TranslationsDocsComponentsSheetIt._(_root);
	@override late final _TranslationsDocsComponentsSkeletonIt skeleton = _TranslationsDocsComponentsSkeletonIt._(_root);
	@override late final _TranslationsDocsComponentsSliderIt slider = _TranslationsDocsComponentsSliderIt._(_root);
	@override late final _TranslationsDocsComponentsSortableIt sortable = _TranslationsDocsComponentsSortableIt._(_root);
	@override late final _TranslationsDocsComponentsStarRatingIt star_rating = _TranslationsDocsComponentsStarRatingIt._(_root);
	@override late final _TranslationsDocsComponentsStepperIt stepper = _TranslationsDocsComponentsStepperIt._(_root);
	@override late final _TranslationsDocsComponentsStepsIt steps = _TranslationsDocsComponentsStepsIt._(_root);
	@override late final _TranslationsDocsComponentsSwiperIt swiper = _TranslationsDocsComponentsSwiperIt._(_root);
	@override late final _TranslationsDocsComponentsKSwitchIt k_switch = _TranslationsDocsComponentsKSwitchIt._(_root);
	@override late final _TranslationsDocsComponentsSwitcherIt switcher = _TranslationsDocsComponentsSwitcherIt._(_root);
	@override late final _TranslationsDocsComponentsTabListIt tab_list = _TranslationsDocsComponentsTabListIt._(_root);
	@override late final _TranslationsDocsComponentsTabPaneIt tab_pane = _TranslationsDocsComponentsTabPaneIt._(_root);
	@override late final _TranslationsDocsComponentsTableIt table = _TranslationsDocsComponentsTableIt._(_root);
	@override late final _TranslationsDocsComponentsTabsIt tabs = _TranslationsDocsComponentsTabsIt._(_root);
	@override late final _TranslationsDocsComponentsTextAreaIt text_area = _TranslationsDocsComponentsTextAreaIt._(_root);
	@override late final _TranslationsDocsComponentsTimePickerIt time_picker = _TranslationsDocsComponentsTimePickerIt._(_root);
	@override late final _TranslationsDocsComponentsTimelineIt timeline = _TranslationsDocsComponentsTimelineIt._(_root);
	@override late final _TranslationsDocsComponentsTimelineAnimationIt timeline_animation = _TranslationsDocsComponentsTimelineAnimationIt._(_root);
	@override late final _TranslationsDocsComponentsToastIt toast = _TranslationsDocsComponentsToastIt._(_root);
	@override late final _TranslationsDocsComponentsToggleIt toggle = _TranslationsDocsComponentsToggleIt._(_root);
	@override late final _TranslationsDocsComponentsTooltipIt tooltip = _TranslationsDocsComponentsTooltipIt._(_root);
	@override late final _TranslationsDocsComponentsTrackerIt tracker = _TranslationsDocsComponentsTrackerIt._(_root);
	@override late final _TranslationsDocsComponentsTreeIt tree = _TranslationsDocsComponentsTreeIt._(_root);
	@override late final _TranslationsDocsComponentsWindowIt window = _TranslationsDocsComponentsWindowIt._(_root);
}

// Path: docs.pages.introduction
class _TranslationsDocsPagesIntroductionIt extends TranslationsDocsPagesIntroductionKo {
	_TranslationsDocsPagesIntroductionIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Introduzione';
	@override String get description => 'Iniziare con coui_flutter';
	@override String get lead => 'Ora puoi utilizzare i componenti splendidamente progettati di Coui/UI in Flutter.';
	@override String get welcome_paragraph_1 => 'coui_flutter è un insieme variegato e completo di componenti UI progettati specificamente per applicazioni desktop e web Flutter. Con la crescente popolarità di Flutter per la costruzione di app cross-platform, abbiamo riconosciuto la necessità di un toolkit che evidenzi le uniche esigenze di design delle interfacce desktop e web.';
	@override String get welcome_paragraph_2 => 'Questo pacchetto offre un\'ampia gamma di componenti personalizzabili e reattivi che si allineano ai principi di design moderni per desktop e web. Che tu stia costruendo sofisticate applicazioni aziendali, dashboard eleganti o strumenti di produttività, i nostri componenti sono progettati per aiutarti a creare interfacce utente professionali e raffinate in modo rapido ed efficiente.';
	@override String get features => 'Caratteristiche principali';
	@override late final _TranslationsDocsPagesIntroductionFeaturesListIt features_list = _TranslationsDocsPagesIntroductionFeaturesListIt._(_root);
	@override String get notes => 'Note';
	@override String get notes_paragraph_1 => 'Questo pacchetto è ancora in fase di sviluppo e potrebbe subire modifiche in futuro. Procedi con cautela quando utilizzi questo pacchetto in produzione.';
	@override String get notes_paragraph_2 => 'Questo pacchetto non è affiliato a Coui/UI. È un progetto guidato dalla comunità.';
	@override String get faq => 'Domande frequent';
	@override String get faq_gorouter_q => 'Supporta GoRouter?';
	@override String get faq_gorouter_a => 'Sì, lo supporta. Puoi utilizzare GoRouter con coui_flutter.';
	@override String get faq_usage_q => 'Posso usarlo nel mio progetto?';
	@override String get faq_usage_a => 'Sì! Puoi usarlo liberamente per progetti personali e commerciali. Non è richiesta attribuzione.';
	@override String get faq_material_q => 'Posso usarlo con widget Material/Cupertino?';
	@override String get faq_material_a_1 => 'Certo!';
	@override String get faq_material_a_2 => 'Fai riferimento a questa pagina!';
	@override String get faq_style_q => 'Posso impostare quale stile usare? (Default/New York)';
	@override String get faq_style_a_1 => 'Sfortunatamente no. Questo pacchetto supporta solo lo stile New York. Se desideri lo stile predefinito di Coui/UI,';
	@override String get faq_style_a_2 => 'ti consiglio di utilizzare';
	@override String get faq_style_a_3 => 'questo pacchetto. Creatore:';
	@override String get links => 'Link';
	@override String get link_github => 'Github: ';
	@override String get link_pubdev => 'pub.dev: ';
	@override String get link_discord => 'Discord: ';
}

// Path: docs.pages.installation
class _TranslationsDocsPagesInstallationIt extends TranslationsDocsPagesInstallationKo {
	_TranslationsDocsPagesInstallationIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Installazione';
	@override String get description => 'Installare coui_flutter nel progetto';
	@override String get stable_version => 'Versione stabile';
	@override String get experimental_version => 'Versione sperimentale';
	@override String get step1_title => 'Crea un nuovo progetto Flutter';
	@override String get step1_content => 'Utilizza il seguente comando per creare un nuovo progetto Flutter:';
	@override String get step2_title => 'Aggiungi dipendenze';
	@override String get step2_content => 'Ora, aggiungi la dipendenza coui_flutter al progetto.';
	@override String get step3_title => 'Importa il pacchetto';
	@override String get step3_content => 'Ora puoi importare il pacchetto nel codice Dart.';
	@override String get step4_title => 'Aggiungi il widget CouiApp';
	@override String get step4_content => 'Aggiungi il widget CouiApp alla funzione main.';
	@override String get step5_title => 'Esegui l\'app';
	@override String get step5_content => 'Utilizza il seguente comando per eseguire l\'app:';
	@override String get experimental_intro => 'La versione sperimentale è disponibile su GitHub.';
	@override String get experimental_usage => 'Per utilizzare la versione sperimentale, usa git nel file pubspec.yaml invece del numero di versione:';
	@override String get see_page => 'Vedi: ';
	@override String get this_page => 'questa pagina';
	@override String get for_more_info => ' per ulteriori informazioni.';
	@override String get warning_title => 'Attenzione';
	@override String get warning_content => 'La versione sperimentale potrebbe includere modifiche che rompono la compatibilità e non è raccomandata per l\'uso in produzione. Questa versione dovrebbe essere utilizzata solo per test e sviluppo.';
}

// Path: docs.pages.theme
class _TranslationsDocsPagesThemeIt extends TranslationsDocsPagesThemeKo {
	_TranslationsDocsPagesThemeIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tema';
	@override String get description => 'Personalizzazione del tema';
	@override String get custom_color_scheme => 'Schema di colore personalizzato';
	@override String get custom_color_scheme_desc => 'Puoi personalizzare l\'aspetto e la sensazione dell\'app utilizzando uno schema di colori personalizzato.';
	@override String get premade_color_schemes => 'Schema di colori predefiniti';
	@override String get premade_color_schemes_desc => 'Puoi personalizzare l\'aspetto e la sensazione dell\'app utilizzando uno schema di colori predefiniti.';
	@override String get radius => 'Raggio';
	@override String get radius_desc => 'Puoi personalizzare quanto arrotondati appaiono gli elementi dell\'app modificando il raggio.';
	@override String get scaling => 'Scalabilità';
	@override String get scaling_desc => 'Puoi personalizzare la scala dei componenti coui_flutter modificando la scalabilità.';
	@override String get scaling_alert => 'Non ingrandisce/riduce l\'intera app. Solo i componenti coui_flutter sono influenzati.';
	@override String get surface_opacity => 'Opacità della superficie';
	@override String get surface_opacity_desc => 'Puoi personalizzare l\'opacità della superficie modificando il valore dell\'opacità.';
	@override String get surface_blur => 'Sfocatura della superficie';
	@override String get surface_blur_desc => 'Puoi personalizzare la sfocatura della superficie modificando il valore della sfocatura.';
	@override String get code => 'Codice';
	@override String get code_desc => 'Utilizza il seguente codice per applicare lo schema di colori.';
}

// Path: docs.pages.typography
class _TranslationsDocsPagesTypographyIt extends TranslationsDocsPagesTypographyKo {
	_TranslationsDocsPagesTypographyIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tipografia';
	@override String get description => 'Stile del testo';
	@override String get headline1 => 'Titolo 1';
	@override String get headline2 => 'Titolo 2';
	@override String get headline3 => 'Titolo 3';
	@override String get headline4 => 'Titolo 4';
	@override String get paragraph => 'Paragrafo';
	@override String get blockquote => 'Citazione';
	@override String get list => 'Elenco';
	@override String get inline_code => 'Codice inline';
	@override String get lead => 'Lead';
	@override String get large_text => 'Testo grande';
	@override String get small_text => 'Testo piccolo';
	@override String get muted_text => 'Testo smorzato';
	@override String get sans => 'Sans';
	@override String get mono => 'Mono';
	@override String get extra_small => 'Molto piccolo';
	@override String get small => 'Piccolo';
	@override String get base => 'Base';
	@override String get large => 'Grande';
	@override String get extra_large => 'Molto grande';
	@override String get extra_2x_large => 'Molto 2x grande';
	@override String get extra_3x_large => 'Molto 3x grande';
	@override String get extra_4x_large => 'Molto 4x grande';
	@override String get extra_5x_large => 'Molto 5x grande';
	@override String get extra_6x_large => 'Molto 6x grande';
	@override String get extra_7x_large => 'Molto 7x grande';
	@override String get extra_8x_large => 'Molto 8x grande';
	@override String get extra_9x_large => 'Molto 9x grande';
	@override String get thin => 'Sottile';
	@override String get extra_light => 'Molto leggero';
	@override String get light => 'Leggero';
	@override String get normal => 'Normale';
	@override String get medium => 'Medio';
	@override String get semi_bold => 'Semi grassetto';
	@override String get bold => 'Grassetto';
	@override String get extra_bold => 'Molto grassetto';
	@override String get black => 'Nero';
	@override String get italic => 'Corsivo';
}

// Path: docs.pages.layout
class _TranslationsDocsPagesLayoutIt extends TranslationsDocsPagesLayoutKo {
	_TranslationsDocsPagesLayoutIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Layout';
	@override String get description => 'Configurare il layout della pagina';
	@override String get padding => 'Padding';
	@override String get margin => 'Margine';
	@override String get center => 'Centro';
	@override String get gapped_column => 'Colonna con spaziatura';
	@override String get gapped_row => 'Riga con spaziatura';
	@override String get separated_column => 'Colonna separata';
	@override String get separated_row => 'Riga separata';
	@override String get basic_layout => 'Layout di base';
}

// Path: docs.pages.web_preloader
class _TranslationsDocsPagesWebPreloaderIt extends TranslationsDocsPagesWebPreloaderKo {
	_TranslationsDocsPagesWebPreloaderIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Preloader web';
	@override String get description => 'Schermata di caricamento web';
	@override String get step1_title => 'Crea directory web';
	@override String get step1_content => 'Se non hai una directory web, creala.';
	@override String get step1_note => '* Se stai utilizzando il legacy Flutter web, dovrai eseguire l\'aggiornamento utilizzando il comando sopra.';
	@override String get step1_button => 'Clicca qui per ulteriori informazioni.';
	@override String get step2_title => 'Aggiungi script';
	@override String get step2_content => 'Successivamente, scegli e copia uno dei seguenti preloader precompilati:';
	@override String get step2_standard => 'Preloader standard';
	@override String get step3_title => 'Incolla lo script';
	@override String get step3_content_1 => 'Apri il tuo ';
	@override String get step3_content_2 => ' file e incolla lo script all\'interno del tag ';
	@override String get step3_content_3 => '.';
	@override String get step3_example => 'Ad esempio:';
	@override String get step4_title => 'Esegui app';
	@override String get step4_content => 'Usa il seguente comando per eseguire l\'app:';
	@override String get alert_title => 'Contribuire';
	@override String get alert_content_1 => 'Se hai un preloader che desideri condividere, crea una pull request nella directory ';
	@override String get alert_button => 'web_loaders';
	@override String get alert_content_2 => '.';
}

// Path: docs.pages.components_list
class _TranslationsDocsPagesComponentsListIt extends TranslationsDocsPagesComponentsListKo {
	_TranslationsDocsPagesComponentsListIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Componenti';
	@override String get description => 'Elenco di componenti riutilizzabili';
	@override String get work_in_progress => 'Lavori in corso';
	@override String get animation => 'Animazione';
	@override String get disclosure => 'Divulgazione';
	@override String get feedback => 'Feedback';
	@override String get forms => 'Moduli';
	@override String get layout => 'Layout';
	@override String get navigation => 'Navigazione';
	@override String get surfaces => 'Superfici';
	@override String get data_display => 'Visualizzazione dei dati';
	@override String get utilities => 'Utilità';
}

// Path: docs.pages.icons
class _TranslationsDocsPagesIconsIt extends TranslationsDocsPagesIconsKo {
	_TranslationsDocsPagesIconsIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Icone';
	@override String get description => 'Sistema di icone';
	@override String get use_this_code => 'Usa questo codice per visualizzare questa icona:';
	@override String get search_icons => 'Cerca icone';
	@override String get radix_icons => 'Icone Radix';
	@override String get bootstrap_icons => 'Icone Bootstrap';
	@override String get lucide_icons => 'Icone Lucide';
}

// Path: docs.pages.colors
class _TranslationsDocsPagesColorsIt extends TranslationsDocsPagesColorsKo {
	_TranslationsDocsPagesColorsIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Colori';
	@override String get description => 'Palette di colori';
	@override String get use_this_code => 'Usa questo codice per visualizzare questo colore:';
	@override String get color_and_colorshades => 'Costanti Color e ColorShades/ColorSwatch';
	@override String get predefined_colors => 'Colori predefiniti';
	@override String get generate_color => 'Genera colore';
	@override String get hue_shift => 'Spostamento tonalità';
	@override String get saturation_step_up => 'Aumento della saturazione';
	@override String get saturation_step_down => 'Diminuzione della saturazione';
	@override String get lightness_step_up => 'Aumento della luminosità';
	@override String get lightness_step_down => 'Diminuzione della luminosità';
	@override String get cancel => 'Annulla';
	@override String get reset_options => 'Ripristina opzioni';
	@override String get reset_confirmation => 'Vuoi davvero ripristinare le opzioni?';
}

// Path: docs.pages.external
class _TranslationsDocsPagesExternalIt extends TranslationsDocsPagesExternalKo {
	_TranslationsDocsPagesExternalIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Material/Cupertino';
	@override String get description => 'Widget predefiniti di Flutter';
}

// Path: docs.pages.state
class _TranslationsDocsPagesStateIt extends TranslationsDocsPagesStateKo {
	_TranslationsDocsPagesStateIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gestione dello stato';
	@override String get description => 'Modelli di gestione dello stato';
	@override String get intro_1 => 'In Flutter, tutto è un widget e anche dove vengono memorizzati i dati.';
	@override String get intro_2 => 'Internamente, coui_flutter ha il proprio sistema di gestione dello stato. Se stai già utilizzando un sistema di gestione dello stato, puoi continuare ad usare coui_flutter.';
	@override String get passing_data_to_children => 'Passare dati ai figli';
	@override String get passing_data_desc => 'Puoi passare dati ai figli utilizzando il widget Data. Ogni modifica dei dati farà ricostruire i figli.';
	@override String get rebuild_difference_title => 'Hai notato la differenza nel numero di ricostruzioni?';
	@override String get rebuild_difference_content => 'MostInnerWidget viene ricostruito quando i dati cambiano, mentre InnerWidget no. Questo perché InnerWidget non riceve dati.';
	@override String get setting_data_boundary => 'Impostare il confine dei dati';
	@override String get setting_data_boundary_desc => 'Puoi impostare un confine per impedire ai figli di accedere ai dati.';
	@override String get data_methods_vs => 'Data.maybeOf/Data.of vs Data.maybeFind/Data.find';
	@override String get data_methods_desc_1 => ' e ';
	@override String get data_methods_desc_2 => 'ricevono dati e ricostruiscono il widget quando i dati cambiano, mentre ';
	@override String get data_methods_desc_3 => 'resta il valore dei dati senza riceverli.';
	@override String get data_find_usage => 'è utile quando il metodo viene chiamato una sola volta, come onPressed, onLongPressed.';
	@override String get data_of_usage => 'si usa meglio all\'interno del metodo build dove il widget deve essere ricostruito quando i dati cambiano.';
	@override String get getting_data_from_child => 'Ottenere dati dai figli';
	@override String get getting_data_desc_1 => 'Puoi usare il metodo per ottenere dati dai figli. Questo metodo non riceve modifiche nei dati.';
	@override String get getting_data_desc_2 => 'Ricevere dati dai figli può creare un ciclo di ricostruzione infinita. Se hai bisogno di ricevere dati, spostati nel widget padre.';
	@override String get root_data_title => 'Hai notato i dati root?';
	@override String get root_data_content => 'Utilizza i dati dei dati più interni a sinistra. I genitori possono ottenere dati solo dal primo figlio connesso.';
	@override String get setting_messenger_boundary => 'Impostare il confine del DataMessenger';
	@override String get setting_messenger_boundary_desc => 'Puoi impostare un confine per impedire di ottenere dati dai figli di un genitore specifico.';
	@override String get multidata_widget => 'Widget MultiData';
	@override String get multidata_desc => 'Utilizzando il widget MultiData, puoi passare più dati ai figli. Dai un\'occhiata al seguente esempio:';
	@override String get multidata_avoid_nesting => 'Utilizzando MultiData, puoi evitare la nidificazione.';
	@override String get example => 'Esempio';
	@override String get passing_state_as_controller => 'Passare lo stato come controllore';
	@override String get passing_state_controller_desc => 'Puoi passare lo stato ai figli come controllore. In questo modo, i widget figli possono chiamare i metodi del widget padre.';
	@override String get databuilder => 'DataBuilder';
	@override String get databuilder_desc => 'Utilizzando il widget DataBuilder, puoi ricostruire il widget quando i dati cambiano, evitando così di ricostruire l\'intero widget.';
	@override String get datanotifier => 'DataNotifier';
	@override String get datanotifier_desc => 'Utilizzando DataNotifier, puoi passare un valore ai figli da ValueListenable.';
	@override String get example_with_multidata => 'Esempio utilizzando MultiData';
	@override String get passing_object_as_data => 'Passare un oggetto come dati';
	@override String get passing_object_desc => 'Ci sono alcune considerazioni da fare quando si passa un oggetto come dati:';
	@override String get override_equals_hashcode => '1. Sovrascrivere == e hashCode';
	@override String get override_equals_desc => 'Le notifiche vengono inviate ai figli quando un oggetto precedente non è uguale a un nuovo oggetto. Se non sovrascrivi == e hashCode, gli oggetti saranno sempre considerati diversi quando vengono instanziati, anche se i valori dei campi sono uguali.';
	@override String get use_distinctdata => '2. Usare DistinctData';
	@override String get use_distinctdata_desc => 'DistinctData è un mixin che può avvisare i figli quando un campo specifico cambia.';
	@override String get passing_mutable_object => '3. Passare oggetti mutabili ai figli';
	@override String get passing_mutable_object_desc => 'È consigliabile passare oggetti immutabili ai figli. Gli oggetti mutabili (come List, Map, Set, Widget State) non notifica i figli quando l\'oggetto cambia, poiché il riferimento dell\'oggetto non cambia.';
	@override String get passing_variable_to_children => 'Passare variabili ai figli';
	@override String get passing_variable_desc => 'Puoi utilizzare il widget Model per passare variabili ai figli. È simile al widget Data ma con tipi rigorosi e etichettati.';
	@override String get change_variable_from_children => 'Modificare variabili dai figli';
	@override String get change_variable_desc => 'Ci sono due modi per cambiare il valore del modello dai figli:';
	@override String get modelnotifier => 'ModelNotifier';
	@override String get modelnotifier_desc => 'Utilizzando ModelNotifier, puoi passare valori ai figli da ValueNotifier senza dover utilizzare setState nel widget padre.';
	@override String get modellistenable => 'ModelListenable';
	@override String get modellistenable_desc => 'ModelListenable è un ModelNotifier in sola lettura. I figli possono solo ricevere il valore e non possono cambiarlo.';
	@override String get modelbuilder => 'ModelBuilder';
	@override String get modelbuilder_desc => 'ModelBuilder riceve valori e si ricostruisce quando questi cambiano. È simile a DataBuilder ma con tipi rigorosi e etichettati.';
}

// Path: docs.components.accordion
class _TranslationsDocsComponentsAccordionIt extends TranslationsDocsComponentsAccordionKo {
	_TranslationsDocsComponentsAccordionIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Accordione';
	@override String get description => 'Un accordione è un elenco di elementi impilati verticalmente. È possibile \'espandere\' o \'ridurre\' ciascun elemento per visualizzare i contenuti associati.';
	@override late final _TranslationsDocsComponentsAccordionExamplesIt examples = _TranslationsDocsComponentsAccordionExamplesIt._(_root);
}

// Path: docs.components.alert
class _TranslationsDocsComponentsAlertIt extends TranslationsDocsComponentsAlertKo {
	_TranslationsDocsComponentsAlertIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Avviso';
	@override String get description => 'Gli avvisi vengono utilizzati per comunicare stati che influenzano il sistema.';
	@override late final _TranslationsDocsComponentsAlertExamplesIt examples = _TranslationsDocsComponentsAlertExamplesIt._(_root);
	@override String get title => 'Titolo dell\'avviso';
	@override String get content => 'Questo è il contenuto dell\'avviso.';
}

// Path: docs.components.alert_dialog
class _TranslationsDocsComponentsAlertDialogIt extends TranslationsDocsComponentsAlertDialogKo {
	_TranslationsDocsComponentsAlertDialogIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Dialogo di avviso';
	@override String get description => 'Il dialogo di avviso mostra informazioni importanti che richiedono l\'attenzione dell\'utente.';
	@override late final _TranslationsDocsComponentsAlertDialogExamplesIt examples = _TranslationsDocsComponentsAlertDialogExamplesIt._(_root);
	@override String get click_here => 'Clicca qui';
	@override String get alert_title => 'Titolo dell\'avviso';
	@override String get alert_content => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
}

// Path: docs.components.animated_value_builder
class _TranslationsDocsComponentsAnimatedValueBuilderIt extends TranslationsDocsComponentsAnimatedValueBuilderKo {
	_TranslationsDocsComponentsAnimatedValueBuilderIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Costruttore di valori animati';
	@override String get description => 'Un costruttore che applica automaticamente animazioni quando i valori cambiano.';
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderExamplesIt examples = _TranslationsDocsComponentsAnimatedValueBuilderExamplesIt._(_root);
}

// Path: docs.components.app_bar
class _TranslationsDocsComponentsAppBarIt extends TranslationsDocsComponentsAppBarKo {
	_TranslationsDocsComponentsAppBarIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barra dell\'app';
	@override String get description => 'La barra dell\'app è un elemento di navigazione di base visualizzato nella parte superiore dell\'app.';
	@override late final _TranslationsDocsComponentsAppBarExamplesIt examples = _TranslationsDocsComponentsAppBarExamplesIt._(_root);
}

// Path: docs.components.autocomplete
class _TranslationsDocsComponentsAutocompleteIt extends TranslationsDocsComponentsAutocompleteKo {
	_TranslationsDocsComponentsAutocompleteIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Autocompletamento';
	@override String get description => 'Un campo di input che mostra suggerimenti in base all\'input dell\'utente.';
	@override late final _TranslationsDocsComponentsAutocompleteExamplesIt examples = _TranslationsDocsComponentsAutocompleteExamplesIt._(_root);
}

// Path: docs.components.avatar
class _TranslationsDocsComponentsAvatarIt extends TranslationsDocsComponentsAvatarKo {
	_TranslationsDocsComponentsAvatarIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Avatar';
	@override String get description => 'Un\'immagine o un\'icona che rappresenta un utente o un\'entità.';
	@override late final _TranslationsDocsComponentsAvatarExamplesIt examples = _TranslationsDocsComponentsAvatarExamplesIt._(_root);
}

// Path: docs.components.avatar_group
class _TranslationsDocsComponentsAvatarGroupIt extends TranslationsDocsComponentsAvatarGroupKo {
	_TranslationsDocsComponentsAvatarGroupIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Gruppo di avatar';
	@override String get description => 'Visualizza più avatar insieme.';
	@override late final _TranslationsDocsComponentsAvatarGroupExamplesIt examples = _TranslationsDocsComponentsAvatarGroupExamplesIt._(_root);
}

// Path: docs.components.badge
class _TranslationsDocsComponentsBadgeIt extends TranslationsDocsComponentsBadgeKo {
	_TranslationsDocsComponentsBadgeIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Distintivo';
	@override String get description => 'Un piccolo etichetta che mostra lo stato o il numero di notifiche.';
	@override late final _TranslationsDocsComponentsBadgeExamplesIt examples = _TranslationsDocsComponentsBadgeExamplesIt._(_root);
	@override String get primary => 'Primario';
	@override String get secondary => 'Secondario';
	@override String get outline => 'Contorno';
	@override String get destructive => 'Distruttivo';
}

// Path: docs.components.breadcrumb
class _TranslationsDocsComponentsBreadcrumbIt extends TranslationsDocsComponentsBreadcrumbKo {
	_TranslationsDocsComponentsBreadcrumbIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Briciole di pane';
	@override String get description => 'Le briciole di pane sono un sistema di navigazione secondario che mostra la posizione dell\'utente in un sito web o un\'applicazione web.';
	@override late final _TranslationsDocsComponentsBreadcrumbExamplesIt examples = _TranslationsDocsComponentsBreadcrumbExamplesIt._(_root);
	@override String get home => 'Home';
	@override String get components => 'Componenti';
}

// Path: docs.components.button
class _TranslationsDocsComponentsButtonIt extends TranslationsDocsComponentsButtonKo {
	_TranslationsDocsComponentsButtonIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Pulsante';
	@override String get description => 'I pulsanti consentono all\'utente di eseguire un\'azione o selezionare un\'opzione con un singolo tocco.';
	@override late final _TranslationsDocsComponentsButtonExamplesIt examples = _TranslationsDocsComponentsButtonExamplesIt._(_root);
	@override String get primary => 'Primario';
	@override String get secondary => 'Secondario';
	@override String get outlined => 'Contornato';
	@override String get ghost => 'Ghost';
	@override String get destructive => 'Distruttivo';
	@override String get link => 'Link';
	@override String get outline => 'Contorno';
	@override String get text => 'Testo';
	@override String get extra_small => 'Extra piccolo';
	@override String get small => 'Piccolo';
	@override String get normal => 'Normale';
	@override String get large => 'Grande';
	@override String get extra_large => 'Extra grande';
	@override String get save => 'Salva';
	@override String get cancel => 'Annulla';
	@override String get close => 'Chiudi';
	@override String get submit => 'Invia';
	@override String get edit_profile => 'Modifica profilo';
	@override String get save_changes => 'Salva modifiche';
	@override String get undo => 'Annulla';
	@override String get compact => 'Compatto';
	@override String get dense => 'Denso';
	@override String get comfortable => 'Confortevole';
	@override String get icon => 'Icona';
	@override String get icon_comfortable => 'Icona Confortevole';
	@override String get rectangle => 'Rettangolo';
	@override String get add => 'Aggiungi';
	@override String get focused => 'Focalizzato';
	@override String get hovered => 'Sopra';
	@override String get pressed => 'Premuto';
	@override String get text_button => 'Pulsante di testo';
	@override String get custom_button => 'Pulsante personalizzato';
}

// Path: docs.components.calendar
class _TranslationsDocsComponentsCalendarIt extends TranslationsDocsComponentsCalendarKo {
	_TranslationsDocsComponentsCalendarIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Calendario';
	@override String get description => 'Un componente calendario per selezionare e visualizzare le date.';
	@override late final _TranslationsDocsComponentsCalendarExamplesIt examples = _TranslationsDocsComponentsCalendarExamplesIt._(_root);
}

// Path: docs.components.card
class _TranslationsDocsComponentsCardIt extends TranslationsDocsComponentsCardKo {
	_TranslationsDocsComponentsCardIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Scheda';
	@override String get description => 'Descrizione';
	@override late final _TranslationsDocsComponentsCardExamplesIt examples = _TranslationsDocsComponentsCardExamplesIt._(_root);
	@override String get create_project => 'Crea progetto';
	@override String get deploy_description => 'Distribuisci un nuovo progetto con un solo clic';
	@override String get name => 'Nome';
	@override String get name_placeholder => 'Nome del progetto';
	@override String get description_placeholder => 'Descrizione del progetto';
	@override String get deploy => 'Distribuisci';
}

// Path: docs.components.card_image
class _TranslationsDocsComponentsCardImageIt extends TranslationsDocsComponentsCardImageKo {
	_TranslationsDocsComponentsCardImageIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Scheda immagine';
	@override String get description => 'Un componente scheda che include un\'immagine.';
	@override late final _TranslationsDocsComponentsCardImageExamplesIt examples = _TranslationsDocsComponentsCardImageExamplesIt._(_root);
	@override String get card_image_title => 'Immagine della scheda';
	@override String get card_clicked => 'Hai cliccato sull\'immagine della scheda';
	@override String card_number({required Object n}) => 'Numero della scheda ${n}';
	@override String get lorem_ipsum => 'Lorem ipsum dolor sit amet';
}

// Path: docs.components.carousel
class _TranslationsDocsComponentsCarouselIt extends TranslationsDocsComponentsCarouselKo {
	_TranslationsDocsComponentsCarouselIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Carosello';
	@override String get description => 'Un componente che mostra più elementi in slideshow.';
	@override late final _TranslationsDocsComponentsCarouselExamplesIt examples = _TranslationsDocsComponentsCarouselExamplesIt._(_root);
}

// Path: docs.components.checkbox
class _TranslationsDocsComponentsCheckboxIt extends TranslationsDocsComponentsCheckboxKo {
	_TranslationsDocsComponentsCheckboxIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Casella di controllo';
	@override String get description => 'La casella di controllo consente all\'utente di selezionare uno o più elementi da un elenco.';
	@override late final _TranslationsDocsComponentsCheckboxExamplesIt examples = _TranslationsDocsComponentsCheckboxExamplesIt._(_root);
	@override String get remember_me => 'Ricordami';
}

// Path: docs.components.chip
class _TranslationsDocsComponentsChipIt extends TranslationsDocsComponentsChipKo {
	_TranslationsDocsComponentsChipIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Chip';
	@override String get description => 'I chip sono piccoli elementi che rappresentano attributi, opzioni o azioni.';
	@override late final _TranslationsDocsComponentsChipExamplesIt examples = _TranslationsDocsComponentsChipExamplesIt._(_root);
	@override String get apple => 'Mela';
	@override String get banana => 'Banana';
	@override String get cherry => 'Ciliegia';
	@override String get durian => 'Durian';
	@override String get elderberry => 'Sambuco';
}

// Path: docs.components.chip_input
class _TranslationsDocsComponentsChipInputIt extends TranslationsDocsComponentsChipInputKo {
	_TranslationsDocsComponentsChipInputIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Input chip';
	@override String get description => 'Un campo di input che consente di inserire più valori in forma di chip.';
	@override late final _TranslationsDocsComponentsChipInputExamplesIt examples = _TranslationsDocsComponentsChipInputExamplesIt._(_root);
}

// Path: docs.components.circular_progress
class _TranslationsDocsComponentsCircularProgressIt extends TranslationsDocsComponentsCircularProgressKo {
	_TranslationsDocsComponentsCircularProgressIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Progresso circolare';
	@override String get description => 'Indicatore di avanzamento circolare.';
	@override late final _TranslationsDocsComponentsCircularProgressExamplesIt examples = _TranslationsDocsComponentsCircularProgressExamplesIt._(_root);
	@override String get increase_by_10 => 'Aumenta di 10';
	@override String get decrease_by_10 => 'Diminuisci di 10';
}

// Path: docs.components.code_snippet
class _TranslationsDocsComponentsCodeSnippetIt extends TranslationsDocsComponentsCodeSnippetKo {
	_TranslationsDocsComponentsCodeSnippetIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Snippet di codice';
	@override String get description => 'Un componente che visualizza un codice.';
	@override late final _TranslationsDocsComponentsCodeSnippetExamplesIt examples = _TranslationsDocsComponentsCodeSnippetExamplesIt._(_root);
}

// Path: docs.components.collapsible
class _TranslationsDocsComponentsCollapsibleIt extends TranslationsDocsComponentsCollapsibleKo {
	_TranslationsDocsComponentsCollapsibleIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Collapsabile';
	@override String get description => 'Un contenitore di contenuti che può essere ripiegato o aperto.';
	@override late final _TranslationsDocsComponentsCollapsibleExamplesIt examples = _TranslationsDocsComponentsCollapsibleExamplesIt._(_root);
	@override String get starred_repositories => '@coco-de ha messo stelle a 3 repository';
	@override String get collapse_all => 'Ripiega tutto';
	@override String get expand_all => 'Espandi tutto';
	@override String get expand_icon => 'Espandi icona';
	@override String get use_path_branch => 'Usa branch di percorso';
	@override String get recursive_selection => 'Selezione ricorsiva';
}

// Path: docs.components.color_picker
class _TranslationsDocsComponentsColorPickerIt extends TranslationsDocsComponentsColorPickerKo {
	_TranslationsDocsComponentsColorPickerIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Selettore di colore';
	@override String get description => 'Un componente per scegliere colori.';
	@override late final _TranslationsDocsComponentsColorPickerExamplesIt examples = _TranslationsDocsComponentsColorPickerExamplesIt._(_root);
	@override String get pick_color => 'Scegli colore';
	@override String color_label({required Object color}) => 'Colore: ${color}';
	@override String get select_color => 'Seleziona colore';
	@override String get open_color_picker_popover => 'Apri popover selettore di colore';
	@override String get open_color_picker_dialog => 'Apri dialogo selettore di colore';
}

// Path: docs.components.command
class _TranslationsDocsComponentsCommandIt extends TranslationsDocsComponentsCommandKo {
	_TranslationsDocsComponentsCommandIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Comando';
	@override String get description => 'Il comando è un componente che consente di cercare elementi.';
	@override late final _TranslationsDocsComponentsCommandExamplesIt examples = _TranslationsDocsComponentsCommandExamplesIt._(_root);
}

// Path: docs.components.context_menu
class _TranslationsDocsComponentsContextMenuIt extends TranslationsDocsComponentsContextMenuKo {
	_TranslationsDocsComponentsContextMenuIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Menu contestuale';
	@override String get description => 'Un menu che viene visualizzato con un clic destro o a lungo.';
	@override late final _TranslationsDocsComponentsContextMenuExamplesIt examples = _TranslationsDocsComponentsContextMenuExamplesIt._(_root);
}

// Path: docs.components.date_picker
class _TranslationsDocsComponentsDatePickerIt extends TranslationsDocsComponentsDatePickerKo {
	_TranslationsDocsComponentsDatePickerIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Selettore di data';
	@override String get description => 'Un campo di input per selezionare una data.';
	@override late final _TranslationsDocsComponentsDatePickerExamplesIt examples = _TranslationsDocsComponentsDatePickerExamplesIt._(_root);
	@override String get select_date => 'Seleziona data';
	@override String get select_date_range => 'Seleziona intervallo di date';
}

// Path: docs.components.dialog
class _TranslationsDocsComponentsDialogIt extends TranslationsDocsComponentsDialogKo {
	_TranslationsDocsComponentsDialogIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Dialogo';
	@override String get description => 'Il dialogo è una finestra modale che viene visualizzata sopra il resto dell\'app.';
	@override late final _TranslationsDocsComponentsDialogExamplesIt examples = _TranslationsDocsComponentsDialogExamplesIt._(_root);
	@override String get edit_profile_title => 'Modifica profilo';
	@override String get edit_profile_description => 'Modifica qui il tuo profilo. Fai clic su Salva quando hai finito.';
	@override String get name_label => 'Nome';
	@override String get username_label => 'Nome utente';
	@override String get hello => 'Ciao';
	@override String get material_dialog_content => 'Dialogo di Material.';
	@override String get cupertino_dialog_content => 'Dialogo di Cupertino.';
	@override String get alert_title => 'Titolo dell\'avviso';
	@override String get click_here => 'Clicca qui';
	@override String get ok => 'OK';
	@override String get open_material_dialog => 'Apri dialogo di Material';
	@override String get open_cupertino_dialog => 'Apri dialogo di Cupertino';
	@override String get open_coui_dialog => 'Apri dialogo COUI';
}

// Path: docs.components.divider
class _TranslationsDocsComponentsDividerIt extends TranslationsDocsComponentsDividerKo {
	_TranslationsDocsComponentsDividerIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Divisore';
	@override String get description => 'Una linea che separa visivamente i contenuti.';
	@override late final _TranslationsDocsComponentsDividerExamplesIt examples = _TranslationsDocsComponentsDividerExamplesIt._(_root);
	@override String get item_1 => 'Elemento 1';
	@override String get item_2 => 'Elemento 2';
	@override String get item_3 => 'Elemento 3';
	@override String get divider => 'Divisore';
}

// Path: docs.components.dot_indicator
class _TranslationsDocsComponentsDotIndicatorIt extends TranslationsDocsComponentsDotIndicatorKo {
	_TranslationsDocsComponentsDotIndicatorIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Indicatore a punto';
	@override String get description => 'Un indicatore che mostra la posizione attuale con un punto.';
	@override late final _TranslationsDocsComponentsDotIndicatorExamplesIt examples = _TranslationsDocsComponentsDotIndicatorExamplesIt._(_root);
}

// Path: docs.components.drawer
class _TranslationsDocsComponentsDrawerIt extends TranslationsDocsComponentsDrawerKo {
	_TranslationsDocsComponentsDrawerIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Cassetto';
	@override String get description => 'Un pannello che scorre dal bordo dello schermo.';
	@override late final _TranslationsDocsComponentsDrawerExamplesIt examples = _TranslationsDocsComponentsDrawerExamplesIt._(_root);
	@override String get open_drawer => 'Apri cassetto';
	@override String get close_drawer => 'Chiudi cassetto';
	@override String get open_another_drawer => 'Apri un altro cassetto';
	@override String drawer_at({required Object count, required Object position}) => 'Cassetto ${count} at ${position}';
}

// Path: docs.components.dropdown_menu
class _TranslationsDocsComponentsDropdownMenuIt extends TranslationsDocsComponentsDropdownMenuKo {
	_TranslationsDocsComponentsDropdownMenuIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Menu a discesa';
	@override String get description => 'Un menu che mostra un elenco di opzioni selezionabili.';
	@override late final _TranslationsDocsComponentsDropdownMenuExamplesIt examples = _TranslationsDocsComponentsDropdownMenuExamplesIt._(_root);
}

// Path: docs.components.expandable_sidebar
class _TranslationsDocsComponentsExpandableSidebarIt extends TranslationsDocsComponentsExpandableSidebarKo {
	_TranslationsDocsComponentsExpandableSidebarIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Sidebar espandibile';
	@override String get description => 'Una barra laterale che può essere espansa e ridotta.';
	@override late final _TranslationsDocsComponentsExpandableSidebarExamplesIt examples = _TranslationsDocsComponentsExpandableSidebarExamplesIt._(_root);
}

// Path: docs.components.form
class _TranslationsDocsComponentsFormIt extends TranslationsDocsComponentsFormKo {
	_TranslationsDocsComponentsFormIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Modulo';
	@override String get description => 'Un widget helper per creare facilmente la validazione del modulo.';
	@override late final _TranslationsDocsComponentsFormExamplesIt examples = _TranslationsDocsComponentsFormExamplesIt._(_root);
	@override String get username_label => 'Nome utente';
	@override String get username_hint => 'Nome pubblico';
	@override String get password_label => 'Password';
	@override String get confirm_password_label => 'Conferma password';
	@override String get passwords_do_not_match => 'Le password non corrispondono';
	@override String get agree_terms => 'Accetto i termini e le condizioni';
	@override String get must_agree_terms => 'Devi accettare i termini e le condizioni';
	@override String get form_values_title => 'Valori del modulo';
	@override String get register => 'Registrati';
	@override String get username_already_taken => 'Nome utente già preso';
	@override String get email => 'Email';
	@override String username_display({required Object value}) => 'Nome utente: ${value}';
	@override String password_display({required Object value}) => 'Password: ${value}';
	@override String confirm_password_display({required Object value}) => 'Conferma password: ${value}';
	@override String agree_display({required Object value}) => 'Accordo: ${value}';
	@override String json_display({required Object value}) => 'JSON: ${value}';
	@override String submitted_value_display({required Object value}) => 'Valore inviato: ${value}';
	@override String get login => 'Accedi';
	@override String get sign_up => 'Registrati';
	@override String get dont_have_account => 'Non hai un account?';
	@override String get already_have_account => 'Hai già un account?';
}

// Path: docs.components.formatted_input
class _TranslationsDocsComponentsFormattedInputIt extends TranslationsDocsComponentsFormattedInputKo {
	_TranslationsDocsComponentsFormattedInputIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Input formattato';
	@override String get description => 'Un campo di testo che accetta input in un formato specifico.';
	@override late final _TranslationsDocsComponentsFormattedInputExamplesIt examples = _TranslationsDocsComponentsFormattedInputExamplesIt._(_root);
}

// Path: docs.components.hover_card
class _TranslationsDocsComponentsHoverCardIt extends TranslationsDocsComponentsHoverCardKo {
	_TranslationsDocsComponentsHoverCardIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Scheda hover';
	@override String get description => 'Una scheda che appare quando si passa il mouse.';
	@override late final _TranslationsDocsComponentsHoverCardExamplesIt examples = _TranslationsDocsComponentsHoverCardExamplesIt._(_root);
	@override String get flutter_handle => '@flutter';
	@override String get flutter_username => 'Flutter';
	@override String get flutter_description => 'Il Flutter SDK fornisce strumenti per costruire bellissime app per mobile, web e desktop da un\'unica base di codice.';
}

// Path: docs.components.input
class _TranslationsDocsComponentsInputIt extends TranslationsDocsComponentsInputKo {
	_TranslationsDocsComponentsInputIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Input';
	@override String get description => 'Campo di input di testo.';
	@override late final _TranslationsDocsComponentsInputExamplesIt examples = _TranslationsDocsComponentsInputExamplesIt._(_root);
	@override String get enter_name => 'Inserisci il tuo nome';
	@override String get enter_username => 'Inserisci il tuo nome utente';
	@override String get username_already_taken => 'Nome utente già preso';
	@override String get hello_world => 'Ciao Mondo!';
	@override String get search_something => 'Cerca qualcosa...';
	@override String get email => 'Email';
	@override String get password => 'Inserisci la tua password';
	@override String get username_hint => 'Questo è per il tuo nome utente';
}

// Path: docs.components.input_otp
class _TranslationsDocsComponentsInputOtpIt extends TranslationsDocsComponentsInputOtpKo {
	_TranslationsDocsComponentsInputOtpIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Input OTP';
	@override String get description => 'Campo per inserire una password monouso.';
	@override late final _TranslationsDocsComponentsInputOtpExamplesIt examples = _TranslationsDocsComponentsInputOtpExamplesIt._(_root);
}

// Path: docs.components.item_picker
class _TranslationsDocsComponentsItemPickerIt extends TranslationsDocsComponentsItemPickerKo {
	_TranslationsDocsComponentsItemPickerIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Selettore di elementi';
	@override String get description => 'Un componente per selezionare un elemento da un elenco.';
	@override late final _TranslationsDocsComponentsItemPickerExamplesIt examples = _TranslationsDocsComponentsItemPickerExamplesIt._(_root);
}

// Path: docs.components.keyboard_display
class _TranslationsDocsComponentsKeyboardDisplayIt extends TranslationsDocsComponentsKeyboardDisplayKo {
	_TranslationsDocsComponentsKeyboardDisplayIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Visualizzazione tastiera';
	@override String get description => 'Un componente che visualizza le scorciatoie da tastiera.';
	@override late final _TranslationsDocsComponentsKeyboardDisplayExamplesIt examples = _TranslationsDocsComponentsKeyboardDisplayExamplesIt._(_root);
}

// Path: docs.components.linear_progress
class _TranslationsDocsComponentsLinearProgressIt extends TranslationsDocsComponentsLinearProgressKo {
	_TranslationsDocsComponentsLinearProgressIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Progresso lineare';
	@override String get description => 'Indicatore di avanzamento lineare.';
	@override late final _TranslationsDocsComponentsLinearProgressExamplesIt examples = _TranslationsDocsComponentsLinearProgressExamplesIt._(_root);
	@override String get increase => 'Aumenta';
	@override String get decrease => 'Diminuisci';
}

// Path: docs.components.material
class _TranslationsDocsComponentsMaterialIt extends TranslationsDocsComponentsMaterialKo {
	_TranslationsDocsComponentsMaterialIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Material/Cupertino';
	@override String get description => 'Come utilizzare i widget Material e Cupertino predefiniti di Flutter.';
	@override late final _TranslationsDocsComponentsMaterialExamplesIt examples = _TranslationsDocsComponentsMaterialExamplesIt._(_root);
	@override String get my_material_app => 'La mia app Material';
	@override String get my_cupertino_app => 'La mia app Cupertino';
	@override String you_pushed_button({required Object count}) => 'Hai premuto il pulsante ${count} volte';
	@override String get open_material_dialog => 'Apri dialogo di Material';
	@override String get open_cupertino_dialog => 'Apri dialogo di Cupertino';
	@override String get open_coui_dialog => 'Apri dialogo COUI';
}

// Path: docs.components.menubar
class _TranslationsDocsComponentsMenubarIt extends TranslationsDocsComponentsMenubarKo {
	_TranslationsDocsComponentsMenubarIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barra dei menu';
	@override String get description => 'Una barra dei menu orizzontale.';
	@override late final _TranslationsDocsComponentsMenubarExamplesIt examples = _TranslationsDocsComponentsMenubarExamplesIt._(_root);
	@override String get file => 'File';
	@override String get edit => 'Modifica';
	@override String get new_tab => 'Nuova scheda';
	@override String get new_window => 'Nuova finestra';
	@override String get new_incognito_window => 'Nuova finestra in incognito';
	@override String get email_link => 'Link email';
	@override String get messages => 'Messaggi';
	@override String get notes => 'Note';
	@override String get share => 'Condividi';
	@override String get print => 'Stampa';
	@override String get save_and_exit => 'Salva e esci';
	@override String get discard_and_exit => 'Annulla e esci';
	@override String get exit => 'Esci';
	@override String get undo => 'Annulla';
	@override String get redo => 'Ripeti';
}

// Path: docs.components.multiselect
class _TranslationsDocsComponentsMultiselectIt extends TranslationsDocsComponentsMultiselectKo {
	_TranslationsDocsComponentsMultiselectIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Selezione multipla';
	@override String get description => 'Un componente che consente di selezionare più elementi.';
	@override late final _TranslationsDocsComponentsMultiselectExamplesIt examples = _TranslationsDocsComponentsMultiselectExamplesIt._(_root);
}

// Path: docs.components.navigation_bar
class _TranslationsDocsComponentsNavigationBarIt extends TranslationsDocsComponentsNavigationBarKo {
	_TranslationsDocsComponentsNavigationBarIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barra di navigazione';
	@override String get description => 'Una barra di navigazione in basso.';
	@override late final _TranslationsDocsComponentsNavigationBarExamplesIt examples = _TranslationsDocsComponentsNavigationBarExamplesIt._(_root);
}

// Path: docs.components.navigation_menu
class _TranslationsDocsComponentsNavigationMenuIt extends TranslationsDocsComponentsNavigationMenuKo {
	_TranslationsDocsComponentsNavigationMenuIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Menu di navigazione';
	@override String get description => 'Un componente di menu di navigazione.';
	@override late final _TranslationsDocsComponentsNavigationMenuExamplesIt examples = _TranslationsDocsComponentsNavigationMenuExamplesIt._(_root);
}

// Path: docs.components.navigation_rail
class _TranslationsDocsComponentsNavigationRailIt extends TranslationsDocsComponentsNavigationRailKo {
	_TranslationsDocsComponentsNavigationRailIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Binario di navigazione';
	@override String get description => 'Un binario di navigazione laterale.';
	@override late final _TranslationsDocsComponentsNavigationRailExamplesIt examples = _TranslationsDocsComponentsNavigationRailExamplesIt._(_root);
}

// Path: docs.components.navigation_sidebar
class _TranslationsDocsComponentsNavigationSidebarIt extends TranslationsDocsComponentsNavigationSidebarKo {
	_TranslationsDocsComponentsNavigationSidebarIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Sidebar di navigazione';
	@override String get description => 'Un componente di sidebar di navigazione.';
	@override late final _TranslationsDocsComponentsNavigationSidebarExamplesIt examples = _TranslationsDocsComponentsNavigationSidebarExamplesIt._(_root);
}

// Path: docs.components.number_input
class _TranslationsDocsComponentsNumberInputIt extends TranslationsDocsComponentsNumberInputKo {
	_TranslationsDocsComponentsNumberInputIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Input numerico';
	@override String get description => 'Un campo per inserire numeri.';
	@override late final _TranslationsDocsComponentsNumberInputExamplesIt examples = _TranslationsDocsComponentsNumberInputExamplesIt._(_root);
	@override String value({required Object value}) => 'Valore: ${value}';
}

// Path: docs.components.number_ticker
class _TranslationsDocsComponentsNumberTickerIt extends TranslationsDocsComponentsNumberTickerKo {
	_TranslationsDocsComponentsNumberTickerIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Ticker numerico';
	@override String get description => 'Mostra un\'animazione quando il numero cambia.';
	@override late final _TranslationsDocsComponentsNumberTickerExamplesIt examples = _TranslationsDocsComponentsNumberTickerExamplesIt._(_root);
}

// Path: docs.components.overflow_marquee
class _TranslationsDocsComponentsOverflowMarqueeIt extends TranslationsDocsComponentsOverflowMarqueeKo {
	_TranslationsDocsComponentsOverflowMarqueeIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Marquee overflow';
	@override String get description => 'Scorre automaticamente quando il testo è troppo lungo.';
	@override late final _TranslationsDocsComponentsOverflowMarqueeExamplesIt examples = _TranslationsDocsComponentsOverflowMarqueeExamplesIt._(_root);
}

// Path: docs.components.pagination
class _TranslationsDocsComponentsPaginationIt extends TranslationsDocsComponentsPaginationKo {
	_TranslationsDocsComponentsPaginationIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Paginazione';
	@override String get description => 'Un componente per navigare tra le pagine.';
	@override late final _TranslationsDocsComponentsPaginationExamplesIt examples = _TranslationsDocsComponentsPaginationExamplesIt._(_root);
}

// Path: docs.components.phone_input
class _TranslationsDocsComponentsPhoneInputIt extends TranslationsDocsComponentsPhoneInputKo {
	_TranslationsDocsComponentsPhoneInputIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Input telefono';
	@override String get description => 'Un campo per inserire un numero di telefono.';
	@override late final _TranslationsDocsComponentsPhoneInputExamplesIt examples = _TranslationsDocsComponentsPhoneInputExamplesIt._(_root);
}

// Path: docs.components.popover
class _TranslationsDocsComponentsPopoverIt extends TranslationsDocsComponentsPopoverKo {
	_TranslationsDocsComponentsPopoverIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Popover';
	@override String get description => 'Un popup che viene visualizzato sopra un elemento.';
	@override late final _TranslationsDocsComponentsPopoverExamplesIt examples = _TranslationsDocsComponentsPopoverExamplesIt._(_root);
	@override String get dimensions => 'Dimensioni';
	@override String get set_dimensions => 'Imposta le dimensioni del layer';
	@override String get width => 'Larghezza';
	@override String get max_width => 'Larghezza massima';
	@override String get height => 'Altezza';
	@override String get max_height => 'Altezza massima';
	@override String get open_popover => 'Apri popover';
	@override String get submit => 'Invia';
}

// Path: docs.components.progress
class _TranslationsDocsComponentsProgressIt extends TranslationsDocsComponentsProgressKo {
	_TranslationsDocsComponentsProgressIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Progresso';
	@override String get description => 'Mostra lo stato di avanzamento.';
	@override late final _TranslationsDocsComponentsProgressExamplesIt examples = _TranslationsDocsComponentsProgressExamplesIt._(_root);
}

// Path: docs.components.radio_card
class _TranslationsDocsComponentsRadioCardIt extends TranslationsDocsComponentsRadioCardKo {
	_TranslationsDocsComponentsRadioCardIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Carta radio';
	@override String get description => 'Un pulsante radio a forma di scheda.';
	@override late final _TranslationsDocsComponentsRadioCardExamplesIt examples = _TranslationsDocsComponentsRadioCardExamplesIt._(_root);
}

// Path: docs.components.radio_group
class _TranslationsDocsComponentsRadioGroupIt extends TranslationsDocsComponentsRadioGroupKo {
	_TranslationsDocsComponentsRadioGroupIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Gruppo radio';
	@override String get description => 'Un gruppo di pulsanti radio.';
	@override late final _TranslationsDocsComponentsRadioGroupExamplesIt examples = _TranslationsDocsComponentsRadioGroupExamplesIt._(_root);
	@override String get option_1 => 'Opzione 1';
	@override String get option_2 => 'Opzione 2';
	@override String get option_3 => 'Opzione 3';
	@override String get selected => 'Selezionato';
}

// Path: docs.components.refresh_trigger
class _TranslationsDocsComponentsRefreshTriggerIt extends TranslationsDocsComponentsRefreshTriggerKo {
	_TranslationsDocsComponentsRefreshTriggerIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Trigger di aggiornamento';
	@override String get description => 'Offre la possibilità di tirare per aggiornare.';
	@override late final _TranslationsDocsComponentsRefreshTriggerExamplesIt examples = _TranslationsDocsComponentsRefreshTriggerExamplesIt._(_root);
	@override String get pull_me => 'Tira per favore';
	@override String get refresh => 'Aggiorna';
}

// Path: docs.components.repeated_animation_builder
class _TranslationsDocsComponentsRepeatedAnimationBuilderIt extends TranslationsDocsComponentsRepeatedAnimationBuilderKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Costruttore di animazione ripetuta';
	@override String get description => 'Un costruttore che ripete l\'animazione.';
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesIt examples = _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesIt._(_root);
}

// Path: docs.components.resizable
class _TranslationsDocsComponentsResizableIt extends TranslationsDocsComponentsResizableKo {
	_TranslationsDocsComponentsResizableIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Ridimensionabile';
	@override String get description => 'Un contenitore che può essere ridimensionato.';
	@override late final _TranslationsDocsComponentsResizableExamplesIt examples = _TranslationsDocsComponentsResizableExamplesIt._(_root);
}

// Path: docs.components.scaffold
class _TranslationsDocsComponentsScaffoldIt extends TranslationsDocsComponentsScaffoldKo {
	_TranslationsDocsComponentsScaffoldIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Scaffold';
	@override String get description => 'Lo scaffold è il contenitore di livello superiore della pagina.';
	@override late final _TranslationsDocsComponentsScaffoldExamplesIt examples = _TranslationsDocsComponentsScaffoldExamplesIt._(_root);
}

// Path: docs.components.select
class _TranslationsDocsComponentsSelectIt extends TranslationsDocsComponentsSelectKo {
	_TranslationsDocsComponentsSelectIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Seleziona';
	@override String get description => 'Permette di scegliere un elemento da un elenco di opzioni.';
	@override late final _TranslationsDocsComponentsSelectExamplesIt examples = _TranslationsDocsComponentsSelectExamplesIt._(_root);
	@override String get placeholder => 'Seleziona un frutto';
	@override String get search_fruit => 'Cerca frutto';
	@override String get no_fruit_found => 'Nessun frutto trovato';
	@override String get apple => 'Mela';
	@override String get banana => 'Banana';
	@override String get cherry => 'Ciliegia';
	@override String get lemon => 'Limone';
	@override String get tomato => 'Pomodoro';
	@override String get red_apple => 'Mela rossa';
	@override String get green_apple => 'Mela verde';
	@override String get yellow_banana => 'Banana gialla';
	@override String get brown_banana => 'Banana marrone';
	@override String get yellow_lemon => 'Limone giallo';
	@override String get green_lemon => 'Limone verde';
	@override String get red => 'Rosso';
	@override String get green => 'Verde';
	@override String get yellow => 'Giallo';
	@override String get brown => 'Marrone';
}

// Path: docs.components.sheet
class _TranslationsDocsComponentsSheetIt extends TranslationsDocsComponentsSheetKo {
	_TranslationsDocsComponentsSheetIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Foglietto';
	@override String get description => 'Un foglietto che emerge dal basso.';
	@override late final _TranslationsDocsComponentsSheetExamplesIt examples = _TranslationsDocsComponentsSheetExamplesIt._(_root);
}

// Path: docs.components.skeleton
class _TranslationsDocsComponentsSkeletonIt extends TranslationsDocsComponentsSkeletonKo {
	_TranslationsDocsComponentsSkeletonIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Scheletro';
	@override String get description => 'Uno schermo scheletro visualizzato durante il caricamento.';
	@override late final _TranslationsDocsComponentsSkeletonExamplesIt examples = _TranslationsDocsComponentsSkeletonExamplesIt._(_root);
}

// Path: docs.components.slider
class _TranslationsDocsComponentsSliderIt extends TranslationsDocsComponentsSliderKo {
	_TranslationsDocsComponentsSliderIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Slider';
	@override String get description => 'Permette di scegliere un valore scorrendo.';
	@override late final _TranslationsDocsComponentsSliderExamplesIt examples = _TranslationsDocsComponentsSliderExamplesIt._(_root);
	@override String value_single({required Object value}) => 'Valore: ${value}';
	@override String value_range({required Object start, required Object end}) => 'Valore: ${start} - ${end}';
}

// Path: docs.components.sortable
class _TranslationsDocsComponentsSortableIt extends TranslationsDocsComponentsSortableKo {
	_TranslationsDocsComponentsSortableIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Ordinabile';
	@override String get description => 'Permette di ordinare gli elementi trascinandoli.';
	@override late final _TranslationsDocsComponentsSortableExamplesIt examples = _TranslationsDocsComponentsSortableExamplesIt._(_root);
}

// Path: docs.components.star_rating
class _TranslationsDocsComponentsStarRatingIt extends TranslationsDocsComponentsStarRatingKo {
	_TranslationsDocsComponentsStarRatingIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Valutazione a stelle';
	@override String get description => 'Permette di selezionare una valutazione a stelle.';
	@override late final _TranslationsDocsComponentsStarRatingExamplesIt examples = _TranslationsDocsComponentsStarRatingExamplesIt._(_root);
}

// Path: docs.components.stepper
class _TranslationsDocsComponentsStepperIt extends TranslationsDocsComponentsStepperKo {
	_TranslationsDocsComponentsStepperIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Stepper';
	@override String get description => 'Mostra un processo passo-passo.';
	@override late final _TranslationsDocsComponentsStepperExamplesIt examples = _TranslationsDocsComponentsStepperExamplesIt._(_root);
	@override String get step_1 => 'Passo 1';
	@override String get step_2 => 'Passo 2';
	@override String get step_3 => 'Passo 3';
	@override String step_n({required Object n}) => 'Passo ${n}';
	@override String get optional_step => 'Passo opzionale';
	@override String get horizontal => 'Orizzontale';
	@override String get vertical => 'Verticale';
	@override String get toggle_error => 'Interruttore di errore';
	@override String get circle => 'Circolare';
	@override String get circle_alt => 'Circolare alternativo';
	@override String get line => 'Lineare';
	@override String get small => 'Piccolo';
	@override String get medium => 'Medio';
	@override String get large => 'Grande';
}

// Path: docs.components.steps
class _TranslationsDocsComponentsStepsIt extends TranslationsDocsComponentsStepsKo {
	_TranslationsDocsComponentsStepsIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Passi';
	@override String get description => 'Mostra i progressi come passi.';
	@override late final _TranslationsDocsComponentsStepsExamplesIt examples = _TranslationsDocsComponentsStepsExamplesIt._(_root);
}

// Path: docs.components.swiper
class _TranslationsDocsComponentsSwiperIt extends TranslationsDocsComponentsSwiperKo {
	_TranslationsDocsComponentsSwiperIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Swiper';
	@override String get description => 'Un componente che può essere scorrere.';
	@override late final _TranslationsDocsComponentsSwiperExamplesIt examples = _TranslationsDocsComponentsSwiperExamplesIt._(_root);
}

// Path: docs.components.k_switch
class _TranslationsDocsComponentsKSwitchIt extends TranslationsDocsComponentsKSwitchKo {
	_TranslationsDocsComponentsKSwitchIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Interruttore';
	@override String get description => 'Un interruttore che può essere acceso/spento.';
	@override late final _TranslationsDocsComponentsKSwitchExamplesIt examples = _TranslationsDocsComponentsKSwitchExamplesIt._(_root);
}

// Path: docs.components.switcher
class _TranslationsDocsComponentsSwitcherIt extends TranslationsDocsComponentsSwitcherKo {
	_TranslationsDocsComponentsSwitcherIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Switcher';
	@override String get description => 'Permette di passare tra diverse visualizzazioni.';
	@override late final _TranslationsDocsComponentsSwitcherExamplesIt examples = _TranslationsDocsComponentsSwitcherExamplesIt._(_root);
	@override String get switch_direction => 'Cambia direzione';
	@override String get next_item => 'Prossimo elemento';
}

// Path: docs.components.tab_list
class _TranslationsDocsComponentsTabListIt extends TranslationsDocsComponentsTabListKo {
	_TranslationsDocsComponentsTabListIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Elenco di schede';
	@override String get description => 'Un componente elenco di schede.';
	@override late final _TranslationsDocsComponentsTabListExamplesIt examples = _TranslationsDocsComponentsTabListExamplesIt._(_root);
}

// Path: docs.components.tab_pane
class _TranslationsDocsComponentsTabPaneIt extends TranslationsDocsComponentsTabPaneKo {
	_TranslationsDocsComponentsTabPaneIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Pannello di schede';
	@override String get description => 'Un componente pannello di schede.';
	@override late final _TranslationsDocsComponentsTabPaneExamplesIt examples = _TranslationsDocsComponentsTabPaneExamplesIt._(_root);
}

// Path: docs.components.table
class _TranslationsDocsComponentsTableIt extends TranslationsDocsComponentsTableKo {
	_TranslationsDocsComponentsTableIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tabella';
	@override String get description => 'Mostra i dati in formato tabellare.';
	@override late final _TranslationsDocsComponentsTableExamplesIt examples = _TranslationsDocsComponentsTableExamplesIt._(_root);
	@override String get invoice => 'Fattura';
	@override String get status => 'Stato';
	@override String get method => 'Metodo';
	@override String get amount => 'Importo';
	@override String get total => 'Totale';
	@override String get paid => 'Pagato';
	@override String get pending => 'In attesa';
	@override String get unpaid => 'Non pagato';
	@override String get credit_card => 'Carta di credito';
	@override String get paypal => 'PayPal';
	@override String get bank_transfer => 'Bonifico bancario';
}

// Path: docs.components.tabs
class _TranslationsDocsComponentsTabsIt extends TranslationsDocsComponentsTabsKo {
	_TranslationsDocsComponentsTabsIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Schede';
	@override String get description => 'Usa le schede per organizzare i contenuti.';
	@override late final _TranslationsDocsComponentsTabsExamplesIt examples = _TranslationsDocsComponentsTabsExamplesIt._(_root);
	@override String get tab_1 => 'Scheda 1';
	@override String get tab_2 => 'Scheda 2';
	@override String get tab_3 => 'Scheda 3';
	@override String tab_n({required Object n}) => 'Scheda ${n}';
}

// Path: docs.components.text_area
class _TranslationsDocsComponentsTextAreaIt extends TranslationsDocsComponentsTextAreaKo {
	_TranslationsDocsComponentsTextAreaIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Area di testo';
	@override String get description => 'Permette di inserire più righe di testo.';
	@override late final _TranslationsDocsComponentsTextAreaExamplesIt examples = _TranslationsDocsComponentsTextAreaExamplesIt._(_root);
	@override String get hello_world => 'Ciao, Mondo!';
}

// Path: docs.components.time_picker
class _TranslationsDocsComponentsTimePickerIt extends TranslationsDocsComponentsTimePickerKo {
	_TranslationsDocsComponentsTimePickerIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Selettore di ora';
	@override String get description => 'Permette di selezionare un\'ora.';
	@override late final _TranslationsDocsComponentsTimePickerExamplesIt examples = _TranslationsDocsComponentsTimePickerExamplesIt._(_root);
	@override String get select_time => 'Seleziona ora';
}

// Path: docs.components.timeline
class _TranslationsDocsComponentsTimelineIt extends TranslationsDocsComponentsTimelineKo {
	_TranslationsDocsComponentsTimelineIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Timeline';
	@override String get description => 'Mostra eventi in una cronologia.';
	@override late final _TranslationsDocsComponentsTimelineExamplesIt examples = _TranslationsDocsComponentsTimelineExamplesIt._(_root);
}

// Path: docs.components.timeline_animation
class _TranslationsDocsComponentsTimelineAnimationIt extends TranslationsDocsComponentsTimelineAnimationKo {
	_TranslationsDocsComponentsTimelineAnimationIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Animazione di timeline';
	@override String get description => 'Animazione basata su timeline.';
	@override late final _TranslationsDocsComponentsTimelineAnimationExamplesIt examples = _TranslationsDocsComponentsTimelineAnimationExamplesIt._(_root);
}

// Path: docs.components.toast
class _TranslationsDocsComponentsToastIt extends TranslationsDocsComponentsToastKo {
	_TranslationsDocsComponentsToastIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Toast';
	@override String get description => 'Un\'avviso che mostra un messaggio breve.';
	@override late final _TranslationsDocsComponentsToastExamplesIt examples = _TranslationsDocsComponentsToastExamplesIt._(_root);
	@override String get event_created => 'Evento creato';
	@override String get event_date => 'Domenica 7 luglio 2024 ore 12:00';
	@override String get show_bottom_left => 'Mostra toast in basso a sinistra';
	@override String get show_bottom_right => 'Mostra toast in basso a destra';
	@override String get show_top_left => 'Mostra toast in alto a sinistra';
	@override String get show_top_right => 'Mostra toast in alto a destra';
	@override String get show_bottom_center => 'Mostra toast al centro in basso';
	@override String get show_top_center => 'Mostra toast al centro in alto';
}

// Path: docs.components.toggle
class _TranslationsDocsComponentsToggleIt extends TranslationsDocsComponentsToggleKo {
	_TranslationsDocsComponentsToggleIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Toggle';
	@override String get description => 'Permette di passare tra le opzioni.';
	@override late final _TranslationsDocsComponentsToggleExamplesIt examples = _TranslationsDocsComponentsToggleExamplesIt._(_root);
	@override String get toggle => 'Attiva/disattiva';
}

// Path: docs.components.tooltip
class _TranslationsDocsComponentsTooltipIt extends TranslationsDocsComponentsTooltipKo {
	_TranslationsDocsComponentsTooltipIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tooltip';
	@override String get description => 'Mostra informazioni aggiuntive su un elemento.';
	@override late final _TranslationsDocsComponentsTooltipExamplesIt examples = _TranslationsDocsComponentsTooltipExamplesIt._(_root);
	@override String get this_is_tooltip => 'Questo è un tooltip.';
	@override String get hover_over_me => 'Passa il mouse su di me';
}

// Path: docs.components.tracker
class _TranslationsDocsComponentsTrackerIt extends TranslationsDocsComponentsTrackerKo {
	_TranslationsDocsComponentsTrackerIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tracker';
	@override String get description => 'Tiene traccia dei progressi.';
	@override late final _TranslationsDocsComponentsTrackerExamplesIt examples = _TranslationsDocsComponentsTrackerExamplesIt._(_root);
	@override String get fine => 'Buono';
	@override String get warning => 'Attenzione';
	@override String get critical => 'Critico';
	@override String get unknown => 'Sconosciuto';
	@override String get tracker_fine => 'Tracker buono';
	@override String get tracker_warning => 'Tracker attenzione';
	@override String get tracker_critical => 'Tracker critico';
	@override String get tracker_unknown => 'Tracker sconosciuto';
}

// Path: docs.components.tree
class _TranslationsDocsComponentsTreeIt extends TranslationsDocsComponentsTreeKo {
	_TranslationsDocsComponentsTreeIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Albero';
	@override String get description => 'Visualizza dati gerarchici in forma ad albero.';
	@override late final _TranslationsDocsComponentsTreeExamplesIt examples = _TranslationsDocsComponentsTreeExamplesIt._(_root);
}

// Path: docs.components.window
class _TranslationsDocsComponentsWindowIt extends TranslationsDocsComponentsWindowKo {
	_TranslationsDocsComponentsWindowIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Finestra';
	@override String get description => 'Una finestra in stile desktop.';
	@override late final _TranslationsDocsComponentsWindowExamplesIt examples = _TranslationsDocsComponentsWindowExamplesIt._(_root);
	@override String get window_1 => 'Finestra 1';
	@override String get window_2 => 'Finestra 2';
	@override String get desktop => 'Desktop';
	@override String get add_window => 'Aggiungi finestra';
}

// Path: docs.pages.introduction.features_list
class _TranslationsDocsPagesIntroductionFeaturesListIt extends TranslationsDocsPagesIntroductionFeaturesListKo {
	_TranslationsDocsPagesIntroductionFeaturesListIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get components_count => '84 componenti e in continua crescita!';
	@override String get material_cupertino => 'Supporta i widget Material e Cupertino, con temi attualmente adattati per il tema coui_flutter.';
	@override String get premade_themes => 'Temi predefiniti di Coui/UI.';
	@override String get platform_support => 'Supporto per piattaforme mobili, web e desktop.';
	@override String get middle_drag => 'Supporto per lo scorrimento con trascinamento intermedio.';
	@override String get typography_extensions => 'Vasta gamma di estensioni per la tipografia.';
	@override String get webassembly => 'Supporto per WebAssembly per migliori prestazioni.';
}

// Path: docs.components.accordion.examples
class _TranslationsDocsComponentsAccordionExamplesIt extends TranslationsDocsComponentsAccordionExamplesKo {
	_TranslationsDocsComponentsAccordionExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di accordione';
}

// Path: docs.components.alert.examples
class _TranslationsDocsComponentsAlertExamplesIt extends TranslationsDocsComponentsAlertExamplesKo {
	_TranslationsDocsComponentsAlertExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di avviso';
	@override String get destructive => 'Esempio di avviso distruttivo';
}

// Path: docs.components.alert_dialog.examples
class _TranslationsDocsComponentsAlertDialogExamplesIt extends TranslationsDocsComponentsAlertDialogExamplesKo {
	_TranslationsDocsComponentsAlertDialogExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di dialogo di avviso';
}

// Path: docs.components.animated_value_builder.examples
class _TranslationsDocsComponentsAnimatedValueBuilderExamplesIt extends TranslationsDocsComponentsAnimatedValueBuilderExamplesKo {
	_TranslationsDocsComponentsAnimatedValueBuilderExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di costruttore di valori animati';
}

// Path: docs.components.app_bar.examples
class _TranslationsDocsComponentsAppBarExamplesIt extends TranslationsDocsComponentsAppBarExamplesKo {
	_TranslationsDocsComponentsAppBarExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di barra dell\'app';
}

// Path: docs.components.autocomplete.examples
class _TranslationsDocsComponentsAutocompleteExamplesIt extends TranslationsDocsComponentsAutocompleteExamplesKo {
	_TranslationsDocsComponentsAutocompleteExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di autocompletamento';
}

// Path: docs.components.avatar.examples
class _TranslationsDocsComponentsAvatarExamplesIt extends TranslationsDocsComponentsAvatarExamplesKo {
	_TranslationsDocsComponentsAvatarExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di avatar';
}

// Path: docs.components.avatar_group.examples
class _TranslationsDocsComponentsAvatarGroupExamplesIt extends TranslationsDocsComponentsAvatarGroupExamplesKo {
	_TranslationsDocsComponentsAvatarGroupExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di gruppo di avatar';
}

// Path: docs.components.badge.examples
class _TranslationsDocsComponentsBadgeExamplesIt extends TranslationsDocsComponentsBadgeExamplesKo {
	_TranslationsDocsComponentsBadgeExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di distintivo';
}

// Path: docs.components.breadcrumb.examples
class _TranslationsDocsComponentsBreadcrumbExamplesIt extends TranslationsDocsComponentsBreadcrumbExamplesKo {
	_TranslationsDocsComponentsBreadcrumbExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di briciole di pane';
}

// Path: docs.components.button.examples
class _TranslationsDocsComponentsButtonExamplesIt extends TranslationsDocsComponentsButtonExamplesKo {
	_TranslationsDocsComponentsButtonExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get primary => 'Esempio di pulsante primario';
	@override String get secondary => 'Esempio di pulsante secondario';
	@override String get outline => 'Esempio di pulsante contornato';
	@override String get ghost => 'Esempio di pulsante ghost';
	@override String get destructive => 'Esempio di pulsante distruttivo';
	@override String get link => 'Esempio di pulsante link';
	@override String get text => 'Esempio di pulsante di testo';
	@override String get disabled => 'Esempio di pulsante disabilitato';
	@override String get icon => 'Esempio di pulsante icona';
	@override String get icon_with_label => 'Esempio di pulsante icona con etichetta';
	@override String get size => 'Esempio di dimensione del pulsante';
	@override String get density => 'Esempio di densità del pulsante';
	@override String get shape => 'Esempio di forma del pulsante';
	@override String get group => 'Esempio di gruppo di pulsanti';
	@override String get stated => 'Esempio di pulsante stato';
	@override String get card => 'Esempio di pulsante carta';
	@override String get custom => 'Esempio di pulsante personalizzato';
}

// Path: docs.components.calendar.examples
class _TranslationsDocsComponentsCalendarExamplesIt extends TranslationsDocsComponentsCalendarExamplesKo {
	_TranslationsDocsComponentsCalendarExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di calendario';
}

// Path: docs.components.card.examples
class _TranslationsDocsComponentsCardExamplesIt extends TranslationsDocsComponentsCardExamplesKo {
	_TranslationsDocsComponentsCardExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di scheda';
}

// Path: docs.components.card_image.examples
class _TranslationsDocsComponentsCardImageExamplesIt extends TranslationsDocsComponentsCardImageExamplesKo {
	_TranslationsDocsComponentsCardImageExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di scheda immagine';
}

// Path: docs.components.carousel.examples
class _TranslationsDocsComponentsCarouselExamplesIt extends TranslationsDocsComponentsCarouselExamplesKo {
	_TranslationsDocsComponentsCarouselExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di carosello';
}

// Path: docs.components.checkbox.examples
class _TranslationsDocsComponentsCheckboxExamplesIt extends TranslationsDocsComponentsCheckboxExamplesKo {
	_TranslationsDocsComponentsCheckboxExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di casella di controllo';
}

// Path: docs.components.chip.examples
class _TranslationsDocsComponentsChipExamplesIt extends TranslationsDocsComponentsChipExamplesKo {
	_TranslationsDocsComponentsChipExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di chip';
}

// Path: docs.components.chip_input.examples
class _TranslationsDocsComponentsChipInputExamplesIt extends TranslationsDocsComponentsChipInputExamplesKo {
	_TranslationsDocsComponentsChipInputExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di input chip';
}

// Path: docs.components.circular_progress.examples
class _TranslationsDocsComponentsCircularProgressExamplesIt extends TranslationsDocsComponentsCircularProgressExamplesKo {
	_TranslationsDocsComponentsCircularProgressExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di progresso circolare';
}

// Path: docs.components.code_snippet.examples
class _TranslationsDocsComponentsCodeSnippetExamplesIt extends TranslationsDocsComponentsCodeSnippetExamplesKo {
	_TranslationsDocsComponentsCodeSnippetExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di snippet di codice';
}

// Path: docs.components.collapsible.examples
class _TranslationsDocsComponentsCollapsibleExamplesIt extends TranslationsDocsComponentsCollapsibleExamplesKo {
	_TranslationsDocsComponentsCollapsibleExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di collapsabile';
}

// Path: docs.components.color_picker.examples
class _TranslationsDocsComponentsColorPickerExamplesIt extends TranslationsDocsComponentsColorPickerExamplesKo {
	_TranslationsDocsComponentsColorPickerExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di selettore di colore';
}

// Path: docs.components.command.examples
class _TranslationsDocsComponentsCommandExamplesIt extends TranslationsDocsComponentsCommandExamplesKo {
	_TranslationsDocsComponentsCommandExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di comando';
}

// Path: docs.components.context_menu.examples
class _TranslationsDocsComponentsContextMenuExamplesIt extends TranslationsDocsComponentsContextMenuExamplesKo {
	_TranslationsDocsComponentsContextMenuExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di menu contestuale';
}

// Path: docs.components.date_picker.examples
class _TranslationsDocsComponentsDatePickerExamplesIt extends TranslationsDocsComponentsDatePickerExamplesKo {
	_TranslationsDocsComponentsDatePickerExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di selettore di data';
}

// Path: docs.components.dialog.examples
class _TranslationsDocsComponentsDialogExamplesIt extends TranslationsDocsComponentsDialogExamplesKo {
	_TranslationsDocsComponentsDialogExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di dialogo';
}

// Path: docs.components.divider.examples
class _TranslationsDocsComponentsDividerExamplesIt extends TranslationsDocsComponentsDividerExamplesKo {
	_TranslationsDocsComponentsDividerExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di divisore';
}

// Path: docs.components.dot_indicator.examples
class _TranslationsDocsComponentsDotIndicatorExamplesIt extends TranslationsDocsComponentsDotIndicatorExamplesKo {
	_TranslationsDocsComponentsDotIndicatorExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di indicatore a punto';
}

// Path: docs.components.drawer.examples
class _TranslationsDocsComponentsDrawerExamplesIt extends TranslationsDocsComponentsDrawerExamplesKo {
	_TranslationsDocsComponentsDrawerExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di cassetto';
}

// Path: docs.components.dropdown_menu.examples
class _TranslationsDocsComponentsDropdownMenuExamplesIt extends TranslationsDocsComponentsDropdownMenuExamplesKo {
	_TranslationsDocsComponentsDropdownMenuExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di menu a discesa';
}

// Path: docs.components.expandable_sidebar.examples
class _TranslationsDocsComponentsExpandableSidebarExamplesIt extends TranslationsDocsComponentsExpandableSidebarExamplesKo {
	_TranslationsDocsComponentsExpandableSidebarExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di sidebar espandibile';
}

// Path: docs.components.form.examples
class _TranslationsDocsComponentsFormExamplesIt extends TranslationsDocsComponentsFormExamplesKo {
	_TranslationsDocsComponentsFormExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get table_layout => 'Esempio di modulo (layout a tabella)';
	@override String get column_layout => 'Esempio di modulo (layout a colonne)';
	@override String get validation_mode => 'Esempio di modalità di validazione';
}

// Path: docs.components.formatted_input.examples
class _TranslationsDocsComponentsFormattedInputExamplesIt extends TranslationsDocsComponentsFormattedInputExamplesKo {
	_TranslationsDocsComponentsFormattedInputExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di input formattato';
}

// Path: docs.components.hover_card.examples
class _TranslationsDocsComponentsHoverCardExamplesIt extends TranslationsDocsComponentsHoverCardExamplesKo {
	_TranslationsDocsComponentsHoverCardExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di scheda hover';
}

// Path: docs.components.input.examples
class _TranslationsDocsComponentsInputExamplesIt extends TranslationsDocsComponentsInputExamplesKo {
	_TranslationsDocsComponentsInputExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di input';
}

// Path: docs.components.input_otp.examples
class _TranslationsDocsComponentsInputOtpExamplesIt extends TranslationsDocsComponentsInputOtpExamplesKo {
	_TranslationsDocsComponentsInputOtpExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di input OTP';
}

// Path: docs.components.item_picker.examples
class _TranslationsDocsComponentsItemPickerExamplesIt extends TranslationsDocsComponentsItemPickerExamplesKo {
	_TranslationsDocsComponentsItemPickerExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di selettore di elementi';
}

// Path: docs.components.keyboard_display.examples
class _TranslationsDocsComponentsKeyboardDisplayExamplesIt extends TranslationsDocsComponentsKeyboardDisplayExamplesKo {
	_TranslationsDocsComponentsKeyboardDisplayExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di visualizzazione tastiera';
}

// Path: docs.components.linear_progress.examples
class _TranslationsDocsComponentsLinearProgressExamplesIt extends TranslationsDocsComponentsLinearProgressExamplesKo {
	_TranslationsDocsComponentsLinearProgressExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di progresso lineare';
}

// Path: docs.components.material.examples
class _TranslationsDocsComponentsMaterialExamplesIt extends TranslationsDocsComponentsMaterialExamplesKo {
	_TranslationsDocsComponentsMaterialExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di Material/Cupertino';
}

// Path: docs.components.menubar.examples
class _TranslationsDocsComponentsMenubarExamplesIt extends TranslationsDocsComponentsMenubarExamplesKo {
	_TranslationsDocsComponentsMenubarExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di barra dei menu';
}

// Path: docs.components.multiselect.examples
class _TranslationsDocsComponentsMultiselectExamplesIt extends TranslationsDocsComponentsMultiselectExamplesKo {
	_TranslationsDocsComponentsMultiselectExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di selezione multipla';
}

// Path: docs.components.navigation_bar.examples
class _TranslationsDocsComponentsNavigationBarExamplesIt extends TranslationsDocsComponentsNavigationBarExamplesKo {
	_TranslationsDocsComponentsNavigationBarExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di barra di navigazione';
}

// Path: docs.components.navigation_menu.examples
class _TranslationsDocsComponentsNavigationMenuExamplesIt extends TranslationsDocsComponentsNavigationMenuExamplesKo {
	_TranslationsDocsComponentsNavigationMenuExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di menu di navigazione';
}

// Path: docs.components.navigation_rail.examples
class _TranslationsDocsComponentsNavigationRailExamplesIt extends TranslationsDocsComponentsNavigationRailExamplesKo {
	_TranslationsDocsComponentsNavigationRailExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di binario di navigazione';
}

// Path: docs.components.navigation_sidebar.examples
class _TranslationsDocsComponentsNavigationSidebarExamplesIt extends TranslationsDocsComponentsNavigationSidebarExamplesKo {
	_TranslationsDocsComponentsNavigationSidebarExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di sidebar di navigazione';
}

// Path: docs.components.number_input.examples
class _TranslationsDocsComponentsNumberInputExamplesIt extends TranslationsDocsComponentsNumberInputExamplesKo {
	_TranslationsDocsComponentsNumberInputExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di input numerico';
}

// Path: docs.components.number_ticker.examples
class _TranslationsDocsComponentsNumberTickerExamplesIt extends TranslationsDocsComponentsNumberTickerExamplesKo {
	_TranslationsDocsComponentsNumberTickerExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di ticker numerico';
}

// Path: docs.components.overflow_marquee.examples
class _TranslationsDocsComponentsOverflowMarqueeExamplesIt extends TranslationsDocsComponentsOverflowMarqueeExamplesKo {
	_TranslationsDocsComponentsOverflowMarqueeExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di marquee overflow';
}

// Path: docs.components.pagination.examples
class _TranslationsDocsComponentsPaginationExamplesIt extends TranslationsDocsComponentsPaginationExamplesKo {
	_TranslationsDocsComponentsPaginationExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di paginazione';
}

// Path: docs.components.phone_input.examples
class _TranslationsDocsComponentsPhoneInputExamplesIt extends TranslationsDocsComponentsPhoneInputExamplesKo {
	_TranslationsDocsComponentsPhoneInputExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di input telefono';
}

// Path: docs.components.popover.examples
class _TranslationsDocsComponentsPopoverExamplesIt extends TranslationsDocsComponentsPopoverExamplesKo {
	_TranslationsDocsComponentsPopoverExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di popover';
}

// Path: docs.components.progress.examples
class _TranslationsDocsComponentsProgressExamplesIt extends TranslationsDocsComponentsProgressExamplesKo {
	_TranslationsDocsComponentsProgressExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di progresso';
}

// Path: docs.components.radio_card.examples
class _TranslationsDocsComponentsRadioCardExamplesIt extends TranslationsDocsComponentsRadioCardExamplesKo {
	_TranslationsDocsComponentsRadioCardExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di carta radio';
}

// Path: docs.components.radio_group.examples
class _TranslationsDocsComponentsRadioGroupExamplesIt extends TranslationsDocsComponentsRadioGroupExamplesKo {
	_TranslationsDocsComponentsRadioGroupExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di gruppo radio';
}

// Path: docs.components.refresh_trigger.examples
class _TranslationsDocsComponentsRefreshTriggerExamplesIt extends TranslationsDocsComponentsRefreshTriggerExamplesKo {
	_TranslationsDocsComponentsRefreshTriggerExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di trigger di aggiornamento';
}

// Path: docs.components.repeated_animation_builder.examples
class _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesIt extends TranslationsDocsComponentsRepeatedAnimationBuilderExamplesKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di costruttore di animazione ripetuta';
}

// Path: docs.components.resizable.examples
class _TranslationsDocsComponentsResizableExamplesIt extends TranslationsDocsComponentsResizableExamplesKo {
	_TranslationsDocsComponentsResizableExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di ridimensionabile';
}

// Path: docs.components.scaffold.examples
class _TranslationsDocsComponentsScaffoldExamplesIt extends TranslationsDocsComponentsScaffoldExamplesKo {
	_TranslationsDocsComponentsScaffoldExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di scaffold';
}

// Path: docs.components.select.examples
class _TranslationsDocsComponentsSelectExamplesIt extends TranslationsDocsComponentsSelectExamplesKo {
	_TranslationsDocsComponentsSelectExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di selezione';
}

// Path: docs.components.sheet.examples
class _TranslationsDocsComponentsSheetExamplesIt extends TranslationsDocsComponentsSheetExamplesKo {
	_TranslationsDocsComponentsSheetExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di foglietto';
}

// Path: docs.components.skeleton.examples
class _TranslationsDocsComponentsSkeletonExamplesIt extends TranslationsDocsComponentsSkeletonExamplesKo {
	_TranslationsDocsComponentsSkeletonExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di scheletro';
}

// Path: docs.components.slider.examples
class _TranslationsDocsComponentsSliderExamplesIt extends TranslationsDocsComponentsSliderExamplesKo {
	_TranslationsDocsComponentsSliderExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di slider';
}

// Path: docs.components.sortable.examples
class _TranslationsDocsComponentsSortableExamplesIt extends TranslationsDocsComponentsSortableExamplesKo {
	_TranslationsDocsComponentsSortableExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di ordinabile';
}

// Path: docs.components.star_rating.examples
class _TranslationsDocsComponentsStarRatingExamplesIt extends TranslationsDocsComponentsStarRatingExamplesKo {
	_TranslationsDocsComponentsStarRatingExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di valutazione a stelle';
}

// Path: docs.components.stepper.examples
class _TranslationsDocsComponentsStepperExamplesIt extends TranslationsDocsComponentsStepperExamplesKo {
	_TranslationsDocsComponentsStepperExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di stepper';
}

// Path: docs.components.steps.examples
class _TranslationsDocsComponentsStepsExamplesIt extends TranslationsDocsComponentsStepsExamplesKo {
	_TranslationsDocsComponentsStepsExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di passi';
}

// Path: docs.components.swiper.examples
class _TranslationsDocsComponentsSwiperExamplesIt extends TranslationsDocsComponentsSwiperExamplesKo {
	_TranslationsDocsComponentsSwiperExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di swiper';
}

// Path: docs.components.k_switch.examples
class _TranslationsDocsComponentsKSwitchExamplesIt extends TranslationsDocsComponentsKSwitchExamplesKo {
	_TranslationsDocsComponentsKSwitchExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di interruttore';
}

// Path: docs.components.switcher.examples
class _TranslationsDocsComponentsSwitcherExamplesIt extends TranslationsDocsComponentsSwitcherExamplesKo {
	_TranslationsDocsComponentsSwitcherExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di switcher';
}

// Path: docs.components.tab_list.examples
class _TranslationsDocsComponentsTabListExamplesIt extends TranslationsDocsComponentsTabListExamplesKo {
	_TranslationsDocsComponentsTabListExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di elenco di schede';
}

// Path: docs.components.tab_pane.examples
class _TranslationsDocsComponentsTabPaneExamplesIt extends TranslationsDocsComponentsTabPaneExamplesKo {
	_TranslationsDocsComponentsTabPaneExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di pannello di schede';
}

// Path: docs.components.table.examples
class _TranslationsDocsComponentsTableExamplesIt extends TranslationsDocsComponentsTableExamplesKo {
	_TranslationsDocsComponentsTableExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di tabella';
}

// Path: docs.components.tabs.examples
class _TranslationsDocsComponentsTabsExamplesIt extends TranslationsDocsComponentsTabsExamplesKo {
	_TranslationsDocsComponentsTabsExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di schede';
}

// Path: docs.components.text_area.examples
class _TranslationsDocsComponentsTextAreaExamplesIt extends TranslationsDocsComponentsTextAreaExamplesKo {
	_TranslationsDocsComponentsTextAreaExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di area di testo';
}

// Path: docs.components.time_picker.examples
class _TranslationsDocsComponentsTimePickerExamplesIt extends TranslationsDocsComponentsTimePickerExamplesKo {
	_TranslationsDocsComponentsTimePickerExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di selettore di ora';
}

// Path: docs.components.timeline.examples
class _TranslationsDocsComponentsTimelineExamplesIt extends TranslationsDocsComponentsTimelineExamplesKo {
	_TranslationsDocsComponentsTimelineExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di timeline';
}

// Path: docs.components.timeline_animation.examples
class _TranslationsDocsComponentsTimelineAnimationExamplesIt extends TranslationsDocsComponentsTimelineAnimationExamplesKo {
	_TranslationsDocsComponentsTimelineAnimationExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di animazione di timeline';
}

// Path: docs.components.toast.examples
class _TranslationsDocsComponentsToastExamplesIt extends TranslationsDocsComponentsToastExamplesKo {
	_TranslationsDocsComponentsToastExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di toast';
}

// Path: docs.components.toggle.examples
class _TranslationsDocsComponentsToggleExamplesIt extends TranslationsDocsComponentsToggleExamplesKo {
	_TranslationsDocsComponentsToggleExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di toggle';
}

// Path: docs.components.tooltip.examples
class _TranslationsDocsComponentsTooltipExamplesIt extends TranslationsDocsComponentsTooltipExamplesKo {
	_TranslationsDocsComponentsTooltipExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di tooltip';
}

// Path: docs.components.tracker.examples
class _TranslationsDocsComponentsTrackerExamplesIt extends TranslationsDocsComponentsTrackerExamplesKo {
	_TranslationsDocsComponentsTrackerExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di tracker';
}

// Path: docs.components.tree.examples
class _TranslationsDocsComponentsTreeExamplesIt extends TranslationsDocsComponentsTreeExamplesKo {
	_TranslationsDocsComponentsTreeExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di albero';
}

// Path: docs.components.window.examples
class _TranslationsDocsComponentsWindowExamplesIt extends TranslationsDocsComponentsWindowExamplesKo {
	_TranslationsDocsComponentsWindowExamplesIt._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Esempio di finestra';
}
