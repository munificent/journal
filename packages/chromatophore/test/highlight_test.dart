import 'dart:io';

import 'package:chromatophore/src/token.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:chromatophore/chromatophore.dart';

const _languageExtensions = {
  'c': 'c',
  'csharp': 'cs',
  'python': 'py',
  'ruby': 'rb'
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
    Category.decimalNumber: 'nd',
    Category.hexInteger: 'nh',
    Category.integer: 'ni',
    Category.identifier: 'i',
    Category.keyword: 'k',
    Category.typeName: 't',
    Category.field: 'f',
    Category.preprocessor: 'r',
    Category.constant: 'v',
    Category.boolean: 'kb',
    Category.string: 's',
    Category.character: 'sc',
    Category.stringEscape: 'se',
    Category.annotation: 'a',
    Category.punctuation: 'p',
    Category.operator: 'o',
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