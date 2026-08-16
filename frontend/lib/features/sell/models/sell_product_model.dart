class SellProduct {
  const SellProduct({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    required this.stock,
    required this.status,
    this.rating = '0',
    this.imageUrl,
    this.description,
    this.availableUntil,
    this.updatedAt,
    this.farmerName = '',
    this.farmerProfileImageUrl,
    this.farmerAddress = '',
    this.farmerDetailHouse = '',
  });

  static String normalizeCategory(dynamic rawCategory) {
    final category = rawCategory?.toString().trim().toLowerCase();
    if (category == null || category.isEmpty) {
      return 'Sayur';
    }

    if (category == 'buah') {
      return 'Buah';
    }

    if (category == 'vegetables' || category == 'vegetable' || category == 'sayur' || category == 'sayuran') {
      return 'Sayur';
    }

    return 'Sayur';
  }

  final String id;
  final String name;
  final String category;
  final String price;
  final String unit;
  final String stock;
  final String status;
  final String rating;
  final String? imageUrl;
  final String? description;
  final String? availableUntil;
  final String? updatedAt;
  final String farmerName;
  final String? farmerProfileImageUrl;  final String farmerAddress;
  final String farmerDetailHouse;
  factory SellProduct.fromApiMap(Map<String, dynamic> item) {
    final rawPrice = item['price'];
    final formattedPrice = rawPrice is num
        ? 'Rp${rawPrice.toStringAsFixed(0)}'
        : 'Rp${rawPrice.toString()}';

    final farmerNameValue = item['farmer_name']?.toString().trim();
    final farmerProfileValue = item['farmer_profile']?.toString().trim();
    final farmerAddressValue = item['farmer_address']?.toString().trim();
    final farmerDetailHouseValue = item['farmer_detail_house']?.toString().trim();

    return SellProduct(
      id: item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: item['name']?.toString() ?? '-',
      category: normalizeCategory(item['category']),
      price: formattedPrice,
      unit: item['unit']?.toString() ?? 'kg',
      stock: item['stock']?.toString() ?? '0',
      status: item['status']?.toString() == 'available' ? 'Aktif' : 'Nonaktif',
      rating: (() {
        final rawRating = item['rating'];
        if (rawRating == null) return '0';
        if (rawRating is num) {
          return rawRating % 1 == 0 ? rawRating.toStringAsFixed(0) : rawRating.toStringAsFixed(1);
        }
        return rawRating.toString();
      })(),
      imageUrl: item['image']?.toString(),
      description: item['description']?.toString() ?? item['product_description']?.toString() ?? '',
      availableUntil: item['available_until']?.toString(),
      updatedAt: item['updated_at']?.toString(),
      farmerName: farmerNameValue != null && farmerNameValue.isNotEmpty ? farmerNameValue : 'Petani Lokal',
      farmerProfileImageUrl: farmerProfileValue != null && farmerProfileValue.isNotEmpty ? farmerProfileValue : null,
      farmerAddress: farmerAddressValue != null && farmerAddressValue.isNotEmpty ? farmerAddressValue : '',
      farmerDetailHouse: farmerDetailHouseValue != null && farmerDetailHouseValue.isNotEmpty ? farmerDetailHouseValue : '',
    );
  }
}