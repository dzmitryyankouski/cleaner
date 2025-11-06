# Использование Namespace через Environment

## Описание

Теперь `photoPreviewNamespace` доступен через `Environment` во всех дочерних view без необходимости прокидывать его через каждый слой.

## Как использовать

### 1. В любом дочернем view добавьте:

```swift
@Environment(\.photoPreviewNamespace) var photoPreviewNamespace
```

### 2. Используйте namespace для анимаций:

```swift
struct SomeChildView: View {
    @Environment(\.photoPreviewNamespace) var photoPreviewNamespace
    
    var body: some View {
        if let namespace = photoPreviewNamespace {
            Image(systemName: "photo")
                .matchedGeometryEffect(id: "photoPreview", in: namespace)
        }
    }
}
```

## Пример в PhotosTabView

Вместо прокидывания namespace через параметры:

```swift
// ❌ Старый способ
PhotoPreview(viewModel: viewModel, namespace: photoPreviewNamespace)
```

Теперь можно использовать напрямую в `PhotoPreview`:

```swift
// ✅ Новый способ
struct PhotoPreview: View {
    @Environment(\.photoPreviewNamespace) var photoPreviewNamespace
    @ObservedObject var viewModel: PhotoViewModel
    
    var body: some View {
        if let namespace = photoPreviewNamespace {
            // Используйте namespace для анимаций
        }
    }
}
```

## Преимущества

1. **Чистый код**: Не нужно прокидывать namespace через каждый слой view
2. **Гибкость**: Любой дочерний view может получить доступ к namespace
3. **Удобство**: Соответствует паттернам SwiftUI для передачи данных вниз по иерархии

## Важно

- Namespace является опциональным (`Namespace.ID?`), поэтому всегда проверяйте его на `nil`
- Namespace создается в `MainTabView` и автоматически доступен во всех дочерних view

