import 'dart:io';

void clearLine() {
  if (allowAnsi) {
    stdout.write('\u001b[2K\r');
  } else {
    print('');
  }
}

bool get allowAnsi =>
    !Platform.isWindows && stdioType(stdout) == StdioType.terminal;

final _cyan = _ansi('\u001b[36m');
final _green = _ansi('\u001b[32m');
final _magenta = _ansi('\u001b[35m');
final _red = _ansi('\u001b[31m');
final _yellow = _ansi('\u001b[33m');
final _gray = _ansi('\u001b[1;30m');
final _none = _ansi('\u001b[0m');

String cyan(Object message) => '$_cyan$message$_none';
String gray(Object message) => '$_gray$message$_none';
String green(Object message) => '$_green$message$_none';
String magenta(Object message) => '$_magenta$message$_none';
String red(Object message) => '$_red$message$_none';
String yellow(Object message) => '$_yellow$message$_none';

String _ansi(String special, [String fallback = '']) =>
    allowAnsi ? special : fallback;
