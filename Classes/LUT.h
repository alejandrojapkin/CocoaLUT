//
//  LUT.h
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LUTLattice.h"
#import <QuartzCore/CoreImage.h>

@interface LUT : NSObject

@property (strong) LUTLattice *lattice;

+ (LUT *)LUTWithLattice:(LUTLattice *)lattice;
+ (LUT *)identityLutOfSize:(NSUInteger)size;
- (LUT *)LUTByResizingToSize:(NSUInteger)newSize;

- (CIFilter *)coreImageFilter;

- (CIImage *)processCIImage:(CIImage *)image;
- (NSImage *)processNSImage:(NSImage *)image;

@end
