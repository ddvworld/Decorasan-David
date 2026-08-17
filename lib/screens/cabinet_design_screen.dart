import 'package:flutter/material.dart';
import '../services/local_database_service.dart';
import '../models/cabinet_model.dart';
import '../models/project_design_model.dart';
import '../data/cabinet_configs.dart';
import '../models/cabinet_config_model.dart';

class CabinetDesignScreen extends StatefulWidget {
  final String projectId;
  final CabinetModel cabinet;
  final ProjectDesignModel? existingDesign;
  final int cabinetNumber;

  const CabinetDesignScreen({
    super.key,
    required this.projectId,
    required this.cabinet,
    this.existingDesign,
    required this.cabinetNumber,
  });

  @override
  State<CabinetDesignScreen> createState() => _CabinetDesignScreenState();
}

class _CabinetDesignScreenState extends State<CabinetDesignScreen> {
  final Map<String, TextEditingController> _controllers = {};
  
  bool _isLoading = false;
  String? _errorMessage;
  
  List<Map<String, dynamic>> _tableData = [];
  List<Map<String, dynamic>> _doorTableData = [];
  List<Map<String, dynamic>> _floorTableData = [];
  bool _showTable = false;
  bool _hasCalculated = false;
  
  // ==============================
  // گزینه‌های رادیویی عمومی
  // ==============================
  String _selectedDoorType = 'دو درب';
  String _selectedHandleType = 'ندارد';
  String _selectedThreeMeterType = 'ساده';
  
  // کمد 3
  String _selectedDrawerCount = '1';
  String _selectedHiddenDrawer = 'ندارد';
  String _selectedFloorType = 'سه میل ساده';
  
  // کمد 4
  String _selectedDoorType4 = 'درب معمولی';
  String _selectedWallType = 'سه میل فومیز';
  
  // کمد 5
  String _selectedDoorCount5 = '1';
  
  // کمد 6
  String _selectedDoorCount6 = '1';
  
  // کمد 7
  String _selectedDoorCount7 = '1';
  
  // کمد 8
  String _selectedDoorCount8 = '1';
  
  final List<String> _handleOptions = ['دارد', 'ندارد'];
  final List<String> _threeMeterOptions = ['ساده', 'فومیز'];
  final List<String> _hiddenDrawerOptions = ['دارد', 'ندارد'];
  final List<String> _drawerCountOptions = ['1', '2', '3', '4', '5'];
  final List<String> _floorTypeOptions = ['سه میل ساده', 'هشت میل'];
  final List<String> _doorCountOptions5 = ['1', '2'];
  final List<String> _doorCountOptions6 = ['1', '2'];
  final List<String> _doorCountOptions7 = ['1', '2', '3', '4'];
  final List<String> _doorCountOptions8 = ['1', '2', '3', '4'];
  final List<String> _doorType4Options = ['درب معمولی', 'درب جکی'];
  final List<String> _wallTypeOptions = ['سه میل فومیز', 'فومیز 16 میل'];

  CabinetConfigModel? get _config => CabinetConfigs.getConfig(widget.cabinetNumber);
  bool get isActiveCabinet => _config != null;

  @override
  void initState() {
    super.initState();
    _initControllers();
    if (widget.existingDesign != null) {
      _loadExistingDesign();
    }
    if (widget.existingDesign != null && 
        widget.existingDesign!.length > 0 && 
        widget.existingDesign!.width > 0 && 
        widget.existingDesign!.height > 0) {
      _calculate();
      _hasCalculated = true;
    }
  }

  void _initControllers() {
    if (_config == null) return;
    for (var field in _config!.inputFields) {
      _controllers[field] = TextEditingController();
    }
    _controllers['ارتفاع درب 1 (cm)'] = TextEditingController();
    _controllers['ارتفاع درب 2 (cm)'] = TextEditingController();
    _controllers['ارتفاع درب 3 (cm)'] = TextEditingController();
    _controllers['ارتفاع درب 4 (cm)'] = TextEditingController();
  }

  void _loadExistingDesign() {
    final design = widget.existingDesign!;
    _setControllerValue('طول', design.length > 0 ? design.length.toString() : '');
    _setControllerValue('عرض (عمق)', design.width > 0 ? design.width.toString() : '');
    _setControllerValue('ارتفاع', design.height > 0 ? design.height.toString() : '');
    
    if (_config?.hasFloors == true && design.floors > 0) {
      _setControllerValue('تعداد طبقات', design.floors.toString());
      _setControllerValue('تعداد طبقه', design.floors.toString());
    }
    
    if (design.notes != null) {
      final beamMatch = RegExp(r'تیرک:(\d+\.?\d*)').firstMatch(design.notes!);
      if (beamMatch != null) {
        _setControllerValue('عرض تیرک', beamMatch.group(1) ?? '');
        _setControllerValue('عرض تیرک (cm)', beamMatch.group(1) ?? '');
      }
      
      if (widget.cabinetNumber == 1) {
        final columnBeamMatch = RegExp(r'تیرک لولا:(\d+\.?\d*)').firstMatch(design.notes!);
        if (columnBeamMatch != null) {
          _setControllerValue('تیرک لولا', columnBeamMatch.group(1) ?? '');
        }
      }
      
      if (widget.cabinetNumber == 3) {
        final drawerDepthMatch = RegExp(r'عمق کشوی مخفی:(\d+\.?\d*)').firstMatch(design.notes!);
        if (drawerDepthMatch != null) {
          _setControllerValue('عمق کشوی مخفی', drawerDepthMatch.group(1) ?? '');
          _setControllerValue('عمق کشوی مخفی (cm)', drawerDepthMatch.group(1) ?? '');
        }
        final drawerGapMatch = RegExp(r'فاصله بین کشوها:(\d+\.?\d*)').firstMatch(design.notes!);
        if (drawerGapMatch != null) {
          _setControllerValue('فاصله بین کشوها (cm)', drawerGapMatch.group(1) ?? '');
        }
        final drawerCountMatch = RegExp(r'تعداد کشو:(1|2|3|4|5)').firstMatch(design.notes!);
        if (drawerCountMatch != null) {
          _selectedDrawerCount = drawerCountMatch.group(1) ?? '1';
        }
        final hiddenDrawerMatch = RegExp(r'کشوی مخفی:(دارد|ندارد)').firstMatch(design.notes!);
        if (hiddenDrawerMatch != null) {
          _selectedHiddenDrawer = hiddenDrawerMatch.group(1) ?? 'ندارد';
        }
        final floorTypeMatch = RegExp(r'نوع کفی کشو:(سه میل ساده|هشت میل)').firstMatch(design.notes!);
        if (floorTypeMatch != null) {
          _selectedFloorType = floorTypeMatch.group(1) ?? 'سه میل ساده';
        }
      }
      
      if (widget.cabinetNumber == 4) {
        if (design.notes!.contains('نوع درب:درب جکی')) {
          _selectedDoorType4 = 'درب جکی';
        } else if (design.notes!.contains('نوع درب:درب معمولی')) {
          _selectedDoorType4 = 'درب معمولی';
        }
        if (design.notes!.contains('نوع دیواره پشت آبچک:فومیز 16 میل')) {
          _selectedWallType = 'فومیز 16 میل';
        } else if (design.notes!.contains('نوع دیواره پشت آبچک:سه میل فومیز')) {
          _selectedWallType = 'سه میل فومیز';
        }
        final topFloorMatch = RegExp(r'ارتفاع طبقه بالایی:(\d+\.?\d*)').firstMatch(design.notes!);
        if (topFloorMatch != null) {
          _setControllerValue('ارتفاع طبقه بالایی (cm)', topFloorMatch.group(1) ?? '');
        }
      }
      
      if (widget.cabinetNumber == 5) {
        if (design.notes!.contains('تعداد درب:1')) _selectedDoorCount5 = '1';
        else if (design.notes!.contains('تعداد درب:2')) _selectedDoorCount5 = '2';
      }
      
      if (widget.cabinetNumber == 6) {
        if (design.notes!.contains('تعداد درب:1')) _selectedDoorCount6 = '1';
        else if (design.notes!.contains('تعداد درب:2')) _selectedDoorCount6 = '2';
        final floorsMatch6 = RegExp(r'طبقه:(\d+)').firstMatch(design.notes!);
        if (floorsMatch6 != null) {
          _setControllerValue('تعداد طبقه', floorsMatch6.group(1) ?? '');
        }
      }
      
      if (widget.cabinetNumber == 7) {
        if (design.notes!.contains('تعداد درب:1')) _selectedDoorCount7 = '1';
        else if (design.notes!.contains('تعداد درب:2')) _selectedDoorCount7 = '2';
        else if (design.notes!.contains('تعداد درب:3')) _selectedDoorCount7 = '3';
        else if (design.notes!.contains('تعداد درب:4')) _selectedDoorCount7 = '4';
        final floorsMatch7 = RegExp(r'طبقه:(\d+)').firstMatch(design.notes!);
        if (floorsMatch7 != null) {
          _setControllerValue('تعداد طبقه', floorsMatch7.group(1) ?? '');
        }
        final doorHeight1Match = RegExp(r'ارتفاع درب 1:(\d+\.?\d*)').firstMatch(design.notes!);
        if (doorHeight1Match != null) {
          _setControllerValue('ارتفاع درب 1 (cm)', doorHeight1Match.group(1) ?? '');
        }
        final doorHeight2Match = RegExp(r'ارتفاع درب 2:(\d+\.?\d*)').firstMatch(design.notes!);
        if (doorHeight2Match != null) {
          _setControllerValue('ارتفاع درب 2 (cm)', doorHeight2Match.group(1) ?? '');
        }
        final doorHeight3Match = RegExp(r'ارتفاع درب 3:(\d+\.?\d*)').firstMatch(design.notes!);
        if (doorHeight3Match != null) {
          _setControllerValue('ارتفاع درب 3 (cm)', doorHeight3Match.group(1) ?? '');
        }
        final doorHeight4Match = RegExp(r'ارتفاع درب 4:(\d+\.?\d*)').firstMatch(design.notes!);
        if (doorHeight4Match != null) {
          _setControllerValue('ارتفاع درب 4 (cm)', doorHeight4Match.group(1) ?? '');
        }
      }
      
      if (widget.cabinetNumber == 8) {
        if (design.notes!.contains('تعداد درب:1')) _selectedDoorCount8 = '1';
        else if (design.notes!.contains('تعداد درب:2')) _selectedDoorCount8 = '2';
        else if (design.notes!.contains('تعداد درب:3')) _selectedDoorCount8 = '3';
        else if (design.notes!.contains('تعداد درب:4')) _selectedDoorCount8 = '4';
      }
      
      if (widget.cabinetNumber == 1 || widget.cabinetNumber == 2) {
        if (design.notes!.contains('سه میل:فومیز')) _selectedThreeMeterType = 'فومیز';
        else if (design.notes!.contains('سه میل:ساده')) _selectedThreeMeterType = 'ساده';
      }
      
      if (widget.cabinetNumber == 1 || widget.cabinetNumber == 2) {
        final doorOptions = _config?.doorOptions ?? ['بدون درب', 'یک درب', 'دو درب'];
        for (var option in doorOptions) {
          if (design.notes!.contains(option)) {
            _selectedDoorType = option;
            break;
          }
        }
      }
      
      if (widget.cabinetNumber != 7 && widget.cabinetNumber != 8) {
        if (design.notes!.contains('دستگیره: دارد') || design.notes!.contains('دستگیره مخفی:دارد')) {
          _selectedHandleType = 'دارد';
        } else if (design.notes!.contains('دستگیره: ندارد') || design.notes!.contains('دستگیره مخفی:ندارد')) {
          _selectedHandleType = 'ندارد';
        }
      }
    }
  }

  void _setControllerValue(String key, String value) {
    if (_controllers.containsKey(key)) {
      _controllers[key]?.text = value;
    }
  }

  String _getControllerValue(String key) {
    return _controllers[key]?.text ?? '';
  }

  double _getControllerDouble(String key) {
    return double.tryParse(_getControllerValue(key)) ?? 0;
  }

  int _getControllerInt(String key) {
    return int.tryParse(_getControllerValue(key)) ?? 0;
  }

  int _getDrawerCountNumber() {
    return int.tryParse(_selectedDrawerCount) ?? 1;
  }

  int _getDoorCount() {
    if (_config?.number == 3) return 0;
    switch (_selectedDoorType) {
      case 'بدون درب': return 0;
      case 'یک درب': return 1;
      case 'دو درب': return 2;
      case 'سه درب': return 3;
      default: return 2;
    }
  }

  void _calculate() {
    setState(() {
      _errorMessage = null;
      _tableData = [];
      _doorTableData = [];
      _floorTableData = [];
      _showTable = false;
      _hasCalculated = false;
    });

    if (_getControllerValue('طول').isEmpty ||
        _getControllerValue('عرض (عمق)').isEmpty ||
        _getControllerValue('ارتفاع').isEmpty) {
      setState(() {
        _errorMessage = 'لطفاً طول، عرض و ارتفاع را وارد کنید';
      });
      return;
    }

    try {
      final length = _getControllerDouble('طول');
      final width = _getControllerDouble('عرض (عمق)');
      final height = _getControllerDouble('ارتفاع');
      
      if (length <= 0 || width <= 0 || height <= 0) {
        setState(() {
          _errorMessage = 'طول، عرض و ارتفاع باید مثبت باشند';
        });
        return;
      }

      if (widget.cabinetNumber == 1) {
        _calculateCabinet1(length, width, height);
      } else if (widget.cabinetNumber == 2) {
        _calculateCabinet2(length, width, height);
      } else if (widget.cabinetNumber == 3) {
        _calculateCabinet3(length, width, height);
      } else if (widget.cabinetNumber == 4) {
        _calculateCabinet4(length, width, height);
      } else if (widget.cabinetNumber == 5) {
        _calculateCabinet5(length, width, height);
      } else if (widget.cabinetNumber == 6) {
        _calculateCabinet6(length, width, height);
      } else if (widget.cabinetNumber == 7) {
        _calculateCabinet7(length, width, height);
      } else if (widget.cabinetNumber == 8) {
        _calculateCabinet8(length, width, height);
      } else {
        _calculateDefaultCabinet(length, width, height);
      }

      setState(() {
        _showTable = true;
        _hasCalculated = true;
      });

      _saveDesignAutomatically();

    } catch (e) {
      setState(() {
        _errorMessage = 'لطفاً مقادیر عددی معتبر وارد کنید';
      });
    }
  }

  void _calculateCabinet1(double length, double width, double height) {
    _tableData = [];
    _doorTableData = [];
    _floorTableData = [];
    
    int rowCounter = 1;
    int floors = _getControllerInt('تعداد طبقات');
    double beam = _getControllerDouble('عرض تیرک (cm)');
    double columnBeam = _getControllerDouble('تیرک لولا');
    int doorCount = _getDoorCount();
    bool hasHandle = _selectedHandleType == 'دارد';

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'کف'
    });
    rowCounter++;

    if (floors > 0) {
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': floors.toString(),
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': width.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'طبقه'
      });
      rowCounter++;
    }

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '2',
      'طول': (height - 1.6).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل'
    });
    rowCounter++;

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '3',
      'طول': (length - 3.2).toStringAsFixed(1),
      'PVC': '1',
      'عرض': beam.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'تیرک'
    });
    rowCounter++;

    if (doorCount > 2) {
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': '2',
        'طول': (height - 1.6).toStringAsFixed(1),
        'PVC': '1',
        'عرض': columnBeam.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'تیرک لولا'
      });
      rowCounter++;
    }

    _floorTableData.add({
      'ردیف': '1',
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'عرض': height.toStringAsFixed(0),
      'توضیحات': 'سه میل ساده'
    });

    if (doorCount > 0) {
      double doorHeight = hasHandle ? height - 3.6 : height;
      double doorWidth;
      if (doorCount == 1) doorWidth = length - 0.3;
      else if (doorCount == 2) doorWidth = (length / 2) - 0.3;
      else doorWidth = (length / 3) - 0.3;
      
      _doorTableData.add({
        'ردیف': '1',
        'تعداد': doorCount.toString(),
        'طول': doorHeight.toStringAsFixed(1),
        'PVC': '2',
        'عرض': doorWidth.toStringAsFixed(1),
        'PVC2': '2',
        'توضیحات': 'درب ساده'
      });
    }
  }

  void _calculateCabinet2(double length, double width, double height) {
    _tableData = [];
    _doorTableData = [];
    _floorTableData = [];
    
    int rowCounter = 1;
    double beam = _getControllerDouble('عرض تیرک (cm)');
    int doorCount = _getDoorCount();
    bool hasHandle = _selectedHandleType == 'دارد';

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'کف'
    });
    rowCounter++;

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '2',
      'طول': (height - 1.6).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل'
    });
    rowCounter++;

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '3',
      'طول': (length - 3.2).toStringAsFixed(1),
      'PVC': '1',
      'عرض': beam.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'تیرک'
    });
    rowCounter++;

    _floorTableData.add({
      'ردیف': '1',
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'عرض': height.toStringAsFixed(0),
      'توضیحات': 'سه میل فومیز'
    });

    if (doorCount > 0) {
      double doorHeight = hasHandle ? height - 3.6 : height;
      double doorWidth = doorCount == 1 ? length - 0.3 : (length / 2) - 0.3;
      
      _doorTableData.add({
        'ردیف': '1',
        'تعداد': doorCount.toString(),
        'طول': doorHeight.toStringAsFixed(1),
        'PVC': '2',
        'عرض': doorWidth.toStringAsFixed(1),
        'PVC2': '2',
        'توضیحات': 'درب ساده'
      });
    }
  }

  void _calculateCabinet3(double length, double width, double height) {
    _tableData = [];
    _doorTableData = [];
    _floorTableData = [];
    
    int rowCounter = 1;
    double beam = _getControllerDouble('عرض تیرک (cm)');
    double drawerDepth = _getControllerDouble('عمق کشوی مخفی (cm)');
    double drawerGap = _getControllerDouble('فاصله بین کشوها (cm)');
    int drawerCount = _getDrawerCountNumber();
    bool hasHiddenDrawer = _selectedHiddenDrawer == 'دارد';
    bool hasHandle = _selectedHandleType == 'دارد';
    String floorType = _selectedFloorType;

    double x = (drawerCount - 1).toDouble();
    double y = hasHandle ? x * 2 : x * drawerGap;
    double doorDrawerWidth = (height - y) / drawerCount;
    double z = (doorDrawerWidth - 5).floorToDouble();

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'کف'
    });
    rowCounter++;

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '2',
      'طول': (height - 1.6).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل'
    });
    rowCounter++;

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '3',
      'طول': (length - 3.2).toStringAsFixed(1),
      'PVC': '1',
      'عرض': beam.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'تیرک'
    });
    rowCounter++;

    if (hasHiddenDrawer) {
      double w1 = (floorType == 'هشت میل') ? drawerDepth - 0.8 : drawerDepth;
      double w3 = (floorType == 'هشت میل') ? 15 - 0.8 : 15;
      double w5 = (floorType == 'هشت میل') ? 20 - 0.8 : 20;
      
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': '2',
        'طول': (length - 9).toStringAsFixed(1),
        'PVC': '1',
        'عرض': w1.toStringAsFixed(1),
        'PVC2': '-',
        'توضیحات': 'بدنه کشو مخفی'
      });
      rowCounter++;
      
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': '2',
        'طول': (width - 10).toStringAsFixed(1),
        'PVC': '1',
        'عرض': drawerDepth.toStringAsFixed(1),
        'PVC2': '-',
        'توضیحات': 'بدنه کشو مخفی'
      });
      rowCounter++;
      
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': '2',
        'طول': (length - 9).toStringAsFixed(1),
        'PVC': '1',
        'عرض': w3.toStringAsFixed(1),
        'PVC2': '-',
        'توضیحات': 'بدنه کشو'
      });
      rowCounter++;
      
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': '2',
        'طول': (width - 5).toStringAsFixed(1),
        'PVC': '1',
        'عرض': '15',
        'PVC2': '-',
        'توضیحات': 'بدنه کشو'
      });
      rowCounter++;
      
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': '2',
        'طول': (length - 9).toStringAsFixed(1),
        'PVC': '1',
        'عرض': w5.toStringAsFixed(1),
        'PVC2': '-',
        'توضیحات': 'بدنه کشو'
      });
      rowCounter++;
      
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': '2',
        'طول': (width - 5).toStringAsFixed(1),
        'PVC': '1',
        'عرض': '20',
        'PVC2': '-',
        'توضیحات': 'بدنه کشو'
      });
      rowCounter++;
      
    } else {
      double z2 = (floorType == 'هشت میل') ? z - 0.8 : z;
      
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': (drawerCount * 2).toString(),
        'طول': (length - 9).toStringAsFixed(1),
        'PVC': '1',
        'عرض': z.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'بدنه کشو'
      });
      rowCounter++;
      
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': (drawerCount * 2).toString(),
        'طول': (width - 5).toStringAsFixed(1),
        'PVC': '1',
        'عرض': z2.toStringAsFixed(1),
        'PVC2': '-',
        'توضیحات': 'بدنه کشو'
      });
      rowCounter++;
    }

    if (floorType == 'سه میل ساده') {
      double floorWidth = width - 5;
      double floorLength = length - 9;
      double maxVal = floorLength > floorWidth ? floorLength : floorWidth;
      double minVal = floorLength < floorWidth ? floorLength : floorWidth;
      
      _floorTableData.add({
        'ردیف': '1',
        'تعداد': drawerCount.toString(),
        'طول': maxVal.toStringAsFixed(1),
        'عرض': minVal.toStringAsFixed(1),
        'توضیحات': 'سه میل ساده'
      });

      if (hasHiddenDrawer) {
        double hiddenFloorWidth = width - 10;
        double hiddenFloorLength = length - 9;
        double hiddenMax = hiddenFloorLength > hiddenFloorWidth ? hiddenFloorLength : hiddenFloorWidth;
        double hiddenMin = hiddenFloorLength < hiddenFloorWidth ? hiddenFloorLength : hiddenFloorWidth;
        
        _floorTableData.add({
          'ردیف': '2',
          'تعداد': '1',
          'طول': hiddenMax.toStringAsFixed(1),
          'عرض': hiddenMin.toStringAsFixed(1),
          'توضیحات': 'کشوی مخفی - سه میل ساده'
        });
      }
      
    } else {
      double floorWidth8 = width - 5;
      double floorLength8 = length - 12.2;
      double maxVal8 = floorLength8 > floorWidth8 ? floorLength8 : floorWidth8;
      double minVal8 = floorLength8 < floorWidth8 ? floorLength8 : floorWidth8;
      
      _floorTableData.add({
        'ردیف': '1',
        'تعداد': drawerCount.toString(),
        'طول': maxVal8.toStringAsFixed(1),
        'عرض': minVal8.toStringAsFixed(1),
        'توضیحات': 'هشت میل'
      });

      if (hasHiddenDrawer) {
        double hiddenFloorWidth8 = width - 10;
        double hiddenFloorLength8 = length - 9;
        double hiddenMax8 = hiddenFloorLength8 > hiddenFloorWidth8 ? hiddenFloorLength8 : hiddenFloorWidth8;
        double hiddenMin8 = hiddenFloorLength8 < hiddenFloorWidth8 ? hiddenFloorLength8 : hiddenFloorWidth8;
        
        _floorTableData.add({
          'ردیف': '2',
          'تعداد': '1',
          'طول': hiddenMax8.toStringAsFixed(1),
          'عرض': hiddenMin8.toStringAsFixed(1),
          'توضیحات': 'کشوی مخفی - هشت میل'
        });
      }
    }

    _doorTableData.add({
      'ردیف': '1',
      'تعداد': drawerCount.toString(),
      'طول': length.toStringAsFixed(0),
      'PVC': '2',
      'عرض': doorDrawerWidth.toStringAsFixed(1),
      'PVC2': '2',
      'توضیحات': 'درب کشو'
    });

    if (hasHiddenDrawer) {
      _doorTableData.add({
        'ردیف': '2',
        'تعداد': '1',
        'طول': (length - 3.7).toStringAsFixed(1),
        'PVC': '2',
        'عرض': (drawerDepth + 1).toStringAsFixed(1),
        'PVC2': '2',
        'توضیحات': 'درب کشو مخفی'
      });
    }
  }

  void _calculateCabinet4(double length, double width, double height) {
    _tableData = [];
    _doorTableData = [];
    _floorTableData = [];
    
    int rowCounter = 1;
    double beam = _getControllerDouble('عرض تیرک (cm)');
    double topFloorHeight = _getControllerDouble('ارتفاع طبقه بالایی (cm)');
    bool hasHandle = _selectedHandleType == 'دارد';
    String doorType = _selectedDoorType4;
    String wallType = _selectedWallType;

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'سقف'
    });
    rowCounter++;

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '1',
      'طول': (length - 3.2).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'طبقه'
    });
    rowCounter++;

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '2',
      'طول': (height - 1.6).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل'
    });
    rowCounter++;

    if (hasHandle && beam > 0) {
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': '1',
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': beam.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'تیرک'
      });
      rowCounter++;
    }

    List<Map<String, dynamic>> foamData = [];
    int foamRow = 1;
    
    foamData.add({
      'ردیف': foamRow.toString(),
      'تعداد': '2',
      'طول': (length - 3.2).toStringAsFixed(1),
      'PVC': '2',
      'عرض': beam.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'تیرک فومیز'
    });
    foamRow++;

    if (wallType == 'فومیز 16 میل') {
      foamData.add({
        'ردیف': foamRow.toString(),
        'تعداد': '1',
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': (height - topFloorHeight).toStringAsFixed(1),
        'PVC2': '-',
        'توضیحات': 'دیواره پشت آبچک'
      });
      foamRow++;
    }

    _floorTableData.add({
      'ردیف': '1',
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'عرض': topFloorHeight.toStringAsFixed(0),
      'توضیحات': 'سه میل پشت طبقه'
    });

    if (wallType == 'سه میل فومیز') {
      _floorTableData.add({
        'ردیف': '2',
        'تعداد': '1',
        'طول': length.toStringAsFixed(0),
        'عرض': (height - topFloorHeight).toStringAsFixed(1),
        'توضیحات': 'سه میل فومیز'
      });
    }

    for (var row in foamData) {
      _tableData.add(row);
    }

    if (!hasHandle) {
      if (doorType == 'درب معمولی') {
        _doorTableData.add({
          'ردیف': '1',
          'تعداد': '2',
          'طول': height.toStringAsFixed(0),
          'PVC': '2',
          'عرض': ((length / 2) - 0.3).toStringAsFixed(1),
          'PVC2': '2',
          'توضیحات': 'درب ساده'
        });
      } else {
        _doorTableData.add({
          'ردیف': '1',
          'تعداد': '2',
          'طول': length.toStringAsFixed(0),
          'PVC': '2',
          'عرض': ((height / 2) - 0.4).toStringAsFixed(1),
          'PVC2': '2',
          'توضیحات': 'درب جکی'
        });
      }
    } else {
      if (doorType == 'درب معمولی') {
        _doorTableData.add({
          'ردیف': '1',
          'تعداد': '2',
          'طول': (height + 2).toStringAsFixed(0),
          'PVC': '2',
          'عرض': ((length / 2) - 0.3).toStringAsFixed(1),
          'PVC2': '2',
          'توضیحات': 'درب ساده'
        });
      } else {
        _doorTableData.add({
          'ردیف': '1',
          'تعداد': '2',
          'طول': length.toStringAsFixed(0),
          'PVC': '2',
          'عرض': ((height + 2) / 2).toStringAsFixed(1),
          'PVC2': '2',
          'توضیحات': 'درب جکی'
        });
      }
    }
  }

  void _calculateCabinet5(double length, double width, double height) {
    _tableData = [];
    _doorTableData = [];
    _floorTableData = [];
    
    int rowCounter = 1;
    double beam = _getControllerDouble('عرض تیرک (cm)');
    String doorCount = _selectedDoorCount5;
    bool hasHandle = _selectedHandleType == 'دارد';

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '5',
      'طول': (length - 3.2).toStringAsFixed(1),
      'PVC': '1',
      'عرض': beam.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'تیرک'
    });
    rowCounter++;

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '2',
      'طول': height.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل'
    });

    double doorHeight = hasHandle ? height + 2 : height;
    double doorWidth = doorCount == '1' ? length - 0.3 : (length / 2) - 0.3;
    
    _doorTableData.add({
      'ردیف': '1',
      'تعداد': doorCount,
      'طول': doorHeight.toStringAsFixed(1),
      'PVC': '2',
      'عرض': doorWidth.toStringAsFixed(1),
      'PVC2': '2',
      'توضیحات': 'درب ساده'
    });
  }

  void _calculateCabinet6(double length, double width, double height) {
    _tableData = [];
    _doorTableData = [];
    _floorTableData = [];
    
    int rowCounter = 1;
    int floors = _getControllerInt('تعداد طبقه');
    double beam = _getControllerDouble('عرض تیرک (cm)');
    String doorCount = _selectedDoorCount6;
    bool hasHandle = _selectedHandleType == 'دارد';

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '2',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'سقف و کف'
    });
    rowCounter++;

    if (floors > 0) {
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': floors.toString(),
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': width.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'طبقه'
      });
      rowCounter++;
    }

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '2',
      'طول': (height - 3.2).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل'
    });
    rowCounter++;

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '1',
      'طول': (length - 3.2).toStringAsFixed(1),
      'PVC': '1',
      'عرض': beam.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'تیرک'
    });
    rowCounter++;

    _floorTableData.add({
      'ردیف': '1',
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'عرض': height.toStringAsFixed(0),
      'توضیحات': 'سه میل ساده'
    });

    double doorHeight = hasHandle ? height + 2 : height;
    double doorWidth = doorCount == '1' ? length - 0.3 : (length / 2) - 0.3;
    
    _doorTableData.add({
      'ردیف': '1',
      'تعداد': doorCount,
      'طول': doorHeight.toStringAsFixed(1),
      'PVC': '2',
      'عرض': doorWidth.toStringAsFixed(1),
      'PVC2': '2',
      'توضیحات': 'درب ساده'
    });
  }

  void _calculateCabinet7(double length, double width, double height) {
    _tableData = [];
    _doorTableData = [];
    _floorTableData = [];
    
    int rowCounter = 1;
    int floors = _getControllerInt('تعداد طبقه');
    double beam = _getControllerDouble('عرض تیرک (cm)');
    int doorCount = int.tryParse(_selectedDoorCount7) ?? 1;
    bool hasHandle = _selectedHandleType == 'دارد';
    
    double doorHeight1 = _getControllerDouble('ارتفاع درب 1 (cm)');
    double doorHeight2 = _getControllerDouble('ارتفاع درب 2 (cm)');
    double doorHeight3 = _getControllerDouble('ارتفاع درب 3 (cm)');
    double doorHeight4 = _getControllerDouble('ارتفاع درب 4 (cm)');
    List<double> doorHeights = [doorHeight1, doorHeight2, doorHeight3, doorHeight4];

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'کف'
    });
    rowCounter++;

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '1',
      'طول': (length - 3.2).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'سقف'
    });
    rowCounter++;

    if (floors > 0) {
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': floors.toString(),
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': width.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'طبقه'
      });
      rowCounter++;
    }

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '2',
      'طول': (height - 1.6).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل'
    });
    rowCounter++;

    if (beam > 0) {
      int tirkCount = hasHandle ? doorCount + 1 : 1;
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': tirkCount.toString(),
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': beam.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'تیرک'
      });
      rowCounter++;
    }

    _floorTableData.add({
      'ردیف': '1',
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'عرض': height.toStringAsFixed(0),
      'توضیحات': 'سه میل ساده'
    });

    for (int i = 0; i < doorCount && i < doorHeights.length; i++) {
      if (doorHeights[i] > 0) {
        _doorTableData.add({
          'ردیف': (i + 1).toString(),
          'تعداد': '1',
          'طول': doorHeights[i].toStringAsFixed(1),
          'PVC': '2',
          'عرض': (length - 0.3).toStringAsFixed(1),
          'PVC2': '2',
          'توضیحات': 'درب'
        });
      }
    }
  }

  void _calculateCabinet8(double length, double width, double height) {
    _tableData = [];
    _doorTableData = [];
    _floorTableData = [];
    
    int rowCounter = 1;
    double beam = _getControllerDouble('عرض تیرک (cm)');
    int doorCount = int.tryParse(_selectedDoorCount8) ?? 1;
    bool hasHandle = _selectedHandleType == 'دارد';

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '2',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'سقف و کف'
    });
    rowCounter++;

    _tableData.add({
      'ردیف': rowCounter.toString(),
      'تعداد': '2',
      'طول': (height - 3.2).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل'
    });
    rowCounter++;

    if (doorCount > 2 && beam > 0) {
      _tableData.add({
        'ردیف': rowCounter.toString(),
        'تعداد': '2',
        'طول': (height - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': beam.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'تیرک'
      });
      rowCounter++;
    }

    _floorTableData.add({
      'ردیف': '1',
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'عرض': height.toStringAsFixed(0),
      'توضیحات': 'سه میل ساده'
    });

    double doorHeight = hasHandle ? height + 2 : height;
    double doorWidth;
    if (doorCount == 1) doorWidth = length - 0.3;
    else if (doorCount == 2) doorWidth = (length / 2) - 0.3;
    else if (doorCount == 3) doorWidth = (length / 3) - 0.3;
    else doorWidth = (length / 4) - 0.3;
    
    _doorTableData.add({
      'ردیف': '1',
      'تعداد': doorCount.toString(),
      'طول': doorHeight.toStringAsFixed(1),
      'PVC': '2',
      'عرض': doorWidth.toStringAsFixed(1),
      'PVC2': '2',
      'توضیحات': 'درب ساده'
    });
  }

  void _calculateDefaultCabinet(double length, double width, double height) {
    _tableData = [];
    _doorTableData = [];
    _floorTableData = [];
    _tableData.add({
      'ردیف': '1',
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'کف',
    });
    _tableData.add({
      'ردیف': '2',
      'تعداد': '2',
      'طول': (height - 1.6).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل',
    });
  }

  // ==============================
  // توابع ذخیره‌سازی
  // ==============================
  Future<void> _saveDesignAutomatically() async {
    final length = _getControllerDouble('طول');
    final width = _getControllerDouble('عرض (عمق)');
    final height = _getControllerDouble('ارتفاع');
    
    if (length > 0 || width > 0 || height > 0) {
      await _saveDesignToDatabase(closeAfterSave: false);
    }
  }

  Future<void> _saveDesignManually() async {
    if (!isActiveCabinet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏳ این کمد در حال توسعه است.'), backgroundColor: Colors.orange),
      );
      return;
    }
    setState(() => _isLoading = true);
    await _saveDesignToDatabase(closeAfterSave: true);
    setState(() => _isLoading = false);
  }

  Future<void> _saveDesignToDatabase({bool closeAfterSave = false}) async {
    try {
      final length = _getControllerDouble('طول');
      final width = _getControllerDouble('عرض (عمق)');
      final height = _getControllerDouble('ارتفاع');
      
      if (length <= 0 && width <= 0 && height <= 0 && !closeAfterSave) {
        return;
      }
      
      String notes = _buildNotes();
      
      final existing = await LocalDatabaseService.query(
        'project_cabinets',
        where: 'project_id = ? AND cabinet_id = ?',
        whereArgs: [int.parse(widget.projectId), int.parse(widget.cabinet.id)],
      );

      if (existing.isEmpty) {
        await LocalDatabaseService.insert('project_cabinets', {
          'project_id': int.parse(widget.projectId),
          'cabinet_id': int.parse(widget.cabinet.id),
          'length': length,
          'width': width,
          'height': height,
          'floors': _getControllerInt('تعداد طبقات') + _getControllerInt('تعداد طبقه'),
          'notes': notes,
        });
      } else {
        await LocalDatabaseService.update(
          'project_cabinets',
          {
            'length': length,
            'width': width,
            'height': height,
            'floors': _getControllerInt('تعداد طبقات') + _getControllerInt('تعداد طبقه'),
            'notes': notes,
          },
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      }

      if (closeAfterSave) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ طراحی کمد شماره ${widget.cabinetNumber} ذخیره شد'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (closeAfterSave) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveDesignOnExit() async {
    final length = _getControllerDouble('طول');
    final width = _getControllerDouble('عرض (عمق)');
    final height = _getControllerDouble('ارتفاع');
    
    if (length > 0 || width > 0 || height > 0) {
      await _saveDesignToDatabase(closeAfterSave: false);
    }
  }

  String _buildNotes() {
    String notes = '';
    
    switch (widget.cabinetNumber) {
      case 1:
        notes = 'تعداد درب:$_selectedDoorType - دستگیره:$_selectedHandleType - سه میل:$_selectedThreeMeterType';
        break;
      case 2:
        notes = 'تعداد درب:$_selectedDoorType - دستگیره:$_selectedHandleType - سه میل:$_selectedThreeMeterType';
        break;
      case 3:
        notes = 'تعداد کشو:$_selectedDrawerCount - کشوی مخفی:$_selectedHiddenDrawer - نوع کفی کشو:$_selectedFloorType - دستگیره:$_selectedHandleType';
        String drawerDepth = _getControllerValue('عمق کشوی مخفی (cm)');
        if (drawerDepth.isNotEmpty) notes += ' - عمق کشوی مخفی:$drawerDepth';
        String drawerGap = _getControllerValue('فاصله بین کشوها (cm)');
        if (drawerGap.isNotEmpty) notes += ' - فاصله بین کشوها:$drawerGap';
        break;
      case 4:
        notes = 'نوع درب:$_selectedDoorType4 - نوع دیواره پشت آبچک:$_selectedWallType - دستگیره:$_selectedHandleType';
        break;
      case 5:
        notes = 'تعداد درب:$_selectedDoorCount5 - دستگیره:$_selectedHandleType';
        break;
      case 6:
        notes = 'تعداد درب:$_selectedDoorCount6 - دستگیره:$_selectedHandleType';
        String floors = _getControllerValue('تعداد طبقه');
        if (floors.isNotEmpty) notes += ' - طبقه:$floors';
        break;
      case 7:
        notes = 'تعداد درب:$_selectedDoorCount7 - دستگیره:$_selectedHandleType';
        String floors7 = _getControllerValue('تعداد طبقه');
        if (floors7.isNotEmpty) notes += ' - طبقه:$floors7';
        String dh1 = _getControllerValue('ارتفاع درب 1 (cm)');
        if (dh1.isNotEmpty) notes += ' - ارتفاع درب 1:$dh1';
        String dh2 = _getControllerValue('ارتفاع درب 2 (cm)');
        if (dh2.isNotEmpty) notes += ' - ارتفاع درب 2:$dh2';
        String dh3 = _getControllerValue('ارتفاع درب 3 (cm)');
        if (dh3.isNotEmpty) notes += ' - ارتفاع درب 3:$dh3';
        String dh4 = _getControllerValue('ارتفاع درب 4 (cm)');
        if (dh4.isNotEmpty) notes += ' - ارتفاع درب 4:$dh4';
        break;
      case 8:
        notes = 'تعداد درب:$_selectedDoorCount8 - دستگیره:$_selectedHandleType';
        break;
    }
    
    String beamValue = _getControllerValue('عرض تیرک (cm)');
    if (beamValue.isNotEmpty) notes += ' - تیرک:$beamValue';
    
    return notes;
  }

  double _calculateVolume() {
    return _getControllerDouble('طول') * _getControllerDouble('عرض (عمق)') * _getControllerDouble('ارتفاع');
  }

  // ==============================
  // ✅ تابع دریافت مسیر عکس
  // ==============================
  String _getLocalImagePath() {
    return 'assets/images/cabinet_${widget.cabinetNumber}.png';
  }

  // ==============================
  // توابع UI
  // ==============================
  Widget _buildDynamicInputField(String label, Color color) {
    final controller = _controllers[label];
    if (controller == null) return const SizedBox.shrink();
    return _buildSmallInputField(label, controller, color);
  }

  Widget _buildSmallInputFieldNoLabel(String label, TextEditingController controller, Color color, {bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: enabled ? color.withOpacity(0.1) : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? color : Colors.grey[400]!,
              width: enabled ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              hintText: '0',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: enabled ? color : Colors.grey[400],
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (value) { setState(() {}); },
          ),
        ),
      ],
    );
  }

  Widget _buildSmallInputField(String label, TextEditingController controller, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color, width: 2)),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), hintText: '0', hintStyle: TextStyle(color: Colors.grey, fontSize: 13)),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (value) { setState(() {}); },
          ),
        ),
      ],
    );
  }

  Widget _buildRadioGroup({
    required String label,
    required List<String> options,
    required String selectedValue,
    required Color color,
    required Function(String) onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700]))),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: options.map((option) {
              final isSelected = selectedValue == option;
              return GestureDetector(
                onTap: () => onChanged(option),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? color : Colors.grey[400]!, width: 2),
                      ),
                      child: isSelected ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color))) : null,
                    ),
                    const SizedBox(width: 4),
                    Text(option, style: TextStyle(fontSize: 12, color: isSelected ? color : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    const SizedBox(width: 8),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTableWidget({
    required String title,
    required List<Map<String, dynamic>> data,
    required List<String> columns,
    required List<double> columnWidths,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(padding: const EdgeInsets.all(8.0), child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1), borderRadius: BorderRadius.circular(4)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.black, width: 1, style: BorderStyle.solid),
                columnWidths: {for (int i = 0; i < columnWidths.length; i++) i: FixedColumnWidth(columnWidths[i])},
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[300]),
                    children: columns.map((col) => Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(col, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    )).toList(),
                  ),
                  ...data.map((row) => TableRow(
                    children: columns.map((col) {
                      String value = '';
                      if (col == 'ردیف') value = row['ردیف'] ?? '';
                      else if (col == 'تعداد') value = row['تعداد'] ?? '';
                      else if (col == 'طول') value = row['طول'] ?? '';
                      else if (col == 'PVC') value = row['PVC'] ?? '';
                      else if (col == 'عرض') value = row['عرض'] ?? '';
                      else if (col == 'PVC2') value = row['PVC2'] ?? '';
                      else if (col == 'توضیحات') value = row['توضیحات'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: col == 'تعداد' ? FontWeight.bold : FontWeight.normal)),
                      );
                    }).toList(),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnderDevelopmentContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('⏳ در حال توسعه', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('کمد شماره ${widget.cabinetNumber} (${widget.cabinet.name}) به زودی اضافه می‌شود', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
        ],
      ),
    );
  }

  String _getFloorTableTitle(bool isCabinet3) {
    if (isCabinet3) {
      return _selectedFloorType == 'هشت میل' ? 'جدول هشت میل' : 'جدول سه میل ساده';
    }
    if (widget.cabinetNumber == 2) {
      return 'جدول سه میل فومیز';
    }
    return 'جدول سه میل ساده';
  }

  @override
  void dispose() {
    _saveDesignOnExit();
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = const Color(0xFF1565C0);
    final config = _config;

    if (!isActiveCabinet || config == null) {
      return Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          title: Text('کمد شماره ${widget.cabinetNumber} - در حال توسعه'),
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: _buildUnderDevelopmentContent(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('طراحی کمد شماره ${widget.cabinetNumber}'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _isLoading ? null : _saveDesignManually,
            tooltip: 'ذخیره طراحی (دستی)',
          ),
        ],
      ),
      body: _buildCabinetContent(color, config),
    );
  }

  Widget _buildCabinetContent(Color color, CabinetConfigModel config) {
    final bool isCabinet1 = config.number == 1;
    final bool isCabinet2 = config.number == 2;
    final bool isCabinet3 = config.number == 3;
    final bool isCabinet4 = config.number == 4;
    final bool isCabinet5 = config.number == 5;
    final bool isCabinet6 = config.number == 6;
    final bool isCabinet7 = config.number == 7;
    final bool isCabinet8 = config.number == 8;
    
    final bool showFloors = isCabinet1 || isCabinet6 || isCabinet7;
    final bool showColumnBeam = isCabinet1;
    final bool showDrawerFields = isCabinet3;
    final bool showThreeMeter = isCabinet1 || isCabinet2 || isCabinet6 || isCabinet7 || isCabinet8;
    final bool showDoorCount5 = isCabinet5;
    final bool showDoorCount6 = isCabinet6;
    final bool showDoorCount7 = isCabinet7;
    final bool showDoorCount8 = isCabinet8;
    final bool showDoorOptions = isCabinet1 || isCabinet2;
    final bool showDoorType4 = isCabinet4;
    final bool showWallType = isCabinet4;
    final bool showTopFloorHeight = isCabinet4;
    final bool showDoorHeightFields = isCabinet7;
    
    bool isHiddenDrawerSelected = _selectedHiddenDrawer == 'دارد';
    bool isDrawerCountDisabled = isCabinet3 && isHiddenDrawerSelected;
    
    int doorCount7 = int.tryParse(_selectedDoorCount7) ?? 1;
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'طراحی کمد شماره ${widget.cabinetNumber}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.cabinet.name,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),

                // ==============================
                // ✅ نمایش عکس کمد (بزرگ و مربعی)
                // ==============================
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        _getLocalImagePath(),
                        fit: BoxFit.contain,
                        width: 240,
                        height: 240,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 56,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'عکس کمد ${widget.cabinetNumber}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'در پوشه assets/images قرار دهید',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(children: [
                  Expanded(child: _buildDynamicInputField('طول', color)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDynamicInputField('عرض (عمق)', color)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDynamicInputField('ارتفاع', color)),
                ]),

                const SizedBox(height: 16),

                Row(children: [
                  if (showFloors) ...[
                    Expanded(child: _buildDynamicInputField(isCabinet1 ? 'تعداد طبقات' : 'تعداد طبقه', color)),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: _buildDynamicInputField('عرض تیرک (cm)', color)),
                  if (showColumnBeam) ...[
                    const SizedBox(width: 12),
                    Expanded(child: _buildDynamicInputField('تیرک لولا', color)),
                  ],
                  if (showDrawerFields) ...[
                    const SizedBox(width: 12),
                    Expanded(child: _buildDynamicInputField('عمق کشوی مخفی (cm)', color)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDynamicInputField('فاصله بین کشوها (cm)', color)),
                  ],
                  if (showTopFloorHeight) ...[
                    const SizedBox(width: 12),
                    Expanded(child: _buildDynamicInputField('ارتفاع طبقه بالایی (cm)', color)),
                  ],
                ]),

                const SizedBox(height: 16),

                if (showDoorHeightFields) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      flex: 2,
                      child: Text('ارتفاع درب‌ها (cm)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSmallInputFieldNoLabel(
                        'ارتفاع درب 1 (cm)',
                        _controllers['ارتفاع درب 1 (cm)']!,
                        color,
                        enabled: doorCount7 >= 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSmallInputFieldNoLabel(
                        'ارتفاع درب 2 (cm)',
                        _controllers['ارتفاع درب 2 (cm)']!,
                        color,
                        enabled: doorCount7 >= 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSmallInputFieldNoLabel(
                        'ارتفاع درب 3 (cm)',
                        _controllers['ارتفاع درب 3 (cm)']!,
                        color,
                        enabled: doorCount7 >= 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSmallInputFieldNoLabel(
                        'ارتفاع درب 4 (cm)',
                        _controllers['ارتفاع درب 4 (cm)']!,
                        color,
                        enabled: doorCount7 >= 4,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                ],

                if (isCabinet3) ...[
                  _buildRadioGroup(
                    label: 'کشوی مخفی',
                    options: _hiddenDrawerOptions,
                    selectedValue: _selectedHiddenDrawer,
                    color: color,
                    onChanged: (value) {
                      setState(() {
                        _selectedHiddenDrawer = value;
                        if (value == 'دارد' && _selectedDrawerCount != '2') {
                          _selectedDrawerCount = '2';
                        }
                      });
                      _saveDesignAutomatically();
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(width: 90, child: Text('تعداد کشو', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey))),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _drawerCountOptions.map((option) {
                            final isSelected = _selectedDrawerCount == option;
                            final isDisabled = isDrawerCountDisabled && option != '2';
                            return GestureDetector(
                              onTap: isDisabled ? null : () {
                                setState(() { _selectedDrawerCount = option; });
                                _saveDesignAutomatically();
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isDisabled ? Colors.grey[300]! : (isSelected ? color : Colors.grey[400]!), width: 2),
                                    ),
                                    child: isSelected && !isDisabled ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color))) : null,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(option, style: TextStyle(fontSize: 12, color: isDisabled ? Colors.grey[400] : (isSelected ? color : Colors.grey[600]), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRadioGroup(
                    label: 'نوع کفی کشو',
                    options: _floorTypeOptions,
                    selectedValue: _selectedFloorType,
                    color: color,
                    onChanged: (value) {
                      setState(() { _selectedFloorType = value; });
                      _saveDesignAutomatically();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (showDoorOptions) ...[
                  _buildRadioGroup(
                    label: 'تعداد درب',
                    options: config.doorOptions,
                    selectedValue: _selectedDoorType,
                    color: color,
                    onChanged: (value) {
                      setState(() { _selectedDoorType = value; });
                      _saveDesignAutomatically();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (showDoorType4) ...[
                  _buildRadioGroup(
                    label: 'نوع درب',
                    options: _doorType4Options,
                    selectedValue: _selectedDoorType4,
                    color: color,
                    onChanged: (value) {
                      setState(() { _selectedDoorType4 = value; });
                      _saveDesignAutomatically();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (showWallType) ...[
                  _buildRadioGroup(
                    label: 'نوع دیواره پشت آبچک',
                    options: _wallTypeOptions,
                    selectedValue: _selectedWallType,
                    color: color,
                    onChanged: (value) {
                      setState(() { _selectedWallType = value; });
                      _saveDesignAutomatically();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (showDoorCount5) ...[
                  _buildRadioGroup(
                    label: 'تعداد درب',
                    options: _doorCountOptions5,
                    selectedValue: _selectedDoorCount5,
                    color: color,
                    onChanged: (value) {
                      setState(() { _selectedDoorCount5 = value; });
                      _saveDesignAutomatically();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (showDoorCount6) ...[
                  _buildRadioGroup(
                    label: 'تعداد درب',
                    options: _doorCountOptions6,
                    selectedValue: _selectedDoorCount6,
                    color: color,
                    onChanged: (value) {
                      setState(() { _selectedDoorCount6 = value; });
                      _saveDesignAutomatically();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (showDoorCount7) ...[
                  _buildRadioGroup(
                    label: 'تعداد درب',
                    options: _doorCountOptions7,
                    selectedValue: _selectedDoorCount7,
                    color: color,
                    onChanged: (value) {
                      setState(() { _selectedDoorCount7 = value; });
                      _saveDesignAutomatically();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (showDoorCount8) ...[
                  _buildRadioGroup(
                    label: 'تعداد درب',
                    options: _doorCountOptions8,
                    selectedValue: _selectedDoorCount8,
                    color: color,
                    onChanged: (value) {
                      setState(() { _selectedDoorCount8 = value; });
                      _saveDesignAutomatically();
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                _buildRadioGroup(
                  label: 'دستگیره مخفی',
                  options: _handleOptions,
                  selectedValue: _selectedHandleType,
                  color: color,
                  onChanged: (value) {
                    setState(() { _selectedHandleType = value; });
                    _saveDesignAutomatically();
                  },
                ),
                const SizedBox(height: 12),

                if (showThreeMeter && !isCabinet3 && !isCabinet4 && !isCabinet5 && !isCabinet7 && !isCabinet8) ...[
                  _buildRadioGroup(
                    label: 'نوع سه میل',
                    options: _threeMeterOptions,
                    selectedValue: _selectedThreeMeterType,
                    color: color,
                    onChanged: (value) {
                      setState(() { _selectedThreeMeterType = value; });
                      _saveDesignAutomatically();
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'محاسبه لیست قطعات',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                if (_hasCalculated && _tableData.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildTableWidget(
                    title: isCabinet2 ? 'لیست قطعات فومیز' : 'لیست قطعات ام دی اف',
                    data: _tableData,
                    columns: const ['ردیف', 'تعداد', 'طول', 'PVC', 'عرض', 'PVC2', 'توضیحات'],
                    columnWidths: const [45, 50, 70, 55, 60, 55, 80],
                  ),
                ],

                if (_hasCalculated && _doorTableData.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildTableWidget(
                    title: isCabinet3 ? 'لیست درب کشو' : 'لیست درب',
                    data: _doorTableData,
                    columns: const ['ردیف', 'تعداد', 'طول', 'PVC', 'عرض', 'PVC2', 'توضیحات'],
                    columnWidths: const [45, 50, 70, 55, 60, 55, 80],
                  ),
                ],

                if (_hasCalculated && _floorTableData.isNotEmpty && (isCabinet1 || isCabinet2 || isCabinet3 || isCabinet6 || isCabinet7 || isCabinet8)) ...[
                  const SizedBox(height: 24),
                  _buildTableWidget(
                    title: _getFloorTableTitle(isCabinet3),
                    data: _floorTableData,
                    columns: const ['ردیف', 'تعداد', 'طول', 'عرض', 'توضیحات'],
                    columnWidths: const [45, 50, 70, 70, 80],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}