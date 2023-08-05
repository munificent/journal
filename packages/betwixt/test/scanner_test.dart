import 'dart:math';

import 'package:test/test.dart';

import 'package:betwixt/src/scanner.dart';
import 'package:betwixt/src/token.dart';

import 'utils.dart';

void main() {
  _testScanner('empty string', '', []);

  _testScanner('expected characters', '&@# {{ &@# }} %^&', [
    [TokenType.text, '&@# '],
    [TokenType.openTag, '{{'],
    [TokenType.closeTag, '}}'],
    [TokenType.text, ' %^&'],
  ], '''
      line 1, column 8 of test.html: Unexpected character.
        ╷
      1 │ &@# {{ &@# }} %^&
        │        ^
        ╵
      line 1, column 9 of test.html: Unexpected character.
        ╷
      1 │ &@# {{ &@# }} %^&
        │         ^
        ╵
      line 1, column 10 of test.html: Unexpected character.
        ╷
      1 │ &@# {{ &@# }} %^&
        │          ^
        ╵
      ''');

  _testScanner('all text', '  this is { just }} text ', [
    [TokenType.indent, '  '],
    [TokenType.text, 'this is { just }} text '],
  ]);

  _testScanner('all code', '{{all code}}', [
    [TokenType.openTag, '{{'],
    [TokenType.identifier, 'all'],
    [TokenType.identifier, 'code'],
    [TokenType.closeTag, '}}'],
  ]);

  _testScanner('text and code', 'a{{b}}c{{d}}e{{f}}g', [
    [TokenType.text, 'a'],
    [TokenType.openTag, '{{'],
    [TokenType.identifier, 'b'],
    [TokenType.closeTag, '}}'],
    [TokenType.text, 'c'],
    [TokenType.openTag, '{{'],
    [TokenType.identifier, 'd'],
    [TokenType.closeTag, '}}'],
    [TokenType.text, 'e'],
    [TokenType.openTag, '{{'],
    [TokenType.identifier, 'f'],
    [TokenType.closeTag, '}}'],
    [TokenType.text, 'g'],
  ]);

  group('whitespace', () {
    _testScanner('indent on first line', '  {{ a }}', [
      [TokenType.indent, '  '],
      [TokenType.openTag, '{{'],
      [TokenType.identifier, 'a'],
      [TokenType.closeTag, '}}'],
    ]);

    _testScanner('preserved in text', '  a\n b \t\r  c  \r\t ', [
      [TokenType.indent, '  '],
      [TokenType.text, 'a'],
      [TokenType.newline, '\n'],
      [TokenType.indent, ' '],
      [TokenType.text, 'b \t\r  c  \r\t '],
    ]);

    _testScanner('ignored in code', '{{  a\n b \t\r  c  \r\t }}', [
      [TokenType.openTag, '{{'],
      [TokenType.identifier, 'a'],
      [TokenType.identifier, 'b'],
      [TokenType.identifier, 'c'],
      [TokenType.closeTag, '}}'],
    ]);

    _testScanner('kept before {{', 'a  {{ b }}\nc', [
      [TokenType.text, 'a  '],
      [TokenType.openTag, '{{'],
      [TokenType.identifier, 'b'],
      [TokenType.closeTag, '}}'],
      [TokenType.newline, '\n'],
      [TokenType.text, 'c'],
    ]);

    _testScanner('kept after }}', 'a\n {{ b }}  c', [
      [TokenType.text, 'a'],
      [TokenType.newline, '\n'],
      [TokenType.indent, ' '],
      [TokenType.openTag, '{{'],
      [TokenType.identifier, 'b'],
      [TokenType.closeTag, '}}'],
      [TokenType.text, '  c'],
    ]);
  });

  _testScanner('punctuation', '{{ . , ( ) }}', [
    [TokenType.openTag, '{{'],
    [TokenType.dot, '.'],
    [TokenType.comma, ','],
    [TokenType.leftParen, '('],
    [TokenType.rightParen, ')'],
    [TokenType.closeTag, '}}'],
  ]);

  _testScanner('keywords',
      '{{ and between else end for if in include let or set with }}', [
    [TokenType.openTag, '{{'],
    [TokenType.andKeyword, 'and'],
    [TokenType.betweenKeyword, 'between'],
    [TokenType.elseKeyword, 'else'],
    [TokenType.endKeyword, 'end'],
    [TokenType.forKeyword, 'for'],
    [TokenType.ifKeyword, 'if'],
    [TokenType.inKeyword, 'in'],
    [TokenType.includeKeyword, 'include'],
    [TokenType.letKeyword, 'let'],
    [TokenType.orKeyword, 'or'],
    [TokenType.setKeyword, 'set'],
    [TokenType.withKeyword, 'with'],
    [TokenType.closeTag, '}}'],
  ]);

  _testScanner('identifiers', '{{ a bCDefG___123jshe }}', [
    [TokenType.openTag, '{{'],
    [TokenType.identifier, 'a'],
    [TokenType.identifier, 'bCDefG___123jshe'],
    [TokenType.closeTag, '}}'],
  ]);
  // TODO: Digits at beginning of identifier.

  _testScanner('string literals', '{{ "" "some string" }}', [
    [TokenType.openTag, '{{'],
    [TokenType.string, ''],
    [TokenType.string, 'some string'],
    [TokenType.closeTag, '}}'],
  ]);

  _testScanner('tag in string', '{{ " {{ string }} " }}', [
    [TokenType.openTag, '{{'],
    [TokenType.string, ' {{ string }} '],
    [TokenType.closeTag, '}}'],
  ]);
  // TODO: String escapes.
}

void _testScanner(
    String description, String source, List<List<Object>> expectedTokens,
    [String expectedErrors = '']) {
  test(description, () {
    var reporter = TestErrorReporter();
    var tokens = Scanner(source, 'test.html', reporter).scan();

    expect(reporter.reportedErrors, stripIndent(expectedErrors));

    for (var i = 0; i < min(tokens.length, expectedTokens.length); i++) {
      var type = expectedTokens[i][0] as TokenType;
      expect(tokens[i].type, type,
          reason: 'Expected type ${type.name} at $i but was '
              '${tokens[i].type.name}');

      var text = expectedTokens[i][1] as String;
      expect(tokens[i].text, text,
          reason: 'Expected text "$text" at $i but was "${tokens[i].text}"');
    }

    if (expectedTokens.length > tokens.length) {
      var missing = expectedTokens.sublist(tokens.length);
      fail('Missing expected tokens ${missing.join(', ')}.');
    } else if (tokens.length > expectedTokens.length) {
      var unexpected = tokens.sublist(expectedTokens.length);
      fail('Unexpected tokens ${unexpected.join(', ')}.');
    }
  });
}
