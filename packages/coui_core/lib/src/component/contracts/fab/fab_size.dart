/// FAB-specific size variants.
///
/// Each size maps to a distinct circular button dimension shared by
/// Flutter and Web. Logical pixel values come from the `CoreSize`
/// scale so both platforms render an identical footprint.
library;

import 'package:coui_core/src/size/component_size.dart';

/// Size options for a `Fab`.
enum CoreFabSize {
  /// Mini FAB (48dp).
  ///
  /// 48, not 40. `touch-target`(터치 화면의 권장 크기)은 48 이고, FAB 은
  /// 그 권장을 깨면서까지 작아질 이유가 없다 — Checkbox 처럼 광학 크기를
  /// 요구하는 형태가 아니다. 40 이던 시절에는 히트박스가 그리는 크기보다 커서 화면
  /// 가장자리 마진 16 과 합쳐도 히트박스가 화면 밖으로 나갔다.
  mini,

  /// Regular FAB (56dp) — the default.
  regular,

  /// Large FAB (72dp).
  large;

  /// Widget default size. Flutter / Web `Fab` constructors reference
  /// this so neither platform diverges silently.
  static const CoreFabSize defaultSize = regular;

  /// The composed `Button` size an **Extended** FAB of this size takes.
  ///
  /// Extended FAB 은 라벨을 가진 알약이고, 그 높이·라벨 크기 사다리는
  /// `Button` 이 이미 갖고 있다 — 48 은 `lg`, 56 은 `xl`, 72 는 `xl2` 다.
  /// FAB 이 자기 라벨 롤을 따로 정하면 같은 높이의 Button 과 다른 답을
  /// 갖게 되므로, 높이로 Button 사이즈를 고르고 라벨은 거기서 상속받는다.
  /// (좌우 패딩만 덮어쓴다 — Button 의 lg/xl/xl2 패딩은 폼과 행에 놓이는
  /// 버튼용이라 콘텐츠 위에 뜨는 FAB 에는 과하다.)
  ///
  /// Core enum → Core enum 이라 source enum 의 메서드로 둔다
  /// (`resolver/resolver-pattern.md` — 플랫폼 어휘가 아니므로 adapter 가
  /// 아니라 여기).
  CoreComponentSize toExtendedButtonSize() => switch (this) {
    mini => CoreComponentSize.lg,
    regular => CoreComponentSize.xl,
    large => CoreComponentSize.xl2,
  };
}
