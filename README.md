# 👁️ IRIS - Intelligent Retinal Imaging Systems 👁️
**IRIS** is a Flutter-based application designed to **analyze eye images** and detect possible eye conditions using **AI-powered diagnostics**. Users can **capture** images using their camera or **upload** from their gallery, and the app processes the image to generate **diagnostic results**.

## ✨ Features

- 📷 **Capture Eye Scan**: Use the device camera to take a scan.
- 🖼️ **Upload from Gallery**: Select an image from the gallery for analysis.
- ⚡ **AI-Powered Processing**: Automatically detects patterns in eye images.
- 📊 **Instant Results**: Displays a diagnosis based on the analysis.
- 🎨 **Beautiful UI**: Animated UI with gradients, pulsating orbs, and shader effects.

## 📱 Screenshots

| Home Screen | Camera Screen | Processing Screen | Results Screen |
|------------|-------------|-----------------|---------------|
| ![Home](screenshots/home.png) | ![Camera](screenshots/camera.png) | ![Processing](screenshots/processing.png) | ![Results](screenshots/results.png) |

## 🏗️ Project Structure

```plaintext
📂 lib
 ├── 📂 screens
 │   ├── home_screen.dart        # Home page
 │   ├── camera_screen.dart      # Camera capture screen
 │   ├── gallery_upload_screen.dart # Image picker from gallery
 │   ├── processing_screen.dart  # AI processing animation
 │   ├── results_screen.dart     # Diagnosis results
 ├── 📂 widgets
 │   ├── pulsating_orb.dart      # Animated pulsating effect for processing
 │   ├── animated_background.dart # Dynamic background animations
 │   ├── aurora_background.dart  # Aurora-style gradient shader
 ├── 📂 theme
 │   ├── colors.dart             # Theme colors
 ├── main.dart                   # Entry point
```

## 🚀 Getting Started
### Prerequisites
- Flutter 3.0+
- Dart 2.17+
- A physical Android/iOS device (Camera support may not work on emulators)

### Installation
1. Clone the repository'
   ``` bash
   git clone https://github.com/aywhoosh/IRIS-Ocular-Diagnostics.git
   cd IRIS-Ocular-Diagnostics
2. Install dependencies
   ``` bash
   flutter pub get
3. Run the app!
   ``` bash
   flutter run

## 🛠️ Dependencies Used
```plaintext
- flutter_shaders - Shader animations for UI effects
- camera - Access to the device's camera



