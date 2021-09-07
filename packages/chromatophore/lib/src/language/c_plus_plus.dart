import '../category.dart';
import '../language.dart';
import 'patterns.dart';

Language makeCPlusPlusLanguage() {
  var language = Language();

  language.regExp(r'[0-9]+\.[0-9]+f?', Category.number);
  language.regExp(r'0x[0-9a-fA-F]+', Category.number);
  language.regExp(r'[0-9]+[Lu]?', Category.number);

  language.include('whitespace');

  // ALL_CAPS preprocessor macro use.
  language.regExp(allCaps, Category.preprocessor);

  // Capitalized type name.
  language.regExp(capsIdentifier, Category.typeName);

  // TODO: Make false and true a different category?
  language.keywords(
      Category.keyword,
      'alignas alignof and and_eq asm atomic_cancel atomic_commit '
      'atomic_noexcept auto bitand bitor bool break case catch class compl '
      'concept const consteval constexpr constinit const_cast continue '
      'co_await co_return co_yield decltype default delete do dynamic_cast '
      'else enum explicit export extern false for friend goto if inline '
      'mutable namespace new noexcept not not_eq nullptr operator or or_eq '
      'private protected public reflexpr register reinterpret_cast requires '
      'return sizeof static static_assert static_cast struct switch '
      'synchronized template this thread_local throw true try typedef typeid '
      'typename union using virtual volatile while xor xor_eq');
  language.keywords(
      Category.typeName,
      'char char8_t char16_t char32_t double float int long short signed '
      'unsigned void wchar_t');

  language.regExp(identifier, Category.identifier);

  // TODO: Multi-character escapes?
  language.regExp(r"'\\?.'", Category.character);

  language.regExp(r'"', Category.string).push('string');

  language.regExp('#', Category.preprocessor).push('preprocessor');

  language.regExp(r'[{}()[\].,;!*/&%~+=<>|-]', Category.punctuation);

  language.ruleSet('block comment', () {
    language.regExp(r'/\*.*?\*/', Category.blockComment);
  });

  language.ruleSet('comment', () {
    language.regExp(r'//.*', Category.lineComment);
    language.include('block comment');
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

  language.ruleSet('string', () {
    language.regExp('"', Category.string).pop();
    language.regExp(r'\\.', Category.stringEscape);
    language.regExp('.', Category.string);
  });

  language.ruleSet('whitespace', () {
    language.include('comment');
    language.include('space');
  });

  return language;
}
