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
    ((SCNView *)self.view).scene = [LUTPreviewScene sceneForLUT:lut];
    self.animationPercentage = 1.0;
}

- (void)setAnimationPercentage:(double)animationPercentage{
    _animationPercentage = animationPercentage;
    [(LUTPreviewScene *)((SCNView *)self.view).scene updateNodesToPercentage:animationPercentage];
}

@end

@implementation LUTPreviewScene

- (void)updateNodesToPercentage:(double)percentage{
    for(LUTColorNode *node in self.dotGroup.childNodes){
        [node changeToAnimationPercentage:percentage];
    }
}

- (void)setDotGroup:(SCNNode *)dotGroup{
    if(_dotGroup){
        [_dotGroup removeFromParentNode];
    }
    _dotGroup = dotGroup;
    [self.rootNode addChildNode:_dotGroup];
}

- (void)setCubeOutline:(SCNNode *)cubeOutline{
    if(_cubeOutline){
        [_cubeOutline removeFromParentNode];
    }
    _cubeOutline = cubeOutline;
    [self.rootNode addChildNode:_cubeOutline];
}

- (void)setAxes:(SCNNode *)axes{
    if(_axes){
        [_axes removeFromParentNode];
    }
    _axes = axes;
    [self.rootNode addChildNode:_axes];
}

+ (instancetype)sceneForLUT:(LUT *)lut {
    
    
    LUT3D *lut3D = LUTAsLUT3D(lut, MIN(LATTICE_SIZE, lut.size));
    
    LUTPreviewScene *scene = [self scene];
    
    
    
    double radius;
    double initialAnimationPercentage;
    double axisLength;
    
    double minimumOutputValue = lut3D.minimumOutputValue;
    double maximumOutputValue = lut3D.maximumOutputValue;
    
    if((maximumOutputValue - minimumOutputValue) > (lut3D.inputUpperBound - lut3D.inputLowerBound)){
        initialAnimationPercentage = 1.0;
        radius = .013 * clampLowerBound(maximumOutputValue - minimumOutputValue, 1);
        axisLength = 1.2*clampLowerBound(maximumOutputValue - minimumOutputValue, 1);
    }
    else{
        initialAnimationPercentage = 0.0;
        radius = .013 * clampLowerBound(lut3D.inputUpperBound - lut3D.inputLowerBound, 1);
        axisLength = 1.2*clampLowerBound(lut3D.inputUpperBound - lut3D.inputLowerBound, 1);
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
    
    scene.cubeOutline = [[self class] cubeOutlineWithInputLowerBound:lut3D.inputLowerBound
                                                 inputUpperBound:lut3D.inputUpperBound
                                                          radius:radius/2.0];
    scene.cubeOutline.opacity = .3;
    
    scene.axes = [[self class] axesWithOrigin:SCNVector3Make(0,0,0)
                                       length:axisLength
                                       radius:radius/2.0];
    scene.axes.opacity = .5;
    
    return scene;
}

+ (SCNNode *)axesWithOrigin:(SCNVector3)origin
                     length:(double)length
                     radius:(double)radius{
    SCNNode *axes = [SCNNode node];
    
    SCNCylinder *redLineGeometry = [SCNCylinder cylinderWithRadius:radius height:length];
    redLineGeometry.firstMaterial.diffuse.contents = [NSColor redColor];
    
    SCNCylinder *greenLineGeometry = [SCNCylinder cylinderWithRadius:radius height:length];
    greenLineGeometry.firstMaterial.diffuse.contents = [NSColor greenColor];
    
    SCNCylinder *blueLineGeometry = [SCNCylinder cylinderWithRadius:radius height:length];
    blueLineGeometry.firstMaterial.diffuse.contents = [NSColor blueColor];
    
    SCNCone *redAxisPointerGeometry = [SCNCone coneWithTopRadius:radius*4.0 bottomRadius:0 height:radius*4.0];
    redAxisPointerGeometry.firstMaterial.diffuse.contents = [NSColor redColor];
    SCNCone *greenAxisPointerGeometry = [SCNCone coneWithTopRadius:radius*4.0 bottomRadius:0 height:radius*4.0];
    greenAxisPointerGeometry.firstMaterial.diffuse.contents = [NSColor greenColor];
    SCNCone *blueAxisPointerGeometry = [SCNCone coneWithTopRadius:radius*4.0 bottomRadius:0 height:radius*4.0];
    blueAxisPointerGeometry.firstMaterial.diffuse.contents = [NSColor blueColor];
    double axisPointerOffset = redAxisPointerGeometry.height/2.0;
    
    SCNNode *xAxis = [SCNNode nodeWithGeometry:redLineGeometry];
    xAxis.position = SCNVector3Make(origin.x + length/2.0, origin.y, origin.z);
    xAxis.rotation = SCNVector4Make(0, 0, 1, GLKMathDegreesToRadians(90));

    SCNNode *xAxisPointer = [SCNNode nodeWithGeometry:redAxisPointerGeometry];
    xAxisPointer.position = SCNVector3Make(origin.x + length + axisPointerOffset, origin.y, origin.z);
    xAxisPointer.rotation = SCNVector4Make(0, 0, 1, GLKMathDegreesToRadians(90));

    
    SCNNode *yAxis = [SCNNode nodeWithGeometry:greenLineGeometry];
    yAxis.position = SCNVector3Make(origin.x, origin.y + length/2.0, origin.z);
    yAxis.rotation = SCNVector4Make(0, 1, 0, GLKMathDegreesToRadians(90));

    SCNNode *yAxisPointer = [SCNNode nodeWithGeometry:greenAxisPointerGeometry];
    yAxisPointer.position = SCNVector3Make(origin.x, origin.y + length + axisPointerOffset, origin.z);
    yAxisPointer.rotation = SCNVector4Make(1, 0, 0, GLKMathDegreesToRadians(180));

    
    
    SCNNode *zAxis = [SCNNode nodeWithGeometry:blueLineGeometry];
    zAxis.position = SCNVector3Make(origin.x, origin.y, origin.z + length/2.0);
    zAxis.rotation = SCNVector4Make(1, 0, 0, GLKMathDegreesToRadians(90));

    SCNNode *zAxisPointer = [SCNNode nodeWithGeometry:blueAxisPointerGeometry];
    zAxisPointer.position = SCNVector3Make(origin.x, origin.y, origin.z + length + axisPointerOffset);
    zAxisPointer.rotation = SCNVector4Make(1, 0, 0, GLKMathDegreesToRadians(-90));

    
    
    [axes addChildNode:xAxis];
    [axes addChildNode:xAxisPointer];
    [axes addChildNode:yAxis];
    [axes addChildNode:yAxisPointer];
    [axes addChildNode:zAxis];
    [axes addChildNode:zAxisPointer];
    
    return axes;
    
}

+ (SCNNode *)cubeOutlineWithInputLowerBound:(double)inputLowerBound
                          inputUpperBound:(double)inputUpperBound
                                   radius:(double)radius{
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
    
    
    return gridLines;
}

@end
