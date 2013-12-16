//
//  LUT.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUT.h"

@implementation LUT

+ (LUT *)LUTWithLattice:(LUTLattice *)lattice {
    LUT *lut = [[LUT alloc] init];
    lut.lattice = lattice;
    return lut;
}

+ (LUT *)identityLutOfSize:(NSUInteger)size {
    NSMutableArray *indices = [NSMutableArray array];
    float ratio = 1.0 / (float)(size - 1);
    for (int i = 0; i < size; i++) {
        [indices addObject:@((float)i * ratio)];
    }
    
    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:size];

    for (int r = 0; r < size; r++) {
        for (int g = 0; g < size; g++) {
            for (int b = 0; b < size; b++) {
                LUTColorValue rv = [indices[r] doubleValue];
                LUTColorValue gv = [indices[g] doubleValue];
                LUTColorValue bv = [indices[b] doubleValue];
                [lattice setColor:[LUTColor colorWithRed:rv green:gv blue:bv] r:r g:g b:b];
            }
        }
    }

    return [LUT LUTWithLattice:lattice];
}

- (CIFilter *)coreImageFilter {
    
    NSUInteger size = self.lattice.size;
    size_t cubeDataSize = size * size * size * sizeof ( float ) * 4;
    float *cubeData = (float *) malloc ( cubeDataSize );
    
    size_t offset = 0;
    for (int z = 0; z < size; z++) {
        for (int y = 0; y < size; y++) {
            for (int x = 0; x < size; x++) {
                
                LUTColor *color = [self.lattice colorAtR:x g:y b:z];
                
                cubeData[offset]   = color.red;
                cubeData[offset+1] = color.green;
                cubeData[offset+2] = color.blue;
                cubeData[offset+3] = 1.0;
                
                offset += 4;
            }
        }
    }
    
    NSData *data = [NSData dataWithBytesNoCopy:cubeData length:cubeDataSize freeWhenDone:YES];
    CIFilter *colorCube = [CIFilter filterWithName:@"CIColorCube"];
    [colorCube setValue:@(size) forKey:@"inputCubeDimension"];
    [colorCube setValue:data forKey:@"inputCubeData"];

    return colorCube;
}

@end
