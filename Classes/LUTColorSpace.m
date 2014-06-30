//
//  LUTColorSpace.m
//  Pods
//
//  Created by Greg Cotten on 4/2/14.
//
//

#import "LUTColorSpace.h"

@interface LUTColorSpace ()



@end


@implementation LUTColorSpace

+ (instancetype)LUTColorSpaceWithDefaultWhitePoint:(LUTColorSpaceWhitePoint *)whitePoint
                                  redChromaticityX:(double)redChromaticityX
                                  redChromaticityY:(double)redChromaticityY
                                greenChromaticityX:(double)greenChromaticityX
                                greenChromaticityY:(double)greenChromaticityY
                                 blueChromaticityX:(double)blueChromaticityX
                                 blueChromaticityY:(double)blueChromaticityY
                                              name:(NSString *)name{
    return [[self alloc] initWithDefaultWhitePoint:whitePoint
                                  redChromaticityX:redChromaticityX
                                  redChromaticityY:redChromaticityY
                                greenChromaticityX:greenChromaticityX
                                greenChromaticityY:greenChromaticityY
                                 blueChromaticityX:blueChromaticityX
                                 blueChromaticityY:blueChromaticityY
                                              name:name];
}

+ (instancetype)LUTColorSpaceWithNPM:(GLKMatrix3)npm
                                name:(NSString *)name{
    return [[self alloc] initWithNPM:npm
                                name:name];
}

- (instancetype)initWithDefaultWhitePoint:(LUTColorSpaceWhitePoint *)whitePoint
                         redChromaticityX:(double)redChromaticityX
                         redChromaticityY:(double)redChromaticityY
                       greenChromaticityX:(double)greenChromaticityX
                       greenChromaticityY:(double)greenChromaticityY
                        blueChromaticityX:(double)blueChromaticityX
                        blueChromaticityY:(double)blueChromaticityY
                                     name:(NSString *)name{
    if (self = [super init]) {
        self.redChromaticityX = redChromaticityX;
        self.redChromaticityY = redChromaticityY;
        self.greenChromaticityX = greenChromaticityX;
        self.greenChromaticityY = greenChromaticityY;
        self.blueChromaticityX = blueChromaticityX;
        self.blueChromaticityY = blueChromaticityY;
        self.forcesNPM = NO;
        self.name = name;
    }
    return self;
}

- (instancetype)initWithNPM:(GLKMatrix3)npm
                       name:(NSString *)name{
    if (self = [super init]) {
        self.npm = npm;
        self.forcesNPM = YES;
        self.name = name;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone{
    if(self.forcesNPM){
        return [self.class LUTColorSpaceWithNPM:self.npm
                                           name:[self.name copyWithZone:zone]];
    }
    else{
        return [self.class LUTColorSpaceWithDefaultWhitePoint:[self.defaultWhitePoint copyWithZone:zone]
                                             redChromaticityX:self.redChromaticityX
                                             redChromaticityY:self.redChromaticityY
                                           greenChromaticityX:self.greenChromaticityX
                                           greenChromaticityY:self.greenChromaticityY
                                            blueChromaticityX:self.blueChromaticityX
                                            blueChromaticityY:self.blueChromaticityY
                                                         name:[self.name copyWithZone:zone]];
    }
}

+ (GLKMatrix3)npmFromColorSpace:(LUTColorSpace *)colorSpace
                     whitePoint:(LUTColorSpaceWhitePoint *)whitePoint{
    if(colorSpace.forcesNPM){
        return colorSpace.npm;
    }
    double whiteChromaticityZ = 1 - (whitePoint.whiteChromaticityX + whitePoint.whiteChromaticityY);
    double redChromaticityZ = 1 - (colorSpace.redChromaticityX + colorSpace.redChromaticityY);
    double greenChromaticityZ = 1 - (colorSpace.greenChromaticityX + colorSpace.greenChromaticityY);
    double blueChromaticityZ = 1 - (colorSpace.blueChromaticityX + colorSpace.blueChromaticityY);
    
    GLKMatrix3 P = GLKMatrix3MakeWithRows(GLKVector3Make(colorSpace.redChromaticityX, colorSpace.greenChromaticityX, colorSpace.blueChromaticityX),
                                          GLKVector3Make(colorSpace.redChromaticityY, colorSpace.greenChromaticityY, colorSpace.blueChromaticityY),
                                          GLKVector3Make(redChromaticityZ, greenChromaticityZ, blueChromaticityZ));
    
    GLKVector3 W = GLKVector3Make(whitePoint.whiteChromaticityX / whitePoint.whiteChromaticityY, 1.0, whiteChromaticityZ / whitePoint.whiteChromaticityY);
    bool isInvertible;
    GLKVector3 pInverseDotW = GLKMatrix3MultiplyVector3(GLKMatrix3Invert(P, &isInvertible), W);
    
    NSAssert(isInvertible == YES, @"NPM can't be generated because matrix is not invertible");
    
    GLKMatrix3 C = GLKMatrix3MakeWithRows(GLKVector3Make(pInverseDotW.x,0.0,0.0),
                                          GLKVector3Make(0.0,pInverseDotW.y,0.0),
                                          GLKVector3Make(0.0,0.0,pInverseDotW.z));
    
    return GLKMatrix3Multiply(P, C);
}

+ (LUT3D *)convertLUT3D:(LUT3D *)lut fromColorSpace:(LUTColorSpace *)sourceColorSpace
             whitePoint:(LUTColorSpaceWhitePoint *)sourceWhitePoint
           toColorSpace:(LUTColorSpace *)destinationColorSpace
             whitePoint:(LUTColorSpaceWhitePoint *)destinationWhitePoint{
    //NSLog(@"Source NPM: %@\n Destination NPM: %@", NSStringFromGLKMatrix3(sourceColorSpace.npm), NSStringFromGLKMatrix3(destinationColorSpace.npm));
    
    GLKMatrix3 transformationMatrix = [self transformationMatrixFromColorSpace:sourceColorSpace
                                                                    whitePoint:sourceWhitePoint
                                                                  toColorSpace:destinationColorSpace
                                                                    whitePoint:destinationWhitePoint];
    //NSLog(@"Transformation Matrix: %@", NSStringFromGLKMatrix3(transformationMatrix));
    
    LUT3D *transformedLUT = [LUT3D LUTOfSize:[lut size] inputLowerBound:[lut inputLowerBound] inputUpperBound:[lut inputUpperBound]];
    
    [transformedLUT copyMetaPropertiesFromLUT:lut];
    
    [transformedLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *sourceColor = [lut colorAtR:r g:g b:b];
        GLKVector3 transformedColor = GLKMatrix3MultiplyVector3(transformationMatrix, GLKVector3Make(sourceColor.red, sourceColor.green, sourceColor.blue));
        [transformedLUT setColor:[LUTColor colorWithRed:transformedColor.x green:transformedColor.y blue:transformedColor.z] r:r g:g b:b];
    }];
    
    return transformedLUT;
}


+ (GLKMatrix3)transformationMatrixFromColorSpace:(LUTColorSpace *)sourceColorSpace
                                      whitePoint:(LUTColorSpaceWhitePoint *)sourceWhitePoint
                                    toColorSpace:(LUTColorSpace *)destinationColorSpace
                                      whitePoint:(LUTColorSpaceWhitePoint *)destinationWhitePoint{
   bool isInvertible;
   GLKMatrix3 transformationMatrix = GLKMatrix3Multiply(GLKMatrix3Invert([self npmFromColorSpace:destinationColorSpace whitePoint:destinationWhitePoint], &isInvertible), [self npmFromColorSpace:sourceColorSpace whitePoint:sourceWhitePoint]);
   NSAssert(isInvertible == YES, @"Transformation Matrix can't be generated because matrix is not invertible");
   return transformationMatrix;
}

+ (NSArray *)knownColorSpaces{
    NSArray *allKnownColorSpaces = @[[self rec709ColorSpace],
                                     [self dciP3ColorSpace],
                                     [self rec2020ColorSpace],
                                     [self alexaWideGamutColorSpace],
                                     [self sGamut3CineColorSpace],
                                     [self sGamutColorSpace],
                                     [self acesGamutColorSpace],
                                     [self xyzColorSpace]];
    
    return allKnownColorSpaces;
}


+ (instancetype)rec709ColorSpace{
    return [self LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                   redChromaticityX:0.64
                                   redChromaticityY:0.33
                                 greenChromaticityX:0.30
                                 greenChromaticityY:0.60
                                  blueChromaticityX:0.15
                                  blueChromaticityY:0.06
                                               name:@"Rec. 709"];
}

+ (instancetype)dciP3ColorSpace{
    return [self LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint dciP3WhitePoint]
                                   redChromaticityX:0.680
                                   redChromaticityY:0.320
                                 greenChromaticityX:0.265
                                 greenChromaticityY:0.69
                                  blueChromaticityX:0.15
                                  blueChromaticityY:0.06
                                               name:@"DCI-P3"];
}

+ (instancetype)rec2020ColorSpace{
    return [LUTColorSpace LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                             redChromaticityX:0.708
                                             redChromaticityY:0.292
                                           greenChromaticityX:0.170
                                           greenChromaticityY:0.797
                                            blueChromaticityX:0.131
                                            blueChromaticityY:0.046
                                                         name:@"Rec. 2020"];
    
}

+ (instancetype)alexaWideGamutColorSpace{
    return [LUTColorSpace LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                            redChromaticityX:0.6840
                                            redChromaticityY:0.3130
                                          greenChromaticityX:0.2210
                                          greenChromaticityY:0.8480
                                           blueChromaticityX:0.0861
                                           blueChromaticityY:-0.1020
                                                        name:@"Alexa Wide Gamut"];
}

+ (instancetype)sGamut3CineColorSpace{
    return [LUTColorSpace LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                            redChromaticityX:0.76600
                                            redChromaticityY:0.27500
                                          greenChromaticityX:0.22500
                                          greenChromaticityY:0.80000
                                           blueChromaticityX:0.08900
                                           blueChromaticityY:-0.08700
                                                        name:@"S-Gamut3.Cine"];
}

+ (instancetype)sGamutColorSpace{
    return [LUTColorSpace LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                            redChromaticityX:0.73000
                                            redChromaticityY:0.28000
                                          greenChromaticityX:0.14000
                                          greenChromaticityY:0.85500
                                           blueChromaticityX:0.10000
                                           blueChromaticityY:-0.05000
                                                        name:@"S-Gamut/S-Gamut3"];
}

+ (instancetype)acesGamutColorSpace{
    return [LUTColorSpace LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d60WhitePoint]
                                            redChromaticityX:0.73470
                                            redChromaticityY:0.26530
                                          greenChromaticityX:0.00000
                                          greenChromaticityY:1.00000
                                           blueChromaticityX:0.00010
                                           blueChromaticityY:-0.07700
                                                        name:@"ACES Gamut"];
}
+ (instancetype)xyzColorSpace{
    return [LUTColorSpace LUTColorSpaceWithNPM:GLKMatrix3MakeWithRows(GLKVector3Make(1.0, 0.0, 0.0),
                                                                      GLKVector3Make(0.0, 1.0, 0.0),
                                                                      GLKVector3Make(0.0, 0.0, 1.0))
                                          name:@"XYZ Gamut"];
}

@end
