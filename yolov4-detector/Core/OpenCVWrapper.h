//
//  OpenCVWrapper.h
//  yolov4-detector
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DetectionResult : NSObject
@property (nonatomic) int classId;
@property (nonatomic, strong) NSString *className;
@property (nonatomic) float confidence;
@property (nonatomic) CGRect boundingBox;
@end

@interface OpenCVWrapper : NSObject

- (instancetype)initWithModelPath:(NSString *)modelPath
                       configPath:(NSString *)configPath
                        namesPath:(NSString *)namesPath;

- (NSArray<DetectionResult *> *)detectObjectsInSampleBuffer:(CMSampleBufferRef)sampleBuffer
                                         confidenceThreshold:(float)confThreshold
                                                nmsThreshold:(float)nmsThreshold;

- (NSArray<DetectionResult *> *)detectObjectsInImage:(UIImage *)image
                                 confidenceThreshold:(float)confThreshold
                                         nmsThreshold:(float)nmsThreshold;

@property (nonatomic, readonly) double lastInferenceTime;
@property (nonatomic, readonly) CGSize inputSize;
@property (nonatomic, readonly, nullable) UIImage *lastPreprocessedImage;

@end

NS_ASSUME_NONNULL_END