# Использование функции textToEmbedding

## Обзор

Функция `textToEmbedding` преобразует текстовые запросы в векторные представления (эмбединги) с помощью модели MobileCLIP. Это позволяет искать изображения по текстовому описанию.

## Основные функции

### 1. textToEmbedding(text: String) -> [Float]

Преобразует текст в эмбединг.

```swift
let service = ImageEmbeddingService()
let embedding = await service.textToEmbedding(text: "a beautiful sunset over the ocean")
```

**Параметры:**
- `text`: Текст для преобразования (не может быть пустым)

**Возвращает:**
- Массив Float значений, представляющий эмбединг текста
- Пустой массив в случае ошибки

### 2. generateTextEmbeddings(from texts: [String]) -> [[Float]]

Преобразует массив текстов в массив эмбедингов.

```swift
let texts = ["sunset", "ocean", "mountains"]
let embeddings = await service.generateTextEmbeddings(from: texts)
```

### 3. cosineSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float

Вычисляет косинусное сходство между двумя эмбедингами.

```swift
let similarity = service.cosineSimilarity(imageEmbedding, textEmbedding)
```

**Возвращает:**
- Значение от -1 до 1, где 1 означает полное сходство

### 4. findSimilarPhotos(query: String, limit: Int = 10) -> [(Photo, Float)]

Находит наиболее похожие фотографии по текстовому запросу.

```swift
let results = await service.findSimilarPhotos(query: "beautiful landscape", limit: 5)
for (photo, similarity) in results {
    print("Similarity: \(similarity)")
}
```

## Примеры использования

### Поиск изображений по тексту

```swift
class SearchViewModel: ObservableObject {
    private let embeddingService = ImageEmbeddingService()
    @Published var searchResults: [Photo] = []
    
    func searchPhotos(query: String) async {
        let results = await embeddingService.findSimilarPhotos(query: query, limit: 20)
        await MainActor.run {
            self.searchResults = results.map { $0.0 }
        }
    }
}
```

### Сравнение эмбедингов

```swift
let textEmbedding = await service.textToEmbedding(text: "sunset")
let imageEmbedding = await service.generateEmbedding(from: someImage)

let similarity = service.cosineSimilarity(textEmbedding, imageEmbedding)
if similarity > 0.7 {
    print("Изображение соответствует текстовому описанию!")
}
```

## Обработка ошибок

Функция автоматически обрабатывает следующие ошибки:

- **Модель не загружена**: Возвращает пустой массив
- **Пустой текст**: Возвращает пустой массив
- **Ошибка модели**: Выводит сообщение в консоль и возвращает пустой массив

```swift
let embedding = await service.textToEmbedding(text: "test")
if embedding.isEmpty {
    print("Не удалось сгенерировать эмбединг")
}
```

## Производительность

- **Размерность эмбединга**: Обычно 512 для MobileCLIP
- **Время генерации**: ~50-100ms на современном устройстве
- **Память**: ~2KB на эмбединг

## Тестирование

Запустите тесты для проверки корректности работы:

```bash
# В Xcode: Product -> Test
# Или через командную строку:
xcodebuild test -scheme cleaner_ios
```

Тесты проверяют:
- Генерацию эмбедингов
- Корректность косинусного сходства
- Обработку ошибок

## Отладка

Включите отладочные сообщения в консоли Xcode:

```
✅ Text embedding generated successfully, dimension: 512
❌ Text model not loaded
❌ Empty text provided
```

## Советы по использованию

1. **Качественные запросы**: Используйте описательные фразы вместо отдельных слов
2. **Кэширование**: Сохраняйте эмбединги для повторного использования
3. **Пороги сходства**: Используйте порог 0.7+ для высокого качества результатов
4. **Асинхронность**: Все функции асинхронные, используйте await
