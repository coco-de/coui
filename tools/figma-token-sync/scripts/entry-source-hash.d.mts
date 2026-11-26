export const kBundleEntry: string;
export const kBundleTarget: string;
export const kNonDrawingModules: Readonly<Record<string, string>>;
export const kPipelineRoots: readonly string[];
export const kPipelineGlue: readonly string[];

export interface MetafileLike {
  inputs: Record<
    string,
    { imports: { path: string; kind: string; external?: boolean; original?: string }[] }
  >;
}

export interface ModuleGraph {
  edges: Map<string, string[]>;
  opaque: Map<string, string>;
  modules: Set<string>;
}

export interface HashConfig {
  nonDrawing: Readonly<Record<string, string>>;
  pipelineRoots: readonly string[];
  pipelineGlue: readonly string[];
}

export type Closure = { files: Set<string>; why: null } | { files: null; why: string };

export function moduleGraph(metafile: MetafileLike): ModuleGraph;
export function closureOf(graph: ModuleGraph, roots: readonly string[], cuts: ReadonlySet<string>): Closure;
export function hashFiles(
  files: Iterable<string>,
  readFile: (path: string) => string | Uint8Array,
  toolchain: string,
): string;
export function registryKeyModules(registrySource: string): Map<string, string>;
export function checkDeclarations(graph: ModuleGraph, config?: HashConfig): string[];
export function defaultConfig(): HashConfig;

export interface EntrySourceHashes {
  hashes: Record<string, string>;
  unresolved: { key: string; why: string }[];
  filesByKey: Record<string, Set<string>>;
  keyModules: Map<string, string>;
  pipelineFiles: Set<string> | null;
}

export function entrySourceHashes(args: {
  graph: ModuleGraph;
  registrySource: string;
  readFile: (path: string) => string | Uint8Array;
  toolchain: string;
  config?: HashConfig;
}): EntrySourceHashes;

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function bundleGraph(esbuild: { build: (opts: any) => Promise<{ metafile?: any }> }, cwd?: string): Promise<MetafileLike>;
export function toolchainOf(esbuild: { version: string }): string;
