import 'language.dart';

/// Looks up a [Language] for a given name on a markdown code block.
///
/// By default, just delegates to [Language.find()], but users can implement or
/// extend this to do their own lookup and error reporting.
class LanguageProvider {
  const LanguageProvider();

  /// Find a [Language] that matches [name].
  ///
  /// If none is found and this returns `null`, then the code will not be
  /// syntax highlighted and no error is reported.
  Language? find(String name) => Language.find(name);
}
