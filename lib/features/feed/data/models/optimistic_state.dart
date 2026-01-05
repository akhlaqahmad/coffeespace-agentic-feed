import 'package:hive/hive.dart';

/// Enum representing the optimistic state of an operation.
enum OptimisticState {
  pending,
  failed,
  confirmed,
}

/// Manual Hive adapter for OptimisticState enum.
class OptimisticStateAdapter extends TypeAdapter<OptimisticState> {
  @override
  final int typeId = 3;

  @override
  OptimisticState read(BinaryReader reader) {
    final index = reader.readByte();
    switch (index) {
      case 0:
        return OptimisticState.pending;
      case 1:
        return OptimisticState.failed;
      case 2:
        return OptimisticState.confirmed;
      default:
        throw Exception('Invalid OptimisticState index: $index');
    }
  }

  @override
  void write(BinaryWriter writer, OptimisticState obj) {
    switch (obj) {
      case OptimisticState.pending:
        writer.writeByte(0);
        break;
      case OptimisticState.failed:
        writer.writeByte(1);
        break;
      case OptimisticState.confirmed:
        writer.writeByte(2);
        break;
    }
  }
}
