import 'package:source_span/source_span.dart';

import 'error_reporter.dart';

class WrappingErrorReporter implements ErrorReporter {
  bool hadError = false;
  final ErrorReporter inner;

  WrappingErrorReporter(this.inner);

  @override
  void report(SourceSpan span, String message) {
    hadError = true;
    inner.report(span, message);
  }
}
