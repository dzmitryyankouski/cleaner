import Foundation

class TranslateService {
    private let apiKey: String
    private let session = URLSession.shared
    
    init() {
        // Читаем API ключ через ConfigService
        self.apiKey = ConfigService.shared.getValue(for: "GOOGLE_TRANSLATE_API_KEY")!
    }

    /// Переводит текст с помощью Google Translate API
    /// - Parameters:
    ///   - text: Текст для перевода
    ///   - targetLanguage: Язык, на который нужно перевести (например, "en", "ru")
    /// - Returns: Переведённый текст или исходный текст в случае ошибки
    func translate(text: String, to targetLanguage: String = "en") async -> String {
        guard let url = URL(string: "https://translation.googleapis.com/language/translate/v2?key=\(apiKey)") else {
            return text
        }

        let parameters: [String: Any] = [
            "q": text,
            "target": targetLanguage
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            return text
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return text
            }

            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let dataDict = json["data"] as? [String: Any],
               let translations = dataDict["translations"] as? [[String: Any]],
               let translatedText = translations.first?["translatedText"] as? String {
                return translatedText
            } else {
                return text
            }
        } catch {
            print("Ошибка перевода: \(error.localizedDescription)")
            return text
        }
    }
}
