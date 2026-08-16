class WasteProductModel {
  const WasteProductModel({
    required this.id,
    required this.residentName,
    required this.wasteType,
    required this.weight,
    required this.date,
    required this.note,
    required this.status,
    this.imageUrl,
  });

  final String id;
  final String residentName;
  final String wasteType; // 'Organik' atau 'Anorganik'
  final String weight; // Contoh: '5 kg'
  final String date;
  final String note;
  final String status; // 'Tersedia' atau 'Diklaim'
  final String? imageUrl;
}