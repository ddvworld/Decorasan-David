import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/cabinet_model.dart';
import '../models/project_design_model.dart';
import '../data/cabinet_configs.dart';

class PrintPreviewScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final List<ProjectDesignModel> designs;
  final List<CabinetModel> cabinets;
  final String printType; // 'mdf', 'three_meter', 'door'

  const PrintPreviewScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    required this.designs,
    required this.cabinets,
    required this.printType,
  });

  @override
  State<PrintPreviewScreen> createState() => _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends State<PrintPreviewScreen> {
  List<Map<String, dynamic>> _mdfPrintData = [];
  List<Map<String, dynamic>> _foamPrintData = [];
  List<Map<String, dynamic>> _threeMeterSimplePrintData = [];
  List<Map<String, dynamic>> _threeMeterFoamPrintData = [];
  List<Map<String, dynamic>> _drawerFloorPrintData = [];
  List<Map<String, dynamic>> _doorPrintData = [];

  @override
  void initState() {
    super.initState();
    _buildAllTables();
  }

  // ==============================
  // توابع کمکی محاسباتی (همانند cabinet_design_screen)
  // ==============================
  int _getDoorCount(String doorType) {
    switch (doorType) {
      case 'بدون درب': return 0;
      case 'یک درب': return 1;
      case 'دو درب': return 2;
      case 'سه درب': return 3;
      default: return 2;
    }
  }

  int _getDrawerCount(String drawerCountStr) {
    return int.tryParse(drawerCountStr) ?? 1;
  }

  void _buildAllTables() {
    _mdfPrintData = [];
    _foamPrintData = [];
    _threeMeterSimplePrintData = [];
    _threeMeterFoamPrintData = [];
    _drawerFloorPrintData = [];
    _doorPrintData = [];

    for (var design in widget.designs) {
      if (design.length <= 0 || design.width <= 0 || design.height <= 0) continue;

      final cabinet = widget.cabinets.firstWhere(
        (c) => c.id == design.cabinetId,
        orElse: () => widget.cabinets.first,
      );

      final cabinetNumber = widget.cabinets.indexOf(cabinet) + 1;
      final cabinetName = cabinet.name;
      final config = CabinetConfigs.getConfig(cabinetNumber);

      if (config == null) continue;

      // ==============================
      // استخراج اطلاعات از notes
      // ==============================
      String notes = design.notes ?? '';
      
      // تعداد درب
      int doorCount = 2;
      if (notes.contains('تعداد درب:بدون درب')) doorCount = 0;
      else if (notes.contains('تعداد درب:یک درب')) doorCount = 1;
      else if (notes.contains('تعداد درب:دو درب')) doorCount = 2;
      else if (notes.contains('تعداد درب:سه درب')) doorCount = 3;
      else if (notes.contains('تعداد درب:1')) doorCount = 1;
      else if (notes.contains('تعداد درب:2')) doorCount = 2;
      else if (notes.contains('تعداد درب:3')) doorCount = 3;
      else if (notes.contains('تعداد درب:4')) doorCount = 4;
      
      // دستگیره مخفی
      bool hasHandle = notes.contains('دستگیره: دارد') || notes.contains('دستگیره مخفی:دارد');
      
      // سه میل
      String threeMeterType = 'ساده';
      if (notes.contains('سه میل:فومیز')) threeMeterType = 'فومیز';
      
      // تیرک
      double beam = 0;
      final beamMatch = RegExp(r'تیرک:(\d+\.?\d*)').firstMatch(notes);
      if (beamMatch != null) {
        beam = double.tryParse(beamMatch.group(1) ?? '0') ?? 0;
      }
      
      // تیرک لولا (کمد 1)
      double columnBeam = 0;
      if (cabinetNumber == 1) {
        final columnBeamMatch = RegExp(r'تیرک لولا:(\d+\.?\d*)').firstMatch(notes);
        if (columnBeamMatch != null) {
          columnBeam = double.tryParse(columnBeamMatch.group(1) ?? '0') ?? 0;
        }
      }
      
      // تعداد طبقات (کمد 1, 6, 7)
      int floors = 0;
      if (cabinetNumber == 1) {
        final floorsMatch = RegExp(r'طبقه:(\d+)').firstMatch(notes);
        if (floorsMatch != null) {
          floors = int.tryParse(floorsMatch.group(1) ?? '0') ?? 0;
        }
        if (floors == 0) {
          floors = design.floors;
        }
      } else if (cabinetNumber == 6 || cabinetNumber == 7) {
        final floorsMatch = RegExp(r'طبقه:(\d+)').firstMatch(notes);
        if (floorsMatch != null) {
          floors = int.tryParse(floorsMatch.group(1) ?? '0') ?? 0;
        }
      }
      
      // کمد 3
      int drawerCount = 1;
      String floorType = 'سه میل ساده';
      bool hasHiddenDrawer = false;
      double drawerDepth = 0;
      double drawerGap = 0;
      
      if (cabinetNumber == 3) {
        final drawerCountMatch = RegExp(r'تعداد کشو:(1|2|3|4|5)').firstMatch(notes);
        if (drawerCountMatch != null) {
          drawerCount = int.tryParse(drawerCountMatch.group(1) ?? '1') ?? 1;
        }
        if (notes.contains('کشوی مخفی:دارد')) hasHiddenDrawer = true;
        if (notes.contains('نوع کفی کشو:هشت میل')) floorType = 'هشت میل';
        
        final drawerDepthMatch = RegExp(r'عمق کشوی مخفی:(\d+\.?\d*)').firstMatch(notes);
        if (drawerDepthMatch != null) {
          drawerDepth = double.tryParse(drawerDepthMatch.group(1) ?? '0') ?? 0;
        }
        final drawerGapMatch = RegExp(r'فاصله بین کشوها:(\d+\.?\d*)').firstMatch(notes);
        if (drawerGapMatch != null) {
          drawerGap = double.tryParse(drawerGapMatch.group(1) ?? '0') ?? 0;
        }
      }
      
      // کمد 4
      String doorType4 = 'درب معمولی';
      String wallType = 'سه میل فومیز';
      double topFloorHeight = 0;
      
      if (cabinetNumber == 4) {
        if (notes.contains('نوع درب:درب جکی')) doorType4 = 'درب جکی';
        if (notes.contains('نوع دیواره پشت آبچک:فومیز 16 میل')) wallType = 'فومیز 16 میل';
        final topFloorMatch = RegExp(r'ارتفاع طبقه بالایی:(\d+\.?\d*)').firstMatch(notes);
        if (topFloorMatch != null) {
          topFloorHeight = double.tryParse(topFloorMatch.group(1) ?? '0') ?? 0;
        }
      }
      
      // کمد 7
      double doorHeight1 = 0, doorHeight2 = 0, doorHeight3 = 0, doorHeight4 = 0;
      if (cabinetNumber == 7) {
        final dh1 = RegExp(r'ارتفاع درب 1:(\d+\.?\d*)').firstMatch(notes);
        if (dh1 != null) doorHeight1 = double.tryParse(dh1.group(1) ?? '0') ?? 0;
        final dh2 = RegExp(r'ارتفاع درب 2:(\d+\.?\d*)').firstMatch(notes);
        if (dh2 != null) doorHeight2 = double.tryParse(dh2.group(1) ?? '0') ?? 0;
        final dh3 = RegExp(r'ارتفاع درب 3:(\d+\.?\d*)').firstMatch(notes);
        if (dh3 != null) doorHeight3 = double.tryParse(dh3.group(1) ?? '0') ?? 0;
        final dh4 = RegExp(r'ارتفاع درب 4:(\d+\.?\d*)').firstMatch(notes);
        if (dh4 != null) doorHeight4 = double.tryParse(dh4.group(1) ?? '0') ?? 0;
      }

      // ==============================
      // تولید جداول بر اساس شماره کمد
      // ==============================
      
      // کمد 1
      if (cabinetNumber == 1) {
        _generateCabinet1Data(design, cabinet, cabinetNumber, cabinetName, 
          doorCount, hasHandle, threeMeterType, beam, columnBeam, floors);
      }
      // کمد 2
      else if (cabinetNumber == 2) {
        _generateCabinet2Data(design, cabinet, cabinetNumber, cabinetName,
          doorCount, hasHandle, threeMeterType, beam);
      }
      // کمد 3
      else if (cabinetNumber == 3) {
        _generateCabinet3Data(design, cabinet, cabinetNumber, cabinetName,
          drawerCount, hasHandle, hasHiddenDrawer, floorType, drawerDepth, drawerGap, beam);
      }
      // کمد 4
      else if (cabinetNumber == 4) {
        _generateCabinet4Data(design, cabinet, cabinetNumber, cabinetName,
          doorCount, hasHandle, doorType4, wallType, beam, topFloorHeight);
      }
      // کمد 5
      else if (cabinetNumber == 5) {
        _generateCabinet5Data(design, cabinet, cabinetNumber, cabinetName,
          doorCount, hasHandle, beam);
      }
      // کمد 6
      else if (cabinetNumber == 6) {
        _generateCabinet6Data(design, cabinet, cabinetNumber, cabinetName,
          doorCount, hasHandle, beam, floors);
      }
      // کمد 7
      else if (cabinetNumber == 7) {
        _generateCabinet7Data(design, cabinet, cabinetNumber, cabinetName,
          doorCount, hasHandle, beam, floors, doorHeight1, doorHeight2, doorHeight3, doorHeight4);
      }
      // کمد 8
      else if (cabinetNumber == 8) {
        _generateCabinet8Data(design, cabinet, cabinetNumber, cabinetName,
          doorCount, hasHandle, beam);
      }
    }

    // شماره‌گذاری ردیف‌ها
    _numberRows(_mdfPrintData);
    _numberRows(_foamPrintData);
    _numberRows(_threeMeterSimplePrintData);
    _numberRows(_threeMeterFoamPrintData);
    _numberRows(_drawerFloorPrintData);
    _numberRows(_doorPrintData);
  }

  // ==============================
  // کمد شماره 1
  // ==============================
  void _generateCabinet1Data(
    ProjectDesignModel design,
    CabinetModel cabinet,
    int cabinetNumber,
    String cabinetName,
    int doorCount,
    bool hasHandle,
    String threeMeterType,
    double beam,
    double columnBeam,
    int floors,
  ) {
    double length = design.length;
    double width = design.width;
    double height = design.height;
    
    // MDF
    _mdfPrintData.add({
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'کف',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    if (floors > 0) {
      _mdfPrintData.add({
        'تعداد': floors.toString(),
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': width.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'طبقه',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
    
    _mdfPrintData.add({
      'تعداد': '2',
      'طول': (height - 1.6).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    if (beam > 0) {
      _mdfPrintData.add({
        'تعداد': '3',
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': beam.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'تیرک',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
    
    if (doorCount > 2 && columnBeam > 0) {
      _mdfPrintData.add({
        'تعداد': '2',
        'طول': (height - 1.6).toStringAsFixed(1),
        'PVC': '1',
        'عرض': columnBeam.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'تیرک لولا',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
    
    // سه میل
    _threeMeterSimplePrintData.add({
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'عرض': height.toStringAsFixed(0),
      'توضیحات': threeMeterType,
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    // درب
    if (doorCount > 0) {
      double doorHeight = hasHandle ? height - 3.6 : height;
      double doorWidth;
      if (doorCount == 1) doorWidth = length - 0.3;
      else if (doorCount == 2) doorWidth = (length / 2) - 0.3;
      else doorWidth = (length / 3) - 0.3;
      
      _doorPrintData.add({
        'تعداد': doorCount.toString(),
        'طول': doorHeight.toStringAsFixed(1),
        'PVC': '2',
        'عرض': doorWidth.toStringAsFixed(1),
        'PVC2': '2',
        'توضیحات': 'درب ساده',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
  }

  // ==============================
  // کمد شماره 2
  // ==============================
  void _generateCabinet2Data(
    ProjectDesignModel design,
    CabinetModel cabinet,
    int cabinetNumber,
    String cabinetName,
    int doorCount,
    bool hasHandle,
    String threeMeterType,
    double beam,
  ) {
    double length = design.length;
    double width = design.width;
    double height = design.height;
    
    // فومیز
    _foamPrintData.add({
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'کف',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    _foamPrintData.add({
      'تعداد': '2',
      'طول': (height - 1.6).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    if (beam > 0) {
      _foamPrintData.add({
        'تعداد': '3',
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': beam.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'تیرک',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
    
    // سه میل فومیز
    _threeMeterFoamPrintData.add({
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'عرض': height.toStringAsFixed(0),
      'توضیحات': 'سه میل فومیز',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    // درب
    if (doorCount > 0) {
      double doorHeight = hasHandle ? height - 3.6 : height;
      double doorWidth = doorCount == 1 ? length - 0.3 : (length / 2) - 0.3;
      
      _doorPrintData.add({
        'تعداد': doorCount.toString(),
        'طول': doorHeight.toStringAsFixed(1),
        'PVC': '2',
        'عرض': doorWidth.toStringAsFixed(1),
        'PVC2': '2',
        'توضیحات': 'درب ساده',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
  }

  // ==============================
  // کمد شماره 3
  // ==============================
  void _generateCabinet3Data(
    ProjectDesignModel design,
    CabinetModel cabinet,
    int cabinetNumber,
    String cabinetName,
    int drawerCount,
    bool hasHandle,
    bool hasHiddenDrawer,
    String floorType,
    double drawerDepth,
    double drawerGap,
    double beam,
  ) {
    double length = design.length;
    double width = design.width;
    double height = design.height;
    
    // محاسبه عرض درب کشو
    double x = (drawerCount - 1).toDouble();
    double y = hasHandle ? x * 2 : x * drawerGap;
    double doorDrawerWidth = (height - y) / drawerCount;
    double z = (doorDrawerWidth - 5).floorToDouble();
    
    // MDF
    _mdfPrintData.add({
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'کف',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    _mdfPrintData.add({
      'تعداد': '2',
      'طول': (height - 1.6).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    if (beam > 0) {
      _mdfPrintData.add({
        'تعداد': '3',
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': beam.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'تیرک',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
    
    if (hasHiddenDrawer) {
      double w1 = (floorType == 'هشت میل') ? drawerDepth - 0.8 : drawerDepth;
      double w3 = (floorType == 'هشت میل') ? 15 - 0.8 : 15;
      double w5 = (floorType == 'هشت میل') ? 20 - 0.8 : 20;
      
      _mdfPrintData.add({
        'تعداد': '2',
        'طول': (length - 9).toStringAsFixed(1),
        'PVC': '1',
        'عرض': w1.toStringAsFixed(1),
        'PVC2': '-',
        'توضیحات': 'بدنه کشو مخفی',
        'کمد': '$cabinetNumber - $cabinetName',
      });
      
      _mdfPrintData.add({
        'تعداد': '2',
        'طول': (width - 10).toStringAsFixed(1),
        'PVC': '1',
        'عرض': drawerDepth.toStringAsFixed(1),
        'PVC2': '-',
        'توضیحات': 'بدنه کشو مخفی',
        'کمد': '$cabinetNumber - $cabinetName',
      });
      
      _mdfPrintData.add({
        'تعداد': '2',
        'طول': (length - 9).toStringAsFixed(1),
        'PVC': '1',
        'عرض': w3.toStringAsFixed(1),
        'PVC2': '-',
        'توضیحات': 'بدنه کشو',
        'کمد': '$cabinetNumber - $cabinetName',
      });
      
      _mdfPrintData.add({
        'تعداد': '2',
        'طول': (width - 5).toStringAsFixed(1),
        'PVC': '1',
        'عرض': '15',
        'PVC2': '-',
        'توضیحات': 'بدنه کشو',
        'کمد': '$cabinetNumber - $cabinetName',
      });
      
      _mdfPrintData.add({
        'تعداد': '2',
        'طول': (length - 9).toStringAsFixed(1),
        'PVC': '1',
        'عرض': w5.toStringAsFixed(1),
        'PVC2': '-',
        'توضیحات': 'بدنه کشو',
        'کمد': '$cabinetNumber - $cabinetName',
      });
      
      _mdfPrintData.add({
        'تعداد': '2',
        'طول': (width - 5).toStringAsFixed(1),
        'PVC': '1',
        'عرض': '20',
        'PVC2': '-',
        'توضیحات': 'بدنه کشو',
        'کمد': '$cabinetNumber - $cabinetName',
      });
      
    } else {
      double z2 = (floorType == 'هشت میل') ? z - 0.8 : z;
      
      _mdfPrintData.add({
        'تعداد': (drawerCount * 2).toString(),
        'طول': (length - 9).toStringAsFixed(1),
        'PVC': '1',
        'عرض': z.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'بدنه کشو',
        'کمد': '$cabinetNumber - $cabinetName',
      });
      
      _mdfPrintData.add({
        'تعداد': (drawerCount * 2).toString(),
        'طول': (width - 5).toStringAsFixed(1),
        'PVC': '1',
        'عرض': z2.toStringAsFixed(1),
        'PVC2': '-',
        'توضیحات': 'بدنه کشو',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
    
    // کفی کشو
    if (floorType == 'سه میل ساده') {
      double floorWidth = width - 5;
      double floorLength = length - 9;
      double maxVal = floorLength > floorWidth ? floorLength : floorWidth;
      double minVal = floorLength < floorWidth ? floorLength : floorWidth;
      
      _drawerFloorPrintData.add({
        'تعداد': drawerCount.toString(),
        'طول': maxVal.toStringAsFixed(1),
        'عرض': minVal.toStringAsFixed(1),
        'توضیحات': 'سه میل ساده',
        'کمد': '$cabinetNumber - $cabinetName',
      });
      
      if (hasHiddenDrawer) {
        double hiddenFloorWidth = width - 10;
        double hiddenFloorLength = length - 9;
        double hiddenMax = hiddenFloorLength > hiddenFloorWidth ? hiddenFloorLength : hiddenFloorWidth;
        double hiddenMin = hiddenFloorLength < hiddenFloorWidth ? hiddenFloorLength : hiddenFloorWidth;
        
        _drawerFloorPrintData.add({
          'تعداد': '1',
          'طول': hiddenMax.toStringAsFixed(1),
          'عرض': hiddenMin.toStringAsFixed(1),
          'توضیحات': 'کشوی مخفی - سه میل ساده',
          'کمد': '$cabinetNumber - $cabinetName',
        });
      }
      
    } else {
      double floorWidth8 = width - 5;
      double floorLength8 = length - 12.2;
      double maxVal8 = floorLength8 > floorWidth8 ? floorLength8 : floorWidth8;
      double minVal8 = floorLength8 < floorWidth8 ? floorLength8 : floorWidth8;
      
      _drawerFloorPrintData.add({
        'تعداد': drawerCount.toString(),
        'طول': maxVal8.toStringAsFixed(1),
        'عرض': minVal8.toStringAsFixed(1),
        'توضیحات': 'هشت میل',
        'کمد': '$cabinetNumber - $cabinetName',
      });
      
      if (hasHiddenDrawer) {
        double hiddenFloorWidth8 = width - 10;
        double hiddenFloorLength8 = length - 9;
        double hiddenMax8 = hiddenFloorLength8 > hiddenFloorWidth8 ? hiddenFloorLength8 : hiddenFloorWidth8;
        double hiddenMin8 = hiddenFloorLength8 < hiddenFloorWidth8 ? hiddenFloorLength8 : hiddenFloorWidth8;
        
        _drawerFloorPrintData.add({
          'تعداد': '1',
          'طول': hiddenMax8.toStringAsFixed(1),
          'عرض': hiddenMin8.toStringAsFixed(1),
          'توضیحات': 'کشوی مخفی - هشت میل',
          'کمد': '$cabinetNumber - $cabinetName',
        });
      }
    }
    
    // درب کشو
    _doorPrintData.add({
      'تعداد': drawerCount.toString(),
      'طول': length.toStringAsFixed(0),
      'PVC': '2',
      'عرض': doorDrawerWidth.toStringAsFixed(1),
      'PVC2': '2',
      'توضیحات': 'درب کشو',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    if (hasHiddenDrawer) {
      _doorPrintData.add({
        'تعداد': '1',
        'طول': (length - 3.7).toStringAsFixed(1),
        'PVC': '2',
        'عرض': (drawerDepth + 1).toStringAsFixed(1),
        'PVC2': '2',
        'توضیحات': 'درب کشو مخفی',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
  }

  // ==============================
  // کمد شماره 4
  // ==============================
  void _generateCabinet4Data(
    ProjectDesignModel design,
    CabinetModel cabinet,
    int cabinetNumber,
    String cabinetName,
    int doorCount,
    bool hasHandle,
    String doorType4,
    String wallType,
    double beam,
    double topFloorHeight,
  ) {
    double length = design.length;
    double width = design.width;
    double height = design.height;
    
    // MDF
    _mdfPrintData.add({
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'سقف',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    _mdfPrintData.add({
      'تعداد': '1',
      'طول': (length - 3.2).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'طبقه',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    _mdfPrintData.add({
      'تعداد': '2',
      'طول': (height - 1.6).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    if (hasHandle && beam > 0) {
      _mdfPrintData.add({
        'تعداد': '1',
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': beam.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'تیرک',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
    
    // فومیز
    _foamPrintData.add({
      'تعداد': '2',
      'طول': (length - 3.2).toStringAsFixed(1),
      'PVC': '2',
      'عرض': beam.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'تیرک فومیز',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    if (wallType == 'فومیز 16 میل') {
      _foamPrintData.add({
        'تعداد': '1',
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': (height - topFloorHeight).toStringAsFixed(1),
        'PVC2': '-',
        'توضیحات': 'دیواره پشت آبچک',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
    
    // سه میل ساده
    _threeMeterSimplePrintData.add({
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'عرض': topFloorHeight.toStringAsFixed(0),
      'توضیحات': 'سه میل پشت طبقه',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    // سه میل فومیز
    if (wallType == 'سه میل فومیز') {
      _threeMeterFoamPrintData.add({
        'تعداد': '1',
        'طول': length.toStringAsFixed(0),
        'عرض': (height - topFloorHeight).toStringAsFixed(1),
        'توضیحات': 'سه میل فومیز',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
    
    // درب
    if (!hasHandle) {
      if (doorType4 == 'درب معمولی') {
        _doorPrintData.add({
          'تعداد': '2',
          'طول': height.toStringAsFixed(0),
          'PVC': '2',
          'عرض': ((length / 2) - 0.3).toStringAsFixed(1),
          'PVC2': '2',
          'توضیحات': 'درب ساده',
          'کمد': '$cabinetNumber - $cabinetName',
        });
      } else {
        _doorPrintData.add({
          'تعداد': '2',
          'طول': length.toStringAsFixed(0),
          'PVC': '2',
          'عرض': ((height / 2) - 0.4).toStringAsFixed(1),
          'PVC2': '2',
          'توضیحات': 'درب جکی',
          'کمد': '$cabinetNumber - $cabinetName',
        });
      }
    } else {
      if (doorType4 == 'درب معمولی') {
        _doorPrintData.add({
          'تعداد': '2',
          'طول': (height + 2).toStringAsFixed(0),
          'PVC': '2',
          'عرض': ((length / 2) - 0.3).toStringAsFixed(1),
          'PVC2': '2',
          'توضیحات': 'درب ساده',
          'کمد': '$cabinetNumber - $cabinetName',
        });
      } else {
        _doorPrintData.add({
          'تعداد': '2',
          'طول': length.toStringAsFixed(0),
          'PVC': '2',
          'عرض': ((height + 2) / 2).toStringAsFixed(1),
          'PVC2': '2',
          'توضیحات': 'درب جکی',
          'کمد': '$cabinetNumber - $cabinetName',
        });
      }
    }
  }

  // ==============================
  // کمد شماره 5
  // ==============================
  void _generateCabinet5Data(
    ProjectDesignModel design,
    CabinetModel cabinet,
    int cabinetNumber,
    String cabinetName,
    int doorCount,
    bool hasHandle,
    double beam,
  ) {
    double length = design.length;
    double width = design.width;
    double height = design.height;
    
    // MDF
    _mdfPrintData.add({
      'تعداد': '5',
      'طول': (length - 3.2).toStringAsFixed(1),
      'PVC': '1',
      'عرض': beam.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'تیرک',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    _mdfPrintData.add({
      'تعداد': '2',
      'طول': height.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    // درب
    double doorHeight = hasHandle ? height + 2 : height;
    double doorWidth = doorCount == 1 ? length - 0.3 : (length / 2) - 0.3;
    
    _doorPrintData.add({
      'تعداد': doorCount.toString(),
      'طول': doorHeight.toStringAsFixed(1),
      'PVC': '2',
      'عرض': doorWidth.toStringAsFixed(1),
      'PVC2': '2',
      'توضیحات': 'درب ساده',
      'کمد': '$cabinetNumber - $cabinetName',
    });
  }

  // ==============================
  // کمد شماره 6
  // ==============================
  void _generateCabinet6Data(
    ProjectDesignModel design,
    CabinetModel cabinet,
    int cabinetNumber,
    String cabinetName,
    int doorCount,
    bool hasHandle,
    double beam,
    int floors,
  ) {
    double length = design.length;
    double width = design.width;
    double height = design.height;
    
    // MDF
    _mdfPrintData.add({
      'تعداد': '2',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'سقف و کف',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    if (floors > 0) {
      _mdfPrintData.add({
        'تعداد': floors.toString(),
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': width.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'طبقه',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
    
    _mdfPrintData.add({
      'تعداد': '2',
      'طول': (height - 3.2).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    if (beam > 0) {
      _mdfPrintData.add({
        'تعداد': '1',
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': beam.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'تیرک',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
    
    // سه میل ساده
    _threeMeterSimplePrintData.add({
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'عرض': height.toStringAsFixed(0),
      'توضیحات': 'سه میل ساده',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    // درب
    double doorHeight = hasHandle ? height + 2 : height;
    double doorWidth = doorCount == 1 ? length - 0.3 : (length / 2) - 0.3;
    
    _doorPrintData.add({
      'تعداد': doorCount.toString(),
      'طول': doorHeight.toStringAsFixed(1),
      'PVC': '2',
      'عرض': doorWidth.toStringAsFixed(1),
      'PVC2': '2',
      'توضیحات': 'درب ساده',
      'کمد': '$cabinetNumber - $cabinetName',
    });
  }

  // ==============================
  // کمد شماره 7
  // ==============================
  void _generateCabinet7Data(
    ProjectDesignModel design,
    CabinetModel cabinet,
    int cabinetNumber,
    String cabinetName,
    int doorCount,
    bool hasHandle,
    double beam,
    int floors,
    double doorHeight1,
    double doorHeight2,
    double doorHeight3,
    double doorHeight4,
  ) {
    double length = design.length;
    double width = design.width;
    double height = design.height;
    
    // MDF
    _mdfPrintData.add({
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'کف',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    _mdfPrintData.add({
      'تعداد': '1',
      'طول': (length - 3.2).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'سقف',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    if (floors > 0) {
      _mdfPrintData.add({
        'تعداد': floors.toString(),
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': width.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'طبقه',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
    
    _mdfPrintData.add({
      'تعداد': '2',
      'طول': (height - 1.6).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    if (beam > 0) {
      int tirkCount = hasHandle ? doorCount + 1 : 1;
      _mdfPrintData.add({
        'تعداد': tirkCount.toString(),
        'طول': (length - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': beam.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'تیرک',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
    
    // سه میل ساده
    _threeMeterSimplePrintData.add({
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'عرض': height.toStringAsFixed(0),
      'توضیحات': 'سه میل ساده',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    // درب
    List<double> doorHeights = [doorHeight1, doorHeight2, doorHeight3, doorHeight4];
    for (int i = 0; i < doorCount && i < doorHeights.length; i++) {
      if (doorHeights[i] > 0) {
        _doorPrintData.add({
          'تعداد': '1',
          'طول': doorHeights[i].toStringAsFixed(1),
          'PVC': '2',
          'عرض': (length - 0.3).toStringAsFixed(1),
          'PVC2': '2',
          'توضیحات': 'درب',
          'کمد': '$cabinetNumber - $cabinetName',
        });
      }
    }
  }

  // ==============================
  // کمد شماره 8
  // ==============================
  void _generateCabinet8Data(
    ProjectDesignModel design,
    CabinetModel cabinet,
    int cabinetNumber,
    String cabinetName,
    int doorCount,
    bool hasHandle,
    double beam,
  ) {
    double length = design.length;
    double width = design.width;
    double height = design.height;
    
    // MDF
    _mdfPrintData.add({
      'تعداد': '2',
      'طول': length.toStringAsFixed(0),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'سقف و کف',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    _mdfPrintData.add({
      'تعداد': '2',
      'طول': (height - 3.2).toStringAsFixed(1),
      'PVC': '1',
      'عرض': width.toStringAsFixed(0),
      'PVC2': '-',
      'توضیحات': 'بغل',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    if (doorCount > 2 && beam > 0) {
      _mdfPrintData.add({
        'تعداد': '2',
        'طول': (height - 3.2).toStringAsFixed(1),
        'PVC': '1',
        'عرض': beam.toStringAsFixed(0),
        'PVC2': '-',
        'توضیحات': 'تیرک',
        'کمد': '$cabinetNumber - $cabinetName',
      });
    }
    
    // سه میل ساده
    _threeMeterSimplePrintData.add({
      'تعداد': '1',
      'طول': length.toStringAsFixed(0),
      'عرض': height.toStringAsFixed(0),
      'توضیحات': 'سه میل ساده',
      'کمد': '$cabinetNumber - $cabinetName',
    });
    
    // درب
    double doorHeight = hasHandle ? height + 2 : height;
    double doorWidth;
    if (doorCount == 1) doorWidth = length - 0.3;
    else if (doorCount == 2) doorWidth = (length / 2) - 0.3;
    else if (doorCount == 3) doorWidth = (length / 3) - 0.3;
    else doorWidth = (length / 4) - 0.3;
    
    _doorPrintData.add({
      'تعداد': doorCount.toString(),
      'طول': doorHeight.toStringAsFixed(1),
      'PVC': '2',
      'عرض': doorWidth.toStringAsFixed(1),
      'PVC2': '2',
      'توضیحات': 'درب ساده',
      'کمد': '$cabinetNumber - $cabinetName',
    });
  }

  // ==============================
  // شماره‌گذاری ردیف‌ها
  // ==============================
  void _numberRows(List<Map<String, dynamic>> data) {
    for (int i = 0; i < data.length; i++) {
      data[i]['ردیف'] = (i + 1).toString();
    }
  }

  // ==============================
  // تولید PDF
  // ==============================
  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          List<pw.Widget> children = [];

          children.addAll([
            pw.Text(
              'پروژه: ${widget.projectName}',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'تاریخ: ${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 20),
          ]);

          if (widget.printType == 'mdf') {
            if (_mdfPrintData.isNotEmpty) {
              children.add(_buildPdfTableWithCabinetName(
                title: 'لیست قطعات ام دی اف',
                data: _mdfPrintData,
              ));
            }
            if (_foamPrintData.isNotEmpty) {
              if (children.isNotEmpty) children.add(pw.SizedBox(height: 30));
              children.add(_buildPdfTableWithCabinetName(
                title: 'لیست قطعات فومیز',
                data: _foamPrintData,
              ));
            }
          }

          if (widget.printType == 'three_meter') {
            if (_threeMeterSimplePrintData.isNotEmpty) {
              children.add(_buildPdfTableWithCabinetName(
                title: 'جدول سه میل ساده',
                data: _threeMeterSimplePrintData,
                isThreeMeter: true,
              ));
            }
            if (_threeMeterFoamPrintData.isNotEmpty) {
              if (children.isNotEmpty) children.add(pw.SizedBox(height: 30));
              children.add(_buildPdfTableWithCabinetName(
                title: 'جدول سه میل فومیز',
                data: _threeMeterFoamPrintData,
                isThreeMeter: true,
              ));
            }
            if (_drawerFloorPrintData.isNotEmpty) {
              if (children.isNotEmpty) children.add(pw.SizedBox(height: 30));
              children.add(_buildPdfTableWithCabinetName(
                title: 'جدول کفی کشو',
                data: _drawerFloorPrintData,
                isThreeMeter: true,
              ));
            }
          }

          if (widget.printType == 'door') {
            if (_doorPrintData.isNotEmpty) {
              children.add(_buildPdfTableWithCabinetName(
                title: 'لیست درب‌ها',
                data: _doorPrintData,
              ));
            }
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: children,
          );
        },
      ),
    );

    return pdf;
  }

  // ==============================
  // ساخت جدول PDF
  // ==============================
  pw.Widget _buildPdfTableWithCabinetName({
    required String title,
    required List<Map<String, dynamic>> data,
    bool isThreeMeter = false,
  }) {
    bool hasPVC = data.isNotEmpty && data.first.containsKey('PVC');
    bool hasPVC2 = data.isNotEmpty && data.first.containsKey('PVC2');
    
    List<String> columns = ['کمد', 'ردیف', 'تعداد', 'طول'];
    if (hasPVC) columns.add('PVC');
    columns.add('عرض');
    if (hasPVC2) columns.add('PVC2');
    columns.add('توضیحات');

    List<double> columnWidths = [70, 40, 50, 60];
    if (hasPVC) columnWidths.add(50);
    columnWidths.add(60);
    if (hasPVC2) columnWidths.add(50);
    columnWidths.add(70);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.Text(
            'تعداد کل قطعات: ${data.length}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            for (int i = 0; i < columnWidths.length; i++)
              i: pw.FixedColumnWidth(columnWidths[i]),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              children: columns.map((col) {
                return _buildPdfCell(col, isHeader: true);
              }).toList(),
            ),
            ...data.map((row) {
              return pw.TableRow(
                children: columns.map((col) {
                  String value = '';
                  if (col == 'کمد') {
                    value = row['کمد'] ?? '';
                  } else if (col == 'ردیف') {
                    value = row['ردیف'] ?? '';
                  } else if (col == 'تعداد') value = row['تعداد'] ?? '';
                  else if (col == 'طول') value = row['طول'] ?? '';
                  else if (col == 'PVC') value = row['PVC'] ?? '';
                  else if (col == 'عرض') value = row['عرض'] ?? '';
                  else if (col == 'PVC2') value = row['PVC2'] ?? '';
                  else if (col == 'توضیحات') value = row['توضیحات'] ?? '';
                  return _buildPdfCell(value);
                }).toList(),
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPdfCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6.0),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: isHeader ? 11 : 10,
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ==============================
  // نمایش در برنامه
  // ==============================
  @override
  Widget build(BuildContext context) {
    String title = '';
    int totalCount = 0;

    if (widget.printType == 'mdf') {
      title = 'چاپ لیست قطعات';
      totalCount = _mdfPrintData.length + _foamPrintData.length;
    } else if (widget.printType == 'three_meter') {
      title = 'چاپ جدول سه میل و کفی کشو';
      totalCount = _threeMeterSimplePrintData.length + 
                   _threeMeterFoamPrintData.length + 
                   _drawerFloorPrintData.length;
    } else {
      title = 'چاپ لیست درب‌ها';
      totalCount = _doorPrintData.length;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () async {
              final pdf = await _generatePdf();
              await Printing.layoutPdf(
                onLayout: (PdfPageFormat format) async => pdf.save(),
              );
            },
            tooltip: 'چاپ',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'پروژه: ${widget.projectName}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'تاریخ: ${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'تعداد کل قطعات: $totalCount',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (widget.printType == 'mdf') ...[
                      if (_mdfPrintData.isNotEmpty)
                        _buildPreviewTableWithCabinetName(
                          title: 'لیست قطعات ام دی اف',
                          data: _mdfPrintData,
                        ),
                      if (_foamPrintData.isNotEmpty) ...[
                        const SizedBox(height: 30),
                        _buildPreviewTableWithCabinetName(
                          title: 'لیست قطعات فومیز',
                          data: _foamPrintData,
                        ),
                      ],
                    ],
                    if (widget.printType == 'three_meter') ...[
                      if (_threeMeterSimplePrintData.isNotEmpty)
                        _buildPreviewTableWithCabinetName(
                          title: 'جدول سه میل ساده',
                          data: _threeMeterSimplePrintData,
                          isThreeMeter: true,
                        ),
                      if (_threeMeterFoamPrintData.isNotEmpty) ...[
                        const SizedBox(height: 30),
                        _buildPreviewTableWithCabinetName(
                          title: 'جدول سه میل فومیز',
                          data: _threeMeterFoamPrintData,
                          isThreeMeter: true,
                        ),
                      ],
                      if (_drawerFloorPrintData.isNotEmpty) ...[
                        const SizedBox(height: 30),
                        _buildPreviewTableWithCabinetName(
                          title: 'جدول کفی کشو',
                          data: _drawerFloorPrintData,
                          isThreeMeter: true,
                        ),
                      ],
                    ],
                    if (widget.printType == 'door') ...[
                      if (_doorPrintData.isNotEmpty)
                        _buildPreviewTableWithCabinetName(
                          title: 'لیست درب‌ها',
                          data: _doorPrintData,
                        ),
                    ],
                    if (totalCount == 0) ...[
                      const Center(
                        child: Text(
                          'هیچ داده‌ای برای چاپ وجود ندارد',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTableWithCabinetName({
    required String title,
    required List<Map<String, dynamic>> data,
    bool isThreeMeter = false,
  }) {
    bool hasPVC = data.isNotEmpty && data.first.containsKey('PVC');
    bool hasPVC2 = data.isNotEmpty && data.first.containsKey('PVC2');
    
    List<String> columns = ['کمد', 'ردیف', 'تعداد', 'طول'];
    if (hasPVC) columns.add('PVC');
    columns.add('عرض');
    if (hasPVC2) columns.add('PVC2');
    columns.add('توضیحات');

    List<double> columnWidths = [80, 45, 50, 70];
    if (hasPVC) columnWidths.add(55);
    columnWidths.add(60);
    if (hasPVC2) columnWidths.add(55);
    columnWidths.add(80);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(
                  color: Colors.black,
                  width: 1,
                  style: BorderStyle.solid,
                ),
                columnWidths: {
                  for (int i = 0; i < columnWidths.length; i++)
                    i: FixedColumnWidth(columnWidths[i]),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                    ),
                    children: columns.map((col) {
                      return Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Text(
                          col,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  ...data.map((row) {
                    return TableRow(
                      children: columns.map((col) {
                        String value = '';
                        if (col == 'کمد') {
                          value = row['کمد'] ?? '';
                        } else if (col == 'ردیف') {
                          value = row['ردیف'] ?? '';
                        } else if (col == 'تعداد') value = row['تعداد'] ?? '';
                        else if (col == 'طول') value = row['طول'] ?? '';
                        else if (col == 'PVC') value = row['PVC'] ?? '';
                        else if (col == 'عرض') value = row['عرض'] ?? '';
                        else if (col == 'PVC2') value = row['PVC2'] ?? '';
                        else if (col == 'توضیحات') value = row['توضیحات'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            value,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: col == 'تعداد' ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}