import 'surface_marker_registry.dart';

/// Catalog group ids that are entirely Tier1 — every component in the group,
/// every variant.
///
/// Source: `.bmad/architecture-*.md` "미해결 기술 스파이크 → ✅ 해소됨 →
/// Tier1 컴포넌트 목록" — "`overlay` 그룹 전체(9) + `menu` 전체(5) +
/// `control` 전체(6)".
const Set<String> kTier1GroupIds = {'control', 'menu', 'overlay'};

/// The ten `form` group slugs the architecture doc names as
/// "고빈도·고위험" and puts in Tier1 by name rather than by group (`form`
/// as a whole has 32 entries — too broad to take wholesale).
///
/// This is a policy decision the PRD/architecture made by hand (the doc
/// says as much — "최종 목록은 Sprint Planning에서 확정") and is not
/// mechanically derivable from any existing enum or catalog field. Encoding
/// it as a named, documented set here satisfies NFR-003's "정책이 코드에
/// 있고 목록이 코드에서 파생되어야 한다" — the *policy* (these ten, by
/// name) lives in code and every other tier1 slug is computed from it, even
/// though this one ingredient of the policy is itself a literal list.
const Set<String> kTier1FormSlugs = {
  'text-field',
  'text-area',
  'select',
  'checkbox',
  'toggle',
  'slider',
  'date-picker',
  'time-picker',
  'radio-group',
  'autocomplete',
};

/// Components with a confirmed, PRD-verified cross-platform defect. These
/// must be in Tier1 regardless of what group/policy math says, because the
/// whole pipeline's completion definition (#3595, #3607) is proving it
/// turns these two RED before it turns anything else green.
const Set<String> kConfirmedDefectSlugs = {'command', 'date-picker', 'dialog'};

/// Whether [slug] (belonging to catalog group [groupId]) is Tier1.
///
/// Tier1 = [kTier1GroupIds] membership (whole group) ∪ [kTier1FormSlugs] ∪
/// [kSurfaceMarkerComponentSlugs] (every surface-marker holder, whether or
/// not its group is already covered — set union makes the overlap with
/// `overlay`'s `dialog`/`tooltip` harmless) ∪ [kConfirmedDefectSlugs].
///
/// Anything not matched here is Tier2 — there is no third bucket and no
/// "unclassified" state; #3604's completion definition requires exactly
/// this fall-through.
bool isTier1(String slug, String groupId) =>
    kTier1GroupIds.contains(groupId) ||
    kTier1FormSlugs.contains(slug) ||
    kSurfaceMarkerComponentSlugs.contains(slug) ||
    kConfirmedDefectSlugs.contains(slug);
