// GENERATED — dart run tool/generate_chain_artifacts.dart (write mode).
// Do not hand-edit; edit the `*StyleChain` extension sources and regenerate.

/// Web 순열 렌더러 registry — T1 컴포넌트 전수.
///
/// jaspr Component 는 서버에서도 컴파일되므로(SSG 초기 렌더) 서버
/// 경로 유입 자체는 무해하다 — 단 SSG 의 T1 **판정**은 여전히
/// `shared/chain_tier1.dart` name-set 을 쓴다 (판정 단일 출처).
library;

import 'package:coui_web/coui_web.dart' show Component;

import '../shared/chain_permutations.dart';
import 'examples/web/accordion/accordion_chain_permutations.dart';
import 'examples/web/alert/alert_chain_permutations.dart';
import 'examples/web/avatar/avatar_chain_permutations.dart';
import 'examples/web/badge/badge_chain_permutations.dart';
import 'examples/web/banner/banner_chain_permutations.dart';
import 'examples/web/button/button_chain_permutations.dart';
import 'examples/web/card/card_chain_permutations.dart';
import 'examples/web/card_image/card_image_chain_permutations.dart';
import 'examples/web/chip/chip_chain_permutations.dart';
import 'examples/web/chip_input/chip_input_chain_permutations.dart';
import 'examples/web/code_snippet/code_snippet_chain_permutations.dart';
import 'examples/web/command/command_chain_permutations.dart';
import 'examples/web/description_card/description_card_chain_permutations.dart';
import 'examples/web/fieldset/fieldset_chain_permutations.dart';
import 'examples/web/file_input/file_input_chain_permutations.dart';
import 'examples/web/filter/filter_chain_permutations.dart';
import 'examples/web/formatted_input/formatted_input_chain_permutations.dart';
import 'examples/web/frame/frame_chain_permutations.dart';
import 'examples/web/hover_card/hover_card_chain_permutations.dart';
import 'examples/web/input_otp/input_otp_chain_permutations.dart';
import 'examples/web/item_picker/item_picker_chain_permutations.dart';
import 'examples/web/multi_answer_card/multi_answer_card_chain_permutations.dart';
import 'examples/web/object_input/object_input_chain_permutations.dart';
import 'examples/web/outlined_container/outlined_container_chain_permutations.dart';
import 'examples/web/phone_input/phone_input_chain_permutations.dart';
import 'examples/web/popup/popup_chain_permutations.dart';
import 'examples/web/progress/progress_chain_permutations.dart';
import 'examples/web/skeleton/skeleton_chain_permutations.dart';
import 'examples/web/stat/stat_chain_permutations.dart';
import 'examples/web/tab_pane/tab_pane_chain_permutations.dart';
import 'examples/web/table/table_chain_permutations.dart';
import 'examples/web/text_area/text_area_chain_permutations.dart';
import 'examples/web/text_field/text_field_chain_permutations.dart';

/// 순열 좌표를 받아 chain 프리뷰를 만드는 렌더러.
typedef WebChainRenderer = Component Function(ChainPermutation permutation);

/// T1 컴포넌트 slug → 순열 렌더러. 키 집합 ≡ `kChainTier1Components`
/// (drift 는 unit 테스트가 가드).
final Map<String, WebChainRenderer> kWebChainRegistry = {
  'accordion': buildAccordionChainPermutation,
  'alert': buildAlertChainPermutation,
  'avatar': buildAvatarChainPermutation,
  'badge': buildBadgeChainPermutation,
  'banner': buildBannerChainPermutation,
  'button': buildButtonChainPermutation,
  'card': buildCardChainPermutation,
  'card-image': buildCardImageChainPermutation,
  'chip': buildChipChainPermutation,
  'chip-input': buildChipInputChainPermutation,
  'code-snippet': buildCodeSnippetChainPermutation,
  'command': buildCommandChainPermutation,
  'description-card': buildDescriptionCardChainPermutation,
  'fieldset': buildFieldsetChainPermutation,
  'file-input': buildFileInputChainPermutation,
  'filter': buildFilterChainPermutation,
  'formatted-input': buildFormattedInputChainPermutation,
  'frame': buildFrameChainPermutation,
  'hover-card': buildHoverCardChainPermutation,
  'input-otp': buildInputOtpChainPermutation,
  'item-picker': buildItemPickerChainPermutation,
  'multi-answer-card': buildMultiAnswerCardChainPermutation,
  'object-input': buildObjectInputChainPermutation,
  'outlined-container': buildOutlinedContainerChainPermutation,
  'phone-input': buildPhoneInputChainPermutation,
  'popup': buildPopupChainPermutation,
  'progress': buildProgressChainPermutation,
  'skeleton': buildSkeletonChainPermutation,
  'stat': buildStatChainPermutation,
  'tab-pane': buildTabPaneChainPermutation,
  'table': buildTableChainPermutation,
  'text-area': buildTextAreaChainPermutation,
  'text-field': buildTextFieldChainPermutation,
};
