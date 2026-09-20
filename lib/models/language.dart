/// Dialect language catalog model with Supabase serialization.
/// Maps to the Supabase `languages` table.
class Language {
  final String id;
  final String name;
  final String nativeScript;
  final String isoCode;
  final String branch;
  final String region;
  final String countryEmoji;
  final String summary;
  final int preservedPeopleCount;
  final int verifiedAudioCount;
  final List<String> contributorAvatarUrls;

  const Language({
    required this.id,
    required this.name,
    required this.nativeScript,
    required this.isoCode,
    required this.branch,
    required this.region,
    required this.countryEmoji,
    required this.summary,
    required this.preservedPeopleCount,
    required this.verifiedAudioCount,
    required this.contributorAvatarUrls,
  });

  factory Language.fromMap(Map<String, dynamic> map) {
    return Language(
      id: map['id'] as String,
      name: map['name'] as String,
      nativeScript: map['native_script'] as String? ?? '',
      isoCode: map['iso_code'] as String? ?? '',
      branch: map['branch'] as String? ?? '',
      region: map['region'] as String? ?? '',
      countryEmoji: map['country_emoji'] as String? ?? '🌐',
      summary: map['summary'] as String? ?? '',
      preservedPeopleCount: (map['preserved_people_count'] as num?)?.toInt() ?? 0,
      verifiedAudioCount: (map['verified_audio_count'] as num?)?.toInt() ?? 0,
      contributorAvatarUrls: (map['contributor_avatar_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'native_script': nativeScript,
      'iso_code': isoCode,
      'branch': branch,
      'region': region,
      'country_emoji': countryEmoji,
      'summary': summary,
      'preserved_people_count': preservedPeopleCount,
      'verified_audio_count': verifiedAudioCount,
      'contributor_avatar_urls': contributorAvatarUrls,
    };
  }
}
