import 'package:test/test.dart';

import '../../src/report/pr_comment_poster.dart';

void main() {
  group('decidePrCommentPosting', () {
    test('--post-comment not requested -> no post', () {
      final decision = decidePrCommentPosting(
        requestedPosting: false,
        comment: 'body',
        hasGhToken: true,
        hasGhExecutable: true,
      );

      expect(decision.shouldPost, isFalse);
    });

    test('requested but 0 failures (comment null) -> no post', () {
      final decision = decidePrCommentPosting(
        requestedPosting: true,
        comment: null,
        hasGhToken: true,
        hasGhExecutable: true,
      );

      expect(decision.shouldPost, isFalse);
      expect(decision.reason, contains('실패 0건'));
    });

    test('requested but gh missing -> no post', () {
      final decision = decidePrCommentPosting(
        requestedPosting: true,
        comment: 'body',
        hasGhToken: true,
        hasGhExecutable: false,
      );

      expect(decision.shouldPost, isFalse);
      expect(decision.reason, contains('gh CLI'));
    });

    test('requested but no token -> no post', () {
      final decision = decidePrCommentPosting(
        requestedPosting: true,
        comment: 'body',
        hasGhToken: false,
        hasGhExecutable: true,
      );

      expect(decision.shouldPost, isFalse);
      expect(decision.reason, contains('TOKEN'));
    });

    test('requested + comment + gh + token -> post', () {
      final decision = decidePrCommentPosting(
        requestedPosting: true,
        comment: 'body',
        hasGhToken: true,
        hasGhExecutable: true,
      );

      expect(decision.shouldPost, isTrue);
    });
  });
}
