/// Model representing an interactive geographic dialect pin on the Living Atlas.
/// Maps to the Supabase `dialect_pins` table.
class DialectPinModel {
  final String id;
  final String languageId;
  final String languageName;
  final String countryEmoji;
  final double topPercent; // Normalized coordinate (0.0 to 1.0)
  final double leftPercent; // Normalized coordinate (0.0 to 1.0)
  final int echoesCount;
  final bool isFeatured;

  const DialectPinModel({
    required this.id,
    required this.languageId,
    required this.languageName,
    required this.countryEmoji,
    required this.topPercent,
    required this.leftPercent,
    required this.echoesCount,
    this.isFeatured = false,
  });

  factory DialectPinModel.fromMap(Map<String, dynamic> map) {
    return DialectPinModel(
      id: map['id'] as String,
      languageId: map['language_id'] as String,
      languageName: map['language_name'] as String,
      countryEmoji: map['country_emoji'] as String? ?? '📍',
      topPercent: (map['top_percent'] as num).toDouble(),
      leftPercent: (map['left_percent'] as num).toDouble(),
      echoesCount: (map['echoes_count'] as num?)?.toInt() ?? 0,
      isFeatured: map['is_featured'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'language_id': languageId,
      'language_name': languageName,
      'country_emoji': countryEmoji,
      'top_percent': topPercent,
      'left_percent': leftPercent,
      'echoes_count': echoesCount,
      'is_featured': isFeatured,
    };
  }
}
