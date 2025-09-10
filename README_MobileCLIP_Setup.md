# Cleaner iOS - Project Setup Guide

## Initial Project Setup

### 1. Installing Dependencies

The project uses CocoaPods for dependency management. Run the following commands:

```bash
# Install CocoaPods (if not already installed)
sudo gem install cocoapods

# Install project dependencies
pod install
```

### 2. Opening the Project

⚠️ **Important:** Always open the `cleaner_ios.xcworkspace` file, not `cleaner_ios.xcodeproj`

```bash
open cleaner_ios.xcworkspace
```

### 3. MobileCLIP Model Setup

## Problem: "Could not find MobileCLIP model"

If you see this error, follow these steps:

### 1. Add the model to your Xcode project

1. Open the project in Xcode
2. Drag the `mobileclip_s0_image.mlpackage` file from the `cleaner_ios/` folder into the project
3. Make sure your main target is selected in the "Add to target" dialog
4. Click "Add"

### 2. Check project settings

1. Select the model file in the project
2. In the Inspector, make sure that:
   - "Target Membership" includes your main target
   - "Build Phases" contains the model

### 3. Alternative solution

If the model is still not found, the code will automatically try to load it from the Documents folder. The model has already been copied there for testing.

### 4. Debug information

The code now outputs detailed debug information to the console:
- 🔍 Model search
- 📁 Bundle paths
- ✅ Successful loading
- ❌ Loading errors

Check the Xcode console for problem diagnostics.

## Model Structure

```
mobileclip_s0_image.mlpackage/
├── Data/
│   └── com.apple.CoreML/
│       ├── model.mlmodel
│       └── weights/
│           └── weight.bin
└── Manifest.json
```

## Testing

After adding the model to the project:
1. Run the application
2. Select an image
3. Tap "Generate Embedding"
4. Check the console for model loading messages

## Project Structure

```
cleaner_ios/
├── cleaner_ios/
│   ├── cleaner_iosApp.swift          # Application entry point
│   ├── AppView.swift                 # Main screen
│   ├── Features/                     # Functional modules
│   ├── Services/                     # Services (ImageEmbedding, Translate)
│   └── mobileclip_s0_image.mlpackage # MobileCLIP model
├── Podfile                          # CocoaPods dependencies
├── Podfile.lock                     # Locked versions
├── cleaner_ios.xcworkspace          # Workspace file (open this one!)
└── .gitignore                       # File ignore rules
```

## Common Issues and Solutions

### Build error with access permissions
If you see an error like "Sandbox: deny file-write-create":
- Make sure User Script Sandboxing is disabled in project settings
- Run `pod install` again

### Model not loading
- Check that the `mobileclip_s0_image.mlpackage` file is added to the project
- Make sure the model is included in Target Membership
- Check the Xcode console for loading errors


## Useful Commands

```bash
# Clean and reinstall dependencies
rm -rf Pods/ Podfile.lock
pod install

# Clear CocoaPods cache
pod cache clean --all

# Build project from command line
xcodebuild -workspace cleaner_ios.xcworkspace -scheme cleaner_ios -destination 'platform=iOS Simulator,name=iPhone 15' build
```

## Support

If you encounter problems:
1. Check the Xcode console for errors
2. Make sure all dependencies are installed correctly
3. Verify the MobileCLIP model setup is correct
