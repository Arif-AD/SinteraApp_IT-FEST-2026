class SharedProduce {
  const SharedProduce({
    required this.id,
    required this.title,
    required this.donorName,
    required this.location,
    required this.category,
    required this.amount,
    required this.status,
    required this.description,
    required this.imageAsset,
    required this.isClaimed,
  });

  final String id;
  final String title;
  final String donorName;
  final String location;
  final String category;
  final String amount;
  final String status;
  final String description;
  final String imageAsset;
  final bool isClaimed;
}