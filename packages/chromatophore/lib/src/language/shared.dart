import '../../chromatophore.dart';

/// Common regex patterns in languages.

// TODO: Hack. Require an all caps name to be longer than two letters so that
// "VM" (a type name) isn't treated as a constant.
const allCaps = r'\b[A-Z][A-Z0-9_]{2,}\b';
const identifier = r'\b[a-zA-Z_][a-zA-Z0-9_]*\b';
const capsIdentifier = r'\b[A-Z]+(?:[a-z][a-zA-Z0-9_]*)?\b';
const dottedIdentifier = '$identifier(\\.$identifier)*';

/// Word boundary.
const b = '\\b';

/// Zero or more whitespace characters.
const s = '\\s*';

/// One or more whitespace characters.
const ss = '\\s+';

/// Defines rules for C-style double-quoted strings and string escapes.
void doubleQuotedString(Language language) {
  language.regExp(r'"', Category.string).push('double string');

  language.ruleSet('double string', () {
    language.regExp('"', Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    language.regExp('.', Category.string);
  });
}

/// Defines rules for JavaScript-style single-quoted strings and string escapes.
void singleQuotedString(Language language) {
  language.regExp("'", Category.string).push('single string');

  language.ruleSet('single string', () {
    language.regExp("'", Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    language.regExp('.', Category.string);
  });
}

/// Defines rules for Python-style single-quoted raw string.
void singleQuotedRawString(Language language) {
  language.regExp("r'", Category.string).push('single raw string');

  language.ruleSet('single raw string', () {
    language.regExp("'", Category.string).pop();
    language.regExp('.', Category.string);
  });
}

/// Defines rules for Python-style double-quoted raw string.
void doubleQuotedRawString(Language language) {
  language.regExp(r'r"', Category.string).push('double raw string');

  language.ruleSet('double raw string', () {
    language.regExp('"', Category.string).pop();
    language.regExp('.', Category.string);
  });
}

void cStyleComments(Language language) {
  language.ruleSet('block comment', () {
    language.verbatim(r'/*', Category.blockComment).push('in block comment');
  });

  language.ruleSet('in block comment', () {
    language.verbatim(r'*/', Category.blockComment).pop();
    language.regExp(r'.', Category.blockComment);
    language.verbatim('\n', Category.blockComment);
  });

  language.ruleSet('comment', () {
    language.regExp(r'//.*', Category.lineComment);
    language.include('block comment');
  });

  language.include('comment');
}

void cPreprocessor(Language language) {
  language.regExp('#', Category.preprocessor).push('preprocessor');

  language.ruleSet('preprocessor', () {
    language.regExp(r'//.*', Category.lineComment).pop();
    language.include('block comment');
    language.verbatim('\\\n', Category.preprocessor);
    language.regExp('.', Category.preprocessor);
    language.verbatim('\n', Category.text).pop();
  });
}
