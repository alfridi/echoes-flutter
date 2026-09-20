# Echoes — Flutter Mobile Architecture & Implementation Guide
> **Living Audio Archive & Dialect Explorer**  
> *Design System: Warm Editorial Resonance*

---

## Table of Contents
1. [Project Overview & Architectural Vision](#1-project-overview--architectural-vision)
2. [Dependencies & `pubspec.yaml`](#2-dependencies--pubspecyaml)
3. [Design System & Theme Engine](#3-design-system--theme-engine)
   - [Color Tokens](#color-tokens)
   - [Typography Hierarchy](#typography-hierarchy)
   - [Radii, Shadows & Elevations](#radii-shadows--elevations)
   - [Complete `AppTheme` Implementation](#complete-apptheme-implementation)
4. [Data Models (with Supabase Serialization)](#4-data-models-with-supabase-serialization)
5. [Supabase Backend Architecture & Database Schema](#5-supabase-backend-architecture--database-schema)
   - [PostgreSQL Relational Schema](#postgresql-relational-schema)
   - [Supabase Storage Configuration (`echoes-audio`)](#supabase-storage-configuration-echoes-audio)
   - [Row-Level Security (RLS) Policies](#row-level-security-rls-policies)
   - [Supabase Client & Service Layer](#supabase-client--service-layer)
   - [Supabase Repositories](#supabase-repositories)
6. [State Management Architecture (`Cubit` & `flutter_bloc`)](#6-state-management-architecture-cubit--flutter_bloc)
   - [Why Cubit for Echoes?](#why-cubit-for-echoes)
   - [Audio Player Cubit (`AudioPlayerCubit`)](#audio-player-cubit-audioplayercubit)
   - [Audio Recorder Cubit (`AudioRecorderCubit`)](#audio-recorder-cubit-audiorecordercubit)
   - [Explore & Atlas Cubit (`ExploreCubit`)](#explore--atlas-cubit-explorecubit)
   - [Authentication Cubit (`AuthCubit`)](#authentication-cubit-authcubit)
7. [Navigation & Routing (`GoRouter`) & Root Bloc Injection](#7-navigation--routing-gorouter--root-bloc-injection)
8. [Screen-by-Screen Flutter Implementations](#8-screen-by-screen-flutter-implementations)
   - [Screen 1: Onboarding (`OnboardingScreen`)](#screen-1-onboarding-onboardingscreen)
   - [Screen 2: World Map & Living Atlas (`WorldMapScreen`)](#screen-2-world-map--living-atlas-worldmapscreen)
   - [Screen 3: Language Detail (`LanguageDetailScreen`)](#screen-3-language-detail-languagedetailscreen)
   - [Screen 4: Word Detail & Acoustic Player (`WordDetailScreen`)](#screen-4-word-detail--acoustic-player-worddetailscreen)
   - [Screen 5: Record Voice Expedition (`RecordVoiceScreen`)](#screen-5-record-voice-expedition-recordvoicescreen)
9. [Tactile Reusable Widgets](#9-tactile-reusable-widgets)
   - [Tactile Soundwave / Equalizer (`TactileWaveformWidget`)](#tactile-soundwave--equalizer-tactilewaveformwidget)
   - [Archival Dialect Pin (`DialectPinWidget`)](#archival-dialect-pin-dialectpinwidget)
   - [Overlapping Community Avatar Stack (`AvatarStackWidget`)](#overlapping-community-avatar-stack-avatarstackwidget)
   - [Echoes Seal / Emblem (`EchoesEmblemWidget`)](#echoes-seal--emblem-echoesemblemwidget)
10. [Audio Services & Supabase Storage Pipeline](#10-audio-services--supabase-storage-pipeline)
11. [Asset Manifest, Environment Configuration & Deployment Checklist](#11-asset-manifest-environment-configuration--deployment-checklist)

---

## 1. Project Overview & Architectural Vision

**Echoes** is an audio-first dialect preservation mobile platform with a **Warm Editorial Resonance** aesthetic. It moves away from sterile tech minimalism in favor of rich paper-tier tactile warmth, classical literary serif typography (**Newsreader**), crisp tabular numerals and micro-labels (**Hanken Grotesk**), and organic acoustic visualizations (deep forest sage and amber gold accents).

### Architectural Philosophy
- **Backend-as-a-Service**: Powered by **Supabase** (PostgreSQL, Row Level Security, Supabase Auth, and Supabase Storage for lossless `.m4a` / AAC archival recordings).
- **State Management**: Orchestrated via **Cubit** (`flutter_bloc`), establishing a clean separation between reactive audio presentation, recording timelines, audio waveform streaming, and Supabase cloud synchronization without verbose event boilerplate.
- **Repository Pattern**: Strict decoupling of data sources (Supabase REST API and Storage SDK) from business logic cubits.

### Architectural Blueprint
```
lib/
├── main.dart
├── core/
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_theme.dart
│   ├── constants/
│   │   ├── app_dimensions.dart
│   │   └── supabase_constants.dart
│   ├── router/
│   │   └── app_router.dart
│   └── services/
│       ├── supabase_service.dart
│       ├── audio_player_service.dart
│       └── audio_recorder_service.dart
├── models/
│   ├── language.dart
│   ├── word_entry.dart
│   ├── echo_recording.dart
│   ├── map_pin.dart
│   └── user_profile.dart
├── repositories/
│   ├── language_repository.dart
│   ├── word_repository.dart
│   └── recording_repository.dart
├── cubits/
│   ├── audio_player/
│   │   ├── audio_player_cubit.dart
│   │   └── audio_player_state.dart
│   ├── audio_recorder/
│   │   ├── audio_recorder_cubit.dart
│   │   └── audio_recorder_state.dart
│   ├── explore/
│   │   ├── explore_cubit.dart
│   │   └── explore_state.dart
│   └── auth/
│       ├── auth_cubit.dart
│       └── auth_state.dart
├── screens/
│   ├── onboarding/
│   │   └── onboarding_screen.dart
│   ├── map/
│   │   ├── world_map_screen.dart
│   │   └── widgets/
│   │       ├── archival_map_canvas.dart
│   │       └── featured_echo_card.dart
│   ├── language/
│   │   └── language_detail_screen.dart
│   ├── word/
│   │   └── word_detail_screen.dart
│   └── record/
│       └── record_voice_screen.dart
└── shared_widgets/
    ├── echoes_emblem.dart
    ├── tactile_waveform.dart
    ├── dialect_pin.dart
    ├── avatar_stack.dart
    └── editorial_bottom_bar.dart
```

---

## 2. Dependencies & `pubspec.yaml`

Add the following packages to your `pubspec.yaml`:

```yaml
name: echoes_audio_archive
description: "Living audio archive and dialect explorer for Flutter."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  
  # Typography & Iconography
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10+1

  # Backend & Cloud Storage
  supabase_flutter: ^2.17.2

  # Navigation & State Management
  go_router: ^14.2.0
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5

  # Audio Playback & Recording
  just_audio: ^0.9.36
  record: ^5.1.2
  audio_session: ^0.1.19
  path_provider: ^2.1.3

  # UI Enhancement & Utilities
  cached_network_image: ^3.3.1
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/vectors/
```

---

## 3. Design System & Theme Engine

### Color Tokens

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

abstract class AppColors {
  // Canvas & Paper Tiers
  static const Color surface = Color(0xFFFBF9F4);
  static const Color surfaceDim = Color(0xFFDBDAD5);
  static const Color surfaceBright = Color(0xFFFBF9F4);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5F4EE);
  static const Color surfaceContainer = Color(0xFFEFEEE9);
  static const Color surfaceContainerHigh = Color(0xFFE9E8E3);
  static const Color surfaceContainerHighest = Color(0xFFE4E2DD);

  // Inks & Typography
  static const Color onSurface = Color(0xFF1B1C19);
  static const Color onSurfaceVariant = Color(0xFF404946);
  static const Color inverseSurface = Color(0xFF30312D);
  static const Color inverseOnSurface = Color(0xFFF2F1EB);
  static const Color outline = Color(0xFF707975);
  static const Color outlineVariant = Color(0xFFC0C8C4);

  // Brand Accents
  static const Color primary = Color(0xFF00372D); // Deep Forest Sage
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1D4E43);
  static const Color onPrimaryContainer = Color(0xFF8DBEB0);
  static const Color primaryFixed = Color(0xFFBAEDDE);
  static const Color primaryFixedDim = Color(0xFF9FD1C2);
  static const Color onPrimaryFixed = Color(0xFF00201A);

  // Amber Focal Accents
  static const Color secondary = Color(0xFF904D00); // Amber Gold
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFFE932C);
  static const Color onSecondaryContainer = Color(0xFF663500);
  static const Color secondaryFixed = Color(0xFFFFDCC3);
  static const Color secondaryFixedDim = Color(0xFFFFB77D);
  static const Color onSecondaryFixed = Color(0xFF2F1500);

  // Tertiary
  static const Color tertiary = Color(0xFF00372D);
  static const Color tertiaryContainer = Color(0xFF005043);
  static const Color tertiaryFixed = Color(0xFFABF0DD);
  static const Color tertiaryFixedDim = Color(0xFF8FD4C1);

  // Semantic
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
  
  // Map Elements
  static const Color mapWaterBase = Color(0xFFE4EFF1);
  static const Color mapLandMass = Color(0xFFEDE7DC);
}
```

### Typography Hierarchy

```dart
// lib/core/theme/app_typography.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract class AppTypography {
  // Display - Literary Titles (Newsreader)
  static TextStyle displayLg = GoogleFonts.newsreader(
    fontSize: 40,
    fontWeight: FontWeight.w500,
    height: 48 / 40,
    letterSpacing: -0.8,
    color: AppColors.onSurface,
  );

  static TextStyle displayLgMobile = GoogleFonts.newsreader(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    height: 40 / 32,
    letterSpacing: -0.32,
    color: AppColors.onSurface,
  );

  // Headlines (Newsreader)
  static TextStyle headlineLg = GoogleFonts.newsreader(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 36 / 28,
    letterSpacing: -0.28,
    color: AppColors.primary,
  );

  static TextStyle headlineMd = GoogleFonts.newsreader(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    color: AppColors.onSurface,
  );

  static TextStyle headlineSm = GoogleFonts.newsreader(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    color: AppColors.onSurface,
  );

  // Body Copy (Newsreader & Hanken Grotesk)
  static TextStyle bodyLg = GoogleFonts.newsreader(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 28 / 18,
    color: AppColors.onSurface,
  );

  static TextStyle bodyMd = GoogleFonts.newsreader(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle bodySm = GoogleFonts.hankenGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    color: AppColors.onSurfaceVariant,
  );

  // Functional Labels & Metrics (Hanken Grotesk with tabular numerals)
  static TextStyle labelLg = GoogleFonts.hankenGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 18 / 14,
    letterSpacing: 0.28,
    color: AppColors.onSurface,
  );

  static TextStyle labelMd = GoogleFonts.hankenGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 16 / 12,
    letterSpacing: 0.48,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle labelSm = GoogleFonts.hankenGrotesk(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 14 / 10,
    letterSpacing: 0.6,
    fontFeatures: const [FontFeature.tabularFigures()],
    color: AppColors.onSurfaceVariant,
  );
}
```

### Radii, Shadows & Elevations

```dart
// lib/core/constants/app_dimensions.dart
import 'package:flutter/material.dart';

abstract class AppRadii {
  static const BorderRadius sm = BorderRadius.all(Radius.circular(4));
  static const BorderRadius md = BorderRadius.all(Radius.circular(8));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(24));
  static const BorderRadius full = BorderRadius.all(Radius.circular(9999));
}

abstract class AppShadows {
  static const List<BoxShadow> paperCard = [
    BoxShadow(
      color: Color.fromRGBO(28, 29, 26, 0.05),
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color.fromRGBO(28, 29, 26, 0.03),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> floatingSheet = [
    BoxShadow(
      color: Color.fromRGBO(27, 28, 25, 0.08),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
```

### Complete `AppTheme` Implementation

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import '../constants/app_dimensions.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.surface,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onPrimary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.tertiaryFixedDim,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface.withOpacity(0.85),
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: AppTypography.headlineSm.copyWith(color: AppColors.primary),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimary,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
          textStyle: AppTypography.labelLg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
```

---

## 4. Data Models (with Supabase Serialization)

```dart
// lib/models/language.dart
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

// lib/models/word_entry.dart
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
      availableRecordingsCount: (map['available_recordings_count'] as num?)?.toInt() ?? 1,
      sampleAudioUrl: map['sample_audio_url'] as String? ?? '',
      duration: Duration(milliseconds: (map['duration_ms'] as num?)?.toInt() ?? 3000),
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

// lib/models/echo_recording.dart
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
      contributorName: map['contributor_name'] as String? ?? 'Anonymous Keeper',
      contributorAvatarUrl: map['contributor_avatar_url'] as String? ?? '',
      audioUrl: map['audio_url'] as String,
      duration: Duration(milliseconds: (map['duration_ms'] as num?)?.toInt() ?? 0),
      accentTerritory: map['accent_territory'] as String? ?? 'Indigenous Accent',
      acousticFidelity: map['acoustic_fidelity'] as String? ?? 'Pristine',
      upvotesCount: (map['upvotes_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
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

// lib/models/map_pin.dart
class DialectPinModel {
  final String id;
  final String languageId;
  final String languageName;
  final String countryEmoji;
  final double topPercent;   // Normalized coordinate (0.0 to 1.0)
  final double leftPercent;  // Normalized coordinate (0.0 to 1.0)
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

// lib/models/user_profile.dart
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
}
```

---

## 5. Supabase Backend Architecture & Database Schema

Supabase acts as the resilient cloud foundation for Echoes:
1. **PostgreSQL** maintains the dialect taxonomy, vocabulary entries, metadata, and dialect pin coordinates.
2. **Supabase Storage (`echoes-audio` bucket)** stores lossless voice recordings in high-fidelity `.m4a` / AAC format.
3. **Supabase Auth** powers anonymous dialect explorer sessions and authenticated voice contributors.
4. **Row-Level Security (RLS)** guarantees read accessibility for global listeners and write protection for dialect recordings.

### PostgreSQL Relational Schema

Run the following SQL migration in your Supabase SQL editor:

```sql
-- 1. Create Profiles Table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  display_name TEXT NOT NULL DEFAULT 'Dialect Custodian',
  avatar_url TEXT,
  role TEXT DEFAULT 'Explorer',
  native_dialect TEXT,
  contributions_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Languages Table
CREATE TABLE IF NOT EXISTS public.languages (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  native_script TEXT NOT NULL,
  iso_code TEXT NOT NULL,
  branch TEXT NOT NULL,
  region TEXT NOT NULL,
  country_emoji TEXT NOT NULL DEFAULT '🌐',
  summary TEXT NOT NULL,
  preserved_people_count INT DEFAULT 0,
  verified_audio_count INT DEFAULT 0,
  contributor_avatar_urls JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create Words Table
CREATE TABLE IF NOT EXISTS public.words (
  id TEXT PRIMARY KEY,
  language_id TEXT NOT NULL REFERENCES public.languages(id) ON DELETE CASCADE,
  english_word TEXT NOT NULL,
  native_script TEXT NOT NULL,
  transliteration TEXT NOT NULL,
  phonetic_ipa TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'Greeting',
  cultural_etymology TEXT NOT NULL,
  origin_territory TEXT NOT NULL,
  available_recordings_count INT DEFAULT 1,
  sample_audio_url TEXT NOT NULL,
  duration_ms INT NOT NULL DEFAULT 3200,
  contributor_name TEXT NOT NULL,
  contributor_avatar_url TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Create Echo Recordings Table (User Community Submissions)
CREATE TABLE IF NOT EXISTS public.echo_recordings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  word_id TEXT NOT NULL REFERENCES public.words(id) ON DELETE CASCADE,
  language_id TEXT NOT NULL REFERENCES public.languages(id) ON DELETE CASCADE,
  contributor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  contributor_name TEXT NOT NULL,
  contributor_avatar_url TEXT NOT NULL,
  audio_url TEXT NOT NULL,
  duration_ms INT NOT NULL,
  accent_territory TEXT NOT NULL,
  acoustic_fidelity TEXT DEFAULT 'Pristine',
  upvotes_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Create Dialect Map Pins Table
CREATE TABLE IF NOT EXISTS public.dialect_pins (
  id TEXT PRIMARY KEY,
  language_id TEXT NOT NULL REFERENCES public.languages(id) ON DELETE CASCADE,
  language_name TEXT NOT NULL,
  country_emoji TEXT NOT NULL DEFAULT '📍',
  top_percent NUMERIC(5, 4) NOT NULL,
  left_percent NUMERIC(5, 4) NOT NULL,
  echoes_count INT DEFAULT 0,
  is_featured BOOLEAN DEFAULT false
);

-- Indexes for lightning-fast queries
CREATE INDEX IF NOT EXISTS idx_words_language_id ON public.words(language_id);
CREATE INDEX IF NOT EXISTS idx_recordings_word_id ON public.echo_recordings(word_id);
CREATE INDEX IF NOT EXISTS idx_pins_featured ON public.dialect_pins(is_featured);
```

### Supabase Storage Configuration (`echoes-audio`)

1. In Supabase Dashboard, navigate to **Storage** and create a new bucket named: `echoes-audio`.
2. Toggle **Public Bucket** to `ON` so audio tracks can stream directly into `just_audio` with zero CDN latency.
3. Apply the Storage Security Policy:

```sql
-- Allow public streaming read access to audio archive
CREATE POLICY "Public Read Audio Bucket"
ON storage.objects FOR SELECT
USING (bucket_id = 'echoes-audio');

-- Allow authenticated users & anonymous guests to upload dialect voice expeditions
CREATE POLICY "Allow Voice Submissions Upload"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'echoes-audio');
```

### Row-Level Security (RLS) Policies

```sql
-- Enable RLS across all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.words ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.echo_recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dialect_pins ENABLE ROW LEVEL SECURITY;

-- 1. Languages & Words (Global Public Read)
CREATE POLICY "Languages are viewable by everyone" ON public.languages FOR SELECT USING (true);
CREATE POLICY "Words are viewable by everyone" ON public.words FOR SELECT USING (true);
CREATE POLICY "Dialect pins are viewable by everyone" ON public.dialect_pins FOR SELECT USING (true);

-- 2. Recordings (Global Public Read, Authenticated / Guest Insert)
CREATE POLICY "Recordings are viewable by everyone" ON public.echo_recordings FOR SELECT USING (true);
CREATE POLICY "Anyone can submit voice recordings" ON public.echo_recordings FOR INSERT WITH CHECK (true);

-- 3. Profiles (Viewable by everyone, editable by owner)
CREATE POLICY "Profiles viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
```

### Supabase Client & Service Layer

```dart
// lib/core/constants/supabase_constants.dart
abstract class SupabaseConstants {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xyzcompany.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
  );

  static const String audioBucket = 'echoes-audio';
}
```

```dart
// lib/core/services/supabase_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  /// Uploads audio recording file to Supabase Storage bucket and returns public stream URL
  Future<String> uploadAudioFile({
    required File file,
    required String wordId,
  }) async {
    final fileName = 'recordings/${wordId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await client.storage.from(SupabaseConstants.audioBucket).upload(
          fileName,
          file,
          fileOptions: const FileOptions(contentType: 'audio/mp4'),
        );
    return client.storage.from(SupabaseConstants.audioBucket).getPublicUrl(fileName);
  }
}
```

### Supabase Repositories

```dart
// lib/repositories/language_repository.dart
import '../core/services/supabase_service.dart';
import '../models/language.dart';
import '../models/map_pin.dart';

abstract class LanguageRepository {
  Future<List<Language>> getLanguages();
  Future<Language> getLanguageById(String id);
  Future<List<DialectPinModel>> getDialectPins();
}

class SupabaseLanguageRepository implements LanguageRepository {
  final SupabaseService _supabase;
  SupabaseLanguageRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService();

  @override
  Future<List<Language>> getLanguages() async {
    final response = await _supabase.client.from('languages').select().order('name');
    return (response as List<dynamic>).map((e) => Language.fromMap(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Language> getLanguageById(String id) async {
    final response = await _supabase.client.from('languages').select().eq('id', id).single();
    return Language.fromMap(response);
  }

  @override
  Future<List<DialectPinModel>> getDialectPins() async {
    final response = await _supabase.client.from('dialect_pins').select();
    return (response as List<dynamic>).map((e) => DialectPinModel.fromMap(e as Map<String, dynamic>)).toList();
  }
}
```

```dart
// lib/repositories/word_repository.dart
import '../core/services/supabase_service.dart';
import '../models/word_entry.dart';

abstract class WordRepository {
  Future<List<WordEntry>> getWordsForLanguage(String languageId);
  Future<WordEntry> getWordDetail(String wordId);
  Future<WordEntry?> getFeaturedWordOfTheDay();
}

class SupabaseWordRepository implements WordRepository {
  final SupabaseService _supabase;
  SupabaseWordRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService();

  @override
  Future<List<WordEntry>> getWordsForLanguage(String languageId) async {
    final response = await _supabase.client
        .from('words')
        .select()
        .eq('language_id', languageId)
        .order('english_word');
    return (response as List<dynamic>).map((e) => WordEntry.fromMap(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<WordEntry> getWordDetail(String wordId) async {
    final response = await _supabase.client.from('words').select().eq('id', wordId).single();
    return WordEntry.fromMap(response);
  }

  @override
  Future<WordEntry?> getFeaturedWordOfTheDay() async {
    final response = await _supabase.client.from('words').select().limit(1).maybeSingle();
    if (response == null) return null;
    return WordEntry.fromMap(response);
  }
}
```

```dart
// lib/repositories/recording_repository.dart
import 'dart:io';
import '../core/services/supabase_service.dart';
import '../models/echo_recording.dart';

abstract class RecordingRepository {
  Future<List<EchoRecording>> getRecordingsForWord(String wordId);
  Future<EchoRecording> uploadAndCreateRecording({
    required File audioFile,
    required String wordId,
    required String languageId,
    required Duration duration,
    required String accentTerritory,
    required String contributorName,
    required String contributorAvatarUrl,
  });
}

class SupabaseRecordingRepository implements RecordingRepository {
  final SupabaseService _supabase;
  SupabaseRecordingRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService();

  @override
  Future<List<EchoRecording>> getRecordingsForWord(String wordId) async {
    final response = await _supabase.client
        .from('echo_recordings')
        .select()
        .eq('word_id', wordId)
        .order('created_at', ascending: false);
    return (response as List<dynamic>)
        .map((e) => EchoRecording.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<EchoRecording> uploadAndCreateRecording({
    required File audioFile,
    required String wordId,
    required String languageId,
    required Duration duration,
    required String accentTerritory,
    required String contributorName,
    required String contributorAvatarUrl,
  }) async {
    // 1. Upload lossless audio to Supabase Storage
    final publicAudioUrl = await _supabase.uploadAudioFile(
      file: audioFile,
      wordId: wordId,
    );

    // 2. Insert record into Postgres echo_recordings table
    final currentUser = _supabase.client.auth.currentUser;
    final row = {
      'word_id': wordId,
      'language_id': languageId,
      'contributor_id': currentUser?.id,
      'contributor_name': contributorName,
      'contributor_avatar_url': contributorAvatarUrl,
      'audio_url': publicAudioUrl,
      'duration_ms': duration.inMilliseconds,
      'accent_territory': accentTerritory,
      'acoustic_fidelity': 'Pristine',
    };

    final inserted = await _supabase.client.from('echo_recordings').insert(row).select().single();

    // 3. Increment word recording counter
    await _supabase.client.rpc('increment_word_recordings', params: {'p_word_id': wordId}).catchError((_) {});

    return EchoRecording.fromMap(inserted);
  }
}
```

---

## 6. State Management Architecture (`Cubit` & `flutter_bloc`)

### Why Cubit for Echoes?
1. **Lightweight & Ergonomic**: Unlike full Blocs requiring boilerplate event classes (`AudioPlayerPlayRequested`, `AudioPlayerSeekRequested`), **Cubit** exposes clean, imperative action methods (`play()`, `seek()`, `togglePhoneticSpeed()`) while maintaining complete immutability.
2. **Audio-Driven Continuous Streams**: Synchronizing audio player position (30ms ticker), dynamic waveform visualization, recording timers, and upload progress maps naturally to Cubit's state emission stream.
3. **Decoupled Testability**: All Supabase calls flow through repository interfaces, making each Cubit 100% unit-testable via `bloc_test`.

---

### Audio Player Cubit (`AudioPlayerCubit`)

Manages audio streaming from Supabase public storage, position scrubber, phonetic slow-speed playback (0.8x), and seamless looping.

```dart
// lib/cubits/audio_player/audio_player_state.dart
import 'package:equatable/equatable.dart';

enum AudioPlayerStatus { idle, loading, playing, paused, completed, error }

class AudioPlaybackState extends Equatable {
  final AudioPlayerStatus status;
  final String? activeTrackId;
  final Duration currentPosition;
  final Duration totalDuration;
  final double playbackSpeed;
  final bool isLooping;
  final String? errorMessage;

  const AudioPlaybackState({
    this.status = AudioPlayerStatus.idle,
    this.activeTrackId,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.isLooping = false,
    this.errorMessage,
  });

  bool get isPlaying => status == AudioPlayerStatus.playing;
  double get progress => totalDuration.inMilliseconds > 0
      ? (currentPosition.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0)
      : 0.0;

  AudioPlaybackState copyWith({
    AudioPlayerStatus? status,
    String? activeTrackId,
    Duration? currentPosition,
    Duration? totalDuration,
    double? playbackSpeed,
    bool? isLooping,
    String? errorMessage,
  }) {
    return AudioPlaybackState(
      status: status ?? this.status,
      activeTrackId: activeTrackId ?? this.activeTrackId,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isLooping: isLooping ?? this.isLooping,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        activeTrackId,
        currentPosition,
        totalDuration,
        playbackSpeed,
        isLooping,
        errorMessage,
      ];
}
```

```dart
// lib/cubits/audio_player/audio_player_cubit.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_player_state.dart';

class AudioPlayerCubit extends Cubit<AudioPlaybackState> {
  final AudioPlayer _player;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;

  AudioPlayerCubit({AudioPlayer? player})
      : _player = player ?? AudioPlayer(),
        super(const AudioPlaybackState()) {
    _bindStreams();
  }

  void _bindStreams() {
    _playerStateSub = _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        emit(state.copyWith(
          status: AudioPlayerStatus.completed,
          currentPosition: state.totalDuration,
        ));
      } else if (playerState.playing) {
        emit(state.copyWith(status: AudioPlayerStatus.playing));
      } else if (playerState.processingState == ProcessingState.ready) {
        emit(state.copyWith(status: AudioPlayerStatus.paused));
      }
    });

    _positionSub = _player.positionStream.listen((pos) {
      emit(state.copyWith(currentPosition: pos));
    });

    _durationSub = _player.durationStream.listen((dur) {
      if (dur != null) {
        emit(state.copyWith(totalDuration: dur));
      }
    });
  }

  /// Plays an audio URL (e.g. from Supabase Storage)
  Future<void> playTrack({required String audioUrl, required String trackId}) async {
    try {
      if (state.activeTrackId == trackId && state.isPlaying) {
        await _player.pause();
        return;
      }
      if (state.activeTrackId == trackId && state.status == AudioPlayerStatus.paused) {
        await _player.play();
        return;
      }

      emit(state.copyWith(
        status: AudioPlayerStatus.loading,
        activeTrackId: trackId,
        currentPosition: Duration.zero,
      ));

      await _player.setUrl(audioUrl);
      await _player.setSpeed(state.playbackSpeed);
      await _player.setLoopMode(state.isLooping ? LoopMode.one : LoopMode.off);
      await _player.play();
    } catch (e) {
      emit(state.copyWith(
        status: AudioPlayerStatus.error,
        errorMessage: 'Playback error: $e',
      ));
    }
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> togglePhoneticSpeed() async {
    final nextSpeed = state.playbackSpeed == 1.0 ? 0.8 : 1.0;
    await _player.setSpeed(nextSpeed);
    emit(state.copyWith(playbackSpeed: nextSpeed));
  }

  Future<void> toggleLoop() async {
    final nextLoop = !state.isLooping;
    await _player.setLoopMode(nextLoop ? LoopMode.one : LoopMode.off);
    emit(state.copyWith(isLooping: nextLoop));
  }

  @override
  Future<void> close() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    return super.close();
  }
}
```

---

### Audio Recorder Cubit (`AudioRecorderCubit`)

Orchestrates microphoned dialect capture, real-time waveform decibel tracking, and direct upload to Supabase Storage + PostgreSQL.

```dart
// lib/cubits/audio_recorder/audio_recorder_state.dart
import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../models/echo_recording.dart';

abstract class AudioRecorderState extends Equatable {
  const AudioRecorderState();

  @override
  List<Object?> get props => [];
}

class RecorderInitial extends AudioRecorderState {
  const RecorderInitial();
}

class RecorderRecording extends AudioRecorderState {
  final int elapsedSeconds;
  final int maxSeconds;
  final double currentAmplitude; // -60.0 to 0.0 dB

  const RecorderRecording({
    required this.elapsedSeconds,
    this.maxSeconds = 5,
    this.currentAmplitude = -30.0,
  });

  double get progress => (elapsedSeconds / maxSeconds).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [elapsedSeconds, maxSeconds, currentAmplitude];
}

class RecorderCaptured extends AudioRecorderState {
  final File file;
  final Duration duration;

  const RecorderCaptured({required this.file, required this.duration});

  @override
  List<Object?> get props => [file.path, duration];
}

class RecorderUploading extends AudioRecorderState {
  final double uploadProgress;
  const RecorderUploading({this.uploadProgress = 0.5});

  @override
  List<Object?> get props => [uploadProgress];
}

class RecorderUploadedSuccess extends AudioRecorderState {
  final EchoRecording recording;
  const RecorderUploadedSuccess(this.recording);

  @override
  List<Object?> get props => [recording];
}

class RecorderFailure extends AudioRecorderState {
  final String error;
  const RecorderFailure(this.error);

  @override
  List<Object?> get props => [error];
}
```

```dart
// lib/cubits/audio_recorder/audio_recorder_cubit.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../repositories/recording_repository.dart';
import 'audio_recorder_state.dart';

class AudioRecorderCubit extends Cubit<AudioRecorderState> {
  final AudioRecorder _recorder;
  final RecordingRepository _recordingRepository;
  Timer? _ticker;
  int _seconds = 0;
  String? _capturedPath;

  AudioRecorderCubit({
    AudioRecorder? recorder,
    required RecordingRepository recordingRepository,
  })  : _recorder = recorder ?? AudioRecorder(),
        _recordingRepository = recordingRepository,
        super(const RecorderInitial());

  Future<void> startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        emit(const RecorderFailure('Microphone permission denied'));
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/echo_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _capturedPath = path;

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 48000,
        ),
        path: path,
      );

      _seconds = 0;
      emit(RecorderRecording(elapsedSeconds: _seconds));

      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) async {
        _seconds++;
        final amp = await _recorder.getAmplitude();
        if (_seconds >= 5) {
          timer.cancel();
          await stopLocalCapture();
        } else {
          emit(RecorderRecording(
            elapsedSeconds: _seconds,
            currentAmplitude: amp.current,
          ));
        }
      });
    } catch (e) {
      emit(RecorderFailure('Failed to start recording: $e'));
    }
  }

  Future<void> stopLocalCapture() async {
    _ticker?.cancel();
    final path = await _recorder.stop();
    final finalPath = path ?? _capturedPath;
    if (finalPath != null && File(finalPath).existsSync()) {
      emit(RecorderCaptured(
        file: File(finalPath),
        duration: Duration(seconds: _seconds),
      ));
    } else {
      emit(const RecorderFailure('Audio file could not be finalized'));
    }
  }

  /// Uploads local recording to Supabase Storage and records metadata
  Future<void> uploadToSupabase({
    required String wordId,
    required String languageId,
    required String accentTerritory,
    required String contributorName,
    required String contributorAvatarUrl,
  }) async {
    final currentState = state;
    if (currentState is! RecorderCaptured) return;

    try {
      emit(const RecorderUploading());
      final recording = await _recordingRepository.uploadAndCreateRecording(
        audioFile: currentState.file,
        wordId: wordId,
        languageId: languageId,
        duration: currentState.duration,
        accentTerritory: accentTerritory,
        contributorName: contributorName,
        contributorAvatarUrl: contributorAvatarUrl,
      );
      emit(RecorderUploadedSuccess(recording));
    } catch (e) {
      emit(RecorderFailure('Supabase upload failed: $e'));
    }
  }

  void reset() {
    _ticker?.cancel();
    emit(const RecorderInitial());
  }

  @override
  Future<void> close() {
    _ticker?.cancel();
    _recorder.dispose();
    return super.close();
  }
}
```

---

### Explore & Atlas Cubit (`ExploreCubit`)

Fetches dialect pins, featured daily word, and manages atlas filtering.

```dart
// lib/cubits/explore/explore_state.dart
import 'package:equatable/equatable.dart';
import '../../models/language.dart';
import '../../models/map_pin.dart';
import '../../models/word_entry.dart';

abstract class ExploreState extends Equatable {
  const ExploreState();

  @override
  List<Object?> get props => [];
}

class ExploreLoading extends ExploreState {
  const ExploreLoading();
}

class ExploreLoaded extends ExploreState {
  final List<DialectPinModel> pins;
  final List<Language> languages;
  final WordEntry? featuredEcho;
  final String activeFilter;

  const ExploreLoaded({
    required this.pins,
    required this.languages,
    this.featuredEcho,
    this.activeFilter = 'All Continents',
  });

  List<DialectPinModel> get filteredPins {
    if (activeFilter == 'All Continents') return pins;
    if (activeFilter == 'Featured') return pins.where((p) => p.isFeatured).toList();
    return pins;
  }

  ExploreLoaded copyWith({
    List<DialectPinModel>? pins,
    List<Language>? languages,
    WordEntry? featuredEcho,
    String? activeFilter,
  }) {
    return ExploreLoaded(
      pins: pins ?? this.pins,
      languages: languages ?? this.languages,
      featuredEcho: featuredEcho ?? this.featuredEcho,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }

  @override
  List<Object?> get props => [pins, languages, featuredEcho, activeFilter];
}

class ExploreError extends ExploreState {
  final String message;
  const ExploreError(this.message);

  @override
  List<Object?> get props => [message];
}
```

```dart
// lib/cubits/explore/explore_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/language_repository.dart';
import '../../repositories/word_repository.dart';
import 'explore_state.dart';

class ExploreCubit extends Cubit<ExploreState> {
  final LanguageRepository _languageRepository;
  final WordRepository _wordRepository;

  ExploreCubit({
    required LanguageRepository languageRepository,
    required WordRepository wordRepository,
  })  : _languageRepository = languageRepository,
        _wordRepository = wordRepository,
        super(const ExploreLoading());

  Future<void> loadAtlasData() async {
    try {
      emit(const ExploreLoading());
      final pinsFuture = _languageRepository.getDialectPins();
      final languagesFuture = _languageRepository.getLanguages();
      final featuredFuture = _wordRepository.getFeaturedWordOfTheDay();

      final results = await Future.wait([pinsFuture, languagesFuture, featuredFuture]);

      emit(ExploreLoaded(
        pins: results[0] as List<DialectPinModel>,
        languages: results[1] as List<Language>,
        featuredEcho: results[2] as WordEntry?,
      ));
    } catch (e) {
      emit(ExploreError('Failed to load dialect atlas: $e'));
    }
  }

  void setFilter(String filter) {
    if (state is ExploreLoaded) {
      emit((state as ExploreLoaded).copyWith(activeFilter: filter));
    }
  }
}
```

---

### Authentication Cubit (`AuthCubit`)

Manages anonymous explorer access and authenticated voice preservation accounts.

```dart
// lib/cubits/auth/auth_cubit.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../models/user_profile.dart';

abstract class EchoesAuthState extends Equatable {
  const EchoesAuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends EchoesAuthState {}
class AuthLoading extends EchoesAuthState {}

class Authenticated extends EchoesAuthState {
  final UserProfile profile;
  final bool isAnonymous;
  const Authenticated({required this.profile, this.isAnonymous = false});
  @override
  List<Object?> get props => [profile, isAnonymous];
}

class Unauthenticated extends EchoesAuthState {}

class AuthCubit extends Cubit<EchoesAuthState> {
  final SupabaseService _supabase;

  AuthCubit({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService(),
        super(AuthInitial());

  Future<void> checkAuth() async {
    final user = _supabase.client.auth.currentUser;
    if (user != null) {
      final profile = await _fetchProfile(user.id, user.email);
      emit(Authenticated(profile: profile, isAnonymous: user.isAnonymous));
    } else {
      // Auto sign-in anonymously so visitors can browse & listen immediately
      await signInAnonymously();
    }
  }

  Future<void> signInAnonymously() async {
    try {
      emit(AuthLoading());
      final res = await _supabase.client.auth.signInAnonymously();
      if (res.user != null) {
        emit(Authenticated(
          profile: UserProfile(
            id: res.user!.id,
            displayName: 'Guest Dialect Explorer',
            role: 'Explorer',
          ),
          isAnonymous: true,
        ));
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<UserProfile> _fetchProfile(String userId, String? email) async {
    try {
      final data = await _supabase.client.from('profiles').select().eq('id', userId).single();
      return UserProfile.fromMap(data);
    } catch (_) {
      return UserProfile(id: userId, email: email, displayName: 'Voice Custodian');
    }
  }
}
```

---

## 7. Navigation & Routing (`GoRouter`) & Root Bloc Injection

### `main.dart` Setup with Supabase & Cubit Providers

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/supabase_constants.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'repositories/language_repository.dart';
import 'repositories/word_repository.dart';
import 'repositories/recording_repository.dart';
import 'cubits/audio_player/audio_player_cubit.dart';
import 'cubits/audio_recorder/audio_recorder_cubit.dart';
import 'cubits/explore/explore_cubit.dart';
import 'cubits/auth/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase Backend
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  // 2. Instantiate Repositories
  final languageRepository = SupabaseLanguageRepository();
  final wordRepository = SupabaseWordRepository();
  final recordingRepository = SupabaseRecordingRepository();

  runApp(
    EchoesApp(
      languageRepository: languageRepository,
      wordRepository: wordRepository,
      recordingRepository: recordingRepository,
    ),
  );
}

class EchoesApp extends StatelessWidget {
  final LanguageRepository languageRepository;
  final WordRepository wordRepository;
  final RecordingRepository recordingRepository;

  const EchoesApp({
    super.key,
    required this.languageRepository,
    required this.wordRepository,
    required this.recordingRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LanguageRepository>.value(value: languageRepository),
        RepositoryProvider<WordRepository>.value(value: wordRepository),
        RepositoryProvider<RecordingRepository>.value(value: recordingRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (ctx) => AuthCubit()..checkAuth()),
          BlocProvider(create: (ctx) => AudioPlayerCubit()),
          BlocProvider(
            create: (ctx) => AudioRecorderCubit(
              recordingRepository: ctx.read<RecordingRepository>(),
            ),
          ),
          BlocProvider(
            create: (ctx) => ExploreCubit(
              languageRepository: ctx.read<LanguageRepository>(),
              wordRepository: ctx.read<WordRepository>(),
            )..loadAtlasData(),
          ),
        ],
        child: MaterialApp.router(
          title: 'Echoes — Dialect Archive',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
```

### Router Definition

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/map/world_map_screen.dart';
import '../../screens/language/language_detail_screen.dart';
import '../../screens/word/word_detail_screen.dart';
import '../../screens/record/record_voice_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/explore',
      builder: (context, state) => const WorldMapScreen(),
    ),
    GoRoute(
      path: '/language/:id',
      builder: (context, state) => LanguageDetailScreen(
        languageId: state.pathParameters['id'] ?? 'malayalam',
      ),
    ),
    GoRoute(
      path: '/word/:id',
      builder: (context, state) => WordDetailScreen(
        wordId: state.pathParameters['id'] ?? 'welcome',
      ),
    ),
    GoRoute(
      path: '/record',
      builder: (context, state) => const RecordVoiceScreen(),
    ),
  ],
);
```

---

## 8. Screen-by-Screen Flutter Implementations

### Screen 1: Onboarding (`OnboardingScreen`)
*Represents `onboarding_echoes/code.html`*

#### Features:
- Archival seal / brand emblem with ripple animation.
- Metric cards: Global Scope (89), Dialects (420+), Folktales (3.1k).
- Playable "Daily Acoustic Tapestry" sample card.
- Primary and secondary navigation buttons.

```dart
// lib/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared_widgets/echoes_emblem.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool isPlayingSample = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Seal & Archival Paper Card
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: AppRadii.xl,
                  boxShadow: AppShadows.paperCard,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withOpacity(0.2),
                        borderRadius: AppRadii.full,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LIVING AUDIO ARCHIVE',
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.secondary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Pulsing Brand Emblem
                    const EchoesEmblemWidget(size: 112),
                    const SizedBox(height: 24),
                    // Title & Motto
                    Text(
                      'ECHOES',
                      style: AppTypography.headlineLg.copyWith(
                        letterSpacing: 3.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '“Every voice carries a story.”',
                      style: AppTypography.bodyMd.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Discover the world\'s languages through the people who speak them. A living global tapestry of accents, dialects, and mother tongues.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySm.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    // Counter Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerHighest,
                        borderRadius: AppRadii.full,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mic, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Text(
                            '14,280 living voices preserved across 89 regions',
                            style: AppTypography.labelMd,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Metric Grid (3 cols)
              Row(
                children: [
                  _buildMetricTile(Icons.public, 'Global Scope', '89', AppColors.primaryContainer),
                  const SizedBox(width: 10),
                  _buildMetricTile(Icons.graphic_eq, 'Dialects', '420+', AppColors.secondary),
                  const SizedBox(width: 10),
                  _buildMetricTile(Icons.auto_stories, 'Folktales', '3.1k', AppColors.primaryContainer),
                ],
              ),
              const SizedBox(height: 16),
              // Daily Acoustic Tapestry Preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: AppRadii.lg,
                  boxShadow: AppShadows.paperCard,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.hearing, color: AppColors.secondary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DAILY ACOUSTIC TAPESTRY', style: AppTypography.labelSm.copyWith(color: AppColors.secondary)),
                          Text('Gaelic Lullaby of Barra', style: AppTypography.headlineSm),
                          Text('Outer Hebrides • 01:42', style: AppTypography.bodySm),
                        ],
                      ),
                    ),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimary,
                      ),
                      onPressed: () => setState(() => isPlayingSample = !isPlayingSample),
                      icon: Icon(isPlayingSample ? Icons.pause : Icons.play_arrow),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // CTAs
              ElevatedButton.icon(
                onPressed: () => context.go('/explore'),
                icon: const Text('Explore Echoes'),
                label: const Icon(Icons.arrow_forward, size: 18),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.record_voice_over, size: 18, color: AppColors.primary),
                label: Text('Already an Echo Keeper? Sign In', style: AppTypography.labelLg.copyWith(color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.surfaceContainer,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text('Curated by phonetic linguists & native heritage speakers', style: AppTypography.bodySm),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile(IconData icon, String label, String value, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: AppRadii.md,
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 4),
            Text(label, style: AppTypography.labelSm),
            const SizedBox(height: 2),
            Text(value, style: AppTypography.headlineSm),
          ],
        ),
      ),
    );
  }
}
```

---

### Screen 2: World Map & Living Atlas (`WorldMapScreen`)
*Represents `world_map_echoes/code.html`*

#### Features:
- Custom parchment map viewport with coordinate lines and geographic landmasses.
- Interactive living pins with animated ripple rings (Kerala, Ainu, Nahuatl, isiXhosa, Javanese, Guugu Yimithirr).
- Interactive filter pills (All Continents, Endangered, Indigenous, Daily Word).
- Featured Echo of the Day card with playable waveform preview.
- Horizontal scroll tray of "Fresh Vocal Dispatches".
- Bottom Navigation Bar with centered tactile Record button.

```dart
// lib/screens/map/world_map_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared_widgets/tactile_waveform.dart';
import '../../shared_widgets/dialect_pin.dart';

class WorldMapScreen extends StatefulWidget {
  const WorldMapScreen({super.key});

  @override
  State<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends State<WorldMapScreen> {
  int selectedTabIndex = 0;
  String activeFilter = 'All Continents';
  bool isPlayingDaily = false;

  final List<String> filters = ['All Continents', 'Endangered', 'Indigenous', 'Daily Word'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer,
              ),
              child: const Icon(Icons.graphic_eq, color: AppColors.primaryFixed, size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Echoes', style: AppTypography.headlineSm.copyWith(color: AppColors.primary)),
                Text('MAP', style: AppTypography.labelSm.copyWith(letterSpacing: 1.1)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Search & Greetings
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Good morning', style: AppTypography.labelMd),
                          const SizedBox(width: 4),
                          const Text('👋'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Explore voices around the world', style: AppTypography.headlineLg),
                      const SizedBox(height: 12),
                      // Search field
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search languages, places, or dialects...',
                          hintStyle: AppTypography.bodySm,
                          prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant),
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadii.sm,
                            ),
                            child: const Icon(Icons.tune, size: 18, color: AppColors.primary),
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceContainer,
                          border: const OutlineInputBorder(
                            borderRadius: AppRadii.lg,
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: filters.map((f) {
                            final isSelected = activeFilter == f;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(f),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.surfaceContainerHigh,
                                labelStyle: AppTypography.labelMd.copyWith(
                                  color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                                ),
                                shape: const RoundedRectangleBorder(borderRadius: AppRadii.full),
                                side: BorderSide.none,
                                onSelected: (_) => setState(() => activeFilter = f),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Interactive Living Map Canvas
                Container(
                  height: 380,
                  width: double.infinity,
                  color: AppColors.mapWaterBase,
                  child: Stack(
                    children: [
                      // Background SVG / Canvas Grid & Continents
                      Positioned.fill(
                        child: CustomPaint(
                          painter: ArchivalMapPainter(),
                        ),
                      ),
                      // Map Overlay Badges
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.9),
                            borderRadius: AppRadii.full,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.explore, size: 16, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text('LIVING ATLAS', style: AppTypography.labelSm),
                            ],
                          ),
                        ),
                      ),
                      // Pin 1: Kerala (Active Highlight)
                      Positioned(
                        top: 190,
                        left: 230,
                        child: DialectPinWidget(
                          countryEmoji: '🇮🇳',
                          dialectName: 'MALAYALAM',
                          echoesCount: 128,
                          isFeatured: true,
                          onTap: () => context.push('/language/malayalam'),
                        ),
                      ),
                      // Pin 2: Japan (Ainu)
                      Positioned(
                        top: 120,
                        left: 310,
                        child: DialectPinWidget(
                          countryEmoji: '🇯🇵',
                          dialectName: 'Ainu',
                          echoesCount: 45,
                          onTap: () {},
                        ),
                      ),
                      // Pin 3: Mexico (Nahuatl)
                      Positioned(
                        top: 170,
                        left: 60,
                        child: DialectPinWidget(
                          countryEmoji: '🇲🇽',
                          dialectName: 'Nahuatl',
                          echoesCount: 68,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
                // Featured Echo of the Day Card (Overlapping)
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: AppRadii.xl,
                        boxShadow: AppShadows.floatingSheet,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.between,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: const BoxDecoration(
                                  color: AppColors.secondaryFixed,
                                  borderRadius: AppRadii.full,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.graphic_eq, size: 14, color: AppColors.onSecondaryFixed),
                                    const SizedBox(width: 4),
                                    Text('FEATURED ECHO OF THE DAY', style: AppTypography.labelSm.copyWith(color: AppColors.onSecondaryFixed)),
                                  ],
                                ),
                              ),
                              Text('Archived 2h ago', style: AppTypography.labelSm),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.between,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                                      const SizedBox(width: 6),
                                      Text('Malayalam', style: AppTypography.headlineSm.copyWith(color: AppColors.primary)),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: const BoxDecoration(
                                          color: AppColors.tertiaryFixed,
                                          borderRadius: AppRadii.sm,
                                        ),
                                        child: Text('Dravidian', style: AppTypography.labelSm),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('Welcome', style: AppTypography.displayLgMobile),
                                      const SizedBox(width: 8),
                                      Text('സ്വാഗതം', style: AppTypography.headlineMd.copyWith(color: AppColors.secondary)),
                                    ],
                                  ),
                                ],
                              ),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: isPlayingDaily ? AppColors.secondary : AppColors.primary,
                                  shape: const RoundedRectangleBorder(borderRadius: AppRadii.lg),
                                ),
                                onPressed: () => setState(() => isPlayingDaily = !isPlayingDaily),
                                icon: Icon(isPlayingDaily ? Icons.pause : Icons.play_arrow, size: 18),
                                label: Text(isPlayingDaily ? 'Playing' : 'Listen (00:05)', style: AppTypography.labelMd),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Soundwave groove
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHighest.withOpacity(0.7),
                              borderRadius: AppRadii.lg,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.between,
                                  children: [
                                    Text('Acoustic Waveform', style: AppTypography.labelSm),
                                    Text('48 kHz · Lossless Vocal', style: AppTypography.labelMd.copyWith(color: AppColors.secondary)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TactileWaveformWidget(
                                  isPlaying: isPlayingDaily,
                                  height: 28,
                                  barCount: 26,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.between,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.record_voice_over, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text('Recorded by Anu · Kerala, India', style: AppTypography.bodySm),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () => context.push('/word/welcome'),
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: Text('Details', style: AppTypography.labelMd.copyWith(color: AppColors.primary)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Fresh Vocal Dispatches Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Text('Fresh Vocal Dispatches', style: AppTypography.headlineSm.copyWith(color: AppColors.primary)),
                      TextButton(onPressed: () {}, child: Text('View archive', style: AppTypography.labelMd.copyWith(color: AppColors.secondary))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 130,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildQuickCard('🇲🇽 Nahuatl', '00:04', 'Tlazohcamati', '"Thank you"', 'By Mateo · Puebla'),
                      const SizedBox(width: 12),
                      _buildQuickCard('🇯🇵 Ainu', '00:06', 'Irankarapte', '"Hello / Touch heart"', 'By Kenji · Hokkaido'),
                      const SizedBox(width: 12),
                      _buildQuickCard('🇿🇦 isiXhosa', '00:03', 'Molo', '"Greetings"', 'By Lindiwe · Cape Town'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildEditorialBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCard(String tag, String duration, String word, String meaning, String author) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppRadii.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: const BoxDecoration(color: AppColors.surface, borderRadius: AppRadii.sm),
                child: Text(tag, style: AppTypography.labelSm),
              ),
              Text(duration, style: AppTypography.labelSm),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(word, style: AppTypography.headlineSm),
              Text('Meaning: $meaning', style: AppTypography.bodySm),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              Text(author, style: AppTypography.labelSm),
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow, size: 16, color: AppColors.onPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditorialBottomBar() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(27, 28, 25, 0.05), blurRadius: 16, offset: Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavTab(0, Icons.public, 'Explore'),
          _buildNavTab(1, Icons.auto_awesome, 'Challenges'),
          // Elevated Center Record Button
          GestureDetector(
            onTap: () => context.push('/record'),
            child: Container(
              width: 52,
              height: 52,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.mic, color: AppColors.onPrimary, size: 26),
            ),
          ),
          _buildNavTab(2, Icons.bookmark, 'Saved'),
          _buildNavTab(3, Icons.person, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label) {
    final isSelected = selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTabIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelMd.copyWith(
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Archival Coordinate Grid & World Outline
class ArchivalMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.outline.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75;

    // Grid pattern
    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Stylized landmass blobs (tactile parchment)
    final landPaint = Paint()
      ..color = AppColors.mapLandMass
      ..style = PaintingStyle.fill;

    // Asia & India silhouette placeholder
    final path = Path()
      ..moveTo(size.width * 0.55, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.25, size.width * 0.75, size.height * 0.4)
      ..lineTo(size.width * 0.7, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.58, size.width * 0.55, size.height * 0.3);
    canvas.drawPath(path, landPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

---

### Screen 3: Language Detail (`LanguageDetailScreen`)
*Represents `language_detail_malayalam/code.html`*

#### Features:
- Heritage catalogue tags & ISO 639-3 identifier.
- Overlapping community contributor avatar stack (`+125`).
- Native Malayalam script typography (`മലയാളം (Kēraḷaṁ)`).
- Vocabulary deck cards with native script, IPA phonetics, and dynamic waveform previews.
- Oral Preservation Drive bottom invitation card.

```dart
// lib/screens/language/language_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../shared_widgets/avatar_stack.dart';
import '../../shared_widgets/tactile_waveform.dart';

class LanguageDetailScreen extends StatelessWidget {
  final String languageId;

  const LanguageDetailScreen({super.key, required this.languageId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Language Detail', style: AppTypography.headlineSm),
            Text('ECHOES ARCHIVE', style: AppTypography.labelSm),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.bookmark_border)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Classification & Breadcrumb
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text('Back to Map', style: AppTypography.labelMd),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainer,
                    side: BorderSide.none,
                    shape: const RoundedRectangleBorder(borderRadius: AppRadii.full),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryFixed,
                    borderRadius: AppRadii.full,
                  ),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('DRAVIDIAN BRANCH', style: AppTypography.labelSm.copyWith(color: AppColors.onSecondaryFixed)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Language Heading
            Row(
              children: [
                const Text('🇮🇳', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text('KERALA · SOUTH INDIA', style: AppTypography.labelMd),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Malayalam', style: AppTypography.headlineLg),
                Text('ISO 639-3: mal', style: AppTypography.labelSm),
              ],
            ),
            Text('മലയാളം (Kēraḷaṁ)', style: AppTypography.headlineMd.copyWith(color: AppColors.secondaryContainer)),
            const SizedBox(height: 8),
            Text(
              'A melodious Dravidian language spoken primarily in Kerala and surrounding regions, celebrated for its poetic tradition and rich vocal inflections.',
              style: AppTypography.bodyMd,
            ),
            const SizedBox(height: 14),
            // Contributor & Preservation Metric Strip
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: AppRadii.lg,
                boxShadow: AppShadows.paperCard,
              ),
              child: Row(
                children: [
                  const AvatarStackWidget(countText: '+125'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Preserved by 128 people', style: AppTypography.labelMd.copyWith(color: AppColors.onSurface)),
                        Text('342 verified audio recordings', style: AppTypography.labelSm),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified, size: 20, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Section Divider
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.surfaceContainerHighest, thickness: 1.5)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.secondaryContainer, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    ],
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.surfaceContainerHighest, thickness: 1.5)),
              ],
            ),
            const SizedBox(height: 16),
            // Vocabulary Deck
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Explore words in this language', style: AppTypography.headlineSm),
                    Text('Listen to nuanced pronunciations recorded by native speakers', style: AppTypography.bodySm),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(color: AppColors.surfaceContainer, borderRadius: AppRadii.sm),
                  child: Text('3 ROOTS', style: AppTypography.labelSm),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Word Card 1 (Welcome)
            _buildWordCard(
              context: context,
              category: 'HONORIFIC GREETING',
              englishWord: 'Welcome',
              nativeWord: 'സ്വാഗതം',
              transliteration: 'Swagatham',
              ipa: '/sʋɑːɡɐt̪ɐm/',
              durationText: '00:05',
              contributor: 'Anjali M. (Thrissur)',
              recordingsAvailable: 42,
              isFeatured: true,
              onTap: () => context.push('/word/welcome'),
            ),
            const SizedBox(height: 12),
            // Word Card 2 (Mother)
            _buildWordCard(
              context: context,
              category: 'KINSHIP & ORIGIN',
              englishWord: 'Mother',
              nativeWord: 'അമ്മ',
              transliteration: 'Amma',
              ipa: '/əm-mə/',
              durationText: '00:03',
              contributor: 'Ramanathan K.',
              recordingsAvailable: 89,
            ),
            const SizedBox(height: 12),
            // Word Card 3 (Home)
            _buildWordCard(
              context: context,
              category: 'SPATIAL SANCTUARY',
              englishWord: 'Home',
              nativeWord: 'വീട്',
              transliteration: 'Veedu',
              ipa: '/ʋiːɖə̆/',
              durationText: '00:04',
              contributor: 'Devika S.',
              recordingsAvailable: 31,
            ),
            const SizedBox(height: 24),
            // Oral Preservation Drive Invitation Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadii.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.tertiaryContainer,
                      borderRadius: AppRadii.full,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mic, size: 14, color: AppColors.tertiaryFixed),
                        const SizedBox(width: 4),
                        Text('ORAL PRESERVATION DRIVE', style: AppTypography.labelSm.copyWith(color: AppColors.tertiaryFixed)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Know this tongue? Add your voice to Kerala\'s living heritage.',
                    style: AppTypography.headlineSm.copyWith(color: AppColors.onPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Record everyday idioms, lullabies, or vernacular regional accents. Your echo stays preserved for future generations.',
                    style: AppTypography.bodySm.copyWith(color: AppColors.tertiaryFixedDim),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryContainer,
                        foregroundColor: AppColors.onSecondaryContainer,
                      ),
                      onPressed: () => context.push('/record'),
                      icon: const Icon(Icons.mic),
                      label: const Text('Record an Echo for Malayalam'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCard({
    required BuildContext context,
    required String category,
    required String englishWord,
    required String nativeWord,
    required String transliteration,
    required String ipa,
    required String durationText,
    required String contributor,
    required int recordingsAvailable,
    bool isFeatured = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isFeatured ? AppColors.surfaceContainerLowest : AppColors.surfaceContainerLow,
          borderRadius: AppRadii.lg,
          border: isFeatured ? const Border(top: BorderSide(color: AppColors.secondaryContainer, width: 3)) : null,
          boxShadow: AppShadows.paperCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Text(category, style: AppTypography.labelSm.copyWith(color: isFeatured ? AppColors.secondary : AppColors.onSurfaceVariant)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: AppRadii.full,
                  ),
                  child: Text('$recordingsAvailable recordings', style: AppTypography.labelSm.copyWith(color: AppColors.secondary)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(englishWord, style: AppTypography.headlineMd),
            const SizedBox(height: 8),
            // Native Script Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: AppRadii.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nativeWord, style: AppTypography.headlineLg.copyWith(color: AppColors.primary)),
                      Text(transliteration, style: AppTypography.labelMd),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: AppRadii.sm,
                    ),
                    child: Text(ipa, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Acoustic Waveform
            TactileWaveformWidget(isPlaying: false, height: 24, barCount: 20),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                Row(
                  children: [
                    const CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100')),
                    const SizedBox(width: 8),
                    Text('Archived by $contributor', style: AppTypography.labelSm),
                  ],
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
                  ),
                  onPressed: onTap,
                  icon: const Icon(Icons.play_arrow, size: 16),
                  label: const Text('Listen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Screen 4: Word Detail & Acoustic Player (`WordDetailScreen`)
*Represents `word_detail_welcome/code.html`*

#### Features:
- Large phonetic & native typography focus (`Welcome / സ്വാഗതം (Swagatham)`).
- Speaker biographical badge (Anu · 28 yrs · Central Travancore accent).
- Tactical playback deck with scrubbable waveform, phonetic slow-motion speed toggle (`0.8x Slow / 1.0x`), loop playback toggle, and pulsing hero play button.
- Cultural Etymology card ("Su" + "Agatam" folded hands tradition).
- "Add your voice" recording callout card.

```dart
// lib/screens/word/word_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../cubits/audio_player/audio_player_cubit.dart';
import '../../cubits/audio_player/audio_player_state.dart';
import '../../shared_widgets/tactile_waveform.dart';

class WordDetailScreen extends StatefulWidget {
  final String wordId;

  const WordDetailScreen({super.key, required this.wordId});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    // Preload & auto-play word audio sample via Cubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioPlayerCubit>().playTrack(
        audioUrl: 'https://cdn.freesound.org/previews/316/316844_4939433-lq.mp3',
        trackId: widget.wordId,
      );
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Word Detail', style: AppTypography.headlineSm),
            Text('ECHOES ARCHIVE', style: AppTypography.labelSm),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
          IconButton(
            onPressed: () => setState(() => isFavorite = !isFavorite),
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? AppColors.secondary : null),
          ),
        ],
      ),
      body: BlocBuilder<AudioPlayerCubit, AudioPlaybackState>(
        builder: (context, audioState) {
          final cubit = context.read<AudioPlayerCubit>();
          final isPlaying = audioState.isPlaying;
          final isSlowSpeed = audioState.playbackSpeed < 1.0;
          final isLooping = audioState.isLooping;
          final progress = audioState.progress;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Classification & ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: AppRadii.full,
                      ),
                      child: Row(
                        children: [
                          const Text('🇮🇳'),
                          const SizedBox(width: 6),
                          Text('MALAYALAM', style: AppTypography.labelSm.copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryFixed.withOpacity(0.5),
                        borderRadius: AppRadii.full,
                      ),
                      child: Text('ARCHIVE ID #MY-0492', style: AppTypography.labelSm.copyWith(color: AppColors.secondary)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text('WORD OF GREETING', style: AppTypography.labelSm),
                Text('Welcome', style: AppTypography.displayLgMobile),
                Row(
                  children: [
                    Text('സ്വാഗതം', style: AppTypography.headlineLg.copyWith(color: AppColors.primary)),
                    const SizedBox(width: 8),
                    Text('(Swagatham)', style: AppTypography.bodyMd.copyWith(fontStyle: FontStyle.italic)),
                  ],
                ),
                const SizedBox(height: 14),
                // Speaker Profile Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: AppRadii.lg,
                    boxShadow: AppShadows.paperCard,
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Voiced by Anu', style: AppTypography.labelLg),
                                Text(' · 28 yrs', style: AppTypography.bodySm),
                              ],
                            ),
                            Text('Kerala, India', style: AppTypography.bodySm),
                            Row(
                              children: [
                                const Icon(Icons.record_voice_over, size: 14, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text('Central Travancore accent', style: AppTypography.labelSm.copyWith(color: AppColors.secondary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Organic Audio Centerpiece
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: AppRadii.xl,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.graphic_eq, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text('ACOUSTIC RESONANCE', style: AppTypography.labelSm),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius: AppRadii.full,
                            ),
                            child: Text(
                              audioState.status == AudioPlayerStatus.loading ? 'Streaming...' : 'Original Pitch',
                              style: AppTypography.labelSm,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Large Waveform Area
                      TactileWaveformWidget(
                        isPlaying: isPlaying,
                        height: 80,
                        barCount: 30,
                      ),
                      const SizedBox(height: 16),
                      // Interactive Scrubber Slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.surfaceContainerHighest,
                          thumbColor: AppColors.secondaryContainer,
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: progress,
                          onChanged: (v) {
                            final seekMs = (v * audioState.totalDuration.inMilliseconds).toInt();
                            cubit.seek(Duration(milliseconds: seekMs));
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Text(
                            _formatDuration(audioState.currentPosition),
                            style: AppTypography.labelSm.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _formatDuration(audioState.totalDuration),
                            style: AppTypography.labelSm,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Tactical Controls Deck
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Phonetic Speed Slow (0.8x)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: isSlowSpeed ? AppColors.primaryFixed : AppColors.surfaceContainerLow,
                              foregroundColor: isSlowSpeed ? AppColors.onPrimaryFixed : AppColors.onSurface,
                              shape: const RoundedRectangleBorder(borderRadius: AppRadii.full),
                            ),
                            onPressed: cubit.togglePhoneticSpeed,
                            icon: const Icon(Icons.speed, size: 16),
                            label: Text(isSlowSpeed ? '0.8x Slow' : '1.0x', style: AppTypography.labelMd),
                          ),
                          // Hero Master Play Button
                          GestureDetector(
                            onTap: cubit.togglePlayPause,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6)),
                                ],
                              ),
                              child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 32, color: AppColors.surface),
                            ),
                          ),
                          // Loop Toggle
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: isLooping ? AppColors.secondaryFixed : AppColors.surfaceContainerLow,
                            ),
                            onPressed: cubit.toggleLoop,
                            icon: Icon(Icons.repeat, color: isLooping ? AppColors.secondary : AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Cultural Etymology
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: AppRadii.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_stories, size: 18, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Text('CULTURAL ETYMOLOGY', style: AppTypography.labelSm.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '“Swagatham” is delivered with folded hands (Namaskaram), welcoming not just the guest, but the divine spirit within them. In Kerala tradition, greeting an entrant is accompanied by an open veranda door and offering of clear well-water.',
                        style: AppTypography.bodyMd,
                      ),
                      const SizedBox(height: 8),
                      Text('Sanskrit root: Su (good) + Agatam (arrival)', style: AppTypography.bodySm),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Add Your Voice CTA Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: AppRadii.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.record_voice_over, color: AppColors.secondaryContainer),
                          const SizedBox(width: 8),
                          Text('Add your voice', style: AppTypography.headlineSm),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'How do you say “Welcome” in your dialect or local accent? Share an oral trace with future listeners.',
                        style: AppTypography.bodyMd,
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/record'),
                          icon: const Icon(Icons.mic, color: AppColors.secondaryContainer),
                          label: const Text('Record your Echo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

---

### Screen 5: Record Voice Expedition (`RecordVoiceScreen`)
*Represents `record_voice_echoes/code.html`*

#### Features:
- Capture wizard step bar (`Step 1 of 2: Capture`).
- Pronunciation prompt box with phonetic guide: `[swa-ga-tham]`.
- Pulsing concentric recording hub with animated dashes and live timer (`00:03 / 00:05 max`).
- Real-time dynamic audio equalizer visualization.
- Microphone proximity guidance.
- Discard and Stop & Review controls.

```dart
// lib/screens/record/record_voice_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/constants/app_dimensions.dart';
import '../../cubits/audio_recorder/audio_recorder_cubit.dart';
import '../../cubits/audio_recorder/audio_recorder_state.dart';
import '../../shared_widgets/tactile_waveform.dart';

class RecordVoiceScreen extends StatefulWidget {
  final String wordId;
  final String languageId;

  const RecordVoiceScreen({
    super.key,
    this.wordId = 'welcome',
    this.languageId = 'malayalam',
  });

  @override
  State<RecordVoiceScreen> createState() => _RecordVoiceScreenState();
}

class _RecordVoiceScreenState extends State<RecordVoiceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AudioRecorderCubit, AudioRecorderState>(
      listener: (context, state) {
        if (state is RecorderUploadedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.primary,
              content: Text('✨ Echo successfully preserved to Supabase Audio Archive!'),
            ),
          );
          context.pop();
        } else if (state is RecorderFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.error,
              content: Text('Capture error: ${state.error}'),
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<AudioRecorderCubit>();
        final isRecording = state is RecorderRecording;
        final isCaptured = state is RecorderCaptured;
        final isUploading = state is RecorderUploading;

        final elapsedSeconds = isRecording ? state.elapsedSeconds : (isCaptured ? state.duration.inSeconds : 0);
        final maxSeconds = isRecording ? state.maxSeconds : 5;
        final progress = isRecording ? state.progress : (isCaptured ? 1.0 : 0.0);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                cubit.reset();
                context.pop();
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Record Expedition', style: AppTypography.headlineSm),
                Text('ECHOES ARCHIVE', style: AppTypography.labelSm),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // Target Prompt Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: AppRadii.lg,
                    boxShadow: AppShadows.paperCard,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history_edu, size: 16, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text('YOU ARE PRESERVING', style: AppTypography.labelSm),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: const BoxDecoration(color: AppColors.surfaceContainerHighest, borderRadius: AppRadii.full),
                            child: Text('Malayalam (India)', style: AppTypography.labelSm.copyWith(color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Welcome', style: AppTypography.headlineLg),
                      Text('സ്വാഗതം', style: AppTypography.headlineMd.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer.withOpacity(0.6),
                          borderRadius: AppRadii.md,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.graphic_eq, size: 18, color: AppColors.secondaryContainer),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '[swa-ga-tham] · Speak naturally at a steady conversational pace.',
                                style: AppTypography.bodySm,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Central Recording Canvas
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: AppRadii.xl,
                  ),
                  child: Column(
                    children: [
                      Text(
                        isUploading
                            ? 'Uploading to Supabase Storage...'
                            : (isCaptured
                                ? 'Recording finalized · 00:0$elapsedSeconds'
                                : (isRecording ? '00:0$elapsedSeconds / 00:0$maxSeconds max' : 'Tap mic to begin preserving')),
                        style: AppTypography.labelLg.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 8),
                      // Segmented progress bar
                      SizedBox(
                        width: 140,
                        child: isUploading
                            ? const LinearProgressIndicator(minHeight: 6)
                            : LinearProgressIndicator(
                                value: progress,
                                backgroundColor: AppColors.surfaceContainerHighest,
                                color: AppColors.secondaryContainer,
                                minHeight: 6,
                                borderRadius: AppRadii.full,
                              ),
                      ),
                      const SizedBox(height: 28),
                      // Concentric Pulse Microphone Button
                      GestureDetector(
                        onTap: () {
                          if (!isRecording && !isCaptured && !isUploading) {
                            cubit.startRecording();
                          } else if (isRecording) {
                            cubit.stopLocalCapture();
                          }
                        },
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isRecording)
                                  Container(
                                    width: 140 + (_pulseController.value * 20),
                                    height: 140 + (_pulseController.value * 20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryFixed.withOpacity(0.3 * (1 - _pulseController.value)),
                                    ),
                                  ),
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCaptured ? AppColors.secondaryFixed : AppColors.surfaceContainerHighest,
                                  ),
                                ),
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isRecording
                                        ? AppColors.error
                                        : (isCaptured ? AppColors.secondary : AppColors.primary),
                                  ),
                                  child: Icon(
                                    isRecording ? Icons.stop : (isCaptured ? Icons.check : Icons.mic),
                                    color: AppColors.onPrimary,
                                    size: 36,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Live dynamic equalizer bars
                      TactileWaveformWidget(
                        isPlaying: isRecording,
                        height: 48,
                        barCount: 20,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.graphic_eq, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            isRecording ? 'Acoustic fidelity: 48kHz Pristine' : 'Ready for capture',
                            style: AppTypography.labelSm,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Tips callout
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: AppRadii.lg,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: AppColors.secondaryFixed, shape: BoxShape.circle),
                        child: const Icon(Icons.lightbulb, color: AppColors.onSecondaryFixed, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Speak close to your phone microphone in a quiet space. Audio is preserved to Supabase Storage in lossless AAC format.',
                          style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Bottom Controls
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: () {
                          cubit.reset();
                          context.pop();
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerHigh,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
                        ),
                        child: Text('Discard', style: AppTypography.labelLg),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: isUploading
                            ? null
                            : () {
                                if (isRecording) {
                                  cubit.stopLocalCapture();
                                } else if (isCaptured) {
                                  cubit.uploadToSupabase(
                                    wordId: widget.wordId,
                                    languageId: widget.languageId,
                                    accentTerritory: 'Central Travancore accent',
                                    contributorName: 'Voice Custodian',
                                    contributorAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120',
                                  );
                                } else {
                                  cubit.startRecording();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCaptured ? AppColors.secondaryContainer : AppColors.primary,
                          foregroundColor: isCaptured ? AppColors.onSecondaryContainer : AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: Icon(
                          isCaptured ? Icons.cloud_upload : (isRecording ? Icons.stop_circle : Icons.mic),
                          size: 20,
                        ),
                        label: Text(
                          isUploading
                              ? 'Preserving...'
                              : (isCaptured ? 'Upload to Supabase' : (isRecording ? 'Stop & Review' : 'Start Recording')),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

---

## 9. Tactile Reusable Widgets

### Tactile Soundwave / Equalizer (`TactileWaveformWidget`)
Renders vertical rounded bars with animated rhythm in Deep Forest Sage and Amber accents:

```dart
// lib/shared_widgets/tactile_waveform.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class TactileWaveformWidget extends StatefulWidget {
  final bool isPlaying;
  final double height;
  final int barCount;

  const TactileWaveformWidget({
    super.key,
    required this.isPlaying,
    this.height = 36,
    this.barCount = 24,
  });

  @override
  State<TactileWaveformWidget> createState() => _TactileWaveformWidgetState();
}

class _TactileWaveformWidgetState extends State<TactileWaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random(42);
  late List<double> _baseHeights;

  @override
  void initState() {
    super.initState();
    _baseHeights = List.generate(widget.barCount, (i) => 0.2 + _random.nextDouble() * 0.8);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );

    if (widget.isPlaying) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TactileWaveformWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(widget.barCount, (index) {
              final scale = widget.isPlaying
                  ? (0.5 + 0.5 * sin(_controller.value * pi + index))
                  : 1.0;
              final barHeight = (widget.height * _baseHeights[index] * scale).clamp(4.0, widget.height);

              Color color;
              if (index % 5 == 0) {
                color = AppColors.secondaryContainer;
              } else if (index < widget.barCount * 0.6) {
                color = AppColors.primary;
              } else {
                color = AppColors.outlineVariant;
              }

              return Container(
                width: 3.5,
                height: barHeight,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
```

### Archival Dialect Pin (`DialectPinWidget`)
Used on the interactive world map with animated ripple waves:

```dart
// lib/shared_widgets/dialect_pin.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/constants/app_dimensions.dart';

class DialectPinWidget extends StatelessWidget {
  final String countryEmoji;
  final String dialectName;
  final int echoesCount;
  final bool isFeatured;
  final VoidCallback onTap;

  const DialectPinWidget({
    super.key,
    required this.countryEmoji,
    required this.dialectName,
    required this.echoesCount,
    this.isFeatured = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isFeatured ? AppColors.primary : AppColors.surfaceContainerLowest,
              borderRadius: AppRadii.full,
              boxShadow: AppShadows.paperCard,
              border: Border.all(
                color: isFeatured ? AppColors.surfaceBright : AppColors.outlineVariant.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(countryEmoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  dialectName,
                  style: AppTypography.labelSm.copyWith(
                    color: isFeatured ? AppColors.primaryFixed : AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
          // Downward pointer tip
          CustomPaint(
            size: const Size(8, 4),
            painter: TrianglePainter(
              color: isFeatured ? AppColors.primary : AppColors.surfaceContainerLowest,
            ),
          ),
          if (isFeatured)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withOpacity(0.95),
                borderRadius: AppRadii.sm,
              ),
              child: Text('$dialectName · $echoesCount echoes', style: const TextStyle(fontSize: 10)),
            ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

### Overlapping Community Avatar Stack (`AvatarStackWidget`)

```dart
// lib/shared_widgets/avatar_stack.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class AvatarStackWidget extends StatelessWidget {
  final String countText;
  final List<String>? avatarUrls;

  const AvatarStackWidget({
    super.key,
    required this.countText,
    this.avatarUrls,
  });

  @override
  Widget build(BuildContext context) {
    final images = avatarUrls ?? const [
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100',
    ];

    return SizedBox(
      height: 32,
      width: (images.length * 20.0) + 32.0,
      child: Stack(
        children: [
          for (int i = 0; i < images.length; i++)
            Positioned(
              left: i * 18.0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.surfaceContainerLow,
                child: CircleAvatar(
                  radius: 12,
                  backgroundImage: NetworkImage(images[i]),
                ),
              ),
            ),
          Positioned(
            left: images.length * 18.0,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryContainer,
              child: Text(
                countText,
                style: AppTypography.labelSm.copyWith(color: AppColors.onPrimaryContainer, fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Echoes Seal / Emblem (`EchoesEmblemWidget`)
Vector implementation matching `echoes_brand_emblem/code.html`:

```dart
// lib/shared_widgets/echoes_emblem.dart
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class EchoesEmblemWidget extends StatelessWidget {
  final double size;

  const EchoesEmblemWidget({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: EchoesEmblemPainter(),
      ),
    );
  }
}

class EchoesEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer circle
    final bgPaint = Paint()..color = AppColors.primaryContainer;
    canvas.drawCircle(center, radius, bgPaint);

    // Dashed inner ring
    final dashedPaint = Paint()
      ..color = AppColors.surfaceContainerLow.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.85, dashedPaint);

    // Soundwave frequency bars
    final barPaint = Paint()
      ..color = AppColors.surface
      ..strokeWidth = size.width * 0.035
      ..strokeCap = StrokeCap.round;

    final centerBarPaint = Paint()
      ..color = AppColors.secondaryContainer
      ..strokeWidth = size.width * 0.04
      ..strokeCap = StrokeCap.round;

    final heights = [0.15, 0.3, 0.5, 0.7, 0.95, 0.7, 0.5, 0.3, 0.15];
    final barSpacing = size.width * 0.055;
    final startX = center.dx - (heights.length ~/ 2) * barSpacing;

    for (int i = 0; i < heights.length; i++) {
      final x = startX + i * barSpacing;
      final h = heights[i] * (size.height * 0.5);
      final p = (i == heights.length ~/ 2) ? centerBarPaint : barPaint;
      canvas.drawLine(Offset(x, center.dy - h / 2), Offset(x, center.dy + h / 2), p);
    }

    // Center pivot node
    final nodePaint = Paint()..color = AppColors.surface;
    canvas.drawCircle(center, size.width * 0.04, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

---

## 10. Audio Services & Supabase Storage Pipeline

### High-Fidelity Audio Recording Service
Preserves dialect audio in AAC-LC format encapsulated in `.m4a` containers, optimized for archival preservation and efficient Supabase cloud uploads:

```dart
// lib/core/services/audio_recorder_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<String> startRecording() async {
    if (!await hasPermission()) {
      throw Exception('Microphone permission not granted');
    }
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/echo_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 48000,
      ),
      path: path,
    );
    return path;
  }

  Future<Amplitude> getAmplitude() async {
    return await _audioRecorder.getAmplitude();
  }

  Future<String?> stopRecording() async {
    return await _audioRecorder.stop();
  }

  Future<void> dispose() async {
    await _audioRecorder.dispose();
  }
}
```

### Audio Playback & Session Setup (`just_audio` + `audio_session`)
Configures platform audio session for clear spoken-word voice playback without ducking music unnecessarily:

```dart
// lib/core/services/audio_player_service.dart
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer player = AudioPlayer();

  Future<void> initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  Future<void> playSupabaseUrl(String url) async {
    await player.setUrl(url);
    await player.play();
  }

  Future<void> dispose() async {
    await player.dispose();
  }
}
```

---

## 11. Asset Manifest, Environment Configuration & Deployment Checklist

### Environment Variables & Supabase Setup
Supply Supabase credentials at runtime using compile-time `--dart-define` parameters or via flutter environment loaders:

```bash
# Run on connected device or simulator with Supabase config
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

For VS Code or Android Studio `launch.json`:
```json
{
  "configurations": [
    {
      "name": "Echoes (Development)",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define", "SUPABASE_URL=https://your-project.supabase.co",
        "--dart-define", "SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
      ]
    }
  ]
}
```

### Storage Bucket Checklist
1. Ensure the bucket `echoes-audio` exists and is marked **Public**.
2. Run the storage RLS policy in the Supabase SQL editor:
   - `SELECT` allowed for `public` / `anon`.
   - `INSERT` allowed for `anon` and `authenticated`.
3. Allowed MIME types: `audio/mp4`, `audio/aac`, `audio/m4a`, `audio/mpeg`.

### Font Assets
Ensure Google Fonts are allowed in online mode or bundle font files in `assets/fonts/`:
1. `Newsreader` (weights: 400, 500, 600, italic) — Classical editorial serif.
2. `Hanken Grotesk` (weights: 400, 600, 700) — Modern tabular numerals & metadata labels.

### Permissions Checklist
- **iOS (`ios/Runner/Info.plist`)**:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Echoes requires access to your microphone to preserve dialect recordings for future generations.</string>
```

- **Android (`android/app/src/main/AndroidManifest.xml`)**:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.INTERNET" />
```

---
*Generated for the Echoes Mobile Flutter initiative. Compatible with Flutter 3.19+ & Dart 3.3+.*
