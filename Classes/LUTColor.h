//
//  LUTColor.h
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef double LUTColorValue;

double clamp(double value, double min, double max);
double clamp01(double value);

@interface LUTColor : NSObject

@property (assign) LUTColorValue red;
@property (assign) LUTColorValue green;
@property (assign) LUTColorValue blue;

+ (LUTColor *)colorWithRed:(LUTColorValue)r green:(LUTColorValue)g blue:(LUTColorValue)b;
- (LUTColor *)clampedO1;
- (LUTColor *)lerpTo:(LUTColor *)otherColor amount:(double)amount;
- (NSColor *)nsColor;

@end
