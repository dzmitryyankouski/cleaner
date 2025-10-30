# Инструкция по добавлению новых файлов в Xcode проект

## ⚠️ Важно!

Новые файлы созданы в файловой системе, но **не добавлены в Xcode проект**.  
Чтобы проект собрался, нужно добавить их через Xcode.

## Шаги для добавления файлов

### 1. Откройте проект в Xcode

```bash
open /Users/dmitriyyankovskiy/Documents/projects/cleaner_ios/cleaner_ios.xcworkspace
```

### 2. Добавьте папки с новыми файлами

#### Вариант A: Через меню (Рекомендуется)

1. В Project Navigator правой кнопкой на папку `cleaner_ios`
2. Выберите `Add Files to "cleaner_ios"...`
3. Выберите папки:
   - `cleaner_ios/Core/` (полностью)
   - `cleaner_ios/Data/` (полностью)
   - `cleaner_ios/Domain/` (полностью)
   - `cleaner_ios/Presentation/` (полностью)
4. **Важно!** Убедитесь что выбрано:
   - ☑️ Copy items if needed (можно не ставить, файлы уже на месте)
   - ☑️ Create groups (а не folder references)
   - ☑️ Add to targets: cleaner_ios

#### Вариант B: Drag & Drop

1. Откройте Finder
2. Перейдите в `/Users/dmitriyyankovskiy/Documents/projects/cleaner_ios/cleaner_ios/`
3. Перетащите папки `Core`, `Data`, `Domain`, `Presentation` в Project Navigator Xcode
4. В диалоге убедитесь:
   - ☑️ Create groups
   - ☑️ Add to targets: cleaner_ios

### 3. Удалите старые файлы (опционально)

Эти файлы заменены новыми, можно удалить:

**Удалить из проекта (но оставить в файловой системе как backup):**
- `cleaner_ios/Services/ImageEmbeddingService.swift` → заменен на:
  - `Data/Services/MLModelLoader.swift`
  - `Data/Services/EmbeddingGenerator.swift`
  - `Data/Services/SimilarityCalculator.swift`
  - `Data/Services/MobileCLIPEmbeddingService.swift`

- `cleaner_ios/Services/PhotoService.swift` → заменен на:
  - `Presentation/ViewModels/PhotoViewModel.swift`
  - `Domain/UseCases/IndexPhotosUseCase.swift`
  - `Domain/UseCases/GroupSimilarPhotosUseCase.swift`
  - `Domain/UseCases/SearchPhotosUseCase.swift`

- `cleaner_ios/Services/VideoService.swift` → заменен на:
  - `Presentation/ViewModels/VideoViewModel.swift`
  - `Domain/UseCases/IndexVideosUseCase.swift`
  - `Domain/UseCases/GroupSimilarVideosUseCase.swift`

- `cleaner_ios/Services/ClusterService.swift` → заменен на:
  - `Data/Services/LSHClusteringService.swift`

- `cleaner_ios/Services/TranslateSerivce.swift` → заменен на:
  - `Data/Services/GoogleTranslationService.swift`

- `cleaner_ios/AppView.swift` → заменен на:
  - `Presentation/Views/MainTabView.swift`

- `cleaner_ios/cleaner_iosApp.swift` → заменен на:
  - `Core/App/CleanerApp.swift`

**Как удалить:**
1. Выберите файл в Project Navigator
2. Правой кнопкой → Delete
3. Выберите "Remove Reference" (не "Move to Trash")

### 4. Проверьте структуру проекта

Структура должна выглядеть так:

```
cleaner_ios/
├── Core/
│   ├── App/
│   │   ├── CleanerApp.swift
│   │   └── AppDependencyContainer.swift
│   ├── DI/
│   │   ├── ServiceFactory.swift
│   │   └── UseCaseFactory.swift
│   ├── Models/
│   │   ├── Photo.swift
│   │   ├── Video.swift
│   │   └── MediaGroup.swift
│   └── Protocols/
│       ├── EmbeddingServiceProtocol.swift
│       ├── AssetRepositoryProtocol.swift
│       ├── ClusteringServiceProtocol.swift
│       ├── TranslationServiceProtocol.swift
│       └── ImageProcessingProtocol.swift
│
├── Data/
│   ├── Repositories/
│   │   ├── PhotoAssetRepository.swift
│   │   └── VideoAssetRepository.swift
│   └── Services/
│       ├── MLModelLoader.swift
│       ├── EmbeddingGenerator.swift
│       ├── SimilarityCalculator.swift
│       ├── MobileCLIPEmbeddingService.swift
│       ├── LSHClusteringService.swift
│       ├── GoogleTranslationService.swift
│       └── ImageProcessingService.swift
│
├── Domain/
│   └── UseCases/
│       ├── IndexPhotosUseCase.swift
│       ├── GroupSimilarPhotosUseCase.swift
│       ├── SearchPhotosUseCase.swift
│       ├── IndexVideosUseCase.swift
│       └── GroupSimilarVideosUseCase.swift
│
├── Presentation/
│   ├── ViewModels/
│   │   ├── PhotoViewModel.swift
│   │   └── VideoViewModel.swift
│   ├── Views/
│   │   ├── MainTabView.swift
│   │   ├── PhotosTabView.swift
│   │   ├── SearchTabView.swift
│   │   └── VideosTabView.swift
│   └── Components/
│       ├── LoadingView.swift
│       ├── EmptyStateView.swift
│       ├── StatisticCardView.swift
│       └── PhotoThumbnailCard.swift
│
└── (остальные существующие файлы...)
```

### 5. Обновите импорты в существующих файлах

В файле `cleaner_ios/Services/ConfigService.swift` не нужно ничего менять - он используется новыми сервисами.

В файле `cleaner_ios/Tokenizer/CLIPTokenizer.swift` тоже не нужно менять.

### 6. Соберите проект

#### В Xcode:
1. Нажмите `Cmd + B` (Build)
2. Исправьте возможные ошибки компиляции

#### Из терминала:
```bash
cd /Users/dmitriyyankovskiy/Documents/projects/cleaner_ios
xcodebuild -workspace cleaner_ios.xcworkspace \
  -scheme cleaner_ios \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build
```

### 7. Запустите приложение

1. Выберите симулятор: `iPhone 15` (или любой другой)
2. Нажмите `Cmd + R` (Run)

## Возможные ошибки компиляции

### Ошибка: "Cannot find type X in scope"

**Решение:** Убедитесь что файл добавлен в Target Membership:
1. Выберите файл в Project Navigator
2. В File Inspector (справа) проверьте `Target Membership`
3. Убедитесь что `cleaner_ios` отмечен галочкой

### Ошибка: "Duplicate symbol"

**Решение:** Удалите старые файлы из проекта:
- Старый `cleaner_iosApp.swift`
- Старый `AppView.swift`

### Ошибка: "Missing required module"

**Решение:** Проверьте что установлены Pods:
```bash
cd /Users/dmitriyyankovskiy/Documents/projects/cleaner_ios
pod install
```

## Быстрый чеклист

- [ ] Открыт workspace (не project!)
- [ ] Добавлены папки Core, Data, Domain, Presentation
- [ ] Все файлы имеют Target Membership: cleaner_ios
- [ ] Удалены старые файлы из проекта
- [ ] Проект собирается (Cmd + B)
- [ ] Приложение запускается (Cmd + R)

## Если что-то пошло не так

### Вариант 1: Откат
1. Удалите новые папки из Xcode проекта
2. Верните старые файлы обратно
3. Rebuild проекта

### Вариант 2: Чистая пересборка
```bash
# В терминале
cd /Users/dmitriyyankovskiy/Documents/projects/cleaner_ios
rm -rf ~/Library/Developer/Xcode/DerivedData/cleaner_ios-*
pod install
```

Затем в Xcode:
1. Product → Clean Build Folder (Cmd + Shift + K)
2. Product → Build (Cmd + B)

## Поддержка

Если возникли проблемы, проверьте:
1. Все ли файлы добавлены в проект
2. Правильно ли установлен Target Membership
3. Нет ли дублирующихся файлов
4. Собираются ли зависимости (Pods)

## Следующие шаги после успешной сборки

1. Протестируйте индексацию фотографий
2. Протестируйте индексацию видео
3. Протестируйте поиск
4. Проверьте группировку похожих
5. Убедитесь что UI отображается корректно

Удачи! 🚀

