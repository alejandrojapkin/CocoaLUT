//
//  LUT1D.m
//  Pods
//
//  Created by Greg Cotten and Wil Gieseler on 3/5/14.
//
//

#import "LUT1D.h"

@interface LUT1D ()

@property (strong) NSArray *redCurve;
@property (strong) NSArray *greenCurve;
@property (strong) NSArray *blueCurve;
@property NSUInteger size;


@end

@implementation LUT1D

+ (instancetype)LUT1DWithRedCurve:(NSArray *)redCurve
                       greenCurve:(NSArray *)greenCurve
                        blueCurve:(NSArray *)blueCurve
                       lowerBound:(double)lowerBound
                       upperBound:(double)upperBound {
    return [[[self class] alloc] initWithRedCurve:redCurve
                                       greenCurve:greenCurve
                                        blueCurve:blueCurve
                                       lowerBound:lowerBound
                                       upperBound:upperBound];
}

+ (instancetype)LUT1DWith1DCurve:(NSArray *)curve1D
                      lowerBound:(double)lowerBound
                      upperBound:(double)upperBound {
    return [[[self class] alloc] initWithRedCurve:[curve1D copy]
                                       greenCurve:[curve1D copy]
                                        blueCurve:[curve1D copy]
                                       lowerBound:lowerBound
                                       upperBound:upperBound];
}

- (instancetype)initWithRedCurve:(NSArray *)redCurve
                      greenCurve:(NSArray *)greenCurve
                       blueCurve:(NSArray *)blueCurve
                      lowerBound:(double)lowerBound
                      upperBound:(double)upperBound {
    if (self = [super init]){
        self.redCurve = redCurve;
        self.greenCurve = greenCurve;
        self.blueCurve = blueCurve;
        self.inputLowerBound = lowerBound;
        self.inputUpperBound = upperBound;
        
        NSAssert(redCurve.count == greenCurve.count && redCurve.count == blueCurve.count, @"Curves must be the same length.");
        self.size = self.redCurve.count;
    }
    return self;
}

- (LUTColor *)colorAtColor:(LUTColor *)inputColor{
    inputColor = [inputColor clampedWithLowerBound:self.inputLowerBound upperBound:self.inputUpperBound];
    double redRemappedInterpolatedIndex = remap(inputColor.red, self.inputLowerBound, self.inputUpperBound, 0, self.size-1);
    double greenRemappedInterpolatedIndex = remap(inputColor.green, self.inputLowerBound, self.inputUpperBound, 0, self.size-1);
    double blueRemappedInterpolatedIndex = remap(inputColor.blue, self.inputLowerBound, self.inputUpperBound, 0, self.size-1);
    
    return [self colorAtInterpolatedR:redRemappedInterpolatedIndex
                                    g:greenRemappedInterpolatedIndex
                                    b:blueRemappedInterpolatedIndex];
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


- (LUT1D *)LUT1DByResizingToSize:(NSUInteger)newSize {
    /*
    if (newSize == self.size) {
        return [self copy];
    }
    */
    NSMutableArray *newRedCurve = [NSMutableArray array];
    NSMutableArray *newGreenCurve = [NSMutableArray array];
    NSMutableArray *newBlueCurve = [NSMutableArray array];
    
    double ratio = ((double)self.size - 1.0) / ((float)newSize - 1.0);
    
    for(int i = 0; i < newSize; i++){
        double interpolatedIndex = (double)i * ratio;
        
        LUTColor *color = [self colorAtInterpolatedR:interpolatedIndex g:interpolatedIndex b:interpolatedIndex];
        
        [newRedCurve addObject:@(color.red)];
        [newGreenCurve addObject:@(color.green)];
        [newBlueCurve addObject:@(color.blue)];
        
        
    }
    
    return [LUT1D LUT1DWithRedCurve:newRedCurve greenCurve:newGreenCurve blueCurve:newBlueCurve lowerBound:self.inputLowerBound upperBound:self.inputUpperBound];
}

- (LUT1D *)LUT1DByReversing{
    if(![self isReversible]){
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
    
    double range = newUpperBound - newLowerBound;
    
    for(NSArray *curve in rgbCurves){
        NSMutableArray *newCurve = [[NSMutableArray alloc] init];
        
        double minValue = [[curve valueForKeyPath:@"@min.self"] doubleValue];
        double maxValue = [[curve valueForKeyPath:@"@max.self"] doubleValue];
        
        
        for(int i = 0; i < self.size; i++){
            double remappedIndex = newLowerBound + range*((double)i/(double)(self.size-1));
            if (remappedIndex <= minValue){
                [newCurve addObject:@(minValue)];
            }
            else if(remappedIndex >= maxValue){
                [newCurve addObject:@(maxValue)];
            }
            else{
                for(int i = 0; i < self.size; i++){
                    double currentValue = [curve[i] doubleValue];
                    if (remappedIndex < currentValue){
                        double previousValue = [curve[i-1] doubleValue]; //smaller than remappedIndex
                        double lowerValue = remap(i-1, 0, self.size-1, self.inputLowerBound, self.inputUpperBound);
                        double higherValue = remap(i, 0, self.size-1, self.inputLowerBound, self.inputUpperBound);
                        [newCurve addObject:@(lerp1d(lowerValue, higherValue,(remappedIndex - previousValue)/(currentValue - previousValue)))];
                        break;
                    }
                }
            }
            
        }
        
        [newRGBCurves addObject:[NSArray arrayWithArray:newCurve]];
    }
    
    return [LUT1D LUT1DWithRedCurve:newRGBCurves[0]
                         greenCurve:newRGBCurves[1]
                          blueCurve:newRGBCurves[2]
                         lowerBound:newLowerBound
                         upperBound:newUpperBound];
}

- (BOOL)isReversible{
    BOOL isIncreasing = YES;
    BOOL isDecreasing = YES;
    
    NSArray *rgbCurves = @[self.redCurve, self.greenCurve, self.blueCurve];
    
    for(NSArray *curve in rgbCurves){
        double lastValue = [curve[0] doubleValue];
        for(int i = 1; i < [curve count]; i++){
            double currentValue = [curve[i] doubleValue];
            if(currentValue < lastValue){//make <= to be very strict
                isIncreasing = NO;
            }
            if(currentValue > lastValue){//make <= to be very strict
                isDecreasing = NO;
            }
            lastValue = currentValue;
        }
    }
    return isIncreasing;
}

- (LUT *)lutOfSize:(NSUInteger)size {
    LUT1D *resized1DLUT = [self LUT1DByResizingToSize:size];
    
    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:size];
    
    LUTConcurrentCubeLoop(lattice.size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColorValue rv = [resized1DLUT.redCurve[r] doubleValue];
        LUTColorValue gv = [resized1DLUT.greenCurve[g] doubleValue];
        LUTColorValue bv = [resized1DLUT.blueCurve[b] doubleValue];
        [lattice setColor:[LUTColor colorWithRed:rv green:gv blue:bv] r:r g:g b:b];
    });
    
    return [[LUT LUTWithLattice:lattice] LUTByResizingToSize:size];
}

@end
