//
//  LUTColorSpace.m
//  Pods
//
//  Created by Greg Cotten on 4/2/14.
//
//

#import "LUTColorSpace.h"

@interface LUTColorSpace ()
    @property (assign) GLKMatrix3 npm;
@end

@implementation LUTColorSpace

+ (instancetype)LUTColorSpaceWithWhiteChromaticityX:(double)whiteChromaticityX
                                 whiteChromaticityY:(double)whiteChromaticityY
                                   redChromaticityX:(double)redChromaticityX
                                   redChromaticityY:(double)redChromaticityY
                                 greenChromaticityX:(double)greenChromaticityX
                                 greenChromaticityY:(double)greenChromaticityY
                                  blueChromaticityX:(double)blueChromaticityX
                                  blueChromaticityY:(double)blueChromaticityY{
    return [[[self class] alloc] initWithWhiteChromaticityX:whiteChromaticityX
                                         whiteChromaticityY:whiteChromaticityY
                                           redChromaticityX:redChromaticityX
                                           redChromaticityY:redChromaticityY
                                         greenChromaticityX:greenChromaticityX
                                         greenChromaticityY:greenChromaticityY
                                          blueChromaticityX:blueChromaticityX
                                          blueChromaticityY:blueChromaticityY];
}

+ (instancetype)LUTColorSpaceWithNPM:(GLKMatrix3)npm{
    return [[[self class] alloc] initWithNPM:npm];
}

- (instancetype)initWithNPM:(GLKMatrix3)npm{
    if (self = [super init]){
        self.npm = npm;
    }
    return self;
}

- (instancetype)initWithWhiteChromaticityX:(double)whiteChromaticityX
                        whiteChromaticityY:(double)whiteChromaticityY
                          redChromaticityX:(double)redChromaticityX
                          redChromaticityY:(double)redChromaticityY
                        greenChromaticityX:(double)greenChromaticityX
                        greenChromaticityY:(double)greenChromaticityY
                         blueChromaticityX:(double)blueChromaticityX
                         blueChromaticityY:(double)blueChromaticityY{
    if (self = [super init]) {
        double whiteChromaticityZ = 1 - (whiteChromaticityX + whiteChromaticityY);
        double redChromaticityZ = 1 - (redChromaticityX + redChromaticityY);
        double greenChromaticityZ = 1 - (greenChromaticityX + greenChromaticityY);
        double blueChromaticityZ = 1 - (blueChromaticityX + blueChromaticityY);
        
        GLKMatrix3 P = GLKMatrix3MakeWithRows(GLKVector3Make(redChromaticityX, greenChromaticityX, blueChromaticityX),
                                              GLKVector3Make(redChromaticityY, greenChromaticityY, blueChromaticityY),
                                              GLKVector3Make(redChromaticityZ, greenChromaticityZ, blueChromaticityZ));
        
        GLKVector3 W = GLKVector3Make(whiteChromaticityX / whiteChromaticityY, 1.0, whiteChromaticityZ / whiteChromaticityY);
        bool isInvertible;
        GLKVector3 pInverseDotW = GLKMatrix3MultiplyVector3(GLKMatrix3Invert(P, &isInvertible), W);
        
        NSAssert(isInvertible == YES, @"NPM can't be generated because matrix is not invertible");
        
        GLKMatrix3 C = GLKMatrix3MakeWithRows(GLKVector3Make(pInverseDotW.x,0.0,0.0),
                                              GLKVector3Make(0.0,pInverseDotW.y,0.0),
                                              GLKVector3Make(0.0,0.0,pInverseDotW.z));
        
        self.npm = GLKMatrix3Multiply(P, C);
    }
    return self;
}

+ (LUT *)convertLUT:(LUT *)lut fromColorSpace:(LUTColorSpace *)sourceColorSpace toColorSpace:(LUTColorSpace *)destinationColorSpace{
    NSLog(@"Source NPM: %@\n Destination NPM: %@", NSStringFromGLKMatrix3(sourceColorSpace.npm), NSStringFromGLKMatrix3(destinationColorSpace.npm));
    
    GLKMatrix3 transformationMatrix = [LUTColorSpace transformationMatrixFromColorSpace:sourceColorSpace ToColorSpace:destinationColorSpace];
    NSLog(@"Transformation Matrix: %@", NSStringFromGLKMatrix3(transformationMatrix));
    LUTLattice *transformedLattice = [[LUTLattice alloc] initWithSize:lut.lattice.size];
    
    LUTConcurrentCubeLoop(lut.lattice.size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColor *sourceColor = [lut.lattice colorAtR:r g:g b:b];
        GLKVector3 transformedColor = GLKMatrix3MultiplyVector3(transformationMatrix, GLKVector3Make(sourceColor.red, sourceColor.green, sourceColor.blue));
        [transformedLattice setColor:[LUTColor colorWithRed:transformedColor.x green:transformedColor.y blue:transformedColor.z] r:r g:g b:b];
    });
    
    return [LUT LUTWithLattice:transformedLattice];
}


+ (GLKMatrix3)transformationMatrixFromColorSpace:(LUTColorSpace *)sourceColorSpace ToColorSpace:(LUTColorSpace *)destinationColorSpace{
   bool isInvertible;
   GLKMatrix3 transformationMatrix = GLKMatrix3Multiply(GLKMatrix3Invert(destinationColorSpace.npm, &isInvertible), sourceColorSpace.npm);
   NSAssert(isInvertible == YES, @"Transformation Matrix can't be generated because matrix is not invertible");
   return transformationMatrix;
}
   

+ (M13OrderedDictionary *)knownColorSpaces{
    return M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"Rec. 709 / sRGB": [LUTColorSpace rec709ColorSpace]},
                                                                  @{@"DCI-P3": [LUTColorSpace dciP3ColorSpace]},
                                                                  @{@"P3 D60": [LUTColorSpace p3D60ColorSpace]},
                                                                  @{@"P3 D65": [LUTColorSpace p3D65ColorSpace]},
                                                                  @{@"Rec. 2020": [LUTColorSpace rec2020ColorSpace]},
                                                                  @{@"Alexa Wide Gamut": [LUTColorSpace alexaWideGamutColorSpace]},
                                                                  @{@"S-Gamut3.Cine": [LUTColorSpace sGamut3CineColorSpace]},
                                                                  @{@"S-Gamut/S-Gamut3": [LUTColorSpace sGamutColorSpace]},
                                                                  @{@"ACES Gamut": [LUTColorSpace acesGamutColorSpace]},
                                                                  @{@"XYZ Gamut": [LUTColorSpace xyzColorSpace]}
                                                                  ]);
}


+ (instancetype)rec709ColorSpace{
    return [LUTColorSpace LUTColorSpaceWithWhiteChromaticityX:0.31271
                                           whiteChromaticityY:0.32902
                                             redChromaticityX:0.64
                                             redChromaticityY:0.33
                                           greenChromaticityX:0.30
                                           greenChromaticityY:0.60
                                            blueChromaticityX:0.15
                                            blueChromaticityY:0.06];
}

+ (instancetype)dciP3ColorSpace{
    return [LUTColorSpace LUTColorSpaceWithWhiteChromaticityX:0.314
                                           whiteChromaticityY:0.351
                                             redChromaticityX:0.680
                                             redChromaticityY:0.320
                                           greenChromaticityX:0.265
                                           greenChromaticityY:0.690
                                            blueChromaticityX:0.150
                                            blueChromaticityY:0.060];
    
}

+ (instancetype)p3D60ColorSpace{
    return [LUTColorSpace LUTColorSpaceWithWhiteChromaticityX:0.3217
                                           whiteChromaticityY:0.3378
                                             redChromaticityX:0.680
                                             redChromaticityY:0.320
                                           greenChromaticityX:0.265
                                           greenChromaticityY:0.690
                                            blueChromaticityX:0.150
                                            blueChromaticityY:0.060];
    
}

+ (instancetype)p3D65ColorSpace{
    return [LUTColorSpace LUTColorSpaceWithWhiteChromaticityX:0.31271
                                           whiteChromaticityY:0.32902
                                             redChromaticityX:0.680
                                             redChromaticityY:0.320
                                           greenChromaticityX:0.265
                                           greenChromaticityY:0.690
                                            blueChromaticityX:0.150
                                            blueChromaticityY:0.060];
    
}

+ (instancetype)rec2020ColorSpace{
    return [LUTColorSpace LUTColorSpaceWithWhiteChromaticityX:0.31271
                                           whiteChromaticityY:0.32902
                                             redChromaticityX:0.708
                                             redChromaticityY:0.292
                                           greenChromaticityX:0.170
                                           greenChromaticityY:0.797
                                            blueChromaticityX:0.131
                                            blueChromaticityY:0.046];
    
}

+ (instancetype)alexaWideGamutColorSpace{
    return [LUTColorSpace LUTColorSpaceWithWhiteChromaticityX:0.31271
                                           whiteChromaticityY:0.32902
                                             redChromaticityX:0.6840
                                             redChromaticityY:0.3130
                                           greenChromaticityX:0.2210
                                           greenChromaticityY:0.8480
                                            blueChromaticityX:0.0861
                                            blueChromaticityY:-0.1020];
    
}

+ (instancetype)sGamut3CineColorSpace{
    return [LUTColorSpace LUTColorSpaceWithWhiteChromaticityX:0.31270
                                           whiteChromaticityY:0.32900
                                             redChromaticityX:0.76600
                                             redChromaticityY:0.27500
                                           greenChromaticityX:0.22500
                                           greenChromaticityY:0.80000
                                            blueChromaticityX:0.08900
                                            blueChromaticityY:-0.08700];
    
}

+ (instancetype)sGamutColorSpace{
    return [LUTColorSpace LUTColorSpaceWithWhiteChromaticityX:0.31270
                                           whiteChromaticityY:0.32900
                                             redChromaticityX:0.73000
                                             redChromaticityY:0.28000
                                           greenChromaticityX:0.14000
                                           greenChromaticityY:0.85500
                                            blueChromaticityX:0.10000
                                            blueChromaticityY:-0.05000];
    
}

+ (instancetype)acesGamutColorSpace{
    return [LUTColorSpace LUTColorSpaceWithWhiteChromaticityX:0.32168
                                           whiteChromaticityY:0.33767
                                             redChromaticityX:0.73470
                                             redChromaticityY:0.26530
                                           greenChromaticityX:0.00000
                                           greenChromaticityY:1.00000
                                            blueChromaticityX:0.00010
                                            blueChromaticityY:-0.07700];
}
+ (instancetype)xyzColorSpace{
    return [LUTColorSpace LUTColorSpaceWithNPM:GLKMatrix3MakeWithRows(GLKVector3Make(1.0, 0.0, 0.0),
                                                                      GLKVector3Make(0.0, 1.0, 0.0),
                                                                      GLKVector3Make(0.0, 0.0, 1.0))];
}

@end
