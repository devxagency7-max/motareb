import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();

  factory TranslationService() => _instance;

  TranslationService._internal();

  final _onDeviceTranslator = OnDeviceTranslator(
    sourceLanguage: TranslateLanguage.arabic,
    targetLanguage: TranslateLanguage.english,
  );

  final _modelManager = OnDeviceTranslatorModelManager();

  Future<void> _ensureModelsDownloaded() async {
    try {
      final bool isArabicDownloaded = await _modelManager.isModelDownloaded(
        TranslateLanguage.arabic.bcpCode,
      );
      final bool isEnglishDownloaded = await _modelManager.isModelDownloaded(
        TranslateLanguage.english.bcpCode,
      );

      if (!isArabicDownloaded) {
        debugPrint('Downloading Arabic model...');
        await _modelManager.downloadModel(TranslateLanguage.arabic.bcpCode);
      }
      if (!isEnglishDownloaded) {
        debugPrint('Downloading English model...');
        await _modelManager.downloadModel(TranslateLanguage.english.bcpCode);
      }
    } catch (e) {
      debugPrint('Error checking/downloading models: $e');
    }
  }

  Future<String?> translate(String text) async {
    if (text.trim().isEmpty) return null;
    try {
      // Ensure models are available before translating
      // This is a blocking call if models are not downloaded,
      // but necessary for offline functionality.
      await _ensureModelsDownloaded();

      final String translation = await _onDeviceTranslator.translateText(text);
      return translation;
    } catch (e) {
      debugPrint('Translation error: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    await _onDeviceTranslator.close();
  }
}
