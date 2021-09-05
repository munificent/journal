import '../betwixt.dart';
import 'ast.dart';
import 'parser.dart';
import 'wrapping_error_reporter.dart';

/// Walks the AST looking for includes to load.
class IncludeVisitor implements StmtVisitor<Future<void>> {
  final Map<String, Stmt> _templates = {};
  final WrappingErrorReporter _reporter;
  final IncludeLoader? _loader;

  IncludeVisitor(this._reporter, this._loader);

  Future<Map<String, Stmt>> traverse(Stmt stmt) async {
    await stmt.accept(this);
    return _templates;
  }

  @override
  Future<void> visitErrorStmt(ErrorStmt stmt) async {}

  @override
  Future<void> visitForStmt(ForStmt stmt) async {
    await stmt.body.accept(this);
    await stmt.between?.accept(this);
    await stmt.elseStatement?.accept(this);
  }

  @override
  Future<void> visitIfStmt(IfStmt stmt) async {
    await stmt.thenStatement.accept(this);
    await stmt.elseStatement?.accept(this);
  }

  @override
  Future<void> visitIncludeStmt(IncludeStmt stmt) async {
    var name = stmt.name.text;

    // Only load shared includes once and don't get stuck in cycles.
    if (_templates.containsKey(name)) return;

    var loader = _loader;
    if (loader != null) {
      var includeSource = await loader(name);
      if (includeSource == null) {
        _reporter.report(stmt.name.span, 'Could not load include.');
      } else {
        var include =
            Parser.parseSource(_reporter, includeSource, '$name.html');
        _templates[name] = include;

        // Recurse into the include.
        await include.accept(this);
      }
    } else {
      _reporter.report(
          stmt.name.span, 'Cannot process includes without a loader.');
    }
  }

  @override
  Future<void> visitLetStmt(LetStmt stmt) async {}

  @override
  Future<void> visitRenderStmt(RenderStmt stmt) async {}

  @override
  Future<void> visitSequenceStmt(SequenceStmt stmt) async {
    for (var statement in stmt.statements) {
      await statement.accept(this);
    }
  }

  @override
  Future<void> visitSetStmt(SetStmt stmt) async {}

  @override
  Future<void> visitTextStmt(TextStmt stmt) async {}
}
