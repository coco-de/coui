/// Classifies [StaticMember]s discovered by `style_reader.dart` into the
/// two shapes the rest of the reader pipeline cares about — a single-value
/// design-system default, or a dispatch table keyed by an enum/bool/other
/// discriminator. Classification is by *declared type*
/// (`core/style-contract.md` convention #1: "필드 수집은 이름이 아니라 타입
/// 기반"), never by whether the name matches `default[A-Z]` or
/// `defaultsBy*` — those are reported alongside the classification for
/// coverage tooling (`#3751`'s G3/G4 guards), not used to drive it.
library;

import 'style_reader.dart';

/// The seven conventionally-named dispatch tables this codebase already
/// uses (`core/style-contract.md`'s "7개 이름 46멤버"). A member matching
/// one of these is still discovered and classified purely by type — this
/// set exists only so census reporting can separate "known convention" from
/// "off-convention but still discovered" dispatch tables, per the reader's
/// non-regression requirement (an unlisted 8th name must still be found).
const kConventionalDispatchNames = {
  'defaultsByVariant',
  'defaultsBySize',
  'defaultsByType',
  'defaultsByTone',
  'defaultsByStatus',
  'defaultsByState',
  'defaultsByColor',
  // `defaultsByPresentation` dispatches `Command` on its `presentation:`
  // axis (`CoreCommandPresentation` — inline / dialog / fullscreen), the
  // same name-follows-parameter rule as the others.
  'defaultsByPresentation',
  // `defaultsByLayout` dispatches `DefinitionList` on its `layout:` axis
  // (`CoreDefinitionLayout` — inline / stacked / columns), the same
  // name-follows-parameter rule.
  'defaultsByLayout',
};

/// `true` when [member]'s declared type is a dispatch table (`Map<K, V>`),
/// regardless of name.
bool isDispatchTable(StaticMember member) =>
    member.typeSource.startsWith('Map<');

/// `true` when [member] is a scalar (non-Map) design-system default —
/// i.e. every non-dispatch `static const`/`static final` member. Unlike
/// [isDispatchTable], this makes no claim about the *name* (`default[A-Z]`
/// vs off-convention) — callers that need that distinction read
/// [member].name directly; this reader doesn't gate discovery on naming
/// (see this file's doc comment).
bool isScalarDefault(StaticMember member) => !isDispatchTable(member);

/// One row of the reader's population census — the counts `#3746`'s
/// completion criteria and `#3751`'s G3/G4 guards both read.
final class ReaderCensus {
  const ReaderCensus({
    required this.filesParsed,
    required this.filesFailed,
    required this.mainStyleClassCount,
    required this.totalClassCount,
    required this.scalarDefaultCount,
    required this.dispatchTableCount,
    required this.offConventionDispatchNames,
  });

  final int filesParsed;
  final List<String> filesFailed;

  /// Classes whose `implements` clause names `CoreStyle` — the MAIN Style
  /// category (`core/style-contract.md`'s "Style 클래스 3 종").
  final int mainStyleClassCount;

  /// Every discovered class, MAIN and auxiliary (`CoreXxxVariantStyle`,
  /// `CoreXxxContract`, `CoreXxxTheme`, …) combined.
  final int totalClassCount;

  final int scalarDefaultCount;
  final int dispatchTableCount;

  /// `ClassName.memberName` for every dispatch table whose name isn't one
  /// of [kConventionalDispatchNames] — the set `#3751`'s G4 baseline pins.
  final List<String> offConventionDispatchNames;
}

/// Builds the census from a `RepoReadResult`-shaped input — kept generic
/// over the two collections `repo_reader.dart` produces rather than
/// depending on that file directly, so `census.dart` stays a pure function
/// of "classes it was handed," easy to unit test without touching disk.
ReaderCensus buildCensus({
  required Iterable<DiscoveredClass> classes,
  required int filesParsed,
  required List<String> filesFailed,
}) {
  var mainCount = 0;
  var totalCount = 0;
  var scalarCount = 0;
  var dispatchCount = 0;
  final offConvention = <String>[];

  for (final cls in classes) {
    totalCount++;
    if (cls.implementsCoreStyle) mainCount++;
    for (final member in cls.staticMembers) {
      if (isDispatchTable(member)) {
        dispatchCount++;
        if (!kConventionalDispatchNames.contains(member.name)) {
          offConvention.add('${cls.name}.${member.name}');
        }
      } else {
        scalarCount++;
      }
    }
  }

  return ReaderCensus(
    filesParsed: filesParsed,
    filesFailed: filesFailed,
    mainStyleClassCount: mainCount,
    totalClassCount: totalCount,
    scalarDefaultCount: scalarCount,
    dispatchTableCount: dispatchCount,
    offConventionDispatchNames: offConvention,
  );
}
