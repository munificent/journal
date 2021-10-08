import 'package:charcode/ascii.dart';
import 'package:charcode/charcode.dart';
import 'package:markdown/markdown.dart';

/// All extensions provided by this package.
final List<InlineSyntax> allSyntaxes = [
  EmDashSyntax(),
  EllipseSyntax(),
  ApostropheSyntax(),
  QuoteSyntax(),
];

final _document = Document(
    inlineSyntaxes: allSyntaxes, extensionSet: ExtensionSet.gitHubFlavored);

String parseInline(String input) {
  var ast = _document.parseInline(input);
  return HtmlRenderer().render(ast);
}

/// Converts `...` to an ellipsis (&hellip;).
///
/// A Unicode ellipsis character is not the ideal output if the goal is to
/// visually match *The Chicago Manual of Style*. CMOS recommends full spaces
/// between each dot (`. . .`), which is wider than the ellipsis character in
/// most Unicode fonts. A future release of this package may remedy this
/// grievous oversight.
class EllipseSyntax extends InlineSyntax {
  EllipseSyntax() : super(r"\.\.\.", startCharacter: $dot);

  @override
  bool onMatch(InlineParser parser, Match match) {
    parser.addNode(Text('&hellip;'));
    return true;
  }
}

/// Converts ` -- `, a double hyphen with some kind of whitespace on either
/// side to an em dash (&mdash;). This is different from SmartyPants, which
/// uses a triple-dash for em dashes and double-dash for en dashes. I find en
/// dashes are so rare that I would rather use ` -- ` for em dashes and write
/// the HTML entity for en dashes.
class EmDashSyntax extends InlineSyntax {
  EmDashSyntax() : super(r"\s--\s");

  @override
  bool onMatch(InlineParser parser, Match match) {
    parser.addNode(Text('&mdash;'));
    return true;
  }
}

/// Converts plain "'" apostrophe characters to left (&lsquo;) and right
/// (&rsquo;) characters as appropriate.
///
/// The parser is as simple and stateless as possible. It only looks at the
/// characters surrounding the apostrophe to decide what quote character to use,
/// which means its heuristics aren't perfect. It leans towards assuming that
/// apostrophes are more likely to be used for contractions than paired
/// quotations. So it will do the wrong thing in:
///
///     "He said '1 is the loneliest number.'"
///
/// Here, it guesses that the `'1` is a numeric contraction and produces:
///
///     “He said ’1 is the loneliest number.’”
class ApostropheSyntax extends InlineSyntax {
  ApostropheSyntax() : super(r"'", startCharacter: $apostrophe);

  @override
  bool onMatch(InlineParser parser, Match match) {
    parser.addNode(Text(_quote(parser)));
    return true;
  }

  String _quote(InlineParser parser) {
    var before = -1;
    if (parser.pos > 0) {
      before = parser.charAt(parser.pos - 1);
    }
    var after = -1;
    if (parser.pos < parser.source!.length - 1) {
      after = parser.charAt(parser.pos + 1);
    }

    // See if it should be a right quote.
    if (before >= $a && before <= $z) return '&rsquo;';
    if (before >= $A && before <= $Z) return '&rsquo;';
    if (before >= $0 && before <= $9) return '&rsquo;';
    if (before == $dot) return '&rsquo;';
    if (before == $question) return '&rsquo;';
    if (before == $exclamation) return '&rsquo;';
    if (before == $backquote) return '&rsquo;';

    if (after == $space) return '&rsquo;';
    if (after == $colon) return '&rsquo;';
    if (after == $comma) return '&rsquo;';
    if (after == $dot) return '&rsquo;';

    // Years like "the '60s".
    if (before == $space && after >= $0 && after <= $9) return '&rsquo;';

    // Contraction.
    if (after == $s) return '&rsquo;';

    // See if it should be a left quote.
    if (after >= $a && after <= $z) return '&lsquo;';
    if (after >= $A && after <= $Z) return '&lsquo;';
    if (after >= $0 && after <= $9) return '&lsquo;';

    if (before == $space) return '&lsquo;';
    if (before == $lf) return '&lsquo;';
    if (before == -1) return '&lsquo;';

    // Handle HTML tags. Kind of hacky because we don't want to have to scan
    // all the way back to see if the preceding tag is a closing or opening
    // tag.

    var afterNext = -1;
    if (parser.pos < parser.source!.length - 2) {
      afterNext = parser.charAt(parser.pos + 2);
    }

    if (after == $lessThan && afterNext == $slash) return '&rsquo;';
    if (before == $greaterThan) return '&rsquo;';

    // If we got here, we couldn't decide, so leave it alone.
    return "'";
  }
}

/// Converts plain '"' double quote characters to left (&ldquo;) and right
/// (&rdquo;) characters as appropriate.
class QuoteSyntax extends InlineSyntax {
  QuoteSyntax() : super(r'"', startCharacter: $double_quote);

  @override
  bool onMatch(InlineParser parser, Match match) {
    parser.addNode(Text(_quote(parser)));
    return true;
  }

  String _quote(InlineParser parser) {
    var before = -1;
    if (parser.pos > 0) {
      before = parser.charAt(parser.pos - 1);
    }
    var after = -1;
    if (parser.pos < parser.source!.length - 1) {
      after = parser.charAt(parser.pos + 1);
    }

    // See if it should be a right quote.
    if (before >= $a && before <= $z) return '&rdquo;';
    if (before >= $A && before <= $Z) return '&rdquo;';
    if (before >= $0 && before <= $9) return '&rdquo;';
    if (before == $dot) return '&rdquo;';
    if (before == $question) return '&rdquo;';
    if (before == $exclamation) return '&rdquo;';
    if (before == $backquote) return '&rdquo;';

    if (after == $space) return '&rdquo;';
    if (after == $colon) return '&rdquo;';
    if (after == $comma) return '&rdquo;';
    if (after == $dot) return '&rdquo;';

    // See if it should be a left quote.
    if (after >= $a && after <= $z) return '&ldquo;';
    if (after >= $A && after <= $Z) return '&ldquo;';
    if (after >= $0 && after <= $9) return '&ldquo;';

    if (before == $space) return '&ldquo;';
    if (before == $lf) return '&ldquo;';
    if (before == -1) return '&ldquo;';

    // Handle HTML tags.
    var afterNext = -1;
    if (parser.pos < parser.source!.length - 2) {
      afterNext = parser.charAt(parser.pos + 2);
    }

    if (after == $lessThan && afterNext == $slash) return '&rdquo;';
    if (before == $greaterThan) return '&rdquo;';

    // If we got here, we couldn't decide, so leave it alone.
    return '"';
  }
}
