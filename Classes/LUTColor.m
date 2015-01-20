//
//  LUTColor.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTColor.h"
#import "LUTHelper.h"
#import <GLKit/GLKit.h>

#define LUT_COLOR_EQUALITY_ERROR_MARGIN .0005

@implementation LUTColor

-(instancetype)copyWithZone:(NSZone *)zone{
    return [LUTColor colorWithRed:self.red green:self.green blue:self.blue];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]) {
        self.red = [aDecoder decodeDoubleForKey:@"red"];
        self.green = [aDecoder decodeDoubleForKey:@"green"];
        self.blue = [aDecoder decodeDoubleForKey:@"blue"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeDouble:self.red forKey:@"red"];
    [aCoder encodeDouble:self.green forKey:@"green"];
    [aCoder encodeDouble:self.blue forKey:@"blue"];
}

+ (instancetype)colorWithZeroes{
    return [self colorWithValue:0];
}

+ (instancetype)colorWithOnes{
    return [self colorWithValue:1];
}

+ (instancetype)colorWithValue:(double)value{
    return [self colorWithRed:value green:value blue:value];
}

+ (instancetype)colorWithRed:(LUTColorValue)r green:(LUTColorValue)g blue:(LUTColorValue)b {
    LUTColor *color = [[LUTColor alloc] init];
    color.red = !isfinite(r) ? 0 : r;
    color.green = !isfinite(g) ? 0 : g;
    color.blue = !isfinite(b) ? 0 : b;
    return color;
}

+ (instancetype)colorFromIntegersWithBitDepth:(NSUInteger)bitdepth red:(NSUInteger)r green:(NSUInteger)g blue:(NSUInteger)b {
    NSUInteger maxBits = maxIntegerFromBitdepth(bitdepth);
    return [LUTColor colorWithRed:nsremapint01(r, maxBits) green:nsremapint01(g, maxBits) blue:nsremapint01(b, maxBits)];
}

+ (instancetype)colorFromIntegersWithMaxOutputValue:(NSUInteger)maxOutputValue red:(NSUInteger)r green:(NSUInteger)g blue:(NSUInteger)b {
    return [LUTColor colorWithRed:nsremapint01(r, maxOutputValue) green:nsremapint01(g, maxOutputValue) blue:nsremapint01(b, maxOutputValue)];
}

- (double)minimumValue{
    return MIN(MIN(self.red, self.green), self.blue);
}

- (double)maximumValue{
    return MAX(MAX(self.red, self.green), self.blue);
}

- (void)setRed:(LUTColorValue)red{
    _red = !isfinite(red) ? 0 : red;
}

- (void)setGreen:(LUTColorValue)green{
    _green = !isfinite(green) ? 0 : green;
}

- (void)setBlue:(LUTColorValue)blue{
    _blue = !isfinite(blue) ? 0 : blue;
}

- (LUTColor *)clampedWithLowerBound:(double)lowerBound
                         upperBound:(double)upperBound{
    return [LUTColor colorWithRed:clamp(self.red, lowerBound, upperBound)
                            green:clamp(self.green, lowerBound, upperBound)
                             blue:clamp(self.blue, lowerBound, upperBound)];
}

- (LUTColor *)clampedWithLowerBoundOnly:(double)lowerBound{
    return [LUTColor colorWithRed:clampLowerBound(self.red, lowerBound)
                            green:clampLowerBound(self.green, lowerBound)
                             blue:clampLowerBound(self.blue, lowerBound)];

}

- (LUTColor *)clampedWithUpperBoundOnly:(double)upperBound{
    return [LUTColor colorWithRed:clampUpperBound(self.red, upperBound)
                            green:clampUpperBound(self.green, upperBound)
                             blue:clampUpperBound(self.blue, upperBound)];

}

- (LUTColor *)contrastStretchWithCurrentMin:(double)currentMin
                                 currentMax:(double)currentMax
                                   finalMin:(double)finalMin
                                   finalMax:(double)finalMax{
    return [LUTColor colorWithRed:contrastStretch(self.red, currentMin, currentMax, finalMin, finalMax)
                            green:contrastStretch(self.green, currentMin, currentMax, finalMin, finalMax)
                             blue:contrastStretch(self.blue, currentMin, currentMax, finalMin, finalMax)];
}

- (LUTColor *)colorByMultiplyingByNumber:(double)number{
    return [LUTColor colorWithRed:self.red*number green:self.green*number blue:self.blue*number];
}

- (LUTColor *)colorByMultiplyingColor:(LUTColor *)offsetColor{
    return [LUTColor colorWithRed:self.red*offsetColor.red green:self.green*offsetColor.green blue:self.blue*offsetColor.blue];
}

- (LUTColor *)colorByAddingColor:(LUTColor *)offsetColor{
    return [LUTColor colorWithRed:self.red+offsetColor.red green:self.green+offsetColor.green blue:self.blue+offsetColor.blue];
}

- (LUTColor *)colorBySubtractingColor:(LUTColor *)offsetColor{
    return [LUTColor colorWithRed:self.red-offsetColor.red green:self.green-offsetColor.green blue:self.blue-offsetColor.blue];
}

- (LUTColor *)colorByInvertingColorWithMinimumValue:(double)minimumValue
                                       maximumValue:(double)maximumValue{
    double distance = abs(maximumValue-minimumValue);
    return [LUTColor colorWithRed:distance - self.red green:distance - self.green blue:distance - self.blue];
}

//thanks http://git.dyne.org/frei0r/plain/src/filter/sopsat/sopsat.cpp
//  The "saturation" parameter works like this:
//    0.0 creates a black-and-white image.
//    0.5 reduces the color saturation by half.
//    1.0 causes no change.
//    2.0 doubles the color saturation.
//  Note:  A "change" value greater than 1.0 may project your RGB values
//  beyond their normal range, in which case you probably should truncate
//  them to the desired range before trying to use them in an image.
//  ex: REC709 luma: 0.212636821677 R + 0.715182981841 G + 0.0721801964814 B
///  AlexaWideGamut: 0.291948669899 R + 0.823830265984 G + -0.115778935883 B
- (LUTColor *)colorByChangingSaturation:(double)saturation
                             usingLumaR:(double)lumaR
                                  lumaG:(double)lumaG
                                  lumaB:(double)lumaB{

    double luma = (self.red)*lumaR + (self.green)*lumaG + (self.blue)*lumaB;

    return [LUTColor colorWithRed:luma + saturation * (self.red - luma)
                            green:luma + saturation * (self.green - luma)
                             blue:luma + saturation * (self.blue - luma)];

}

- (double)luminanceRec709{
    return [self luminanceUsingLumaR:0.2126 lumaG:0.7152 lumaB:0.0722];
}


- (double)luminanceUsingLumaR:(double)lumaR
                        lumaG:(double)lumaG
                        lumaB:(double)lumaB{
    return (self.red)*lumaR + (self.green)*lumaG + (self.blue)*lumaB;
}


//thanks http://en.wikipedia.org/wiki/ASC_CDL
- (LUTColor *)colorByApplyingRedSlope:(double)redSlope
                            redOffset:(double)redOffset
                             redPower:(double)redPower
                           greenSlope:(double)greenSlope
                          greenOffset:(double)greenOffset
                           greenPower:(double)greenPower
                             blueSlope:(double)blueSlope
                            blueOffset:(double)blueOffset
                             bluePower:(double)bluePower {

    redSlope = clampLowerBound(redSlope, 0);
    redPower = clampLowerBound(redPower, 0);
    greenSlope = clampLowerBound(greenSlope, 0);
    greenPower = clampLowerBound(greenPower, 0);
    blueSlope = clampLowerBound(blueSlope, 0);
    bluePower = clampLowerBound(bluePower, 0);


    double newRed = pow(self.red*redSlope + redOffset, redPower);
    double newGreen = pow(self.green*greenSlope + greenOffset, greenPower);
    double newBlue = pow(self.blue*blueSlope + blueOffset, bluePower);

    return [LUTColor colorWithRed:newRed green:newGreen blue:newBlue];

}


- (LUTColor *)clamped01 {
    return [LUTColor colorWithRed:clamp01(self.red) green:clamp01(self.green) blue:clamp01(self.blue)];
}

- (LUTColor *)lerpTo:(LUTColor *)otherColor amount:(double)amount {
    return [LUTColor colorWithRed:lerp1d(self.red, otherColor.red, amount)
                            green:lerp1d(self.green, otherColor.green, amount)
                             blue:lerp1d(self.blue, otherColor.blue, amount)];
}

- (LUTColor *)remappedFromInputLow:(double)inputLow
                         inputHigh:(double)inputHigh
                         outputLow:(double)outputLow
                        outputHigh:(double)outputHigh
                           bounded:(BOOL)bounded{
    if(!bounded){
        return [LUTColor colorWithRed:remapNoError(self.red, inputLow, inputHigh, outputLow, outputHigh)
                                green:remapNoError(self.green, inputLow, inputHigh, outputLow, outputHigh)
                                 blue:remapNoError(self.blue, inputLow, inputHigh, outputLow, outputHigh)];

    }
    else{
        return [LUTColor colorWithRed:remap(self.red, inputLow, inputHigh, outputLow, outputHigh)
                                green:remap(self.green, inputLow, inputHigh, outputLow, outputHigh)
                                 blue:remap(self.blue, inputLow, inputHigh, outputLow, outputHigh)];
    }

}

- (LUTColor *)colorByRemappingFromInputLowColor:(LUTColor *)inputLowColor
                                      inputHigh:(LUTColor *)inputHighColor
                                      outputLow:(LUTColor *)outputLowColor
                                     outputHigh:(LUTColor *)outputHighColor
                                        bounded:(BOOL)bounded{
    if(!bounded){
        return [LUTColor colorWithRed:remapNoError(self.red, inputLowColor.red, inputHighColor.red, outputLowColor.red, outputHighColor.red)
                                green:remapNoError(self.green, inputLowColor.green, inputHighColor.green, outputLowColor.green, outputHighColor.green)
                                 blue:remapNoError(self.blue, inputLowColor.blue, inputHighColor.blue, outputLowColor.blue, outputHighColor.blue)];

    }
    else{
        return [LUTColor colorWithRed:remap(self.red, inputLowColor.red, inputHighColor.red, outputLowColor.red, outputHighColor.red)
                                green:remap(self.green, inputLowColor.green, inputHighColor.green, outputLowColor.green, outputHighColor.green)
                                 blue:remap(self.blue, inputLowColor.blue, inputHighColor.blue, outputLowColor.blue, outputHighColor.blue)];
    }
    
}

- (LUTColor *)colorByApplyingColorMatrixColumnMajorM00:(double)m00
                                                   m01:(double)m01
                                                   m02:(double)m02
                                                   m10:(double)m10
                                                   m11:(double)m11
                                                   m12:(double)m12
                                                   m20:(double)m20
                                                   m21:(double)m21
                                                   m22:(double)m22{
    GLKMatrix3 matrix = GLKMatrix3Make(m00, m01, m02, m10, m11, m12, m20, m21, m22);
    GLKVector3 result = GLKMatrix3MultiplyVector3(matrix, GLKVector3Make(self.red, self.green, self.blue));

    return [LUTColor colorWithRed:result.x green:result.y blue:result.z];
}

- (double)distanceToColor:(LUTColor *)otherColor{
    return sqrt(pow(self.red - otherColor.red, 2) + pow(self.green - otherColor.green, 2) + pow(self.blue - otherColor.blue, 2));
}

- (NSString *)stringFormattedWithFloatingPointLength:(int)length{
    NSString *formatString = [NSString stringWithFormat:@"%%.%if", length];
    NSString *colorStringFormat = [NSString stringWithFormat:@"(%@, %@, %@)", formatString, formatString, formatString];
    return [NSString stringWithFormat:colorStringFormat, self.red, self.green, self.blue];
}

- (NSString *)description{
    return [NSString stringWithFormat:@"(%.6f, %.6f, %.6f)", self.red, self.green, self.blue];
}

- (NSArray *)rgbArray{
    return @[@(self.red), @(self.green), @(self.blue)];
}

- (NSAttributedString *)colorizedAttributedStringWithFormat:(NSString *)formatString{
    NSString *redString = [NSString stringWithFormat:[NSString stringWithFormat:@"%@", formatString], self.red];
    NSString *greenString = [NSString stringWithFormat:[NSString stringWithFormat:@"%@", formatString], self.green];
    NSString *blueString = [NSString stringWithFormat:[NSString stringWithFormat:@"%@", formatString], self.blue];

    NSAttributedString *redColoredString = [[NSAttributedString alloc] initWithString:redString attributes:@{NSForegroundColorAttributeName: [SystemColor redColor]}];

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    SystemColor *green = SystemColor.greenColor;
#elif TARGET_OS_MAC
    SystemColor *green = [SystemColor colorWithDeviceRed:0 green:.8 blue:0 alpha:1];
#endif

    NSAttributedString *greenColoredString = [[NSAttributedString alloc] initWithString:greenString attributes:@{NSForegroundColorAttributeName: green}];//custom green color because pure green is really hard to read.

    NSAttributedString *blueColoredString = [[NSAttributedString alloc] initWithString:blueString attributes:@{NSForegroundColorAttributeName: [SystemColor blueColor]}];

    NSMutableAttributedString *outString = [[NSMutableAttributedString alloc] initWithString:@""];
    [outString appendAttributedString:redColoredString];
    [outString appendAttributedString:[[NSAttributedString alloc] initWithString:@", "]];
    [outString appendAttributedString:greenColoredString];
    [outString appendAttributedString:[[NSAttributedString alloc] initWithString:@", "]];
    [outString appendAttributedString:blueColoredString];
    [outString appendAttributedString:[[NSAttributedString alloc] initWithString:@""]];

    return outString;
}

- (BOOL)isEqualToLUTColor:(LUTColor *)otherColor{
    if (!otherColor){
        return NO;
    }
    return fabs(self.red - otherColor.red) <= LUT_COLOR_EQUALITY_ERROR_MARGIN && fabs(self.green - otherColor.green) <= LUT_COLOR_EQUALITY_ERROR_MARGIN && fabs(self.blue - otherColor.blue) <= LUT_COLOR_EQUALITY_ERROR_MARGIN;

}

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[LUTColor class]]) {
        return NO;
    }

    return [self isEqualToLUTColor:(LUTColor *)object];
}

- (SystemColor *)systemColor {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    return [UIColor colorWithRed:self.red green:self.green blue:self.blue alpha:1];
#elif TARGET_OS_MAC
    return [NSColor colorWithDeviceRed:self.red green:self.green blue:self.blue alpha:1];
#endif
}
+ (instancetype)colorWithSystemColor:(SystemColor *)color {
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    return [LUTColor colorWithRed:[[color CIColor] red] green:[[color CIColor] green] blue:[[color CIColor] blue]];
#elif TARGET_OS_MAC
    return [LUTColor colorWithRed:color.redComponent green:color.greenComponent blue:color.blueComponent];
#endif
}

@end
