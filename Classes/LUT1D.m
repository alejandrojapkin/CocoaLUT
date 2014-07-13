//
//  LUT1D.m
//  Pods
//
//  Created by Greg Cotten and Wil Gieseler on 3/5/14.
//
//

#import "LUT1D.h"
#if defined(COCOAPODS_POD_AVAILABLE_VVLUT1DFilter)
#import <VVLUT1DFilter/VVLUT1DFilter.h>
#endif

@interface LUT1D ()

@property (strong) NSMutableArray *redCurve;
@property (strong) NSMutableArray *greenCurve;
@property (strong) NSMutableArray *blueCurve;

@end

@implementation LUT1D

+ (instancetype)LUT1DWithRedCurve:(NSMutableArray *)redCurve
                       greenCurve:(NSMutableArray *)greenCurve
                        blueCurve:(NSMutableArray *)blueCurve
                       lowerBound:(double)lowerBound
                       upperBound:(double)upperBound {
    return [[self alloc] initWithRedCurve:redCurve
                                       greenCurve:greenCurve
                                        blueCurve:blueCurve
                                       lowerBound:lowerBound
                                       upperBound:upperBound];
}

+ (instancetype)LUT1DWith1DCurve:(NSMutableArray *)curve1D
                      lowerBound:(double)lowerBound
                      upperBound:(double)upperBound {
    return [[self alloc] initWithRedCurve:[curve1D mutableCopy]
                                       greenCurve:[curve1D mutableCopy]
                                        blueCurve:[curve1D mutableCopy]
                                       lowerBound:lowerBound
                                       upperBound:upperBound];
}

- (instancetype)initWithRedCurve:(NSMutableArray *)redCurve
                      greenCurve:(NSMutableArray *)greenCurve
                       blueCurve:(NSMutableArray *)blueCurve
                      lowerBound:(double)lowerBound
                      upperBound:(double)upperBound {
    if (self = [super initWithSize:redCurve.count inputLowerBound:lowerBound inputUpperBound:upperBound]){
        
        self.redCurve = redCurve;
        self.greenCurve = greenCurve;
        self.blueCurve = blueCurve;
        if(redCurve.count != greenCurve.count || redCurve.count != blueCurve.count){
            @throw [NSException exceptionWithName:@"LUT1DCreationError" reason:[NSString stringWithFormat:@"Curves must be the same length. R:%d G:%d B:%d", (int)redCurve.count, (int)greenCurve.count, (int)blueCurve.count] userInfo:nil];
        }

    }
    return self;
}

+ (instancetype)LUTOfSize:(NSUInteger)size
          inputLowerBound:(double)inputLowerBound
          inputUpperBound:(double)inputUpperBound{
    NSMutableArray *blankCurve = [NSMutableArray array];
    for(int i = 0; i < size; i++){
        [blankCurve addObject:[NSNull null]];
    }
    return [LUT1D LUT1DWith1DCurve:blankCurve lowerBound:inputLowerBound upperBound:inputUpperBound];
}

- (void) LUTLoopWithBlock:( void ( ^ )(size_t r, size_t g, size_t b) )block{
    for(int index = 0; index < [self size]; index++){
        block(index, index, index);
    }
}

- (LUT *)LUTByCombiningWithLUT:(LUT *)otherLUT{
    LUT *combinedLUT;
    if(isLUT1D(otherLUT)){
        combinedLUT = [LUT1D LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    }
    else{
        combinedLUT = [LUT3D LUTOfSize:[otherLUT size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    }
    [combinedLUT copyMetaPropertiesFromLUT:self];
    
    LUT *selfResizedLUT = [self LUTByResizingToSize:[combinedLUT size]];
    
    [combinedLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        LUTColor *startColor = [selfResizedLUT colorAtR:r g:g b:b];
        LUTColor *newColor = [otherLUT colorAtColor:startColor];
        [combinedLUT setColor:newColor r:r g:g b:b];
    }];
    
    return combinedLUT;
}

- (NSArray *)rgbCurveArray{
    return @[[self.redCurve mutableCopy], [self.greenCurve mutableCopy], [self.blueCurve mutableCopy]];
}

//convenience method for comparison purposes
- (NSMutableArray *)colorCurve{
    
    NSMutableArray *colorCurve = [NSMutableArray array];
    for(int i = 0; i < self.redCurve.count; i++){
        [colorCurve addObject:[LUTColor colorWithRed:[self.redCurve[i] doubleValue] green:[self.greenCurve[i] doubleValue] blue:[self.blueCurve[i] doubleValue]]];
    }
    return colorCurve;
}

- (void)setColor:(LUTColor *)color r:(NSUInteger)r g:(NSUInteger)g b:(NSUInteger)b{
    self.redCurve[r] = @(color.red);
    self.greenCurve[g] = @(color.green);
    self.blueCurve[b] = @(color.blue);
}

- (LUTColor *)colorAtR:(NSUInteger)r g:(NSUInteger)g b:(NSUInteger)b {
    return [LUTColor colorWithRed:[self.redCurve[r] doubleValue] green:[self.greenCurve[g] doubleValue] blue:[self.blueCurve[b] doubleValue]];
}

- (double)valueAtR:(NSUInteger)r{
    return [self.redCurve[r] doubleValue];
}
- (double)valueAtG:(NSUInteger)g{
    return [self.greenCurve[g] doubleValue];
}
- (double)valueAtB:(NSUInteger)b{
    return [self.blueCurve[b] doubleValue];
}

- (LUTColor *)colorAtInterpolatedR:(double)redPoint
                                 g:(double)greenPoint
                                 b:(double)bluePoint{
    
    if ((redPoint < 0   || redPoint     > self.size - 1) ||
        (greenPoint < 0 || greenPoint   > self.size - 1) ||
        (bluePoint < 0  || bluePoint    > self.size - 1)) {
        @throw [NSException exceptionWithName:@"InvalidInputs"
                                       reason:[NSString stringWithFormat:@"Tried to access out-of-bounds point r:%f g:%f b:%f", redPoint, greenPoint, bluePoint]
                                     userInfo:nil];
    }
    
    //red
    int redBottomIndex = floor(redPoint);
    int redTopIndex = ceil(redPoint);
    
    int greenBottomIndex = floor(greenPoint);
    int greenTopIndex = ceil(greenPoint);
    
    int blueBottomIndex = floor(bluePoint);
    int blueTopIndex = ceil(bluePoint);
    
    double interpolatedRedValue = lerp1d([self.redCurve[redBottomIndex] doubleValue], [self.redCurve[redTopIndex] doubleValue], redPoint - (double)redBottomIndex);
    double interpolatedGreenValue = lerp1d([self.greenCurve[greenBottomIndex] doubleValue], [self.greenCurve[greenTopIndex] doubleValue], greenPoint - (double)greenBottomIndex);
    double interpolatedBlueValue = lerp1d([self.blueCurve[blueBottomIndex] doubleValue], [self.blueCurve[blueTopIndex] doubleValue], bluePoint - (double)blueBottomIndex);
    
    return [LUTColor colorWithRed:interpolatedRedValue green:interpolatedGreenValue blue:interpolatedBlueValue];

}

+ (M13OrderedDictionary *)LUT1DSwizzleChannelsMethods{
    return M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"Averaged RGB":@(LUT1DSwizzleChannelsMethodAverageRGB)},
                                                                  @{@"Copy Red Channel":@(LUT1DSwizzleChannelsMethodRedCopiedToRGB)},
                                                                  @{@"Copy Green Channel":@(LUT1DSwizzleChannelsMethodGreenCopiedToRGB)},
                                                                  @{@"Copy Blue Channel":@(LUT1DSwizzleChannelsMethodBlueCopiedToRGB)}]);
}

- (instancetype)LUT1DBySwizzling1DChannelsWithMethod:(LUT1DSwizzleChannelsMethod)method{
    LUT1D *swizzledLUT = [LUT1D LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [swizzledLUT copyMetaPropertiesFromLUT:self];
    
    [swizzledLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        if(method == LUT1DSwizzleChannelsMethodAverageRGB){
            LUTColor *color = [self colorAtR:r g:g b:b];
            double averageValue = (color.red+color.green+color.blue)/3.0;
            [swizzledLUT setColor:[LUTColor colorWithRed:averageValue green:averageValue blue:averageValue] r:r g:g b:b];
        }
        else if(method == LUT1DSwizzleChannelsMethodRedCopiedToRGB){
            LUTColor *color = [self colorAtR:r g:g b:b];
            [swizzledLUT setColor:[LUTColor colorWithRed:color.red green:color.red blue:color.red] r:r g:g b:b];
        }
        else if(method == LUT1DSwizzleChannelsMethodGreenCopiedToRGB){
            LUTColor *color = [self colorAtR:r g:g b:b];
            [swizzledLUT setColor:[LUTColor colorWithRed:color.green green:color.green blue:color.green] r:r g:g b:b];
        }
        else if(method == LUT1DSwizzleChannelsMethodBlueCopiedToRGB){
            LUTColor *color = [self colorAtR:r g:g b:b];
            [swizzledLUT setColor:[LUTColor colorWithRed:color.blue green:color.blue blue:color.blue] r:r g:g b:b];
        }
    }];
    
    return swizzledLUT;
}

- (instancetype)LUT1DByReversingWithStrictness:(BOOL)strictness{
    if(![self isReversibleWithStrictness:strictness]){
        return nil;
    }
    NSArray *rgbCurves = @[self.redCurve, self.greenCurve, self.blueCurve];
    
    NSMutableArray *newRGBCurves = [[NSMutableArray alloc] init];
    
    NSMutableArray *allCurvesCombined = [[NSMutableArray alloc] init];
    [allCurvesCombined addObjectsFromArray:self.redCurve];
    [allCurvesCombined addObjectsFromArray:self.greenCurve];
    [allCurvesCombined addObjectsFromArray:self.blueCurve];
    
    double newLowerBound = [[allCurvesCombined valueForKeyPath:@"@min.doubleValue"] doubleValue];
    double newUpperBound = [[allCurvesCombined valueForKeyPath:@"@max.doubleValue"] doubleValue];
    
    for(NSMutableArray *curve in rgbCurves){
        NSMutableArray *newCurve = [[NSMutableArray alloc] init];
        
        double minValue = [[curve valueForKeyPath:@"@min.self"] doubleValue];
        double maxValue = [[curve valueForKeyPath:@"@max.self"] doubleValue];
        
        
        for(int i = 0; i < [self size]; i++){
            double remappedIndex = remap(i, 0, [self size]-1, newLowerBound, newUpperBound);

            if (remappedIndex <= minValue){
                [newCurve addObject:@([self inputLowerBound])];
            }
            else if(remappedIndex >= maxValue){
                [newCurve addObject:@([self inputUpperBound])];
            }
            else{
                for(int j = 0; j < [self size]; j++){
                    double currentValue = [curve[j] doubleValue];
                    if (currentValue > remappedIndex){
                        double previousValue = [curve[j-1] doubleValue]; //smaller or equal to remappedIndex
                        double lowerValue = remap(j-1, 0, [self size]-1, [self inputLowerBound], [self inputUpperBound]);
                        double higherValue = remap(j, 0, [self size]-1, [self inputLowerBound], [self inputUpperBound]);
                        [newCurve addObject:@(lerp1d(lowerValue, higherValue,(remappedIndex - previousValue)/(currentValue - previousValue)))];
                        break;
                    }
                }
            }
            
        }
        
        [newRGBCurves addObject:[NSMutableArray arrayWithArray:newCurve]];
    }
    
    //ease edges
//    if(![self isReversibleWithStrictness:YES]){
//        for (NSMutableArray *curve in newRGBCurves){
//            curve[0] = @(clampLowerBound([curve[1] doubleValue] - (([curve[2] doubleValue] - [curve[1] doubleValue])), self.inputLowerBound));
//            curve[self.size - 1] = @(clampUpperBound([curve[self.size-2] doubleValue] + (([curve[self.size-2] doubleValue] - [curve[self.size-3] doubleValue])), self.inputUpperBound));
//        }
//    }
    
    
    LUT1D *newLUT = [LUT1D LUT1DWithRedCurve:newRGBCurves[0]
                                  greenCurve:newRGBCurves[1]
                                   blueCurve:newRGBCurves[2]
                                  lowerBound:newLowerBound
                                  upperBound:newUpperBound];
    [newLUT copyMetaPropertiesFromLUT:self];
    
    return newLUT;
}

- (BOOL)isReversibleWithStrictness:(BOOL)strict{
    BOOL isIncreasing = YES;
    BOOL isDecreasing = YES;
    
    NSArray *rgbCurves = @[self.redCurve, self.greenCurve, self.blueCurve];
    
    for(NSMutableArray *curve in rgbCurves){
        double lastValue = [curve[0] doubleValue];
        for(int i = 1; i < [curve count]; i++){
            double currentValue = [curve[i] doubleValue];
            if(currentValue <= lastValue){//make <= to be very strict
                if(strict || currentValue != lastValue){
                    isIncreasing = NO;
                }
            }
            if(currentValue >= lastValue){//make <= to be very strict
                if(strict || currentValue != lastValue){
                    isDecreasing = NO;
                }
            }
            lastValue = currentValue;
        }
    }
    return isIncreasing;
}

- (bool)equalsLUT:(LUT *)comparisonLUT{
    if(isLUT3D(comparisonLUT)){
        return NO;
    }
    else{
        //it's LUT1D
        if([self size] != [comparisonLUT size]){
            return NO;
        }
        else{
            return [[self colorCurve] isEqualToArray:[(LUT1D *)comparisonLUT colorCurve]];
        }
    }
}

- (LUT3D *)LUT3DOfSize:(NSUInteger)size {
    //the size parameter is out of desperation - we can't be making 1024x cubes can we?
    LUT1D *resized1DLUT = [self LUTByResizingToSize:size];
    
    
    LUT3D *newLUT = [LUT3D LUTOfSize:size inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    [newLUT copyMetaPropertiesFromLUT:self];
    
    [newLUT LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        [newLUT setColor:[resized1DLUT colorAtR:r g:g b:b] r:r g:g b:b];
    }];
    
    return newLUT;
}

- (CIFilter *)coreImageFilterWithColorSpace:(CGColorSpaceRef)colorSpace{
    #if defined(COCOAPODS_POD_AVAILABLE_VVLUT1DFilter)
    LUT1D *usedLUT = [self LUTByResizingToSize:COCOALUT_VVLUT1DFILTER_SIZE];
    
    if (usedLUT.inputLowerBound != 0.0 || usedLUT.inputUpperBound != 1.0) {
        usedLUT = [usedLUT LUTByChangingInputLowerBound:0 inputUpperBound:1];
    }

    size_t dataSize = sizeof(float)*4*usedLUT.size;
    float* lutArray = (float *)malloc(dataSize);
    for (int i = 0; i < usedLUT.size; i++) {
        LUTColor *color = [usedLUT colorAtR:i g:i b:i];
        lutArray[i*4] = clamp(color.red, 0, 1);
        lutArray[i*4+1] = clamp(color.green, 0, 1);
        lutArray[i*4+2] = clamp(color.blue, 0, 1);
        lutArray[i*4+3] = 1.0;
    }
    
    NSData *inputData = [NSData dataWithBytes:lutArray length:dataSize];
    
    CIFilter *lutFilter = [CIFilter filterWithName:@"VVLUT1DFilter"];
    
    [lutFilter setValue:inputData forKey:@"inputData"];
    [lutFilter setValue:@(COCOALUT_VVLUT1DFILTER_SIZE) forKey:@"inputSize"];
    
    return lutFilter;
    
    #else
    return [super coreImageFilterWithColorSpace:colorSpace];
    #endif
}

- (id)copyWithZone:(NSZone *)zone{
    LUT1D *copiedLUT = [super copyWithZone:zone];
    copiedLUT.redCurve = [self.redCurve mutableCopyWithZone:zone];
    copiedLUT.greenCurve = [self.greenCurve mutableCopyWithZone:zone];
    copiedLUT.blueCurve = [self.blueCurve mutableCopyWithZone:zone];
    
    return copiedLUT;
}

@end
