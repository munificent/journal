import 'dart:convert';

import 'package:intl/intl.dart';

import '../betwixt.dart';

final _functions = {
  'escape': BetwixtFunction(_escape, 1, 1),
  'escape_xml': BetwixtFunction(_escapeElement, 1, 1),
  'format_date': BetwixtFunction(_formatDate, 2, 2),
  'take': BetwixtFunction(_take, 2, 2)
};

BetwixtFunction? findFunction(String name) => _functions[name];

Object? _escape(List<Object?> arguments) {
  return const HtmlEscape().convert(arguments[0].toString());
}

Object? _escapeElement(List<Object?> arguments) {
  return const HtmlEscape(HtmlEscapeMode(
          name: 'xml', escapeLtGt: true, escapeQuot: true, escapeApos: true))
      .convert(arguments[0].toString());
}

Object? _take(List<Object?> arguments) {
  // TODO: Handle type errors.
  var iterable = arguments[0] as Iterable<Object?>;
  var count = arguments[1] as int;
  return iterable.take(count);
}

Object? _formatDate(List<Object?> arguments) {
  var format = DateFormat(arguments[1].toString());
  // TODO: Support other locales.
  // TODO: Handle type errors better.
  return format.format(arguments[0] as DateTime);
}
