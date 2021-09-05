import 'dart:async';

abstract class TemplateData {
  /// Return this value to indicate that the property could not be found.
  ///
  /// Returning `null` means the property was found and its value is null.
  static const Object unknownProperty = _UnknownProperty();

  FutureOr<Object?> lookup(String property);
}

class _UnknownProperty {
  const _UnknownProperty();
}
