import Foundation

// MARK: - Translation Service Protocol

/// Протокол для перевода текста
protocol TranslationServiceProtocol {
    /// Переводит текст на указанный язык
    func translate(_ text: String, to language: String) async -> Result<String, TranslationError>
}

// MARK: - Translation Error

enum TranslationError: LocalizedError {
    case apiKeyMissing
    case networkError(Error)
    case invalidResponse
    case translationFailed
    
    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "API ключ для перевода не найден"
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .invalidResponse:
            return "Некорректный ответ от сервера"
        case .translationFailed:
            return "Не удалось выполнить перевод"
        }
    }
}

