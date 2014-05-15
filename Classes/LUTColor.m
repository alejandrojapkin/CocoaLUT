//
//  LUTColor.m
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import "LUTColor.h"
#import "LUTHelper.h"

#define LUT_COLOR_EQUALITY_ERROR_MARGIN .0005

@implementation LUTColor

+ (instancetype)colorWithRed:(LUTColorValue)r green:(LUTColorValue)g blue:(LUTColorValue)b {
    LUTColor *color = [[LUTColor alloc] init];
    color.red = r;
    color.green = g;
    color.blue = b;
    return color;
}

+ (instancetype)colorFromIntegersWithBitDepth:(NSUInteger)bitdepth red:(NSUInteger)r green:(NSUInteger)g blue:(NSUInteger)b {
    NSUInteger maxBits = pow(2, bitdepth) - 1;
    return [LUTColor colorWithRed:nsremapint01(r, maxBits) green:nsremapint01(g, maxBits) blue:nsremapint01(b, maxBits)];
}

+ (instancetype)colorFromIntegersWithMaxOutputValue:(NSUInteger)maxOutputValue red:(NSUInteger)r green:(NSUInteger)g blue:(NSUInteger)b {
    return [LUTColor colorWithRed:nsremapint01(r, maxOutputValue) green:nsremapint01(g, maxOutputValue) blue:nsremapint01(b, maxOutputValue)];
}

- (LUTColor *)clampedWithLowerBound:(double)lowerBound
                         upperBound:(double)upperBound{
    return [LUTColor colorWithRed:clamp(self.red, lowerBound, upperBound)
                            green:clamp(self.green, lowerBound, upperBound)
                             blue:clamp(self.blue, lowerBound, upperBound)];
}

- (LUTColor *)contrastStretchWithCurrentMin:(double)currentMin
                                 currentMax:(double)currentMax
                                   finalMin:(double)finalMin
                                   finalMax:(double)finalMax{
    return [LUTColor colorWithRed:contrastStretch(self.red, currentMin, currentMax, finalMin, finalMax)
                            green:contrastStretch(self.green, currentMin, currentMax, finalMin, finalMax)
                             blue:contrastStretch(self.blue, currentMin, currentMax, finalMin, finalMax)];
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
                        outputHigh:(double)outputHigh{
    return [LUTColor colorWithRed:remap(self.red, inputLow, inputHigh, outputLow, outputHigh)
                            green:remap(self.green, inputLow, inputHigh, outputLow, outputHigh)
                             blue:remap(self.blue, inputLow, inputHigh, outputLow, outputHigh)];
}

- (NSString *)description{
    return [NSString stringWithFormat:@"%.6f %.6f %.6f", self.red, self.green, self.blue];
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


#if TARGET_OS_IPHONE
- (UIColor *)UIColor {
    return [UIColor colorWithRed:self.red green:self.green blue:self.blue alpha:1];
}
+ (instancetype)colorWithUIColor:(UIColor *)color {
    return [LUTColor colorWithRed:color.redComponent green:color.greenComponent blue:color.blueComponent];
}
#elif TARGET_OS_MAC
- (NSColor *)NSColor {
    return [NSColor colorWithDeviceRed:self.red green:self.green blue:self.blue alpha:1];
}
+ (instancetype)colorWithNSColor:(NSColor *)color {
    return [LUTColor colorWithRed:color.redComponent green:color.greenComponent blue:color.blueComponent];
}
#endif


@end
