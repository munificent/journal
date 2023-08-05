import '../../chromatophore.dart';
import 'shared.dart';

Language makeCSharpLanguage() {
  var language = Language();

  language.include('comment');

  language.regExp(r'[0-9]+\.[0-9]+f?', Category.number);
  language.regExp(r'0x[0-9a-fA-F]+', Category.number);
  language.regExp(r'[0-9]+?', Category.number);

  // Contextual keywords.
  language.regExp(r'\byield break\b', Category.keyword);
  language.regExp(r'\byield return\b', Category.keyword);

  language.capture('$b(class|enum|interface|struct)($ss)($identifier)',
      [Category.keyword, Category.whitespace, Category.typeName]).push('class');

  // Heuristic: A capitalized identifier followed by "<" is probably a generic
  // type, but not if precededed by ".".
  language.capture('(\\.)($capsIdentifier)(<)', [
    Category.punctuation,
    Category.identifier,
    Category.operator
  ]).push('generic');
  language.capture('($capsIdentifier)(<)',
      [Category.typeName, Category.operator]).push('generic');

  // Keywords that must have a type following.
  language.capture('$b(as|is|new)($ss)($identifier)(<)', [
    Category.keyword,
    Category.whitespace,
    Category.typeName,
    Category.operator
  ]).push('generic');
  language.capture('$b(as|is|new)($ss)($identifier)',
      [Category.keyword, Category.whitespace, Category.typeName]);

  // Cast expressions.
  language.capture('(\\()($capsIdentifier)(\\))',
      [Category.punctuation, Category.typeName, Category.punctuation]);

  language.capture('$b(where)($ss)($identifier)',
      [Category.keyword, Category.whitespace, Category.typeName]).push('where');

  // Heuristic: Assume a capitalized identifier followed by another is a
  // variable declaration.
  language.capture('$b($capsIdentifier\\??)($ss)($identifier)(<)', [
    Category.typeName,
    Category.whitespace,
    Category.identifier,
    Category.operator
  ]).push('generic');
  language.capture('$b($capsIdentifier\\??)($ss)($identifier)',
      [Category.typeName, Category.whitespace, Category.identifier]);

  // Heuristic: Assume a capitalized identifier followed by "[]" is a type name
  // for an array type.
  language.capture('$b($capsIdentifier\\??)((?:\\[\\])+)',
      [Category.typeName, Category.punctuation]);

  // Nullable lowercase primitive types.
  language.regExp(
      r'\b(bool|char|decimal|double|float|s?byte|u?int|u?long|u?short)\?',
      Category.typeName);

  language.keywords(
      Category.typeName,
      'bool byte char decimal double float int long object sbyte short string '
      'uint ulong ushort');

  language.keywords(
      Category.keyword,
      'abstract as base break case catch checked class const continue default '
      'delegate do else enum event explicit extern false finally fixed for '
      'foreach get goto if implicit in interface internal is lock namespace '
      'new null operator out override params private protected public readonly '
      'ref return sealed set sizeof stackalloc static struct switch this throw '
      'true try typeof unchecked unsafe using var virtual volatile where while '
      'void');

  language.regExp(identifier, Category.identifier);

  // Attributes. To try to distinguish these from index operators, require it
  // to have nothing before it on the line, or to look like it's before a
  // parameter in a parameter list.
  language.capture('^($s)(\\[)($dottedIdentifier)',
      [Category.whitespace, Category.punctuation, Category.annotation]);
  // Heuristic: Assume a "[" after a "(", ",", or "]" is an attribute in a
  // parameter list or following another attribute.
  language.capture('([,(\\]])($s)(\\[)($dottedIdentifier)', [
    Category.punctuation,
    Category.whitespace,
    Category.punctuation,
    Category.annotation
  ]);
  // TODO: This only captures the first attribute name in an attribute clause:
  //
  //     [One, Two]
  //      ^^^
  // Ideally, it should find all of them in the list.

  language.regExp(r'[{}()[\].,:;]', Category.punctuation);
  language.regExp(r'[!?*/&%~+=<>|-]', Category.operator);

  // Preprocessor directives: #region, #endregion, etc.
  language.regExp('#', Category.preprocessor).push('preprocessor');

  // TODO: Multi-character escapes?
  language.regExp(r"'\\?.'", Category.character);

  doubleQuotedString(language);

  language.include('space');

  language.ruleSet('class', () {
    language.verbatim('<', Category.operator).push('generic');
    language.verbatim(':', Category.punctuation).pop().push('supertypes');
    language.verbatim('{', Category.punctuation).pop();
    language.include('whitespace');

    // TODO: Hack to support proposed syntax in
    // 2008/04/10/a-c-feature-request-extension-classes.
    language.verbatim('this', Category.keyword);
    language.regExp('\\b$capsIdentifier\\b', Category.typeName);
  });

  cStyleComments(language);

  // Generic type.
  language.ruleSet('generic', () {
    // Nested generic.
    language.capture('($identifier)(<)',
        [Category.typeName, Category.operator]).push('generic');

    language.regExp('>', Category.operator).pop();
    language.regExp(identifier, Category.typeName);
    language.regExp(r'[,\[\]]', Category.punctuation);
    language.include('whitespace');
  });

  language.ruleSet('preprocessor', () {
    language.regExp(r'//.*', Category.lineComment).pop();
    language.include('block comment');
    language.regExp('.', Category.preprocessor);
    language.verbatim('\n', Category.text).pop();
  });

  language.ruleSet('space', () {
    language.regExp(r'[\s\n\t]', Category.whitespace);
  });

  language.ruleSet('supertypes', () {
    language.regExp(identifier, Category.typeName);
    language.verbatim(',', Category.punctuation);
    language.verbatim('<', Category.operator).push('generic');
    language.verbatim('{', Category.punctuation).pop();
    language.include('whitespace');
  });

  language.ruleSet('where', () {
    language.regExp(identifier, Category.typeName);
    language.verbatim('<', Category.operator).push('generic');
    language.verbatim(',', Category.punctuation);
    language.verbatim(':', Category.punctuation);
    language.verbatim('{', Category.punctuation).pop();
    language.include('whitespace');
  });

  language.ruleSet('whitespace', () {
    language.include('comment');
    language.include('space');
  });

  return language;
}
