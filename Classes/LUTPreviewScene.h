//
//  LUTPreviewSceneGenerator.h
//  Pods
//
//  Created by Wil Gieseler on 12/16/13.
//
//

#import <Foundation/Foundation.h>
#import <SceneKit/SceneKit.h>
#import "CocoaLUT.h"

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#elif TARGET_OS_MAC
@interface LUTPreviewSceneViewController : NSViewController

@property (assign, nonatomic) double animationPercentage;

- (void)setSceneWithLUT:(LUT *)lut;

@end
#endif

@interface LUTPreviewScene : SCNScene

@property (strong, nonatomic) SCNNode *dotGroup;
@property (strong, nonatomic) SCNNode *cubeOutline;
@property (strong, nonatomic) SCNNode *axes;

- (void)updateNodesToPercentage:(double)percentage;

+ (instancetype)sceneForLUT:(LUT *)lut;


@end
