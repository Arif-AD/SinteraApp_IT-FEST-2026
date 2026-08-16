class CloudinaryConstants {
  CloudinaryConstants._();

  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'jpxjd4v7',
  );

  static const String uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'sintera',
  );

  static String get uploadUrl => 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}
