// Control components
import 'package:coui_web/src/components/control/button/button_style.dart';

// Display components
import 'package:coui_web/src/components/display/alert/alert_style.dart';
import 'package:coui_web/src/components/display/avatar/avatar_style.dart';
import 'package:coui_web/src/components/display/badge/badge_style.dart';
import 'package:coui_web/src/components/display/chip/chip_style.dart';
import 'package:coui_web/src/components/display/divider/divider_style.dart';
import 'package:coui_web/src/components/display/loading/loading_style.dart';
import 'package:coui_web/src/components/display/progress/progress_style.dart';
import 'package:coui_web/src/components/display/skeleton/skeleton_style.dart';

// Form components
import 'package:coui_web/src/components/form/checkbox/checkbox_style.dart';
import 'package:coui_web/src/components/form/input/input_style.dart';
import 'package:coui_web/src/components/form/radio/radio_style.dart';
import 'package:coui_web/src/components/form/select/select_style.dart';
import 'package:coui_web/src/components/form/slider/slider_style.dart';
import 'package:coui_web/src/components/form/textarea/textarea_style.dart';
import 'package:coui_web/src/components/form/toggle/toggle_style.dart';

// Icon components
import 'package:coui_web/src/components/icon/icon_style.dart';

// Layout components
import 'package:coui_web/src/components/layout/card/card_style.dart';

// Text components
import 'package:coui_web/src/components/text/link/link_style.dart';

mixin AllComponentStylings
    implements
        // Control
        ButtonStyling,
        // Display
        AlertStyling,
        AvatarStyling,
        BadgeStyling,
        ChipStyling,
        DividerStyling,
        LoadingStyling,
        ProgressStyling,
        SkeletonStyling,
        // Form
        CheckboxStyling,
        InputStyling,
        RadioStyling,
        SelectStyling,
        SliderStyling,
        TextareaStyling,
        ToggleStyling,
        // Icon
        IconStyling,
        // Layout
        CardStyling,
        // Text
        LinkStyling {
  // Empty mixin - only Interface
}
