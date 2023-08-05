import 'dart:async';

import 'package:betwixt/betwixt.dart';
import 'package:test/test.dart';

import 'utils.dart';

final _errorPattern = RegExp(r'line 1, column 4 of test: (.*)');

void main() {
  group('Map', () {
    var map = {
      'present': 'value',
      'nil': null,
      'future': Future.value('later'),
      'unknown': TemplateData.unknownProperty
    };

    _testProperty(map, 'present', 'value');
    _testProperty(map, 'nil', 'null');
    _testProperty(map, 'future', 'later');

    _testPropertyError(map, 'absent', 'Map does not have key "absent".');
    _testPropertyError(map, 'unknown', 'Unknown property "unknown" in map.');

    // Getter on Dart map object.
    _testPropertyError(map, 'length', 'Map does not have key "length".');
  });

  group('TemplateData', () {
    var data = _TestTemplateData();

    _testProperty(data, 'present', 'value');
    _testProperty(data, 'nil', 'null');
    _testProperty(data, 'future', 'later');

    _testPropertyError(
        data, 'absent', 'Unknown property "absent" on _TestTemplateData.');
    _testPropertyError(
        data, 'throw', 'Exception accessing "throw" on _TestTemplateData:');

    // Getter on Dart object.
    _testPropertyError(
        data, 'getter', 'Unknown property "getter" on _TestTemplateData.');
  });

  group('Asynchronous accessor function', () {
    Future<Object?> lookup(String property) async {
      if (property == 'present') return 'value';
      if (property == 'nil') return null;
      if (property == 'throw') throw Exception('boom!');
      return TemplateData.unknownProperty;
    }

    _testProperty(lookup, 'present', 'value');
    _testProperty(lookup, 'nil', 'null');

    _testPropertyError(
        lookup, 'absent', 'Unknown property "absent" from accessor function.');
    _testPropertyError(
        lookup, 'throw', 'Exception accessing "throw" from accessor function:');

    // Getter on Dart function object.
    _testPropertyError(lookup, 'runtimeType',
        'Unknown property "runtimeType" from accessor function.');
  });

  group('Synchronous accessor function', () {
    Object? lookup(String property) {
      if (property == 'present') return 'value';
      if (property == 'nil') return null;
      if (property == 'throw') throw Exception('boom!');
      return TemplateData.unknownProperty;
    }

    _testProperty(lookup, 'present', 'value');
    _testProperty(lookup, 'nil', 'null');

    _testPropertyError(
        lookup, 'absent', 'Unknown property "absent" from accessor function.');
    _testPropertyError(
        lookup, 'throw', 'Exception accessing "throw" from accessor function:');

    // Getter on Dart function object.
    _testPropertyError(lookup, 'runtimeType',
        'Unknown property "runtimeType" from accessor function.');
  });

  group('DateTime', () {
    var date = DateTime(123, 4, 5, 6, 7, 8, 9, 10);
    _testProperty(date, 'year', '123');
    _testProperty(date, 'month', '4');
    _testProperty(date, 'day', '5');
    _testProperty(date, 'hour', '6');
    _testProperty(date, 'minute', '7');
    _testProperty(date, 'second', '8');
    _testProperty(date, 'millisecond', '9');
    _testProperty(date, 'microsecond', '10');
    _testProperty(date, 'weekday', '1');

    _testPropertyError(date, 'wat', 'Unknown property "wat" on DateTime.');
  });

  group('String', () {
    var string = 'string';
    _testProperty(string, 'length', '6');

    _testPropertyError(string, 'wat', 'Unknown property "wat" on String.');
  });
}

class _TestTemplateData implements TemplateData {
  String get getter => 'getter';

  @override
  FutureOr<Object?> lookup(String property) {
    return switch (property) {
      'present' => 'value',
      'nil' => null,
      'future' => Future.value('later'),
      'throw' => throw Exception('boom!'),
      _ => TemplateData.unknownProperty,
    };
  }
}

void _testProperty(Object? object, String property, String expected) {
  test('property "$property" should be "$expected"', () async {
    var reporter = TestErrorReporter();
    var template =
        await Template.compile('{{ $property }}', 'test', reporter: reporter);
    expect(reporter.reportedErrors, isEmpty);
    expect(template, isNotNull);

    var result = await template!.render(object, reporter: reporter);
    expect(reporter.reportedErrors, isEmpty);

    expect(result, expected);
  });
}

void _testPropertyError(Object? object, String property, String expectedError) {
  test('property "$property" should return error "$expectedError"', () async {
    var reporter = TestErrorReporter();
    var template =
        await Template.compile('{{ $property }}', 'test', reporter: reporter);
    expect(reporter.reportedErrors, isEmpty);
    expect(template, isNotNull);

    var result = await template!.render(object, reporter: reporter);
    expect(reporter.reportedErrors, isNotEmpty,
        reason: 'Should report runtime error.');
    var match = _errorPattern.firstMatch(reporter.reportedErrors);
    expect(match, isNotNull, reason: 'Runtime error should match pattern.');
    expect(match![1], expectedError);
    expect(result, 'null');
  });
}
