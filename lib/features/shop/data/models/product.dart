class Product {
  final String id;
  final String name;
  final String slug;
  final String description;
  final double price;
  final int stock;
  final List<String> images;
  final List<String> features;
  final List<String> sizes;
  final List<String> colors;
  final bool isActive;
  final bool isFeatured;
  final double? rating;
  final int reviewCount;
  final String? deviceType; // 'SMART_RING' | 'WHOOP_BAND' | null

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.price,
    required this.stock,
    required this.images,
    required this.features,
    required this.sizes,
    required this.colors,
    required this.isActive,
    required this.isFeatured,
    this.rating,
    required this.reviewCount,
    this.deviceType,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      images: (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      features: (json['features'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      sizes: (json['sizes'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      colors: (json['colors'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      isActive: json['isActive'] as bool? ?? false,
      isFeatured: json['isFeatured'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      deviceType: json['deviceType'] as String?,
    );
  }
}
