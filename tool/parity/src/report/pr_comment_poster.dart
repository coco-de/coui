import 'dart:io';

/// Whether `report.dart` should attempt to post a PR comment, and why —
/// split from the actual `gh pr comment` shell-out so the decision (which
/// env vars matter, what "nothing to post" means) is unit-testable without
/// touching real env vars/PATH.
class PrCommentDecision {
  const PrCommentDecision({required this.shouldPost, required this.reason});

  final bool shouldPost;

  /// Logged either way — a "no" here should be as legible from the CI log
  /// as a "yes" (silent no-ops are how CI wiring gaps hide).
  final String reason;
}

/// [requestedPosting] is the CLI's own `--post-comment` flag — the
/// operator's stated intent. [comment] `null` means Reporter found nothing
/// to say (#3617 완료 정의: "실패 0건 시 코멘트 미게시").
/// [hasGhToken]/[hasGhExecutable] let callers/tests substitute the
/// environment without touching real env vars/PATH.
PrCommentDecision decidePrCommentPosting({
  required bool requestedPosting,
  required String? comment,
  required bool hasGhToken,
  required bool hasGhExecutable,
}) {
  if (!requestedPosting) {
    return const PrCommentDecision(
      shouldPost: false,
      reason: '--post-comment 미지정',
    );
  }
  if (comment == null) {
    return const PrCommentDecision(
      shouldPost: false,
      reason: '실패 0건 — 코멘트 없음',
    );
  }
  if (!hasGhExecutable) {
    return const PrCommentDecision(
      shouldPost: false,
      reason: 'gh CLI 를 찾지 못함',
    );
  }
  if (!hasGhToken) {
    return const PrCommentDecision(
      shouldPost: false,
      reason: 'GH_TOKEN/GITHUB_TOKEN 미설정 — PR 이벤트가 아니거나 권한 없음',
    );
  }
  return const PrCommentDecision(shouldPost: true, reason: 'ok');
}

/// The result of actually shelling out to `gh pr comment`.
class PrCommentPostResult {
  const PrCommentPostResult({required this.success, required this.detail});

  final bool success;
  final String detail;
}

/// Posts [comment] via `gh pr comment --body-file` against the PR for the
/// current branch/checkout. A failure here is an amenity failing, not a
/// reason to change `report.dart`'s own exit code — the caller only logs
/// [PrCommentPostResult.detail].
PrCommentPostResult postPrComment(String comment) {
  final tempFile = File(
    '${Directory.systemTemp.path}/coui-parity-report-comment-'
    '${DateTime.now().microsecondsSinceEpoch}.md',
  )..writeAsStringSync(comment);
  try {
    final result = Process.runSync('gh', [
      'pr',
      'comment',
      '--body-file',
      tempFile.path,
    ]);
    if (result.exitCode != 0) {
      return PrCommentPostResult(
        success: false,
        detail: 'gh pr comment 실패 (exit ${result.exitCode}): ${result.stderr}',
      );
    }
    return const PrCommentPostResult(success: true, detail: 'posted');
  } finally {
    if (tempFile.existsSync()) tempFile.deleteSync();
  }
}
