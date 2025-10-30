#!/bin/bash

echo "🔍 Проверка наличия всех рефакторенных файлов..."
echo ""

MISSING=0

# Протоколы
FILES_PROTOCOLS=(
    "cleaner_ios/Core/Protocols/EmbeddingServiceProtocol.swift"
    "cleaner_ios/Core/Protocols/AssetRepositoryProtocol.swift"
    "cleaner_ios/Core/Protocols/ClusteringServiceProtocol.swift"
    "cleaner_ios/Core/Protocols/TranslationServiceProtocol.swift"
    "cleaner_ios/Core/Protocols/ImageProcessingProtocol.swift"
)

# Модели
FILES_MODELS=(
    "cleaner_ios/Core/Models/Photo.swift"
    "cleaner_ios/Core/Models/Video.swift"
    "cleaner_ios/Core/Models/MediaGroup.swift"
)

# DI
FILES_DI=(
    "cleaner_ios/Core/DI/ServiceFactory.swift"
    "cleaner_ios/Core/DI/UseCaseFactory.swift"
    "cleaner_ios/Core/App/AppDependencyContainer.swift"
    "cleaner_ios/Core/App/CleanerApp.swift"
)

# Сервисы
FILES_SERVICES=(
    "cleaner_ios/Data/Services/MLModelLoader.swift"
    "cleaner_ios/Data/Services/EmbeddingGenerator.swift"
    "cleaner_ios/Data/Services/SimilarityCalculator.swift"
    "cleaner_ios/Data/Services/MobileCLIPEmbeddingService.swift"
    "cleaner_ios/Data/Services/LSHClusteringService.swift"
    "cleaner_ios/Data/Services/GoogleTranslationService.swift"
    "cleaner_ios/Data/Services/ImageProcessingService.swift"
)

# Репозитории
FILES_REPOSITORIES=(
    "cleaner_ios/Data/Repositories/PhotoAssetRepository.swift"
    "cleaner_ios/Data/Repositories/VideoAssetRepository.swift"
)

# Use Cases
FILES_USECASES=(
    "cleaner_ios/Domain/UseCases/IndexPhotosUseCase.swift"
    "cleaner_ios/Domain/UseCases/GroupSimilarPhotosUseCase.swift"
    "cleaner_ios/Domain/UseCases/SearchPhotosUseCase.swift"
    "cleaner_ios/Domain/UseCases/IndexVideosUseCase.swift"
    "cleaner_ios/Domain/UseCases/GroupSimilarVideosUseCase.swift"
)

# ViewModels
FILES_VIEWMODELS=(
    "cleaner_ios/Presentation/ViewModels/PhotoViewModel.swift"
    "cleaner_ios/Presentation/ViewModels/VideoViewModel.swift"
)

# Views
FILES_VIEWS=(
    "cleaner_ios/Presentation/Views/MainTabView.swift"
    "cleaner_ios/Presentation/Views/PhotosTabView.swift"
    "cleaner_ios/Presentation/Views/SearchTabView.swift"
    "cleaner_ios/Presentation/Views/VideosTabView.swift"
)

# Components
FILES_COMPONENTS=(
    "cleaner_ios/Presentation/Components/LoadingView.swift"
    "cleaner_ios/Presentation/Components/EmptyStateView.swift"
    "cleaner_ios/Presentation/Components/StatisticCardView.swift"
    "cleaner_ios/Presentation/Components/PhotoThumbnailCard.swift"
)

check_files() {
    local category=$1
    shift
    local files=("$@")
    
    echo "📁 $category:"
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            echo "  ✅ $file"
        else
            echo "  ❌ $file - ОТСУТСТВУЕТ!"
            MISSING=$((MISSING + 1))
        fi
    done
    echo ""
}

check_files "Протоколы" "${FILES_PROTOCOLS[@]}"
check_files "Модели" "${FILES_MODELS[@]}"
check_files "DI & App" "${FILES_DI[@]}"
check_files "Сервисы" "${FILES_SERVICES[@]}"
check_files "Репозитории" "${FILES_REPOSITORIES[@]}"
check_files "Use Cases" "${FILES_USECASES[@]}"
check_files "ViewModels" "${FILES_VIEWMODELS[@]}"
check_files "Views" "${FILES_VIEWS[@]}"
check_files "Components" "${FILES_COMPONENTS[@]}"

echo "================================================"
if [ $MISSING -eq 0 ]; then
    echo "✅ Все файлы на месте!"
    echo "📝 Теперь нужно добавить их в Xcode проект"
    echo "   См. XCODE_PROJECT_SETUP.md"
else
    echo "❌ Отсутствует файлов: $MISSING"
    echo "   Проверьте что все файлы созданы"
fi
echo "================================================"
