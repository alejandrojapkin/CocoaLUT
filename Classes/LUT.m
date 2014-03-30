//
//  LUT.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUT.h"
#import "CocoaLUT.h"
#import "LUTFormatterCube.h"
#import "LUTFormatter3DL.h"
#import "LUTFormatterOLUT.h"
#import "LUTFormatterDiscreet1DLUT.h"
#import "LUTFormatterUnwrappedTexture.h"

@interface LUT ()
@property (strong) LUTLattice *lattice;
@end

@implementation LUT

+ (LUT *)LUTFromURL:(NSURL *)url {
    if ([url.pathExtension.lowercaseString isEqualToString:@"cube"]){
        return [LUTFormatterCube LUTFromFile:url];
    }
    else if ([url.pathExtension.lowercaseString isEqualToString:@"3dl"]) {
        return [LUTFormatter3DL LUTFromFile:url];
    }
    else if ([url.pathExtension.lowercaseString isEqualToString:@"olut"]) {
        return [LUTFormatterOLUT LUTFromFile:url];
    }
    else if ([url.pathExtension.lowercaseString isEqualToString:@"lut"]) {
        return [LUTFormatterDiscreet1DLUT LUTFromFile:url];
    }
    else if ([@[@"tif", @"tiff", @"png"] containsObject:url.pathExtension.lowercaseString]) {
        return [LUTFormatterUnwrappedTexture LUTFromFile:url];
    }
    return nil;
}

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

    LUTConcurrentCubeLoop(size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColorValue rv = [indices[r] doubleValue];
        LUTColorValue gv = [indices[g] doubleValue];
        LUTColorValue bv = [indices[b] doubleValue];
        [lattice setColor:[LUTColor colorWithRed:rv green:gv blue:bv] r:r g:g b:b];
    });

    return [LUT LUTWithLattice:lattice];
}

- (LUT *)LUTByCombiningWithLUT:(LUT *)otherLUT {
    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:self.lattice.size];
    
    LUTConcurrentCubeLoop(lattice.size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColor *startColor = [self.lattice colorAtR:r g:g b:b];
        LUTColor *newColor = [otherLUT.lattice colorAtColor:startColor];
        [lattice setColor:newColor r:r g:g b:b];
    });
    
    return [LUT LUTWithLattice:lattice];
}

- (LUT1D *) LUT1D{
    NSMutableArray *redCurve = [NSMutableArray array];
    NSMutableArray *greenCurve = [NSMutableArray array];
    NSMutableArray *blueCurve = [NSMutableArray array];
    LUTColor *color;
    for(int i = 0; i < self.lattice.size; i++){
        color = [self.lattice colorAtR:i g:i b:i];
        [redCurve addObject:@(color.red)];
        [greenCurve addObject:@(color.green)];
        [blueCurve addObject:@(color.blue)];
    }
    
    return [LUT1D LUT1DWithRedCurve:redCurve greenCurve:greenCurve blueCurve:blueCurve];
}

- (LUT *)LUTByResizingToSize:(NSUInteger)newSize {
    if (newSize == self.lattice.size) {
        return [self copy];
    }
    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:newSize];

    double ratio = ((double)self.lattice.size - 1.0) / ((float)newSize - 1.0);
    
    LUTConcurrentCubeLoop(newSize, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        LUTColor *color = [self.lattice colorAtInterpolatedR:r * ratio g:g * ratio b:b * ratio];
        [lattice setColor:color r:r g:g b:b];
    });
    
    return [LUT LUTWithLattice:lattice];
}

- (bool) equalsIdentityLUT{
    return [self equalsLUT:[LUT identityLutOfSize:self.lattice.size]];
}

- (bool) equalsLUT:(LUT *)comparisonLUT{
    if(comparisonLUT.lattice.size != self.lattice.size){
        return false;
    }
    bool __block isEqual = true;
    LUTConcurrentCubeLoop(self.lattice.size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        if(! ([[comparisonLUT.lattice colorAtR:r g:g b:b] equalsLUTColor:[self.lattice colorAtR:r g:g b:b]]) ){
            isEqual = false;
        }
    });
    return isEqual;
}

- (id)copyWithZone:(NSZone *)zone {
    return [LUT LUTWithLattice:[self.lattice copyWithZone:zone]];
}


- (CIFilter *)coreImageFilterWithCurrentColorSpace {
    #if TARGET_OS_IPHONE
    return [self coreImageFilterWithColorSpace:CGColorSpaceCreateDeviceRGB()];
    #elif TARGET_OS_MAC
    return [self coreImageFilterWithColorSpace:[[[NSScreen mainScreen] colorSpace] CGColorSpace]];
    #endif
}

- (CIFilter *)coreImageFilterWithColorSpace:(CGColorSpaceRef)colorSpace {
    
    LUT *usedLut = self.lattice.size > 64 ? [self LUTByResizingToSize:64] : self;
    
    NSUInteger size = usedLut.lattice.size;
    size_t cubeDataSize = size * size * size * sizeof ( float ) * 4;
    float *cubeData = (float *) malloc ( cubeDataSize );
    
    
    
    size_t offset = 0;
    for (int z = 0; z < size; z++) {
        for (int y = 0; y < size; y++) {
            for (int x = 0; x < size; x++) {
                LUTColor *color = [usedLut.lattice colorAtR:x g:y b:z];
                
                cubeData[offset]   = color.red;
                cubeData[offset+1] = color.green;
                cubeData[offset+2] = color.blue;
                cubeData[offset+3] = 1.0;
                
                offset += 4;
            }
        }
    }
    
    NSData *data = [NSData dataWithBytesNoCopy:cubeData length:cubeDataSize freeWhenDone:YES];
    
    CIFilter *colorCube;
    if (colorSpace) {
        colorCube = [CIFilter filterWithName:@"CIColorCubeWithColorSpace"];
        [colorCube setValue:(__bridge id)(colorSpace) forKey:@"inputColorSpace"];
    }
    else {
        colorCube = [CIFilter filterWithName:@"CIColorCube"];
    }
    [colorCube setValue:@(size) forKey:@"inputCubeDimension"];
    [colorCube setValue:data forKey:@"inputCubeData"];
    
    return colorCube;
}

- (CIImage *)processCIImage:(CIImage *)image withColorSpace:(CGColorSpaceRef)colorSpace {
    CIFilter *filter = [self coreImageFilterWithColorSpace:colorSpace];
    [filter setValue:image forKey:@"inputImage"];
    return [filter valueForKey:@"outputImage"];
}

#if TARGET_OS_IPHONE
- (UIImage *)processUIImage:(UIImage *)image withColorSpace:(CGColorSpaceRef)colorSpace {
    return [[UIImage alloc] initWithCIImage:[self processCIImage:image.CIImage withColorSpace:colorSpace]];
}
#elif TARGET_OS_MAC
- (NSImage *)processNSImage:(NSImage *)image withColorSpace:(CGColorSpaceRef)colorSpace {
    CIImage *inputCIImage = [image deep_CIImage];
    CIImage *outputCIImage = [self processCIImage:inputCIImage withColorSpace:colorSpace];
    return [NSImage deep_imageWithCImage:outputCIImage];
}
#endif

@end
