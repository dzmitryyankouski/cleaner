# Руководство по интеграции MobileCLIP в iOS

## Текущая реализация

В проекте создан `ImageEmbeddingService` который использует встроенную модель ResNet50 для генерации эмбедингов изображений. Это демонстрационная реализация, которая показывает как работать с Vision framework и Core ML.

## Интеграция настоящей MobileCLIP модели

### Шаг 1: Конвертация модели в Core ML

MobileCLIP изначально разработан для PyTorch. Для использования в iOS необходимо конвертировать модель в формат Core ML:

```python
import torch
import coremltools as ct
from mobileclip import create_model_and_transforms

# Загрузка MobileCLIP модели
model, _, preprocess = create_model_and_transforms('mobileclip_s0', pretrained='path/to/mobileclip_s0.pt')

# Конвертация в Core ML
model.eval()
example_input = torch.randn(1, 3, 224, 224)
traced_model = torch.jit.trace(model, example_input)

# Сохранение в Core ML формате
mlmodel = ct.convert(
    traced_model,
    inputs=[ct.TensorType(shape=(1, 3, 224, 224))],
    outputs=[ct.TensorType()]
)
mlmodel.save("MobileCLIP.mlmodel")
```

### Шаг 2: Добавление модели в проект

1. Скачайте файл `MobileCLIP.mlmodel`
2. Перетащите его в проект Xcode
3. Убедитесь, что модель добавлена в target приложения

### Шаг 3: Обновление ImageEmbeddingService

Замените код в `ImageEmbeddingService.swift`:

```swift
private func setupVisionModel() {
    do {
        // Загрузка MobileCLIP модели
        let model = try MobileCLIP(configuration: MLModelConfiguration())
        self.visionModel = try VNCoreMLModel(for: model.model)
    } catch {
        print("Ошибка загрузки MobileCLIP: \(error)")
        self.errorMessage = "Не удалось загрузить MobileCLIP модель"
    }
}
```

### Шаг 4: Предобработка изображений

MobileCLIP требует специфической предобработки изображений:

```swift
private func preprocessImage(_ image: UIImage) -> UIImage? {
    // Изменение размера до 224x224
    let targetSize = CGSize(width: 224, height: 224)
    
    UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
    image.draw(in: CGRect(origin: .zero, size: targetSize))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return resizedImage
}
```

## Альтернативные решения

### 1. Использование Vision Transformer (ViT)

Если MobileCLIP недоступен, можно использовать другие модели Vision Transformer:

```swift
// Добавьте зависимость через Swift Package Manager
// https://github.com/apple/ml-mobileclip
```

### 2. Использование Create ML

Создайте собственную модель с помощью Create ML:

```swift
import CreateML

// Создание модели для классификации изображений
let model = try MLImageClassifier(trainingData: trainingData)
```

### 3. Использование TensorFlow Lite

Для более сложных моделей можно использовать TensorFlow Lite:

```swift
// Добавьте TensorFlow Lite через Swift Package Manager
// https://github.com/tensorflow/tensorflow/tree/master/tensorflow/lite/swift
```

## Рекомендации по производительности

1. **Кэширование**: Сохраняйте эмбединги для повторного использования
2. **Асинхронная обработка**: Используйте background queues для обработки
3. **Оптимизация модели**: Используйте quantized версии моделей
4. **Batch processing**: Обрабатывайте несколько изображений одновременно

## Тестирование

Создайте unit тесты для проверки корректности генерации эмбедингов:

```swift
import XCTest
@testable import cleaner_ios

class ImageEmbeddingServiceTests: XCTestCase {
    func testEmbeddingGeneration() {
        let service = ImageEmbeddingService()
        let testImage = UIImage(systemName: "photo")!
        
        service.generateEmbedding(from: testImage)
        
        // Проверка что эмбединг сгенерирован
        XCTAssertNotNil(service.embedding)
        XCTAssertFalse(service.embedding!.isEmpty)
    }
}
```

## Заключение

Текущая реализация предоставляет базовую функциональность для генерации эмбедингов изображений. Для использования настоящей MobileCLIP модели следуйте инструкциям выше по конвертации и интеграции модели.
