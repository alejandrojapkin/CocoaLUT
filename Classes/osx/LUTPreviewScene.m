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
    self.position = SCNVector3Make(lerpedColor.red, lerpedColor.green, lerpedColor.blue);
    
//    self.geometry.firstMaterial.diffuse.contents = lerpedColor.NSColor;
}
@end

@implementation LUTPreviewScene

- (void)dealloc{
    [self removeObserver:self forKeyPath:@"animationPercentage"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if([keyPath isEqualToString:@"animationPercentage"]){
        [self updateNodePositions];
    }
    else if([keyPath isEqualToString:@"pointOfView"]){
        self.cameraNode = change[NSKeyValueChangeNewKey];
    }

}

- (void)setCameraNode:(SCNNode *)cameraNode{
    if(cameraNode == nil){
        return;
    }
    _cameraNode = cameraNode;
    
    [self updateNodeLookAt];
}

- (void)updateNodeLookAt{
    SCNConstraint *lookAtConstraint = [SCNLookAtConstraint lookAtConstraintWithTarget:self.cameraNode];
    for(LUTColorNode *node in self.dotGroup.childNodes){
        node.constraints = @[lookAtConstraint];
    }
}

- (void)updateNodePositions{
    for(LUTColorNode *node in self.dotGroup.childNodes){
        node.constraints = nil;
        [node changeToAnimationPercentage:self.animationPercentage];
    }  
    [self updateNodeLookAt];
}


+ (instancetype)sceneForLUT:(LUT *)lut{
    
    
    LUT3D *lut3D = LUTAsLUT3D(lut, LATTICE_SIZE);
    
    LUTPreviewScene *scene = [self scene];
    scene.animationPercentage = 1.0;
    [scene addObserver:scene forKeyPath:@"animationPercentage" options:NSKeyValueObservingOptionNew context:NULL];
    
    
    SCNNode *dotGroup = [SCNNode node];
    [scene.rootNode addChildNode:dotGroup];
    
    SCNCamera *camera = [SCNCamera camera];
    camera.xFov = 45;   // Degrees, not radians
    camera.yFov = 45;
    camera.zNear = .001;
    camera.zFar = 5;
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = camera;
    cameraNode.position = SCNVector3Make(.5, .5, 2.237284);
    
    [scene.rootNode addChildNode:cameraNode];
    
    SCNNode __block *centerDot;
    
    
    [lut3D LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *identityColor = [lut3D identityColorAtR:r g:g b:b];
        LUTColor *transformedColor = [lut3D colorAtR:r g:g b:b];
        
//        SCNSphere *dot = [SCNSphere sphereWithRadius:0.0010f];
//        dot.firstMaterial.diffuse.contents = identityColor.NSColor;
        double radius = .0125;
        SCNPlane *dot = [SCNPlane planeWithWidth:2.0*radius height:2.0*radius];
        dot.cornerRadius = radius;
        dot.firstMaterial.diffuse.contents = identityColor.NSColor;
        dot.firstMaterial.cullMode = SCNCullFront;
        //dot.firstMaterial.doubleSided = YES;
        
        LUTColorNode *node = (LUTColorNode*)[LUTColorNode nodeWithGeometry:dot];
        node.identityColor = identityColor;
        node.transformedColor = transformedColor;
        [node changeToAnimationPercentage:scene.animationPercentage];
        
        
        if(r == floor(LATTICE_SIZE/2) || g == floor(LATTICE_SIZE/2) || b == floor(LATTICE_SIZE/2)){
            centerDot = node;
        }
        
        @synchronized(dotGroup) {
            [dotGroup addChildNode:node];
        }
    }];
    
    scene.dotGroup = dotGroup;
    scene.centerDot = centerDot;
    scene.cameraNode = cameraNode;
    
    return scene;
}

@end
