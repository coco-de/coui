# DotIndicator documentation previews

The documentation described vertical and read-only indicators, but its
Flutter and Web preview registries only supplied default and chain views. The
page now has `default`, `vertical`, and `passive` variants on both platforms,
plus the existing chain view. Each new view has a matching code snippet.

The vertical variant contains three interactive dots and the passive variant
contains three read-only dots. The stage is 88px high for vertical: the docs
preview overflow test found that a 72px stage clips under spacious density.
That test passes for 1024px and 1440px viewports over every CoreDensity. A
widget test verifies both variant configurations, visible fit and that selecting
a vertical dot changes the current index. Preview registry and docs API tests
also passed.

The actual release docs were inspected using Ego Lite on a local integration
of current CoUI main `deb49b5fe` with #5737, #5739, #5741, #5743 and this
change. Both Web and Flutter vertical previews rendered three markers and
selected the first when clicked; [screenshot](vertical-selected.png). The
Web passive preview exposed one `Item 2 of 3` group and zero tab controls.
The existing dark preview background difference between Web pane and opaque
Flutter embed is unrelated and remains outstanding. Physical VoiceOver and
TalkBack were not tested. No Figma file was changed.

This branch is based on #5741 for the vertical-spacing correction. The
read-only semantic behavior in the combined preview also depends on #5743,
which is a separate draft. It must be integrated and verified before claiming
the passive example's final accessibility behavior.
