// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RouteModelAdapter extends TypeAdapter<RouteModel> {
  @override
  final int typeId = 0;

  @override
  RouteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RouteModel(
      start: fields[0] as LatLng,
      end: fields[1] as LatLng,
      date: fields[2] as DateTime,
      seats: fields[3] as int,
      routePoints: (fields[4] as List).cast<LatLng>(),
      bookedSeats: fields[5] as int,
      driverId: fields[6] as String,
      driverName: fields[7] as String,
      totalCost: fields[8] as double,
      passengerIds: (fields[9] as List).cast<String>(),
      isActive: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RouteModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.start)
      ..writeByte(1)
      ..write(obj.end)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.seats)
      ..writeByte(4)
      ..write(obj.routePoints)
      ..writeByte(5)
      ..write(obj.bookedSeats)
      ..writeByte(6)
      ..write(obj.driverId)
      ..writeByte(7)
      ..write(obj.driverName)
      ..writeByte(8)
      ..write(obj.totalCost)
      ..writeByte(9)
      ..write(obj.passengerIds)
      ..writeByte(10)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
