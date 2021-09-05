import 'package:betwixt/src/error_reporter.dart';
import 'package:betwixt/src/parser.dart';
import 'package:betwixt/src/pretty_printer.dart';
import 'package:betwixt/src/scanner.dart';
import 'package:betwixt/src/string_extension.dart';
import 'package:betwixt/src/token.dart';
import 'package:betwixt/src/whitespace_simplifier.dart';

const source = '''
{{ for a in first }}{{ for b in second }} {{ a }}-{{ b }}{{ end }}{{ end }}
''';

void main() {
  print('-- source --');
  print('    123456789012345678901234567890');
  var lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    print('${(i + 1).toString().padLeft(2)}: ${lines[i]}');
  }

  var reporter = ErrorReporter();
  var tokens = Scanner(source, 'test.html', reporter).scan();
  print('-- scanner --');
  _printTokens(tokens);

  tokens = WhitespaceSimplifier(tokens).simplify();
  print('-- simplify --');
  _printTokens(tokens);

  var statement = Parser(tokens, reporter).parse();
  var pretty = PrettyPrinter.print(statement);
  print('-- parser --');
  print(pretty);
}

void _printTokens(List<Token> tokens) {
  for (var i = 0; i < tokens.length; i++) {
    var token = tokens[i];
    var start = token.span.start;
    var closeTag = '';
    if (token.closeTag != -1) closeTag = '-> ${token.closeTag}';

    print('${i.toString().padLeft(3)} '
        'line ${(start.line + 1).toString().padLeft(2)} '
        'col ${(start.column + 1).toString().padLeft(2)}-'
        '${(start.column + 1 + token.span.length).toString().padLeft(2)}: '
        '${token.type.name.padRight(10)} "${token.text.toStringLiteral()}"'
        ' $closeTag');
  }
}
