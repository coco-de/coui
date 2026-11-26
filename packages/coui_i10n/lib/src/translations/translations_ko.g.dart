///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'translations.g.dart';

// Path: <root>
typedef TranslationsKo = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final translations = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.ko,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  );

	/// Metadata for the translations of <ko>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final TranslationsWidgetbookKo widgetbook = TranslationsWidgetbookKo.internal(_root);
	late final TranslationsDocsKo docs = TranslationsDocsKo.internal(_root);
}

// Path: widgetbook
class TranslationsWidgetbookKo {
	TranslationsWidgetbookKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsWidgetbookCommonKo common = TranslationsWidgetbookCommonKo.internal(_root);
	late final TranslationsWidgetbookLoadingKo loading = TranslationsWidgetbookLoadingKo.internal(_root);
	late final TranslationsWidgetbookTabsKo tabs = TranslationsWidgetbookTabsKo.internal(_root);
	late final TranslationsWidgetbookPaginationKo pagination = TranslationsWidgetbookPaginationKo.internal(_root);
	late final TranslationsWidgetbookTooltipKo tooltip = TranslationsWidgetbookTooltipKo.internal(_root);
	late final TranslationsWidgetbookRadioKo radio = TranslationsWidgetbookRadioKo.internal(_root);
	late final TranslationsWidgetbookCardKo card = TranslationsWidgetbookCardKo.internal(_root);
	late final TranslationsWidgetbookAlertKo alert = TranslationsWidgetbookAlertKo.internal(_root);
	late final TranslationsWidgetbookAccordionKo accordion = TranslationsWidgetbookAccordionKo.internal(_root);
	late final TranslationsWidgetbookSkeletonKo skeleton = TranslationsWidgetbookSkeletonKo.internal(_root);
	late final TranslationsWidgetbookToastKo toast = TranslationsWidgetbookToastKo.internal(_root);
	late final TranslationsWidgetbookChipKo chip = TranslationsWidgetbookChipKo.internal(_root);
	late final TranslationsWidgetbookCheckboxKo checkbox = TranslationsWidgetbookCheckboxKo.internal(_root);
	late final TranslationsWidgetbookToggleKo toggle = TranslationsWidgetbookToggleKo.internal(_root);
	late final TranslationsWidgetbookDialogKo dialog = TranslationsWidgetbookDialogKo.internal(_root);
	late final TranslationsWidgetbookPopoverKo popover = TranslationsWidgetbookPopoverKo.internal(_root);
	late final TranslationsWidgetbookTextFieldKo text_field = TranslationsWidgetbookTextFieldKo.internal(_root);
	late final TranslationsWidgetbookButtonKo button = TranslationsWidgetbookButtonKo.internal(_root);
	late final TranslationsWidgetbookCommandKo command = TranslationsWidgetbookCommandKo.internal(_root);
	late final TranslationsWidgetbookFabKo fab = TranslationsWidgetbookFabKo.internal(_root);
	late final TranslationsWidgetbookTableKo table = TranslationsWidgetbookTableKo.internal(_root);
	late final TranslationsWidgetbookKSwitchKo k_switch = TranslationsWidgetbookKSwitchKo.internal(_root);
	late final TranslationsWidgetbookSwitchComponentKo switch_component = TranslationsWidgetbookSwitchComponentKo.internal(_root);
	late final TranslationsWidgetbookSelectKo select = TranslationsWidgetbookSelectKo.internal(_root);
	late final TranslationsWidgetbookBreadcrumbKo breadcrumb = TranslationsWidgetbookBreadcrumbKo.internal(_root);
	late final TranslationsWidgetbookBadgeKo badge = TranslationsWidgetbookBadgeKo.internal(_root);
	late final TranslationsWidgetbookThemePreviewKo theme_preview = TranslationsWidgetbookThemePreviewKo.internal(_root);
	late final TranslationsWidgetbookChatKo chat = TranslationsWidgetbookChatKo.internal(_root);
	late final TranslationsWidgetbookMultipleChoiceKo multiple_choice = TranslationsWidgetbookMultipleChoiceKo.internal(_root);
	late final TranslationsWidgetbookFormattedInputKo formatted_input = TranslationsWidgetbookFormattedInputKo.internal(_root);
	late final TranslationsWidgetbookSwiperKo swiper = TranslationsWidgetbookSwiperKo.internal(_root);
}

// Path: docs
class TranslationsDocsKo {
	TranslationsDocsKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsDocsCommonKo common = TranslationsDocsCommonKo.internal(_root);
	late final TranslationsDocsBadgesKo badges = TranslationsDocsBadgesKo.internal(_root);
	late final TranslationsDocsFlavorsKo flavors = TranslationsDocsFlavorsKo.internal(_root);
	late final TranslationsDocsNavigationKo navigation = TranslationsDocsNavigationKo.internal(_root);
	late final TranslationsDocsPagesKo pages = TranslationsDocsPagesKo.internal(_root);
	late final TranslationsDocsComponentsKo components = TranslationsDocsComponentsKo.internal(_root);
}

// Path: widgetbook.common
class TranslationsWidgetbookCommonKo {
	TranslationsWidgetbookCommonKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '진행률 증가'
	String get increment_progress => '진행률 증가';

	/// ko: '선택된 탭: {index}'
	String selected_tab({required Object index}) => '선택된 탭: ${index}';

	/// ko: '현재 페이지: {page}'
	String current_page({required Object page}) => '현재 페이지: ${page}';

	/// ko: '전체 페이지: {count}'
	String total_pages({required Object count}) => '전체 페이지: ${count}';

	/// ko: '{current}페이지 / {total}'
	String page_of({required Object current, required Object total}) => '${current}페이지 / ${total}';

	/// ko: '아이콘 위에 마우스를 올려보세요'
	String get hover_over_icon => '아이콘 위에 마우스를 올려보세요';

	/// ko: '카운터: {count}'
	String counter({required Object count}) => '카운터: ${count}';

	/// ko: '선택된 행: {count}'
	String selected_rows({required Object count}) => '선택된 행: ${count}';

	/// ko: '값: {value}'
	String value({required Object value}) => '값: ${value}';

	/// ko: '선택된 셀: {count}'
	String selected_cells({required Object count}) => '선택된 셀: ${count}';
}

// Path: widgetbook.loading
class TranslationsWidgetbookLoadingKo {
	TranslationsWidgetbookLoadingKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '무한 로딩'
	String get indeterminate => '무한 로딩';

	/// ko: '값 포함 ({percent}%)'
	String with_value({required Object percent}) => '값 포함 (${percent}%)';

	/// ko: '사용자 정의 크기'
	String get custom_size => '사용자 정의 크기';

	/// ko: '사용자 정의 높이'
	String get custom_height => '사용자 정의 높이';

	/// ko: '원형 진행률'
	String get circular_progress => '원형 진행률';

	/// ko: '선형 진행률'
	String get linear_progress => '선형 진행률';
}

// Path: widgetbook.tabs
class TranslationsWidgetbookTabsKo {
	TranslationsWidgetbookTabsKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '홈'
	String get home => '홈';

	/// ko: '프로필'
	String get profile => '프로필';

	/// ko: '설정'
	String get settings => '설정';

	/// ko: '개요'
	String get overview => '개요';

	/// ko: '상세'
	String get details => '상세';

	/// ko: '히스토리'
	String get history => '히스토리';

	/// ko: '개요 콘텐츠'
	String get overview_content => '개요 콘텐츠';

	/// ko: '상세 콘텐츠'
	String get details_content => '상세 콘텐츠';

	/// ko: '히스토리 콘텐츠'
	String get history_content => '히스토리 콘텐츠';

	/// ko: '항목에 대한 일반 정보'
	String get general_info => '항목에 대한 일반 정보';

	/// ko: '상세 사양 및 속성'
	String get specifications => '상세 사양 및 속성';

	/// ko: '변경 및 업데이트 타임라인'
	String get timeline => '변경 및 업데이트 타임라인';
}

// Path: widgetbook.pagination
class TranslationsWidgetbookPaginationKo {
	TranslationsWidgetbookPaginationKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '처음으로 건너뛰기 표시'
	String get show_skip_to_first => '처음으로 건너뛰기 표시';

	/// ko: '마지막으로 건너뛰기 표시'
	String get show_skip_to_last => '마지막으로 건너뛰기 표시';

	/// ko: '첫 페이지에서 이전 숨기기'
	String get hide_previous_on_first => '첫 페이지에서 이전 숨기기';

	/// ko: '마지막 페이지에서 다음 숨기기'
	String get hide_next_on_last => '마지막 페이지에서 다음 숨기기';

	/// ko: '최대 표시 페이지 수'
	String get max_visible_pages => '최대 표시 페이지 수';
}

// Path: widgetbook.tooltip
class TranslationsWidgetbookTooltipKo {
	TranslationsWidgetbookTooltipKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '도움이 되는 툴팁 메시지입니다'
	String get helpful_message => '도움이 되는 툴팁 메시지입니다';

	/// ko: '위쪽 툴팁'
	String get tooltip_above => '위쪽 툴팁';

	/// ko: '아래쪽 툴팁'
	String get tooltip_below => '아래쪽 툴팁';

	/// ko: '왼쪽 툴팁'
	String get tooltip_left => '왼쪽 툴팁';

	/// ko: '오른쪽 툴팁'
	String get tooltip_right => '오른쪽 툴팁';

	/// ko: '위'
	String get top => '위';

	/// ko: '아래'
	String get bottom => '아래';

	/// ko: '왼쪽'
	String get left => '왼쪽';

	/// ko: '오른쪽'
	String get right => '오른쪽';
}

// Path: widgetbook.radio
class TranslationsWidgetbookRadioKo {
	TranslationsWidgetbookRadioKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '작게'
	String get small => '작게';

	/// ko: '중간'
	String get medium => '중간';

	/// ko: '크게'
	String get large => '크게';
}

// Path: widgetbook.card
class TranslationsWidgetbookCardKo {
	TranslationsWidgetbookCardKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '카드 콘텐츠'
	String get card_content => '카드 콘텐츠';

	/// ko: '그라데이션 카드'
	String get gradient_card => '그라데이션 카드';

	/// ko: '커스텀 데코레이션이 적용된 카드'
	String get custom_decoration => '커스텀 데코레이션이 적용된 카드';
}

// Path: widgetbook.alert
class TranslationsWidgetbookAlertKo {
	TranslationsWidgetbookAlertKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '알림 제목'
	String get title => '알림 제목';

	/// ko: '알림 메시지입니다.'
	String get message => '알림 메시지입니다.';
}

// Path: widgetbook.accordion
class TranslationsWidgetbookAccordionKo {
	TranslationsWidgetbookAccordionKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'CoUI Flutter란?'
	String get what_is_coui => 'CoUI Flutter란?';

	/// ko: 'CoUI Flutter는 일관된 디자인 패턴으로 현대적이고 접근성 높은 Flutter 애플리케이션을 구축하기 위해 설계된 종합 UI 컴포넌트 라이브러리입니다.'
	String get what_is_coui_answer => 'CoUI Flutter는 일관된 디자인 패턴으로 현대적이고 접근성 높은 Flutter 애플리케이션을 구축하기 위해 설계된 종합 UI 컴포넌트 라이브러리입니다.';

	/// ko: '어떻게 설치하나요?'
	String get how_to_install => '어떻게 설치하나요?';

	/// ko: 'pubspec.yaml 의존성에 coui_flutter를 추가하고 flutter pub get을 실행하여 패키지를 설치하세요.'
	String get how_to_install_answer => 'pubspec.yaml 의존성에 coui_flutter를 추가하고 flutter pub get을 실행하여 패키지를 설치하세요.';

	/// ko: '커스터마이징이 가능한가요?'
	String get is_customizable => '커스터마이징이 가능한가요?';

	/// ko: '네! CoUI Flutter는 ThemeData를 통해 색상, 타이포그래피, 간격 등을 커스터마이징할 수 있는 포괄적인 테마 지원을 제공합니다.'
	String get is_customizable_answer => '네! CoUI Flutter는 ThemeData를 통해 색상, 타이포그래피, 간격 등을 커스터마이징할 수 있는 포괄적인 테마 지원을 제공합니다.';

	/// ko: '시작하기'
	String get getting_started => '시작하기';

	/// ko: '패키지를 설치하고 프로젝트에 가져오는 것으로 시작하세요. 자세한 설정 방법은 문서를 참조하세요.'
	String get getting_started_answer => '패키지를 설치하고 프로젝트에 가져오는 것으로 시작하세요. 자세한 설정 방법은 문서를 참조하세요.';

	/// ko: '기능 (기본 확장됨)'
	String get features_expanded => '기능 (기본 확장됨)';

	/// ko: 'CoUI Flutter는 버튼, 폼, 다이얼로그, 네비게이션 컴포넌트 등을 포함합니다. 모든 컴포넌트는 접근성과 테마를 고려하여 설계되었습니다.'
	String get features_answer => 'CoUI Flutter는 버튼, 폼, 다이얼로그, 네비게이션 컴포넌트 등을 포함합니다. 모든 컴포넌트는 접근성과 테마를 고려하여 설계되었습니다.';

	/// ko: '지원'
	String get support => '지원';

	/// ko: '질문이나 지원이 필요하면 GitHub 저장소를 방문하거나 docs.coui.dev에서 문서를 확인하세요.'
	String get support_answer => '질문이나 지원이 필요하면 GitHub 저장소를 방문하거나 docs.coui.dev에서 문서를 확인하세요.';
}

// Path: widgetbook.skeleton
class TranslationsWidgetbookSkeletonKo {
	TranslationsWidgetbookSkeletonKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스켈레톤 활성화:'
	String get skeleton_enabled => '스켈레톤 활성화:';

	/// ko: '제목입니다'
	String get title_text => '제목입니다';

	/// ko: '긴 설명 텍스트입니다'
	String get description_text => '긴 설명 텍스트입니다';

	/// ko: '짧은 텍스트'
	String get short_text => '짧은 텍스트';

	/// ko: '스켈레톤 없이:'
	String get without_skeleton => '스켈레톤 없이:';

	/// ko: '스켈레톤 포함:'
	String get with_skeleton => '스켈레톤 포함:';

	/// ko: '사용자 이름'
	String get user_name => '사용자 이름';

	/// ko: 'user@example.com'
	String get user_email => 'user@example.com';

	/// ko: '기사 제목'
	String get article_title => '기사 제목';

	/// ko: '2024년 1월 1일 게시'
	String get posted_date => '2024년 1월 1일 게시';

	/// ko: '일상을 기록하는 개발자입니다'
	String get bio_description => '일상을 기록하는 개발자입니다';

	/// ko: '콘텐츠 표시'
	String get show_content => '콘텐츠 표시';

	/// ko: '로딩 표시'
	String get show_loading => '로딩 표시';

	/// ko: '이것은 기사 내용의 예시입니다. 로딩 중일 때 스켈레톤으로 대체됩니다.'
	String get article_content => '이것은 기사 내용의 예시입니다. 로딩 중일 때 스켈레톤으로 대체됩니다.';
}

// Path: widgetbook.toast
class TranslationsWidgetbookToastKo {
	TranslationsWidgetbookToastKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '성공'
	String get success => '성공';

	/// ko: '작업이 성공적으로 완료되었습니다'
	String get operation_completed => '작업이 성공적으로 완료되었습니다';

	/// ko: '토스트 표시'
	String get show_toast => '토스트 표시';

	/// ko: '{location}에 토스트'
	String toast_at({required Object location}) => '${location}에 토스트';

	/// ko: '왼쪽 상단'
	String get top_left => '왼쪽 상단';

	/// ko: '상단 중앙'
	String get top_center => '상단 중앙';

	/// ko: '오른쪽 상단'
	String get top_right => '오른쪽 상단';

	/// ko: '왼쪽 하단'
	String get bottom_left => '왼쪽 하단';

	/// ko: '하단 중앙'
	String get bottom_center => '하단 중앙';

	/// ko: '오른쪽 하단'
	String get bottom_right => '오른쪽 하단';
}

// Path: widgetbook.chip
class TranslationsWidgetbookChipKo {
	TranslationsWidgetbookChipKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '칩'
	String get chip => '칩';
}

// Path: widgetbook.checkbox
class TranslationsWidgetbookCheckboxKo {
	TranslationsWidgetbookCheckboxKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '이용약관에 동의합니다'
	String get accept_terms => '이용약관에 동의합니다';

	/// ko: '세 가지 상태'
	String get tristate => '세 가지 상태';
}

// Path: widgetbook.toggle
class TranslationsWidgetbookToggleKo {
	TranslationsWidgetbookToggleKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '토글'
	String get toggle => '토글';
}

// Path: widgetbook.dialog
class TranslationsWidgetbookDialogKo {
	TranslationsWidgetbookDialogKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '기본 다이얼로그'
	String get basic_dialog => '기본 다이얼로그';

	/// ko: '기본 다이얼로그'
	String get basic_title => '기본 다이얼로그';

	/// ko: '제목과 내용이 있는 간단한 다이얼로그입니다.'
	String get basic_content => '제목과 내용이 있는 간단한 다이얼로그입니다.';

	/// ko: '제목과 내용이 있는 간단한 다이얼로그입니다.'
	String get simple_dialog_content => '제목과 내용이 있는 간단한 다이얼로그입니다.';

	/// ko: '기본 표시'
	String get show_basic => '기본 표시';

	/// ko: '기본 다이얼로그 표시'
	String get show_basic_dialog => '기본 다이얼로그 표시';

	/// ko: '작업 확인'
	String get confirm_action => '작업 확인';

	/// ko: '확인'
	String get confirm_title => '확인';

	/// ko: '정말 이 작업을 수행하시겠습니까?'
	String get confirm_content => '정말 이 작업을 수행하시겠습니까?';

	/// ko: '정말 이 작업을 수행하시겠습니까? 이 작업은 취소할 수 없습니다.'
	String get confirm_action_content => '정말 이 작업을 수행하시겠습니까? 이 작업은 취소할 수 없습니다.';

	/// ko: '취소'
	String get cancel => '취소';

	/// ko: '확인'
	String get confirm => '확인';

	/// ko: '확인 표시'
	String get show_confirmation => '확인 표시';

	/// ko: '확인 다이얼로그 표시'
	String get show_confirmation_dialog => '확인 다이얼로그 표시';

	/// ko: '경고'
	String get warning => '경고';

	/// ko: '경고'
	String get warning_title => '경고';

	/// ko: '이 작업은 데이터에 영향을 미칠 수 있습니다. 신중하게 진행하세요.'
	String get warning_content => '이 작업은 데이터에 영향을 미칠 수 있습니다. 신중하게 진행하세요.';

	/// ko: '닫기'
	String get dismiss => '닫기';

	/// ko: '경고 표시'
	String get show_warning => '경고 표시';

	/// ko: '경고 다이얼로그 표시'
	String get show_warning_dialog => '경고 다이얼로그 표시';
}

// Path: widgetbook.popover
class TranslationsWidgetbookPopoverKo {
	TranslationsWidgetbookPopoverKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '팝오버 콘텐츠'
	String get popover_content => '팝오버 콘텐츠';

	/// ko: '팝오버 제목'
	String get content_title => '팝오버 제목';

	/// ko: '사용자 정의 가능한 콘텐츠가 있는 팝오버입니다.'
	String get content_description => '사용자 정의 가능한 콘텐츠가 있는 팝오버입니다.';

	/// ko: '사용자 정의 가능한 콘텐츠가 있는 팝오버입니다.'
	String get customizable_content => '사용자 정의 가능한 콘텐츠가 있는 팝오버입니다.';

	/// ko: '팝오버 표시'
	String get show_popover => '팝오버 표시';

	/// ko: '{position}에 팝오버'
	String popover_at({required Object position}) => '${position}에 팝오버';

	/// ko: '상단'
	String get top => '상단';

	/// ko: '하단'
	String get bottom => '하단';

	/// ko: '왼쪽'
	String get left => '왼쪽';

	/// ko: '오른쪽'
	String get right => '오른쪽';
}

// Path: widgetbook.text_field
class TranslationsWidgetbookTextFieldKo {
	TranslationsWidgetbookTextFieldKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '이름을 입력하세요'
	String get enter_name => '이름을 입력하세요';

	/// ko: '여기에 입력하세요'
	String get type_here => '여기에 입력하세요';
}

// Path: widgetbook.button
class TranslationsWidgetbookButtonKo {
	TranslationsWidgetbookButtonKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '기본 버튼'
	String get primary_button => '기본 버튼';

	/// ko: '보조 버튼'
	String get secondary_button => '보조 버튼';

	/// ko: '파일 업로드'
	String get dashed_button => '파일 업로드';

	/// ko: '파일 업로드'
	String get upload_file => '파일 업로드';
}

// Path: widgetbook.command
class TranslationsWidgetbookCommandKo {
	TranslationsWidgetbookCommandKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '명령어 검색...'
	String get placeholder => '명령어 검색...';

	/// ko: '항목'
	String get item => '항목';

	/// ko: '최근 항목'
	String get category_recent => '최근 항목';

	/// ko: '작업'
	String get category_actions => '작업';

	/// ko: '최근 파일 1'
	String get recent_item_1 => '최근 파일 1';

	/// ko: '최근 파일 2'
	String get recent_item_2 => '최근 파일 2';

	/// ko: '새로 만들기'
	String get action_new => '새로 만들기';

	/// ko: '열기'
	String get action_open => '열기';

	/// ko: '저장'
	String get action_save => '저장';
}

// Path: widgetbook.fab
class TranslationsWidgetbookFabKo {
	TranslationsWidgetbookFabKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '추가'
	String get default_tooltip => '추가';

	/// ko: '메뉴 열기'
	String get actions_tooltip => '메뉴 열기';

	/// ko: '작은 FAB'
	String get mini_tooltip => '작은 FAB';

	/// ko: '팬 메뉴'
	String get fan_tooltip => '팬 메뉴';

	/// ko: 'FAB 버튼을 클릭해보세요'
	String get body_text => 'FAB 버튼을 클릭해보세요';

	/// ko: '편집'
	String get action_edit => '편집';

	/// ko: '편집'
	String get action_edit_tooltip => '편집';

	/// ko: '공유'
	String get action_share => '공유';

	/// ko: '공유'
	String get action_share_tooltip => '공유';

	/// ko: '삭제'
	String get action_delete => '삭제';

	/// ko: '삭제'
	String get action_delete_tooltip => '삭제';

	/// ko: '카메라'
	String get action_camera => '카메라';

	/// ko: '갤러리'
	String get action_gallery => '갤러리';

	/// ko: '비디오'
	String get action_video => '비디오';

	/// ko: '오디오'
	String get action_audio => '오디오';
}

// Path: widgetbook.table
class TranslationsWidgetbookTableKo {
	TranslationsWidgetbookTableKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '이름'
	String get name => '이름';

	/// ko: '이메일'
	String get email => '이메일';

	/// ko: '역할'
	String get role => '역할';

	/// ko: '홍길동'
	String get john_doe => '홍길동';

	/// ko: 'hong@example.com'
	String get john_email => 'hong@example.com';

	/// ko: '개발자'
	String get developer => '개발자';

	/// ko: '김영희'
	String get jane_smith => '김영희';

	/// ko: 'kim@example.com'
	String get jane_email => 'kim@example.com';

	/// ko: '디자이너'
	String get designer => '디자이너';

	/// ko: '이철수'
	String get bob_johnson => '이철수';

	/// ko: 'lee@example.com'
	String get bob_email => 'lee@example.com';

	/// ko: '매니저'
	String get manager => '매니저';

	/// ko: '선택'
	String get select => '선택';

	/// ko: '제품'
	String get product => '제품';

	/// ko: '가격'
	String get price => '가격';

	/// ko: '재고'
	String get stock => '재고';

	/// ko: '노트북'
	String get laptop => '노트북';

	/// ko: '마우스'
	String get mouse => '마우스';

	/// ko: '키보드'
	String get keyboard => '키보드';
}

// Path: widgetbook.k_switch
class TranslationsWidgetbookKSwitchKo {
	TranslationsWidgetbookKSwitchKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스위치'
	String get k_switch => '스위치';
}

// Path: widgetbook.switch_component
class TranslationsWidgetbookSwitchComponentKo {
	TranslationsWidgetbookSwitchComponentKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스위치 라벨'
	String get switch_label => '스위치 라벨';
}

// Path: widgetbook.select
class TranslationsWidgetbookSelectKo {
	TranslationsWidgetbookSelectKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '사과'
	String get apple => '사과';

	/// ko: '바나나'
	String get banana => '바나나';

	/// ko: '체리'
	String get cherry => '체리';

	/// ko: '대추'
	String get date => '대추';

	/// ko: '크기를 선택하세요'
	String get choose_size => '크기를 선택하세요';

	/// ko: '작게'
	String get small => '작게';

	/// ko: '중간'
	String get medium => '중간';

	/// ko: '크게'
	String get large => '크게';

	/// ko: '아주 크게'
	String get extra_large => '아주 크게';

	/// ko: '감귤류'
	String get citrus_fruits => '감귤류';

	/// ko: '오렌지'
	String get orange => '오렌지';

	/// ko: '레몬'
	String get lemon => '레몬';

	/// ko: '자몽'
	String get grapefruit => '자몽';

	/// ko: '베리류'
	String get berries => '베리류';

	/// ko: '딸기'
	String get strawberry => '딸기';

	/// ko: '블루베리'
	String get blueberry => '블루베리';

	/// ko: '라즈베리'
	String get raspberry => '라즈베리';
}

// Path: widgetbook.breadcrumb
class TranslationsWidgetbookBreadcrumbKo {
	TranslationsWidgetbookBreadcrumbKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '홈'
	String get home => '홈';

	/// ko: '제품'
	String get products => '제품';

	/// ko: '전자제품'
	String get electronics => '전자제품';

	/// ko: '스마트폰'
	String get smartphones => '스마트폰';

	/// ko: '문서'
	String get documents => '문서';

	/// ko: '프로젝트'
	String get projects => '프로젝트';

	/// ko: '현재 폴더'
	String get current_folder => '현재 폴더';

	/// ko: '현재 경로: {path}'
	String current_path({required Object path}) => '현재 경로: ${path}';
}

// Path: widgetbook.badge
class TranslationsWidgetbookBadgeKo {
	TranslationsWidgetbookBadgeKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '기본'
	String get primary => '기본';

	/// ko: '보조'
	String get secondary => '보조';

	/// ko: '외곽선'
	String get outline => '외곽선';

	/// ko: '위험'
	String get destructive => '위험';

	/// ko: '추천'
	String get featured => '추천';

	/// ko: '더보기'
	String get more => '더보기';

	/// ko: '인증됨'
	String get verified => '인증됨';

	/// ko: '오류'
	String get error => '오류';

	/// ko: '클릭하세요'
	String get click_me => '클릭하세요';

	/// ko: '클릭 가능'
	String get clickable => '클릭 가능';
}

// Path: widgetbook.theme_preview
class TranslationsWidgetbookThemePreviewKo {
	TranslationsWidgetbookThemePreviewKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '테마 미리보기'
	String get title => '테마 미리보기';

	/// ko: '모든 테마 토큰과 컴포넌트 스타일의 종합적인 개요'
	String get description => '모든 테마 토큰과 컴포넌트 스타일의 종합적인 개요';

	/// ko: '색상 팔레트'
	String get color_palette => '색상 팔레트';

	/// ko: '브랜드 색상'
	String get brand_colors => '브랜드 색상';

	/// ko: '기본 색상'
	String get base_colors => '기본 색상';

	/// ko: '상태 색상'
	String get status_colors => '상태 색상';

	/// ko: '버튼'
	String get buttons => '버튼';

	/// ko: 'Primary'
	String get primary_button => 'Primary';

	/// ko: 'Secondary'
	String get secondary_button => 'Secondary';

	/// ko: 'Outline'
	String get outline_button => 'Outline';

	/// ko: 'Ghost'
	String get ghost_button => 'Ghost';

	/// ko: 'Destructive'
	String get destructive_button => 'Destructive';

	/// ko: '비활성화'
	String get disabled_button => '비활성화';

	/// ko: '카드'
	String get cards => '카드';

	/// ko: '카드 제목'
	String get card_title => '카드 제목';

	/// ko: '샘플 카드 설명입니다.'
	String get card_description => '샘플 카드 설명입니다.';

	/// ko: 'Surface 카드'
	String get surface_card => 'Surface 카드';

	/// ko: '배경이 있는 filled 스타일'
	String get filled_variant => '배경이 있는 filled 스타일';

	/// ko: '폼 요소'
	String get form_elements => '폼 요소';

	/// ko: '텍스트를 입력하세요...'
	String get text_input_placeholder => '텍스트를 입력하세요...';

	/// ko: '선택됨'
	String get checkbox_checked => '선택됨';

	/// ko: '선택 안됨'
	String get checkbox_unchecked => '선택 안됨';

	/// ko: '켜짐'
	String get toggle_on => '켜짐';

	/// ko: '꺼짐'
	String get toggle_off => '꺼짐';

	/// ko: '알림'
	String get alerts => '알림';

	/// ko: '정보 알림'
	String get info_alert => '정보 알림';

	/// ko: '안내 메시지입니다.'
	String get info_alert_message => '안내 메시지입니다.';

	/// ko: '오류 알림'
	String get error_alert => '오류 알림';

	/// ko: '문제가 발생했습니다.'
	String get error_alert_message => '문제가 발생했습니다.';

	/// ko: '배지 & 칩'
	String get badges_chips => '배지 & 칩';

	/// ko: 'Primary'
	String get primary_badge => 'Primary';

	/// ko: 'Secondary'
	String get secondary_badge => 'Secondary';

	/// ko: 'Outline'
	String get outline_badge => 'Outline';

	/// ko: 'Destructive'
	String get destructive_badge => 'Destructive';

	/// ko: '즐겨찾기'
	String get chip_example => '즐겨찾기';

	/// ko: '타이포그래피'
	String get typography => '타이포그래피';

	/// ko: '제목 1'
	String get heading_1 => '제목 1';

	/// ko: '제목 2'
	String get heading_2 => '제목 2';

	/// ko: '제목 3'
	String get heading_3 => '제목 3';

	/// ko: '제목 4'
	String get heading_4 => '제목 4';

	/// ko: '일반 두께의 본문 텍스트입니다.'
	String get body_text => '일반 두께의 본문 텍스트입니다.';

	/// ko: '캡션용 작은 텍스트입니다.'
	String get small_text => '캡션용 작은 텍스트입니다.';

	/// ko: '부가 정보를 위한 흐린 텍스트입니다.'
	String get muted_text => '부가 정보를 위한 흐린 텍스트입니다.';

	/// ko: '강조를 위한 굵은 텍스트입니다.'
	String get bold_text => '강조를 위한 굵은 텍스트입니다.';

	/// ko: '간격 & 둥글기'
	String get spacing_radius => '간격 & 둥글기';

	/// ko: '테두리 둥글기'
	String get border_radius => '테두리 둥글기';

	/// ko: '로딩 상태'
	String get loading_states => '로딩 상태';

	/// ko: '컴포넌트 데모'
	String get component_demos => '컴포넌트 데모';

	/// ko: '테마 설정을 활용한 다양한 컴포넌트 데모'
	String get component_demos_desc => '테마 설정을 활용한 다양한 컴포넌트 데모';

	/// ko: '미리보기'
	String get preview => '미리보기';

	/// ko: '더보기'
	String get more => '더보기';

	/// ko: '신발'
	String get shoes => '신발';

	/// ko: '가방'
	String get bags => '가방';

	/// ko: '후드티'
	String get hoodies => '후드티';

	/// ko: '액세서리'
	String get accessories => '액세서리';

	/// ko: '판매량'
	String get sales_volume_text => '판매량';

	/// ko: '차트'
	String get charts => '차트';

	/// ko: '상세'
	String get details => '상세';

	/// ko: '줌 회의'
	String get pm_zoomcall => '줌 회의';

	/// ko: '대화 중'
	String get pm_talking => '대화 중';

	/// ko: '이벤트 검색'
	String get search_for_events => '이벤트 검색';

	/// ko: '종일 이벤트 표시'
	String get show_all_day_events => '종일 이벤트 표시';

	/// ko: '팀 동기화 회의'
	String get team_sync_meeting => '팀 동기화 회의';

	/// ko: '주간 제품 리뷰'
	String get weekly_product_review => '주간 제품 리뷰';

	/// ko: '1시간'
	String get one_hour => '1시간';

	/// ko: '탭 1'
	String get tab_1 => '탭 1';

	/// ko: '탭 2'
	String get tab_2 => '탭 2';

	/// ko: '탭 3'
	String get tab_3 => '탭 3';

	/// ko: '탭 2 콘텐츠'
	String get tab_content_2 => '탭 2 콘텐츠';

	/// ko: '최근 주문'
	String get recent_orders => '최근 주문';

	/// ko: '찰리'
	String get name_charlie => '찰리';

	/// ko: '보내기'
	String get send => '보내기';

	/// ko: '하워드'
	String get name_howard => '하워드';

	/// ko: '실패'
	String get failed => '실패';

	/// ko: '피오나'
	String get name_fiona => '피오나';

	/// ko: '진행 중'
	String get in_progress => '진행 중';

	/// ko: '닉'
	String get name_nick => '닉';

	/// ko: '완료됨'
	String get completed => '완료됨';

	/// ko: '아만다'
	String get name_amanda => '아만다';

	/// ko: '설치 명령어'
	String get install_command => '설치 명령어';

	/// ko: '설치 중'
	String get installing => '설치 중';

	/// ko: '완료'
	String get done => '완료';

	/// ko: '페이지 점수'
	String get page_score => '페이지 점수';

	/// ko: '모두 양호'
	String get all_good => '모두 양호';

	/// ko: '{count}개의 새 메시지'
	String new_messages({required Object count}) => '${count}개의 새 메시지';

	/// ko: '인증 완료'
	String get verification_completed => '인증 완료';

	/// ko: '클릭하여 인증'
	String get click_to_verify => '클릭하여 인증';

	/// ko: '접근 거부됨'
	String get access_denied => '접근 거부됨';

	/// ko: '지원'
	String get support => '지원';

	/// ko: '가격 범위'
	String get price_range => '가격 범위';

	/// ko: '슬라이더 값'
	String get slider_value => '슬라이더 값';

	/// ko: '세일'
	String get sale => '세일';

	/// ko: '{count}개 리뷰'
	String n_reviews({required Object count}) => '${count}개 리뷰';

	/// ko: '{amount}원'
	String price_amount({required Object amount}) => '${amount}원';

	/// ko: '{count}자 남음'
	String characters_remaining({required Object count}) => '${count}자 남음';

	/// ko: '카드 소유자명'
	String get name_on_card => '카드 소유자명';

	/// ko: '약관을 읽지 않고 동의합니다'
	String get accept_terms_without_reading => '약관을 읽지 않고 동의합니다';

	/// ko: '액세스 토큰'
	String get access_tokens => '액세스 토큰';

	/// ko: '댓글 추가'
	String get add_comments => '댓글 추가';

	/// ko: '컨텍스트 추가'
	String get add_context => '컨텍스트 추가';

	/// ko: '파일 추가'
	String get add_files => '파일 추가';

	/// ko: '나중에 더 추가'
	String get add_more_later => '나중에 더 추가';

	/// ko: '관리자 패널'
	String get admin_panel => '관리자 패널';

	/// ko: '모든 소스'
	String get all_sources => '모든 소스';

	/// ko: '모든 거래 안전함'
	String get all_transactions_secure => '모든 거래 안전함';

	/// ko: '배경화면 틴트 허용'
	String get allow_wallpaper_tint => '배경화면 틴트 허용';

	/// ko: '아나킨'
	String get anakin => '아나킨';

	/// ko: '분석'
	String get analytics => '분석';

	/// ko: 'API 접근'
	String get api_access => 'API 접근';

	/// ko: '보관'
	String get archive => '보관';

	/// ko: '자동'
	String get auto => '자동';

	/// ko: '청구 주소'
	String get billing_address => '청구 주소';

	/// ko: '결제에 사용되는 주소'
	String get billing_address_desc => '결제에 사용되는 주소';

	/// ko: '박스 둥글기'
	String get box_radius => '박스 둥글기';

	/// ko: '지금 구매'
	String get buy_now => '지금 구매';

	/// ko: '취소'
	String get cancel => '취소';

	/// ko: '카드 번호'
	String get card_number => '카드 번호';

	/// ko: '신용카드 번호'
	String get card_number_desc => '신용카드 번호';

	/// ko: '0000 0000 0000 0000'
	String get card_number_placeholder => '0000 0000 0000 0000';

	/// ko: '댓글'
	String get comments => '댓글';

	/// ko: '컴퓨팅 환경'
	String get compute_env => '컴퓨팅 환경';

	/// ko: '계정 만들기'
	String get create_account => '계정 만들기';

	/// ko: '새 계정을 만드세요'
	String get create_account_desc => '새 계정을 만드세요';

	/// ko: '현재 테마'
	String get current_theme => '현재 테마';

	/// ko: 'CVV'
	String get cvv => 'CVV';

	/// ko: '123'
	String get cvv_placeholder => '123';

	/// ko: '다크'
	String get dark => '다크';

	/// ko: '데이터베이스'
	String get databases => '데이터베이스';

	/// ko: '12월 매출'
	String get december_revenue => '12월 매출';

	/// ko: '배송됨'
	String get delivered => '배송됨';

	/// ko: '임시 저장'
	String get draft => '임시 저장';

	/// ko: '활성화'
	String get enable => '활성화';

	/// ko: '필드 둥글기'
	String get field_radius => '필드 둥글기';

	/// ko: '찾기'
	String get find => '찾기';

	/// ko: '안녕하세요!'
	String get hello_message => '안녕하세요!';

	/// ko: '고지'
	String get high_ground => '고지';

	/// ko: '저희를 어떻게 알게 되셨나요?'
	String get how_hear_about_us => '저희를 어떻게 알게 되셨나요?';

	/// ko: '서버의 비밀'
	String get hp_chamber_of_servers => '서버의 비밀';

	/// ko: '프레임워크의 유물'
	String get hp_deathly_frameworks => '프레임워크의 유물';

	/// ko: '피닉스의 영약'
	String get hp_elixir_of_phoenix => '피닉스의 영약';

	/// ko: '파이어베이스의 성배'
	String get hp_goblet_of_firebase => '파이어베이스의 성배';

	/// ko: '반쯤 배포된 앱'
	String get hp_half_deployed_app => '반쯤 배포된 앱';

	/// ko: '애저의 포로'
	String get hp_prisoner_of_azure => '애저의 포로';

	/// ko: '마법사의 스택'
	String get hp_sorcerers_stack => '마법사의 스택';

	/// ko: '팀원을 초대하세요'
	String get invite_desc => '팀원을 초대하세요';

	/// ko: '홍길동'
	String get john_doe => '홍길동';

	/// ko: '케노비'
	String get kenobi => '케노비';

	/// ko: '쿠버네티스'
	String get kubernetes => '쿠버네티스';

	/// ko: '라이트'
	String get light => '라이트';

	/// ko: '탭 로딩 중'
	String get loading_tab => '탭 로딩 중';

	/// ko: '메시지'
	String get messages => '메시지';

	/// ko: '최소값'
	String get min_value => '최소값';

	/// ko: '모드'
	String get mode => '모드';

	/// ko: '월'
	String get month => '월';

	/// ko: 'MM'
	String get month_placeholder => 'MM';

	/// ko: '월간'
	String get monthly => '월간';

	/// ko: '나이키 신발'
	String get nike_shoes => '나이키 신발';

	/// ko: '팀원이 없습니다'
	String get no_team_members => '팀원이 없습니다';

	/// ko: 'GPU 개수'
	String get number_of_gpus => 'GPU 개수';

	/// ko: '또는 로그인'
	String get or_login => '또는 로그인';

	/// ko: '기타'
	String get other => '기타';

	/// ko: '비밀번호'
	String get password => '비밀번호';

	/// ko: '비밀번호가 취약합니다'
	String get password_weak => '비밀번호가 취약합니다';

	/// ko: '결제 수단'
	String get payment_method => '결제 수단';

	/// ko: '월당'
	String get per_month => '월당';

	/// ko: '게시물을 작성하세요...'
	String get post_placeholder => '게시물을 작성하세요...';

	/// ko: '우선 지원'
	String get priority_support => '우선 지원';

	/// ko: '요청 처리 중'
	String get processing_request => '요청 처리 중';

	/// ko: '제품'
	String get products => '제품';

	/// ko: '게시'
	String get publish => '게시';

	/// ko: '추천'
	String get referral => '추천';

	/// ko: '등록'
	String get register => '등록';

	/// ko: '보고서'
	String get report => '보고서';

	/// ko: '매출액'
	String get revenue_amount => '매출액';

	/// ko: '매출 추세'
	String get revenue_trend => '매출 추세';

	/// ko: '배송 주소와 동일'
	String get same_as_shipping => '배송 주소와 동일';

	/// ko: '검색'
	String get search => '검색';

	/// ko: '검색 엔진'
	String get search_engine => '검색 엔진';

	/// ko: '선택자 둥글기'
	String get selector_radius => '선택자 둥글기';

	/// ko: '초대 보내기'
	String get send_invite => '초대 보내기';

	/// ko: '메시지를 입력하세요...'
	String get send_message_placeholder => '메시지를 입력하세요...';

	/// ko: '설정'
	String get settings => '설정';

	/// ko: '다시 알림'
	String get snooze => '다시 알림';

	/// ko: '소셜 미디어'
	String get social_media => '소셜 미디어';

	/// ko: '별점'
	String get star_rating => '별점';

	/// ko: '스타터 플랜'
	String get starter_plan => '스타터 플랜';

	/// ko: '제출'
	String get submit => '제출';

	/// ko: '스팸 수신 동의'
	String get subscribe_spam => '스팸 수신 동의';

	/// ko: '동기화 중'
	String get syncing => '동기화 중';

	/// ko: '2단계 인증'
	String get two_factor_auth => '2단계 인증';

	/// ko: '힘을 과소평가하지 마세요'
	String get underestimate_power => '힘을 과소평가하지 마세요';

	/// ko: '무제한 프로젝트'
	String get unlimited_projects => '무제한 프로젝트';

	/// ko: '업데이트 중'
	String get updating => '업데이트 중';

	/// ko: '사용자 이름'
	String get username => '사용자 이름';

	/// ko: '사용자'
	String get users => '사용자';

	/// ko: '가상 머신'
	String get virtual_machine => '가상 머신';

	/// ko: '배경화면 틴팅'
	String get wallpaper_tinting => '배경화면 틴팅';

	/// ko: '게시물 작성'
	String get write_post => '게시물 작성';

	/// ko: '년'
	String get year => '년';

	/// ko: 'YYYY'
	String get year_placeholder => 'YYYY';

	/// ko: '연간'
	String get yearly => '연간';

	/// ko: '당신'
	String get you => '당신';
}

// Path: widgetbook.chat
class TranslationsWidgetbookChatKo {
	TranslationsWidgetbookChatKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '안녕하세요! 어떻게 지내세요?'
	String get hello => '안녕하세요! 어떻게 지내세요?';

	/// ko: '잘 지내요, 감사합니다!'
	String get doing_great => '잘 지내요, 감사합니다!';

	/// ko: '오늘 날씨가 좋네요!'
	String get nice_weather => '오늘 날씨가 좋네요!';

	/// ko: '네, 정말 아름답네요!'
	String get yes_beautiful => '네, 정말 아름답네요!';

	/// ko: '발신자'
	String get sender => '발신자';

	/// ko: '수신자'
	String get receiver => '수신자';
}

// Path: widgetbook.multiple_choice
class TranslationsWidgetbookMultipleChoiceKo {
	TranslationsWidgetbookMultipleChoiceKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'Option A'
	String get option_a => 'Option A';

	/// ko: 'Option B'
	String get option_b => 'Option B';

	/// ko: 'Option C'
	String get option_c => 'Option C';

	/// ko: 'Option D'
	String get option_d => 'Option D';

	/// ko: '선택: {value}'
	String selected_value({required Object value}) => '선택: ${value}';

	/// ko: '선택: {values}'
	String selected_values({required Object values}) => '선택: ${values}';
}

// Path: widgetbook.formatted_input
class TranslationsWidgetbookFormattedInputKo {
	TranslationsWidgetbookFormattedInputKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '날짜 형식 (MM/DD/YYYY)'
	String get date_format => '날짜 형식 (MM/DD/YYYY)';

	/// ko: '시간 형식 (HH:MM)'
	String get time_format => '시간 형식 (HH:MM)';

	/// ko: '현재 값: {value}'
	String current_value({required Object value}) => '현재 값: ${value}';
}

// Path: widgetbook.swiper
class TranslationsWidgetbookSwiperKo {
	TranslationsWidgetbookSwiperKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스와이프하거나 탭하여 열기'
	String get swipe_hint => '스와이프하거나 탭하여 열기';

	/// ko: '오버레이 콘텐츠'
	String get overlay_content => '오버레이 콘텐츠';

	/// ko: '닫기'
	String get close => '닫기';
}

// Path: docs.common
class TranslationsDocsCommonKo {
	TranslationsDocsCommonKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'coui_flutter'
	String get app_name => 'coui_flutter';

	/// ko: '문서 검색...'
	String get search_documentation => '문서 검색...';

	/// ko: '문서'
	String get docs => '문서';

	/// ko: '컴포넌트'
	String get components => '컴포넌트';

	/// ko: '닫기'
	String get close => '닫기';

	/// ko: '이 페이지 목차'
	String get on_this_page => '이 페이지 목차';

	/// ko: '개발 중'
	String get work_in_progress_title => '개발 중';

	/// ko: '이 페이지는 아직 개발 중입니다. 나중에 다시 방문해주세요.'
	String get work_in_progress_message => '이 페이지는 아직 개발 중입니다. 나중에 다시 방문해주세요.';

	/// ko: '추가'
	String get add => '추가';

	/// ko: '초기화'
	String get reset => '초기화';

	/// ko: '이전'
	String get prev => '이전';

	/// ko: '다음'
	String get next => '다음';

	/// ko: '완료'
	String get finish => '완료';

	/// ko: '열기'
	String get open => '열기';

	/// ko: '비활성'
	String get disabled => '비활성';

	/// ko: '새로고침'
	String get refresh => '새로고침';

	/// ko: '다시 빌드'
	String get rebuild => '다시 빌드';

	/// ko: '색상 변경'
	String get change_color => '색상 변경';
}

// Path: docs.badges
class TranslationsDocsBadgesKo {
	TranslationsDocsBadgesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '새로운'
	String get k_new => '새로운';

	/// ko: '업데이트됨'
	String get updated => '업데이트됨';

	/// ko: '개발 중'
	String get wip => '개발 중';

	/// ko: '실험적'
	String get experimental => '실험적';
}

// Path: docs.flavors
class TranslationsDocsFlavorsKo {
	TranslationsDocsFlavorsKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '로컬'
	String get local => '로컬';

	/// ko: '실험적'
	String get experimental => '실험적';

	/// ko: '알 수 없음'
	String get unknown => '알 수 없음';
}

// Path: docs.navigation
class TranslationsDocsNavigationKo {
	TranslationsDocsNavigationKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '시작하기'
	String get getting_started => '시작하기';

	/// ko: '애니메이션'
	String get animation => '애니메이션';

	/// ko: '컨트롤'
	String get control => '컨트롤';

	/// ko: '공개'
	String get disclosure => '공개';

	/// ko: '표시'
	String get display => '표시';

	/// ko: '피드백'
	String get feedback => '피드백';

	/// ko: '폼'
	String get form => '폼';

	/// ko: '레이아웃'
	String get layout => '레이아웃';

	/// ko: '네비게이션'
	String get navigation => '네비게이션';

	/// ko: '오버레이'
	String get overlay => '오버레이';

	/// ko: '유틸리티'
	String get utility => '유틸리티';

	/// ko: '내 계정'
	String get my_account => '내 계정';

	/// ko: '프로필'
	String get profile => '프로필';

	/// ko: '설정'
	String get settings => '설정';

	/// ko: '팀'
	String get team => '팀';

	/// ko: '새 팀'
	String get new_team => '새 팀';

	/// ko: '결제'
	String get billing => '결제';

	/// ko: 'API'
	String get api => 'API';

	/// ko: '로그아웃'
	String get log_out => '로그아웃';

	/// ko: '지원'
	String get support => '지원';

	/// ko: '사용자 초대'
	String get invite_users => '사용자 초대';

	/// ko: '더보기'
	String get more => '더보기';

	/// ko: 'GitHub'
	String get github => 'GitHub';

	/// ko: '노트'
	String get note => '노트';

	/// ko: '메시지'
	String get message => '메시지';

	/// ko: '키보드 단축키'
	String get keyboard_shortcuts => '키보드 단축키';
}

// Path: docs.pages
class TranslationsDocsPagesKo {
	TranslationsDocsPagesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsDocsPagesIntroductionKo introduction = TranslationsDocsPagesIntroductionKo.internal(_root);
	late final TranslationsDocsPagesInstallationKo installation = TranslationsDocsPagesInstallationKo.internal(_root);
	late final TranslationsDocsPagesThemeKo theme = TranslationsDocsPagesThemeKo.internal(_root);
	late final TranslationsDocsPagesTypographyKo typography = TranslationsDocsPagesTypographyKo.internal(_root);
	late final TranslationsDocsPagesLayoutKo layout = TranslationsDocsPagesLayoutKo.internal(_root);
	late final TranslationsDocsPagesWebPreloaderKo web_preloader = TranslationsDocsPagesWebPreloaderKo.internal(_root);
	late final TranslationsDocsPagesComponentsListKo components_list = TranslationsDocsPagesComponentsListKo.internal(_root);
	late final TranslationsDocsPagesIconsKo icons = TranslationsDocsPagesIconsKo.internal(_root);
	late final TranslationsDocsPagesColorsKo colors = TranslationsDocsPagesColorsKo.internal(_root);
	late final TranslationsDocsPagesExternalKo external = TranslationsDocsPagesExternalKo.internal(_root);
	late final TranslationsDocsPagesStateKo state = TranslationsDocsPagesStateKo.internal(_root);
}

// Path: docs.components
class TranslationsDocsComponentsKo {
	TranslationsDocsComponentsKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsDocsComponentsAccordionKo accordion = TranslationsDocsComponentsAccordionKo.internal(_root);
	late final TranslationsDocsComponentsAlertKo alert = TranslationsDocsComponentsAlertKo.internal(_root);
	late final TranslationsDocsComponentsEmptyStateKo empty_state = TranslationsDocsComponentsEmptyStateKo.internal(_root);
	late final TranslationsDocsComponentsFadeScrollKo fade_scroll = TranslationsDocsComponentsFadeScrollKo.internal(_root);
	late final TranslationsDocsComponentsValidationBadgeKo validation_badge = TranslationsDocsComponentsValidationBadgeKo.internal(_root);
	late final TranslationsDocsComponentsBannerKo banner = TranslationsDocsComponentsBannerKo.internal(_root);
	late final TranslationsDocsComponentsAlertDialogKo alert_dialog = TranslationsDocsComponentsAlertDialogKo.internal(_root);
	late final TranslationsDocsComponentsAnimatedValueBuilderKo animated_value_builder = TranslationsDocsComponentsAnimatedValueBuilderKo.internal(_root);
	late final TranslationsDocsComponentsAppBarKo app_bar = TranslationsDocsComponentsAppBarKo.internal(_root);
	late final TranslationsDocsComponentsFabKo fab = TranslationsDocsComponentsFabKo.internal(_root);
	late final TranslationsDocsComponentsHoverKo hover = TranslationsDocsComponentsHoverKo.internal(_root);
	late final TranslationsDocsComponentsScrollbarKo scrollbar = TranslationsDocsComponentsScrollbarKo.internal(_root);
	late final TranslationsDocsComponentsAutocompleteKo autocomplete = TranslationsDocsComponentsAutocompleteKo.internal(_root);
	late final TranslationsDocsComponentsAvatarKo avatar = TranslationsDocsComponentsAvatarKo.internal(_root);
	late final TranslationsDocsComponentsAvatarGroupKo avatar_group = TranslationsDocsComponentsAvatarGroupKo.internal(_root);
	late final TranslationsDocsComponentsBadgeKo badge = TranslationsDocsComponentsBadgeKo.internal(_root);
	late final TranslationsDocsComponentsBreadcrumbKo breadcrumb = TranslationsDocsComponentsBreadcrumbKo.internal(_root);
	late final TranslationsDocsComponentsButtonKo button = TranslationsDocsComponentsButtonKo.internal(_root);
	late final TranslationsDocsComponentsCalendarKo calendar = TranslationsDocsComponentsCalendarKo.internal(_root);
	late final TranslationsDocsComponentsCardKo card = TranslationsDocsComponentsCardKo.internal(_root);
	late final TranslationsDocsComponentsCardImageKo card_image = TranslationsDocsComponentsCardImageKo.internal(_root);
	late final TranslationsDocsComponentsCarouselKo carousel = TranslationsDocsComponentsCarouselKo.internal(_root);
	late final TranslationsDocsComponentsCheckboxKo checkbox = TranslationsDocsComponentsCheckboxKo.internal(_root);
	late final TranslationsDocsComponentsChipKo chip = TranslationsDocsComponentsChipKo.internal(_root);
	late final TranslationsDocsComponentsChipInputKo chip_input = TranslationsDocsComponentsChipInputKo.internal(_root);
	late final TranslationsDocsComponentsCircularProgressKo circular_progress = TranslationsDocsComponentsCircularProgressKo.internal(_root);
	late final TranslationsDocsComponentsCodeSnippetKo code_snippet = TranslationsDocsComponentsCodeSnippetKo.internal(_root);
	late final TranslationsDocsComponentsCollapsibleKo collapsible = TranslationsDocsComponentsCollapsibleKo.internal(_root);
	late final TranslationsDocsComponentsColorPickerKo color_picker = TranslationsDocsComponentsColorPickerKo.internal(_root);
	late final TranslationsDocsComponentsCommandKo command = TranslationsDocsComponentsCommandKo.internal(_root);
	late final TranslationsDocsComponentsContextMenuKo context_menu = TranslationsDocsComponentsContextMenuKo.internal(_root);
	late final TranslationsDocsComponentsDatePickerKo date_picker = TranslationsDocsComponentsDatePickerKo.internal(_root);
	late final TranslationsDocsComponentsDialogKo dialog = TranslationsDocsComponentsDialogKo.internal(_root);
	late final TranslationsDocsComponentsDividerKo divider = TranslationsDocsComponentsDividerKo.internal(_root);
	late final TranslationsDocsComponentsDotIndicatorKo dot_indicator = TranslationsDocsComponentsDotIndicatorKo.internal(_root);
	late final TranslationsDocsComponentsDrawerKo drawer = TranslationsDocsComponentsDrawerKo.internal(_root);
	late final TranslationsDocsComponentsDropdownMenuKo dropdown_menu = TranslationsDocsComponentsDropdownMenuKo.internal(_root);
	late final TranslationsDocsComponentsExpandableSidebarKo expandable_sidebar = TranslationsDocsComponentsExpandableSidebarKo.internal(_root);
	late final TranslationsDocsComponentsFormKo form = TranslationsDocsComponentsFormKo.internal(_root);
	late final TranslationsDocsComponentsFormattedInputKo formatted_input = TranslationsDocsComponentsFormattedInputKo.internal(_root);
	late final TranslationsDocsComponentsHoverCardKo hover_card = TranslationsDocsComponentsHoverCardKo.internal(_root);
	late final TranslationsDocsComponentsInputKo input = TranslationsDocsComponentsInputKo.internal(_root);
	late final TranslationsDocsComponentsInputOtpKo input_otp = TranslationsDocsComponentsInputOtpKo.internal(_root);
	late final TranslationsDocsComponentsItemPickerKo item_picker = TranslationsDocsComponentsItemPickerKo.internal(_root);
	late final TranslationsDocsComponentsKeyboardDisplayKo keyboard_display = TranslationsDocsComponentsKeyboardDisplayKo.internal(_root);
	late final TranslationsDocsComponentsLinearProgressKo linear_progress = TranslationsDocsComponentsLinearProgressKo.internal(_root);
	late final TranslationsDocsComponentsMaterialKo material = TranslationsDocsComponentsMaterialKo.internal(_root);
	late final TranslationsDocsComponentsMenubarKo menubar = TranslationsDocsComponentsMenubarKo.internal(_root);
	late final TranslationsDocsComponentsMultiselectKo multiselect = TranslationsDocsComponentsMultiselectKo.internal(_root);
	late final TranslationsDocsComponentsNavigationBarKo navigation_bar = TranslationsDocsComponentsNavigationBarKo.internal(_root);
	late final TranslationsDocsComponentsNavigationMenuKo navigation_menu = TranslationsDocsComponentsNavigationMenuKo.internal(_root);
	late final TranslationsDocsComponentsNavigationRailKo navigation_rail = TranslationsDocsComponentsNavigationRailKo.internal(_root);
	late final TranslationsDocsComponentsNavigationSidebarKo navigation_sidebar = TranslationsDocsComponentsNavigationSidebarKo.internal(_root);
	late final TranslationsDocsComponentsNumberInputKo number_input = TranslationsDocsComponentsNumberInputKo.internal(_root);
	late final TranslationsDocsComponentsNumberTickerKo number_ticker = TranslationsDocsComponentsNumberTickerKo.internal(_root);
	late final TranslationsDocsComponentsOverflowMarqueeKo overflow_marquee = TranslationsDocsComponentsOverflowMarqueeKo.internal(_root);
	late final TranslationsDocsComponentsPaginationKo pagination = TranslationsDocsComponentsPaginationKo.internal(_root);
	late final TranslationsDocsComponentsPhoneInputKo phone_input = TranslationsDocsComponentsPhoneInputKo.internal(_root);
	late final TranslationsDocsComponentsPopoverKo popover = TranslationsDocsComponentsPopoverKo.internal(_root);
	late final TranslationsDocsComponentsProgressKo progress = TranslationsDocsComponentsProgressKo.internal(_root);
	late final TranslationsDocsComponentsRadioCardKo radio_card = TranslationsDocsComponentsRadioCardKo.internal(_root);
	late final TranslationsDocsComponentsRadioGroupKo radio_group = TranslationsDocsComponentsRadioGroupKo.internal(_root);
	late final TranslationsDocsComponentsRefreshTriggerKo refresh_trigger = TranslationsDocsComponentsRefreshTriggerKo.internal(_root);
	late final TranslationsDocsComponentsRepeatedAnimationBuilderKo repeated_animation_builder = TranslationsDocsComponentsRepeatedAnimationBuilderKo.internal(_root);
	late final TranslationsDocsComponentsResizableKo resizable = TranslationsDocsComponentsResizableKo.internal(_root);
	late final TranslationsDocsComponentsScaffoldKo scaffold = TranslationsDocsComponentsScaffoldKo.internal(_root);
	late final TranslationsDocsComponentsSelectKo select = TranslationsDocsComponentsSelectKo.internal(_root);
	late final TranslationsDocsComponentsSheetKo sheet = TranslationsDocsComponentsSheetKo.internal(_root);
	late final TranslationsDocsComponentsSkeletonKo skeleton = TranslationsDocsComponentsSkeletonKo.internal(_root);
	late final TranslationsDocsComponentsSliderKo slider = TranslationsDocsComponentsSliderKo.internal(_root);
	late final TranslationsDocsComponentsSortableKo sortable = TranslationsDocsComponentsSortableKo.internal(_root);
	late final TranslationsDocsComponentsStarRatingKo star_rating = TranslationsDocsComponentsStarRatingKo.internal(_root);
	late final TranslationsDocsComponentsStepperKo stepper = TranslationsDocsComponentsStepperKo.internal(_root);
	late final TranslationsDocsComponentsStepsKo steps = TranslationsDocsComponentsStepsKo.internal(_root);
	late final TranslationsDocsComponentsSwiperKo swiper = TranslationsDocsComponentsSwiperKo.internal(_root);
	late final TranslationsDocsComponentsKSwitchKo k_switch = TranslationsDocsComponentsKSwitchKo.internal(_root);
	late final TranslationsDocsComponentsSwitcherKo switcher = TranslationsDocsComponentsSwitcherKo.internal(_root);
	late final TranslationsDocsComponentsTabContainerKo tab_container = TranslationsDocsComponentsTabContainerKo.internal(_root);
	late final TranslationsDocsComponentsTabListKo tab_list = TranslationsDocsComponentsTabListKo.internal(_root);
	late final TranslationsDocsComponentsTabPaneKo tab_pane = TranslationsDocsComponentsTabPaneKo.internal(_root);
	late final TranslationsDocsComponentsTableKo table = TranslationsDocsComponentsTableKo.internal(_root);
	late final TranslationsDocsComponentsTabsKo tabs = TranslationsDocsComponentsTabsKo.internal(_root);
	late final TranslationsDocsComponentsTextAreaKo text_area = TranslationsDocsComponentsTextAreaKo.internal(_root);
	late final TranslationsDocsComponentsTimePickerKo time_picker = TranslationsDocsComponentsTimePickerKo.internal(_root);
	late final TranslationsDocsComponentsTimelineKo timeline = TranslationsDocsComponentsTimelineKo.internal(_root);
	late final TranslationsDocsComponentsTimelineAnimationKo timeline_animation = TranslationsDocsComponentsTimelineAnimationKo.internal(_root);
	late final TranslationsDocsComponentsToastKo toast = TranslationsDocsComponentsToastKo.internal(_root);
	late final TranslationsDocsComponentsToggleKo toggle = TranslationsDocsComponentsToggleKo.internal(_root);
	late final TranslationsDocsComponentsTooltipKo tooltip = TranslationsDocsComponentsTooltipKo.internal(_root);
	late final TranslationsDocsComponentsTrackerKo tracker = TranslationsDocsComponentsTrackerKo.internal(_root);
	late final TranslationsDocsComponentsTreeKo tree = TranslationsDocsComponentsTreeKo.internal(_root);
	late final TranslationsDocsComponentsWindowKo window = TranslationsDocsComponentsWindowKo.internal(_root);
}

// Path: docs.pages.introduction
class TranslationsDocsPagesIntroductionKo {
	TranslationsDocsPagesIntroductionKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '소개'
	String get title => '소개';

	/// ko: 'coui_flutter 시작하기'
	String get description => 'coui_flutter 시작하기';

	/// ko: 'Coui/UI의 아름답게 디자인된 컴포넌트를 이제 Flutter에서 사용할 수 있습니다.'
	String get lead => 'Coui/UI의 아름답게 디자인된 컴포넌트를 이제 Flutter에서 사용할 수 있습니다.';

	/// ko: 'coui_flutter는 Flutter 데스크톱 및 웹 애플리케이션을 위해 특별히 설계된 다양하고 포괄적인 UI 컴포넌트 세트입니다. 크로스 플랫폼 앱 구축을 위한 Flutter의 인기가 높아짐에 따라 데스크톱 및 웹 인터페이스의 고유한 디자인 요구 사항을 강조하는 툴킷의 필요성을 인식했습니다.'
	String get welcome_paragraph_1 => 'coui_flutter는 Flutter 데스크톱 및 웹 애플리케이션을 위해 특별히 설계된 다양하고 포괄적인 UI 컴포넌트 세트입니다. 크로스 플랫폼 앱 구축을 위한 Flutter의 인기가 높아짐에 따라 데스크톱 및 웹 인터페이스의 고유한 디자인 요구 사항을 강조하는 툴킷의 필요성을 인식했습니다.';

	/// ko: '이 패키지는 현대적인 데스크톱 및 웹 디자인 원칙에 부합하는 광범위한 사용자 정의 가능하고 반응형 컴포넌트를 제공합니다. 정교한 비즈니스 애플리케이션, 세련된 대시보드 또는 생산성 도구를 구축하든 우리의 컴포넌트는 전문적이고 세련된 UI를 빠르고 효율적으로 만드는 데 도움이 되도록 설계되었습니다.'
	String get welcome_paragraph_2 => '이 패키지는 현대적인 데스크톱 및 웹 디자인 원칙에 부합하는 광범위한 사용자 정의 가능하고 반응형 컴포넌트를 제공합니다. 정교한 비즈니스 애플리케이션, 세련된 대시보드 또는 생산성 도구를 구축하든 우리의 컴포넌트는 전문적이고 세련된 UI를 빠르고 효율적으로 만드는 데 도움이 되도록 설계되었습니다.';

	/// ko: '주요 기능'
	String get features => '주요 기능';

	late final TranslationsDocsPagesIntroductionFeaturesListKo features_list = TranslationsDocsPagesIntroductionFeaturesListKo.internal(_root);

	/// ko: '참고사항'
	String get notes => '참고사항';

	/// ko: '이 패키지는 아직 개발 중이며 향후 변경 사항이 있을 수 있습니다. 프로덕션에서 이 패키지를 사용할 때는 주의하십시오.'
	String get notes_paragraph_1 => '이 패키지는 아직 개발 중이며 향후 변경 사항이 있을 수 있습니다. 프로덕션에서 이 패키지를 사용할 때는 주의하십시오.';

	/// ko: '이 패키지는 Coui/UI와 제휴하지 않습니다. 이 패키지는 커뮤니티 주도 프로젝트입니다.'
	String get notes_paragraph_2 => '이 패키지는 Coui/UI와 제휴하지 않습니다. 이 패키지는 커뮤니티 주도 프로젝트입니다.';

	/// ko: '자주 묻는 질문'
	String get faq => '자주 묻는 질문';

	/// ko: 'GoRouter를 지원하나요?'
	String get faq_gorouter_q => 'GoRouter를 지원하나요?';

	/// ko: '네, 지원합니다. coui_flutter와 함께 GoRouter를 사용할 수 있습니다.'
	String get faq_gorouter_a => '네, 지원합니다. coui_flutter와 함께 GoRouter를 사용할 수 있습니다.';

	/// ko: '내 프로젝트에서 사용할 수 있나요?'
	String get faq_usage_q => '내 프로젝트에서 사용할 수 있나요?';

	/// ko: '네! 개인 및 상업 프로젝트에 무료로 사용할 수 있습니다. 저작자 표시 불필요.'
	String get faq_usage_a => '네! 개인 및 상업 프로젝트에 무료로 사용할 수 있습니다. 저작자 표시 불필요.';

	/// ko: 'Material/Cupertino 위젯과 함께 사용할 수 있나요?'
	String get faq_material_q => 'Material/Cupertino 위젯과 함께 사용할 수 있나요?';

	/// ko: '물론입니다!'
	String get faq_material_a_1 => '물론입니다!';

	/// ko: '이 페이지를 참조하세요!'
	String get faq_material_a_2 => '이 페이지를 참조하세요!';

	/// ko: '어떤 스타일을 사용할지 설정할 수 있나요? (Default/New York)'
	String get faq_style_q => '어떤 스타일을 사용할지 설정할 수 있나요? (Default/New York)';

	/// ko: '안타깝게도 할 수 없습니다. 이 패키지는 New York 스타일만 지원합니다. 하지만 Coui/UI의 기본 스타일을 원한다면'
	String get faq_style_a_1 => '안타깝게도 할 수 없습니다. 이 패키지는 New York 스타일만 지원합니다. 하지만 Coui/UI의 기본 스타일을 원한다면';

	/// ko: '이 패키지'
	String get faq_style_a_2 => '이 패키지';

	/// ko: '를 추천합니다. 제작자:'
	String get faq_style_a_3 => '를 추천합니다. 제작자:';

	/// ko: '링크'
	String get links => '링크';

	/// ko: 'Github: '
	String get link_github => 'Github: ';

	/// ko: 'pub.dev: '
	String get link_pubdev => 'pub.dev: ';

	/// ko: 'Discord: '
	String get link_discord => 'Discord: ';
}

// Path: docs.pages.installation
class TranslationsDocsPagesInstallationKo {
	TranslationsDocsPagesInstallationKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '설치'
	String get title => '설치';

	/// ko: '프로젝트에 coui_flutter 설치 및 구성하기'
	String get description => '프로젝트에 coui_flutter 설치 및 구성하기';

	/// ko: '안정 버전'
	String get stable_version => '안정 버전';

	/// ko: '실험 버전'
	String get experimental_version => '실험 버전';

	/// ko: '새 Flutter 프로젝트 생성'
	String get step1_title => '새 Flutter 프로젝트 생성';

	/// ko: '다음 명령어를 사용하여 새 Flutter 프로젝트를 생성하세요:'
	String get step1_content => '다음 명령어를 사용하여 새 Flutter 프로젝트를 생성하세요:';

	/// ko: '의존성 추가'
	String get step2_title => '의존성 추가';

	/// ko: '다음으로, 프로젝트에 coui_flutter 의존성을 추가하세요.'
	String get step2_content => '다음으로, 프로젝트에 coui_flutter 의존성을 추가하세요.';

	/// ko: '패키지 가져오기'
	String get step3_title => '패키지 가져오기';

	/// ko: '이제 Dart 코드에서 패키지를 가져올 수 있습니다.'
	String get step3_content => '이제 Dart 코드에서 패키지를 가져올 수 있습니다.';

	/// ko: 'CouiApp 위젯 추가'
	String get step4_title => 'CouiApp 위젯 추가';

	/// ko: 'main 함수에 CouiApp 위젯을 추가하세요.'
	String get step4_content => 'main 함수에 CouiApp 위젯을 추가하세요.';

	/// ko: '앱 실행'
	String get step5_title => '앱 실행';

	/// ko: '다음 명령어를 사용하여 앱을 실행하세요:'
	String get step5_content => '다음 명령어를 사용하여 앱을 실행하세요:';

	/// ko: '실험 버전은 GitHub에서 사용할 수 있습니다.'
	String get experimental_intro => '실험 버전은 GitHub에서 사용할 수 있습니다.';

	/// ko: '실험 버전을 사용하려면 pubspec.yaml 파일에서 버전 번호 대신 git을 사용하세요:'
	String get experimental_usage => '실험 버전을 사용하려면 pubspec.yaml 파일에서 버전 번호 대신 git을 사용하세요:';

	/// ko: '참조: '
	String get see_page => '참조: ';

	/// ko: '이 페이지'
	String get this_page => '이 페이지';

	/// ko: ' 자세한 정보.'
	String get for_more_info => ' 자세한 정보.';

	/// ko: '경고'
	String get warning_title => '경고';

	/// ko: '실험 버전에는 호환성을 깨는 변경 사항이 포함될 수 있으며 프로덕션 사용을 권장하지 않습니다. 이 버전은 테스트 및 개발 목적으로만 사용됩니다.'
	String get warning_content => '실험 버전에는 호환성을 깨는 변경 사항이 포함될 수 있으며 프로덕션 사용을 권장하지 않습니다. 이 버전은 테스트 및 개발 목적으로만 사용됩니다.';
}

// Path: docs.pages.theme
class TranslationsDocsPagesThemeKo {
	TranslationsDocsPagesThemeKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '테마'
	String get title => '테마';

	/// ko: '앱의 모양과 느낌을 커스터마이징하세요'
	String get description => '앱의 모양과 느낌을 커스터마이징하세요';

	/// ko: '사용자 정의 색 구성표'
	String get custom_color_scheme => '사용자 정의 색 구성표';

	/// ko: '사용자 정의 색 구성표를 사용하여 앱의 모양과 느낌을 커스터마이징할 수 있습니다.'
	String get custom_color_scheme_desc => '사용자 정의 색 구성표를 사용하여 앱의 모양과 느낌을 커스터마이징할 수 있습니다.';

	/// ko: '사전 제작된 색 구성표'
	String get premade_color_schemes => '사전 제작된 색 구성표';

	/// ko: '사전 제작된 색 구성표를 사용하여 앱의 모양과 느낌을 커스터마이징할 수 있습니다.'
	String get premade_color_schemes_desc => '사전 제작된 색 구성표를 사용하여 앱의 모양과 느낌을 커스터마이징할 수 있습니다.';

	/// ko: '반경'
	String get radius => '반경';

	/// ko: '반경을 변경하여 앱이 얼마나 둥글게 보이는지 커스터마이징할 수 있습니다.'
	String get radius_desc => '반경을 변경하여 앱이 얼마나 둥글게 보이는지 커스터마이징할 수 있습니다.';

	/// ko: '크기 조정'
	String get scaling => '크기 조정';

	/// ko: '크기 조정을 변경하여 coui_flutter 컴포넌트의 스케일을 커스터마이징할 수 있습니다.'
	String get scaling_desc => '크기 조정을 변경하여 coui_flutter 컴포넌트의 스케일을 커스터마이징할 수 있습니다.';

	/// ko: '전체 앱을 확대/축소하지 않습니다. coui_flutter 컴포넌트만 영향을 받습니다.'
	String get scaling_alert => '전체 앱을 확대/축소하지 않습니다. coui_flutter 컴포넌트만 영향을 받습니다.';

	/// ko: '표면 불투명도'
	String get surface_opacity => '표면 불투명도';

	/// ko: '표면 불투명도를 변경하여 표면의 불투명도를 커스터마이징할 수 있습니다.'
	String get surface_opacity_desc => '표면 불투명도를 변경하여 표면의 불투명도를 커스터마이징할 수 있습니다.';

	/// ko: '표면 블러'
	String get surface_blur => '표면 블러';

	/// ko: '표면 블러를 변경하여 표면의 블러를 커스터마이징할 수 있습니다.'
	String get surface_blur_desc => '표면 블러를 변경하여 표면의 블러를 커스터마이징할 수 있습니다.';

	/// ko: '코드'
	String get code => '코드';

	/// ko: '다음 코드를 사용하여 색 구성표를 적용하세요.'
	String get code_desc => '다음 코드를 사용하여 색 구성표를 적용하세요.';
}

// Path: docs.pages.typography
class TranslationsDocsPagesTypographyKo {
	TranslationsDocsPagesTypographyKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '타이포그래피'
	String get title => '타이포그래피';

	/// ko: '디자인과 콘텐츠를 가능한 한 명확하고 효율적으로 표현하기 위해 타이포그래피를 사용하세요.'
	String get description => '디자인과 콘텐츠를 가능한 한 명확하고 효율적으로 표현하기 위해 타이포그래피를 사용하세요.';

	/// ko: '헤드라인 1'
	String get headline1 => '헤드라인 1';

	/// ko: '헤드라인 2'
	String get headline2 => '헤드라인 2';

	/// ko: '헤드라인 3'
	String get headline3 => '헤드라인 3';

	/// ko: '헤드라인 4'
	String get headline4 => '헤드라인 4';

	/// ko: '단락'
	String get paragraph => '단락';

	/// ko: '인용구'
	String get blockquote => '인용구';

	/// ko: '목록'
	String get list => '목록';

	/// ko: '인라인 코드'
	String get inline_code => '인라인 코드';

	/// ko: '리드'
	String get lead => '리드';

	/// ko: '큰 텍스트'
	String get large_text => '큰 텍스트';

	/// ko: '작은 텍스트'
	String get small_text => '작은 텍스트';

	/// ko: '회색 텍스트'
	String get muted_text => '회색 텍스트';

	/// ko: 'Sans'
	String get sans => 'Sans';

	/// ko: 'Mono'
	String get mono => 'Mono';

	/// ko: '아주 작은'
	String get extra_small => '아주 작은';

	/// ko: '작은'
	String get small => '작은';

	/// ko: '기본'
	String get base => '기본';

	/// ko: '큰'
	String get large => '큰';

	/// ko: '아주 큰'
	String get extra_large => '아주 큰';

	/// ko: '아주 2배 큰'
	String get extra_2x_large => '아주 2배 큰';

	/// ko: '아주 3배 큰'
	String get extra_3x_large => '아주 3배 큰';

	/// ko: '아주 4배 큰'
	String get extra_4x_large => '아주 4배 큰';

	/// ko: '아주 5배 큰'
	String get extra_5x_large => '아주 5배 큰';

	/// ko: '아주 6배 큰'
	String get extra_6x_large => '아주 6배 큰';

	/// ko: '아주 7배 큰'
	String get extra_7x_large => '아주 7배 큰';

	/// ko: '아주 8배 큰'
	String get extra_8x_large => '아주 8배 큰';

	/// ko: '아주 9배 큰'
	String get extra_9x_large => '아주 9배 큰';

	/// ko: '얇은'
	String get thin => '얇은';

	/// ko: '아주 가벼운'
	String get extra_light => '아주 가벼운';

	/// ko: '가벼운'
	String get light => '가벼운';

	/// ko: '일반'
	String get normal => '일반';

	/// ko: '중간'
	String get medium => '중간';

	/// ko: '세미 볼드'
	String get semi_bold => '세미 볼드';

	/// ko: '볼드'
	String get bold => '볼드';

	/// ko: '아주 볼드'
	String get extra_bold => '아주 볼드';

	/// ko: '블랙'
	String get black => '블랙';

	/// ko: '이탤릭'
	String get italic => '이탤릭';
}

// Path: docs.pages.layout
class TranslationsDocsPagesLayoutKo {
	TranslationsDocsPagesLayoutKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '레이아웃'
	String get title => '레이아웃';

	/// ko: 'Coui Flutter의 레이아웃 가이드'
	String get description => 'Coui Flutter의 레이아웃 가이드';

	/// ko: '패딩'
	String get padding => '패딩';

	/// ko: '마진'
	String get margin => '마진';

	/// ko: '센터'
	String get center => '센터';

	/// ko: '간격이 있는 Column'
	String get gapped_column => '간격이 있는 Column';

	/// ko: '간격이 있는 Row'
	String get gapped_row => '간격이 있는 Row';

	/// ko: '구분된 Column'
	String get separated_column => '구분된 Column';

	/// ko: '구분된 Row'
	String get separated_row => '구분된 Row';

	/// ko: '기본 레이아웃'
	String get basic_layout => '기본 레이아웃';
}

// Path: docs.pages.web_preloader
class TranslationsDocsPagesWebPreloaderKo {
	TranslationsDocsPagesWebPreloaderKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '웹 프리로더'
	String get title => '웹 프리로더';

	/// ko: 'Flutter가 웹 애플리케이션을 로드하는 방법을 커스터마이징하세요'
	String get description => 'Flutter가 웹 애플리케이션을 로드하는 방법을 커스터마이징하세요';

	/// ko: '웹 디렉토리 생성'
	String get step1_title => '웹 디렉토리 생성';

	/// ko: '웹 디렉토리가 없다면 생성하세요.'
	String get step1_content => '웹 디렉토리가 없다면 생성하세요.';

	/// ko: '* 레거시 Flutter 웹을 사용 중이라면 위 명령어를 사용하여 업그레이드해야 합니다. '
	String get step1_note => '* 레거시 Flutter 웹을 사용 중이라면 위 명령어를 사용하여 업그레이드해야 합니다. ';

	/// ko: '자세한 정보는 여기를 클릭하세요.'
	String get step1_button => '자세한 정보는 여기를 클릭하세요.';

	/// ko: '스크립트 추가'
	String get step2_title => '스크립트 추가';

	/// ko: '다음으로, 다음 사전 제작된 프리로더 중 하나를 선택하고 복사하세요:'
	String get step2_content => '다음으로, 다음 사전 제작된 프리로더 중 하나를 선택하고 복사하세요:';

	/// ko: '표준 프리로더'
	String get step2_standard => '표준 프리로더';

	/// ko: '스크립트 붙여넣기'
	String get step3_title => '스크립트 붙여넣기';

	/// ko: '당신의 '
	String get step3_content_1 => '당신의 ';

	/// ko: ' 파일을 열고 '
	String get step3_content_2 => ' 파일을 열고 ';

	/// ko: ' 태그 안에 스크립트를 붙여넣으세요.'
	String get step3_content_3 => ' 태그 안에 스크립트를 붙여넣으세요.';

	/// ko: '예를 들어:'
	String get step3_example => '예를 들어:';

	/// ko: '앱 실행'
	String get step4_title => '앱 실행';

	/// ko: '다음 명령어를 사용하여 앱을 실행하세요:'
	String get step4_content => '다음 명령어를 사용하여 앱을 실행하세요:';

	/// ko: '기여하기'
	String get alert_title => '기여하기';

	/// ko: '공유하고 싶은 프리로더가 있다면 '
	String get alert_content_1 => '공유하고 싶은 프리로더가 있다면 ';

	/// ko: 'web_loaders'
	String get alert_button => 'web_loaders';

	/// ko: ' 디렉토리에 풀 리퀘스트를 생성하세요.'
	String get alert_content_2 => ' 디렉토리에 풀 리퀘스트를 생성하세요.';
}

// Path: docs.pages.components_list
class TranslationsDocsPagesComponentsListKo {
	TranslationsDocsPagesComponentsListKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '컴포넌트'
	String get title => '컴포넌트';

	/// ko: 'Coui/UI의 아름답게 디자인된 컴포넌트가 이제 Flutter에서 사용 가능합니다.'
	String get description => 'Coui/UI의 아름답게 디자인된 컴포넌트가 이제 Flutter에서 사용 가능합니다.';

	/// ko: '작업 중'
	String get work_in_progress => '작업 중';

	/// ko: '애니메이션'
	String get animation => '애니메이션';

	/// ko: '공개'
	String get disclosure => '공개';

	/// ko: '피드백'
	String get feedback => '피드백';

	/// ko: '양식'
	String get forms => '양식';

	/// ko: '레이아웃'
	String get layout => '레이아웃';

	/// ko: '네비게이션'
	String get navigation => '네비게이션';

	/// ko: '표면'
	String get surfaces => '표면';

	/// ko: '데이터 표시'
	String get data_display => '데이터 표시';

	/// ko: '유틸리티'
	String get utilities => '유틸리티';
}

// Path: docs.pages.icons
class TranslationsDocsPagesIconsKo {
	TranslationsDocsPagesIconsKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '아이콘'
	String get title => '아이콘';

	/// ko: '아이콘 시스템'
	String get description => '아이콘 시스템';

	/// ko: '이 아이콘을 표시하려면 다음 코드를 사용하세요:'
	String get use_this_code => '이 아이콘을 표시하려면 다음 코드를 사용하세요:';

	/// ko: '아이콘 검색'
	String get search_icons => '아이콘 검색';

	/// ko: 'Radix 아이콘'
	String get radix_icons => 'Radix 아이콘';

	/// ko: 'Bootstrap 아이콘'
	String get bootstrap_icons => 'Bootstrap 아이콘';

	/// ko: 'Lucide 아이콘'
	String get lucide_icons => 'Lucide 아이콘';

	/// ko: 'Hero 아이콘'
	String get hero_icons => 'Hero 아이콘';
}

// Path: docs.pages.colors
class TranslationsDocsPagesColorsKo {
	TranslationsDocsPagesColorsKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '색상'
	String get title => '색상';

	/// ko: '색상 팔레트'
	String get description => '색상 팔레트';

	/// ko: '이 색상을 표시하려면 다음 코드를 사용하세요:'
	String get use_this_code => '이 색상을 표시하려면 다음 코드를 사용하세요:';

	/// ko: 'Color 및 ColorShades/ColorSwatch 상수'
	String get color_and_colorshades => 'Color 및 ColorShades/ColorSwatch 상수';

	/// ko: '미리 정의된 색상'
	String get predefined_colors => '미리 정의된 색상';

	/// ko: '색상 생성'
	String get generate_color => '색상 생성';

	/// ko: '색조 이동'
	String get hue_shift => '색조 이동';

	/// ko: '채도 증가 단계'
	String get saturation_step_up => '채도 증가 단계';

	/// ko: '채도 감소 단계'
	String get saturation_step_down => '채도 감소 단계';

	/// ko: '밝기 증가 단계'
	String get lightness_step_up => '밝기 증가 단계';

	/// ko: '밝기 감소 단계'
	String get lightness_step_down => '밝기 감소 단계';

	/// ko: '취소'
	String get cancel => '취소';

	/// ko: '옵션 초기화'
	String get reset_options => '옵션 초기화';

	/// ko: '옵션을 초기화하시겠습니까?'
	String get reset_confirmation => '옵션을 초기화하시겠습니까?';
}

// Path: docs.pages.external
class TranslationsDocsPagesExternalKo {
	TranslationsDocsPagesExternalKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'Material/Cupertino'
	String get title => 'Material/Cupertino';

	/// ko: 'Flutter 기본 위젯'
	String get description => 'Flutter 기본 위젯';
}

// Path: docs.pages.state
class TranslationsDocsPagesStateKo {
	TranslationsDocsPagesStateKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '상태 관리'
	String get title => '상태 관리';

	/// ko: 'coui_flutter에서 상태를 관리하는 포괄적인 가이드입니다.'
	String get description => 'coui_flutter에서 상태를 관리하는 포괄적인 가이드입니다.';

	/// ko: 'Flutter에서는 모든 것이 위젯이며, 데이터가 저장되는 곳도 마찬가지입니다.'
	String get intro_1 => 'Flutter에서는 모든 것이 위젯이며, 데이터가 저장되는 곳도 마찬가지입니다.';

	/// ko: '내부적으로 coui_flutter는 자체 상태 관리 시스템을 가지고 있습니다. 이미 상태 관리 시스템을 사용하고 있다면 coui_flutter와 함께 계속 사용할 수 있습니다.'
	String get intro_2 => '내부적으로 coui_flutter는 자체 상태 관리 시스템을 가지고 있습니다. 이미 상태 관리 시스템을 사용하고 있다면 coui_flutter와 함께 계속 사용할 수 있습니다.';

	/// ko: '자식에게 데이터 전달하기'
	String get passing_data_to_children => '자식에게 데이터 전달하기';

	/// ko: 'Data 위젯을 사용하여 자식에게 데이터를 전달할 수 있습니다. 데이터에 발생하는 모든 변경 사항은 자식을 다시 빌드하게 합니다.'
	String get passing_data_desc => 'Data 위젯을 사용하여 자식에게 데이터를 전달할 수 있습니다. 데이터에 발생하는 모든 변경 사항은 자식을 다시 빌드하게 합니다.';

	/// ko: '리빌드 횟수의 차이를 눈치채셨나요?'
	String get rebuild_difference_title => '리빌드 횟수의 차이를 눈치채셨나요?';

	/// ko: 'MostInnerWidget은 데이터가 변경될 때 다시 빌드되지만 InnerWidget은 그렇지 않습니다. 이는 InnerWidget이 데이터를 수신하지 않기 때문입니다.'
	String get rebuild_difference_content => 'MostInnerWidget은 데이터가 변경될 때 다시 빌드되지만 InnerWidget은 그렇지 않습니다. 이는 InnerWidget이 데이터를 수신하지 않기 때문입니다.';

	/// ko: '데이터 경계 설정'
	String get setting_data_boundary => '데이터 경계 설정';

	/// ko: '자식이 데이터에 액세스할 수 없도록 경계를 설정할 수 있습니다.'
	String get setting_data_boundary_desc => '자식이 데이터에 액세스할 수 없도록 경계를 설정할 수 있습니다.';

	/// ko: 'Data.maybeOf/Data.of vs Data.maybeFind/Data.find'
	String get data_methods_vs => 'Data.maybeOf/Data.of vs Data.maybeFind/Data.find';

	/// ko: ' 및 '
	String get data_methods_desc_1 => ' 및 ';

	/// ko: '은(는) 데이터를 수신하고 데이터가 변경될 때 위젯을 다시 빌드합니다. 반면에 '
	String get data_methods_desc_2 => '은(는) 데이터를 수신하고 데이터가 변경될 때 위젯을 다시 빌드합니다. 반면에 ';

	/// ko: '은(는) 데이터를 수신하지 않고 데이터만 반환합니다.'
	String get data_methods_desc_3 => '은(는) 데이터를 수신하지 않고 데이터만 반환합니다.';

	/// ko: '은(는) onPressed, onLongPressed 등 메서드가 한 번 호출되는 곳에서 사용하기 좋습니다. '
	String get data_find_usage => '은(는) onPressed, onLongPressed 등 메서드가 한 번 호출되는 곳에서 사용하기 좋습니다. ';

	/// ko: '은(는) 데이터가 변경될 때 위젯을 다시 빌드해야 하는 build 메서드 내에서 사용하기 좋습니다.'
	String get data_of_usage => '은(는) 데이터가 변경될 때 위젯을 다시 빌드해야 하는 build 메서드 내에서 사용하기 좋습니다.';

	/// ko: '자식으로부터 데이터 가져오기'
	String get getting_data_from_child => '자식으로부터 데이터 가져오기';

	/// ko: ' 메서드를 사용하여 자식으로부터 데이터를 가져올 수 있습니다. 이 메서드는 데이터에 발생하는 변경 사항을 수신하지 않습니다. '
	String get getting_data_desc_1 => ' 메서드를 사용하여 자식으로부터 데이터를 가져올 수 있습니다. 이 메서드는 데이터에 발생하는 변경 사항을 수신하지 않습니다. ';

	/// ko: '자식 데이터를 수신하면 무한 리빌드 루프가 발생할 수 있습니다. 데이터를 수신해야 하는 경우 부모 위젯으로 이동하세요.'
	String get getting_data_desc_2 => '자식 데이터를 수신하면 무한 리빌드 루프가 발생할 수 있습니다. 데이터를 수신해야 하는 경우 부모 위젯으로 이동하세요.';

	/// ko: '루트 데이터를 눈치채셨나요?'
	String get root_data_title => '루트 데이터를 눈치채셨나요?';

	/// ko: '왼쪽의 가장 안쪽 데이터의 데이터를 사용합니다. 부모는 첫 번째로 연결된 자식에서만 데이터를 가져올 수 있기 때문입니다.'
	String get root_data_content => '왼쪽의 가장 안쪽 데이터의 데이터를 사용합니다. 부모는 첫 번째로 연결된 자식에서만 데이터를 가져올 수 있기 때문입니다.';

	/// ko: 'DataMessenger 경계 설정'
	String get setting_messenger_boundary => 'DataMessenger 경계 설정';

	/// ko: '특정 부모로부터 자식 데이터를 얻을 수 없도록 경계를 설정할 수 있습니다.'
	String get setting_messenger_boundary_desc => '특정 부모로부터 자식 데이터를 얻을 수 없도록 경계를 설정할 수 있습니다.';

	/// ko: 'MultiData 위젯'
	String get multidata_widget => 'MultiData 위젯';

	/// ko: 'MultiData 위젯을 사용하면 자식에게 여러 데이터를 전달할 수 있습니다. 다음 예제를 살펴보세요:'
	String get multidata_desc => 'MultiData 위젯을 사용하면 자식에게 여러 데이터를 전달할 수 있습니다. 다음 예제를 살펴보세요:';

	/// ko: 'MultiData 위젯을 사용하여 중첩을 피할 수 있습니다.'
	String get multidata_avoid_nesting => 'MultiData 위젯을 사용하여 중첩을 피할 수 있습니다.';

	/// ko: '예제'
	String get example => '예제';

	/// ko: '컨트롤러로 상태 전달하기'
	String get passing_state_as_controller => '컨트롤러로 상태 전달하기';

	/// ko: '상태를 컨트롤러로 자식에게 전달할 수 있습니다. 이렇게 하면 자식 위젯에서 부모 위젯의 메서드를 호출할 수 있습니다.'
	String get passing_state_controller_desc => '상태를 컨트롤러로 자식에게 전달할 수 있습니다. 이렇게 하면 자식 위젯에서 부모 위젯의 메서드를 호출할 수 있습니다.';

	/// ko: 'DataBuilder'
	String get databuilder => 'DataBuilder';

	/// ko: 'DataBuilder 위젯을 사용하여 데이터가 변경될 때 위젯을 다시 빌드할 수 있습니다. 이는 전체 위젯을 다시 빌드하는 것을 피합니다.'
	String get databuilder_desc => 'DataBuilder 위젯을 사용하여 데이터가 변경될 때 위젯을 다시 빌드할 수 있습니다. 이는 전체 위젯을 다시 빌드하는 것을 피합니다.';

	/// ko: 'DataNotifier'
	String get datanotifier => 'DataNotifier';

	/// ko: 'DataNotifier를 사용하면 ValueListenable에서 자식에게 값을 전달할 수 있습니다.'
	String get datanotifier_desc => 'DataNotifier를 사용하면 ValueListenable에서 자식에게 값을 전달할 수 있습니다.';

	/// ko: 'MultiData를 사용한 예제'
	String get example_with_multidata => 'MultiData를 사용한 예제';

	/// ko: '객체를 데이터로 전달하기'
	String get passing_object_as_data => '객체를 데이터로 전달하기';

	/// ko: '객체를 데이터로 전달할 때 고려해야 할 몇 가지 사항이 있습니다:'
	String get passing_object_desc => '객체를 데이터로 전달할 때 고려해야 할 몇 가지 사항이 있습니다:';

	/// ko: '1. == 및 hashCode 재정의'
	String get override_equals_hashcode => '1. == 및 hashCode 재정의';

	/// ko: '이전 객체가 새 객체와 같지 않을 때 자식에게 알림이 전송됩니다. == 및 hashCode를 재정의하지 않으면 필드 값이 동일하더라도 객체가 인스턴스화될 때마다 항상 다른 것으로 간주됩니다.'
	String get override_equals_desc => '이전 객체가 새 객체와 같지 않을 때 자식에게 알림이 전송됩니다. == 및 hashCode를 재정의하지 않으면 필드 값이 동일하더라도 객체가 인스턴스화될 때마다 항상 다른 것으로 간주됩니다.';

	/// ko: '2. DistinctData 사용'
	String get use_distinctdata => '2. DistinctData 사용';

	/// ko: 'DistinctData는 특정 필드가 변경될 때 자식에게 알릴 수 있는 mixin입니다.'
	String get use_distinctdata_desc => 'DistinctData는 특정 필드가 변경될 때 자식에게 알릴 수 있는 mixin입니다.';

	/// ko: '3. 가변 객체를 자식에게 전달하기'
	String get passing_mutable_object => '3. 가변 객체를 자식에게 전달하기';

	/// ko: '자식에게 불변 객체를 전달하는 것이 좋습니다. 가변 객체(예: List, Map, Set, Widget State)는 객체 참조가 변경되지 않기 때문에 객체가 변경될 때 자식에게 알리지 않습니다. '
	String get passing_mutable_object_desc => '자식에게 불변 객체를 전달하는 것이 좋습니다. 가변 객체(예: List, Map, Set, Widget State)는 객체 참조가 변경되지 않기 때문에 객체가 변경될 때 자식에게 알리지 않습니다. ';

	/// ko: '자식에게 변수 전달하기'
	String get passing_variable_to_children => '자식에게 변수 전달하기';

	/// ko: '자식에게 변수를 전달하려면 Model 위젯을 사용할 수 있습니다. Data 위젯과 비슷하지만 타입에 엄격하고 레이블이 지정됩니다.'
	String get passing_variable_desc => '자식에게 변수를 전달하려면 Model 위젯을 사용할 수 있습니다. Data 위젯과 비슷하지만 타입에 엄격하고 레이블이 지정됩니다.';

	/// ko: '자식에서 변수 변경하기'
	String get change_variable_from_children => '자식에서 변수 변경하기';

	/// ko: '자식에서 모델 값을 변경하는 2가지 방법이 있습니다:'
	String get change_variable_desc => '자식에서 모델 값을 변경하는 2가지 방법이 있습니다:';

	/// ko: 'ModelNotifier'
	String get modelnotifier => 'ModelNotifier';

	/// ko: 'ModelNotifier를 사용하면 ValueNotifier에서 자식에게 값을 전달할 수 있습니다. 부모 위젯에서 setState를 사용할 필요가 없습니다.'
	String get modelnotifier_desc => 'ModelNotifier를 사용하면 ValueNotifier에서 자식에게 값을 전달할 수 있습니다. 부모 위젯에서 setState를 사용할 필요가 없습니다.';

	/// ko: 'ModelListenable'
	String get modellistenable => 'ModelListenable';

	/// ko: 'ModelListenable은 읽기 전용 ModelNotifier입니다. 자식은 값을 수신만 할 수 있습니다. 값을 변경하려고 하면 오류가 발생합니다.'
	String get modellistenable_desc => 'ModelListenable은 읽기 전용 ModelNotifier입니다. 자식은 값을 수신만 할 수 있습니다. 값을 변경하려고 하면 오류가 발생합니다.';

	/// ko: 'ModelBuilder'
	String get modelbuilder => 'ModelBuilder';

	/// ko: 'ModelBuilder는 값이 변경될 때 위젯을 수신하고 다시 빌드합니다. DataBuilder와 비슷하지만 타입에 엄격하고 레이블이 지정됩니다.'
	String get modelbuilder_desc => 'ModelBuilder는 값이 변경될 때 위젯을 수신하고 다시 빌드합니다. DataBuilder와 비슷하지만 타입에 엄격하고 레이블이 지정됩니다.';
}

// Path: docs.components.accordion
class TranslationsDocsComponentsAccordionKo {
	TranslationsDocsComponentsAccordionKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '아코디언'
	String get display_name => '아코디언';

	/// ko: '아코디언은 수직으로 쌓인 항목 목록입니다. 각 항목을 '확장' 또는 '축소'하여 해당 항목과 관련된 콘텐츠를 표시할 수 있습니다.'
	String get description => '아코디언은 수직으로 쌓인 항목 목록입니다. 각 항목을 \'확장\' 또는 \'축소\'하여 해당 항목과 관련된 콘텐츠를 표시할 수 있습니다.';

	late final TranslationsDocsComponentsAccordionExamplesKo examples = TranslationsDocsComponentsAccordionExamplesKo.internal(_root);
}

// Path: docs.components.alert
class TranslationsDocsComponentsAlertKo {
	TranslationsDocsComponentsAlertKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '알림'
	String get display_name => '알림';

	/// ko: '알림은 시스템에 영향을 미치는 상태를 전달하는 데 사용됩니다.'
	String get description => '알림은 시스템에 영향을 미치는 상태를 전달하는 데 사용됩니다.';

	late final TranslationsDocsComponentsAlertExamplesKo examples = TranslationsDocsComponentsAlertExamplesKo.internal(_root);

	/// ko: '알림 제목'
	String get title => '알림 제목';

	/// ko: '알림 내용입니다.'
	String get content => '알림 내용입니다.';
}

// Path: docs.components.empty_state
class TranslationsDocsComponentsEmptyStateKo {
	TranslationsDocsComponentsEmptyStateKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '빈 상태'
	String get display_name => '빈 상태';

	/// ko: '콘텐츠가 없을 때 사용자에게 안내 메시지와 선택적 액션을 표시하는 컴포넌트입니다.'
	String get description => '콘텐츠가 없을 때 사용자에게 안내 메시지와 선택적 액션을 표시하는 컴포넌트입니다.';

	late final TranslationsDocsComponentsEmptyStateExamplesKo examples = TranslationsDocsComponentsEmptyStateExamplesKo.internal(_root);

	/// ko: '데이터가 없습니다'
	String get no_data => '데이터가 없습니다';

	/// ko: '표시할 데이터가 아직 없습니다.'
	String get no_data_description => '표시할 데이터가 아직 없습니다.';

	/// ko: '검색 결과 없음'
	String get no_results => '검색 결과 없음';

	/// ko: '검색 조건을 조정해 보세요.'
	String get no_results_description => '검색 조건을 조정해 보세요.';

	/// ko: '파일이 없습니다'
	String get no_files => '파일이 없습니다';

	/// ko: '파일을 업로드하여 시작하세요.'
	String get no_files_description => '파일을 업로드하여 시작하세요.';

	/// ko: '파일 업로드'
	String get upload_files => '파일 업로드';
}

// Path: docs.components.fade_scroll
class TranslationsDocsComponentsFadeScrollKo {
	TranslationsDocsComponentsFadeScrollKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '페이드 스크롤'
	String get display_name => '페이드 스크롤';

	/// ko: '스크롤 가능한 콘텐츠의 가장자리에 페이드 효과를 적용하여 더 많은 콘텐츠가 있음을 시각적으로 표시합니다.'
	String get description => '스크롤 가능한 콘텐츠의 가장자리에 페이드 효과를 적용하여 더 많은 콘텐츠가 있음을 시각적으로 표시합니다.';

	late final TranslationsDocsComponentsFadeScrollExamplesKo examples = TranslationsDocsComponentsFadeScrollExamplesKo.internal(_root);
}

// Path: docs.components.validation_badge
class TranslationsDocsComponentsValidationBadgeKo {
	TranslationsDocsComponentsValidationBadgeKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '유효성 배지'
	String get display_name => '유효성 배지';

	/// ko: '폼 필드의 유효성 검사 결과를 시각적으로 표시하는 배지 컴포넌트입니다.'
	String get description => '폼 필드의 유효성 검사 결과를 시각적으로 표시하는 배지 컴포넌트입니다.';

	late final TranslationsDocsComponentsValidationBadgeExamplesKo examples = TranslationsDocsComponentsValidationBadgeExamplesKo.internal(_root);

	/// ko: '유효'
	String get valid_label => '유효';

	/// ko: '무효'
	String get invalid_label => '무효';

	/// ko: '대기 중'
	String get pending_label => '대기 중';

	/// ko: '8자 이상'
	String get min_length => '8자 이상';

	/// ko: '숫자 포함'
	String get has_number => '숫자 포함';

	/// ko: '특수문자 포함'
	String get has_special => '특수문자 포함';

	/// ko: '아주 작음'
	String get extra_small => '아주 작음';

	/// ko: '작음'
	String get small => '작음';

	/// ko: '보통'
	String get medium => '보통';
}

// Path: docs.components.banner
class TranslationsDocsComponentsBannerKo {
	TranslationsDocsComponentsBannerKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '배너'
	String get display_name => '배너';

	/// ko: '배너는 중요한 공지사항이나 시스템 메시지를 눈에 띄게 표시하는 컴포넌트입니다.'
	String get description => '배너는 중요한 공지사항이나 시스템 메시지를 눈에 띄게 표시하는 컴포넌트입니다.';

	late final TranslationsDocsComponentsBannerExamplesKo examples = TranslationsDocsComponentsBannerExamplesKo.internal(_root);

	/// ko: '중요한 배너 메시지입니다.'
	String get content => '중요한 배너 메시지입니다.';
}

// Path: docs.components.alert_dialog
class TranslationsDocsComponentsAlertDialogKo {
	TranslationsDocsComponentsAlertDialogKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '알림 다이얼로그'
	String get display_name => '알림 다이얼로그';

	/// ko: '알림 다이얼로그는 사용자의 주의가 필요한 중요한 정보를 표시합니다.'
	String get description => '알림 다이얼로그는 사용자의 주의가 필요한 중요한 정보를 표시합니다.';

	late final TranslationsDocsComponentsAlertDialogExamplesKo examples = TranslationsDocsComponentsAlertDialogExamplesKo.internal(_root);

	/// ko: '여기를 클릭하세요'
	String get click_here => '여기를 클릭하세요';

	/// ko: '알림 제목'
	String get alert_title => '알림 제목';

	/// ko: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
	String get alert_content => 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
}

// Path: docs.components.animated_value_builder
class TranslationsDocsComponentsAnimatedValueBuilderKo {
	TranslationsDocsComponentsAnimatedValueBuilderKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '애니메이션 값 빌더'
	String get display_name => '애니메이션 값 빌더';

	/// ko: '값 변경 시 애니메이션을 자동으로 적용하는 빌더입니다.'
	String get description => '값 변경 시 애니메이션을 자동으로 적용하는 빌더입니다.';

	late final TranslationsDocsComponentsAnimatedValueBuilderExamplesKo examples = TranslationsDocsComponentsAnimatedValueBuilderExamplesKo.internal(_root);
}

// Path: docs.components.app_bar
class TranslationsDocsComponentsAppBarKo {
	TranslationsDocsComponentsAppBarKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '앱 바'
	String get display_name => '앱 바';

	/// ko: '앱 바는 앱의 상단에 표시되는 기본 네비게이션 요소입니다.'
	String get description => '앱 바는 앱의 상단에 표시되는 기본 네비게이션 요소입니다.';

	late final TranslationsDocsComponentsAppBarExamplesKo examples = TranslationsDocsComponentsAppBarExamplesKo.internal(_root);
}

// Path: docs.components.fab
class TranslationsDocsComponentsFabKo {
	TranslationsDocsComponentsFabKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'FAB'
	String get display_name => 'FAB';

	/// ko: '화면에 떠 있는 동작 버튼으로, 주요 작업을 빠르게 수행할 수 있습니다. 선택적으로 스피드 다이얼 패턴을 지원합니다.'
	String get description => '화면에 떠 있는 동작 버튼으로, 주요 작업을 빠르게 수행할 수 있습니다. 선택적으로 스피드 다이얼 패턴을 지원합니다.';

	late final TranslationsDocsComponentsFabExamplesKo examples = TranslationsDocsComponentsFabExamplesKo.internal(_root);

	/// ko: '수정'
	String get edit => '수정';

	/// ko: '공유'
	String get share => '공유';

	/// ko: '삭제'
	String get delete => '삭제';
}

// Path: docs.components.hover
class TranslationsDocsComponentsHoverKo {
	TranslationsDocsComponentsHoverKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '호버'
	String get display_name => '호버';

	/// ko: '마우스 커서의 호버 상태를 추적하는 유틸리티 위젯입니다. 호버 효과를 쉽게 구현할 수 있습니다.'
	String get description => '마우스 커서의 호버 상태를 추적하는 유틸리티 위젯입니다. 호버 효과를 쉽게 구현할 수 있습니다.';

	late final TranslationsDocsComponentsHoverExamplesKo examples = TranslationsDocsComponentsHoverExamplesKo.internal(_root);

	/// ko: '호버됨'
	String get hovered => '호버됨';

	/// ko: '호버 안됨'
	String get not_hovered => '호버 안됨';

	/// ko: '활성'
	String get active => '활성';

	/// ko: '비활성'
	String get inactive => '비활성';
}

// Path: docs.components.scrollbar
class TranslationsDocsComponentsScrollbarKo {
	TranslationsDocsComponentsScrollbarKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스크롤바'
	String get display_name => '스크롤바';

	/// ko: '스크롤 가능한 콘텐츠에 커스텀 스크롤바를 표시합니다.'
	String get description => '스크롤 가능한 콘텐츠에 커스텀 스크롤바를 표시합니다.';

	late final TranslationsDocsComponentsScrollbarExamplesKo examples = TranslationsDocsComponentsScrollbarExamplesKo.internal(_root);
}

// Path: docs.components.autocomplete
class TranslationsDocsComponentsAutocompleteKo {
	TranslationsDocsComponentsAutocompleteKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '자동완성'
	String get display_name => '자동완성';

	/// ko: '사용자 입력에 따라 제안을 표시하는 입력 필드입니다.'
	String get description => '사용자 입력에 따라 제안을 표시하는 입력 필드입니다.';

	late final TranslationsDocsComponentsAutocompleteExamplesKo examples = TranslationsDocsComponentsAutocompleteExamplesKo.internal(_root);
}

// Path: docs.components.avatar
class TranslationsDocsComponentsAvatarKo {
	TranslationsDocsComponentsAvatarKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '아바타'
	String get display_name => '아바타';

	/// ko: '사용자 또는 엔티티를 나타내는 이미지 또는 아이콘입니다.'
	String get description => '사용자 또는 엔티티를 나타내는 이미지 또는 아이콘입니다.';

	late final TranslationsDocsComponentsAvatarExamplesKo examples = TranslationsDocsComponentsAvatarExamplesKo.internal(_root);
}

// Path: docs.components.avatar_group
class TranslationsDocsComponentsAvatarGroupKo {
	TranslationsDocsComponentsAvatarGroupKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '아바타 그룹'
	String get display_name => '아바타 그룹';

	/// ko: '여러 아바타를 함께 표시합니다.'
	String get description => '여러 아바타를 함께 표시합니다.';

	late final TranslationsDocsComponentsAvatarGroupExamplesKo examples = TranslationsDocsComponentsAvatarGroupExamplesKo.internal(_root);
}

// Path: docs.components.badge
class TranslationsDocsComponentsBadgeKo {
	TranslationsDocsComponentsBadgeKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '배지'
	String get display_name => '배지';

	/// ko: '상태 또는 알림 수를 표시하는 작은 라벨입니다.'
	String get description => '상태 또는 알림 수를 표시하는 작은 라벨입니다.';

	late final TranslationsDocsComponentsBadgeExamplesKo examples = TranslationsDocsComponentsBadgeExamplesKo.internal(_root);

	/// ko: '기본'
	String get primary => '기본';

	/// ko: '보조'
	String get secondary => '보조';

	/// ko: '테두리'
	String get outline => '테두리';

	/// ko: '위험'
	String get destructive => '위험';
}

// Path: docs.components.breadcrumb
class TranslationsDocsComponentsBreadcrumbKo {
	TranslationsDocsComponentsBreadcrumbKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '브레드크럼'
	String get display_name => '브레드크럼';

	/// ko: '브레드크럼은 웹사이트 또는 웹 애플리케이션에서 사용자의 위치를 나타내는 보조 네비게이션 체계입니다.'
	String get description => '브레드크럼은 웹사이트 또는 웹 애플리케이션에서 사용자의 위치를 나타내는 보조 네비게이션 체계입니다.';

	late final TranslationsDocsComponentsBreadcrumbExamplesKo examples = TranslationsDocsComponentsBreadcrumbExamplesKo.internal(_root);

	/// ko: '홈'
	String get home => '홈';

	/// ko: '컴포넌트'
	String get components => '컴포넌트';
}

// Path: docs.components.button
class TranslationsDocsComponentsButtonKo {
	TranslationsDocsComponentsButtonKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '버튼'
	String get display_name => '버튼';

	/// ko: '버튼을 사용하면 사용자가 한 번의 탭으로 작업을 수행하고 선택을 할 수 있습니다.'
	String get description => '버튼을 사용하면 사용자가 한 번의 탭으로 작업을 수행하고 선택을 할 수 있습니다.';

	late final TranslationsDocsComponentsButtonExamplesKo examples = TranslationsDocsComponentsButtonExamplesKo.internal(_root);

	/// ko: '기본'
	String get primary => '기본';

	/// ko: '보조'
	String get secondary => '보조';

	/// ko: '테두리'
	String get outlined => '테두리';

	/// ko: '고스트'
	String get ghost => '고스트';

	/// ko: '위험'
	String get destructive => '위험';

	/// ko: '링크'
	String get link => '링크';

	/// ko: '외곽선'
	String get outline => '외곽선';

	/// ko: '텍스트'
	String get text => '텍스트';

	/// ko: '엑스트라 스몰'
	String get extra_small => '엑스트라 스몰';

	/// ko: '스몰'
	String get small => '스몰';

	/// ko: '노멀'
	String get normal => '노멀';

	/// ko: '라지'
	String get large => '라지';

	/// ko: '엑스트라 라지'
	String get extra_large => '엑스트라 라지';

	/// ko: '저장'
	String get save => '저장';

	/// ko: '취소'
	String get cancel => '취소';

	/// ko: '닫기'
	String get close => '닫기';

	/// ko: '제출'
	String get submit => '제출';

	/// ko: '프로필 수정'
	String get edit_profile => '프로필 수정';

	/// ko: '변경사항 저장'
	String get save_changes => '변경사항 저장';

	/// ko: '실행 취소'
	String get undo => '실행 취소';

	/// ko: 'Compact'
	String get compact => 'Compact';

	/// ko: 'Dense'
	String get dense => 'Dense';

	/// ko: 'Comfortable'
	String get comfortable => 'Comfortable';

	/// ko: 'Icon'
	String get icon => 'Icon';

	/// ko: 'Icon Comfortable'
	String get icon_comfortable => 'Icon Comfortable';

	/// ko: 'Rectangle'
	String get rectangle => 'Rectangle';

	/// ko: 'Add'
	String get add => 'Add';

	/// ko: 'Focused'
	String get focused => 'Focused';

	/// ko: 'Hovered'
	String get hovered => 'Hovered';

	/// ko: 'Pressed'
	String get pressed => 'Pressed';

	/// ko: 'Text Button'
	String get text_button => 'Text Button';

	/// ko: 'Custom Button'
	String get custom_button => 'Custom Button';
}

// Path: docs.components.calendar
class TranslationsDocsComponentsCalendarKo {
	TranslationsDocsComponentsCalendarKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '캘린더'
	String get display_name => '캘린더';

	/// ko: '날짜를 선택하고 표시하는 캘린더 컴포넌트입니다.'
	String get description => '날짜를 선택하고 표시하는 캘린더 컴포넌트입니다.';

	late final TranslationsDocsComponentsCalendarExamplesKo examples = TranslationsDocsComponentsCalendarExamplesKo.internal(_root);
}

// Path: docs.components.card
class TranslationsDocsComponentsCardKo {
	TranslationsDocsComponentsCardKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '카드'
	String get display_name => '카드';

	/// ko: '설명'
	String get description => '설명';

	late final TranslationsDocsComponentsCardExamplesKo examples = TranslationsDocsComponentsCardExamplesKo.internal(_root);

	/// ko: '프로젝트 만들기'
	String get create_project => '프로젝트 만들기';

	/// ko: '원클릭으로 새 프로젝트를 배포하세요'
	String get deploy_description => '원클릭으로 새 프로젝트를 배포하세요';

	/// ko: '이름'
	String get name => '이름';

	/// ko: '프로젝트 이름'
	String get name_placeholder => '프로젝트 이름';

	/// ko: '프로젝트 설명'
	String get description_placeholder => '프로젝트 설명';

	/// ko: '배포'
	String get deploy => '배포';
}

// Path: docs.components.card_image
class TranslationsDocsComponentsCardImageKo {
	TranslationsDocsComponentsCardImageKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '이미지 카드'
	String get display_name => '이미지 카드';

	/// ko: '이미지가 포함된 카드 컴포넌트입니다.'
	String get description => '이미지가 포함된 카드 컴포넌트입니다.';

	late final TranslationsDocsComponentsCardImageExamplesKo examples = TranslationsDocsComponentsCardImageExamplesKo.internal(_root);

	/// ko: '카드 이미지'
	String get card_image_title => '카드 이미지';

	/// ko: '카드 이미지를 클릭했습니다'
	String get card_clicked => '카드 이미지를 클릭했습니다';

	/// ko: '카드 번호 {n}'
	String card_number({required Object n}) => '카드 번호 ${n}';

	/// ko: 'Lorem ipsum dolor sit amet'
	String get lorem_ipsum => 'Lorem ipsum dolor sit amet';
}

// Path: docs.components.carousel
class TranslationsDocsComponentsCarouselKo {
	TranslationsDocsComponentsCarouselKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '캐러셀'
	String get display_name => '캐러셀';

	/// ko: '여러 항목을 슬라이드로 표시하는 컴포넌트입니다.'
	String get description => '여러 항목을 슬라이드로 표시하는 컴포넌트입니다.';

	late final TranslationsDocsComponentsCarouselExamplesKo examples = TranslationsDocsComponentsCarouselExamplesKo.internal(_root);
}

// Path: docs.components.checkbox
class TranslationsDocsComponentsCheckboxKo {
	TranslationsDocsComponentsCheckboxKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '체크박스'
	String get display_name => '체크박스';

	/// ko: '체크박스를 사용하면 사용자가 목록에서 하나 이상의 항목을 선택할 수 있습니다.'
	String get description => '체크박스를 사용하면 사용자가 목록에서 하나 이상의 항목을 선택할 수 있습니다.';

	late final TranslationsDocsComponentsCheckboxExamplesKo examples = TranslationsDocsComponentsCheckboxExamplesKo.internal(_root);

	/// ko: '기억하기'
	String get remember_me => '기억하기';
}

// Path: docs.components.chip
class TranslationsDocsComponentsChipKo {
	TranslationsDocsComponentsChipKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '칩'
	String get display_name => '칩';

	/// ko: '칩은 속성, 선택사항 또는 작업을 나타내는 작은 요소입니다.'
	String get description => '칩은 속성, 선택사항 또는 작업을 나타내는 작은 요소입니다.';

	late final TranslationsDocsComponentsChipExamplesKo examples = TranslationsDocsComponentsChipExamplesKo.internal(_root);

	/// ko: '사과'
	String get apple => '사과';

	/// ko: '바나나'
	String get banana => '바나나';

	/// ko: '체리'
	String get cherry => '체리';

	/// ko: '두리안'
	String get durian => '두리안';

	/// ko: '엘더베리'
	String get elderberry => '엘더베리';
}

// Path: docs.components.chip_input
class TranslationsDocsComponentsChipInputKo {
	TranslationsDocsComponentsChipInputKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '칩 입력'
	String get display_name => '칩 입력';

	/// ko: '여러 값을 칩 형태로 입력할 수 있는 입력 필드입니다.'
	String get description => '여러 값을 칩 형태로 입력할 수 있는 입력 필드입니다.';

	late final TranslationsDocsComponentsChipInputExamplesKo examples = TranslationsDocsComponentsChipInputExamplesKo.internal(_root);
}

// Path: docs.components.circular_progress
class TranslationsDocsComponentsCircularProgressKo {
	TranslationsDocsComponentsCircularProgressKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '원형 진행률'
	String get display_name => '원형 진행률';

	/// ko: '원형 진행 표시기입니다.'
	String get description => '원형 진행 표시기입니다.';

	late final TranslationsDocsComponentsCircularProgressExamplesKo examples = TranslationsDocsComponentsCircularProgressExamplesKo.internal(_root);

	/// ko: '10 증가'
	String get increase_by_10 => '10 증가';

	/// ko: '10 감소'
	String get decrease_by_10 => '10 감소';
}

// Path: docs.components.code_snippet
class TranslationsDocsComponentsCodeSnippetKo {
	TranslationsDocsComponentsCodeSnippetKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '코드 스니펫'
	String get display_name => '코드 스니펫';

	/// ko: '코드를 표시하는 컴포넌트입니다.'
	String get description => '코드를 표시하는 컴포넌트입니다.';

	late final TranslationsDocsComponentsCodeSnippetExamplesKo examples = TranslationsDocsComponentsCodeSnippetExamplesKo.internal(_root);
}

// Path: docs.components.collapsible
class TranslationsDocsComponentsCollapsibleKo {
	TranslationsDocsComponentsCollapsibleKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '접을 수 있는'
	String get display_name => '접을 수 있는';

	/// ko: '접거나 펼칠 수 있는 콘텐츠 컨테이너입니다.'
	String get description => '접거나 펼칠 수 있는 콘텐츠 컨테이너입니다.';

	late final TranslationsDocsComponentsCollapsibleExamplesKo examples = TranslationsDocsComponentsCollapsibleExamplesKo.internal(_root);

	/// ko: '@coco-de가 3개의 저장소에 별표를 지정했습니다'
	String get starred_repositories => '@coco-de가 3개의 저장소에 별표를 지정했습니다';

	/// ko: '모두 축소'
	String get collapse_all => '모두 축소';

	/// ko: '모두 확장'
	String get expand_all => '모두 확장';

	/// ko: '아이콘 확장'
	String get expand_icon => '아이콘 확장';

	/// ko: '경로 분기선 사용'
	String get use_path_branch => '경로 분기선 사용';

	/// ko: '재귀적 선택'
	String get recursive_selection => '재귀적 선택';
}

// Path: docs.components.color_picker
class TranslationsDocsComponentsColorPickerKo {
	TranslationsDocsComponentsColorPickerKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '색상 선택기'
	String get display_name => '색상 선택기';

	/// ko: '색상을 선택할 수 있는 컴포넌트입니다.'
	String get description => '색상을 선택할 수 있는 컴포넌트입니다.';

	late final TranslationsDocsComponentsColorPickerExamplesKo examples = TranslationsDocsComponentsColorPickerExamplesKo.internal(_root);

	/// ko: '색상 선택'
	String get pick_color => '색상 선택';

	/// ko: '색상: {color}'
	String color_label({required Object color}) => '색상: ${color}';

	/// ko: '색상 선택'
	String get select_color => '색상 선택';

	/// ko: '색상 선택기 팝오버 열기'
	String get open_color_picker_popover => '색상 선택기 팝오버 열기';

	/// ko: '색상 선택기 다이얼로그 열기'
	String get open_color_picker_dialog => '색상 선택기 다이얼로그 열기';
}

// Path: docs.components.command
class TranslationsDocsComponentsCommandKo {
	TranslationsDocsComponentsCommandKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '커맨드'
	String get display_name => '커맨드';

	/// ko: '커맨드는 항목을 검색할 수 있는 컴포넌트입니다.'
	String get description => '커맨드는 항목을 검색할 수 있는 컴포넌트입니다.';

	late final TranslationsDocsComponentsCommandExamplesKo examples = TranslationsDocsComponentsCommandExamplesKo.internal(_root);
}

// Path: docs.components.context_menu
class TranslationsDocsComponentsContextMenuKo {
	TranslationsDocsComponentsContextMenuKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '컨텍스트 메뉴'
	String get display_name => '컨텍스트 메뉴';

	/// ko: '우클릭 또는 길게 누르기로 표시되는 메뉴입니다.'
	String get description => '우클릭 또는 길게 누르기로 표시되는 메뉴입니다.';

	late final TranslationsDocsComponentsContextMenuExamplesKo examples = TranslationsDocsComponentsContextMenuExamplesKo.internal(_root);
}

// Path: docs.components.date_picker
class TranslationsDocsComponentsDatePickerKo {
	TranslationsDocsComponentsDatePickerKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '날짜 선택기'
	String get display_name => '날짜 선택기';

	/// ko: '날짜를 선택할 수 있는 입력 필드입니다.'
	String get description => '날짜를 선택할 수 있는 입력 필드입니다.';

	late final TranslationsDocsComponentsDatePickerExamplesKo examples = TranslationsDocsComponentsDatePickerExamplesKo.internal(_root);

	/// ko: '날짜 선택'
	String get select_date => '날짜 선택';

	/// ko: '날짜 범위 선택'
	String get select_date_range => '날짜 범위 선택';
}

// Path: docs.components.dialog
class TranslationsDocsComponentsDialogKo {
	TranslationsDocsComponentsDialogKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '다이얼로그'
	String get display_name => '다이얼로그';

	/// ko: '다이얼로그는 앱의 나머지 부분 위에 표시되는 모달 창입니다.'
	String get description => '다이얼로그는 앱의 나머지 부분 위에 표시되는 모달 창입니다.';

	late final TranslationsDocsComponentsDialogExamplesKo examples = TranslationsDocsComponentsDialogExamplesKo.internal(_root);

	/// ko: '프로필 수정'
	String get edit_profile_title => '프로필 수정';

	/// ko: '여기서 프로필을 변경하세요. 완료되면 저장을 클릭하세요.'
	String get edit_profile_description => '여기서 프로필을 변경하세요. 완료되면 저장을 클릭하세요.';

	/// ko: '이름'
	String get name_label => '이름';

	/// ko: '사용자명'
	String get username_label => '사용자명';

	/// ko: '안녕하세요'
	String get hello => '안녕하세요';

	/// ko: 'Material 다이얼로그입니다'
	String get material_dialog_content => 'Material 다이얼로그입니다';

	/// ko: 'Cupertino 다이얼로그입니다'
	String get cupertino_dialog_content => 'Cupertino 다이얼로그입니다';

	/// ko: '알림 제목'
	String get alert_title => '알림 제목';

	/// ko: '여기를 클릭하세요'
	String get click_here => '여기를 클릭하세요';

	/// ko: '확인'
	String get ok => '확인';

	/// ko: 'Material 다이얼로그 열기'
	String get open_material_dialog => 'Material 다이얼로그 열기';

	/// ko: 'Cupertino 다이얼로그 열기'
	String get open_cupertino_dialog => 'Cupertino 다이얼로그 열기';

	/// ko: 'COUI 다이얼로그 열기'
	String get open_coui_dialog => 'COUI 다이얼로그 열기';
}

// Path: docs.components.divider
class TranslationsDocsComponentsDividerKo {
	TranslationsDocsComponentsDividerKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '구분선'
	String get display_name => '구분선';

	/// ko: '콘텐츠를 시각적으로 구분하는 선입니다.'
	String get description => '콘텐츠를 시각적으로 구분하는 선입니다.';

	late final TranslationsDocsComponentsDividerExamplesKo examples = TranslationsDocsComponentsDividerExamplesKo.internal(_root);

	/// ko: '항목 1'
	String get item_1 => '항목 1';

	/// ko: '항목 2'
	String get item_2 => '항목 2';

	/// ko: '항목 3'
	String get item_3 => '항목 3';

	/// ko: '구분선'
	String get divider => '구분선';
}

// Path: docs.components.dot_indicator
class TranslationsDocsComponentsDotIndicatorKo {
	TranslationsDocsComponentsDotIndicatorKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '점 표시기'
	String get display_name => '점 표시기';

	/// ko: '현재 위치를 점으로 표시하는 인디케이터입니다.'
	String get description => '현재 위치를 점으로 표시하는 인디케이터입니다.';

	late final TranslationsDocsComponentsDotIndicatorExamplesKo examples = TranslationsDocsComponentsDotIndicatorExamplesKo.internal(_root);
}

// Path: docs.components.drawer
class TranslationsDocsComponentsDrawerKo {
	TranslationsDocsComponentsDrawerKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '드로어'
	String get display_name => '드로어';

	/// ko: '화면 가장자리에서 슬라이드되는 패널입니다.'
	String get description => '화면 가장자리에서 슬라이드되는 패널입니다.';

	late final TranslationsDocsComponentsDrawerExamplesKo examples = TranslationsDocsComponentsDrawerExamplesKo.internal(_root);

	/// ko: '드로어 열기'
	String get open_drawer => '드로어 열기';

	/// ko: '드로어 닫기'
	String get close_drawer => '드로어 닫기';

	/// ko: '다른 드로어 열기'
	String get open_another_drawer => '다른 드로어 열기';

	/// ko: '드로어 {count}번 at {position}'
	String drawer_at({required Object count, required Object position}) => '드로어 ${count}번 at ${position}';
}

// Path: docs.components.dropdown_menu
class TranslationsDocsComponentsDropdownMenuKo {
	TranslationsDocsComponentsDropdownMenuKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '드롭다운 메뉴'
	String get display_name => '드롭다운 메뉴';

	/// ko: '선택 가능한 옵션 목록을 표시하는 메뉴입니다.'
	String get description => '선택 가능한 옵션 목록을 표시하는 메뉴입니다.';

	late final TranslationsDocsComponentsDropdownMenuExamplesKo examples = TranslationsDocsComponentsDropdownMenuExamplesKo.internal(_root);
}

// Path: docs.components.expandable_sidebar
class TranslationsDocsComponentsExpandableSidebarKo {
	TranslationsDocsComponentsExpandableSidebarKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '확장 가능한 사이드바'
	String get display_name => '확장 가능한 사이드바';

	/// ko: '확장 및 축소가 가능한 사이드바입니다.'
	String get description => '확장 및 축소가 가능한 사이드바입니다.';

	late final TranslationsDocsComponentsExpandableSidebarExamplesKo examples = TranslationsDocsComponentsExpandableSidebarExamplesKo.internal(_root);
}

// Path: docs.components.form
class TranslationsDocsComponentsFormKo {
	TranslationsDocsComponentsFormKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '폼'
	String get display_name => '폼';

	/// ko: '폼 유효성 검사를 쉽게 만드는 도우미 위젯입니다.'
	String get description => '폼 유효성 검사를 쉽게 만드는 도우미 위젯입니다.';

	late final TranslationsDocsComponentsFormExamplesKo examples = TranslationsDocsComponentsFormExamplesKo.internal(_root);

	/// ko: '사용자명'
	String get username_label => '사용자명';

	/// ko: '공개적으로 표시될 이름입니다'
	String get username_hint => '공개적으로 표시될 이름입니다';

	/// ko: '비밀번호'
	String get password_label => '비밀번호';

	/// ko: '비밀번호 확인'
	String get confirm_password_label => '비밀번호 확인';

	/// ko: '비밀번호가 일치하지 않습니다'
	String get passwords_do_not_match => '비밀번호가 일치하지 않습니다';

	/// ko: '이용약관에 동의합니다'
	String get agree_terms => '이용약관에 동의합니다';

	/// ko: '이용약관에 동의해야 합니다'
	String get must_agree_terms => '이용약관에 동의해야 합니다';

	/// ko: '폼 값'
	String get form_values_title => '폼 값';

	/// ko: '등록'
	String get register => '등록';

	/// ko: '사용자명이 이미 사용 중입니다'
	String get username_already_taken => '사용자명이 이미 사용 중입니다';

	/// ko: '이메일'
	String get email => '이메일';

	/// ko: '사용자명: {value}'
	String username_display({required Object value}) => '사용자명: ${value}';

	/// ko: '비밀번호: {value}'
	String password_display({required Object value}) => '비밀번호: ${value}';

	/// ko: '비밀번호 확인: {value}'
	String confirm_password_display({required Object value}) => '비밀번호 확인: ${value}';

	/// ko: '동의: {value}'
	String agree_display({required Object value}) => '동의: ${value}';

	/// ko: 'JSON: {value}'
	String json_display({required Object value}) => 'JSON: ${value}';

	/// ko: '제출된 값: {value}'
	String submitted_value_display({required Object value}) => '제출된 값: ${value}';

	/// ko: '로그인'
	String get login => '로그인';

	/// ko: '회원가입'
	String get sign_up => '회원가입';

	/// ko: '계정이 없으신가요?'
	String get dont_have_account => '계정이 없으신가요?';

	/// ko: '이미 계정이 있으신가요?'
	String get already_have_account => '이미 계정이 있으신가요?';
}

// Path: docs.components.formatted_input
class TranslationsDocsComponentsFormattedInputKo {
	TranslationsDocsComponentsFormattedInputKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '포맷 입력'
	String get display_name => '포맷 입력';

	/// ko: '특정 형식에 맞춰 입력되는 텍스트 필드입니다.'
	String get description => '특정 형식에 맞춰 입력되는 텍스트 필드입니다.';

	late final TranslationsDocsComponentsFormattedInputExamplesKo examples = TranslationsDocsComponentsFormattedInputExamplesKo.internal(_root);
}

// Path: docs.components.hover_card
class TranslationsDocsComponentsHoverCardKo {
	TranslationsDocsComponentsHoverCardKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '호버 카드'
	String get display_name => '호버 카드';

	/// ko: '호버 시 표시되는 카드입니다.'
	String get description => '호버 시 표시되는 카드입니다.';

	late final TranslationsDocsComponentsHoverCardExamplesKo examples = TranslationsDocsComponentsHoverCardExamplesKo.internal(_root);

	/// ko: '@flutter'
	String get flutter_handle => '@flutter';

	/// ko: 'Flutter'
	String get flutter_username => 'Flutter';

	/// ko: 'Flutter SDK는 단일 코드베이스에서 모바일, 웹, 데스크톱용 아름다운 앱을 빌드할 수 있는 도구를 제공합니다.'
	String get flutter_description => 'Flutter SDK는 단일 코드베이스에서 모바일, 웹, 데스크톱용 아름다운 앱을 빌드할 수 있는 도구를 제공합니다.';
}

// Path: docs.components.input
class TranslationsDocsComponentsInputKo {
	TranslationsDocsComponentsInputKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '입력'
	String get display_name => '입력';

	/// ko: '텍스트 입력 필드입니다.'
	String get description => '텍스트 입력 필드입니다.';

	late final TranslationsDocsComponentsInputExamplesKo examples = TranslationsDocsComponentsInputExamplesKo.internal(_root);

	/// ko: '이름을 입력하세요'
	String get enter_name => '이름을 입력하세요';

	/// ko: '사용자명을 입력하세요'
	String get enter_username => '사용자명을 입력하세요';

	/// ko: '사용자명이 이미 사용 중입니다'
	String get username_already_taken => '사용자명이 이미 사용 중입니다';

	/// ko: '안녕하세요, 세계!'
	String get hello_world => '안녕하세요, 세계!';

	/// ko: '검색할 내용을 입력하세요...'
	String get search_something => '검색할 내용을 입력하세요...';

	/// ko: '이메일'
	String get email => '이메일';

	/// ko: '비밀번호를 입력하세요'
	String get password => '비밀번호를 입력하세요';

	/// ko: '사용자명 입력란입니다'
	String get username_hint => '사용자명 입력란입니다';
}

// Path: docs.components.input_otp
class TranslationsDocsComponentsInputOtpKo {
	TranslationsDocsComponentsInputOtpKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'OTP 입력'
	String get display_name => 'OTP 입력';

	/// ko: '일회용 비밀번호를 입력하는 필드입니다.'
	String get description => '일회용 비밀번호를 입력하는 필드입니다.';

	late final TranslationsDocsComponentsInputOtpExamplesKo examples = TranslationsDocsComponentsInputOtpExamplesKo.internal(_root);
}

// Path: docs.components.item_picker
class TranslationsDocsComponentsItemPickerKo {
	TranslationsDocsComponentsItemPickerKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '항목 선택기'
	String get display_name => '항목 선택기';

	/// ko: '목록에서 항목을 선택할 수 있는 컴포넌트입니다.'
	String get description => '목록에서 항목을 선택할 수 있는 컴포넌트입니다.';

	late final TranslationsDocsComponentsItemPickerExamplesKo examples = TranslationsDocsComponentsItemPickerExamplesKo.internal(_root);
}

// Path: docs.components.keyboard_display
class TranslationsDocsComponentsKeyboardDisplayKo {
	TranslationsDocsComponentsKeyboardDisplayKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '키보드 표시'
	String get display_name => '키보드 표시';

	/// ko: '키보드 단축키를 표시하는 컴포넌트입니다.'
	String get description => '키보드 단축키를 표시하는 컴포넌트입니다.';

	late final TranslationsDocsComponentsKeyboardDisplayExamplesKo examples = TranslationsDocsComponentsKeyboardDisplayExamplesKo.internal(_root);
}

// Path: docs.components.linear_progress
class TranslationsDocsComponentsLinearProgressKo {
	TranslationsDocsComponentsLinearProgressKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '선형 진행률'
	String get display_name => '선형 진행률';

	/// ko: '선형 진행 표시기입니다.'
	String get description => '선형 진행 표시기입니다.';

	late final TranslationsDocsComponentsLinearProgressExamplesKo examples = TranslationsDocsComponentsLinearProgressExamplesKo.internal(_root);

	/// ko: '증가'
	String get increase => '증가';

	/// ko: '감소'
	String get decrease => '감소';
}

// Path: docs.components.material
class TranslationsDocsComponentsMaterialKo {
	TranslationsDocsComponentsMaterialKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'Material/Cupertino'
	String get display_name => 'Material/Cupertino';

	/// ko: 'Flutter의 기본 Material 및 Cupertino 위젯을 사용하는 방법입니다.'
	String get description => 'Flutter의 기본 Material 및 Cupertino 위젯을 사용하는 방법입니다.';

	late final TranslationsDocsComponentsMaterialExamplesKo examples = TranslationsDocsComponentsMaterialExamplesKo.internal(_root);

	/// ko: '내 Material 앱'
	String get my_material_app => '내 Material 앱';

	/// ko: '내 Cupertino 앱'
	String get my_cupertino_app => '내 Cupertino 앱';

	/// ko: '버튼을 {count}번 눌렀습니다'
	String you_pushed_button({required Object count}) => '버튼을 ${count}번 눌렀습니다';

	/// ko: 'Material 다이얼로그 열기'
	String get open_material_dialog => 'Material 다이얼로그 열기';

	/// ko: 'Cupertino 다이얼로그 열기'
	String get open_cupertino_dialog => 'Cupertino 다이얼로그 열기';

	/// ko: 'COUI 다이얼로그 열기'
	String get open_coui_dialog => 'COUI 다이얼로그 열기';
}

// Path: docs.components.menubar
class TranslationsDocsComponentsMenubarKo {
	TranslationsDocsComponentsMenubarKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '메뉴바'
	String get display_name => '메뉴바';

	/// ko: '수평 메뉴 바입니다.'
	String get description => '수평 메뉴 바입니다.';

	late final TranslationsDocsComponentsMenubarExamplesKo examples = TranslationsDocsComponentsMenubarExamplesKo.internal(_root);

	/// ko: '파일'
	String get file => '파일';

	/// ko: '편집'
	String get edit => '편집';

	/// ko: '새 탭'
	String get new_tab => '새 탭';

	/// ko: '새 창'
	String get new_window => '새 창';

	/// ko: '새 시크릿 창'
	String get new_incognito_window => '새 시크릿 창';

	/// ko: '이메일 링크'
	String get email_link => '이메일 링크';

	/// ko: '메시지'
	String get messages => '메시지';

	/// ko: '노트'
	String get notes => '노트';

	/// ko: '공유'
	String get share => '공유';

	/// ko: '인쇄'
	String get print => '인쇄';

	/// ko: '저장 후 종료'
	String get save_and_exit => '저장 후 종료';

	/// ko: '취소 후 종료'
	String get discard_and_exit => '취소 후 종료';

	/// ko: '종료'
	String get exit => '종료';

	/// ko: '실행 취소'
	String get undo => '실행 취소';

	/// ko: '다시 실행'
	String get redo => '다시 실행';
}

// Path: docs.components.multiselect
class TranslationsDocsComponentsMultiselectKo {
	TranslationsDocsComponentsMultiselectKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '다중 선택'
	String get display_name => '다중 선택';

	/// ko: '여러 항목을 선택할 수 있는 컴포넌트입니다.'
	String get description => '여러 항목을 선택할 수 있는 컴포넌트입니다.';

	late final TranslationsDocsComponentsMultiselectExamplesKo examples = TranslationsDocsComponentsMultiselectExamplesKo.internal(_root);
}

// Path: docs.components.navigation_bar
class TranslationsDocsComponentsNavigationBarKo {
	TranslationsDocsComponentsNavigationBarKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '네비게이션 바'
	String get display_name => '네비게이션 바';

	/// ko: '하단 네비게이션 바입니다.'
	String get description => '하단 네비게이션 바입니다.';

	late final TranslationsDocsComponentsNavigationBarExamplesKo examples = TranslationsDocsComponentsNavigationBarExamplesKo.internal(_root);
}

// Path: docs.components.navigation_menu
class TranslationsDocsComponentsNavigationMenuKo {
	TranslationsDocsComponentsNavigationMenuKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '네비게이션 메뉴'
	String get display_name => '네비게이션 메뉴';

	/// ko: '네비게이션 메뉴 컴포넌트입니다.'
	String get description => '네비게이션 메뉴 컴포넌트입니다.';

	late final TranslationsDocsComponentsNavigationMenuExamplesKo examples = TranslationsDocsComponentsNavigationMenuExamplesKo.internal(_root);
}

// Path: docs.components.navigation_rail
class TranslationsDocsComponentsNavigationRailKo {
	TranslationsDocsComponentsNavigationRailKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '네비게이션 레일'
	String get display_name => '네비게이션 레일';

	/// ko: '측면 네비게이션 레일입니다.'
	String get description => '측면 네비게이션 레일입니다.';

	late final TranslationsDocsComponentsNavigationRailExamplesKo examples = TranslationsDocsComponentsNavigationRailExamplesKo.internal(_root);
}

// Path: docs.components.navigation_sidebar
class TranslationsDocsComponentsNavigationSidebarKo {
	TranslationsDocsComponentsNavigationSidebarKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '네비게이션 사이드바'
	String get display_name => '네비게이션 사이드바';

	/// ko: '네비게이션 사이드바 컴포넌트입니다.'
	String get description => '네비게이션 사이드바 컴포넌트입니다.';

	late final TranslationsDocsComponentsNavigationSidebarExamplesKo examples = TranslationsDocsComponentsNavigationSidebarExamplesKo.internal(_root);
}

// Path: docs.components.number_input
class TranslationsDocsComponentsNumberInputKo {
	TranslationsDocsComponentsNumberInputKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '숫자 입력'
	String get display_name => '숫자 입력';

	/// ko: '숫자를 입력하는 필드입니다.'
	String get description => '숫자를 입력하는 필드입니다.';

	late final TranslationsDocsComponentsNumberInputExamplesKo examples = TranslationsDocsComponentsNumberInputExamplesKo.internal(_root);

	/// ko: '값: {value}'
	String value({required Object value}) => '값: ${value}';
}

// Path: docs.components.number_ticker
class TranslationsDocsComponentsNumberTickerKo {
	TranslationsDocsComponentsNumberTickerKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '숫자 티커'
	String get display_name => '숫자 티커';

	/// ko: '숫자가 변경될 때 애니메이션을 표시합니다.'
	String get description => '숫자가 변경될 때 애니메이션을 표시합니다.';

	late final TranslationsDocsComponentsNumberTickerExamplesKo examples = TranslationsDocsComponentsNumberTickerExamplesKo.internal(_root);
}

// Path: docs.components.overflow_marquee
class TranslationsDocsComponentsOverflowMarqueeKo {
	TranslationsDocsComponentsOverflowMarqueeKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '오버플로우 마키'
	String get display_name => '오버플로우 마키';

	/// ko: '텍스트가 넘칠 때 자동으로 스크롤됩니다.'
	String get description => '텍스트가 넘칠 때 자동으로 스크롤됩니다.';

	late final TranslationsDocsComponentsOverflowMarqueeExamplesKo examples = TranslationsDocsComponentsOverflowMarqueeExamplesKo.internal(_root);
}

// Path: docs.components.pagination
class TranslationsDocsComponentsPaginationKo {
	TranslationsDocsComponentsPaginationKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '페이지네이션'
	String get display_name => '페이지네이션';

	/// ko: '페이지를 탐색하는 컴포넌트입니다.'
	String get description => '페이지를 탐색하는 컴포넌트입니다.';

	late final TranslationsDocsComponentsPaginationExamplesKo examples = TranslationsDocsComponentsPaginationExamplesKo.internal(_root);
}

// Path: docs.components.phone_input
class TranslationsDocsComponentsPhoneInputKo {
	TranslationsDocsComponentsPhoneInputKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '전화번호 입력'
	String get display_name => '전화번호 입력';

	/// ko: '전화번호를 입력하는 필드입니다.'
	String get description => '전화번호를 입력하는 필드입니다.';

	late final TranslationsDocsComponentsPhoneInputExamplesKo examples = TranslationsDocsComponentsPhoneInputExamplesKo.internal(_root);
}

// Path: docs.components.popover
class TranslationsDocsComponentsPopoverKo {
	TranslationsDocsComponentsPopoverKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '팝오버'
	String get display_name => '팝오버';

	/// ko: '요소 위에 표시되는 팝업입니다.'
	String get description => '요소 위에 표시되는 팝업입니다.';

	late final TranslationsDocsComponentsPopoverExamplesKo examples = TranslationsDocsComponentsPopoverExamplesKo.internal(_root);

	/// ko: '크기'
	String get dimensions => '크기';

	/// ko: '레이어의 크기를 설정하세요'
	String get set_dimensions => '레이어의 크기를 설정하세요';

	/// ko: '너비'
	String get width => '너비';

	/// ko: '최대 너비'
	String get max_width => '최대 너비';

	/// ko: '높이'
	String get height => '높이';

	/// ko: '최대 높이'
	String get max_height => '최대 높이';

	/// ko: '팝오버 열기'
	String get open_popover => '팝오버 열기';

	/// ko: '제출'
	String get submit => '제출';
}

// Path: docs.components.progress
class TranslationsDocsComponentsProgressKo {
	TranslationsDocsComponentsProgressKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '진행률'
	String get display_name => '진행률';

	/// ko: '진행 상태를 표시합니다.'
	String get description => '진행 상태를 표시합니다.';

	late final TranslationsDocsComponentsProgressExamplesKo examples = TranslationsDocsComponentsProgressExamplesKo.internal(_root);
}

// Path: docs.components.radio_card
class TranslationsDocsComponentsRadioCardKo {
	TranslationsDocsComponentsRadioCardKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '라디오 카드'
	String get display_name => '라디오 카드';

	/// ko: '카드 형태의 라디오 버튼입니다.'
	String get description => '카드 형태의 라디오 버튼입니다.';

	late final TranslationsDocsComponentsRadioCardExamplesKo examples = TranslationsDocsComponentsRadioCardExamplesKo.internal(_root);
}

// Path: docs.components.radio_group
class TranslationsDocsComponentsRadioGroupKo {
	TranslationsDocsComponentsRadioGroupKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '라디오 그룹'
	String get display_name => '라디오 그룹';

	/// ko: '라디오 버튼 그룹입니다.'
	String get description => '라디오 버튼 그룹입니다.';

	late final TranslationsDocsComponentsRadioGroupExamplesKo examples = TranslationsDocsComponentsRadioGroupExamplesKo.internal(_root);

	/// ko: '옵션 1'
	String get option_1 => '옵션 1';

	/// ko: '옵션 2'
	String get option_2 => '옵션 2';

	/// ko: '옵션 3'
	String get option_3 => '옵션 3';

	/// ko: '선택됨'
	String get selected => '선택됨';
}

// Path: docs.components.refresh_trigger
class TranslationsDocsComponentsRefreshTriggerKo {
	TranslationsDocsComponentsRefreshTriggerKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '새로고침 트리거'
	String get display_name => '새로고침 트리거';

	/// ko: '당겨서 새로고침 기능을 제공합니다.'
	String get description => '당겨서 새로고침 기능을 제공합니다.';

	late final TranslationsDocsComponentsRefreshTriggerExamplesKo examples = TranslationsDocsComponentsRefreshTriggerExamplesKo.internal(_root);

	/// ko: '당겨주세요'
	String get pull_me => '당겨주세요';

	/// ko: '새로고침'
	String get refresh => '새로고침';
}

// Path: docs.components.repeated_animation_builder
class TranslationsDocsComponentsRepeatedAnimationBuilderKo {
	TranslationsDocsComponentsRepeatedAnimationBuilderKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '반복 애니메이션 빌더'
	String get display_name => '반복 애니메이션 빌더';

	/// ko: '애니메이션을 반복하는 빌더입니다.'
	String get description => '애니메이션을 반복하는 빌더입니다.';

	late final TranslationsDocsComponentsRepeatedAnimationBuilderExamplesKo examples = TranslationsDocsComponentsRepeatedAnimationBuilderExamplesKo.internal(_root);
}

// Path: docs.components.resizable
class TranslationsDocsComponentsResizableKo {
	TranslationsDocsComponentsResizableKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '크기 조절 가능'
	String get display_name => '크기 조절 가능';

	/// ko: '크기를 조절할 수 있는 컨테이너입니다.'
	String get description => '크기를 조절할 수 있는 컨테이너입니다.';

	late final TranslationsDocsComponentsResizableExamplesKo examples = TranslationsDocsComponentsResizableExamplesKo.internal(_root);
}

// Path: docs.components.scaffold
class TranslationsDocsComponentsScaffoldKo {
	TranslationsDocsComponentsScaffoldKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스캐폴드'
	String get display_name => '스캐폴드';

	/// ko: '스캐폴드는 페이지의 최상위 컨테이너입니다.'
	String get description => '스캐폴드는 페이지의 최상위 컨테이너입니다.';

	late final TranslationsDocsComponentsScaffoldExamplesKo examples = TranslationsDocsComponentsScaffoldExamplesKo.internal(_root);
}

// Path: docs.components.select
class TranslationsDocsComponentsSelectKo {
	TranslationsDocsComponentsSelectKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '선택'
	String get display_name => '선택';

	/// ko: '옵션 목록에서 항목을 선택할 수 있습니다.'
	String get description => '옵션 목록에서 항목을 선택할 수 있습니다.';

	late final TranslationsDocsComponentsSelectExamplesKo examples = TranslationsDocsComponentsSelectExamplesKo.internal(_root);

	/// ko: '과일을 선택하세요'
	String get placeholder => '과일을 선택하세요';

	/// ko: '과일 검색'
	String get search_fruit => '과일 검색';

	/// ko: '과일을 찾을 수 없습니다'
	String get no_fruit_found => '과일을 찾을 수 없습니다';

	/// ko: '사과'
	String get apple => '사과';

	/// ko: '바나나'
	String get banana => '바나나';

	/// ko: '체리'
	String get cherry => '체리';

	/// ko: '레몬'
	String get lemon => '레몬';

	/// ko: '토마토'
	String get tomato => '토마토';

	/// ko: '빨간 사과'
	String get red_apple => '빨간 사과';

	/// ko: '초록 사과'
	String get green_apple => '초록 사과';

	/// ko: '노란 바나나'
	String get yellow_banana => '노란 바나나';

	/// ko: '갈색 바나나'
	String get brown_banana => '갈색 바나나';

	/// ko: '노란 레몬'
	String get yellow_lemon => '노란 레몬';

	/// ko: '초록 레몬'
	String get green_lemon => '초록 레몬';

	/// ko: '빨강'
	String get red => '빨강';

	/// ko: '초록'
	String get green => '초록';

	/// ko: '노랑'
	String get yellow => '노랑';

	/// ko: '갈색'
	String get brown => '갈색';
}

// Path: docs.components.sheet
class TranslationsDocsComponentsSheetKo {
	TranslationsDocsComponentsSheetKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '시트'
	String get display_name => '시트';

	/// ko: '하단에서 올라오는 시트입니다.'
	String get description => '하단에서 올라오는 시트입니다.';

	late final TranslationsDocsComponentsSheetExamplesKo examples = TranslationsDocsComponentsSheetExamplesKo.internal(_root);
}

// Path: docs.components.skeleton
class TranslationsDocsComponentsSkeletonKo {
	TranslationsDocsComponentsSkeletonKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스켈레톤'
	String get display_name => '스켈레톤';

	/// ko: '로딩 중 표시되는 스켈레톤 화면입니다.'
	String get description => '로딩 중 표시되는 스켈레톤 화면입니다.';

	late final TranslationsDocsComponentsSkeletonExamplesKo examples = TranslationsDocsComponentsSkeletonExamplesKo.internal(_root);
}

// Path: docs.components.slider
class TranslationsDocsComponentsSliderKo {
	TranslationsDocsComponentsSliderKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '슬라이더'
	String get display_name => '슬라이더';

	/// ko: '값을 슬라이드하여 선택할 수 있습니다.'
	String get description => '값을 슬라이드하여 선택할 수 있습니다.';

	late final TranslationsDocsComponentsSliderExamplesKo examples = TranslationsDocsComponentsSliderExamplesKo.internal(_root);

	/// ko: '값: {value}'
	String value_single({required Object value}) => '값: ${value}';

	/// ko: '값: {start} - {end}'
	String value_range({required Object start, required Object end}) => '값: ${start} - ${end}';
}

// Path: docs.components.sortable
class TranslationsDocsComponentsSortableKo {
	TranslationsDocsComponentsSortableKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '정렬 가능'
	String get display_name => '정렬 가능';

	/// ko: '드래그하여 항목을 정렬할 수 있습니다.'
	String get description => '드래그하여 항목을 정렬할 수 있습니다.';

	late final TranslationsDocsComponentsSortableExamplesKo examples = TranslationsDocsComponentsSortableExamplesKo.internal(_root);
}

// Path: docs.components.star_rating
class TranslationsDocsComponentsStarRatingKo {
	TranslationsDocsComponentsStarRatingKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '별점'
	String get display_name => '별점';

	/// ko: '별점을 선택할 수 있습니다.'
	String get description => '별점을 선택할 수 있습니다.';

	late final TranslationsDocsComponentsStarRatingExamplesKo examples = TranslationsDocsComponentsStarRatingExamplesKo.internal(_root);
}

// Path: docs.components.stepper
class TranslationsDocsComponentsStepperKo {
	TranslationsDocsComponentsStepperKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스테퍼'
	String get display_name => '스테퍼';

	/// ko: '단계별 프로세스를 표시합니다.'
	String get description => '단계별 프로세스를 표시합니다.';

	late final TranslationsDocsComponentsStepperExamplesKo examples = TranslationsDocsComponentsStepperExamplesKo.internal(_root);

	/// ko: '1단계'
	String get step_1 => '1단계';

	/// ko: '2단계'
	String get step_2 => '2단계';

	/// ko: '3단계'
	String get step_3 => '3단계';

	/// ko: '단계 {n}'
	String step_n({required Object n}) => '단계 ${n}';

	/// ko: '선택적 단계'
	String get optional_step => '선택적 단계';

	/// ko: '가로'
	String get horizontal => '가로';

	/// ko: '세로'
	String get vertical => '세로';

	/// ko: '오류 전환'
	String get toggle_error => '오류 전환';

	/// ko: '원형'
	String get circle => '원형';

	/// ko: '원형 대체'
	String get circle_alt => '원형 대체';

	/// ko: '선형'
	String get line => '선형';

	/// ko: '작게'
	String get small => '작게';

	/// ko: '중간'
	String get medium => '중간';

	/// ko: '크게'
	String get large => '크게';
}

// Path: docs.components.steps
class TranslationsDocsComponentsStepsKo {
	TranslationsDocsComponentsStepsKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '단계'
	String get display_name => '단계';

	/// ko: '진행 상황을 단계로 표시합니다.'
	String get description => '진행 상황을 단계로 표시합니다.';

	late final TranslationsDocsComponentsStepsExamplesKo examples = TranslationsDocsComponentsStepsExamplesKo.internal(_root);
}

// Path: docs.components.swiper
class TranslationsDocsComponentsSwiperKo {
	TranslationsDocsComponentsSwiperKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스와이퍼'
	String get display_name => '스와이퍼';

	/// ko: '스와이프 가능한 컴포넌트입니다.'
	String get description => '스와이프 가능한 컴포넌트입니다.';

	late final TranslationsDocsComponentsSwiperExamplesKo examples = TranslationsDocsComponentsSwiperExamplesKo.internal(_root);
}

// Path: docs.components.k_switch
class TranslationsDocsComponentsKSwitchKo {
	TranslationsDocsComponentsKSwitchKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스위치'
	String get display_name => '스위치';

	/// ko: '켜기/끄기 스위치입니다.'
	String get description => '켜기/끄기 스위치입니다.';

	late final TranslationsDocsComponentsKSwitchExamplesKo examples = TranslationsDocsComponentsKSwitchExamplesKo.internal(_root);
}

// Path: docs.components.switcher
class TranslationsDocsComponentsSwitcherKo {
	TranslationsDocsComponentsSwitcherKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '전환기'
	String get display_name => '전환기';

	/// ko: '여러 뷰 간에 전환할 수 있습니다.'
	String get description => '여러 뷰 간에 전환할 수 있습니다.';

	late final TranslationsDocsComponentsSwitcherExamplesKo examples = TranslationsDocsComponentsSwitcherExamplesKo.internal(_root);

	/// ko: '방향 전환'
	String get switch_direction => '방향 전환';

	/// ko: '다음 항목'
	String get next_item => '다음 항목';
}

// Path: docs.components.tab_container
class TranslationsDocsComponentsTabContainerKo {
	TranslationsDocsComponentsTabContainerKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '탭 컨테이너'
	String get display_name => '탭 컨테이너';

	/// ko: '탭 선택 상태와 커스텀 렌더링을 관리하는 기본 컨테이너입니다.'
	String get description => '탭 선택 상태와 커스텀 렌더링을 관리하는 기본 컨테이너입니다.';

	late final TranslationsDocsComponentsTabContainerExamplesKo examples = TranslationsDocsComponentsTabContainerExamplesKo.internal(_root);
}

// Path: docs.components.tab_list
class TranslationsDocsComponentsTabListKo {
	TranslationsDocsComponentsTabListKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '탭 목록'
	String get display_name => '탭 목록';

	/// ko: '탭 목록 컴포넌트입니다.'
	String get description => '탭 목록 컴포넌트입니다.';

	late final TranslationsDocsComponentsTabListExamplesKo examples = TranslationsDocsComponentsTabListExamplesKo.internal(_root);
}

// Path: docs.components.tab_pane
class TranslationsDocsComponentsTabPaneKo {
	TranslationsDocsComponentsTabPaneKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '탭 패널'
	String get display_name => '탭 패널';

	/// ko: '탭 패널 컴포넌트입니다.'
	String get description => '탭 패널 컴포넌트입니다.';

	late final TranslationsDocsComponentsTabPaneExamplesKo examples = TranslationsDocsComponentsTabPaneExamplesKo.internal(_root);
}

// Path: docs.components.table
class TranslationsDocsComponentsTableKo {
	TranslationsDocsComponentsTableKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '테이블'
	String get display_name => '테이블';

	/// ko: '데이터를 테이블 형식으로 표시합니다.'
	String get description => '데이터를 테이블 형식으로 표시합니다.';

	late final TranslationsDocsComponentsTableExamplesKo examples = TranslationsDocsComponentsTableExamplesKo.internal(_root);

	/// ko: '송장'
	String get invoice => '송장';

	/// ko: '상태'
	String get status => '상태';

	/// ko: '방법'
	String get method => '방법';

	/// ko: '금액'
	String get amount => '금액';

	/// ko: '합계'
	String get total => '합계';

	/// ko: '지불됨'
	String get paid => '지불됨';

	/// ko: '대기 중'
	String get pending => '대기 중';

	/// ko: '미지불'
	String get unpaid => '미지불';

	/// ko: '신용 카드'
	String get credit_card => '신용 카드';

	/// ko: 'PayPal'
	String get paypal => 'PayPal';

	/// ko: '은행 송금'
	String get bank_transfer => '은행 송금';
}

// Path: docs.components.tabs
class TranslationsDocsComponentsTabsKo {
	TranslationsDocsComponentsTabsKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '탭'
	String get display_name => '탭';

	/// ko: '탭을 사용하여 콘텐츠를 구성합니다.'
	String get description => '탭을 사용하여 콘텐츠를 구성합니다.';

	late final TranslationsDocsComponentsTabsExamplesKo examples = TranslationsDocsComponentsTabsExamplesKo.internal(_root);

	/// ko: '탭 1'
	String get tab_1 => '탭 1';

	/// ko: '탭 2'
	String get tab_2 => '탭 2';

	/// ko: '탭 3'
	String get tab_3 => '탭 3';

	/// ko: '탭 {n}'
	String tab_n({required Object n}) => '탭 ${n}';
}

// Path: docs.components.text_area
class TranslationsDocsComponentsTextAreaKo {
	TranslationsDocsComponentsTextAreaKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '텍스트 영역'
	String get display_name => '텍스트 영역';

	/// ko: '여러 줄의 텍스트를 입력할 수 있습니다.'
	String get description => '여러 줄의 텍스트를 입력할 수 있습니다.';

	late final TranslationsDocsComponentsTextAreaExamplesKo examples = TranslationsDocsComponentsTextAreaExamplesKo.internal(_root);

	/// ko: '안녕하세요, 세계!'
	String get hello_world => '안녕하세요, 세계!';
}

// Path: docs.components.time_picker
class TranslationsDocsComponentsTimePickerKo {
	TranslationsDocsComponentsTimePickerKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '시간 선택기'
	String get display_name => '시간 선택기';

	/// ko: '시간을 선택할 수 있습니다.'
	String get description => '시간을 선택할 수 있습니다.';

	late final TranslationsDocsComponentsTimePickerExamplesKo examples = TranslationsDocsComponentsTimePickerExamplesKo.internal(_root);

	/// ko: '시간 선택'
	String get select_time => '시간 선택';
}

// Path: docs.components.timeline
class TranslationsDocsComponentsTimelineKo {
	TranslationsDocsComponentsTimelineKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '타임라인'
	String get display_name => '타임라인';

	/// ko: '이벤트를 타임라인으로 표시합니다.'
	String get description => '이벤트를 타임라인으로 표시합니다.';

	late final TranslationsDocsComponentsTimelineExamplesKo examples = TranslationsDocsComponentsTimelineExamplesKo.internal(_root);
}

// Path: docs.components.timeline_animation
class TranslationsDocsComponentsTimelineAnimationKo {
	TranslationsDocsComponentsTimelineAnimationKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '타임라인 애니메이션'
	String get display_name => '타임라인 애니메이션';

	/// ko: '타임라인 기반 애니메이션입니다.'
	String get description => '타임라인 기반 애니메이션입니다.';

	late final TranslationsDocsComponentsTimelineAnimationExamplesKo examples = TranslationsDocsComponentsTimelineAnimationExamplesKo.internal(_root);
}

// Path: docs.components.toast
class TranslationsDocsComponentsToastKo {
	TranslationsDocsComponentsToastKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '토스트'
	String get display_name => '토스트';

	/// ko: '짧은 메시지를 표시하는 알림입니다.'
	String get description => '짧은 메시지를 표시하는 알림입니다.';

	late final TranslationsDocsComponentsToastExamplesKo examples = TranslationsDocsComponentsToastExamplesKo.internal(_root);

	/// ko: '이벤트가 생성되었습니다'
	String get event_created => '이벤트가 생성되었습니다';

	/// ko: '2024년 7월 7일 일요일 오후 12:00'
	String get event_date => '2024년 7월 7일 일요일 오후 12:00';

	/// ko: '왼쪽 하단 토스트 표시'
	String get show_bottom_left => '왼쪽 하단 토스트 표시';

	/// ko: '오른쪽 하단 토스트 표시'
	String get show_bottom_right => '오른쪽 하단 토스트 표시';

	/// ko: '왼쪽 상단 토스트 표시'
	String get show_top_left => '왼쪽 상단 토스트 표시';

	/// ko: '오른쪽 상단 토스트 표시'
	String get show_top_right => '오른쪽 상단 토스트 표시';

	/// ko: '하단 중앙 토스트 표시'
	String get show_bottom_center => '하단 중앙 토스트 표시';

	/// ko: '상단 중앙 토스트 표시'
	String get show_top_center => '상단 중앙 토스트 표시';
}

// Path: docs.components.toggle
class TranslationsDocsComponentsToggleKo {
	TranslationsDocsComponentsToggleKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '토글'
	String get display_name => '토글';

	/// ko: '옵션 간에 토글할 수 있습니다.'
	String get description => '옵션 간에 토글할 수 있습니다.';

	late final TranslationsDocsComponentsToggleExamplesKo examples = TranslationsDocsComponentsToggleExamplesKo.internal(_root);

	/// ko: '토글'
	String get toggle => '토글';
}

// Path: docs.components.tooltip
class TranslationsDocsComponentsTooltipKo {
	TranslationsDocsComponentsTooltipKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '툴팁'
	String get display_name => '툴팁';

	/// ko: '요소에 대한 추가 정보를 표시합니다.'
	String get description => '요소에 대한 추가 정보를 표시합니다.';

	late final TranslationsDocsComponentsTooltipExamplesKo examples = TranslationsDocsComponentsTooltipExamplesKo.internal(_root);

	/// ko: '툴팁입니다.'
	String get this_is_tooltip => '툴팁입니다.';

	/// ko: '마우스를 올려보세요'
	String get hover_over_me => '마우스를 올려보세요';
}

// Path: docs.components.tracker
class TranslationsDocsComponentsTrackerKo {
	TranslationsDocsComponentsTrackerKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '트래커'
	String get display_name => '트래커';

	/// ko: '진행 상황을 추적합니다.'
	String get description => '진행 상황을 추적합니다.';

	late final TranslationsDocsComponentsTrackerExamplesKo examples = TranslationsDocsComponentsTrackerExamplesKo.internal(_root);

	/// ko: '양호'
	String get fine => '양호';

	/// ko: '경고'
	String get warning => '경고';

	/// ko: '위험'
	String get critical => '위험';

	/// ko: '알 수 없음'
	String get unknown => '알 수 없음';

	/// ko: '트래커 양호'
	String get tracker_fine => '트래커 양호';

	/// ko: '트래커 경고'
	String get tracker_warning => '트래커 경고';

	/// ko: '트래커 위험'
	String get tracker_critical => '트래커 위험';

	/// ko: '트래커 알 수 없음'
	String get tracker_unknown => '트래커 알 수 없음';
}

// Path: docs.components.tree
class TranslationsDocsComponentsTreeKo {
	TranslationsDocsComponentsTreeKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '트리'
	String get display_name => '트리';

	/// ko: '계층 구조 데이터를 트리 형식으로 표시합니다.'
	String get description => '계층 구조 데이터를 트리 형식으로 표시합니다.';

	late final TranslationsDocsComponentsTreeExamplesKo examples = TranslationsDocsComponentsTreeExamplesKo.internal(_root);
}

// Path: docs.components.window
class TranslationsDocsComponentsWindowKo {
	TranslationsDocsComponentsWindowKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '윈도우'
	String get display_name => '윈도우';

	/// ko: '데스크톱 스타일의 윈도우입니다.'
	String get description => '데스크톱 스타일의 윈도우입니다.';

	late final TranslationsDocsComponentsWindowExamplesKo examples = TranslationsDocsComponentsWindowExamplesKo.internal(_root);

	/// ko: '윈도우 1'
	String get window_1 => '윈도우 1';

	/// ko: '윈도우 2'
	String get window_2 => '윈도우 2';

	/// ko: '데스크톱'
	String get desktop => '데스크톱';

	/// ko: '윈도우 추가'
	String get add_window => '윈도우 추가';
}

// Path: docs.pages.introduction.features_list
class TranslationsDocsPagesIntroductionFeaturesListKo {
	TranslationsDocsPagesIntroductionFeaturesListKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '84개의 컴포넌트 및 계속 증가 중!'
	String get components_count => '84개의 컴포넌트 및 계속 증가 중!';

	/// ko: 'Material 및 Cupertino 위젯을 지원하며 테마가 현재 coui_flutter 테마에 맞게 조정됩니다.'
	String get material_cupertino => 'Material 및 Cupertino 위젯을 지원하며 테마가 현재 coui_flutter 테마에 맞게 조정됩니다.';

	/// ko: 'Coui/UI의 사전 제작된 테마.'
	String get premade_themes => 'Coui/UI의 사전 제작된 테마.';

	/// ko: '모바일, 웹 및 데스크톱 플랫폼 지원.'
	String get platform_support => '모바일, 웹 및 데스크톱 플랫폼 지원.';

	/// ko: '중간 드래그 스크롤 지원.'
	String get middle_drag => '중간 드래그 스크롤 지원.';

	/// ko: '타이포그래피를 위한 다양한 위젯 확장.'
	String get typography_extensions => '타이포그래피를 위한 다양한 위젯 확장.';

	/// ko: '더 나은 성능을 위한 WebAssembly 지원.'
	String get webassembly => '더 나은 성능을 위한 WebAssembly 지원.';
}

// Path: docs.components.accordion.examples
class TranslationsDocsComponentsAccordionExamplesKo {
	TranslationsDocsComponentsAccordionExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '아코디언 예제'
	String get basic => '아코디언 예제';
}

// Path: docs.components.alert.examples
class TranslationsDocsComponentsAlertExamplesKo {
	TranslationsDocsComponentsAlertExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '알림 예제'
	String get basic => '알림 예제';

	/// ko: '위험 알림 예제'
	String get destructive => '위험 알림 예제';
}

// Path: docs.components.empty_state.examples
class TranslationsDocsComponentsEmptyStateExamplesKo {
	TranslationsDocsComponentsEmptyStateExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '기본 빈 상태'
	String get basic => '기본 빈 상태';

	/// ko: '컴팩트 빈 상태'
	String get compact => '컴팩트 빈 상태';

	/// ko: '액션이 있는 빈 상태'
	String get with_action => '액션이 있는 빈 상태';
}

// Path: docs.components.fade_scroll.examples
class TranslationsDocsComponentsFadeScrollExamplesKo {
	TranslationsDocsComponentsFadeScrollExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '수직 페이드 스크롤'
	String get vertical => '수직 페이드 스크롤';

	/// ko: '수평 페이드 스크롤'
	String get horizontal => '수평 페이드 스크롤';
}

// Path: docs.components.validation_badge.examples
class TranslationsDocsComponentsValidationBadgeExamplesKo {
	TranslationsDocsComponentsValidationBadgeExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '유효성 상태'
	String get states => '유효성 상태';

	/// ko: 'Boolean 기반 생성'
	String get from_bool => 'Boolean 기반 생성';

	/// ko: '크기 변형'
	String get sizes => '크기 변형';
}

// Path: docs.components.banner.examples
class TranslationsDocsComponentsBannerExamplesKo {
	TranslationsDocsComponentsBannerExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '기본 배너'
	String get basic => '기본 배너';

	/// ko: '배너 변형'
	String get variants => '배너 변형';

	/// ko: '액션이 있는 배너'
	String get with_action => '액션이 있는 배너';
}

// Path: docs.components.alert_dialog.examples
class TranslationsDocsComponentsAlertDialogExamplesKo {
	TranslationsDocsComponentsAlertDialogExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '알림 다이얼로그 예제'
	String get basic => '알림 다이얼로그 예제';
}

// Path: docs.components.animated_value_builder.examples
class TranslationsDocsComponentsAnimatedValueBuilderExamplesKo {
	TranslationsDocsComponentsAnimatedValueBuilderExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '애니메이션 값 빌더 예제'
	String get basic => '애니메이션 값 빌더 예제';
}

// Path: docs.components.app_bar.examples
class TranslationsDocsComponentsAppBarExamplesKo {
	TranslationsDocsComponentsAppBarExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '앱 바 예제'
	String get basic => '앱 바 예제';
}

// Path: docs.components.fab.examples
class TranslationsDocsComponentsFabExamplesKo {
	TranslationsDocsComponentsFabExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '기본 FAB'
	String get basic => '기본 FAB';

	/// ko: '크기 변형'
	String get sizes => '크기 변형';

	/// ko: '스피드 다이얼'
	String get speed_dial => '스피드 다이얼';
}

// Path: docs.components.hover.examples
class TranslationsDocsComponentsHoverExamplesKo {
	TranslationsDocsComponentsHoverExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '기본 호버'
	String get basic => '기본 호버';

	/// ko: '호버 액티비티'
	String get activity => '호버 액티비티';
}

// Path: docs.components.scrollbar.examples
class TranslationsDocsComponentsScrollbarExamplesKo {
	TranslationsDocsComponentsScrollbarExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '기본 스크롤바'
	String get basic => '기본 스크롤바';
}

// Path: docs.components.autocomplete.examples
class TranslationsDocsComponentsAutocompleteExamplesKo {
	TranslationsDocsComponentsAutocompleteExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '자동완성 예제'
	String get basic => '자동완성 예제';
}

// Path: docs.components.avatar.examples
class TranslationsDocsComponentsAvatarExamplesKo {
	TranslationsDocsComponentsAvatarExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '아바타 예제'
	String get basic => '아바타 예제';
}

// Path: docs.components.avatar_group.examples
class TranslationsDocsComponentsAvatarGroupExamplesKo {
	TranslationsDocsComponentsAvatarGroupExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '아바타 그룹 예제'
	String get basic => '아바타 그룹 예제';
}

// Path: docs.components.badge.examples
class TranslationsDocsComponentsBadgeExamplesKo {
	TranslationsDocsComponentsBadgeExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '배지 예제'
	String get basic => '배지 예제';
}

// Path: docs.components.breadcrumb.examples
class TranslationsDocsComponentsBreadcrumbExamplesKo {
	TranslationsDocsComponentsBreadcrumbExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '브레드크럼 예제'
	String get basic => '브레드크럼 예제';
}

// Path: docs.components.button.examples
class TranslationsDocsComponentsButtonExamplesKo {
	TranslationsDocsComponentsButtonExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '기본 버튼 예제'
	String get primary => '기본 버튼 예제';

	/// ko: '보조 버튼 예제'
	String get secondary => '보조 버튼 예제';

	/// ko: '테두리 버튼 예제'
	String get outline => '테두리 버튼 예제';

	/// ko: '고스트 버튼 예제'
	String get ghost => '고스트 버튼 예제';

	/// ko: '위험 버튼 예제'
	String get destructive => '위험 버튼 예제';

	/// ko: '링크 버튼 예제'
	String get link => '링크 버튼 예제';

	/// ko: '텍스트 버튼 예제'
	String get text => '텍스트 버튼 예제';

	/// ko: '비활성 버튼 예제'
	String get disabled => '비활성 버튼 예제';

	/// ko: '아이콘 버튼 예제'
	String get icon => '아이콘 버튼 예제';

	/// ko: '라벨이 있는 아이콘 버튼 예제'
	String get icon_with_label => '라벨이 있는 아이콘 버튼 예제';

	/// ko: '버튼 크기 예제'
	String get size => '버튼 크기 예제';

	/// ko: '버튼 밀도 예제'
	String get density => '버튼 밀도 예제';

	/// ko: '버튼 모양 예제'
	String get shape => '버튼 모양 예제';

	/// ko: '버튼 그룹 예제'
	String get group => '버튼 그룹 예제';

	/// ko: '상태 버튼 예제'
	String get stated => '상태 버튼 예제';

	/// ko: '카드 버튼 예제'
	String get card => '카드 버튼 예제';

	/// ko: '커스텀 버튼 예제'
	String get custom => '커스텀 버튼 예제';
}

// Path: docs.components.calendar.examples
class TranslationsDocsComponentsCalendarExamplesKo {
	TranslationsDocsComponentsCalendarExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '캘린더 예제'
	String get basic => '캘린더 예제';
}

// Path: docs.components.card.examples
class TranslationsDocsComponentsCardExamplesKo {
	TranslationsDocsComponentsCardExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '카드 예제'
	String get basic => '카드 예제';
}

// Path: docs.components.card_image.examples
class TranslationsDocsComponentsCardImageExamplesKo {
	TranslationsDocsComponentsCardImageExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '이미지 카드 예제'
	String get basic => '이미지 카드 예제';
}

// Path: docs.components.carousel.examples
class TranslationsDocsComponentsCarouselExamplesKo {
	TranslationsDocsComponentsCarouselExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '캐러셀 예제'
	String get basic => '캐러셀 예제';
}

// Path: docs.components.checkbox.examples
class TranslationsDocsComponentsCheckboxExamplesKo {
	TranslationsDocsComponentsCheckboxExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '체크박스 예제'
	String get basic => '체크박스 예제';
}

// Path: docs.components.chip.examples
class TranslationsDocsComponentsChipExamplesKo {
	TranslationsDocsComponentsChipExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '칩 예제'
	String get basic => '칩 예제';
}

// Path: docs.components.chip_input.examples
class TranslationsDocsComponentsChipInputExamplesKo {
	TranslationsDocsComponentsChipInputExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '칩 입력 예제'
	String get basic => '칩 입력 예제';
}

// Path: docs.components.circular_progress.examples
class TranslationsDocsComponentsCircularProgressExamplesKo {
	TranslationsDocsComponentsCircularProgressExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '원형 진행률 예제'
	String get basic => '원형 진행률 예제';
}

// Path: docs.components.code_snippet.examples
class TranslationsDocsComponentsCodeSnippetExamplesKo {
	TranslationsDocsComponentsCodeSnippetExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '코드 스니펫 예제'
	String get basic => '코드 스니펫 예제';
}

// Path: docs.components.collapsible.examples
class TranslationsDocsComponentsCollapsibleExamplesKo {
	TranslationsDocsComponentsCollapsibleExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '접을 수 있는 예제'
	String get basic => '접을 수 있는 예제';
}

// Path: docs.components.color_picker.examples
class TranslationsDocsComponentsColorPickerExamplesKo {
	TranslationsDocsComponentsColorPickerExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '색상 선택기 예제'
	String get basic => '색상 선택기 예제';
}

// Path: docs.components.command.examples
class TranslationsDocsComponentsCommandExamplesKo {
	TranslationsDocsComponentsCommandExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '커맨드 예제'
	String get basic => '커맨드 예제';
}

// Path: docs.components.context_menu.examples
class TranslationsDocsComponentsContextMenuExamplesKo {
	TranslationsDocsComponentsContextMenuExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '컨텍스트 메뉴 예제'
	String get basic => '컨텍스트 메뉴 예제';
}

// Path: docs.components.date_picker.examples
class TranslationsDocsComponentsDatePickerExamplesKo {
	TranslationsDocsComponentsDatePickerExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '날짜 선택기 예제'
	String get basic => '날짜 선택기 예제';
}

// Path: docs.components.dialog.examples
class TranslationsDocsComponentsDialogExamplesKo {
	TranslationsDocsComponentsDialogExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '다이얼로그 예제'
	String get basic => '다이얼로그 예제';
}

// Path: docs.components.divider.examples
class TranslationsDocsComponentsDividerExamplesKo {
	TranslationsDocsComponentsDividerExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '구분선 예제'
	String get basic => '구분선 예제';
}

// Path: docs.components.dot_indicator.examples
class TranslationsDocsComponentsDotIndicatorExamplesKo {
	TranslationsDocsComponentsDotIndicatorExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '점 표시기 예제'
	String get basic => '점 표시기 예제';
}

// Path: docs.components.drawer.examples
class TranslationsDocsComponentsDrawerExamplesKo {
	TranslationsDocsComponentsDrawerExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '드로어 예제'
	String get basic => '드로어 예제';
}

// Path: docs.components.dropdown_menu.examples
class TranslationsDocsComponentsDropdownMenuExamplesKo {
	TranslationsDocsComponentsDropdownMenuExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '드롭다운 메뉴 예제'
	String get basic => '드롭다운 메뉴 예제';
}

// Path: docs.components.expandable_sidebar.examples
class TranslationsDocsComponentsExpandableSidebarExamplesKo {
	TranslationsDocsComponentsExpandableSidebarExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '확장 가능한 사이드바 예제'
	String get basic => '확장 가능한 사이드바 예제';
}

// Path: docs.components.form.examples
class TranslationsDocsComponentsFormExamplesKo {
	TranslationsDocsComponentsFormExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '폼 예제 (테이블 레이아웃)'
	String get table_layout => '폼 예제 (테이블 레이아웃)';

	/// ko: '폼 예제 (컬럼 레이아웃)'
	String get column_layout => '폼 예제 (컬럼 레이아웃)';

	/// ko: '유효성 검사 모드 예제'
	String get validation_mode => '유효성 검사 모드 예제';
}

// Path: docs.components.formatted_input.examples
class TranslationsDocsComponentsFormattedInputExamplesKo {
	TranslationsDocsComponentsFormattedInputExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '포맷 입력 예제'
	String get basic => '포맷 입력 예제';
}

// Path: docs.components.hover_card.examples
class TranslationsDocsComponentsHoverCardExamplesKo {
	TranslationsDocsComponentsHoverCardExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '호버 카드 예제'
	String get basic => '호버 카드 예제';
}

// Path: docs.components.input.examples
class TranslationsDocsComponentsInputExamplesKo {
	TranslationsDocsComponentsInputExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '입력 예제'
	String get basic => '입력 예제';
}

// Path: docs.components.input_otp.examples
class TranslationsDocsComponentsInputOtpExamplesKo {
	TranslationsDocsComponentsInputOtpExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'OTP 입력 예제'
	String get basic => 'OTP 입력 예제';
}

// Path: docs.components.item_picker.examples
class TranslationsDocsComponentsItemPickerExamplesKo {
	TranslationsDocsComponentsItemPickerExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '항목 선택기 예제'
	String get basic => '항목 선택기 예제';
}

// Path: docs.components.keyboard_display.examples
class TranslationsDocsComponentsKeyboardDisplayExamplesKo {
	TranslationsDocsComponentsKeyboardDisplayExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '키보드 표시 예제'
	String get basic => '키보드 표시 예제';
}

// Path: docs.components.linear_progress.examples
class TranslationsDocsComponentsLinearProgressExamplesKo {
	TranslationsDocsComponentsLinearProgressExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '선형 진행률 예제'
	String get basic => '선형 진행률 예제';
}

// Path: docs.components.material.examples
class TranslationsDocsComponentsMaterialExamplesKo {
	TranslationsDocsComponentsMaterialExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: 'Material/Cupertino 예제'
	String get basic => 'Material/Cupertino 예제';
}

// Path: docs.components.menubar.examples
class TranslationsDocsComponentsMenubarExamplesKo {
	TranslationsDocsComponentsMenubarExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '메뉴바 예제'
	String get basic => '메뉴바 예제';
}

// Path: docs.components.multiselect.examples
class TranslationsDocsComponentsMultiselectExamplesKo {
	TranslationsDocsComponentsMultiselectExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '다중 선택 예제'
	String get basic => '다중 선택 예제';
}

// Path: docs.components.navigation_bar.examples
class TranslationsDocsComponentsNavigationBarExamplesKo {
	TranslationsDocsComponentsNavigationBarExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '네비게이션 바 예제'
	String get basic => '네비게이션 바 예제';
}

// Path: docs.components.navigation_menu.examples
class TranslationsDocsComponentsNavigationMenuExamplesKo {
	TranslationsDocsComponentsNavigationMenuExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '네비게이션 메뉴 예제'
	String get basic => '네비게이션 메뉴 예제';
}

// Path: docs.components.navigation_rail.examples
class TranslationsDocsComponentsNavigationRailExamplesKo {
	TranslationsDocsComponentsNavigationRailExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '네비게이션 레일 예제'
	String get basic => '네비게이션 레일 예제';
}

// Path: docs.components.navigation_sidebar.examples
class TranslationsDocsComponentsNavigationSidebarExamplesKo {
	TranslationsDocsComponentsNavigationSidebarExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '네비게이션 사이드바 예제'
	String get basic => '네비게이션 사이드바 예제';
}

// Path: docs.components.number_input.examples
class TranslationsDocsComponentsNumberInputExamplesKo {
	TranslationsDocsComponentsNumberInputExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '숫자 입력 예제'
	String get basic => '숫자 입력 예제';
}

// Path: docs.components.number_ticker.examples
class TranslationsDocsComponentsNumberTickerExamplesKo {
	TranslationsDocsComponentsNumberTickerExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '숫자 티커 예제'
	String get basic => '숫자 티커 예제';
}

// Path: docs.components.overflow_marquee.examples
class TranslationsDocsComponentsOverflowMarqueeExamplesKo {
	TranslationsDocsComponentsOverflowMarqueeExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '오버플로우 마키 예제'
	String get basic => '오버플로우 마키 예제';
}

// Path: docs.components.pagination.examples
class TranslationsDocsComponentsPaginationExamplesKo {
	TranslationsDocsComponentsPaginationExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '페이지네이션 예제'
	String get basic => '페이지네이션 예제';
}

// Path: docs.components.phone_input.examples
class TranslationsDocsComponentsPhoneInputExamplesKo {
	TranslationsDocsComponentsPhoneInputExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '전화번호 입력 예제'
	String get basic => '전화번호 입력 예제';
}

// Path: docs.components.popover.examples
class TranslationsDocsComponentsPopoverExamplesKo {
	TranslationsDocsComponentsPopoverExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '팝오버 예제'
	String get basic => '팝오버 예제';
}

// Path: docs.components.progress.examples
class TranslationsDocsComponentsProgressExamplesKo {
	TranslationsDocsComponentsProgressExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '진행률 예제'
	String get basic => '진행률 예제';
}

// Path: docs.components.radio_card.examples
class TranslationsDocsComponentsRadioCardExamplesKo {
	TranslationsDocsComponentsRadioCardExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '라디오 카드 예제'
	String get basic => '라디오 카드 예제';
}

// Path: docs.components.radio_group.examples
class TranslationsDocsComponentsRadioGroupExamplesKo {
	TranslationsDocsComponentsRadioGroupExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '라디오 그룹 예제'
	String get basic => '라디오 그룹 예제';
}

// Path: docs.components.refresh_trigger.examples
class TranslationsDocsComponentsRefreshTriggerExamplesKo {
	TranslationsDocsComponentsRefreshTriggerExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '새로고침 트리거 예제'
	String get basic => '새로고침 트리거 예제';
}

// Path: docs.components.repeated_animation_builder.examples
class TranslationsDocsComponentsRepeatedAnimationBuilderExamplesKo {
	TranslationsDocsComponentsRepeatedAnimationBuilderExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '반복 애니메이션 빌더 예제'
	String get basic => '반복 애니메이션 빌더 예제';
}

// Path: docs.components.resizable.examples
class TranslationsDocsComponentsResizableExamplesKo {
	TranslationsDocsComponentsResizableExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '크기 조절 가능 예제'
	String get basic => '크기 조절 가능 예제';
}

// Path: docs.components.scaffold.examples
class TranslationsDocsComponentsScaffoldExamplesKo {
	TranslationsDocsComponentsScaffoldExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스캐폴드 예제'
	String get basic => '스캐폴드 예제';
}

// Path: docs.components.select.examples
class TranslationsDocsComponentsSelectExamplesKo {
	TranslationsDocsComponentsSelectExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '선택 예제'
	String get basic => '선택 예제';
}

// Path: docs.components.sheet.examples
class TranslationsDocsComponentsSheetExamplesKo {
	TranslationsDocsComponentsSheetExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '시트 예제'
	String get basic => '시트 예제';
}

// Path: docs.components.skeleton.examples
class TranslationsDocsComponentsSkeletonExamplesKo {
	TranslationsDocsComponentsSkeletonExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스켈레톤 예제'
	String get basic => '스켈레톤 예제';
}

// Path: docs.components.slider.examples
class TranslationsDocsComponentsSliderExamplesKo {
	TranslationsDocsComponentsSliderExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '슬라이더 예제'
	String get basic => '슬라이더 예제';
}

// Path: docs.components.sortable.examples
class TranslationsDocsComponentsSortableExamplesKo {
	TranslationsDocsComponentsSortableExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '정렬 가능 예제'
	String get basic => '정렬 가능 예제';
}

// Path: docs.components.star_rating.examples
class TranslationsDocsComponentsStarRatingExamplesKo {
	TranslationsDocsComponentsStarRatingExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '별점 예제'
	String get basic => '별점 예제';
}

// Path: docs.components.stepper.examples
class TranslationsDocsComponentsStepperExamplesKo {
	TranslationsDocsComponentsStepperExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스테퍼 예제'
	String get basic => '스테퍼 예제';
}

// Path: docs.components.steps.examples
class TranslationsDocsComponentsStepsExamplesKo {
	TranslationsDocsComponentsStepsExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '단계 예제'
	String get basic => '단계 예제';
}

// Path: docs.components.swiper.examples
class TranslationsDocsComponentsSwiperExamplesKo {
	TranslationsDocsComponentsSwiperExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스와이퍼 예제'
	String get basic => '스와이퍼 예제';
}

// Path: docs.components.k_switch.examples
class TranslationsDocsComponentsKSwitchExamplesKo {
	TranslationsDocsComponentsKSwitchExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '스위치 예제'
	String get basic => '스위치 예제';
}

// Path: docs.components.switcher.examples
class TranslationsDocsComponentsSwitcherExamplesKo {
	TranslationsDocsComponentsSwitcherExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '전환기 예제'
	String get basic => '전환기 예제';
}

// Path: docs.components.tab_container.examples
class TranslationsDocsComponentsTabContainerExamplesKo {
	TranslationsDocsComponentsTabContainerExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '탭 컨테이너 예제'
	String get basic => '탭 컨테이너 예제';
}

// Path: docs.components.tab_list.examples
class TranslationsDocsComponentsTabListExamplesKo {
	TranslationsDocsComponentsTabListExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '탭 목록 예제'
	String get basic => '탭 목록 예제';
}

// Path: docs.components.tab_pane.examples
class TranslationsDocsComponentsTabPaneExamplesKo {
	TranslationsDocsComponentsTabPaneExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '탭 패널 예제'
	String get basic => '탭 패널 예제';
}

// Path: docs.components.table.examples
class TranslationsDocsComponentsTableExamplesKo {
	TranslationsDocsComponentsTableExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '테이블 예제'
	String get basic => '테이블 예제';
}

// Path: docs.components.tabs.examples
class TranslationsDocsComponentsTabsExamplesKo {
	TranslationsDocsComponentsTabsExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '탭 예제'
	String get basic => '탭 예제';
}

// Path: docs.components.text_area.examples
class TranslationsDocsComponentsTextAreaExamplesKo {
	TranslationsDocsComponentsTextAreaExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '텍스트 영역 예제'
	String get basic => '텍스트 영역 예제';
}

// Path: docs.components.time_picker.examples
class TranslationsDocsComponentsTimePickerExamplesKo {
	TranslationsDocsComponentsTimePickerExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '시간 선택기 예제'
	String get basic => '시간 선택기 예제';
}

// Path: docs.components.timeline.examples
class TranslationsDocsComponentsTimelineExamplesKo {
	TranslationsDocsComponentsTimelineExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '타임라인 예제'
	String get basic => '타임라인 예제';
}

// Path: docs.components.timeline_animation.examples
class TranslationsDocsComponentsTimelineAnimationExamplesKo {
	TranslationsDocsComponentsTimelineAnimationExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '타임라인 애니메이션 예제'
	String get basic => '타임라인 애니메이션 예제';
}

// Path: docs.components.toast.examples
class TranslationsDocsComponentsToastExamplesKo {
	TranslationsDocsComponentsToastExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '토스트 예제'
	String get basic => '토스트 예제';
}

// Path: docs.components.toggle.examples
class TranslationsDocsComponentsToggleExamplesKo {
	TranslationsDocsComponentsToggleExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '토글 예제'
	String get basic => '토글 예제';
}

// Path: docs.components.tooltip.examples
class TranslationsDocsComponentsTooltipExamplesKo {
	TranslationsDocsComponentsTooltipExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '툴팁 예제'
	String get basic => '툴팁 예제';
}

// Path: docs.components.tracker.examples
class TranslationsDocsComponentsTrackerExamplesKo {
	TranslationsDocsComponentsTrackerExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '트래커 예제'
	String get basic => '트래커 예제';
}

// Path: docs.components.tree.examples
class TranslationsDocsComponentsTreeExamplesKo {
	TranslationsDocsComponentsTreeExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '트리 예제'
	String get basic => '트리 예제';
}

// Path: docs.components.window.examples
class TranslationsDocsComponentsWindowExamplesKo {
	TranslationsDocsComponentsWindowExamplesKo.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// ko: '윈도우 예제'
	String get basic => '윈도우 예제';
}
