# Photo Analyzer

A modern iOS app that captures photos using the iPhone camera and stores them in a custom "Photo Analyzer" album with an Instagram-like interface.

## Features

- 📸 **Modern Camera Interface**: Full-screen camera with flash control, camera switching, and capture button
- 🖼️ **Photo Gallery**: Instagram-style grid layout displaying all captured photos
- 📱 **Photo Library Integration**: Automatically creates and manages a "Photo Analyzer" album
- 🤖 **AI Photo Analysis**: Local AI analysis using Vision framework and Core ML
- 🔍 **Comprehensive Detection**: Labels, objects, faces, and text recognition
- 📊 **Analysis Results**: Detailed analysis reports with confidence scores
- 🎨 **Modern UI**: Dark theme with gradient backgrounds and smooth animations
- 💾 **Data Persistence**: Stores analysis results locally for future reference

## Screenshots

The app features:
- Permission request screen for camera and photo library access
- Full-screen camera interface with controls
- Photo gallery with grid layout
- Photo detail view with analysis capabilities

## Technical Details

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Local data persistence for photo metadata and analysis results
- **AVFoundation**: Camera capture and photo processing
- **Photos Framework**: Photo library access and album management
- **Vision Framework**: AI-powered image analysis and recognition
- **Core ML**: Machine learning model integration for advanced analysis

### Key Components

1. **PhotoManager**: Handles camera permissions, photo capture, and album management
2. **AIAnalyzer**: Local AI analysis using Vision framework and Core ML
3. **CameraView**: Full-screen camera interface with AVFoundation
4. **GalleryView**: Instagram-style photo grid
5. **PhotoDetailView**: Full-screen photo viewing with analysis features
6. **AnalysisResultsView**: Comprehensive analysis results display
7. **ContentView**: Main app interface with navigation

### Permissions Required

The app requires the following permissions:
- **Camera Access**: To capture photos
- **Photo Library Access**: To save photos to the custom album
- **Photo Library Add Access**: To create and manage the "Photo Analyzer" album

## Getting Started

1. Open the project in Xcode
2. Build and run on a physical iOS device (camera features require a real device)
3. Grant camera and photo library permissions when prompted
4. Start taking photos!

## Usage

1. **Taking Photos**: Tap the camera button to open the full-screen camera
2. **Camera Controls**: 
   - Tap the capture button to take a photo
   - Use the flash button to toggle flash on/off
   - Use the camera switch button to switch between front/back cameras
   - Tap "Cancel" to return to the gallery
3. **Viewing Photos**: Tap any photo in the gallery to view it full-screen
4. **Photo Analysis**: Use the "Analyze Photo" button in the detail view to run local AI analysis
5. **View Results**: Tap "View Analysis" or "View Full Results" to see detailed AI analysis

## AI Analysis Features

The app includes comprehensive local AI analysis capabilities:

- **Image Classification**: Identifies objects, scenes, and content in photos
- **Object Detection**: Detects and locates objects within images
- **Face Detection**: Recognizes faces and facial landmarks
- **Text Recognition**: Extracts and reads text from images
- **Confidence Scoring**: Provides confidence levels for all detections
- **Local Processing**: All analysis runs locally on device for privacy

## Future Enhancements

- Custom Core ML model integration
- Advanced photo editing capabilities
- Sharing features with analysis results
- Cloud sync for analysis data
- Advanced camera features (filters, effects)
- Photo organization and tagging based on AI analysis
- Batch analysis for multiple photos

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Physical iOS device (for camera functionality)

## License

This project is created for educational and development purposes.
