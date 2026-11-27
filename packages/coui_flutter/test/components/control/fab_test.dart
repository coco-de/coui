import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('Fab', () {
    testWidgets('renders the trigger widget', (tester) async {
      await pumpTestApp(
        tester,
        Fab(
          trigger: const Icon(LucideIcons.plus),
          onPressed: () {},
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('fires onPressed when there are no actions', (tester) async {
      var pressed = false;
      await pumpTestApp(
        tester,
        Fab(
          trigger: const Icon(LucideIcons.plus),
          onPressed: () => pressed = true,
        ),
      );

      await tester.tap(find.byType(Fab));
      final _ = await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('renders with the default regular size', (tester) async {
      await pumpTestApp(
        tester,
        Fab(
          trigger: const Icon(LucideIcons.plus),
          onPressed: () {},
        ),
      );

      expect(find.byType(Fab), findsOneWidget);
    });

    testWidgets('renders with mini size', (tester) async {
      await pumpTestApp(
        tester,
        Fab(
          trigger: const Icon(LucideIcons.plus),
          size: .mini,
          onPressed: () {},
        ),
      );

      expect(find.byType(Fab), findsOneWidget);
    });

    testWidgets('renders with large size', (tester) async {
      await pumpTestApp(
        tester,
        Fab(
          trigger: const Icon(LucideIcons.plus),
          size: .large,
          onPressed: () {},
        ),
      );

      expect(find.byType(Fab), findsOneWidget);
    });

    testWidgets('renders speed-dial action labels', (tester) async {
      await pumpTestApp(
        tester,
        const Fab(
          trigger: Icon(LucideIcons.plus),
          open: true,
          actions: [
            FabAction(
              icon: Icon(LucideIcons.pencil),
              label: Text('Edit'),
            ),
            FabAction(
              icon: Icon(LucideIcons.share),
              label: Text('Share'),
            ),
          ],
        ),
      );
      // The expanded actions render in a composed `Popover` overlay whose
      // shared engine runs a `follow` re-anchor ticker (a frame stays
      // scheduled while open), so `pumpAndSettle` never settles. Finite
      // pumps mount + settle the panel instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('toggles speed dial open state on tap', (tester) async {
      await pumpTestApp(
        tester,
        const Fab(
          trigger: Icon(LucideIcons.plus),
          actions: [
            FabAction(icon: Icon(LucideIcons.pencil)),
          ],
        ),
      );

      // Uncontrolled toggle — tapping the main FAB flips internal state and
      // opens the composed `Popover` overlay. Finite pumps instead of
      // `pumpAndSettle` (the overlay's `follow` ticker keeps a frame
      // scheduled while open, so `pumpAndSettle` never settles).
      await tester.tap(find.byType(Fab));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Fab), findsOneWidget);
    });

    testWidgets('invokes onOpenChanged in controlled mode', (tester) async {
      bool? requested;
      await pumpTestApp(
        tester,
        Fab(
          trigger: const Icon(LucideIcons.plus),
          onOpenChanged: (value) => requested = value,
          actions: const [
            FabAction(icon: Icon(LucideIcons.pencil)),
          ],
        ),
      );

      await tester.tap(find.byType(Fab));
      final _ = await tester.pumpAndSettle();

      expect(requested, isTrue);
    });
  });

  group('CoreFab enums', () {
    test('CoreFabExpandDirection has the expected values', () {
      expect(CoreFabExpandDirection.values.length, greaterThan(0));
      expect(
        CoreFabExpandDirection.defaultDirection,
        CoreFabExpandDirection.up,
      );
    });

    test('CoreFabSize has the expected values', () {
      expect(CoreFabSize.values.length, greaterThan(0));
      expect(CoreFabSize.defaultSize, CoreFabSize.regular);
    });
  });

  group('CoreFabStyle', () {
    test('merge overrides only non-null fields', () {
      const base = CoreFabStyle(spacing: CoreSpace.space16);
      const override = CoreFabStyle(
        actionItemStyle: CoreMenuItemStyle(
          leadingIconStyle: CoreIconStyle(size: CoreIconSize.size20),
        ),
      );
      final merged = base.merge(override);

      expect(merged.spacing, CoreSpace.space16);
      expect(
        merged.actionItemStyle,
        const CoreMenuItemStyle(
          leadingIconStyle: CoreIconStyle(size: CoreIconSize.size20),
        ),
      );
    });

    test('copyWith replaces the supplied field', () {
      const style = CoreFabStyle(spacing: CoreSpace.space16);
      final copy = style.copyWith(spacing: CoreSpace.space24);

      expect(copy.spacing, CoreSpace.space24);
    });

    test('equality compares all fields', () {
      const a = CoreFabStyle(spacing: CoreSpace.space16);
      const b = CoreFabStyle(spacing: CoreSpace.space16);
      const c = CoreFabStyle(spacing: CoreSpace.space24);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('CoreFabTheme', () {
    test('creates with default null values', () {
      const theme = CoreFabTheme();

      expect(theme.style, isNull);
    });

    test('equality compares style', () {
      const a = CoreFabTheme(style: CoreFabStyle(spacing: CoreSpace.space16));
      const b = CoreFabTheme(style: CoreFabStyle(spacing: CoreSpace.space16));
      const c = CoreFabTheme(style: CoreFabStyle(spacing: CoreSpace.space24));

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('FAB 리디자인 (디자이너 확정 · Figma ❖ Fab)', () {
    test('mini 는 48 — touch-target 하한을 깨지 않는다', () {
      // 40 이던 시절에는 히트박스가 그리는 크기보다 커서, 화면 가장자리
      // 마진과 합쳐도 히트박스가 화면 밖으로 나갔다.
      expect(
        CoreFabStyle.defaultsBySize[CoreFabSize.mini]!.diameter,
        CoreSize.size48,
      );
      expect(
        CoreFabStyle.defaultsBySize[CoreFabSize.regular]!.diameter,
        CoreSize.size56,
      );
      expect(
        CoreFabStyle.defaultsBySize[CoreFabSize.large]!.diameter,
        CoreSize.size72,
      );
    });

    test('아이콘이 지름을 따라간다 — 24 / 24 / 28', () {
      // Figma 는 세 사이즈 모두 24 다(swap 슬롯의 기본값을 세트가 공유해
      // variant 마다 다른 크기를 가질 수 없다). 사다리는 코드가 소유한다.
      const sizes = {
        // mini 는 24 — 20 이면 48 원 안에서 글리프가 사라진다
        // (Button · Menu 개편의 `fab/icon-mini` 토큰).
        CoreFabSize.mini: CoreIconSize.size24,
        CoreFabSize.regular: CoreIconSize.size24,
        CoreFabSize.large: CoreIconSize.size28,
      };
      for (final entry in sizes.entries) {
        expect(
          CoreFabStyle.defaultsBySize[entry.key]!.iconStyle!.size,
          entry.value,
          reason: '${entry.key} 아이콘',
        );
      }
    });

    test('Extended 는 자기 라벨 롤을 정하지 않고 Button 사다리를 탄다', () {
      // 48 은 lg(16), 56 은 xl(18), 72 는 xl2(18) — 같은 높이의 Button 과
      // 다른 답을 갖지 않게 한다.
      expect(CoreFabSize.mini.toExtendedButtonSize(), CoreComponentSize.lg);
      expect(CoreFabSize.regular.toExtendedButtonSize(), CoreComponentSize.xl);
      expect(CoreFabSize.large.toExtendedButtonSize(), CoreComponentSize.xl2);
    });

    test('Extended 는 좌우 패딩만 덮어쓴다 — 20 / 24 / 28', () {
      // Button lg/xl/xl2 의 패딩은 폼과 행에 놓이는 버튼용이라 콘텐츠 위에
      // 뜨는 FAB 에는 과하다. 캔버스 실측값.
      const paddings = {
        CoreFabSize.mini: CoreSpace.space20,
        CoreFabSize.regular: CoreSpace.space24,
        CoreFabSize.large: CoreSpace.space28,
      };
      for (final entry in paddings.entries) {
        final ext = CoreFabStyle.defaultsBySize[entry.key]!.extendedButtonStyle;
        expect(ext, isNotNull, reason: '${entry.key} extendedButtonStyle');
        expect(ext!.padding!.left, entry.value, reason: '${entry.key} 좌');
        expect(ext.padding!.right, entry.value, reason: '${entry.key} 우');
      }
    });

    test('Extended 는 아이콘 크기를 진술하지 않는다 — Button 슬롯이 소유', () {
      // 인스턴스에서 그 바인딩을 덮으면 다음 Button 개편에서 깨진다.
      for (final size in CoreFabSize.values) {
        expect(
          CoreFabStyle
              .defaultsBySize[size]!
              .extendedButtonStyle!
              .leadingIconStyle,
          isNull,
          reason: '$size',
        );
      }
    });

    test('메뉴 행은 touch-target 을 갖는 MenuItem 사이즈를 쓴다', () {
      // 고정 높이가 아니라 사이즈로 고르는 이유: height 토큰은 최소 높이라
      // 글자 배율이 커지면 행이 늘어나야 한다.
      expect(CoreFabContract.actionItemSize, CoreMenuItemSize.lg);
    });

    test('크기와 무관한 행 기본값은 모서리뿐이고 바탕은 MenuItem lg 행이다', () {
      // 평면 기본값이 고정하는 것은 패널이 담는 행의 모서리(8 — 같은 판 안
      // 목록 행과 같은 값)뿐이다. 크기별 값은 `defaultsBySize` 가 얹고,
      // 거기서 말하지 않는 것은 행이 `lg` 사다리에서 채운다.
      expect(
        CoreFabStyle.defaultActionItemStyle,
        const CoreMenuItemStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        ),
      );
      final row =
          CoreMenuItemStyle.defaultsBySize[CoreFabContract.actionItemSize]!;
      expect(row.minHeight, CoreControlSize.heightLg);
      expect(row.padding!.left, CoreSpace.space16);
      expect(row.padding!.top, CoreSpace.space12);
      expect(row.contentGapStyle!.size, CoreSpace.space12);
      expect(row.leadingIconStyle!.size, CoreIconSize.size24);
    });

    test('extendedButtonStyle 이 merge / copyWith / == 를 지난다', () {
      const a = CoreFabStyle(
        extendedButtonStyle: CoreButtonStyle(minWidth: 88),
      );
      const b = CoreFabStyle(
        extendedButtonStyle: CoreButtonStyle(height: 48),
      );

      // merge 는 nested 슬롯을 재귀로 합친다 — 한쪽 필드만 준 override 가
      // 나머지를 통째로 지우지 않는다.
      final merged = a.merge(b);
      expect(merged.extendedButtonStyle!.minWidth, 88);
      expect(merged.extendedButtonStyle!.height, 48);

      expect(a.copyWith(extendedButtonStyle: b.extendedButtonStyle), equals(b));
      expect(a, isNot(equals(b)));
    });
  });

  group('Fab 메뉴는 FAB 크기를 따라간다', () {
    // size: (메뉴 폭, 행 높이, 아이콘, FAB 과 판 사이)
    const expected = {
      CoreFabSize.mini: (160.0, 48.0, 20.0, 12.0),
      CoreFabSize.regular: (176.0, 48.0, 20.0, 12.0),
      CoreFabSize.large: (224.0, 56.0, 24.0, 16.0),
    };

    for (final MapEntry(key: size, value: values) in expected.entries) {
      testWidgets('${size.name} — 열린 메뉴를 잰다', (tester) async {
        final (width, rowHeight, icon, gap) = values;
        await pumpTestApp(
          tester,
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(CoreSpace.space48),
              child: Fab(
                trigger: const Icon(LucideIcons.plus),
                size: size,
                actions: const [
                  FabAction(icon: Icon(LucideIcons.pencil), label: Text('편집')),
                  FabAction(icon: Icon(LucideIcons.share), label: Text('공유')),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.byType(Fab));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // 트리에는 `Popup` 이 둘이다 — 행을 감싸는 가장 가까운 쪽이 메뉴 판.
        final panel = tester.getRect(
          find
              .ancestor(
                of: find.byType(MenuItem).first,
                matching: find.byType(Popup),
              )
              .first,
        );
        final row = tester.getRect(find.byType(MenuItem).first);
        final fab = tester.getRect(find.byType(Button).first);
        final glyph = tester.getSize(
          find.descendant(
            of: find.byType(MenuItem).first,
            matching: find.byType(Icon),
          ),
        );

        expect(panel.width, moreOrLessEquals(width, epsilon: 0.5));
        expect(row.height, moreOrLessEquals(rowHeight, epsilon: 0.5));
        expect(glyph.width, moreOrLessEquals(icon, epsilon: 0.5));
        expect(fab.top - panel.bottom, moreOrLessEquals(gap, epsilon: 0.5));
        expect(panel.right, moreOrLessEquals(fab.right, epsilon: 0.5));
      });
    }
  });

  // `withStyle` rebuilds through `copyWith`. The Web twin carries `label`
  // through it; Flutter dropped it, so an extended Fab given a style tweak
  // lost its label and collapsed back to an icon-only button.
  group('Fab copyWith keeps what it is not told to change', () {
    test('withStyle keeps the label', () {
      const label = Text('Compose');
      final fab = const Fab(
        trigger: Icon(LucideIcons.pencil),
        label: label,
      ).withStyle(const CoreFabStyle());

      expect(fab.label, same(label));
    });

    test('copyWith can change the label', () {
      const label = Text('Send');
      final fab = const Fab(
        trigger: Icon(LucideIcons.pencil),
        label: Text('Compose'),
      ).copyWith(label: label);

      expect(fab.label, same(label));
    });
  });

  // #4136 — the FAB restates three fields after the caller's composed-Button
  // slot, and only three. `height` / `width` belong to `diameter` (the
  // circle), the glyph `size` belongs to `iconStyle`. Every other icon
  // sub-field is merged, not replaced — before this, the trigger slot's
  // `leadingIconStyle` was rebuilt from `size` alone, so a caller colour
  // (from `iconStyle` *or* the slot) never reached the glyph.
  //
  // Each case pumps once: two `pumpWidget` calls in one test reuse the
  // element tree and can report a stale value as fixed.
  group('Fab icon style reaches the composed Button (#4136)', () {
    const pinned = CoreColor.token(CoreColors.error);
    const slotPinned = CoreColor.token(CoreColors.tertiary);

    Future<(ResolvedFab, ThemeData)> resolveIn(
      WidgetTester tester,
      CoreFabStyle? fabStyle,
    ) async {
      late ResolvedFab resolved;
      late ThemeData theme;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            theme = Theme.of(context);
            resolved = resolveFab(
              context,
              size: CoreFabSize.regular,
              fabStyle: fabStyle,
            );
            return const SizedBox.shrink();
          },
        ),
      );
      return (resolved, theme);
    }

    testWidgets('baseline — no override leaves the glyph colour unset', (
      tester,
    ) async {
      final (resolved, theme) = await resolveIn(tester, null);
      final icon = resolved.buttonStyle.leadingIconStyle!;

      // Without this baseline the override cases below could not tell
      // "the override was applied" from "the default happened to match".
      expect(icon.color, isNull);
      expect(icon.size, CoreIconSize.size24 * theme.scaling);
      expect(resolved.buttonStyle.width, CoreSize.size56 * theme.scaling);
      expect(resolved.buttonStyle.height, CoreSize.size56 * theme.scaling);
      // The rows are a `MenuItem`: with nothing stated the slot is the
      // defaults of this size, and no caller colour reaches the row.
      expect(
        resolved.actionItemStyle,
        CoreFabStyle.defaultActionItemStyle.merge(
          CoreFabStyle.defaultsBySize[CoreFabSize.regular]!.actionItemStyle,
        ),
      );
    });

    testWidgets('iconStyle.color reaches the trigger slot', (tester) async {
      final (resolved, theme) = await resolveIn(
        tester,
        const CoreFabStyle(iconStyle: CoreIconStyle(color: pinned)),
      );
      final icon = resolved.buttonStyle.leadingIconStyle!;

      expect(icon.color, pinned);
      expect(icon.size, CoreIconSize.size24 * theme.scaling);
    });

    testWidgets('the slot keeps its own colour; size stays iconStyle-owned', (
      tester,
    ) async {
      final (resolved, theme) = await resolveIn(
        tester,
        const CoreFabStyle(
          iconStyle: CoreIconStyle(color: pinned),
          buttonStyle: CoreButtonStyle(
            height: 999,
            width: 888,
            leadingIconStyle: CoreIconStyle(size: 99, color: slotPinned),
          ),
        ),
      );
      final icon = resolved.buttonStyle.leadingIconStyle!;

      // The more specific statement (the slot) wins the colour …
      expect(icon.color, slotPinned);
      // … but the size, height and width are owned elsewhere.
      expect(icon.size, CoreIconSize.size24 * theme.scaling);
      expect(resolved.buttonStyle.width, CoreSize.size56 * theme.scaling);
      expect(resolved.buttonStyle.height, CoreSize.size56 * theme.scaling);
    });

    testWidgets('the action row slot is raw-forwarded to the MenuItem', (
      tester,
    ) async {
      final (resolved, _) = await resolveIn(
        tester,
        const CoreFabStyle(
          actionItemStyle: CoreMenuItemStyle(
            leadingIconStyle: CoreIconStyle(color: slotPinned),
          ),
        ),
      );

      // Not pre-scaled: the `MenuItem` scales the slot itself. The caller's
      // colour merges over the size's own icon size.
      final icon = resolved.actionItemStyle.leadingIconStyle!;
      expect(icon.color, slotPinned);
      expect(icon.size, CoreIconSize.size20);
    });

    testWidgets('the rendered trigger glyph takes the pinned colour', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        Fab(
          trigger: const Icon(LucideIcons.plus),
          onPressed: () {},
          fabStyle: const CoreFabStyle(iconStyle: CoreIconStyle(color: pinned)),
        ),
      );
      final element = tester.element(find.byType(Icon));
      final theme = Theme.of(element);
      final ambient = IconTheme.of(element);

      expect(ambient.color, theme.colorScheme.resolve(pinned).toValue());
      expect(ambient.size, CoreIconSize.size24 * theme.scaling);
    });
  });

  // 리디자인 #5406 — 메뉴 패널은 Fab 자신의 카드이고, 행은 MenuItem lg 다.
  group('FAB 메뉴 패널 · 행 (#5406)', () {
    FabAction action(String label, IconName icon) =>
        FabAction(icon: Icon(icon), label: Text(label));

    Future<void> openMenu(WidgetTester tester, List<FabAction> actions) async {
      // 오른쪽 아래 — 실제 FAB 이 놓이는 자리. 끝 정렬은 패널이 FAB 보다
      // 넓을 때 화면 안에 남는 쪽으로 열려야 의미가 있다.
      await pumpTestApp(
        tester,
        SizedBox.expand(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Fab(
                trigger: const Icon(LucideIcons.plus),
                open: true,
                onOpenChanged: (_) {},
                actions: actions,
              ),
            ),
          ),
        ),
      );
      // The open menu lives in a `Popover` overlay whose follow ticker keeps
      // a frame scheduled — finite pumps, not `pumpAndSettle`.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    // 트리에는 `Popup` 이 둘이다 — 호스트 Popover 의 (chrome 없는) 패널과
    // 보이는 메뉴 패널. 행을 감싸는 가장 가까운 쪽이 메뉴 패널이다.
    final menuPanel = find
        .ancestor(of: find.byType(MenuItem).first, matching: find.byType(Popup))
        .first;

    // 라벨은 일부러 짧다: 테스트 폰트(Ahem)는 글리프 폭이 글자 크기와 같아
    // 실제 글꼴보다 훨씬 넓다. 짧은 라벨이어야 "내용 폭이 아니라 최소 폭이
    // 패널 너비를 정한다" 는 경우를 만들 수 있다.
    final shortActions = [
      action('추가', LucideIcons.calendarPlus),
      action('첨부', LucideIcons.paperclip),
      action('사진', LucideIcons.image),
      action('글쓰기', LucideIcons.pencil),
    ];

    testWidgets('행은 전부 MenuItem lg 이고 Button(menu) 가 없다', (tester) async {
      await openMenu(tester, shortActions);

      final rows = tester.widgetList<MenuItem>(find.byType(MenuItem)).toList();
      expect(rows, hasLength(shortActions.length));
      for (final row in rows) {
        expect(row.size, CoreMenuItemSize.lg);
        expect(row.tone, CoreMenuItemTone.neutral);
        expect(row.leading, isNotNull);
      }
      // 메인 원만 Button 이다 — 행에 Button 이 남아 있으면 menu 변형이
      // 아직 쓰이는 것이다.
      for (final button in tester.widgetList<Button>(find.byType(Button))) {
        expect(button.variant, isNot(CoreButtonVariant.menu));
      }
    });

    testWidgets('행 높이는 터치 하한 48 이다', (tester) async {
      await openMenu(tester, shortActions);

      final theme = Theme.of(tester.element(find.byType(Fab)));
      for (final row in tester.widgetList(find.byType(MenuItem)).indexed) {
        final height = tester.getSize(find.byType(MenuItem).at(row.$1)).height;
        expect(
          height,
          CoreControlSize.heightLg * theme.scaling,
          reason: '${row.$1} 번째 행',
        );
      }
    });

    testWidgets('짧은 라벨의 패널 너비는 기본 크기의 최소 176 이다', (tester) async {
      await openMenu(tester, shortActions);

      final theme = Theme.of(tester.element(find.byType(Fab)));
      expect(
        tester.getSize(menuPanel).width,
        CoreSpace.space176 * theme.scaling,
      );
    });

    testWidgets('긴 라벨은 패널을 최대 280 까지 넓힌다', (tester) async {
      await openMenu(tester, [
        action('아주 아주 긴 라벨이 패널 너비의 상한을 넘기려고 한다', LucideIcons.image),
        action('글쓰기', LucideIcons.pencil),
      ]);

      final theme = Theme.of(tester.element(find.byType(Fab)));
      expect(
        tester.getSize(menuPanel).width,
        CoreLayout.layout280 * theme.scaling,
      );
    });

    testWidgets('280 을 넘는 라벨은 한 줄로 말줄임한다', (tester) async {
      const long = '아주 아주 긴 라벨이 패널 너비의 상한을 넘기려고 한다';
      await openMenu(tester, [
        action(long, LucideIcons.image),
        action('글쓰기', LucideIcons.pencil),
      ]);

      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.byType(MenuItem), matching: find.text(long)),
      );
      expect(paragraph.maxLines, 1);
      expect(paragraph.overflow, TextOverflow.ellipsis);
      expect(paragraph.didExceedMaxLines, isTrue);
      // 줄바꿈 대신 말줄임이므로 행은 터치 하한 그대로다.
      final theme = Theme.of(tester.element(find.byType(Fab)));
      expect(
        tester.getSize(find.byType(MenuItem).first).height,
        CoreControlSize.heightLg * theme.scaling,
      );
    });

    testWidgets('deprecated actionIconStyle · actionLabelTextStyle 도 행에 닿는다', (
      tester,
    ) async {
      late ResolvedFab resolved;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveFab(
              context,
              size: CoreFabSize.regular,
              fabStyle: const CoreFabStyle(
                // The deprecated slots are the subject: they must still
                // reach the MenuItem row until they are removed.
                // ignore: deprecated_member_use
                actionIconStyle: CoreIconStyle(size: CoreIconSize.size20),
                // Deprecated slot under test.
                // ignore: deprecated_member_use
                actionLabelTextStyle: CoreTextStyle.token(
                  CoreTextStyles.labelSmall,
                ),
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      );
      expect(
        resolved.actionItemStyle.leadingIconStyle?.size,
        CoreIconSize.size20,
      );
      expect(
        resolved.actionItemStyle.labelStyle,
        const CoreTextStyle.token(CoreTextStyles.labelSmall),
      );
      // 새 슬롯이 정하지 않은 모서리는 Fab 의 행 기본값(8) 그대로다.
      expect(
        resolved.actionItemStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius8),
      );
    });

    testWidgets('패널은 FAB 의 끝(오른쪽) 가장자리에 맞는다', (tester) async {
      await openMenu(tester, shortActions);

      final panelRight = tester.getTopRight(menuPanel).dx;
      final fabRight = tester.getTopRight(find.byType(Fab)).dx;
      expect(panelRight, closeTo(fabRight, 0.5));
      // 가운데 정렬이었다면 패널이 FAB 보다 넓은 만큼 왼쪽으로 넘쳤을 것이다.
      expect(
        tester.getTopLeft(menuPanel).dx,
        lessThan(tester.getTopLeft(find.byType(Fab)).dx),
      );
    });

    testWidgets('아래로 여는 패널도 끝 가장자리에 맞는다', (tester) async {
      await pumpTestApp(
        tester,
        SizedBox.expand(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Fab(
                trigger: const Icon(LucideIcons.plus),
                open: true,
                onOpenChanged: (_) {},
                expandDirection: CoreFabExpandDirection.down,
                actions: shortActions,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        tester.getTopRight(menuPanel).dx,
        closeTo(tester.getTopRight(find.byType(Fab)).dx, 0.5),
      );
      expect(
        tester.getTopLeft(menuPanel).dy,
        greaterThan(tester.getBottomLeft(find.byType(Fab)).dy),
      );
    });

    testWidgets('resolver 는 Fab 자신의 카드를 Popup 에 넘긴다', (tester) async {
      late ResolvedPopup panel;
      late ResolvedPopup expected;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            final resolved = resolveFab(context, size: CoreFabSize.regular);
            panel = resolvePopup(context, popupStyle: resolved.popupStyle);
            // The card the designer stated, spelt out field by field — the
            // Fab forwards only the width band and lets the Popup fill the
            // rest, so the comparison is on what the Popup paints.
            expected = resolvePopup(
              context,
              popupStyle: const CorePopupStyle(
                borderRadius: CoreBorderRadius.all(CoreRadiusRole.panel),
                borderWidth: CoreStrokeWidth.stroke1,
                backgroundColor: CoreColor.token(CoreColors.surfaceBright),
                borderColor: CoreColor.token(CoreColors.outlineVariant),
                boxShadow: CoreShadow.lg,
                padding: CoreEdgeInsets.all(CoreSpace.space8),
                minWidth: CoreSpace.space176,
                maxWidth: CoreLayout.layout280,
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      );

      expect(panel.minWidth, expected.minWidth);
      expect(panel.maxWidth, expected.maxWidth);
      expect(panel.padding, expected.padding);
      expect(panel.borderRadius, expected.borderRadius);
      expect(panel.borderWidth, expected.borderWidth);
      expect(panel.backgroundColor, expected.backgroundColor);
      expect(panel.borderColor, expected.borderColor);
      expect(panel.boxShadow, expected.boxShadow);
    });

    // 행 모서리는 같은 판 안 목록 행과 같은 8 이고, 패널 모서리 12 보다
    // 둥글지 않다.
    testWidgets('행 8 은 패널 12 보다 둥글지 않고 mini 패널 여백은 8', (tester) async {
      late ResolvedFab fab;
      late ResolvedPopup popup;
      late double scaling;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            fab = resolveFab(context, size: CoreFabSize.values.first);
            popup = resolvePopup(context, popupStyle: fab.popupStyle);
            scaling = Theme.of(context).scaling;
            return const SizedBox.shrink();
          },
        ),
      );
      final row = fab.actionItemStyle.borderRadius!.topLeft;
      expect(popup.padding, EdgeInsets.all(8 * scaling));
      expect(row, 8);
      expect(popup.borderRadius.topLeft.x, greaterThan(row * scaling));
    });
  });
}
