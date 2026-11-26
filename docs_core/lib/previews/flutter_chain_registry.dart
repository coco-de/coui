// GENERATED — dart run tool/generate_chain_artifacts.dart (write mode).
// Do not hand-edit; edit the `*StyleChain` extension sources and regenerate.

/// Flutter 순열 렌더러 registry — T1 컴포넌트 전수.
///
/// **클라이언트 경로 전용 import**: 이 파일은 Flutter Widget 을
/// 나르므로 SSG(서버) 경로가 import 하면 서버 빌드에 `dart:ui` 가
/// 유입된다. 서버가 읽는 T1 판정은 `shared/chain_tier1.dart`
/// name-set 하나이고, 이 registry 는 임베드 위젯
/// (`preview_app.dart`) 쪽에서만 도달한다.
library;

import 'package:coui_flutter/coui_flutter.dart' show Widget;

import '../shared/chain_permutations.dart';
import 'examples/flutter/accordion/accordion_chain_permutations.dart';
import 'examples/flutter/alert/alert_chain_permutations.dart';
import 'examples/flutter/avatar/avatar_chain_permutations.dart';
import 'examples/flutter/badge/badge_chain_permutations.dart';
import 'examples/flutter/banner/banner_chain_permutations.dart';
import 'examples/flutter/button/button_chain_permutations.dart';
import 'examples/flutter/card/card_chain_permutations.dart';
import 'examples/flutter/card_image/card_image_chain_permutations.dart';
import 'examples/flutter/chip/chip_chain_permutations.dart';
import 'examples/flutter/chip_input/chip_input_chain_permutations.dart';
import 'examples/flutter/code_snippet/code_snippet_chain_permutations.dart';
import 'examples/flutter/command/command_chain_permutations.dart';
import 'examples/flutter/description_card/description_card_chain_permutations.dart';
import 'examples/flutter/fieldset/fieldset_chain_permutations.dart';
import 'examples/flutter/file_input/file_input_chain_permutations.dart';
import 'examples/flutter/filter/filter_chain_permutations.dart';
import 'examples/flutter/formatted_input/formatted_input_chain_permutations.dart';
import 'examples/flutter/frame/frame_chain_permutations.dart';
import 'examples/flutter/hover_card/hover_card_chain_permutations.dart';
import 'examples/flutter/input_otp/input_otp_chain_permutations.dart';
import 'examples/flutter/item_picker/item_picker_chain_permutations.dart';
import 'examples/flutter/multi_answer_card/multi_answer_card_chain_permutations.dart';
import 'examples/flutter/object_input/object_input_chain_permutations.dart';
import 'examples/flutter/outlined_container/outlined_container_chain_permutations.dart';
import 'examples/flutter/phone_input/phone_input_chain_permutations.dart';
import 'examples/flutter/popup/popup_chain_permutations.dart';
import 'examples/flutter/progress/progress_chain_permutations.dart';
import 'examples/flutter/skeleton/skeleton_chain_permutations.dart';
import 'examples/flutter/stat/stat_chain_permutations.dart';
import 'examples/flutter/tab_pane/tab_pane_chain_permutations.dart';
import 'examples/flutter/table/table_chain_permutations.dart';
import 'examples/flutter/text_area/text_area_chain_permutations.dart';
import 'examples/flutter/text_field/text_field_chain_permutations.dart';

/// 순열 좌표를 받아 chain 프리뷰를 만드는 렌더러.
typedef FlutterChainRenderer = Widget Function(ChainPermutation permutation);

/// T1 컴포넌트 slug → 순열 렌더러. 키 집합 ≡ `kChainTier1Components`
/// (drift 는 unit 테스트가 가드).
final Map<String, FlutterChainRenderer> kFlutterChainRegistry = {
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
