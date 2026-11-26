/// Web `Fab` — 리디자인이 Web 쪽에도 도달했는지 본다.
///
/// Core 값 자체(사다리·패딩·아이콘 크기)는 플랫폼 무관이라 Flutter 쪽
/// 테스트가 이미 고정한다. 여기가 보는 것은 **Web 만 가진 배선**이다 —
/// resolver 가 그 값을 실제로 굽는지, 위젯이 `label` 을 받아 Extended 로
/// 갈라지는지, 그리고 `copyWith` 가 그 슬롯을 떨어뜨리지 않는지.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

void main() {
  group('Web Fab resolver — 리디자인 값이 Web 에도 굽힌다', () {
    testComponents('원형은 사이즈별 지름과 아이콘을 굽는다 — 48/56/72 · 24/24/28', (
      tester,
    ) async {
      const expected = {
        // mini 는 24 — 20 이면 48 원 안에서 글리프가 사라진다
        // (Button · Menu 개편의 `fab/icon-mini` 토큰).
        CoreFabSize.mini: (CoreSize.size48, CoreIconSize.size24),
        CoreFabSize.regular: (CoreSize.size56, CoreIconSize.size24),
        CoreFabSize.large: (CoreSize.size72, CoreIconSize.size28),
      };
      final context = _themedContext(tester);

      for (final entry in expected.entries) {
        final resolved = resolveFab(context, size: entry.key);
        final (diameter, icon) = entry.value;
        expect(resolved.buttonStyle.width, diameter, reason: '${entry.key} 폭');
        expect(
          resolved.buttonStyle.height,
          diameter,
          reason: '${entry.key} 높이',
        );
        expect(
          resolved.buttonStyle.leadingIconStyle!.size,
          icon,
          reason: '${entry.key} 아이콘',
        );
      }
    });

    testComponents('Extended 는 높이만 굽고 폭은 라벨에 맡긴다', (tester) async {
      final resolved = resolveFab(
        _themedContext(tester),
        size: CoreFabSize.regular,
      );

      expect(resolved.extendedButtonStyle.height, CoreSize.size56);
      // 폭을 굽으면 라벨이 길어져도 알약이 안 늘어난다 — 원형과 갈리는 지점.
      expect(resolved.extendedButtonStyle.width, isNull);
      // 아이콘 크기도 진술하지 않는다 — Button 사이즈가 소유한다.
      expect(resolved.extendedButtonStyle.leadingIconStyle, isNull);
      expect(resolved.extendedButtonStyle.padding!.left, CoreSpace.space24);
      expect(resolved.extendedButtonStyle.padding!.right, CoreSpace.space24);
    });

    testComponents('caller override 가 사이즈 기본값 위에 얹힌다', (tester) async {
      final resolved = resolveFab(
        _themedContext(tester),
        size: CoreFabSize.mini,
        fabStyle: const CoreFabStyle(
          extendedButtonStyle: CoreButtonStyle(minWidth: 88),
        ),
      );

      expect(resolved.extendedButtonStyle.minWidth, 88);
      // override 가 준 필드만 덮고 나머지 사이즈 기본값은 살아남는다.
      expect(resolved.extendedButtonStyle.padding!.left, CoreSpace.space20);
      expect(resolved.extendedButtonStyle.height, CoreSize.size48);
    });

    testComponents('메뉴 행은 MenuItem 으로 raw-forward 된다 — Fab 이 굽지 않는다', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final base = resolveFab(context, size: CoreFabSize.regular);
      expect(base.actionItemStyle, CoreFabStyle.defaultActionItemStyle);

      // 행이 자기 사다리(48 · 16/12 · 12 · 24)에서 스스로 채우므로 Fab 은
      // 아이콘 크기도 패딩도 다시 진술하지 않는다.
      const stated = CoreMenuItemStyle(
        leadingIconStyle: CoreIconStyle(
          color: CoreColor.token(CoreColors.error),
        ),
      );
      final forwarded = resolveFab(
        context,
        size: CoreFabSize.regular,
        fabStyle: const CoreFabStyle(actionItemStyle: stated),
      );
      expect(
        forwarded.actionItemStyle.leadingIconStyle,
        stated.leadingIconStyle,
      );
      expect(forwarded.actionItemStyle.leadingIconStyle!.size, isNull);
    });

    testComponents('메뉴 패널은 Fab 자신의 카드다 — 12 · surface-bright · 160~280', (
      tester,
    ) async {
      final resolved = resolveFab(
        _themedContext(tester),
        size: CoreFabSize.regular,
      );
      final panel = resolved.popupStyle;

      // The Fab forwards only the width band; the card itself is the
      // Popup's own default, read the way the popup resolver reads it.
      expect(
        panel.borderRadius ?? CorePopupStyle.defaultBorderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
      expect(
        panel.backgroundColor ?? CorePopupStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.surfaceBright),
      );
      expect(
        panel.borderColor ?? CorePopupStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(
        panel.borderWidth ?? CorePopupStyle.defaultBorderWidth,
        CoreStrokeWidth.stroke1,
      );
      expect(panel.boxShadow ?? CorePopupStyle.defaultBoxShadow, CoreShadow.lg);
      expect(panel.minWidth, CoreLayout.layout160);
      expect(panel.maxWidth, CoreLayout.layout280);
    });

    testComponents('280 을 넘는 라벨은 한 줄로 말줄임한다 — 라벨 래퍼는 truncate', (
      tester,
    ) async {
      final resolved = resolveFab(
        _themedContext(tester),
        size: CoreFabSize.regular,
      );
      // Layout only: the label's typography and colour stay the MenuItem
      // row's own, so the wrapper carries nothing but the one-line clamp.
      expect(resolved.actionLabel.className, WebLayout.truncate);
      expect(resolved.actionLabel.inlineStyles, isNull);
    });

    testComponents('deprecated Button 행 필드도 MenuItem 행에 닿는다', (tester) async {
      final resolved = resolveFab(
        _themedContext(tester),
        size: CoreFabSize.regular,
        fabStyle: const CoreFabStyle(
          // The deprecated slots are the subject: they must still reach the
          // MenuItem row until they are removed.
          // ignore: deprecated_member_use
          actionButtonStyle: CoreButtonStyle(
            padding: CoreEdgeInsets.all(CoreSpace.space8),
          ),
          // Deprecated slot under test.
          // ignore: deprecated_member_use
          actionIconStyle: CoreIconStyle(size: CoreIconSize.size20),
          // Deprecated slot under test.
          // ignore: deprecated_member_use
          actionLabelTextStyle: CoreTextStyle.token(CoreTextStyles.labelSmall),
        ),
      );
      final row = resolved.actionItemStyle;
      expect(row.padding, const CoreEdgeInsets.all(CoreSpace.space8));
      expect(row.leadingIconStyle?.size, CoreIconSize.size20);
      expect(
        row.labelStyle,
        const CoreTextStyle.token(CoreTextStyles.labelSmall),
      );
      // 옛 필드가 모서리를 말하지 않으면 Fab 의 행 기본값(8)이 남는다.
      expect(row.borderRadius, const CoreBorderRadius.all(CoreRadius.radius8));
    });

    testComponents(
      '메뉴 행 모서리는 8 — 같은 판 안의 목록 행과 같다',
      (tester) async {
        for (final size in CoreFabSize.values) {
          final resolved = resolveFab(_themedContext(tester), size: size);
          expect(
            resolved.actionItemStyle.borderRadius,
            const CoreBorderRadius.all(CoreRadius.radius8),
            reason: '$size',
          );
        }
        // The row is composed at actionItemSize (lg, own corner 12); the
        // pin takes the list-row corner 8, so the inner never rounds past
        // the panel's corner (the panel role, 12) and the Fab rows match the
        // other list rows.
        final panel =
            CoreFabStyle.defaultPopupStyle.borderRadius ??
            CorePopupStyle.defaultBorderRadius;
        expect(panel, const CoreBorderRadius.all(CoreRadiusRole.panel));
        final inset = CoreFabStyle.defaultPopupStyle.padding!;
        expect(inset, CorePopupStyle.defaultListPadding);
        expect(panel.topLeft, greaterThan(CoreRadius.radius8));
      },
    );
  });

  group('Web Fab 위젯 — label 배선', () {
    test('copyWith 가 label 을 떨어뜨리지 않는다', () {
      // 이 파라미터가 없던 동안 `.copyWith(...)` 는 Extended 를 조용히 원형으로
      // 되돌렸다 — 체인(`withStyle`)이 그 경로를 지나므로 사용자에게 보인다.
      const original = Fab(trigger: Icon(LucideIcons.plus), label: Text('New'));

      expect(original.copyWith(size: CoreFabSize.large).label, isNotNull);
      expect(original.copyWith(label: const Text('Other')).label, isNotNull);
    });

    testComponents('label 을 주면 라벨이 실제로 렌더된다', (tester) async {
      pumpWithTheme(
        tester,
        const Fab(trigger: Icon(LucideIcons.plus), label: Text('New note')),
      );

      expect(find.text('New note'), findsOneComponent);
    });

    testComponents('label 이 없으면 원형이라 그 라벨도 없다', (tester) async {
      pumpWithTheme(tester, const Fab(trigger: Icon(LucideIcons.plus)));

      expect(find.text('New note'), findsNothing);
    });
  });

  group('Web Fab 메뉴 — 패널은 끝 정렬 (#5406)', () {
    FabAction action(String label, IconName icon) =>
        FabAction(icon: Icon(icon), label: Text(label));

    Fab fab({CoreFabExpandDirection direction = .up}) => Fab(
      trigger: const Icon(LucideIcons.plus),
      expandDirection: direction,
      open: true,
      onOpenChanged: (_) {},
      actions: [
        action('일정 추가', LucideIcons.calendarPlus),
        action('글쓰기', LucideIcons.pencil),
      ],
    );

    testComponents('Popover 가 FAB 의 끝 가장자리에 맞춰 열린다 — up · fan · down', (
      tester,
    ) async {
      const expected = {
        CoreFabExpandDirection.up: CorePopoverPlacement.topEnd,
        CoreFabExpandDirection.fan: CorePopoverPlacement.topEnd,
        CoreFabExpandDirection.down: CorePopoverPlacement.bottomEnd,
        CoreFabExpandDirection.left: CorePopoverPlacement.left,
        CoreFabExpandDirection.right: CorePopoverPlacement.right,
      };
      for (final entry in expected.entries) {
        pumpWithTheme(tester, fab(direction: entry.key));
        final popover =
            find.byType(Popover).evaluate().single.component as Popover;
        expect(popover.placement, entry.value, reason: '${entry.key}');
      }
    });
  });

  // #4136 — the Flutter twin of these cases lives in
  // `coui_flutter/test/components/control/fab_test.dart`. The FAB restates
  // `height` / `width` (owned by `diameter`) and the glyph `size` (owned by
  // `iconStyle`) after the caller's slot; every other icon sub-field is
  // merged. The render cases then check the glyph actually receives it —
  // through the composed `Button`'s ambient `IconTheme`, which is the only
  // path a Web glyph has (the FAB passes the caller's trigger through
  // untouched).
  group('Web Fab icon style reaches the glyph (#4136)', () {
    const pinned = CoreColor.token(CoreColors.error);
    const slotPinned = CoreColor.token(CoreColors.tertiary);

    testComponents('baseline — no override leaves the glyph colour unset', (
      tester,
    ) async {
      final resolved = resolveFab(
        _themedContext(tester),
        size: CoreFabSize.regular,
      );

      expect(resolved.buttonStyle.leadingIconStyle!.color, isNull);
      expect(resolved.buttonStyle.leadingIconStyle!.size, CoreIconSize.size24);
    });

    testComponents('iconStyle.color and the slot colour both reach the slot', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final flat = resolveFab(
        context,
        size: CoreFabSize.regular,
        fabStyle: const CoreFabStyle(iconStyle: CoreIconStyle(color: pinned)),
      );
      final slot = resolveFab(
        context,
        size: CoreFabSize.regular,
        fabStyle: const CoreFabStyle(
          iconStyle: CoreIconStyle(color: pinned),
          buttonStyle: CoreButtonStyle(
            height: 999,
            width: 888,
            leadingIconStyle: CoreIconStyle(size: 99, color: slotPinned),
          ),
        ),
      );

      expect(flat.buttonStyle.leadingIconStyle!.color, pinned);
      // The more specific statement (the slot) wins the colour …
      expect(slot.buttonStyle.leadingIconStyle!.color, slotPinned);
      // … but the size, height and width are owned elsewhere.
      expect(slot.buttonStyle.leadingIconStyle!.size, CoreIconSize.size24);
      expect(slot.buttonStyle.width, CoreSize.size56);
      expect(slot.buttonStyle.height, CoreSize.size56);
    });

    testComponents('render — the trigger glyph is sized by the FAB', (
      tester,
    ) async {
      IconThemeData? ambient;
      pumpWithTheme(
        tester,
        Fab(
          size: CoreFabSize.large,
          trigger: _ContextCapture((c) => ambient = IconTheme.maybeOf(c)),
        ),
      );

      // 28, not the 20 a bare Icon would otherwise take from the app root.
      expect(ambient?.size, CoreIconSize.size28);
      expect(ambient?.color, isNull);
    });

    testComponents('render — a pinned colour reaches the trigger glyph', (
      tester,
    ) async {
      IconThemeData? ambient;
      pumpWithTheme(
        tester,
        Fab(
          fabStyle: const CoreFabStyle(iconStyle: CoreIconStyle(color: pinned)),
          trigger: _ContextCapture((c) => ambient = IconTheme.maybeOf(c)),
        ),
      );

      expect(ambient?.size, CoreIconSize.size24);
      expect(ambient?.color, pinned);
    });
  });
}
