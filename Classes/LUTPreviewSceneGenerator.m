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
    
    lut = [lut LUTByResizingToSize:10];
    
    SCNScene *scene = [SCNScene scene];
    
    SCNNode *dotGroup = [SCNNode node];
    [scene.rootNode addChildNode:dotGroup];
    
    float size = lut.lattice.size;
    
    LUTConcurrentCubeLoop(size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColor *color = [lut.lattice colorAtR:r g:g b:b];
        
        SCNSphere *dot = [SCNSphere sphereWithRadius:0.005f];
        dot.firstMaterial.diffuse.contents = color.NSColor;
        
        SCNNode *node = [SCNNode nodeWithGeometry:dot];
        node.position = SCNVector3Make(color.red/size, color.green/size, color.blue/size);
        
        
        [dotGroup addChildNode:node];

    });

    return scene;
}

@end
