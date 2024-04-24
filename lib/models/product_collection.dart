class ProductCollection {
  final String id;

  ProductCollection(this.id);

  factory ProductCollection.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': String id,

      } =>
        ProductCollection(
          id,

        ),
      _ => throw const FormatException('Failed to load album.'),
    };
  }
  
}
