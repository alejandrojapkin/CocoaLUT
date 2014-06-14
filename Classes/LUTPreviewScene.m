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

@implementation LUTPreviewSceneViewController

- (void)setSceneWithLUT:(LUT *)lut{
    self.sceneView.scene = [LUTPreviewScene sceneForLUT:lut];
    self.animationPercentage = 1.0;
}

- (void)setAnimationPercentage:(double)animationPercentage{
    _animationPercentage = animationPercentage;
    [(LUTPreviewScene *)self.sceneView.scene updateNodesToPercentage:animationPercentage];
}

@end

@implementation LUTPreviewScene

- (void)updateNodesToPercentage:(double)percentage{
    for(LUTColorNode *node in self.dotGroup.childNodes){
        [node changeToAnimationPercentage:percentage];
    }
}

- (void)setDotGroup:(SCNNode *)dotGroup{
    _dotGroup = dotGroup;
    [self.rootNode addChildNode:_dotGroup];
}

- (void)setGridLines:(SCNNode *)gridLines{
    _gridLines = gridLines;
    [self.rootNode addChildNode:_gridLines];
}

+ (instancetype)sceneForLUT:(LUT *)lut {
    
    
    LUT3D *lut3D = LUTAsLUT3D(lut, MIN(LATTICE_SIZE, lut.size));
    
    LUTPreviewScene *scene = [self scene];
    
    
    
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
    
    
    SCNNode *dotGroup = [SCNNode node];
    
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
        
        #if TARGET_OS_IPHONE
        dot.firstMaterial.diffuse.contents = [identityColor remappedFromInputLow:lut3D.inputLowerBound inputHigh:lut3D.inputUpperBound outputLow:0 outputHigh:1 bounded:NO].UIColor;
        #elif TARGET_OS_MAC
        dot.firstMaterial.diffuse.contents = [identityColor remappedFromInputLow:lut3D.inputLowerBound inputHigh:lut3D.inputUpperBound outputLow:0 outputHigh:1 bounded:NO].NSColor;
        #endif
        
        LUTColorNode *node = (LUTColorNode*)[LUTColorNode nodeWithGeometry:dot];
        node.identityColor = identityColor;
        node.transformedColor = transformedColor;
        [node changeToAnimationPercentage:initialAnimationPercentage];
        
        @synchronized(dotGroup) {
            
            [dotGroup addChildNode:node];
        }
    }];
    
    scene.dotGroup = dotGroup;
    
    scene.gridLines = [[self class] gridLinesWithInputLowerBound:lut3D.inputLowerBound
                                                 inputUpperBound:lut3D.inputUpperBound
                                                          radius:radius/2.0
                                                         opacity:.3];
    
    
    return scene;
}

+ (SCNNode *)gridLinesWithInputLowerBound:(double)inputLowerBound
                          inputUpperBound:(double)inputUpperBound
                                   radius:(double)radius
                                   opacity:(double)opacity{
    SCNNode *gridLines = [SCNNode node];
    
    double gridLinesLength = inputUpperBound - inputLowerBound;
    SCNCylinder *gridLineGeometry = [SCNCylinder cylinderWithRadius:radius/2.0 height:gridLinesLength];
    gridLineGeometry.firstMaterial.diffuse.contents = [NSColor blackColor];
    
    
    SCNNode *x1 = [SCNNode nodeWithGeometry:gridLineGeometry];
    x1.position = SCNVector3Make(inputLowerBound + gridLinesLength/2.0, inputLowerBound, inputLowerBound);
    x1.rotation = SCNVector4Make(0, 0, 1, GLKMathDegreesToRadians(90));
    
    [gridLines addChildNode:x1];
    
    SCNNode *x2 = [SCNNode nodeWithGeometry:gridLineGeometry];
    x2.position = SCNVector3Make(inputLowerBound + gridLinesLength/2.0, inputUpperBound, inputLowerBound);
    x2.rotation = SCNVector4Make(0, 0, 1, GLKMathDegreesToRadians(90));
    
    [gridLines addChildNode:x2];
    
    SCNNode *x3 = [SCNNode nodeWithGeometry:gridLineGeometry];
    x3.position = SCNVector3Make(inputLowerBound + gridLinesLength/2.0, inputLowerBound, inputUpperBound);
    x3.rotation = SCNVector4Make(0, 0, 1, GLKMathDegreesToRadians(90));
    
    [gridLines addChildNode:x3];
    
    SCNNode *x4 = [SCNNode nodeWithGeometry:gridLineGeometry];
    x4.position = SCNVector3Make(inputLowerBound + gridLinesLength/2.0, inputUpperBound, inputUpperBound);
    x4.rotation = SCNVector4Make(0, 0, 1, GLKMathDegreesToRadians(90));
    
    [gridLines addChildNode:x4];
    
    SCNNode *y1 = [SCNNode nodeWithGeometry:gridLineGeometry];
    y1.position = SCNVector3Make(inputLowerBound, inputLowerBound+gridLinesLength/2.0, inputLowerBound);
    
    [gridLines addChildNode:y1];
    
    SCNNode *y2 = [SCNNode nodeWithGeometry:gridLineGeometry];
    y2.position = SCNVector3Make(inputUpperBound, inputLowerBound+gridLinesLength/2.0, inputLowerBound);
    
    [gridLines addChildNode:y2];
    
    SCNNode *y3 = [SCNNode nodeWithGeometry:gridLineGeometry];
    y3.position = SCNVector3Make(inputLowerBound, inputLowerBound+gridLinesLength/2.0, inputUpperBound);
    
    [gridLines addChildNode:y3];
    
    SCNNode *y4 = [SCNNode nodeWithGeometry:gridLineGeometry];
    y4.position = SCNVector3Make(inputUpperBound, inputLowerBound+gridLinesLength/2.0, inputUpperBound);
    
    [gridLines addChildNode:y4];
    
    //Z AXIS
    
    SCNNode *z1 = [SCNNode nodeWithGeometry:gridLineGeometry];
    z1.position = SCNVector3Make(inputLowerBound, inputLowerBound, inputLowerBound+gridLinesLength/2.0);
    z1.rotation = SCNVector4Make(1, 0, 0, GLKMathDegreesToRadians(90));

    [gridLines addChildNode:z1];
    
    SCNNode *z2 = [SCNNode nodeWithGeometry:gridLineGeometry];
    z2.position = SCNVector3Make(inputUpperBound, inputLowerBound, inputLowerBound+gridLinesLength/2.0);
    z2.rotation = SCNVector4Make(1, 0, 0, GLKMathDegreesToRadians(90));
    
    [gridLines addChildNode:z2];
    
    SCNNode *z3 = [SCNNode nodeWithGeometry:gridLineGeometry];
    z3.position = SCNVector3Make(inputLowerBound, inputUpperBound, inputLowerBound+gridLinesLength/2.0);
    z3.rotation = SCNVector4Make(1, 0, 0, GLKMathDegreesToRadians(90));
    
    [gridLines addChildNode:z3];
    
    SCNNode *z4 = [SCNNode nodeWithGeometry:gridLineGeometry];
    z4.position = SCNVector3Make(inputUpperBound, inputUpperBound, inputLowerBound+gridLinesLength/2.0);
    z4.rotation = SCNVector4Make(1, 0, 0, GLKMathDegreesToRadians(90));
    
    [gridLines addChildNode:z4];
    
    gridLines.opacity = opacity;
    
    return gridLines;
}

@end
