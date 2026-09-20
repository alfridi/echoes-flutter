import 'package:equatable/equatable.dart';
import '../../models/language.dart';
import '../../models/map_pin.dart';
import '../../models/word_entry.dart';

abstract class ExploreState extends Equatable {
  const ExploreState();

  @override
  List<Object?> get props => [];
}

class ExploreInitial extends ExploreState {
  const ExploreInitial();
}

class ExploreLoading extends ExploreState {
  const ExploreLoading();
}

class ExploreLoaded extends ExploreState {
  final List<DialectPinModel> pins;
  final List<Language> languages;
  final WordEntry? featuredEcho;
  final String activeFilter;
  final String searchQuery;

  const ExploreLoaded({
    required this.pins,
    required this.languages,
    this.featuredEcho,
    this.activeFilter = 'All Continents',
    this.searchQuery = '',
  });

  List<DialectPinModel> get filteredPins {
    var result = pins;
    if (activeFilter == 'Featured') {
      result = result.where((p) => p.isFeatured).toList();
    }
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result
          .where((p) =>
              p.languageName.toLowerCase().contains(query) ||
              p.languageId.toLowerCase().contains(query))
          .toList();
    }
    return result;
  }

  List<Language> get filteredLanguages {
    var result = languages;
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result
          .where((l) =>
              l.name.toLowerCase().contains(query) ||
              l.region.toLowerCase().contains(query) ||
              l.branch.toLowerCase().contains(query) ||
              l.nativeScript.toLowerCase().contains(query))
          .toList();
    }
    return result;
  }

  bool get isEmpty => languages.isEmpty && pins.isEmpty;

  ExploreLoaded copyWith({
    List<DialectPinModel>? pins,
    List<Language>? languages,
    WordEntry? featuredEcho,
    String? activeFilter,
    String? searchQuery,
  }) {
    return ExploreLoaded(
      pins: pins ?? this.pins,
      languages: languages ?? this.languages,
      featuredEcho: featuredEcho ?? this.featuredEcho,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props =>
      [pins, languages, featuredEcho, activeFilter, searchQuery];
}

class ExploreError extends ExploreState {
  final String message;
  const ExploreError(this.message);

  @override
  List<Object?> get props => [message];
}
