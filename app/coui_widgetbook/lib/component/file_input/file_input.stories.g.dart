// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'file_input.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<FileIconDemo, StoryArgs<FileIconDemo>>;
typedef _Scenario = FileIconDemoScenario;
typedef _Defaults = FileIconDemoDefaults;
typedef _Story = FileIconDemoStory;
typedef _Args = FileIconDemoArgs;
final FileIconDemoComponent = Component<FileIconDemo, StoryArgs<FileIconDemo>>(
  name: kComponentMeta.name ?? 'FileIconDemo',
  path: kComponentMeta.path ?? 'component/file_input',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Demo host mapping a file extension to a file-type icon.''',
  stories: [
    $Default..$generatedName = 'Default',
    $Document..$generatedName = 'Document',
    $Spreadsheet..$generatedName = 'Spreadsheet',
    $Presentation..$generatedName = 'Presentation',
    $Archive..$generatedName = 'Archive',
    $Image..$generatedName = 'Image',
    $Audio..$generatedName = 'Audio',
    $Video..$generatedName = 'Video',
    $Unknown..$generatedName = 'Unknown',
  ],
);
typedef FileIconDemoScenario = Scenario<FileIconDemo, FileIconDemoArgs>;
typedef FileIconDemoDefaults = Defaults<FileIconDemo, FileIconDemoArgs>;

class FileIconDemoStory extends Story<FileIconDemo, FileIconDemoArgs> {
  FileIconDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    FileIconDemoArgs? args,
    StoryWidgetBuilder<FileIconDemo, FileIconDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? FileIconDemoArgs(),
         builder:
             builder ??
             (context, args) =>
                 FileIconDemo(key: args.key, extension: args.extension),
       );
}

class FileIconDemoArgs extends StoryArgs<FileIconDemo> {
  FileIconDemoArgs({Arg<Key?>? key, Arg<String>? extension})
    : this.keyArg = $initArg('key', key, null),
      this.extensionArg = $initArg('extension', extension, StringArg('pdf'))!;

  FileIconDemoArgs.fixed({Key? key, String extension = 'pdf'})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null),
      this.extensionArg = $initArg('extension', Arg.fixed(extension), null)!;

  final Arg<Key?>? keyArg;

  final Arg<String> extensionArg;

  Key? get key => keyArg?.value;

  String get extension => extensionArg.value;

  @override
  List<Arg?> get list => [keyArg, extensionArg];
}
