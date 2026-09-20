import '../core/services/supabase_service.dart';
import '../models/language.dart';
import '../models/map_pin.dart';

/// Repository interface defining queries for dialect languages and geographic map pins.
abstract class LanguageRepository {
  Future<List<Language>> getLanguages();
  Future<Language> getLanguageById(String id);
  Future<List<DialectPinModel>> getDialectPins();
}

/// Supabase PostgreSQL implementation of [LanguageRepository].
class SupabaseLanguageRepository implements LanguageRepository {
  final SupabaseService _supabase;

  SupabaseLanguageRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService();

  @override
  Future<List<Language>> getLanguages() async {
    final response =
        await _supabase.client.from('languages').select().order('name');
    return (response as List<dynamic>)
        .map((e) => Language.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Language> getLanguageById(String id) async {
    final response =
        await _supabase.client.from('languages').select().eq('id', id).single();
    return Language.fromMap(response);
  }

  @override
  Future<List<DialectPinModel>> getDialectPins() async {
    final response = await _supabase.client.from('dialect_pins').select();
    return (response as List<dynamic>)
        .map((e) => DialectPinModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
