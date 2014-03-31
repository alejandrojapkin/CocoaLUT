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
    CGFloat width  = lut.lattice.size * lut.lattice.size;
    CGFloat height = lut.lattice.size;
    
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
    
    LUTConcurrentCubeLoop(lut.lattice.size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        NSUInteger x = b * lut.lattice.size + r;
        NSUInteger y = g;
        NSColor *color = [[lut.lattice colorAtR:r g:g b:b].NSColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
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
    
    LUTLattice *lattice = [[LUTLattice alloc] initWithSize:image.size.height];

    NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];

    LUTConcurrentCubeLoop(lattice.size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        NSUInteger x = b * lattice.size + r;
        NSUInteger y = g;
        [lattice setColor:[LUTColor colorWithNSColor:[imageRep colorAtX:x y:y]] r:r g:g b:b];
    });

    return [LUT LUTWithLattice:lattice];
}
#endif

@end
