import '../category.dart';
import '../language.dart';
import 'shared.dart';

Language makeXmlLanguage() {
  const tagName = r'[a-zA-Z_:][a-zA-Z_0-9:\.-]*';

  var language = Language();

  language.regExp(r'[\s\n\t]', Category.whitespace);

  // Self-closing tag.
  language.regExp('<$s$tagName/>', Category.tag);

  // Closing tag.
  language.regExp('</$s$tagName$s>', Category.tag);

  // Open tag.
  language.regExp('<$s$tagName', Category.tag).push('tag');

  language.verbatim('<!--', Category.blockComment).push('comment');

  language.regExp('.', Category.text);

  language.ruleSet('comment', () {
    language.verbatim('-->', Category.blockComment).pop();
    language.regExp(r'.', Category.blockComment);
    language.verbatim('\n', Category.blockComment);
  });

  language.ruleSet('tag', () {
    language.regExp(r'/?>', Category.tag).pop();
    doubleQuotedString(language);
    language.capture('($tagName)$s(=)', [Category.field, Category.operator]);
    language.regExp('.', Category.text);
  });

  return language;
}
