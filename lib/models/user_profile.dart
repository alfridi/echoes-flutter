/// Model representing the user's profile in the Echoes Living Dialect Archive.
/// Maps directly to the Supabase `profiles` table.
class UserProfile {
  final String id;
  final String? email;
  final String displayName;
  final String? avatarUrl;
  final String role;
  final String? nativeDialect;
  final int contributionsCount;

  const UserProfile({
    required this.id,
    this.email,
    required this.displayName,
    this.avatarUrl,
    this.role = 'Explorer',
    this.nativeDialect,
    this.contributionsCount = 0,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String?,
      displayName: map['display_name'] as String? ?? 'Dialect Custodian',
      avatarUrl: map['avatar_url'] as String?,
      role: map['role'] as String? ?? 'Explorer',
      nativeDialect: map['native_dialect'] as String?,
      contributionsCount: (map['contributions_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'role': role,
      'native_dialect': nativeDialect,
      'contributions_count': contributionsCount,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? role,
    String? nativeDialect,
    int? contributionsCount,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      nativeDialect: nativeDialect ?? this.nativeDialect,
      contributionsCount: contributionsCount ?? this.contributionsCount,
    );
  }
}
