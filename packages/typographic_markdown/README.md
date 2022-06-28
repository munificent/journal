# Typographic Markdown

Typographic Markdown is a simple library that defines a few [InlineSyntax]
classes for extending the [markdown] package. These produce typographically
correct punctuation characters automatically (according to some heuristics)
while letting you write plain ASCII. It's similar to the original [SmartyPants]
library by John Gruber.

[inlinesyntax]: https://pub.dev/documentation/markdown/latest/markdown/InlineSyntax-class.html
[markdown]: https://pub.dev/packages/markdown
[smartypants]: https://daringfireball.net/projects/smartypants/

The extensions are:

*   **ApostropheSyntax**: Converts plain "'" apostrophe characters to left
    (&lsquo;) and right (&rsquo;) characters as appropriate.

    The parser is as simple and stateless as possible. It only looks at the
    characters surrounding the apostrophe to decide what quote character to use,
    which means its heuristics aren't perfect. It leans towards assuming that
    apostrophes are more likely to be used for contractions than paired
    quotations. So it will do the wrong thing in:
   
        "He said '1 is the loneliest number.'"
   
    Here, it guesses that the `'1` is a numeric contraction and produces:
   
        “He said ’1 is the loneliest number.’”

*   **QuoteSyntax**: Converts plain '"' double quote characters to left
    (&ldquo;) and right (&rdquo;) characters as appropriate.

*   **EllipseSyntax**: Converts `...` to an ellipsis (&hellip;).

    A Unicode ellipsis character is not the ideal output if the goal is to
    visually match *The Chicago Manual of Style*. CMOS recommends full spaces
    between each dot (`. . .`), which is wider than the ellipsis character in
    most Unicode fonts. A future release of this package may remedy this
    grievous oversight.

*   **EmDashSyntax**: Converts ` -- `, a double hyphen with some kind of
    whitespace on either side to an em dash (&mdash;). This is different from
    SmartyPants, which uses a triple-dash for em dashes and double-dash for en
    dashes. I find en dashes are so rare that I would rather use ` -- ` for em
    dashes and write the HTML entity for en dashes explicitly.
