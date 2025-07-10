# YOLOv4 Detector for iOS

iOS app for running live object detection with YOLOv4 models on your phone's camera feed. Import your own models trained with Darknet using the Model Manager. Detection is done with OpenCV's DNN module. No need to convert the weights to another format.

## Features

- **Real-time Object Detection**: Use YOLOv4-Tiny for efficient mobile inference
- **Model Management**: Import and manage custom YOLO models
- **Adjustable Parameters**: Fine-tune confidence and NMS thresholds in real-time
- **Performance Metrics**: Live FPS and inference time display
- **Camera Controls**: Flash toggle, camera switching (front/back)
- **SwiftUI Interface**: Modern, intuitive interface with smooth animations

## Screenshots

*TBD - Screenshots coming soon*

## Requirements

- iOS 15.0 or higher
- Device with camera (simulator not supported)

## Installation

### Option 1: Download from App Store

*Coming soon*

### Option 2: Build from Source

#### Prerequisites
- Latest version of Xcode
- macOS 12.0 or later
- CocoaPods

#### Steps

1. Clone the repository:
   ```bash
   git clone https://github.com/TommiHonkanen/yolov4-detector-ios.git
   cd yolov4-detector-ios
   ```

2. Install dependencies:
   ```bash
   pod install
   ```

3. Open the workspace in Xcode:
   ```bash
   open yolov4-detector.xcworkspace
   ```

4. Select your development team and build on device
   
## Usage

### Basic Operation

1. **Grant Camera Permission** when prompted on first launch
2. **Point camera** at objects to detect
3. **View detections** with bounding boxes and confidence scores

### Controls

- **Pause/Resume**: Tap the pause button to freeze detection
- **Flash**: Toggle camera flash on/off
- **Switch Camera**: Switch between front and back cameras
- **Settings**: Adjust detection thresholds
- **Models**: Access model managerd
- **About**: View app information

### Threshold Settings

- **Confidence Threshold** (default: 25%): Minimum confidence for detections
- **NMS Threshold** (default: 45%): Non-maximum suppression for overlapping boxes

### Model Management

The app includes YOLOv4-Tiny trained on COCO dataset (80 classes) by default. You can import custom models:

1. Open the **Model Manager**
2. Tap the **+** button 
3. Import the three files into their corresponding slots:
   - `.weights` - Neural network weights
   - `.cfg` - Network architecture configuration  
   - `.names` - Class labels (one per line)
4. Enter a name for the model and press **Import**

## Supported Models

The app supports Darknet YOLO format models. Tested configurations:

- YOLOv4
- YOLOv4-Tiny
- YOLOv4-Tiny-3l

### Model Requirements

- Input size must be square (e.g., 416x416, 608x608)
- Config file must contain proper [net] and [yolo] sections
- Names file must have one class label per line

## Architecture

### Core Components

- **ContentView**: Main view and UI coordination
- **YOLOv4Detector**: YOLO inference engine using OpenCV DNN
- **ModelManager**: Model storage and configuration
- **DetectionOverlayView**: Real-time visualization

### Technical Stack

- **Language**: Swift
- **Camera**: AVFoundation
- **ML Framework**: OpenCV DNN module
- **UI**: SwiftUI
- **Architecture**: MVVM pattern with Combine

## Performance

Typical performance on modern devices:
- YOLOv4-Tiny: 10-20 FPS
- YOLOv4: 1-5 FPS

Performance varies based on:
- Device processing power
- Network dimensions

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Joseph Redmon (pjreddie)](https://pjreddie.com/) - Original YOLO author and Darknet framework creator
- [Alexey Bochkovskiy (AlexeyAB)](https://github.com/AlexeyAB/darknet) - YOLOv4 author and Darknet maintainer
- [Stéphane Charette](https://www.ccoderun.ca/darknet/) - Darknet/YOLO maintainer and creator of DarkHelp and DarkMark
- [OpenCV](https://opencv.org/) - Computer vision library
