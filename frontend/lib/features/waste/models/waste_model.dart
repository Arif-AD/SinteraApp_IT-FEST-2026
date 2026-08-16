import 'package:flutter/material.dart';

class WasteSellItem {
  const WasteSellItem({
    required this.title,
    required this.value,
    required this.imageName,
  });

  final String title;
  final String value;
  final String imageName;
}

class WasteSellRecord {
  const WasteSellRecord({
    required this.date,
    required this.title,
    required this.unitInfo,
    required this.totalPoints,
    required this.status,
    required this.statusColor,
    required this.imageName,
    this.id,
    this.wasteType,
    this.weight,
    this.note,
    this.address,
    this.latitude,
    this.longitude,
    this.imageUrl,
  });

  final String date;
  final String title;
  final String unitInfo;
  final String totalPoints;
  final String status;
  final Color statusColor;
  final String imageName;
  final String? id;
  final String? wasteType;
  final double? weight;
  final String? note;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
}