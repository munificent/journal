import 'dart:async';

import 'package:betwixt/betwixt.dart';

import '../markdown.dart';

/// A parsed Markdown blog post.
class Post implements TemplateData {
  final DateTime date;

  final String title;

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
  String? _html;

  Post(this.date, this.title, this.titleUrl, this.tags, this.contents);

  @override
  FutureOr<Object?> lookup(String property) {
    switch (property) {
      case 'content':
        return _html ??= renderMarkdown(contents);
      case 'date':
        return date;
      case 'tags':
        return tags;
      case 'title':
        return title;
      case 'titleUrl':
        return titleUrl;
      case 'url':
        return url;
      default:
        throw Exception('Unknown post key $property.');
    }
  }
}
