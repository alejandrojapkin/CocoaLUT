//
//  LUTLattice.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTLattice.h"

@interface LUTLattice()
@property NSMutableArray *latticeArray;
@end

@implementation LUTLattice

- (id)initWithSize:(NSUInteger)size{
    if (self = [super init]) {
        _size = size;
        self.latticeArray = [self blankLatticeOfSize:_size];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:self.size];
    lattice.latticeArray = [self.latticeArray copy];
    return lattice;
}

- (NSMutableArray *)blankLatticeOfSize:(NSUInteger)size {
    NSMutableArray *blankArray = [NSMutableArray arrayWithCapacity:_size];
    for (int i = 0; i < _size; i++) {
        blankArray[i] = [NSNull null];
    }

    NSMutableArray *rArray = [blankArray mutableCopy];
    for (int i = 0; i < _size; i++) {
        NSMutableArray *gArray = [blankArray mutableCopy];
        for (int j = 0; j < _size; j++) {
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
    return _latticeArray[r][g][b];
}

- (LUTColor *)colorAtInterpolatedR:(double)redPoint g:(double)greenPoint b:(double)bluePoint {
    NSUInteger cubeSize = self.size;

    if ((0 < redPoint   && redPoint     > cubeSize - 1) ||
        (0 < greenPoint && greenPoint   > cubeSize - 1) ||
        (0 < bluePoint  && bluePoint    > cubeSize - 1)) {
        @throw [NSException exceptionWithName:@"InvalidInputs" reason:@"" userInfo:nil];
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
