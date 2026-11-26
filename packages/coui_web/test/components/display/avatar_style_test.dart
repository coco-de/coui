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
  group('Avatar initials follow the size row', () {
    // The role is the size's (labelXs … headlineLarge), the 600 weight is the
    // avatar's own statement, and no font-size is emitted: the role class
    // carries the size, tracking and leading.
    const roles = {
      CoreComponentSize.xs: 'text-label-xs',
      CoreComponentSize.sm: 'text-label-medium',
      CoreComponentSize.md: 'text-label-xl',
      CoreComponentSize.lg: 'text-title-medium',
      CoreComponentSize.xl: 'text-headline-small',
      CoreComponentSize.xl2: 'text-headline-large',
    };

    for (final MapEntry(key: size, value: roleClass) in roles.entries) {
      testComponents('${size.name} reads $roleClass at 600', (tester) async {
        final resolved = resolveAvatar(
          _themedContext(tester),
          size: size,
          shape: CoreAvatarShape.circle,
          ring: false,
        );

        expect(resolved.initials.className.split(' '), contains(roleClass));
        final inline = resolved.initials.inlineStyles?.properties;
        expect(inline?['font-weight'], '${CoreFontWeight.semiBold}');
        expect(inline?.containsKey('font-size'), isFalse);
      });
    }

    testComponents('a stated ratio sizes the letters from the diameter', (
      tester,
    ) async {
      final resolved = resolveAvatar(
        _themedContext(tester),
        size: CoreComponentSize.md,
        shape: CoreAvatarShape.circle,
        ring: false,
        avatarStyle: const CoreAvatarStyle(initialsFontRatio: 0.5),
      );

      expect(
        resolved.initials.inlineStyles?.properties['font-size'],
        '${(40 * 0.5) / kRemDivisor}rem',
      );
    });

    testComponents('a stated diameter wins over the size row', (tester) async {
      final resolved = resolveAvatar(
        _themedContext(tester),
        size: CoreComponentSize.sm,
        shape: CoreAvatarShape.circle,
        ring: false,
        avatarStyle: const CoreAvatarStyle(diameter: 52),
      );

      expect(resolved.avatarBoxStyle.width, 52);
      expect(resolved.avatarBoxStyle.height, 52);
    });
  });
  group('Avatar shape', () {
    // A quarter of each step's diameter, as the size row states it.
    const tileCorners = {
      CoreComponentSize.xs: CoreRadius.radius6,
      CoreComponentSize.sm: CoreRadius.radius8,
      CoreComponentSize.md: CoreRadius.radius10,
      CoreComponentSize.lg: CoreRadius.radius12,
      CoreComponentSize.xl: CoreRadius.radius16,
      CoreComponentSize.xl2: CoreRadius.radius24,
    };

    for (final MapEntry(key: size, value: corner) in tileCorners.entries) {
      testComponents('${size.name} rounded is a $corner tile', (tester) async {
        final context = _themedContext(tester);
        final rounded = resolveAvatar(
          context,
          size: size,
          shape: CoreAvatarShape.rounded,
          ring: true,
        );
        final circle = resolveAvatar(
          context,
          size: size,
          shape: CoreAvatarShape.circle,
          ring: true,
        );

        expect(
          rounded.avatarBoxStyle.borderRadius,
          CoreBorderRadius.all(corner),
        );
        expect(
          circle.avatarBoxStyle.borderRadius,
          CoreAvatarStyle.defaultBorderRadius,
        );
        // The ring wrapper takes the same corner, so its `box-shadow`
        // spread grows the tile's curve rather than a disc's.
        expect(
          rounded.ringWrapper!.inlineStyles!.properties['border-radius'],
          CoreBorderRadius.all(corner).toValue(),
        );
        expect(
          circle.ringWrapper!.inlineStyles!.properties['border-radius'],
          CoreAvatarStyle.defaultBorderRadius.toValue(),
        );
      });
    }

    testComponents('a stated corner wins over both shapes', (tester) async {
      final context = _themedContext(tester);
      for (final shape in CoreAvatarShape.values) {
        final resolved = resolveAvatar(
          context,
          size: CoreComponentSize.lg,
          shape: shape,
          ring: false,
          avatarStyle: const CoreAvatarStyle(
            borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
          ),
        );
        expect(
          resolved.avatarBoxStyle.borderRadius,
          const CoreBorderRadius.all(CoreRadius.radius4),
        );
      }
    });

    testComponents('a stated diameter keeps the step corner', (tester) async {
      final resolved = resolveAvatar(
        _themedContext(tester),
        size: CoreComponentSize.sm,
        shape: CoreAvatarShape.rounded,
        ring: false,
        avatarStyle: const CoreAvatarStyle(diameter: 52),
      );

      expect(
        resolved.avatarBoxStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius8),
      );
    });

    testComponents('the rendered tile and its ring share the corner', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Avatar(initials: 'AB', shape: CoreAvatarShape.rounded, ring: true),
      );

      final doms = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .toList();
      final box = doms.singleWhere((c) => c.attributes?['role'] == 'img');
      // The standoff ring wrapper is the outermost element around the box.
      final ring = doms.first;
      expect(ring, isNot(box));
      expect(ring.styles?.properties['box-shadow'], contains('primary'));
      final tile = const CoreBorderRadius.all(CoreRadius.radius8).toValue();

      expect(box.styles?.properties['border-radius'], tile);
      expect(ring.styles?.properties['border-radius'], tile);
      // The corner only reaches the picture through the box's clip.
      expect(box.styles?.properties['overflow'], 'hidden');
    });

    testComponents('a picture is cut to the tile by the box, not its own', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Avatar(
          imageUrl: 'https://example.com/photo.jpg',
          initials: 'AB',
          shape: CoreAvatarShape.rounded,
        ),
      );

      final doms = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .toList();
      final box = doms.singleWhere((c) => c.attributes?['role'] == 'img');
      final picture = doms.singleWhere((c) => c.tag == 'img');
      final tile = const CoreBorderRadius.all(CoreRadius.radius8).toValue();

      // The box carries the tile corner and the clip …
      expect(box.styles?.properties['border-radius'], tile);
      expect(box.styles?.properties['overflow'], 'hidden');
      // … and the picture adds no corner of its own: a circular one would
      // turn the tile's picture into an oval.
      expect(
        picture.styles?.properties.containsKey('border-radius'),
        isNot(true),
      );
      expect(picture.classes, isNot(contains('rounded')));
    });

    test('the widget default is a disc', () {
      expect(Avatar().shape, CoreAvatarShape.circle);
    });
  });

  group('Avatar badge and child by step', () {
    const badges = {
      CoreComponentSize.xs: 8.0,
      CoreComponentSize.sm: 10.0,
      CoreComponentSize.md: 12.0,
      CoreComponentSize.lg: 14.0,
      CoreComponentSize.xl: 16.0,
      CoreComponentSize.xl2: 20.0,
    };
    const icons = {
      CoreComponentSize.xs: 12.0,
      CoreComponentSize.sm: 16.0,
      CoreComponentSize.md: 20.0,
      CoreComponentSize.lg: 24.0,
      CoreComponentSize.xl: 32.0,
      CoreComponentSize.xl2: 48.0,
    };
    String rem(double px) => '${px / 16}rem';

    for (final size in CoreComponentSize.values) {
      testComponents('${size.name} disc: badge centred on the 45° point', (
        tester,
      ) async {
        final resolved = resolveAvatar(
          _themedContext(tester),
          size: size,
          shape: CoreAvatarShape.circle,
          ring: false,
        );
        final r = CoreAvatarStyle.diameterFor(size) / 2;
        final inline = resolved.badgeSlot.inlineStyles?.properties;
        double px(String? value) =>
            double.parse(value!.replaceFirst('rem', '')) * 16;
        expect(px(inline?['left']), closeTo(r + r * 0.7071067811865476, 1e-9));
        expect(px(inline?['top']), closeTo(r - r * 0.7071067811865476, 1e-9));
        expect(inline?['transform'], 'translate(-50%, -50%)');
        expect(resolved.badgeStyle.size, badges[size]);
        expect(resolved.childIconStyle.size, icons[size]);
      });

      testComponents('${size.name} tile: badge flush in the corner', (
        tester,
      ) async {
        final resolved = resolveAvatar(
          _themedContext(tester),
          size: size,
          shape: CoreAvatarShape.rounded,
          ring: false,
        );
        final inline = resolved.badgeSlot.inlineStyles?.properties;
        expect(inline?['left'], rem(CoreAvatarStyle.diameterFor(size)));
        expect(inline?['top'], rem(0));
        expect(inline?['transform'], 'translate(-100%, 0%)');
      });
    }

    testComponents('the badge draws at the step size, a stated one wins', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        div([
          Avatar(
            initials: 'AB',
            size: CoreComponentSize.xl2,
            badge: AvatarBadge(),
          ),
          Avatar(
            initials: 'CD',
            size: CoreComponentSize.xl2,
            badge: AvatarBadge(
              avatarBadgeStyle: const CoreAvatarBadgeStyle(size: 6),
            ),
          ),
        ]),
      );
      final dots = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .where((c) => c.classes?.contains('bg-primary') ?? false)
          .map((c) => c.styles!.properties['width'])
          .toList();
      expect(dots, contains(rem(20)));
      expect(dots, contains(rem(6)));
    });

    testComponents('the badge ring is an inset shadow, stroke1 when small', (
      tester,
    ) async {
      final context = _themedContext(tester);
      String ringOf(CoreAvatarBadgeStyle? inherited) => resolveAvatarBadge(
        context,
        inheritedStyle: inherited,
      ).root.inlineStyles!.properties['box-shadow']!;
      final surface = const CoreColor.token(CoreColors.surface).toValue();
      expect(
        ringOf(null),
        'inset 0 0 0 ${strokeWidthCss(CoreStrokeWidth.stroke2)} $surface',
      );
      expect(
        ringOf(CoreAvatarStyle.badgeStyleFor(CoreComponentSize.xs)),
        'inset 0 0 0 ${strokeWidthCss(CoreStrokeWidth.stroke1)} $surface',
      );
      expect(
        ringOf(CoreAvatarStyle.badgeStyleFor(CoreComponentSize.md)),
        'inset 0 0 0 ${strokeWidthCss(CoreStrokeWidth.stroke2)} $surface',
      );
      expect(
        resolveAvatarBadge(
          context,
          avatarBadgeStyle: const CoreAvatarBadgeStyle(borderWidth: 0),
        ).root.inlineStyles!.properties.containsKey('box-shadow'),
        isFalse,
      );
    });

    testComponents('an Icon child takes the step icon size', (tester) async {
      pumpWithTheme(
        tester,
        Avatar(
          size: CoreComponentSize.xl2,
          child: const Icon(LucideIcons.user),
        ),
      );
      final widths = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .map((c) => c.styles?.properties['font-size'])
          .whereType<String>()
          .toList();
      expect(widths, contains(rem(48)));
    });
  });

  group('Avatar copyWith', () {
    test('keeps the shape and every caller hook', () {
      final original = Avatar(
        initials: 'AB',
        shape: CoreAvatarShape.rounded,
        classes: 'caller-class',
        css: const Styles(raw: {'margin': '1px'}),
        attributes: const {'data-testid': 'org'},
        eventHandlers: {
          'mouseenter': [(_) {}],
        },
      );

      for (final copy in [original.copyWith(ring: true), original.radius4]) {
        expect(copy.shape, CoreAvatarShape.rounded);
        expect(copy.classes, 'caller-class');
        expect(copy.css?.properties['margin'], '1px');
        expect(copy.userAttributes, {'data-testid': 'org'});
        expect(copy.eventHandlers.keys, contains('mouseenter'));
      }
      expect(
        original.copyWith(shape: CoreAvatarShape.circle).shape,
        CoreAvatarShape.circle,
      );
    });
  });
}
