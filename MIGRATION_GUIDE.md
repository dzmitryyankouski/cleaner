# Руководство по миграции на новую архитектуру

## Быстрый старт

### Шаг 1: Добавить новые файлы в Xcode проект

1. Откройте проект в Xcode
2. Добавьте новые папки в проект:
   - `Core/App/`
   - `Core/DI/`
   - `Core/Models/`
   - `Core/Protocols/`
   - `Data/Repositories/`
   - `Data/Services/`
   - `Domain/UseCases/`
   - `Presentation/ViewModels/`
   - `Presentation/Views/`
   - `Presentation/Components/`

### Шаг 2: Удалить старые файлы

Удалите следующие файлы из Xcode (они заменены новой реализацией):
- `cleaner_ios/Services/ImageEmbeddingService.swift`
- `cleaner_ios/Services/PhotoService.swift`
- `cleaner_ios/Services/ClusterService.swift`
- `cleaner_ios/Services/TranslateSerivce.swift`
- `cleaner_ios/AppView.swift`
- `cleaner_ios/cleaner_iosApp.swift`

**Важно**: Не удаляйте физически, только из Xcode. Оставьте как backup.

### Шаг 3: Обновить зависимости в старых файлах

Если вы хотите сохранить `VideoService.swift` и другие файлы, нужно обновить их использование:

**Было:**
```swift
@StateObject private var photoService = PhotoService.shared
```

**Стало:**
```swift
@StateObject private var photoViewModel: PhotoViewModel

init() {
    let container = AppDependencyContainer.shared
    _photoViewModel = StateObject(wrappedValue: container.makePhotoViewModel()!)
}
```

### Шаг 4: Проверить компиляцию

1. Нажмите `Cmd + B` для сборки проекта
2. Исправьте возможные ошибки импортов
3. Убедитесь что все Target Membership установлены правильно

### Шаг 5: Запустить приложение

1. Выберите симулятор или устройство
2. Нажмите `Cmd + R`
3. Протестируйте основные функции

## Детальная миграция

### Миграция Photos функциональности

**Старый код:**
```swift
// PhotoService.swift
class PhotoService: ObservableObject {
    static let shared = PhotoService()
    @Published var photos: [Photo] = []
    
    func search(text: String) async -> [Photo] {
        // логика поиска
    }
}
```

**Новый код:**
```swift
// PhotoViewModel.swift
@MainActor
final class PhotoViewModel: ObservableObject {
    @Published var photos: [Photo] = []
    
    private let searchPhotosUseCase: SearchPhotosUseCase
    
    func search(text: String) async -> [Photo] {
        let result = await searchPhotosUseCase.execute(
            query: text,
            photos: photos,
            minSimilarity: searchSimilarityThreshold
        )
        // обработка результата
    }
}
```

### Миграция View

**Старый код:**
```swift
struct PhotosView: View {
    @ObservedObject var photoService: PhotoService
}
```

**Новый код:**
```swift
struct PhotosTabView: View {
    @ObservedObject var viewModel: PhotoViewModel
}
```

### Использование новых компонентов

**Загрузка:**
```swift
LoadingView(
    title: "Загрузка...",
    message: "Пожалуйста, подождите"
)
```

**Прогресс:**
```swift
ProgressLoadingView(
    title: "Индексация",
    current: 50,
    total: 100,
    message: "Обработка фотографий..."
)
```

**Пустое состояние:**
```swift
EmptyStateView(
    icon: "photo",
    title: "Нет фотографий",
    message: "Добавьте фотографии в галерею"
)
```

**Статистика:**
```swift
StatisticCardView(statistics: [
    .init(label: "Всего", value: "123", alignment: .leading),
    .init(label: "Размер", value: "1.5 GB", alignment: .trailing)
])
```

## Добавление новой функциональности

### Пример: Добавление поддержки нового типа поиска

#### 1. Создать протокол (если нужно)
```swift
// Core/Protocols/NewServiceProtocol.swift
protocol NewServiceProtocol {
    func doSomething() async -> Result<Data, Error>
}
```

#### 2. Создать реализацию
```swift
// Data/Services/NewService.swift
final class NewService: NewServiceProtocol {
    func doSomething() async -> Result<Data, Error> {
        // реализация
    }
}
```

#### 3. Создать Use Case
```swift
// Domain/UseCases/NewUseCase.swift
final class NewUseCase {
    private let service: NewServiceProtocol
    
    init(service: NewServiceProtocol) {
        self.service = service
    }
    
    func execute() async -> Result<SomeData, SomeError> {
        // бизнес-логика
    }
}
```

#### 4. Добавить в фабрику
```swift
// Core/DI/ServiceFactory.swift
extension ServiceFactory {
    func makeNewService() -> NewServiceProtocol {
        return NewService()
    }
}

// Core/DI/UseCaseFactory.swift
extension UseCaseFactory {
    func makeNewUseCase() -> NewUseCase {
        return NewUseCase(
            service: serviceFactory.makeNewService()
        )
    }
}
```

#### 5. Использовать в ViewModel
```swift
// Presentation/ViewModels/SomeViewModel.swift
final class SomeViewModel: ObservableObject {
    private let newUseCase: NewUseCase
    
    func performNewAction() async {
        let result = await newUseCase.execute()
        // обработка результата
    }
}
```

## Типичные проблемы и решения

### Проблема: "Cannot find type in scope"
**Решение**: Убедитесь что файл добавлен в Target Membership

### Проблема: Circular dependency
**Решение**: Используйте протоколы вместо конкретных классов

### Проблема: ViewModel не обновляется
**Решение**: Убедитесь что используете `@MainActor` и `@Published`

### Проблема: Use Case не создается
**Решение**: Проверьте что все зависимости доступны в фабрике

## Тестирование после миграции

### Чеклист функций:
- [ ] Индексация фотографий
- [ ] Поиск похожих фотографий
- [ ] Поиск дубликатов
- [ ] Поиск скриншотов
- [ ] Поиск размытых фотографий
- [ ] Текстовый поиск
- [ ] Выбор фото для удаления
- [ ] Отображение статистики

## Производительность

Новая архитектура не должна влиять на производительность:
- ✅ Параллельная индексация сохранена
- ✅ LSH алгоритм оптимизирован
- ✅ Кэширование работает
- ✅ Lazy loading для UI

## Поддержка

Если возникли проблемы:
1. Проверьте ARCHITECTURE.md для понимания структуры
2. Посмотрите REFACTORING_SUMMARY.md для деталей изменений
3. Проверьте что все файлы добавлены в проект
4. Убедитесь что Target Membership настроен правильно

## Дальнейшее развитие

После успешной миграции можно:
1. Рефакторить VideoService аналогично PhotoService
2. Добавить юнит-тесты используя протоколы
3. Добавить UI-тесты для новых Views
4. Оптимизировать Use Cases при необходимости

## Откат изменений (если нужно)

Если что-то пошло не так:
1. Восстановите старые файлы из backup
2. Удалите новые файлы из проекта
3. Очистите derived data: `Cmd + Shift + K`
4. Пересоберите проект: `Cmd + B`

Новая архитектура не меняет существующий функционал, только улучшает структуру кода!

