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
      id: fields[0] as String,
      start: fields[1] as LatLng?,
      end: fields[2] as LatLng?,
      date: fields[3] as DateTime?,
      seats: fields[4] as int,
      routePoints: (fields[5] as List).cast<LatLng>(),
      bookedSeats: fields[6] as int,
      driverId: fields[7] as String,
      driverName: fields[8] as String,
      totalCost: fields[9] as double,
      passengerIds: (fields[10] as List).cast<String>(),
      isActive: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RouteModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.start)
      ..writeByte(2)
      ..write(obj.end)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.seats)
      ..writeByte(5)
      ..write(obj.routePoints)
      ..writeByte(6)
      ..write(obj.bookedSeats)
      ..writeByte(7)
      ..write(obj.driverId)
      ..writeByte(8)
      ..write(obj.driverName)
      ..writeByte(9)
      ..write(obj.totalCost)
      ..writeByte(10)
      ..write(obj.passengerIds)
      ..writeByte(11)
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
