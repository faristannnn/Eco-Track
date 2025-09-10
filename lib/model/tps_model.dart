class Tps {
  final String id;
  final String nama;
  final String alamat;
  final double latitude;
  final double longitude;
  final int kapasitas;

  Tps({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.kapasitas,
  });

  factory Tps.fromJson(Map<String, dynamic> json) {
    return Tps(
      id: json['_id'],
      nama: json['nama'],
      alamat: json['alamat'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      kapasitas: json['kapasitas'],
    );
  }
}
