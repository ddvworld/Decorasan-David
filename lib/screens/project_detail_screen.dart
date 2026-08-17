import 'package:flutter/material.dart';
import '../services/local_database_service.dart';
import '../models/cabinet_model.dart';
import '../models/project_design_model.dart';
import '../data/cabinet_configs.dart';
import 'cabinet_design_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  List<Map<String, dynamic>> _allCabinets = [];
  List<Map<String, dynamic>> _projectCabinets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final allCabinets = await LocalDatabaseService.query('cabinets', orderBy: 'id ASC');
      _allCabinets = allCabinets;
      
      final projectCabinets = await LocalDatabaseService.query(
        'project_cabinets',
        where: 'project_id = ?',
        whereArgs: [widget.projectId],
      );
      _projectCabinets = projectCabinets;
      
      setState(() => _isLoading = false);
      
      print('📊 تعداد کل کمدها: ${_allCabinets.length}');
      print('📊 تعداد کمدهای پروژه: ${_projectCabinets.length}');
      
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ خطا: $e');
    }
  }

  Future<void> _addCabinet(int cabinetId) async {
    try {
      final existing = await LocalDatabaseService.query(
        'project_cabinets',
        where: 'project_id = ? AND cabinet_id = ?',
        whereArgs: [widget.projectId, cabinetId],
      );
      
      if (existing.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ این کمد قبلاً اضافه شده است'), backgroundColor: Colors.orange),
        );
        return;
      }
      
      await LocalDatabaseService.insert('project_cabinets', {
        'project_id': widget.projectId,
        'cabinet_id': cabinetId,
        'length': 0,
        'width': 0,
        'height': 0,
        'floors': 0,
        'notes': '',
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ کمد به پروژه اضافه شد'), backgroundColor: Colors.green),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطا: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _removeCabinet(int id) async {
    try {
      await LocalDatabaseService.delete('project_cabinets', where: 'id = ?', whereArgs: [id]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ کمد از پروژه حذف شد'), backgroundColor: Colors.green),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ خطا: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Map<String, dynamic>? _getCabinetInfo(int cabinetId) {
    try {
      return _allCabinets.firstWhere((c) => c['id'] == cabinetId);
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic>? _getProjectCabinet(int cabinetId) {
    try {
      return _projectCabinets.firstWhere((pc) => pc['cabinet_id'] == cabinetId);
    } catch (e) {
      return null;
    }
  }

  void _showAddCabinetDialog() {
    final availableCabinets = _allCabinets.where((cabinet) {
      final cabinetId = cabinet['id'] as int;
      return !_projectCabinets.any((pc) => pc['cabinet_id'] == cabinetId);
    }).toList();

    if (availableCabinets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ همه کمدها به این پروژه اضافه شده‌اند'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'انتخاب کمد برای اضافه کردن',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${availableCabinets.length} کمد موجود برای اضافه کردن',
                style: const TextStyle(color: Colors.grey),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: availableCabinets.length,
                  itemBuilder: (BuildContext context, int index) {
                    final cabinet = availableCabinets[index];
                    final cabinetId = cabinet['id'] as int;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green[100],
                        child: Text(
                          '$cabinetId',
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),
                      title: Text(cabinet['name'] ?? 'کمد شماره $cabinetId'),
                      subtitle: const Text('برای اضافه کردن کلیک کنید'),
                      trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
                      onTap: () {
                        Navigator.pop(context);
                        _addCabinet(cabinetId);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openCabinetDesign(int cabinetId) {
    final cabinetInfo = _getCabinetInfo(cabinetId);
    final projectCabinet = _getProjectCabinet(cabinetId);
    
    if (cabinetInfo == null || projectCabinet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ اطلاعات کمد یافت نشد'), backgroundColor: Colors.red),
      );
      return;
    }

    final cabinetModel = CabinetModel(
      id: cabinetId.toString(),
      name: cabinetInfo['name'] ?? 'کمد شماره $cabinetId',
      iconName: cabinetInfo['icon_name'] ?? 'cabin',
      colorCode: cabinetInfo['color_code'] ?? '#2196F3',
      imageUrl: cabinetInfo['image_url'],
      imageName: cabinetInfo['image_name'],
      createdAt: DateTime.now(),
    );

    final existingDesign = ProjectDesignModel(
      id: projectCabinet['id'].toString(),
      projectId: widget.projectId.toString(),
      cabinetId: cabinetId.toString(),
      length: (projectCabinet['length'] ?? 0).toDouble(),
      width: (projectCabinet['width'] ?? 0).toDouble(),
      height: (projectCabinet['height'] ?? 0).toDouble(),
      floors: projectCabinet['floors'] ?? 0,
      volume: (projectCabinet['length'] ?? 0) * 
              (projectCabinet['width'] ?? 0) * 
              (projectCabinet['height'] ?? 0),
      notes: projectCabinet['notes'],
      createdAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CabinetDesignScreen(
          projectId: widget.projectId.toString(),
          cabinet: cabinetModel,
          existingDesign: existingDesign,
          cabinetNumber: cabinetId,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('پروژه: ${widget.projectName}'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showAddCabinetDialog,
            tooltip: 'افزودن کمد به پروژه',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projectCabinets.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'هیچ کمدی به این پروژه اضافه نشده',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'برای افزودن کمد، روی دکمه + کلیک کنید',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: _projectCabinets.length,
                    itemBuilder: (BuildContext context, int index) {
                      final projectCabinet = _projectCabinets[index];
                      final cabinetId = projectCabinet['cabinet_id'] as int;
                      final cabinetInfo = _getCabinetInfo(cabinetId);
                      final cabinetName = cabinetInfo?['name'] ?? 'کمد شماره $cabinetId';
                      
                      // ✅ دریافت ابعاد
                      final length = projectCabinet['length'] ?? 0;
                      final width = projectCabinet['width'] ?? 0;
                      final height = projectCabinet['height'] ?? 0;
                      
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.green[700]!, width: 2),
                        ),
                        child: InkWell(
                          onTap: () {
                            _openCabinetDesign(cabinetId);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // شماره کمد
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[700],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'کمد $cabinetId',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                
                                // عکس کمد
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/cabinet_$cabinetId.png',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.cabin,
                                          size: 30,
                                          color: Colors.green[700],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                
                                // ✅ نمایش ابعاد با علامت ×
                                if (length > 0 || width > 0 || height > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${length.toStringAsFixed(0)}×${width.toStringAsFixed(0)}×${height.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'بدون ابعاد',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                
                                const SizedBox(height: 2),
                                
                                // نام کمد
                                Text(
                                  cabinetName,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                
                                // وضعیت طراحی
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[700],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white, size: 10),
                                      SizedBox(width: 2),
                                      Text(
                                        'طراحی شده',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}