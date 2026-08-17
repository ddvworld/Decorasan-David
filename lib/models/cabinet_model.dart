class CabinetModel {
  final String id;
  final String name;
  final String iconName;
  final String colorCode;
  final String? imageUrl;
  final String? imageName;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CabinetModel({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorCode,
    this.imageUrl,
    this.imageName,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  // ✅ تابع دریافت مسیر عکس محلی
  String getLocalImagePath(int cabinetNumber) {
    return 'assets/images/cabinet_$cabinetNumber.png';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'icon_name': iconName,
    'color_code': colorCode,
    'image_url': imageUrl,
    'image_name': imageName,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  factory CabinetModel.fromJson(Map<String, dynamic> json) => CabinetModel(
    id: json['id'].toString(),
    name: json['name'] ?? '',
    iconName: json['icon_name'] ?? 'cabin',
    colorCode: json['color_code'] ?? '#2196F3',
    imageUrl: json['image_url'],
    imageName: json['image_name'],
    createdBy: json['created_by']?.toString(),
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
    updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : null,
  );
}