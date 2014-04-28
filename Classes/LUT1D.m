//
//  LUT1D.m
//  Pods
//
//  Created by Greg Cotten and Wil Gieseler on 3/5/14.
//
//

#import "LUT1D.h"

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
    return [[[self class] alloc] initWithRedCurve:redCurve
                                       greenCurve:greenCurve
                                        blueCurve:blueCurve
                                       lowerBound:lowerBound
                                       upperBound:upperBound];
}

+ (instancetype)LUT1DWith1DCurve:(NSMutableArray *)curve1D
                      lowerBound:(double)lowerBound
                      upperBound:(double)upperBound {
    return [[[self class] alloc] initWithRedCurve:[curve1D mutableCopy]
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
    if (self = [super init]){
        self.redCurve = redCurve;
        self.greenCurve = greenCurve;
        self.blueCurve = blueCurve;
        [self setInputLowerBound:lowerBound];
        [self setInputUpperBound:upperBound];
        
        NSAssert(redCurve.count == greenCurve.count && redCurve.count == blueCurve.count, @"Curves must be the same length.");
        [self setSize: self.redCurve.count];
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

+ (instancetype)LUTIdentityOfSize:(NSUInteger)size
                  inputLowerBound:(double)inputLowerBound
                  inputUpperBound:(double)inputUpperBound{
    LUT1D *identityLUT = [LUT1D LUTOfSize:size inputLowerBound:inputLowerBound inputUpperBound:inputUpperBound];
    LUT1DLoop(size, ^(NSUInteger index) {
        [identityLUT setColor:[identityLUT identityColorAtR:index g:index b:index] r:index g:index b:index];
    });
    return identityLUT;
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


- (instancetype)LUTByResizingToSize:(NSUInteger)newSize {
    if (newSize == self.size) {
        return [self copy];
    }
    LUT1D *resizedLUT = [LUT1D LUTOfSize:newSize inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    
    LUT1DLoop(newSize, ^(NSUInteger index) {
        double interpolatedIndex = remap(index, 0, [resizedLUT size] - 1, 0, [self size] - 1);
        
        LUTColor *color = [self colorAtInterpolatedR:interpolatedIndex g:interpolatedIndex b:interpolatedIndex];

        [resizedLUT setColor:color r:index g:index b:index];
    });
    
    return resizedLUT;
}

+ (M13OrderedDictionary *)LUT1DSwizzleChannelsMethods{
    return M13OrderedDictionaryFromOrderedArrayWithDictionaries(@[@{@"Averaged RGB":@(LUT1DSwizzleChannelsMethodAverageRGB)},
                                                                  @{@"Copy Red Channel":@(LUT1DSwizzleChannelsMethodRedCopiedToRGB)},
                                                                  @{@"Copy Green Channel":@(LUT1DSwizzleChannelsMethodGreenCopiedToRGB)},
                                                                  @{@"Copy Blue Channel":@(LUT1DSwizzleChannelsMethodBlueCopiedToRGB)}]);
}

- (LUT1D *)LUT1DBySwizzlingChannelsWithMethod:(LUT1DSwizzleChannelsMethod)method{
    LUT1D *swizzledLUT = [LUT1D LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    
    LUT1DLoop([swizzledLUT size], ^(NSUInteger index) {
        if(method == LUT1DSwizzleChannelsMethodAverageRGB){
            LUTColor *color = [self colorAtR:index g:index b:index];
            double averageValue = (color.red+color.green+color.blue)/3.0;
            [swizzledLUT setColor:[LUTColor colorWithRed:averageValue green:averageValue blue:averageValue] r:index g:index b:index];
        }
        else if(method == LUT1DSwizzleChannelsMethodRedCopiedToRGB){
            LUTColor *color = [self colorAtR:index g:index b:index];
            [swizzledLUT setColor:[LUTColor colorWithRed:color.red green:color.red blue:color.red] r:index g:index b:index];
        }
        else if(method == LUT1DSwizzleChannelsMethodGreenCopiedToRGB){
            LUTColor *color = [self colorAtR:index g:index b:index];
            [swizzledLUT setColor:[LUTColor colorWithRed:color.green green:color.green blue:color.green] r:index g:index b:index];
        }
        else if(method == LUT1DSwizzleChannelsMethodBlueCopiedToRGB){
            LUTColor *color = [self colorAtR:index g:index b:index];
            [swizzledLUT setColor:[LUTColor colorWithRed:color.blue green:color.blue blue:color.blue] r:index g:index b:index];
        }
    });
    
    return swizzledLUT;
}

- (LUT1D *)LUT1DByReversing{
    if(![self isReversibleWithStrictness:NO]){
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
                [newCurve addObject:@(minValue)];
            }
            else if(remappedIndex >= maxValue){
                [newCurve addObject:@(maxValue)];
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
    
    return [LUT1D LUT1DWithRedCurve:newRGBCurves[0]
                         greenCurve:newRGBCurves[1]
                          blueCurve:newRGBCurves[2]
                         lowerBound:newLowerBound
                         upperBound:newUpperBound];
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
                if(strict && currentValue == lastValue){
                    isIncreasing = NO;
                }
            }
            if(currentValue >= lastValue){//make <= to be very strict
                if(strict && currentValue == lastValue){
                    isDecreasing = NO;
                }
            }
            lastValue = currentValue;
        }
    }
    return isIncreasing;
}

- (LUT3D *)LUT3DOfSize:(NSUInteger)size {
    LUT1D *resized1DLUT = [self LUTByResizingToSize:size];
    
    LUT3D *newLUT = [LUT3D LUTOfSize:size inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    
    
    LUT3DConcurrentLoop(size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        [newLUT setColor:[resized1DLUT colorAtR:r g:g b:b] r:r g:g b:b];
    });
    
    return newLUT;
}

- (id)copyWithZone:(NSZone *)zone{
    LUT1D *copiedLUT = [LUT1D LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    copiedLUT.redCurve = [self.redCurve mutableCopyWithZone:zone];
    copiedLUT.greenCurve = [self.greenCurve mutableCopyWithZone:zone];
    copiedLUT.blueCurve = [self.blueCurve mutableCopyWithZone:zone];
    
    return copiedLUT;
}

@end
