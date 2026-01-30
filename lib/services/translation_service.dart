import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  static final OnDeviceTranslator _translator = OnDeviceTranslator(
    sourceLanguage: TranslateLanguage.arabic,
    targetLanguage: TranslateLanguage.english,
  );

  static Future<String> translateToEnglish(String text) async {
    try {
      if (text.isEmpty) return '';
      final result = await _translator.translateText(text);
      return result;
    } catch (e) {
      print('Translation Error: $e');
      return text;
    }
  }

  static void dispose() {
    _translator.close();
  }
}
