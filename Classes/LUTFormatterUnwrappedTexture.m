//
//  LUTFormatterUnwrappedTexture.m
//  Pods
//
//  Created by Wil Gieseler on 3/30/14.
//
//

#import "LUTFormatterUnwrappedTexture.h"
#import "CocoaLUT.h"
#if defined(COCOAPODS_POD_AVAILABLE_oiiococoa)
#import "NSImage+OIIO.h"
#endif

@implementation LUTFormatterUnwrappedTexture

+ (void)load{
    [super load];
}

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR

//maybe implement someday

#elif TARGET_OS_MAC

+ (NSImage *)imageFromLUT:(LUT *)lut {
    
    LUT3D *lut3D = LUTAsLUT3D(lut, clampUpperBound([lut size], 64));
    
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
    
    [lut3D LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        NSUInteger x = b * [lut3D size] + r;
        NSUInteger y = g;
        NSColor *color = [[lut3D colorAtR:r g:g b:b].systemColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
        [imageRep setColor:color atX:x y:y];
    }];
    
    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image addRepresentation:imageRep];
    return image;
}

+ (LUT *)LUTFromImage:(NSImage *)image {

    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];

    
    if (imageRep.pixelsWide != imageRep.pixelsHigh * imageRep.pixelsHigh) {
        @throw [NSException exceptionWithName:@"UnwrappedTextureReadError"
                                                         reason:@"Image width must be the square of the image height." userInfo:nil];
    }
    
    LUT3D *lut3D = [LUT3D LUTOfSize:image.size.height inputLowerBound:0.0 inputUpperBound:1.0];
    

    
    
    [lut3D LUTLoopWithBlock:^(size_t r, size_t g, size_t b) {
        NSUInteger x = b * [lut3D size] + r;
        NSUInteger y = g;
        [lut3D setColor:[LUTColor colorWithSystemColor:[imageRep colorAtX:x y:y]] r:r g:g b:b];
    }];
    
    return lut3D;
}
#endif

+ (NSString *)utiString{
    return @"public.unwrapped-cube-lut";
}

+ (NSString *)formatterName{
    return @"Unwrapped Cube Image 3D LUT";
}

@end
