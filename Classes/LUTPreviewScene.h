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

@interface LUTPreviewSceneViewController : NSObject

@property (assign, nonatomic) double animationPercentage;
@property (weak) IBOutlet SCNView *sceneView;

- (void)setSceneWithLUT:(LUT *)lut;

@end

@interface LUTPreviewScene : SCNScene

@property (strong, nonatomic) SCNNode *dotGroup;
@property (strong, nonatomic) SCNNode *gridLines;

- (void)updateNodesToPercentage:(double)percentage;

+ (instancetype)sceneForLUT:(LUT *)lut;


@end
