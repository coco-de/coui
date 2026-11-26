import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

// Test constants.
const _kBadgeSize = 16.0;
const _kGroupGap = 4.0;
const _kGroupOffset = 0.7;

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(data: const ThemeData(), child: child),
  );
}

// A picture the test owns. `Image.network` never loads in `flutter_test`
// (the binding answers every request with a 400), so the picture would be
// the error fallback and nothing would prove how a loaded one is clipped.
// Seeding the image cache under the key `NetworkImage` looks up serves a
// solid fill to the same `Image.network` the avatar builds.
const _kPictureUrl = 'https://example.com/photo.jpg';
const _kPictureSide = 32;
const _kPictureColor = ui.Color(0xFFFF0000);
const _kRgbaStride = 4;

Future<ui.Image> _solidPicture() {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, _kPictureSide.toDouble(), _kPictureSide.toDouble()),
    ui.Paint()..color = _kPictureColor,
  );

  return recorder.endRecording().toImage(_kPictureSide, _kPictureSide);
}

/// The pixels of [boundary] at one device pixel per logical pixel,
/// straight (not premultiplied) RGBA.
Future<ByteData> _readPixels(RenderRepaintBoundary boundary) async {
  final captured = await boundary.toImage();
  final bytes = await captured.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  captured.dispose();

  return bytes!;
}

/// `[r, g, b, a]` of the pixel at ([x], [y]) in a [_kPictureSide]-wide
/// capture.
List<int> _pixelAt(ByteData bytes, int x, int y) {
  final offset = ((y * _kPictureSide) + x) * _kRgbaStride;

  return [for (var i = 0; i < _kRgbaStride; i++) bytes.getUint8(offset + i)];
}

void main() {
  group('Avatar', () {
    testWidgets('renders with initials', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Avatar(initials: 'JD')),
      );
      await tester.pump();

      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Avatar(initials: 'AB', size: CoreComponentSize.lg)),
      );
      await tester.pump();

      expect(find.byType(Avatar), findsOneWidget);
    });

    testWidgets('renders with custom background color', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Avatar(
            avatarStyle: CoreAvatarStyle(
              backgroundColor: CoreColor(0xFFFF0000),
            ),
            initials: 'AB',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Avatar), findsOneWidget);
    });

    testWidgets('renders with child widget instead of initials', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Avatar(
            initials: 'AB',
            child: Icon(LucideIcons.info),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Icon), findsOneWidget);
      // When child is provided, initials text should not be shown.
      expect(find.text('AB'), findsNothing);
    });

    testWidgets('renders with badge', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Avatar(
            badge: AvatarBadge(
              avatarBadgeStyle: CoreAvatarBadgeStyle(
                backgroundColor: CoreColor(0xFF00FF00),
              ),
            ),
            initials: 'AB',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Avatar), findsOneWidget);
      expect(find.byType(AvatarBadge), findsOneWidget);
    });

    testWidgets('renders with ring', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Avatar(
            initials: 'AB',
            ring: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Avatar), findsOneWidget);
      // Ring adds a CustomPaint wrapper around the avatar.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('accepts key parameter', (tester) async {
      const testKey = Key('avatar-test');

      await tester.pumpWidget(
        _buildApp(const Avatar(key: testKey, initials: 'AB')),
      );
      await tester.pump();

      expect(find.byKey(testKey), findsOneWidget);
    });

    group('getInitials', () {
      test('generates initials from single word', () {
        final result = Avatar.getInitials('John');

        expect(result, equals('JO'));
      });

      test('generates initials from name with space', () {
        // Splits on whitespace and takes the first letter of the first two
        // words: "John Doe" -> "JD".
        final result = Avatar.getInitials('John Doe');

        expect(result, equals('JD'));
      });

      test('generates initials from single character', () {
        final result = Avatar.getInitials('J');

        expect(result, equals('J'));
      });

      test('converts to uppercase', () {
        final result = Avatar.getInitials('john');

        expect(result, equals('JO'));
      });
    });
  });

  group('badge and child by step', () {
    // The badge's top-left from the avatar's, measured off the scaffold
    // (whole px there) — a disc's badge centres on the 45° point of the
    // outline, a tile's sits flush in the top-end corner.
    const badges = {
      CoreComponentSize.xs: 8.0,
      CoreComponentSize.sm: 10.0,
      CoreComponentSize.md: 12.0,
      CoreComponentSize.lg: 14.0,
      CoreComponentSize.xl: 16.0,
      CoreComponentSize.xl2: 20.0,
    };
    const discs = {
      CoreComponentSize.xs: Offset(16, 0),
      CoreComponentSize.sm: Offset(22, 0),
      CoreComponentSize.md: Offset(28, 0),
      CoreComponentSize.lg: Offset(34, 0),
      CoreComponentSize.xl: Offset(47, 1),
      CoreComponentSize.xl2: Offset(72, 4),
    };
    const tiles = {
      CoreComponentSize.xs: Offset(16, 0),
      CoreComponentSize.sm: Offset(22, 0),
      CoreComponentSize.md: Offset(28, 0),
      CoreComponentSize.lg: Offset(34, 0),
      CoreComponentSize.xl: Offset(48, 0),
      CoreComponentSize.xl2: Offset(76, 0),
    };
    for (final shape in CoreAvatarShape.values) {
      for (final size in CoreComponentSize.values) {
        testWidgets('${shape.name} ${size.name}: badge size and place', (
          tester,
        ) async {
          await tester.pumpWidget(
            _buildApp(
              Center(
                child: Avatar(
                  size: size,
                  shape: shape,
                  badge: const AvatarBadge(),
                  initials: 'AB',
                ),
              ),
            ),
          );
          final avatar = tester.getRect(find.byType(Avatar));
          final badge = tester.getRect(find.byType(AvatarBadge));
          expect(badge.width, badges[size]);
          expect(badge.height, badges[size]);
          final want = (shape == CoreAvatarShape.circle ? discs : tiles)[size]!;
          final got = badge.topLeft - avatar.topLeft;
          expect(got.dx, closeTo(want.dx, 0.5));
          expect(got.dy, closeTo(want.dy, 0.5));
        });
      }
    }

    for (final size in CoreComponentSize.values) {
      testWidgets('${size.name}: the badge ring is drawn inside the dot', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            Center(
              child: Avatar(
                size: size,
                badge: const AvatarBadge(),
                initials: 'AB',
              ),
            ),
          ),
        );
        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(AvatarBadge),
            matching: find.byType(Container),
          ),
        );
        final ring = container.foregroundDecoration! as BoxDecoration;
        final side = (ring.border! as Border).top;
        final small =
            size == CoreComponentSize.xs || size == CoreComponentSize.sm;
        expect(side.width, small ? 1.0 : 2.0);
        expect(side.strokeAlign, BorderSide.strokeAlignInside);
        expect(side.color, const ThemeData().colorScheme.surface.toValue());
        // Inward — the dot keeps the step's size.
        expect(tester.getSize(find.byType(AvatarBadge)).width, badges[size]);
      });
    }

    testWidgets('a size the badge states wins and keeps the anchor', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Center(
            child: Avatar(
              size: CoreComponentSize.md,
              badge: AvatarBadge(
                avatarBadgeStyle: CoreAvatarBadgeStyle(size: _kBadgeSize),
              ),
              initials: 'AB',
            ),
          ),
        ),
      );
      final avatar = tester.getRect(find.byType(Avatar));
      final badge = tester.getRect(find.byType(AvatarBadge));
      expect(badge.width, _kBadgeSize);
      // The centre still sits on the 45° point of the 40 disc.
      final r = avatar.width / 2;
      final centre = badge.center - avatar.center;
      expect(centre.dx, closeTo(r * 0.7071067811865476, 1e-6));
      expect(centre.dy, closeTo(-r * 0.7071067811865476, 1e-6));
    });

    const icons = {
      CoreComponentSize.xs: 12.0,
      CoreComponentSize.sm: 16.0,
      CoreComponentSize.md: 20.0,
      CoreComponentSize.lg: 24.0,
      CoreComponentSize.xl: 32.0,
      CoreComponentSize.xl2: 48.0,
    };
    for (final size in CoreComponentSize.values) {
      testWidgets('${size.name}: an Icon child draws at ${icons[size]}', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            Center(
              child: Avatar(size: size, child: const Icon(LucideIcons.user)),
            ),
          ),
        );
        expect(tester.getSize(find.byType(Icon)).width, icons[size]);
      });
    }

    testWidgets('an Icon child that states its size keeps it', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Center(
            child: Avatar(
              size: CoreComponentSize.xl2,
              child: Icon(
                LucideIcons.user,
                iconStyle: CoreIconStyle(size: _kBadgeSize),
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(Icon)).width, _kBadgeSize);
    });
  });

  group('AvatarBadge', () {
    testWidgets('renders as colored circle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const AvatarBadge(
            avatarBadgeStyle: CoreAvatarBadgeStyle(
              backgroundColor: CoreColor(0xFF00FF00),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AvatarBadge), findsOneWidget);
    });

    testWidgets('renders with child content', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const AvatarBadge(
            avatarBadgeStyle: CoreAvatarBadgeStyle(
              backgroundColor: CoreColor(0xFFFF0000),
            ),
            child: Text('5'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders with custom size', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const AvatarBadge(
            avatarBadgeStyle: CoreAvatarBadgeStyle(
              backgroundColor: CoreColor(0xFF00FF00),
              size: _kBadgeSize,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AvatarBadge), findsOneWidget);
    });
  });

  group('AvatarGroup', () {
    testWidgets('renders multiple avatars', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          AvatarGroup(
            children: const [
              Avatar(initials: 'AB'),
              Avatar(initials: 'CD'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('AB'), findsOneWidget);
      expect(find.text('CD'), findsOneWidget);
    });

    testWidgets('toLeft factory creates group', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          AvatarGroup.toLeft(
            children: const [
              Avatar(initials: 'AB'),
              Avatar(initials: 'CD'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AvatarGroup), findsOneWidget);
    });

    testWidgets('toRight factory creates group', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          AvatarGroup.toRight(
            children: const [
              Avatar(initials: 'AB'),
              Avatar(initials: 'CD'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AvatarGroup), findsOneWidget);
    });

    testWidgets('renders with custom extra spacing', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          AvatarGroup.toRight(
            avatarGroupStyle: const CoreAvatarGroupStyle(
              extraSpacing: _kGroupGap,
            ),
            children: const [
              Avatar(initials: 'AB'),
              Avatar(initials: 'CD'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AvatarGroup), findsOneWidget);
    });

    testWidgets('renders with custom overlap', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          AvatarGroup.toRight(
            avatarGroupStyle: const CoreAvatarGroupStyle(
              overlap: _kGroupOffset,
            ),
            children: const [
              Avatar(initials: 'AB'),
              Avatar(initials: 'CD'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AvatarGroup), findsOneWidget);
    });
  });

  group('AvatarStyleChain', () {
    test(
      'withStyle merges patch into avatarStyle and preserves other fields',
      () {
        const original = Avatar(
          imageUrl: 'https://example.com/photo.jpg',
          initials: 'JD',
          size: CoreComponentSize.lg,
          ring: true,
        );

        final updated = original.withStyle(
          const CoreAvatarStyle(ringWidth: 3),
        );

        // Other fields preserved.
        expect(updated.imageUrl, equals(original.imageUrl));
        expect(updated.initials, equals(original.initials));
        expect(updated.size, equals(original.size));
        expect(updated.ring, equals(original.ring));
        expect(updated.child, equals(original.child));
        expect(updated.badge, equals(original.badge));

        // Patch merged into avatarStyle.
        expect(updated.avatarStyle?.ringWidth, equals(3));
      },
    );

    test('copyWith replaces only the given fields', () {
      const original = Avatar(
        imageUrl: 'https://example.com/photo.jpg',
        initials: 'JD',
        size: CoreComponentSize.md,
        ring: false,
      );

      final updated = original.copyWith(initials: 'AB', ring: true);

      // Given fields replaced.
      expect(updated.initials, equals('AB'));
      expect(updated.ring, isTrue);

      // Omitted fields preserved from the original instance.
      expect(updated.imageUrl, equals(original.imageUrl));
      expect(updated.size, equals(original.size));
      expect(updated.shape, equals(original.shape));
      expect(updated.child, equals(original.child));
      expect(updated.badge, equals(original.badge));
      expect(updated.avatarStyle, equals(original.avatarStyle));
    });
  });

  group('initials follow the size row', () {
    // Each size draws its initials in the type scale's role at 600 — the
    // role's own size, not a share of the diameter.
    const roles = {
      CoreComponentSize.xs: CoreTextStyles.labelXs,
      CoreComponentSize.sm: CoreTextStyles.labelMedium,
      CoreComponentSize.md: CoreTextStyles.labelXl,
      CoreComponentSize.lg: CoreTextStyles.titleMedium,
      CoreComponentSize.xl: CoreTextStyles.headlineSmall,
      CoreComponentSize.xl2: CoreTextStyles.headlineLarge,
    };

    TextStyle? initialsStyle(WidgetTester tester) =>
        tester.widget<Text>(find.text('AB')).style;

    double? roleSize(WidgetTester tester, CoreTextStyleToken role) =>
        CoreTextStyle.token(
          role,
        ).toValue(theme: Theme.of(tester.element(find.text('AB')))).fontSize;

    for (final MapEntry(key: size, value: role) in roles.entries) {
      testWidgets('${size.name} reads ${role.name} at 600', (tester) async {
        await tester.pumpWidget(
          _buildApp(Avatar(initials: 'AB', size: size)),
        );
        await tester.pump();

        expect(initialsStyle(tester)?.fontSize, roleSize(tester, role));
        expect(initialsStyle(tester)?.fontWeight, FontWeight.w600);
      });
    }

    testWidgets('the widget default is sm', (tester) async {
      await tester.pumpWidget(
        _buildApp(const material.Center(child: Avatar(initials: 'AB'))),
      );
      await tester.pump();

      expect(
        initialsStyle(tester)?.fontSize,
        roleSize(tester, CoreTextStyles.labelMedium),
      );
      expect(tester.getSize(find.byType(Avatar)).width, 32);
    });

    testWidgets('a stated ratio sizes the letters from the diameter', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const Avatar(
            initials: 'AB',
            size: CoreComponentSize.md,
            avatarStyle: CoreAvatarStyle(initialsFontRatio: 0.5),
          ),
        ),
      );
      await tester.pump();

      expect(initialsStyle(tester)?.fontSize, 40 * 0.5);
    });

    testWidgets('a stated diameter wins over the size row', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Center(
            child: Avatar(
              initials: 'AB',
              avatarStyle: CoreAvatarStyle(diameter: 52),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getSize(find.byType(Avatar)), const Size(52, 52));
    });
  });
  group('shape', () {
    // The corner the avatar box actually paints — read off the composed
    // `OutlinedContainer`'s decoration, after its geometry bend and scaling.
    BorderRadius? paintedCorner(WidgetTester tester) {
      final box = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(OutlinedContainer),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return (box.decoration! as BoxDecoration).borderRadius as BorderRadius?;
    }

    // The two standoff ring layers: the gap band (a fill) and the stroke.
    List<BoxDecoration> ringLayers(WidgetTester tester) => tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.descendant(
              of: find.byType(Avatar),
              matching: find.byType(IgnorePointer),
            ),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration as BoxDecoration)
        .toList();

    testWidgets('the widget default is a disc', (tester) async {
      const avatar = Avatar(initials: 'AB');
      expect(avatar.shape, CoreAvatarShape.circle);

      await tester.pumpWidget(_buildApp(avatar));
      await tester.pump();

      expect(paintedCorner(tester), BorderRadius.circular(9999));
    });

    // A quarter of each step's diameter, as the size row states it.
    const tileCorners = {
      CoreComponentSize.xs: 6.0,
      CoreComponentSize.sm: 8.0,
      CoreComponentSize.md: 10.0,
      CoreComponentSize.lg: 12.0,
      CoreComponentSize.xl: 16.0,
      CoreComponentSize.xl2: 24.0,
    };

    for (final MapEntry(key: size, value: corner) in tileCorners.entries) {
      testWidgets('${size.name} rounded paints a $corner corner', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            Avatar(initials: 'AB', size: size, shape: CoreAvatarShape.rounded),
          ),
        );
        await tester.pump();

        expect(paintedCorner(tester), BorderRadius.circular(corner));
      });
    }

    testWidgets('a rounded ring keeps the tile curve at its standoff', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Center(
            child: Avatar(
              initials: 'AB',
              shape: CoreAvatarShape.rounded,
              ring: true,
            ),
          ),
        ),
      );
      await tester.pump();

      final layers = ringLayers(tester);
      final band = layers.singleWhere((d) => d.border == null);
      final stroke = layers.singleWhere((d) => d.border != null);
      // sm tile 8, grown by the 2 offset, then by the 2 ring width.
      expect(band.borderRadius, BorderRadius.circular(8 + 2));
      expect(stroke.borderRadius, BorderRadius.circular(8 + 2 + 2));
      // Neither layer is forced into a circle any more.
      expect(band.shape, BoxShape.rectangle);
      expect(stroke.shape, BoxShape.rectangle);
      // The stroke box stands off by offset + width on every side.
      final strokeBox = tester.getSize(
        find
            .ancestor(
              of: find.byWidgetPredicate(
                (w) => w is DecoratedBox && w.decoration == stroke,
              ),
              matching: find.byType(IgnorePointer),
            )
            .first,
      );
      expect(strokeBox, const Size(32 + 8, 32 + 8));
    });

    testWidgets('a disc ring stays a circle', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Avatar(initials: 'AB', ring: true)),
      );
      await tester.pump();

      final stroke = ringLayers(tester).singleWhere((d) => d.border != null);
      expect(stroke.borderRadius, BorderRadius.circular(9999 + 2 + 2));
    });

    testWidgets('a picture takes the tile, not an oval', (tester) async {
      final picture = (await tester.runAsync(_solidPicture))!;
      addTearDown(imageCache.clear);
      imageCache.putIfAbsent(
        const NetworkImage(_kPictureUrl),
        () => OneFrameImageStreamCompleter(
          SynchronousFuture(ImageInfo(image: picture)),
        ),
      );
      final boundaryKey = GlobalKey();

      await tester.pumpWidget(
        _buildApp(
          material.Center(
            child: material.RepaintBoundary(
              key: boundaryKey,
              child: const Avatar(
                imageUrl: _kPictureUrl,
                initials: 'AB',
                shape: CoreAvatarShape.rounded,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ClipOval), findsNothing);
      expect(
        find.descendant(
          of: find.byType(OutlinedContainer),
          matching: find.byType(Image),
        ),
        findsOneWidget,
      );
      final box = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(OutlinedContainer),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect(box.clipBehavior, isNot(Clip.none));
      expect(paintedCorner(tester), BorderRadius.circular(8));

      // What reaches the screen: the loaded picture is cut by the sm
      // tile's 8 corner. Read where the tile and a disc disagree — pixel
      // (3, 3) sits inside an 8 corner (6.4 from its centre) and outside a
      // 16 disc (17.7 from the middle); pixel (0, 0) is outside both.
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(boundaryKey),
      );
      final pixels = (await tester.runAsync(() => _readPixels(boundary)))!;
      expect(_pixelAt(pixels, 16, 16), [0xFF, 0x00, 0x00, 0xFF]);
      expect(_pixelAt(pixels, 3, 3), [0xFF, 0x00, 0x00, 0xFF]);
      expect(_pixelAt(pixels, 0, 0)[3], 0);
      expect(_pixelAt(pixels, _kPictureSide - 1, _kPictureSide - 1)[3], 0);
    });

    testWidgets('a stated corner wins over both shapes', (tester) async {
      for (final shape in CoreAvatarShape.values) {
        await tester.pumpWidget(
          _buildApp(Avatar(initials: 'AB', shape: shape).radius4),
        );
        await tester.pump();

        expect(paintedCorner(tester), BorderRadius.circular(4));
      }
    });

    testWidgets('a theme corner wins over both shapes', (tester) async {
      for (final shape in CoreAvatarShape.values) {
        await tester.pumpWidget(
          material.MaterialApp(
            home: Theme(
              data: const ThemeData(
                coreComponentTheme: CoreComponentTheme(
                  avatar: CoreAvatarTheme(
                    style: CoreAvatarStyle(
                      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
                    ),
                  ),
                ),
              ),
              child: Avatar(initials: 'AB', shape: shape),
            ),
          ),
        );
        await tester.pump();

        expect(paintedCorner(tester), BorderRadius.circular(2));
      }
    });

    testWidgets('a stated diameter keeps the step corner', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Avatar(
            initials: 'AB',
            shape: CoreAvatarShape.rounded,
            avatarStyle: CoreAvatarStyle(diameter: 52),
          ),
        ),
      );
      await tester.pump();

      expect(paintedCorner(tester), BorderRadius.circular(8));
    });

    testWidgets('copyWith carries the shape', (tester) async {
      const original = Avatar(initials: 'AB', shape: CoreAvatarShape.rounded);
      expect(original.copyWith(ring: true).shape, CoreAvatarShape.rounded);
      expect(original.radius4.shape, CoreAvatarShape.rounded);
      expect(
        original.copyWith(shape: CoreAvatarShape.circle).shape,
        CoreAvatarShape.circle,
      );
    });
  });
}
