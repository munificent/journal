import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:betwixt/src/error_reporter.dart';
import 'package:path/path.dart' as p;
import 'package:source_span/src/span.dart';
import 'package:test/test.dart';

import 'package:betwixt/betwixt.dart';

final _sectionRegExp = RegExp(r'^--- (.*)');

final _testFunctions = {
  'noArgs': BetwixtFunction((args) => 'no args', 0, 0),
  'oneArg': BetwixtFunction((args) => 'one arg(${args[0]})', 1, 1),
  'threeArgs': BetwixtFunction(
      (args) => 'three args(${args[0]}, ${args[1]}, ${args[2]})', 3, 3),
  'asynchronous': BetwixtFunction((args) => Future.value('later'), 0, 0),
  'testDate':
      BetwixtFunction((args) => DateTime(123, 4, 5, 6, 7, 8, 9, 10), 0, 0),
};

Future<void> main() async {
  // TODO: Hack. Assumes working directory is package root.
  var testCases = Directory('test/cases')
      .listSync(recursive: true)
      .whereType<File>()
      .where((entry) => entry.path.endsWith('.txt'))
      .toList();
  testCases.sort((a, b) => a.path.compareTo(b.path));

  for (var entry in testCases) {
    var description =
        p.relative(p.withoutExtension(entry.path), from: 'test/cases');
    test(description, () async {
      // Not using readAsLinesSync() because that discards a trailing newline.
      var testCase = _TestCase.parse(entry.readAsStringSync());
      await testCase.run();
    });
  }
}

class _TestCase {
  factory _TestCase.parse(String source) {
    const allSections = {
      'compile errors',
      'data',
      'output',
      'runtime errors',
      'template'
    };

    var lines = source.split('\n');
    var section = 'template';
    var sections = {'template': StringBuffer()};

    for (var line in lines) {
      var match = _sectionRegExp.firstMatch(line);
      if (match != null) {
        section = match[1]!.trim();
        if (section.startsWith('include ') || allSections.contains(section)) {
          sections[section] = StringBuffer();
        } else {
          fail('Invalid test section "$section".');
        }
      } else {
        var buffer = sections[section]!;
        if (buffer.isNotEmpty) buffer.writeln();
        buffer.write(line);
      }
    }

    var data = <String, dynamic>{};
    if (sections.containsKey('data')) {
      data = jsonDecode(sections['data']!.toString());
    }

    var includes = {
      for (var entry in sections.entries)
        if (entry.key.startsWith('include '))
          entry.key.substring('include '.length).trim(): entry.value.toString()
    };

    return _TestCase(
        sections['template']!.toString(),
        sections['output']?.toString(),
        sections['compile errors']?.toString(),
        sections['runtime errors']?.toString(),
        includes,
        data);
  }

  final String templateString;
  final String? expectedOutput;
  final String? expectedCompileErrors;
  final String? expectedRuntimeErrors;
  final Map<String, String> includes;
  final Map<String, dynamic> data;

  _TestCase(
      this.templateString,
      this.expectedOutput,
      this.expectedCompileErrors,
      this.expectedRuntimeErrors,
      this.includes,
      this.data);

  Future<void> run() async {
    var reporter = _CollectingErrorReporter();
    var template = await Template.compile(templateString, 'test',
        loader: _loadInclude,
        functionBinder: _bindFunction,
        reporter: reporter);

    if (expectedCompileErrors != null) {
      expect(reporter._buffer.toString(), expectedCompileErrors);
      expect(template, isNull,
          reason: 'Should not return template when expecting compile errors.');
    } else {
      expect(reporter._buffer.toString(), isEmpty,
          reason: 'Unexpected compile errors:\n${reporter._buffer}');
      expect(template, isNotNull,
          reason: 'Should return template when not expecting compile errors.');

      var output = await template!.render(data, reporter: reporter);
      if (expectedRuntimeErrors != null) {
        expect(reporter._buffer.toString(), expectedRuntimeErrors);
      } else {
        expect(reporter._buffer.toString(), isEmpty,
            reason: 'Unexpected runtime errors:\n${reporter._buffer}');
        expect(output, expectedOutput);
      }
    }
  }

  Future<String> _loadInclude(String name) async {
    var include = includes[name];
    if (include == null) fail('Test does not define include "$name".');
    return include;
  }

  BetwixtFunction? _bindFunction(String name) => _testFunctions[name];
}

class _CollectingErrorReporter implements ErrorReporter {
  final _buffer = StringBuffer();

  @override
  void report(SourceSpan span, String message) {
    if (_buffer.isNotEmpty) _buffer.writeln();
    _buffer.write(span.message(message, color: false));
  }
}
