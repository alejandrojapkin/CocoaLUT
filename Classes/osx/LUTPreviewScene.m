//
//  LUTPreviewSceneGenerator.m
//  Pods
//
//  Created by Wil Gieseler on 12/16/13.
//
//

#import "LUTPreviewScene.h"

#define LATTICE_SIZE 13.0

@interface LUTColorNode: SCNNode
@property LUTColor *identityColor;
@property LUTColor *transformedColor;
@end

@implementation LUTColorNode
- (void)changeToAnimationPercentage:(float)animationPercentage{
    LUTColor *lerpedColor = [self.identityColor lerpTo:self.transformedColor amount:animationPercentage];
    self.position = SCNVector3Make(lerpedColor.red/LATTICE_SIZE, lerpedColor.green/LATTICE_SIZE, lerpedColor.blue/LATTICE_SIZE);
//    self.geometry.firstMaterial.diffuse.contents = lerpedColor.NSColor;
}
@end

@implementation LUTPreviewScene

- (void)dealloc{
    [self removeObserver:self forKeyPath:@"animationPercentage"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    [self updateNodes];
}

- (void)updateNodes{
    for(LUTColorNode *node in [self.rootNode.childNodes[0] childNodes]){
        [node changeToAnimationPercentage:self.animationPercentage];
    }
    
}

+ (instancetype)sceneForLUT:(LUT *)lut {
    
    
    LUT3D *lut3D = LUTAsLUT3D(lut, LATTICE_SIZE);
    
    LUTPreviewScene *scene = [self scene];
    scene.animationPercentage = 1.0;
    [scene addObserver:scene forKeyPath:@"animationPercentage" options:NSKeyValueObservingOptionNew context:NULL];
    
    
    SCNNode *dotGroup = [SCNNode node];
    [scene.rootNode addChildNode:dotGroup];
    
    [lut3D LUTLoopWithBlock:^(double r, double g, double b) {
        LUTColor *identityColor = [LUTColor colorWithRed:(float)r/(float)(LATTICE_SIZE-1) green:(float)g/(float)(LATTICE_SIZE-1) blue:(float)b/(float)(LATTICE_SIZE-1)];
        LUTColor *transformedColor = [lut3D colorAtR:r g:g b:b];
        
        SCNSphere *dot = [SCNSphere sphereWithRadius:0.0010f];
        dot.firstMaterial.diffuse.contents = identityColor.NSColor;
        
        LUTColorNode *node = (LUTColorNode*)[LUTColorNode nodeWithGeometry:dot];
        node.identityColor = identityColor;
        node.transformedColor = transformedColor;
        [node changeToAnimationPercentage:scene.animationPercentage];
        
        @synchronized(dotGroup) {
            [dotGroup addChildNode:node];
        }
    }];
    
    return scene;
}

@end
