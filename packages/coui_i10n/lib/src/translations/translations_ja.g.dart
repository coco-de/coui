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
class TranslationsJa extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsJa({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ja,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver);

	/// Metadata for the translations of <ja>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final TranslationsJa _root = this; // ignore: unused_field

	@override 
	TranslationsJa $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsJa(meta: meta ?? this.$meta);

	// Translations
	@override late final _TranslationsWidgetbookJa widgetbook = _TranslationsWidgetbookJa._(_root);
	@override late final _TranslationsDocsJa docs = _TranslationsDocsJa._(_root);
}

// Path: widgetbook
class _TranslationsWidgetbookJa extends TranslationsWidgetbookKo {
	_TranslationsWidgetbookJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsWidgetbookCommonJa common = _TranslationsWidgetbookCommonJa._(_root);
	@override late final _TranslationsWidgetbookLoadingJa loading = _TranslationsWidgetbookLoadingJa._(_root);
	@override late final _TranslationsWidgetbookTabsJa tabs = _TranslationsWidgetbookTabsJa._(_root);
	@override late final _TranslationsWidgetbookPaginationJa pagination = _TranslationsWidgetbookPaginationJa._(_root);
	@override late final _TranslationsWidgetbookTooltipJa tooltip = _TranslationsWidgetbookTooltipJa._(_root);
	@override late final _TranslationsWidgetbookRadioJa radio = _TranslationsWidgetbookRadioJa._(_root);
	@override late final _TranslationsWidgetbookCardJa card = _TranslationsWidgetbookCardJa._(_root);
	@override late final _TranslationsWidgetbookAlertJa alert = _TranslationsWidgetbookAlertJa._(_root);
	@override late final _TranslationsWidgetbookAccordionJa accordion = _TranslationsWidgetbookAccordionJa._(_root);
	@override late final _TranslationsWidgetbookSkeletonJa skeleton = _TranslationsWidgetbookSkeletonJa._(_root);
	@override late final _TranslationsWidgetbookToastJa toast = _TranslationsWidgetbookToastJa._(_root);
	@override late final _TranslationsWidgetbookChipJa chip = _TranslationsWidgetbookChipJa._(_root);
	@override late final _TranslationsWidgetbookCheckboxJa checkbox = _TranslationsWidgetbookCheckboxJa._(_root);
	@override late final _TranslationsWidgetbookToggleJa toggle = _TranslationsWidgetbookToggleJa._(_root);
	@override late final _TranslationsWidgetbookDialogJa dialog = _TranslationsWidgetbookDialogJa._(_root);
	@override late final _TranslationsWidgetbookPopoverJa popover = _TranslationsWidgetbookPopoverJa._(_root);
	@override late final _TranslationsWidgetbookTextFieldJa text_field = _TranslationsWidgetbookTextFieldJa._(_root);
	@override late final _TranslationsWidgetbookButtonJa button = _TranslationsWidgetbookButtonJa._(_root);
	@override late final _TranslationsWidgetbookTableJa table = _TranslationsWidgetbookTableJa._(_root);
	@override late final _TranslationsWidgetbookKSwitchJa k_switch = _TranslationsWidgetbookKSwitchJa._(_root);
	@override late final _TranslationsWidgetbookSwitchComponentJa switch_component = _TranslationsWidgetbookSwitchComponentJa._(_root);
	@override late final _TranslationsWidgetbookSelectJa select = _TranslationsWidgetbookSelectJa._(_root);
	@override late final _TranslationsWidgetbookBreadcrumbJa breadcrumb = _TranslationsWidgetbookBreadcrumbJa._(_root);
	@override late final _TranslationsWidgetbookBadgeJa badge = _TranslationsWidgetbookBadgeJa._(_root);
	@override late final _TranslationsWidgetbookThemePreviewJa theme_preview = _TranslationsWidgetbookThemePreviewJa._(_root);
	@override late final _TranslationsWidgetbookChatJa chat = _TranslationsWidgetbookChatJa._(_root);
	@override late final _TranslationsWidgetbookMultipleChoiceJa multiple_choice = _TranslationsWidgetbookMultipleChoiceJa._(_root);
	@override late final _TranslationsWidgetbookFormattedInputJa formatted_input = _TranslationsWidgetbookFormattedInputJa._(_root);
	@override late final _TranslationsWidgetbookSwiperJa swiper = _TranslationsWidgetbookSwiperJa._(_root);
}

// Path: docs
class _TranslationsDocsJa extends TranslationsDocsKo {
	_TranslationsDocsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsCommonJa common = _TranslationsDocsCommonJa._(_root);
	@override late final _TranslationsDocsBadgesJa badges = _TranslationsDocsBadgesJa._(_root);
	@override late final _TranslationsDocsFlavorsJa flavors = _TranslationsDocsFlavorsJa._(_root);
	@override late final _TranslationsDocsNavigationJa navigation = _TranslationsDocsNavigationJa._(_root);
	@override late final _TranslationsDocsPagesJa pages = _TranslationsDocsPagesJa._(_root);
	@override late final _TranslationsDocsComponentsJa components = _TranslationsDocsComponentsJa._(_root);
}

// Path: widgetbook.common
class _TranslationsWidgetbookCommonJa extends TranslationsWidgetbookCommonKo {
	_TranslationsWidgetbookCommonJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get increment_progress => '進捗を増加させる';
	@override String selected_tab({required Object index}) => '選択されたタブ: ${index}';
	@override String current_page({required Object page}) => '現在のページ: ${page}';
	@override String total_pages({required Object count}) => '全ページ: ${count}';
	@override String page_of({required Object current, required Object total}) => '${current}ページ / ${total}';
	@override String get hover_over_icon => 'アイコンの上にカーソルを合わせてください';
	@override String counter({required Object count}) => 'カウンター: ${count}';
	@override String selected_rows({required Object count}) => '選択された行: ${count}';
	@override String value({required Object value}) => '値: ${value}';
	@override String selected_cells({required Object count}) => '選択されたセル: ${count}';
}

// Path: widgetbook.loading
class _TranslationsWidgetbookLoadingJa extends TranslationsWidgetbookLoadingKo {
	_TranslationsWidgetbookLoadingJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get indeterminate => '無限ローディング';
	@override String with_value({required Object percent}) => '値を含む (${percent}%)';
	@override String get custom_size => 'カスタムサイズ';
	@override String get custom_height => 'カスタム高さ';
	@override String get circular_progress => '円形進捗';
	@override String get linear_progress => '線形進捗';
}

// Path: widgetbook.tabs
class _TranslationsWidgetbookTabsJa extends TranslationsWidgetbookTabsKo {
	_TranslationsWidgetbookTabsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get home => 'ホーム';
	@override String get profile => 'プロフィール';
	@override String get settings => '設定';
	@override String get overview => '概要';
	@override String get details => '詳細';
	@override String get history => '履歴';
	@override String get overview_content => '概要コンテンツ';
	@override String get details_content => '詳細コンテンツ';
	@override String get history_content => '履歴コンテンツ';
	@override String get general_info => '項目に関する一般情報';
	@override String get specifications => '詳細仕様と属性';
	@override String get timeline => '変更と更新のタイムライン';
}

// Path: widgetbook.pagination
class _TranslationsWidgetbookPaginationJa extends TranslationsWidgetbookPaginationKo {
	_TranslationsWidgetbookPaginationJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get show_skip_to_first => '最初にスキップを表示';
	@override String get show_skip_to_last => '最後にスキップを表示';
	@override String get hide_previous_on_first => '最初のページで前を隠す';
	@override String get hide_next_on_last => '最後のページで次を隠す';
	@override String get max_visible_pages => '最大表示ページ数';
}

// Path: widgetbook.tooltip
class _TranslationsWidgetbookTooltipJa extends TranslationsWidgetbookTooltipKo {
	_TranslationsWidgetbookTooltipJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get helpful_message => '役立つツールチップメッセージです';
	@override String get tooltip_above => '上のツールチップ';
	@override String get tooltip_below => '下のツールチップ';
	@override String get tooltip_left => '左のツールチップ';
	@override String get tooltip_right => '右のツールチップ';
	@override String get top => '上';
	@override String get bottom => '下';
	@override String get left => '左';
	@override String get right => '右';
}

// Path: widgetbook.radio
class _TranslationsWidgetbookRadioJa extends TranslationsWidgetbookRadioKo {
	_TranslationsWidgetbookRadioJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get small => '小さい';
	@override String get medium => '中くらい';
	@override String get large => '大きい';
}

// Path: widgetbook.card
class _TranslationsWidgetbookCardJa extends TranslationsWidgetbookCardKo {
	_TranslationsWidgetbookCardJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get card_content => 'カードコンテンツ';
	@override String get gradient_card => 'グラデーションカード';
	@override String get custom_decoration => 'カスタムデコレーション付きカード';
}

// Path: widgetbook.alert
class _TranslationsWidgetbookAlertJa extends TranslationsWidgetbookAlertKo {
	_TranslationsWidgetbookAlertJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '通知タイトル';
	@override String get message => '通知メッセージです。';
}

// Path: widgetbook.accordion
class _TranslationsWidgetbookAccordionJa extends TranslationsWidgetbookAccordionKo {
	_TranslationsWidgetbookAccordionJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get what_is_coui => 'CoUI Flutterとは？';
	@override String get what_is_coui_answer => 'CoUI Flutterは、一貫したデザインパターンで現代的でアクセスしやすいFlutterアプリケーションを構築するために設計された包括的なUIコンポーネントライブラリです。';
	@override String get how_to_install => 'どのようにインストールしますか？';
	@override String get how_to_install_answer => 'pubspec.yamlの依存関係にcoui_flutterを追加し、flutter pub getを実行してパッケージをインストールしてください。';
	@override String get is_customizable => 'カスタマイズ可能ですか？';
	@override String get is_customizable_answer => 'はい！ CoUI Flutterは、ThemeDataを通じて色、タイポグラフィ、間隔などをカスタマイズできる包括的なテーマサポートを提供します。';
	@override String get getting_started => '始め方';
	@override String get getting_started_answer => 'パッケージをインストールし、プロジェクトに取り込むことから始めてください。詳細な設定方法はドキュメントを参照してください。';
	@override String get features_expanded => '機能（基本機能を拡張）';
	@override String get features_answer => 'CoUI Flutterには、ボタン、フォーム、ダイアログ、ナビゲーションコンポーネントなどが含まれています。すべてのコンポーネントは、アクセシビリティとテーマを考慮して設計されています。';
	@override String get support => 'サポート';
	@override String get support_answer => '質問やサポートが必要な場合は、GitHubリポジトリを訪れるか、docs.coui.devでドキュメントを確認してください。';
}

// Path: widgetbook.skeleton
class _TranslationsWidgetbookSkeletonJa extends TranslationsWidgetbookSkeletonKo {
	_TranslationsWidgetbookSkeletonJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get skeleton_enabled => 'スケルトン有効化:';
	@override String get title_text => 'タイトルです';
	@override String get description_text => '長い説明テキストです';
	@override String get short_text => '短いテキスト';
	@override String get without_skeleton => 'スケルトンなし:';
	@override String get with_skeleton => 'スケルトン含む:';
	@override String get user_name => 'ユーザー名';
	@override String get user_email => 'user@example.com';
	@override String get article_title => '記事タイトル';
	@override String get posted_date => '2024年1月1日掲載';
	@override String get bio_description => '日常を記録する開発者です';
	@override String get show_content => 'コンテンツを表示';
	@override String get show_loading => 'ローディングを表示';
	@override String get article_content => 'これは記事内容の例です。ローディング中にスケルトンで置き換えられます。';
}

// Path: widgetbook.toast
class _TranslationsWidgetbookToastJa extends TranslationsWidgetbookToastKo {
	_TranslationsWidgetbookToastJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get success => '成功';
	@override String get operation_completed => '作業が成功裏に完了しました';
	@override String get show_toast => 'トーストを表示';
	@override String toast_at({required Object location}) => '${location}にトースト';
	@override String get top_left => '左上';
	@override String get top_center => '上中央';
	@override String get top_right => '右上';
	@override String get bottom_left => '左下';
	@override String get bottom_center => '下中央';
	@override String get bottom_right => '右下';
}

// Path: widgetbook.chip
class _TranslationsWidgetbookChipJa extends TranslationsWidgetbookChipKo {
	_TranslationsWidgetbookChipJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get chip => 'チップ';
}

// Path: widgetbook.checkbox
class _TranslationsWidgetbookCheckboxJa extends TranslationsWidgetbookCheckboxKo {
	_TranslationsWidgetbookCheckboxJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get accept_terms => '利用規約に同意します';
	@override String get tristate => '三つの状態';
}

// Path: widgetbook.toggle
class _TranslationsWidgetbookToggleJa extends TranslationsWidgetbookToggleKo {
	_TranslationsWidgetbookToggleJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get toggle => 'トグル';
}

// Path: widgetbook.dialog
class _TranslationsWidgetbookDialogJa extends TranslationsWidgetbookDialogKo {
	_TranslationsWidgetbookDialogJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic_dialog => '基本ダイアログ';
	@override String get basic_title => '基本ダイアログ';
	@override String get basic_content => 'タイトルと内容があるシンプルなダイアログです。';
	@override String get simple_dialog_content => 'タイトルと内容のあるシンプルなダイアログです。';
	@override String get show_basic => '基本表示';
	@override String get show_basic_dialog => '基本ダイアログを表示';
	@override String get confirm_action => 'アクションを確認';
	@override String get confirm_title => '確認';
	@override String get confirm_content => '本当にこの操作を行いますか？';
	@override String get confirm_action_content => '本当にこのアクションを実行しますか？ このアクションはキャンセルできません。';
	@override String get cancel => 'キャンセル';
	@override String get confirm => '確認';
	@override String get show_confirmation => '確認表示';
	@override String get show_confirmation_dialog => '確認ダイアログを表示';
	@override String get warning => '警告';
	@override String get warning_title => '警告';
	@override String get warning_content => 'このアクションはデータに影響を与える可能性があります。慎重に進めてください。';
	@override String get dismiss => '閉じる';
	@override String get show_warning => '警告表示';
	@override String get show_warning_dialog => '警告ダイアログを表示';
}

// Path: widgetbook.popover
class _TranslationsWidgetbookPopoverJa extends TranslationsWidgetbookPopoverKo {
	_TranslationsWidgetbookPopoverJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get popover_content => 'ポップオーバーコンテンツ';
	@override String get content_title => 'ポップオーバータイトル';
	@override String get content_description => 'カスタマイズ可能なコンテンツを持つポップオーバーです。';
	@override String get customizable_content => 'カスタマイズ可能なコンテンツを持つポップオーバーです。';
	@override String get show_popover => 'ポップオーバーを表示';
	@override String popover_at({required Object position}) => '${position}にポップオーバー';
	@override String get top => '上';
	@override String get bottom => '下';
	@override String get left => '左';
	@override String get right => '右';
}

// Path: widgetbook.text_field
class _TranslationsWidgetbookTextFieldJa extends TranslationsWidgetbookTextFieldKo {
	_TranslationsWidgetbookTextFieldJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get enter_name => '名前を入力してください';
	@override String get type_here => 'ここに入力してください';
}

// Path: widgetbook.button
class _TranslationsWidgetbookButtonJa extends TranslationsWidgetbookButtonKo {
	_TranslationsWidgetbookButtonJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get primary_button => '基本ボタン';
	@override String get secondary_button => '補助ボタン';
	@override String get dashed_button => 'ファイルアップロード';
	@override String get upload_file => 'ファイルアップロード';
}

// Path: widgetbook.table
class _TranslationsWidgetbookTableJa extends TranslationsWidgetbookTableKo {
	_TranslationsWidgetbookTableJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get name => '名前';
	@override String get email => 'メール';
	@override String get role => '役割';
	@override String get john_doe => 'ジョンドー';
	@override String get john_email => 'hong@example.com';
	@override String get developer => '開発者';
	@override String get jane_smith => 'ジェーンスミス';
	@override String get jane_email => 'kim@example.com';
	@override String get designer => 'デザイナー';
	@override String get bob_johnson => 'ボブジョンソン';
	@override String get bob_email => 'lee@example.com';
	@override String get manager => 'マネージャー';
	@override String get select => '選択';
	@override String get product => '製品';
	@override String get price => '価格';
	@override String get stock => '在庫';
	@override String get laptop => 'ノートパソコン';
	@override String get mouse => 'マウス';
	@override String get keyboard => 'キーボード';
}

// Path: widgetbook.k_switch
class _TranslationsWidgetbookKSwitchJa extends TranslationsWidgetbookKSwitchKo {
	_TranslationsWidgetbookKSwitchJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get k_switch => 'スイッチ';
}

// Path: widgetbook.switch_component
class _TranslationsWidgetbookSwitchComponentJa extends TranslationsWidgetbookSwitchComponentKo {
	_TranslationsWidgetbookSwitchComponentJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get switch_label => 'スイッチラベル';
}

// Path: widgetbook.select
class _TranslationsWidgetbookSelectJa extends TranslationsWidgetbookSelectKo {
	_TranslationsWidgetbookSelectJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get apple => 'リンゴ';
	@override String get banana => 'バナナ';
	@override String get cherry => 'さくらんぼ';
	@override String get date => 'デーツ';
	@override String get choose_size => 'サイズを選択してください';
	@override String get small => '小さい';
	@override String get medium => '中くらい';
	@override String get large => '大きい';
	@override String get extra_large => '特大';
}

// Path: widgetbook.breadcrumb
class _TranslationsWidgetbookBreadcrumbJa extends TranslationsWidgetbookBreadcrumbKo {
	_TranslationsWidgetbookBreadcrumbJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get home => 'ホーム';
	@override String get products => '製品';
	@override String get electronics => '電子製品';
	@override String get smartphones => 'スマートフォン';
	@override String get documents => '文書';
	@override String get projects => 'プロジェクト';
	@override String get current_folder => '現在のフォルダー';
	@override String current_path({required Object path}) => '現在のパス: ${path}';
}

// Path: widgetbook.badge
class _TranslationsWidgetbookBadgeJa extends TranslationsWidgetbookBadgeKo {
	_TranslationsWidgetbookBadgeJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get primary => '基本';
	@override String get secondary => '補助';
	@override String get outline => '外枠';
	@override String get destructive => '危険';
	@override String get featured => 'おすすめ';
	@override String get more => 'もっと見る';
	@override String get verified => '認証済み';
	@override String get error => 'エラー';
	@override String get click_me => 'クリックしてください';
	@override String get clickable => 'クリック可能';
}

// Path: widgetbook.theme_preview
class _TranslationsWidgetbookThemePreviewJa extends TranslationsWidgetbookThemePreviewKo {
	_TranslationsWidgetbookThemePreviewJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'テーマプレビュー';
	@override String get description => 'すべてのテーマトークンとコンポーネントスタイルの包括的な概要';
	@override String get color_palette => 'カラーパレット';
	@override String get brand_colors => 'ブランドカラー';
	@override String get base_colors => '基本カラー';
	@override String get status_colors => 'ステータスカラー';
	@override String get buttons => 'ボタン';
	@override String get primary_button => 'プライマリ';
	@override String get secondary_button => 'セカンダリ';
	@override String get outline_button => 'アウトライン';
	@override String get ghost_button => 'ゴースト';
	@override String get destructive_button => '破壊的';
	@override String get disabled_button => '無効';
	@override String get cards => 'カード';
	@override String get card_title => 'カードタイトル';
	@override String get card_description => 'サンプルカードの説明です。';
	@override String get surface_card => 'サーフェスカード';
	@override String get filled_variant => '背景のあるフィルドスタイル';
	@override String get form_elements => 'フォーム要素';
	@override String get text_input_placeholder => 'テキストを入力してください...';
	@override String get checkbox_checked => '選択済み';
	@override String get checkbox_unchecked => '選択されていない';
	@override String get toggle_on => 'オン';
	@override String get toggle_off => 'オフ';
	@override String get alerts => 'アラート';
	@override String get info_alert => '情報アラート';
	@override String get info_alert_message => 'ガイダンスメッセージです。';
	@override String get error_alert => 'エラーアラート';
	@override String get error_alert_message => '問題が発生しました。';
	@override String get badges_chips => 'バッジ & チップ';
	@override String get primary_badge => 'プライマリ';
	@override String get secondary_badge => 'セカンダリ';
	@override String get outline_badge => 'アウトライン';
	@override String get destructive_badge => '破壊的';
	@override String get chip_example => 'お気に入り';
	@override String get typography => 'タイポグラフィ';
	@override String get heading_1 => '見出し 1';
	@override String get heading_2 => '見出し 2';
	@override String get heading_3 => '見出し 3';
	@override String get heading_4 => '見出し 4';
	@override String get body_text => '通常の太さの本文テキストです。';
	@override String get small_text => 'キャプション用の小さなテキストです。';
	@override String get muted_text => '副次情報用の薄いテキストです。';
	@override String get bold_text => '強調のための太字テキストです。';
	@override String get spacing_radius => '間隔 & 丸み';
	@override String get border_radius => 'ボーダーの丸み';
	@override String get loading_states => 'ローディング状態';
}

// Path: widgetbook.chat
class _TranslationsWidgetbookChatJa extends TranslationsWidgetbookChatKo {
	_TranslationsWidgetbookChatJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get hello => 'こんにちは！お元気ですか？';
	@override String get doing_great => '元気です、ありがとう！';
	@override String get nice_weather => '今日はいい天気ですね！';
	@override String get yes_beautiful => 'はい、きれいですね！';
	@override String get sender => '送信者';
	@override String get receiver => '受信者';
}

// Path: widgetbook.multiple_choice
class _TranslationsWidgetbookMultipleChoiceJa extends TranslationsWidgetbookMultipleChoiceKo {
	_TranslationsWidgetbookMultipleChoiceJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get option_a => 'Option A';
	@override String get option_b => 'Option B';
	@override String get option_c => 'Option C';
	@override String get option_d => 'Option D';
	@override String selected_value({required Object value}) => '選択: ${value}';
	@override String selected_values({required Object values}) => '選択: ${values}';
}

// Path: widgetbook.formatted_input
class _TranslationsWidgetbookFormattedInputJa extends TranslationsWidgetbookFormattedInputKo {
	_TranslationsWidgetbookFormattedInputJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get date_format => '日付形式 (MM/DD/YYYY)';
	@override String get time_format => '時間形式 (HH:MM)';
	@override String current_value({required Object value}) => '現在の値: ${value}';
}

// Path: widgetbook.swiper
class _TranslationsWidgetbookSwiperJa extends TranslationsWidgetbookSwiperKo {
	_TranslationsWidgetbookSwiperJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get swipe_hint => 'スワイプまたはタップして開く';
	@override String get overlay_content => 'オーバーレイコンテンツ';
	@override String get close => '閉じる';
}

// Path: docs.common
class _TranslationsDocsCommonJa extends TranslationsDocsCommonKo {
	_TranslationsDocsCommonJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get app_name => 'coui_flutter';
	@override String get search_documentation => 'ドキュメントを検索...';
	@override String get docs => 'ドキュメント';
	@override String get components => 'コンポーネント';
	@override String get close => '閉じる';
	@override String get on_this_page => 'このページの目次';
	@override String get work_in_progress_title => '開発中';
	@override String get work_in_progress_message => 'このページはまだ開発中です。後で再訪してください。';
	@override String get add => '追加';
	@override String get reset => 'リセット';
	@override String get prev => '前へ';
	@override String get next => '次へ';
	@override String get finish => '完了';
	@override String get open => '開く';
	@override String get disabled => '無効';
	@override String get refresh => '更新';
	@override String get rebuild => '再構築';
	@override String get change_color => '色の変更';
}

// Path: docs.badges
class _TranslationsDocsBadgesJa extends TranslationsDocsBadgesKo {
	_TranslationsDocsBadgesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get k_new => '新しい';
	@override String get updated => '更新済み';
	@override String get wip => '作成中';
	@override String get experimental => '実験的';
}

// Path: docs.flavors
class _TranslationsDocsFlavorsJa extends TranslationsDocsFlavorsKo {
	_TranslationsDocsFlavorsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get local => 'ローカル';
	@override String get experimental => '実験的';
	@override String get unknown => '不明';
}

// Path: docs.navigation
class _TranslationsDocsNavigationJa extends TranslationsDocsNavigationKo {
	_TranslationsDocsNavigationJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get getting_started => '始める';
	@override String get animation => 'アニメーション';
	@override String get control => 'コントロール';
	@override String get disclosure => '開示';
	@override String get display => '表示';
	@override String get feedback => 'フィードバック';
	@override String get form => 'フォーム';
	@override String get layout => 'レイアウト';
	@override String get navigation => 'ナビゲーション';
	@override String get overlay => 'オーバーレイ';
	@override String get utility => 'ユーティリティ';
	@override String get my_account => '私のアカウント';
	@override String get profile => 'プロフィール';
	@override String get settings => '設定';
	@override String get team => 'チーム';
	@override String get new_team => '新しいチーム';
	@override String get billing => '請求';
	@override String get api => 'API';
	@override String get log_out => 'ログアウト';
	@override String get support => 'サポート';
	@override String get invite_users => 'ユーザーを招待';
	@override String get more => 'もっと見る';
	@override String get github => 'GitHub';
	@override String get note => 'ノート';
	@override String get message => 'メッセージ';
	@override String get keyboard_shortcuts => 'キーボードショートカット';
}

// Path: docs.pages
class _TranslationsDocsPagesJa extends TranslationsDocsPagesKo {
	_TranslationsDocsPagesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsPagesIntroductionJa introduction = _TranslationsDocsPagesIntroductionJa._(_root);
	@override late final _TranslationsDocsPagesInstallationJa installation = _TranslationsDocsPagesInstallationJa._(_root);
	@override late final _TranslationsDocsPagesThemeJa theme = _TranslationsDocsPagesThemeJa._(_root);
	@override late final _TranslationsDocsPagesTypographyJa typography = _TranslationsDocsPagesTypographyJa._(_root);
	@override late final _TranslationsDocsPagesLayoutJa layout = _TranslationsDocsPagesLayoutJa._(_root);
	@override late final _TranslationsDocsPagesWebPreloaderJa web_preloader = _TranslationsDocsPagesWebPreloaderJa._(_root);
	@override late final _TranslationsDocsPagesComponentsListJa components_list = _TranslationsDocsPagesComponentsListJa._(_root);
	@override late final _TranslationsDocsPagesIconsJa icons = _TranslationsDocsPagesIconsJa._(_root);
	@override late final _TranslationsDocsPagesColorsJa colors = _TranslationsDocsPagesColorsJa._(_root);
	@override late final _TranslationsDocsPagesExternalJa external = _TranslationsDocsPagesExternalJa._(_root);
	@override late final _TranslationsDocsPagesStateJa state = _TranslationsDocsPagesStateJa._(_root);
}

// Path: docs.components
class _TranslationsDocsComponentsJa extends TranslationsDocsComponentsKo {
	_TranslationsDocsComponentsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsDocsComponentsAccordionJa accordion = _TranslationsDocsComponentsAccordionJa._(_root);
	@override late final _TranslationsDocsComponentsAlertJa alert = _TranslationsDocsComponentsAlertJa._(_root);
	@override late final _TranslationsDocsComponentsAlertDialogJa alert_dialog = _TranslationsDocsComponentsAlertDialogJa._(_root);
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderJa animated_value_builder = _TranslationsDocsComponentsAnimatedValueBuilderJa._(_root);
	@override late final _TranslationsDocsComponentsAppBarJa app_bar = _TranslationsDocsComponentsAppBarJa._(_root);
	@override late final _TranslationsDocsComponentsAutocompleteJa autocomplete = _TranslationsDocsComponentsAutocompleteJa._(_root);
	@override late final _TranslationsDocsComponentsAvatarJa avatar = _TranslationsDocsComponentsAvatarJa._(_root);
	@override late final _TranslationsDocsComponentsAvatarGroupJa avatar_group = _TranslationsDocsComponentsAvatarGroupJa._(_root);
	@override late final _TranslationsDocsComponentsBadgeJa badge = _TranslationsDocsComponentsBadgeJa._(_root);
	@override late final _TranslationsDocsComponentsBreadcrumbJa breadcrumb = _TranslationsDocsComponentsBreadcrumbJa._(_root);
	@override late final _TranslationsDocsComponentsButtonJa button = _TranslationsDocsComponentsButtonJa._(_root);
	@override late final _TranslationsDocsComponentsCalendarJa calendar = _TranslationsDocsComponentsCalendarJa._(_root);
	@override late final _TranslationsDocsComponentsCardJa card = _TranslationsDocsComponentsCardJa._(_root);
	@override late final _TranslationsDocsComponentsCardImageJa card_image = _TranslationsDocsComponentsCardImageJa._(_root);
	@override late final _TranslationsDocsComponentsCarouselJa carousel = _TranslationsDocsComponentsCarouselJa._(_root);
	@override late final _TranslationsDocsComponentsCheckboxJa checkbox = _TranslationsDocsComponentsCheckboxJa._(_root);
	@override late final _TranslationsDocsComponentsChipJa chip = _TranslationsDocsComponentsChipJa._(_root);
	@override late final _TranslationsDocsComponentsChipInputJa chip_input = _TranslationsDocsComponentsChipInputJa._(_root);
	@override late final _TranslationsDocsComponentsCircularProgressJa circular_progress = _TranslationsDocsComponentsCircularProgressJa._(_root);
	@override late final _TranslationsDocsComponentsCodeSnippetJa code_snippet = _TranslationsDocsComponentsCodeSnippetJa._(_root);
	@override late final _TranslationsDocsComponentsCollapsibleJa collapsible = _TranslationsDocsComponentsCollapsibleJa._(_root);
	@override late final _TranslationsDocsComponentsColorPickerJa color_picker = _TranslationsDocsComponentsColorPickerJa._(_root);
	@override late final _TranslationsDocsComponentsCommandJa command = _TranslationsDocsComponentsCommandJa._(_root);
	@override late final _TranslationsDocsComponentsContextMenuJa context_menu = _TranslationsDocsComponentsContextMenuJa._(_root);
	@override late final _TranslationsDocsComponentsDatePickerJa date_picker = _TranslationsDocsComponentsDatePickerJa._(_root);
	@override late final _TranslationsDocsComponentsDialogJa dialog = _TranslationsDocsComponentsDialogJa._(_root);
	@override late final _TranslationsDocsComponentsDividerJa divider = _TranslationsDocsComponentsDividerJa._(_root);
	@override late final _TranslationsDocsComponentsDotIndicatorJa dot_indicator = _TranslationsDocsComponentsDotIndicatorJa._(_root);
	@override late final _TranslationsDocsComponentsDrawerJa drawer = _TranslationsDocsComponentsDrawerJa._(_root);
	@override late final _TranslationsDocsComponentsDropdownMenuJa dropdown_menu = _TranslationsDocsComponentsDropdownMenuJa._(_root);
	@override late final _TranslationsDocsComponentsExpandableSidebarJa expandable_sidebar = _TranslationsDocsComponentsExpandableSidebarJa._(_root);
	@override late final _TranslationsDocsComponentsFormJa form = _TranslationsDocsComponentsFormJa._(_root);
	@override late final _TranslationsDocsComponentsFormattedInputJa formatted_input = _TranslationsDocsComponentsFormattedInputJa._(_root);
	@override late final _TranslationsDocsComponentsHoverCardJa hover_card = _TranslationsDocsComponentsHoverCardJa._(_root);
	@override late final _TranslationsDocsComponentsInputJa input = _TranslationsDocsComponentsInputJa._(_root);
	@override late final _TranslationsDocsComponentsInputOtpJa input_otp = _TranslationsDocsComponentsInputOtpJa._(_root);
	@override late final _TranslationsDocsComponentsItemPickerJa item_picker = _TranslationsDocsComponentsItemPickerJa._(_root);
	@override late final _TranslationsDocsComponentsKeyboardDisplayJa keyboard_display = _TranslationsDocsComponentsKeyboardDisplayJa._(_root);
	@override late final _TranslationsDocsComponentsLinearProgressJa linear_progress = _TranslationsDocsComponentsLinearProgressJa._(_root);
	@override late final _TranslationsDocsComponentsMaterialJa material = _TranslationsDocsComponentsMaterialJa._(_root);
	@override late final _TranslationsDocsComponentsMenubarJa menubar = _TranslationsDocsComponentsMenubarJa._(_root);
	@override late final _TranslationsDocsComponentsMultiselectJa multiselect = _TranslationsDocsComponentsMultiselectJa._(_root);
	@override late final _TranslationsDocsComponentsNavigationBarJa navigation_bar = _TranslationsDocsComponentsNavigationBarJa._(_root);
	@override late final _TranslationsDocsComponentsNavigationMenuJa navigation_menu = _TranslationsDocsComponentsNavigationMenuJa._(_root);
	@override late final _TranslationsDocsComponentsNavigationRailJa navigation_rail = _TranslationsDocsComponentsNavigationRailJa._(_root);
	@override late final _TranslationsDocsComponentsNavigationSidebarJa navigation_sidebar = _TranslationsDocsComponentsNavigationSidebarJa._(_root);
	@override late final _TranslationsDocsComponentsNumberInputJa number_input = _TranslationsDocsComponentsNumberInputJa._(_root);
	@override late final _TranslationsDocsComponentsNumberTickerJa number_ticker = _TranslationsDocsComponentsNumberTickerJa._(_root);
	@override late final _TranslationsDocsComponentsOverflowMarqueeJa overflow_marquee = _TranslationsDocsComponentsOverflowMarqueeJa._(_root);
	@override late final _TranslationsDocsComponentsPaginationJa pagination = _TranslationsDocsComponentsPaginationJa._(_root);
	@override late final _TranslationsDocsComponentsPhoneInputJa phone_input = _TranslationsDocsComponentsPhoneInputJa._(_root);
	@override late final _TranslationsDocsComponentsPopoverJa popover = _TranslationsDocsComponentsPopoverJa._(_root);
	@override late final _TranslationsDocsComponentsProgressJa progress = _TranslationsDocsComponentsProgressJa._(_root);
	@override late final _TranslationsDocsComponentsRadioCardJa radio_card = _TranslationsDocsComponentsRadioCardJa._(_root);
	@override late final _TranslationsDocsComponentsRadioGroupJa radio_group = _TranslationsDocsComponentsRadioGroupJa._(_root);
	@override late final _TranslationsDocsComponentsRefreshTriggerJa refresh_trigger = _TranslationsDocsComponentsRefreshTriggerJa._(_root);
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderJa repeated_animation_builder = _TranslationsDocsComponentsRepeatedAnimationBuilderJa._(_root);
	@override late final _TranslationsDocsComponentsResizableJa resizable = _TranslationsDocsComponentsResizableJa._(_root);
	@override late final _TranslationsDocsComponentsScaffoldJa scaffold = _TranslationsDocsComponentsScaffoldJa._(_root);
	@override late final _TranslationsDocsComponentsSelectJa select = _TranslationsDocsComponentsSelectJa._(_root);
	@override late final _TranslationsDocsComponentsSheetJa sheet = _TranslationsDocsComponentsSheetJa._(_root);
	@override late final _TranslationsDocsComponentsSkeletonJa skeleton = _TranslationsDocsComponentsSkeletonJa._(_root);
	@override late final _TranslationsDocsComponentsSliderJa slider = _TranslationsDocsComponentsSliderJa._(_root);
	@override late final _TranslationsDocsComponentsSortableJa sortable = _TranslationsDocsComponentsSortableJa._(_root);
	@override late final _TranslationsDocsComponentsStarRatingJa star_rating = _TranslationsDocsComponentsStarRatingJa._(_root);
	@override late final _TranslationsDocsComponentsStepperJa stepper = _TranslationsDocsComponentsStepperJa._(_root);
	@override late final _TranslationsDocsComponentsStepsJa steps = _TranslationsDocsComponentsStepsJa._(_root);
	@override late final _TranslationsDocsComponentsSwiperJa swiper = _TranslationsDocsComponentsSwiperJa._(_root);
	@override late final _TranslationsDocsComponentsKSwitchJa k_switch = _TranslationsDocsComponentsKSwitchJa._(_root);
	@override late final _TranslationsDocsComponentsSwitcherJa switcher = _TranslationsDocsComponentsSwitcherJa._(_root);
	@override late final _TranslationsDocsComponentsTabListJa tab_list = _TranslationsDocsComponentsTabListJa._(_root);
	@override late final _TranslationsDocsComponentsTabPaneJa tab_pane = _TranslationsDocsComponentsTabPaneJa._(_root);
	@override late final _TranslationsDocsComponentsTableJa table = _TranslationsDocsComponentsTableJa._(_root);
	@override late final _TranslationsDocsComponentsTabsJa tabs = _TranslationsDocsComponentsTabsJa._(_root);
	@override late final _TranslationsDocsComponentsTextAreaJa text_area = _TranslationsDocsComponentsTextAreaJa._(_root);
	@override late final _TranslationsDocsComponentsTimePickerJa time_picker = _TranslationsDocsComponentsTimePickerJa._(_root);
	@override late final _TranslationsDocsComponentsTimelineJa timeline = _TranslationsDocsComponentsTimelineJa._(_root);
	@override late final _TranslationsDocsComponentsTimelineAnimationJa timeline_animation = _TranslationsDocsComponentsTimelineAnimationJa._(_root);
	@override late final _TranslationsDocsComponentsToastJa toast = _TranslationsDocsComponentsToastJa._(_root);
	@override late final _TranslationsDocsComponentsToggleJa toggle = _TranslationsDocsComponentsToggleJa._(_root);
	@override late final _TranslationsDocsComponentsTooltipJa tooltip = _TranslationsDocsComponentsTooltipJa._(_root);
	@override late final _TranslationsDocsComponentsTrackerJa tracker = _TranslationsDocsComponentsTrackerJa._(_root);
	@override late final _TranslationsDocsComponentsTreeJa tree = _TranslationsDocsComponentsTreeJa._(_root);
	@override late final _TranslationsDocsComponentsWindowJa window = _TranslationsDocsComponentsWindowJa._(_root);
}

// Path: docs.pages.introduction
class _TranslationsDocsPagesIntroductionJa extends TranslationsDocsPagesIntroductionKo {
	_TranslationsDocsPagesIntroductionJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '紹介';
	@override String get description => 'coui_flutterを始める';
	@override String get lead => 'Coui/UIの美しくデザインされたコンポーネントがFlutterで使用できるようになりました。';
	@override String get welcome_paragraph_1 => 'coui_flutterは、Flutterデスクトップとウェブアプリケーションのために特別に設計された多様で包括的なUIコンポーネントセットです。クロスプラットフォームアプリの構築が増加する中で、デスクトップとウェブインターフェースの独自のデザイン要件を強調するツールキットの必要性を認識しました。';
	@override String get welcome_paragraph_2 => 'このパッケージは、現代的なデスクトップおよびウェブデザイン原則に合った幅広いカスタマイズ可能でレスポンシブなコンポーネントを提供します。洗練されたビジネスアプリケーション、スタイリッシュなダッシュボード、または生産性ツールを構築する際に、私たちのコンポーネントはプロフェッショナルで洗練されたUIを迅速かつ効率的に作成するために設計されています。';
	@override String get features => '主な機能';
	@override late final _TranslationsDocsPagesIntroductionFeaturesListJa features_list = _TranslationsDocsPagesIntroductionFeaturesListJa._(_root);
	@override String get notes => '注意事項';
	@override String get notes_paragraph_1 => 'このパッケージはまだ開発中であり、今後変更がある可能性があります。本番環境でこのパッケージを使用する際は注意してください。';
	@override String get notes_paragraph_2 => 'このパッケージはCoui/UIとは提携していません。このパッケージはコミュニティ主導のプロジェクトです。';
	@override String get faq => 'よくある質問';
	@override String get faq_gorouter_q => 'GoRouterをサポートしていますか？';
	@override String get faq_gorouter_a => 'はい、サポートしています。coui_flutterと一緒にGoRouterを使用できます。';
	@override String get faq_usage_q => '私のプロジェクトで使用できますか？';
	@override String get faq_usage_a => 'はい！個人および商業プロジェクトに無料で使用できます。著作権表示は不要です。';
	@override String get faq_material_q => 'Material/Cupertinoウィジェットと一緒に使用できますか？';
	@override String get faq_material_a_1 => 'もちろんです！';
	@override String get faq_material_a_2 => 'このページをご覧ください！';
	@override String get faq_style_q => 'どのスタイルを使用するか設定できますか？ (Default/New York)';
	@override String get faq_style_a_1 => '残念ながらできません。このパッケージはNew Yorkスタイルのみをサポートしています。しかし、一度Coui/UIの基本スタイルが必要な場合は、';
	@override String get faq_style_a_2 => 'このパッケージ';
	@override String get faq_style_a_3 => 'をお勧めします。制作者：';
	@override String get links => 'リンク';
	@override String get link_github => 'Github: ';
	@override String get link_pubdev => 'pub.dev: ';
	@override String get link_discord => 'Discord: ';
}

// Path: docs.pages.installation
class _TranslationsDocsPagesInstallationJa extends TranslationsDocsPagesInstallationKo {
	_TranslationsDocsPagesInstallationJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'インストール';
	@override String get description => 'プロジェクトにcoui_flutterをインストールする';
	@override String get stable_version => '安定版';
	@override String get experimental_version => '実験版';
	@override String get step1_title => '新しいFlutterプロジェクトを作成';
	@override String get step1_content => '次のコマンドを使用して新しいFlutterプロジェクトを作成します:';
	@override String get step2_title => '依存関係の追加';
	@override String get step2_content => '次に、プロジェクトにcoui_flutterの依存関係を追加します。';
	@override String get step3_title => 'パッケージのインポート';
	@override String get step3_content => 'これで、Dartコードでパッケージをインポートできます。';
	@override String get step4_title => 'CouiAppウィジェットの追加';
	@override String get step4_content => 'main関数にCouiAppウィジェットを追加します。';
	@override String get step5_title => 'アプリの実行';
	@override String get step5_content => '次のコマンドを使用してアプリを実行します:';
	@override String get experimental_intro => '実験版はGitHubで利用できます。';
	@override String get experimental_usage => '実験版を使用するには、pubspec.yamlファイルでバージョン番号の代わりにgitを使用します:';
	@override String get see_page => '参照: ';
	@override String get this_page => 'このページ';
	@override String get for_more_info => ' 詳細情報。';
	@override String get warning_title => '警告';
	@override String get warning_content => '実験版には互換性を壊す変更が含まれている可能性があり、プロダクションでの使用は推奨されません。このバージョンはテストおよび開発目的でのみ使用されます。';
}

// Path: docs.pages.theme
class _TranslationsDocsPagesThemeJa extends TranslationsDocsPagesThemeKo {
	_TranslationsDocsPagesThemeJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'テーマ';
	@override String get description => 'テーマのカスタマイズ';
	@override String get custom_color_scheme => 'カスタムカラースキーム';
	@override String get custom_color_scheme_desc => 'カスタムカラースキームを使用してアプリの外観をカスタマイズできます。';
	@override String get premade_color_schemes => 'プレメイドカラースキーム';
	@override String get premade_color_schemes_desc => 'プレメイドカラースキームを使用してアプリの外観をカスタマイズできます。';
	@override String get radius => '半径';
	@override String get radius_desc => '半径を変更してアプリがどれだけ丸く見えるかをカスタマイズできます。';
	@override String get scaling => 'スケーリング';
	@override String get scaling_desc => 'スケーリングを変更してcoui_flutterコンポーネントのサイズをカスタマイズできます。';
	@override String get scaling_alert => '全体のアプリを拡大/縮小しません。coui_flutterコンポーネントのみに影響があります。';
	@override String get surface_opacity => '表面の不透明度';
	@override String get surface_opacity_desc => '表面の不透明度を変更して表面の不透明度をカスタマイズできます。';
	@override String get surface_blur => '表面のぼかし';
	@override String get surface_blur_desc => '表面のぼかしを変更して表面のぼかしをカスタマイズできます。';
	@override String get code => 'コード';
	@override String get code_desc => '次のコードを使用してカラースキームを適用してください。';
}

// Path: docs.pages.typography
class _TranslationsDocsPagesTypographyJa extends TranslationsDocsPagesTypographyKo {
	_TranslationsDocsPagesTypographyJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'タイポグラフィ';
	@override String get description => 'テキストスタイル';
	@override String get headline1 => '見出し1';
	@override String get headline2 => '見出し2';
	@override String get headline3 => '見出し3';
	@override String get headline4 => '見出し4';
	@override String get paragraph => '段落';
	@override String get blockquote => '引用';
	@override String get list => 'リスト';
	@override String get inline_code => 'インラインコード';
	@override String get lead => 'リード';
	@override String get large_text => '大きなテキスト';
	@override String get small_text => '小さなテキスト';
	@override String get muted_text => 'グレーのテキスト';
	@override String get sans => 'サンセリフ';
	@override String get mono => 'モノスペース';
	@override String get extra_small => '非常に小さい';
	@override String get small => '小さい';
	@override String get base => '基本';
	@override String get large => '大きい';
	@override String get extra_large => '非常に大きい';
	@override String get extra_2x_large => '非常に2倍の大きさ';
	@override String get extra_3x_large => '非常に3倍の大きさ';
	@override String get extra_4x_large => '非常に4倍の大きさ';
	@override String get extra_5x_large => '非常に5倍の大きさ';
	@override String get extra_6x_large => '非常に6倍の大きさ';
	@override String get extra_7x_large => '非常に7倍の大きさ';
	@override String get extra_8x_large => '非常に8倍の大きさ';
	@override String get extra_9x_large => '非常に9倍の大きさ';
	@override String get thin => '細い';
	@override String get extra_light => '非常に軽い';
	@override String get light => '軽い';
	@override String get normal => '通常';
	@override String get medium => '中間';
	@override String get semi_bold => 'セミボールド';
	@override String get bold => 'ボールド';
	@override String get extra_bold => '非常にボールド';
	@override String get black => 'ブラック';
	@override String get italic => 'イタリック';
}

// Path: docs.pages.layout
class _TranslationsDocsPagesLayoutJa extends TranslationsDocsPagesLayoutKo {
	_TranslationsDocsPagesLayoutJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'レイアウト';
	@override String get description => 'ページレイアウトの構成';
	@override String get padding => 'パディング';
	@override String get margin => 'マージン';
	@override String get center => 'センター';
	@override String get gapped_column => '間隔のあるカラム';
	@override String get gapped_row => '間隔のある行';
	@override String get separated_column => '分離されたカラム';
	@override String get separated_row => '分離された行';
	@override String get basic_layout => '基本レイアウト';
}

// Path: docs.pages.web_preloader
class _TranslationsDocsPagesWebPreloaderJa extends TranslationsDocsPagesWebPreloaderKo {
	_TranslationsDocsPagesWebPreloaderJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'ウェブプレローダー';
	@override String get description => 'ウェブローディング画面';
	@override String get step1_title => 'ウェブディレクトリを作成';
	@override String get step1_content => 'ウェブディレクトリがない場合は作成してください。';
	@override String get step1_note => '* レガシーFlutterウェブを使用している場合は、上記のコマンドを使用してアップグレードする必要があります。';
	@override String get step1_button => '詳細情報はこちらをクリックしてください。';
	@override String get step2_title => 'スクリプトを追加';
	@override String get step2_content => '次に、次のプリメイドのプリローダーのいずれかを選択し、コピーしてください:';
	@override String get step2_standard => '標準プリローダー';
	@override String get step3_title => 'スクリプトを貼り付け';
	@override String get step3_content_1 => 'あなたの';
	@override String get step3_content_2 => 'ファイルを開き、';
	@override String get step3_content_3 => 'タグ内にスクリプトを貼り付けてください。';
	@override String get step3_example => '例えば:';
	@override String get step4_title => 'アプリを実行';
	@override String get step4_content => '次のコマンドを使用してアプリを実行してください。';
	@override String get alert_title => '貢献する';
	@override String get alert_content_1 => '共有したいプリローダーがある場合は、';
	@override String get alert_button => 'web_loaders';
	@override String get alert_content_2 => 'ディレクトリにプルリクエストを作成してください。';
}

// Path: docs.pages.components_list
class _TranslationsDocsPagesComponentsListJa extends TranslationsDocsPagesComponentsListKo {
	_TranslationsDocsPagesComponentsListJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'コンポーネント';
	@override String get description => '再利用可能なコンポーネントのリスト';
	@override String get work_in_progress => '作業中';
	@override String get animation => 'アニメーション';
	@override String get disclosure => '開示';
	@override String get feedback => 'フィードバック';
	@override String get forms => 'フォーム';
	@override String get layout => 'レイアウト';
	@override String get navigation => 'ナビゲーション';
	@override String get surfaces => '表面';
	@override String get data_display => 'データ表示';
	@override String get utilities => 'ユーティリティ';
}

// Path: docs.pages.icons
class _TranslationsDocsPagesIconsJa extends TranslationsDocsPagesIconsKo {
	_TranslationsDocsPagesIconsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'アイコン';
	@override String get description => 'アイコンシステム';
	@override String get use_this_code => 'このアイコンを表示するには、次のコードを使用してください：';
	@override String get search_icons => 'アイコン検索';
	@override String get radix_icons => 'Radixアイコン';
	@override String get bootstrap_icons => 'Bootstrapアイコン';
	@override String get lucide_icons => 'Lucideアイコン';
}

// Path: docs.pages.colors
class _TranslationsDocsPagesColorsJa extends TranslationsDocsPagesColorsKo {
	_TranslationsDocsPagesColorsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '色';
	@override String get description => 'カラーパレット';
	@override String get use_this_code => 'この色を表示するには、次のコードを使用してください：';
	@override String get color_and_colorshades => 'ColorおよびColorShades/ColorSwatch定数';
	@override String get predefined_colors => 'あらかじめ定義された色';
	@override String get generate_color => '色を生成';
	@override String get hue_shift => '色相シフト';
	@override String get saturation_step_up => '彩度増加ステップ';
	@override String get saturation_step_down => '彩度減少ステップ';
	@override String get lightness_step_up => '明度増加ステップ';
	@override String get lightness_step_down => '明度減少ステップ';
	@override String get cancel => 'キャンセル';
	@override String get reset_options => 'オプションをリセット';
	@override String get reset_confirmation => 'オプションをリセットしますか？';
}

// Path: docs.pages.external
class _TranslationsDocsPagesExternalJa extends TranslationsDocsPagesExternalKo {
	_TranslationsDocsPagesExternalJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => 'Material/Cupertino';
	@override String get description => 'Flutterの基本ウィジェット';
}

// Path: docs.pages.state
class _TranslationsDocsPagesStateJa extends TranslationsDocsPagesStateKo {
	_TranslationsDocsPagesStateJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get title => '状態管理';
	@override String get description => '状態管理パターン';
	@override String get intro_1 => 'Flutterでは、すべてがウィジェットであり、データが保存される場所も同じです。';
	@override String get intro_2 => '内部的にcoui_flutterは独自の状態管理システムを持っています。すでに状態管理システムを使用している場合は、coui_flutterと共に使用し続けることができます。';
	@override String get passing_data_to_children => '子にデータを渡す';
	@override String get passing_data_desc => 'Dataウィジェットを使用して、子にデータを渡すことができます。データで発生するすべての変更は、子を再構築します。';
	@override String get rebuild_difference_title => '再構築回数の違いに気づきましたか？';
	@override String get rebuild_difference_content => 'MostInnerWidgetはデータが変更されると再構築されますが、InnerWidgetはそうではありません。これはInnerWidgetがデータを受信していないからです。';
	@override String get setting_data_boundary => 'データ境界の設定';
	@override String get setting_data_boundary_desc => '子がデータにアクセスできないように境界を設定できます。';
	@override String get data_methods_vs => 'Data.maybeOf/Data.of vs Data.maybeFind/Data.find';
	@override String get data_methods_desc_1 => 'と';
	@override String get data_methods_desc_2 => 'はデータを受信し、データが変更されるとウィジェットを再構築します。一方、';
	@override String get data_methods_desc_3 => 'はデータを受信せず、データのみを返します。';
	@override String get data_find_usage => 'はonPressed、onLongPressedなどのメソッドが一度だけ呼び出される場所で使用するのに適しています。';
	@override String get data_of_usage => 'はデータが変更されるとウィジェットを再構築する必要があるbuildメソッド内で使用するのに適しています。';
	@override String get getting_data_from_child => '子からデータを取得';
	@override String get getting_data_desc_1 => 'メソッドを使用して子からデータを取得できます。このメソッドはデータで発生する変更を受信しません。';
	@override String get getting_data_desc_2 => '子のデータを受信すると、無限再構築ループが発生する可能性があります。データを受信する必要がある場合は、親ウィジェットに移動してください。';
	@override String get root_data_title => 'ルートデータに気づきましたか？';
	@override String get root_data_content => '左側の最も内側のデータのデータを使用します。親は最初に接続された子からのみデータを取得できるためです。';
	@override String get setting_messenger_boundary => 'DataMessenger境界の設定';
	@override String get setting_messenger_boundary_desc => '特定の親から子データを取得できないように境界を設定できます。';
	@override String get multidata_widget => 'MultiDataウィジェット';
	@override String get multidata_desc => 'MultiDataウィジェットを使用すると、子に複数のデータを渡すことができます。次の例を見てください：';
	@override String get multidata_avoid_nesting => 'MultiDataウィジェットを使用してネストを回避できます。';
	@override String get example => '例';
	@override String get passing_state_as_controller => 'コントローラとして状態を渡す';
	@override String get passing_state_controller_desc => '状態をコントローラとして子に渡すことができます。これにより、子ウィジェットから親ウィジェットのメソッドを呼び出すことができます。';
	@override String get databuilder => 'DataBuilder';
	@override String get databuilder_desc => 'DataBuilderウィジェットを使用すると、データが変更されるとウィジェットを再構築できます。これは、全体のウィジェットを再構築するのを避けます。';
	@override String get datanotifier => 'DataNotifier';
	@override String get datanotifier_desc => 'DataNotifierを使用すると、ValueListenableから子に値を渡すことができます。';
	@override String get example_with_multidata => 'MultiDataを使用した例';
	@override String get passing_object_as_data => 'オブジェクトをデータとして渡す';
	@override String get passing_object_desc => 'オブジェクトをデータとして渡すときに考慮すべき事項がいくつかあります：';
	@override String get override_equals_hashcode => '1. ==とhashCodeのオーバーライド';
	@override String get override_equals_desc => '前のオブジェクトが新しいオブジェクトと異なるとき、子に通知が送信されます。==とhashCodeをオーバーライドしない場合、フィールドの値が同じであっても、オブジェクトはインスタンス化されるたびに常に異なるものと見なされます。';
	@override String get use_distinctdata => '2. DistinctDataを使用';
	@override String get use_distinctdata_desc => 'DistinctDataは特定のフィールドが変更されたときに子に通知できるミックスインです。';
	@override String get passing_mutable_object => '3. 可変オブジェクトを子に渡す';
	@override String get passing_mutable_object_desc => '子に不変のオブジェクトを渡す方が良いです。可変オブジェクト（例：List、Map、Set、Widget State）はオブジェクト参照が変更されないため、オブジェクトが変更されても子に通知されません。';
	@override String get passing_variable_to_children => '子に変数を渡す';
	@override String get passing_variable_desc => '子に変数を渡すには、Modelウィジェットを使用できます。Dataウィジェットに似ていますが、タイプが厳密でラベル付けされています。';
	@override String get change_variable_from_children => '子で変数を変更';
	@override String get change_variable_desc => '子でモデル値を変更する方法が2つあります：';
	@override String get modelnotifier => 'ModelNotifier';
	@override String get modelnotifier_desc => 'ModelNotifierを使用すると、ValueNotifierから子に値を渡すことができます。親ウィジェットでsetStateを使う必要はありません。';
	@override String get modellistenable => 'ModelListenable';
	@override String get modellistenable_desc => 'ModelListenableは読み取り専用のModelNotifierです。子は値を受信することのみができます。値を変更しようとするとエラーが発生します。';
	@override String get modelbuilder => 'ModelBuilder';
	@override String get modelbuilder_desc => 'ModelBuilderは値が変更されるとウィジェットを受信し、再構築します。DataBuilderに似ていますが、タイプが厳密でラベル付けされています。';
}

// Path: docs.components.accordion
class _TranslationsDocsComponentsAccordionJa extends TranslationsDocsComponentsAccordionKo {
	_TranslationsDocsComponentsAccordionJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'アコーディオン';
	@override String get description => 'アコーディオンは、縦に積み上げられた項目のリストです。各項目を「展開」または「折りたたむ」ことで、その項目に関連するコンテンツを表示できます。';
	@override late final _TranslationsDocsComponentsAccordionExamplesJa examples = _TranslationsDocsComponentsAccordionExamplesJa._(_root);
}

// Path: docs.components.alert
class _TranslationsDocsComponentsAlertJa extends TranslationsDocsComponentsAlertKo {
	_TranslationsDocsComponentsAlertJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'アラート';
	@override String get description => 'アラートは、システムに影響を与える状態を伝えるために使用されます。';
	@override late final _TranslationsDocsComponentsAlertExamplesJa examples = _TranslationsDocsComponentsAlertExamplesJa._(_root);
	@override String get title => 'アラートのタイトル';
	@override String get content => 'アラートの内容です。';
}

// Path: docs.components.alert_dialog
class _TranslationsDocsComponentsAlertDialogJa extends TranslationsDocsComponentsAlertDialogKo {
	_TranslationsDocsComponentsAlertDialogJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'アラートダイアログ';
	@override String get description => 'アラートダイアログは、ユーザーの注意を必要とする重要な情報を表示します。';
	@override late final _TranslationsDocsComponentsAlertDialogExamplesJa examples = _TranslationsDocsComponentsAlertDialogExamplesJa._(_root);
	@override String get click_here => 'ここをクリックしてください';
	@override String get alert_title => 'アラートのタイトル';
	@override String get alert_content => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
}

// Path: docs.components.animated_value_builder
class _TranslationsDocsComponentsAnimatedValueBuilderJa extends TranslationsDocsComponentsAnimatedValueBuilderKo {
	_TranslationsDocsComponentsAnimatedValueBuilderJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'アニメーション値ビルダー';
	@override String get description => '値変更時にアニメーションを自動的に適用するビルダーです。';
	@override late final _TranslationsDocsComponentsAnimatedValueBuilderExamplesJa examples = _TranslationsDocsComponentsAnimatedValueBuilderExamplesJa._(_root);
}

// Path: docs.components.app_bar
class _TranslationsDocsComponentsAppBarJa extends TranslationsDocsComponentsAppBarKo {
	_TranslationsDocsComponentsAppBarJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'アプリバー';
	@override String get description => 'アプリバーは、アプリの上部に表示される基本的なナビゲーション要素です。';
	@override late final _TranslationsDocsComponentsAppBarExamplesJa examples = _TranslationsDocsComponentsAppBarExamplesJa._(_root);
}

// Path: docs.components.autocomplete
class _TranslationsDocsComponentsAutocompleteJa extends TranslationsDocsComponentsAutocompleteKo {
	_TranslationsDocsComponentsAutocompleteJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'オートコンプリート';
	@override String get description => 'ユーザーの入力に応じて提案を表示する入力フィールドです。';
	@override late final _TranslationsDocsComponentsAutocompleteExamplesJa examples = _TranslationsDocsComponentsAutocompleteExamplesJa._(_root);
}

// Path: docs.components.avatar
class _TranslationsDocsComponentsAvatarJa extends TranslationsDocsComponentsAvatarKo {
	_TranslationsDocsComponentsAvatarJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'アバター';
	@override String get description => 'ユーザーまたはエンティティを表す画像またはアイコンです。';
	@override late final _TranslationsDocsComponentsAvatarExamplesJa examples = _TranslationsDocsComponentsAvatarExamplesJa._(_root);
}

// Path: docs.components.avatar_group
class _TranslationsDocsComponentsAvatarGroupJa extends TranslationsDocsComponentsAvatarGroupKo {
	_TranslationsDocsComponentsAvatarGroupJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'アバターグループ';
	@override String get description => '複数のアバターをまとめて表示します。';
	@override late final _TranslationsDocsComponentsAvatarGroupExamplesJa examples = _TranslationsDocsComponentsAvatarGroupExamplesJa._(_root);
}

// Path: docs.components.badge
class _TranslationsDocsComponentsBadgeJa extends TranslationsDocsComponentsBadgeKo {
	_TranslationsDocsComponentsBadgeJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'バッジ';
	@override String get description => '状態または通知の数を表示する小さなラベルです。';
	@override late final _TranslationsDocsComponentsBadgeExamplesJa examples = _TranslationsDocsComponentsBadgeExamplesJa._(_root);
	@override String get primary => 'プライマリ';
	@override String get secondary => 'セカンダリ';
	@override String get outline => 'アウトライン';
	@override String get destructive => '破壊的';
}

// Path: docs.components.breadcrumb
class _TranslationsDocsComponentsBreadcrumbJa extends TranslationsDocsComponentsBreadcrumbKo {
	_TranslationsDocsComponentsBreadcrumbJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ブレッドクラム';
	@override String get description => 'ブレッドクラムは、ウェブサイトやウェブアプリケーションにおけるユーザーの位置を示す補助的なナビゲーションシステムです。';
	@override late final _TranslationsDocsComponentsBreadcrumbExamplesJa examples = _TranslationsDocsComponentsBreadcrumbExamplesJa._(_root);
	@override String get home => 'ホーム';
	@override String get components => 'コンポーネント';
}

// Path: docs.components.button
class _TranslationsDocsComponentsButtonJa extends TranslationsDocsComponentsButtonKo {
	_TranslationsDocsComponentsButtonJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ボタン';
	@override String get description => 'ボタンを使用すると、ユーザーが1回タップでアクションを実行し、選択できます。';
	@override late final _TranslationsDocsComponentsButtonExamplesJa examples = _TranslationsDocsComponentsButtonExamplesJa._(_root);
	@override String get primary => 'プライマリ';
	@override String get secondary => 'セカンダリ';
	@override String get outlined => 'アウトライン';
	@override String get ghost => 'ゴースト';
	@override String get destructive => '破壊的';
	@override String get link => 'リンク';
	@override String get outline => '外枠';
	@override String get text => 'テキスト';
	@override String get extra_small => 'エクストラスモール';
	@override String get small => 'スモール';
	@override String get normal => 'ノーマル';
	@override String get large => 'ラージ';
	@override String get extra_large => 'エクストララージ';
	@override String get save => '保存';
	@override String get cancel => 'キャンセル';
	@override String get close => '閉じる';
	@override String get submit => '提出';
	@override String get edit_profile => 'プロフィールを編集';
	@override String get save_changes => '変更を保存';
	@override String get undo => '元に戻す';
	@override String get compact => 'コンパクト';
	@override String get dense => '密';
	@override String get comfortable => '快適';
	@override String get icon => 'アイコン';
	@override String get icon_comfortable => 'アイコン快適';
	@override String get rectangle => '長方形';
	@override String get add => '追加';
	@override String get focused => 'フォーカス';
	@override String get hovered => 'ホバー';
	@override String get pressed => '押された';
	@override String get text_button => 'テキストボタン';
	@override String get custom_button => 'カスタムボタン';
}

// Path: docs.components.calendar
class _TranslationsDocsComponentsCalendarJa extends TranslationsDocsComponentsCalendarKo {
	_TranslationsDocsComponentsCalendarJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'カレンダー';
	@override String get description => '日付を選択して表示するカレンダーコンポーネントです。';
	@override late final _TranslationsDocsComponentsCalendarExamplesJa examples = _TranslationsDocsComponentsCalendarExamplesJa._(_root);
}

// Path: docs.components.card
class _TranslationsDocsComponentsCardJa extends TranslationsDocsComponentsCardKo {
	_TranslationsDocsComponentsCardJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'カード';
	@override String get description => '説明';
	@override late final _TranslationsDocsComponentsCardExamplesJa examples = _TranslationsDocsComponentsCardExamplesJa._(_root);
	@override String get create_project => 'プロジェクトを作成';
	@override String get deploy_description => 'ワンクリックで新しいプロジェクトをデプロイします';
	@override String get name => '名前';
	@override String get name_placeholder => 'プロジェクト名';
	@override String get description_placeholder => 'プロジェクトの説明';
	@override String get deploy => 'デプロイ';
}

// Path: docs.components.card_image
class _TranslationsDocsComponentsCardImageJa extends TranslationsDocsComponentsCardImageKo {
	_TranslationsDocsComponentsCardImageJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '画像カード';
	@override String get description => '画像を含むカードコンポーネントです。';
	@override late final _TranslationsDocsComponentsCardImageExamplesJa examples = _TranslationsDocsComponentsCardImageExamplesJa._(_root);
	@override String get card_image_title => 'カード画像';
	@override String get card_clicked => 'カード画像がクリックされました';
	@override String card_number({required Object n}) => 'カード番号 ${n}';
	@override String get lorem_ipsum => 'Lorem ipsum dolor sit amet';
}

// Path: docs.components.carousel
class _TranslationsDocsComponentsCarouselJa extends TranslationsDocsComponentsCarouselKo {
	_TranslationsDocsComponentsCarouselJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'カルーセル';
	@override String get description => '複数の項目をスライドで表示するコンポーネントです。';
	@override late final _TranslationsDocsComponentsCarouselExamplesJa examples = _TranslationsDocsComponentsCarouselExamplesJa._(_root);
}

// Path: docs.components.checkbox
class _TranslationsDocsComponentsCheckboxJa extends TranslationsDocsComponentsCheckboxKo {
	_TranslationsDocsComponentsCheckboxJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'チェックボックス';
	@override String get description => 'チェックボックスを使用すると、ユーザーがリストから1つ以上の項目を選択できます。';
	@override late final _TranslationsDocsComponentsCheckboxExamplesJa examples = _TranslationsDocsComponentsCheckboxExamplesJa._(_root);
	@override String get remember_me => '覚えておいて';
}

// Path: docs.components.chip
class _TranslationsDocsComponentsChipJa extends TranslationsDocsComponentsChipKo {
	_TranslationsDocsComponentsChipJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'チップ';
	@override String get description => 'チップは属性、選択肢、またはアクションを示す小さな要素です。';
	@override late final _TranslationsDocsComponentsChipExamplesJa examples = _TranslationsDocsComponentsChipExamplesJa._(_root);
	@override String get apple => 'リンゴ';
	@override String get banana => 'バナナ';
	@override String get cherry => 'さくらんぼ';
	@override String get durian => 'ドリアン';
	@override String get elderberry => 'エルダーベリー';
}

// Path: docs.components.chip_input
class _TranslationsDocsComponentsChipInputJa extends TranslationsDocsComponentsChipInputKo {
	_TranslationsDocsComponentsChipInputJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'チップ入力';
	@override String get description => '複数の値をチップ形式で入力できる入力フィールドです。';
	@override late final _TranslationsDocsComponentsChipInputExamplesJa examples = _TranslationsDocsComponentsChipInputExamplesJa._(_root);
}

// Path: docs.components.circular_progress
class _TranslationsDocsComponentsCircularProgressJa extends TranslationsDocsComponentsCircularProgressKo {
	_TranslationsDocsComponentsCircularProgressJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '円形の進捗';
	@override String get description => '円形の進捗インジケーターです。';
	@override late final _TranslationsDocsComponentsCircularProgressExamplesJa examples = _TranslationsDocsComponentsCircularProgressExamplesJa._(_root);
	@override String get increase_by_10 => '10増加';
	@override String get decrease_by_10 => '10減少';
}

// Path: docs.components.code_snippet
class _TranslationsDocsComponentsCodeSnippetJa extends TranslationsDocsComponentsCodeSnippetKo {
	_TranslationsDocsComponentsCodeSnippetJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'コードスニペット';
	@override String get description => 'コードを表示するコンポーネントです。';
	@override late final _TranslationsDocsComponentsCodeSnippetExamplesJa examples = _TranslationsDocsComponentsCodeSnippetExamplesJa._(_root);
}

// Path: docs.components.collapsible
class _TranslationsDocsComponentsCollapsibleJa extends TranslationsDocsComponentsCollapsibleKo {
	_TranslationsDocsComponentsCollapsibleJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '折りたたみ可能';
	@override String get description => '折りたたむまたは展開できるコンテンツコンテナです。';
	@override late final _TranslationsDocsComponentsCollapsibleExamplesJa examples = _TranslationsDocsComponentsCollapsibleExamplesJa._(_root);
	@override String get starred_repositories => '@coco-deが3つのリポジトリに星を付けました';
	@override String get collapse_all => 'すべて折りたたむ';
	@override String get expand_all => 'すべて展開する';
	@override String get expand_icon => 'アイコンを展開';
	@override String get use_path_branch => 'パスとブランチを使用';
	@override String get recursive_selection => '再帰的選択';
}

// Path: docs.components.color_picker
class _TranslationsDocsComponentsColorPickerJa extends TranslationsDocsComponentsColorPickerKo {
	_TranslationsDocsComponentsColorPickerJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'カラーセレクター';
	@override String get description => '色を選択できるコンポーネントです。';
	@override late final _TranslationsDocsComponentsColorPickerExamplesJa examples = _TranslationsDocsComponentsColorPickerExamplesJa._(_root);
	@override String get pick_color => '色を選択';
	@override String color_label({required Object color}) => '色: ${color}';
	@override String get select_color => '色を選択';
	@override String get open_color_picker_popover => 'カラーセレクターポップオーバーを開く';
	@override String get open_color_picker_dialog => 'カラーセレクターダイアログを開く';
}

// Path: docs.components.command
class _TranslationsDocsComponentsCommandJa extends TranslationsDocsComponentsCommandKo {
	_TranslationsDocsComponentsCommandJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'コマンド';
	@override String get description => '項目を検索できるコンポーネントです。';
	@override late final _TranslationsDocsComponentsCommandExamplesJa examples = _TranslationsDocsComponentsCommandExamplesJa._(_root);
}

// Path: docs.components.context_menu
class _TranslationsDocsComponentsContextMenuJa extends TranslationsDocsComponentsContextMenuKo {
	_TranslationsDocsComponentsContextMenuJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'コンテキストメニュー';
	@override String get description => '右クリックまたは長押しで表示されるメニューです。';
	@override late final _TranslationsDocsComponentsContextMenuExamplesJa examples = _TranslationsDocsComponentsContextMenuExamplesJa._(_root);
}

// Path: docs.components.date_picker
class _TranslationsDocsComponentsDatePickerJa extends TranslationsDocsComponentsDatePickerKo {
	_TranslationsDocsComponentsDatePickerJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '日付選択';
	@override String get description => '日付を選択できる入力フィールドです。';
	@override late final _TranslationsDocsComponentsDatePickerExamplesJa examples = _TranslationsDocsComponentsDatePickerExamplesJa._(_root);
	@override String get select_date => '日付を選択';
	@override String get select_date_range => '日付範囲を選択';
}

// Path: docs.components.dialog
class _TranslationsDocsComponentsDialogJa extends TranslationsDocsComponentsDialogKo {
	_TranslationsDocsComponentsDialogJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ダイアログ';
	@override String get description => 'ダイアログは、アプリの他の部分の上に表示されるモーダルウィンドウです。';
	@override late final _TranslationsDocsComponentsDialogExamplesJa examples = _TranslationsDocsComponentsDialogExamplesJa._(_root);
	@override String get edit_profile_title => 'プロフィールを編集';
	@override String get edit_profile_description => 'ここでプロフィールを変更してください。完了したら保存をクリックしてください。';
	@override String get name_label => '名前';
	@override String get username_label => 'ユーザー名';
	@override String get hello => 'こんにちは';
	@override String get material_dialog_content => 'マテリアルダイアログです';
	@override String get cupertino_dialog_content => 'クパチーノダイアログです';
	@override String get alert_title => 'アラートのタイトル';
	@override String get click_here => 'ここをクリックしてください';
	@override String get ok => '確認';
	@override String get open_material_dialog => 'マテリアルダイアログを開く';
	@override String get open_cupertino_dialog => 'クパチーノダイアログを開く';
	@override String get open_coui_dialog => 'COUIダイアログを開く';
}

// Path: docs.components.divider
class _TranslationsDocsComponentsDividerJa extends TranslationsDocsComponentsDividerKo {
	_TranslationsDocsComponentsDividerJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '区切り線';
	@override String get description => 'コンテンツを視覚的に区分けする線です。';
	@override late final _TranslationsDocsComponentsDividerExamplesJa examples = _TranslationsDocsComponentsDividerExamplesJa._(_root);
	@override String get item_1 => 'アイテム1';
	@override String get item_2 => 'アイテム2';
	@override String get item_3 => 'アイテム3';
	@override String get divider => '区切り線';
}

// Path: docs.components.dot_indicator
class _TranslationsDocsComponentsDotIndicatorJa extends TranslationsDocsComponentsDotIndicatorKo {
	_TranslationsDocsComponentsDotIndicatorJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ドットインジケーター';
	@override String get description => '現在位置を点で示すインジケーターです。';
	@override late final _TranslationsDocsComponentsDotIndicatorExamplesJa examples = _TranslationsDocsComponentsDotIndicatorExamplesJa._(_root);
}

// Path: docs.components.drawer
class _TranslationsDocsComponentsDrawerJa extends TranslationsDocsComponentsDrawerKo {
	_TranslationsDocsComponentsDrawerJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ドロワー';
	@override String get description => '画面の端からスライドするパネルです。';
	@override late final _TranslationsDocsComponentsDrawerExamplesJa examples = _TranslationsDocsComponentsDrawerExamplesJa._(_root);
	@override String get open_drawer => 'ドロワーを開く';
	@override String get close_drawer => 'ドロワーを閉じる';
	@override String get open_another_drawer => '別のドロワーを開く';
	@override String drawer_at({required Object count, required Object position}) => 'ドロワー ${count} 番目 at ${position}';
}

// Path: docs.components.dropdown_menu
class _TranslationsDocsComponentsDropdownMenuJa extends TranslationsDocsComponentsDropdownMenuKo {
	_TranslationsDocsComponentsDropdownMenuJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ドロップダウンメニュー';
	@override String get description => '選択可能なオプションのリストを表示するメニューです。';
	@override late final _TranslationsDocsComponentsDropdownMenuExamplesJa examples = _TranslationsDocsComponentsDropdownMenuExamplesJa._(_root);
}

// Path: docs.components.expandable_sidebar
class _TranslationsDocsComponentsExpandableSidebarJa extends TranslationsDocsComponentsExpandableSidebarKo {
	_TranslationsDocsComponentsExpandableSidebarJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '拡張可能なサイドバー';
	@override String get description => '展開及び折りたたみ可能なサイドバーです。';
	@override late final _TranslationsDocsComponentsExpandableSidebarExamplesJa examples = _TranslationsDocsComponentsExpandableSidebarExamplesJa._(_root);
}

// Path: docs.components.form
class _TranslationsDocsComponentsFormJa extends TranslationsDocsComponentsFormKo {
	_TranslationsDocsComponentsFormJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'フォーム';
	@override String get description => 'フォームのバリデーションを容易に作成できるヘルパーウィジェットです。';
	@override late final _TranslationsDocsComponentsFormExamplesJa examples = _TranslationsDocsComponentsFormExamplesJa._(_root);
	@override String get username_label => 'ユーザー名';
	@override String get username_hint => '公開される名前です';
	@override String get password_label => 'パスワード';
	@override String get confirm_password_label => 'パスワードの確認';
	@override String get passwords_do_not_match => 'パスワードが一致しません';
	@override String get agree_terms => '利用規約に同意します';
	@override String get must_agree_terms => '利用規約に同意する必要があります';
	@override String get form_values_title => 'フォーム値';
	@override String get register => '登録';
	@override String get username_already_taken => 'ユーザー名はすでに使用されています';
	@override String get email => 'メール';
	@override String username_display({required Object value}) => 'ユーザー名: ${value}';
	@override String password_display({required Object value}) => 'パスワード: ${value}';
	@override String confirm_password_display({required Object value}) => 'パスワードの確認: ${value}';
	@override String agree_display({required Object value}) => '同意: ${value}';
	@override String json_display({required Object value}) => 'JSON: ${value}';
	@override String submitted_value_display({required Object value}) => '提出された値: ${value}';
	@override String get login => 'ログイン';
	@override String get sign_up => 'サインアップ';
	@override String get dont_have_account => 'アカウントをお持ちでないですか？';
	@override String get already_have_account => 'すでにアカウントをお持ちですか？';
}

// Path: docs.components.formatted_input
class _TranslationsDocsComponentsFormattedInputJa extends TranslationsDocsComponentsFormattedInputKo {
	_TranslationsDocsComponentsFormattedInputJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'フォーマット入力';
	@override String get description => '特定の形式で入力されるテキストフィールドです。';
	@override late final _TranslationsDocsComponentsFormattedInputExamplesJa examples = _TranslationsDocsComponentsFormattedInputExamplesJa._(_root);
}

// Path: docs.components.hover_card
class _TranslationsDocsComponentsHoverCardJa extends TranslationsDocsComponentsHoverCardKo {
	_TranslationsDocsComponentsHoverCardJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ホバーカード';
	@override String get description => 'ホバー時に表示されるカードです。';
	@override late final _TranslationsDocsComponentsHoverCardExamplesJa examples = _TranslationsDocsComponentsHoverCardExamplesJa._(_root);
	@override String get flutter_handle => '@flutter';
	@override String get flutter_username => 'Flutter';
	@override String get flutter_description => 'Flutter SDKは、単一のコードベースからモバイル、ウェブ、デスクトップ用の美しいアプリを構築できるツールを提供します。';
}

// Path: docs.components.input
class _TranslationsDocsComponentsInputJa extends TranslationsDocsComponentsInputKo {
	_TranslationsDocsComponentsInputJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '入力';
	@override String get description => 'テキスト入力フィールドです。';
	@override late final _TranslationsDocsComponentsInputExamplesJa examples = _TranslationsDocsComponentsInputExamplesJa._(_root);
	@override String get enter_name => '名前を入力してください';
	@override String get enter_username => 'ユーザー名を入力してください';
	@override String get username_already_taken => 'ユーザー名はすでに使用されています';
	@override String get hello_world => 'こんにちは世界！';
	@override String get search_something => '何かを検索...';
	@override String get email => 'メールアドレス';
	@override String get password => 'パスワードを入力してください';
	@override String get username_hint => 'これはあなたのユーザー名用です';
}

// Path: docs.components.input_otp
class _TranslationsDocsComponentsInputOtpJa extends TranslationsDocsComponentsInputOtpKo {
	_TranslationsDocsComponentsInputOtpJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'OTP入力';
	@override String get description => '一回限りのパスワードを入力するフィールドです。';
	@override late final _TranslationsDocsComponentsInputOtpExamplesJa examples = _TranslationsDocsComponentsInputOtpExamplesJa._(_root);
}

// Path: docs.components.item_picker
class _TranslationsDocsComponentsItemPickerJa extends TranslationsDocsComponentsItemPickerKo {
	_TranslationsDocsComponentsItemPickerJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'アイテムピッカー';
	@override String get description => 'リストからアイテムを選択できるコンポーネントです。';
	@override late final _TranslationsDocsComponentsItemPickerExamplesJa examples = _TranslationsDocsComponentsItemPickerExamplesJa._(_root);
}

// Path: docs.components.keyboard_display
class _TranslationsDocsComponentsKeyboardDisplayJa extends TranslationsDocsComponentsKeyboardDisplayKo {
	_TranslationsDocsComponentsKeyboardDisplayJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'キーボード表示';
	@override String get description => 'キーボードショートカットを表示するコンポーネントです。';
	@override late final _TranslationsDocsComponentsKeyboardDisplayExamplesJa examples = _TranslationsDocsComponentsKeyboardDisplayExamplesJa._(_root);
}

// Path: docs.components.linear_progress
class _TranslationsDocsComponentsLinearProgressJa extends TranslationsDocsComponentsLinearProgressKo {
	_TranslationsDocsComponentsLinearProgressJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '線形進捗';
	@override String get description => '線形進捗インジケーターです。';
	@override late final _TranslationsDocsComponentsLinearProgressExamplesJa examples = _TranslationsDocsComponentsLinearProgressExamplesJa._(_root);
	@override String get increase => '増加';
	@override String get decrease => '減少';
}

// Path: docs.components.material
class _TranslationsDocsComponentsMaterialJa extends TranslationsDocsComponentsMaterialKo {
	_TranslationsDocsComponentsMaterialJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'Material/Cupertino';
	@override String get description => 'Flutterの基本MaterialおよびCupertinoウィジェットを使用する方法です。';
	@override late final _TranslationsDocsComponentsMaterialExamplesJa examples = _TranslationsDocsComponentsMaterialExamplesJa._(_root);
	@override String get my_material_app => '私のMaterialアプリ';
	@override String get my_cupertino_app => '私のCupertinoアプリ';
	@override String you_pushed_button({required Object count}) => 'ボタンを${count}回押しました';
	@override String get open_material_dialog => 'マテリアルダイアログを開く';
	@override String get open_cupertino_dialog => 'クパチーノダイアログを開く';
	@override String get open_coui_dialog => 'COUIダイアログを開く';
}

// Path: docs.components.menubar
class _TranslationsDocsComponentsMenubarJa extends TranslationsDocsComponentsMenubarKo {
	_TranslationsDocsComponentsMenubarJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'メニューバー';
	@override String get description => '水平メニューバーです。';
	@override late final _TranslationsDocsComponentsMenubarExamplesJa examples = _TranslationsDocsComponentsMenubarExamplesJa._(_root);
	@override String get file => 'ファイル';
	@override String get edit => '編集';
	@override String get new_tab => '新しいタブ';
	@override String get new_window => '新しいウィンドウ';
	@override String get new_incognito_window => '新しいシークレットウィンドウ';
	@override String get email_link => 'メールリンク';
	@override String get messages => 'メッセージ';
	@override String get notes => 'ノート';
	@override String get share => '共有';
	@override String get print => '印刷';
	@override String get save_and_exit => '保存後に終了';
	@override String get discard_and_exit => '破棄後に終了';
	@override String get exit => '終了';
	@override String get undo => '元に戻す';
	@override String get redo => 'やり直し';
}

// Path: docs.components.multiselect
class _TranslationsDocsComponentsMultiselectJa extends TranslationsDocsComponentsMultiselectKo {
	_TranslationsDocsComponentsMultiselectJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'マルチセレクト';
	@override String get description => '複数の項目を選択できるコンポーネントです。';
	@override late final _TranslationsDocsComponentsMultiselectExamplesJa examples = _TranslationsDocsComponentsMultiselectExamplesJa._(_root);
}

// Path: docs.components.navigation_bar
class _TranslationsDocsComponentsNavigationBarJa extends TranslationsDocsComponentsNavigationBarKo {
	_TranslationsDocsComponentsNavigationBarJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ナビゲーションバー';
	@override String get description => '下部ナビゲーションバーです。';
	@override late final _TranslationsDocsComponentsNavigationBarExamplesJa examples = _TranslationsDocsComponentsNavigationBarExamplesJa._(_root);
}

// Path: docs.components.navigation_menu
class _TranslationsDocsComponentsNavigationMenuJa extends TranslationsDocsComponentsNavigationMenuKo {
	_TranslationsDocsComponentsNavigationMenuJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ナビゲーションメニュー';
	@override String get description => 'ナビゲーションメニューコンポーネントです。';
	@override late final _TranslationsDocsComponentsNavigationMenuExamplesJa examples = _TranslationsDocsComponentsNavigationMenuExamplesJa._(_root);
}

// Path: docs.components.navigation_rail
class _TranslationsDocsComponentsNavigationRailJa extends TranslationsDocsComponentsNavigationRailKo {
	_TranslationsDocsComponentsNavigationRailJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ナビゲーションレール';
	@override String get description => '側面ナビゲーションレールです。';
	@override late final _TranslationsDocsComponentsNavigationRailExamplesJa examples = _TranslationsDocsComponentsNavigationRailExamplesJa._(_root);
}

// Path: docs.components.navigation_sidebar
class _TranslationsDocsComponentsNavigationSidebarJa extends TranslationsDocsComponentsNavigationSidebarKo {
	_TranslationsDocsComponentsNavigationSidebarJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ナビゲーションサイドバー';
	@override String get description => 'ナビゲーションサイドバーコンポーネントです。';
	@override late final _TranslationsDocsComponentsNavigationSidebarExamplesJa examples = _TranslationsDocsComponentsNavigationSidebarExamplesJa._(_root);
}

// Path: docs.components.number_input
class _TranslationsDocsComponentsNumberInputJa extends TranslationsDocsComponentsNumberInputKo {
	_TranslationsDocsComponentsNumberInputJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '数値入力';
	@override String get description => '数値を入力するフィールドです。';
	@override late final _TranslationsDocsComponentsNumberInputExamplesJa examples = _TranslationsDocsComponentsNumberInputExamplesJa._(_root);
	@override String value({required Object value}) => '値: ${value}';
}

// Path: docs.components.number_ticker
class _TranslationsDocsComponentsNumberTickerJa extends TranslationsDocsComponentsNumberTickerKo {
	_TranslationsDocsComponentsNumberTickerJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '数値ティッカー';
	@override String get description => '数値が変更されるときにアニメーションを表示します。';
	@override late final _TranslationsDocsComponentsNumberTickerExamplesJa examples = _TranslationsDocsComponentsNumberTickerExamplesJa._(_root);
}

// Path: docs.components.overflow_marquee
class _TranslationsDocsComponentsOverflowMarqueeJa extends TranslationsDocsComponentsOverflowMarqueeKo {
	_TranslationsDocsComponentsOverflowMarqueeJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'オーバーフローマーキー';
	@override String get description => 'テキストがオーバーフローするときに自動でスクロールします。';
	@override late final _TranslationsDocsComponentsOverflowMarqueeExamplesJa examples = _TranslationsDocsComponentsOverflowMarqueeExamplesJa._(_root);
}

// Path: docs.components.pagination
class _TranslationsDocsComponentsPaginationJa extends TranslationsDocsComponentsPaginationKo {
	_TranslationsDocsComponentsPaginationJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ページネーション';
	@override String get description => 'ページをナビゲートするコンポーネントです。';
	@override late final _TranslationsDocsComponentsPaginationExamplesJa examples = _TranslationsDocsComponentsPaginationExamplesJa._(_root);
}

// Path: docs.components.phone_input
class _TranslationsDocsComponentsPhoneInputJa extends TranslationsDocsComponentsPhoneInputKo {
	_TranslationsDocsComponentsPhoneInputJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '電話番号入力';
	@override String get description => '電話番号を入力するフィールドです。';
	@override late final _TranslationsDocsComponentsPhoneInputExamplesJa examples = _TranslationsDocsComponentsPhoneInputExamplesJa._(_root);
}

// Path: docs.components.popover
class _TranslationsDocsComponentsPopoverJa extends TranslationsDocsComponentsPopoverKo {
	_TranslationsDocsComponentsPopoverJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ポップオーバー';
	@override String get description => '要素の上に表示されるポップアップです。';
	@override late final _TranslationsDocsComponentsPopoverExamplesJa examples = _TranslationsDocsComponentsPopoverExamplesJa._(_root);
	@override String get dimensions => 'サイズ';
	@override String get set_dimensions => 'レイヤーのサイズを設定してください';
	@override String get width => '幅';
	@override String get max_width => '最大幅';
	@override String get height => '高さ';
	@override String get max_height => '最大高さ';
	@override String get open_popover => 'ポップオーバーを開く';
	@override String get submit => '提出';
}

// Path: docs.components.progress
class _TranslationsDocsComponentsProgressJa extends TranslationsDocsComponentsProgressKo {
	_TranslationsDocsComponentsProgressJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '進捗';
	@override String get description => '進行状況を表示します。';
	@override late final _TranslationsDocsComponentsProgressExamplesJa examples = _TranslationsDocsComponentsProgressExamplesJa._(_root);
}

// Path: docs.components.radio_card
class _TranslationsDocsComponentsRadioCardJa extends TranslationsDocsComponentsRadioCardKo {
	_TranslationsDocsComponentsRadioCardJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ラジオカード';
	@override String get description => 'カード形式のラジオボタンです。';
	@override late final _TranslationsDocsComponentsRadioCardExamplesJa examples = _TranslationsDocsComponentsRadioCardExamplesJa._(_root);
}

// Path: docs.components.radio_group
class _TranslationsDocsComponentsRadioGroupJa extends TranslationsDocsComponentsRadioGroupKo {
	_TranslationsDocsComponentsRadioGroupJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ラジオグループ';
	@override String get description => 'ラジオボタンのグループです。';
	@override late final _TranslationsDocsComponentsRadioGroupExamplesJa examples = _TranslationsDocsComponentsRadioGroupExamplesJa._(_root);
	@override String get option_1 => 'オプション1';
	@override String get option_2 => 'オプション2';
	@override String get option_3 => 'オプション3';
	@override String get selected => '選択中';
}

// Path: docs.components.refresh_trigger
class _TranslationsDocsComponentsRefreshTriggerJa extends TranslationsDocsComponentsRefreshTriggerKo {
	_TranslationsDocsComponentsRefreshTriggerJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'リフレッシュトリガー';
	@override String get description => '引っ張ってリフレッシュ機能を提供します。';
	@override late final _TranslationsDocsComponentsRefreshTriggerExamplesJa examples = _TranslationsDocsComponentsRefreshTriggerExamplesJa._(_root);
	@override String get pull_me => '引っ張ってください';
	@override String get refresh => 'リフレッシュ';
}

// Path: docs.components.repeated_animation_builder
class _TranslationsDocsComponentsRepeatedAnimationBuilderJa extends TranslationsDocsComponentsRepeatedAnimationBuilderKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'リピートアニメーションビルダー';
	@override String get description => 'アニメーションを繰り返すビルダーです。';
	@override late final _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesJa examples = _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesJa._(_root);
}

// Path: docs.components.resizable
class _TranslationsDocsComponentsResizableJa extends TranslationsDocsComponentsResizableKo {
	_TranslationsDocsComponentsResizableJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'リサイズ可能';
	@override String get description => 'サイズを変更できるコンテナです。';
	@override late final _TranslationsDocsComponentsResizableExamplesJa examples = _TranslationsDocsComponentsResizableExamplesJa._(_root);
}

// Path: docs.components.scaffold
class _TranslationsDocsComponentsScaffoldJa extends TranslationsDocsComponentsScaffoldKo {
	_TranslationsDocsComponentsScaffoldJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'スキャフォールド';
	@override String get description => 'スキャフォールドはページの最上位コンテナです。';
	@override late final _TranslationsDocsComponentsScaffoldExamplesJa examples = _TranslationsDocsComponentsScaffoldExamplesJa._(_root);
}

// Path: docs.components.select
class _TranslationsDocsComponentsSelectJa extends TranslationsDocsComponentsSelectKo {
	_TranslationsDocsComponentsSelectJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '選択';
	@override String get description => 'オプションリストから項目を選択できます。';
	@override late final _TranslationsDocsComponentsSelectExamplesJa examples = _TranslationsDocsComponentsSelectExamplesJa._(_root);
	@override String get placeholder => '果物を選択してください';
	@override String get search_fruit => '果物を検索';
	@override String get no_fruit_found => '果物が見つかりません';
	@override String get apple => 'リンゴ';
	@override String get banana => 'バナナ';
	@override String get cherry => 'サクランボ';
	@override String get lemon => 'レモン';
	@override String get tomato => 'トマト';
	@override String get red_apple => '赤いリンゴ';
	@override String get green_apple => '緑のリンゴ';
	@override String get yellow_banana => '黄色いバナナ';
	@override String get brown_banana => '茶色のバナナ';
	@override String get yellow_lemon => '黄色いレモン';
	@override String get green_lemon => '緑のレモン';
	@override String get red => '赤';
	@override String get green => '緑';
	@override String get yellow => '黄';
	@override String get brown => '茶色';
}

// Path: docs.components.sheet
class _TranslationsDocsComponentsSheetJa extends TranslationsDocsComponentsSheetKo {
	_TranslationsDocsComponentsSheetJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'シート';
	@override String get description => '下から上がってくるシートです。';
	@override late final _TranslationsDocsComponentsSheetExamplesJa examples = _TranslationsDocsComponentsSheetExamplesJa._(_root);
}

// Path: docs.components.skeleton
class _TranslationsDocsComponentsSkeletonJa extends TranslationsDocsComponentsSkeletonKo {
	_TranslationsDocsComponentsSkeletonJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'スケルトン';
	@override String get description => '読み込み中に表示されるスケルトン画面です。';
	@override late final _TranslationsDocsComponentsSkeletonExamplesJa examples = _TranslationsDocsComponentsSkeletonExamplesJa._(_root);
}

// Path: docs.components.slider
class _TranslationsDocsComponentsSliderJa extends TranslationsDocsComponentsSliderKo {
	_TranslationsDocsComponentsSliderJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'スライダー';
	@override String get description => '値をスライドして選択できます。';
	@override late final _TranslationsDocsComponentsSliderExamplesJa examples = _TranslationsDocsComponentsSliderExamplesJa._(_root);
	@override String value_single({required Object value}) => '値: ${value}';
	@override String value_range({required Object start, required Object end}) => '値: ${start} - ${end}';
}

// Path: docs.components.sortable
class _TranslationsDocsComponentsSortableJa extends TranslationsDocsComponentsSortableKo {
	_TranslationsDocsComponentsSortableJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ソート可能';
	@override String get description => 'ドラッグして項目をソートできます。';
	@override late final _TranslationsDocsComponentsSortableExamplesJa examples = _TranslationsDocsComponentsSortableExamplesJa._(_root);
}

// Path: docs.components.star_rating
class _TranslationsDocsComponentsStarRatingJa extends TranslationsDocsComponentsStarRatingKo {
	_TranslationsDocsComponentsStarRatingJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '星評価';
	@override String get description => '星評価を選択できます。';
	@override late final _TranslationsDocsComponentsStarRatingExamplesJa examples = _TranslationsDocsComponentsStarRatingExamplesJa._(_root);
}

// Path: docs.components.stepper
class _TranslationsDocsComponentsStepperJa extends TranslationsDocsComponentsStepperKo {
	_TranslationsDocsComponentsStepperJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ステッパー';
	@override String get description => '段階的プロセスを表示します。';
	@override late final _TranslationsDocsComponentsStepperExamplesJa examples = _TranslationsDocsComponentsStepperExamplesJa._(_root);
	@override String get step_1 => 'ステップ1';
	@override String get step_2 => 'ステップ2';
	@override String get step_3 => 'ステップ3';
	@override String step_n({required Object n}) => 'ステップ ${n}';
	@override String get optional_step => 'オプションのステップ';
	@override String get horizontal => '水平';
	@override String get vertical => '垂直';
	@override String get toggle_error => 'エラーを切り替え';
	@override String get circle => '円形';
	@override String get circle_alt => '円形代替';
	@override String get line => '線形';
	@override String get small => '小';
	@override String get medium => '中';
	@override String get large => '大';
}

// Path: docs.components.steps
class _TranslationsDocsComponentsStepsJa extends TranslationsDocsComponentsStepsKo {
	_TranslationsDocsComponentsStepsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ステップ';
	@override String get description => '進行状況をステップで表示します。';
	@override late final _TranslationsDocsComponentsStepsExamplesJa examples = _TranslationsDocsComponentsStepsExamplesJa._(_root);
}

// Path: docs.components.swiper
class _TranslationsDocsComponentsSwiperJa extends TranslationsDocsComponentsSwiperKo {
	_TranslationsDocsComponentsSwiperJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'スワイパー';
	@override String get description => 'スワイプ可能なコンポーネントです。';
	@override late final _TranslationsDocsComponentsSwiperExamplesJa examples = _TranslationsDocsComponentsSwiperExamplesJa._(_root);
}

// Path: docs.components.k_switch
class _TranslationsDocsComponentsKSwitchJa extends TranslationsDocsComponentsKSwitchKo {
	_TranslationsDocsComponentsKSwitchJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'スイッチ';
	@override String get description => 'オン/オフのスイッチです。';
	@override late final _TranslationsDocsComponentsKSwitchExamplesJa examples = _TranslationsDocsComponentsKSwitchExamplesJa._(_root);
}

// Path: docs.components.switcher
class _TranslationsDocsComponentsSwitcherJa extends TranslationsDocsComponentsSwitcherKo {
	_TranslationsDocsComponentsSwitcherJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'スイッチャー';
	@override String get description => '複数のビュー間で切り替え可能です。';
	@override late final _TranslationsDocsComponentsSwitcherExamplesJa examples = _TranslationsDocsComponentsSwitcherExamplesJa._(_root);
	@override String get switch_direction => '方向切り替え';
	@override String get next_item => '次の項目';
}

// Path: docs.components.tab_list
class _TranslationsDocsComponentsTabListJa extends TranslationsDocsComponentsTabListKo {
	_TranslationsDocsComponentsTabListJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'タブリスト';
	@override String get description => 'タブリストコンポーネントです。';
	@override late final _TranslationsDocsComponentsTabListExamplesJa examples = _TranslationsDocsComponentsTabListExamplesJa._(_root);
}

// Path: docs.components.tab_pane
class _TranslationsDocsComponentsTabPaneJa extends TranslationsDocsComponentsTabPaneKo {
	_TranslationsDocsComponentsTabPaneJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'タブパネル';
	@override String get description => 'タブパネルコンポーネントです。';
	@override late final _TranslationsDocsComponentsTabPaneExamplesJa examples = _TranslationsDocsComponentsTabPaneExamplesJa._(_root);
}

// Path: docs.components.table
class _TranslationsDocsComponentsTableJa extends TranslationsDocsComponentsTableKo {
	_TranslationsDocsComponentsTableJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'テーブル';
	@override String get description => 'データをテーブル形式で表示します。';
	@override late final _TranslationsDocsComponentsTableExamplesJa examples = _TranslationsDocsComponentsTableExamplesJa._(_root);
	@override String get invoice => '請求書';
	@override String get status => '状態';
	@override String get method => '方法';
	@override String get amount => '金額';
	@override String get total => '合計';
	@override String get paid => '支払い済み';
	@override String get pending => '保留中';
	@override String get unpaid => '未払い';
	@override String get credit_card => 'クレジットカード';
	@override String get paypal => 'PayPal';
	@override String get bank_transfer => '銀行振込';
}

// Path: docs.components.tabs
class _TranslationsDocsComponentsTabsJa extends TranslationsDocsComponentsTabsKo {
	_TranslationsDocsComponentsTabsJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'タブ';
	@override String get description => 'タブを使用してコンテンツを構成します。';
	@override late final _TranslationsDocsComponentsTabsExamplesJa examples = _TranslationsDocsComponentsTabsExamplesJa._(_root);
	@override String get tab_1 => 'タブ1';
	@override String get tab_2 => 'タブ2';
	@override String get tab_3 => 'タブ3';
	@override String tab_n({required Object n}) => 'タブ ${n}';
}

// Path: docs.components.text_area
class _TranslationsDocsComponentsTextAreaJa extends TranslationsDocsComponentsTextAreaKo {
	_TranslationsDocsComponentsTextAreaJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'テキストエリア';
	@override String get description => '複数行のテキストを入力できます。';
	@override late final _TranslationsDocsComponentsTextAreaExamplesJa examples = _TranslationsDocsComponentsTextAreaExamplesJa._(_root);
	@override String get hello_world => 'こんにちは、世界！';
}

// Path: docs.components.time_picker
class _TranslationsDocsComponentsTimePickerJa extends TranslationsDocsComponentsTimePickerKo {
	_TranslationsDocsComponentsTimePickerJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => '時間選択';
	@override String get description => '時間を選択できます。';
	@override late final _TranslationsDocsComponentsTimePickerExamplesJa examples = _TranslationsDocsComponentsTimePickerExamplesJa._(_root);
	@override String get select_time => '時間を選択';
}

// Path: docs.components.timeline
class _TranslationsDocsComponentsTimelineJa extends TranslationsDocsComponentsTimelineKo {
	_TranslationsDocsComponentsTimelineJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'タイムライン';
	@override String get description => 'イベントをタイムラインで表示します。';
	@override late final _TranslationsDocsComponentsTimelineExamplesJa examples = _TranslationsDocsComponentsTimelineExamplesJa._(_root);
}

// Path: docs.components.timeline_animation
class _TranslationsDocsComponentsTimelineAnimationJa extends TranslationsDocsComponentsTimelineAnimationKo {
	_TranslationsDocsComponentsTimelineAnimationJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'タイムラインアニメーション';
	@override String get description => 'タイムラインベースのアニメーションです。';
	@override late final _TranslationsDocsComponentsTimelineAnimationExamplesJa examples = _TranslationsDocsComponentsTimelineAnimationExamplesJa._(_root);
}

// Path: docs.components.toast
class _TranslationsDocsComponentsToastJa extends TranslationsDocsComponentsToastKo {
	_TranslationsDocsComponentsToastJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'トースト';
	@override String get description => '短いメッセージを表示する通知です。';
	@override late final _TranslationsDocsComponentsToastExamplesJa examples = _TranslationsDocsComponentsToastExamplesJa._(_root);
	@override String get event_created => 'イベントが作成されました';
	@override String get event_date => '2024年7月7日(日)午後12:00';
	@override String get show_bottom_left => '左下トーストを表示';
	@override String get show_bottom_right => '右下トーストを表示';
	@override String get show_top_left => '左上トーストを表示';
	@override String get show_top_right => '右上トーストを表示';
	@override String get show_bottom_center => '下中央トーストを表示';
	@override String get show_top_center => '上中央トーストを表示';
}

// Path: docs.components.toggle
class _TranslationsDocsComponentsToggleJa extends TranslationsDocsComponentsToggleKo {
	_TranslationsDocsComponentsToggleJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'トグル';
	@override String get description => 'オプション間でトグルできます。';
	@override late final _TranslationsDocsComponentsToggleExamplesJa examples = _TranslationsDocsComponentsToggleExamplesJa._(_root);
	@override String get toggle => 'トグル';
}

// Path: docs.components.tooltip
class _TranslationsDocsComponentsTooltipJa extends TranslationsDocsComponentsTooltipKo {
	_TranslationsDocsComponentsTooltipJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ツールチップ';
	@override String get description => '要素に関する追加情報を表示します。';
	@override late final _TranslationsDocsComponentsTooltipExamplesJa examples = _TranslationsDocsComponentsTooltipExamplesJa._(_root);
	@override String get this_is_tooltip => 'これはツールチップです。';
	@override String get hover_over_me => 'マウスを上に乗せてください';
}

// Path: docs.components.tracker
class _TranslationsDocsComponentsTrackerJa extends TranslationsDocsComponentsTrackerKo {
	_TranslationsDocsComponentsTrackerJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'トラッカー';
	@override String get description => '進行状況を追跡します。';
	@override late final _TranslationsDocsComponentsTrackerExamplesJa examples = _TranslationsDocsComponentsTrackerExamplesJa._(_root);
	@override String get fine => '良好';
	@override String get warning => '警告';
	@override String get critical => '危険';
	@override String get unknown => '不明';
	@override String get tracker_fine => 'トラッカー良好';
	@override String get tracker_warning => 'トラッカー警告';
	@override String get tracker_critical => 'トラッカー危険';
	@override String get tracker_unknown => 'トラッカー不明';
}

// Path: docs.components.tree
class _TranslationsDocsComponentsTreeJa extends TranslationsDocsComponentsTreeKo {
	_TranslationsDocsComponentsTreeJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ツリー';
	@override String get description => '階層データをツリー形式で表示します。';
	@override late final _TranslationsDocsComponentsTreeExamplesJa examples = _TranslationsDocsComponentsTreeExamplesJa._(_root);
}

// Path: docs.components.window
class _TranslationsDocsComponentsWindowJa extends TranslationsDocsComponentsWindowKo {
	_TranslationsDocsComponentsWindowJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get display_name => 'ウィンドウ';
	@override String get description => 'デスクトップスタイルのウィンドウです。';
	@override late final _TranslationsDocsComponentsWindowExamplesJa examples = _TranslationsDocsComponentsWindowExamplesJa._(_root);
	@override String get window_1 => 'ウィンドウ1';
	@override String get window_2 => 'ウィンドウ2';
	@override String get desktop => 'デスクトップ';
	@override String get add_window => 'ウィンドウを追加';
}

// Path: docs.pages.introduction.features_list
class _TranslationsDocsPagesIntroductionFeaturesListJa extends TranslationsDocsPagesIntroductionFeaturesListKo {
	_TranslationsDocsPagesIntroductionFeaturesListJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get components_count => '84のコンポーネントがあり、さらに増加中！';
	@override String get material_cupertino => 'MaterialおよびCupertinoウィジェットをサポートし、テーマは現在coui_flutterテーマに合わせて調整されています。';
	@override String get premade_themes => 'Coui/UIのプレミadeテーマ。';
	@override String get platform_support => 'モバイル、ウェブ、デスクトッププラットフォームのサポート。';
	@override String get middle_drag => '中間ドラッグスクロールをサポート。';
	@override String get typography_extensions => 'タイポグラフィ用のさまざまなウィジェット拡張。';
	@override String get webassembly => 'パフォーマンス向上のためのWebAssemblyサポート。';
}

// Path: docs.components.accordion.examples
class _TranslationsDocsComponentsAccordionExamplesJa extends TranslationsDocsComponentsAccordionExamplesKo {
	_TranslationsDocsComponentsAccordionExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'アコーディオンの例';
}

// Path: docs.components.alert.examples
class _TranslationsDocsComponentsAlertExamplesJa extends TranslationsDocsComponentsAlertExamplesKo {
	_TranslationsDocsComponentsAlertExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'アラートの例';
	@override String get destructive => '危険アラートの例';
}

// Path: docs.components.alert_dialog.examples
class _TranslationsDocsComponentsAlertDialogExamplesJa extends TranslationsDocsComponentsAlertDialogExamplesKo {
	_TranslationsDocsComponentsAlertDialogExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'アラートダイアログの例';
}

// Path: docs.components.animated_value_builder.examples
class _TranslationsDocsComponentsAnimatedValueBuilderExamplesJa extends TranslationsDocsComponentsAnimatedValueBuilderExamplesKo {
	_TranslationsDocsComponentsAnimatedValueBuilderExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'アニメーション値ビルダーの例';
}

// Path: docs.components.app_bar.examples
class _TranslationsDocsComponentsAppBarExamplesJa extends TranslationsDocsComponentsAppBarExamplesKo {
	_TranslationsDocsComponentsAppBarExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'アプリバーの例';
}

// Path: docs.components.autocomplete.examples
class _TranslationsDocsComponentsAutocompleteExamplesJa extends TranslationsDocsComponentsAutocompleteExamplesKo {
	_TranslationsDocsComponentsAutocompleteExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'オートコンプリートの例';
}

// Path: docs.components.avatar.examples
class _TranslationsDocsComponentsAvatarExamplesJa extends TranslationsDocsComponentsAvatarExamplesKo {
	_TranslationsDocsComponentsAvatarExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'アバターの例';
}

// Path: docs.components.avatar_group.examples
class _TranslationsDocsComponentsAvatarGroupExamplesJa extends TranslationsDocsComponentsAvatarGroupExamplesKo {
	_TranslationsDocsComponentsAvatarGroupExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'アバターグループの例';
}

// Path: docs.components.badge.examples
class _TranslationsDocsComponentsBadgeExamplesJa extends TranslationsDocsComponentsBadgeExamplesKo {
	_TranslationsDocsComponentsBadgeExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'バッジの例';
}

// Path: docs.components.breadcrumb.examples
class _TranslationsDocsComponentsBreadcrumbExamplesJa extends TranslationsDocsComponentsBreadcrumbExamplesKo {
	_TranslationsDocsComponentsBreadcrumbExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ブレッドクラムの例';
}

// Path: docs.components.button.examples
class _TranslationsDocsComponentsButtonExamplesJa extends TranslationsDocsComponentsButtonExamplesKo {
	_TranslationsDocsComponentsButtonExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get primary => 'プライマリボタンの例';
	@override String get secondary => 'セカンダリボタンの例';
	@override String get outline => 'アウトラインボタンの例';
	@override String get ghost => 'ゴーストボタンの例';
	@override String get destructive => '危険ボタンの例';
	@override String get link => 'リンクボタンの例';
	@override String get text => 'テキストボタンの例';
	@override String get disabled => '無効ボタンの例';
	@override String get icon => 'アイコンボタンの例';
	@override String get icon_with_label => 'ラベル付きアイコンボタンの例';
	@override String get size => 'ボタンサイズの例';
	@override String get density => 'ボタン密度の例';
	@override String get shape => 'ボタン形状の例';
	@override String get group => 'ボタングループの例';
	@override String get stated => '状態ボタンの例';
	@override String get card => 'カードボタンの例';
	@override String get custom => 'カスタムボタンの例';
}

// Path: docs.components.calendar.examples
class _TranslationsDocsComponentsCalendarExamplesJa extends TranslationsDocsComponentsCalendarExamplesKo {
	_TranslationsDocsComponentsCalendarExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'カレンダーの例';
}

// Path: docs.components.card.examples
class _TranslationsDocsComponentsCardExamplesJa extends TranslationsDocsComponentsCardExamplesKo {
	_TranslationsDocsComponentsCardExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'カードの例';
}

// Path: docs.components.card_image.examples
class _TranslationsDocsComponentsCardImageExamplesJa extends TranslationsDocsComponentsCardImageExamplesKo {
	_TranslationsDocsComponentsCardImageExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '画像カードの例';
}

// Path: docs.components.carousel.examples
class _TranslationsDocsComponentsCarouselExamplesJa extends TranslationsDocsComponentsCarouselExamplesKo {
	_TranslationsDocsComponentsCarouselExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'カルーセルの例';
}

// Path: docs.components.checkbox.examples
class _TranslationsDocsComponentsCheckboxExamplesJa extends TranslationsDocsComponentsCheckboxExamplesKo {
	_TranslationsDocsComponentsCheckboxExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'チェックボックスの例';
}

// Path: docs.components.chip.examples
class _TranslationsDocsComponentsChipExamplesJa extends TranslationsDocsComponentsChipExamplesKo {
	_TranslationsDocsComponentsChipExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'チップの例';
}

// Path: docs.components.chip_input.examples
class _TranslationsDocsComponentsChipInputExamplesJa extends TranslationsDocsComponentsChipInputExamplesKo {
	_TranslationsDocsComponentsChipInputExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'チップ入力の例';
}

// Path: docs.components.circular_progress.examples
class _TranslationsDocsComponentsCircularProgressExamplesJa extends TranslationsDocsComponentsCircularProgressExamplesKo {
	_TranslationsDocsComponentsCircularProgressExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '円形の進捗の例';
}

// Path: docs.components.code_snippet.examples
class _TranslationsDocsComponentsCodeSnippetExamplesJa extends TranslationsDocsComponentsCodeSnippetExamplesKo {
	_TranslationsDocsComponentsCodeSnippetExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'コードスニペットの例';
}

// Path: docs.components.collapsible.examples
class _TranslationsDocsComponentsCollapsibleExamplesJa extends TranslationsDocsComponentsCollapsibleExamplesKo {
	_TranslationsDocsComponentsCollapsibleExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '折りたたみ可能の例';
}

// Path: docs.components.color_picker.examples
class _TranslationsDocsComponentsColorPickerExamplesJa extends TranslationsDocsComponentsColorPickerExamplesKo {
	_TranslationsDocsComponentsColorPickerExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'カラーセレクターの例';
}

// Path: docs.components.command.examples
class _TranslationsDocsComponentsCommandExamplesJa extends TranslationsDocsComponentsCommandExamplesKo {
	_TranslationsDocsComponentsCommandExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'コマンドの例';
}

// Path: docs.components.context_menu.examples
class _TranslationsDocsComponentsContextMenuExamplesJa extends TranslationsDocsComponentsContextMenuExamplesKo {
	_TranslationsDocsComponentsContextMenuExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'コンテキストメニューの例';
}

// Path: docs.components.date_picker.examples
class _TranslationsDocsComponentsDatePickerExamplesJa extends TranslationsDocsComponentsDatePickerExamplesKo {
	_TranslationsDocsComponentsDatePickerExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '日付選択の例';
}

// Path: docs.components.dialog.examples
class _TranslationsDocsComponentsDialogExamplesJa extends TranslationsDocsComponentsDialogExamplesKo {
	_TranslationsDocsComponentsDialogExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ダイアログの例';
}

// Path: docs.components.divider.examples
class _TranslationsDocsComponentsDividerExamplesJa extends TranslationsDocsComponentsDividerExamplesKo {
	_TranslationsDocsComponentsDividerExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '区切り線の例';
}

// Path: docs.components.dot_indicator.examples
class _TranslationsDocsComponentsDotIndicatorExamplesJa extends TranslationsDocsComponentsDotIndicatorExamplesKo {
	_TranslationsDocsComponentsDotIndicatorExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ドットインジケーターの例';
}

// Path: docs.components.drawer.examples
class _TranslationsDocsComponentsDrawerExamplesJa extends TranslationsDocsComponentsDrawerExamplesKo {
	_TranslationsDocsComponentsDrawerExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ドロワーの例';
}

// Path: docs.components.dropdown_menu.examples
class _TranslationsDocsComponentsDropdownMenuExamplesJa extends TranslationsDocsComponentsDropdownMenuExamplesKo {
	_TranslationsDocsComponentsDropdownMenuExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ドロップダウンメニューの例';
}

// Path: docs.components.expandable_sidebar.examples
class _TranslationsDocsComponentsExpandableSidebarExamplesJa extends TranslationsDocsComponentsExpandableSidebarExamplesKo {
	_TranslationsDocsComponentsExpandableSidebarExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '拡張可能なサイドバーの例';
}

// Path: docs.components.form.examples
class _TranslationsDocsComponentsFormExamplesJa extends TranslationsDocsComponentsFormExamplesKo {
	_TranslationsDocsComponentsFormExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get table_layout => 'フォームの例 (テーブルレイアウト)';
	@override String get column_layout => 'フォームの例 (カラムレイアウト)';
	@override String get validation_mode => 'バリデーションモードの例';
}

// Path: docs.components.formatted_input.examples
class _TranslationsDocsComponentsFormattedInputExamplesJa extends TranslationsDocsComponentsFormattedInputExamplesKo {
	_TranslationsDocsComponentsFormattedInputExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'フォーマット入力の例';
}

// Path: docs.components.hover_card.examples
class _TranslationsDocsComponentsHoverCardExamplesJa extends TranslationsDocsComponentsHoverCardExamplesKo {
	_TranslationsDocsComponentsHoverCardExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ホバーカードの例';
}

// Path: docs.components.input.examples
class _TranslationsDocsComponentsInputExamplesJa extends TranslationsDocsComponentsInputExamplesKo {
	_TranslationsDocsComponentsInputExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '入力の例';
}

// Path: docs.components.input_otp.examples
class _TranslationsDocsComponentsInputOtpExamplesJa extends TranslationsDocsComponentsInputOtpExamplesKo {
	_TranslationsDocsComponentsInputOtpExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'OTP入力の例';
}

// Path: docs.components.item_picker.examples
class _TranslationsDocsComponentsItemPickerExamplesJa extends TranslationsDocsComponentsItemPickerExamplesKo {
	_TranslationsDocsComponentsItemPickerExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'アイテムピッカーの例';
}

// Path: docs.components.keyboard_display.examples
class _TranslationsDocsComponentsKeyboardDisplayExamplesJa extends TranslationsDocsComponentsKeyboardDisplayExamplesKo {
	_TranslationsDocsComponentsKeyboardDisplayExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'キーボード表示の例';
}

// Path: docs.components.linear_progress.examples
class _TranslationsDocsComponentsLinearProgressExamplesJa extends TranslationsDocsComponentsLinearProgressExamplesKo {
	_TranslationsDocsComponentsLinearProgressExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '線形進捗の例';
}

// Path: docs.components.material.examples
class _TranslationsDocsComponentsMaterialExamplesJa extends TranslationsDocsComponentsMaterialExamplesKo {
	_TranslationsDocsComponentsMaterialExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'Material/Cupertinoの例';
}

// Path: docs.components.menubar.examples
class _TranslationsDocsComponentsMenubarExamplesJa extends TranslationsDocsComponentsMenubarExamplesKo {
	_TranslationsDocsComponentsMenubarExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'メニューバーの例';
}

// Path: docs.components.multiselect.examples
class _TranslationsDocsComponentsMultiselectExamplesJa extends TranslationsDocsComponentsMultiselectExamplesKo {
	_TranslationsDocsComponentsMultiselectExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'マルチセレクトの例';
}

// Path: docs.components.navigation_bar.examples
class _TranslationsDocsComponentsNavigationBarExamplesJa extends TranslationsDocsComponentsNavigationBarExamplesKo {
	_TranslationsDocsComponentsNavigationBarExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ナビゲーションバーの例';
}

// Path: docs.components.navigation_menu.examples
class _TranslationsDocsComponentsNavigationMenuExamplesJa extends TranslationsDocsComponentsNavigationMenuExamplesKo {
	_TranslationsDocsComponentsNavigationMenuExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ナビゲーションメニューの例';
}

// Path: docs.components.navigation_rail.examples
class _TranslationsDocsComponentsNavigationRailExamplesJa extends TranslationsDocsComponentsNavigationRailExamplesKo {
	_TranslationsDocsComponentsNavigationRailExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ナビゲーションレールの例';
}

// Path: docs.components.navigation_sidebar.examples
class _TranslationsDocsComponentsNavigationSidebarExamplesJa extends TranslationsDocsComponentsNavigationSidebarExamplesKo {
	_TranslationsDocsComponentsNavigationSidebarExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ナビゲーションサイドバーの例';
}

// Path: docs.components.number_input.examples
class _TranslationsDocsComponentsNumberInputExamplesJa extends TranslationsDocsComponentsNumberInputExamplesKo {
	_TranslationsDocsComponentsNumberInputExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '数値入力の例';
}

// Path: docs.components.number_ticker.examples
class _TranslationsDocsComponentsNumberTickerExamplesJa extends TranslationsDocsComponentsNumberTickerExamplesKo {
	_TranslationsDocsComponentsNumberTickerExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '数値ティッカーの例';
}

// Path: docs.components.overflow_marquee.examples
class _TranslationsDocsComponentsOverflowMarqueeExamplesJa extends TranslationsDocsComponentsOverflowMarqueeExamplesKo {
	_TranslationsDocsComponentsOverflowMarqueeExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'オーバーフローマーキーの例';
}

// Path: docs.components.pagination.examples
class _TranslationsDocsComponentsPaginationExamplesJa extends TranslationsDocsComponentsPaginationExamplesKo {
	_TranslationsDocsComponentsPaginationExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ページネーションの例';
}

// Path: docs.components.phone_input.examples
class _TranslationsDocsComponentsPhoneInputExamplesJa extends TranslationsDocsComponentsPhoneInputExamplesKo {
	_TranslationsDocsComponentsPhoneInputExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '電話番号入力の例';
}

// Path: docs.components.popover.examples
class _TranslationsDocsComponentsPopoverExamplesJa extends TranslationsDocsComponentsPopoverExamplesKo {
	_TranslationsDocsComponentsPopoverExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ポップオーバーの例';
}

// Path: docs.components.progress.examples
class _TranslationsDocsComponentsProgressExamplesJa extends TranslationsDocsComponentsProgressExamplesKo {
	_TranslationsDocsComponentsProgressExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '進捗の例';
}

// Path: docs.components.radio_card.examples
class _TranslationsDocsComponentsRadioCardExamplesJa extends TranslationsDocsComponentsRadioCardExamplesKo {
	_TranslationsDocsComponentsRadioCardExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ラジオカードの例';
}

// Path: docs.components.radio_group.examples
class _TranslationsDocsComponentsRadioGroupExamplesJa extends TranslationsDocsComponentsRadioGroupExamplesKo {
	_TranslationsDocsComponentsRadioGroupExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ラジオグループの例';
}

// Path: docs.components.refresh_trigger.examples
class _TranslationsDocsComponentsRefreshTriggerExamplesJa extends TranslationsDocsComponentsRefreshTriggerExamplesKo {
	_TranslationsDocsComponentsRefreshTriggerExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'リフレッシュトリガーの例';
}

// Path: docs.components.repeated_animation_builder.examples
class _TranslationsDocsComponentsRepeatedAnimationBuilderExamplesJa extends TranslationsDocsComponentsRepeatedAnimationBuilderExamplesKo {
	_TranslationsDocsComponentsRepeatedAnimationBuilderExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'リピートアニメーションビルダーの例';
}

// Path: docs.components.resizable.examples
class _TranslationsDocsComponentsResizableExamplesJa extends TranslationsDocsComponentsResizableExamplesKo {
	_TranslationsDocsComponentsResizableExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'リサイズ可能の例';
}

// Path: docs.components.scaffold.examples
class _TranslationsDocsComponentsScaffoldExamplesJa extends TranslationsDocsComponentsScaffoldExamplesKo {
	_TranslationsDocsComponentsScaffoldExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'スキャフォールドの例';
}

// Path: docs.components.select.examples
class _TranslationsDocsComponentsSelectExamplesJa extends TranslationsDocsComponentsSelectExamplesKo {
	_TranslationsDocsComponentsSelectExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '選択の例';
}

// Path: docs.components.sheet.examples
class _TranslationsDocsComponentsSheetExamplesJa extends TranslationsDocsComponentsSheetExamplesKo {
	_TranslationsDocsComponentsSheetExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'シートの例';
}

// Path: docs.components.skeleton.examples
class _TranslationsDocsComponentsSkeletonExamplesJa extends TranslationsDocsComponentsSkeletonExamplesKo {
	_TranslationsDocsComponentsSkeletonExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'スケルトンの例';
}

// Path: docs.components.slider.examples
class _TranslationsDocsComponentsSliderExamplesJa extends TranslationsDocsComponentsSliderExamplesKo {
	_TranslationsDocsComponentsSliderExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'スライダーの例';
}

// Path: docs.components.sortable.examples
class _TranslationsDocsComponentsSortableExamplesJa extends TranslationsDocsComponentsSortableExamplesKo {
	_TranslationsDocsComponentsSortableExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ソート可能の例';
}

// Path: docs.components.star_rating.examples
class _TranslationsDocsComponentsStarRatingExamplesJa extends TranslationsDocsComponentsStarRatingExamplesKo {
	_TranslationsDocsComponentsStarRatingExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '星評価の例';
}

// Path: docs.components.stepper.examples
class _TranslationsDocsComponentsStepperExamplesJa extends TranslationsDocsComponentsStepperExamplesKo {
	_TranslationsDocsComponentsStepperExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ステッパーの例';
}

// Path: docs.components.steps.examples
class _TranslationsDocsComponentsStepsExamplesJa extends TranslationsDocsComponentsStepsExamplesKo {
	_TranslationsDocsComponentsStepsExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ステップの例';
}

// Path: docs.components.swiper.examples
class _TranslationsDocsComponentsSwiperExamplesJa extends TranslationsDocsComponentsSwiperExamplesKo {
	_TranslationsDocsComponentsSwiperExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'スワイパーの例';
}

// Path: docs.components.k_switch.examples
class _TranslationsDocsComponentsKSwitchExamplesJa extends TranslationsDocsComponentsKSwitchExamplesKo {
	_TranslationsDocsComponentsKSwitchExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'スイッチの例';
}

// Path: docs.components.switcher.examples
class _TranslationsDocsComponentsSwitcherExamplesJa extends TranslationsDocsComponentsSwitcherExamplesKo {
	_TranslationsDocsComponentsSwitcherExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'スイッチャーの例';
}

// Path: docs.components.tab_list.examples
class _TranslationsDocsComponentsTabListExamplesJa extends TranslationsDocsComponentsTabListExamplesKo {
	_TranslationsDocsComponentsTabListExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'タブリストの例';
}

// Path: docs.components.tab_pane.examples
class _TranslationsDocsComponentsTabPaneExamplesJa extends TranslationsDocsComponentsTabPaneExamplesKo {
	_TranslationsDocsComponentsTabPaneExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'タブパネルの例';
}

// Path: docs.components.table.examples
class _TranslationsDocsComponentsTableExamplesJa extends TranslationsDocsComponentsTableExamplesKo {
	_TranslationsDocsComponentsTableExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'テーブルの例';
}

// Path: docs.components.tabs.examples
class _TranslationsDocsComponentsTabsExamplesJa extends TranslationsDocsComponentsTabsExamplesKo {
	_TranslationsDocsComponentsTabsExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'タブの例';
}

// Path: docs.components.text_area.examples
class _TranslationsDocsComponentsTextAreaExamplesJa extends TranslationsDocsComponentsTextAreaExamplesKo {
	_TranslationsDocsComponentsTextAreaExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'テキストエリアの例';
}

// Path: docs.components.time_picker.examples
class _TranslationsDocsComponentsTimePickerExamplesJa extends TranslationsDocsComponentsTimePickerExamplesKo {
	_TranslationsDocsComponentsTimePickerExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => '時間選択の例';
}

// Path: docs.components.timeline.examples
class _TranslationsDocsComponentsTimelineExamplesJa extends TranslationsDocsComponentsTimelineExamplesKo {
	_TranslationsDocsComponentsTimelineExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'タイムラインの例';
}

// Path: docs.components.timeline_animation.examples
class _TranslationsDocsComponentsTimelineAnimationExamplesJa extends TranslationsDocsComponentsTimelineAnimationExamplesKo {
	_TranslationsDocsComponentsTimelineAnimationExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'タイムラインアニメーションの例';
}

// Path: docs.components.toast.examples
class _TranslationsDocsComponentsToastExamplesJa extends TranslationsDocsComponentsToastExamplesKo {
	_TranslationsDocsComponentsToastExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'トーストの例';
}

// Path: docs.components.toggle.examples
class _TranslationsDocsComponentsToggleExamplesJa extends TranslationsDocsComponentsToggleExamplesKo {
	_TranslationsDocsComponentsToggleExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'トグルの例';
}

// Path: docs.components.tooltip.examples
class _TranslationsDocsComponentsTooltipExamplesJa extends TranslationsDocsComponentsTooltipExamplesKo {
	_TranslationsDocsComponentsTooltipExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ツールチップの例';
}

// Path: docs.components.tracker.examples
class _TranslationsDocsComponentsTrackerExamplesJa extends TranslationsDocsComponentsTrackerExamplesKo {
	_TranslationsDocsComponentsTrackerExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'トラッカーの例';
}

// Path: docs.components.tree.examples
class _TranslationsDocsComponentsTreeExamplesJa extends TranslationsDocsComponentsTreeExamplesKo {
	_TranslationsDocsComponentsTreeExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ツリーの例';
}

// Path: docs.components.window.examples
class _TranslationsDocsComponentsWindowExamplesJa extends TranslationsDocsComponentsWindowExamplesKo {
	_TranslationsDocsComponentsWindowExamplesJa._(TranslationsJa root) : this._root = root, super.internal(root);

	final TranslationsJa _root; // ignore: unused_field

	// Translations
	@override String get basic => 'ウィンドウの例';
}
