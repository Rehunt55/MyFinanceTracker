import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class GeminiService {
  static const _apiKey = "AIzaSyAGsdCEE1pGRCAvVVN-3n5ExOnpUHuFdLQ";

  Future<Map<String, dynamic>> askAi(String prompt) async {
    try {
      // Model tanımlaması
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

      final content = [
        Content.text('''
        Sen bir finans asistanısın. Kullanıcıdan gelen miktar ve varlık adını JSON olarak döndür.
        Kategori şu listeden seçilmeli: borsa, kripto, doviz, altin.
        Sadece JSON döndür: {"ad": "BTC", "miktar": 0.5, "kategori": "kripto"}
        Metin: $prompt
      '''),
      ];

      final response = await model.generateContent(content);
      final text = response.text ?? "";

      String cleanJson = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return {
        "text": "Analiz tamamlandı, portföyünüze ekleniyor...",
        "data": jsonDecode(cleanJson),
      };
    } catch (e) {
      return {
        "text":
            "Asistan şu an bağlanamıyor, lütfen internetinizi kontrol edin.",
        "data": null,
      };
    }
  }
}
