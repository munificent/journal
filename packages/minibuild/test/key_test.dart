import 'package:test/test.dart';

import 'package:minibuild/minibuild.dart';

void main() {
  test('join', () {
    expect(Key.join('one/two', Key('three/four')), Key('one/two/three/four'));
    expect(Key.join(1, 'two', true, Key('key')), Key('1/two/true/key'));
    expect(Key.join('a', 'b', null, 'c'), Key('a/b/c'));

    expect(Key.join('a/', 'b'), Key('a/b'));
    expect(Key.join('a', '/b'), Key('/b'));
    expect(Key.join('a\\b', 'c'), Key('a\\b/c'));
  });

  test('basename', () {
    expect(Key('dir/sub/path.txt').basename, 'path.txt');
    expect(Key('dir/sub').basename, 'sub');
    expect(Key('dir/sub/').basename, 'sub');
    expect(Key('path.txt').basename, 'path.txt');
  });

  test('basenameWithoutExtension', () {
    expect(Key('dir/sub/path.txt').basenameWithoutExtension, 'path');
    expect(Key('dir/sub').basenameWithoutExtension, 'sub');
    expect(Key('dir/sub/').basenameWithoutExtension, 'sub');
    expect(Key('path.').basenameWithoutExtension, 'path');
    expect(Key('.dotfile').basenameWithoutExtension, '.dotfile');
    expect(Key('path.foo.bar').basenameWithoutExtension, 'path.foo');
  });

  test('extension', () {
    expect(Key('dir/sub/path.txt').extension, '.txt');
    expect(Key('path.txt').extension, '.txt');
    expect(Key('.dotfile').extension, '');
    expect(Key('path.foo.bar').extension, '.bar');
  });

  test('isWithin()', () {
    expect(Key('dir/sub/file').isWithin('dir'), isTrue);
    expect(Key('dir/sub/file').isWithin('dir/sub'), isTrue);
    expect(Key('dir/sub/file').isWithin('dir/sub/file'), isFalse);
    expect(Key('dir/sub/file').isWithin('dir/sub/no'), isFalse);
    expect(Key('dir/sub/file').isWithin('dir/no/file'), isFalse);
    expect(Key('dir/sub/file').isWithin('no/dir/sub'), isFalse);
  });

  test('relativeTo()', () {
    expect(Key('dir/sub/file').relativeTo(''), Key('dir/sub/file'));
    expect(Key('dir/sub/file').relativeTo('dir'), Key('sub/file'));
    expect(Key('dir/sub/file').relativeTo('dir/sub'), Key('file'));
    expect(Key('dir/sub/file').relativeTo('dir/sub/file'), Key('.'));
    expect(Key('dir/sub/file').relativeTo('unr/elated'),
        Key('../../dir/sub/file'));
  });

  test('changeExtension()', () {
    expect(Key('dir/sub/path.txt').changeExtension('bin'),
        Key('dir/sub/path.bin'));
    expect(Key('path.txt').changeExtension(''), Key('path.'));
    expect(Key('.dotfile').changeExtension('out'), Key('.dotfile.out'));
    expect(Key('path.foo.bar').changeExtension('new'), Key('path.foo.new'));
  });

  test('basenameWithExtension()', () {
    expect(
        Key('dir/sub/path.txt').basenameWithExtension('bin'), Key('path.bin'));
    expect(Key('a/path.txt').basenameWithExtension(''), Key('path.'));
    expect(
        Key('dir/.dotfile').basenameWithExtension('out'), Key('.dotfile.out'));
    expect(Key('dir/path.foo.bar').basenameWithExtension('new'),
        Key('path.foo.new'));
  });

  test('hasExtension()', () {
    expect(Key('dir/sub/path.txt').hasExtension('txt'), isTrue);
    expect(Key('dir/sub/path.txt').hasExtension('bin'), isFalse);

    expect(Key('path.txt').hasExtension('txt'), isTrue);
    expect(Key('path.txt').hasExtension('bin'), isFalse);

    expect(Key('.dotfile').hasExtension('dotfile'), isFalse);

    expect(Key('path.foo.bar').hasExtension('foo.bar'), isFalse);
    expect(Key('path.foo.bar').hasExtension('bar'), isTrue);
  });

  test('toString()', () {
    expect(Key('dir/sub/path.txt').toString(), 'dir/sub/path.txt');
  });

  test('equality', () {
    expect(Key('dir/sub/path.txt') == Key('dir/sub/path.txt'), isTrue);
    expect(Key('dir/sub/path.txt') == Key('dir/other/path.txt'), isFalse);
  });
}
