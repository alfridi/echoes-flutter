import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/language.dart';
import '../../models/map_pin.dart';
import '../../models/word_entry.dart';
import '../../repositories/language_repository.dart';
import '../../repositories/word_repository.dart';
import 'explore_state.dart';

class ExploreCubit extends Cubit<ExploreState> {
  final LanguageRepository languageRepository;
  final WordRepository wordRepository;

  ExploreCubit({
    required this.languageRepository,
    required this.wordRepository,
  }) : super(const ExploreInitial());

  Future<void> loadAtlasData() async {
    try {
      emit(const ExploreLoading());
      final pinsFuture = languageRepository.getDialectPins();
      final languagesFuture = languageRepository.getLanguages();
      final featuredFuture = wordRepository.getFeaturedWordOfTheDay();

      final results = await Future.wait([
        pinsFuture,
        languagesFuture,
        featuredFuture,
      ]);

      emit(ExploreLoaded(
        pins: results[0] as List<DialectPinModel>,
        languages: results[1] as List<Language>,
        featuredEcho: results[2] as WordEntry?,
      ));
    } catch (e) {
      emit(ExploreError(e.toString()));
    }
  }

  void setFilter(String filter) {
    final currentState = state;
    if (currentState is ExploreLoaded) {
      emit(currentState.copyWith(activeFilter: filter));
    }
  }

  void setSearchQuery(String query) {
    final currentState = state;
    if (currentState is ExploreLoaded) {
      emit(currentState.copyWith(searchQuery: query.trim()));
    }
  }
}
