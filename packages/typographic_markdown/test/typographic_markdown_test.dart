import 'package:markdown/markdown.dart';
import 'package:test/test.dart';

import 'package:typographic_markdown/typographic_markdown.dart';

void main() {
  group(EllipseSyntax, () {
    testMarkdown('a..b', 'a..b');
    testMarkdown('a...b', 'a&hellip;b');
    testMarkdown('a....b', 'a&hellip;.b');
    testMarkdown('a... b', 'a&hellip; b');
    testMarkdown('...', '&hellip;');
    testMarkdown('a\n...', 'a\n&hellip;');
    testMarkdown('a...\n', 'a&hellip;');
  });

  group(EmDashSyntax, () {
    testMarkdown('a -- b', 'a&mdash;b');
    testMarkdown('a\n-- b', 'a&mdash;b');
    testMarkdown('a --\nb', 'a&mdash;b');
    testMarkdown('a--b', 'a--b');
  });

  group(ApostropheSyntax, () {
    group('letters and whitespace', () {
      testMarkdown("a 'chars' b", "a &lsquo;chars&rsquo; b");
      testMarkdown("a 'CAPS' b", "a &lsquo;CAPS&rsquo; b");
      testMarkdown("'ends'", "&lsquo;ends&rsquo;");
      testMarkdown("\n'line'\n", "&lsquo;line&rsquo;");
    });

    group('contractions', () {
      testMarkdown("the '80s", "the &rsquo;80s");
      testMarkdown("<b>a</b>'s", "<b>a</b>&rsquo;s");
      testMarkdown("C++'s", "C++&rsquo;s");
      testMarkdown("`code`'s", "<code>code</code>&rsquo;s");
    });

    group('punctuation', () {
      testMarkdown("a 'b.' c", "a &lsquo;b.&rsquo; c");
      testMarkdown("a 'b!' c", "a &lsquo;b!&rsquo; c");
      testMarkdown("a 'b?' c", "a &lsquo;b?&rsquo; c");
      testMarkdown("a 'b,' c", "a &lsquo;b,&rsquo; c");
      testMarkdown("a 'b;' c", "a &lsquo;b;&rsquo; c");
      testMarkdown("a 'b:' c", "a &lsquo;b:&rsquo; c");

      testMarkdown("a 'b'. c", "a &lsquo;b&rsquo;. c");
      testMarkdown("a 'b'! c", "a &lsquo;b&rsquo;! c");
      testMarkdown("a 'b'? c", "a &lsquo;b&rsquo;? c");
      testMarkdown("a 'b', c", "a &lsquo;b&rsquo;, c");
      testMarkdown("a 'b'; c", "a &lsquo;b&rsquo;; c");
      testMarkdown("a 'b': c", "a &lsquo;b&rsquo;: c");

      testMarkdown("a '@#%' c", "a &lsquo;@#%&rsquo; c");
      testMarkdown("a 'b'&mdash;c", "a &lsquo;b&rsquo;&mdash;c");
    });

    group('markdown', () {
      testMarkdown("a '*b*' c", "a &lsquo;<em>b</em>&rsquo; c");
      testMarkdown("a *'b'* c", "a <em>&lsquo;b&rsquo;</em> c");
      testMarkdown("a '_b_' c", "a &lsquo;<em>b</em>&rsquo; c");
      testMarkdown("a _'b'_ c", "a <em>&lsquo;b&rsquo;</em> c");
      testMarkdown("a '`b`' c", "a &lsquo;<code>b</code>&rsquo; c");
      testMarkdown("a `'b'` c", "a <code>'b'</code> c");
    });

    group('tags', () {
      testMarkdown("a '<b>b</b>' c", "a &lsquo;<b>b</b>&rsquo; c");
      testMarkdown("a <b>'b'</b> c", "a <b>&lsquo;b&rsquo;</b> c");

      testMarkdown("a '<b>b</b>'. c", "a &lsquo;<b>b</b>&rsquo;. c");
      testMarkdown("a <b>'b.'</b> c", "a <b>&lsquo;b.&rsquo;</b> c");
    });
  });

  group(QuoteSyntax, () {
    group('letters and whitespace', () {
      testMarkdown('a "chars" b', 'a &ldquo;chars&rdquo; b');
      testMarkdown('a "CAPS" b', 'a &ldquo;CAPS&rdquo; b');
      testMarkdown('"ends"', '&ldquo;ends&rdquo;');
      testMarkdown('\n"line"\n', '&ldquo;line&rdquo;');
    });

    group('punctuation', () {
      testMarkdown('a "b." c', 'a &ldquo;b.&rdquo; c');
      testMarkdown('a "b!" c', 'a &ldquo;b!&rdquo; c');
      testMarkdown('a "b?" c', 'a &ldquo;b?&rdquo; c');
      testMarkdown('a "b," c', 'a &ldquo;b,&rdquo; c');
      testMarkdown('a "b;" c', 'a &ldquo;b;&rdquo; c');
      testMarkdown('a "b:" c', 'a &ldquo;b:&rdquo; c');

      testMarkdown('a "b". c', 'a &ldquo;b&rdquo;. c');
      testMarkdown('a "b"! c', 'a &ldquo;b&rdquo;! c');
      testMarkdown('a "b"? c', 'a &ldquo;b&rdquo;? c');
      testMarkdown('a "b", c', 'a &ldquo;b&rdquo;, c');
      testMarkdown('a "b"; c', 'a &ldquo;b&rdquo;; c');
      testMarkdown('a "b": c', 'a &ldquo;b&rdquo;: c');

      testMarkdown('a "@#%" c', 'a &ldquo;@#%&rdquo; c');
      testMarkdown('a "b"&mdash;c', 'a &ldquo;b&rdquo;&mdash;c');
    });

    group('markdown', () {
      testMarkdown('a "*b*" c', 'a &ldquo;<em>b</em>&rdquo; c');
      testMarkdown('a *"b"* c', 'a <em>&ldquo;b&rdquo;</em> c');
      testMarkdown('a "_b_" c', 'a &ldquo;<em>b</em>&rdquo; c');
      testMarkdown('a _"b"_ c', 'a <em>&ldquo;b&rdquo;</em> c');
      testMarkdown('a "`b`" c', 'a &ldquo;<code>b</code>&rdquo; c');
      testMarkdown('a `"b"` c', 'a <code>"b"</code> c');
    });

    group('tags', () {
      testMarkdown('a "<b>b</b>" c', 'a &ldquo;<b>b</b>&rdquo; c');
      testMarkdown('a <b>"b"</b> c', 'a <b>&ldquo;b&rdquo;</b> c');

      testMarkdown('a "<b>b</b>". c', 'a &ldquo;<b>b</b>&rdquo;. c');
      testMarkdown('a <b>"b."</b> c', 'a <b>&ldquo;b.&rdquo;</b> c');
    });
  });
}

void testMarkdown(String markdown, String html) {
  test("'" + markdown.replaceAll('\n', '\\n') + "'", () {
    var document = Document(
        inlineSyntaxes: allSyntaxes, extensionSet: ExtensionSet.gitHubFlavored);
    var ast = document.parseLines(markdown.split('\n'));
    var result = HtmlRenderer().render(ast);
    expect(result, startsWith('<p>'));
    expect(result, endsWith('</p>'));
    result = result.substring(3, result.length - 4);
    expect(result, html);
  });
}
