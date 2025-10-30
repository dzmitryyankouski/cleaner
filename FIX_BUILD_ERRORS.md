# 🔧 Исправление ошибок сборки

## Проблема

В проекте есть **конфликты имен** - новые и старые файлы существуют одновременно.

## ❌ Ошибки компиляции:

1. **Дублирование Photo** - `Core/Models/Photo.swift` VS `Services/PhotoService.swift`
2. **Дублирование Video** - `Core/Models/Video.swift` VS `Services/VideoService.swift`  
3. **Два @main** - `cleaner_iosApp.swift` VS `Core/App/CleanerApp.swift`
4. **Дублирование Views** - `Features/Videos/VideosView.swift` VS `Presentation/Views/VideosTabView.swift`

## ✅ Решение: Удалить старые файлы

### Шаг 1: Откройте Xcode

```bash
open /Users/dmitriyyankovskiy/Documents/projects/cleaner_ios/cleaner_ios.xcworkspace
```

### Шаг 2: Удалите эти файлы из проекта

**В Project Navigator найдите и удалите (Remove Reference):**

#### 1️⃣ Старый App файл:
- ❌ `cleaner_ios/cleaner_iosApp.swift` 
  - Заменен на: ✅ `Core/App/CleanerApp.swift`

#### 2️⃣ Старый AppView:
- ❌ `cleaner_ios/AppView.swift`
  - Заменен на: ✅ `Presentation/Views/MainTabView.swift`

#### 3️⃣ Старые сервисы:
- ❌ `cleaner_ios/Services/PhotoService.swift`
  - Заменен на: ✅ `Presentation/ViewModels/PhotoViewModel.swift` + Use Cases

- ❌ `cleaner_ios/Services/VideoService.swift`
  - Заменен на: ✅ `Presentation/ViewModels/VideoViewModel.swift` + Use Cases

- ❌ `cleaner_ios/Services/ImageEmbeddingService.swift`
  - Заменен на: ✅ `Data/Services/MobileCLIPEmbeddingService.swift` + др.

- ❌ `cleaner_ios/Services/ClusterService.swift`
  - Заменен на: ✅ `Data/Services/LSHClusteringService.swift`

- ❌ `cleaner_ios/Services/TranslateSerivce.swift`
  - Заменен на: ✅ `Data/Services/GoogleTranslationService.swift`

#### 4️⃣ Старые Views (папка Features):
- ❌ `cleaner_ios/Features/Photos/PhotosView.swift`
  - Заменен на: ✅ `Presentation/Views/PhotosTabView.swift`

- ❌ `cleaner_ios/Features/Videos/VideosView.swift`
  - Заменен на: ✅ `Presentation/Views/VideosTabView.swift`

- ❌ `cleaner_ios/Features/Search/SearchView.swift`
  - Заменен на: ✅ `Presentation/Views/SearchTabView.swift`

### Как удалять правильно:

1. Выберите файл в Project Navigator
2. Правой кнопкой → **Delete**
3. Выберите **"Remove Reference"** (НЕ "Move to Trash")
   - Это удалит файл из проекта, но оставит на диске как backup

### Шаг 3: Соберите проект

После удаления старых файлов:

1. Clean Build: `Product` → `Clean Build Folder` (Cmd + Shift + K)
2. Build: `Product` → `Build` (Cmd + B)

## Быстрый чеклист удаления

- [ ] ❌ `cleaner_iosApp.swift` - удален
- [ ] ❌ `AppView.swift` - удален
- [ ] ❌ `Services/PhotoService.swift` - удален
- [ ] ❌ `Services/VideoService.swift` - удален
- [ ] ❌ `Services/ImageEmbeddingService.swift` - удален
- [ ] ❌ `Services/ClusterService.swift` - удален
- [ ] ❌ `Services/TranslateSerivce.swift` - удален
- [ ] ❌ `Features/Photos/PhotosView.swift` - удален
- [ ] ❌ `Features/Videos/VideosView.swift` - удален
- [ ] ❌ `Features/Search/SearchView.swift` - удален
- [ ] ✅ Проект собирается без ошибок

## Что НЕ удалять:

✅ `Services/ConfigService.swift` - используется новым кодом  
✅ `Tokenizer/CLIPTokenizer.swift` - используется новым кодом  
✅ `Features/Files/FilesView.swift` - еще не заменен  
✅ `Features/Settings/SettingsView.swift` - еще не заменен  

## После удаления

Проект должен собраться успешно! Все функции будут работать через новую архитектуру.

## Если что-то пошло не так

### Вариант 1: Вернуть старые файлы
Они физически на диске, просто перетащите обратно в Xcode

### Вариант 2: Полная очистка
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/cleaner_ios-*
```
Затем в Xcode: Clean + Build

## Автоматическое удаление (опционально)

Если хотите удалить физически с диска (ОСТОРОЖНО!):

```bash
cd /Users/dmitriyyankovskiy/Documents/projects/cleaner_ios

# Создаем backup
mkdir -p ../backup_old_files
cp cleaner_ios/cleaner_iosApp.swift ../backup_old_files/
cp cleaner_ios/AppView.swift ../backup_old_files/
cp -r cleaner_ios/Services ../backup_old_files/
cp -r cleaner_ios/Features ../backup_old_files/

echo "✅ Backup создан в ../backup_old_files/"
```

Но лучше удалять через Xcode с "Remove Reference"!

## Готово!

После удаления старых файлов проект соберется и заработает! 🚀

