import '../models/cabinet_config_model.dart';

class CabinetConfigs {
  static final Map<int, CabinetConfigModel> configs = {
    1: _cabinet1(),
    2: _cabinet2(),
    3: _cabinet3(),
    4: _cabinet4(),
    5: _cabinet5(),
    6: _cabinet6(),
    7: _cabinet7(),
    8: _cabinet8(),
  };

  // ==============================
  // کمد شماره 1 - کمد زمینی ساده
  // ==============================
  static CabinetConfigModel _cabinet1() {
    return CabinetConfigModel(
      number: 1,
      name: 'کمد زمینی ساده',
      type: 'mdf',
      hasFloors: true,
      hasColumnBeam: true,
      doorOptions: ['بدون درب', 'یک درب', 'دو درب', 'سه درب'],
      inputFields: [
        'طول',
        'عرض (عمق)',
        'ارتفاع',
        'تعداد طبقات',
        'عرض تیرک (cm)',
        'تیرک لولا',
      ],
      rows: [],
    );
  }

  // ==============================
  // کمد شماره 2 - کمد زیر سینک (فومیز)
  // ==============================
  static CabinetConfigModel _cabinet2() {
    return CabinetConfigModel(
      number: 2,
      name: 'کمد زیر سینک',
      type: 'foam',
      hasFloors: false,
      hasColumnBeam: false,
      doorOptions: ['بدون درب', 'یک درب', 'دو درب'],
      inputFields: [
        'طول',
        'عرض (عمق)',
        'ارتفاع',
        'عرض تیرک (cm)',
      ],
      rows: [],
    );
  }

  // ==============================
  // کمد شماره 3 - کمد کشو دار
  // ==============================
  static CabinetConfigModel _cabinet3() {
    return CabinetConfigModel(
      number: 3,
      name: 'کمد کشو دار',
      type: 'mdf',
      hasFloors: false,
      hasColumnBeam: false,
      doorOptions: [],
      inputFields: [
        'طول',
        'عرض (عمق)',
        'ارتفاع',
        'عرض تیرک (cm)',
        'عمق کشوی مخفی (cm)',
        'فاصله بین کشوها (cm)',
      ],
      rows: [],
    );
  }

  // ==============================
  // کمد شماره 4 - کمد آبچک
  // ==============================
  static CabinetConfigModel _cabinet4() {
    return CabinetConfigModel(
      number: 4,
      name: 'کمد آبچک',
      type: 'mdf',
      hasFloors: false,
      hasColumnBeam: false,
      doorOptions: [],
      inputFields: [
        'طول',
        'عرض (عمق)',
        'ارتفاع',
        'عرض تیرک (cm)',
        'ارتفاع طبقه بالایی (cm)',
      ],
      rows: [],
    );
  }

  // ==============================
  // کمد شماره 5 - کمد پکیج
  // ==============================
  static CabinetConfigModel _cabinet5() {
    return CabinetConfigModel(
      number: 5,
      name: 'کمد پکیج',
      type: 'mdf',
      hasFloors: false,
      hasColumnBeam: false,
      doorOptions: [],
      inputFields: [
        'طول',
        'عرض (عمق)',
        'ارتفاع',
        'عرض تیرک (cm)',
      ],
      rows: [],
    );
  }

  // ==============================
  // کمد شماره 6 - کمد دیواری
  // ==============================
  static CabinetConfigModel _cabinet6() {
    return CabinetConfigModel(
      number: 6,
      name: 'کمد دیواری',
      type: 'mdf',
      hasFloors: false,
      hasColumnBeam: false,
      doorOptions: [],
      inputFields: [
        'طول',
        'عرض (عمق)',
        'ارتفاع',
        'عرض تیرک (cm)',
        'تعداد طبقه',
      ],
      rows: [],
    );
  }

  // ==============================
  // کمد شماره 7 - کمد سوپری
  // ==============================
  static CabinetConfigModel _cabinet7() {
    return CabinetConfigModel(
      number: 7,
      name: 'کمد سوپری',
      type: 'mdf',
      hasFloors: true,
      hasColumnBeam: false,
      doorOptions: [],
      inputFields: [
        'طول',
        'عرض (عمق)',
        'ارتفاع',
        'عرض تیرک (cm)',
        'تعداد طبقه',
      ],
      rows: [],
    );
  }

  // ==============================
  // کمد شماره 8 - کمد بالای یخچال
  // ==============================
  static CabinetConfigModel _cabinet8() {
    return CabinetConfigModel(
      number: 8,
      name: 'کمد بالای یخچال',
      type: 'mdf',
      hasFloors: false,
      hasColumnBeam: false,
      doorOptions: [],
      inputFields: [
        'طول',
        'عرض (عمق)',
        'ارتفاع',
        'عرض تیرک (cm)',
      ],
      rows: [],
    );
  }

  static CabinetConfigModel? getConfig(int number) {
    return configs[number];
  }

  static List<int> getAllCabinetNumbers() {
    return configs.keys.toList()..sort();
  }
}