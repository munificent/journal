import 'dart:async';

import 'package:betwixt/betwixt.dart';
import 'package:typographic_markdown/typographic_markdown.dart';

import '../markdown.dart';

/// A parsed Markdown blog post.
class Post implements TemplateData {
  final DateTime date;

  final String title;

  late final String titleHtml = parseInline(title);

  /// The `<year>/<month>/<date>/<title>.html` URL for the post.
  String get url {
    var year = date.year.toString();
    var month = date.month.toString().padLeft(2, '0');
    var day = date.day.toString().padLeft(2, '0');
    return '$year/$month/$day/$titleUrl';
  }

  final String titleUrl;

  final List<String> tags;

  /// The Markdown contents of the post.
  final List<String> contents;

  /// The rendered HTML from the Markdown, initialized lazily.
  late final String html = renderMarkdown(contents);

  Post(this.date, this.title, this.titleUrl, this.tags, this.contents);

  @override
  FutureOr<Object?> lookup(String property) {
    return switch (property) {
      'content' => html,
      'date' => date,
      'tags' => tags,
      'title' => titleHtml,
      'titleUrl' => titleUrl,
      'url' => url,
      _ => throw Exception('Unknown post key $property.'),
    };
  }
}
