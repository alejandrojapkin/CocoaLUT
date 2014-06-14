//
//  LUTColor.h
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CocoaLUT.h"

#define LEGAL_LEVELS_MIN 0.06256109481 //64.0/1023.0
#define LEGAL_LEVELS_MAX 0.91886608015 //940.0/1023.0
#define EXTENDED_LEVELS_MIN 0.0 //0.00391006842 //4.0/1023.0
#define EXTENDED_LEVELS_MAX 1.0 //0.99608993157 //1019.0/1023.0

/**
 *  Used to represent the value of a channel for a `LUTColor`.
 */
typedef double LUTColorValue;

/**
 *  Represents a color value on a 3D LUT lattice.
 */
@interface LUTColor : NSObject

/**
 *  The value of the red channel of the color. Values should be between 0 and 1
 */
@property (assign) LUTColorValue red;

/**
 *  The value of the green channel of the color. Values should be between 0 and 1
 */
@property (assign) LUTColorValue green;

/**
 *  The value of the blue channel of the color. Values should be between 0 and 1
 */
@property (assign) LUTColorValue blue;


/**
 *  Returns a new color with the provided floating-point channel values.
 *
 *  @param r The value of the red channel of the color. Values should be between 0 and 1
 *  @param g The value of the green channel of the color. Values should be between 0 and 1
 *  @param b The value of the blue channel of the color. Values should be between 0 and 1
 *
 *  @return A new color.
 */
+ (instancetype)colorWithRed:(LUTColorValue)r green:(LUTColorValue)g blue:(LUTColorValue)b;

/**
 *  Returns a new color with the provided integer channel values and a bit depth of the color system. Values will be converted to floating-point.
 *
 *  @param bitdepth The bit depth of the color system represented by these integers.
 *  @param r        The value of the red channel of the color in the color system.
 *  @param g        The value of the green channel of the color in the color system.
 *  @param b        The value of the blue channel of the color in the color system.
 *
 *  @return A new color.
 */
+ (instancetype)colorFromIntegersWithBitDepth:(NSUInteger)bitdepth red:(NSUInteger)r green:(NSUInteger)g blue:(NSUInteger)b;
+ (instancetype)colorFromIntegersWithMaxOutputValue:(NSUInteger)maxOutputValue red:(NSUInteger)r green:(NSUInteger)g blue:(NSUInteger)b;


- (LUTColor *)contrastStretchWithCurrentMin:(double)currentMin
                                 currentMax:(double)currentMax
                                   finalMin:(double)finalMin
                                   finalMax:(double)finalMax;

/**
 *  Returns a new color with channel values clipped below zero and above 1.
 *
 *  @return A new color.
 */
- (LUTColor *)clamped01;

- (LUTColor *)clampedWithLowerBound:(double)lowerBound
                         upperBound:(double)upperBound;

- (LUTColor *)remappedFromInputLow:(double)inputLow
                         inputHigh:(double)inputHigh
                         outputLow:(double)outputLow
                        outputHigh:(double)outputHigh
                           bounded:(BOOL)bounded;

- (LUTColor *)colorByAddingColor:(LUTColor *)offsetColor;
- (LUTColor *)colorBySubtractingColor:(LUTColor *)offsetColor;

- (LUTColor *)colorByInvertingColorWithMinimumValue:(double)minimumValue
                                       maximumValue:(double)maximumValue;

- (LUTColor *)colorByChangingSaturation:(double)saturation
                             usingLumaR:(double)lumaR
                                  lumaG:(double)lumaG
                                  lumaB:(double)lumaB;

- (LUTColor *)colorByApplyingRedSlope:(double)redSlope
                            redOffset:(double)redOffset
                             redPower:(double)redPower
                           greenSlope:(double)greenSlope
                          greenOffset:(double)greenOffset
                           greenPower:(double)greenPower
                            blueSlope:(double)blueSlope
                           blueOffset:(double)blueOffset
                            bluePower:(double)bluePower;

/**
 *  Linearly interpolate between two colors by a percentage amount.
 *
 *  An `amount` of zero returns a color identical to the receiver. An `amount` of 1 returns a color identical to `otherColor`. An `amount` of 0.5 represents a color halfway between the receiver and `otherColor`.
 *
 *  @param otherColor The destination color of the interpolation.
 *  @param amount     The percentage distance between the two colors, between 0 and 1.
 *
 *  @return <#return value description#>
 */
- (LUTColor *)lerpTo:(LUTColor *)otherColor amount:(double)amount;

/**
 *  A LUTColor representation of the system color. On OS X this takes an NSColor, on iOS a UIColor.
 *
 *  @return A `LUTColor`.
 */
+ (instancetype)colorWithSystemColor:(SystemColor *)color;

/**
 *  A system color representation of the LUTColor.
 *
 *  @return On OS X, an NSColor, on iOS a UIColor.
 */
- (SystemColor *)systemColor;

@end
