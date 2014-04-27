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
    return [[[self class] alloc] initWithRedCurve:[curve1D copy]
                                       greenCurve:[curve1D copy]
                                        blueCurve:[curve1D copy]
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

- (LUTColor *)colorAtR:(NSUInteger)r g:(NSUInteger)g b:(NSUInteger)b {
    return [LUTColor colorWithRed:[self.redCurve[r] doubleValue] green:[self.greenCurve[g] doubleValue] blue:[self.blueCurve[b] doubleValue]];
}

- (void)setValue:(LUTColorValue)value atR:(NSUInteger)r{
    [self.redCurve replaceObjectAtIndex:r withObject:@(value)];
}

- (void)setValue:(LUTColorValue)value atG:(NSUInteger)g{
    [self.greenCurve replaceObjectAtIndex:g withObject:@(value)];
}

- (void)setValue:(LUTColorValue)value atB:(NSUInteger)b{
    [self.blueCurve replaceObjectAtIndex:b withObject:@(value)];
}

- (double)valueAtR:(NSUInteger)r{
    return [[self.redCurve objectAtIndex:r] doubleValue];
}

- (double)valueAtG:(NSUInteger)g{
    return [[self.greenCurve objectAtIndex:g] doubleValue];
}

- (double)valueAtB:(NSUInteger)b{
    return [[self.blueCurve objectAtIndex:b] doubleValue];
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
    
    NSMutableArray *newRedCurve = [NSMutableArray array];
    NSMutableArray *newGreenCurve = [NSMutableArray array];
    NSMutableArray *newBlueCurve = [NSMutableArray array];
    
    double ratio = ((double)[self size] - 1.0) / ((float)newSize - 1.0);
    
    for(int i = 0; i < newSize; i++){
        double interpolatedIndex = (double)i * ratio;
        
        LUTColor *color = [self colorAtInterpolatedR:interpolatedIndex g:interpolatedIndex b:interpolatedIndex];
        
        [newRedCurve addObject:@(color.red)];
        [newGreenCurve addObject:@(color.green)];
        [newBlueCurve addObject:@(color.blue)];
        
        
    }
    
    return [LUT1D LUT1DWithRedCurve:newRedCurve greenCurve:newGreenCurve blueCurve:newBlueCurve lowerBound:[self inputLowerBound] upperBound:[self inputUpperBound]];
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
        double redIndexAsColor = remap(r, 0, [newLUT size]-1, [newLUT inputLowerBound], [newLUT inputUpperBound]);
        double greenIndexAsColor = remap(g, 0, [newLUT size]-1, [newLUT inputLowerBound], [newLUT inputUpperBound]);
        double blueIndexAsColor = remap(b, 0, [newLUT size]-1, [newLUT inputLowerBound], [newLUT inputUpperBound]);
        
        LUTColor *transformedColor = [resized1DLUT colorAtColor:[LUTColor colorWithRed:redIndexAsColor
                                                                                 green:greenIndexAsColor
                                                                                  blue:blueIndexAsColor]];
        
        [newLUT setColor:transformedColor r:r g:g b:b];
    });
    
    return newLUT;
}

- (id)copyWithZone:(NSZone *)zone{
    LUT1D *copiedLUT = [LUT1D LUTOfSize:[self size] inputLowerBound:[self inputLowerBound] inputUpperBound:[self inputUpperBound]];
    copiedLUT.redCurve = [self.redCurve copyWithZone:zone];
    copiedLUT.greenCurve = [self.greenCurve copyWithZone:zone];
    copiedLUT.blueCurve = [self.blueCurve copyWithZone:zone];
    [copiedLUT setMetadata:[[self metadata] copyWithZone:zone]];
    [copiedLUT setTitle:[[self title] copyWithZone:zone]];
    [copiedLUT setDescription:[[self description] copyWithZone:zone]];
    
    return copiedLUT;
}

@end
