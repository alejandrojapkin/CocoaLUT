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
                                                               colorSpaceName:NSCalibratedRGBColorSpace
                                                                  bytesPerRow:(width * (16 * 3)) / 8
                                                                 bitsPerPixel:16 * 3];
    
    LUTConcurrentCubeLoop(lut.lattice.size, ^(NSUInteger r, NSUInteger g, NSUInteger b) {
        NSUInteger x = b * lut.lattice.size + r;
        NSUInteger y = g;
        NSColor *color = [[lut.lattice colorAtR:r g:g b:b].NSColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
        [imageRep setColor:color atX:x y:y];
    });
    
    NSImage* image = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    [image addRepresentation:imageRep];
    return image;
}

+ (NSData *)dataFromLUT:(LUT *)lut {
    return [[self imageFromLUT:lut] TIFFRepresentation];
}

+ (LUT *)LUTFromData:(NSData *)data {
    return [self LUTFromImage:[[NSImage alloc] initWithData:data]];
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

@end
