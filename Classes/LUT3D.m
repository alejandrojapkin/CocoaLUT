//
//  LUT3D.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUT3D.h"

@interface LUT3D()
@property NSMutableArray *latticeArray;
@end

@implementation LUT3D

- (instancetype)initWithSize:(NSUInteger)size
   inputLowerBound:(double)inputLowerBound
   inputUpperBound:(double)inputUpperBound{
    if (self = [super init]) {
        [self setSize: size];
        [self setInputLowerBound:inputLowerBound];
        [self setInputUpperBound:inputUpperBound];
        
        self.latticeArray = [LUT3D blankLatticeArrayOfSize:size];
    }
    return self;
}

+ (instancetype)LUTOfSize:(NSUInteger)size
          inputLowerBound:(double)inputLowerBound
          inputUpperBound:(double)inputUpperBound{
    return [[[self class] alloc] initWithSize:size
                              inputLowerBound:inputLowerBound
                              inputUpperBound:inputUpperBound];
}

+ (instancetype)LUTIdentityOfSize:(NSUInteger)size
                  inputLowerBound:(double)inputLowerBound
                  inputUpperBound:(double)inputUpperBound{
    LUT3D *identity = [self LUTOfSize:size inputLowerBound:inputLowerBound inputUpperBound:inputUpperBound];
    
    LUT3DConcurrentLoop(size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        [identity setColor:[identity identityColorAtR:r g:g b:b] r:r g:g b:b];
    });
    
    return identity;
}

- (instancetype)LUTByResizingToSize:(NSUInteger)newSize {
    if (newSize == [self size]) {
        return [self copy];
    }
    LUT3D *resizedLUT = [LUT3D LUTOfSize:newSize inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    
    double ratio = remap(1, 0, [resizedLUT size] - 1, 0, [self size] - 1);
    
    LUT3DConcurrentLoop([resizedLUT size], ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColor *color = [self colorAtInterpolatedR:r * ratio g:g * ratio b:b * ratio];
        [resizedLUT setColor:color r:r g:g b:b];
    });
    
    return resizedLUT;
}

- (instancetype)LUTByCombiningWithLUT:(LUT *)otherLUT {
    LUT3D *newLUT = [LUT3D LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    
//    if([otherLUT inputLowerBound] > [self inputLowerBound] || [otherLUT inputUpperBound] < [self inputUpperBound]){
//        //other LUT does not encompass the range of the current LUT - this won't work for us!
//        @throw [NSException exceptionWithName:@"InvalidCombiningLUT"
//                                       reason:[NSString stringWithFormat:@"LUT to combine with does not encompass the full input range of the current LUT."]
//                                     userInfo:nil];
//    }
    
    LUT3DConcurrentLoop([newLUT size], ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColor *startColor = [self colorAtR:r g:g b:b];
        LUTColor *newColor = [otherLUT colorAtColor:startColor];
        [newLUT setColor:newColor r:r g:g b:b];
    });
    
    return newLUT;
}



- (instancetype)LUTByClamping01{
    LUT3D *newLUT = [self copy];

    LUT3DConcurrentLoop([newLUT size], ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        [newLUT setColor:[[newLUT colorAtR:r g:g b:b] clamped01] r:r g:g b:b];
    });
    
    return newLUT;
}

- (instancetype)LUT3DByExtractingColorOnly{
    LUT1D *reversed1D = [[self LUT1D] LUT1DByReversing];
    
    if(reversed1D == nil){
        return nil;
    }
    
    LUT3D *extractedLUT = [self LUTByCombiningWithLUT:reversed1D];
    
    return extractedLUT;
}

- (LUT1D *)LUT1D{
    NSMutableArray *redCurve = [NSMutableArray array];
    NSMutableArray *greenCurve = [NSMutableArray array];
    NSMutableArray *blueCurve = [NSMutableArray array];
    
    LUTColor *color;
    for(int i = 0; i < [self size]; i++){
        color = [self colorAtR:i g:i b:i];
        [redCurve addObject:@(color.red)];
        [greenCurve addObject:@(color.green)];
        [blueCurve addObject:@(color.blue)];
    }
    
    return [LUT1D LUT1DWithRedCurve:redCurve greenCurve:greenCurve blueCurve:blueCurve lowerBound:0.0 upperBound:1.0];
}

- (instancetype)LUT3DByConvertingToMonoWithConversionMethod:(LUTMonoConversionMethod)conversionMethod{
    LUT3D *newLUT = [self copy];
    
    typedef LUTColor* (^converter)(LUTColor *);
    
    converter convertToMonoBlock;
    
    if(conversionMethod == LUTMonoConversionMethodAverageRGB){
        convertToMonoBlock = ^(LUTColor *color){double average = (color.red+color.green+color.blue)/3.0; return [LUTColor colorWithRed:average green:average blue:average];};
    }
    else if (conversionMethod == LUTMonoConversionMethodRedCopiedToRGB){
        convertToMonoBlock = ^(LUTColor *color){return [LUTColor colorWithRed:color.red green:color.red blue:color.red];};
    }
    else if (conversionMethod == LUTMonoConversionMethodGreenCopiedToRGB){
        convertToMonoBlock = ^(LUTColor *color){return [LUTColor colorWithRed:color.green green:color.green blue:color.green];};
    }
    else if (conversionMethod == LUTMonoConversionMethodBlueCopiedToRGB){
        convertToMonoBlock = ^(LUTColor *color){return [LUTColor colorWithRed:color.blue green:color.blue blue:color.blue];};
    }
    
    
    LUT3DConcurrentLoop([newLUT size], ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        [newLUT setColor:convertToMonoBlock([newLUT colorAtR:r g:g b:b])
                        r:r
                        g:g
                        b:b];
    });
    
    return newLUT;
    
}

+ (M13OrderedDictionary *)LUTMonoConversionMethods{
    return M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"Averaged RGB":@(LUTMonoConversionMethodAverageRGB)},
                                                                  @{@"Copy Red Channel":@(LUTMonoConversionMethodRedCopiedToRGB)},
                                                                  @{@"Copy Green Channel":@(LUTMonoConversionMethodGreenCopiedToRGB)},
                                                                  @{@"Copy Blue Channel":@(LUTMonoConversionMethodBlueCopiedToRGB)}]);
}



- (id)copyWithZone:(NSZone *)zone{
    LUT3D *copiedLUT = [super copyWithZone:zone];
    [copiedLUT setLatticeArray:[[self latticeArray] mutableCopyWithZone:zone]];
    
    return copiedLUT;
}

+ (NSMutableArray *)blankLatticeArrayOfSize:(NSUInteger)size {
    NSMutableArray *blankArray = [NSMutableArray arrayWithCapacity:size];
    for (int i = 0; i < size; i++) {
        blankArray[i] = [NSNull null];
    }

    NSMutableArray *rArray = [blankArray mutableCopy];
    for (int i = 0; i < size; i++) {
        NSMutableArray *gArray = [blankArray mutableCopy];
        for (int j = 0; j < size; j++) {
            gArray[j] = [blankArray mutableCopy]; // bArray
        }
        rArray[i] = gArray;
    }

    return rArray;
}

- (void)setColor:(LUTColor *)color r:(NSUInteger)r g:(NSUInteger)g b:(NSUInteger)b {
    _latticeArray[r][g][b] = color;
}

- (LUTColor *)colorAtR:(NSUInteger)r g:(NSUInteger)g b:(NSUInteger)b {
    LUTColor *color = _latticeArray[r][g][b];
    if ([color isEqual:[NSNull null]]) {
        return nil;
    }
    return color;
}

- (LUTColor *)colorAtInterpolatedR:(double)redPoint g:(double)greenPoint b:(double)bluePoint {
    NSUInteger cubeSize = self.size;

    if ((0 < redPoint   && redPoint     > cubeSize - 1) ||
        (0 < greenPoint && greenPoint   > cubeSize - 1) ||
        (0 < bluePoint  && bluePoint    > cubeSize - 1)) {
        @throw [NSException exceptionWithName:@"InvalidInputs"
                                       reason:[NSString stringWithFormat:@"Tried to access out-of-bounds lattice point r:%f g:%f b:%f", redPoint, greenPoint, bluePoint]
                                     userInfo:nil];
    }

    double lowerRedPoint = clamp(floor(redPoint), 0, cubeSize-1);
    double upperRedPoint = clamp(lowerRedPoint + 1, 0, cubeSize-1);

    double lowerGreenPoint = clamp(floor(greenPoint), 0, cubeSize-1);
    double upperGreenPoint = clamp(lowerGreenPoint + 1, 0, cubeSize-1);

    double lowerBluePoint = clamp(floor(bluePoint), 0, cubeSize-1);
    double upperBluePoint = clamp(lowerBluePoint + 1, 0, cubeSize-1);

    LUTColor *C000 = [self colorAtR:lowerRedPoint g:lowerGreenPoint b:lowerBluePoint];
    LUTColor *C010 = [self colorAtR:lowerRedPoint g:lowerGreenPoint b:upperBluePoint];
    LUTColor *C100 = [self colorAtR:upperRedPoint g:lowerGreenPoint b:lowerBluePoint];
    LUTColor *C001 = [self colorAtR:lowerRedPoint g:upperGreenPoint b:lowerBluePoint];
    LUTColor *C110 = [self colorAtR:upperRedPoint g:lowerGreenPoint b:upperBluePoint];
    LUTColor *C111 = [self colorAtR:upperRedPoint g:upperGreenPoint b:upperBluePoint];
    LUTColor *C101 = [self colorAtR:upperRedPoint g:upperGreenPoint b:lowerBluePoint];
    LUTColor *C011 = [self colorAtR:lowerRedPoint g:upperGreenPoint b:upperBluePoint];

    LUTColor *C00  = [C000 lerpTo:C100 amount:1.0 - (upperRedPoint - redPoint)];
    LUTColor *C10  = [C010 lerpTo:C110 amount:1.0 - (upperRedPoint - redPoint)];
    LUTColor *C01  = [C001 lerpTo:C101 amount:1.0 - (upperRedPoint - redPoint)];
    LUTColor *C11  = [C011 lerpTo:C111 amount:1.0 - (upperRedPoint - redPoint)];

    LUTColor *C1 = [C01 lerpTo:C11 amount:1.0 - (upperBluePoint - bluePoint)];
    LUTColor *C0 = [C00 lerpTo:C10 amount:1.0 - (upperBluePoint - bluePoint)];

    return [C0 lerpTo:C1 amount:1.0 - (upperGreenPoint - greenPoint)];
}


@end
