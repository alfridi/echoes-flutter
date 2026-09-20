/// Community and custodian dialect voice recording submission model.
/// Maps to the Supabase `echo_recordings` table.
class EchoRecording {
  final String id;
  final String wordId;
  final String languageId;
  final String? contributorId;
  final String contributorName;
  final String contributorAvatarUrl;
  final String audioUrl;
  final Duration duration;
  final String accentTerritory;
  final String acousticFidelity;
  final int upvotesCount;
  final DateTime createdAt;

  const EchoRecording({
    required this.id,
    required this.wordId,
    required this.languageId,
    this.contributorId,
    required this.contributorName,
    required this.contributorAvatarUrl,
    required this.audioUrl,
    required this.duration,
    required this.accentTerritory,
    this.acousticFidelity = 'Pristine',
    this.upvotesCount = 0,
    required this.createdAt,
  });

  factory EchoRecording.fromMap(Map<String, dynamic> map) {
    return EchoRecording(
      id: map['id'] as String,
      wordId: map['word_id'] as String,
      languageId: map['language_id'] as String,
      contributorId: map['contributor_id'] as String?,
      contributorName:
          map['contributor_name'] as String? ?? 'Anonymous Keeper',
      contributorAvatarUrl: map['contributor_avatar_url'] as String? ?? '',
      audioUrl: map['audio_url'] as String,
      duration: Duration(
        milliseconds: (map['duration_ms'] as num?)?.toInt() ?? 0,
      ),
      accentTerritory:
          map['accent_territory'] as String? ?? 'Indigenous Accent',
      acousticFidelity: map['acoustic_fidelity'] as String? ?? 'Pristine',
      upvotesCount: (map['upvotes_count'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word_id': wordId,
      'language_id': languageId,
      if (contributorId != null) 'contributor_id': contributorId,
      'contributor_name': contributorName,
      'contributor_avatar_url': contributorAvatarUrl,
      'audio_url': audioUrl,
      'duration_ms': duration.inMilliseconds,
      'accent_territory': accentTerritory,
      'acoustic_fidelity': acousticFidelity,
      'upvotes_count': upvotesCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
