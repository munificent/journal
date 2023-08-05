import 'package:typographic_markdown/typographic_markdown.dart';
import 'package:chromatophore/markdown.dart';
import 'package:markdown/markdown.dart';

import 'code/finch.dart';
import 'code/jasic.dart';
import 'code/magpie.dart';
import 'code/vgs.dart';

final _languages = {
  'magpie1': makeMagpie1Language(),
  'magpie': makeMagpieLanguage(),
  'finch': makeFinchLanguage(),
  'jasic': makeJasicLanguage(),
  'vgs': makeVgsLanguage(),
};

String renderMarkdown(List<String> lines) {
  var document = Document(blockSyntaxes: [
    // TODO: Header syntax that adds anchor links.
    HighlightedCodeBlockSyntax(languages: _languages),
  ], inlineSyntaxes: [
    // Put inline Markdown code syntax before our smart quotes so that
    // quotes inside `code` spans don't get smartened.
    CodeSyntax(),
    ...allSyntaxes,
  ], extensionSet: ExtensionSet.gitHubFlavored);
  var ast = document.parseLines(lines);
  var html = HtmlRenderer().render(ast);

  // TODO: Temporary code to try to match the old site more precisely. Once
  // that's no longer needed, delete this.
  const tags = ['figure', 'h2', 'h3', 'ol', 'p', 'ul'];
  for (var tag in tags) {
    html = html.replaceAll('>\n<$tag>', '>\n\n<$tag>');
    html = html.replaceAll('><$tag>', '>\n\n<$tag>');
  }

  html = html.replaceAll('<li>\n\n<p>', '<li><p>');
  html = html.replaceAll('\n</li>', '</li>');

  html = html.replaceAll(
      '<div class="highlight">\n<pre>', '<div class="highlight"><pre>');
  html =
      html.replaceAll('</code></pre>\n</div>\n\n', '\n</code></pre></div>\n');
  html = html.replaceAll('</code></pre>\n</div>', '</code></pre></div>');
  html = html.replaceAll('</span></code></pre>', '</span>\n</code></pre>');

  html = html.replaceAll('</p>\n<blockquote>\n\n', '</p>\n\n<blockquote>\n');

  html = html.replaceAll(
      '</p><div class="update">\n\n<p>', '</p>\n\n<div class="update">\n<p>');

  html = html.replaceAll(
      '<div class="update">\n\n<p>', '<div class="update">\n<p>');

  // TODO: Other languages.
  const languages = ['c', 'cpp', 'csharp', 'fsharp', 'magpie', 'md', 'text'];
  for (var language in languages) {
    html = html.replaceAll(
        'data-lang="$language">', 'data-lang="$language"><span></span>');
  }

  return html;
}
