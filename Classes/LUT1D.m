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

+ (instancetype)LUT1DWithRedCurve:(NSArray *)redCurve greenCurve:(NSArray *)greenCurve blueCurve:(NSArray *)blueCurve{
    return [[[self class] alloc] initWithRedCurve:redCurve greenCurve:greenCurve blueCurve:blueCurve];
}

- (instancetype)initWithRedCurve:(NSArray *)redCurve greenCurve:(NSArray *)greenCurve blueCurve:(NSArray *)blueCurve{
    if (self = [super init]){
        self.redCurve = redCurve;
        self.greenCurve = greenCurve;
        self.blueCurve = blueCurve;
        NSAssert(redCurve.count == greenCurve.count && redCurve.count == blueCurve.count, @"Curves must be the same length.");
        self.size = self.redCurve.count;
    }
    return self;
}

- (LUT1D *)LUT1DByResizingToSize:(NSUInteger)newSize {
    if (newSize == self.size) {
        return [self copy];
    }
    
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
    
    return [LUT1D LUT1DWithRedCurve:newRedCurve greenCurve:newGreenCurve blueCurve:newBlueCurve];
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
