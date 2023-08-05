import 'package:source_span/source_span.dart';

import 'package:betwixt/src/error_reporter.dart';

class TestErrorReporter implements ErrorReporter {
  final StringBuffer _buffer = StringBuffer();

  String get reportedErrors => _buffer.toString();

  @override
  void report(SourceSpan span, String message) {
    _buffer.writeln(span.message(message));
  }
}

String stripIndent(String string) {
  var lines = string.split('\n');
  var indentation = lines[0].length - lines[0].trimLeft().length;
  return lines.map((line) => line.substring(indentation)).join('\n');
}
