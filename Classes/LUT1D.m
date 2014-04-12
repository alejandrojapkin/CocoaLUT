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
@property (assign) double inputLowerBound;
@property (assign) double inputUpperBound;

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
        NSUInteger bottomIndex = floor(interpolatedIndex);
        NSUInteger topIndex = ceil(interpolatedIndex);
        
        double interpolatedRedValue = lerp1d([self.redCurve[bottomIndex] doubleValue], [self.redCurve[topIndex] doubleValue], interpolatedIndex - (double)bottomIndex);
        double interpolatedGreenValue = lerp1d([self.greenCurve[bottomIndex] doubleValue], [self.greenCurve[topIndex] doubleValue], interpolatedIndex - (double)bottomIndex);
        double interpolatedBlueValue = lerp1d([self.blueCurve[bottomIndex] doubleValue], [self.blueCurve[topIndex] doubleValue], interpolatedIndex - (double)bottomIndex);
        
        [newRedCurve addObject:@(interpolatedRedValue)];
        [newGreenCurve addObject:@(interpolatedGreenValue)];
        [newBlueCurve addObject:@(interpolatedBlueValue)];
        
        
    }
    
    return [LUT1D LUT1DWithRedCurve:newRedCurve greenCurve:newGreenCurve blueCurve:newBlueCurve lowerBound:0.0 upperBound:1.0];
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
