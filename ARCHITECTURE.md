# Архитектура приложения Cleaner iOS

## Обзор

Приложение построено на принципах **Clean Architecture** с применением паттернов SOLID и лучших практик из книги Роберта Мартина "Чистый код".

## Структура проекта

```
cleaner_ios/
├── Core/                      # Ядро приложения
│   ├── App/                   # Точка входа и конфигурация
│   ├── DI/                    # Dependency Injection (фабрики)
│   ├── Models/                # Модели данных и Value Objects
│   └── Protocols/             # Протоколы (интерфейсы)
│
├── Data/                      # Слой данных
│   ├── Repositories/          # Репозитории для работы с данными
│   └── Services/              # Реализации сервисов
│
├── Domain/                    # Бизнес-логика
│   └── UseCases/              # Use Cases (варианты использования)
│
└── Presentation/              # UI слой
    ├── ViewModels/            # ViewModels (MVVM)
    ├── Views/                 # SwiftUI Views
    └── Components/            # Переиспользуемые UI компоненты
```

## Принципы SOLID

### 1. Single Responsibility Principle (SRP)
Каждый класс имеет одну ответственность:
- `MLModelLoader` - только загрузка ML моделей
- `EmbeddingGenerator` - только генерация эмбедингов
- `SimilarityCalculator` - только вычисление схожести
- `PhotoAssetRepository` - только работа с фото ассетами

### 2. Open/Closed Principle (OCP)
Классы открыты для расширения, но закрыты для модификации:
- Использование протоколов позволяет легко добавлять новые реализации
- Например, можно добавить новый `TranslationService` без изменения существующего кода

### 3. Liskov Substitution Principle (LSP)
Любую реализацию можно заменить на другую без нарушения работы:
- Все сервисы реализуют протоколы
- `GoogleTranslationService` может быть заменен на `DeepLTranslationService`

### 4. Interface Segregation Principle (ISP)
Протоколы разделены по функциональности:
- `EmbeddingServiceProtocol` - работа с эмбедингами
- `AssetRepositoryProtocol` - работа с ассетами
- `ClusteringServiceProtocol` - кластеризация
- `TranslationServiceProtocol` - перевод

### 5. Dependency Inversion Principle (DIP)
Зависимости инвертированы через протоколы:
- Use Cases зависят от протоколов, а не от конкретных реализаций
- Фабрики создают зависимости и внедряют их

## Слои архитектуры

### Core Layer (Ядро)
**Ответственность**: Определение интерфейсов, моделей данных и базовой конфигурации

**Компоненты**:
- **Protocols**: Интерфейсы для всех сервисов
- **Models**: Value Objects и модели данных
- **DI**: Фабрики для создания зависимостей

**Принципы**:
- Не зависит от других слоев
- Содержит только протоколы и модели
- Чистый Swift код без frameworks

### Data Layer (Слой данных)
**Ответственность**: Реализация работы с данными и внешними источниками

**Компоненты**:
- **Repositories**: Работа с Photos Framework, файловой системой
- **Services**: Реализации ML, обработки изображений, API

**Принципы**:
- Реализует протоколы из Core
- Изолирует детали работы с frameworks
- Использует Result type для обработки ошибок

### Domain Layer (Бизнес-логика)
**Ответственность**: Бизнес-логика и варианты использования

**Компоненты**:
- **UseCases**: Конкретные сценарии использования приложения
  - `IndexPhotosUseCase`: Индексация фотографий
  - `GroupSimilarPhotosUseCase`: Группировка похожих фото
  - `SearchPhotosUseCase`: Поиск по текстовому запросу

**Принципы**:
- Не зависит от UI
- Использует только протоколы
- Содержит всю бизнес-логику

### Presentation Layer (UI)
**Ответственность**: Отображение и взаимодействие с пользователем

**Компоненты**:
- **ViewModels**: MVVM паттерн, управление состоянием
- **Views**: SwiftUI представления
- **Components**: Переиспользуемые UI компоненты

**Принципы**:
- Использует только ViewModels для доступа к данным
- Не содержит бизнес-логики
- Легко тестируемые компоненты

## Паттерны проектирования

### 1. Repository Pattern
Инкапсуляция логики доступа к данным:
```swift
protocol AssetRepositoryProtocol {
    func fetchPhotos() async -> Result<[PHAsset], AssetError>
    func fetchVideos() async -> Result<[PHAsset], AssetError>
}
```

### 2. Factory Pattern
Создание сложных объектов с зависимостями:
```swift
final class ServiceFactory {
    func makeEmbeddingService() -> EmbeddingServiceProtocol?
    func makeClusteringService() -> ClusteringServiceProtocol
}
```

### 3. Use Case Pattern
Инкапсуляция бизнес-логики:
```swift
final class IndexPhotosUseCase {
    func execute(onProgress: @escaping (Int, Photo) async -> Void) 
        -> Result<[Photo], PhotoIndexingError>
}
```

### 4. MVVM Pattern
Разделение UI и бизнес-логики:
```swift
@MainActor
final class PhotoViewModel: ObservableObject {
    @Published var photos: [Photo] = []
    private let indexPhotosUseCase: IndexPhotosUseCase
}
```

### 5. Value Object Pattern
Инкапсуляция значений:
```swift
struct FileSize {
    let bytes: Int64
    var formatted: String { /* форматирование */ }
}
```

## Обработка ошибок

### Result Type
Используется для явной обработки ошибок:
```swift
enum EmbeddingError: LocalizedError {
    case modelNotLoaded(String)
    case tokenizerNotAvailable
    case predictionFailed(Error)
}

func generateEmbedding() async -> Result<[Float], EmbeddingError>
```

### Типизированные ошибки
Каждый слой определяет свои типы ошибок:
- `AssetError` - ошибки работы с ассетами
- `EmbeddingError` - ошибки генерации эмбедингов
- `SearchError` - ошибки поиска
- `TranslationError` - ошибки перевода

## Dependency Injection

### Фабрики
Создание объектов с зависимостями:
```swift
final class UseCaseFactory {
    func makeIndexPhotosUseCase() -> IndexPhotosUseCase? {
        guard let embeddingService = serviceFactory.makeEmbeddingService() 
        else { return nil }
        
        return IndexPhotosUseCase(
            assetRepository: serviceFactory.makePhotoAssetRepository(),
            embeddingService: embeddingService
        )
    }
}
```

### Container
Центральная точка для создания зависимостей:
```swift
final class AppDependencyContainer {
    static let shared = AppDependencyContainer()
    
    func makePhotoViewModel() -> PhotoViewModel?
}
```

## Тестирование

### Преимущества архитектуры для тестирования:

1. **Протоколы**: Легко создавать моки
2. **Use Cases**: Бизнес-логика изолирована от UI
3. **Repository**: Данные изолированы от логики
4. **Result Type**: Явная обработка ошибок

### Пример тестирования:
```swift
final class MockEmbeddingService: EmbeddingServiceProtocol {
    var mockEmbedding: [Float] = [0.1, 0.2, 0.3]
    
    func generateImageEmbedding(from pixelBuffer: CVPixelBuffer) 
        async -> Result<[Float], EmbeddingError> {
        return .success(mockEmbedding)
    }
}
```

## Преимущества текущей архитектуры

1. ✅ **Тестируемость**: Все компоненты легко тестировать
2. ✅ **Расширяемость**: Легко добавлять новые функции
3. ✅ **Поддерживаемость**: Код организован и понятен
4. ✅ **Переиспользование**: Компоненты можно использовать повторно
5. ✅ **Изоляция**: Изменения в одном слое не влияют на другие
6. ✅ **SOLID**: Все принципы соблюдены
7. ✅ **Чистый код**: Читаемый и понятный код

## Рекомендации по развитию

### Добавление новой функции:
1. Определить протокол в `Core/Protocols/`
2. Создать реализацию в `Data/Services/`
3. Создать Use Case в `Domain/UseCases/`
4. Добавить в фабрику в `Core/DI/`
5. Использовать в ViewModel

### Изменение существующей функции:
1. Изменения начинать с Use Case (бизнес-логика)
2. При необходимости обновить протоколы
3. Обновить реализации сервисов
4. Обновить ViewModel и UI

## Заключение

Архитектура построена на проверенных принципах и паттернах, что обеспечивает:
- Высокую гибкость и расширяемость
- Простоту тестирования
- Легкость поддержки
- Чистоту и читаемость кода

Следование этим принципам позволяет создавать качественное и надежное программное обеспечение.

