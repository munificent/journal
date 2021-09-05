import 'dart:async';

import 'src/ast.dart';
import 'src/betwixt_function.dart';
import 'src/compiler.dart';
import 'src/error_reporter.dart';
import 'src/renderer.dart';

export 'src/betwixt_function.dart';
export 'src/data.dart';

typedef IncludeLoader = Future<String?> Function(String name);

/// A compiled template.
class Template {
  /// Compiles the template from [source] at [url] (which is used only for
  /// error reporting).
  ///
  /// During compilation, all included templates will be resolved and inserted.
  /// Once this returns, no other include processing is needed.
  static Future<Template?> compile(String source, String url,
      {IncludeLoader? loader,
      BetwixtFunction? Function(String name)? functionBinder,
      ErrorReporter? reporter}) async {
    reporter ??= ErrorReporter();

    var compiler = Compiler(loader, functionBinder, reporter);
    var code = await compiler.compile(source, url);
    if (code == null) return null;

    return Template._(code);
  }

  final Stmt _code;

  Template._(this._code);

  /// Renders this template using the given [data].
  ///
  /// Any render-time errors are reported using [reporter]. If omitted, errors
  /// are printed to stdout.
  Future<String> render(Object? data, {ErrorReporter? reporter}) async {
    reporter ??= ErrorReporter();

    var renderer = Renderer(data, reporter);
    await _code.accept(renderer);
    return renderer.output;
  }
}
