import 'package:latlong2/latlong.dart';

class RouteFilters {
  DateTime? dateFrom;
  DateTime? dateTo;
  double? maxPrice;
  int? minSeats;
  double? minRating;
  double? maxDistance;
  LatLng? userLocation;
  double? searchRadiusKm;

  RouteFilters({
    this.dateFrom,
    this.dateTo,
    this.maxPrice,
    this.minSeats,
    this.minRating,
    this.maxDistance,
    this.userLocation,
    this.searchRadiusKm,
  });

  bool get hasFilters {
    return dateFrom != null ||
        dateTo != null ||
        maxPrice != null ||
        minSeats != null ||
        minRating != null ||
        maxDistance != null ||
        (userLocation != null && searchRadiusKm != null);
  }

  RouteFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    double? maxPrice,
    int? minSeats,
    double? minRating,
    double? maxDistance,
    LatLng? userLocation,
    double? searchRadiusKm,
  }) {
    return RouteFilters(
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      maxPrice: maxPrice ?? this.maxPrice,
      minSeats: minSeats ?? this.minSeats,
      minRating: minRating ?? this.minRating,
      maxDistance: maxDistance ?? this.maxDistance,
      userLocation: userLocation ?? this.userLocation,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
    );
  }

  static RouteFilters get defaultFilters => RouteFilters();
}