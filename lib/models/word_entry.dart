/// Preserved dialect word or phrase model with Supabase serialization.
/// Maps to the Supabase `words` table.
class WordEntry {
  final String id;
  final String languageId;
  final String englishWord;
  final String nativeScript;
  final String transliteration;
  final String phoneticIpa;
  final String category;
  final String culturalEtymology;
  final String originTerritory;
  final int availableRecordingsCount;
  final String sampleAudioUrl;
  final Duration duration;
  final String contributorName;
  final String contributorAvatarUrl;

  const WordEntry({
    required this.id,
    required this.languageId,
    required this.englishWord,
    required this.nativeScript,
    required this.transliteration,
    required this.phoneticIpa,
    required this.category,
    required this.culturalEtymology,
    required this.originTerritory,
    required this.availableRecordingsCount,
    required this.sampleAudioUrl,
    required this.duration,
    required this.contributorName,
    required this.contributorAvatarUrl,
  });

  factory WordEntry.fromMap(Map<String, dynamic> map) {
    return WordEntry(
      id: map['id'] as String,
      languageId: map['language_id'] as String,
      englishWord: map['english_word'] as String,
      nativeScript: map['native_script'] as String? ?? '',
      transliteration: map['transliteration'] as String? ?? '',
      phoneticIpa: map['phonetic_ipa'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      culturalEtymology: map['cultural_etymology'] as String? ?? '',
      originTerritory: map['origin_territory'] as String? ?? '',
      availableRecordingsCount:
          (map['available_recordings_count'] as num?)?.toInt() ?? 1,
      sampleAudioUrl: map['sample_audio_url'] as String? ?? '',
      duration: Duration(
        milliseconds: (map['duration_ms'] as num?)?.toInt() ?? 3000,
      ),
      contributorName: map['contributor_name'] as String? ?? 'Archival Voice',
      contributorAvatarUrl: map['contributor_avatar_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'language_id': languageId,
      'english_word': englishWord,
      'native_script': nativeScript,
      'transliteration': transliteration,
      'phonetic_ipa': phoneticIpa,
      'category': category,
      'cultural_etymology': culturalEtymology,
      'origin_territory': originTerritory,
      'available_recordings_count': availableRecordingsCount,
      'sample_audio_url': sampleAudioUrl,
      'duration_ms': duration.inMilliseconds,
      'contributor_name': contributorName,
      'contributor_avatar_url': contributorAvatarUrl,
    };
  }
}
