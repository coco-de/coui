// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'chat.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<ChatBubble, StoryArgs<ChatBubble>>;
typedef _Scenario = ChatBubbleScenario;
typedef _Defaults = ChatBubbleDefaults;
typedef _Story = ChatBubbleStory;
typedef _Args = ChatBubbleInputArgs;
final ChatBubbleComponent = Component<ChatBubble, StoryArgs<ChatBubble>>(
  name: kComponentMeta.name ?? 'ChatBubble',
  path: kComponentMeta.path ?? 'component/chat',
  docsBuilder: kComponentMeta.docsBuilder,
  docComment: r'''Unified speech-bubble component used by [Chat] / [ChatGroup].

surface:behind — whatever the message column sits over (a chat
screen's scrolling body). It draws its own box rather than composing
`OutlinedContainer` — its concave tail path is cut against the same
fill, a shape the container has no slot for (#4358) — so the marker
is restated here directly.

surface:content — a face in the content layer alongside the messages
around it, not a floating affordance: no sticky, fixed, or overlay
mount on either platform.''',
  stories: [
    $Default..$generatedName = 'Default',
    $EndAligned..$generatedName = 'EndAligned',
  ],
);
typedef ChatBubbleScenario = Scenario<ChatBubble, ChatBubbleInputArgs>;
typedef ChatBubbleDefaults = Defaults<ChatBubble, ChatBubbleInputArgs>;

class ChatBubbleStory extends Story<ChatBubble, ChatBubbleInputArgs> {
  ChatBubbleStory({
    super.name,
    super.designLink,
    SetupBuilder<ChatBubble, ChatBubbleInputArgs>? setup,
    super.modes,
    ChatBubbleInputArgs? args,
    StoryWidgetBuilder<ChatBubble, ChatBubbleInputArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         args: args ?? ChatBubbleInputArgs(),
         builder: builder ?? defaults.builder!,
         setup: setup ?? defaults.setup!,
       );
}

class ChatBubbleInputArgs extends StoryArgs<ChatBubble> {
  ChatBubbleInputArgs({
    Arg<String>? text,
    Arg<CoreChatBubbleVariant>? variant,
    Arg<CoreChatAlignment>? alignment,
    Arg<bool>? tail,
  }) : this.textArg = $initArg('text', text, StringArg('Hello! How are you?'))!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CoreChatBubbleVariant>(
           CoreChatBubbleVariant.neutral,
           values: CoreChatBubbleVariant.values,
         ),
       )!,
       this.alignmentArg = $initArg(
         'alignment',
         alignment,
         EnumArg<CoreChatAlignment>(
           CoreChatAlignment.start,
           values: CoreChatAlignment.values,
         ),
       )!,
       this.tailArg = $initArg(
         'tail',
         tail,
         BoolArg(CoreChatBubbleContract.defaultTail),
       )!;

  ChatBubbleInputArgs.fixed({
    String text = 'Hello! How are you?',
    CoreChatBubbleVariant variant = CoreChatBubbleVariant.neutral,
    CoreChatAlignment alignment = CoreChatAlignment.start,
    bool tail = CoreChatBubbleContract.defaultTail,
  }) : this.textArg = $initArg('text', Arg.fixed(text), null)!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.alignmentArg = $initArg('alignment', Arg.fixed(alignment), null)!,
       this.tailArg = $initArg('tail', Arg.fixed(tail), null)!;

  final Arg<String> textArg;

  final Arg<CoreChatBubbleVariant> variantArg;

  final Arg<CoreChatAlignment> alignmentArg;

  final Arg<bool> tailArg;

  String get text => textArg.value;

  CoreChatBubbleVariant get variant => variantArg.value;

  CoreChatAlignment get alignment => alignmentArg.value;

  bool get tail => tailArg.value;

  @override
  List<Arg?> get list => [textArg, variantArg, alignmentArg, tailArg];
}
