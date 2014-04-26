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

typedef NS_ENUM(NSInteger, LUT1DExtractionMethod) {
    LUT1DExtractionMethodUniqueRGB,
    LUT1DExtractionMethodAverageRGB,
    LUT1DExtractionMethodEdgesRGB,
    LUT1DExtractionMethodRedCopiedToRGB,
    LUT1DExtractionMethodGreenCopiedToRGB,
    LUT1DExtractionMethodBlueCopiedToRGB
};

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

- (instancetype)LUT3DByExtractingColorOnly;
- (instancetype)LUT3DByConvertingToMonoWithConversionMethod:(LUTMonoConversionMethod)conversionMethod;
- (LUT1D *)LUT1DWithExtractionMethod:(LUT1DExtractionMethod)extractionMethod;


//options for API hooks and whatnot
+ (M13OrderedDictionary *)LUT1DExtractionMethods;
+ (M13OrderedDictionary *)LUTMonoConversionMethods;

- (void)setColor:(LUTColor *)color r:(NSUInteger)r g:(NSUInteger)g b:(NSUInteger)b;


@end
