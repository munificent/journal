import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';

import 'src/asset.dart';
import 'src/key.dart';

/// Asset backed by a lazily-read file.
///
/// The file's contents will be read once the first time [readBytes] or
/// [readString] is called. When the contents of the file on disk have changed,
/// create a new [FileAsset] and update the asset in the [Graph].
class FileAsset implements BinaryAsset, StringAsset {
  /// Make sure we don't try to read too many files at the same time.
  static final Pool _pool = Pool(64);

  final File _file;

  /// The cached contents of the asset.
  List<int>? _contents;

  String? _stringContents;

  FileAsset(this._file);

  Key get path => Key(p.toUri(_file.path).path);

  @override
  Future<List<int>> readBytes() async {
    var contents = _contents;
    if (contents != null) return contents;

    return _pool.withResource(() async {
      return _contents = await _file.readAsBytes();
    });
  }

  @override
  Future<String> readString() async {
    var string = _stringContents;
    if (string != null) return string;

    _stringContents = string = utf8.decode(await readBytes());
    return string;
  }
}
