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
    
    // An empty scene
    SCNScene *scene = [SCNScene scene];
    
    SCNNode *dotGroup = [SCNNode node];
    [scene.rootNode addChildNode:dotGroup];
    
    
    float size = lut.lattice.size;
    
    for (int r = 0; r < size; r++) {
        for (int g = 0; g < size; g++) {
            for (int b = 0; b < size; b++) {
                LUTColor *color = [lut.lattice colorAtR:r g:g b:b];
                
                SCNSphere *dot = [SCNSphere sphereWithRadius:0.005f];
                dot.firstMaterial.diffuse.contents = color.NSColor;

                SCNNode *node = [SCNNode nodeWithGeometry:dot];
                node.position = SCNVector3Make(color.red/size, color.green/size, color.blue/size);
                

                [dotGroup addChildNode:node];
            }
        }
    }

    
    // A camera
//    SCNNode *cameraNode = [SCNNode node];
//    cameraNode.camera = [SCNCamera camera];
//    cameraNode.position = SCNVector3Make(0, 15, 30);
//    cameraNode.transform = CATransform3DRotate(cameraNode.transform,
//                                               -M_PI/7.0,
//                                               1, 0, 0);
//    
//    [scene.rootNode addChildNode:cameraNode];
    
    // A spotlight
//    SCNLight *spotLight = [SCNLight light];
//    spotLight.type = SCNLightTypeSpot;
//    spotLight.color = [NSColor redColor];
//    SCNNode *spotLightNode = [SCNNode node];
//    spotLightNode.light = spotLight;
//    spotLightNode.position = SCNVector3Make(-2, 1, 0);
//    
//    [cameraNode addChildNode:spotLightNode];
    
    // A square box
//    CGFloat boxSide = 15.0;
//    SCNBox *box = [SCNBox boxWithWidth:boxSide
//                                height:boxSide
//                                length:boxSide
//                         chamferRadius:0];
//    SCNNode *boxNode = [SCNNode nodeWithGeometry:box];
//    boxNode.transform = CATransform3DMakeRotation(M_PI_2/3, 0, 1, 0);
//    
//    [scene.rootNode addChildNode:boxNode];

    return scene;
}

@end
