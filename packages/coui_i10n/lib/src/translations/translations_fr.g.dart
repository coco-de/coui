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
class TranslationsFr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.fr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <fr>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsFr _root = this; // ignore: unused_field

	@override 
	TranslationsFr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsFr(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsWidgetbookFr widgetbook = _TranslationsWidgetbookFr._(_root);
	@override late final _TranslationsDocsFr docs = _TranslationsDocsFr._(_root);
}

// Path: widgetbook
class _TranslationsWidgetbookFr extends TranslationsWidgetbookKo {
	_TranslationsWidgetbookFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsWidgetbookCommonFr common = _TranslationsWidgetbookCommonFr._(_root);
	@override late final _TranslationsWidgetbookLoadingFr loading = _TranslationsWidgetbookLoadingFr._(_root);
	@override late final _TranslationsWidgetbookTabsFr tabs = _TranslationsWidgetbookTabsFr._(_root);
	@override late final _TranslationsWidgetbookPaginationFr pagination = _TranslationsWidgetbookPaginationFr._(_root);
	@override late final _TranslationsWidgetbookTooltipFr tooltip = _TranslationsWidgetbookTooltipFr._(_root);
	@override late final _TranslationsWidgetbookRadioFr radio = _TranslationsWidgetbookRadioFr._(_root);
	@override late final _TranslationsWidgetbookCardFr card = _TranslationsWidgetbookCardFr._(_root);
	@override late final _TranslationsWidgetbookAlertFr alert = _TranslationsWidgetbookAlertFr._(_root);
	@override late final _TranslationsWidgetbookAccordionFr accordion = _TranslationsWidgetbookAccordionFr._(_root);
	@override late final _TranslationsWidgetbookSkeletonFr skeleton = _TranslationsWidgetbookSkeletonFr._(_root);
	@override late final _TranslationsWidgetbookToastFr toast = _TranslationsWidgetbookToastFr._(_root);
	@override late final _TranslationsWidgetbookChipFr chip = _TranslationsWidgetbookChipFr._(_root);
	@override late final _TranslationsWidgetbookCheckboxFr checkbox = _TranslationsWidgetbookCheckboxFr._(_root);
	@override late final _TranslationsWidgetbookToggleFr toggle = _TranslationsWidgetbookToggleFr._(_root);
	@override late final _TranslationsWidgetbookDialogFr dialog = _TranslationsWidgetbookDialogFr._(_root);
	@override late final _TranslationsWidgetbookPopoverFr popover = _TranslationsWidgetbookPopoverFr._(_root);
	@override late final _TranslationsWidgetbookTextFieldFr text_field = _TranslationsWidgetbookTextFieldFr._(_root);
	@override late final _TranslationsWidgetbookButtonFr button = _TranslationsWidgetbookButtonFr._(_root);
	@override late final _TranslationsWidgetbookTableFr table = _TranslationsWidgetbookTableFr._(_root);
	@override late final _TranslationsWidgetbookKSwitchFr k_switch = _TranslationsWidgetbookKSwitchFr._(_root);
	@override late final _TranslationsWidgetbookSwitchComponentFr switch_component = _TranslationsWidgetbookSwitchComponentFr._(_root);
	@override late final _TranslationsWidgetbookSelectFr select = _TranslationsWidgetbookSelectFr._(_root);
	@override late final _TranslationsWidgetbookBreadcrumbFr breadcrumb = _TranslationsWidgetbookBreadcrumbFr._(_root);
	@override late final _TranslationsWidgetbookBadgeFr badge = _TranslationsWidgetbookBadgeFr._(_root);
	@override late final _TranslationsWidgetbookThemePreviewFr theme_preview = _TranslationsWidgetbookThemePreviewFr._(_root);
	@override late final _TranslationsWidgetbookChatFr chat = _TranslationsWidgetbookChatFr._(_root);
	@override late final _TranslationsWidgetbookMultipleChoiceFr multiple_choice = _TranslationsWidgetbookMultipleChoiceFr._(_root);
	@override late final _TranslationsWidgetbookFormattedInputFr formatted_input = _TranslationsWidgetbookFormattedInputFr._(_root);
	@override late final _TranslationsWidgetbookSwiperFr swiper = _TranslationsWidgetbookSwiperFr._(_root);
}

// Path: docs
class _TranslationsDocsFr extends TranslationsDocsKo {
	_TranslationsDocsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsCommonFr common = _TranslationsDocsCommonFr._(_root);
	@override late final _TranslationsDocsBadgesFr badges = _TranslationsDocsBadgesFr._(_root);
	@override late final _TranslationsDocsFlavorsFr flavors = _TranslationsDocsFlavorsFr._(_root);
	@override late final _TranslationsDocsNavigationFr navigation = _TranslationsDocsNavigationFr._(_root);
	@override late final _TranslationsDocsPagesFr pages = _TranslationsDocsPagesFr._(_root);
	@override late final _TranslationsDocsComponentsFr components = _TranslationsDocsComponentsFr._(_root);
}

// Path: widgetbook.common
class _TranslationsWidgetbookCommonFr extends TranslationsWidgetbookCommonKo {
	_TranslationsWidgetbookCommonFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get increment_progress => 'Augmenter la progression';
	@override String selected_tab({required Object index}) => 'Onglet sélectionné : ${index}';
	@override String current_page({required Object page}) => 'Page actuelle : ${page}';
	@override String total_pages({required Object count}) => 'Pages totales : ${count}';
	@override String page_of({required Object current, required Object total}) => '${current} page / ${total}';
	@override String get hover_over_icon => 'Survolez l\'icône';
	@override String counter({required Object count}) => 'Compteur : ${count}';
	@override String selected_rows({required Object count}) => 'Lignes sélectionnées : ${count}';
	@override String value({required Object value}) => 'Valeur : ${value}';
	@override String selected_cells({required Object count}) => 'Cellules sélectionnées : ${count}';
}

// Path: widgetbook.loading
class _TranslationsWidgetbookLoadingFr extends TranslationsWidgetbookLoadingKo {
	_TranslationsWidgetbookLoadingFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get indeterminate => 'Chargement indéterminé';
	@override String with_value({required Object percent}) => 'Avec valeur (${percent}%)';
	@override String get custom_size => 'Taille personnalisée';
	@override String get custom_height => 'Hauteur personnalisée';
	@override String get circular_progress => 'Progression circulaire';
	@override String get linear_progress => 'Progression linéaire';
}

// Path: widgetbook.tabs
class _TranslationsWidgetbookTabsFr extends TranslationsWidgetbookTabsKo {
	_TranslationsWidgetbookTabsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get home => 'Accueil';
	@override String get profile => 'Profil';
	@override String get settings => 'Paramètres';
	@override String get overview => 'Aperçu';
	@override String get details => 'Détails';
	@override String get history => 'Historique';
	@override String get overview_content => 'Contenu de l\'aperçu';
	@override String get details_content => 'Contenu des détails';
	@override String get history_content => 'Contenu de l\'historique';
	@override String get general_info => 'Informations générales sur l\'élément';
	@override String get specifications => 'Spécifications et caractéristiques détaillées';
	@override String get timeline => 'Chronologie des changements et des mises à jour';
}

// Path: widgetbook.pagination
class _TranslationsWidgetbookPaginationFr extends TranslationsWidgetbookPaginationKo {
	_TranslationsWidgetbookPaginationFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get show_skip_to_first => 'Afficher le saut vers le premier';
	@override String get show_skip_to_last => 'Afficher le saut vers le dernier';
	@override String get hide_previous_on_first => 'Masquer précédent sur la première page';
	@override String get hide_next_on_last => 'Masquer suivant sur la dernière page';
	@override String get max_visible_pages => 'Nombre maximum de pages visibles';
}

// Path: widgetbook.tooltip
class _TranslationsWidgetbookTooltipFr extends TranslationsWidgetbookTooltipKo {
	_TranslationsWidgetbookTooltipFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get helpful_message => 'Ceci est un message d\'infobulle utile';
	@override String get tooltip_above => 'Infobulle au-dessus';
	@override String get tooltip_below => 'Infobulle en dessous';
	@override String get tooltip_left => 'Infobulle à gauche';
	@override String get tooltip_right => 'Infobulle à droite';
	@override String get top => 'Haut';
	@override String get bottom => 'Bas';
	@override String get left => 'Gauche';
	@override String get right => 'Droite';
}

// Path: widgetbook.radio
class _TranslationsWidgetbookRadioFr extends TranslationsWidgetbookRadioKo {
	_TranslationsWidgetbookRadioFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get small => 'Petit';
	@override String get medium => 'Moyen';
	@override String get large => 'Grand';
}

// Path: widgetbook.card
class _TranslationsWidgetbookCardFr extends TranslationsWidgetbookCardKo {
	_TranslationsWidgetbookCardFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get card_content => 'Contenu de la carte';
	@override String get gradient_card => 'Carte dégradée';
	@override String get custom_decoration => 'Carte avec décoration personnalisée';
}

// Path: widgetbook.alert
class _TranslationsWidgetbookAlertFr extends TranslationsWidgetbookAlertKo {
	_TranslationsWidgetbookAlertFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Titre de l\'alerte';
	@override String get message => 'Ceci est un message d\'alerte.';
}

// Path: widgetbook.accordion
class _TranslationsWidgetbookAccordionFr extends TranslationsWidgetbookAccordionKo {
	_TranslationsWidgetbookAccordionFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get what_is_coui => 'Qu\'est-ce que CoUI Flutter ?';
	@override String get what_is_coui_answer => 'CoUI Flutter est une bibliothèque de composants UI complète conçue pour construire des applications Flutter modernes et accessibles avec des motifs de conception cohérents.';
	@override String get how_to_install => 'Comment l\'installer ?';
	@override String get how_to_install_answer => 'Ajoutez coui_flutter à vos dépendances dans pubspec.yaml et exécutez flutter pub get pour installer le package.';
	@override String get is_customizable => 'Est-ce personnalisable ?';
	@override String get is_customizable_answer => 'Oui ! CoUI Flutter offre un support de thème complet pour personnaliser les couleurs, la typographie, les espacements, etc. via ThemeData.';
	@override String get getting_started => 'Commencer';
	@override String get getting_started_answer => 'Commencez par installer le package et l\'importer dans votre projet. Pour des instructions de configuration détaillées, consultez la documentation.';
	@override String get features_expanded => 'Fonctionnalités (par défaut étendues)';
	@override String get features_answer => 'CoUI Flutter inclut des boutons, des formulaires, des dialogues, des composants de navigation, etc. Tous les composants sont conçus en tenant compte de l\'accessibilité et des thèmes.';
	@override String get support => 'Assistance';
	@override String get support_answer => 'Si vous avez des questions ou besoin d\'assistance, visitez le dépôt GitHub ou consultez la documentation sur docs.coui.dev.';
}

// Path: widgetbook.skeleton
class _TranslationsWidgetbookSkeletonFr extends TranslationsWidgetbookSkeletonKo {
	_TranslationsWidgetbookSkeletonFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get skeleton_enabled => 'Squelette activé :';
	@override String get title_text => 'Ceci est un titre';
	@override String get description_text => 'Ceci est un texte de description long';
	@override String get short_text => 'Texte court';
	@override String get without_skeleton => 'Sans squelette :';
	@override String get with_skeleton => 'Avec squelette :';
	@override String get user_name => 'Nom d\'utilisateur';
	@override String get user_email => 'user@example.com';
	@override String get article_title => 'Titre de l\'article';
	@override String get posted_date => 'Publié le 1er janvier 2024';
	@override String get bio_description => 'Développeur enregistrant le quotidien';
	@override String get show_content => 'Afficher le contenu';
	@override String get show_loading => 'Afficher le chargement';
	@override String get article_content => 'Ceci est un exemple de contenu d\'article. Cela sera remplacé par un squelette pendant le chargement.';
}

// Path: widgetbook.toast
class _TranslationsWidgetbookToastFr extends TranslationsWidgetbookToastKo {
	_TranslationsWidgetbookToastFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get success => 'Succès';
	@override String get operation_completed => 'L\'opération a été réussie';
	@override String get show_toast => 'Afficher le toast';
	@override String toast_at({required Object location}) => 'Toast à ${location}';
	@override String get top_left => 'En haut à gauche';
	@override String get top_center => 'En haut au centre';
	@override String get top_right => 'En haut à droite';
	@override String get bottom_left => 'En bas à gauche';
	@override String get bottom_center => 'En bas au centre';
	@override String get bottom_right => 'En bas à droite';
}

// Path: widgetbook.chip
class _TranslationsWidgetbookChipFr extends TranslationsWidgetbookChipKo {
	_TranslationsWidgetbookChipFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get chip => 'Puce';
}

// Path: widgetbook.checkbox
class _TranslationsWidgetbookCheckboxFr extends TranslationsWidgetbookCheckboxKo {
	_TranslationsWidgetbookCheckboxFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get accept_terms => 'J\'accepte les conditions d\'utilisation';
	@override String get tristate => 'Trois états';
}

// Path: widgetbook.toggle
class _TranslationsWidgetbookToggleFr extends TranslationsWidgetbookToggleKo {
	_TranslationsWidgetbookToggleFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get toggle => 'Basculer';
}

// Path: widgetbook.dialog
class _TranslationsWidgetbookDialogFr extends TranslationsWidgetbookDialogKo {
	_TranslationsWidgetbookDialogFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic_dialog => 'Dialogue de base';
	@override String get basic_title => 'Dialogue de base';
	@override String get basic_content => 'C\'est un dialogue simple avec un titre et un contenu.';
	@override String get simple_dialog_content => 'Ceci est un dialogue simple avec un titre et un contenu.';
	@override String get show_basic => 'Afficher de base';
	@override String get show_basic_dialog => 'Afficher le dialogue de base';
	@override String get confirm_action => 'Confirmer l\'action';
	@override String get confirm_title => 'Confirmer';
	@override String get confirm_content => 'Êtes-vous sûr de vouloir effectuer cette action ?';
	@override String get confirm_action_content => 'Voulez-vous vraiment effectuer cette action ? Cette action ne peut pas être annulée.';
	@override String get cancel => 'Annuler';
	@override String get confirm => 'Confirmer';
	@override String get show_confirmation => 'Afficher la confirmation';
	@override String get show_confirmation_dialog => 'Afficher le dialogue de confirmation';
	@override String get warning => 'Avertissement';
	@override String get warning_title => 'Avertissement';
	@override String get warning_content => 'Cette action peut affecter les données. Procédez avec prudence.';
	@override String get dismiss => 'Fermer';
	@override String get show_warning => 'Afficher l\'avertissement';
	@override String get show_warning_dialog => 'Afficher le dialogue d\'avertissement';
}

// Path: widgetbook.popover
class _TranslationsWidgetbookPopoverFr extends TranslationsWidgetbookPopoverKo {
	_TranslationsWidgetbookPopoverFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get popover_content => 'Contenu du popover';
	@override String get content_title => 'Titre du popover';
	@override String get content_description => 'Un popover avec un contenu personnalisable.';
	@override String get customizable_content => 'Popover avec contenu personnalisable.';
	@override String get show_popover => 'Afficher le popover';
	@override String popover_at({required Object position}) => '${position} Popover';
	@override String get top => 'Haut';
	@override String get bottom => 'Bas';
	@override String get left => 'Gauche';
	@override String get right => 'Droite';
}

// Path: widgetbook.text_field
class _TranslationsWidgetbookTextFieldFr extends TranslationsWidgetbookTextFieldKo {
	_TranslationsWidgetbookTextFieldFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get enter_name => 'Entrez votre nom';
	@override String get type_here => 'Tapez ici';
}

// Path: widgetbook.button
class _TranslationsWidgetbookButtonFr extends TranslationsWidgetbookButtonKo {
	_TranslationsWidgetbookButtonFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get primary_button => 'Bouton principal';
	@override String get secondary_button => 'Bouton secondaire';
	@override String get dashed_button => 'Télécharger un fichier';
	@override String get upload_file => 'Télécharger un fichier';
}

// Path: widgetbook.table
class _TranslationsWidgetbookTableFr extends TranslationsWidgetbookTableKo {
	_TranslationsWidgetbookTableFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get name => 'Nom';
	@override String get email => 'Email';
	@override String get role => 'Rôle';
	@override String get john_doe => 'Hong Gil-Dong';
	@override String get john_email => 'hong@example.com';
	@override String get developer => 'Développeur';
	@override String get jane_smith => 'Kim Young-Hee';
	@override String get jane_email => 'kim@example.com';
	@override String get designer => 'Designer';
	@override String get bob_johnson => 'Lee Cheol-Soo';
	@override String get bob_email => 'lee@example.com';
	@override String get manager => 'Responsable';
	@override String get select => 'Sélectionner';
	@override String get product => 'Produit';
	@override String get price => 'Prix';
	@override String get stock => 'Stock';
	@override String get laptop => 'Ordinateur portable';
	@override String get mouse => 'Souris';
	@override String get keyboard => 'Clavier';
}

// Path: widgetbook.k_switch
class _TranslationsWidgetbookKSwitchFr extends TranslationsWidgetbookKSwitchKo {
	_TranslationsWidgetbookKSwitchFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get k_switch => 'Interrupteur';
}

// Path: widgetbook.switch_component
class _TranslationsWidgetbookSwitchComponentFr extends TranslationsWidgetbookSwitchComponentKo {
	_TranslationsWidgetbookSwitchComponentFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get switch_label => 'Étiquette de l\'interrupteur';
}

// Path: widgetbook.select
class _TranslationsWidgetbookSelectFr extends TranslationsWidgetbookSelectKo {
	_TranslationsWidgetbookSelectFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get apple => 'Pomme';
	@override String get banana => 'Banane';
	@override String get cherry => 'Cerise';
	@override String get date => 'Dattes';
	@override String get choose_size => 'Choisissez une taille';
	@override String get small => 'Petit';
	@override String get medium => 'Moyen';
	@override String get large => 'Grand';
	@override String get extra_large => 'Très grand';
}

// Path: widgetbook.breadcrumb
class _TranslationsWidgetbookBreadcrumbFr extends TranslationsWidgetbookBreadcrumbKo {
	_TranslationsWidgetbookBreadcrumbFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get home => 'Accueil';
	@override String get products => 'Produits';
	@override String get electronics => 'Électronique';
	@override String get smartphones => 'Smartphones';
	@override String get documents => 'Documents';
	@override String get projects => 'Projets';
	@override String get current_folder => 'Dossier actuel';
	@override String current_path({required Object path}) => 'Chemin actuel : ${path}';
}

// Path: widgetbook.badge
class _TranslationsWidgetbookBadgeFr extends TranslationsWidgetbookBadgeKo {
	_TranslationsWidgetbookBadgeFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get primary => 'Principal';
	@override String get secondary => 'Secondaire';
	@override String get outline => 'Contour';
	@override String get destructive => 'Destructeur';
	@override String get featured => 'Présenté';
	@override String get more => 'Plus';
	@override String get verified => 'Vérifié';
	@override String get error => 'Erreur';
	@override String get click_me => 'Cliquez ici';
	@override String get clickable => 'Cliquable';
}

// Path: widgetbook.theme_preview
class _TranslationsWidgetbookThemePreviewFr extends TranslationsWidgetbookThemePreviewKo {
	_TranslationsWidgetbookThemePreviewFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Aperçu du thème';
	@override String get description => 'Une vue d\'ensemble complète de tous les tokens de thème et styles de composants.';
	@override String get color_palette => 'Palette de couleurs';
	@override String get brand_colors => 'Couleurs de la marque';
	@override String get base_colors => 'Couleurs de base';
	@override String get status_colors => 'Couleurs d\'état';
	@override String get buttons => 'Boutons';
	@override String get primary_button => 'Principal';
	@override String get secondary_button => 'Secondaire';
	@override String get outline_button => 'Contour';
	@override String get ghost_button => 'Fantôme';
	@override String get destructive_button => 'Destructif';
	@override String get disabled_button => 'Désactivé';
	@override String get cards => 'Cartes';
	@override String get card_title => 'Titre de la carte';
	@override String get card_description => 'Ceci est une description d\'une carte d\'exemple.';
	@override String get surface_card => 'Carte de surface';
	@override String get filled_variant => 'Style rempli avec fond';
	@override String get form_elements => 'Éléments de formulaire';
	@override String get text_input_placeholder => 'Entrez le texte...';
	@override String get checkbox_checked => 'Coché';
	@override String get checkbox_unchecked => 'Non coché';
	@override String get toggle_on => 'Activé';
	@override String get toggle_off => 'Désactivé';
	@override String get alerts => 'Alertes';
	@override String get info_alert => 'Alerte d\'information';
	@override String get info_alert_message => 'Ceci est un message d\'orientation.';
	@override String get error_alert => 'Alerte d\'erreur';
	@override String get error_alert_message => 'Un problème est survenu.';
	@override String get badges_chips => 'Badges & Chips';
	@override String get primary_badge => 'Principal';
	@override String get secondary_badge => 'Secondaire';
	@override String get outline_badge => 'Contour';
	@override String get destructive_badge => 'Destructif';
	@override String get chip_example => 'Favori';
	@override String get typography => 'Typographie';
	@override String get heading_1 => 'Titre 1';
	@override String get heading_2 => 'Titre 2';
	@override String get heading_3 => 'Titre 3';
	@override String get heading_4 => 'Titre 4';
	@override String get body_text => 'Texte de corps de poids normal.';
	@override String get small_text => 'Petit texte pour les légendes.';
	@override String get muted_text => 'Texte atténué pour les informations supplémentaires.';
	@override String get bold_text => 'Texte en gras pour l\'accentuation.';
	@override String get spacing_radius => 'Espacement & Rondeur';
	@override String get border_radius => 'Rondeur des bordures';
	@override String get loading_states => 'États de chargement';
}

// Path: widgetbook.chat
class _TranslationsWidgetbookChatFr extends TranslationsWidgetbookChatKo {
	_TranslationsWidgetbookChatFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get hello => 'Bonjour ! Comment allez-vous ?';
	@override String get doing_great => 'Très bien, merci !';
	@override String get nice_weather => 'Beau temps aujourd\'hui !';
	@override String get yes_beautiful => 'Oui, c\'est magnifique !';
	@override String get sender => 'Expéditeur';
	@override String get receiver => 'Destinataire';
}

// Path: widgetbook.multiple_choice
class _TranslationsWidgetbookMultipleChoiceFr extends TranslationsWidgetbookMultipleChoiceKo {
	_TranslationsWidgetbookMultipleChoiceFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get option_a => 'Option A';
	@override String get option_b => 'Option B';
	@override String get option_c => 'Option C';
	@override String get option_d => 'Option D';
	@override String selected_value({required Object value}) => 'Sélectionné : ${value}';
	@override String selected_values({required Object values}) => 'Sélectionnés : ${values}';
}

// Path: widgetbook.formatted_input
class _TranslationsWidgetbookFormattedInputFr extends TranslationsWidgetbookFormattedInputKo {
	_TranslationsWidgetbookFormattedInputFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get date_format => 'Format de date (MM/JJ/AAAA)';
	@override String get time_format => 'Format d\'heure (HH:MM)';
	@override String current_value({required Object value}) => 'Valeur actuelle : ${value}';
}

// Path: widgetbook.swiper
class _TranslationsWidgetbookSwiperFr extends TranslationsWidgetbookSwiperKo {
	_TranslationsWidgetbookSwiperFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get swipe_hint => 'Glissez ou appuyez pour ouvrir';
	@override String get overlay_content => 'Contenu de l\'overlay';
	@override String get close => 'Fermer';
}

// Path: docs.common
class _TranslationsDocsCommonFr extends TranslationsDocsCommonKo {
	_TranslationsDocsCommonFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get app_name => 'coui_flutter';
	@override String get search_documentation => 'Recherche dans la documentation...';
	@override String get docs => 'Documentation';
	@override String get components => 'Composants';
	@override String get close => 'Fermer';
	@override String get on_this_page => 'Table des matières de cette page';
	@override String get work_in_progress_title => 'En cours de développement';
	@override String get work_in_progress_message => 'Cette page est encore en développement. Veuillez revenir plus tard.';
	@override String get add => 'Ajouter';
	@override String get reset => 'Réinitialiser';
	@override String get prev => 'Précédent';
	@override String get next => 'Suivant';
	@override String get finish => 'Terminer';
	@override String get open => 'Ouvrir';
	@override String get disabled => 'Désactivé';
	@override String get refresh => 'Rafraîchir';
	@override String get rebuild => 'Reconstruire';
	@override String get change_color => 'Changer la couleur';
}

// Path: docs.badges
class _TranslationsDocsBadgesFr extends TranslationsDocsBadgesKo {
	_TranslationsDocsBadgesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get k_new => 'Nouveau';
	@override String get updated => 'Mis à jour';
	@override String get wip => 'En cours de développement';
	@override String get experimental => 'Expérimental';
}

// Path: docs.flavors
class _TranslationsDocsFlavorsFr extends TranslationsDocsFlavorsKo {
	_TranslationsDocsFlavorsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get local => 'Local';
	@override String get experimental => 'Expérimental';
	@override String get unknown => 'Inconnu';
}

// Path: docs.navigation
class _TranslationsDocsNavigationFr extends TranslationsDocsNavigationKo {
	_TranslationsDocsNavigationFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get getting_started => 'Commencer';
	@override String get animation => 'Animation';
	@override String get control => 'Contrôle';
	@override String get disclosure => 'Divulgation';
	@override String get display => 'Affichage';
	@override String get feedback => 'Retour d\'information';
	@override String get form => 'Formulaire';
	@override String get layout => 'Mise en page';
	@override String get navigation => 'Navigation';
	@override String get overlay => 'Superposition';
	@override String get utility => 'Utilitaire';
	@override String get my_account => 'Mon compte';
	@override String get profile => 'Profil';
	@override String get settings => 'Paramètres';
	@override String get team => 'Équipe';
	@override String get new_team => 'Nouvelle équipe';
	@override String get billing => 'Facturation';
	@override String get api => 'API';
	@override String get log_out => 'Se déconnecter';
	@override String get support => 'Soutien';
	@override String get invite_users => 'Inviter des utilisateurs';
	@override String get more => 'Plus';
	@override String get github => 'GitHub';
	@override String get note => 'Note';
	@override String get message => 'Message';
	@override String get keyboard_shortcuts => 'Raccourcis clavier';
}

// Path: docs.pages
class _TranslationsDocsPagesFr extends TranslationsDocsPagesKo {
	_TranslationsDocsPagesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsPagesIntroductionFr introduction = _TranslationsDocsPagesIntroductionFr._(_root);
	@override late final _TranslationsDocsPagesInstallationFr installation = _TranslationsDocsPagesInstallationFr._(_root);
	@override late final _TranslationsDocsPagesThemeFr theme = _TranslationsDocsPagesThemeFr._(_root);
	@override late final _TranslationsDocsPagesTypographyFr typography = _TranslationsDocsPagesTypographyFr._(_root);
	@override late final _TranslationsDocsPagesLayoutFr layout = _TranslationsDocsPagesLayoutFr._(_root);
	@override late final _TranslationsDocsPagesWebPreloaderFr web_preloader = _TranslationsDocsPagesWebPreloaderFr._(_root);
	@override late final _TranslationsDocsPagesComponentsListFr components_list = _TranslationsDocsPagesComponentsListFr._(_root);
	@override late final _TranslationsDocsPagesIconsFr icons = _TranslationsDocsPagesIconsFr._(_root);
	@override late final _TranslationsDocsPagesColorsFr colors = _TranslationsDocsPagesColorsFr._(_root);
	@override late final _TranslationsDocsPagesExternalFr external = _TranslationsDocsPagesExternalFr._(_root);
	@override late final _TranslationsDocsPagesStateFr state = _TranslationsDocsPagesStateFr._(_root);
}

// Path: docs.components
class _TranslationsDocsComponentsFr extends TranslationsDocsComponentsKo {
	_TranslationsDocsComponentsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsComponentsAccordionFr accordion = _TranslationsDocsComponentsAccordionFr._(_root);
	@override late final _TranslationsDocsComponentsAlertFr alert = _TranslationsDocsComponentsAlertFr._(_root);
	@override late final _TranslationsDocsComponentsAlertDialogFr alert_dialog = _TranslationsDocsComponentsAlertDialogFr._(_root);
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderFr animated_value_builder = _TranslationsDocsComponentsAnimatedValueBuilderFr._(_root);
	@override late final _TranslationsDocsComponentsAppBarFr app_bar = _TranslationsDocsComponentsAppBarFr._(_root);
	@override late final _TranslationsDocsComponentsAutocompleteFr autocomplete = _TranslationsDocsComponentsAutocompleteFr._(_root);
	@override late final _TranslationsDocsComponentsAvatarFr avatar = _TranslationsDocsComponentsAvatarFr._(_root);
	@override late final _TranslationsDocsComponentsAvatarGroupFr avatar_group = _TranslationsDocsComponentsAvatarGroupFr._(_root);
	@override late final _TranslationsDocsComponentsBadgeFr badge = _TranslationsDocsComponentsBadgeFr._(_root);
	@override late final _TranslationsDocsComponentsBreadcrumbFr breadcrumb = _TranslationsDocsComponentsBreadcrumbFr._(_root);
	@override late final _TranslationsDocsComponentsButtonFr button = _TranslationsDocsComponentsButtonFr._(_root);
	@override late final _TranslationsDocsComponentsCalendarFr calendar = _TranslationsDocsComponentsCalendarFr._(_root);
	@override late final _TranslationsDocsComponentsCardFr card = _TranslationsDocsComponentsCardFr._(_root);
	@override late final _TranslationsDocsComponentsCardImageFr card_image = _TranslationsDocsComponentsCardImageFr._(_root);
	@override late final _TranslationsDocsComponentsCarouselFr carousel = _TranslationsDocsComponentsCarouselFr._(_root);
	@override late final _TranslationsDocsComponentsCheckboxFr checkbox = _TranslationsDocsComponentsCheckboxFr._(_root);
	@override late final _TranslationsDocsComponentsChipFr chip = _TranslationsDocsComponentsChipFr._(_root);
	@override late final _TranslationsDocsComponentsChipInputFr chip_input = _TranslationsDocsComponentsChipInputFr._(_root);
	@override late final _TranslationsDocsComponentsCircularProgressFr circular_progress = _TranslationsDocsComponentsCircularProgressFr._(_root);
	@override late final _TranslationsDocsComponentsCodeSnippetFr code_snippet = _TranslationsDocsComponentsCodeSnippetFr._(_root);
	@override late final _TranslationsDocsComponentsCollapsibleFr collapsible = _TranslationsDocsComponentsCollapsibleFr._(_root);
	@override late final _TranslationsDocsComponentsColorPickerFr color_picker = _TranslationsDocsComponentsColorPickerFr._(_root);
	@override late final _TranslationsDocsComponentsCommandFr command = _TranslationsDocsComponentsCommandFr._(_root);
	@override late final _TranslationsDocsComponentsContextMenuFr context_menu = _TranslationsDocsComponentsContextMenuFr._(_root);
	@override late final _TranslationsDocsComponentsDatePickerFr date_picker = _TranslationsDocsComponentsDatePickerFr._(_root);
	@override late final _TranslationsDocsComponentsDialogFr dialog = _TranslationsDocsComponentsDialogFr._(_root);
	@override late final _TranslationsDocsComponentsDividerFr divider = _TranslationsDocsComponentsDividerFr._(_root);
	@override late final _TranslationsDocsComponentsDotIndicatorFr dot_indicator = _TranslationsDocsComponentsDotIndicatorFr._(_root);
	@override late final _TranslationsDocsComponentsDrawerFr drawer = _TranslationsDocsComponentsDrawerFr._(_root);
	@override late final _TranslationsDocsComponentsDropdownMenuFr dropdown_menu = _TranslationsDocsComponentsDropdownMenuFr._(_root);
	@override late final _TranslationsDocsComponentsExpandableSidebarFr expandable_sidebar = _TranslationsDocsComponentsExpandableSidebarFr._(_root);
	@override late final _TranslationsDocsComponentsFormFr form = _TranslationsDocsComponentsFormFr._(_root);
	@override late final _TranslationsDocsComponentsFormattedInputFr formatted_input = _TranslationsDocsComponentsFormattedInputFr._(_root);
	@override late final _TranslationsDocsComponentsHoverCardFr hover_card = _TranslationsDocsComponentsHoverCardFr._(_root);
	@override late final _TranslationsDocsComponentsInputFr input = _TranslationsDocsComponentsInputFr._(_root);
	@override late final _TranslationsDocsComponentsInputOtpFr input_otp = _TranslationsDocsComponentsInputOtpFr._(_root);
	@override late final _TranslationsDocsComponentsItemPickerFr item_picker = _TranslationsDocsComponentsItemPickerFr._(_root);
	@override late final _TranslationsDocsComponentsKeyboardDisplayFr keyboard_display = _TranslationsDocsComponentsKeyboardDisplayFr._(_root);
	@override late final _TranslationsDocsComponentsLinearProgressFr linear_progress = _TranslationsDocsComponentsLinearProgressFr._(_root);
	@override late final _TranslationsDocsComponentsMaterialFr material = _TranslationsDocsComponentsMaterialFr._(_root);
	@override late final _TranslationsDocsComponentsMenubarFr menubar = _TranslationsDocsComponentsMenubarFr._(_root);
	@override late final _TranslationsDocsComponentsMultiselectFr multiselect = _TranslationsDocsComponentsMultiselectFr._(_root);
	@override late final _TranslationsDocsComponentsNavigationBarFr navigation_bar = _TranslationsDocsComponentsNavigationBarFr._(_root);
	@override late final _TranslationsDocsComponentsNavigationMenuFr navigation_menu = _TranslationsDocsComponentsNavigationMenuFr._(_root);
	@override late final _TranslationsDocsComponentsNavigationRailFr navigation_rail = _TranslationsDocsComponentsNavigationRailFr._(_root);
	@override late final _TranslationsDocsComponentsNavigationSidebarFr navigation_sidebar = _TranslationsDocsComponentsNavigationSidebarFr._(_root);
	@override late final _TranslationsDocsComponentsNumberInputFr number_input = _TranslationsDocsComponentsNumberInputFr._(_root);
	@override late final _TranslationsDocsComponentsNumberTickerFr number_ticker = _TranslationsDocsComponentsNumberTickerFr._(_root);
	@override late final _TranslationsDocsComponentsOverflowMarqueeFr overflow_marquee = _TranslationsDocsComponentsOverflowMarqueeFr._(_root);
	@override late final _TranslationsDocsComponentsPaginationFr pagination = _TranslationsDocsComponentsPaginationFr._(_root);
	@override late final _TranslationsDocsComponentsPhoneInputFr phone_input = _TranslationsDocsComponentsPhoneInputFr._(_root);
	@override late final _TranslationsDocsComponentsPopoverFr popover = _TranslationsDocsComponentsPopoverFr._(_root);
	@override late final _TranslationsDocsComponentsProgressFr progress = _TranslationsDocsComponentsProgressFr._(_root);
	@override late final _TranslationsDocsComponentsRadioCardFr radio_card = _TranslationsDocsComponentsRadioCardFr._(_root);
	@override late final _TranslationsDocsComponentsRadioGroupFr radio_group = _TranslationsDocsComponentsRadioGroupFr._(_root);
	@override late final _TranslationsDocsComponentsRefreshTriggerFr refresh_trigger = _TranslationsDocsComponentsRefreshTriggerFr._(_root);
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderFr repeated_animation_builder = _TranslationsDocsComponentsRepeatedAnimationBuilderFr._(_root);
	@override late final _TranslationsDocsComponentsResizableFr resizable = _TranslationsDocsComponentsResizableFr._(_root);
	@override late final _TranslationsDocsComponentsScaffoldFr scaffold = _TranslationsDocsComponentsScaffoldFr._(_root);
	@override late final _TranslationsDocsComponentsSelectFr select = _TranslationsDocsComponentsSelectFr._(_root);
	@override late final _TranslationsDocsComponentsSheetFr sheet = _TranslationsDocsComponentsSheetFr._(_root);
	@override late final _TranslationsDocsComponentsSkeletonFr skeleton = _TranslationsDocsComponentsSkeletonFr._(_root);
	@override late final _TranslationsDocsComponentsSliderFr slider = _TranslationsDocsComponentsSliderFr._(_root);
	@override late final _TranslationsDocsComponentsSortableFr sortable = _TranslationsDocsComponentsSortableFr._(_root);
	@override late final _TranslationsDocsComponentsStarRatingFr star_rating = _TranslationsDocsComponentsStarRatingFr._(_root);
	@override late final _TranslationsDocsComponentsStepperFr stepper = _TranslationsDocsComponentsStepperFr._(_root);
	@override late final _TranslationsDocsComponentsStepsFr steps = _TranslationsDocsComponentsStepsFr._(_root);
	@override late final _TranslationsDocsComponentsSwiperFr swiper = _TranslationsDocsComponentsSwiperFr._(_root);
	@override late final _TranslationsDocsComponentsKSwitchFr k_switch = _TranslationsDocsComponentsKSwitchFr._(_root);
	@override late final _TranslationsDocsComponentsSwitcherFr switcher = _TranslationsDocsComponentsSwitcherFr._(_root);
	@override late final _TranslationsDocsComponentsTabListFr tab_list = _TranslationsDocsComponentsTabListFr._(_root);
	@override late final _TranslationsDocsComponentsTabPaneFr tab_pane = _TranslationsDocsComponentsTabPaneFr._(_root);
	@override late final _TranslationsDocsComponentsTableFr table = _TranslationsDocsComponentsTableFr._(_root);
	@override late final _TranslationsDocsComponentsTabsFr tabs = _TranslationsDocsComponentsTabsFr._(_root);
	@override late final _TranslationsDocsComponentsTextAreaFr text_area = _TranslationsDocsComponentsTextAreaFr._(_root);
	@override late final _TranslationsDocsComponentsTimePickerFr time_picker = _TranslationsDocsComponentsTimePickerFr._(_root);
	@override late final _TranslationsDocsComponentsTimelineFr timeline = _TranslationsDocsComponentsTimelineFr._(_root);
	@override late final _TranslationsDocsComponentsTimelineAnimationFr timeline_animation = _TranslationsDocsComponentsTimelineAnimationFr._(_root);
	@override late final _TranslationsDocsComponentsToastFr toast = _TranslationsDocsComponentsToastFr._(_root);
	@override late final _TranslationsDocsComponentsToggleFr toggle = _TranslationsDocsComponentsToggleFr._(_root);
	@override late final _TranslationsDocsComponentsTooltipFr tooltip = _TranslationsDocsComponentsTooltipFr._(_root);
	@override late final _TranslationsDocsComponentsTrackerFr tracker = _TranslationsDocsComponentsTrackerFr._(_root);
	@override late final _TranslationsDocsComponentsTreeFr tree = _TranslationsDocsComponentsTreeFr._(_root);
	@override late final _TranslationsDocsComponentsWindowFr window = _TranslationsDocsComponentsWindowFr._(_root);
}

// Path: docs.pages.introduction
class _TranslationsDocsPagesIntroductionFr extends TranslationsDocsPagesIntroductionKo {
	_TranslationsDocsPagesIntroductionFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Introduction';
	@override String get description => 'Commencer avec coui_flutter';
	@override String get lead => 'Les composants magnifiquement conçus de Coui/UI sont désormais disponibles sur Flutter.';
	@override String get welcome_paragraph_1 => 'coui_flutter est un ensemble complet et diversifié de composants UI spécialement conçus pour les applications de bureau et web Flutter. Avec la popularité croissante de Flutter pour la création d\'applications multiplateformes, nous avons reconnu la nécessité d\'un ensemble d\'outils qui met en évidence les exigences uniques de conception des interfaces de bureau et web.';
	@override String get welcome_paragraph_2 => 'Ce paquet propose un large éventail de composants personnalisables et réactifs, conformes aux principes de design modernes de bureau et web. Que vous construisiez des applications commerciales sophistiquées, des tableaux de bord élégants ou des outils de productivité, nos composants sont conçus pour vous aider à créer rapidement et efficacement une interface utilisateur professionnelle et raffinée.';
	@override String get features => 'Fonctionnalités principales';
	@override late final _TranslationsDocsPagesIntroductionFeaturesListFr features_list = _TranslationsDocsPagesIntroductionFeaturesListFr._(_root);
	@override String get notes => 'Remarques';
	@override String get notes_paragraph_1 => 'Ce paquet est toujours en développement et peut être sujet à des modifications futures. Veuillez faire preuve de prudence lorsque vous utilisez ce paquet en production.';
	@override String get notes_paragraph_2 => 'Ce paquet n\'est pas affilié à Coui/UI. Il s\'agit d\'un projet dirigé par la communauté.';
	@override String get faq => 'Questions fréquemment posées';
	@override String get faq_gorouter_q => 'Supportez-vous GoRouter ?';
	@override String get faq_gorouter_a => 'Oui, nous le supportons. Vous pouvez utiliser GoRouter avec coui_flutter.';
	@override String get faq_usage_q => 'Puis-je l\'utiliser dans mon projet ?';
	@override String get faq_usage_a => 'Oui ! Vous pouvez l\'utiliser gratuitement pour des projets personnels et commerciaux. Aucune attribution n\'est requise.';
	@override String get faq_material_q => 'Puis-je l\'utiliser avec des widgets Material/Cupertino ?';
	@override String get faq_material_a_1 => 'Bien sûr !';
	@override String get faq_material_a_2 => 'Veuillez consulter cette page !';
	@override String get faq_style_q => 'Puis-je configurer quel style utiliser ? (Default/New York)';
	@override String get faq_style_a_1 => 'Malheureusement, ce n\'est pas possible. Ce paquet ne prend en charge que le style New York. Mais si vous voulez le style par défaut de Coui/UI,';
	@override String get faq_style_a_2 => 'je recommande';
	@override String get faq_style_a_3 => 'ce paquet. Créé par :';
	@override String get links => 'Liens';
	@override String get link_github => 'Github : ';
	@override String get link_pubdev => 'pub.dev : ';
	@override String get link_discord => 'Discord : ';
}

// Path: docs.pages.installation
class _TranslationsDocsPagesInstallationFr extends TranslationsDocsPagesInstallationKo {
	_TranslationsDocsPagesInstallationFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Installation';
	@override String get description => 'Installer coui_flutter dans votre projet';
	@override String get stable_version => 'Version stable';
	@override String get experimental_version => 'Version expérimentale';
	@override String get step1_title => 'Créer un nouveau projet Flutter';
	@override String get step1_content => 'Utilisez la commande suivante pour créer un nouveau projet Flutter :';
	@override String get step2_title => 'Ajouter des dépendances';
	@override String get step2_content => 'Ensuite, ajoutez la dépendance coui_flutter à votre projet.';
	@override String get step3_title => 'Importer le package';
	@override String get step3_content => 'Vous pouvez maintenant importer le package dans votre code Dart.';
	@override String get step4_title => 'Ajouter le widget CouiApp';
	@override String get step4_content => 'Ajoutez le widget CouiApp à votre fonction main.';
	@override String get step5_title => 'Exécuter l\'application';
	@override String get step5_content => 'Utilisez la commande suivante pour exécuter l\'application :';
	@override String get experimental_intro => 'La version expérimentale est disponible sur GitHub.';
	@override String get experimental_usage => 'Pour utiliser la version expérimentale, remplacez le numéro de version par git dans le fichier pubspec.yaml :';
	@override String get see_page => 'Voir : ';
	@override String get this_page => 'cette page';
	@override String get for_more_info => ' pour plus d\'informations.';
	@override String get warning_title => 'Avertissement';
	@override String get warning_content => 'La version expérimentale peut contenir des modifications qui brisent la compatibilité et n\'est pas recommandée pour une utilisation en production. Cette version doit être utilisée uniquement à des fins de test et de développement.';
}

// Path: docs.pages.theme
class _TranslationsDocsPagesThemeFr extends TranslationsDocsPagesThemeKo {
	_TranslationsDocsPagesThemeFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Thème';
	@override String get description => 'Personnalisation du thème';
	@override String get custom_color_scheme => 'Schéma de couleurs personnalisé';
	@override String get custom_color_scheme_desc => 'Utilisez un schéma de couleurs personnalisé pour personnaliser l\'apparence de votre application.';
	@override String get premade_color_schemes => 'Schémas de couleurs prédéfinis';
	@override String get premade_color_schemes_desc => 'Utilisez des schémas de couleurs prédéfinis pour personnaliser l\'apparence de votre application.';
	@override String get radius => 'Rayon';
	@override String get radius_desc => 'Modifiez le rayon pour personnaliser le degré d\'arrondi de votre application.';
	@override String get scaling => 'Mise à l\'échelle';
	@override String get scaling_desc => 'Modifiez la mise à l\'échelle pour personnaliser le rapport des composants coui_flutter.';
	@override String get scaling_alert => 'Cela n\'agrandit/réduit pas l\'ensemble de l\'application. Seuls les composants coui_flutter sont affectés.';
	@override String get surface_opacity => 'Opacité de la surface';
	@override String get surface_opacity_desc => 'Modifiez l\'opacité de la surface pour personnaliser la transparence de la surface.';
	@override String get surface_blur => 'Flou de la surface';
	@override String get surface_blur_desc => 'Modifiez le flou de la surface pour personnaliser le flou de la surface.';
	@override String get code => 'Code';
	@override String get code_desc => 'Utilisez le code suivant pour appliquer le schéma de couleurs.';
}

// Path: docs.pages.typography
class _TranslationsDocsPagesTypographyFr extends TranslationsDocsPagesTypographyKo {
	_TranslationsDocsPagesTypographyFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Typographie';
	@override String get description => 'Styles de texte';
	@override String get headline1 => 'Titre 1';
	@override String get headline2 => 'Titre 2';
	@override String get headline3 => 'Titre 3';
	@override String get headline4 => 'Titre 4';
	@override String get paragraph => 'Paragraphe';
	@override String get blockquote => 'Citation';
	@override String get list => 'Liste';
	@override String get inline_code => 'Code en ligne';
	@override String get lead => 'Lead';
	@override String get large_text => 'Texte grand';
	@override String get small_text => 'Texte petit';
	@override String get muted_text => 'Texte atténué';
	@override String get sans => 'Sans empattement';
	@override String get mono => 'Monospace';
	@override String get extra_small => 'Très petit';
	@override String get small => 'Petit';
	@override String get base => 'De base';
	@override String get large => 'Grand';
	@override String get extra_large => 'Très grand';
	@override String get extra_2x_large => 'Très 2x grand';
	@override String get extra_3x_large => 'Très 3x grand';
	@override String get extra_4x_large => 'Très 4x grand';
	@override String get extra_5x_large => 'Très 5x grand';
	@override String get extra_6x_large => 'Très 6x grand';
	@override String get extra_7x_large => 'Très 7x grand';
	@override String get extra_8x_large => 'Très 8x grand';
	@override String get extra_9x_large => 'Très 9x grand';
	@override String get thin => 'Fin';
	@override String get extra_light => 'Très léger';
	@override String get light => 'Léger';
	@override String get normal => 'Normal';
	@override String get medium => 'Moyen';
	@override String get semi_bold => 'Semi-gras';
	@override String get bold => 'Gras';
	@override String get extra_bold => 'Très gras';
	@override String get black => 'Noir';
	@override String get italic => 'Italique';
}

// Path: docs.pages.layout
class _TranslationsDocsPagesLayoutFr extends TranslationsDocsPagesLayoutKo {
	_TranslationsDocsPagesLayoutFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mise en page';
	@override String get description => 'Configuration de la mise en page de la page';
	@override String get padding => 'Marge intérieure';
	@override String get margin => 'Marge';
	@override String get center => 'Centre';
	@override String get gapped_column => 'Colonne avec espacement';
	@override String get gapped_row => 'Ligne avec espacement';
	@override String get separated_column => 'Colonne séparée';
	@override String get separated_row => 'Ligne séparée';
	@override String get basic_layout => 'Mise en page de base';
}

// Path: docs.pages.web_preloader
class _TranslationsDocsPagesWebPreloaderFr extends TranslationsDocsPagesWebPreloaderKo {
	_TranslationsDocsPagesWebPreloaderFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Préchargeur Web';
	@override String get description => 'Écran de chargement Web';
	@override String get step1_title => 'Créer un répertoire web';
	@override String get step1_content => 'Créez un répertoire web s\'il n\'existe pas.';
	@override String get step1_note => '* Si vous utilisez l\'ancien web Flutter, vous devrez utiliser la commande ci-dessus pour mettre à jour.';
	@override String get step1_button => 'Cliquez ici pour plus d\'informations.';
	@override String get step2_title => 'Ajouter un script';
	@override String get step2_content => 'Ensuite, choisissez l\'un des préchargeurs prédéfinis ci-dessous et copiez-le :';
	@override String get step2_standard => 'Préchargeur standard';
	@override String get step3_title => 'Coller le script';
	@override String get step3_content_1 => 'Ouvrez votre ';
	@override String get step3_content_2 => ' fichier et collez le script dans la ';
	@override String get step3_content_3 => ' balise.';
	@override String get step3_example => 'Par exemple :';
	@override String get step4_title => 'Exécuter l\'application';
	@override String get step4_content => 'Utilisez la commande suivante pour exécuter l\'application :';
	@override String get alert_title => 'Contribuer';
	@override String get alert_content_1 => 'Si vous avez un préchargeur que vous souhaitez partager, créez une requête de tirage dans le répertoire ';
	@override String get alert_button => 'web_loaders';
	@override String get alert_content_2 => '.';
}

// Path: docs.pages.components_list
class _TranslationsDocsPagesComponentsListFr extends TranslationsDocsPagesComponentsListKo {
	_TranslationsDocsPagesComponentsListFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Composants';
	@override String get description => 'Liste de composants réutilisables';
	@override String get work_in_progress => 'En cours';
	@override String get animation => 'Animation';
	@override String get disclosure => 'Divulgation';
	@override String get feedback => 'Retour d\'information';
	@override String get forms => 'Formulaires';
	@override String get layout => 'Mise en page';
	@override String get navigation => 'Navigation';
	@override String get surfaces => 'Surfaces';
	@override String get data_display => 'Affichage des données';
	@override String get utilities => 'Utilitaires';
}

// Path: docs.pages.icons
class _TranslationsDocsPagesIconsFr extends TranslationsDocsPagesIconsKo {
	_TranslationsDocsPagesIconsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Icônes';
	@override String get description => 'Système d\'icônes';
	@override String get use_this_code => 'Utilisez le code suivant pour afficher cette icône :';
	@override String get search_icons => 'Rechercher des icônes';
	@override String get radix_icons => 'Icônes Radix';
	@override String get bootstrap_icons => 'Icônes Bootstrap';
	@override String get lucide_icons => 'Icônes Lucide';
}

// Path: docs.pages.colors
class _TranslationsDocsPagesColorsFr extends TranslationsDocsPagesColorsKo {
	_TranslationsDocsPagesColorsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Couleurs';
	@override String get description => 'Palette de couleurs';
	@override String get use_this_code => 'Utilisez le code suivant pour afficher cette couleur :';
	@override String get color_and_colorshades => 'Constantes Color et ColorShades/ColorSwatch';
	@override String get predefined_colors => 'Couleurs prédéfinies';
	@override String get generate_color => 'Générer une couleur';
	@override String get hue_shift => 'Changement de teinte';
	@override String get saturation_step_up => 'Augmenter la saturation';
	@override String get saturation_step_down => 'Diminuer la saturation';
	@override String get lightness_step_up => 'Augmenter la luminosité';
	@override String get lightness_step_down => 'Diminuer la luminosité';
	@override String get cancel => 'Annuler';
	@override String get reset_options => 'Réinitialiser les options';
	@override String get reset_confirmation => 'Voulez-vous réinitialiser les options ?';
}

// Path: docs.pages.external
class _TranslationsDocsPagesExternalFr extends TranslationsDocsPagesExternalKo {
	_TranslationsDocsPagesExternalFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Material/Cupertino';
	@override String get description => 'Widgets Material de base pour Flutter';
}

// Path: docs.pages.state
class _TranslationsDocsPagesStateFr extends TranslationsDocsPagesStateKo {
	_TranslationsDocsPagesStateFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gestion d\'état';
	@override String get description => 'Patrons de gestion d\'état';
	@override String get intro_1 => 'Dans Flutter, tout est un widget et c\'est aussi là où les données sont stockées.';
	@override String get intro_2 => 'En interne, coui_flutter dispose de son propre système de gestion d\'état. Si vous utilisez déjà un système de gestion d\'état, vous pouvez continuer à l\'utiliser avec coui_flutter.';
	@override String get passing_data_to_children => 'Passer des données aux enfants';
	@override String get passing_data_desc => 'Vous pouvez utiliser le widget Data pour passer des données à vos enfants. Tous les changements sur les données entraîneront une reconstruction des enfants.';
	@override String get rebuild_difference_title => 'Avez-vous remarqué la différence de reconstruction ?';
	@override String get rebuild_difference_content => 'MostInnerWidget se reconstruit lorsque les données changent, mais InnerWidget ne le fait pas. C\'est parce que InnerWidget ne reçoit pas les données.';
	@override String get setting_data_boundary => 'Définir une frontière de données';
	@override String get setting_data_boundary_desc => 'Vous pouvez définir une frontière pour que les enfants ne puissent pas accéder aux données.';
	@override String get data_methods_vs => 'Data.maybeOf/Data.of vs Data.maybeFind/Data.find';
	@override String get data_methods_desc_1 => ' et ';
	@override String get data_methods_desc_2 => ' reçoivent des données et reconstruisent le widget lorsque les données changent. En revanche, ';
	@override String get data_methods_desc_3 => ' ne les reçoit pas et ne fait que retourner les données.';
	@override String get data_find_usage => 's\'utilise bien là où les méthodes comme onPressed, onLongPressed, etc., sont appelées une fois.';
	@override String get data_of_usage => 's\'utilise bien dans le méthode build où il doit reconstruire le widget lorsque les données changent.';
	@override String get getting_data_from_child => 'Obtenir des données d\'un enfant';
	@override String get getting_data_desc_1 => 'Vous pouvez utiliser le méthode pour obtenir des données d\'un enfant. Cette méthode ne reçoit pas les changements sur les données.';
	@override String get getting_data_desc_2 => 'Recevoir des données d\'un enfant pourrait créer une boucle infinie de reconstruction. Si vous devez recevoir des données, déplacez-vous vers le widget parent.';
	@override String get root_data_title => 'Avez-vous remarqué les données racines ?';
	@override String get root_data_content => 'Utilise les données du widget le plus interne à gauche. Parce que les parents ne peuvent obtenir des données que du premier enfant connecté.';
	@override String get setting_messenger_boundary => 'Définir une frontière de DataMessenger';
	@override String get setting_messenger_boundary_desc => 'Vous pouvez définir une frontière pour empêcher l\'obtention des données des enfants d\'un parent spécifique.';
	@override String get multidata_widget => 'Widget MultiData';
	@override String get multidata_desc => 'Avec le widget MultiData, vous pouvez passer plusieurs données à des enfants. Consultez l\'exemple ci-dessous :';
	@override String get multidata_avoid_nesting => 'Vous pouvez éviter l\'imbrication en utilisant le widget MultiData.';
	@override String get example => 'Exemple';
	@override String get passing_state_as_controller => 'Passer l\'état en tant que contrôleur';
	@override String get passing_state_controller_desc => 'Vous pouvez passer l\'état comme un contrôleur à des enfants. Cela permet aux widgets enfants d\'appeler des méthodes sur le widget parent.';
	@override String get databuilder => 'DataBuilder';
	@override String get databuilder_desc => 'Utilisez le widget DataBuilder pour reconstruire le widget lorsque les données changent. Cela évite de reconstruire l\'ensemble du widget.';
	@override String get datanotifier => 'DataNotifier';
	@override String get datanotifier_desc => 'Avec DataNotifier, vous pouvez passer des valeurs d\'erreur ValueListenable aux enfants.';
	@override String get example_with_multidata => 'Exemple d\'utilisation de MultiData';
	@override String get passing_object_as_data => 'Passer un objet comme données';
	@override String get passing_object_desc => 'Il y a quelques considérations à garder à l\'esprit lorsque vous passez des objets comme données :';
	@override String get override_equals_hashcode => '1. Surcharger == et hashCode';
	@override String get override_equals_desc => 'Une alerte sera envoyée aux enfants lorsque le dernier objet ne sera pas le même que le nouvel objet. Si you ne surchargez pas == et hashCode, l\'objet sera toujours considéré comme différent à chaque instanciation même si les valeurs des champs sont identiques.';
	@override String get use_distinctdata => '2. Utiliser DistinctData';
	@override String get use_distinctdata_desc => 'DistinctData est un mixin qui peut alerter les enfants lorsque certains champs changent.';
	@override String get passing_mutable_object => '3. Passer des objets mutables aux enfants';
	@override String get passing_mutable_object_desc => 'Il est préférable de passer des objets immuables aux enfants. Les objets mutables (comme List, Map, Set, Widget State) ne préviendront pas les enfants lorsque l\'objet changera car la référence de l\'objet ne change pas.';
	@override String get passing_variable_to_children => 'Passer des variables aux enfants';
	@override String get passing_variable_desc => 'Vous pouvez utiliser le widget Model pour passer des variables à des enfants. Similaire au widget Data mais avec une exigence de type stricte.';
	@override String get change_variable_from_children => 'Changer une variable depuis les enfants';
	@override String get change_variable_desc => 'Il existe deux façons de modifier la valeur du modèle depuis les enfants :';
	@override String get modelnotifier => 'ModelNotifier';
	@override String get modelnotifier_desc => 'Avec ModelNotifier, vous pouvez passer des valeurs de ValueNotifier aux enfants. Aucun besoin d\'utiliser setState dans le widget parent.';
	@override String get modellistenable => 'ModelListenable';
	@override String get modellistenable_desc => 'ModelListenable est un ModelNotifier en lecture seule. Les enfants ne pourront que recevoir des valeurs. Tenter de changer des valeurs entraînera une erreur.';
	@override String get modelbuilder => 'ModelBuilder';
	@override String get modelbuilder_desc => 'ModelBuilder reçoit des valeurs lorsque celles-ci changent et reconstruit le widget. Similaire à DataBuilder mais avec une exigence de type stricte.';
}

// Path: docs.components.accordion
class _TranslationsDocsComponentsAccordionFr extends TranslationsDocsComponentsAccordionKo {
	_TranslationsDocsComponentsAccordionFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Accordéon';
	@override String get description => 'L\'accordéon est une liste d\'éléments empilés verticalement. Chaque élément peut être \'développé\' ou \'réduit\' pour afficher le contenu associé.';
	@override late final _TranslationsDocsComponentsAccordionExamplesFr examples = _TranslationsDocsComponentsAccordionExamplesFr._(_root);
}

// Path: docs.components.alert
class _TranslationsDocsComponentsAlertFr extends TranslationsDocsComponentsAlertKo {
	_TranslationsDocsComponentsAlertFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Alerte';
	@override String get description => 'Les alertes sont utilisées pour transmettre des états qui affectent le système.';
	@override late final _TranslationsDocsComponentsAlertExamplesFr examples = _TranslationsDocsComponentsAlertExamplesFr._(_root);
	@override String get title => 'Titre de l\'alerte';
	@override String get content => 'Ceci est le contenu de l\'alerte.';
}

// Path: docs.components.alert_dialog
class _TranslationsDocsComponentsAlertDialogFr extends TranslationsDocsComponentsAlertDialogKo {
	_TranslationsDocsComponentsAlertDialogFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Dialogue d\'alerte';
	@override String get description => 'Le dialogue d\'alerte affiche des informations importantes qui nécessitent l\'attention de l\'utilisateur.';
	@override late final _TranslationsDocsComponentsAlertDialogExamplesFr examples = _TranslationsDocsComponentsAlertDialogExamplesFr._(_root);
	@override String get click_here => 'Cliquez ici';
	@override String get alert_title => 'Titre de l\'alerte';
	@override String get alert_content => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
}

// Path: docs.components.animated_value_builder
class _TranslationsDocsComponentsAnimatedValueBuilderFr extends TranslationsDocsComponentsAnimatedValueBuilderKo {
	_TranslationsDocsComponentsAnimatedValueBuilderFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Constructeur de valeur animée';
	@override String get description => 'Un constructeur qui applique automatiquement des animations lors de changements de valeur.';
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderExamplesFr examples = _TranslationsDocsComponentsAnimatedValueBuilderExamplesFr._(_root);
}

// Path: docs.components.app_bar
class _TranslationsDocsComponentsAppBarFr extends TranslationsDocsComponentsAppBarKo {
	_TranslationsDocsComponentsAppBarFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barre d\'application';
	@override String get description => 'La barre d\'application est un élément de navigation principal affiché en haut de l\'application.';
	@override late final _TranslationsDocsComponentsAppBarExamplesFr examples = _TranslationsDocsComponentsAppBarExamplesFr._(_root);
}

// Path: docs.components.autocomplete
class _TranslationsDocsComponentsAutocompleteFr extends TranslationsDocsComponentsAutocompleteKo {
	_TranslationsDocsComponentsAutocompleteFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Auto-complétion';
	@override String get description => 'Une zone de saisie qui affiche des suggestions en fonction de l\'entrée de l\'utilisateur.';
	@override late final _TranslationsDocsComponentsAutocompleteExamplesFr examples = _TranslationsDocsComponentsAutocompleteExamplesFr._(_root);
}

// Path: docs.components.avatar
class _TranslationsDocsComponentsAvatarFr extends TranslationsDocsComponentsAvatarKo {
	_TranslationsDocsComponentsAvatarFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Avatar';
	@override String get description => 'Une image ou une icône représentant un utilisateur ou une entité.';
	@override late final _TranslationsDocsComponentsAvatarExamplesFr examples = _TranslationsDocsComponentsAvatarExamplesFr._(_root);
}

// Path: docs.components.avatar_group
class _TranslationsDocsComponentsAvatarGroupFr extends TranslationsDocsComponentsAvatarGroupKo {
	_TranslationsDocsComponentsAvatarGroupFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Groupe d\'avatars';
	@override String get description => 'Affiche plusieurs avatars ensemble.';
	@override late final _TranslationsDocsComponentsAvatarGroupExamplesFr examples = _TranslationsDocsComponentsAvatarGroupExamplesFr._(_root);
}

// Path: docs.components.badge
class _TranslationsDocsComponentsBadgeFr extends TranslationsDocsComponentsBadgeKo {
	_TranslationsDocsComponentsBadgeFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Badge';
	@override String get description => 'Une petite étiquette affichant un état ou un nombre de notifications.';
	@override late final _TranslationsDocsComponentsBadgeExamplesFr examples = _TranslationsDocsComponentsBadgeExamplesFr._(_root);
	@override String get primary => 'Primaire';
	@override String get secondary => 'Secondaire';
	@override String get outline => 'Contour';
	@override String get destructive => 'Destructeur';
}

// Path: docs.components.breadcrumb
class _TranslationsDocsComponentsBreadcrumbFr extends TranslationsDocsComponentsBreadcrumbKo {
	_TranslationsDocsComponentsBreadcrumbFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Fil d\'Ariane';
	@override String get description => 'Le fil d\'Ariane est un système de navigation secondaire indiquant la position de l\'utilisateur sur un site Web ou une application Web.';
	@override late final _TranslationsDocsComponentsBreadcrumbExamplesFr examples = _TranslationsDocsComponentsBreadcrumbExamplesFr._(_root);
	@override String get home => 'Accueil';
	@override String get components => 'Composants';
}

// Path: docs.components.button
class _TranslationsDocsComponentsButtonFr extends TranslationsDocsComponentsButtonKo {
	_TranslationsDocsComponentsButtonFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Bouton';
	@override String get description => 'Un bouton permet à l\'utilisateur d\'effectuer une action ou de faire un choix avec un tap.';
	@override late final _TranslationsDocsComponentsButtonExamplesFr examples = _TranslationsDocsComponentsButtonExamplesFr._(_root);
	@override String get primary => 'Primaire';
	@override String get secondary => 'Secondaire';
	@override String get outlined => 'En contour';
	@override String get ghost => 'Fantôme';
	@override String get destructive => 'Destructeur';
	@override String get link => 'Lien';
	@override String get outline => 'Contour';
	@override String get text => 'Texte';
	@override String get extra_small => 'Très petit';
	@override String get small => 'Petit';
	@override String get normal => 'Normal';
	@override String get large => 'Grand';
	@override String get extra_large => 'Très grand';
	@override String get save => 'Enregistrer';
	@override String get cancel => 'Annuler';
	@override String get close => 'Fermer';
	@override String get submit => 'Soumettre';
	@override String get edit_profile => 'Modifier le profil';
	@override String get save_changes => 'Enregistrer les modifications';
	@override String get undo => 'Annuler';
	@override String get compact => 'Compact';
	@override String get dense => 'Dense';
	@override String get comfortable => 'Confortable';
	@override String get icon => 'Icône';
	@override String get icon_comfortable => 'Icône confortable';
	@override String get rectangle => 'Rectangle';
	@override String get add => 'Ajouter';
	@override String get focused => 'Focalisé';
	@override String get hovered => 'Survolé';
	@override String get pressed => 'Appuyé';
	@override String get text_button => 'Bouton texte';
	@override String get custom_button => 'Bouton personnalisé';
}

// Path: docs.components.calendar
class _TranslationsDocsComponentsCalendarFr extends TranslationsDocsComponentsCalendarKo {
	_TranslationsDocsComponentsCalendarFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Calendrier';
	@override String get description => 'Un composant calendrier permettant de sélectionner et d\'afficher des dates.';
	@override late final _TranslationsDocsComponentsCalendarExamplesFr examples = _TranslationsDocsComponentsCalendarExamplesFr._(_root);
}

// Path: docs.components.card
class _TranslationsDocsComponentsCardFr extends TranslationsDocsComponentsCardKo {
	_TranslationsDocsComponentsCardFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Carte';
	@override String get description => 'Description';
	@override late final _TranslationsDocsComponentsCardExamplesFr examples = _TranslationsDocsComponentsCardExamplesFr._(_root);
	@override String get create_project => 'Créer un projet';
	@override String get deploy_description => 'Déployez un nouveau projet en un clic';
	@override String get name => 'Nom';
	@override String get name_placeholder => 'Nom du projet';
	@override String get description_placeholder => 'Description du projet';
	@override String get deploy => 'Déployer';
}

// Path: docs.components.card_image
class _TranslationsDocsComponentsCardImageFr extends TranslationsDocsComponentsCardImageKo {
	_TranslationsDocsComponentsCardImageFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Carte d\'image';
	@override String get description => 'Un composant de carte contenant une image.';
	@override late final _TranslationsDocsComponentsCardImageExamplesFr examples = _TranslationsDocsComponentsCardImageExamplesFr._(_root);
	@override String get card_image_title => 'Image de carte';
	@override String get card_clicked => 'Vous avez cliqué sur l\'image de carte';
	@override String card_number({required Object n}) => 'Numéro de carte ${n}';
	@override String get lorem_ipsum => 'Lorem ipsum dolor sit amet';
}

// Path: docs.components.carousel
class _TranslationsDocsComponentsCarouselFr extends TranslationsDocsComponentsCarouselKo {
	_TranslationsDocsComponentsCarouselFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Carrousel';
	@override String get description => 'Un composant qui affiche plusieurs éléments sous forme de diaporama.';
	@override late final _TranslationsDocsComponentsCarouselExamplesFr examples = _TranslationsDocsComponentsCarouselExamplesFr._(_root);
}

// Path: docs.components.checkbox
class _TranslationsDocsComponentsCheckboxFr extends TranslationsDocsComponentsCheckboxKo {
	_TranslationsDocsComponentsCheckboxFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Case à cocher';
	@override String get description => 'La case à cocher permet à l\'utilisateur de sélectionner un ou plusieurs éléments dans une liste.';
	@override late final _TranslationsDocsComponentsCheckboxExamplesFr examples = _TranslationsDocsComponentsCheckboxExamplesFr._(_root);
	@override String get remember_me => 'Se souvenir de moi';
}

// Path: docs.components.chip
class _TranslationsDocsComponentsChipFr extends TranslationsDocsComponentsChipKo {
	_TranslationsDocsComponentsChipFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Puce';
	@override String get description => 'Une puce est un petit élément représentant une propriété, une option ou une action.';
	@override late final _TranslationsDocsComponentsChipExamplesFr examples = _TranslationsDocsComponentsChipExamplesFr._(_root);
	@override String get apple => 'Pomme';
	@override String get banana => 'Banane';
	@override String get cherry => 'Cerise';
	@override String get durian => 'Durian';
	@override String get elderberry => 'Sureau';
}

// Path: docs.components.chip_input
class _TranslationsDocsComponentsChipInputFr extends TranslationsDocsComponentsChipInputKo {
	_TranslationsDocsComponentsChipInputFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrée de puce';
	@override String get description => 'Un champ d\'entrée permettant d\'entrer plusieurs valeurs sous forme de puces.';
	@override late final _TranslationsDocsComponentsChipInputExamplesFr examples = _TranslationsDocsComponentsChipInputExamplesFr._(_root);
}

// Path: docs.components.circular_progress
class _TranslationsDocsComponentsCircularProgressFr extends TranslationsDocsComponentsCircularProgressKo {
	_TranslationsDocsComponentsCircularProgressFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Progression circulaire';
	@override String get description => 'Un indicateur de progression circulaire.';
	@override late final _TranslationsDocsComponentsCircularProgressExamplesFr examples = _TranslationsDocsComponentsCircularProgressExamplesFr._(_root);
	@override String get increase_by_10 => 'Augmenter de 10';
	@override String get decrease_by_10 => 'Diminuer de 10';
}

// Path: docs.components.code_snippet
class _TranslationsDocsComponentsCodeSnippetFr extends TranslationsDocsComponentsCodeSnippetKo {
	_TranslationsDocsComponentsCodeSnippetFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Extrait de code';
	@override String get description => 'Un composant pour afficher du code.';
	@override late final _TranslationsDocsComponentsCodeSnippetExamplesFr examples = _TranslationsDocsComponentsCodeSnippetExamplesFr._(_root);
}

// Path: docs.components.collapsible
class _TranslationsDocsComponentsCollapsibleFr extends TranslationsDocsComponentsCollapsibleKo {
	_TranslationsDocsComponentsCollapsibleFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Collapsible';
	@override String get description => 'Un conteneur de contenu pouvant être replié ou déplié.';
	@override late final _TranslationsDocsComponentsCollapsibleExamplesFr examples = _TranslationsDocsComponentsCollapsibleExamplesFr._(_root);
	@override String get starred_repositories => '@coco-de a étoilé 3 dépôts';
	@override String get collapse_all => 'Tout réduire';
	@override String get expand_all => 'Tout développer';
	@override String get expand_icon => 'Icône de développement';
	@override String get use_path_branch => 'Utiliser la branche du chemin';
	@override String get recursive_selection => 'Sélection récursive';
}

// Path: docs.components.color_picker
class _TranslationsDocsComponentsColorPickerFr extends TranslationsDocsComponentsColorPickerKo {
	_TranslationsDocsComponentsColorPickerFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Sélecteur de couleur';
	@override String get description => 'Un composant pour choisir une couleur.';
	@override late final _TranslationsDocsComponentsColorPickerExamplesFr examples = _TranslationsDocsComponentsColorPickerExamplesFr._(_root);
	@override String get pick_color => 'Choisir une couleur';
	@override String color_label({required Object color}) => 'Couleur: ${color}';
	@override String get select_color => 'Sélectionner une couleur';
	@override String get open_color_picker_popover => 'Ouvrir le popover du sélecteur de couleurs';
	@override String get open_color_picker_dialog => 'Ouvrir la boîte de dialogue du sélecteur de couleurs';
}

// Path: docs.components.command
class _TranslationsDocsComponentsCommandFr extends TranslationsDocsComponentsCommandKo {
	_TranslationsDocsComponentsCommandFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Commande';
	@override String get description => 'Un composant pour rechercher des éléments.';
	@override late final _TranslationsDocsComponentsCommandExamplesFr examples = _TranslationsDocsComponentsCommandExamplesFr._(_root);
}

// Path: docs.components.context_menu
class _TranslationsDocsComponentsContextMenuFr extends TranslationsDocsComponentsContextMenuKo {
	_TranslationsDocsComponentsContextMenuFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Menu contextuel';
	@override String get description => 'Un menu affiché par un clic droit ou un appui long.';
	@override late final _TranslationsDocsComponentsContextMenuExamplesFr examples = _TranslationsDocsComponentsContextMenuExamplesFr._(_root);
}

// Path: docs.components.date_picker
class _TranslationsDocsComponentsDatePickerFr extends TranslationsDocsComponentsDatePickerKo {
	_TranslationsDocsComponentsDatePickerFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Sélecteur de date';
	@override String get description => 'Un champ d\'entrée permettant de sélectionner une date.';
	@override late final _TranslationsDocsComponentsDatePickerExamplesFr examples = _TranslationsDocsComponentsDatePickerExamplesFr._(_root);
	@override String get select_date => 'Sélectionner une date';
	@override String get select_date_range => 'Sélectionner une plage de dates';
}

// Path: docs.components.dialog
class _TranslationsDocsComponentsDialogFr extends TranslationsDocsComponentsDialogKo {
	_TranslationsDocsComponentsDialogFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Dialogue';
	@override String get description => 'Un dialogue est une fenêtre modale qui s\'affiche au-dessus du reste de l\'application.';
	@override late final _TranslationsDocsComponentsDialogExamplesFr examples = _TranslationsDocsComponentsDialogExamplesFr._(_root);
	@override String get edit_profile_title => 'Modifier le profil';
	@override String get edit_profile_description => 'Modifiez votre profil ici. Cliquez sur enregistrer lorsque vous avez terminé.';
	@override String get name_label => 'Nom';
	@override String get username_label => 'Nom d\'utilisateur';
	@override String get hello => 'Bonjour';
	@override String get material_dialog_content => 'Ceci est un dialogue Material.';
	@override String get cupertino_dialog_content => 'Ceci est un dialogue Cupertino.';
	@override String get alert_title => 'Titre de l\'alerte';
	@override String get click_here => 'Cliquez ici';
	@override String get ok => 'D\'accord';
	@override String get open_material_dialog => 'Ouvrir le dialogue Material';
	@override String get open_cupertino_dialog => 'Ouvrir le dialogue Cupertino';
	@override String get open_coui_dialog => 'Ouvrir le dialogue COUI';
}

// Path: docs.components.divider
class _TranslationsDocsComponentsDividerFr extends TranslationsDocsComponentsDividerKo {
	_TranslationsDocsComponentsDividerFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Séparateur';
	@override String get description => 'Une ligne qui sépare visuellement le contenu.';
	@override late final _TranslationsDocsComponentsDividerExamplesFr examples = _TranslationsDocsComponentsDividerExamplesFr._(_root);
	@override String get item_1 => 'Élément 1';
	@override String get item_2 => 'Élément 2';
	@override String get item_3 => 'Élément 3';
	@override String get divider => 'Séparateur';
}

// Path: docs.components.dot_indicator
class _TranslationsDocsComponentsDotIndicatorFr extends TranslationsDocsComponentsDotIndicatorKo {
	_TranslationsDocsComponentsDotIndicatorFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Indicateur de points';
	@override String get description => 'Un indicateur qui montre la position actuelle avec un point.';
	@override late final _TranslationsDocsComponentsDotIndicatorExamplesFr examples = _TranslationsDocsComponentsDotIndicatorExamplesFr._(_root);
}

// Path: docs.components.drawer
class _TranslationsDocsComponentsDrawerFr extends TranslationsDocsComponentsDrawerKo {
	_TranslationsDocsComponentsDrawerFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tiroir';
	@override String get description => 'Un panneau qui glisse depuis le bord de l\'écran.';
	@override late final _TranslationsDocsComponentsDrawerExamplesFr examples = _TranslationsDocsComponentsDrawerExamplesFr._(_root);
	@override String get open_drawer => 'Ouvrir le tiroir';
	@override String get close_drawer => 'Fermer le tiroir';
	@override String get open_another_drawer => 'Ouvrir un autre tiroir';
	@override String drawer_at({required Object count, required Object position}) => 'Tiroir ${count} à ${position}';
}

// Path: docs.components.dropdown_menu
class _TranslationsDocsComponentsDropdownMenuFr extends TranslationsDocsComponentsDropdownMenuKo {
	_TranslationsDocsComponentsDropdownMenuFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Menu déroulant';
	@override String get description => 'Un menu qui affiche une liste d\'options sélectionnables.';
	@override late final _TranslationsDocsComponentsDropdownMenuExamplesFr examples = _TranslationsDocsComponentsDropdownMenuExamplesFr._(_root);
}

// Path: docs.components.expandable_sidebar
class _TranslationsDocsComponentsExpandableSidebarFr extends TranslationsDocsComponentsExpandableSidebarKo {
	_TranslationsDocsComponentsExpandableSidebarFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barre latérale extensible';
	@override String get description => 'Une barre latérale qui peut être étendue et rétrécie.';
	@override late final _TranslationsDocsComponentsExpandableSidebarExamplesFr examples = _TranslationsDocsComponentsExpandableSidebarExamplesFr._(_root);
}

// Path: docs.components.form
class _TranslationsDocsComponentsFormFr extends TranslationsDocsComponentsFormKo {
	_TranslationsDocsComponentsFormFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => ' formulaire';
	@override String get description => 'Un widget d\'assistance qui facilite la validation des formulaires.';
	@override late final _TranslationsDocsComponentsFormExamplesFr examples = _TranslationsDocsComponentsFormExamplesFr._(_root);
	@override String get username_label => 'Nom d\'utilisateur';
	@override String get username_hint => 'Ceci est le nom qui sera affiché publiquement';
	@override String get password_label => 'Mot de passe';
	@override String get confirm_password_label => 'Confirmer le mot de passe';
	@override String get passwords_do_not_match => 'Les mots de passe ne correspondent pas';
	@override String get agree_terms => 'J\'accepte les conditions d\'utilisation';
	@override String get must_agree_terms => 'Vous devez accepter les conditions d\'utilisation';
	@override String get form_values_title => 'Valeurs du formulaire';
	@override String get register => 'S\'inscrire';
	@override String get username_already_taken => 'Le nom d\'utilisateur est déjà pris';
	@override String get email => 'Email';
	@override String username_display({required Object value}) => 'Nom d\'utilisateur : ${value}';
	@override String password_display({required Object value}) => 'Mot de passe : ${value}';
	@override String confirm_password_display({required Object value}) => 'Confirmer le mot de passe : ${value}';
	@override String agree_display({required Object value}) => 'Accepter : ${value}';
	@override String json_display({required Object value}) => 'JSON : ${value}';
	@override String submitted_value_display({required Object value}) => 'Valeur soumise : ${value}';
	@override String get login => 'Connexion';
	@override String get sign_up => 'S\'inscrire';
	@override String get dont_have_account => 'Vous n\'avez pas de compte ?';
	@override String get already_have_account => 'Vous avez déjà un compte ?';
}

// Path: docs.components.formatted_input
class _TranslationsDocsComponentsFormattedInputFr extends TranslationsDocsComponentsFormattedInputKo {
	_TranslationsDocsComponentsFormattedInputFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrée formatée';
	@override String get description => 'Un champ de texte qui est saisi dans un format spécifique.';
	@override late final _TranslationsDocsComponentsFormattedInputExamplesFr examples = _TranslationsDocsComponentsFormattedInputExamplesFr._(_root);
}

// Path: docs.components.hover_card
class _TranslationsDocsComponentsHoverCardFr extends TranslationsDocsComponentsHoverCardKo {
	_TranslationsDocsComponentsHoverCardFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Carte au survol';
	@override String get description => 'Une carte affichée au survol.';
	@override late final _TranslationsDocsComponentsHoverCardExamplesFr examples = _TranslationsDocsComponentsHoverCardExamplesFr._(_root);
	@override String get flutter_handle => '@flutter';
	@override String get flutter_username => 'Flutter';
	@override String get flutter_description => 'Le SDK Flutter est un outil permettant de créer des applications mobiles, Web et de bureau à partir d\'une seule base de code.';
}

// Path: docs.components.input
class _TranslationsDocsComponentsInputFr extends TranslationsDocsComponentsInputKo {
	_TranslationsDocsComponentsInputFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrée';
	@override String get description => 'Champ de saisie de texte.';
	@override late final _TranslationsDocsComponentsInputExamplesFr examples = _TranslationsDocsComponentsInputExamplesFr._(_root);
	@override String get enter_name => 'Entrez votre nom';
	@override String get enter_username => 'Entrez votre nom d\'utilisateur';
	@override String get username_already_taken => 'Le nom d\'utilisateur est déjà pris';
	@override String get hello_world => 'Bonjour le monde !';
	@override String get search_something => 'Rechercher quelque chose...';
	@override String get email => 'Email';
	@override String get password => 'Entrez votre mot de passe';
	@override String get username_hint => 'Ceci est pour votre nom d\'utilisateur';
}

// Path: docs.components.input_otp
class _TranslationsDocsComponentsInputOtpFr extends TranslationsDocsComponentsInputOtpKo {
	_TranslationsDocsComponentsInputOtpFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrée OTP';
	@override String get description => 'Champ d\'entrée pour entrer un mot de passe à usage unique.';
	@override late final _TranslationsDocsComponentsInputOtpExamplesFr examples = _TranslationsDocsComponentsInputOtpExamplesFr._(_root);
}

// Path: docs.components.item_picker
class _TranslationsDocsComponentsItemPickerFr extends TranslationsDocsComponentsItemPickerKo {
	_TranslationsDocsComponentsItemPickerFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Sélecteur d\'éléments';
	@override String get description => 'Un composant pour sélectionner des éléments dans une liste.';
	@override late final _TranslationsDocsComponentsItemPickerExamplesFr examples = _TranslationsDocsComponentsItemPickerExamplesFr._(_root);
}

// Path: docs.components.keyboard_display
class _TranslationsDocsComponentsKeyboardDisplayFr extends TranslationsDocsComponentsKeyboardDisplayKo {
	_TranslationsDocsComponentsKeyboardDisplayFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Affichage du clavier';
	@override String get description => 'Un composant pour afficher les raccourcis clavier.';
	@override late final _TranslationsDocsComponentsKeyboardDisplayExamplesFr examples = _TranslationsDocsComponentsKeyboardDisplayExamplesFr._(_root);
}

// Path: docs.components.linear_progress
class _TranslationsDocsComponentsLinearProgressFr extends TranslationsDocsComponentsLinearProgressKo {
	_TranslationsDocsComponentsLinearProgressFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Progression linéaire';
	@override String get description => 'Un indicateur de progression linéaire.';
	@override late final _TranslationsDocsComponentsLinearProgressExamplesFr examples = _TranslationsDocsComponentsLinearProgressExamplesFr._(_root);
	@override String get increase => 'Augmenter';
	@override String get decrease => 'Diminuer';
}

// Path: docs.components.material
class _TranslationsDocsComponentsMaterialFr extends TranslationsDocsComponentsMaterialKo {
	_TranslationsDocsComponentsMaterialFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Material/Cupertino';
	@override String get description => 'Comment utiliser les widgets Material et Cupertino basiques de Flutter.';
	@override late final _TranslationsDocsComponentsMaterialExamplesFr examples = _TranslationsDocsComponentsMaterialExamplesFr._(_root);
	@override String get my_material_app => 'Mon application Material';
	@override String get my_cupertino_app => 'Mon application Cupertino';
	@override String you_pushed_button({required Object count}) => 'Vous avez appuyé sur le bouton ${count} fois';
	@override String get open_material_dialog => 'Ouvrir le dialogue Material';
	@override String get open_cupertino_dialog => 'Ouvrir le dialogue Cupertino';
	@override String get open_coui_dialog => 'Ouvrir le dialogue COUI';
}

// Path: docs.components.menubar
class _TranslationsDocsComponentsMenubarFr extends TranslationsDocsComponentsMenubarKo {
	_TranslationsDocsComponentsMenubarFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barre de menu';
	@override String get description => 'Une barre de menu horizontale.';
	@override late final _TranslationsDocsComponentsMenubarExamplesFr examples = _TranslationsDocsComponentsMenubarExamplesFr._(_root);
	@override String get file => 'Fichier';
	@override String get edit => 'Éditer';
	@override String get new_tab => 'Nouvel onglet';
	@override String get new_window => 'Nouvelle fenêtre';
	@override String get new_incognito_window => 'Nouvelle fenêtre en mode incognito';
	@override String get email_link => 'Lien d\'email';
	@override String get messages => 'Messages';
	@override String get notes => 'Notes';
	@override String get share => 'Partager';
	@override String get print => 'Imprimer';
	@override String get save_and_exit => 'Enregistrer et quitter';
	@override String get discard_and_exit => 'Annuler et quitter';
	@override String get exit => 'Quitter';
	@override String get undo => 'Annuler';
	@override String get redo => 'Rétablir';
}

// Path: docs.components.multiselect
class _TranslationsDocsComponentsMultiselectFr extends TranslationsDocsComponentsMultiselectKo {
	_TranslationsDocsComponentsMultiselectFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Multi-sélection';
	@override String get description => 'Un composant permettant de sélectionner plusieurs éléments.';
	@override late final _TranslationsDocsComponentsMultiselectExamplesFr examples = _TranslationsDocsComponentsMultiselectExamplesFr._(_root);
}

// Path: docs.components.navigation_bar
class _TranslationsDocsComponentsNavigationBarFr extends TranslationsDocsComponentsNavigationBarKo {
	_TranslationsDocsComponentsNavigationBarFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barre de navigation';
	@override String get description => 'Barre de navigation inférieure.';
	@override late final _TranslationsDocsComponentsNavigationBarExamplesFr examples = _TranslationsDocsComponentsNavigationBarExamplesFr._(_root);
}

// Path: docs.components.navigation_menu
class _TranslationsDocsComponentsNavigationMenuFr extends TranslationsDocsComponentsNavigationMenuKo {
	_TranslationsDocsComponentsNavigationMenuFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Menu de navigation';
	@override String get description => 'Composant de menu de navigation.';
	@override late final _TranslationsDocsComponentsNavigationMenuExamplesFr examples = _TranslationsDocsComponentsNavigationMenuExamplesFr._(_root);
}

// Path: docs.components.navigation_rail
class _TranslationsDocsComponentsNavigationRailFr extends TranslationsDocsComponentsNavigationRailKo {
	_TranslationsDocsComponentsNavigationRailFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Rail de navigation';
	@override String get description => 'Rail de navigation latéral.';
	@override late final _TranslationsDocsComponentsNavigationRailExamplesFr examples = _TranslationsDocsComponentsNavigationRailExamplesFr._(_root);
}

// Path: docs.components.navigation_sidebar
class _TranslationsDocsComponentsNavigationSidebarFr extends TranslationsDocsComponentsNavigationSidebarKo {
	_TranslationsDocsComponentsNavigationSidebarFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barre latérale de navigation';
	@override String get description => 'Composant de barre latérale de navigation.';
	@override late final _TranslationsDocsComponentsNavigationSidebarExamplesFr examples = _TranslationsDocsComponentsNavigationSidebarExamplesFr._(_root);
}

// Path: docs.components.number_input
class _TranslationsDocsComponentsNumberInputFr extends TranslationsDocsComponentsNumberInputKo {
	_TranslationsDocsComponentsNumberInputFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Saisie numérique';
	@override String get description => 'Champ pour entrer des chiffres.';
	@override late final _TranslationsDocsComponentsNumberInputExamplesFr examples = _TranslationsDocsComponentsNumberInputExamplesFr._(_root);
	@override String value({required Object value}) => 'Valeur : ${value}';
}

// Path: docs.components.number_ticker
class _TranslationsDocsComponentsNumberTickerFr extends TranslationsDocsComponentsNumberTickerKo {
	_TranslationsDocsComponentsNumberTickerFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Ticker numérique';
	@override String get description => 'Affiche une animation lorsque le nombre change.';
	@override late final _TranslationsDocsComponentsNumberTickerExamplesFr examples = _TranslationsDocsComponentsNumberTickerExamplesFr._(_root);
}

// Path: docs.components.overflow_marquee
class _TranslationsDocsComponentsOverflowMarqueeFr extends TranslationsDocsComponentsOverflowMarqueeKo {
	_TranslationsDocsComponentsOverflowMarqueeFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Marquee de débordement';
	@override String get description => 'Fait défiler automatiquement le texte lorsqu\'il déborde.';
	@override late final _TranslationsDocsComponentsOverflowMarqueeExamplesFr examples = _TranslationsDocsComponentsOverflowMarqueeExamplesFr._(_root);
}

// Path: docs.components.pagination
class _TranslationsDocsComponentsPaginationFr extends TranslationsDocsComponentsPaginationKo {
	_TranslationsDocsComponentsPaginationFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Pagination';
	@override String get description => 'Composant pour naviguer entre les pages.';
	@override late final _TranslationsDocsComponentsPaginationExamplesFr examples = _TranslationsDocsComponentsPaginationExamplesFr._(_root);
}

// Path: docs.components.phone_input
class _TranslationsDocsComponentsPhoneInputFr extends TranslationsDocsComponentsPhoneInputKo {
	_TranslationsDocsComponentsPhoneInputFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Saisie de numéro de téléphone';
	@override String get description => 'Champ pour entrer un numéro de téléphone.';
	@override late final _TranslationsDocsComponentsPhoneInputExamplesFr examples = _TranslationsDocsComponentsPhoneInputExamplesFr._(_root);
}

// Path: docs.components.popover
class _TranslationsDocsComponentsPopoverFr extends TranslationsDocsComponentsPopoverKo {
	_TranslationsDocsComponentsPopoverFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Popover';
	@override String get description => 'Une pop-up affichée au-dessus d\'un élément.';
	@override late final _TranslationsDocsComponentsPopoverExamplesFr examples = _TranslationsDocsComponentsPopoverExamplesFr._(_root);
	@override String get dimensions => 'Dimensions';
	@override String get set_dimensions => 'Définir la taille du calque';
	@override String get width => 'Largeur';
	@override String get max_width => 'Largeur maximale';
	@override String get height => 'Hauteur';
	@override String get max_height => 'Hauteur maximale';
	@override String get open_popover => 'Ouvrir le popover';
	@override String get submit => 'Soumettre';
}

// Path: docs.components.progress
class _TranslationsDocsComponentsProgressFr extends TranslationsDocsComponentsProgressKo {
	_TranslationsDocsComponentsProgressFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Progression';
	@override String get description => 'Montre l\'état de progression.';
	@override late final _TranslationsDocsComponentsProgressExamplesFr examples = _TranslationsDocsComponentsProgressExamplesFr._(_root);
}

// Path: docs.components.radio_card
class _TranslationsDocsComponentsRadioCardFr extends TranslationsDocsComponentsRadioCardKo {
	_TranslationsDocsComponentsRadioCardFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Carte radio';
	@override String get description => 'Un bouton radio sous forme de carte.';
	@override late final _TranslationsDocsComponentsRadioCardExamplesFr examples = _TranslationsDocsComponentsRadioCardExamplesFr._(_root);
}

// Path: docs.components.radio_group
class _TranslationsDocsComponentsRadioGroupFr extends TranslationsDocsComponentsRadioGroupKo {
	_TranslationsDocsComponentsRadioGroupFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Groupe de radio';
	@override String get description => 'Groupe de boutons radio.';
	@override late final _TranslationsDocsComponentsRadioGroupExamplesFr examples = _TranslationsDocsComponentsRadioGroupExamplesFr._(_root);
	@override String get option_1 => 'Option 1';
	@override String get option_2 => 'Option 2';
	@override String get option_3 => 'Option 3';
	@override String get selected => 'Sélectionné';
}

// Path: docs.components.refresh_trigger
class _TranslationsDocsComponentsRefreshTriggerFr extends TranslationsDocsComponentsRefreshTriggerKo {
	_TranslationsDocsComponentsRefreshTriggerFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Déclencheur de rafraîchissement';
	@override String get description => 'Permet de rafraîchir en tirant.';
	@override late final _TranslationsDocsComponentsRefreshTriggerExamplesFr examples = _TranslationsDocsComponentsRefreshTriggerExamplesFr._(_root);
	@override String get pull_me => 'Tirez-moi';
	@override String get refresh => 'Rafraîchir';
}

// Path: docs.components.repeated_animation_builder
class _TranslationsDocsComponentsRepeatedAnimationBuilderFr extends TranslationsDocsComponentsRepeatedAnimationBuilderKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Constructeur d\'animation répétée';
	@override String get description => 'Un constructeur qui répète les animations.';
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesFr examples = _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesFr._(_root);
}

// Path: docs.components.resizable
class _TranslationsDocsComponentsResizableFr extends TranslationsDocsComponentsResizableKo {
	_TranslationsDocsComponentsResizableFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Redimensionnable';
	@override String get description => 'Un conteneur qui peut être redimensionné.';
	@override late final _TranslationsDocsComponentsResizableExamplesFr examples = _TranslationsDocsComponentsResizableExamplesFr._(_root);
}

// Path: docs.components.scaffold
class _TranslationsDocsComponentsScaffoldFr extends TranslationsDocsComponentsScaffoldKo {
	_TranslationsDocsComponentsScaffoldFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Échafaudage';
	@override String get description => 'L\'échafaudage est le conteneur de niveau supérieur d\'une page.';
	@override late final _TranslationsDocsComponentsScaffoldExamplesFr examples = _TranslationsDocsComponentsScaffoldExamplesFr._(_root);
}

// Path: docs.components.select
class _TranslationsDocsComponentsSelectFr extends TranslationsDocsComponentsSelectKo {
	_TranslationsDocsComponentsSelectFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Sélectionner';
	@override String get description => 'Permet de sélectionner un élément dans une liste d\'options.';
	@override late final _TranslationsDocsComponentsSelectExamplesFr examples = _TranslationsDocsComponentsSelectExamplesFr._(_root);
	@override String get placeholder => 'Sélectionnez un fruit';
	@override String get search_fruit => 'Recherchez un fruit';
	@override String get no_fruit_found => 'Aucun fruit trouvé';
	@override String get apple => 'Pomme';
	@override String get banana => 'Banane';
	@override String get cherry => 'Cerise';
	@override String get lemon => 'Citron';
	@override String get tomato => 'Tomate';
	@override String get red_apple => 'Pomme rouge';
	@override String get green_apple => 'Pomme verte';
	@override String get yellow_banana => 'Banane jaune';
	@override String get brown_banana => 'Banane brune';
	@override String get yellow_lemon => 'Citron jaune';
	@override String get green_lemon => 'Citron vert';
	@override String get red => 'Rouge';
	@override String get green => 'Vert';
	@override String get yellow => 'Jaune';
	@override String get brown => 'Brun';
}

// Path: docs.components.sheet
class _TranslationsDocsComponentsSheetFr extends TranslationsDocsComponentsSheetKo {
	_TranslationsDocsComponentsSheetFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Feuille';
	@override String get description => 'Une feuille qui glisse depuis le bas.';
	@override late final _TranslationsDocsComponentsSheetExamplesFr examples = _TranslationsDocsComponentsSheetExamplesFr._(_root);
}

// Path: docs.components.skeleton
class _TranslationsDocsComponentsSkeletonFr extends TranslationsDocsComponentsSkeletonKo {
	_TranslationsDocsComponentsSkeletonFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Squelette';
	@override String get description => 'Un écran de squelette affiché pendant le chargement.';
	@override late final _TranslationsDocsComponentsSkeletonExamplesFr examples = _TranslationsDocsComponentsSkeletonExamplesFr._(_root);
}

// Path: docs.components.slider
class _TranslationsDocsComponentsSliderFr extends TranslationsDocsComponentsSliderKo {
	_TranslationsDocsComponentsSliderFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Curseur';
	@override String get description => 'Permet de sélectionner une valeur en la glissant.';
	@override late final _TranslationsDocsComponentsSliderExamplesFr examples = _TranslationsDocsComponentsSliderExamplesFr._(_root);
	@override String value_single({required Object value}) => 'Valeur : ${value}';
	@override String value_range({required Object start, required Object end}) => 'Valeur : ${start} - ${end}';
}

// Path: docs.components.sortable
class _TranslationsDocsComponentsSortableFr extends TranslationsDocsComponentsSortableKo {
	_TranslationsDocsComponentsSortableFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Triable';
	@override String get description => 'Permet de trier les éléments par glisser-déposer.';
	@override late final _TranslationsDocsComponentsSortableExamplesFr examples = _TranslationsDocsComponentsSortableExamplesFr._(_root);
}

// Path: docs.components.star_rating
class _TranslationsDocsComponentsStarRatingFr extends TranslationsDocsComponentsStarRatingKo {
	_TranslationsDocsComponentsStarRatingFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Évaluation par étoiles';
	@override String get description => 'Permet de noter avec des étoiles.';
	@override late final _TranslationsDocsComponentsStarRatingExamplesFr examples = _TranslationsDocsComponentsStarRatingExamplesFr._(_root);
}

// Path: docs.components.stepper
class _TranslationsDocsComponentsStepperFr extends TranslationsDocsComponentsStepperKo {
	_TranslationsDocsComponentsStepperFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Stepper';
	@override String get description => 'Affiche un processus en étapes.';
	@override late final _TranslationsDocsComponentsStepperExamplesFr examples = _TranslationsDocsComponentsStepperExamplesFr._(_root);
	@override String get step_1 => 'Étape 1';
	@override String get step_2 => 'Étape 2';
	@override String get step_3 => 'Étape 3';
	@override String step_n({required Object n}) => 'Étape ${n}';
	@override String get optional_step => 'Étape facultative';
	@override String get horizontal => 'Horizontal';
	@override String get vertical => 'Vertical';
	@override String get toggle_error => 'Basculer l\'erreur';
	@override String get circle => 'Cercle';
	@override String get circle_alt => 'Cercle alternatif';
	@override String get line => 'Ligne';
	@override String get small => 'Petit';
	@override String get medium => 'Moyen';
	@override String get large => 'Grand';
}

// Path: docs.components.steps
class _TranslationsDocsComponentsStepsFr extends TranslationsDocsComponentsStepsKo {
	_TranslationsDocsComponentsStepsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Étapes';
	@override String get description => 'Affiche la progression par étapes.';
	@override late final _TranslationsDocsComponentsStepsExamplesFr examples = _TranslationsDocsComponentsStepsExamplesFr._(_root);
}

// Path: docs.components.swiper
class _TranslationsDocsComponentsSwiperFr extends TranslationsDocsComponentsSwiperKo {
	_TranslationsDocsComponentsSwiperFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Swiper';
	@override String get description => 'Un composant qui permet de faire glisser.';
	@override late final _TranslationsDocsComponentsSwiperExamplesFr examples = _TranslationsDocsComponentsSwiperExamplesFr._(_root);
}

// Path: docs.components.k_switch
class _TranslationsDocsComponentsKSwitchFr extends TranslationsDocsComponentsKSwitchKo {
	_TranslationsDocsComponentsKSwitchFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Interrupteur';
	@override String get description => 'Interrupteur marche/arrêt.';
	@override late final _TranslationsDocsComponentsKSwitchExamplesFr examples = _TranslationsDocsComponentsKSwitchExamplesFr._(_root);
}

// Path: docs.components.switcher
class _TranslationsDocsComponentsSwitcherFr extends TranslationsDocsComponentsSwitcherKo {
	_TranslationsDocsComponentsSwitcherFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Commutateur';
	@override String get description => 'Permet de passer entre plusieurs vues.';
	@override late final _TranslationsDocsComponentsSwitcherExamplesFr examples = _TranslationsDocsComponentsSwitcherExamplesFr._(_root);
	@override String get switch_direction => 'Changer de direction';
	@override String get next_item => 'Prochain élément';
}

// Path: docs.components.tab_list
class _TranslationsDocsComponentsTabListFr extends TranslationsDocsComponentsTabListKo {
	_TranslationsDocsComponentsTabListFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Liste d\'onglets';
	@override String get description => 'Composant de liste d\'onglets.';
	@override late final _TranslationsDocsComponentsTabListExamplesFr examples = _TranslationsDocsComponentsTabListExamplesFr._(_root);
}

// Path: docs.components.tab_pane
class _TranslationsDocsComponentsTabPaneFr extends TranslationsDocsComponentsTabPaneKo {
	_TranslationsDocsComponentsTabPaneFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Panneau d\'onglets';
	@override String get description => 'Composant de panneau d\'onglets.';
	@override late final _TranslationsDocsComponentsTabPaneExamplesFr examples = _TranslationsDocsComponentsTabPaneExamplesFr._(_root);
}

// Path: docs.components.table
class _TranslationsDocsComponentsTableFr extends TranslationsDocsComponentsTableKo {
	_TranslationsDocsComponentsTableFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tableau';
	@override String get description => 'Affiche des données sous forme de tableau.';
	@override late final _TranslationsDocsComponentsTableExamplesFr examples = _TranslationsDocsComponentsTableExamplesFr._(_root);
	@override String get invoice => 'Facture';
	@override String get status => 'Statut';
	@override String get method => 'Méthode';
	@override String get amount => 'Montant';
	@override String get total => 'Total';
	@override String get paid => 'Payé';
	@override String get pending => 'En attente';
	@override String get unpaid => 'Non payé';
	@override String get credit_card => 'Carte de crédit';
	@override String get paypal => 'PayPal';
	@override String get bank_transfer => 'Virement bancaire';
}

// Path: docs.components.tabs
class _TranslationsDocsComponentsTabsFr extends TranslationsDocsComponentsTabsKo {
	_TranslationsDocsComponentsTabsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Onglets';
	@override String get description => 'Utilisez des onglets pour organiser le contenu.';
	@override late final _TranslationsDocsComponentsTabsExamplesFr examples = _TranslationsDocsComponentsTabsExamplesFr._(_root);
	@override String get tab_1 => 'Onglet 1';
	@override String get tab_2 => 'Onglet 2';
	@override String get tab_3 => 'Onglet 3';
	@override String tab_n({required Object n}) => 'Onglet ${n}';
}

// Path: docs.components.text_area
class _TranslationsDocsComponentsTextAreaFr extends TranslationsDocsComponentsTextAreaKo {
	_TranslationsDocsComponentsTextAreaFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Zone de texte';
	@override String get description => 'Permet d\'entrer plusieurs lignes de texte.';
	@override late final _TranslationsDocsComponentsTextAreaExamplesFr examples = _TranslationsDocsComponentsTextAreaExamplesFr._(_root);
	@override String get hello_world => 'Bonjour, le monde!';
}

// Path: docs.components.time_picker
class _TranslationsDocsComponentsTimePickerFr extends TranslationsDocsComponentsTimePickerKo {
	_TranslationsDocsComponentsTimePickerFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Sélecteur de temps';
	@override String get description => 'Permet de sélectionner un temps.';
	@override late final _TranslationsDocsComponentsTimePickerExamplesFr examples = _TranslationsDocsComponentsTimePickerExamplesFr._(_root);
	@override String get select_time => 'Sélectionner le temps';
}

// Path: docs.components.timeline
class _TranslationsDocsComponentsTimelineFr extends TranslationsDocsComponentsTimelineKo {
	_TranslationsDocsComponentsTimelineFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Chronologie';
	@override String get description => 'Affiche des événements sur une chronologie.';
	@override late final _TranslationsDocsComponentsTimelineExamplesFr examples = _TranslationsDocsComponentsTimelineExamplesFr._(_root);
}

// Path: docs.components.timeline_animation
class _TranslationsDocsComponentsTimelineAnimationFr extends TranslationsDocsComponentsTimelineAnimationKo {
	_TranslationsDocsComponentsTimelineAnimationFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Animation de chronologie';
	@override String get description => 'Animation basée sur la chronologie.';
	@override late final _TranslationsDocsComponentsTimelineAnimationExamplesFr examples = _TranslationsDocsComponentsTimelineAnimationExamplesFr._(_root);
}

// Path: docs.components.toast
class _TranslationsDocsComponentsToastFr extends TranslationsDocsComponentsToastKo {
	_TranslationsDocsComponentsToastFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Toast';
	@override String get description => 'Une notification qui affiche un message court.';
	@override late final _TranslationsDocsComponentsToastExamplesFr examples = _TranslationsDocsComponentsToastExamplesFr._(_root);
	@override String get event_created => 'L\'événement a été créé';
	@override String get event_date => 'Dimanche, 7 juillet 2024 à 12h00';
	@override String get show_bottom_left => 'Afficher le toast en bas à gauche';
	@override String get show_bottom_right => 'Afficher le toast en bas à droite';
	@override String get show_top_left => 'Afficher le toast en haut à gauche';
	@override String get show_top_right => 'Afficher le toast en haut à droite';
	@override String get show_bottom_center => 'Afficher le toast en bas au centre';
	@override String get show_top_center => 'Afficher le toast en haut au centre';
}

// Path: docs.components.toggle
class _TranslationsDocsComponentsToggleFr extends TranslationsDocsComponentsToggleKo {
	_TranslationsDocsComponentsToggleFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Basculer';
	@override String get description => 'Permet de basculer entre les options.';
	@override late final _TranslationsDocsComponentsToggleExamplesFr examples = _TranslationsDocsComponentsToggleExamplesFr._(_root);
	@override String get toggle => 'Basculer';
}

// Path: docs.components.tooltip
class _TranslationsDocsComponentsTooltipFr extends TranslationsDocsComponentsTooltipKo {
	_TranslationsDocsComponentsTooltipFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Info-bulle';
	@override String get description => 'Affiche des informations supplémentaires sur un élément.';
	@override late final _TranslationsDocsComponentsTooltipExamplesFr examples = _TranslationsDocsComponentsTooltipExamplesFr._(_root);
	@override String get this_is_tooltip => 'Ceci est une info-bulle.';
	@override String get hover_over_me => 'Survolez-moi';
}

// Path: docs.components.tracker
class _TranslationsDocsComponentsTrackerFr extends TranslationsDocsComponentsTrackerKo {
	_TranslationsDocsComponentsTrackerFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Suivi';
	@override String get description => 'Suis la progression.';
	@override late final _TranslationsDocsComponentsTrackerExamplesFr examples = _TranslationsDocsComponentsTrackerExamplesFr._(_root);
	@override String get fine => 'Bon';
	@override String get warning => 'Avertissement';
	@override String get critical => 'Critique';
	@override String get unknown => 'Inconnu';
	@override String get tracker_fine => 'Suivi bon';
	@override String get tracker_warning => 'Suivi avertissement';
	@override String get tracker_critical => 'Suivi critique';
	@override String get tracker_unknown => 'Suivi inconnu';
}

// Path: docs.components.tree
class _TranslationsDocsComponentsTreeFr extends TranslationsDocsComponentsTreeKo {
	_TranslationsDocsComponentsTreeFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Arbre';
	@override String get description => 'Affiche des données hiérarchiques sous forme d\'arbre.';
	@override late final _TranslationsDocsComponentsTreeExamplesFr examples = _TranslationsDocsComponentsTreeExamplesFr._(_root);
}

// Path: docs.components.window
class _TranslationsDocsComponentsWindowFr extends TranslationsDocsComponentsWindowKo {
	_TranslationsDocsComponentsWindowFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Fenêtre';
	@override String get description => 'Une fenêtre de style bureau.';
	@override late final _TranslationsDocsComponentsWindowExamplesFr examples = _TranslationsDocsComponentsWindowExamplesFr._(_root);
	@override String get window_1 => 'Fenêtre 1';
	@override String get window_2 => 'Fenêtre 2';
	@override String get desktop => 'Bureau';
	@override String get add_window => 'Ajouter une fenêtre';
}

// Path: docs.pages.introduction.features_list
class _TranslationsDocsPagesIntroductionFeaturesListFr extends TranslationsDocsPagesIntroductionFeaturesListKo {
	_TranslationsDocsPagesIntroductionFeaturesListFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get components_count => '84 composants et en constante augmentation !';
	@override String get material_cupertino => 'Prise en charge des widgets Material et Cupertino, avec des thèmes actuellement adaptés au thème coui_flutter.';
	@override String get premade_themes => 'Thèmes préconçus de Coui/UI.';
	@override String get platform_support => 'Prise en charge des plateformes mobiles, web et de bureau.';
	@override String get middle_drag => 'Prise en charge du défilement à mi-chemin.';
	@override String get typography_extensions => 'Diverses extensions de widgets pour la typographie.';
	@override String get webassembly => 'Prise en charge de WebAssembly pour de meilleures performances.';
}

// Path: docs.components.accordion.examples
class _TranslationsDocsComponentsAccordionExamplesFr extends TranslationsDocsComponentsAccordionExamplesKo {
	_TranslationsDocsComponentsAccordionExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'accordéon';
}

// Path: docs.components.alert.examples
class _TranslationsDocsComponentsAlertExamplesFr extends TranslationsDocsComponentsAlertExamplesKo {
	_TranslationsDocsComponentsAlertExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'alerte';
	@override String get destructive => 'Exemple d\'alerte destructrice';
}

// Path: docs.components.alert_dialog.examples
class _TranslationsDocsComponentsAlertDialogExamplesFr extends TranslationsDocsComponentsAlertDialogExamplesKo {
	_TranslationsDocsComponentsAlertDialogExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de dialogue d\'alerte';
}

// Path: docs.components.animated_value_builder.examples
class _TranslationsDocsComponentsAnimatedValueBuilderExamplesFr extends TranslationsDocsComponentsAnimatedValueBuilderExamplesKo {
	_TranslationsDocsComponentsAnimatedValueBuilderExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de constructeur de valeur animée';
}

// Path: docs.components.app_bar.examples
class _TranslationsDocsComponentsAppBarExamplesFr extends TranslationsDocsComponentsAppBarExamplesKo {
	_TranslationsDocsComponentsAppBarExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de barre d\'application';
}

// Path: docs.components.autocomplete.examples
class _TranslationsDocsComponentsAutocompleteExamplesFr extends TranslationsDocsComponentsAutocompleteExamplesKo {
	_TranslationsDocsComponentsAutocompleteExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'auto-complétion';
}

// Path: docs.components.avatar.examples
class _TranslationsDocsComponentsAvatarExamplesFr extends TranslationsDocsComponentsAvatarExamplesKo {
	_TranslationsDocsComponentsAvatarExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'avatar';
}

// Path: docs.components.avatar_group.examples
class _TranslationsDocsComponentsAvatarGroupExamplesFr extends TranslationsDocsComponentsAvatarGroupExamplesKo {
	_TranslationsDocsComponentsAvatarGroupExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de groupe d\'avatars';
}

// Path: docs.components.badge.examples
class _TranslationsDocsComponentsBadgeExamplesFr extends TranslationsDocsComponentsBadgeExamplesKo {
	_TranslationsDocsComponentsBadgeExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de badge';
}

// Path: docs.components.breadcrumb.examples
class _TranslationsDocsComponentsBreadcrumbExamplesFr extends TranslationsDocsComponentsBreadcrumbExamplesKo {
	_TranslationsDocsComponentsBreadcrumbExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de fil d\'Ariane';
}

// Path: docs.components.button.examples
class _TranslationsDocsComponentsButtonExamplesFr extends TranslationsDocsComponentsButtonExamplesKo {
	_TranslationsDocsComponentsButtonExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get primary => 'Exemple de bouton primaire';
	@override String get secondary => 'Exemple de bouton secondaire';
	@override String get outline => 'Exemple de bouton en contour';
	@override String get ghost => 'Exemple de bouton fantôme';
	@override String get destructive => 'Exemple de bouton destructeur';
	@override String get link => 'Exemple de bouton lien';
	@override String get text => 'Exemple de bouton texte';
	@override String get disabled => 'Exemple de bouton désactivé';
	@override String get icon => 'Exemple de bouton icône';
	@override String get icon_with_label => 'Exemple de bouton icône avec étiquette';
	@override String get size => 'Exemple de taille de bouton';
	@override String get density => 'Exemple de densité de bouton';
	@override String get shape => 'Exemple de forme de bouton';
	@override String get group => 'Exemple de groupe de boutons';
	@override String get stated => 'Exemple de bouton d\'état';
	@override String get card => 'Exemple de bouton de carte';
	@override String get custom => 'Exemple de bouton personnalisé';
}

// Path: docs.components.calendar.examples
class _TranslationsDocsComponentsCalendarExamplesFr extends TranslationsDocsComponentsCalendarExamplesKo {
	_TranslationsDocsComponentsCalendarExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de calendrier';
}

// Path: docs.components.card.examples
class _TranslationsDocsComponentsCardExamplesFr extends TranslationsDocsComponentsCardExamplesKo {
	_TranslationsDocsComponentsCardExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de carte';
}

// Path: docs.components.card_image.examples
class _TranslationsDocsComponentsCardImageExamplesFr extends TranslationsDocsComponentsCardImageExamplesKo {
	_TranslationsDocsComponentsCardImageExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de carte d\'image';
}

// Path: docs.components.carousel.examples
class _TranslationsDocsComponentsCarouselExamplesFr extends TranslationsDocsComponentsCarouselExamplesKo {
	_TranslationsDocsComponentsCarouselExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de carrousel';
}

// Path: docs.components.checkbox.examples
class _TranslationsDocsComponentsCheckboxExamplesFr extends TranslationsDocsComponentsCheckboxExamplesKo {
	_TranslationsDocsComponentsCheckboxExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de case à cocher';
}

// Path: docs.components.chip.examples
class _TranslationsDocsComponentsChipExamplesFr extends TranslationsDocsComponentsChipExamplesKo {
	_TranslationsDocsComponentsChipExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de puce';
}

// Path: docs.components.chip_input.examples
class _TranslationsDocsComponentsChipInputExamplesFr extends TranslationsDocsComponentsChipInputExamplesKo {
	_TranslationsDocsComponentsChipInputExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'entrée de puce';
}

// Path: docs.components.circular_progress.examples
class _TranslationsDocsComponentsCircularProgressExamplesFr extends TranslationsDocsComponentsCircularProgressExamplesKo {
	_TranslationsDocsComponentsCircularProgressExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de progression circulaire';
}

// Path: docs.components.code_snippet.examples
class _TranslationsDocsComponentsCodeSnippetExamplesFr extends TranslationsDocsComponentsCodeSnippetExamplesKo {
	_TranslationsDocsComponentsCodeSnippetExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'extrait de code';
}

// Path: docs.components.collapsible.examples
class _TranslationsDocsComponentsCollapsibleExamplesFr extends TranslationsDocsComponentsCollapsibleExamplesKo {
	_TranslationsDocsComponentsCollapsibleExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple collapsible';
}

// Path: docs.components.color_picker.examples
class _TranslationsDocsComponentsColorPickerExamplesFr extends TranslationsDocsComponentsColorPickerExamplesKo {
	_TranslationsDocsComponentsColorPickerExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de sélecteur de couleur';
}

// Path: docs.components.command.examples
class _TranslationsDocsComponentsCommandExamplesFr extends TranslationsDocsComponentsCommandExamplesKo {
	_TranslationsDocsComponentsCommandExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de commande';
}

// Path: docs.components.context_menu.examples
class _TranslationsDocsComponentsContextMenuExamplesFr extends TranslationsDocsComponentsContextMenuExamplesKo {
	_TranslationsDocsComponentsContextMenuExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de menu contextuel';
}

// Path: docs.components.date_picker.examples
class _TranslationsDocsComponentsDatePickerExamplesFr extends TranslationsDocsComponentsDatePickerExamplesKo {
	_TranslationsDocsComponentsDatePickerExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de sélecteur de date';
}

// Path: docs.components.dialog.examples
class _TranslationsDocsComponentsDialogExamplesFr extends TranslationsDocsComponentsDialogExamplesKo {
	_TranslationsDocsComponentsDialogExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de dialogue';
}

// Path: docs.components.divider.examples
class _TranslationsDocsComponentsDividerExamplesFr extends TranslationsDocsComponentsDividerExamplesKo {
	_TranslationsDocsComponentsDividerExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de séparateur';
}

// Path: docs.components.dot_indicator.examples
class _TranslationsDocsComponentsDotIndicatorExamplesFr extends TranslationsDocsComponentsDotIndicatorExamplesKo {
	_TranslationsDocsComponentsDotIndicatorExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'indicateur de points';
}

// Path: docs.components.drawer.examples
class _TranslationsDocsComponentsDrawerExamplesFr extends TranslationsDocsComponentsDrawerExamplesKo {
	_TranslationsDocsComponentsDrawerExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de tiroir';
}

// Path: docs.components.dropdown_menu.examples
class _TranslationsDocsComponentsDropdownMenuExamplesFr extends TranslationsDocsComponentsDropdownMenuExamplesKo {
	_TranslationsDocsComponentsDropdownMenuExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de menu déroulant';
}

// Path: docs.components.expandable_sidebar.examples
class _TranslationsDocsComponentsExpandableSidebarExamplesFr extends TranslationsDocsComponentsExpandableSidebarExamplesKo {
	_TranslationsDocsComponentsExpandableSidebarExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de barre latérale extensible';
}

// Path: docs.components.form.examples
class _TranslationsDocsComponentsFormExamplesFr extends TranslationsDocsComponentsFormExamplesKo {
	_TranslationsDocsComponentsFormExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get table_layout => 'Exemple de formulaire (mise en page en table)';
	@override String get column_layout => 'Exemple de formulaire (mise en page en colonnes)';
	@override String get validation_mode => 'Exemple de mode de validation';
}

// Path: docs.components.formatted_input.examples
class _TranslationsDocsComponentsFormattedInputExamplesFr extends TranslationsDocsComponentsFormattedInputExamplesKo {
	_TranslationsDocsComponentsFormattedInputExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'entrée formatée';
}

// Path: docs.components.hover_card.examples
class _TranslationsDocsComponentsHoverCardExamplesFr extends TranslationsDocsComponentsHoverCardExamplesKo {
	_TranslationsDocsComponentsHoverCardExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de carte au survol';
}

// Path: docs.components.input.examples
class _TranslationsDocsComponentsInputExamplesFr extends TranslationsDocsComponentsInputExamplesKo {
	_TranslationsDocsComponentsInputExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'entrée';
}

// Path: docs.components.input_otp.examples
class _TranslationsDocsComponentsInputOtpExamplesFr extends TranslationsDocsComponentsInputOtpExamplesKo {
	_TranslationsDocsComponentsInputOtpExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'entrée OTP';
}

// Path: docs.components.item_picker.examples
class _TranslationsDocsComponentsItemPickerExamplesFr extends TranslationsDocsComponentsItemPickerExamplesKo {
	_TranslationsDocsComponentsItemPickerExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de sélecteur d\'éléments';
}

// Path: docs.components.keyboard_display.examples
class _TranslationsDocsComponentsKeyboardDisplayExamplesFr extends TranslationsDocsComponentsKeyboardDisplayExamplesKo {
	_TranslationsDocsComponentsKeyboardDisplayExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'affichage du clavier';
}

// Path: docs.components.linear_progress.examples
class _TranslationsDocsComponentsLinearProgressExamplesFr extends TranslationsDocsComponentsLinearProgressExamplesKo {
	_TranslationsDocsComponentsLinearProgressExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de progression linéaire';
}

// Path: docs.components.material.examples
class _TranslationsDocsComponentsMaterialExamplesFr extends TranslationsDocsComponentsMaterialExamplesKo {
	_TranslationsDocsComponentsMaterialExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple Material/Cupertino';
}

// Path: docs.components.menubar.examples
class _TranslationsDocsComponentsMenubarExamplesFr extends TranslationsDocsComponentsMenubarExamplesKo {
	_TranslationsDocsComponentsMenubarExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de barre de menu';
}

// Path: docs.components.multiselect.examples
class _TranslationsDocsComponentsMultiselectExamplesFr extends TranslationsDocsComponentsMultiselectExamplesKo {
	_TranslationsDocsComponentsMultiselectExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de multi-sélection';
}

// Path: docs.components.navigation_bar.examples
class _TranslationsDocsComponentsNavigationBarExamplesFr extends TranslationsDocsComponentsNavigationBarExamplesKo {
	_TranslationsDocsComponentsNavigationBarExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de barre de navigation';
}

// Path: docs.components.navigation_menu.examples
class _TranslationsDocsComponentsNavigationMenuExamplesFr extends TranslationsDocsComponentsNavigationMenuExamplesKo {
	_TranslationsDocsComponentsNavigationMenuExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de menu de navigation';
}

// Path: docs.components.navigation_rail.examples
class _TranslationsDocsComponentsNavigationRailExamplesFr extends TranslationsDocsComponentsNavigationRailExamplesKo {
	_TranslationsDocsComponentsNavigationRailExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de rail de navigation';
}

// Path: docs.components.navigation_sidebar.examples
class _TranslationsDocsComponentsNavigationSidebarExamplesFr extends TranslationsDocsComponentsNavigationSidebarExamplesKo {
	_TranslationsDocsComponentsNavigationSidebarExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de barre latérale de navigation';
}

// Path: docs.components.number_input.examples
class _TranslationsDocsComponentsNumberInputExamplesFr extends TranslationsDocsComponentsNumberInputExamplesKo {
	_TranslationsDocsComponentsNumberInputExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de saisie numérique';
}

// Path: docs.components.number_ticker.examples
class _TranslationsDocsComponentsNumberTickerExamplesFr extends TranslationsDocsComponentsNumberTickerExamplesKo {
	_TranslationsDocsComponentsNumberTickerExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de ticker numérique';
}

// Path: docs.components.overflow_marquee.examples
class _TranslationsDocsComponentsOverflowMarqueeExamplesFr extends TranslationsDocsComponentsOverflowMarqueeExamplesKo {
	_TranslationsDocsComponentsOverflowMarqueeExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de marquee de débordement';
}

// Path: docs.components.pagination.examples
class _TranslationsDocsComponentsPaginationExamplesFr extends TranslationsDocsComponentsPaginationExamplesKo {
	_TranslationsDocsComponentsPaginationExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de pagination';
}

// Path: docs.components.phone_input.examples
class _TranslationsDocsComponentsPhoneInputExamplesFr extends TranslationsDocsComponentsPhoneInputExamplesKo {
	_TranslationsDocsComponentsPhoneInputExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de saisie de téléphone';
}

// Path: docs.components.popover.examples
class _TranslationsDocsComponentsPopoverExamplesFr extends TranslationsDocsComponentsPopoverExamplesKo {
	_TranslationsDocsComponentsPopoverExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de popover';
}

// Path: docs.components.progress.examples
class _TranslationsDocsComponentsProgressExamplesFr extends TranslationsDocsComponentsProgressExamplesKo {
	_TranslationsDocsComponentsProgressExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de progression';
}

// Path: docs.components.radio_card.examples
class _TranslationsDocsComponentsRadioCardExamplesFr extends TranslationsDocsComponentsRadioCardExamplesKo {
	_TranslationsDocsComponentsRadioCardExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de carte radio';
}

// Path: docs.components.radio_group.examples
class _TranslationsDocsComponentsRadioGroupExamplesFr extends TranslationsDocsComponentsRadioGroupExamplesKo {
	_TranslationsDocsComponentsRadioGroupExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de groupe radio';
}

// Path: docs.components.refresh_trigger.examples
class _TranslationsDocsComponentsRefreshTriggerExamplesFr extends TranslationsDocsComponentsRefreshTriggerExamplesKo {
	_TranslationsDocsComponentsRefreshTriggerExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de déclencheur de rafraîchissement';
}

// Path: docs.components.repeated_animation_builder.examples
class _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesFr extends TranslationsDocsComponentsRepeatedAnimationBuilderExamplesKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de constructeur d\'animation répétée';
}

// Path: docs.components.resizable.examples
class _TranslationsDocsComponentsResizableExamplesFr extends TranslationsDocsComponentsResizableExamplesKo {
	_TranslationsDocsComponentsResizableExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple redimensionnable';
}

// Path: docs.components.scaffold.examples
class _TranslationsDocsComponentsScaffoldExamplesFr extends TranslationsDocsComponentsScaffoldExamplesKo {
	_TranslationsDocsComponentsScaffoldExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'échafaudage';
}

// Path: docs.components.select.examples
class _TranslationsDocsComponentsSelectExamplesFr extends TranslationsDocsComponentsSelectExamplesKo {
	_TranslationsDocsComponentsSelectExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de sélection';
}

// Path: docs.components.sheet.examples
class _TranslationsDocsComponentsSheetExamplesFr extends TranslationsDocsComponentsSheetExamplesKo {
	_TranslationsDocsComponentsSheetExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de feuille';
}

// Path: docs.components.skeleton.examples
class _TranslationsDocsComponentsSkeletonExamplesFr extends TranslationsDocsComponentsSkeletonExamplesKo {
	_TranslationsDocsComponentsSkeletonExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de squelette';
}

// Path: docs.components.slider.examples
class _TranslationsDocsComponentsSliderExamplesFr extends TranslationsDocsComponentsSliderExamplesKo {
	_TranslationsDocsComponentsSliderExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de curseur';
}

// Path: docs.components.sortable.examples
class _TranslationsDocsComponentsSortableExamplesFr extends TranslationsDocsComponentsSortableExamplesKo {
	_TranslationsDocsComponentsSortableExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple triable';
}

// Path: docs.components.star_rating.examples
class _TranslationsDocsComponentsStarRatingExamplesFr extends TranslationsDocsComponentsStarRatingExamplesKo {
	_TranslationsDocsComponentsStarRatingExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'évaluation par étoiles';
}

// Path: docs.components.stepper.examples
class _TranslationsDocsComponentsStepperExamplesFr extends TranslationsDocsComponentsStepperExamplesKo {
	_TranslationsDocsComponentsStepperExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de stepper';
}

// Path: docs.components.steps.examples
class _TranslationsDocsComponentsStepsExamplesFr extends TranslationsDocsComponentsStepsExamplesKo {
	_TranslationsDocsComponentsStepsExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'étapes';
}

// Path: docs.components.swiper.examples
class _TranslationsDocsComponentsSwiperExamplesFr extends TranslationsDocsComponentsSwiperExamplesKo {
	_TranslationsDocsComponentsSwiperExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de swiper';
}

// Path: docs.components.k_switch.examples
class _TranslationsDocsComponentsKSwitchExamplesFr extends TranslationsDocsComponentsKSwitchExamplesKo {
	_TranslationsDocsComponentsKSwitchExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'interrupteur';
}

// Path: docs.components.switcher.examples
class _TranslationsDocsComponentsSwitcherExamplesFr extends TranslationsDocsComponentsSwitcherExamplesKo {
	_TranslationsDocsComponentsSwitcherExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de commutateur';
}

// Path: docs.components.tab_list.examples
class _TranslationsDocsComponentsTabListExamplesFr extends TranslationsDocsComponentsTabListExamplesKo {
	_TranslationsDocsComponentsTabListExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de liste d\'onglets';
}

// Path: docs.components.tab_pane.examples
class _TranslationsDocsComponentsTabPaneExamplesFr extends TranslationsDocsComponentsTabPaneExamplesKo {
	_TranslationsDocsComponentsTabPaneExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de panneau d\'onglets';
}

// Path: docs.components.table.examples
class _TranslationsDocsComponentsTableExamplesFr extends TranslationsDocsComponentsTableExamplesKo {
	_TranslationsDocsComponentsTableExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de tableau';
}

// Path: docs.components.tabs.examples
class _TranslationsDocsComponentsTabsExamplesFr extends TranslationsDocsComponentsTabsExamplesKo {
	_TranslationsDocsComponentsTabsExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'onglets';
}

// Path: docs.components.text_area.examples
class _TranslationsDocsComponentsTextAreaExamplesFr extends TranslationsDocsComponentsTextAreaExamplesKo {
	_TranslationsDocsComponentsTextAreaExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de zone de texte';
}

// Path: docs.components.time_picker.examples
class _TranslationsDocsComponentsTimePickerExamplesFr extends TranslationsDocsComponentsTimePickerExamplesKo {
	_TranslationsDocsComponentsTimePickerExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de sélecteur de temps';
}

// Path: docs.components.timeline.examples
class _TranslationsDocsComponentsTimelineExamplesFr extends TranslationsDocsComponentsTimelineExamplesKo {
	_TranslationsDocsComponentsTimelineExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de chronologie';
}

// Path: docs.components.timeline_animation.examples
class _TranslationsDocsComponentsTimelineAnimationExamplesFr extends TranslationsDocsComponentsTimelineAnimationExamplesKo {
	_TranslationsDocsComponentsTimelineAnimationExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'animation de chronologie';
}

// Path: docs.components.toast.examples
class _TranslationsDocsComponentsToastExamplesFr extends TranslationsDocsComponentsToastExamplesKo {
	_TranslationsDocsComponentsToastExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de toast';
}

// Path: docs.components.toggle.examples
class _TranslationsDocsComponentsToggleExamplesFr extends TranslationsDocsComponentsToggleExamplesKo {
	_TranslationsDocsComponentsToggleExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de bascule';
}

// Path: docs.components.tooltip.examples
class _TranslationsDocsComponentsTooltipExamplesFr extends TranslationsDocsComponentsTooltipExamplesKo {
	_TranslationsDocsComponentsTooltipExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'info-bulle';
}

// Path: docs.components.tracker.examples
class _TranslationsDocsComponentsTrackerExamplesFr extends TranslationsDocsComponentsTrackerExamplesKo {
	_TranslationsDocsComponentsTrackerExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de suivi';
}

// Path: docs.components.tree.examples
class _TranslationsDocsComponentsTreeExamplesFr extends TranslationsDocsComponentsTreeExamplesKo {
	_TranslationsDocsComponentsTreeExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple d\'arbre';
}

// Path: docs.components.window.examples
class _TranslationsDocsComponentsWindowExamplesFr extends TranslationsDocsComponentsWindowExamplesKo {
	_TranslationsDocsComponentsWindowExamplesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemple de fenêtre';
}
