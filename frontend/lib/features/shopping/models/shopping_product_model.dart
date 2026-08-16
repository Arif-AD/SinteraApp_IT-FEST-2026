class ShoppingProduct {
  const ShoppingProduct({
    this.id,
    this.sellerId,
    required this.name,
    required this.farmerName,
    this.farmerProfileImageUrl,
    required this.price,
    this.originalPrice,
    required this.unit,
    this.discount,
    required this.rating,
    required this.sold,
    required this.category,
    required this.imageAsset,
    this.imageUrl,
    this.description,
    this.availableUntil,
    this.updatedAt,
    this.farmerAddress = '',
    this.farmerDetailHouse = '',
    this.shippingBaseFee = 0,
    this.shippingDistanceFee = 0,
    this.shippingFarmerSubsidy = 0,
    this.shippingCustomerShipping = 0,
    this.shippingDistanceKm = 0.0,
    this.shippingNote = 'Biaya pengiriman dihitung otomatis berdasarkan jarak.',
  });

  final String? id;
  final String? sellerId;
  final String name;
  final String farmerName;
  final String? farmerProfileImageUrl;
  final String price;
  final String? originalPrice;
  final String unit;
  final int? discount;
  final String rating;
  final String sold;
  final String category;
  final String imageAsset;
  final String? imageUrl;
  final String? description;
  final String? availableUntil;
  final String? updatedAt;
  final String farmerAddress;
  final String farmerDetailHouse;
  final int shippingBaseFee;
  final int shippingDistanceFee;
  final int shippingFarmerSubsidy;
  final int shippingCustomerShipping;
  final double shippingDistanceKm;
  final String shippingNote;
  // Optional timestamps
}
