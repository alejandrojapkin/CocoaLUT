//
//  LUTFormatterUnwrappedTexture.h
//  Pods
//
//  Created by Wil Gieseler on 3/30/14.
//
//

#import "LUTFormatter.h"

@interface LUTFormatterUnwrappedTexture : LUTFormatter

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
+ (UIImage *)imageFromLUT:(LUT *)lut;
+ (LUT *)LUTFromImage:(UIImage *)image;
#elif TARGET_OS_MAC
+ (NSImage *)imageFromLUT:(LUT *)lut;
+ (LUT *)LUTFromImage:(NSImage *)image;
#endif

@end
