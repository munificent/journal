/// Interface for an asset that can expose its data as a byte array.
abstract class BinaryAsset {
  Future<List<int>> readBytes();
}

/// Interface for an asset that can expose its data as a string.
abstract class StringAsset {
  Future<String> readString();
}
