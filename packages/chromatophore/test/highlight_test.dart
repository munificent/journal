import 'dart:io';

import 'package:chromatophore/src/token.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:chromatophore/chromatophore.dart';

const _languageExtensions = {
  'c': 'c',
  'cpp': 'cpp',
  'csharp': 'cs',
  'go': 'go',
  'java': 'java',
  'lisp': 'lisp',
  'ocaml': 'ml',
  'python': 'py',
  'ruby': 'rb',
  'smalltalk': 'st',
  'xml': 'xml',
};

void main() {
  // TODO: Hack. Assumes working directory is package root.
  var expectionFiles = Directory('test/language')
      .listSync(recursive: true)
      .whereType<File>()
      .where((entry) => entry.path.endsWith('.expect'))
      .toList();
  expectionFiles.sort((a, b) => a.path.compareTo(b.path));

  for (var expectionFile in expectionFiles) {
    var expectationPath = expectionFile.path;
    var languageName = p.basenameWithoutExtension(expectationPath);
    test(languageName, () async {
      var extension = _languageExtensions[languageName];
      var inputPath = '${p.withoutExtension(expectationPath)}.$extension';
      var input = File(inputPath).readAsStringSync();
      var expectation = expectionFile.readAsStringSync();

      var language = Language.find(languageName);
      if (language == null) fail('Unknown language "$languageName".');
      var result = highlight(language, input, _TestFormatter());
      expect(result, expectation);
    });
  }
}

class _TestFormatter implements Formatter {
  static const _abbreviations = {
    Category.comment: 'c',
    Category.lineComment: 'lc',
    Category.blockComment: 'bc',
    Category.literal: 'l',
    Category.number: 'n',
    Category.identifier: 'i',
    Category.keyword: 'k',
    Category.typeName: 't',
    Category.field: 'f',
    Category.preprocessor: 'r',
    Category.string: 's',
    Category.character: 'sc',
    Category.stringEscape: 'e',
    Category.annotation: 'a',
    Category.punctuation: 'p',
    Category.operator: 'o',
    Category.tag: 'g',
    Category.text: '',
    Category.whitespace: '',
    Category.unrecognized: '?',
  };

  @override
  String format(Iterable<Token> tokens) {
    var buffer = StringBuffer();

    for (var token in tokens) {
      var tag = _abbreviations[token.category];
      if (tag == null) fail('Unexpected category ${token.category}.');

      if (tag.isNotEmpty) buffer.write('‹$tag⋮');
      buffer.write(token.text);
      if (tag.isNotEmpty) buffer.write('›');
    }

    return buffer.toString();
  }
}
