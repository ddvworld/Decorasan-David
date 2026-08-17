class CabinetConfigModel {
  final int number;
  final String name;
  final String type; // 'mdf' یا 'foam'
  final bool hasFloors;
  final bool hasColumnBeam;
  final bool hasThreeDoor;
  final List<String> doorOptions;
  final List<String> inputFields;
  final List<Map<String, dynamic>>? extraFields;
  final List<Map<String, dynamic>> rows;

  CabinetConfigModel({
    required this.number,
    required this.name,
    required this.type,
    this.hasFloors = false,
    this.hasColumnBeam = false,
    this.hasThreeDoor = false,
    this.doorOptions = const ['بدون درب', 'یک درب', 'دو درب'],
    required this.inputFields,
    this.extraFields,
    required this.rows,
  });

  String get tableTitle {
    return type == 'mdf' ? 'لیست قطعات ام دی اف' : 'لیست قطعات فومیز';
  }

  String get threeMeterTitle {
    return type == 'mdf' ? 'جدول سه میل' : 'جدول سه میل فومیز';
  }
}