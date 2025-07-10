//
//  OpenCVWrapper.mm
//  yolov4detector
//

#import <opencv2/opencv.hpp>
#import <opencv2/dnn.hpp>
#import <opencv2/imgcodecs/ios.h>
#import "OpenCVWrapper.h"
#import <vector>
#import <string>
#import <fstream>
#import <chrono>

@implementation DetectionResult
@end

@interface OpenCVWrapper () {
    cv::dnn::Net net;
    std::vector<std::string> classNames;
    cv::Size2f inputSize;
    double inferenceTime;
    UIImage *_lastPreprocessedImage;
}
- (std::vector<std::string>)getOutputNames;
@end

@implementation OpenCVWrapper

@synthesize lastPreprocessedImage = _lastPreprocessedImage;

- (instancetype)initWithModelPath:(NSString *)modelPath
                       configPath:(NSString *)configPath
                        namesPath:(NSString *)namesPath {
    self = [super init];
    if (self) {
        // Load YOLO model
        std::string modelPathStr = [modelPath UTF8String];
        std::string configPathStr = [configPath UTF8String];
        
        net = cv::dnn::readNet(modelPathStr, configPathStr);
        
        if (net.empty()) {
            return nil;
        }
        
        // Set preferable backend and target
        net.setPreferableBackend(cv::dnn::DNN_BACKEND_OPENCV);
        net.setPreferableTarget(cv::dnn::DNN_TARGET_CPU);
        
        // Load class names
        std::string namesPathStr = [namesPath UTF8String];
        std::ifstream ifs(namesPathStr);
        std::string line;
        while (std::getline(ifs, line)) {
            classNames.push_back(line);
        }
        
        // Extract input size from config file
        [self extractInputSizeFromConfig:configPath];
    }
    return self;
}

- (void)extractInputSizeFromConfig:(NSString *)configPath {
    std::ifstream configFile([configPath UTF8String]);
    std::string line;
    int width = 416, height = 416; // Default values
    
    while (std::getline(configFile, line)) {
        if (line.find("width=") != std::string::npos) {
            width = std::stoi(line.substr(line.find("=") + 1));
        } else if (line.find("height=") != std::string::npos) {
            height = std::stoi(line.substr(line.find("=") + 1));
        }
    }
    
    inputSize = cv::Size2f(width, height);
}

- (NSArray<DetectionResult *> *)detectObjectsInSampleBuffer:(CMSampleBufferRef)sampleBuffer
                                         confidenceThreshold:(float)confThreshold
                                                nmsThreshold:(float)nmsThreshold {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    // Log buffer dimensions only once
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // Get the current device orientation
        UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
        
        // Check if buffer has any rotation info
        CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
        if (attachments) {
            // NSLog(@"Sample buffer attachments: %@", (__bridge NSDictionary *)attachments);
            CFRelease(attachments);
        }
    });
    
    cv::Mat mat((int)height, (int)width, CV_8UC4, baseAddress, bytesPerRow);
    cv::Mat bgrMat;
    cv::cvtColor(mat, bgrMat, cv::COLOR_BGRA2BGR);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    // For portrait-only app, camera buffer comes in landscape (1920x1080)
    // Always rotate to portrait (1080x1920)
    cv::Mat processedMat;
    CGSize processedSize;
    cv::transpose(bgrMat, processedMat);
    cv::flip(processedMat, processedMat, 1); // Flip along y-axis
    processedSize = CGSizeMake(height, width); // Swap dimensions
    
    /*
    
    if (width > height) {
        // Rotate 90 degrees clockwise to convert landscape to portrait
        cv::transpose(bgrMat, processedMat);
        cv::flip(processedMat, processedMat, 1); // Flip along y-axis
        processedSize = CGSizeMake(height, width); // Swap dimensions
    } else {
        // Already in portrait orientation
        processedMat = bgrMat;
        processedSize = CGSizeMake(width, height);
    }
     
     */
    
    NSArray<DetectionResult *> *results = [self detectObjectsInMat:processedMat
                                               confidenceThreshold:confThreshold
                                                      nmsThreshold:nmsThreshold
                                                      originalSize:processedSize];
    
    return results;
}

- (NSArray<DetectionResult *> *)detectObjectsInImage:(UIImage *)image
                                 confidenceThreshold:(float)confThreshold
                                         nmsThreshold:(float)nmsThreshold {
    cv::Mat mat;
    UIImageToMat(image, mat);
    
    cv::Mat bgrMat;
    cv::cvtColor(mat, bgrMat, cv::COLOR_RGBA2BGR);
    
    return [self detectObjectsInMat:bgrMat
                confidenceThreshold:confThreshold
                       nmsThreshold:nmsThreshold
                       originalSize:image.size];
}

- (NSArray<DetectionResult *> *)detectObjectsInMat:(cv::Mat)image
                               confidenceThreshold:(float)confThreshold
                                      nmsThreshold:(float)nmsThreshold
                                      originalSize:(CGSize)originalSize {
    NSMutableArray<DetectionResult *> *results = [NSMutableArray array];
    
    // Create blob from image
    cv::Mat blob;
    double scaleFactor = 1.0 / 255.0;
    cv::Size size(inputSize.width, inputSize.height);
    cv::Scalar mean = cv::Scalar(0, 0, 0);
    bool swapRB = true;
    bool crop = false;
    
    // Capture the image as it is passed to blobFromImage
    // This is after rotation but before any RGB conversion or resizing
    _lastPreprocessedImage = MatToUIImage(image);
    
    cv::dnn::blobFromImage(image, blob, scaleFactor, size, mean, swapRB, crop);
    
    // Set input
    net.setInput(blob);
    
    // Run forward pass
    std::vector<cv::Mat> outputs;
    auto start = std::chrono::high_resolution_clock::now();
    net.forward(outputs, [self getOutputNames]);
    auto end = std::chrono::high_resolution_clock::now();
    
    inferenceTime = std::chrono::duration<double, std::milli>(end - start).count();
    
    // Post-process detections
    std::vector<int> classIds;
    std::vector<float> confidences;
    std::vector<cv::Rect> boxes;
    
    for (const auto& output : outputs) {
        for (int i = 0; i < output.rows; i++) {
            const float* data = output.ptr<float>(i);
            float confidence = data[4];
            
            if (confidence > confThreshold) {
                // YOLO outputs are normalized [0,1] - log raw values
                float rawCenterX = data[0];
                float rawCenterY = data[1];
                float rawWidth = data[2];
                float rawHeight = data[3];
                
                int centerX = (int)(rawCenterX * originalSize.width);
                int centerY = (int)(rawCenterY * originalSize.height);
                int width = (int)(rawWidth * originalSize.width);
                int height = (int)(rawHeight * originalSize.height);
                
                int left = centerX - width / 2;
                int top = centerY - height / 2;
                
                
                cv::Mat scores = output.row(i).colRange(5, output.cols);
                cv::Point classIdPoint;
                double maxScore;
                cv::minMaxLoc(scores, 0, &maxScore, 0, &classIdPoint);
                
                if (maxScore > confThreshold) {
                    boxes.push_back(cv::Rect(left, top, width, height));
                    confidences.push_back((float)maxScore);
                    classIds.push_back(classIdPoint.x);
                }
            }
        }
    }
    
    // Apply NMS
    std::vector<int> indices;
    cv::dnn::NMSBoxes(boxes, confidences, confThreshold, nmsThreshold, indices);
    
    // Create detection results
    for (int idx : indices) {
        DetectionResult *detection = [[DetectionResult alloc] init];
        detection.classId = classIds[idx];
        detection.className = classIds[idx] < classNames.size() ? 
            [NSString stringWithUTF8String:classNames[classIds[idx]].c_str()] : @"Unknown";
        detection.confidence = confidences[idx];
        detection.boundingBox = CGRectMake(boxes[idx].x, boxes[idx].y, 
                                         boxes[idx].width, boxes[idx].height);
        
        
        [results addObject:detection];
    }
    
    return results;
}

- (std::vector<std::string>)getOutputNames {
    std::vector<std::string> names;
    std::vector<int> outLayers = net.getUnconnectedOutLayers();
    std::vector<std::string> layersNames = net.getLayerNames();
    
    names.resize(outLayers.size());
    for (size_t i = 0; i < outLayers.size(); ++i) {
        names[i] = layersNames[outLayers[i] - 1];
    }
    return names;
}

- (double)lastInferenceTime {
    return inferenceTime;
}

- (CGSize)inputSize {
    return CGSizeMake(inputSize.width, inputSize.height);
}

@end
