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

@interface LUTPreviewScene : SCNScene

@property float animationPercentage;
@property (strong) SCNNode *dotGroup;

+ (instancetype)sceneForLUT:(LUT *)lut;


@end
