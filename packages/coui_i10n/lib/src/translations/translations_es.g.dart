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
class TranslationsEs extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <es>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsEs _root = this; // ignore: unused_field

	@override 
	TranslationsEs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEs(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsWidgetbookEs widgetbook = _TranslationsWidgetbookEs._(_root);
	@override late final _TranslationsDocsEs docs = _TranslationsDocsEs._(_root);
}

// Path: widgetbook
class _TranslationsWidgetbookEs extends TranslationsWidgetbookKo {
	_TranslationsWidgetbookEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsWidgetbookCommonEs common = _TranslationsWidgetbookCommonEs._(_root);
	@override late final _TranslationsWidgetbookLoadingEs loading = _TranslationsWidgetbookLoadingEs._(_root);
	@override late final _TranslationsWidgetbookTabsEs tabs = _TranslationsWidgetbookTabsEs._(_root);
	@override late final _TranslationsWidgetbookPaginationEs pagination = _TranslationsWidgetbookPaginationEs._(_root);
	@override late final _TranslationsWidgetbookTooltipEs tooltip = _TranslationsWidgetbookTooltipEs._(_root);
	@override late final _TranslationsWidgetbookRadioEs radio = _TranslationsWidgetbookRadioEs._(_root);
	@override late final _TranslationsWidgetbookCardEs card = _TranslationsWidgetbookCardEs._(_root);
	@override late final _TranslationsWidgetbookAlertEs alert = _TranslationsWidgetbookAlertEs._(_root);
	@override late final _TranslationsWidgetbookAccordionEs accordion = _TranslationsWidgetbookAccordionEs._(_root);
	@override late final _TranslationsWidgetbookSkeletonEs skeleton = _TranslationsWidgetbookSkeletonEs._(_root);
	@override late final _TranslationsWidgetbookToastEs toast = _TranslationsWidgetbookToastEs._(_root);
	@override late final _TranslationsWidgetbookChipEs chip = _TranslationsWidgetbookChipEs._(_root);
	@override late final _TranslationsWidgetbookCheckboxEs checkbox = _TranslationsWidgetbookCheckboxEs._(_root);
	@override late final _TranslationsWidgetbookToggleEs toggle = _TranslationsWidgetbookToggleEs._(_root);
	@override late final _TranslationsWidgetbookDialogEs dialog = _TranslationsWidgetbookDialogEs._(_root);
	@override late final _TranslationsWidgetbookPopoverEs popover = _TranslationsWidgetbookPopoverEs._(_root);
	@override late final _TranslationsWidgetbookTextFieldEs text_field = _TranslationsWidgetbookTextFieldEs._(_root);
	@override late final _TranslationsWidgetbookButtonEs button = _TranslationsWidgetbookButtonEs._(_root);
	@override late final _TranslationsWidgetbookTableEs table = _TranslationsWidgetbookTableEs._(_root);
	@override late final _TranslationsWidgetbookKSwitchEs k_switch = _TranslationsWidgetbookKSwitchEs._(_root);
	@override late final _TranslationsWidgetbookSwitchComponentEs switch_component = _TranslationsWidgetbookSwitchComponentEs._(_root);
	@override late final _TranslationsWidgetbookSelectEs select = _TranslationsWidgetbookSelectEs._(_root);
	@override late final _TranslationsWidgetbookBreadcrumbEs breadcrumb = _TranslationsWidgetbookBreadcrumbEs._(_root);
	@override late final _TranslationsWidgetbookBadgeEs badge = _TranslationsWidgetbookBadgeEs._(_root);
	@override late final _TranslationsWidgetbookThemePreviewEs theme_preview = _TranslationsWidgetbookThemePreviewEs._(_root);
	@override late final _TranslationsWidgetbookChatEs chat = _TranslationsWidgetbookChatEs._(_root);
	@override late final _TranslationsWidgetbookMultipleChoiceEs multiple_choice = _TranslationsWidgetbookMultipleChoiceEs._(_root);
	@override late final _TranslationsWidgetbookFormattedInputEs formatted_input = _TranslationsWidgetbookFormattedInputEs._(_root);
	@override late final _TranslationsWidgetbookSwiperEs swiper = _TranslationsWidgetbookSwiperEs._(_root);
}

// Path: docs
class _TranslationsDocsEs extends TranslationsDocsKo {
	_TranslationsDocsEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsCommonEs common = _TranslationsDocsCommonEs._(_root);
	@override late final _TranslationsDocsBadgesEs badges = _TranslationsDocsBadgesEs._(_root);
	@override late final _TranslationsDocsFlavorsEs flavors = _TranslationsDocsFlavorsEs._(_root);
	@override late final _TranslationsDocsNavigationEs navigation = _TranslationsDocsNavigationEs._(_root);
	@override late final _TranslationsDocsPagesEs pages = _TranslationsDocsPagesEs._(_root);
	@override late final _TranslationsDocsComponentsEs components = _TranslationsDocsComponentsEs._(_root);
}

// Path: widgetbook.common
class _TranslationsWidgetbookCommonEs extends TranslationsWidgetbookCommonKo {
	_TranslationsWidgetbookCommonEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get increment_progress => 'Aumentar progreso';
	@override String selected_tab({required Object index}) => 'Pestaña seleccionada: ${index}';
	@override String current_page({required Object page}) => 'Página actual: ${page}';
	@override String total_pages({required Object count}) => 'Total de páginas: ${count}';
	@override String page_of({required Object current, required Object total}) => '${current} página / ${total}';
	@override String get hover_over_icon => 'Pasa el ratón sobre el icono';
	@override String counter({required Object count}) => 'Contador: ${count}';
	@override String selected_rows({required Object count}) => 'Filas seleccionadas: ${count}';
	@override String value({required Object value}) => 'Valor: ${value}';
	@override String selected_cells({required Object count}) => 'Celdas seleccionadas: ${count}';
}

// Path: widgetbook.loading
class _TranslationsWidgetbookLoadingEs extends TranslationsWidgetbookLoadingKo {
	_TranslationsWidgetbookLoadingEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get indeterminate => 'Cargando indefinidamente';
	@override String with_value({required Object percent}) => 'Con valor (${percent}%)';
	@override String get custom_size => 'Tamaño personalizado';
	@override String get custom_height => 'Altura personalizada';
	@override String get circular_progress => 'Progreso circular';
	@override String get linear_progress => 'Progreso lineal';
}

// Path: widgetbook.tabs
class _TranslationsWidgetbookTabsEs extends TranslationsWidgetbookTabsKo {
	_TranslationsWidgetbookTabsEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get home => 'Inicio';
	@override String get profile => 'Perfil';
	@override String get settings => 'Configuraciones';
	@override String get overview => 'Descripción general';
	@override String get details => 'Detalles';
	@override String get history => 'Historial';
	@override String get overview_content => 'Contenido general';
	@override String get details_content => 'Contenido detallado';
	@override String get history_content => 'Contenido del historial';
	@override String get general_info => 'Información general sobre el artículo';
	@override String get specifications => 'Especificaciones y propiedades detalladas';
	@override String get timeline => 'Cronología de cambios y actualizaciones';
}

// Path: widgetbook.pagination
class _TranslationsWidgetbookPaginationEs extends TranslationsWidgetbookPaginationKo {
	_TranslationsWidgetbookPaginationEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get show_skip_to_first => 'Mostrar saltar al primero';
	@override String get show_skip_to_last => 'Mostrar saltar al último';
	@override String get hide_previous_on_first => 'Ocultar anterior en la primera página';
	@override String get hide_next_on_last => 'Ocultar siguiente en la última página';
	@override String get max_visible_pages => 'Número máximo de páginas visibles';
}

// Path: widgetbook.tooltip
class _TranslationsWidgetbookTooltipEs extends TranslationsWidgetbookTooltipKo {
	_TranslationsWidgetbookTooltipEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get helpful_message => 'Este es un mensaje de tooltip útil';
	@override String get tooltip_above => 'Tooltip arriba';
	@override String get tooltip_below => 'Tooltip abajo';
	@override String get tooltip_left => 'Tooltip izquierda';
	@override String get tooltip_right => 'Tooltip derecha';
	@override String get top => 'Arriba';
	@override String get bottom => 'Abajo';
	@override String get left => 'Izquierda';
	@override String get right => 'Derecha';
}

// Path: widgetbook.radio
class _TranslationsWidgetbookRadioEs extends TranslationsWidgetbookRadioKo {
	_TranslationsWidgetbookRadioEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get small => 'Pequeño';
	@override String get medium => 'Mediano';
	@override String get large => 'Grande';
}

// Path: widgetbook.card
class _TranslationsWidgetbookCardEs extends TranslationsWidgetbookCardKo {
	_TranslationsWidgetbookCardEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get card_content => 'Contenido de la tarjeta';
	@override String get gradient_card => 'Tarjeta degradada';
	@override String get custom_decoration => 'Tarjeta con decoración personalizada';
}

// Path: widgetbook.alert
class _TranslationsWidgetbookAlertEs extends TranslationsWidgetbookAlertKo {
	_TranslationsWidgetbookAlertEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título de la alerta';
	@override String get message => 'Este es un mensaje de alerta.';
}

// Path: widgetbook.accordion
class _TranslationsWidgetbookAccordionEs extends TranslationsWidgetbookAccordionKo {
	_TranslationsWidgetbookAccordionEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get what_is_coui => '¿Qué es CoUI Flutter?';
	@override String get what_is_coui_answer => 'CoUI Flutter es una biblioteca de componentes UI integral diseñada para construir aplicaciones Flutter modernas y accesibles con un patrón de diseño coherente.';
	@override String get how_to_install => '¿Cómo instalarlo?';
	@override String get how_to_install_answer => 'Agrega coui_flutter a tus dependencias en pubspec.yaml y ejecuta flutter pub get para instalar el paquete.';
	@override String get is_customizable => '¿Es personalizable?';
	@override String get is_customizable_answer => '¡Sí! CoUI Flutter ofrece un soporte de tema integral que permite personalizar colores, tipografía, espacios, etc., a través de ThemeData.';
	@override String get getting_started => 'Empezando';
	@override String get getting_started_answer => 'Comienza instalando el paquete y importándolo en tu proyecto. Consulta la documentación para más detalles sobre la configuración.';
	@override String get features_expanded => 'Características (expansión por defecto)';
	@override String get features_answer => 'CoUI Flutter incluye botones, formularios, diálogos, componentes de navegación, entre otros. Todos los componentes están diseñados teniendo en cuenta la accesibilidad y el tema.';
	@override String get support => 'Soporte';
	@override String get support_answer => 'Si tienes preguntas o necesitas ayuda, visita nuestro repositorio de GitHub o consulta la documentación en docs.coui.dev.';
}

// Path: widgetbook.skeleton
class _TranslationsWidgetbookSkeletonEs extends TranslationsWidgetbookSkeletonKo {
	_TranslationsWidgetbookSkeletonEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get skeleton_enabled => 'Esqueleto habilitado:';
	@override String get title_text => 'Este es el título';
	@override String get description_text => 'Este es un texto de descripción largo';
	@override String get short_text => 'Texto corto';
	@override String get without_skeleton => 'Sin esqueleto:';
	@override String get with_skeleton => 'Con esqueleto:';
	@override String get user_name => 'Nombre de usuario';
	@override String get user_email => 'user@example.com';
	@override String get article_title => 'Título del artículo';
	@override String get posted_date => 'Publicado el 1 de enero de 2024';
	@override String get bio_description => 'Desarrollador que registra la vida diaria';
	@override String get show_content => 'Mostrar contenido';
	@override String get show_loading => 'Mostrar carga';
	@override String get article_content => 'Este es un ejemplo del contenido del artículo. Se reemplaza por un esqueleto mientras se carga.';
}

// Path: widgetbook.toast
class _TranslationsWidgetbookToastEs extends TranslationsWidgetbookToastKo {
	_TranslationsWidgetbookToastEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get success => 'Éxito';
	@override String get operation_completed => 'La operación se completó con éxito';
	@override String get show_toast => 'Mostrar toast';
	@override String toast_at({required Object location}) => 'Toast en ${location}';
	@override String get top_left => 'Esquina superior izquierda';
	@override String get top_center => 'Centro superior';
	@override String get top_right => 'Esquina superior derecha';
	@override String get bottom_left => 'Esquina inferior izquierda';
	@override String get bottom_center => 'Centro inferior';
	@override String get bottom_right => 'Esquina inferior derecha';
}

// Path: widgetbook.chip
class _TranslationsWidgetbookChipEs extends TranslationsWidgetbookChipKo {
	_TranslationsWidgetbookChipEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get chip => 'Chip';
}

// Path: widgetbook.checkbox
class _TranslationsWidgetbookCheckboxEs extends TranslationsWidgetbookCheckboxKo {
	_TranslationsWidgetbookCheckboxEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get accept_terms => 'Acepto los términos y condiciones';
	@override String get tristate => 'Tres estados';
}

// Path: widgetbook.toggle
class _TranslationsWidgetbookToggleEs extends TranslationsWidgetbookToggleKo {
	_TranslationsWidgetbookToggleEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get toggle => 'Alternar';
}

// Path: widgetbook.dialog
class _TranslationsWidgetbookDialogEs extends TranslationsWidgetbookDialogKo {
	_TranslationsWidgetbookDialogEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic_dialog => 'Diálogo básico';
	@override String get basic_title => 'Diálogo básico';
	@override String get basic_content => 'Un diálogo simple con título y contenido.';
	@override String get simple_dialog_content => 'Este es un diálogo simple con título y contenido.';
	@override String get show_basic => 'Mostrar básico';
	@override String get show_basic_dialog => 'Mostrar diálogo básico';
	@override String get confirm_action => 'Confirmar acción';
	@override String get confirm_title => 'Confirmar';
	@override String get confirm_content => '¿Está seguro de que desea realizar esta acción?';
	@override String get confirm_action_content => '¿Realmente quieres realizar esta acción? Esta acción no se puede deshacer.';
	@override String get cancel => 'Cancelar';
	@override String get confirm => 'Confirmar';
	@override String get show_confirmation => 'Mostrar confirmación';
	@override String get show_confirmation_dialog => 'Mostrar diálogo de confirmación';
	@override String get warning => 'Advertencia';
	@override String get warning_title => 'Advertencia';
	@override String get warning_content => 'Esta acción puede afectar los datos. Procede con precaución.';
	@override String get dismiss => 'Cerrar';
	@override String get show_warning => 'Mostrar advertencia';
	@override String get show_warning_dialog => 'Mostrar diálogo de advertencia';
}

// Path: widgetbook.popover
class _TranslationsWidgetbookPopoverEs extends TranslationsWidgetbookPopoverKo {
	_TranslationsWidgetbookPopoverEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get popover_content => 'Contenido del popover';
	@override String get content_title => 'Título del popover';
	@override String get content_description => 'Popover con contenido personalizable.';
	@override String get customizable_content => 'Popover con contenido personalizable.';
	@override String get show_popover => 'Mostrar popover';
	@override String popover_at({required Object position}) => '${position} en popover';
	@override String get top => 'Superior';
	@override String get bottom => 'Inferior';
	@override String get left => 'Izquierda';
	@override String get right => 'Derecha';
}

// Path: widgetbook.text_field
class _TranslationsWidgetbookTextFieldEs extends TranslationsWidgetbookTextFieldKo {
	_TranslationsWidgetbookTextFieldEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get enter_name => 'Ingresa tu nombre';
	@override String get type_here => 'Escribe aquí';
}

// Path: widgetbook.button
class _TranslationsWidgetbookButtonEs extends TranslationsWidgetbookButtonKo {
	_TranslationsWidgetbookButtonEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get primary_button => 'Botón principal';
	@override String get secondary_button => 'Botón secundario';
	@override String get dashed_button => 'Subir archivo';
	@override String get upload_file => 'Subir archivo';
}

// Path: widgetbook.table
class _TranslationsWidgetbookTableEs extends TranslationsWidgetbookTableKo {
	_TranslationsWidgetbookTableEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get name => 'Nombre';
	@override String get email => 'Correo electrónico';
	@override String get role => 'Rol';
	@override String get john_doe => 'Juan Pérez';
	@override String get john_email => 'juan@example.com';
	@override String get developer => 'Desarrollador';
	@override String get jane_smith => 'Ana Gómez';
	@override String get jane_email => 'ana@example.com';
	@override String get designer => 'Diseñador';
	@override String get bob_johnson => 'Carlos Ruiz';
	@override String get bob_email => 'carlos@example.com';
	@override String get manager => 'Gerente';
	@override String get select => 'Seleccionar';
	@override String get product => 'Producto';
	@override String get price => 'Precio';
	@override String get stock => 'Inventario';
	@override String get laptop => 'Portátil';
	@override String get mouse => 'Ratón';
	@override String get keyboard => 'Teclado';
}

// Path: widgetbook.k_switch
class _TranslationsWidgetbookKSwitchEs extends TranslationsWidgetbookKSwitchKo {
	_TranslationsWidgetbookKSwitchEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get k_switch => 'Interruptor';
}

// Path: widgetbook.switch_component
class _TranslationsWidgetbookSwitchComponentEs extends TranslationsWidgetbookSwitchComponentKo {
	_TranslationsWidgetbookSwitchComponentEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get switch_label => 'Etiqueta del interruptor';
}

// Path: widgetbook.select
class _TranslationsWidgetbookSelectEs extends TranslationsWidgetbookSelectKo {
	_TranslationsWidgetbookSelectEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get apple => 'Manzana';
	@override String get banana => 'Banana';
	@override String get cherry => 'Cereza';
	@override String get date => 'Dátil';
	@override String get choose_size => 'Elige un tamaño';
	@override String get small => 'Pequeño';
	@override String get medium => 'Mediano';
	@override String get large => 'Grande';
	@override String get extra_large => 'Extra grande';
}

// Path: widgetbook.breadcrumb
class _TranslationsWidgetbookBreadcrumbEs extends TranslationsWidgetbookBreadcrumbKo {
	_TranslationsWidgetbookBreadcrumbEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get home => 'Inicio';
	@override String get products => 'Productos';
	@override String get electronics => 'Electrónica';
	@override String get smartphones => 'Smartphones';
	@override String get documents => 'Documentos';
	@override String get projects => 'Proyectos';
	@override String get current_folder => 'Carpeta actual';
	@override String current_path({required Object path}) => 'Ruta actual: ${path}';
}

// Path: widgetbook.badge
class _TranslationsWidgetbookBadgeEs extends TranslationsWidgetbookBadgeKo {
	_TranslationsWidgetbookBadgeEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get primary => 'Primario';
	@override String get secondary => 'Secundario';
	@override String get outline => 'Contorno';
	@override String get destructive => 'Destructivo';
	@override String get featured => 'Destacado';
	@override String get more => 'Más';
	@override String get verified => 'Verificado';
	@override String get error => 'Error';
	@override String get click_me => 'Haz clic aquí';
	@override String get clickable => 'Clicable';
}

// Path: widgetbook.theme_preview
class _TranslationsWidgetbookThemePreviewEs extends TranslationsWidgetbookThemePreviewKo {
	_TranslationsWidgetbookThemePreviewEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Vista previa del tema';
	@override String get description => 'Una visión general integral de todos los tokens de tema y estilos de componentes';
	@override String get color_palette => 'Paleta de colores';
	@override String get brand_colors => 'Colores de marca';
	@override String get base_colors => 'Colores base';
	@override String get status_colors => 'Colores de estado';
	@override String get buttons => 'Botones';
	@override String get primary_button => 'Primario';
	@override String get secondary_button => 'Secundario';
	@override String get outline_button => 'Contorno';
	@override String get ghost_button => 'Fantasma';
	@override String get destructive_button => 'Destructivo';
	@override String get disabled_button => 'Deshabilitado';
	@override String get cards => 'Tarjetas';
	@override String get card_title => 'Título de la tarjeta';
	@override String get card_description => 'Descripción de la tarjeta de muestra.';
	@override String get surface_card => 'Tarjeta de superficie';
	@override String get filled_variant => 'Estilo lleno con fondo';
	@override String get form_elements => 'Elementos de formulario';
	@override String get text_input_placeholder => 'Escriba el texto aquí...';
	@override String get checkbox_checked => 'Seleccionado';
	@override String get checkbox_unchecked => 'No seleccionado';
	@override String get toggle_on => 'Encendido';
	@override String get toggle_off => 'Apagado';
	@override String get alerts => 'Alertas';
	@override String get info_alert => 'Alerta de información';
	@override String get info_alert_message => 'Este es un mensaje informativo.';
	@override String get error_alert => 'Alerta de error';
	@override String get error_alert_message => 'Ha ocurrido un problema.';
	@override String get badges_chips => 'Insignias y Chips';
	@override String get primary_badge => 'Primario';
	@override String get secondary_badge => 'Secundario';
	@override String get outline_badge => 'Contorno';
	@override String get destructive_badge => 'Destructivo';
	@override String get chip_example => 'Favorito';
	@override String get typography => 'Tipografía';
	@override String get heading_1 => 'Título 1';
	@override String get heading_2 => 'Título 2';
	@override String get heading_3 => 'Título 3';
	@override String get heading_4 => 'Título 4';
	@override String get body_text => 'Texto del cuerpo con grosor normal.';
	@override String get small_text => 'Texto pequeño para captions.';
	@override String get muted_text => 'Texto atenuado para información adicional.';
	@override String get bold_text => 'Texto en negrita para énfasis.';
	@override String get spacing_radius => 'Espaciado y redondeo';
	@override String get border_radius => 'Redondeo de bordes';
	@override String get loading_states => 'Estados de carga';
}

// Path: widgetbook.chat
class _TranslationsWidgetbookChatEs extends TranslationsWidgetbookChatKo {
	_TranslationsWidgetbookChatEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get hello => '¡Hola! ¿Cómo estás?';
	@override String get doing_great => '¡Muy bien, gracias!';
	@override String get nice_weather => '¡Buen tiempo hoy!';
	@override String get yes_beautiful => '¡Sí, es hermoso!';
	@override String get sender => 'Remitente';
	@override String get receiver => 'Destinatario';
}

// Path: widgetbook.multiple_choice
class _TranslationsWidgetbookMultipleChoiceEs extends TranslationsWidgetbookMultipleChoiceKo {
	_TranslationsWidgetbookMultipleChoiceEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get option_a => 'Option A';
	@override String get option_b => 'Option B';
	@override String get option_c => 'Option C';
	@override String get option_d => 'Option D';
	@override String selected_value({required Object value}) => 'Seleccionado: ${value}';
	@override String selected_values({required Object values}) => 'Seleccionados: ${values}';
}

// Path: widgetbook.formatted_input
class _TranslationsWidgetbookFormattedInputEs extends TranslationsWidgetbookFormattedInputKo {
	_TranslationsWidgetbookFormattedInputEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get date_format => 'Formato de fecha (MM/DD/AAAA)';
	@override String get time_format => 'Formato de hora (HH:MM)';
	@override String current_value({required Object value}) => 'Valor actual: ${value}';
}

// Path: widgetbook.swiper
class _TranslationsWidgetbookSwiperEs extends TranslationsWidgetbookSwiperKo {
	_TranslationsWidgetbookSwiperEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get swipe_hint => 'Desliza o toca para abrir';
	@override String get overlay_content => 'Contenido del overlay';
	@override String get close => 'Cerrar';
}

// Path: docs.common
class _TranslationsDocsCommonEs extends TranslationsDocsCommonKo {
	_TranslationsDocsCommonEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get app_name => 'coui_flutter';
	@override String get search_documentation => 'Buscar documentación...';
	@override String get docs => 'Documentos';
	@override String get components => 'Componentes';
	@override String get close => 'Cerrar';
	@override String get on_this_page => 'Índice de esta página';
	@override String get work_in_progress_title => 'En desarrollo';
	@override String get work_in_progress_message => 'Esta página todavía está en desarrollo. Por favor, regresa más tarde.';
	@override String get add => 'Agregar';
	@override String get reset => 'Reiniciar';
	@override String get prev => 'Anterior';
	@override String get next => 'Siguiente';
	@override String get finish => 'Finalizar';
	@override String get open => 'Abrir';
	@override String get disabled => 'Desactivado';
	@override String get refresh => 'Actualizar';
	@override String get rebuild => 'Reconstruir';
	@override String get change_color => 'Cambiar color';
}

// Path: docs.badges
class _TranslationsDocsBadgesEs extends TranslationsDocsBadgesKo {
	_TranslationsDocsBadgesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get k_new => 'Nuevo';
	@override String get updated => 'Actualizado';
	@override String get wip => 'En desarrollo';
	@override String get experimental => 'Experimental';
}

// Path: docs.flavors
class _TranslationsDocsFlavorsEs extends TranslationsDocsFlavorsKo {
	_TranslationsDocsFlavorsEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get local => 'Local';
	@override String get experimental => 'Experimental';
	@override String get unknown => 'Desconocido';
}

// Path: docs.navigation
class _TranslationsDocsNavigationEs extends TranslationsDocsNavigationKo {
	_TranslationsDocsNavigationEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get getting_started => 'Introductorio';
	@override String get animation => 'Animación';
	@override String get control => 'Control';
	@override String get disclosure => 'Divulgación';
	@override String get display => 'Mostrar';
	@override String get feedback => 'Comentarios';
	@override String get form => 'Formulario';
	@override String get layout => 'Diseño';
	@override String get navigation => 'Navegación';
	@override String get overlay => 'Superposición';
	@override String get utility => 'Utilidad';
	@override String get my_account => 'Mi cuenta';
	@override String get profile => 'Perfil';
	@override String get settings => 'Configuración';
	@override String get team => 'Equipo';
	@override String get new_team => 'Nuevo equipo';
	@override String get billing => 'Facturación';
	@override String get api => 'API';
	@override String get log_out => 'Cerrar sesión';
	@override String get support => 'Soporte';
	@override String get invite_users => 'Invitar usuarios';
	@override String get more => 'Más';
	@override String get github => 'GitHub';
	@override String get note => 'Nota';
	@override String get message => 'Mensaje';
	@override String get keyboard_shortcuts => 'Atajos de teclado';
}

// Path: docs.pages
class _TranslationsDocsPagesEs extends TranslationsDocsPagesKo {
	_TranslationsDocsPagesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsPagesIntroductionEs introduction = _TranslationsDocsPagesIntroductionEs._(_root);
	@override late final _TranslationsDocsPagesInstallationEs installation = _TranslationsDocsPagesInstallationEs._(_root);
	@override late final _TranslationsDocsPagesThemeEs theme = _TranslationsDocsPagesThemeEs._(_root);
	@override late final _TranslationsDocsPagesTypographyEs typography = _TranslationsDocsPagesTypographyEs._(_root);
	@override late final _TranslationsDocsPagesLayoutEs layout = _TranslationsDocsPagesLayoutEs._(_root);
	@override late final _TranslationsDocsPagesWebPreloaderEs web_preloader = _TranslationsDocsPagesWebPreloaderEs._(_root);
	@override late final _TranslationsDocsPagesComponentsListEs components_list = _TranslationsDocsPagesComponentsListEs._(_root);
	@override late final _TranslationsDocsPagesIconsEs icons = _TranslationsDocsPagesIconsEs._(_root);
	@override late final _TranslationsDocsPagesColorsEs colors = _TranslationsDocsPagesColorsEs._(_root);
	@override late final _TranslationsDocsPagesExternalEs external = _TranslationsDocsPagesExternalEs._(_root);
	@override late final _TranslationsDocsPagesStateEs state = _TranslationsDocsPagesStateEs._(_root);
}

// Path: docs.components
class _TranslationsDocsComponentsEs extends TranslationsDocsComponentsKo {
	_TranslationsDocsComponentsEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsComponentsAccordionEs accordion = _TranslationsDocsComponentsAccordionEs._(_root);
	@override late final _TranslationsDocsComponentsAlertEs alert = _TranslationsDocsComponentsAlertEs._(_root);
	@override late final _TranslationsDocsComponentsAlertDialogEs alert_dialog = _TranslationsDocsComponentsAlertDialogEs._(_root);
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderEs animated_value_builder = _TranslationsDocsComponentsAnimatedValueBuilderEs._(_root);
	@override late final _TranslationsDocsComponentsAppBarEs app_bar = _TranslationsDocsComponentsAppBarEs._(_root);
	@override late final _TranslationsDocsComponentsAutocompleteEs autocomplete = _TranslationsDocsComponentsAutocompleteEs._(_root);
	@override late final _TranslationsDocsComponentsAvatarEs avatar = _TranslationsDocsComponentsAvatarEs._(_root);
	@override late final _TranslationsDocsComponentsAvatarGroupEs avatar_group = _TranslationsDocsComponentsAvatarGroupEs._(_root);
	@override late final _TranslationsDocsComponentsBadgeEs badge = _TranslationsDocsComponentsBadgeEs._(_root);
	@override late final _TranslationsDocsComponentsBreadcrumbEs breadcrumb = _TranslationsDocsComponentsBreadcrumbEs._(_root);
	@override late final _TranslationsDocsComponentsButtonEs button = _TranslationsDocsComponentsButtonEs._(_root);
	@override late final _TranslationsDocsComponentsCalendarEs calendar = _TranslationsDocsComponentsCalendarEs._(_root);
	@override late final _TranslationsDocsComponentsCardEs card = _TranslationsDocsComponentsCardEs._(_root);
	@override late final _TranslationsDocsComponentsCardImageEs card_image = _TranslationsDocsComponentsCardImageEs._(_root);
	@override late final _TranslationsDocsComponentsCarouselEs carousel = _TranslationsDocsComponentsCarouselEs._(_root);
	@override late final _TranslationsDocsComponentsCheckboxEs checkbox = _TranslationsDocsComponentsCheckboxEs._(_root);
	@override late final _TranslationsDocsComponentsChipEs chip = _TranslationsDocsComponentsChipEs._(_root);
	@override late final _TranslationsDocsComponentsChipInputEs chip_input = _TranslationsDocsComponentsChipInputEs._(_root);
	@override late final _TranslationsDocsComponentsCircularProgressEs circular_progress = _TranslationsDocsComponentsCircularProgressEs._(_root);
	@override late final _TranslationsDocsComponentsCodeSnippetEs code_snippet = _TranslationsDocsComponentsCodeSnippetEs._(_root);
	@override late final _TranslationsDocsComponentsCollapsibleEs collapsible = _TranslationsDocsComponentsCollapsibleEs._(_root);
	@override late final _TranslationsDocsComponentsColorPickerEs color_picker = _TranslationsDocsComponentsColorPickerEs._(_root);
	@override late final _TranslationsDocsComponentsCommandEs command = _TranslationsDocsComponentsCommandEs._(_root);
	@override late final _TranslationsDocsComponentsContextMenuEs context_menu = _TranslationsDocsComponentsContextMenuEs._(_root);
	@override late final _TranslationsDocsComponentsDatePickerEs date_picker = _TranslationsDocsComponentsDatePickerEs._(_root);
	@override late final _TranslationsDocsComponentsDialogEs dialog = _TranslationsDocsComponentsDialogEs._(_root);
	@override late final _TranslationsDocsComponentsDividerEs divider = _TranslationsDocsComponentsDividerEs._(_root);
	@override late final _TranslationsDocsComponentsDotIndicatorEs dot_indicator = _TranslationsDocsComponentsDotIndicatorEs._(_root);
	@override late final _TranslationsDocsComponentsDrawerEs drawer = _TranslationsDocsComponentsDrawerEs._(_root);
	@override late final _TranslationsDocsComponentsDropdownMenuEs dropdown_menu = _TranslationsDocsComponentsDropdownMenuEs._(_root);
	@override late final _TranslationsDocsComponentsExpandableSidebarEs expandable_sidebar = _TranslationsDocsComponentsExpandableSidebarEs._(_root);
	@override late final _TranslationsDocsComponentsFormEs form = _TranslationsDocsComponentsFormEs._(_root);
	@override late final _TranslationsDocsComponentsFormattedInputEs formatted_input = _TranslationsDocsComponentsFormattedInputEs._(_root);
	@override late final _TranslationsDocsComponentsHoverCardEs hover_card = _TranslationsDocsComponentsHoverCardEs._(_root);
	@override late final _TranslationsDocsComponentsInputEs input = _TranslationsDocsComponentsInputEs._(_root);
	@override late final _TranslationsDocsComponentsInputOtpEs input_otp = _TranslationsDocsComponentsInputOtpEs._(_root);
	@override late final _TranslationsDocsComponentsItemPickerEs item_picker = _TranslationsDocsComponentsItemPickerEs._(_root);
	@override late final _TranslationsDocsComponentsKeyboardDisplayEs keyboard_display = _TranslationsDocsComponentsKeyboardDisplayEs._(_root);
	@override late final _TranslationsDocsComponentsLinearProgressEs linear_progress = _TranslationsDocsComponentsLinearProgressEs._(_root);
	@override late final _TranslationsDocsComponentsMaterialEs material = _TranslationsDocsComponentsMaterialEs._(_root);
	@override late final _TranslationsDocsComponentsMenubarEs menubar = _TranslationsDocsComponentsMenubarEs._(_root);
	@override late final _TranslationsDocsComponentsMultiselectEs multiselect = _TranslationsDocsComponentsMultiselectEs._(_root);
	@override late final _TranslationsDocsComponentsNavigationBarEs navigation_bar = _TranslationsDocsComponentsNavigationBarEs._(_root);
	@override late final _TranslationsDocsComponentsNavigationMenuEs navigation_menu = _TranslationsDocsComponentsNavigationMenuEs._(_root);
	@override late final _TranslationsDocsComponentsNavigationRailEs navigation_rail = _TranslationsDocsComponentsNavigationRailEs._(_root);
	@override late final _TranslationsDocsComponentsNavigationSidebarEs navigation_sidebar = _TranslationsDocsComponentsNavigationSidebarEs._(_root);
	@override late final _TranslationsDocsComponentsNumberInputEs number_input = _TranslationsDocsComponentsNumberInputEs._(_root);
	@override late final _TranslationsDocsComponentsNumberTickerEs number_ticker = _TranslationsDocsComponentsNumberTickerEs._(_root);
	@override late final _TranslationsDocsComponentsOverflowMarqueeEs overflow_marquee = _TranslationsDocsComponentsOverflowMarqueeEs._(_root);
	@override late final _TranslationsDocsComponentsPaginationEs pagination = _TranslationsDocsComponentsPaginationEs._(_root);
	@override late final _TranslationsDocsComponentsPhoneInputEs phone_input = _TranslationsDocsComponentsPhoneInputEs._(_root);
	@override late final _TranslationsDocsComponentsPopoverEs popover = _TranslationsDocsComponentsPopoverEs._(_root);
	@override late final _TranslationsDocsComponentsProgressEs progress = _TranslationsDocsComponentsProgressEs._(_root);
	@override late final _TranslationsDocsComponentsRadioCardEs radio_card = _TranslationsDocsComponentsRadioCardEs._(_root);
	@override late final _TranslationsDocsComponentsRadioGroupEs radio_group = _TranslationsDocsComponentsRadioGroupEs._(_root);
	@override late final _TranslationsDocsComponentsRefreshTriggerEs refresh_trigger = _TranslationsDocsComponentsRefreshTriggerEs._(_root);
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderEs repeated_animation_builder = _TranslationsDocsComponentsRepeatedAnimationBuilderEs._(_root);
	@override late final _TranslationsDocsComponentsResizableEs resizable = _TranslationsDocsComponentsResizableEs._(_root);
	@override late final _TranslationsDocsComponentsScaffoldEs scaffold = _TranslationsDocsComponentsScaffoldEs._(_root);
	@override late final _TranslationsDocsComponentsSelectEs select = _TranslationsDocsComponentsSelectEs._(_root);
	@override late final _TranslationsDocsComponentsSheetEs sheet = _TranslationsDocsComponentsSheetEs._(_root);
	@override late final _TranslationsDocsComponentsSkeletonEs skeleton = _TranslationsDocsComponentsSkeletonEs._(_root);
	@override late final _TranslationsDocsComponentsSliderEs slider = _TranslationsDocsComponentsSliderEs._(_root);
	@override late final _TranslationsDocsComponentsSortableEs sortable = _TranslationsDocsComponentsSortableEs._(_root);
	@override late final _TranslationsDocsComponentsStarRatingEs star_rating = _TranslationsDocsComponentsStarRatingEs._(_root);
	@override late final _TranslationsDocsComponentsStepperEs stepper = _TranslationsDocsComponentsStepperEs._(_root);
	@override late final _TranslationsDocsComponentsStepsEs steps = _TranslationsDocsComponentsStepsEs._(_root);
	@override late final _TranslationsDocsComponentsSwiperEs swiper = _TranslationsDocsComponentsSwiperEs._(_root);
	@override late final _TranslationsDocsComponentsKSwitchEs k_switch = _TranslationsDocsComponentsKSwitchEs._(_root);
	@override late final _TranslationsDocsComponentsSwitcherEs switcher = _TranslationsDocsComponentsSwitcherEs._(_root);
	@override late final _TranslationsDocsComponentsTabListEs tab_list = _TranslationsDocsComponentsTabListEs._(_root);
	@override late final _TranslationsDocsComponentsTabPaneEs tab_pane = _TranslationsDocsComponentsTabPaneEs._(_root);
	@override late final _TranslationsDocsComponentsTableEs table = _TranslationsDocsComponentsTableEs._(_root);
	@override late final _TranslationsDocsComponentsTabsEs tabs = _TranslationsDocsComponentsTabsEs._(_root);
	@override late final _TranslationsDocsComponentsTextAreaEs text_area = _TranslationsDocsComponentsTextAreaEs._(_root);
	@override late final _TranslationsDocsComponentsTimePickerEs time_picker = _TranslationsDocsComponentsTimePickerEs._(_root);
	@override late final _TranslationsDocsComponentsTimelineEs timeline = _TranslationsDocsComponentsTimelineEs._(_root);
	@override late final _TranslationsDocsComponentsTimelineAnimationEs timeline_animation = _TranslationsDocsComponentsTimelineAnimationEs._(_root);
	@override late final _TranslationsDocsComponentsToastEs toast = _TranslationsDocsComponentsToastEs._(_root);
	@override late final _TranslationsDocsComponentsToggleEs toggle = _TranslationsDocsComponentsToggleEs._(_root);
	@override late final _TranslationsDocsComponentsTooltipEs tooltip = _TranslationsDocsComponentsTooltipEs._(_root);
	@override late final _TranslationsDocsComponentsTrackerEs tracker = _TranslationsDocsComponentsTrackerEs._(_root);
	@override late final _TranslationsDocsComponentsTreeEs tree = _TranslationsDocsComponentsTreeEs._(_root);
	@override late final _TranslationsDocsComponentsWindowEs window = _TranslationsDocsComponentsWindowEs._(_root);
}

// Path: docs.pages.introduction
class _TranslationsDocsPagesIntroductionEs extends TranslationsDocsPagesIntroductionKo {
	_TranslationsDocsPagesIntroductionEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Introducción';
	@override String get description => 'Empezando con coui_flutter';
	@override String get lead => 'Ahora puedes utilizar los hermosos componentes de Coui/UI en Flutter.';
	@override String get welcome_paragraph_1 => 'coui_flutter es un conjunto diverso y abarcador de componentes de UI diseñado especialmente para aplicaciones de escritorio y web en Flutter. A medida que crece la popularidad de Flutter para construir aplicaciones multiplataforma, reconocimos la necesidad de un kit de herramientas que resalte los requisitos únicos de diseño de las interfaces de escritorio y web.';
	@override String get welcome_paragraph_2 => 'Este paquete proporciona una amplia gama de componentes personalizables y responsivos que cumplen con los principios de diseño modernos de escritorio y web. Ya sea que estés construyendo aplicaciones empresariales sofisticadas, dashboards elegantes o herramientas de productividad, nuestros componentes están diseñados para ayudarte a crear UI profesional y elegante de manera rápida y eficiente.';
	@override String get features => 'Características principales';
	@override late final _TranslationsDocsPagesIntroductionFeaturesListEs features_list = _TranslationsDocsPagesIntroductionFeaturesListEs._(_root);
	@override String get notes => 'Notas';
	@override String get notes_paragraph_1 => 'Este paquete todavía está en desarrollo y puede haber cambios en el futuro. Ten cuidado al usar este paquete en producción.';
	@override String get notes_paragraph_2 => 'Este paquete no está asociado con Coui/UI. Este es un proyecto liderado por la comunidad.';
	@override String get faq => 'Preguntas frecuentes';
	@override String get faq_gorouter_q => '¿Soporta GoRouter?';
	@override String get faq_gorouter_a => 'Sí, lo soporta. Puedes usar GoRouter junto con coui_flutter.';
	@override String get faq_usage_q => '¿Puedo usarlo en mi proyecto?';
	@override String get faq_usage_a => '¡Sí! Puedes usarlo de forma gratuita en proyectos personales y comerciales. No es necesario atribuir al autor.';
	@override String get faq_material_q => '¿Puedo usarlo con widgets de Material/Cupertino?';
	@override String get faq_material_a_1 => '¡Por supuesto!';
	@override String get faq_material_a_2 => '¡Consulta esta página!';
	@override String get faq_style_q => '¿Puedo configurar qué estilo usar? (Predeterminado/Nueva York)';
	@override String get faq_style_a_1 => 'Desafortunadamente, no puedes. Este paquete solo soporta el estilo Nueva York. Pero si deseas el estilo predeterminado de Coui/UI,';
	@override String get faq_style_a_2 => 'se recomienda este paquete.';
	@override String get faq_style_a_3 => 'Creador:';
	@override String get links => 'Enlaces';
	@override String get link_github => 'Github: ';
	@override String get link_pubdev => 'pub.dev: ';
	@override String get link_discord => 'Discord: ';
}

// Path: docs.pages.installation
class _TranslationsDocsPagesInstallationEs extends TranslationsDocsPagesInstallationKo {
	_TranslationsDocsPagesInstallationEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Instalación';
	@override String get description => 'Instalar coui_flutter en tu proyecto';
	@override String get stable_version => 'Versión estable';
	@override String get experimental_version => 'Versión experimental';
	@override String get step1_title => 'Crea un nuevo proyecto de Flutter';
	@override String get step1_content => 'Usa el siguiente comando para crear un nuevo proyecto de Flutter:';
	@override String get step2_title => 'Agregar dependencias';
	@override String get step2_content => 'A continuación, agrega la dependencia de coui_flutter a tu proyecto.';
	@override String get step3_title => 'Importar paquetes';
	@override String get step3_content => 'Ahora puedes importar el paquete en tu código Dart.';
	@override String get step4_title => 'Agregar el widget CouiApp';
	@override String get step4_content => 'Agrega el widget CouiApp a la función main.';
	@override String get step5_title => 'Ejecutar la aplicación';
	@override String get step5_content => 'Usa el siguiente comando para ejecutar la aplicación:';
	@override String get experimental_intro => 'La versión experimental está disponible en GitHub.';
	@override String get experimental_usage => 'Para usar la versión experimental, en lugar del número de versión en el archivo pubspec.yaml, usa git:';
	@override String get see_page => 'Consulta: ';
	@override String get this_page => 'esta página';
	@override String get for_more_info => ' para más información.';
	@override String get warning_title => 'Advertencia';
	@override String get warning_content => 'La versión experimental puede contener cambios que rompen la compatibilidad y no se recomienda para uso en producción. Esta versión debe usarse solo para pruebas y desarrollo.';
}

// Path: docs.pages.theme
class _TranslationsDocsPagesThemeEs extends TranslationsDocsPagesThemeKo {
	_TranslationsDocsPagesThemeEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tema';
	@override String get description => 'Personalización de temas';
	@override String get custom_color_scheme => 'Esquema de color personalizado';
	@override String get custom_color_scheme_desc => 'Puedes personalizar la apariencia y sensación de tu app utilizando un esquema de color personalizado.';
	@override String get premade_color_schemes => 'Esquemas de color predefinidos';
	@override String get premade_color_schemes_desc => 'Puedes personalizar la apariencia y sensación de tu app utilizando esquemas de color predefinidos.';
	@override String get radius => 'Radio';
	@override String get radius_desc => 'Puedes personalizar cuán redondeada se ve tu app cambiando el radio.';
	@override String get scaling => 'Escalado';
	@override String get scaling_desc => 'Puedes personalizar la escala de los componentes de coui_flutter cambiando el escalado.';
	@override String get scaling_alert => 'No escala toda la app. Solo los componentes de coui_flutter se ven afectados.';
	@override String get surface_opacity => 'Opacidad de la superficie';
	@override String get surface_opacity_desc => 'Puedes personalizar la opacidad de la superficie cambiando la opacidad de la superficie.';
	@override String get surface_blur => 'Desenfoque de la superficie';
	@override String get surface_blur_desc => 'Puedes personalizar el desenfoque de la superficie cambiando el desenfoque de la superficie.';
	@override String get code => 'Código';
	@override String get code_desc => 'Usa el siguiente código para aplicar el esquema de color.';
}

// Path: docs.pages.typography
class _TranslationsDocsPagesTypographyEs extends TranslationsDocsPagesTypographyKo {
	_TranslationsDocsPagesTypographyEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tipografía';
	@override String get description => 'Estilo de texto';
	@override String get headline1 => 'Encabezado 1';
	@override String get headline2 => 'Encabezado 2';
	@override String get headline3 => 'Encabezado 3';
	@override String get headline4 => 'Encabezado 4';
	@override String get paragraph => 'Párrafo';
	@override String get blockquote => 'Cita';
	@override String get list => 'Lista';
	@override String get inline_code => 'Código en línea';
	@override String get lead => 'Introducción';
	@override String get large_text => 'Texto grande';
	@override String get small_text => 'Texto pequeño';
	@override String get muted_text => 'Texto tenue';
	@override String get sans => 'Sans';
	@override String get mono => 'Mono';
	@override String get extra_small => 'Muy pequeño';
	@override String get small => 'Pequeño';
	@override String get base => 'Base';
	@override String get large => 'Grande';
	@override String get extra_large => 'Muy grande';
	@override String get extra_2x_large => 'Muy 2x grande';
	@override String get extra_3x_large => 'Muy 3x grande';
	@override String get extra_4x_large => 'Muy 4x grande';
	@override String get extra_5x_large => 'Muy 5x grande';
	@override String get extra_6x_large => 'Muy 6x grande';
	@override String get extra_7x_large => 'Muy 7x grande';
	@override String get extra_8x_large => 'Muy 8x grande';
	@override String get extra_9x_large => 'Muy 9x grande';
	@override String get thin => 'Delgado';
	@override String get extra_light => 'Muy ligero';
	@override String get light => 'Ligero';
	@override String get normal => 'Normal';
	@override String get medium => 'Mediano';
	@override String get semi_bold => 'Semi negrita';
	@override String get bold => 'Negrita';
	@override String get extra_bold => 'Muy negrita';
	@override String get black => 'Negro';
	@override String get italic => 'Cursiva';
}

// Path: docs.pages.layout
class _TranslationsDocsPagesLayoutEs extends TranslationsDocsPagesLayoutKo {
	_TranslationsDocsPagesLayoutEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Diseño';
	@override String get description => 'Configuración del diseño de la página';
	@override String get padding => 'Relleno';
	@override String get margin => 'Margen';
	@override String get center => 'Centro';
	@override String get gapped_column => 'Columna con espacio';
	@override String get gapped_row => 'Fila con espacio';
	@override String get separated_column => 'Columna separada';
	@override String get separated_row => 'Fila separada';
	@override String get basic_layout => 'Diseño básico';
}

// Path: docs.pages.web_preloader
class _TranslationsDocsPagesWebPreloaderEs extends TranslationsDocsPagesWebPreloaderKo {
	_TranslationsDocsPagesWebPreloaderEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Preloader web';
	@override String get description => 'Pantalla de carga web';
	@override String get step1_title => 'Crear Directorio Web';
	@override String get step1_content => 'Si no hay un directorio web, créalo.';
	@override String get step1_note => '* Si estás usando Flutter web legado, tendrás que actualizar usando el siguiente comando.';
	@override String get step1_button => 'Haz clic aquí para más información.';
	@override String get step2_title => 'Agregar Script';
	@override String get step2_content => 'A continuación, elige uno de los preloader predefinidos y cópialo:';
	@override String get step2_standard => 'Preloader estándar';
	@override String get step3_title => 'Pegar Script';
	@override String get step3_content_1 => 'Abre tu ';
	@override String get step3_content_2 => ' archivo y pega el script dentro de la ';
	@override String get step3_content_3 => ' etiqueta.';
	@override String get step3_example => 'Por ejemplo:';
	@override String get step4_title => 'Ejecutar la Aplicación';
	@override String get step4_content => 'Usa el siguiente comando para ejecutar la aplicación:';
	@override String get alert_title => 'Contribuciones';
	@override String get alert_content_1 => 'Si tienes un preloader que deseas compartir, crea un pull request en el directorio ';
	@override String get alert_button => 'web_loaders';
	@override String get alert_content_2 => '.';
}

// Path: docs.pages.components_list
class _TranslationsDocsPagesComponentsListEs extends TranslationsDocsPagesComponentsListKo {
	_TranslationsDocsPagesComponentsListEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Componentes';
	@override String get description => 'Lista de componentes reutilizables';
	@override String get work_in_progress => 'En progreso';
	@override String get animation => 'Animación';
	@override String get disclosure => 'Divulgación';
	@override String get feedback => 'Retroalimentación';
	@override String get forms => 'Formularios';
	@override String get layout => 'Diseño';
	@override String get navigation => 'Navegación';
	@override String get surfaces => 'Superficies';
	@override String get data_display => 'Visualización de datos';
	@override String get utilities => 'Utilidades';
}

// Path: docs.pages.icons
class _TranslationsDocsPagesIconsEs extends TranslationsDocsPagesIconsKo {
	_TranslationsDocsPagesIconsEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Íconos';
	@override String get description => 'Sistema de íconos';
	@override String get use_this_code => 'Usa el siguiente código para mostrar este ícono:';
	@override String get search_icons => 'Buscar íconos';
	@override String get radix_icons => 'Íconos de Radix';
	@override String get bootstrap_icons => 'Íconos de Bootstrap';
	@override String get lucide_icons => 'Íconos de Lucide';
}

// Path: docs.pages.colors
class _TranslationsDocsPagesColorsEs extends TranslationsDocsPagesColorsKo {
	_TranslationsDocsPagesColorsEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Colores';
	@override String get description => 'Paleta de colores';
	@override String get use_this_code => 'Usa el siguiente código para mostrar este color:';
	@override String get color_and_colorshades => 'Constantes de Color y ColorShades/ColorSwatch';
	@override String get predefined_colors => 'Colores predefinidos';
	@override String get generate_color => 'Generar color';
	@override String get hue_shift => 'Cambio de matiz';
	@override String get saturation_step_up => 'Aumento de saturación';
	@override String get saturation_step_down => 'Disminución de saturación';
	@override String get lightness_step_up => 'Aumento de claridad';
	@override String get lightness_step_down => 'Disminución de claridad';
	@override String get cancel => 'Cancelar';
	@override String get reset_options => 'Restablecer opciones';
	@override String get reset_confirmation => '¿Quieres restablecer las opciones?';
}

// Path: docs.pages.external
class _TranslationsDocsPagesExternalEs extends TranslationsDocsPagesExternalKo {
	_TranslationsDocsPagesExternalEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Material/Cupertino';
	@override String get description => 'Widgets básicos de Flutter';
}

// Path: docs.pages.state
class _TranslationsDocsPagesStateEs extends TranslationsDocsPagesStateKo {
	_TranslationsDocsPagesStateEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gestión del estado';
	@override String get description => 'Patrones de gestión del estado';
	@override String get intro_1 => 'En Flutter, todo es un widget, y donde se almacenan los datos también lo es.';
	@override String get intro_2 => 'Internamente, coui_flutter tiene su propio sistema de gestión de estado. Si ya estás utilizando un sistema de gestión de estado, puedes seguir usándolo junto con coui_flutter.';
	@override String get passing_data_to_children => 'Pasando datos a los hijos';
	@override String get passing_data_desc => 'Puedes pasar datos a los hijos utilizando el widget Data. Todos los cambios en los datos obligarán a los hijos a reconstruirse.';
	@override String get rebuild_difference_title => '¿Notaste la diferencia en la cantidad de reconstrucciones?';
	@override String get rebuild_difference_content => 'MostInnerWidget se reconstruye cuando los datos cambian, pero InnerWidget no. Esto es porque InnerWidget no recibe los datos.';
	@override String get setting_data_boundary => 'Estableciendo un límite de datos';
	@override String get setting_data_boundary_desc => 'Puedes establecer límites para que los hijos no accedan a los datos.';
	@override String get data_methods_vs => 'Data.maybeOf/Data.of vs Data.maybeFind/Data.find';
	@override String get data_methods_desc_1 => ' y ';
	@override String get data_methods_desc_2 => ' reciben datos y reconstruyen el widget cuando los datos cambian. En cambio, ';
	@override String get data_methods_desc_3 => ' no reciben datos, solo devuelven los datos.';
	@override String get data_find_usage => 'es bueno usar en lugares donde el método se llama solo una vez, como onPressed, onLongPressed, etc.';
	@override String get data_of_usage => 'es bueno para usar dentro del método build donde el widget debe reconstruirse cuando los datos cambian.';
	@override String get getting_data_from_child => 'Obteniendo datos de los hijos';
	@override String get getting_data_desc_1 => 'Puedes obtener datos de los hijos usando el método . Este método no recibe cambios en los datos.';
	@override String get getting_data_desc_2 => 'Si recibes datos de los hijos, puede ocurrir un bucle de reconstrucción infinita. Si necesitas recibir datos, muévete a un widget padre.';
	@override String get root_data_title => '¿Notaste los datos de la raíz?';
	@override String get root_data_content => 'Usa los datos del widget más interno a la izquierda. Esto es porque los padres solo pueden obtener datos del primer hijo conectado.';
	@override String get setting_messenger_boundary => 'Estableciendo un límite de DataMessenger';
	@override String get setting_messenger_boundary_desc => 'Puedes establecer límites para que los hijos no obtengan datos de un padre específico.';
	@override String get multidata_widget => 'Widget MultiData';
	@override String get multidata_desc => 'El widget MultiData te permite pasar múltiples datos a los hijos. Mira el siguiente ejemplo:';
	@override String get multidata_avoid_nesting => 'Puedes evitar la anidación usando el widget MultiData.';
	@override String get example => 'Ejemplo';
	@override String get passing_state_as_controller => 'Pasando el estado como controlador';
	@override String get passing_state_controller_desc => 'Puedes pasar el estado a los hijos como un controlador. Esto permitirá a los hijos llamar a los métodos del widget padre.';
	@override String get databuilder => 'DataBuilder';
	@override String get databuilder_desc => 'El widget DataBuilder te permite reconstruir el widget cuando los datos cambian. Esto evita tener que reconstruir todo el widget.';
	@override String get datanotifier => 'DataNotifier';
	@override String get datanotifier_desc => 'Con DataNotifier, puedes pasar valores a los hijos desde ValueListenable.';
	@override String get example_with_multidata => 'Ejemplo usando MultiData';
	@override String get passing_object_as_data => 'Pasando un objeto como datos';
	@override String get passing_object_desc => 'Hay algunas consideraciones cuando pasas objetos como datos:';
	@override String get override_equals_hashcode => '1. Sobrescribir == y hashCode';
	@override String get override_equals_desc => 'Se enviará una notificación a los hijos cuando el objeto anterior no sea igual al nuevo. Si no sobrescribes == y hashCode, siempre se considerará diferente cuando se instancie, incluso si los valores de los campos son iguales.';
	@override String get use_distinctdata => '2. Usar DistinctData';
	@override String get use_distinctdata_desc => 'DistinctData es un mixin que puede notificar a los hijos cuando se cambia un campo específico.';
	@override String get passing_mutable_object => '3. Pasando objetos mutables a los hijos';
	@override String get passing_mutable_object_desc => 'Es mejor pasar objetos inmutables a los hijos. Los objetos mutables (por ejemplo, List, Map, Set, Estado del Widget) no notificarán a los hijos cuando el objeto cambie porque la referencia del objeto no cambia.';
	@override String get passing_variable_to_children => 'Pasando variables a los hijos';
	@override String get passing_variable_desc => 'Puedes usar el widget Model para pasar variables a los hijos. Es similar al widget Data, pero es estricto en el tipo y etiquetado.';
	@override String get change_variable_from_children => 'Cambiar variable desde los hijos';
	@override String get change_variable_desc => 'Hay 2 formas de cambiar el valor del modelo desde los hijos:';
	@override String get modelnotifier => 'ModelNotifier';
	@override String get modelnotifier_desc => 'Con ModelNotifier, puedes pasar valores desde ValueNotifier a los hijos. No necesitas usar setState en el widget padre.';
	@override String get modellistenable => 'ModelListenable';
	@override String get modellistenable_desc => 'ModelListenable es un ModelNotifier de solo lectura. Los hijos solo pueden recibir valores. Si intentan cambiar valores, se producirá un error.';
	@override String get modelbuilder => 'ModelBuilder';
	@override String get modelbuilder_desc => 'El ModelBuilder recibe y reconstruye el widget cuando el valor cambia. Es similar al DataBuilder, pero estricto en el tipo y etiquetado.';
}

// Path: docs.components.accordion
class _TranslationsDocsComponentsAccordionEs extends TranslationsDocsComponentsAccordionKo {
	_TranslationsDocsComponentsAccordionEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Acordeón';
	@override String get description => 'Un acordeón es una lista de elementos apilados verticalmente. Cada elemento se puede \'expandir\' o \'colapsar\' para mostrar el contenido relacionado con ese elemento.';
	@override late final _TranslationsDocsComponentsAccordionExamplesEs examples = _TranslationsDocsComponentsAccordionExamplesEs._(_root);
}

// Path: docs.components.alert
class _TranslationsDocsComponentsAlertEs extends TranslationsDocsComponentsAlertKo {
	_TranslationsDocsComponentsAlertEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Alerta';
	@override String get description => 'Las alertas se utilizan para comunicar un estado que afecta al sistema.';
	@override late final _TranslationsDocsComponentsAlertExamplesEs examples = _TranslationsDocsComponentsAlertExamplesEs._(_root);
	@override String get title => 'Título de la alerta';
	@override String get content => 'Este es el contenido de la alerta.';
}

// Path: docs.components.alert_dialog
class _TranslationsDocsComponentsAlertDialogEs extends TranslationsDocsComponentsAlertDialogKo {
	_TranslationsDocsComponentsAlertDialogEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Diálogo de alerta';
	@override String get description => 'El diálogo de alerta muestra información importante que requiere la atención del usuario.';
	@override late final _TranslationsDocsComponentsAlertDialogExamplesEs examples = _TranslationsDocsComponentsAlertDialogExamplesEs._(_root);
	@override String get click_here => 'Haz clic aquí';
	@override String get alert_title => 'Título de la alerta';
	@override String get alert_content => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
}

// Path: docs.components.animated_value_builder
class _TranslationsDocsComponentsAnimatedValueBuilderEs extends TranslationsDocsComponentsAnimatedValueBuilderKo {
	_TranslationsDocsComponentsAnimatedValueBuilderEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Constructor de valores animados';
	@override String get description => 'Un constructor que aplica automáticamente animaciones al cambiar los valores.';
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderExamplesEs examples = _TranslationsDocsComponentsAnimatedValueBuilderExamplesEs._(_root);
}

// Path: docs.components.app_bar
class _TranslationsDocsComponentsAppBarEs extends TranslationsDocsComponentsAppBarKo {
	_TranslationsDocsComponentsAppBarEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barra de la aplicación';
	@override String get description => 'La barra de la aplicación es el elemento de navegación raíz que se muestra en la parte superior de la aplicación.';
	@override late final _TranslationsDocsComponentsAppBarExamplesEs examples = _TranslationsDocsComponentsAppBarExamplesEs._(_root);
}

// Path: docs.components.autocomplete
class _TranslationsDocsComponentsAutocompleteEs extends TranslationsDocsComponentsAutocompleteKo {
	_TranslationsDocsComponentsAutocompleteEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Autocompletar';
	@override String get description => 'Un campo de entrada que muestra sugerencias en función de la entrada del usuario.';
	@override late final _TranslationsDocsComponentsAutocompleteExamplesEs examples = _TranslationsDocsComponentsAutocompleteExamplesEs._(_root);
}

// Path: docs.components.avatar
class _TranslationsDocsComponentsAvatarEs extends TranslationsDocsComponentsAvatarKo {
	_TranslationsDocsComponentsAvatarEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Avatar';
	@override String get description => 'Una imagen o ícono que representa a un usuario o entidad.';
	@override late final _TranslationsDocsComponentsAvatarExamplesEs examples = _TranslationsDocsComponentsAvatarExamplesEs._(_root);
}

// Path: docs.components.avatar_group
class _TranslationsDocsComponentsAvatarGroupEs extends TranslationsDocsComponentsAvatarGroupKo {
	_TranslationsDocsComponentsAvatarGroupEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Grupo de avatares';
	@override String get description => 'Muestra varios avatares juntos.';
	@override late final _TranslationsDocsComponentsAvatarGroupExamplesEs examples = _TranslationsDocsComponentsAvatarGroupExamplesEs._(_root);
}

// Path: docs.components.badge
class _TranslationsDocsComponentsBadgeEs extends TranslationsDocsComponentsBadgeKo {
	_TranslationsDocsComponentsBadgeEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Insignia';
	@override String get description => 'Una pequeña etiqueta que muestra un estado o cuenta de las alertas.';
	@override late final _TranslationsDocsComponentsBadgeExamplesEs examples = _TranslationsDocsComponentsBadgeExamplesEs._(_root);
	@override String get primary => 'Primario';
	@override String get secondary => 'Secundario';
	@override String get outline => 'Contorno';
	@override String get destructive => 'Destructivo';
}

// Path: docs.components.breadcrumb
class _TranslationsDocsComponentsBreadcrumbEs extends TranslationsDocsComponentsBreadcrumbKo {
	_TranslationsDocsComponentsBreadcrumbEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Pan migas';
	@override String get description => 'Las migas de pan son una forma de navegación adicional que muestra la ubicación del usuario en un sitio web o aplicación web.';
	@override late final _TranslationsDocsComponentsBreadcrumbExamplesEs examples = _TranslationsDocsComponentsBreadcrumbExamplesEs._(_root);
	@override String get home => 'Inicio';
	@override String get components => 'Componentes';
}

// Path: docs.components.button
class _TranslationsDocsComponentsButtonEs extends TranslationsDocsComponentsButtonKo {
	_TranslationsDocsComponentsButtonEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Botón';
	@override String get description => 'Los botones permiten a los usuarios realizar acciones y selecciones con un solo toque.';
	@override late final _TranslationsDocsComponentsButtonExamplesEs examples = _TranslationsDocsComponentsButtonExamplesEs._(_root);
	@override String get primary => 'Primario';
	@override String get secondary => 'Secundario';
	@override String get outlined => 'Contorneado';
	@override String get ghost => 'Fantasma';
	@override String get destructive => 'Destructivo';
	@override String get link => 'Enlace';
	@override String get outline => 'Contorno';
	@override String get text => 'Texto';
	@override String get extra_small => 'Extra pequeño';
	@override String get small => 'Pequeño';
	@override String get normal => 'Normal';
	@override String get large => 'Grande';
	@override String get extra_large => 'Extra grande';
	@override String get save => 'Guardar';
	@override String get cancel => 'Cancelar';
	@override String get close => 'Cerrar';
	@override String get submit => 'Enviar';
	@override String get edit_profile => 'Modificar perfil';
	@override String get save_changes => 'Guardar cambios';
	@override String get undo => 'Deshacer';
	@override String get compact => 'Compacto';
	@override String get dense => 'Denso';
	@override String get comfortable => 'Confortable';
	@override String get icon => 'Ícono';
	@override String get icon_comfortable => 'Ícono Confortable';
	@override String get rectangle => 'Rectángulo';
	@override String get add => 'Agregar';
	@override String get focused => 'Enfocado';
	@override String get hovered => 'Sobrevolando';
	@override String get pressed => 'Presionado';
	@override String get text_button => 'Botón de texto';
	@override String get custom_button => 'Botón personalizado';
}

// Path: docs.components.calendar
class _TranslationsDocsComponentsCalendarEs extends TranslationsDocsComponentsCalendarKo {
	_TranslationsDocsComponentsCalendarEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Calendario';
	@override String get description => 'Componente de calendario para seleccionar y mostrar fechas.';
	@override late final _TranslationsDocsComponentsCalendarExamplesEs examples = _TranslationsDocsComponentsCalendarExamplesEs._(_root);
}

// Path: docs.components.card
class _TranslationsDocsComponentsCardEs extends TranslationsDocsComponentsCardKo {
	_TranslationsDocsComponentsCardEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tarjeta';
	@override String get description => 'Descripción';
	@override late final _TranslationsDocsComponentsCardExamplesEs examples = _TranslationsDocsComponentsCardExamplesEs._(_root);
	@override String get create_project => 'Crear proyecto';
	@override String get deploy_description => 'Despliega un nuevo proyecto con un clic';
	@override String get name => 'Nombre';
	@override String get name_placeholder => 'Nombre del proyecto';
	@override String get description_placeholder => 'Descripción del proyecto';
	@override String get deploy => 'Desplegar';
}

// Path: docs.components.card_image
class _TranslationsDocsComponentsCardImageEs extends TranslationsDocsComponentsCardImageKo {
	_TranslationsDocsComponentsCardImageEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tarjeta de imagen';
	@override String get description => 'Componente de tarjeta que incluye una imagen.';
	@override late final _TranslationsDocsComponentsCardImageExamplesEs examples = _TranslationsDocsComponentsCardImageExamplesEs._(_root);
	@override String get card_image_title => 'Imagen de la tarjeta';
	@override String get card_clicked => 'Has hecho clic en la imagen de la tarjeta';
	@override String card_number({required Object n}) => 'Número de tarjeta ${n}';
	@override String get lorem_ipsum => 'Lorem ipsum dolor sit amet';
}

// Path: docs.components.carousel
class _TranslationsDocsComponentsCarouselEs extends TranslationsDocsComponentsCarouselKo {
	_TranslationsDocsComponentsCarouselEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Carrusel';
	@override String get description => 'Un componente que muestra varios elementos en un deslizador.';
	@override late final _TranslationsDocsComponentsCarouselExamplesEs examples = _TranslationsDocsComponentsCarouselExamplesEs._(_root);
}

// Path: docs.components.checkbox
class _TranslationsDocsComponentsCheckboxEs extends TranslationsDocsComponentsCheckboxKo {
	_TranslationsDocsComponentsCheckboxEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Casilla de verificación';
	@override String get description => 'Las casillas de verificación permiten a los usuarios seleccionar uno o más elementos de una lista.';
	@override late final _TranslationsDocsComponentsCheckboxExamplesEs examples = _TranslationsDocsComponentsCheckboxExamplesEs._(_root);
	@override String get remember_me => 'Recuérdame';
}

// Path: docs.components.chip
class _TranslationsDocsComponentsChipEs extends TranslationsDocsComponentsChipKo {
	_TranslationsDocsComponentsChipEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Chip';
	@override String get description => 'Un chip es un pequeño elemento que representa una propiedad, opción o acción.';
	@override late final _TranslationsDocsComponentsChipExamplesEs examples = _TranslationsDocsComponentsChipExamplesEs._(_root);
	@override String get apple => 'Manzana';
	@override String get banana => 'Plátano';
	@override String get cherry => 'Cereza';
	@override String get durian => 'Durian';
	@override String get elderberry => 'Baya de saúco';
}

// Path: docs.components.chip_input
class _TranslationsDocsComponentsChipInputEs extends TranslationsDocsComponentsChipInputKo {
	_TranslationsDocsComponentsChipInputEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrada de chips';
	@override String get description => 'Un campo de entrada que permite ingresar varios valores en forma de chips.';
	@override late final _TranslationsDocsComponentsChipInputExamplesEs examples = _TranslationsDocsComponentsChipInputExamplesEs._(_root);
}

// Path: docs.components.circular_progress
class _TranslationsDocsComponentsCircularProgressEs extends TranslationsDocsComponentsCircularProgressKo {
	_TranslationsDocsComponentsCircularProgressEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Progreso circular';
	@override String get description => 'Un indicador de progreso circular.';
	@override late final _TranslationsDocsComponentsCircularProgressExamplesEs examples = _TranslationsDocsComponentsCircularProgressExamplesEs._(_root);
	@override String get increase_by_10 => 'Aumentar en 10';
	@override String get decrease_by_10 => 'Disminuir en 10';
}

// Path: docs.components.code_snippet
class _TranslationsDocsComponentsCodeSnippetEs extends TranslationsDocsComponentsCodeSnippetKo {
	_TranslationsDocsComponentsCodeSnippetEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Fragmento de código';
	@override String get description => 'Un componente para mostrar código.';
	@override late final _TranslationsDocsComponentsCodeSnippetExamplesEs examples = _TranslationsDocsComponentsCodeSnippetExamplesEs._(_root);
}

// Path: docs.components.collapsible
class _TranslationsDocsComponentsCollapsibleEs extends TranslationsDocsComponentsCollapsibleKo {
	_TranslationsDocsComponentsCollapsibleEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Colapsable';
	@override String get description => 'Un contenedor de contenido que se puede colapsar o expandir.';
	@override late final _TranslationsDocsComponentsCollapsibleExamplesEs examples = _TranslationsDocsComponentsCollapsibleExamplesEs._(_root);
	@override String get starred_repositories => '@coco-de ha dasto estrella a 3 repositorios';
	@override String get collapse_all => 'Colapsar todo';
	@override String get expand_all => 'Expandir todo';
	@override String get expand_icon => 'Icono de expansión';
	@override String get use_path_branch => 'Usar camino de ramificación';
	@override String get recursive_selection => 'Selección recursiva';
}

// Path: docs.components.color_picker
class _TranslationsDocsComponentsColorPickerEs extends TranslationsDocsComponentsColorPickerKo {
	_TranslationsDocsComponentsColorPickerEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Selector de color';
	@override String get description => 'Un componente para seleccionar colores.';
	@override late final _TranslationsDocsComponentsColorPickerExamplesEs examples = _TranslationsDocsComponentsColorPickerExamplesEs._(_root);
	@override String get pick_color => 'Seleccionar color';
	@override String color_label({required Object color}) => 'Color: ${color}';
	@override String get select_color => 'Seleccionar color';
	@override String get open_color_picker_popover => 'Abrir popover del selector de color';
	@override String get open_color_picker_dialog => 'Abrir diálogo del selector de color';
}

// Path: docs.components.command
class _TranslationsDocsComponentsCommandEs extends TranslationsDocsComponentsCommandKo {
	_TranslationsDocsComponentsCommandEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Comando';
	@override String get description => 'Un componente que permite buscar elementos.';
	@override late final _TranslationsDocsComponentsCommandExamplesEs examples = _TranslationsDocsComponentsCommandExamplesEs._(_root);
}

// Path: docs.components.context_menu
class _TranslationsDocsComponentsContextMenuEs extends TranslationsDocsComponentsContextMenuKo {
	_TranslationsDocsComponentsContextMenuEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Menú contextual';
	@override String get description => 'Un menú que aparece con clic derecho o toque prolongado.';
	@override late final _TranslationsDocsComponentsContextMenuExamplesEs examples = _TranslationsDocsComponentsContextMenuExamplesEs._(_root);
}

// Path: docs.components.date_picker
class _TranslationsDocsComponentsDatePickerEs extends TranslationsDocsComponentsDatePickerKo {
	_TranslationsDocsComponentsDatePickerEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Selector de fecha';
	@override String get description => 'Campo de entrada para seleccionar fechas.';
	@override late final _TranslationsDocsComponentsDatePickerExamplesEs examples = _TranslationsDocsComponentsDatePickerExamplesEs._(_root);
	@override String get select_date => 'Seleccionar fecha';
	@override String get select_date_range => 'Seleccionar rango de fechas';
}

// Path: docs.components.dialog
class _TranslationsDocsComponentsDialogEs extends TranslationsDocsComponentsDialogKo {
	_TranslationsDocsComponentsDialogEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Diálogo';
	@override String get description => 'El diálogo es una ventana modal que aparece sobre el resto de la aplicación.';
	@override late final _TranslationsDocsComponentsDialogExamplesEs examples = _TranslationsDocsComponentsDialogExamplesEs._(_root);
	@override String get edit_profile_title => 'Modificar perfil';
	@override String get edit_profile_description => 'Cambia aquí tu perfil. Haz clic en guardar una vez que hayas terminado.';
	@override String get name_label => 'Nombre';
	@override String get username_label => 'Nombre de usuario';
	@override String get hello => '¡Hola!';
	@override String get material_dialog_content => 'Este es un diálogo Material.';
	@override String get cupertino_dialog_content => 'Este es un diálogo Cupertino.';
	@override String get alert_title => 'Título de la alerta';
	@override String get click_here => 'Haz clic aquí';
	@override String get ok => 'Ok';
	@override String get open_material_dialog => 'Abrir diálogo Material';
	@override String get open_cupertino_dialog => 'Abrir diálogo Cupertino';
	@override String get open_coui_dialog => 'Abrir diálogo COUI';
}

// Path: docs.components.divider
class _TranslationsDocsComponentsDividerEs extends TranslationsDocsComponentsDividerKo {
	_TranslationsDocsComponentsDividerEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Divisor';
	@override String get description => 'Una línea que visualmente separa el contenido.';
	@override late final _TranslationsDocsComponentsDividerExamplesEs examples = _TranslationsDocsComponentsDividerExamplesEs._(_root);
	@override String get item_1 => 'Elemento 1';
	@override String get item_2 => 'Elemento 2';
	@override String get item_3 => 'Elemento 3';
	@override String get divider => 'Divisor';
}

// Path: docs.components.dot_indicator
class _TranslationsDocsComponentsDotIndicatorEs extends TranslationsDocsComponentsDotIndicatorKo {
	_TranslationsDocsComponentsDotIndicatorEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Indicador de punto';
	@override String get description => 'Un indicador que muestra la posición actual con un punto.';
	@override late final _TranslationsDocsComponentsDotIndicatorExamplesEs examples = _TranslationsDocsComponentsDotIndicatorExamplesEs._(_root);
}

// Path: docs.components.drawer
class _TranslationsDocsComponentsDrawerEs extends TranslationsDocsComponentsDrawerKo {
	_TranslationsDocsComponentsDrawerEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Cajón';
	@override String get description => 'Un panel que se desliza desde el borde de la pantalla.';
	@override late final _TranslationsDocsComponentsDrawerExamplesEs examples = _TranslationsDocsComponentsDrawerExamplesEs._(_root);
	@override String get open_drawer => 'Abrir cajón';
	@override String get close_drawer => 'Cerrar cajón';
	@override String get open_another_drawer => 'Abrir otro cajón';
	@override String drawer_at({required Object count, required Object position}) => 'Cajón ${count} en ${position}';
}

// Path: docs.components.dropdown_menu
class _TranslationsDocsComponentsDropdownMenuEs extends TranslationsDocsComponentsDropdownMenuKo {
	_TranslationsDocsComponentsDropdownMenuEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Menú desplegable';
	@override String get description => 'Un menú que muestra una lista de opciones seleccionables.';
	@override late final _TranslationsDocsComponentsDropdownMenuExamplesEs examples = _TranslationsDocsComponentsDropdownMenuExamplesEs._(_root);
}

// Path: docs.components.expandable_sidebar
class _TranslationsDocsComponentsExpandableSidebarEs extends TranslationsDocsComponentsExpandableSidebarKo {
	_TranslationsDocsComponentsExpandableSidebarEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barra lateral expandible';
	@override String get description => 'Una barra lateral que se puede expandir y colapsar.';
	@override late final _TranslationsDocsComponentsExpandableSidebarExamplesEs examples = _TranslationsDocsComponentsExpandableSidebarExamplesEs._(_root);
}

// Path: docs.components.form
class _TranslationsDocsComponentsFormEs extends TranslationsDocsComponentsFormKo {
	_TranslationsDocsComponentsFormEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Formulario';
	@override String get description => 'Un widget helper para hacer la validación de formularios fácilmente.';
	@override late final _TranslationsDocsComponentsFormExamplesEs examples = _TranslationsDocsComponentsFormExamplesEs._(_root);
	@override String get username_label => 'Nombre de usuario';
	@override String get username_hint => 'Nombre que se mostrará públicamente';
	@override String get password_label => 'Contraseña';
	@override String get confirm_password_label => 'Confirmar contraseña';
	@override String get passwords_do_not_match => 'Las contraseñas no coinciden';
	@override String get agree_terms => 'Acepto los términos y condiciones';
	@override String get must_agree_terms => 'Debes aceptar los términos y condiciones';
	@override String get form_values_title => 'Valores de formulario';
	@override String get register => 'Registrar';
	@override String get username_already_taken => 'El nombre de usuario ya está en uso.';
	@override String get email => 'Correo electrónico';
	@override String username_display({required Object value}) => 'Nombre de usuario: ${value}';
	@override String password_display({required Object value}) => 'Contraseña: ${value}';
	@override String confirm_password_display({required Object value}) => 'Confirmar contraseña: ${value}';
	@override String agree_display({required Object value}) => 'Acepto: ${value}';
	@override String json_display({required Object value}) => 'JSON: ${value}';
	@override String submitted_value_display({required Object value}) => 'Valor enviado: ${value}';
	@override String get login => 'Iniciar sesión';
	@override String get sign_up => 'Registrarse';
	@override String get dont_have_account => '¿No tienes cuenta? ';
	@override String get already_have_account => '¿Ya tienes una cuenta? ';
}

// Path: docs.components.formatted_input
class _TranslationsDocsComponentsFormattedInputEs extends TranslationsDocsComponentsFormattedInputKo {
	_TranslationsDocsComponentsFormattedInputEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrada formateada';
	@override String get description => 'Campo de texto que se ajusta a un formato específico.';
	@override late final _TranslationsDocsComponentsFormattedInputExamplesEs examples = _TranslationsDocsComponentsFormattedInputExamplesEs._(_root);
}

// Path: docs.components.hover_card
class _TranslationsDocsComponentsHoverCardEs extends TranslationsDocsComponentsHoverCardKo {
	_TranslationsDocsComponentsHoverCardEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tarjeta de hover';
	@override String get description => 'Tarjeta que se muestra al pasar el cursor.';
	@override late final _TranslationsDocsComponentsHoverCardExamplesEs examples = _TranslationsDocsComponentsHoverCardExamplesEs._(_root);
	@override String get flutter_handle => '@flutter';
	@override String get flutter_username => 'Flutter';
	@override String get flutter_description => 'El SDK de Flutter proporciona herramientas para construir hermosas aplicaciones para móvil, web y escritorio desde una sola base de código.';
}

// Path: docs.components.input
class _TranslationsDocsComponentsInputEs extends TranslationsDocsComponentsInputKo {
	_TranslationsDocsComponentsInputEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrada';
	@override String get description => 'Campo de entrada de texto.';
	@override late final _TranslationsDocsComponentsInputExamplesEs examples = _TranslationsDocsComponentsInputExamplesEs._(_root);
	@override String get enter_name => 'Introduce tu nombre';
	@override String get enter_username => 'Introduce tu nombre de usuario';
	@override String get username_already_taken => 'El nombre de usuario ya está en uso.';
	@override String get hello_world => '¡Hola Mundo!';
	@override String get search_something => 'Buscar algo...';
	@override String get email => 'Correo electrónico';
	@override String get password => 'Introduce tu contraseña';
	@override String get username_hint => 'Esto es para tu nombre de usuario';
}

// Path: docs.components.input_otp
class _TranslationsDocsComponentsInputOtpEs extends TranslationsDocsComponentsInputOtpKo {
	_TranslationsDocsComponentsInputOtpEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrada OTP';
	@override String get description => 'Campo para ingresar un código de un solo uso.';
	@override late final _TranslationsDocsComponentsInputOtpExamplesEs examples = _TranslationsDocsComponentsInputOtpExamplesEs._(_root);
}

// Path: docs.components.item_picker
class _TranslationsDocsComponentsItemPickerEs extends TranslationsDocsComponentsItemPickerKo {
	_TranslationsDocsComponentsItemPickerEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Selector de ítems';
	@override String get description => 'Componente para seleccionar un ítem de una lista.';
	@override late final _TranslationsDocsComponentsItemPickerExamplesEs examples = _TranslationsDocsComponentsItemPickerExamplesEs._(_root);
}

// Path: docs.components.keyboard_display
class _TranslationsDocsComponentsKeyboardDisplayEs extends TranslationsDocsComponentsKeyboardDisplayKo {
	_TranslationsDocsComponentsKeyboardDisplayEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Display de teclado';
	@override String get description => 'Componente que muestra atajos de teclado.';
	@override late final _TranslationsDocsComponentsKeyboardDisplayExamplesEs examples = _TranslationsDocsComponentsKeyboardDisplayExamplesEs._(_root);
}

// Path: docs.components.linear_progress
class _TranslationsDocsComponentsLinearProgressEs extends TranslationsDocsComponentsLinearProgressKo {
	_TranslationsDocsComponentsLinearProgressEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Progreso lineal';
	@override String get description => 'Un indicador de progreso lineal.';
	@override late final _TranslationsDocsComponentsLinearProgressExamplesEs examples = _TranslationsDocsComponentsLinearProgressExamplesEs._(_root);
	@override String get increase => 'Aumentar';
	@override String get decrease => 'Disminuir';
}

// Path: docs.components.material
class _TranslationsDocsComponentsMaterialEs extends TranslationsDocsComponentsMaterialKo {
	_TranslationsDocsComponentsMaterialEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Material/Cupertino';
	@override String get description => 'Cómo usar los widgets básicos Material y Cupertino en Flutter.';
	@override late final _TranslationsDocsComponentsMaterialExamplesEs examples = _TranslationsDocsComponentsMaterialExamplesEs._(_root);
	@override String get my_material_app => 'Mi aplicación Material';
	@override String get my_cupertino_app => 'Mi aplicación Cupertino';
	@override String you_pushed_button({required Object count}) => 'Has pulsado el botón ${count} veces';
	@override String get open_material_dialog => 'Abrir diálogo Material';
	@override String get open_cupertino_dialog => 'Abrir diálogo Cupertino';
	@override String get open_coui_dialog => 'Abrir diálogo COUI';
}

// Path: docs.components.menubar
class _TranslationsDocsComponentsMenubarEs extends TranslationsDocsComponentsMenubarKo {
	_TranslationsDocsComponentsMenubarEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barra de menú';
	@override String get description => 'Barra de menú horizontal.';
	@override late final _TranslationsDocsComponentsMenubarExamplesEs examples = _TranslationsDocsComponentsMenubarExamplesEs._(_root);
	@override String get file => 'Archivo';
	@override String get edit => 'Editar';
	@override String get new_tab => 'Nueva pestaña';
	@override String get new_window => 'Nueva ventana';
	@override String get new_incognito_window => 'Nueva ventana en modo incógnito';
	@override String get email_link => 'Enlace de correo electrónico';
	@override String get messages => 'Mensajes';
	@override String get notes => 'Notas';
	@override String get share => 'Compartir';
	@override String get print => 'Imprimir';
	@override String get save_and_exit => 'Guardar y salir';
	@override String get discard_and_exit => 'Descartar y salir';
	@override String get exit => 'Salir';
	@override String get undo => 'Deshacer';
	@override String get redo => 'Rehacer';
}

// Path: docs.components.multiselect
class _TranslationsDocsComponentsMultiselectEs extends TranslationsDocsComponentsMultiselectKo {
	_TranslationsDocsComponentsMultiselectEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Selección múltiple';
	@override String get description => 'Componente que permite seleccionar varios ítems.';
	@override late final _TranslationsDocsComponentsMultiselectExamplesEs examples = _TranslationsDocsComponentsMultiselectExamplesEs._(_root);
}

// Path: docs.components.navigation_bar
class _TranslationsDocsComponentsNavigationBarEs extends TranslationsDocsComponentsNavigationBarKo {
	_TranslationsDocsComponentsNavigationBarEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barra de navegación';
	@override String get description => 'Barra de navegación inferior.';
	@override late final _TranslationsDocsComponentsNavigationBarExamplesEs examples = _TranslationsDocsComponentsNavigationBarExamplesEs._(_root);
}

// Path: docs.components.navigation_menu
class _TranslationsDocsComponentsNavigationMenuEs extends TranslationsDocsComponentsNavigationMenuKo {
	_TranslationsDocsComponentsNavigationMenuEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Menú de navegación';
	@override String get description => 'Componente de menú de navegación.';
	@override late final _TranslationsDocsComponentsNavigationMenuExamplesEs examples = _TranslationsDocsComponentsNavigationMenuExamplesEs._(_root);
}

// Path: docs.components.navigation_rail
class _TranslationsDocsComponentsNavigationRailEs extends TranslationsDocsComponentsNavigationRailKo {
	_TranslationsDocsComponentsNavigationRailEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Riel de navegación';
	@override String get description => 'Riel de navegación lateral.';
	@override late final _TranslationsDocsComponentsNavigationRailExamplesEs examples = _TranslationsDocsComponentsNavigationRailExamplesEs._(_root);
}

// Path: docs.components.navigation_sidebar
class _TranslationsDocsComponentsNavigationSidebarEs extends TranslationsDocsComponentsNavigationSidebarKo {
	_TranslationsDocsComponentsNavigationSidebarEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barra lateral de navegación';
	@override String get description => 'Componente de la barra lateral de navegación.';
	@override late final _TranslationsDocsComponentsNavigationSidebarExamplesEs examples = _TranslationsDocsComponentsNavigationSidebarExamplesEs._(_root);
}

// Path: docs.components.number_input
class _TranslationsDocsComponentsNumberInputEs extends TranslationsDocsComponentsNumberInputKo {
	_TranslationsDocsComponentsNumberInputEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrada numérica';
	@override String get description => 'Campo para ingresar números.';
	@override late final _TranslationsDocsComponentsNumberInputExamplesEs examples = _TranslationsDocsComponentsNumberInputExamplesEs._(_root);
	@override String value({required Object value}) => 'Valor: ${value}';
}

// Path: docs.components.number_ticker
class _TranslationsDocsComponentsNumberTickerEs extends TranslationsDocsComponentsNumberTickerKo {
	_TranslationsDocsComponentsNumberTickerEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Ticker numérico';
	@override String get description => 'Muestra una animación cuando el número cambia.';
	@override late final _TranslationsDocsComponentsNumberTickerExamplesEs examples = _TranslationsDocsComponentsNumberTickerExamplesEs._(_root);
}

// Path: docs.components.overflow_marquee
class _TranslationsDocsComponentsOverflowMarqueeEs extends TranslationsDocsComponentsOverflowMarqueeKo {
	_TranslationsDocsComponentsOverflowMarqueeEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Marquee desbordante';
	@override String get description => 'Se desplaza automáticamente cuando el texto desborda.';
	@override late final _TranslationsDocsComponentsOverflowMarqueeExamplesEs examples = _TranslationsDocsComponentsOverflowMarqueeExamplesEs._(_root);
}

// Path: docs.components.pagination
class _TranslationsDocsComponentsPaginationEs extends TranslationsDocsComponentsPaginationKo {
	_TranslationsDocsComponentsPaginationEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Paginación';
	@override String get description => 'Componente para navegar entre páginas.';
	@override late final _TranslationsDocsComponentsPaginationExamplesEs examples = _TranslationsDocsComponentsPaginationExamplesEs._(_root);
}

// Path: docs.components.phone_input
class _TranslationsDocsComponentsPhoneInputEs extends TranslationsDocsComponentsPhoneInputKo {
	_TranslationsDocsComponentsPhoneInputEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrada de teléfono';
	@override String get description => 'Campo para ingresar un número de teléfono.';
	@override late final _TranslationsDocsComponentsPhoneInputExamplesEs examples = _TranslationsDocsComponentsPhoneInputExamplesEs._(_root);
}

// Path: docs.components.popover
class _TranslationsDocsComponentsPopoverEs extends TranslationsDocsComponentsPopoverKo {
	_TranslationsDocsComponentsPopoverEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Popover';
	@override String get description => 'Un popup que aparece sobre un elemento.';
	@override late final _TranslationsDocsComponentsPopoverExamplesEs examples = _TranslationsDocsComponentsPopoverExamplesEs._(_root);
	@override String get dimensions => 'Tamaño';
	@override String get set_dimensions => 'Establecer tamaño de la capa';
	@override String get width => 'Ancho';
	@override String get max_width => 'Ancho máximo';
	@override String get height => 'Altura';
	@override String get max_height => 'Altura máxima';
	@override String get open_popover => 'Abrir popover';
	@override String get submit => 'Enviar';
}

// Path: docs.components.progress
class _TranslationsDocsComponentsProgressEs extends TranslationsDocsComponentsProgressKo {
	_TranslationsDocsComponentsProgressEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Progreso';
	@override String get description => 'Muestra el estado del progreso.';
	@override late final _TranslationsDocsComponentsProgressExamplesEs examples = _TranslationsDocsComponentsProgressExamplesEs._(_root);
}

// Path: docs.components.radio_card
class _TranslationsDocsComponentsRadioCardEs extends TranslationsDocsComponentsRadioCardKo {
	_TranslationsDocsComponentsRadioCardEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tarjeta de radio';
	@override String get description => 'Botón de radio en forma de tarjeta.';
	@override late final _TranslationsDocsComponentsRadioCardExamplesEs examples = _TranslationsDocsComponentsRadioCardExamplesEs._(_root);
}

// Path: docs.components.radio_group
class _TranslationsDocsComponentsRadioGroupEs extends TranslationsDocsComponentsRadioGroupKo {
	_TranslationsDocsComponentsRadioGroupEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Grupo de radio';
	@override String get description => 'Grupo de botones de radio.';
	@override late final _TranslationsDocsComponentsRadioGroupExamplesEs examples = _TranslationsDocsComponentsRadioGroupExamplesEs._(_root);
	@override String get option_1 => 'Opción 1';
	@override String get option_2 => 'Opción 2';
	@override String get option_3 => 'Opción 3';
	@override String get selected => 'Seleccionado';
}

// Path: docs.components.refresh_trigger
class _TranslationsDocsComponentsRefreshTriggerEs extends TranslationsDocsComponentsRefreshTriggerKo {
	_TranslationsDocsComponentsRefreshTriggerEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Disparador de actualización';
	@override String get description => 'Proporciona la función de refrescar al arrastrar.';
	@override late final _TranslationsDocsComponentsRefreshTriggerExamplesEs examples = _TranslationsDocsComponentsRefreshTriggerExamplesEs._(_root);
	@override String get pull_me => 'Tira de mí';
	@override String get refresh => 'Actualizar';
}

// Path: docs.components.repeated_animation_builder
class _TranslationsDocsComponentsRepeatedAnimationBuilderEs extends TranslationsDocsComponentsRepeatedAnimationBuilderKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Constructor de animación repetida';
	@override String get description => 'Constructor que repite animaciones.';
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesEs examples = _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesEs._(_root);
}

// Path: docs.components.resizable
class _TranslationsDocsComponentsResizableEs extends TranslationsDocsComponentsResizableKo {
	_TranslationsDocsComponentsResizableEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Redimensionable';
	@override String get description => 'Un contenedor que se puede redimensionar.';
	@override late final _TranslationsDocsComponentsResizableExamplesEs examples = _TranslationsDocsComponentsResizableExamplesEs._(_root);
}

// Path: docs.components.scaffold
class _TranslationsDocsComponentsScaffoldEs extends TranslationsDocsComponentsScaffoldKo {
	_TranslationsDocsComponentsScaffoldEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Escaffold';
	@override String get description => 'El escaffold es el contenedor superior de la página.';
	@override late final _TranslationsDocsComponentsScaffoldExamplesEs examples = _TranslationsDocsComponentsScaffoldExamplesEs._(_root);
}

// Path: docs.components.select
class _TranslationsDocsComponentsSelectEs extends TranslationsDocsComponentsSelectKo {
	_TranslationsDocsComponentsSelectEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Seleccionar';
	@override String get description => 'Permite seleccionar un ítem de una lista de opciones.';
	@override late final _TranslationsDocsComponentsSelectExamplesEs examples = _TranslationsDocsComponentsSelectExamplesEs._(_root);
	@override String get placeholder => 'Selecciona una fruta';
	@override String get search_fruit => 'Buscar fruta';
	@override String get no_fruit_found => 'No se encontró ninguna fruta';
	@override String get apple => 'Manzana';
	@override String get banana => 'Plátano';
	@override String get cherry => 'Cereza';
	@override String get lemon => 'Limón';
	@override String get tomato => 'Tomate';
	@override String get red_apple => 'Manzana roja';
	@override String get green_apple => 'Manzana verde';
	@override String get yellow_banana => 'Plátano amarillo';
	@override String get brown_banana => 'Plátano marrón';
	@override String get yellow_lemon => 'Limón amarillo';
	@override String get green_lemon => 'Limón verde';
	@override String get red => 'Rojo';
	@override String get green => 'Verde';
	@override String get yellow => 'Amarillo';
	@override String get brown => 'Marrón';
}

// Path: docs.components.sheet
class _TranslationsDocsComponentsSheetEs extends TranslationsDocsComponentsSheetKo {
	_TranslationsDocsComponentsSheetEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Hoja';
	@override String get description => 'Hoja que aparece desde la parte inferior.';
	@override late final _TranslationsDocsComponentsSheetExamplesEs examples = _TranslationsDocsComponentsSheetExamplesEs._(_root);
}

// Path: docs.components.skeleton
class _TranslationsDocsComponentsSkeletonEs extends TranslationsDocsComponentsSkeletonKo {
	_TranslationsDocsComponentsSkeletonEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Esqueleto';
	@override String get description => 'Pantalla de esqueleto que se muestra mientras se carga.';
	@override late final _TranslationsDocsComponentsSkeletonExamplesEs examples = _TranslationsDocsComponentsSkeletonExamplesEs._(_root);
}

// Path: docs.components.slider
class _TranslationsDocsComponentsSliderEs extends TranslationsDocsComponentsSliderKo {
	_TranslationsDocsComponentsSliderEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Deslizador';
	@override String get description => 'Permite seleccionar un valor deslizando.';
	@override late final _TranslationsDocsComponentsSliderExamplesEs examples = _TranslationsDocsComponentsSliderExamplesEs._(_root);
	@override String value_single({required Object value}) => 'Valor: ${value}';
	@override String value_range({required Object start, required Object end}) => 'Valor: ${start} - ${end}';
}

// Path: docs.components.sortable
class _TranslationsDocsComponentsSortableEs extends TranslationsDocsComponentsSortableKo {
	_TranslationsDocsComponentsSortableEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Ordenable';
	@override String get description => 'Permite arrastrar para ordenar los ítems.';
	@override late final _TranslationsDocsComponentsSortableExamplesEs examples = _TranslationsDocsComponentsSortableExamplesEs._(_root);
}

// Path: docs.components.star_rating
class _TranslationsDocsComponentsStarRatingEs extends TranslationsDocsComponentsStarRatingKo {
	_TranslationsDocsComponentsStarRatingEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Calificación estelar';
	@override String get description => 'Permite seleccionar una calificación estelar.';
	@override late final _TranslationsDocsComponentsStarRatingExamplesEs examples = _TranslationsDocsComponentsStarRatingExamplesEs._(_root);
}

// Path: docs.components.stepper
class _TranslationsDocsComponentsStepperEs extends TranslationsDocsComponentsStepperKo {
	_TranslationsDocsComponentsStepperEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Stepper';
	@override String get description => 'Muestra un proceso en pasos.';
	@override late final _TranslationsDocsComponentsStepperExamplesEs examples = _TranslationsDocsComponentsStepperExamplesEs._(_root);
	@override String get step_1 => 'Paso 1';
	@override String get step_2 => 'Paso 2';
	@override String get step_3 => 'Paso 3';
	@override String step_n({required Object n}) => 'Paso ${n}';
	@override String get optional_step => 'Paso opcional';
	@override String get horizontal => 'Horizontal';
	@override String get vertical => 'Vertical';
	@override String get toggle_error => 'Alternar error';
	@override String get circle => 'Círculo';
	@override String get circle_alt => 'Círculo alternativo';
	@override String get line => 'Línea';
	@override String get small => 'Pequeño';
	@override String get medium => 'Medio';
	@override String get large => 'Grande';
}

// Path: docs.components.steps
class _TranslationsDocsComponentsStepsEs extends TranslationsDocsComponentsStepsKo {
	_TranslationsDocsComponentsStepsEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Pasos';
	@override String get description => 'Muestra el progreso en pasos.';
	@override late final _TranslationsDocsComponentsStepsExamplesEs examples = _TranslationsDocsComponentsStepsExamplesEs._(_root);
}

// Path: docs.components.swiper
class _TranslationsDocsComponentsSwiperEs extends TranslationsDocsComponentsSwiperKo {
	_TranslationsDocsComponentsSwiperEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Swiper';
	@override String get description => 'Componente que permite deslizar.';
	@override late final _TranslationsDocsComponentsSwiperExamplesEs examples = _TranslationsDocsComponentsSwiperExamplesEs._(_root);
}

// Path: docs.components.k_switch
class _TranslationsDocsComponentsKSwitchEs extends TranslationsDocsComponentsKSwitchKo {
	_TranslationsDocsComponentsKSwitchEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Interruptor';
	@override String get description => 'Interruptor de encendido/apagado.';
	@override late final _TranslationsDocsComponentsKSwitchExamplesEs examples = _TranslationsDocsComponentsKSwitchExamplesEs._(_root);
}

// Path: docs.components.switcher
class _TranslationsDocsComponentsSwitcherEs extends TranslationsDocsComponentsSwitcherKo {
	_TranslationsDocsComponentsSwitcherEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Conmutador';
	@override String get description => 'Permite cambiar entre diferentes vistas.';
	@override late final _TranslationsDocsComponentsSwitcherExamplesEs examples = _TranslationsDocsComponentsSwitcherExamplesEs._(_root);
	@override String get switch_direction => 'Cambiar dirección';
	@override String get next_item => 'Siguiente ítem';
}

// Path: docs.components.tab_list
class _TranslationsDocsComponentsTabListEs extends TranslationsDocsComponentsTabListKo {
	_TranslationsDocsComponentsTabListEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Lista de pestañas';
	@override String get description => 'Componente de lista de pestañas.';
	@override late final _TranslationsDocsComponentsTabListExamplesEs examples = _TranslationsDocsComponentsTabListExamplesEs._(_root);
}

// Path: docs.components.tab_pane
class _TranslationsDocsComponentsTabPaneEs extends TranslationsDocsComponentsTabPaneKo {
	_TranslationsDocsComponentsTabPaneEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Panel de pestañas';
	@override String get description => 'Componente de panel de pestañas.';
	@override late final _TranslationsDocsComponentsTabPaneExamplesEs examples = _TranslationsDocsComponentsTabPaneExamplesEs._(_root);
}

// Path: docs.components.table
class _TranslationsDocsComponentsTableEs extends TranslationsDocsComponentsTableKo {
	_TranslationsDocsComponentsTableEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tabla';
	@override String get description => 'Muestra datos en formato de tabla.';
	@override late final _TranslationsDocsComponentsTableExamplesEs examples = _TranslationsDocsComponentsTableExamplesEs._(_root);
	@override String get invoice => 'Factura';
	@override String get status => 'Estado';
	@override String get method => 'Método';
	@override String get amount => 'Cantidad';
	@override String get total => 'Total';
	@override String get paid => 'Pagado';
	@override String get pending => 'En espera';
	@override String get unpaid => 'Sin pagar';
	@override String get credit_card => 'Tarjeta de crédito';
	@override String get paypal => 'PayPal';
	@override String get bank_transfer => 'Transferencia bancaria';
}

// Path: docs.components.tabs
class _TranslationsDocsComponentsTabsEs extends TranslationsDocsComponentsTabsKo {
	_TranslationsDocsComponentsTabsEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Pestañas';
	@override String get description => 'Usa pestañas para organizar contenido.';
	@override late final _TranslationsDocsComponentsTabsExamplesEs examples = _TranslationsDocsComponentsTabsExamplesEs._(_root);
	@override String get tab_1 => 'Pestaña 1';
	@override String get tab_2 => 'Pestaña 2';
	@override String get tab_3 => 'Pestaña 3';
	@override String tab_n({required Object n}) => 'Pestaña ${n}';
}

// Path: docs.components.text_area
class _TranslationsDocsComponentsTextAreaEs extends TranslationsDocsComponentsTextAreaKo {
	_TranslationsDocsComponentsTextAreaEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Área de texto';
	@override String get description => 'Permite ingresar múltiples líneas de texto.';
	@override late final _TranslationsDocsComponentsTextAreaExamplesEs examples = _TranslationsDocsComponentsTextAreaExamplesEs._(_root);
	@override String get hello_world => '¡Hola, mundo!';
}

// Path: docs.components.time_picker
class _TranslationsDocsComponentsTimePickerEs extends TranslationsDocsComponentsTimePickerKo {
	_TranslationsDocsComponentsTimePickerEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Selector de hora';
	@override String get description => 'Campo para seleccionar una hora.';
	@override late final _TranslationsDocsComponentsTimePickerExamplesEs examples = _TranslationsDocsComponentsTimePickerExamplesEs._(_root);
	@override String get select_time => 'Seleccionar hora';
}

// Path: docs.components.timeline
class _TranslationsDocsComponentsTimelineEs extends TranslationsDocsComponentsTimelineKo {
	_TranslationsDocsComponentsTimelineEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Línea de tiempo';
	@override String get description => 'Muestra eventos en una línea de tiempo.';
	@override late final _TranslationsDocsComponentsTimelineExamplesEs examples = _TranslationsDocsComponentsTimelineExamplesEs._(_root);
}

// Path: docs.components.timeline_animation
class _TranslationsDocsComponentsTimelineAnimationEs extends TranslationsDocsComponentsTimelineAnimationKo {
	_TranslationsDocsComponentsTimelineAnimationEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Animación de línea de tiempo';
	@override String get description => 'Animación basada en una línea de tiempo.';
	@override late final _TranslationsDocsComponentsTimelineAnimationExamplesEs examples = _TranslationsDocsComponentsTimelineAnimationExamplesEs._(_root);
}

// Path: docs.components.toast
class _TranslationsDocsComponentsToastEs extends TranslationsDocsComponentsToastKo {
	_TranslationsDocsComponentsToastEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Notificación';
	@override String get description => 'Una notificación que muestra un mensaje corto.';
	@override late final _TranslationsDocsComponentsToastExamplesEs examples = _TranslationsDocsComponentsToastExamplesEs._(_root);
	@override String get event_created => 'El evento ha sido creado';
	@override String get event_date => 'Domingo, 7 de julio de 2024 a las 12:00 PM';
	@override String get show_bottom_left => 'Mostrar notificación en la esquina inferior izquierda';
	@override String get show_bottom_right => 'Mostrar notificación en la esquina inferior derecha';
	@override String get show_top_left => 'Mostrar notificación en la esquina superior izquierda';
	@override String get show_top_right => 'Mostrar notificación en la esquina superior derecha';
	@override String get show_bottom_center => 'Mostrar notificación en el centro inferior';
	@override String get show_top_center => 'Mostrar notificación en el centro superior';
}

// Path: docs.components.toggle
class _TranslationsDocsComponentsToggleEs extends TranslationsDocsComponentsToggleKo {
	_TranslationsDocsComponentsToggleEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Alternar';
	@override String get description => 'Permite alternar entre opciones.';
	@override late final _TranslationsDocsComponentsToggleExamplesEs examples = _TranslationsDocsComponentsToggleExamplesEs._(_root);
	@override String get toggle => 'Alternar';
}

// Path: docs.components.tooltip
class _TranslationsDocsComponentsTooltipEs extends TranslationsDocsComponentsTooltipKo {
	_TranslationsDocsComponentsTooltipEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tooltip';
	@override String get description => 'Muestra información adicional sobre un elemento.';
	@override late final _TranslationsDocsComponentsTooltipExamplesEs examples = _TranslationsDocsComponentsTooltipExamplesEs._(_root);
	@override String get this_is_tooltip => 'Esto es un tooltip.';
	@override String get hover_over_me => 'Pasa el ratón sobre mí';
}

// Path: docs.components.tracker
class _TranslationsDocsComponentsTrackerEs extends TranslationsDocsComponentsTrackerKo {
	_TranslationsDocsComponentsTrackerEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Rastreador';
	@override String get description => 'Rastrea el progreso.';
	@override late final _TranslationsDocsComponentsTrackerExamplesEs examples = _TranslationsDocsComponentsTrackerExamplesEs._(_root);
	@override String get fine => 'Bien';
	@override String get warning => 'Advertencia';
	@override String get critical => 'Crítico';
	@override String get unknown => 'Desconocido';
	@override String get tracker_fine => 'Rastreador en buen estado';
	@override String get tracker_warning => 'Rastreador en advertencia';
	@override String get tracker_critical => 'Rastreador crítico';
	@override String get tracker_unknown => 'Rastreador desconocido';
}

// Path: docs.components.tree
class _TranslationsDocsComponentsTreeEs extends TranslationsDocsComponentsTreeKo {
	_TranslationsDocsComponentsTreeEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Árbol';
	@override String get description => 'Muestra datos jerárquicos en forma de árbol.';
	@override late final _TranslationsDocsComponentsTreeExamplesEs examples = _TranslationsDocsComponentsTreeExamplesEs._(_root);
}

// Path: docs.components.window
class _TranslationsDocsComponentsWindowEs extends TranslationsDocsComponentsWindowKo {
	_TranslationsDocsComponentsWindowEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Ventana';
	@override String get description => 'Ventana estilo escritorio.';
	@override late final _TranslationsDocsComponentsWindowExamplesEs examples = _TranslationsDocsComponentsWindowExamplesEs._(_root);
	@override String get window_1 => 'Ventana 1';
	@override String get window_2 => 'Ventana 2';
	@override String get desktop => 'Escritorio';
	@override String get add_window => 'Agregar ventana';
}

// Path: docs.pages.introduction.features_list
class _TranslationsDocsPagesIntroductionFeaturesListEs extends TranslationsDocsPagesIntroductionFeaturesListKo {
	_TranslationsDocsPagesIntroductionFeaturesListEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get components_count => '¡84 componentes y en aumento!';
	@override String get material_cupertino => 'Soporta widgets de Material y Cupertino, y los temas están ajustados actualmente para el tema de coui_flutter.';
	@override String get premade_themes => 'Temas predefinidos de Coui/UI.';
	@override String get platform_support => 'Soporte para plataformas móviles, web y de escritorio.';
	@override String get middle_drag => 'Soporte para desplazamiento de medio arrastre.';
	@override String get typography_extensions => 'Diferentes extensiones de widgets para tipografía.';
	@override String get webassembly => 'Soporte para WebAssembly para un mejor rendimiento.';
}

// Path: docs.components.accordion.examples
class _TranslationsDocsComponentsAccordionExamplesEs extends TranslationsDocsComponentsAccordionExamplesKo {
	_TranslationsDocsComponentsAccordionExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de acordeón';
}

// Path: docs.components.alert.examples
class _TranslationsDocsComponentsAlertExamplesEs extends TranslationsDocsComponentsAlertExamplesKo {
	_TranslationsDocsComponentsAlertExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de alerta';
	@override String get destructive => 'Ejemplo de alerta destructiva';
}

// Path: docs.components.alert_dialog.examples
class _TranslationsDocsComponentsAlertDialogExamplesEs extends TranslationsDocsComponentsAlertDialogExamplesKo {
	_TranslationsDocsComponentsAlertDialogExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de diálogo de alerta';
}

// Path: docs.components.animated_value_builder.examples
class _TranslationsDocsComponentsAnimatedValueBuilderExamplesEs extends TranslationsDocsComponentsAnimatedValueBuilderExamplesKo {
	_TranslationsDocsComponentsAnimatedValueBuilderExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de constructor de valores animados';
}

// Path: docs.components.app_bar.examples
class _TranslationsDocsComponentsAppBarExamplesEs extends TranslationsDocsComponentsAppBarExamplesKo {
	_TranslationsDocsComponentsAppBarExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de barra de la aplicación';
}

// Path: docs.components.autocomplete.examples
class _TranslationsDocsComponentsAutocompleteExamplesEs extends TranslationsDocsComponentsAutocompleteExamplesKo {
	_TranslationsDocsComponentsAutocompleteExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de autocompletar';
}

// Path: docs.components.avatar.examples
class _TranslationsDocsComponentsAvatarExamplesEs extends TranslationsDocsComponentsAvatarExamplesKo {
	_TranslationsDocsComponentsAvatarExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de avatar';
}

// Path: docs.components.avatar_group.examples
class _TranslationsDocsComponentsAvatarGroupExamplesEs extends TranslationsDocsComponentsAvatarGroupExamplesKo {
	_TranslationsDocsComponentsAvatarGroupExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de grupo de avatares';
}

// Path: docs.components.badge.examples
class _TranslationsDocsComponentsBadgeExamplesEs extends TranslationsDocsComponentsBadgeExamplesKo {
	_TranslationsDocsComponentsBadgeExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de insignia';
}

// Path: docs.components.breadcrumb.examples
class _TranslationsDocsComponentsBreadcrumbExamplesEs extends TranslationsDocsComponentsBreadcrumbExamplesKo {
	_TranslationsDocsComponentsBreadcrumbExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de migas de pan';
}

// Path: docs.components.button.examples
class _TranslationsDocsComponentsButtonExamplesEs extends TranslationsDocsComponentsButtonExamplesKo {
	_TranslationsDocsComponentsButtonExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get primary => 'Ejemplo de botón primario';
	@override String get secondary => 'Ejemplo de botón secundario';
	@override String get outline => 'Ejemplo de botón de contorno';
	@override String get ghost => 'Ejemplo de botón fantasma';
	@override String get destructive => 'Ejemplo de botón destructivo';
	@override String get link => 'Ejemplo de botón de enlace';
	@override String get text => 'Ejemplo de botón de texto';
	@override String get disabled => 'Ejemplo de botón deshabilitado';
	@override String get icon => 'Ejemplo de botón de ícono';
	@override String get icon_with_label => 'Ejemplo de botón de ícono con etiqueta';
	@override String get size => 'Ejemplo de tamaño de botón';
	@override String get density => 'Ejemplo de densidad de botón';
	@override String get shape => 'Ejemplo de forma de botón';
	@override String get group => 'Ejemplo de grupo de botones';
	@override String get stated => 'Ejemplo de botón con estado';
	@override String get card => 'Ejemplo de botón de tarjeta';
	@override String get custom => 'Ejemplo de botón personalizado';
}

// Path: docs.components.calendar.examples
class _TranslationsDocsComponentsCalendarExamplesEs extends TranslationsDocsComponentsCalendarExamplesKo {
	_TranslationsDocsComponentsCalendarExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de calendario';
}

// Path: docs.components.card.examples
class _TranslationsDocsComponentsCardExamplesEs extends TranslationsDocsComponentsCardExamplesKo {
	_TranslationsDocsComponentsCardExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de tarjeta';
}

// Path: docs.components.card_image.examples
class _TranslationsDocsComponentsCardImageExamplesEs extends TranslationsDocsComponentsCardImageExamplesKo {
	_TranslationsDocsComponentsCardImageExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de tarjeta de imagen';
}

// Path: docs.components.carousel.examples
class _TranslationsDocsComponentsCarouselExamplesEs extends TranslationsDocsComponentsCarouselExamplesKo {
	_TranslationsDocsComponentsCarouselExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de carrusel';
}

// Path: docs.components.checkbox.examples
class _TranslationsDocsComponentsCheckboxExamplesEs extends TranslationsDocsComponentsCheckboxExamplesKo {
	_TranslationsDocsComponentsCheckboxExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de casilla de verificación';
}

// Path: docs.components.chip.examples
class _TranslationsDocsComponentsChipExamplesEs extends TranslationsDocsComponentsChipExamplesKo {
	_TranslationsDocsComponentsChipExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de chip';
}

// Path: docs.components.chip_input.examples
class _TranslationsDocsComponentsChipInputExamplesEs extends TranslationsDocsComponentsChipInputExamplesKo {
	_TranslationsDocsComponentsChipInputExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de entrada de chips';
}

// Path: docs.components.circular_progress.examples
class _TranslationsDocsComponentsCircularProgressExamplesEs extends TranslationsDocsComponentsCircularProgressExamplesKo {
	_TranslationsDocsComponentsCircularProgressExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de progreso circular';
}

// Path: docs.components.code_snippet.examples
class _TranslationsDocsComponentsCodeSnippetExamplesEs extends TranslationsDocsComponentsCodeSnippetExamplesKo {
	_TranslationsDocsComponentsCodeSnippetExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de fragmento de código';
}

// Path: docs.components.collapsible.examples
class _TranslationsDocsComponentsCollapsibleExamplesEs extends TranslationsDocsComponentsCollapsibleExamplesKo {
	_TranslationsDocsComponentsCollapsibleExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo colapsable';
}

// Path: docs.components.color_picker.examples
class _TranslationsDocsComponentsColorPickerExamplesEs extends TranslationsDocsComponentsColorPickerExamplesKo {
	_TranslationsDocsComponentsColorPickerExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de selector de color';
}

// Path: docs.components.command.examples
class _TranslationsDocsComponentsCommandExamplesEs extends TranslationsDocsComponentsCommandExamplesKo {
	_TranslationsDocsComponentsCommandExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de comando';
}

// Path: docs.components.context_menu.examples
class _TranslationsDocsComponentsContextMenuExamplesEs extends TranslationsDocsComponentsContextMenuExamplesKo {
	_TranslationsDocsComponentsContextMenuExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de menú contextual';
}

// Path: docs.components.date_picker.examples
class _TranslationsDocsComponentsDatePickerExamplesEs extends TranslationsDocsComponentsDatePickerExamplesKo {
	_TranslationsDocsComponentsDatePickerExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de selector de fecha';
}

// Path: docs.components.dialog.examples
class _TranslationsDocsComponentsDialogExamplesEs extends TranslationsDocsComponentsDialogExamplesKo {
	_TranslationsDocsComponentsDialogExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de diálogo';
}

// Path: docs.components.divider.examples
class _TranslationsDocsComponentsDividerExamplesEs extends TranslationsDocsComponentsDividerExamplesKo {
	_TranslationsDocsComponentsDividerExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de divisor';
}

// Path: docs.components.dot_indicator.examples
class _TranslationsDocsComponentsDotIndicatorExamplesEs extends TranslationsDocsComponentsDotIndicatorExamplesKo {
	_TranslationsDocsComponentsDotIndicatorExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de indicador de punto';
}

// Path: docs.components.drawer.examples
class _TranslationsDocsComponentsDrawerExamplesEs extends TranslationsDocsComponentsDrawerExamplesKo {
	_TranslationsDocsComponentsDrawerExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de cajón';
}

// Path: docs.components.dropdown_menu.examples
class _TranslationsDocsComponentsDropdownMenuExamplesEs extends TranslationsDocsComponentsDropdownMenuExamplesKo {
	_TranslationsDocsComponentsDropdownMenuExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de menú desplegable';
}

// Path: docs.components.expandable_sidebar.examples
class _TranslationsDocsComponentsExpandableSidebarExamplesEs extends TranslationsDocsComponentsExpandableSidebarExamplesKo {
	_TranslationsDocsComponentsExpandableSidebarExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de barra lateral expandible';
}

// Path: docs.components.form.examples
class _TranslationsDocsComponentsFormExamplesEs extends TranslationsDocsComponentsFormExamplesKo {
	_TranslationsDocsComponentsFormExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get table_layout => 'Ejemplo de formulario (diseño de tabla)';
	@override String get column_layout => 'Ejemplo de formulario (diseño de columna)';
	@override String get validation_mode => 'Ejemplo de modo de validación';
}

// Path: docs.components.formatted_input.examples
class _TranslationsDocsComponentsFormattedInputExamplesEs extends TranslationsDocsComponentsFormattedInputExamplesKo {
	_TranslationsDocsComponentsFormattedInputExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de entrada formateada';
}

// Path: docs.components.hover_card.examples
class _TranslationsDocsComponentsHoverCardExamplesEs extends TranslationsDocsComponentsHoverCardExamplesKo {
	_TranslationsDocsComponentsHoverCardExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de tarjeta de hover';
}

// Path: docs.components.input.examples
class _TranslationsDocsComponentsInputExamplesEs extends TranslationsDocsComponentsInputExamplesKo {
	_TranslationsDocsComponentsInputExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de entrada';
}

// Path: docs.components.input_otp.examples
class _TranslationsDocsComponentsInputOtpExamplesEs extends TranslationsDocsComponentsInputOtpExamplesKo {
	_TranslationsDocsComponentsInputOtpExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de entrada OTP';
}

// Path: docs.components.item_picker.examples
class _TranslationsDocsComponentsItemPickerExamplesEs extends TranslationsDocsComponentsItemPickerExamplesKo {
	_TranslationsDocsComponentsItemPickerExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de selector de ítems';
}

// Path: docs.components.keyboard_display.examples
class _TranslationsDocsComponentsKeyboardDisplayExamplesEs extends TranslationsDocsComponentsKeyboardDisplayExamplesKo {
	_TranslationsDocsComponentsKeyboardDisplayExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de display de teclado';
}

// Path: docs.components.linear_progress.examples
class _TranslationsDocsComponentsLinearProgressExamplesEs extends TranslationsDocsComponentsLinearProgressExamplesKo {
	_TranslationsDocsComponentsLinearProgressExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de progreso lineal';
}

// Path: docs.components.material.examples
class _TranslationsDocsComponentsMaterialExamplesEs extends TranslationsDocsComponentsMaterialExamplesKo {
	_TranslationsDocsComponentsMaterialExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de Material/Cupertino';
}

// Path: docs.components.menubar.examples
class _TranslationsDocsComponentsMenubarExamplesEs extends TranslationsDocsComponentsMenubarExamplesKo {
	_TranslationsDocsComponentsMenubarExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de barra de menú';
}

// Path: docs.components.multiselect.examples
class _TranslationsDocsComponentsMultiselectExamplesEs extends TranslationsDocsComponentsMultiselectExamplesKo {
	_TranslationsDocsComponentsMultiselectExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de selección múltiple';
}

// Path: docs.components.navigation_bar.examples
class _TranslationsDocsComponentsNavigationBarExamplesEs extends TranslationsDocsComponentsNavigationBarExamplesKo {
	_TranslationsDocsComponentsNavigationBarExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de barra de navegación';
}

// Path: docs.components.navigation_menu.examples
class _TranslationsDocsComponentsNavigationMenuExamplesEs extends TranslationsDocsComponentsNavigationMenuExamplesKo {
	_TranslationsDocsComponentsNavigationMenuExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de menú de navegación';
}

// Path: docs.components.navigation_rail.examples
class _TranslationsDocsComponentsNavigationRailExamplesEs extends TranslationsDocsComponentsNavigationRailExamplesKo {
	_TranslationsDocsComponentsNavigationRailExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de riel de navegación';
}

// Path: docs.components.navigation_sidebar.examples
class _TranslationsDocsComponentsNavigationSidebarExamplesEs extends TranslationsDocsComponentsNavigationSidebarExamplesKo {
	_TranslationsDocsComponentsNavigationSidebarExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de barra lateral de navegación';
}

// Path: docs.components.number_input.examples
class _TranslationsDocsComponentsNumberInputExamplesEs extends TranslationsDocsComponentsNumberInputExamplesKo {
	_TranslationsDocsComponentsNumberInputExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de entrada numérica';
}

// Path: docs.components.number_ticker.examples
class _TranslationsDocsComponentsNumberTickerExamplesEs extends TranslationsDocsComponentsNumberTickerExamplesKo {
	_TranslationsDocsComponentsNumberTickerExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de ticker numérico';
}

// Path: docs.components.overflow_marquee.examples
class _TranslationsDocsComponentsOverflowMarqueeExamplesEs extends TranslationsDocsComponentsOverflowMarqueeExamplesKo {
	_TranslationsDocsComponentsOverflowMarqueeExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de marquee desbordante';
}

// Path: docs.components.pagination.examples
class _TranslationsDocsComponentsPaginationExamplesEs extends TranslationsDocsComponentsPaginationExamplesKo {
	_TranslationsDocsComponentsPaginationExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de paginación';
}

// Path: docs.components.phone_input.examples
class _TranslationsDocsComponentsPhoneInputExamplesEs extends TranslationsDocsComponentsPhoneInputExamplesKo {
	_TranslationsDocsComponentsPhoneInputExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de entrada de teléfono';
}

// Path: docs.components.popover.examples
class _TranslationsDocsComponentsPopoverExamplesEs extends TranslationsDocsComponentsPopoverExamplesKo {
	_TranslationsDocsComponentsPopoverExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de popover';
}

// Path: docs.components.progress.examples
class _TranslationsDocsComponentsProgressExamplesEs extends TranslationsDocsComponentsProgressExamplesKo {
	_TranslationsDocsComponentsProgressExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de progreso';
}

// Path: docs.components.radio_card.examples
class _TranslationsDocsComponentsRadioCardExamplesEs extends TranslationsDocsComponentsRadioCardExamplesKo {
	_TranslationsDocsComponentsRadioCardExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de tarjeta de radio';
}

// Path: docs.components.radio_group.examples
class _TranslationsDocsComponentsRadioGroupExamplesEs extends TranslationsDocsComponentsRadioGroupExamplesKo {
	_TranslationsDocsComponentsRadioGroupExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de grupo de radio';
}

// Path: docs.components.refresh_trigger.examples
class _TranslationsDocsComponentsRefreshTriggerExamplesEs extends TranslationsDocsComponentsRefreshTriggerExamplesKo {
	_TranslationsDocsComponentsRefreshTriggerExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de disparador de actualización';
}

// Path: docs.components.repeated_animation_builder.examples
class _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesEs extends TranslationsDocsComponentsRepeatedAnimationBuilderExamplesKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de constructor de animación repetida';
}

// Path: docs.components.resizable.examples
class _TranslationsDocsComponentsResizableExamplesEs extends TranslationsDocsComponentsResizableExamplesKo {
	_TranslationsDocsComponentsResizableExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de redimensionable';
}

// Path: docs.components.scaffold.examples
class _TranslationsDocsComponentsScaffoldExamplesEs extends TranslationsDocsComponentsScaffoldExamplesKo {
	_TranslationsDocsComponentsScaffoldExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de escaffold';
}

// Path: docs.components.select.examples
class _TranslationsDocsComponentsSelectExamplesEs extends TranslationsDocsComponentsSelectExamplesKo {
	_TranslationsDocsComponentsSelectExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de selección';
}

// Path: docs.components.sheet.examples
class _TranslationsDocsComponentsSheetExamplesEs extends TranslationsDocsComponentsSheetExamplesKo {
	_TranslationsDocsComponentsSheetExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de hoja';
}

// Path: docs.components.skeleton.examples
class _TranslationsDocsComponentsSkeletonExamplesEs extends TranslationsDocsComponentsSkeletonExamplesKo {
	_TranslationsDocsComponentsSkeletonExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de esqueleto';
}

// Path: docs.components.slider.examples
class _TranslationsDocsComponentsSliderExamplesEs extends TranslationsDocsComponentsSliderExamplesKo {
	_TranslationsDocsComponentsSliderExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de deslizador';
}

// Path: docs.components.sortable.examples
class _TranslationsDocsComponentsSortableExamplesEs extends TranslationsDocsComponentsSortableExamplesKo {
	_TranslationsDocsComponentsSortableExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de ordenable';
}

// Path: docs.components.star_rating.examples
class _TranslationsDocsComponentsStarRatingExamplesEs extends TranslationsDocsComponentsStarRatingExamplesKo {
	_TranslationsDocsComponentsStarRatingExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de calificación estelar';
}

// Path: docs.components.stepper.examples
class _TranslationsDocsComponentsStepperExamplesEs extends TranslationsDocsComponentsStepperExamplesKo {
	_TranslationsDocsComponentsStepperExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de stepper';
}

// Path: docs.components.steps.examples
class _TranslationsDocsComponentsStepsExamplesEs extends TranslationsDocsComponentsStepsExamplesKo {
	_TranslationsDocsComponentsStepsExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de pasos';
}

// Path: docs.components.swiper.examples
class _TranslationsDocsComponentsSwiperExamplesEs extends TranslationsDocsComponentsSwiperExamplesKo {
	_TranslationsDocsComponentsSwiperExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de swiper';
}

// Path: docs.components.k_switch.examples
class _TranslationsDocsComponentsKSwitchExamplesEs extends TranslationsDocsComponentsKSwitchExamplesKo {
	_TranslationsDocsComponentsKSwitchExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de interruptor';
}

// Path: docs.components.switcher.examples
class _TranslationsDocsComponentsSwitcherExamplesEs extends TranslationsDocsComponentsSwitcherExamplesKo {
	_TranslationsDocsComponentsSwitcherExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de conmutador';
}

// Path: docs.components.tab_list.examples
class _TranslationsDocsComponentsTabListExamplesEs extends TranslationsDocsComponentsTabListExamplesKo {
	_TranslationsDocsComponentsTabListExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de lista de pestañas';
}

// Path: docs.components.tab_pane.examples
class _TranslationsDocsComponentsTabPaneExamplesEs extends TranslationsDocsComponentsTabPaneExamplesKo {
	_TranslationsDocsComponentsTabPaneExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de panel de pestañas';
}

// Path: docs.components.table.examples
class _TranslationsDocsComponentsTableExamplesEs extends TranslationsDocsComponentsTableExamplesKo {
	_TranslationsDocsComponentsTableExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de tabla';
}

// Path: docs.components.tabs.examples
class _TranslationsDocsComponentsTabsExamplesEs extends TranslationsDocsComponentsTabsExamplesKo {
	_TranslationsDocsComponentsTabsExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de pestañas';
}

// Path: docs.components.text_area.examples
class _TranslationsDocsComponentsTextAreaExamplesEs extends TranslationsDocsComponentsTextAreaExamplesKo {
	_TranslationsDocsComponentsTextAreaExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de área de texto';
}

// Path: docs.components.time_picker.examples
class _TranslationsDocsComponentsTimePickerExamplesEs extends TranslationsDocsComponentsTimePickerExamplesKo {
	_TranslationsDocsComponentsTimePickerExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de selector de hora';
}

// Path: docs.components.timeline.examples
class _TranslationsDocsComponentsTimelineExamplesEs extends TranslationsDocsComponentsTimelineExamplesKo {
	_TranslationsDocsComponentsTimelineExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de línea de tiempo';
}

// Path: docs.components.timeline_animation.examples
class _TranslationsDocsComponentsTimelineAnimationExamplesEs extends TranslationsDocsComponentsTimelineAnimationExamplesKo {
	_TranslationsDocsComponentsTimelineAnimationExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de animación de línea de tiempo';
}

// Path: docs.components.toast.examples
class _TranslationsDocsComponentsToastExamplesEs extends TranslationsDocsComponentsToastExamplesKo {
	_TranslationsDocsComponentsToastExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de notificación';
}

// Path: docs.components.toggle.examples
class _TranslationsDocsComponentsToggleExamplesEs extends TranslationsDocsComponentsToggleExamplesKo {
	_TranslationsDocsComponentsToggleExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de alternar';
}

// Path: docs.components.tooltip.examples
class _TranslationsDocsComponentsTooltipExamplesEs extends TranslationsDocsComponentsTooltipExamplesKo {
	_TranslationsDocsComponentsTooltipExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de tooltip';
}

// Path: docs.components.tracker.examples
class _TranslationsDocsComponentsTrackerExamplesEs extends TranslationsDocsComponentsTrackerExamplesKo {
	_TranslationsDocsComponentsTrackerExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de rastreador';
}

// Path: docs.components.tree.examples
class _TranslationsDocsComponentsTreeExamplesEs extends TranslationsDocsComponentsTreeExamplesKo {
	_TranslationsDocsComponentsTreeExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de árbol';
}

// Path: docs.components.window.examples
class _TranslationsDocsComponentsWindowExamplesEs extends TranslationsDocsComponentsWindowExamplesKo {
	_TranslationsDocsComponentsWindowExamplesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Ejemplo de ventana';
}
