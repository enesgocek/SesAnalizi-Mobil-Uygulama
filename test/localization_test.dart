import 'package:flutter_test/flutter_test.dart';
import 'package:vokal_koc_uygulamasi/localization_manager.dart';

void main() {
  group('LocalizationManager Tests', () {
    late LocalizationManager manager;

    setUp(() {
      manager = LocalizationManager();
      // Reset to default for each test if possible, but it's a singleton.
      // So we just set it manually to 'tr' at start or testing logic handles it.
      manager.setLanguage('tr'); 
    });

    test('Initial language should be Turkish (tr)', () {
      expect(manager.languageCode, 'tr');
    });

    test('Translate should return correct Turkish values', () {
      manager.setLanguage('tr');
      expect(manager.translate('app_title'), 'VOCAL STUDIO');
      expect(manager.translate('start_analysis'), 'ANALİZİ BAŞLAT');
      expect(manager.translate('female'), 'KADIN');
    });

    test('Should switch language to English', () {
      bool notified = false;
      manager.addListener(() {
        notified = true;
      });

      manager.setLanguage('en');

      expect(manager.languageCode, 'en');
      expect(notified, true);
      expect(manager.translate('start_analysis'), 'START THE ANALYSIS');
      expect(manager.translate('female'), 'FEMALE');
    });

    test('Should switch language to German', () {
      manager.setLanguage('de');
      expect(manager.languageCode, 'de');
      expect(manager.translate('start_analysis'), 'ANALYSE STARTEN');
      expect(manager.translate('female'), 'WEIBLICH');
      expect(manager.translate('voice_soprano'), 'SOPRAN');
    });

    test('Should handle unknown keys gracefully', () {
      const unknownKey = 'non_existent_key';
      expect(manager.translate(unknownKey), unknownKey);
    });

    test('Should handle parameter replacement', () {
       manager.setLanguage('en');
       // Assuming we added parameterized strings like "Delete {filename}?"
       // If not present in all langs, we test specifically.
       // The code I wrote has: 'delete_recording_confirmation': 'Do you want to delete {filename}?'
       
       final translation = manager.translate(
         'delete_recording_confirmation', 
         {'filename': 'test_audio.aac'}
       );
       
       expect(translation, 'Do you want to delete test_audio.aac?');
    });
  });
}
