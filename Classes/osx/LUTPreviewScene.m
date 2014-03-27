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
- (void)moveToAnimationPercentage:(float)animationPercentage{
    LUTColor *lerpedColor = [self.identityColor lerpTo:self.transformedColor amount:animationPercentage];
    self.position = SCNVector3Make(lerpedColor.red/LATTICE_SIZE, lerpedColor.green/LATTICE_SIZE, lerpedColor.blue/LATTICE_SIZE);
}
@end

@implementation LUTPreviewScene


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    [self updateNodePositions];
}

- (void)updateNodePositions{
    for(LUTColorNode *node in [self.rootNode.childNodes[0] childNodes]){
        [node moveToAnimationPercentage:self.animationPercentage];
    }
    
}

+ (instancetype)sceneForLUT:(LUT *)lut {
    
    lut = [lut LUTByResizingToSize:LATTICE_SIZE];
    
    LUTPreviewScene *scene = [self scene];
    
    SCNNode *dotGroup = [SCNNode node];
    [scene.rootNode addChildNode:dotGroup];
    
    float size = lut.lattice.size;
    [SCNTransaction begin];
    LUTConcurrentCubeLoop(size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {

        LUTColor *identityColor =[LUTColor colorWithRed:(float)r/(float)(LATTICE_SIZE-1) green:(float)g/(float)(LATTICE_SIZE-1) blue:(float)b/(float)(LATTICE_SIZE-1)];
        LUTColor *transformedColor = [lut.lattice colorAtR:r g:g b:b];
        
        SCNSphere *dot = [SCNSphere sphereWithRadius:0.0010f];
        dot.firstMaterial.diffuse.contents = identityColor.NSColor;
        
        LUTColorNode *node = (LUTColorNode*)[LUTColorNode nodeWithGeometry:dot];
        node.identityColor = identityColor;
        node.transformedColor = transformedColor;
        [node moveToAnimationPercentage:scene.animationPercentage];
        
        @synchronized(dotGroup) {
            [dotGroup addChildNode:node];
        }

    });
    [SCNTransaction commit];
    
    [scene addObserver:scene forKeyPath:@"animationPercentage" options:NSKeyValueObservingOptionNew context:NULL];

    return scene;
}

@end
