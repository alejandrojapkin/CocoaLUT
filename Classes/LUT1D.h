//
//  LUT1D.h
//  Pods
//
//  Created by Greg Cotten and Wil Gieseler on 3/5/14.
//
//

#import <Foundation/Foundation.h>
#import "CocoaLUT.h"

@class LUT;
@class LUTColor;

/**
 *  A one-dimensional color lookup table that is represented by three channel curves.
 */
@interface LUT1D : NSObject

/**
 *  An array of `NSNumber` instances representing the brightness of the red channel curve. Values should be between 0 and 1.
 */
@property (readonly) NSArray *redCurve;

/**
 *  An array of `NSNumber` instances representing the brightness of the green channel curve. Values should be between 0 and 1.
 */
@property (readonly) NSArray *greenCurve;

/**
 *  An array of `NSNumber` instances representing the brightness of the blue channel curve. Values should be between 0 and 1.
 */
@property (readonly) NSArray *blueCurve;

@property (assign) double inputLowerBound;
@property (assign) double inputUpperBound;

/**
 *  Initializes and returns a 1D LUT with the specified channel curves.
 *
 *  An exception will be raised unless all three curves contain the same number of points.
 *
 *  @param redCurve   An array of `NSNumber` instances representing the brightness of the red channel curve. Values should be between 0 and 1.
 *  @param greenCurve An array of `NSNumber` instances representing the brightness of the green channel curve. Values should be between 0 and 1.
 *  @param blueCurve  An array of `NSNumber` instances representing the brightness of the blue channel curve. Values should be between 0 and 1.
 *
 *  @return A newly initialized 1D LUT.
 */
+ (instancetype)LUT1DWithRedCurve:(NSArray *)redCurve
                       greenCurve:(NSArray *)greenCurve
                        blueCurve:(NSArray *)blueCurve
                       lowerBound:(double)lowerBound
                       upperBound:(double)upperBound;

+ (instancetype)LUT1DWith1DCurve:(NSArray *)curve1D
                      lowerBound:(double)lowerBound
                      upperBound:(double)upperBound;

- (LUT1D *)LUT1DByReversing;

/**
 *  Initializes a newly allocated 1D LUT with the specified channel curves.
 *
 *  An exception will be raised unless all three curves contain the same number of points.
 *
 *  @param redCurve   An array of `NSNumber` instances representing the brightness of the red channel curve. Values should be between 0 and 1.
 *  @param greenCurve An array of `NSNumber` instances representing the brightness of the green channel curve. Values should be between 0 and 1.
 *  @param blueCurve  An array of `NSNumber` instances representing the brightness of the blue channel curve. Values should be between 0 and 1.
 *
 *  @return A newly initialized 1D LUT.
 */
- (instancetype)initWithRedCurve:(NSArray *)redCurve
                      greenCurve:(NSArray *)greenCurve
                       blueCurve:(NSArray *)blueCurve
                      lowerBound:(double)lowerBound
                      upperBound:(double)upperBound;

- (LUTColor *)colorAtInterpolatedR:(double)redPoint
                                 g:(double)greenPoint
                                 b:(double)bluePoint;

- (LUTColor *)colorAtColor:(LUTColor *)inputColor;


/**
 *  Generates a 3D LUT that represents an approximation of the transformation applied by the channel curves.
 *
 *  @param size The edge length of the 3D LUT cube.
 *
 *  @return A new `LUT`.
 */
- (LUT *)lutOfSize:(NSUInteger)size;

/**
 *  Returns a new `LUT1D` with the channel curves linearly interpolated to the new number of points.
 *
 *  @param newSize An integer size for the number of points on each channel curves.
 *
 *  @return A new `LUT1D`.
 */
- (LUT1D *)LUT1DByResizingToSize:(NSUInteger)newSize;


@end
