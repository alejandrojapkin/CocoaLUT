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
    }
    return self;
}

- (LUT *)lut{
    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:self.redCurve.count];
    
    LUTConcurrentCubeLoop(lattice.size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColorValue rv = [self.redCurve[r] doubleValue];
        LUTColorValue gv = [self.greenCurve[g] doubleValue];
        LUTColorValue bv = [self.blueCurve[b] doubleValue];
        [lattice setColor:[LUTColor colorWithRed:rv green:gv blue:bv] r:r g:g b:b];
    });
    
    return [LUT LUTWithLattice:lattice];
}

@end
