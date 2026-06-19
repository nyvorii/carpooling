import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class NominatimService {
  static final String _baseUrl = 'https://nominatim.openstreetmap.org';

  static Future<String> coordinatesToAddress(LatLng coordinates) async {
    print('[Nominatim] Reverse geocoding dla: ${coordinates.latitude}, ${coordinates.longitude}');

    try {
      final url = Uri.parse(
          '$_baseUrl/reverse?format=jsonv2&lat=${coordinates.latitude}&lon=${coordinates.longitude}&zoom=18&addressdetails=1'
      );

      print('[Nominatim] URL: $url');

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'CarpoolingApp/1.0 (contact@example.com)',
          'Accept-Language': 'pl',
        },
      ).timeout(const Duration(seconds: 10));

      print('[Nominatim] Status Code: ${response.statusCode}');
      print('[Nominatim] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final formattedAddress = _formatAddressFromOSM(address);
          print('[Nominatim] Znaleziony adres: $formattedAddress');
          return formattedAddress;
        } else {
          print('[Nominatim] Brak pola "address" w odpowiedzi');
        }
      } else if (response.statusCode == 429) {
        print('[Nominatim] Błąd 429: Za dużo zapytań. Poczekaj chwilę.');
        return 'Limit zapytań - spróbuj później';
      } else {
        print('[Nominatim] Błąd HTTP: ${response.statusCode}');
      }

      return '${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}';
    } catch (e) {
      print('[Nominatim] Błąd reverse geokodowania: $e');
      return '${coordinates.latitude.toStringAsFixed(4)}, ${coordinates.longitude.toStringAsFixed(4)}';
    }
  }

  static Future<LatLng?> addressToCoordinates(String address) async {
    if (address.isEmpty) return null;

    print('[Nominatim] Forward geocoding dla: $address');

    try {
      final url = Uri.parse(
          '$_baseUrl/search?format=jsonv2&q=${Uri.encodeComponent(address)}&limit=1&countrycodes=pl'
      );

      print('[Nominatim] URL: $url');

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'CarpoolingApp/1.0 (contact@example.com)',
          'Accept-Language': 'pl',
        },
      ).timeout(const Duration(seconds: 10));

      print('[Nominatim] Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;

        if (data.isNotEmpty) {
          final location = data.first as Map<String, dynamic>;
          final lat = double.parse(location['lat'] as String);
          final lon = double.parse(location['lon'] as String);
          print('[Nominatim] Znalezione współrzędne: $lat, $lon');
          return LatLng(lat, lon);
        } else {
          print('[Nominatim] Brak wyników dla adresu');
        }
      }

      return null;
    } catch (e) {
      print('[Nominatim] Błąd forward geokodowania: $e');
      return null;
    }
  }

  static String _formatAddressFromOSM(Map<String, dynamic> address) {
    final parts = <String>[];

    if (address['road'] != null) parts.add(address['road'] as String);
    if (address['house_number'] != null) parts.add(address['house_number'] as String);
    if (address['suburb'] != null) parts.add(address['suburb'] as String);
    if (address['city'] != null) {
      parts.add(address['city'] as String);
    } else if (address['town'] != null) {
      parts.add(address['town'] as String);
    } else if (address['village'] != null) {
      parts.add(address['village'] as String);
    }
    if (address['postcode'] != null) parts.add(address['postcode'] as String);

    if (parts.length <= 2 && address['country'] != null) {
      parts.add(address['country'] as String);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Nieznany adres';
  }
}