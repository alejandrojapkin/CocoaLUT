//
//  LUTPreviewSceneGenerator.m
//  Pods
//
//  Created by Wil Gieseler on 12/16/13.
//
//

#import "LUTPreviewSceneGenerator.h"

@implementation LUTPreviewSceneGenerator

+ (SCNScene *)sceneForLUT:(LUT *)lut {
    
    LUT *identityLUT = [LUT identityLutOfSize:12];
    
    lut = [lut LUTByResizingToSize:12];
    
    SCNScene *scene = [SCNScene scene];
    
    SCNNode *dotGroup = [SCNNode node];
    [scene.rootNode addChildNode:dotGroup];
    
    float size = lut.lattice.size;
    
    LUTConcurrentCubeLoop(size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColor *identityColor = [identityLUT.lattice colorAtR:r g:g b:b];
        LUTColor *color = [lut.lattice colorAtR:r g:g b:b];
        
        SCNSphere *dot = [SCNSphere sphereWithRadius:0.0015f];
        dot.firstMaterial.diffuse.contents = color.NSColor;
        
        SCNNode *node = [SCNNode nodeWithGeometry:dot];
        node.position = SCNVector3Make(identityColor.red/size, identityColor.green/size, identityColor.blue/size);
        
        
        CABasicAnimation *dotPosition = [CABasicAnimation animationWithKeyPath:@"position"];
        dotPosition.toValue = [NSValue valueWithSCNVector3:SCNVector3Make(color.red/size, color.green/size, color.blue/size)];
        dotPosition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        dotPosition.repeatCount = INFINITY;
        dotPosition.duration = 2.0;
        
        [node addAnimation:dotPosition forKey:@"Animate from Identity to Changed Value"];
        
        @synchronized(dotGroup) {
            [dotGroup addChildNode:node];
        }

    });

    return scene;
}

@end
