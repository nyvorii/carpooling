part of 'geocoding_cache_model.dart';


class GeocodingCacheAdapter extends TypeAdapter<GeocodingCache> {
  @override
  final int typeId = 3;

  @override
  GeocodingCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GeocodingCache(
      key: fields[0] as String,
      address: fields[1] as String,
      timestamp: fields[2] as DateTime,
      source: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GeocodingCache obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.source);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeocodingCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
