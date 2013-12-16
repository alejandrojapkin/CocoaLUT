//
//  LUTReverser.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/16/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTReverser.h"

@interface LUTReverser ()
@property (strong) KDTree *kdTree;
@end

double remapint01(int value, int maxValue) {
    return (double)value / (double)maxValue;
}

@implementation LUTReverser

+ (instancetype)reverserForLUT:(LUT *)lut {
    LUTReverser *r = [[self alloc] init];
    r.lut = lut;
    return r;
}

- (void)buildSearchTreeWithSize:(NSUInteger)newSize {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:pow(newSize, 3)];
    
    double ratio = ((double)self.lut.lattice.size - 1.0) / ((float)newSize - 1.0);
    
    int maxValue = (int)newSize - 1;
    
    for (int r = 0; r < newSize; r++) {
        for (int g = 0; g < newSize; g++) {
            for (int b = 0; b < newSize; b++) {
                LUTColor *color = [self.lut.lattice colorAtInterpolatedR:r * ratio g:g * ratio b:b * ratio];
                [array addObject:@[@(remapint01(r, maxValue)), @(remapint01(g, maxValue)), @(remapint01(b, maxValue)), color]];
            }
        }
    }
    
    self.kdTree = [[KDTree alloc] initWithArray:array];
}

- (LUT *)reversedLUT {
    
    NSUInteger outputSize = self.lut.lattice.size;
    
    NSLog(@"Building search tree...");
    NSDate *startTime = [NSDate date];
    
    [self buildSearchTreeWithSize:outputSize * 3];
    
    NSLog(@"Tree built in: %f s", -[startTime timeIntervalSinceNow]);

    NSLog(@"Building LUT from tree...");
    NSDate *startTime2 = [NSDate date];
    
    LUTLattice *newLattice = [[LUTLattice alloc] initWithSize:outputSize];
    
    int maxValue = (int)outputSize - 1;
    
    for (int r = 0; r < outputSize; r++) {
        for (int g = 0; g < outputSize; g++) {
            for (int b = 0; b < outputSize; b++) {
                KDLeaf *leaf = [self.kdTree findNearestNeighbor:@[@(remapint01(r, maxValue)),
                                                                  @(remapint01(g, maxValue)),
                                                                  @(remapint01(b, maxValue))]];
                [newLattice setColor:leaf.metadata r:r g:g b:b];
            }
        }
    }
    
    NSLog(@"LUT built in: %f s", -[startTime2 timeIntervalSinceNow]);

    return [LUT LUTWithLattice:newLattice];
}

@end
