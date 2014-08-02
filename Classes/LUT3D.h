//
//  LUT3D.h
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LUTColor.h"
#import "LUT.h"
#import <M13OrderedDictionary/M13OrderedDictionary.h>

@class LUTColor;
@class LUT1D;

typedef NS_ENUM(NSInteger, LUTMonoConversionMethod) {
    LUTMonoConversionMethodAverageRGB,
    LUTMonoConversionMethodRedCopiedToRGB,
    LUTMonoConversionMethodGreenCopiedToRGB,
    LUTMonoConversionMethodBlueCopiedToRGB
};

/**
 *  Represents a lattice of `LUTColor` objects that make up a 3D lookup table.
 */
@interface LUT3D : LUT

- (instancetype)LUT3DByExtractingColorOnlyWith1DReverseStrictness:(BOOL)strictness;
- (instancetype)LUT3DByExtractingColorShiftContrastReferredWithReverseStrictness:(BOOL)strictness;
- (instancetype)LUT3DByExtractingContrastOnly;
- (instancetype)LUT3DByConvertingToMonoWithConversionMethod:(LUTMonoConversionMethod)conversionMethod;
- (instancetype)LUT3DBySwizzling1DChannelsWithMethod:(LUT1DSwizzleChannelsMethod)method
                                          strictness:(BOOL)strictness;
- (LUT1D *)LUT1D;

- (NSMutableArray *)latticeArrayCopy;


+ (M13OrderedDictionary *)LUTMonoConversionMethods;



@end
