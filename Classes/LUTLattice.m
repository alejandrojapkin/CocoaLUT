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


@end
