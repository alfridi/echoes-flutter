import '../core/services/supabase_service.dart';
import '../models/word_entry.dart';

/// Repository interface defining queries for vocabulary words and acoustic samples.
abstract class WordRepository {
  Future<List<WordEntry>> getWordsForLanguage(String languageId);
  Future<WordEntry> getWordDetail(String wordId);
  Future<WordEntry?> getFeaturedWordOfTheDay();
}

/// Supabase PostgreSQL implementation of [WordRepository].
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
    return (response as List<dynamic>)
        .map((e) => WordEntry.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WordEntry> getWordDetail(String wordId) async {
    final response = await _supabase.client
        .from('words')
        .select()
        .eq('id', wordId)
        .single();
    return WordEntry.fromMap(response);
  }

  @override
  Future<WordEntry?> getFeaturedWordOfTheDay() async {
    final response =
        await _supabase.client.from('words').select().limit(1).maybeSingle();
    if (response == null) return null;
    return WordEntry.fromMap(response);
  }
}
