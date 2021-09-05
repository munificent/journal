import 'package:source_span/source_span.dart';

class ErrorReporter {
  void report(SourceSpan span, String message) {
    print(span.message(message, color: true));
  }
}
