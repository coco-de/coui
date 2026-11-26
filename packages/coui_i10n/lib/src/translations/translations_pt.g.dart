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
class TranslationsPt extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsPt({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.pt,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <pt>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsPt _root = this; // ignore: unused_field

	@override 
	TranslationsPt $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsPt(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsWidgetbookPt widgetbook = _TranslationsWidgetbookPt._(_root);
	@override late final _TranslationsDocsPt docs = _TranslationsDocsPt._(_root);
}

// Path: widgetbook
class _TranslationsWidgetbookPt extends TranslationsWidgetbookKo {
	_TranslationsWidgetbookPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsWidgetbookCommonPt common = _TranslationsWidgetbookCommonPt._(_root);
	@override late final _TranslationsWidgetbookLoadingPt loading = _TranslationsWidgetbookLoadingPt._(_root);
	@override late final _TranslationsWidgetbookTabsPt tabs = _TranslationsWidgetbookTabsPt._(_root);
	@override late final _TranslationsWidgetbookPaginationPt pagination = _TranslationsWidgetbookPaginationPt._(_root);
	@override late final _TranslationsWidgetbookTooltipPt tooltip = _TranslationsWidgetbookTooltipPt._(_root);
	@override late final _TranslationsWidgetbookRadioPt radio = _TranslationsWidgetbookRadioPt._(_root);
	@override late final _TranslationsWidgetbookCardPt card = _TranslationsWidgetbookCardPt._(_root);
	@override late final _TranslationsWidgetbookAlertPt alert = _TranslationsWidgetbookAlertPt._(_root);
	@override late final _TranslationsWidgetbookAccordionPt accordion = _TranslationsWidgetbookAccordionPt._(_root);
	@override late final _TranslationsWidgetbookSkeletonPt skeleton = _TranslationsWidgetbookSkeletonPt._(_root);
	@override late final _TranslationsWidgetbookToastPt toast = _TranslationsWidgetbookToastPt._(_root);
	@override late final _TranslationsWidgetbookChipPt chip = _TranslationsWidgetbookChipPt._(_root);
	@override late final _TranslationsWidgetbookCheckboxPt checkbox = _TranslationsWidgetbookCheckboxPt._(_root);
	@override late final _TranslationsWidgetbookTogglePt toggle = _TranslationsWidgetbookTogglePt._(_root);
	@override late final _TranslationsWidgetbookDialogPt dialog = _TranslationsWidgetbookDialogPt._(_root);
	@override late final _TranslationsWidgetbookPopoverPt popover = _TranslationsWidgetbookPopoverPt._(_root);
	@override late final _TranslationsWidgetbookTextFieldPt text_field = _TranslationsWidgetbookTextFieldPt._(_root);
	@override late final _TranslationsWidgetbookButtonPt button = _TranslationsWidgetbookButtonPt._(_root);
	@override late final _TranslationsWidgetbookTablePt table = _TranslationsWidgetbookTablePt._(_root);
	@override late final _TranslationsWidgetbookKSwitchPt k_switch = _TranslationsWidgetbookKSwitchPt._(_root);
	@override late final _TranslationsWidgetbookSwitchComponentPt switch_component = _TranslationsWidgetbookSwitchComponentPt._(_root);
	@override late final _TranslationsWidgetbookSelectPt select = _TranslationsWidgetbookSelectPt._(_root);
	@override late final _TranslationsWidgetbookBreadcrumbPt breadcrumb = _TranslationsWidgetbookBreadcrumbPt._(_root);
	@override late final _TranslationsWidgetbookBadgePt badge = _TranslationsWidgetbookBadgePt._(_root);
	@override late final _TranslationsWidgetbookThemePreviewPt theme_preview = _TranslationsWidgetbookThemePreviewPt._(_root);
	@override late final _TranslationsWidgetbookChatPt chat = _TranslationsWidgetbookChatPt._(_root);
	@override late final _TranslationsWidgetbookMultipleChoicePt multiple_choice = _TranslationsWidgetbookMultipleChoicePt._(_root);
	@override late final _TranslationsWidgetbookFormattedInputPt formatted_input = _TranslationsWidgetbookFormattedInputPt._(_root);
	@override late final _TranslationsWidgetbookSwiperPt swiper = _TranslationsWidgetbookSwiperPt._(_root);
}

// Path: docs
class _TranslationsDocsPt extends TranslationsDocsKo {
	_TranslationsDocsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsCommonPt common = _TranslationsDocsCommonPt._(_root);
	@override late final _TranslationsDocsBadgesPt badges = _TranslationsDocsBadgesPt._(_root);
	@override late final _TranslationsDocsFlavorsPt flavors = _TranslationsDocsFlavorsPt._(_root);
	@override late final _TranslationsDocsNavigationPt navigation = _TranslationsDocsNavigationPt._(_root);
	@override late final _TranslationsDocsPagesPt pages = _TranslationsDocsPagesPt._(_root);
	@override late final _TranslationsDocsComponentsPt components = _TranslationsDocsComponentsPt._(_root);
}

// Path: widgetbook.common
class _TranslationsWidgetbookCommonPt extends TranslationsWidgetbookCommonKo {
	_TranslationsWidgetbookCommonPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get increment_progress => 'Aumentar progresso';
	@override String selected_tab({required Object index}) => 'Aba selecionada: ${index}';
	@override String current_page({required Object page}) => 'Página atual: ${page}';
	@override String total_pages({required Object count}) => 'Total de páginas: ${count}';
	@override String page_of({required Object current, required Object total}) => '${current} página / ${total}';
	@override String get hover_over_icon => 'Passe o mouse sobre o ícone';
	@override String counter({required Object count}) => 'Contador: ${count}';
	@override String selected_rows({required Object count}) => 'Linhas selecionadas: ${count}';
	@override String value({required Object value}) => 'Valor: ${value}';
	@override String selected_cells({required Object count}) => 'Células selecionadas: ${count}';
}

// Path: widgetbook.loading
class _TranslationsWidgetbookLoadingPt extends TranslationsWidgetbookLoadingKo {
	_TranslationsWidgetbookLoadingPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get indeterminate => 'Carregando indefinido';
	@override String with_value({required Object percent}) => 'Com valor (${percent}%)';
	@override String get custom_size => 'Tamanho personalizado';
	@override String get custom_height => 'Altura personalizada';
	@override String get circular_progress => 'Progresso circular';
	@override String get linear_progress => 'Progresso linear';
}

// Path: widgetbook.tabs
class _TranslationsWidgetbookTabsPt extends TranslationsWidgetbookTabsKo {
	_TranslationsWidgetbookTabsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get home => 'Início';
	@override String get profile => 'Perfil';
	@override String get settings => 'Configurações';
	@override String get overview => 'Visão geral';
	@override String get details => 'Detalhes';
	@override String get history => 'Histórico';
	@override String get overview_content => 'Conteúdo de visão geral';
	@override String get details_content => 'Conteúdo de detalhes';
	@override String get history_content => 'Conteúdo do histórico';
	@override String get general_info => 'Informações gerais sobre o item';
	@override String get specifications => 'Especificações e atributos detalhados';
	@override String get timeline => 'Linha do tempo de alterações e atualizações';
}

// Path: widgetbook.pagination
class _TranslationsWidgetbookPaginationPt extends TranslationsWidgetbookPaginationKo {
	_TranslationsWidgetbookPaginationPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get show_skip_to_first => 'Mostrar pular para o primeiro';
	@override String get show_skip_to_last => 'Mostrar pular para o último';
	@override String get hide_previous_on_first => 'Esconder anterior na primeira página';
	@override String get hide_next_on_last => 'Esconder próximo na última página';
	@override String get max_visible_pages => 'Número máximo de páginas visíveis';
}

// Path: widgetbook.tooltip
class _TranslationsWidgetbookTooltipPt extends TranslationsWidgetbookTooltipKo {
	_TranslationsWidgetbookTooltipPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get helpful_message => 'Este é uma mensagem de tooltip útil';
	@override String get tooltip_above => 'Tooltip acima';
	@override String get tooltip_below => 'Tooltip abaixo';
	@override String get tooltip_left => 'Tooltip à esquerda';
	@override String get tooltip_right => 'Tooltip à direita';
	@override String get top => 'Cima';
	@override String get bottom => 'Baixo';
	@override String get left => 'Esquerda';
	@override String get right => 'Direita';
}

// Path: widgetbook.radio
class _TranslationsWidgetbookRadioPt extends TranslationsWidgetbookRadioKo {
	_TranslationsWidgetbookRadioPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get small => 'Pequeno';
	@override String get medium => 'Médio';
	@override String get large => 'Grande';
}

// Path: widgetbook.card
class _TranslationsWidgetbookCardPt extends TranslationsWidgetbookCardKo {
	_TranslationsWidgetbookCardPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get card_content => 'Conteúdo do cartão';
	@override String get gradient_card => 'Cartão gradiente';
	@override String get custom_decoration => 'Cartão com decoração personalizada';
}

// Path: widgetbook.alert
class _TranslationsWidgetbookAlertPt extends TranslationsWidgetbookAlertKo {
	_TranslationsWidgetbookAlertPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Título do alerta';
	@override String get message => 'Esta é uma mensagem de alerta.';
}

// Path: widgetbook.accordion
class _TranslationsWidgetbookAccordionPt extends TranslationsWidgetbookAccordionKo {
	_TranslationsWidgetbookAccordionPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get what_is_coui => 'O que é CoUI Flutter?';
	@override String get what_is_coui_answer => 'CoUI Flutter é uma biblioteca abrangente de componentes de UI projetada para construir aplicativos Flutter modernos e acessíveis com um padrão de design consistente.';
	@override String get how_to_install => 'Como instalar?';
	@override String get how_to_install_answer => 'Adicione coui_flutter às dependências do seu pubspec.yaml e execute flutter pub get para instalar o pacote.';
	@override String get is_customizable => 'É personalizável?';
	@override String get is_customizable_answer => 'Sim! CoUI Flutter oferece suporte abrangente a temas que permite personalizar cores, tipografia, espaçamento, etc., através do ThemeData.';
	@override String get getting_started => 'Começando';
	@override String get getting_started_answer => 'Comece instalando o pacote e importando-o para o seu projeto. Para detalhes sobre a configuração, consulte a documentação.';
	@override String get features_expanded => 'Características (padrão expandido)';
	@override String get features_answer => 'CoUI Flutter inclui botões, formulários, diálogos, componentes de navegação, entre outros. Todos os componentes foram projetados considerando acessibilidade e temas.';
	@override String get support => 'Suporte';
	@override String get support_answer => 'Se você tiver perguntas ou precisar de suporte, visite o repositório do GitHub ou confira a documentação em docs.coui.dev.';
}

// Path: widgetbook.skeleton
class _TranslationsWidgetbookSkeletonPt extends TranslationsWidgetbookSkeletonKo {
	_TranslationsWidgetbookSkeletonPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get skeleton_enabled => 'Esqueleto ativado:';
	@override String get title_text => 'Este é o título';
	@override String get description_text => 'Este é um texto de descrição longo';
	@override String get short_text => 'Texto curto';
	@override String get without_skeleton => 'Sem esqueleto:';
	@override String get with_skeleton => 'Com esqueleto:';
	@override String get user_name => 'Nome de usuário';
	@override String get user_email => 'user@example.com';
	@override String get article_title => 'Título do artigo';
	@override String get posted_date => 'Publicado em 1º de janeiro de 2024';
	@override String get bio_description => 'Um desenvolvedor que registra o cotidiano';
	@override String get show_content => 'Mostrar conteúdo';
	@override String get show_loading => 'Mostrar carregando';
	@override String get article_content => 'Este é um exemplo do conteúdo do artigo. Ele será substituído por um esqueleto durante o carregamento.';
}

// Path: widgetbook.toast
class _TranslationsWidgetbookToastPt extends TranslationsWidgetbookToastKo {
	_TranslationsWidgetbookToastPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get success => 'Sucesso';
	@override String get operation_completed => 'Operação concluída com sucesso';
	@override String get show_toast => 'Mostrar toast';
	@override String toast_at({required Object location}) => 'Toast em ${location}';
	@override String get top_left => 'Canto superior esquerdo';
	@override String get top_center => 'Centro superior';
	@override String get top_right => 'Canto superior direito';
	@override String get bottom_left => 'Canto inferior esquerdo';
	@override String get bottom_center => 'Centro inferior';
	@override String get bottom_right => 'Canto inferior direito';
}

// Path: widgetbook.chip
class _TranslationsWidgetbookChipPt extends TranslationsWidgetbookChipKo {
	_TranslationsWidgetbookChipPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get chip => 'Chip';
}

// Path: widgetbook.checkbox
class _TranslationsWidgetbookCheckboxPt extends TranslationsWidgetbookCheckboxKo {
	_TranslationsWidgetbookCheckboxPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get accept_terms => 'Concordo com os termos de serviço';
	@override String get tristate => 'Três estados';
}

// Path: widgetbook.toggle
class _TranslationsWidgetbookTogglePt extends TranslationsWidgetbookToggleKo {
	_TranslationsWidgetbookTogglePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get toggle => 'Alternar';
}

// Path: widgetbook.dialog
class _TranslationsWidgetbookDialogPt extends TranslationsWidgetbookDialogKo {
	_TranslationsWidgetbookDialogPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic_dialog => 'Diálogo básico';
	@override String get basic_title => 'Diálogo Básico';
	@override String get basic_content => 'Um diálogo simples com título e conteúdo.';
	@override String get simple_dialog_content => 'Este é um diálogo simples com título e conteúdo.';
	@override String get show_basic => 'Mostrar Básico';
	@override String get show_basic_dialog => 'Mostrar diálogo básico';
	@override String get confirm_action => 'Confirmar ação';
	@override String get confirm_title => 'Confirmar';
	@override String get confirm_content => 'Você realmente deseja realizar esta ação?';
	@override String get confirm_action_content => 'Você realmente deseja realizar esta ação? Esta ação não pode ser cancelada.';
	@override String get cancel => 'Cancelar';
	@override String get confirm => 'Confirmar';
	@override String get show_confirmation => 'Mostrar Confirmação';
	@override String get show_confirmation_dialog => 'Mostrar diálogo de confirmação';
	@override String get warning => 'Aviso';
	@override String get warning_title => 'Aviso';
	@override String get warning_content => 'Esta ação pode afetar os dados. Prossiga com cautela.';
	@override String get dismiss => 'Fechar';
	@override String get show_warning => 'Mostrar Aviso';
	@override String get show_warning_dialog => 'Mostrar diálogo de aviso';
}

// Path: widgetbook.popover
class _TranslationsWidgetbookPopoverPt extends TranslationsWidgetbookPopoverKo {
	_TranslationsWidgetbookPopoverPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get popover_content => 'Conteúdo do popover';
	@override String get content_title => 'Título do Popover';
	@override String get content_description => 'Popover com conteúdo personalizável.';
	@override String get customizable_content => 'Popover com conteúdo personalizável.';
	@override String get show_popover => 'Mostrar popover';
	@override String popover_at({required Object position}) => '${position} popover';
	@override String get top => 'Superior';
	@override String get bottom => 'Inferior';
	@override String get left => 'Esquerda';
	@override String get right => 'Direita';
}

// Path: widgetbook.text_field
class _TranslationsWidgetbookTextFieldPt extends TranslationsWidgetbookTextFieldKo {
	_TranslationsWidgetbookTextFieldPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get enter_name => 'Digite seu nome';
	@override String get type_here => 'Digite aqui';
}

// Path: widgetbook.button
class _TranslationsWidgetbookButtonPt extends TranslationsWidgetbookButtonKo {
	_TranslationsWidgetbookButtonPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get primary_button => 'Botão primário';
	@override String get secondary_button => 'Botão secundário';
	@override String get dashed_button => 'Carregar arquivo';
	@override String get upload_file => 'Carregar arquivo';
}

// Path: widgetbook.table
class _TranslationsWidgetbookTablePt extends TranslationsWidgetbookTableKo {
	_TranslationsWidgetbookTablePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get name => 'Nome';
	@override String get email => 'Email';
	@override String get role => 'Função';
	@override String get john_doe => 'João Silva';
	@override String get john_email => 'joao@example.com';
	@override String get developer => 'Desenvolvedor';
	@override String get jane_smith => 'Maria Oliveira';
	@override String get jane_email => 'maria@example.com';
	@override String get designer => 'Designer';
	@override String get bob_johnson => 'Carlos Santos';
	@override String get bob_email => 'carlos@example.com';
	@override String get manager => 'Gerente';
	@override String get select => 'Selecionar';
	@override String get product => 'Produto';
	@override String get price => 'Preço';
	@override String get stock => 'Estoque';
	@override String get laptop => 'Laptop';
	@override String get mouse => 'Mouse';
	@override String get keyboard => 'Teclado';
}

// Path: widgetbook.k_switch
class _TranslationsWidgetbookKSwitchPt extends TranslationsWidgetbookKSwitchKo {
	_TranslationsWidgetbookKSwitchPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get k_switch => 'Interruptor';
}

// Path: widgetbook.switch_component
class _TranslationsWidgetbookSwitchComponentPt extends TranslationsWidgetbookSwitchComponentKo {
	_TranslationsWidgetbookSwitchComponentPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get switch_label => 'Rótulo do interruptor';
}

// Path: widgetbook.select
class _TranslationsWidgetbookSelectPt extends TranslationsWidgetbookSelectKo {
	_TranslationsWidgetbookSelectPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get apple => 'Maçã';
	@override String get banana => 'Banana';
	@override String get cherry => 'Cereja';
	@override String get date => 'Tâmara';
	@override String get choose_size => 'Escolha o tamanho';
	@override String get small => 'Pequeno';
	@override String get medium => 'Médio';
	@override String get large => 'Grande';
	@override String get extra_large => 'Muito grande';
}

// Path: widgetbook.breadcrumb
class _TranslationsWidgetbookBreadcrumbPt extends TranslationsWidgetbookBreadcrumbKo {
	_TranslationsWidgetbookBreadcrumbPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get home => 'Início';
	@override String get products => 'Produtos';
	@override String get electronics => 'Eletrônicos';
	@override String get smartphones => 'Smartphones';
	@override String get documents => 'Documentos';
	@override String get projects => 'Projetos';
	@override String get current_folder => 'Pasta atual';
	@override String current_path({required Object path}) => 'Caminho atual: ${path}';
}

// Path: widgetbook.badge
class _TranslationsWidgetbookBadgePt extends TranslationsWidgetbookBadgeKo {
	_TranslationsWidgetbookBadgePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get primary => 'Primário';
	@override String get secondary => 'Secundário';
	@override String get outline => 'Contorno';
	@override String get destructive => 'Destrutivo';
	@override String get featured => 'Em destaque';
	@override String get more => 'Mais';
	@override String get verified => 'Verificado';
	@override String get error => 'Erro';
	@override String get click_me => 'Clique aqui';
	@override String get clickable => 'Clicável';
}

// Path: widgetbook.theme_preview
class _TranslationsWidgetbookThemePreviewPt extends TranslationsWidgetbookThemePreviewKo {
	_TranslationsWidgetbookThemePreviewPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pré-visualização do Tema';
	@override String get description => 'Uma visão abrangente de todos os tokens de tema e estilos de componentes.';
	@override String get color_palette => 'Paleta de Cores';
	@override String get brand_colors => 'Cores da Marca';
	@override String get base_colors => 'Cores Base';
	@override String get status_colors => 'Cores de Status';
	@override String get buttons => 'Botões';
	@override String get primary_button => 'Primário';
	@override String get secondary_button => 'Secundário';
	@override String get outline_button => 'Contorno';
	@override String get ghost_button => 'Fantasma';
	@override String get destructive_button => 'Destrutivo';
	@override String get disabled_button => 'Desativado';
	@override String get cards => 'Cartões';
	@override String get card_title => 'Título do Cartão';
	@override String get card_description => 'Descrição de exemplo do cartão.';
	@override String get surface_card => 'Cartão Superfície';
	@override String get filled_variant => 'Estilo preenchido com fundo';
	@override String get form_elements => 'Elementos de Formulário';
	@override String get text_input_placeholder => 'Digite o texto...';
	@override String get checkbox_checked => 'Selecionado';
	@override String get checkbox_unchecked => 'Não Selecionado';
	@override String get toggle_on => 'Ligado';
	@override String get toggle_off => 'Desligado';
	@override String get alerts => 'Alertas';
	@override String get info_alert => 'Alerta de Informação';
	@override String get info_alert_message => 'Esta é uma mensagem informativa.';
	@override String get error_alert => 'Alerta de Erro';
	@override String get error_alert_message => 'Ocorreu um problema.';
	@override String get badges_chips => 'Badges & Chips';
	@override String get primary_badge => 'Primário';
	@override String get secondary_badge => 'Secundário';
	@override String get outline_badge => 'Contorno';
	@override String get destructive_badge => 'Destrutivo';
	@override String get chip_example => 'Favorito';
	@override String get typography => 'Tipografia';
	@override String get heading_1 => 'Título 1';
	@override String get heading_2 => 'Título 2';
	@override String get heading_3 => 'Título 3';
	@override String get heading_4 => 'Título 4';
	@override String get body_text => 'Texto do corpo com peso normal.';
	@override String get small_text => 'Texto pequeno para legenda.';
	@override String get muted_text => 'Texto desfocado para informações adicionais.';
	@override String get bold_text => 'Texto em negrito para ênfase.';
	@override String get spacing_radius => 'Espaçamento & Arredondamento';
	@override String get border_radius => 'Arredondamento de Bordas';
	@override String get loading_states => 'Estados de Carregamento';
}

// Path: widgetbook.chat
class _TranslationsWidgetbookChatPt extends TranslationsWidgetbookChatKo {
	_TranslationsWidgetbookChatPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get hello => 'Olá! Como vai?';
	@override String get doing_great => 'Muito bem, obrigado!';
	@override String get nice_weather => 'Bom tempo hoje!';
	@override String get yes_beautiful => 'Sim, é lindo!';
	@override String get sender => 'Remetente';
	@override String get receiver => 'Destinatário';
}

// Path: widgetbook.multiple_choice
class _TranslationsWidgetbookMultipleChoicePt extends TranslationsWidgetbookMultipleChoiceKo {
	_TranslationsWidgetbookMultipleChoicePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get option_a => 'Option A';
	@override String get option_b => 'Option B';
	@override String get option_c => 'Option C';
	@override String get option_d => 'Option D';
	@override String selected_value({required Object value}) => 'Selecionado: ${value}';
	@override String selected_values({required Object values}) => 'Selecionados: ${values}';
}

// Path: widgetbook.formatted_input
class _TranslationsWidgetbookFormattedInputPt extends TranslationsWidgetbookFormattedInputKo {
	_TranslationsWidgetbookFormattedInputPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get date_format => 'Formato de data (MM/DD/AAAA)';
	@override String get time_format => 'Formato de hora (HH:MM)';
	@override String current_value({required Object value}) => 'Valor atual: ${value}';
}

// Path: widgetbook.swiper
class _TranslationsWidgetbookSwiperPt extends TranslationsWidgetbookSwiperKo {
	_TranslationsWidgetbookSwiperPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get swipe_hint => 'Deslize ou toque para abrir';
	@override String get overlay_content => 'Conteúdo do overlay';
	@override String get close => 'Fechar';
}

// Path: docs.common
class _TranslationsDocsCommonPt extends TranslationsDocsCommonKo {
	_TranslationsDocsCommonPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get app_name => 'coui_flutter';
	@override String get search_documentation => 'Buscar documentação...';
	@override String get docs => 'Documentação';
	@override String get components => 'Componentes';
	@override String get close => 'Fechar';
	@override String get on_this_page => 'Índice desta página';
	@override String get work_in_progress_title => 'Em desenvolvimento';
	@override String get work_in_progress_message => 'Esta página ainda está em desenvolvimento. Volte mais tarde.';
	@override String get add => 'Adicionar';
	@override String get reset => 'Redefinir';
	@override String get prev => 'Anterior';
	@override String get next => 'Próximo';
	@override String get finish => 'Concluir';
	@override String get open => 'Abrir';
	@override String get disabled => 'Desativado';
	@override String get refresh => 'Atualizar';
	@override String get rebuild => 'Reconstruir';
	@override String get change_color => 'Mudar cor';
}

// Path: docs.badges
class _TranslationsDocsBadgesPt extends TranslationsDocsBadgesKo {
	_TranslationsDocsBadgesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get k_new => 'Novo';
	@override String get updated => 'Atualizado';
	@override String get wip => 'Em desenvolvimento';
	@override String get experimental => 'Experimental';
}

// Path: docs.flavors
class _TranslationsDocsFlavorsPt extends TranslationsDocsFlavorsKo {
	_TranslationsDocsFlavorsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get local => 'Local';
	@override String get experimental => 'Experimental';
	@override String get unknown => 'Desconhecido';
}

// Path: docs.navigation
class _TranslationsDocsNavigationPt extends TranslationsDocsNavigationKo {
	_TranslationsDocsNavigationPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get getting_started => 'Começando';
	@override String get animation => 'Animação';
	@override String get control => 'Controle';
	@override String get disclosure => 'Divulgação';
	@override String get display => 'Exibição';
	@override String get feedback => 'Feedback';
	@override String get form => 'Formulário';
	@override String get layout => 'Layout';
	@override String get navigation => 'Navegação';
	@override String get overlay => 'Sobreposição';
	@override String get utility => 'Utilitário';
	@override String get my_account => 'Minha conta';
	@override String get profile => 'Perfil';
	@override String get settings => 'Configurações';
	@override String get team => 'Equipe';
	@override String get new_team => 'Nova equipe';
	@override String get billing => 'Cobrança';
	@override String get api => 'API';
	@override String get log_out => 'Sair';
	@override String get support => 'Suporte';
	@override String get invite_users => 'Convidar usuários';
	@override String get more => 'Mais';
	@override String get github => 'GitHub';
	@override String get note => 'Nota';
	@override String get message => 'Mensagem';
	@override String get keyboard_shortcuts => 'Atalhos de teclado';
}

// Path: docs.pages
class _TranslationsDocsPagesPt extends TranslationsDocsPagesKo {
	_TranslationsDocsPagesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsPagesIntroductionPt introduction = _TranslationsDocsPagesIntroductionPt._(_root);
	@override late final _TranslationsDocsPagesInstallationPt installation = _TranslationsDocsPagesInstallationPt._(_root);
	@override late final _TranslationsDocsPagesThemePt theme = _TranslationsDocsPagesThemePt._(_root);
	@override late final _TranslationsDocsPagesTypographyPt typography = _TranslationsDocsPagesTypographyPt._(_root);
	@override late final _TranslationsDocsPagesLayoutPt layout = _TranslationsDocsPagesLayoutPt._(_root);
	@override late final _TranslationsDocsPagesWebPreloaderPt web_preloader = _TranslationsDocsPagesWebPreloaderPt._(_root);
	@override late final _TranslationsDocsPagesComponentsListPt components_list = _TranslationsDocsPagesComponentsListPt._(_root);
	@override late final _TranslationsDocsPagesIconsPt icons = _TranslationsDocsPagesIconsPt._(_root);
	@override late final _TranslationsDocsPagesColorsPt colors = _TranslationsDocsPagesColorsPt._(_root);
	@override late final _TranslationsDocsPagesExternalPt external = _TranslationsDocsPagesExternalPt._(_root);
	@override late final _TranslationsDocsPagesStatePt state = _TranslationsDocsPagesStatePt._(_root);
}

// Path: docs.components
class _TranslationsDocsComponentsPt extends TranslationsDocsComponentsKo {
	_TranslationsDocsComponentsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsComponentsAccordionPt accordion = _TranslationsDocsComponentsAccordionPt._(_root);
	@override late final _TranslationsDocsComponentsAlertPt alert = _TranslationsDocsComponentsAlertPt._(_root);
	@override late final _TranslationsDocsComponentsAlertDialogPt alert_dialog = _TranslationsDocsComponentsAlertDialogPt._(_root);
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderPt animated_value_builder = _TranslationsDocsComponentsAnimatedValueBuilderPt._(_root);
	@override late final _TranslationsDocsComponentsAppBarPt app_bar = _TranslationsDocsComponentsAppBarPt._(_root);
	@override late final _TranslationsDocsComponentsAutocompletePt autocomplete = _TranslationsDocsComponentsAutocompletePt._(_root);
	@override late final _TranslationsDocsComponentsAvatarPt avatar = _TranslationsDocsComponentsAvatarPt._(_root);
	@override late final _TranslationsDocsComponentsAvatarGroupPt avatar_group = _TranslationsDocsComponentsAvatarGroupPt._(_root);
	@override late final _TranslationsDocsComponentsBadgePt badge = _TranslationsDocsComponentsBadgePt._(_root);
	@override late final _TranslationsDocsComponentsBreadcrumbPt breadcrumb = _TranslationsDocsComponentsBreadcrumbPt._(_root);
	@override late final _TranslationsDocsComponentsButtonPt button = _TranslationsDocsComponentsButtonPt._(_root);
	@override late final _TranslationsDocsComponentsCalendarPt calendar = _TranslationsDocsComponentsCalendarPt._(_root);
	@override late final _TranslationsDocsComponentsCardPt card = _TranslationsDocsComponentsCardPt._(_root);
	@override late final _TranslationsDocsComponentsCardImagePt card_image = _TranslationsDocsComponentsCardImagePt._(_root);
	@override late final _TranslationsDocsComponentsCarouselPt carousel = _TranslationsDocsComponentsCarouselPt._(_root);
	@override late final _TranslationsDocsComponentsCheckboxPt checkbox = _TranslationsDocsComponentsCheckboxPt._(_root);
	@override late final _TranslationsDocsComponentsChipPt chip = _TranslationsDocsComponentsChipPt._(_root);
	@override late final _TranslationsDocsComponentsChipInputPt chip_input = _TranslationsDocsComponentsChipInputPt._(_root);
	@override late final _TranslationsDocsComponentsCircularProgressPt circular_progress = _TranslationsDocsComponentsCircularProgressPt._(_root);
	@override late final _TranslationsDocsComponentsCodeSnippetPt code_snippet = _TranslationsDocsComponentsCodeSnippetPt._(_root);
	@override late final _TranslationsDocsComponentsCollapsiblePt collapsible = _TranslationsDocsComponentsCollapsiblePt._(_root);
	@override late final _TranslationsDocsComponentsColorPickerPt color_picker = _TranslationsDocsComponentsColorPickerPt._(_root);
	@override late final _TranslationsDocsComponentsCommandPt command = _TranslationsDocsComponentsCommandPt._(_root);
	@override late final _TranslationsDocsComponentsContextMenuPt context_menu = _TranslationsDocsComponentsContextMenuPt._(_root);
	@override late final _TranslationsDocsComponentsDatePickerPt date_picker = _TranslationsDocsComponentsDatePickerPt._(_root);
	@override late final _TranslationsDocsComponentsDialogPt dialog = _TranslationsDocsComponentsDialogPt._(_root);
	@override late final _TranslationsDocsComponentsDividerPt divider = _TranslationsDocsComponentsDividerPt._(_root);
	@override late final _TranslationsDocsComponentsDotIndicatorPt dot_indicator = _TranslationsDocsComponentsDotIndicatorPt._(_root);
	@override late final _TranslationsDocsComponentsDrawerPt drawer = _TranslationsDocsComponentsDrawerPt._(_root);
	@override late final _TranslationsDocsComponentsDropdownMenuPt dropdown_menu = _TranslationsDocsComponentsDropdownMenuPt._(_root);
	@override late final _TranslationsDocsComponentsExpandableSidebarPt expandable_sidebar = _TranslationsDocsComponentsExpandableSidebarPt._(_root);
	@override late final _TranslationsDocsComponentsFormPt form = _TranslationsDocsComponentsFormPt._(_root);
	@override late final _TranslationsDocsComponentsFormattedInputPt formatted_input = _TranslationsDocsComponentsFormattedInputPt._(_root);
	@override late final _TranslationsDocsComponentsHoverCardPt hover_card = _TranslationsDocsComponentsHoverCardPt._(_root);
	@override late final _TranslationsDocsComponentsInputPt input = _TranslationsDocsComponentsInputPt._(_root);
	@override late final _TranslationsDocsComponentsInputOtpPt input_otp = _TranslationsDocsComponentsInputOtpPt._(_root);
	@override late final _TranslationsDocsComponentsItemPickerPt item_picker = _TranslationsDocsComponentsItemPickerPt._(_root);
	@override late final _TranslationsDocsComponentsKeyboardDisplayPt keyboard_display = _TranslationsDocsComponentsKeyboardDisplayPt._(_root);
	@override late final _TranslationsDocsComponentsLinearProgressPt linear_progress = _TranslationsDocsComponentsLinearProgressPt._(_root);
	@override late final _TranslationsDocsComponentsMaterialPt material = _TranslationsDocsComponentsMaterialPt._(_root);
	@override late final _TranslationsDocsComponentsMenubarPt menubar = _TranslationsDocsComponentsMenubarPt._(_root);
	@override late final _TranslationsDocsComponentsMultiselectPt multiselect = _TranslationsDocsComponentsMultiselectPt._(_root);
	@override late final _TranslationsDocsComponentsNavigationBarPt navigation_bar = _TranslationsDocsComponentsNavigationBarPt._(_root);
	@override late final _TranslationsDocsComponentsNavigationMenuPt navigation_menu = _TranslationsDocsComponentsNavigationMenuPt._(_root);
	@override late final _TranslationsDocsComponentsNavigationRailPt navigation_rail = _TranslationsDocsComponentsNavigationRailPt._(_root);
	@override late final _TranslationsDocsComponentsNavigationSidebarPt navigation_sidebar = _TranslationsDocsComponentsNavigationSidebarPt._(_root);
	@override late final _TranslationsDocsComponentsNumberInputPt number_input = _TranslationsDocsComponentsNumberInputPt._(_root);
	@override late final _TranslationsDocsComponentsNumberTickerPt number_ticker = _TranslationsDocsComponentsNumberTickerPt._(_root);
	@override late final _TranslationsDocsComponentsOverflowMarqueePt overflow_marquee = _TranslationsDocsComponentsOverflowMarqueePt._(_root);
	@override late final _TranslationsDocsComponentsPaginationPt pagination = _TranslationsDocsComponentsPaginationPt._(_root);
	@override late final _TranslationsDocsComponentsPhoneInputPt phone_input = _TranslationsDocsComponentsPhoneInputPt._(_root);
	@override late final _TranslationsDocsComponentsPopoverPt popover = _TranslationsDocsComponentsPopoverPt._(_root);
	@override late final _TranslationsDocsComponentsProgressPt progress = _TranslationsDocsComponentsProgressPt._(_root);
	@override late final _TranslationsDocsComponentsRadioCardPt radio_card = _TranslationsDocsComponentsRadioCardPt._(_root);
	@override late final _TranslationsDocsComponentsRadioGroupPt radio_group = _TranslationsDocsComponentsRadioGroupPt._(_root);
	@override late final _TranslationsDocsComponentsRefreshTriggerPt refresh_trigger = _TranslationsDocsComponentsRefreshTriggerPt._(_root);
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderPt repeated_animation_builder = _TranslationsDocsComponentsRepeatedAnimationBuilderPt._(_root);
	@override late final _TranslationsDocsComponentsResizablePt resizable = _TranslationsDocsComponentsResizablePt._(_root);
	@override late final _TranslationsDocsComponentsScaffoldPt scaffold = _TranslationsDocsComponentsScaffoldPt._(_root);
	@override late final _TranslationsDocsComponentsSelectPt select = _TranslationsDocsComponentsSelectPt._(_root);
	@override late final _TranslationsDocsComponentsSheetPt sheet = _TranslationsDocsComponentsSheetPt._(_root);
	@override late final _TranslationsDocsComponentsSkeletonPt skeleton = _TranslationsDocsComponentsSkeletonPt._(_root);
	@override late final _TranslationsDocsComponentsSliderPt slider = _TranslationsDocsComponentsSliderPt._(_root);
	@override late final _TranslationsDocsComponentsSortablePt sortable = _TranslationsDocsComponentsSortablePt._(_root);
	@override late final _TranslationsDocsComponentsStarRatingPt star_rating = _TranslationsDocsComponentsStarRatingPt._(_root);
	@override late final _TranslationsDocsComponentsStepperPt stepper = _TranslationsDocsComponentsStepperPt._(_root);
	@override late final _TranslationsDocsComponentsStepsPt steps = _TranslationsDocsComponentsStepsPt._(_root);
	@override late final _TranslationsDocsComponentsSwiperPt swiper = _TranslationsDocsComponentsSwiperPt._(_root);
	@override late final _TranslationsDocsComponentsKSwitchPt k_switch = _TranslationsDocsComponentsKSwitchPt._(_root);
	@override late final _TranslationsDocsComponentsSwitcherPt switcher = _TranslationsDocsComponentsSwitcherPt._(_root);
	@override late final _TranslationsDocsComponentsTabListPt tab_list = _TranslationsDocsComponentsTabListPt._(_root);
	@override late final _TranslationsDocsComponentsTabPanePt tab_pane = _TranslationsDocsComponentsTabPanePt._(_root);
	@override late final _TranslationsDocsComponentsTablePt table = _TranslationsDocsComponentsTablePt._(_root);
	@override late final _TranslationsDocsComponentsTabsPt tabs = _TranslationsDocsComponentsTabsPt._(_root);
	@override late final _TranslationsDocsComponentsTextAreaPt text_area = _TranslationsDocsComponentsTextAreaPt._(_root);
	@override late final _TranslationsDocsComponentsTimePickerPt time_picker = _TranslationsDocsComponentsTimePickerPt._(_root);
	@override late final _TranslationsDocsComponentsTimelinePt timeline = _TranslationsDocsComponentsTimelinePt._(_root);
	@override late final _TranslationsDocsComponentsTimelineAnimationPt timeline_animation = _TranslationsDocsComponentsTimelineAnimationPt._(_root);
	@override late final _TranslationsDocsComponentsToastPt toast = _TranslationsDocsComponentsToastPt._(_root);
	@override late final _TranslationsDocsComponentsTogglePt toggle = _TranslationsDocsComponentsTogglePt._(_root);
	@override late final _TranslationsDocsComponentsTooltipPt tooltip = _TranslationsDocsComponentsTooltipPt._(_root);
	@override late final _TranslationsDocsComponentsTrackerPt tracker = _TranslationsDocsComponentsTrackerPt._(_root);
	@override late final _TranslationsDocsComponentsTreePt tree = _TranslationsDocsComponentsTreePt._(_root);
	@override late final _TranslationsDocsComponentsWindowPt window = _TranslationsDocsComponentsWindowPt._(_root);
}

// Path: docs.pages.introduction
class _TranslationsDocsPagesIntroductionPt extends TranslationsDocsPagesIntroductionKo {
	_TranslationsDocsPagesIntroductionPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Introdução';
	@override String get description => 'Começando com coui_flutter';
	@override String get lead => 'Agora você pode usar os belamente projetados componentes Coui/UI no Flutter.';
	@override String get welcome_paragraph_1 => 'coui_flutter é um conjunto diversificado e abrangente de componentes de UI especialmente projetado para aplicações desktop e web no Flutter. À medida que a popularidade do Flutter para construir aplicativos multiplataforma aumenta, reconhecemos a necessidade de um toolkit que enfatize as necessidades de design únicas para interfaces de desktop e web.';
	@override String get welcome_paragraph_2 => 'Este pacote oferece uma ampla gama de componentes personalizáveis e responsivos que atendem aos princípios modernos de design para desktop e web. Seja construindo aplicações de negócios sofisticadas, painéis elegantes ou ferramentas de produtividade, nossos componentes foram projetados para ajudar você a criar UIs profissionais e elegantes de maneira rápida e eficiente.';
	@override String get features => 'Principais funcionalidades';
	@override late final _TranslationsDocsPagesIntroductionFeaturesListPt features_list = _TranslationsDocsPagesIntroductionFeaturesListPt._(_root);
	@override String get notes => 'Notas';
	@override String get notes_paragraph_1 => 'Este pacote ainda está em desenvolvimento e pode ter alterações no futuro. Use este pacote com cautela em produção.';
	@override String get notes_paragraph_2 => 'Este pacote não é afiliado ao Coui/UI. Este pacote é um projeto liderado pela comunidade.';
	@override String get faq => 'Perguntas frequentes';
	@override String get faq_gorouter_q => 'Suporta GoRouter?';
	@override String get faq_gorouter_a => 'Sim, suporta. Você pode usar o GoRouter com o coui_flutter.';
	@override String get faq_usage_q => 'Posso usar em meu projeto?';
	@override String get faq_usage_a => 'Sim! Você pode usá-lo gratuitamente em projetos pessoais e comerciais. Não é necessário atribuir créditos.';
	@override String get faq_material_q => 'Posso usar com widgets Material/Cupertino?';
	@override String get faq_material_a_1 => 'Claro!';
	@override String get faq_material_a_2 => 'Consulte esta página!';
	@override String get faq_style_q => 'Posso configurar qual estilo usar? (Default/New York)';
	@override String get faq_style_a_1 => 'Infelizmente, não. Este pacote suporta apenas o estilo New York. Mas se você deseja o estilo padrão do Coui/UI,';
	@override String get faq_style_a_2 => 'recomendo este pacote.';
	@override String get faq_style_a_3 => 'Criado por:';
	@override String get links => 'Links';
	@override String get link_github => 'Github: ';
	@override String get link_pubdev => 'pub.dev: ';
	@override String get link_discord => 'Discord: ';
}

// Path: docs.pages.installation
class _TranslationsDocsPagesInstallationPt extends TranslationsDocsPagesInstallationKo {
	_TranslationsDocsPagesInstallationPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Instalação';
	@override String get description => 'Instalando coui_flutter no projeto';
	@override String get stable_version => 'Versão estável';
	@override String get experimental_version => 'Versão experimental';
	@override String get step1_title => 'Criar um novo projeto Flutter';
	@override String get step1_content => 'Use o seguinte comando para criar um novo projeto Flutter:';
	@override String get step2_title => 'Adicionar dependências';
	@override String get step2_content => 'Em seguida, adicione a dependência coui_flutter ao seu projeto.';
	@override String get step3_title => 'Importar o pacote';
	@override String get step3_content => 'Agora você pode importar o pacote no código Dart.';
	@override String get step4_title => 'Adicionar o widget CouiApp';
	@override String get step4_content => 'Adicione o widget CouiApp à função main.';
	@override String get step5_title => 'Executar o aplicativo';
	@override String get step5_content => 'Use o seguinte comando para executar o aplicativo:';
	@override String get experimental_intro => 'A versão experimental está disponível no GitHub.';
	@override String get experimental_usage => 'Para usar a versão experimental, utilize git em vez do número da versão no arquivo pubspec.yaml:';
	@override String get see_page => 'Consulte: ';
	@override String get this_page => 'esta página';
	@override String get for_more_info => ' para mais informações.';
	@override String get warning_title => 'Aviso';
	@override String get warning_content => 'A versão experimental pode conter alterações que quebram a compatibilidade e não é recomendada para uso em produção. Esta versão é destinada apenas para testes e desenvolvimento.';
}

// Path: docs.pages.theme
class _TranslationsDocsPagesThemePt extends TranslationsDocsPagesThemeKo {
	_TranslationsDocsPagesThemePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tema';
	@override String get description => 'Personalizando o tema';
	@override String get custom_color_scheme => 'Esquema de cores personalizado';
	@override String get custom_color_scheme_desc => 'Você pode personalizar a aparência e sensação do aplicativo usando um esquema de cores personalizado.';
	@override String get premade_color_schemes => 'Esquemas de cores pré-fabricados';
	@override String get premade_color_schemes_desc => 'Você pode personalizar a aparência e sensação do aplicativo usando esquemas de cores pré-fabricados.';
	@override String get radius => 'Raio';
	@override String get radius_desc => 'Você pode personalizar o quão arredondadas as bordas do aplicativo parecem alterando o raio.';
	@override String get scaling => 'Escalonamento';
	@override String get scaling_desc => 'Você pode personalizar a escala dos componentes do coui_flutter alterando o escalonamento.';
	@override String get scaling_alert => 'Não escala todo o aplicativo. Apenas os componentes do coui_flutter são afetados.';
	@override String get surface_opacity => 'Opacidade da superfície';
	@override String get surface_opacity_desc => 'Você pode personalizar a opacidade da superfície alterando a opacidade.';
	@override String get surface_blur => 'Desfoque da superfície';
	@override String get surface_blur_desc => 'Você pode personalizar o desfoque da superfície alterando o desfoque.';
	@override String get code => 'Código';
	@override String get code_desc => 'Use o seguinte código para aplicar o esquema de cores.';
}

// Path: docs.pages.typography
class _TranslationsDocsPagesTypographyPt extends TranslationsDocsPagesTypographyKo {
	_TranslationsDocsPagesTypographyPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tipografia';
	@override String get description => 'Estilos de texto';
	@override String get headline1 => 'Cabeçalho 1';
	@override String get headline2 => 'Cabeçalho 2';
	@override String get headline3 => 'Cabeçalho 3';
	@override String get headline4 => 'Cabeçalho 4';
	@override String get paragraph => 'Parágrafo';
	@override String get blockquote => 'Citação';
	@override String get list => 'Lista';
	@override String get inline_code => 'Código inline';
	@override String get lead => 'Lead';
	@override String get large_text => 'Texto grande';
	@override String get small_text => 'Texto pequeno';
	@override String get muted_text => 'Texto em cinza';
	@override String get sans => 'Sans';
	@override String get mono => 'Mono';
	@override String get extra_small => 'Muito pequeno';
	@override String get small => 'Pequeno';
	@override String get base => 'Base';
	@override String get large => 'Grande';
	@override String get extra_large => 'Muito grande';
	@override String get extra_2x_large => 'Muito 2x grande';
	@override String get extra_3x_large => 'Muito 3x grande';
	@override String get extra_4x_large => 'Muito 4x grande';
	@override String get extra_5x_large => 'Muito 5x grande';
	@override String get extra_6x_large => 'Muito 6x grande';
	@override String get extra_7x_large => 'Muito 7x grande';
	@override String get extra_8x_large => 'Muito 8x grande';
	@override String get extra_9x_large => 'Muito 9x grande';
	@override String get thin => 'Fino';
	@override String get extra_light => 'Muito leve';
	@override String get light => 'Leve';
	@override String get normal => 'Normal';
	@override String get medium => 'Médio';
	@override String get semi_bold => 'Semi negrito';
	@override String get bold => 'Negrito';
	@override String get extra_bold => 'Muito negrito';
	@override String get black => 'Preto';
	@override String get italic => 'Itálico';
}

// Path: docs.pages.layout
class _TranslationsDocsPagesLayoutPt extends TranslationsDocsPagesLayoutKo {
	_TranslationsDocsPagesLayoutPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Layout';
	@override String get description => 'Configurando o layout da página';
	@override String get padding => 'Preenchimento';
	@override String get margin => 'Margem';
	@override String get center => 'Centro';
	@override String get gapped_column => 'Coluna com espaço';
	@override String get gapped_row => 'Linha com espaço';
	@override String get separated_column => 'Coluna separada';
	@override String get separated_row => 'Linha separada';
	@override String get basic_layout => 'Layout básico';
}

// Path: docs.pages.web_preloader
class _TranslationsDocsPagesWebPreloaderPt extends TranslationsDocsPagesWebPreloaderKo {
	_TranslationsDocsPagesWebPreloaderPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pré-carregador da Web';
	@override String get description => 'Tela de carregamento da Web';
	@override String get step1_title => 'Criar diretório da web';
	@override String get step1_content => 'Crie um diretório da web se não existir.';
	@override String get step1_note => '* Se você está usando a Flutter web legado, você deve usar o comando acima para fazer upgrade.';
	@override String get step1_button => 'Clique aqui para mais informações.';
	@override String get step2_title => 'Adicionar scripts';
	@override String get step2_content => 'Em seguida, escolha e copie um dos pré-carregadores pré-fabricados abaixo:';
	@override String get step2_standard => 'Pré-carregador padrão';
	@override String get step3_title => 'Colar o script';
	@override String get step3_content_1 => 'Abra seu ';
	@override String get step3_content_2 => ' arquivo e cole o script entre a tag ';
	@override String get step3_content_3 => '.';
	@override String get step3_example => 'Por exemplo:';
	@override String get step4_title => 'Executar o aplicativo';
	@override String get step4_content => 'Use o comando abaixo para executar o aplicativo:';
	@override String get alert_title => 'Contribuir';
	@override String get alert_content_1 => 'Se você tem algum pré-carregador que gostaria de compartilhar, por favor, crie um pull request na pastas ';
	@override String get alert_button => 'web_loaders';
	@override String get alert_content_2 => '.';
}

// Path: docs.pages.components_list
class _TranslationsDocsPagesComponentsListPt extends TranslationsDocsPagesComponentsListKo {
	_TranslationsDocsPagesComponentsListPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Componentes';
	@override String get description => 'Lista de componentes reutilizáveis';
	@override String get work_in_progress => 'Em andamento';
	@override String get animation => 'Animação';
	@override String get disclosure => 'Divulgação';
	@override String get feedback => 'Feedback';
	@override String get forms => 'Formulários';
	@override String get layout => 'Layout';
	@override String get navigation => 'Navegação';
	@override String get surfaces => 'Superfícies';
	@override String get data_display => 'Exibição de dados';
	@override String get utilities => 'Utilidades';
}

// Path: docs.pages.icons
class _TranslationsDocsPagesIconsPt extends TranslationsDocsPagesIconsKo {
	_TranslationsDocsPagesIconsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ícones';
	@override String get description => 'Sistema de ícones';
	@override String get use_this_code => 'Use o seguinte código para exibir este ícone:';
	@override String get search_icons => 'Pesquisar ícones';
	@override String get radix_icons => 'Ícones Radix';
	@override String get bootstrap_icons => 'Ícones Bootstrap';
	@override String get lucide_icons => 'Ícones Lucide';
}

// Path: docs.pages.colors
class _TranslationsDocsPagesColorsPt extends TranslationsDocsPagesColorsKo {
	_TranslationsDocsPagesColorsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cores';
	@override String get description => 'Paleta de cores';
	@override String get use_this_code => 'Use o seguinte código para exibir esta cor:';
	@override String get color_and_colorshades => 'Constantes Color e ColorShades/ColorSwatch';
	@override String get predefined_colors => 'Cores pré-definidas';
	@override String get generate_color => 'Gerar cor';
	@override String get hue_shift => 'Mudança de matiz';
	@override String get saturation_step_up => 'Aumento de saturação';
	@override String get saturation_step_down => 'Diminuição de saturação';
	@override String get lightness_step_up => 'Aumento de luminosidade';
	@override String get lightness_step_down => 'Diminuição de luminosidade';
	@override String get cancel => 'Cancelar';
	@override String get reset_options => 'Redefinir opções';
	@override String get reset_confirmation => 'Você tem certeza que deseja redefinir as opções?';
}

// Path: docs.pages.external
class _TranslationsDocsPagesExternalPt extends TranslationsDocsPagesExternalKo {
	_TranslationsDocsPagesExternalPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Material/Cupertino';
	@override String get description => 'Widgets padrão do Flutter';
}

// Path: docs.pages.state
class _TranslationsDocsPagesStatePt extends TranslationsDocsPagesStateKo {
	_TranslationsDocsPagesStatePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gerenciamento de Estado';
	@override String get description => 'Padrões de gerenciamento de estado';
	@override String get intro_1 => 'No Flutter, tudo é um widget e onde os dados são armazenados também.';
	@override String get intro_2 => 'Internamente, o coui_flutter possui seu próprio sistema de gerenciamento de estado. Se você já estiver usando um sistema de gerenciamento de estado, pode continuar usando-o junto com o coui_flutter.';
	@override String get passing_data_to_children => 'Passando dados para filhos';
	@override String get passing_data_desc => 'Você pode passar dados para filhos usando o widget Data. Todas as alterações nos dados resultarão na reconstrução das crianças.';
	@override String get rebuild_difference_title => 'Você notou a diferença nas contagens de reconstrução?';
	@override String get rebuild_difference_content => 'MostInnerWidget é reconstruído quando os dados mudam, mas InnerWidget não é. Isso ocorre porque InnerWidget não recebe os dados.';
	@override String get setting_data_boundary => 'Definindo limite de dados';
	@override String get setting_data_boundary_desc => 'Você pode definir limites para que as crianças não tenham acesso aos dados.';
	@override String get data_methods_vs => 'Data.maybeOf/Data.of vs Data.maybeFind/Data.find';
	@override String get data_methods_desc_1 => ' e ';
	@override String get data_methods_desc_2 => ' recebem dados e reconstróem o widget quando os dados mudam. Por outro lado, ';
	@override String get data_methods_desc_3 => ' não recebe dados, apenas os retorna.';
	@override String get data_find_usage => ' é melhor utilizado em lugares onde o método é chamado uma vez, como onPressed, onLongPressed, etc.';
	@override String get data_of_usage => ' é melhor utilizado dentro do método de construção onde o widget precisa ser reconstruído quando os dados mudam.';
	@override String get getting_data_from_child => 'Obtendo dados do filho';
	@override String get getting_data_desc_1 => ' Você pode usar o método para obter dados de um filho. Esse método não recebe as alterações nos dados.';
	@override String get getting_data_desc_2 => 'Receber dados de filhos pode causar um loop de reconstrução infinita. Se você precisa receber dados, mova-os para o widget pai.';
	@override String get root_data_title => 'Você notou os dados da raiz?';
	@override String get root_data_content => 'Ele usa os dados dos dados mais internos à esquerda. O pai só pode obter dados de um filho que esteja diretamente conectado.';
	@override String get setting_messenger_boundary => 'Definindo limite do DataMessenger';
	@override String get setting_messenger_boundary_desc => 'Você pode definir limites para que os filhos não possam obter dados de um pai específico.';
	@override String get multidata_widget => 'Widget MultiData';
	@override String get multidata_desc => 'O widget MultiData permite que você passe várias informações para filhos. Veja o exemplo abaixo:';
	@override String get multidata_avoid_nesting => 'Evitando aninhamento usando o widget MultiData.';
	@override String get example => 'Exemplo';
	@override String get passing_state_as_controller => 'Passando estado como controlador';
	@override String get passing_state_controller_desc => 'Você pode passar estado para filhos como um controlador. Isso permitirá que seus filhos chamem métodos do widget pai.';
	@override String get databuilder => 'DataBuilder';
	@override String get databuilder_desc => 'O widget DataBuilder permite que o widget seja reconstruído quando os dados mudam. Isso evita reconstruir o widget inteiro.';
	@override String get datanotifier => 'DataNotifier';
	@override String get datanotifier_desc => 'Usando DataNotifier, você pode passar valores para filhos a partir de ValueListenable.';
	@override String get example_with_multidata => 'Exemplo usando MultiData';
	@override String get passing_object_as_data => 'Passando um objeto como dados';
	@override String get passing_object_desc => 'Aqui estão algumas considerações a serem feitas ao passar um objeto como dados:';
	@override String get override_equals_hashcode => '1. Sobrescrever == e hashCode';
	@override String get override_equals_desc => 'Notificações são enviadas para filhos se um objeto anterior não for igual ao novo. Se == e hashCode não forem sobrescritos, mesmo que os valores de campo sejam idênticos, cada nova instância do objeto será sempre considerada diferente.';
	@override String get use_distinctdata => '2. Usar DistinctData';
	@override String get use_distinctdata_desc => 'DistinctData é um mixin que pode notificar os filhos quando um campo específico muda.';
	@override String get passing_mutable_object => '3. Passando objeto mutável para filhos';
	@override String get passing_mutable_object_desc => 'É recomendável passar objetos imutáveis para filhos. Objetos mutáveis (por exemplo, List, Map, Set, Widget State) não notificarão os filhos quando o objeto mudar, pois a referência do objeto não muda.';
	@override String get passing_variable_to_children => 'Passando variáveis para filhos';
	@override String get passing_variable_desc => 'Você pode usar o widget Model para passar variáveis para filhos. Ele é semelhante ao widget Data, mas é estritamente tipado e rotulado.';
	@override String get change_variable_from_children => 'Alterando variáveis a partir de filhos';
	@override String get change_variable_desc => 'Existem duas maneiras de mudar o valor do modelo a partir de filhos:';
	@override String get modelnotifier => 'ModelNotifier';
	@override String get modelnotifier_desc => 'Usando ModelNotifier, você pode passar valores para filhos a partir de ValueNotifier. Não é necessário usar setState no widget pai.';
	@override String get modellistenable => 'ModelListenable';
	@override String get modellistenable_desc => 'ModelListenable é um ModelNotifier somente para leitura. Os filhos só podem receber valores. Se tentarem mudar o valor, ocorrerá um erro.';
	@override String get modelbuilder => 'ModelBuilder';
	@override String get modelbuilder_desc => 'O ModelBuilder recebe e reconstrói widgets quando o valor muda. É semelhante ao DataBuilder, mas é estritamente tipado e rotulado.';
}

// Path: docs.components.accordion
class _TranslationsDocsComponentsAccordionPt extends TranslationsDocsComponentsAccordionKo {
	_TranslationsDocsComponentsAccordionPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Acordeão';
	@override String get description => 'Um acordeão é uma lista de itens empilhados verticalmente. Cada item pode ser \'expandido\' ou \'recolhido\' para mostrar o conteúdo relacionado.';
	@override late final _TranslationsDocsComponentsAccordionExamplesPt examples = _TranslationsDocsComponentsAccordionExamplesPt._(_root);
}

// Path: docs.components.alert
class _TranslationsDocsComponentsAlertPt extends TranslationsDocsComponentsAlertKo {
	_TranslationsDocsComponentsAlertPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Alerta';
	@override String get description => 'Os alertas são usados para comunicar estados que afetam o sistema.';
	@override late final _TranslationsDocsComponentsAlertExamplesPt examples = _TranslationsDocsComponentsAlertExamplesPt._(_root);
	@override String get title => 'Título do Alerta';
	@override String get content => 'Conteúdo do alerta.';
}

// Path: docs.components.alert_dialog
class _TranslationsDocsComponentsAlertDialogPt extends TranslationsDocsComponentsAlertDialogKo {
	_TranslationsDocsComponentsAlertDialogPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Diálogo de Alerta';
	@override String get description => 'Diálogo de alerta exibe informações importantes que requerem a atenção do usuário.';
	@override late final _TranslationsDocsComponentsAlertDialogExamplesPt examples = _TranslationsDocsComponentsAlertDialogExamplesPt._(_root);
	@override String get click_here => 'Clique aqui';
	@override String get alert_title => 'Título do Alerta';
	@override String get alert_content => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
}

// Path: docs.components.animated_value_builder
class _TranslationsDocsComponentsAnimatedValueBuilderPt extends TranslationsDocsComponentsAnimatedValueBuilderKo {
	_TranslationsDocsComponentsAnimatedValueBuilderPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Construtor de Valor Animado';
	@override String get description => 'Um construtor que aplica animações automaticamente ao alterar valores.';
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderExamplesPt examples = _TranslationsDocsComponentsAnimatedValueBuilderExamplesPt._(_root);
}

// Path: docs.components.app_bar
class _TranslationsDocsComponentsAppBarPt extends TranslationsDocsComponentsAppBarKo {
	_TranslationsDocsComponentsAppBarPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barra do App';
	@override String get description => 'A barra do app é o elemento de navegação principal exibido no topo do app.';
	@override late final _TranslationsDocsComponentsAppBarExamplesPt examples = _TranslationsDocsComponentsAppBarExamplesPt._(_root);
}

// Path: docs.components.autocomplete
class _TranslationsDocsComponentsAutocompletePt extends TranslationsDocsComponentsAutocompleteKo {
	_TranslationsDocsComponentsAutocompletePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Autocompletar';
	@override String get description => 'Campo de entrada que exibe sugestões com base na entrada do usuário.';
	@override late final _TranslationsDocsComponentsAutocompleteExamplesPt examples = _TranslationsDocsComponentsAutocompleteExamplesPt._(_root);
}

// Path: docs.components.avatar
class _TranslationsDocsComponentsAvatarPt extends TranslationsDocsComponentsAvatarKo {
	_TranslationsDocsComponentsAvatarPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Avatar';
	@override String get description => 'Uma imagem ou ícone que representa um usuário ou entidade.';
	@override late final _TranslationsDocsComponentsAvatarExamplesPt examples = _TranslationsDocsComponentsAvatarExamplesPt._(_root);
}

// Path: docs.components.avatar_group
class _TranslationsDocsComponentsAvatarGroupPt extends TranslationsDocsComponentsAvatarGroupKo {
	_TranslationsDocsComponentsAvatarGroupPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Grupo de Avatares';
	@override String get description => 'Exibe vários avatares juntos.';
	@override late final _TranslationsDocsComponentsAvatarGroupExamplesPt examples = _TranslationsDocsComponentsAvatarGroupExamplesPt._(_root);
}

// Path: docs.components.badge
class _TranslationsDocsComponentsBadgePt extends TranslationsDocsComponentsBadgeKo {
	_TranslationsDocsComponentsBadgePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Distintivo';
	@override String get description => 'Um pequeno rótulo que exibe status ou contagem de notificações.';
	@override late final _TranslationsDocsComponentsBadgeExamplesPt examples = _TranslationsDocsComponentsBadgeExamplesPt._(_root);
	@override String get primary => 'Primário';
	@override String get secondary => 'Secundário';
	@override String get outline => 'Contornado';
	@override String get destructive => 'Destrutivo';
}

// Path: docs.components.breadcrumb
class _TranslationsDocsComponentsBreadcrumbPt extends TranslationsDocsComponentsBreadcrumbKo {
	_TranslationsDocsComponentsBreadcrumbPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Breadcrumb';
	@override String get description => 'O breadcrumb é um sistema de navegação secundária que indica a posição do usuário em um site ou aplicativo web.';
	@override late final _TranslationsDocsComponentsBreadcrumbExamplesPt examples = _TranslationsDocsComponentsBreadcrumbExamplesPt._(_root);
	@override String get home => 'Início';
	@override String get components => 'Componentes';
}

// Path: docs.components.button
class _TranslationsDocsComponentsButtonPt extends TranslationsDocsComponentsButtonKo {
	_TranslationsDocsComponentsButtonPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Botão';
	@override String get description => 'Os botões permitem que o usuário execute ações e faça seleções com um único toque.';
	@override late final _TranslationsDocsComponentsButtonExamplesPt examples = _TranslationsDocsComponentsButtonExamplesPt._(_root);
	@override String get primary => 'Primário';
	@override String get secondary => 'Secundário';
	@override String get outlined => 'Contornado';
	@override String get ghost => 'Fantasma';
	@override String get destructive => 'Destrutivo';
	@override String get link => 'Link';
	@override String get outline => 'Contornado';
	@override String get text => 'Texto';
	@override String get extra_small => 'Muito Pequeno';
	@override String get small => 'Pequeno';
	@override String get normal => 'Normal';
	@override String get large => 'Grande';
	@override String get extra_large => 'Muito Grande';
	@override String get save => 'Salvar';
	@override String get cancel => 'Cancelar';
	@override String get close => 'Fechar';
	@override String get submit => 'Enviar';
	@override String get edit_profile => 'Editar Perfil';
	@override String get save_changes => 'Salvar Alterações';
	@override String get undo => 'Desfazer';
	@override String get compact => 'Compacto';
	@override String get dense => 'Compacto';
	@override String get comfortable => 'Confortável';
	@override String get icon => 'Ícone';
	@override String get icon_comfortable => 'Ícone Confortável';
	@override String get rectangle => 'Retângulo';
	@override String get add => 'Adicionar';
	@override String get focused => 'Focado';
	@override String get hovered => 'Pairando';
	@override String get pressed => 'Pressionado';
	@override String get text_button => 'Botão de Texto';
	@override String get custom_button => 'Botão Personalizado';
}

// Path: docs.components.calendar
class _TranslationsDocsComponentsCalendarPt extends TranslationsDocsComponentsCalendarKo {
	_TranslationsDocsComponentsCalendarPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Calendário';
	@override String get description => 'Um componente de calendário para selecionar e exibir datas.';
	@override late final _TranslationsDocsComponentsCalendarExamplesPt examples = _TranslationsDocsComponentsCalendarExamplesPt._(_root);
}

// Path: docs.components.card
class _TranslationsDocsComponentsCardPt extends TranslationsDocsComponentsCardKo {
	_TranslationsDocsComponentsCardPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Cartão';
	@override String get description => 'Descrição';
	@override late final _TranslationsDocsComponentsCardExamplesPt examples = _TranslationsDocsComponentsCardExamplesPt._(_root);
	@override String get create_project => 'Criar Projeto';
	@override String get deploy_description => 'Implante um novo projeto com um clique';
	@override String get name => 'Nome';
	@override String get name_placeholder => 'Nome do projeto';
	@override String get description_placeholder => 'Descrição do projeto';
	@override String get deploy => 'Implantar';
}

// Path: docs.components.card_image
class _TranslationsDocsComponentsCardImagePt extends TranslationsDocsComponentsCardImageKo {
	_TranslationsDocsComponentsCardImagePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Cartão de Imagem';
	@override String get description => 'Um componente de cartão que contém uma imagem.';
	@override late final _TranslationsDocsComponentsCardImageExamplesPt examples = _TranslationsDocsComponentsCardImageExamplesPt._(_root);
	@override String get card_image_title => 'Imagem do Cartão';
	@override String get card_clicked => 'Você clicou na imagem do cartão';
	@override String card_number({required Object n}) => 'Número do cartão ${n}';
	@override String get lorem_ipsum => 'Lorem ipsum dolor sit amet';
}

// Path: docs.components.carousel
class _TranslationsDocsComponentsCarouselPt extends TranslationsDocsComponentsCarouselKo {
	_TranslationsDocsComponentsCarouselPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Carrossel';
	@override String get description => 'Um componente que exibe vários itens em slides.';
	@override late final _TranslationsDocsComponentsCarouselExamplesPt examples = _TranslationsDocsComponentsCarouselExamplesPt._(_root);
}

// Path: docs.components.checkbox
class _TranslationsDocsComponentsCheckboxPt extends TranslationsDocsComponentsCheckboxKo {
	_TranslationsDocsComponentsCheckboxPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Checkbox';
	@override String get description => 'Os checkboxes permitem que os usuários selecionem um ou mais itens de uma lista.';
	@override late final _TranslationsDocsComponentsCheckboxExamplesPt examples = _TranslationsDocsComponentsCheckboxExamplesPt._(_root);
	@override String get remember_me => 'Lembrar-me';
}

// Path: docs.components.chip
class _TranslationsDocsComponentsChipPt extends TranslationsDocsComponentsChipKo {
	_TranslationsDocsComponentsChipPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Chip';
	@override String get description => 'Os chips são pequenos elementos que representam atributos, opções ou ações.';
	@override late final _TranslationsDocsComponentsChipExamplesPt examples = _TranslationsDocsComponentsChipExamplesPt._(_root);
	@override String get apple => 'Maçã';
	@override String get banana => 'Banana';
	@override String get cherry => 'Cereja';
	@override String get durian => 'Durian';
	@override String get elderberry => 'Elderberry';
}

// Path: docs.components.chip_input
class _TranslationsDocsComponentsChipInputPt extends TranslationsDocsComponentsChipInputKo {
	_TranslationsDocsComponentsChipInputPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrada de Chip';
	@override String get description => 'Um campo de entrada onde vários valores podem ser inseridos como chips.';
	@override late final _TranslationsDocsComponentsChipInputExamplesPt examples = _TranslationsDocsComponentsChipInputExamplesPt._(_root);
}

// Path: docs.components.circular_progress
class _TranslationsDocsComponentsCircularProgressPt extends TranslationsDocsComponentsCircularProgressKo {
	_TranslationsDocsComponentsCircularProgressPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Progresso Circular';
	@override String get description => 'Um indicador de progresso circular.';
	@override late final _TranslationsDocsComponentsCircularProgressExamplesPt examples = _TranslationsDocsComponentsCircularProgressExamplesPt._(_root);
	@override String get increase_by_10 => 'Aumentar em 10';
	@override String get decrease_by_10 => 'Diminuir em 10';
}

// Path: docs.components.code_snippet
class _TranslationsDocsComponentsCodeSnippetPt extends TranslationsDocsComponentsCodeSnippetKo {
	_TranslationsDocsComponentsCodeSnippetPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Trecho de Código';
	@override String get description => 'Um componente para exibir código.';
	@override late final _TranslationsDocsComponentsCodeSnippetExamplesPt examples = _TranslationsDocsComponentsCodeSnippetExamplesPt._(_root);
}

// Path: docs.components.collapsible
class _TranslationsDocsComponentsCollapsiblePt extends TranslationsDocsComponentsCollapsibleKo {
	_TranslationsDocsComponentsCollapsiblePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Colapsável';
	@override String get description => 'Um contêiner de conteúdo que pode ser colapsado ou expandido.';
	@override late final _TranslationsDocsComponentsCollapsibleExamplesPt examples = _TranslationsDocsComponentsCollapsibleExamplesPt._(_root);
	@override String get starred_repositories => '@coco-de marcou 3 repositórios com estrela';
	@override String get collapse_all => 'Colapsar tudo';
	@override String get expand_all => 'Expandir tudo';
	@override String get expand_icon => 'Ícone de Expandir';
	@override String get use_path_branch => 'Usar caminho do ramo';
	@override String get recursive_selection => 'Seleção recursiva';
}

// Path: docs.components.color_picker
class _TranslationsDocsComponentsColorPickerPt extends TranslationsDocsComponentsColorPickerKo {
	_TranslationsDocsComponentsColorPickerPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Seletor de Cores';
	@override String get description => 'Um componente que permite selecionar cores.';
	@override late final _TranslationsDocsComponentsColorPickerExamplesPt examples = _TranslationsDocsComponentsColorPickerExamplesPt._(_root);
	@override String get pick_color => 'Selecionar cor';
	@override String color_label({required Object color}) => 'Cor: ${color}';
	@override String get select_color => 'Selecionar cor';
	@override String get open_color_picker_popover => 'Abrir popover do seletor de cores';
	@override String get open_color_picker_dialog => 'Abrir diálogo do seletor de cores';
}

// Path: docs.components.command
class _TranslationsDocsComponentsCommandPt extends TranslationsDocsComponentsCommandKo {
	_TranslationsDocsComponentsCommandPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Comando';
	@override String get description => 'O Comando é um componente para pesquisar itens.';
	@override late final _TranslationsDocsComponentsCommandExamplesPt examples = _TranslationsDocsComponentsCommandExamplesPt._(_root);
}

// Path: docs.components.context_menu
class _TranslationsDocsComponentsContextMenuPt extends TranslationsDocsComponentsContextMenuKo {
	_TranslationsDocsComponentsContextMenuPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Menu de Contexto';
	@override String get description => 'Menu que aparece ao clicar com o botão direito ou pressionar e segurar.';
	@override late final _TranslationsDocsComponentsContextMenuExamplesPt examples = _TranslationsDocsComponentsContextMenuExamplesPt._(_root);
}

// Path: docs.components.date_picker
class _TranslationsDocsComponentsDatePickerPt extends TranslationsDocsComponentsDatePickerKo {
	_TranslationsDocsComponentsDatePickerPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Seletor de Data';
	@override String get description => 'Um campo de entrada para selecionar uma data.';
	@override late final _TranslationsDocsComponentsDatePickerExamplesPt examples = _TranslationsDocsComponentsDatePickerExamplesPt._(_root);
	@override String get select_date => 'Selecionar Data';
	@override String get select_date_range => 'Selecionar Intervalo de Datas';
}

// Path: docs.components.dialog
class _TranslationsDocsComponentsDialogPt extends TranslationsDocsComponentsDialogKo {
	_TranslationsDocsComponentsDialogPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Diálogo';
	@override String get description => 'Um diálogo é uma janela modal que aparece sobre o restante do app.';
	@override late final _TranslationsDocsComponentsDialogExamplesPt examples = _TranslationsDocsComponentsDialogExamplesPt._(_root);
	@override String get edit_profile_title => 'Editar Perfil';
	@override String get edit_profile_description => 'Altere seu perfil aqui. Clique em salvar quando terminar.';
	@override String get name_label => 'Nome';
	@override String get username_label => 'Nome de Usuário';
	@override String get hello => 'Olá';
	@override String get material_dialog_content => 'Este é um diálogo Material';
	@override String get cupertino_dialog_content => 'Este é um diálogo Cupertino';
	@override String get alert_title => 'Título do Alerta';
	@override String get click_here => 'Clique aqui';
	@override String get ok => 'OK';
	@override String get open_material_dialog => 'Abrir diálogo Material';
	@override String get open_cupertino_dialog => 'Abrir diálogo Cupertino';
	@override String get open_coui_dialog => 'Abrir diálogo COUI';
}

// Path: docs.components.divider
class _TranslationsDocsComponentsDividerPt extends TranslationsDocsComponentsDividerKo {
	_TranslationsDocsComponentsDividerPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Divisor';
	@override String get description => 'Uma linha que visualmente separa conteúdo.';
	@override late final _TranslationsDocsComponentsDividerExamplesPt examples = _TranslationsDocsComponentsDividerExamplesPt._(_root);
	@override String get item_1 => 'Item 1';
	@override String get item_2 => 'Item 2';
	@override String get item_3 => 'Item 3';
	@override String get divider => 'Divisor';
}

// Path: docs.components.dot_indicator
class _TranslationsDocsComponentsDotIndicatorPt extends TranslationsDocsComponentsDotIndicatorKo {
	_TranslationsDocsComponentsDotIndicatorPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Indicador de Pontos';
	@override String get description => 'Um indicador que mostra a posição atual com um ponto.';
	@override late final _TranslationsDocsComponentsDotIndicatorExamplesPt examples = _TranslationsDocsComponentsDotIndicatorExamplesPt._(_root);
}

// Path: docs.components.drawer
class _TranslationsDocsComponentsDrawerPt extends TranslationsDocsComponentsDrawerKo {
	_TranslationsDocsComponentsDrawerPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Drawer';
	@override String get description => 'Um painel que desliza a partir da borda da tela.';
	@override late final _TranslationsDocsComponentsDrawerExamplesPt examples = _TranslationsDocsComponentsDrawerExamplesPt._(_root);
	@override String get open_drawer => 'Abrir Drawer';
	@override String get close_drawer => 'Fechar Drawer';
	@override String get open_another_drawer => 'Abrir outro Drawer';
	@override String drawer_at({required Object count, required Object position}) => 'Drawer ${count} em ${position}';
}

// Path: docs.components.dropdown_menu
class _TranslationsDocsComponentsDropdownMenuPt extends TranslationsDocsComponentsDropdownMenuKo {
	_TranslationsDocsComponentsDropdownMenuPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Menu Suspenso';
	@override String get description => 'Um menu que exibe uma lista de opções selecionáveis.';
	@override late final _TranslationsDocsComponentsDropdownMenuExamplesPt examples = _TranslationsDocsComponentsDropdownMenuExamplesPt._(_root);
}

// Path: docs.components.expandable_sidebar
class _TranslationsDocsComponentsExpandableSidebarPt extends TranslationsDocsComponentsExpandableSidebarKo {
	_TranslationsDocsComponentsExpandableSidebarPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Sidebar Expandível';
	@override String get description => 'Uma sidebar que pode ser expandida e recolhida.';
	@override late final _TranslationsDocsComponentsExpandableSidebarExamplesPt examples = _TranslationsDocsComponentsExpandableSidebarExamplesPt._(_root);
}

// Path: docs.components.form
class _TranslationsDocsComponentsFormPt extends TranslationsDocsComponentsFormKo {
	_TranslationsDocsComponentsFormPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Formulário';
	@override String get description => 'Um widget auxiliar que facilita a validação de formulários.';
	@override late final _TranslationsDocsComponentsFormExamplesPt examples = _TranslationsDocsComponentsFormExamplesPt._(_root);
	@override String get username_label => 'Nome de Usuário';
	@override String get username_hint => 'Nome que será exibido publicamente';
	@override String get password_label => 'Senha';
	@override String get confirm_password_label => 'Confirmar Senha';
	@override String get passwords_do_not_match => 'As senhas não coincidem';
	@override String get agree_terms => 'Concordo com os Termos de Serviço';
	@override String get must_agree_terms => 'Você deve concordar com os Termos de Serviço';
	@override String get form_values_title => 'Valores do Formulário';
	@override String get register => 'Registrar';
	@override String get username_already_taken => 'Nome de usuário já está em uso';
	@override String get email => 'Email';
	@override String username_display({required Object value}) => 'Nome de Usuário: ${value}';
	@override String password_display({required Object value}) => 'Senha: ${value}';
	@override String confirm_password_display({required Object value}) => 'Confirmar Senha: ${value}';
	@override String agree_display({required Object value}) => 'Concordar: ${value}';
	@override String json_display({required Object value}) => 'JSON: ${value}';
	@override String submitted_value_display({required Object value}) => 'Valor Enviado: ${value}';
	@override String get login => 'Entrar';
	@override String get sign_up => 'Inscrever-se';
	@override String get dont_have_account => 'Não tem uma conta? ';
	@override String get already_have_account => 'Já tem uma conta? ';
}

// Path: docs.components.formatted_input
class _TranslationsDocsComponentsFormattedInputPt extends TranslationsDocsComponentsFormattedInputKo {
	_TranslationsDocsComponentsFormattedInputPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrada Formatada';
	@override String get description => 'Campo de texto em que a entrada é formatada de acordo com um determinado padrão.';
	@override late final _TranslationsDocsComponentsFormattedInputExamplesPt examples = _TranslationsDocsComponentsFormattedInputExamplesPt._(_root);
}

// Path: docs.components.hover_card
class _TranslationsDocsComponentsHoverCardPt extends TranslationsDocsComponentsHoverCardKo {
	_TranslationsDocsComponentsHoverCardPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Cartão Hover';
	@override String get description => 'Um cartão que aparece ao passar o mouse.';
	@override late final _TranslationsDocsComponentsHoverCardExamplesPt examples = _TranslationsDocsComponentsHoverCardExamplesPt._(_root);
	@override String get flutter_handle => '@flutter';
	@override String get flutter_username => 'Flutter';
	@override String get flutter_description => 'O Flutter SDK fornece ferramentas para construir aplicativos bonitos para móvel, web e desktop a partir de uma única base de código.';
}

// Path: docs.components.input
class _TranslationsDocsComponentsInputPt extends TranslationsDocsComponentsInputKo {
	_TranslationsDocsComponentsInputPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrada';
	@override String get description => 'Campo de entrada de texto.';
	@override late final _TranslationsDocsComponentsInputExamplesPt examples = _TranslationsDocsComponentsInputExamplesPt._(_root);
	@override String get enter_name => 'Digite seu nome';
	@override String get enter_username => 'Digite seu nome de usuário';
	@override String get username_already_taken => 'Nome de usuário já está em uso';
	@override String get hello_world => 'Olá Mundo!';
	@override String get search_something => 'Buscar algo...';
	@override String get email => 'Email';
	@override String get password => 'Digite sua senha';
	@override String get username_hint => 'Este é o seu nome de usuário';
}

// Path: docs.components.input_otp
class _TranslationsDocsComponentsInputOtpPt extends TranslationsDocsComponentsInputOtpKo {
	_TranslationsDocsComponentsInputOtpPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrada de OTP';
	@override String get description => 'Campo para inserir uma senha de uso único.';
	@override late final _TranslationsDocsComponentsInputOtpExamplesPt examples = _TranslationsDocsComponentsInputOtpExamplesPt._(_root);
}

// Path: docs.components.item_picker
class _TranslationsDocsComponentsItemPickerPt extends TranslationsDocsComponentsItemPickerKo {
	_TranslationsDocsComponentsItemPickerPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Seletor de Itens';
	@override String get description => 'Um componente para selecionar itens de uma lista.';
	@override late final _TranslationsDocsComponentsItemPickerExamplesPt examples = _TranslationsDocsComponentsItemPickerExamplesPt._(_root);
}

// Path: docs.components.keyboard_display
class _TranslationsDocsComponentsKeyboardDisplayPt extends TranslationsDocsComponentsKeyboardDisplayKo {
	_TranslationsDocsComponentsKeyboardDisplayPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Display do Teclado';
	@override String get description => 'Um componente que exibe atalhos de teclado.';
	@override late final _TranslationsDocsComponentsKeyboardDisplayExamplesPt examples = _TranslationsDocsComponentsKeyboardDisplayExamplesPt._(_root);
}

// Path: docs.components.linear_progress
class _TranslationsDocsComponentsLinearProgressPt extends TranslationsDocsComponentsLinearProgressKo {
	_TranslationsDocsComponentsLinearProgressPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Progresso Linear';
	@override String get description => 'Um indicador de progresso linear.';
	@override late final _TranslationsDocsComponentsLinearProgressExamplesPt examples = _TranslationsDocsComponentsLinearProgressExamplesPt._(_root);
	@override String get increase => 'Aumentar';
	@override String get decrease => 'Diminuir';
}

// Path: docs.components.material
class _TranslationsDocsComponentsMaterialPt extends TranslationsDocsComponentsMaterialKo {
	_TranslationsDocsComponentsMaterialPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Material/Cupertino';
	@override String get description => 'Como usar widgets padrão do Flutter Material e Cupertino.';
	@override late final _TranslationsDocsComponentsMaterialExamplesPt examples = _TranslationsDocsComponentsMaterialExamplesPt._(_root);
	@override String get my_material_app => 'Meu App Material';
	@override String get my_cupertino_app => 'Meu App Cupertino';
	@override String you_pushed_button({required Object count}) => 'Você pressionou o botão ${count} vezes';
	@override String get open_material_dialog => 'Abrir Diálogo Material';
	@override String get open_cupertino_dialog => 'Abrir Diálogo Cupertino';
	@override String get open_coui_dialog => 'Abrir Diálogo COUI';
}

// Path: docs.components.menubar
class _TranslationsDocsComponentsMenubarPt extends TranslationsDocsComponentsMenubarKo {
	_TranslationsDocsComponentsMenubarPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barra de Menus';
	@override String get description => 'Uma barra de menu horizontal.';
	@override late final _TranslationsDocsComponentsMenubarExamplesPt examples = _TranslationsDocsComponentsMenubarExamplesPt._(_root);
	@override String get file => 'Arquivo';
	@override String get edit => 'Editar';
	@override String get new_tab => 'Nova Aba';
	@override String get new_window => 'Nova Janela';
	@override String get new_incognito_window => 'Nova Janela Anônima';
	@override String get email_link => 'Link de Email';
	@override String get messages => 'Mensagens';
	@override String get notes => 'Notas';
	@override String get share => 'Compartilhar';
	@override String get print => 'Imprimir';
	@override String get save_and_exit => 'Salvar e Sair';
	@override String get discard_and_exit => 'Descartar e Sair';
	@override String get exit => 'Sair';
	@override String get undo => 'Desfazer';
	@override String get redo => 'Refazer';
}

// Path: docs.components.multiselect
class _TranslationsDocsComponentsMultiselectPt extends TranslationsDocsComponentsMultiselectKo {
	_TranslationsDocsComponentsMultiselectPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Multiseleção';
	@override String get description => 'Um componente que permite selecionar vários itens.';
	@override late final _TranslationsDocsComponentsMultiselectExamplesPt examples = _TranslationsDocsComponentsMultiselectExamplesPt._(_root);
}

// Path: docs.components.navigation_bar
class _TranslationsDocsComponentsNavigationBarPt extends TranslationsDocsComponentsNavigationBarKo {
	_TranslationsDocsComponentsNavigationBarPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Barra de Navegação';
	@override String get description => 'Uma barra de navegação inferior.';
	@override late final _TranslationsDocsComponentsNavigationBarExamplesPt examples = _TranslationsDocsComponentsNavigationBarExamplesPt._(_root);
}

// Path: docs.components.navigation_menu
class _TranslationsDocsComponentsNavigationMenuPt extends TranslationsDocsComponentsNavigationMenuKo {
	_TranslationsDocsComponentsNavigationMenuPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Menu de Navegação';
	@override String get description => 'Componente de menu de navegação.';
	@override late final _TranslationsDocsComponentsNavigationMenuExamplesPt examples = _TranslationsDocsComponentsNavigationMenuExamplesPt._(_root);
}

// Path: docs.components.navigation_rail
class _TranslationsDocsComponentsNavigationRailPt extends TranslationsDocsComponentsNavigationRailKo {
	_TranslationsDocsComponentsNavigationRailPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Trilho de Navegação';
	@override String get description => 'Um trilho de navegação lateral.';
	@override late final _TranslationsDocsComponentsNavigationRailExamplesPt examples = _TranslationsDocsComponentsNavigationRailExamplesPt._(_root);
}

// Path: docs.components.navigation_sidebar
class _TranslationsDocsComponentsNavigationSidebarPt extends TranslationsDocsComponentsNavigationSidebarKo {
	_TranslationsDocsComponentsNavigationSidebarPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Sidebar de Navegação';
	@override String get description => 'Componente de sidebar de navegação.';
	@override late final _TranslationsDocsComponentsNavigationSidebarExamplesPt examples = _TranslationsDocsComponentsNavigationSidebarExamplesPt._(_root);
}

// Path: docs.components.number_input
class _TranslationsDocsComponentsNumberInputPt extends TranslationsDocsComponentsNumberInputKo {
	_TranslationsDocsComponentsNumberInputPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrada Numérica';
	@override String get description => 'Um campo para inserir números.';
	@override late final _TranslationsDocsComponentsNumberInputExamplesPt examples = _TranslationsDocsComponentsNumberInputExamplesPt._(_root);
	@override String value({required Object value}) => 'Valor: ${value}';
}

// Path: docs.components.number_ticker
class _TranslationsDocsComponentsNumberTickerPt extends TranslationsDocsComponentsNumberTickerKo {
	_TranslationsDocsComponentsNumberTickerPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Ticker Numérico';
	@override String get description => 'Exibe animações quando o número muda.';
	@override late final _TranslationsDocsComponentsNumberTickerExamplesPt examples = _TranslationsDocsComponentsNumberTickerExamplesPt._(_root);
}

// Path: docs.components.overflow_marquee
class _TranslationsDocsComponentsOverflowMarqueePt extends TranslationsDocsComponentsOverflowMarqueeKo {
	_TranslationsDocsComponentsOverflowMarqueePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Marquee de Overflow';
	@override String get description => 'O texto rola automaticamente quando transborda.';
	@override late final _TranslationsDocsComponentsOverflowMarqueeExamplesPt examples = _TranslationsDocsComponentsOverflowMarqueeExamplesPt._(_root);
}

// Path: docs.components.pagination
class _TranslationsDocsComponentsPaginationPt extends TranslationsDocsComponentsPaginationKo {
	_TranslationsDocsComponentsPaginationPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Paginação';
	@override String get description => 'Um componente para navegar entre páginas.';
	@override late final _TranslationsDocsComponentsPaginationExamplesPt examples = _TranslationsDocsComponentsPaginationExamplesPt._(_root);
}

// Path: docs.components.phone_input
class _TranslationsDocsComponentsPhoneInputPt extends TranslationsDocsComponentsPhoneInputKo {
	_TranslationsDocsComponentsPhoneInputPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Entrada de Telefone';
	@override String get description => 'Um campo para inserir números de telefone.';
	@override late final _TranslationsDocsComponentsPhoneInputExamplesPt examples = _TranslationsDocsComponentsPhoneInputExamplesPt._(_root);
}

// Path: docs.components.popover
class _TranslationsDocsComponentsPopoverPt extends TranslationsDocsComponentsPopoverKo {
	_TranslationsDocsComponentsPopoverPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Popover';
	@override String get description => 'Um pop-up que aparece sobre um elemento.';
	@override late final _TranslationsDocsComponentsPopoverExamplesPt examples = _TranslationsDocsComponentsPopoverExamplesPt._(_root);
	@override String get dimensions => 'Dimensões';
	@override String get set_dimensions => 'Defina as dimensões do layer';
	@override String get width => 'Largura';
	@override String get max_width => 'Largura Máxima';
	@override String get height => 'Altura';
	@override String get max_height => 'Altura Máxima';
	@override String get open_popover => 'Abrir Popover';
	@override String get submit => 'Enviar';
}

// Path: docs.components.progress
class _TranslationsDocsComponentsProgressPt extends TranslationsDocsComponentsProgressKo {
	_TranslationsDocsComponentsProgressPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Progresso';
	@override String get description => 'Exibe o estado de progresso.';
	@override late final _TranslationsDocsComponentsProgressExamplesPt examples = _TranslationsDocsComponentsProgressExamplesPt._(_root);
}

// Path: docs.components.radio_card
class _TranslationsDocsComponentsRadioCardPt extends TranslationsDocsComponentsRadioCardKo {
	_TranslationsDocsComponentsRadioCardPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Cartão de Rádio';
	@override String get description => 'Um botão de rádio no formato de cartão.';
	@override late final _TranslationsDocsComponentsRadioCardExamplesPt examples = _TranslationsDocsComponentsRadioCardExamplesPt._(_root);
}

// Path: docs.components.radio_group
class _TranslationsDocsComponentsRadioGroupPt extends TranslationsDocsComponentsRadioGroupKo {
	_TranslationsDocsComponentsRadioGroupPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Grupo de Botões de Rádio';
	@override String get description => 'Um grupo de botões de rádio.';
	@override late final _TranslationsDocsComponentsRadioGroupExamplesPt examples = _TranslationsDocsComponentsRadioGroupExamplesPt._(_root);
	@override String get option_1 => 'Opção 1';
	@override String get option_2 => 'Opção 2';
	@override String get option_3 => 'Opção 3';
	@override String get selected => 'Selecionado';
}

// Path: docs.components.refresh_trigger
class _TranslationsDocsComponentsRefreshTriggerPt extends TranslationsDocsComponentsRefreshTriggerKo {
	_TranslationsDocsComponentsRefreshTriggerPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Gatilho de Atualização';
	@override String get description => 'Fornece a funcionalidade de puxar para atualizar.';
	@override late final _TranslationsDocsComponentsRefreshTriggerExamplesPt examples = _TranslationsDocsComponentsRefreshTriggerExamplesPt._(_root);
	@override String get pull_me => 'Puxe-me';
	@override String get refresh => 'Atualizar';
}

// Path: docs.components.repeated_animation_builder
class _TranslationsDocsComponentsRepeatedAnimationBuilderPt extends TranslationsDocsComponentsRepeatedAnimationBuilderKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Construtor de Animação Repetida';
	@override String get description => 'Um construtor que repete animações.';
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesPt examples = _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesPt._(_root);
}

// Path: docs.components.resizable
class _TranslationsDocsComponentsResizablePt extends TranslationsDocsComponentsResizableKo {
	_TranslationsDocsComponentsResizablePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Redimensionável';
	@override String get description => 'Um contêiner que pode ser redimensionado.';
	@override late final _TranslationsDocsComponentsResizableExamplesPt examples = _TranslationsDocsComponentsResizableExamplesPt._(_root);
}

// Path: docs.components.scaffold
class _TranslationsDocsComponentsScaffoldPt extends TranslationsDocsComponentsScaffoldKo {
	_TranslationsDocsComponentsScaffoldPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Scaffold';
	@override String get description => 'O scaffold é o contêiner principal da página.';
	@override late final _TranslationsDocsComponentsScaffoldExamplesPt examples = _TranslationsDocsComponentsScaffoldExamplesPt._(_root);
}

// Path: docs.components.select
class _TranslationsDocsComponentsSelectPt extends TranslationsDocsComponentsSelectKo {
	_TranslationsDocsComponentsSelectPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Selecionar';
	@override String get description => 'Permite selecionar itens de uma lista de opções.';
	@override late final _TranslationsDocsComponentsSelectExamplesPt examples = _TranslationsDocsComponentsSelectExamplesPt._(_root);
	@override String get placeholder => 'Selecione uma fruta';
	@override String get search_fruit => 'Buscar fruta';
	@override String get no_fruit_found => 'Nenhuma fruta encontrada';
	@override String get apple => 'Maçã';
	@override String get banana => 'Banana';
	@override String get cherry => 'Cereja';
	@override String get lemon => 'Limão';
	@override String get tomato => 'Tomate';
	@override String get red_apple => 'Maçã Vermelha';
	@override String get green_apple => 'Maçã Verde';
	@override String get yellow_banana => 'Banana Amarela';
	@override String get brown_banana => 'Banana Marrom';
	@override String get yellow_lemon => 'Limão Amarelo';
	@override String get green_lemon => 'Limão Verde';
	@override String get red => 'Vermelho';
	@override String get green => 'Verde';
	@override String get yellow => 'Amarelo';
	@override String get brown => 'Marrom';
}

// Path: docs.components.sheet
class _TranslationsDocsComponentsSheetPt extends TranslationsDocsComponentsSheetKo {
	_TranslationsDocsComponentsSheetPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Sheet';
	@override String get description => 'Uma sheet que sobe de baixo.';
	@override late final _TranslationsDocsComponentsSheetExamplesPt examples = _TranslationsDocsComponentsSheetExamplesPt._(_root);
}

// Path: docs.components.skeleton
class _TranslationsDocsComponentsSkeletonPt extends TranslationsDocsComponentsSkeletonKo {
	_TranslationsDocsComponentsSkeletonPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Esqueleto';
	@override String get description => 'A tela de esqueleto exibida durante o carregamento.';
	@override late final _TranslationsDocsComponentsSkeletonExamplesPt examples = _TranslationsDocsComponentsSkeletonExamplesPt._(_root);
}

// Path: docs.components.slider
class _TranslationsDocsComponentsSliderPt extends TranslationsDocsComponentsSliderKo {
	_TranslationsDocsComponentsSliderPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Deslizante';
	@override String get description => 'Um componente que permite selecionar um valor arrastando.';
	@override late final _TranslationsDocsComponentsSliderExamplesPt examples = _TranslationsDocsComponentsSliderExamplesPt._(_root);
	@override String value_single({required Object value}) => 'Valor: ${value}';
	@override String value_range({required Object start, required Object end}) => 'Valor: ${start} - ${end}';
}

// Path: docs.components.sortable
class _TranslationsDocsComponentsSortablePt extends TranslationsDocsComponentsSortableKo {
	_TranslationsDocsComponentsSortablePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Ordenável';
	@override String get description => 'Permite arrastar e soltar itens para ordená-los.';
	@override late final _TranslationsDocsComponentsSortableExamplesPt examples = _TranslationsDocsComponentsSortableExamplesPt._(_root);
}

// Path: docs.components.star_rating
class _TranslationsDocsComponentsStarRatingPt extends TranslationsDocsComponentsStarRatingKo {
	_TranslationsDocsComponentsStarRatingPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Avaliação por Estrelas';
	@override String get description => 'Permite selecionar uma avaliação por estrelas.';
	@override late final _TranslationsDocsComponentsStarRatingExamplesPt examples = _TranslationsDocsComponentsStarRatingExamplesPt._(_root);
}

// Path: docs.components.stepper
class _TranslationsDocsComponentsStepperPt extends TranslationsDocsComponentsStepperKo {
	_TranslationsDocsComponentsStepperPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Stepper';
	@override String get description => 'Exibe um processo por etapas.';
	@override late final _TranslationsDocsComponentsStepperExamplesPt examples = _TranslationsDocsComponentsStepperExamplesPt._(_root);
	@override String get step_1 => 'Passo 1';
	@override String get step_2 => 'Passo 2';
	@override String get step_3 => 'Passo 3';
	@override String step_n({required Object n}) => 'Passo ${n}';
	@override String get optional_step => 'Passo Opcional';
	@override String get horizontal => 'Horizontal';
	@override String get vertical => 'Vertical';
	@override String get toggle_error => 'Alternar Erro';
	@override String get circle => 'Circunferência';
	@override String get circle_alt => 'Circunferência Alternativa';
	@override String get line => 'Linha';
	@override String get small => 'Pequeno';
	@override String get medium => 'Médio';
	@override String get large => 'Grande';
}

// Path: docs.components.steps
class _TranslationsDocsComponentsStepsPt extends TranslationsDocsComponentsStepsKo {
	_TranslationsDocsComponentsStepsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Passos';
	@override String get description => 'Exibe o progresso em etapas.';
	@override late final _TranslationsDocsComponentsStepsExamplesPt examples = _TranslationsDocsComponentsStepsExamplesPt._(_root);
}

// Path: docs.components.swiper
class _TranslationsDocsComponentsSwiperPt extends TranslationsDocsComponentsSwiperKo {
	_TranslationsDocsComponentsSwiperPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Swiper';
	@override String get description => 'Um componente que pode ser deslizado.';
	@override late final _TranslationsDocsComponentsSwiperExamplesPt examples = _TranslationsDocsComponentsSwiperExamplesPt._(_root);
}

// Path: docs.components.k_switch
class _TranslationsDocsComponentsKSwitchPt extends TranslationsDocsComponentsKSwitchKo {
	_TranslationsDocsComponentsKSwitchPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Interruptor';
	@override String get description => 'Um interruptor liga/desliga.';
	@override late final _TranslationsDocsComponentsKSwitchExamplesPt examples = _TranslationsDocsComponentsKSwitchExamplesPt._(_root);
}

// Path: docs.components.switcher
class _TranslationsDocsComponentsSwitcherPt extends TranslationsDocsComponentsSwitcherKo {
	_TranslationsDocsComponentsSwitcherPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Mudador';
	@override String get description => 'Permite alternar entre várias visões.';
	@override late final _TranslationsDocsComponentsSwitcherExamplesPt examples = _TranslationsDocsComponentsSwitcherExamplesPt._(_root);
	@override String get switch_direction => 'Alterar direção';
	@override String get next_item => 'Próximo item';
}

// Path: docs.components.tab_list
class _TranslationsDocsComponentsTabListPt extends TranslationsDocsComponentsTabListKo {
	_TranslationsDocsComponentsTabListPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Lista de Abas';
	@override String get description => 'Componente de lista de abas.';
	@override late final _TranslationsDocsComponentsTabListExamplesPt examples = _TranslationsDocsComponentsTabListExamplesPt._(_root);
}

// Path: docs.components.tab_pane
class _TranslationsDocsComponentsTabPanePt extends TranslationsDocsComponentsTabPaneKo {
	_TranslationsDocsComponentsTabPanePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Painel de Abas';
	@override String get description => 'Componente de painel de abas.';
	@override late final _TranslationsDocsComponentsTabPaneExamplesPt examples = _TranslationsDocsComponentsTabPaneExamplesPt._(_root);
}

// Path: docs.components.table
class _TranslationsDocsComponentsTablePt extends TranslationsDocsComponentsTableKo {
	_TranslationsDocsComponentsTablePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tabela';
	@override String get description => 'Exibe dados em formato de tabela.';
	@override late final _TranslationsDocsComponentsTableExamplesPt examples = _TranslationsDocsComponentsTableExamplesPt._(_root);
	@override String get invoice => 'Fatura';
	@override String get status => 'Status';
	@override String get method => 'Método';
	@override String get amount => 'Quantidade';
	@override String get total => 'Total';
	@override String get paid => 'Pago';
	@override String get pending => 'Pendente';
	@override String get unpaid => 'Não pago';
	@override String get credit_card => 'Cartão de Crédito';
	@override String get paypal => 'PayPal';
	@override String get bank_transfer => 'Transferência Bancária';
}

// Path: docs.components.tabs
class _TranslationsDocsComponentsTabsPt extends TranslationsDocsComponentsTabsKo {
	_TranslationsDocsComponentsTabsPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Abas';
	@override String get description => 'Organiza conteúdo usando abas.';
	@override late final _TranslationsDocsComponentsTabsExamplesPt examples = _TranslationsDocsComponentsTabsExamplesPt._(_root);
	@override String get tab_1 => 'Aba 1';
	@override String get tab_2 => 'Aba 2';
	@override String get tab_3 => 'Aba 3';
	@override String tab_n({required Object n}) => 'Aba ${n}';
}

// Path: docs.components.text_area
class _TranslationsDocsComponentsTextAreaPt extends TranslationsDocsComponentsTextAreaKo {
	_TranslationsDocsComponentsTextAreaPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Área de Texto';
	@override String get description => 'Permite inserir várias linhas de texto.';
	@override late final _TranslationsDocsComponentsTextAreaExamplesPt examples = _TranslationsDocsComponentsTextAreaExamplesPt._(_root);
	@override String get hello_world => 'Olá, mundo!';
}

// Path: docs.components.time_picker
class _TranslationsDocsComponentsTimePickerPt extends TranslationsDocsComponentsTimePickerKo {
	_TranslationsDocsComponentsTimePickerPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Seletor de Hora';
	@override String get description => 'Um componente para selecionar horas.';
	@override late final _TranslationsDocsComponentsTimePickerExamplesPt examples = _TranslationsDocsComponentsTimePickerExamplesPt._(_root);
	@override String get select_time => 'Selecionar Hora';
}

// Path: docs.components.timeline
class _TranslationsDocsComponentsTimelinePt extends TranslationsDocsComponentsTimelineKo {
	_TranslationsDocsComponentsTimelinePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Linha do Tempo';
	@override String get description => 'Exibe eventos em uma linha do tempo.';
	@override late final _TranslationsDocsComponentsTimelineExamplesPt examples = _TranslationsDocsComponentsTimelineExamplesPt._(_root);
}

// Path: docs.components.timeline_animation
class _TranslationsDocsComponentsTimelineAnimationPt extends TranslationsDocsComponentsTimelineAnimationKo {
	_TranslationsDocsComponentsTimelineAnimationPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Animação de Linha do Tempo';
	@override String get description => 'Animações baseadas em linha do tempo.';
	@override late final _TranslationsDocsComponentsTimelineAnimationExamplesPt examples = _TranslationsDocsComponentsTimelineAnimationExamplesPt._(_root);
}

// Path: docs.components.toast
class _TranslationsDocsComponentsToastPt extends TranslationsDocsComponentsToastKo {
	_TranslationsDocsComponentsToastPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Toast';
	@override String get description => 'Uma notificação que exibe mensagens breves.';
	@override late final _TranslationsDocsComponentsToastExamplesPt examples = _TranslationsDocsComponentsToastExamplesPt._(_root);
	@override String get event_created => 'Evento criado';
	@override String get event_date => 'Domingo, 7 de julho de 2024, 12:00 PM';
	@override String get show_bottom_left => 'Mostrar toast no canto inferior esquerdo';
	@override String get show_bottom_right => 'Mostrar toast no canto inferior direito';
	@override String get show_top_left => 'Mostrar toast no canto superior esquerdo';
	@override String get show_top_right => 'Mostrar toast no canto superior direito';
	@override String get show_bottom_center => 'Mostrar toast no centro inferior';
	@override String get show_top_center => 'Mostrar toast no centro superior';
}

// Path: docs.components.toggle
class _TranslationsDocsComponentsTogglePt extends TranslationsDocsComponentsToggleKo {
	_TranslationsDocsComponentsTogglePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Alternar';
	@override String get description => 'Permite alternar entre opções.';
	@override late final _TranslationsDocsComponentsToggleExamplesPt examples = _TranslationsDocsComponentsToggleExamplesPt._(_root);
	@override String get toggle => 'Alternar';
}

// Path: docs.components.tooltip
class _TranslationsDocsComponentsTooltipPt extends TranslationsDocsComponentsTooltipKo {
	_TranslationsDocsComponentsTooltipPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Tooltip';
	@override String get description => 'Exibe informações adicionais sobre um elemento.';
	@override late final _TranslationsDocsComponentsTooltipExamplesPt examples = _TranslationsDocsComponentsTooltipExamplesPt._(_root);
	@override String get this_is_tooltip => 'Este é um tooltip.';
	@override String get hover_over_me => 'Passe o mouse sobre mim';
}

// Path: docs.components.tracker
class _TranslationsDocsComponentsTrackerPt extends TranslationsDocsComponentsTrackerKo {
	_TranslationsDocsComponentsTrackerPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Rastreador';
	@override String get description => 'Rastreador de progresso.';
	@override late final _TranslationsDocsComponentsTrackerExamplesPt examples = _TranslationsDocsComponentsTrackerExamplesPt._(_root);
	@override String get fine => 'Bom';
	@override String get warning => 'Aviso';
	@override String get critical => 'Crítico';
	@override String get unknown => 'Desconhecido';
	@override String get tracker_fine => 'Rastreador bom';
	@override String get tracker_warning => 'Rastreador de aviso';
	@override String get tracker_critical => 'Rastreador crítico';
	@override String get tracker_unknown => 'Rastreador desconhecido';
}

// Path: docs.components.tree
class _TranslationsDocsComponentsTreePt extends TranslationsDocsComponentsTreeKo {
	_TranslationsDocsComponentsTreePt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Árvore';
	@override String get description => 'Exibe dados hierárquicos na forma de uma árvore.';
	@override late final _TranslationsDocsComponentsTreeExamplesPt examples = _TranslationsDocsComponentsTreeExamplesPt._(_root);
}

// Path: docs.components.window
class _TranslationsDocsComponentsWindowPt extends TranslationsDocsComponentsWindowKo {
	_TranslationsDocsComponentsWindowPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Janela';
	@override String get description => 'Uma janela estilizada desktop.';
	@override late final _TranslationsDocsComponentsWindowExamplesPt examples = _TranslationsDocsComponentsWindowExamplesPt._(_root);
	@override String get window_1 => 'Janela 1';
	@override String get window_2 => 'Janela 2';
	@override String get desktop => 'Desktop';
	@override String get add_window => 'Adicionar Janela';
}

// Path: docs.pages.introduction.features_list
class _TranslationsDocsPagesIntroductionFeaturesListPt extends TranslationsDocsPagesIntroductionFeaturesListKo {
	_TranslationsDocsPagesIntroductionFeaturesListPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get components_count => '84 componentes e crescendo!';
	@override String get material_cupertino => 'Suporte a widgets Material e Cupertino, com temas ajustados para o tema do coui_flutter.';
	@override String get premade_themes => 'Temas pré-fabricados do Coui/UI.';
	@override String get platform_support => 'Suporte a plataformas móveis, web e desktop.';
	@override String get middle_drag => 'Suporte ao scroll por arrasto intermediário.';
	@override String get typography_extensions => 'Várias extensões de widgets para tipografia.';
	@override String get webassembly => 'Suporte a WebAssembly para melhor desempenho.';
}

// Path: docs.components.accordion.examples
class _TranslationsDocsComponentsAccordionExamplesPt extends TranslationsDocsComponentsAccordionExamplesKo {
	_TranslationsDocsComponentsAccordionExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Acordeão';
}

// Path: docs.components.alert.examples
class _TranslationsDocsComponentsAlertExamplesPt extends TranslationsDocsComponentsAlertExamplesKo {
	_TranslationsDocsComponentsAlertExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Alerta';
	@override String get destructive => 'Exemplo de Alerta Destrutivo';
}

// Path: docs.components.alert_dialog.examples
class _TranslationsDocsComponentsAlertDialogExamplesPt extends TranslationsDocsComponentsAlertDialogExamplesKo {
	_TranslationsDocsComponentsAlertDialogExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Diálogo de Alerta';
}

// Path: docs.components.animated_value_builder.examples
class _TranslationsDocsComponentsAnimatedValueBuilderExamplesPt extends TranslationsDocsComponentsAnimatedValueBuilderExamplesKo {
	_TranslationsDocsComponentsAnimatedValueBuilderExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Construtor de Valor Animado';
}

// Path: docs.components.app_bar.examples
class _TranslationsDocsComponentsAppBarExamplesPt extends TranslationsDocsComponentsAppBarExamplesKo {
	_TranslationsDocsComponentsAppBarExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo da Barra do App';
}

// Path: docs.components.autocomplete.examples
class _TranslationsDocsComponentsAutocompleteExamplesPt extends TranslationsDocsComponentsAutocompleteExamplesKo {
	_TranslationsDocsComponentsAutocompleteExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Autocompletar';
}

// Path: docs.components.avatar.examples
class _TranslationsDocsComponentsAvatarExamplesPt extends TranslationsDocsComponentsAvatarExamplesKo {
	_TranslationsDocsComponentsAvatarExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Avatar';
}

// Path: docs.components.avatar_group.examples
class _TranslationsDocsComponentsAvatarGroupExamplesPt extends TranslationsDocsComponentsAvatarGroupExamplesKo {
	_TranslationsDocsComponentsAvatarGroupExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Grupo de Avatares';
}

// Path: docs.components.badge.examples
class _TranslationsDocsComponentsBadgeExamplesPt extends TranslationsDocsComponentsBadgeExamplesKo {
	_TranslationsDocsComponentsBadgeExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Distintivo';
}

// Path: docs.components.breadcrumb.examples
class _TranslationsDocsComponentsBreadcrumbExamplesPt extends TranslationsDocsComponentsBreadcrumbExamplesKo {
	_TranslationsDocsComponentsBreadcrumbExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Breadcrumb';
}

// Path: docs.components.button.examples
class _TranslationsDocsComponentsButtonExamplesPt extends TranslationsDocsComponentsButtonExamplesKo {
	_TranslationsDocsComponentsButtonExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get primary => 'Exemplo de Botão Primário';
	@override String get secondary => 'Exemplo de Botão Secundário';
	@override String get outline => 'Exemplo de Botão Contornado';
	@override String get ghost => 'Exemplo de Botão Fantasma';
	@override String get destructive => 'Exemplo de Botão Destrutivo';
	@override String get link => 'Exemplo de Botão de Link';
	@override String get text => 'Exemplo de Botão de Texto';
	@override String get disabled => 'Exemplo de Botão Desativado';
	@override String get icon => 'Exemplo de Botão de Ícone';
	@override String get icon_with_label => 'Exemplo de Botão de Ícone com Rótulo';
	@override String get size => 'Exemplo de Tamanho do Botão';
	@override String get density => 'Exemplo de Densidade do Botão';
	@override String get shape => 'Exemplo de Forma do Botão';
	@override String get group => 'Exemplo de Grupo de Botões';
	@override String get stated => 'Exemplo de Botão com Estado';
	@override String get card => 'Exemplo de Botão de Cartão';
	@override String get custom => 'Exemplo de Botão Personalizado';
}

// Path: docs.components.calendar.examples
class _TranslationsDocsComponentsCalendarExamplesPt extends TranslationsDocsComponentsCalendarExamplesKo {
	_TranslationsDocsComponentsCalendarExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Calendário';
}

// Path: docs.components.card.examples
class _TranslationsDocsComponentsCardExamplesPt extends TranslationsDocsComponentsCardExamplesKo {
	_TranslationsDocsComponentsCardExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Cartão';
}

// Path: docs.components.card_image.examples
class _TranslationsDocsComponentsCardImageExamplesPt extends TranslationsDocsComponentsCardImageExamplesKo {
	_TranslationsDocsComponentsCardImageExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Cartão de Imagem';
}

// Path: docs.components.carousel.examples
class _TranslationsDocsComponentsCarouselExamplesPt extends TranslationsDocsComponentsCarouselExamplesKo {
	_TranslationsDocsComponentsCarouselExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Carrossel';
}

// Path: docs.components.checkbox.examples
class _TranslationsDocsComponentsCheckboxExamplesPt extends TranslationsDocsComponentsCheckboxExamplesKo {
	_TranslationsDocsComponentsCheckboxExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Checkbox';
}

// Path: docs.components.chip.examples
class _TranslationsDocsComponentsChipExamplesPt extends TranslationsDocsComponentsChipExamplesKo {
	_TranslationsDocsComponentsChipExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Chip';
}

// Path: docs.components.chip_input.examples
class _TranslationsDocsComponentsChipInputExamplesPt extends TranslationsDocsComponentsChipInputExamplesKo {
	_TranslationsDocsComponentsChipInputExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Entrada de Chip';
}

// Path: docs.components.circular_progress.examples
class _TranslationsDocsComponentsCircularProgressExamplesPt extends TranslationsDocsComponentsCircularProgressExamplesKo {
	_TranslationsDocsComponentsCircularProgressExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Progresso Circular';
}

// Path: docs.components.code_snippet.examples
class _TranslationsDocsComponentsCodeSnippetExamplesPt extends TranslationsDocsComponentsCodeSnippetExamplesKo {
	_TranslationsDocsComponentsCodeSnippetExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Trecho de Código';
}

// Path: docs.components.collapsible.examples
class _TranslationsDocsComponentsCollapsibleExamplesPt extends TranslationsDocsComponentsCollapsibleExamplesKo {
	_TranslationsDocsComponentsCollapsibleExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Colapsável';
}

// Path: docs.components.color_picker.examples
class _TranslationsDocsComponentsColorPickerExamplesPt extends TranslationsDocsComponentsColorPickerExamplesKo {
	_TranslationsDocsComponentsColorPickerExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Seletor de Cores';
}

// Path: docs.components.command.examples
class _TranslationsDocsComponentsCommandExamplesPt extends TranslationsDocsComponentsCommandExamplesKo {
	_TranslationsDocsComponentsCommandExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Comando';
}

// Path: docs.components.context_menu.examples
class _TranslationsDocsComponentsContextMenuExamplesPt extends TranslationsDocsComponentsContextMenuExamplesKo {
	_TranslationsDocsComponentsContextMenuExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Menu de Contexto';
}

// Path: docs.components.date_picker.examples
class _TranslationsDocsComponentsDatePickerExamplesPt extends TranslationsDocsComponentsDatePickerExamplesKo {
	_TranslationsDocsComponentsDatePickerExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Seletor de Data';
}

// Path: docs.components.dialog.examples
class _TranslationsDocsComponentsDialogExamplesPt extends TranslationsDocsComponentsDialogExamplesKo {
	_TranslationsDocsComponentsDialogExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Diálogo';
}

// Path: docs.components.divider.examples
class _TranslationsDocsComponentsDividerExamplesPt extends TranslationsDocsComponentsDividerExamplesKo {
	_TranslationsDocsComponentsDividerExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Divisor';
}

// Path: docs.components.dot_indicator.examples
class _TranslationsDocsComponentsDotIndicatorExamplesPt extends TranslationsDocsComponentsDotIndicatorExamplesKo {
	_TranslationsDocsComponentsDotIndicatorExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Indicador de Pontos';
}

// Path: docs.components.drawer.examples
class _TranslationsDocsComponentsDrawerExamplesPt extends TranslationsDocsComponentsDrawerExamplesKo {
	_TranslationsDocsComponentsDrawerExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Drawer';
}

// Path: docs.components.dropdown_menu.examples
class _TranslationsDocsComponentsDropdownMenuExamplesPt extends TranslationsDocsComponentsDropdownMenuExamplesKo {
	_TranslationsDocsComponentsDropdownMenuExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Menu Suspenso';
}

// Path: docs.components.expandable_sidebar.examples
class _TranslationsDocsComponentsExpandableSidebarExamplesPt extends TranslationsDocsComponentsExpandableSidebarExamplesKo {
	_TranslationsDocsComponentsExpandableSidebarExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Sidebar Expandível';
}

// Path: docs.components.form.examples
class _TranslationsDocsComponentsFormExamplesPt extends TranslationsDocsComponentsFormExamplesKo {
	_TranslationsDocsComponentsFormExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get table_layout => 'Exemplo de Formulário (Layout de Tabela)';
	@override String get column_layout => 'Exemplo de Formulário (Layout de Coluna)';
	@override String get validation_mode => 'Exemplo Modo de Validação';
}

// Path: docs.components.formatted_input.examples
class _TranslationsDocsComponentsFormattedInputExamplesPt extends TranslationsDocsComponentsFormattedInputExamplesKo {
	_TranslationsDocsComponentsFormattedInputExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Entrada Formatada';
}

// Path: docs.components.hover_card.examples
class _TranslationsDocsComponentsHoverCardExamplesPt extends TranslationsDocsComponentsHoverCardExamplesKo {
	_TranslationsDocsComponentsHoverCardExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Cartão Hover';
}

// Path: docs.components.input.examples
class _TranslationsDocsComponentsInputExamplesPt extends TranslationsDocsComponentsInputExamplesKo {
	_TranslationsDocsComponentsInputExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Entrada';
}

// Path: docs.components.input_otp.examples
class _TranslationsDocsComponentsInputOtpExamplesPt extends TranslationsDocsComponentsInputOtpExamplesKo {
	_TranslationsDocsComponentsInputOtpExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Entrada de OTP';
}

// Path: docs.components.item_picker.examples
class _TranslationsDocsComponentsItemPickerExamplesPt extends TranslationsDocsComponentsItemPickerExamplesKo {
	_TranslationsDocsComponentsItemPickerExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Seletor de Itens';
}

// Path: docs.components.keyboard_display.examples
class _TranslationsDocsComponentsKeyboardDisplayExamplesPt extends TranslationsDocsComponentsKeyboardDisplayExamplesKo {
	_TranslationsDocsComponentsKeyboardDisplayExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Display do Teclado';
}

// Path: docs.components.linear_progress.examples
class _TranslationsDocsComponentsLinearProgressExamplesPt extends TranslationsDocsComponentsLinearProgressExamplesKo {
	_TranslationsDocsComponentsLinearProgressExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Progresso Linear';
}

// Path: docs.components.material.examples
class _TranslationsDocsComponentsMaterialExamplesPt extends TranslationsDocsComponentsMaterialExamplesKo {
	_TranslationsDocsComponentsMaterialExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Material/Cupertino';
}

// Path: docs.components.menubar.examples
class _TranslationsDocsComponentsMenubarExamplesPt extends TranslationsDocsComponentsMenubarExamplesKo {
	_TranslationsDocsComponentsMenubarExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Barra de Menus';
}

// Path: docs.components.multiselect.examples
class _TranslationsDocsComponentsMultiselectExamplesPt extends TranslationsDocsComponentsMultiselectExamplesKo {
	_TranslationsDocsComponentsMultiselectExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Multiseleção';
}

// Path: docs.components.navigation_bar.examples
class _TranslationsDocsComponentsNavigationBarExamplesPt extends TranslationsDocsComponentsNavigationBarExamplesKo {
	_TranslationsDocsComponentsNavigationBarExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Barra de Navegação';
}

// Path: docs.components.navigation_menu.examples
class _TranslationsDocsComponentsNavigationMenuExamplesPt extends TranslationsDocsComponentsNavigationMenuExamplesKo {
	_TranslationsDocsComponentsNavigationMenuExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Menu de Navegação';
}

// Path: docs.components.navigation_rail.examples
class _TranslationsDocsComponentsNavigationRailExamplesPt extends TranslationsDocsComponentsNavigationRailExamplesKo {
	_TranslationsDocsComponentsNavigationRailExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Trilho de Navegação';
}

// Path: docs.components.navigation_sidebar.examples
class _TranslationsDocsComponentsNavigationSidebarExamplesPt extends TranslationsDocsComponentsNavigationSidebarExamplesKo {
	_TranslationsDocsComponentsNavigationSidebarExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Sidebar de Navegação';
}

// Path: docs.components.number_input.examples
class _TranslationsDocsComponentsNumberInputExamplesPt extends TranslationsDocsComponentsNumberInputExamplesKo {
	_TranslationsDocsComponentsNumberInputExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Entrada Numérica';
}

// Path: docs.components.number_ticker.examples
class _TranslationsDocsComponentsNumberTickerExamplesPt extends TranslationsDocsComponentsNumberTickerExamplesKo {
	_TranslationsDocsComponentsNumberTickerExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Ticker Numérico';
}

// Path: docs.components.overflow_marquee.examples
class _TranslationsDocsComponentsOverflowMarqueeExamplesPt extends TranslationsDocsComponentsOverflowMarqueeExamplesKo {
	_TranslationsDocsComponentsOverflowMarqueeExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Marquee de Overflow';
}

// Path: docs.components.pagination.examples
class _TranslationsDocsComponentsPaginationExamplesPt extends TranslationsDocsComponentsPaginationExamplesKo {
	_TranslationsDocsComponentsPaginationExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Paginação';
}

// Path: docs.components.phone_input.examples
class _TranslationsDocsComponentsPhoneInputExamplesPt extends TranslationsDocsComponentsPhoneInputExamplesKo {
	_TranslationsDocsComponentsPhoneInputExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Entrada de Telefone';
}

// Path: docs.components.popover.examples
class _TranslationsDocsComponentsPopoverExamplesPt extends TranslationsDocsComponentsPopoverExamplesKo {
	_TranslationsDocsComponentsPopoverExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Popover';
}

// Path: docs.components.progress.examples
class _TranslationsDocsComponentsProgressExamplesPt extends TranslationsDocsComponentsProgressExamplesKo {
	_TranslationsDocsComponentsProgressExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Progresso';
}

// Path: docs.components.radio_card.examples
class _TranslationsDocsComponentsRadioCardExamplesPt extends TranslationsDocsComponentsRadioCardExamplesKo {
	_TranslationsDocsComponentsRadioCardExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Cartão de Rádio';
}

// Path: docs.components.radio_group.examples
class _TranslationsDocsComponentsRadioGroupExamplesPt extends TranslationsDocsComponentsRadioGroupExamplesKo {
	_TranslationsDocsComponentsRadioGroupExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Grupo de Botões de Rádio';
}

// Path: docs.components.refresh_trigger.examples
class _TranslationsDocsComponentsRefreshTriggerExamplesPt extends TranslationsDocsComponentsRefreshTriggerExamplesKo {
	_TranslationsDocsComponentsRefreshTriggerExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Gatilho de Atualização';
}

// Path: docs.components.repeated_animation_builder.examples
class _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesPt extends TranslationsDocsComponentsRepeatedAnimationBuilderExamplesKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Construtor de Animação Repetida';
}

// Path: docs.components.resizable.examples
class _TranslationsDocsComponentsResizableExamplesPt extends TranslationsDocsComponentsResizableExamplesKo {
	_TranslationsDocsComponentsResizableExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Redimensionável';
}

// Path: docs.components.scaffold.examples
class _TranslationsDocsComponentsScaffoldExamplesPt extends TranslationsDocsComponentsScaffoldExamplesKo {
	_TranslationsDocsComponentsScaffoldExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Scaffold';
}

// Path: docs.components.select.examples
class _TranslationsDocsComponentsSelectExamplesPt extends TranslationsDocsComponentsSelectExamplesKo {
	_TranslationsDocsComponentsSelectExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Selecionar';
}

// Path: docs.components.sheet.examples
class _TranslationsDocsComponentsSheetExamplesPt extends TranslationsDocsComponentsSheetExamplesKo {
	_TranslationsDocsComponentsSheetExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Sheet';
}

// Path: docs.components.skeleton.examples
class _TranslationsDocsComponentsSkeletonExamplesPt extends TranslationsDocsComponentsSkeletonExamplesKo {
	_TranslationsDocsComponentsSkeletonExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Esqueleto';
}

// Path: docs.components.slider.examples
class _TranslationsDocsComponentsSliderExamplesPt extends TranslationsDocsComponentsSliderExamplesKo {
	_TranslationsDocsComponentsSliderExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Deslizante';
}

// Path: docs.components.sortable.examples
class _TranslationsDocsComponentsSortableExamplesPt extends TranslationsDocsComponentsSortableExamplesKo {
	_TranslationsDocsComponentsSortableExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Ordenável';
}

// Path: docs.components.star_rating.examples
class _TranslationsDocsComponentsStarRatingExamplesPt extends TranslationsDocsComponentsStarRatingExamplesKo {
	_TranslationsDocsComponentsStarRatingExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Avaliação por Estrelas';
}

// Path: docs.components.stepper.examples
class _TranslationsDocsComponentsStepperExamplesPt extends TranslationsDocsComponentsStepperExamplesKo {
	_TranslationsDocsComponentsStepperExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Stepper';
}

// Path: docs.components.steps.examples
class _TranslationsDocsComponentsStepsExamplesPt extends TranslationsDocsComponentsStepsExamplesKo {
	_TranslationsDocsComponentsStepsExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Passos';
}

// Path: docs.components.swiper.examples
class _TranslationsDocsComponentsSwiperExamplesPt extends TranslationsDocsComponentsSwiperExamplesKo {
	_TranslationsDocsComponentsSwiperExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Swiper';
}

// Path: docs.components.k_switch.examples
class _TranslationsDocsComponentsKSwitchExamplesPt extends TranslationsDocsComponentsKSwitchExamplesKo {
	_TranslationsDocsComponentsKSwitchExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Interruptor';
}

// Path: docs.components.switcher.examples
class _TranslationsDocsComponentsSwitcherExamplesPt extends TranslationsDocsComponentsSwitcherExamplesKo {
	_TranslationsDocsComponentsSwitcherExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Mudador';
}

// Path: docs.components.tab_list.examples
class _TranslationsDocsComponentsTabListExamplesPt extends TranslationsDocsComponentsTabListExamplesKo {
	_TranslationsDocsComponentsTabListExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Lista de Abas';
}

// Path: docs.components.tab_pane.examples
class _TranslationsDocsComponentsTabPaneExamplesPt extends TranslationsDocsComponentsTabPaneExamplesKo {
	_TranslationsDocsComponentsTabPaneExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Painel de Abas';
}

// Path: docs.components.table.examples
class _TranslationsDocsComponentsTableExamplesPt extends TranslationsDocsComponentsTableExamplesKo {
	_TranslationsDocsComponentsTableExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Tabela';
}

// Path: docs.components.tabs.examples
class _TranslationsDocsComponentsTabsExamplesPt extends TranslationsDocsComponentsTabsExamplesKo {
	_TranslationsDocsComponentsTabsExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Abas';
}

// Path: docs.components.text_area.examples
class _TranslationsDocsComponentsTextAreaExamplesPt extends TranslationsDocsComponentsTextAreaExamplesKo {
	_TranslationsDocsComponentsTextAreaExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Área de Texto';
}

// Path: docs.components.time_picker.examples
class _TranslationsDocsComponentsTimePickerExamplesPt extends TranslationsDocsComponentsTimePickerExamplesKo {
	_TranslationsDocsComponentsTimePickerExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Seletor de Hora';
}

// Path: docs.components.timeline.examples
class _TranslationsDocsComponentsTimelineExamplesPt extends TranslationsDocsComponentsTimelineExamplesKo {
	_TranslationsDocsComponentsTimelineExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Linha do Tempo';
}

// Path: docs.components.timeline_animation.examples
class _TranslationsDocsComponentsTimelineAnimationExamplesPt extends TranslationsDocsComponentsTimelineAnimationExamplesKo {
	_TranslationsDocsComponentsTimelineAnimationExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Animação de Linha do Tempo';
}

// Path: docs.components.toast.examples
class _TranslationsDocsComponentsToastExamplesPt extends TranslationsDocsComponentsToastExamplesKo {
	_TranslationsDocsComponentsToastExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Toast';
}

// Path: docs.components.toggle.examples
class _TranslationsDocsComponentsToggleExamplesPt extends TranslationsDocsComponentsToggleExamplesKo {
	_TranslationsDocsComponentsToggleExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Alternar';
}

// Path: docs.components.tooltip.examples
class _TranslationsDocsComponentsTooltipExamplesPt extends TranslationsDocsComponentsTooltipExamplesKo {
	_TranslationsDocsComponentsTooltipExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Tooltip';
}

// Path: docs.components.tracker.examples
class _TranslationsDocsComponentsTrackerExamplesPt extends TranslationsDocsComponentsTrackerExamplesKo {
	_TranslationsDocsComponentsTrackerExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Rastreador';
}

// Path: docs.components.tree.examples
class _TranslationsDocsComponentsTreeExamplesPt extends TranslationsDocsComponentsTreeExamplesKo {
	_TranslationsDocsComponentsTreeExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Árvore';
}

// Path: docs.components.window.examples
class _TranslationsDocsComponentsWindowExamplesPt extends TranslationsDocsComponentsWindowExamplesKo {
	_TranslationsDocsComponentsWindowExamplesPt._(TranslationsPt root) : this._root = root, super.internal(root);

	final TranslationsPt _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Exemplo de Janela';
}
