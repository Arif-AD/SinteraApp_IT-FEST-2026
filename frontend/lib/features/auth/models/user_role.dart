/// Available user roles in the Sintera app.
enum UserRole {
  warga,
  petani,
  pengantar;

  String get label {
    switch (this) {
      case UserRole.warga:
        return 'Warga';
      case UserRole.petani:
        return 'Petani';
      case UserRole.pengantar:
        return 'Pengantar';
    }
  }

  String get iconAsset {
    switch (this) {
      case UserRole.warga:
        return 'icon_warga.png';
      case UserRole.petani:
        return 'icon_petani.png';
      case UserRole.pengantar:
        return 'icon_pengantar.png';
    }
  }
}
