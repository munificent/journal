import 'package:betwixt/betwixt.dart';
import 'package:minibuild/minibuild.dart';

import '../model/tag_set.dart';
import '../model/template_data.dart';

// TODO: Something more data-driven? How about a tag map asset file?
const _customTagTitles = {
  "ai": "AI",
  "blog": "This Blog",
  "book": "Books",
  "c-sharp": "C#",
  "code": "Coding",
  "cpp": "C++",
  "f-sharp": "F#",
  "game-dev": "Game Development",
  "js": "JavaScript",
  "language": "Programming Languages",
  "oop": "OOP",
  "oscon": "OSCON",
  "personal": "Myself",
  "procedural-generation": "Procedural Generation",
  "roguelike": "Roguelikes",
  "typescript": "TypeScript",
};

/// Generates the HTML page for a single tag.
class TagPageBuilder extends Builder<Tag> {
  @override
  Future<void> build(BuildContext context, Key key, Tag tag) async {
    var template =
        context.input<Template>(Key('betwixt/asset/template/tag.html'));

    var tagName = _customTagTitles[tag.name];
    // If there's no custom name, default to title-casing the tag.
    tagName ??= tag.name
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    var title = 'Stuff I Wrote About $tagName';

    // TODO: Pass in error reporter that plumbs through build system.
    var html = await template.render((String property) =>
        templateData(context, property, tag: tag, tagTitle: title));

    // TODO: Also output at "tag" path. (Keep "category" for backwards
    // compatibility.)
    var pageKey = Key.join('build', 'category', key.basename, 'index.html');
    context.output(pageKey, html);
  }
}
