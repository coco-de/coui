import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('Avatar Golden', () {
    goldenTest(
      'all variants',
      fileName: 'avatar_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'initials',
            child: buildGoldenTestApp(const Avatar(initials: 'JD')),
          ),
          GoldenTestScenario(
            name: 'no initials fallback',
            // Neither `imageUrl` nor `initials` is set — falls back to
            // the `?` placeholder glyph.
            child: buildGoldenTestApp(const Avatar()),
          ),
          GoldenTestScenario(
            name: 'with ring',
            child: buildGoldenTestApp(
              const Avatar(initials: 'AB', ring: true),
            ),
          ),
          GoldenTestScenario(
            name: 'with badge',
            child: buildGoldenTestApp(
              const Avatar(
                initials: 'CD',
                badge: AvatarBadge(
                  avatarBadgeStyle: CoreAvatarBadgeStyle(
                    backgroundColor: CoreColor.token(CoreColors.success),
                  ),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'large size',
            child: buildGoldenTestApp(
              const Avatar(initials: 'EF', size: CoreComponentSize.lg),
            ),
          ),
          GoldenTestScenario(
            name: 'rounded',
            child: buildGoldenTestApp(
              const Avatar(
                initials: 'GH',
                size: CoreComponentSize.lg,
                shape: CoreAvatarShape.rounded,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'rounded with ring',
            child: buildGoldenTestApp(
              const Avatar(
                initials: 'IJ',
                shape: CoreAvatarShape.rounded,
                ring: true,
              ),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
