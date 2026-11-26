import {
  exportDartTokens,
  findDanglingReferences,
  findInvalidIdentifiers,
} from '../src/export-dart';

// Minimal Figma double: only what exportDartTokens touches.
interface FakeMode { modeId: string; name: string }
interface FakeColl { id: string; name: string; modes: FakeMode[] }
interface FakeVar {
  id: string;
  name: string;
  variableCollectionId: string;
  resolvedType: string;
  valuesByMode: Record<string, unknown>;
  scopes?: string[];
}

function installFigma(colls: FakeColl[], vars: FakeVar[]) {
  (globalThis as any).figma = {
    variables: {
      getLocalVariableCollectionsAsync: async () => colls,
      getLocalVariablesAsync: async () => vars,
    },
  };
}

const MODE = [{ modeId: 'm1', name: 'Value' }];

function coll(id: string, name: string): FakeColl {
  return { id, name, modes: MODE };
}
function float(id: string, coll: string, name: string, value: number): FakeVar {
  return {
    id,
    name,
    variableCollectionId: coll,
    resolvedType: 'FLOAT',
    valuesByMode: { m1: value },
  };
}

function scoped(v: FakeVar, scopes: string[]): FakeVar {
  return { ...v, scopes };
}
function alias(id: string): { type: string; id: string } {
  return { type: 'VARIABLE_ALIAS', id };
}

// The consumer contract (coco-de/exchange-money `figma_tokens_source.dart`):
// a `/// Figma:` line immediately followed by its `static const`. A consumer
// pairs every member with its source through this exact shape, so a unit
// note that lands between the two silently unpairs them.
const CONSUMER_MEMBER = new RegExp(
  '/// Figma: `(.+?) / (.+?)`(?: \\(mode: (\\w+)\\))?\\n' +
    '\\s*static const (\\w+) (\\w+) =\\s*([^;]+);',
  'g',
);
function consumerPairs(content: string): number {
  return (content.match(CONSUMER_MEMBER) || []).length;
}
function staticConsts(content: string): number {
  return (content.match(/^  static const /gm) || []).length;
}

let failures = 0;
function check(label: string, cond: boolean, detail?: string) {
  if (cond) {
    console.log(`  ✓ ${label}`);
  } else {
    console.log(`  ✗ ${label}${detail ? ' — ' + detail : ''}`);
    failures++;
  }
}

// Every `abstract final class <Name> {` the export emitted.
function classNames(content: string): string[] {
  const out: string[] = [];
  const re = /abstract final class (\S+) \{/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(content)) !== null) out.push(m[1]);
  return out;
}

const DART_IDENT = /^[A-Za-z_][A-Za-z0-9_]*$/;

async function main() {
  // ── 1. the kobic#12765 bug: sort-prefixed collection names ────────────
  //
  // A file may order its collections with a numeric prefix — `0. Primitives`,
  // `1.1 Semantic/Color`, `2. Component`. Feeding those straight through
  // produced `0PrimitivesSpace`, which is not a legal Dart identifier: the
  // whole generated file failed to compile while the plugin still reported
  // success. The prefix is presentation, not meaning, so it is stripped.
  installFigma(
    [
      coll('c0', '0. Primitives'),
      coll('c1', '1.1 Semantic/Color'),
      coll('c2', '2. Component'),
    ],
    [
      float('v0', 'c0', 'space/16', 16),
      float('v1', 'c1', 'radius/8', 8),
      float('v2', 'c2', 'button/height-md', 40),
    ],
  );
  console.log('sort-prefixed collection names');
  let out: Awaited<ReturnType<typeof exportDartTokens>> = {
    files: [{ name: '', content: '' }],
    log: [],
  };
  try {
    out = await exportDartTokens();
  } catch (e) {
    // The validator refusing this fixture means the class-name fix regressed —
    // report it as a failed check rather than crashing the whole run.
    check('export succeeds on sort-prefixed names', false, String(e));
  }
  let names = classNames(out.files[0].content);
  check('3 classes emitted', names.length === 3, names.join(', '));
  check(
    'no class name starts with a digit',
    names.every((n) => DART_IDENT.test(n)),
    names.join(', '),
  );
  check(
    'prefix stripped, rest kept',
    names.includes('PrimitivesSpace') &&
      names.includes('SemanticColorRadius') &&
      names.includes('ComponentButton'),
    names.join(', '),
  );

  // ── 2. members keep their own leading-digit guard ─────────────────────
  //
  // `space/16` must stay `space16`, not become `16`. This guard predates the
  // class-name one; the point here is that fixing classes did not break it.
  check(
    'member keeps group prefix when it would start with a digit',
    out.files[0].content.includes('space16'),
  );

  // ── 3. a digits-only collection name leaves nothing behind ────────────
  installFigma([coll('c0', '0.')], [float('v0', 'c0', 'opacity/50', 50)]);
  out = await exportDartTokens();
  names = classNames(out.files[0].content);
  console.log('digits-only collection name');
  check('falls back rather than emitting an empty segment', names[0] === 'TokensOpacity', names.join(', '));

  // ── 4. aliases point at the corrected class name ──────────────────────
  //
  // An alias emits `<TargetClass>.<member>`. If the class rename did not
  // reach the alias path, the reference would name a class that no longer
  // exists — still uncompilable, just one layer further in.
  installFigma(
    [coll('c0', '0. Primitives'), coll('c1', '1.1 Semantic/Color')],
    [
      float('v0', 'c0', 'space/16', 16),
      {
        id: 'v1',
        name: 'gap/default',
        variableCollectionId: 'c1',
        resolvedType: 'FLOAT',
        valuesByMode: { m1: { type: 'VARIABLE_ALIAS', id: 'v0' } },
      },
    ],
  );
  out = await exportDartTokens();
  console.log('alias reference');
  check(
    'alias names the stripped class',
    out.files[0].content.includes('= PrimitivesSpace.space16;'),
    out.files[0].content,
  );
  check('alias was not skipped', out.log.every((l) => !l.startsWith('! skipped')), out.log.join(' | '));

  // ── 5. the backstop: refuse to emit uncompilable source ───────────────
  //
  // `classIdent` covers the known case. This is for the ones a future rename
  // invents — here a variable whose name is punctuation only, which leaves an
  // empty member. Reporting success for a file nobody can build is worse than
  // failing: the breakage surfaces downstream, far from its cause.
  installFigma([coll('c0', 'Primitives')], [float('v0', 'c0', '/', 1)]);
  console.log('invalid identifier backstop');
  let threw = '';
  try {
    await exportDartTokens();
  } catch (e) {
    threw = String(e);
  }
  check('export throws instead of reporting success', threw !== '');
  check(
    'the error names what to fix',
    threw.includes('Dart 식별자'),
    threw,
  );

  // ── 6. the class-name branch, called directly ────────────────────────
  //
  // No Figma fixture can reach it: `classIdent` guarantees a leading letter,
  // so the export always produces a legal class name. That makes the branch
  // unreachable-by-fixture, and an unreachable check is indistinguishable from
  // a deleted one — deleting it here left every fixture still passing. Calling
  // the validator directly is what holds it in place.
  console.log('class-name branch (direct)');
  check(
    'a digit-leading class name is reported',
    findInvalidIdentifiers([{ className: '0PrimitivesSpace', member: 'space16' }]).join() ===
      'class 0PrimitivesSpace',
  );
  check(
    'an empty member is reported',
    findInvalidIdentifiers([{ className: 'Primitives', member: '' }]).join() === 'Primitives.',
  );
  check(
    'legal names report nothing',
    findInvalidIdentifiers([{ className: 'PrimitivesSpace', member: 'space16' }]).length === 0,
  );

  // ── 7. an alias takes the TARGET's modes, not the consumer's ─────────
  //
  // kobic#12993. Sections 1–6 only ever aliased between single-mode
  // collections, so the consumer's suffix (always '') happened to be right
  // and the bug was invisible. The real file has four-mode Semantic
  // collections aliasing single-mode Primitives: every reference came out as
  // `PrimitivesColors.whiteDark` / `…HCLight`, names Primitives never
  // declares. 452 dangling references, and the whole export failed to
  // compile while reporting success.
  const PRIMITIVE_MODE = [{ modeId: 'p1', name: 'Value' }];
  const FOUR_MODES = [
    { modeId: 's1', name: 'Light' },
    { modeId: 's2', name: 'Dark' },
    { modeId: 's3', name: 'HCLight' },
    { modeId: 's4', name: 'HCDark' },
  ];
  const WHITE = { r: 1, g: 1, b: 1, a: 1 };
  installFigma(
    [
      { id: 'c0', name: '0. Primitives', modes: PRIMITIVE_MODE },
      { id: 'c1', name: '1-1. Semantic/ Color', modes: FOUR_MODES },
    ],
    [
      {
        id: 'v0',
        name: 'color/white',
        variableCollectionId: 'c0',
        resolvedType: 'COLOR',
        valuesByMode: { p1: WHITE },
      },
      {
        id: 'v1',
        name: 'color/surface',
        variableCollectionId: 'c1',
        resolvedType: 'COLOR',
        valuesByMode: {
          s1: { type: 'VARIABLE_ALIAS', id: 'v0' },
          s2: { type: 'VARIABLE_ALIAS', id: 'v0' },
          s3: { type: 'VARIABLE_ALIAS', id: 'v0' },
          s4: { type: 'VARIABLE_ALIAS', id: 'v0' },
        },
      },
    ],
  );
  console.log('alias target modes (multi-mode → single-mode)');
  let multiMode = '';
  try {
    multiMode = (await exportDartTokens()).files[0].content;
  } catch (e) {
    check('export succeeds when a 4-mode collection aliases a 1-mode one', false, String(e));
  }
  check(
    'every mode of the consumer resolves to the target\'s unsuffixed member',
    (multiMode.match(/= PrimitivesColors\.white;/g) || []).length === 4,
    multiMode,
  );
  check(
    'the consumer suffix is not pasted onto the target',
    !/PrimitivesColors\.white(Dark|HCLight|HCDark)/.test(multiMode),
    multiMode,
  );
  check(
    'the consumer still gets its own suffixed members',
    multiMode.includes('surfaceDark') &&
      multiMode.includes('surfaceHCLight') &&
      multiMode.includes('surfaceHCDark'),
    multiMode,
  );

  // ── 8. when BOTH sides are multi-mode, match by mode name ────────────
  //
  // The fix must not overcorrect into "always unsuffixed": a Dark consumer
  // reading a target that also has Dark should read the target's Dark.
  const TWO = [
    { modeId: 'a1', name: 'Light' },
    { modeId: 'a2', name: 'Dark' },
  ];
  installFigma(
    [
      { id: 'c0', name: 'Palette', modes: TWO },
      { id: 'c1', name: 'Semantic', modes: [{ modeId: 'b1', name: 'Light' }, { modeId: 'b2', name: 'Dark' }] },
    ],
    [
      {
        id: 'v0',
        name: 'color/base',
        variableCollectionId: 'c0',
        resolvedType: 'COLOR',
        valuesByMode: { a1: WHITE, a2: { r: 0, g: 0, b: 0, a: 1 } },
      },
      {
        id: 'v1',
        name: 'color/surface',
        variableCollectionId: 'c1',
        resolvedType: 'COLOR',
        valuesByMode: {
          b1: { type: 'VARIABLE_ALIAS', id: 'v0' },
          b2: { type: 'VARIABLE_ALIAS', id: 'v0' },
        },
      },
    ],
  );
  const bothMulti = (await exportDartTokens()).files[0].content;
  console.log('alias target modes (multi-mode → multi-mode)');
  check(
    'Light reads the target\'s Light (unsuffixed)',
    /surface = PaletteColors\.base;/.test(bothMulti),
    bothMulti,
  );
  check(
    'Dark reads the target\'s Dark, not its Light',
    /surfaceDark = PaletteColors\.baseDark;/.test(bothMulti),
    bothMulti,
  );

  // ── 9. the dangling-reference backstop, through a real export ────────
  //
  // A target that has no value in one of its own modes: the alias still
  // resolves by name (the collection HAS that mode), but the member is never
  // declared because `valuesByMode` skips it. This is the shape §7's fix
  // cannot prevent, and it reaches the backstop through `generateDart` —
  // calling `findDanglingReferences` directly would leave the wiring
  // untested, which mutation testing confirmed (removing the call from
  // `generateDart` left a direct-call-only check passing).
  installFigma(
    [
      { id: 'c0', name: 'Palette', modes: TWO },
      { id: 'c1', name: 'Semantic', modes: [{ modeId: 'b1', name: 'Light' }, { modeId: 'b2', name: 'Dark' }] },
    ],
    [
      {
        id: 'v0',
        name: 'color/base',
        variableCollectionId: 'c0',
        resolvedType: 'COLOR',
        valuesByMode: { a1: WHITE }, // Dark 값 없음 → baseDark 는 선언되지 않는다
      },
      {
        id: 'v1',
        name: 'color/surface',
        variableCollectionId: 'c1',
        resolvedType: 'COLOR',
        valuesByMode: {
          b1: { type: 'VARIABLE_ALIAS', id: 'v0' },
          b2: { type: 'VARIABLE_ALIAS', id: 'v0' }, // → PaletteColors.baseDark
        },
      },
    ],
  );
  console.log('dangling-reference backstop (through export)');
  let danglingErr = '';
  try {
    await exportDartTokens();
  } catch (e) {
    danglingErr = String(e);
  }
  check('export throws instead of emitting an unresolvable reference', danglingErr !== '');
  check(
    'the error names the unresolved reference',
    danglingErr.includes('PaletteColors.baseDark'),
    danglingErr,
  );

  console.log('dangling-reference backstop (direct)');
  check(
    'a reference with no declaration is reported',
    findDanglingReferences(
      ['PrimitivesColors.white'],
      [{ from: 'SemanticColors.surfaceDark', to: 'PrimitivesColors.whiteDark' }],
    ).join() === 'SemanticColors.surfaceDark → PrimitivesColors.whiteDark',
  );
  check(
    'a resolved reference reports nothing',
    findDanglingReferences(
      ['PrimitivesColors.white'],
      [{ from: 'SemanticColors.surface', to: 'PrimitivesColors.white' }],
    ).length === 0,
  );

  // ── 10. a font weight is `int`, across its alias chain ─────────────────
  //
  // `CoreTextStyle.fontWeight` is the CSS 100–900 integer (`int?`). Emitting
  // `double` made the consumer write `.toInt()`, which a `const` style cannot
  // hold. The semantic weight is the scoped one; the primitive it aliases has
  // no scope, and still has to be `int` or the reference would assign a
  // `double` to an `int`.
  const TYPO_MODES = [
    { modeId: 't1', name: 'Mobile' },
    { modeId: 't2', name: 'Tablet' },
    { modeId: 't3', name: 'Desktop' },
  ];
  installFigma(
    [
      { id: 'c0', name: '0. Primitives', modes: PRIMITIVE_MODE },
      { id: 'c1', name: '1-2. Semantic/ Typography', modes: TYPO_MODES },
    ],
    [
      { id: 'w600', name: 'font/weight/semibold', variableCollectionId: 'c0', resolvedType: 'FLOAT', valuesByMode: { p1: 600 } },
      scoped(
        { id: 'w100', name: 'font/weight/thin', variableCollectionId: 'c0', resolvedType: 'FLOAT', valuesByMode: { p1: 100 } },
        ['FONT_WEIGHT'],
      ),
      { id: 's14', name: 'font/size/14', variableCollectionId: 'c0', resolvedType: 'FLOAT', valuesByMode: { p1: 14 } },
      scoped(
        {
          id: 'wTitle',
          name: 'font-weight/title',
          variableCollectionId: 'c1',
          resolvedType: 'FLOAT',
          valuesByMode: { t1: alias('w600'), t2: alias('w600'), t3: alias('w600') },
        },
        ['FONT_WEIGHT'],
      ),
    ],
  );
  console.log('font weight → int');
  const weights = await exportDartTokens();
  const wDart = weights.files[0].content;
  check('an aliased primitive weight is int', wDart.includes('static const int weightSemibold = 600;'), wDart);
  check('a scoped primitive weight is int', wDart.includes('static const int weightThin = 100;'), wDart);
  check(
    'the semantic weight is int in every mode',
    wDart.includes('static const int title = PrimitivesFont.weightSemibold;') &&
      wDart.includes('static const int titleTablet = PrimitivesFont.weightSemibold;') &&
      wDart.includes('static const int titleDesktop = PrimitivesFont.weightSemibold;'),
    wDart,
  );
  check('an unscoped, unaliased number stays double', wDart.includes('static const double size14 = 14;'), wDart);
  check(
    'the log counts the weights',
    weights.log.some((l) => l.includes('굵기 3개 → int')),
    weights.log.join(' | '),
  );

  // ── 11. a letter spacing is em, the unit in its name ──────────────────
  //
  // Figma reads a bound letter spacing as px; `CoreTextStyle.letterSpacing`
  // is an em ratio. The px is divided by the font size that pairs with it —
  // per mode, since the size is responsive — and the member is renamed: a
  // consumer that divided the px itself keeps compiling under the old name
  // and divides twice, so the old name has to go.
  installFigma(
    [
      { id: 'c0', name: '0. Primitives', modes: PRIMITIVE_MODE },
      { id: 'c1', name: '1-2. Semantic/ Typography', modes: TYPO_MODES },
      { id: 'c2', name: '2. Component', modes: MODE },
    ],
    [
      { id: 'fs36', name: 'font/size/36', variableCollectionId: 'c0', resolvedType: 'FLOAT', valuesByMode: { p1: 36 } },
      scoped(
        {
          id: 'fsDL',
          name: 'font-size/display-large',
          variableCollectionId: 'c1',
          resolvedType: 'FLOAT',
          // The mobile size is an alias — the division follows it.
          valuesByMode: { t1: alias('fs36'), t2: 44, t3: 52 },
        },
        ['FONT_SIZE'],
      ),
      scoped(
        {
          id: 'lsDL',
          name: 'letter-spacing/display-large',
          variableCollectionId: 'c1',
          resolvedType: 'FLOAT',
          // Figma stores float32: these are −0.9 · −1.1 · −1.3 as it hands them over.
          valuesByMode: { t1: -0.8999999761581421, t2: -1.100000023841858, t3: -1.2999999523162842 },
        },
        ['LETTER_SPACING'],
      ),
      scoped(
        {
          id: 'ls14',
          name: 'letter-spacing/size-14',
          variableCollectionId: 'c1',
          resolvedType: 'FLOAT',
          valuesByMode: { t1: -0.14, t2: -0.14, t3: -0.14 },
        },
        ['LETTER_SPACING'],
      ),
      {
        id: 'btnLs',
        name: 'button/letter-spacing',
        variableCollectionId: 'c2',
        resolvedType: 'FLOAT',
        valuesByMode: { m1: alias('lsDL') },
      },
      {
        id: 'btnLsPx',
        name: 'button/tracking-small',
        variableCollectionId: 'c2',
        resolvedType: 'FLOAT',
        valuesByMode: { m1: alias('ls14') },
      },
    ],
  );
  console.log('letter spacing → em, unit in the name');
  const tracking = await exportDartTokens();
  const tDart = tracking.files[0].content;
  check(
    'px ÷ the paired font size, per mode',
    tDart.includes('static const double displayLargeEm = -0.025;') &&
      tDart.includes('static const double displayLargeEmTablet = -0.025;') &&
      tDart.includes('static const double displayLargeEmDesktop = -0.025;'),
    tDart,
  );
  const trackingClass = tDart.slice(
    tDart.indexOf('abstract final class SemanticTypographyLetterSpacing {'),
    tDart.indexOf('abstract final class ComponentButton {'),
  );
  check(
    'the px-unit name is gone',
    trackingClass.length > 0 && !/static const double displayLarge(Tablet|Desktop)? =/.test(trackingClass),
    trackingClass,
  );
  check(
    'the em note names what it divided by',
    tDart.includes('/// em — Figma 의 px 를 `font-size/display-large` (36) 로 나눈 값.') &&
      tDart.includes('`font-size/display-large` (44)') &&
      tDart.includes('`font-size/display-large` (52)'),
    tDart,
  );
  check(
    'with no font size to pair, the value stays px and says so',
    tDart.includes('static const double size14Px = -0.14;') &&
      tDart.includes('/// px — Figma 값 그대로(짝이 되는 `font-size` 가 없다).'),
    tDart,
  );
  check(
    'an alias takes its target\'s unit and name',
    tDart.includes('static const double letterSpacingEm = SemanticTypographyLetterSpacing.displayLargeEm;') &&
      tDart.includes('static const double trackingSmallPx = SemanticTypographyLetterSpacing.size14Px;'),
    tDart,
  );
  check(
    'the font sizes themselves are untouched',
    tDart.includes('static const double displayLarge = PrimitivesFont.size36;') &&
      tDart.includes('static const double displayLargeTablet = 44;'),
    tDart,
  );
  check(
    'every member still pairs with its Figma line (consumer contract)',
    consumerPairs(tDart) === staticConsts(tDart) && staticConsts(tDart) > 0,
    `${consumerPairs(tDart)} paired of ${staticConsts(tDart)}`,
  );
  check(
    'the log counts the units',
    // Counted per variable, not per mode member.
    tracking.log.some((l) => l.includes('자간 2개 → em') && l.includes('2개 → px')),
    tracking.log.join(' | '),
  );

  // ── 12. what cannot be typed stays double, and is said ────────────────
  installFigma(
    [{ id: 'c1', name: 'Typo', modes: MODE }],
    [
      scoped(float('odd', 'c1', 'font-weight/odd', 450.5), ['FONT_WEIGHT']),
      scoped(float('both', 'c1', 'misc/both', 2), ['FONT_WEIGHT', 'LETTER_SPACING']),
      scoped(float('any', 'c1', 'misc/any', 3), ['ALL_SCOPES']),
    ],
  );
  console.log('untypable text numbers');
  const odd = await exportDartTokens();
  const oDart = odd.files[0].content;
  check('a fractional weight stays double', oDart.includes('static const double odd = 450.5;'), oDart);
  check('a weight-and-tracking scope stays double', oDart.includes('static const double both = 2;'), oDart);
  check('ALL_SCOPES says nothing', oDart.includes('static const double any = 3;'), oDart);
  check(
    'both are reported',
    odd.log.some((l) => l.includes('정수가 아님')) && odd.log.some((l) => l.includes('섞임')),
    odd.log.join(' | '),
  );

  // ── 13. snapshot — the two types, as a consumer reads them ────────────
  //
  // Every check above looks for a line. This pins the whole generated body
  // for a role a consumer wires into `CoreTextStyle`, so a change to the
  // types, the names or the note placement fails here even when each line
  // check still finds its substring.
  installFigma(
    [
      { id: 'c0', name: '0. Primitives', modes: PRIMITIVE_MODE },
      { id: 'c1', name: '1-2. Semantic/ Typography', modes: TYPO_MODES },
    ],
    [
      { id: 'w500', name: 'font/weight/medium', variableCollectionId: 'c0', resolvedType: 'FLOAT', valuesByMode: { p1: 500 } },
      scoped(
        { id: 'fs', name: 'font-size/label-large', variableCollectionId: 'c1', resolvedType: 'FLOAT', valuesByMode: { t1: 14, t2: 14, t3: 16 } },
        ['FONT_SIZE'],
      ),
      scoped(
        { id: 'fw', name: 'font-weight/label', variableCollectionId: 'c1', resolvedType: 'FLOAT', valuesByMode: { t1: alias('w500'), t2: alias('w500'), t3: alias('w500') } },
        ['FONT_WEIGHT'],
      ),
      scoped(
        { id: 'ls', name: 'letter-spacing/label-large', variableCollectionId: 'c1', resolvedType: 'FLOAT', valuesByMode: { t1: -0.14000000059604645, t2: -0.14000000059604645, t3: -0.1599999964237213 } },
        ['LETTER_SPACING'],
      ),
    ],
  );
  console.log('snapshot');
  const snap = (await exportDartTokens()).files[0].content;
  const body = snap.slice(snap.indexOf('abstract final class'));
  const expected = [
    'abstract final class PrimitivesFont {',
    '  /// Figma: `0. Primitives / font/weight/medium`',
    '  static const int weightMedium = 500;',
    '}',
    '',
    'abstract final class SemanticTypographyFontSize {',
    '  /// Figma: `1-2. Semantic/ Typography / font-size/label-large`',
    '  static const double labelLarge = 14;',
    '  /// Figma: `1-2. Semantic/ Typography / font-size/label-large` (mode: Tablet)',
    '  static const double labelLargeTablet = 14;',
    '  /// Figma: `1-2. Semantic/ Typography / font-size/label-large` (mode: Desktop)',
    '  static const double labelLargeDesktop = 16;',
    '}',
    '',
    'abstract final class SemanticTypographyFontWeight {',
    '  /// Figma: `1-2. Semantic/ Typography / font-weight/label`',
    '  static const int label = PrimitivesFont.weightMedium;',
    '  /// Figma: `1-2. Semantic/ Typography / font-weight/label` (mode: Tablet)',
    '  static const int labelTablet = PrimitivesFont.weightMedium;',
    '  /// Figma: `1-2. Semantic/ Typography / font-weight/label` (mode: Desktop)',
    '  static const int labelDesktop = PrimitivesFont.weightMedium;',
    '}',
    '',
    'abstract final class SemanticTypographyLetterSpacing {',
    '  /// em — Figma 의 px 를 `font-size/label-large` (14) 로 나눈 값. `CoreTextStyle.letterSpacing` 에 그대로 넣는다.',
    '  /// Figma: `1-2. Semantic/ Typography / letter-spacing/label-large`',
    '  static const double labelLargeEm = -0.01;',
    '  /// em — Figma 의 px 를 `font-size/label-large` (14) 로 나눈 값. `CoreTextStyle.letterSpacing` 에 그대로 넣는다.',
    '  /// Figma: `1-2. Semantic/ Typography / letter-spacing/label-large` (mode: Tablet)',
    '  static const double labelLargeEmTablet = -0.01;',
    '  /// em — Figma 의 px 를 `font-size/label-large` (16) 로 나눈 값. `CoreTextStyle.letterSpacing` 에 그대로 넣는다.',
    '  /// Figma: `1-2. Semantic/ Typography / letter-spacing/label-large` (mode: Desktop)',
    '  static const double labelLargeEmDesktop = -0.01;',
    '}',
    '',
  ].join('\n');
  check('the generated body matches the snapshot', body === expected, body);

  console.log(failures === 0 ? '\n✅ export-dart selftest passed' : `\n❌ ${failures} check(s) failed`);
  process.exit(failures > 0 ? 1 : 0);
}

main();
