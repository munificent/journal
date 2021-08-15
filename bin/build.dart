import 'dart:async';

import 'package:minibuild/build_server.dart';

import 'package:journal/src/builder/post_builder.dart';
import 'package:journal/src/builder/post_page_builder.dart';
import 'package:journal/src/builder/post_thread_builder.dart';
import 'package:journal/src/builder/sass_builder.dart';
import 'package:journal/src/builder/static_file_builder.dart';
import 'package:journal/src/builder/tag_builder.dart';
import 'package:journal/src/builder/tag_page_builder.dart';
import 'package:journal/src/builder/tag_set_builder.dart';
import 'package:journal/src/builder/template_builder.dart';
import 'package:journal/src/builder/template_page_builder.dart';

Future<void> main(List<String> arguments) async {
  var server = BuildServer(sourceDirectories: [
    'asset',
    'site'
  ], builders: [
    StaticFileBuilder(),
    SassBuilder(),
    PostBuilder(),
    PostThreadBuilder(),
    TagBuilder(),
    TagSetBuilder(),
    TemplateBuilder(),
    TemplatePageBuilder(),
    PostPageBuilder(),
    TagPageBuilder()
  ]);
  await server.initialize();

  if (arguments.contains('--serve')) await server.serve();
}
