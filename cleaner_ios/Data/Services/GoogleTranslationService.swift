import Foundation

// MARK: - Google Translation Service

/// Сервис перевода текста через Google Translate API
final class GoogleTranslationService: TranslationServiceProtocol {
    
    // MARK: - Properties
    
    private let apiKey: String
    private let session: URLSession
    private let baseURL = "https://translation.googleapis.com/language/translate/v2"
    
    // MARK: - Initialization
    
    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }
    
    // MARK: - Public Methods
    
    func translate(_ text: String, to language: String) async -> Result<String, TranslationError> {
        guard !apiKey.isEmpty else {
            return .failure(.apiKeyMissing)
        }
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            return .failure(.invalidResponse)
        }
        
        let parameters: [String: Any] = [
            "q": text,
            "target": language
        ]
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            return .failure(.translationFailed)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = httpBody
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return .failure(.invalidResponse)
            }
            
            let translatedText = try parseTranslationResponse(data)
            return .success(translatedText)
        } catch let error as TranslationError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    // MARK: - Private Methods
    
    private func parseTranslationResponse(_ data: Data) throws -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let dataDict = json["data"] as? [String: Any],
              let translations = dataDict["translations"] as? [[String: Any]],
              let translatedText = translations.first?["translatedText"] as? String else {
            throw TranslationError.invalidResponse
        }
        
        return translatedText
    }
}

