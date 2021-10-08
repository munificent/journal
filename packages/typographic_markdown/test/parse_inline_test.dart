import 'package:test/test.dart';

import 'package:typographic_markdown/typographic_markdown.dart';

void main() {
  group(EllipseSyntax, () {
    testParseInline('a..b', 'a..b');
    testParseInline('a...b', 'a&hellip;b');
    testParseInline('a....b', 'a&hellip;.b');
    testParseInline('a... b', 'a&hellip; b');
    testParseInline('...', '&hellip;');
  });

  group(EmDashSyntax, () {
    testParseInline('a -- b', 'a&mdash;b');
    testParseInline('a--b', 'a--b');
  });

  group(ApostropheSyntax, () {
    group('letters and whitespace', () {
      testParseInline("a 'chars' b", "a &lsquo;chars&rsquo; b");
      testParseInline("a 'CAPS' b", "a &lsquo;CAPS&rsquo; b");
      testParseInline("'ends'", "&lsquo;ends&rsquo;");
    });

    group('contractions', () {
      testParseInline("the '80s", "the &rsquo;80s");
      testParseInline("<b>a</b>'s", "<b>a</b>&rsquo;s");
      testParseInline("C++'s", "C++&rsquo;s");
      testParseInline("`code`'s", "<code>code</code>&rsquo;s");
    });

    group('punctuation', () {
      testParseInline("a 'b.' c", "a &lsquo;b.&rsquo; c");
      testParseInline("a 'b!' c", "a &lsquo;b!&rsquo; c");
      testParseInline("a 'b?' c", "a &lsquo;b?&rsquo; c");
      testParseInline("a 'b,' c", "a &lsquo;b,&rsquo; c");
      testParseInline("a 'b;' c", "a &lsquo;b;&rsquo; c");
      testParseInline("a 'b:' c", "a &lsquo;b:&rsquo; c");

      testParseInline("a 'b'. c", "a &lsquo;b&rsquo;. c");
      testParseInline("a 'b'! c", "a &lsquo;b&rsquo;! c");
      testParseInline("a 'b'? c", "a &lsquo;b&rsquo;? c");
      testParseInline("a 'b', c", "a &lsquo;b&rsquo;, c");
      testParseInline("a 'b'; c", "a &lsquo;b&rsquo;; c");
      testParseInline("a 'b': c", "a &lsquo;b&rsquo;: c");

      testParseInline("a '@#%' c", "a &lsquo;@#%&rsquo; c");
      testParseInline("a 'b'&mdash;c", "a &lsquo;b&rsquo;&mdash;c");
    });

    group('markdown', () {
      testParseInline("a '*b*' c", "a &lsquo;<em>b</em>&rsquo; c");
      testParseInline("a *'b'* c", "a <em>&lsquo;b&rsquo;</em> c");
      testParseInline("a '_b_' c", "a &lsquo;<em>b</em>&rsquo; c");
      testParseInline("a _'b'_ c", "a <em>&lsquo;b&rsquo;</em> c");
      testParseInline("a '`b`' c", "a &lsquo;<code>b</code>&rsquo; c");
      testParseInline("a `'b'` c", "a <code>'b'</code> c");
    });

    group('tags', () {
      testParseInline("a '<b>b</b>' c", "a &lsquo;<b>b</b>&rsquo; c");
      testParseInline("a <b>'b'</b> c", "a <b>&lsquo;b&rsquo;</b> c");

      testParseInline("a '<b>b</b>'. c", "a &lsquo;<b>b</b>&rsquo;. c");
      testParseInline("a <b>'b.'</b> c", "a <b>&lsquo;b.&rsquo;</b> c");
    });
  });

  group(QuoteSyntax, () {
    group('letters and whitespace', () {
      testParseInline('a "chars" b', 'a &ldquo;chars&rdquo; b');
      testParseInline('a "CAPS" b', 'a &ldquo;CAPS&rdquo; b');
      testParseInline('"ends"', '&ldquo;ends&rdquo;');
    });

    group('punctuation', () {
      testParseInline('a "b." c', 'a &ldquo;b.&rdquo; c');
      testParseInline('a "b!" c', 'a &ldquo;b!&rdquo; c');
      testParseInline('a "b?" c', 'a &ldquo;b?&rdquo; c');
      testParseInline('a "b," c', 'a &ldquo;b,&rdquo; c');
      testParseInline('a "b;" c', 'a &ldquo;b;&rdquo; c');
      testParseInline('a "b:" c', 'a &ldquo;b:&rdquo; c');

      testParseInline('a "b". c', 'a &ldquo;b&rdquo;. c');
      testParseInline('a "b"! c', 'a &ldquo;b&rdquo;! c');
      testParseInline('a "b"? c', 'a &ldquo;b&rdquo;? c');
      testParseInline('a "b", c', 'a &ldquo;b&rdquo;, c');
      testParseInline('a "b"; c', 'a &ldquo;b&rdquo;; c');
      testParseInline('a "b": c', 'a &ldquo;b&rdquo;: c');

      testParseInline('a "@#%" c', 'a &ldquo;@#%&rdquo; c');
      testParseInline('a "b"&mdash;c', 'a &ldquo;b&rdquo;&mdash;c');
    });

    group('markdown', () {
      testParseInline('a "*b*" c', 'a &ldquo;<em>b</em>&rdquo; c');
      testParseInline('a *"b"* c', 'a <em>&ldquo;b&rdquo;</em> c');
      testParseInline('a "_b_" c', 'a &ldquo;<em>b</em>&rdquo; c');
      testParseInline('a _"b"_ c', 'a <em>&ldquo;b&rdquo;</em> c');
      testParseInline('a "`b`" c', 'a &ldquo;<code>b</code>&rdquo; c');
      testParseInline('a `"b"` c', 'a <code>"b"</code> c');
    });

    group('tags', () {
      testParseInline('a "<b>b</b>" c', 'a &ldquo;<b>b</b>&rdquo; c');
      testParseInline('a <b>"b"</b> c', 'a <b>&ldquo;b&rdquo;</b> c');

      testParseInline('a "<b>b</b>". c', 'a &ldquo;<b>b</b>&rdquo;. c');
      testParseInline('a <b>"b."</b> c', 'a <b>&ldquo;b.&rdquo;</b> c');
    });
  });
}

void testParseInline(String input, String expected) {
  test("'" + input.replaceAll('\n', '\\n') + "'", () {
    var output = parseInline(input);
    expect(output, expected);
  });
}
