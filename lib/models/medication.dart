class Medication {
  final String id;
  final String name;
  final String description;
  final String usage;
  final String dosage;
  final List<String> sideEffects;
  final List<String> warnings;
  final List<String> indications;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isVerified;

  Medication({
    required this.id,
    required this.name,
    required this.description,
    required this.usage,
    required this.dosage,
    required this.sideEffects,
    required this.warnings,
    required this.indications,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isVerified = true,
  });

  // Convert from JSON
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      usage: json['usage'] ?? '',
      dosage: json['dosage'] ?? '',
      sideEffects: List<String>.from(json['side_effects'] ?? []),
      warnings: List<String>.from(json['warnings'] ?? []),
      indications: List<String>.from(json['indications'] ?? []),
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      isVerified: json['is_verified'] ?? true,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'usage': usage,
      'dosage': dosage,
      'side_effects': sideEffects,
      'warnings': warnings,
      'indications': indications,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_verified': isVerified,
    };
  }

  // Create copy with updated fields
  Medication copyWith({
    String? id,
    String? name,
    String? description,
    String? usage,
    String? dosage,
    List<String>? sideEffects,
    List<String>? warnings,
    List<String>? indications,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerified,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      usage: usage ?? this.usage,
      dosage: dosage ?? this.dosage,
      sideEffects: sideEffects ?? this.sideEffects,
      warnings: warnings ?? this.warnings,
      indications: indications ?? this.indications,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  String toString() {
    return 'Medication(id: $id, name: $name, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Medication && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Search request model
class SearchRequest {
  final String? medicationName;
  final String? imagePath;
  final List<int>? imageBytes;
  final String? ocrText;
  final String language;

  SearchRequest({
    this.medicationName,
    this.imagePath,
    this.imageBytes,
    this.ocrText,
    this.language = 'tr',
  });

  Map<String, dynamic> toJson() {
    return {
      'medication_name': medicationName,
      'image_path': imagePath,
      'image_bytes': imageBytes,
      'ocr_text': ocrText,
      'language': language,
    };
  }
}
