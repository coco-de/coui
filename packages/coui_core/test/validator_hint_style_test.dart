// The two sizes a validator hint is drawn at, pinned.
//
// Both were changed to agree with something outside this component, and
// neither agreement is visible from inside the file — so without these the
// next edit reverts them and nothing says anything.
//
// The icon matches `Banner`: same job (a severity glyph beside a line of
// message text), and one signal drawn at two sizes reads as two signals.
//
// It used to be anchored to `Alert`, which drew the same bare glyph until
// that component grew a title-and-description block and sized its glyph to
// that instead of to a line. Worth stating because the failure looked like
// the hint had drifted when it had not: the hint held at 16 and the thing
// it was pinned to walked away.
//
// The message matches a field's helper text: they occupy the same place and
// alternate — helper while the value is fine, this the moment it is not. Two
// styles in that one slot make the field twitch as the user types.
import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  group('CoreValidatorHintStyle defaults', () {
    test('the icon is the size Banner draws its own severity glyph at', () {
      expect(
        CoreValidatorHintStyle.defaultIconStyle.size,
        CoreBannerStyle.defaultIconStyle.size,
      );
    });

    test('Alert is no longer a valid anchor for it', () {
      // The reason the anchor moved, made falsifiable. If Alert ever draws
      // a bare glyph again its icon comes back down to a line-height size,
      // this fails, and whoever sees it should re-pin the hint to Alert
      // rather than delete this — the two components agreeing is the
      // desirable state, and this records that it is currently not the case
      // for a reason rather than by neglect.
      expect(
        CoreAlertStyle.defaultIconStyle.size,
        isNot(CoreValidatorHintStyle.defaultIconStyle.size),
        reason:
            'Alert draws its glyph beside a title-and-description block, '
            'not beside a single line of message text',
      );
    });

    test('the message is the role a field helper is written in', () {
      expect(
        CoreValidatorHintStyle.defaultMessageTextStyle.token,
        CoreTextFieldStyle.defaultDescriptionStyle.token,
      );
    });

    test('and it draws exactly as that helper draws', () {
      // Guards the invariant, not just the token: a label role sits one
      // pixel away from the helper's body role on the scale, and swapping
      // to it would still be "a token", so a token-shaped assertion alone
      // would not show what moved. Read both through the scale and compare
      // what lands on screen.
      const typography = CoreTypography.coui;
      final message = CoreValidatorHintStyle.defaultMessageTextStyle.token!
          .read(typography);
      final helper = CoreTextFieldStyle.defaultDescriptionStyle.token!.read(
        typography,
      );

      expect(message.fontSize, helper.fontSize);
      expect(message.fontWeight, helper.fontWeight);
      expect(message.lineHeight, helper.lineHeight);
    });
  });
}
