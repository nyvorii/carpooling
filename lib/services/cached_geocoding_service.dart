import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import '../models/geocoding_cache_model.dart';
import 'nominatim_service.dart';
import 'geocoding_service.dart';

class CachedGeocodingService {
  static final CachedGeocodingService _instance = CachedGeocodingService._internal();
  factory CachedGeocodingService() => _instance;
  CachedGeocodingService._internal();

  static const int _cacheDurationDays = 30;
  static const bool _useNominatim = false;

  String _generateCacheKey(LatLng coordinates) {
    return '${coordinates.latitude.toStringAsFixed(6)},${coordinates.longitude.toStringAsFixed(6)}';
  }

  Future<GeocodingCache?> _getFromCache(String key) async {
    try {
      final box = Hive.box<GeocodingCache>('geocoding_cache');
      final cache = box.get(key);

      if (cache != null) {
        final age = DateTime.now().difference(cache.timestamp);
        if (age.inDays <= _cacheDurationDays) {
          return cache;
        } else {
          await box.delete(key);
        }
      }
    } catch (e) {
      print('[CachedGeocoding] Błąd odczytu cache: $e');
    }
    return null;
  }

  Future<void> _saveToCache(String key, String address, String source) async {
    try {
      final box = Hive.box<GeocodingCache>('geocoding_cache');
      final cache = GeocodingCache(
        key: key,
        address: address,
        timestamp: DateTime.now(),
        source: source,
      );
      await box.put(key, cache);
    } catch (e) {
      print('[CachedGeocoding] Błąd zapisu cache: $e');
    }
  }

  Future<String> coordinatesToAddress(LatLng coordinates) async {
    final cacheKey = _generateCacheKey(coordinates);

    final cached = await _getFromCache(cacheKey);
    if (cached != null) {
      print('[CachedGeocoding] Pobrano z cache: ${cached.address}');
      return cached.address;
    }

    String address;
    String source;

    if (_useNominatim) {
      print('[CachedGeocoding] Używam Nominatim dla: $cacheKey');
      address = await NominatimService.coordinatesToAddress(coordinates);
      source = 'nominatim';
    } else {
      print('[CachedGeocoding] Używam Geocoding dla: $cacheKey');
      address = await GeocodingService.coordinatesToAddress(coordinates);
      source = 'geocoding';
    }

    await _saveToCache(cacheKey, address, source);

    return address;
  }

  Future<LatLng?> addressToCoordinates(String address) async {
    if (address.isEmpty) return null;

    if (_useNominatim) {
      return await NominatimService.addressToCoordinates(address);
    } else {
      return await GeocodingService.addressToCoordinates(address);
    }
  }

  Future<void> clearOldCache() async {
    try {
      final box = Hive.box<GeocodingCache>('geocoding_cache');
      final now = DateTime.now();
      final keysToDelete = <String>[];

      for (final entry in box.keys) {
        final cache = box.get(entry);
        if (cache != null) {
          final age = now.difference(cache.timestamp);
          if (age.inDays > _cacheDurationDays) {
            keysToDelete.add(entry as String);
          }
        }
      }

      for (final key in keysToDelete) {
        await box.delete(key);
      }

      print('[CachedGeocoding] Usunięto ${keysToDelete.length} starych wpisów');
    } catch (e) {
      print('[CachedGeocoding] Błąd czyszczenia cache: $e');
    }
  }

  Future<int> getCacheSize() async {
    try {
      final box = Hive.box<GeocodingCache>('geocoding_cache');
      return box.length;
    } catch (e) {
      return 0;
    }
  }
}