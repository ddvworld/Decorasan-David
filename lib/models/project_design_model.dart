class ProjectDesignModel {
  final String id;
  final String projectId;
  final String cabinetId;
  final double length;
  final double width;
  final double height;
  final int floors;
  final double volume;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProjectDesignModel({
    required this.id,
    required this.projectId,
    required this.cabinetId,
    required this.length,
    required this.width,
    required this.height,
    required this.floors,
    required this.volume,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'project_id': projectId,
    'cabinet_id': cabinetId,
    'length': length,
    'width': width,
    'height': height,
    'floors': floors,
    'volume': volume,
    'notes': notes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  factory ProjectDesignModel.fromJson(Map<String, dynamic> json) => ProjectDesignModel(
    id: json['id']?.toString() ?? '',
    projectId: json['project_id']?.toString() ?? '',
    cabinetId: json['cabinet_id']?.toString() ?? '',
    length: (json['length'] as num?)?.toDouble() ?? 0,
    width: (json['width'] as num?)?.toDouble() ?? 0,
    height: (json['height'] as num?)?.toDouble() ?? 0,
    floors: json['floors'] as int? ?? 0,
    volume: (json['volume'] as num?)?.toDouble() ?? 0,
    notes: json['notes'],
    createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
    updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : null,
  );
}