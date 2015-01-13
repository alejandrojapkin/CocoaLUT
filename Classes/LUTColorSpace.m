//
//  LUTColorSpace.m
//  Pods
//
//  Created by Greg Cotten on 4/2/14.
//
//

#import "LUTColorSpace.h"
#import "LUTColorTransferFunction.h"


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
                    forwardFootlambertCompensation:1.0
                                              name:name];
}

+ (instancetype)LUTColorSpaceWithDefaultWhitePoint:(LUTColorSpaceWhitePoint *)whitePoint
                                  redChromaticityX:(double)redChromaticityX
                                  redChromaticityY:(double)redChromaticityY
                                greenChromaticityX:(double)greenChromaticityX
                                greenChromaticityY:(double)greenChromaticityY
                                 blueChromaticityX:(double)blueChromaticityX
                                 blueChromaticityY:(double)blueChromaticityY
                    forwardFootlambertCompensation:(double)flCompensation
                                              name:(NSString *)name{
    return [[self alloc] initWithDefaultWhitePoint:whitePoint
                                  redChromaticityX:redChromaticityX
                                  redChromaticityY:redChromaticityY
                                greenChromaticityX:greenChromaticityX
                                greenChromaticityY:greenChromaticityY
                                 blueChromaticityX:blueChromaticityX
                                 blueChromaticityY:blueChromaticityY
                    forwardFootlambertCompensation:flCompensation
                                              name:name];
}

+ (instancetype)LUTColorSpaceWithNPM:(GLKMatrix3)npm
                                name:(NSString *)name{
    return [[self alloc] initWithNPM:npm
      forwardFootlambertCompensation:1.0
                                name:name];
}

+ (instancetype)LUTColorSpaceWithNPM:(GLKMatrix3)npm
      forwardFootlambertCompensation:(double)flCompensation
                                name:(NSString *)name{
    return [[self alloc] initWithNPM:npm
      forwardFootlambertCompensation:flCompensation
                                name:name];
}

- (instancetype)initWithDefaultWhitePoint:(LUTColorSpaceWhitePoint *)whitePoint
                         redChromaticityX:(double)redChromaticityX
                         redChromaticityY:(double)redChromaticityY
                       greenChromaticityX:(double)greenChromaticityX
                       greenChromaticityY:(double)greenChromaticityY
                        blueChromaticityX:(double)blueChromaticityX
                        blueChromaticityY:(double)blueChromaticityY
           forwardFootlambertCompensation:(double)flCompensation
                                     name:(NSString *)name{
    if (self = [super init]) {
        self.redChromaticityX = redChromaticityX;
        self.redChromaticityY = redChromaticityY;
        self.greenChromaticityX = greenChromaticityX;
        self.greenChromaticityY = greenChromaticityY;
        self.blueChromaticityX = blueChromaticityX;
        self.blueChromaticityY = blueChromaticityY;
        self.forcesNPM = NO;
        self.forwardFootlambertCompensation = flCompensation;
        self.name = name;
    }
    return self;
}

- (instancetype)initWithNPM:(GLKMatrix3)npm
forwardFootlambertCompensation:(double)flCompensation
                       name:(NSString *)name{
    if (self = [super init]) {
        self.npm = npm;
        self.forcesNPM = YES;
        self.forwardFootlambertCompensation = flCompensation;
        self.name = name;
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone{
    if(self.forcesNPM){
        return [self.class LUTColorSpaceWithNPM:self.npm
                 forwardFootlambertCompensation:self.forwardFootlambertCompensation
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
                               forwardFootlambertCompensation:self.forwardFootlambertCompensation
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
             whitePoint:(LUTColorSpaceWhitePoint *)destinationWhitePoint
         bradfordMatrix:(BOOL)useBradfordMatrix{
    //NSLog(@"Source NPM: %@\n Destination NPM: %@", NSStringFromGLKMatrix3(sourceColorSpace.npm), NSStringFromGLKMatrix3(destinationColorSpace.npm));
    if(useBradfordMatrix && (sourceColorSpace.forcesNPM || destinationColorSpace.forcesNPM)){
        @throw [NSException exceptionWithName:@"ColorSpaceConversionError" reason:@"Can't use the bradford matrix when using a colorspace that forces the NPM." userInfo:nil];
    }

    GLKMatrix3 transformationMatrix = [self transformationMatrixFromColorSpace:sourceColorSpace
                                                                    whitePoint:sourceWhitePoint
                                                                  toColorSpace:destinationColorSpace
                                                                    whitePoint:destinationWhitePoint
                                                                bradfordMatrix:useBradfordMatrix];

    //NSLog(@"Transformation Matrix: %@", NSStringFromGLKMatrix3(transformationMatrix));

    LUT3D *transformedLUT = [LUT3D LUTOfSize:[lut size] inputLowerBound:[lut inputLowerBound] inputUpperBound:[lut inputUpperBound]];

    [transformedLUT copyMetaPropertiesFromLUT:lut];

    double sourceFLCompensation = 1.0/sourceColorSpace.forwardFootlambertCompensation;
    double destinationFLCompensation = destinationColorSpace.forwardFootlambertCompensation;

    BOOL useFLCompensation = sourceFLCompensation != 1.0/destinationFLCompensation;

    [transformedLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *sourceColor = [lut colorAtR:r g:g b:b];
        if (useFLCompensation && sourceFLCompensation != 1.0) {
            sourceColor = [sourceColor colorByMultiplyingByNumber:sourceFLCompensation];
        }

        GLKVector3 transformedColor = GLKMatrix3MultiplyVector3(transformationMatrix, GLKVector3Make(sourceColor.red, sourceColor.green, sourceColor.blue));

        LUTColor *destinationColor = [LUTColor colorWithRed:transformedColor.x green:transformedColor.y blue:transformedColor.z];

        if (useFLCompensation && destinationFLCompensation != 1.0) {
            destinationColor = [destinationColor colorByMultiplyingByNumber:destinationFLCompensation];
        }

        [transformedLUT setColor:destinationColor r:r g:g b:b];
    }];

    return transformedLUT;
}

+ (LUT3D *)convertColorTemperatureFromLUT3D:(LUT3D *)lut
                           sourceColorSpace:(LUTColorSpace *)sourceColorSpace
                     sourceTransferFunction:(LUTColorTransferFunction *)sourceTransferFunction
                     sourceColorTemperature:(LUTColorSpaceWhitePoint *)sourceColorTemperature
                destinationColorTemperature:(LUTColorSpaceWhitePoint *)destinationColorTemperature{
    LUT3D *linearizedLUT = (LUT3D *)[LUTColorTransferFunction transformedLUTFromLUT:lut
                                                 fromColorTransferFunction:sourceTransferFunction
                                                   toColorTransferFunction:[LUTColorTransferFunction linearTransferFunction]];

    LUT3D *linearizedColorSpaceConvertedLUT = [self convertLUT3D:linearizedLUT
                                                  fromColorSpace:sourceColorSpace
                                                      whitePoint:sourceColorTemperature
                                                    toColorSpace:sourceColorSpace
                                                      whitePoint:destinationColorTemperature
                                                  bradfordMatrix:NO];

    return (LUT3D *)[LUTColorTransferFunction transformedLUTFromLUT:linearizedColorSpaceConvertedLUT
                                          fromColorTransferFunction:[LUTColorTransferFunction linearTransferFunction]
                                            toColorTransferFunction:sourceTransferFunction];


}


+ (GLKMatrix3)transformationMatrixFromColorSpace:(LUTColorSpace *)sourceColorSpace
                                      whitePoint:(LUTColorSpaceWhitePoint *)sourceWhitePoint
                                    toColorSpace:(LUTColorSpace *)destinationColorSpace
                                      whitePoint:(LUTColorSpaceWhitePoint *)destinationWhitePoint
                                  bradfordMatrix:(BOOL)useBradfordMatrix{
    bool isInvertible;
    GLKMatrix3 destinationNPMInverted = GLKMatrix3Invert([self npmFromColorSpace:destinationColorSpace whitePoint:destinationWhitePoint], &isInvertible);

    NSAssert(isInvertible == YES, @"Transformation Matrix can't be generated because destination NPM is not invertible.");

    GLKMatrix3 transformationMatrix;

    if (useBradfordMatrix) {
        GLKVector3 sourceConeResponseDomain = GLKMatrix3MultiplyVector3([self bradfordConeResponseMatrix], sourceWhitePoint.tristimulusValues);
        GLKVector3 destinationConeResponseDomain = GLKMatrix3MultiplyVector3([self bradfordConeResponseMatrix], destinationWhitePoint.tristimulusValues);

        GLKMatrix3 intermediateConeResponseDomainMatrix =
        GLKMatrix3Make(destinationConeResponseDomain.x/sourceConeResponseDomain.x, 0, 0,
                       0, destinationConeResponseDomain.y/sourceConeResponseDomain.y, 0,
                       0, 0, destinationConeResponseDomain.z/sourceConeResponseDomain.z);
        GLKMatrix3 bradfordMatrix = GLKMatrix3Multiply(GLKMatrix3Multiply([self bradfordConeResponseMatrixInverse], intermediateConeResponseDomainMatrix), [self bradfordConeResponseMatrix]);

        //NSLog(@"Bradford Matrix: %@", NSStringFromGLKMatrix3(bradfordMatrix));


        transformationMatrix = GLKMatrix3Multiply(GLKMatrix3Multiply(destinationNPMInverted, bradfordMatrix), [self npmFromColorSpace:sourceColorSpace whitePoint:sourceWhitePoint]);
    }
    else{
        transformationMatrix = GLKMatrix3Multiply(destinationNPMInverted, [self npmFromColorSpace:sourceColorSpace whitePoint:sourceWhitePoint]);
    }

    return transformationMatrix;
}

+ (GLKMatrix3)bradfordConeResponseMatrix{
    return GLKMatrix3Make(0.8951000,  -0.7502000, 0.0389000,
                          0.2664000,  1.7135000,  -0.0685000,
                          -0.1614000, 0.0367000,  1.0296000);
}

+ (GLKMatrix3)bradfordConeResponseMatrixInverse{
    return GLKMatrix3Make(0.9869929, 0.4323053,  -0.0085287,
                          -0.1470543,  0.5183603,  0.0400428,
                          0.1599627,  0.0492912,  0.9684867);
}

+ (NSArray *)knownColorSpaces{
    NSArray *allKnownColorSpaces = @[[self rec709ColorSpace],
                                     [self dciP3ColorSpace],
                                     [self rec2020ColorSpace],
                                     [self alexaWideGamutColorSpace],
                                     [self sGamut3CineColorSpace],
                                     [self sGamutColorSpace],
                                     [self bmccColorSpace],
                                     [self redColorColorSpace],
                                     [self redColor2ColorSpace],
                                     [self redColor3ColorSpace],
                                     [self redColor4ColorSpace],
                                     [self dragonColorColorSpace],
                                     [self dragonColor2ColorSpace],
                                     [self canonCinemaGamutColorSpace],
                                     [self canonDCIP3PlusColorSpace],
                                     [self vGamutColorSpace],
                                     [self acesGamutColorSpace],
                                     [self dciXYZColorSpace],
                                     [self xyzColorSpace],
                                     [self adobeRGBColorSpace],
                                     [self proPhotoRGBColorSpace]];

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

+ (instancetype)canonDCIP3PlusColorSpace{
    return [self LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint dciWhitePoint]
                                   redChromaticityX:0.7400
                                   redChromaticityY:0.2700
                                 greenChromaticityX:0.2200
                                 greenChromaticityY:0.7800
                                  blueChromaticityX:0.0900
                                  blueChromaticityY:-0.0900
                                               name:@"Canon DCI-P3+"];
}

+ (instancetype)canonCinemaGamutColorSpace{
    return [self LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                   redChromaticityX:0.7400
                                   redChromaticityY:0.2700
                                 greenChromaticityX:0.1700
                                 greenChromaticityY:1.1400
                                  blueChromaticityX:0.0800
                                  blueChromaticityY:-0.1000
                                               name:@"Canon Cinema Gamut"];
}

+ (instancetype)bmccColorSpace{
    return [self LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                   redChromaticityX:0.901885370853
                                   redChromaticityY:0.249059467640
                                 greenChromaticityX:0.280038809783
                                 greenChromaticityY:1.535129255560
                                  blueChromaticityX:0.078873341398
                                  blueChromaticityY:-0.082629719848
                                               name:@"BMCC"];
}

+ (instancetype)redColorColorSpace{
    return [self LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                   redChromaticityX:0.682235759294
                                   redChromaticityY:0.320973856307
                                 greenChromaticityX:0.295705729612
                                 greenChromaticityY:0.613311106957
                                  blueChromaticityX:0.134524597085
                                  blueChromaticityY:0.034410956920
                                               name:@"REDcolor"];
}

+ (instancetype)redColor2ColorSpace{
    return [self LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                   redChromaticityX:0.858485322390
                                   redChromaticityY:0.316594954144
                                 greenChromaticityX:0.292084791425
                                 greenChromaticityY:0.667838655872
                                  blueChromaticityX:0.097651412967
                                  blueChromaticityY:-0.026565653796
                                               name:@"REDcolor2"];
}

+ (instancetype)redColor3ColorSpace{
    return [self LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                   redChromaticityX:0.682450885401
                                   redChromaticityY:0.320302618634
                                 greenChromaticityX:0.291813306036
                                 greenChromaticityY:0.672642663443
                                  blueChromaticityX:0.109533374066
                                  blueChromaticityY:-0.006916855752
                                               name:@"REDcolor3"];
}

+ (instancetype)redColor4ColorSpace{
    return [self LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                   redChromaticityX:0.682432347
                                   redChromaticityY:0.320314427
                                 greenChromaticityX:0.291815909
                                 greenChromaticityY:0.672638769
                                  blueChromaticityX:0.144290202
                                  blueChromaticityY:0.050547336
                                               name:@"REDcolor4"];
}

+ (instancetype)dragonColorColorSpace{
    return [self LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                   redChromaticityX:0.733696621349
                                   redChromaticityY:0.319213119879
                                 greenChromaticityX:0.290807268864
                                 greenChromaticityY:0.689667987865
                                  blueChromaticityX:0.083009416684
                                  blueChromaticityY:-0.050780628080
                                               name:@"DRAGONcolor"];
}

+ (instancetype)dragonColor2ColorSpace{
    return [self LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                   redChromaticityX:0.733671536367
                                   redChromaticityY:0.319227712042
                                 greenChromaticityX:0.290804815281
                                 greenChromaticityY:0.689668775507
                                  blueChromaticityX:0.143989704285
                                  blueChromaticityY:0.050047743857
                                               name:@"DRAGONcolor2"];
}

+ (instancetype)proPhotoRGBColorSpace{
    return [self LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                   redChromaticityX:0.7347
                                   redChromaticityY:0.2653
                                 greenChromaticityX:0.1596
                                 greenChromaticityY:0.8404
                                  blueChromaticityX:0.0366
                                  blueChromaticityY:0.0001
                                               name:@"ProPhoto RGB"];
}

+ (instancetype)adobeRGBColorSpace{
    return [self LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                   redChromaticityX:0.64
                                   redChromaticityY:0.33
                                 greenChromaticityX:0.21
                                 greenChromaticityY:0.71
                                  blueChromaticityX:0.15
                                  blueChromaticityY:0.06
                                               name:@"Adobe RGB"];
}

+ (instancetype)dciP3ColorSpace{
    return [self LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint dciWhitePoint]
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

+ (instancetype)vGamutColorSpace{
    return [LUTColorSpace LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint d65WhitePoint]
                                            redChromaticityX:0.730
                                            redChromaticityY:0.280
                                          greenChromaticityX:0.165
                                          greenChromaticityY:0.840
                                           blueChromaticityX:0.100
                                           blueChromaticityY:-0.030
                                                        name:@"V-Gamut"];
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
+ (instancetype)dciXYZColorSpace{
    return [LUTColorSpace LUTColorSpaceWithNPM:GLKMatrix3MakeWithRows(GLKVector3Make(1.0, 0.0, 0.0),
                                                                      GLKVector3Make(0.0, 1.0, 0.0),
                                                                      GLKVector3Make(0.0, 0.0, 1.0))
            forwardFootlambertCompensation:0.916555
                                          name:@"DCI-XYZ"];
}

+ (instancetype)xyzColorSpace{
    return [LUTColorSpace LUTColorSpaceWithDefaultWhitePoint:[LUTColorSpaceWhitePoint xyzWhitePoint]
                                            redChromaticityX:1
                                            redChromaticityY:0
                                          greenChromaticityX:0
                                          greenChromaticityY:1
                                           blueChromaticityX:0
                                           blueChromaticityY:0
                              forwardFootlambertCompensation:0.916555
                                                        name:@"CIE-XYZ"];
}

@end
