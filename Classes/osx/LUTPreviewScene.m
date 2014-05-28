//
//  LUTPreviewSceneGenerator.m
//  Pods
//
//  Created by Wil Gieseler on 12/16/13.
//
//

#import "LUTPreviewScene.h"

#define LATTICE_SIZE 18

@interface LUTColorNode: SCNNode
@property LUTColor *identityColor;
@property LUTColor *transformedColor;
@end

@implementation LUTColorNode
- (void)changeToAnimationPercentage:(float)animationPercentage{
//    LUTColor *lerpedColor = [self.identityColor lerpTo:self.transformedColor amount:animationPercentage];
    self.position = SCNVector3Make(lerp1d(self.identityColor.red, self.transformedColor.red, animationPercentage), lerp1d(self.identityColor.green, self.transformedColor.green, animationPercentage), lerp1d(self.identityColor.blue, self.transformedColor.blue, animationPercentage));
//    self.geometry.firstMaterial.diffuse.contents = lerpedColor.NSColor;
}
@end

@implementation LUTPreviewSceneView

- (void)setScene:(SCNScene *)scene{
    [super setScene:scene];
    [(LUTPreviewScene *)self.scene setAnimationPercentage:1.0];
    [(LUTPreviewScene *)self.scene updateNodes];
}

@end

@implementation LUTPreviewScene

- (void)dealloc{
    [self removeObserver:self forKeyPath:@"animationPercentage"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if([keyPath isEqualToString:@"animationPercentage"]){
        [self updateNodes];
    }
             
}

- (void)updateNodes{
    for(LUTColorNode *node in self.dotGroup.childNodes){
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
    
    double radius;
    double initialAnimationPercentage;
    
    double minimumOutputValue = lut3D.minimumOutputValue;
    double maximumOutputValue = lut3D.maximumOutputValue;
    
    if((maximumOutputValue - minimumOutputValue) > (lut3D.inputUpperBound - lut3D.inputLowerBound)){
        initialAnimationPercentage = 1.0;
        radius = .013 * clampLowerBound(maximumOutputValue - minimumOutputValue, 1);
    }
    else{
        initialAnimationPercentage = 0.0;
        radius = .013 * clampLowerBound(lut3D.inputUpperBound - lut3D.inputLowerBound, 1);
    }
    
    
    [lut3D LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *identityColor = [lut3D identityColorAtR:r g:g b:b];
        LUTColor *transformedColor = [lut3D colorAtR:r g:g b:b];
        
        
        
        //SCNSphere *dot = [SCNSphere sphereWithRadius:radius];
        //dot.firstMaterial.diffuse.contents = identityColor.NSColor;
        
        
//        SCNPlane *dot = [SCNPlane planeWithWidth:2.0*radius height:2.0*radius];
//        dot.cornerRadius = radius;
//        dot.firstMaterial.diffuse.contents = identityColor.NSColor;
//        [dot.firstMaterial setDoubleSided:YES];
        
        SCNBox *dot = [SCNBox boxWithWidth:2.0*radius height:2.0*radius length:2.0*radius chamferRadius:radius];
        dot.chamferSegmentCount = 1.0; //efficient for rendering but makes it look like a polygon
        dot.firstMaterial.diffuse.contents = [identityColor remappedFromInputLow:lut3D.inputLowerBound inputHigh:lut3D.inputUpperBound outputLow:0 outputHigh:1 bounded:NO].NSColor;
        
        LUTColorNode *node = (LUTColorNode*)[LUTColorNode nodeWithGeometry:dot];
        node.identityColor = identityColor;
        node.transformedColor = transformedColor;
        [node changeToAnimationPercentage:initialAnimationPercentage];
        
        @synchronized(dotGroup) {
            
            [dotGroup addChildNode:node];
        }
    }];
    
    scene.dotGroup = dotGroup;
    
    return scene;
}

@end
