import Foundation

class ConfigService {
    static let shared = ConfigService()
    
    private var config: [String: String] = [:]
    
    private init() {
        loadConfig()
    }
    
    private func loadConfig() {
        if let configPath = Bundle.main.path(forResource: "config", ofType: "env") {
            do {
                let configContent = try String(contentsOfFile: configPath)
                parseConfigContent(configContent)
            } catch {
                print("Ошибка чтения config.env: \(error)")
            }
        }
    }
    
    private func parseConfigContent(_ content: String) {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                continue
            }
            
            let components = trimmedLine.components(separatedBy: "=")
            if components.count == 2 {
                let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let value = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                config[key] = value
            }
        }
    }
    
    func getValue(for key: String) -> String? {
        return config[key]
    }
    
    func getValue(for key: String, defaultValue: String) -> String {
        return config[key] ?? defaultValue
    }
}

