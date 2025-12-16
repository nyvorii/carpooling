import 'package:hive/hive.dart';

part 'geocoding_cache_model.g.dart';

@HiveType(typeId: 3)
class GeocodingCache {
  @HiveField(0)
  final String key;

  @HiveField(1)
  final String address;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String source;

  GeocodingCache({
    required this.key,
    required this.address,
    required this.timestamp,
    this.source = 'nominatim',
  });
}