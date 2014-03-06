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

@interface LUT () {
    CIFilter *_coreImageFilter;
}
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

- (id)copyWithZone:(NSZone *)zone {
    return [LUT LUTWithLattice:[self.lattice copyWithZone:zone]];
}

- (CIFilter *)coreImageFilter {
    
    if (_coreImageFilter)
        return _coreImageFilter;
    
    NSUInteger size = self.lattice.size;
    size_t cubeDataSize = size * size * size * sizeof ( float ) * 4;
    float *cubeData = (float *) malloc ( cubeDataSize );
    
    LUT *usedLut = self.lattice.size > 64 ? [self LUTByResizingToSize:64] : self;
    
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
    CIFilter *colorCube = [CIFilter filterWithName:@"CIColorCubeWithColorSpace"];
    CGColorSpaceRef currentColorSpace = [[[NSScreen mainScreen] colorSpace] CGColorSpace];
    [colorCube setValue:@(size) forKey:@"inputCubeDimension"];
    [colorCube setValue:data forKey:@"inputCubeData"];
    [colorCube setValue:(__bridge id)currentColorSpace forKey:@"inputColorSpace"];
    
    _coreImageFilter = colorCube;

    return _coreImageFilter;
}

- (CIImage *)processCIImage:(CIImage *)image {
    CIFilter *filter = [self coreImageFilter];
    [filter setValue:image forKey:@"inputImage"];
    return [filter valueForKey:@"outputImage"];
}

#if TARGET_OS_IPHONE
- (UIImage *)processUIImage:(UIImage *)image {
    return [[UIImage alloc] initWithCIImage:[self processCIImage:image.CIImage]];
}
#elif TARGET_OS_MAC
- (NSImage *)processNSImage:(NSImage *)image {
    NSRect rect = NSMakeRect(0, 0, image.size.width, image.size.height);
    CGImageRef cgImage = [image CGImageForProposedRect:&rect context:[NSGraphicsContext currentContext] hints:nil];
    CIImage *ciImage = [self processCIImage:[CIImage imageWithCGImage:cgImage]];
    NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:ciImage];
    NSImage *nsImage = [[NSImage alloc] initWithSize:rep.size];
    [nsImage addRepresentation:rep];
    return nsImage;
}
#endif

@end
