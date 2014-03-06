//
//  LUTColor.h
//  DropLUT
//
//  Created by Wil Gieseler on 12/15/13.
//  Copyright (c) 2013 Wil Gieseler. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CocoaLUT.h"

typedef double LUTColorValue;

@interface LUTColor : NSObject

@property (assign) LUTColorValue red;
@property (assign) LUTColorValue green;
@property (assign) LUTColorValue blue;

+ (LUTColor *)colorWithRed:(LUTColorValue)r green:(LUTColorValue)g blue:(LUTColorValue)b;
+ (LUTColor *)colorFromIntegersWithBitDepth:(NSUInteger)bitdepth red:(NSUInteger)r green:(NSUInteger)g blue:(NSUInteger)b;
- (LUTColor *)clampedO1;
- (LUTColor *)lerpTo:(LUTColor *)otherColor amount:(double)amount;

#if TARGET_OS_IPHONE
- (UIColor *)UIColor;
#elif TARGET_OS_MAC
- (NSColor *)NSColor;
#endif

@end
