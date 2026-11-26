// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'chat_group.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ChatGroupDemo, StoryArgs<ChatGroupDemo>>;
typedef _Scenario = ChatGroupDemoScenario;
typedef _Defaults = ChatGroupDemoDefaults;
typedef _Story = ChatGroupDemoStory;
typedef _Args = ChatGroupDemoArgs;
final ChatGroupDemoComponent =
    Component<ChatGroupDemo, StoryArgs<ChatGroupDemo>>(
      name: kComponentMeta.name ?? 'ChatGroupDemo',
      path: kComponentMeta.path ?? 'component/chat',
      docsBuilder: kComponentMeta.docsBuilder,
      docComment: r'''Conversation demo host for [ChatGroup] stories.

Renders two chat groups — an incoming (start-aligned) group and
an outgoing (end-aligned) group — like a real conversation.''',
      stories: [$Conversation..$generatedName = 'Conversation'],
    );
typedef ChatGroupDemoScenario = Scenario<ChatGroupDemo, ChatGroupDemoArgs>;
typedef ChatGroupDemoDefaults = Defaults<ChatGroupDemo, ChatGroupDemoArgs>;

class ChatGroupDemoStory extends Story<ChatGroupDemo, ChatGroupDemoArgs> {
  ChatGroupDemoStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    ChatGroupDemoArgs? args,
    StoryWidgetBuilder<ChatGroupDemo, ChatGroupDemoArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ChatGroupDemoArgs(),
         builder: builder ?? (context, args) => ChatGroupDemo(key: args.key),
       );
}

class ChatGroupDemoArgs extends StoryArgs<ChatGroupDemo> {
  ChatGroupDemoArgs({Arg<Key?>? key})
    : this.keyArg = $initArg('key', key, null);

  ChatGroupDemoArgs.fixed({Key? key})
    : this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null);

  final Arg<Key?>? keyArg;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [keyArg];
}
