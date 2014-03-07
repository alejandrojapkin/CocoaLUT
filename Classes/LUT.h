//
//  LUT.h
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LUTLattice.h"

@class LUTLattice;

@interface LUT : NSObject <NSCopying>

@property (strong) LUTLattice *lattice;

+ (LUT *)LUTFromURL:(NSURL *)url;
+ (LUT *)LUTWithLattice:(LUTLattice *)lattice;
+ (LUT *)identityLutOfSize:(NSUInteger)size;
- (LUT *)LUTByResizingToSize:(NSUInteger)newSize;

- (CIFilter *)coreImageFilterWithCurrentColorSpace;
- (CIFilter *)coreImageFilterWithColorSpace:(CGColorSpaceRef)colorSpace;

- (CIImage *)processCIImage:(CIImage *)image withColorSpace:(CGColorSpaceRef)colorSpace;

#if TARGET_OS_IPHONE
- (UIImage *)processUIImage:(UIImage *)image withColorSpace:(CGColorSpaceRef)colorSpace;
#elif TARGET_OS_MAC
- (NSImage *)processNSImage:(NSImage *)image withColorSpace:(CGColorSpaceRef)colorSpace;
#endif


@end
