//
//  LUTFormatterUnwrappedTexture.m
//  Pods
//
//  Created by Wil Gieseler on 3/30/14.
//
//

#import "LUTFormatterUnwrappedTexture.h"
#import "CocoaLUT.h"

@implementation LUTFormatterUnwrappedTexture

+ (NSData *)dataFromLUT:(LUT *)lut {
#if TARGET_OS_IPHONE
    return UIImagePNGRepresentation([self imageFromLUT:lut]);
# elif TARGET_OS_MAC
    return [[self imageFromLUT:lut] TIFFRepresentation];
# endif
}

+ (LUT *)LUTFromData:(NSData *)data {
#if TARGET_OS_IPHONE
    return [self LUTFromImage:[[UIImage alloc] initWithData:data]];
# elif TARGET_OS_MAC
    return [self LUTFromImage:[[NSImage alloc] initWithData:data]];
# endif
}

#if TARGET_OS_IPHONE
+ (UIImage *)imageFromLUT:(LUT *)lut {
    NSException *exception = [NSException exceptionWithName:@"Unsupported Platform"
                                                     reason:@"LUTFormatterUnwrappedTexture doesn't currently support iOS." userInfo:nil];
    @throw exception;
    return nil;
}
+ (LUT *)LUTFromImage:(UIImage *)image {
    NSException *exception = [NSException exceptionWithName:@"Unsupported Platform"
                                                     reason:@"LUTFormatterUnwrappedTexture doesn't currently support iOS." userInfo:nil];
    @throw exception;
    return nil;
}
#elif TARGET_OS_MAC

+ (NSImage *)imageFromLUT:(LUT *)lut {
    
    LUT3D *lut3D;
    if(isLUT1D(lut)){
        lut3D = LUTAsLUT3D(lut, 64);
    }
    else{
        lut3D = (LUT3D *)lut;
    }
    
    CGFloat width  = [lut3D size] * [lut3D size];
    CGFloat height = [lut3D size];
    
    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                   pixelsWide:width
                                                                   pixelsHigh:height
                                                                bitsPerSample:16
                                                              samplesPerPixel:3
                                                                     hasAlpha:NO
                                                                     isPlanar:NO
                                                               colorSpaceName:NSDeviceRGBColorSpace
                                                                  bytesPerRow:(width * (16 * 3)) / 8
                                                                 bitsPerPixel:16 * 3];
    
    LUT3DConcurrentLoop([lut3D size], ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        NSUInteger x = b * [lut3D size] + r;
        NSUInteger y = g;
        NSColor *color = [[lut3D colorAtR:r g:g b:b].NSColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
        [imageRep setColor:color atX:x y:y];
    });
    
    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image addRepresentation:imageRep];
    return image;
}

+ (LUT *)LUTFromImage:(NSImage *)image {
    if (image.size.width != image.size.height * image.size.height) {
        NSException *exception = [NSException exceptionWithName:@"LUTParseError"
                                                         reason:@"Image width must be the square of the image height." userInfo:nil];
        @throw exception;
    }
    
    LUT3D *lut3D = [LUT3D LUTOfSize:image.size.height inputLowerBound:0.0 inputUpperBound:1.0];

    NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];

    LUT3DConcurrentLoop([lut3D size], ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        NSUInteger x = b * [lut3D size] + r;
        NSUInteger y = g;
        [lut3D setColor:[LUTColor colorWithNSColor:[imageRep colorAtX:x y:y]] r:r g:g b:b];
    });

    return lut3D;
}
#endif

@end
